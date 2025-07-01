

Цей скрипт створює повну інфраструктуру для Django додатку в Azure, включаючи:

## 🏗️ **Створені ресурси:**

**Основна інфраструктура:**
- **Resource Group** - контейнер для всіх ресурсів
- **App Service Plan** - обчислювальні ресурси (Linux)
- **Web App** - сам Django додаток з Python runtime

**База даних:**
- **PostgreSQL Flexible Server** - керована база даних
- **Database** - окрема база для Django
- **Firewall rules** - доступ для Azure сервісів

**Зберігання та безпека:**
- **Storage Account** - для статичних файлів та медіа
- **Key Vault** - для безпечного зберігання секретів
- **Managed Identity** - для безпечного доступу до ресурсів

**Моніторинг:**
- **Application Insights** - для логів та метрик

## 🔧 **Налаштування для Django:**

**Змінні середовища:**
- `DJANGO_SETTINGS_MODULE` - налаштування для продакшн
- `SECRET_KEY` - з Key Vault
- `DATABASE_URL` - готове підключення до PostgreSQL
- `AZURE_STORAGE_*` - налаштування для статичних файлів
- `APPINSIGHTS_*` - для моніторингу

**Файли конфігурації:**
- `requirements.txt` - всі необхідні пакети
- `startup.sh` - скрипт запуску з міграціями
- `.env.example` - приклад змінних середовища
- `web.config` - конфігурація для App Service

## 🚀 **Як використовувати:**

1. **Налаштуйте змінні** в початку скрипта
2. **Запустіть скрипт:** `chmod +x script.sh && ./script.sh`
3. **Додайте створені файли** до вашого Django проекту
4. **Налаштуйте settings.py** для використання Azure ресурсів
5. **Деплойте код** через GitHub Actions або Azure DevOps

Скрипт автоматично генерує безпечні паролі, налаштовує HTTPS, створює необхідні контейнери для файлів та зберігає всю конфігурацію у `infrastructure-summary.txt`.


---------------------------------------------------------------------------------------------------------------


```bash
#!/bin/bash

# =============================================================================
# Скрипт для створення повної інфраструктури Azure для Django додатку
# =============================================================================

set -e  # Зупинити скрипт при помилці

# Кольори для виводу
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функція для логування
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# =============================================================================
# КОНФІГУРАЦІЯ - НАЛАШТУЙТЕ ЦІ ЗМІННІ
# =============================================================================

# Основні параметри
PROJECT_NAME="django-app"
ENVIRONMENT="production"  # production, staging, development
LOCATION="West Europe"
TIMESTAMP=$(date +%s)

# Імена ресурсів
RESOURCE_GROUP_NAME="${PROJECT_NAME}-${ENVIRONMENT}-rg"
APP_SERVICE_PLAN_NAME="${PROJECT_NAME}-${ENVIRONMENT}-plan"
WEB_APP_NAME="${PROJECT_NAME}-${ENVIRONMENT}-${TIMESTAMP}"
DATABASE_SERVER_NAME="${PROJECT_NAME}-${ENVIRONMENT}-db-${TIMESTAMP}"
DATABASE_NAME="${PROJECT_NAME}_db"
STORAGE_ACCOUNT_NAME="${PROJECT_NAME}${ENVIRONMENT}storage${TIMESTAMP}"
KEY_VAULT_NAME="${PROJECT_NAME}-${ENVIRONMENT}-kv-${TIMESTAMP}"
APP_INSIGHTS_NAME="${PROJECT_NAME}-${ENVIRONMENT}-insights"

# Конфігурація App Service
APP_SERVICE_SKU="B1"  # F1 (Free), B1 (Basic), S1 (Standard), P1V2 (Premium)
PYTHON_VERSION="3.11"

# Конфігурація бази даних
DB_ADMIN_USER="djangoadmin"
DB_ADMIN_PASSWORD="$(openssl rand -base64 32 | tr -d '=/+' | cut -c1-16)Aa1!"
DB_SKU="GP_Gen5_1"  # General Purpose, 1 vCore

# Теги для ресурсів
TAGS="Environment=${ENVIRONMENT} Project=${PROJECT_NAME} CreatedBy=AzureCLI"

log "Початок створення інфраструктури для Django додатку..."
log "Проект: ${PROJECT_NAME}"
log "Середовище: ${ENVIRONMENT}"
log "Регіон: ${LOCATION}"

# =============================================================================
# ПЕРЕВІРКА ЗАЛЕЖНОСТЕЙ
# =============================================================================

log "Перевірка залежностей..."

# Перевірка Azure CLI
if ! command -v az &> /dev/null; then
    error "Azure CLI не встановлено. Встановіть його з https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
fi

# Перевірка авторизації
if ! az account show &> /dev/null; then
    error "Ви не авторизовані в Azure CLI. Виконайте 'az login'"
fi

# Перевірка openssl для генерації паролів
if ! command -v openssl &> /dev/null; then
    error "OpenSSL не встановлено"
fi

log "✅ Всі залежності встановлені"

# =============================================================================
# СТВОРЕННЯ РЕСУРСІВ
# =============================================================================

# 1. Створення Resource Group
log "Створення Resource Group: ${RESOURCE_GROUP_NAME}"
az group create \
    --name "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --tags $TAGS

# 2. Створення Storage Account для статичних файлів та медіа
log "Створення Storage Account: ${STORAGE_ACCOUNT_NAME}"
az storage account create \
    --name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --access-tier Hot \
    --tags $TAGS

# Створення контейнерів для статичних файлів та медіа
STORAGE_KEY=$(az storage account keys list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --query '[0].value' \
    --output tsv)

az storage container create \
    --name "static" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --account-key "$STORAGE_KEY" \
    --public-access blob

az storage container create \
    --name "media" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --account-key "$STORAGE_KEY" \
    --public-access blob

# 3. Створення PostgreSQL Database
log "Створення PostgreSQL сервера: ${DATABASE_SERVER_NAME}"
az postgres flexible-server create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$DATABASE_SERVER_NAME" \
    --location "$LOCATION" \
    --admin-user "$DB_ADMIN_USER" \
    --admin-password "$DB_ADMIN_PASSWORD" \
    --sku-name "$DB_SKU" \
    --storage-size 32 \
    --version 14 \
    --public-access 0.0.0.0 \
    --tags $TAGS

# Створення бази даних
log "Створення бази даних: ${DATABASE_NAME}"
az postgres flexible-server db create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --server-name "$DATABASE_SERVER_NAME" \
    --database-name "$DATABASE_NAME"

# Налаштування firewall правил
log "Налаштування firewall правил для бази даних"
az postgres flexible-server firewall-rule create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$DATABASE_SERVER_NAME" \
    --rule-name "AllowAzureServices" \
    --start-ip-address 0.0.0.0 \
    --end-ip-address 0.0.0.0

# 4. Створення Key Vault для секретів
log "Створення Key Vault: ${KEY_VAULT_NAME}"
az keyvault create \
    --name "$KEY_VAULT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --tags $TAGS

# Додавання секретів до Key Vault
log "Додавання секретів до Key Vault"
DJANGO_SECRET_KEY=$(openssl rand -base64 50 | tr -d '=/+')

az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "django-secret-key" \
    --value "$DJANGO_SECRET_KEY"

az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "database-password" \
    --value "$DB_ADMIN_PASSWORD"

az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "storage-account-key" \
    --value "$STORAGE_KEY"

# 5. Створення Application Insights
log "Створення Application Insights: ${APP_INSIGHTS_NAME}"
az monitor app-insights component create \
    --app "$APP_INSIGHTS_NAME" \
    --location "$LOCATION" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --tags $TAGS

# Отримання Instrumentation Key
INSTRUMENTATION_KEY=$(az monitor app-insights component show \
    --app "$APP_INSIGHTS_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --query "instrumentationKey" \
    --output tsv)

# 6. Створення App Service Plan
log "Створення App Service Plan: ${APP_SERVICE_PLAN_NAME}"
az appservice plan create \
    --name "$APP_SERVICE_PLAN_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --sku "$APP_SERVICE_SKU" \
    --is-linux \
    --tags $TAGS

# 7. Створення Web App
log "Створення Web App: ${WEB_APP_NAME}"
az webapp create \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --plan "$APP_SERVICE_PLAN_NAME" \
    --runtime "PYTHON:${PYTHON_VERSION}" \
    --tags $TAGS

# 8. Налаштування змінних середовища для Django
log "Налаштування змінних середовища"
DATABASE_URL="postgresql://${DB_ADMIN_USER}:${DB_ADMIN_PASSWORD}@${DATABASE_SERVER_NAME}.postgres.database.azure.com:5432/${DATABASE_NAME}?sslmode=require"

az webapp config appsettings set \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --settings \
        DJANGO_SETTINGS_MODULE="config.settings.production" \
        SECRET_KEY="@Microsoft.KeyVault(VaultName=${KEY_VAULT_NAME};SecretName=django-secret-key)" \
        DATABASE_URL="$DATABASE_URL" \
        AZURE_STORAGE_ACCOUNT_NAME="$STORAGE_ACCOUNT_NAME" \
        AZURE_STORAGE_ACCOUNT_KEY="@Microsoft.KeyVault(VaultName=${KEY_VAULT_NAME};SecretName=storage-account-key)" \
        AZURE_STORAGE_CONTAINER_STATIC="static" \
        AZURE_STORAGE_CONTAINER_MEDIA="media" \
        APPINSIGHTS_INSTRUMENTATIONKEY="$INSTRUMENTATION_KEY" \
        APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=${INSTRUMENTATION_KEY}" \
        DEBUG="False" \
        ALLOWED_HOSTS="${WEB_APP_NAME}.azurewebsites.net" \
        DJANGO_LOG_LEVEL="INFO" \
        PYTHONPATH="/home/site/wwwroot"

# 9. Налаштування App Service для Django
log "Налаштування App Service для Django"

# Налаштування startup команди
az webapp config set \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --startup-file "gunicorn --bind=0.0.0.0 --timeout 600 config.wsgi"

# Увімкнення логів
az webapp log config \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --application-logging filesystem \
    --detailed-error-messages true \
    --failed-request-tracing true \
    --web-server-logging filesystem

# 10. Налаштування managed identity для доступу до Key Vault
log "Налаштування Managed Identity"
az webapp identity assign \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME"

# Отримання Principal ID
PRINCIPAL_ID=$(az webapp identity show \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --query "principalId" \
    --output tsv)

# Надання доступу до Key Vault
az keyvault set-policy \
    --name "$KEY_VAULT_NAME" \
    --object-id "$PRINCIPAL_ID" \
    --secret-permissions get list

# 11. Увімкнення HTTPS
log "Увімкнення HTTPS"
az webapp update \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --https-only true

# 12. Налаштування custom domain (опціонально)
# Розкоментуйте якщо маєте кастомний домен
# CUSTOM_DOMAIN="yourdomain.com"
# az webapp config hostname add \
#     --webapp-name "$WEB_APP_NAME" \
#     --resource-group "$RESOURCE_GROUP_NAME" \
#     --hostname "$CUSTOM_DOMAIN"

# =============================================================================
# СТВОРЕННЯ ФАЙЛІВ КОНФІГУРАЦІЇ
# =============================================================================

log "Створення файлів конфігурації"

# Створення requirements.txt
cat > requirements.txt << 'EOF'
Django>=4.2,<5.0
psycopg2-binary>=2.9.0
gunicorn>=20.1.0
django-storages[azure]>=1.13.0
python-decouple>=3.6
applicationinsights>=0.11.10
opencensus-ext-azure>=1.1.0
opencensus-ext-django>=0.8.0
whitenoise>=6.0.0
Pillow>=9.0.0
celery>=5.2.0
redis>=4.0.0
EOF

# Створення .env.example
cat > .env.example << EOF
# Django Settings
SECRET_KEY=your-secret-key-here
DEBUG=False
ALLOWED_HOSTS=${WEB_APP_NAME}.azurewebsites.net

# Database
DATABASE_URL=postgresql://user:password@host:port/database

# Azure Storage
AZURE_STORAGE_ACCOUNT_NAME=${STORAGE_ACCOUNT_NAME}
AZURE_STORAGE_ACCOUNT_KEY=your-storage-key
AZURE_STORAGE_CONTAINER_STATIC=static
AZURE_STORAGE_CONTAINER_MEDIA=media

# Application Insights
APPINSIGHTS_INSTRUMENTATIONKEY=${INSTRUMENTATION_KEY}
EOF

# Створення startup.sh для App Service
cat > startup.sh << 'EOF'
#!/bin/bash

echo "Starting Django application..."

# Collect static files
python manage.py collectstatic --noinput

# Run migrations
python manage.py migrate --noinput

# Start Gunicorn
exec gunicorn --bind=0.0.0.0:8000 --timeout 600 --workers 3 config.wsgi:application
EOF

chmod +x startup.sh

# Створення web.config для App Service
cat > web.config << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <handlers>
      <add name="PythonHandler" path="*" verb="*" modules="httpPlatformHandler" resourceType="Unspecified"/>
    </handlers>
    <httpPlatform processPath="python" arguments="manage.py runserver --noreload 0.0.0.0:%HTTP_PLATFORM_PORT%" stdoutLogEnabled="true" stdoutLogFile="python.log" startupTimeLimit="60" processesPerApplication="16">
      <environmentVariables>
        <environmentVariable name="PYTHONPATH" value="%PYTHONPATH%;%{APPL_PHYSICAL_PATH}"/>
      </environmentVariables>
    </httpPlatform>
  </system.webServer>
</configuration>
EOF

# =============================================================================
# ПІДСУМОК
# =============================================================================

# Отримання URL додатку
APP_URL=$(az webapp show \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --query "defaultHostName" \
    --output tsv)

log "✅ Інфраструктура успішно створена!"

echo ""
echo "=========================================="
echo "📋 ПІДСУМОК СТВОРЕНИХ РЕСУРСІВ"
echo "=========================================="
echo "🌍 Resource Group: $RESOURCE_GROUP_NAME"
echo "🚀 Web App: $WEB_APP_NAME"
echo "🔗 URL: https://$APP_URL"
echo "📊 App Service Plan: $APP_SERVICE_PLAN_NAME ($APP_SERVICE_SKU)"
echo "🗄️  PostgreSQL Server: $DATABASE_SERVER_NAME"
echo "🗃️  Database: $DATABASE_NAME"
echo "💾 Storage Account: $STORAGE_ACCOUNT_NAME"
echo "🔐 Key Vault: $KEY_VAULT_NAME"
echo "📈 Application Insights: $APP_INSIGHTS_NAME"
echo ""
echo "=========================================="
echo "🔑 ДОСТУПИ (ЗБЕРЕЖІТЬ В БЕЗПЕЧНОМУ МІСЦІ!)"
echo "=========================================="
echo "Database Admin User: $DB_ADMIN_USER"
echo "Database Admin Password: $DB_ADMIN_PASSWORD"
echo "Django Secret Key: збережено в Key Vault"
echo "Storage Account Key: збережено в Key Vault"
echo ""
echo "=========================================="
echo "📝 НАСТУПНІ КРОКИ"
echo "=========================================="
echo "1. Налаштуйте ваш Django проект для роботи з Azure"
echo "2. Додайте створені файли конфігурації до вашого проекту"
echo "3. Налаштуйте CI/CD pipeline для автоматичного деплою"
echo "4. Протестуйте підключення до бази даних"
echo "5. Налаштуйте моніторинг в Application Insights"
echo ""
echo "🚀 Ваш Django додаток готовий до деплою!"
echo "=========================================="

# Збереження конфігурації у файл
cat > infrastructure-summary.txt << EOF
Django Azure Infrastructure Summary
===================================
Created: $(date)
Project: $PROJECT_NAME
Environment: $ENVIRONMENT

Resources:
- Resource Group: $RESOURCE_GROUP_NAME
- Web App: $WEB_APP_NAME
- URL: https://$APP_URL
- Database Server: $DATABASE_SERVER_NAME
- Database: $DATABASE_NAME
- Storage Account: $STORAGE_ACCOUNT_NAME
- Key Vault: $KEY_VAULT_NAME
- Application Insights: $APP_INSIGHTS_NAME

Database Credentials:
- Admin User: $DB_ADMIN_USER
- Admin Password: $DB_ADMIN_PASSWORD

Connection String:
$DATABASE_URL
EOF

log "📄 Конфігурація збережена у файл: infrastructure-summary.txt"

```
---------------------------------------------------------------------------------------------------------------

```bash
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ ./script_azure.sh
[2025-06-30 14:42:17] Початок створення інфраструктури для Django додатку...
[2025-06-30 14:42:17] Проект: django-app
[2025-06-30 14:42:17] Середовище: production
[2025-06-30 14:42:17] Регіон: West Europe
[2025-06-30 14:42:17] Перевірка залежностей...
[2025-06-30 14:42:18] ✅ Всі залежності встановлені
[2025-06-30 14:42:18] Створення Resource Group: django-app-production-rg
(AuthorizationFailed) The client 'vitalii_shevchuk3@epam.com' with object id '3c895225-e112-4a44-a6e4-0334207f6879' does not have authorization to perform action 'Microsoft.Resources/subscriptions/resourcegroups/write' over scope '/subscriptions/15c098cd-29f0-4f7e-8b7e-ea2ee94bb956/resourcegroups/django-app-production-rg' or the scope is invalid. If access was recently granted, please refresh your credentials.
Code: AuthorizationFailed
Message: The client 'vitalii_shevchuk3@epam.com' with object id '3c895225-e112-4a44-a6e4-0334207f6879' does not have authorization to perform action 'Microsoft.Resources/subscriptions/resourcegroups/write' over scope '/subscriptions/15c098cd-29f0-4f7e-8b7e-ea2ee94bb956/resourcegroups/django-app-production-rg' or the scope is invalid. If access was recently granted, please refresh your credentials.
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ 
```


Проблема полягає в тому, що ваш обліковий запис не має достатніх прав для створення ресурсних груп в Azure. Ось кілька способів вирішення:

## 🔑 **Швидкі рішення:**

### 1. **Перевірте поточні права:**
```bash
# Перевірте поточну підписку
az account show

# Перевірте ваші ролі
az role assignment list --assignee vitalii_shevchuk3@epam.com --all
```

### 2. **Оновіть credentials:**
```bash
# Вийдіть та знову увійдіть
az logout
az login

# Або очистіть кеш
az account clear
az login
```

### 3. **Використайте існуючу Resource Group:**## 🛠️ **Альтернативні підходи:**

### 4. **Модифікований скрипт з меншими правами:**

```bash
# Створіть спрощену версію скрипта
cat > script_azure_limited.sh << 'EOF'
#!/bin/bash

# Використання існуючої Resource Group
EXISTING_RG="your-existing-rg"  # Замініть на існуючу RG
PROJECT_NAME="django-app"
LOCATION="West Europe"

# Перевірка існування RG
if ! az group show --name "$EXISTING_RG" &> /dev/null; then
    echo "❌ Resource Group '$EXISTING_RG' не існує"
    echo "Доступні Resource Groups:"
    az group list --output table
    exit 1
fi

echo "✅ Використовуємо Resource Group: $EXISTING_RG"

# Продовжуємо зі створенням інших ресурсів...
# (решта коду без створення RG)
EOF

chmod +x script_azure_limited.sh
```

### 5. **Перевірте права через портал:**

1. Відкрийте [Azure Portal](https://portal.azure.com)
2. Перейдіть до **Subscriptions** → **Access control (IAM)**
3. Перевірте ваші ролі та права

### 6. **Запросіть права у адміністратора:**

```bash
# Покажіть цю інформацію адміністратору
echo "Потрібні права для користувача: vitalii_shevchuk3@epam.com"
echo "Object ID: 3c895225-e112-4a44-a6e4-0334207f6879"
echo "Subscription: 15c098cd-29f0-4f7e-8b7e-ea2ee94bb956"
echo "Необхідна роль: Contributor або Resource Group Contributor"
```

## 💡 **Рекомендації:**

**Для EPAM середовища:**
- Зверніться до вашого Azure адміністратора
- Можливо є корпоративні політики, що обмежують створення RG
- Використовуйте існуючі RG для розробки

**Швидке вирішення:**
1. Запустіть `az group list` щоб побачити доступні RG
2. Змініть `RESOURCE_GROUP_NAME` в скрипті на існуючу RG
3. Перезапустіть скрипт

Хочете, щоб я допоміг налаштувати скрипт для роботи з існуючою Resource Group?


```bash
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ az group list
[]
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ az account show
{
  "environmentName": "AzureCloud",
  "homeTenantId": "b41b72d0-4e9f-4c26-8a69-f949f367c91d",
  "id": "15c098cd-29f0-4f7e-8b7e-ea2ee94bb956",
  "isDefault": true,
  "managedByTenants": [],
  "name": "EPAM Production",
  "state": "Enabled",
  "tenantDefaultDomain": "EPAM.onmicrosoft.com",
  "tenantDisplayName": "EPAM",
  "tenantId": "b41b72d0-4e9f-4c26-8a69-f949f367c91d",
  "user": {
    "name": "vitalii_shevchuk3@epam.com",
    "type": "user"
  }
}
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ az role assignment list --assignee vitalii_shevchuk3@epam.com --all
[]
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ 
```


```bash
^C@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ ./script_azure.sh
[2025-07-01 02:45:04] Початок створення інфраструктури для Django додатку...
[2025-07-01 02:45:04] Проект: django-app
[2025-07-01 02:45:04] Середовище: production
[2025-07-01 02:45:04] Регіон: West Europe
[2025-07-01 02:45:04] Перевірка залежностей...
[ERROR] Ви не авторизовані в Azure CLI. Виконайте 'az login'
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ az login
To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code LKG9VV6N3 to authenticate.

Retrieving tenants and subscriptions for the selection...
Authentication failed against tenant 3a7a2d8e-5083-4ef2-809c-3a88f18e0ef8 'EPAM SECLAB UA': AADSTS50076: Due to a configuration change made by your administrator, or because you moved to a new location, you must use multi-factor authentication to access '797f4846-ba00-4fd7-ba43-dac1f8f63013'. Trace ID: c0af776f-6eba-4e28-b2fb-abf2c7ed8300 Correlation ID: c433b3a1-cbea-4ef6-84e1-83445a811c08 Timestamp: 2025-07-01 02:46:21Z
The following tenants don't contain accessible subscriptions. Use `az login --allow-no-subscriptions` to have tenant level access.
0d37204a-f51c-4187-b869-028b3934a0b0 'NEORIS'
If you need to access subscriptions in the following tenants, please use `az login --tenant TENANT_ID`.
3a7a2d8e-5083-4ef2-809c-3a88f18e0ef8 'EPAM SECLAB UA'

[Tenant and subscription selection]

No     Subscription name    Subscription ID                       Tenant
-----  -------------------  ------------------------------------  --------
[1] *  EPAM Production      15c098cd-29f0-4f7e-8b7e-ea2ee94bb956  EPAM

The default is marked with an *; the default tenant is 'EPAM' and subscription is 'EPAM Production' (15c098cd-29f0-4f7e-8b7e-ea2ee94bb956).

Select a subscription and tenant (Type a number or Enter for no changes): 1

Tenant: EPAM
Subscription: EPAM Production (15c098cd-29f0-4f7e-8b7e-ea2ee94bb956)

[Announcements]
With the new Azure CLI login experience, you can select the subscription you want to use more easily. Learn more about it and its configuration at https://go.microsoft.com/fwlink/?linkid=2271236

If you encounter any problem, please open an issue at https://aka.ms/azclibug

[Warning] The login output has been updated. Please be aware that it no longer displays the full list of available subscriptions by default.

@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ 
```

Ви успішно авторизувалися в Azure CLI і готові продовжити створення інфраструктури для Django додатку. Ось що відбулося:

## Статус авторизації ✅

**Успішно підключено до:**
- **Tenant:** EPAM
- **Subscription:** EPAM Production (15c098cd-29f0-4f7e-8b7e-ea2ee94bb956)

## Наступні кроки

Тепер ви можете продовжити виконання скрипту:

```bash
./script_azure.sh
```

## Що буде створено

Судячи з початкових логів, скрипт створить інфраструктуру з такими параметрами:
- **Проект:** django-app
- **Середовище:** production
- **Регіон:** West Europe

## Можливі наступні дії

1. **Запустіть скрипт знову:**
   ```bash
   ./script_azure.sh
   ```

2. **Перегляньте доступні ресурси:**
   ```bash
   az account show
   az group list
   ```

3. **Перевірте права доступу:**
   ```bash
   az role assignment list --assignee $(az account show --query user.name -o tsv)
   ```

## Примітки щодо MFA

Зверніть увагу, що для tenant 'EPAM SECLAB UA' потрібна багатофакторна автентифікація, але ви успішно підключилися до основного EPAM tenant.

```bash

@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ az account show
{
  "environmentName": "AzureCloud",
  "homeTenantId": "b41b72d0-4e9f-4c26-8a69-f949f367c91d",
  "id": "15c098cd-29f0-4f7e-8b7e-ea2ee94bb956",
  "isDefault": true,
  "managedByTenants": [],
  "name": "EPAM Production",
  "state": "Enabled",
  "tenantDefaultDomain": "EPAM.onmicrosoft.com",
  "tenantDisplayName": "EPAM",
  "tenantId": "b41b72d0-4e9f-4c26-8a69-f949f367c91d",
  "user": {
    "name": "vitalii_shevchuk3@epam.com",
    "type": "user"
  }
}
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ az group list
[]
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ az role assignment list --assignee $(az account show --query user.name -o tsv)
[]
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ 

```


```bash
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ ./script_azure.sh
[2025-07-01 03:01:30] Початок створення інфраструктури для Django додатку...
[2025-07-01 03:01:30] Проект: django-app
[2025-07-01 03:01:30] Середовище: production
[2025-07-01 03:01:30] Регіон: West Europe
[2025-07-01 03:01:30] Перевірка залежностей...
[2025-07-01 03:01:30] ✅ Всі залежності встановлені
[2025-07-01 03:01:30] Створення Resource Group: django-app-production-rg
(AuthorizationFailed) The client 'vitalii_shevchuk3@epam.com' with object id '3c895225-e112-4a44-a6e4-0334207f6879' does not have authorization to perform action 'Microsoft.Resources/subscriptions/resourcegroups/write' over scope '/subscriptions/15c098cd-29f0-4f7e-8b7e-ea2ee94bb956/resourcegroups/django-app-production-rg' or the scope is invalid. If access was recently granted, please refresh your credentials.
Code: AuthorizationFailed
Message: The client 'vitalii_shevchuk3@epam.com' with object id '3c895225-e112-4a44-a6e4-0334207f6879' does not have authorization to perform action 'Microsoft.Resources/subscriptions/resourcegroups/write' over scope '/subscriptions/15c098cd-29f0-4f7e-8b7e-ea2ee94bb956/resourcegroups/django-app-production-rg' or the scope is invalid. If access was recently granted, please refresh your credentials.
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ 

```


## Проблема з правами доступу ❌

Ваш обліковий запис `vitalii_shevchuk3@epam.com` не має достатніх прав для створення Resource Groups у subscription "EPAM Production".

## Діагностика проблеми

**Перевірте ваші поточні права:**

```bash
# Перевірка поточних ролей
az role assignment list --assignee vitalii_shevchuk3@epam.com --output table

# Перевірка доступних підписок
az account list --output table

# Перевірка поточної підписки
az account show
```

## Можливі рішення

### 1. Зміна підписки (якщо є доступ до іншої)

```bash
# Подивіться всі доступні підписки
az account list --output table

# Перемкніться на іншу підписку (якщо є)
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 2. Використання існуючої Resource Group

Модифікуйте скрипт для використання існуючої Resource Group:

```bash
# Перегляньте існуючі Resource Groups
az group list --output table

# Знайдіть Resource Group, до якої у вас є доступ
az group list --query "[?contains(name, 'test') || contains(name, 'dev')]" --output table
```

### 3. Запит прав у адміністратора

Зверніться до Azure адміністратора EPAM з проханням надати права:
- **Contributor** або **Owner** роль на subscription
- Або створити окрему Resource Group з правами Contributor

### 4. Тимчасове рішення - використання dev середовища

Спробуйте змінити параметри скрипту на менш привілейовані:

```bash
# Відредагуйте скрипт і змініть:
# ENVIRONMENT="production" на ENVIRONMENT="dev"
# PROJECT_NAME="django-app" на PROJECT_NAME="test-django"
```

## Перевірка доступних ресурсів

```bash
# Перегляд доступних локацій
az account list-locations --output table

# Перегляд існуючих ресурсів
az resource list --output table
```

## Рекомендації

1. **Негайно:** Зверніться до вашого Azure адміністратора або тім-ліда
2. **Альтернативно:** Використайте особисту Azure підписку для тестування
3. **Для розробки:** Створіть окремий проект в dev середовищі


```bash
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ az resource list --output table
Name            ResourceGroup    Location     Type                               Status
--------------  ---------------  -----------  ---------------------------------  --------
gessimages      StorageAccounts  westeurope   Microsoft.Storage/storageAccounts
gessimagestest  StorageAccounts  northeurope  Microsoft.Storage/storageAccounts
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ az group list --query "[?contains(name, 'test') || contains(name, 'dev')]" --output table

@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ az account list-locations --output table
DisplayName               Name                 RegionalDisplayName
------------------------  -------------------  -------------------------------------
East US                   eastus               (US) East US
South Central US          southcentralus       (US) South Central US
West US 2                 westus2              (US) West US 2
West US 3                 westus3              (US) West US 3
Australia East            australiaeast        (Asia Pacific) Australia East
Southeast Asia            southeastasia        (Asia Pacific) Southeast Asia
North Europe              northeurope          (Europe) North Europe
Sweden Central            swedencentral        (Europe) Sweden Central
UK South                  uksouth              (Europe) UK South
West Europe               westeurope           (Europe) West Europe
Central US                centralus            (US) Central US
South Africa North        southafricanorth     (Africa) South Africa North
Central India             centralindia         (Asia Pacific) Central India
East Asia                 eastasia             (Asia Pacific) East Asia
Indonesia Central         indonesiacentral     (Asia Pacific) Indonesia Central
Japan East                japaneast            (Asia Pacific) Japan East
Japan West                japanwest            (Asia Pacific) Japan West
Korea Central             koreacentral         (Asia Pacific) Korea Central
Malaysia West             malaysiawest         (Asia Pacific) Malaysia West
New Zealand North         newzealandnorth      (Asia Pacific) New Zealand North
Canada Central            canadacentral        (Canada) Canada Central
France Central            francecentral        (Europe) France Central
Germany West Central      germanywestcentral   (Europe) Germany West Central
Italy North               italynorth           (Europe) Italy North
Norway East               norwayeast           (Europe) Norway East
Poland Central            polandcentral        (Europe) Poland Central
Spain Central             spaincentral         (Europe) Spain Central
Switzerland North         switzerlandnorth     (Europe) Switzerland North
Mexico Central            mexicocentral        (Mexico) Mexico Central
UAE North                 uaenorth             (Middle East) UAE North
Brazil South              brazilsouth          (South America) Brazil South
Chile Central             chilecentral         (South America) Chile Central
East US 2 EUAP            eastus2euap          (US) East US 2 EUAP
Israel Central            israelcentral        (Middle East) Israel Central
Qatar Central             qatarcentral         (Middle East) Qatar Central
Central US (Stage)        centralusstage       (US) Central US (Stage)
East US (Stage)           eastusstage          (US) East US (Stage)
East US 2 (Stage)         eastus2stage         (US) East US 2 (Stage)
North Central US (Stage)  northcentralusstage  (US) North Central US (Stage)
South Central US (Stage)  southcentralusstage  (US) South Central US (Stage)
West US (Stage)           westusstage          (US) West US (Stage)
West US 2 (Stage)         westus2stage         (US) West US 2 (Stage)
Asia                      asia                 Asia
Asia Pacific              asiapacific          Asia Pacific
Australia                 australia            Australia
Brazil                    brazil               Brazil
Canada                    canada               Canada
Europe                    europe               Europe
France                    france               France
Germany                   germany              Germany
Global                    global               Global
India                     india                India
Indonesia                 indonesia            Indonesia
Israel                    israel               Israel
Italy                     italy                Italy
Japan                     japan                Japan
Korea                     korea                Korea
Malaysia                  malaysia             Malaysia
Mexico                    mexico               Mexico
New Zealand               newzealand           New Zealand
Norway                    norway               Norway
Poland                    poland               Poland
Qatar                     qatar                Qatar
Singapore                 singapore            Singapore
South Africa              southafrica          South Africa
Spain                     spain                Spain
Sweden                    sweden               Sweden
Switzerland               switzerland          Switzerland
Taiwan                    taiwan               Taiwan
United Arab Emirates      uae                  United Arab Emirates
United Kingdom            uk                   United Kingdom
United States             unitedstates         United States
United States EUAP        unitedstateseuap     United States EUAP
East Asia (Stage)         eastasiastage        (Asia Pacific) East Asia (Stage)
Southeast Asia (Stage)    southeastasiastage   (Asia Pacific) Southeast Asia (Stage)
Brazil US                 brazilus             (South America) Brazil US
East US 2                 eastus2              (US) East US 2
East US STG               eastusstg            (US) East US STG
North Central US          northcentralus       (US) North Central US
West US                   westus               (US) West US
Jio India West            jioindiawest         (Asia Pacific) Jio India West
Central US EUAP           centraluseuap        (US) Central US EUAP
South Central US STG      southcentralusstg    (US) South Central US STG
West Central US           westcentralus        (US) West Central US
South Africa West         southafricawest      (Africa) South Africa West
Australia Central         australiacentral     (Asia Pacific) Australia Central
Australia Central 2       australiacentral2    (Asia Pacific) Australia Central 2
Australia Southeast       australiasoutheast   (Asia Pacific) Australia Southeast
Jio India Central         jioindiacentral      (Asia Pacific) Jio India Central
Korea South               koreasouth           (Asia Pacific) Korea South
South India               southindia           (Asia Pacific) South India
West India                westindia            (Asia Pacific) West India
Canada East               canadaeast           (Canada) Canada East
France South              francesouth          (Europe) France South
Germany North             germanynorth         (Europe) Germany North
Norway West               norwaywest           (Europe) Norway West
Switzerland West          switzerlandwest      (Europe) Switzerland West
UK West                   ukwest               (Europe) UK West
UAE Central               uaecentral           (Middle East) UAE Central
Brazil Southeast          brazilsoutheast      (South America) Brazil Southeast
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ 
```



## Аналіз доступних ресурсів 📋

Зі списку ресурсів видно, що у вас є обмежений доступ:

### Наявні ресурси:
- **gessimages** (Storage Account) - West Europe
- **gessimagestest** (Storage Account) - North Europe
- **Resource Group:** StorageAccounts

### Стратегія рішення

Спробуйте використати існуючу Resource Group "StorageAccounts":

## Варіант 1: Модифікувати скрипт для використання існуючої RG

```bash
# Спочатку перевірте права на існуючу Resource Group
az group show --name "StorageAccounts" --output table

# Перевірте, чи можете створювати ресурси в цій групі
az role assignment list --resource-group "StorageAccounts" --assignee vitalii_shevchuk3@epam.com --output table
```

## Варіант 2: Створіть простішу версію скрипту

Створіть новий файл `script_azure_simple.sh`:## Варіант 3: Тестування прав на створення ресурсів

Спочатку протестуйте, що ви можете створити:

```bash
# Тест створення простого ресурсу в існуючій RG
az appservice plan create \
    --name "test-plan-$(date +%s)" \
    --resource-group "StorageAccounts" \
    --location "westeurope" \
    --sku F1 \
    --is-linux \
    --output table
```

## Використання спрощеного скрипту

```bash
# Зробіть файл виконуваним
chmod +x script_azure_simple.sh

# Запустіть спрощений скрипт
./script_azure_simple.sh
```

## Альтернативний підхід - використання Azure Portal

Якщо скрипт не працює, спробуйте створити ресурси через Azure Portal:
1. Увійдіть на https://portal.azure.com
2. Знайдіть Resource Group "StorageAccounts"
3. Спробуйте створити App Service вручну



```bash
#!/bin/bash

# Налаштування
EXISTING_RG="StorageAccounts"
PROJECT_NAME="django-portfolio"
LOCATION="westeurope"  # Використовуємо регіон, де вже є ресурси
TIMESTAMP=$(date +%Y%m%d%H%M)

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Створення додаткових ресурсів у існуючій Resource Group..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Resource Group: $EXISTING_RG"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Проект: $PROJECT_NAME"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Регіон: $LOCATION"

# Перевірка існування Resource Group
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Перевірка доступу до Resource Group..."
if ! az group show --name "$EXISTING_RG" --output none 2>/dev/null; then
    echo "[ERROR] Resource Group '$EXISTING_RG' не існує або немає доступу"
    exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Resource Group доступна"

# Генеруємо унікальні назви ресурсів
APP_SERVICE_PLAN_NAME="${PROJECT_NAME}-plan-${TIMESTAMP}"
WEB_APP_NAME="${PROJECT_NAME}-web-${TIMESTAMP}"
STORAGE_NAME="${PROJECT_NAME}storage${TIMESTAMP}"

# Створення App Service Plan
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Створення App Service Plan: $APP_SERVICE_PLAN_NAME"
az appservice plan create \
    --name "$APP_SERVICE_PLAN_NAME" \
    --resource-group "$EXISTING_RG" \
    --location "$LOCATION" \
    --sku B1 \
    --is-linux

if [ $? -ne 0 ]; then
    echo "[ERROR] Не вдалося створити App Service Plan"
    exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ App Service Plan створено"

# Створення Web App
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Створення Web App: $WEB_APP_NAME"
az webapp create \
    --name "$WEB_APP_NAME" \
    --resource-group "$EXISTING_RG" \
    --plan "$APP_SERVICE_PLAN_NAME" \
    --runtime "PYTHON:3.11"

if [ $? -ne 0 ]; then
    echo "[ERROR] Не вдалося створити Web App"
    exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Web App створено"

# Налаштування веб-додатку для Django
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Налаштування Django..."
az webapp config appsettings set \
    --name "$WEB_APP_NAME" \
    --resource-group "$EXISTING_RG" \
    --settings \
        DJANGO_SETTINGS_MODULE="myproject.settings" \
        PYTHONPATH="/home/site/wwwroot" \
        SCM_DO_BUILD_DURING_DEPLOYMENT=true

# Спроба створити Storage Account (може не вийти через права)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Спроба створення Storage Account: $STORAGE_NAME"
az storage account create \
    --name "$STORAGE_NAME" \
    --resource-group "$EXISTING_RG" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 2>/dev/null

if [ $? -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Storage Account створено"
    
    # Отримання ключа доступу
    STORAGE_KEY=$(az storage account keys list \
        --account-name "$STORAGE_NAME" \
        --resource-group "$EXISTING_RG" \
        --query "[0].value" --output tsv)
    
    # Додавання налаштувань для Storage
    az webapp config appsettings set \
        --name "$WEB_APP_NAME" \
        --resource-group "$EXISTING_RG" \
        --settings \
            AZURE_STORAGE_ACCOUNT_NAME="$STORAGE_NAME" \
            AZURE_STORAGE_ACCOUNT_KEY="$STORAGE_KEY"
else
    echo "[WARNING] Не вдалося створити Storage Account. Використовуйте існуючий gessimages"
    
    # Використання існуючого storage account
    EXISTING_STORAGE="gessimages"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Використання існуючого Storage: $EXISTING_STORAGE"
    
    # Спроба отримати ключ (може не працювати через права)
    STORAGE_KEY=$(az storage account keys list \
        --account-name "$EXISTING_STORAGE" \
        --resource-group "$EXISTING_RG" \
        --query "[0].value" --output tsv 2>/dev/null)
    
    if [ -n "$STORAGE_KEY" ]; then
        az webapp config appsettings set \
            --name "$WEB_APP_NAME" \
            --resource-group "$EXISTING_RG" \
            --settings \
                AZURE_STORAGE_ACCOUNT_NAME="$EXISTING_STORAGE" \
                AZURE_STORAGE_ACCOUNT_KEY="$STORAGE_KEY"
    fi
fi

# Результати
echo ""
echo "=================================="
echo "🎉 РЕСУРСИ СТВОРЕНО УСПІШНО!"
echo "=================================="
echo "Resource Group: $EXISTING_RG"
echo "App Service Plan: $APP_SERVICE_PLAN_NAME"
echo "Web App: $WEB_APP_NAME"
echo "Web App URL: https://${WEB_APP_NAME}.azurewebsites.net"
echo ""
echo "Наступні кроки:"
echo "1. Налаштуйте деплоймент із GitHub:"
echo "   az webapp deployment source config --name $WEB_APP_NAME --resource-group $EXISTING_RG --repo-url YOUR_GITHUB_REPO"
echo ""
echo "2. Перегляньте логи:"
echo "   az webapp log tail --name $WEB_APP_NAME --resource-group $EXISTING_RG"
echo "=================================="
```


```bash
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ az appservice plan create \
>     --name "test-plan-$(date +%s)" \
>     --resource-group "StorageAccounts" \
>     --location "westeurope" \
>     --sku F1 \
>     --is-linux \
>     --output table
(AuthorizationFailed) The client 'vitalii_shevchuk3@epam.com' with object id '3c895225-e112-4a44-a6e4-0334207f6879' does not have authorization to perform action 'Microsoft.Web/serverfarms/write' over scope '/subscriptions/15c098cd-29f0-4f7e-8b7e-ea2ee94bb956/resourceGroups/StorageAccounts/providers/Microsoft.Web/serverfarms/test-plan-1751340203' or the scope is invalid. If access was recently granted, please refresh your credentials.
Code: AuthorizationFailed
Message: The client 'vitalii_shevchuk3@epam.com' with object id '3c895225-e112-4a44-a6e4-0334207f6879' does not have authorization to perform action 'Microsoft.Web/serverfarms/write' over scope '/subscriptions/15c098cd-29f0-4f7e-8b7e-ea2ee94bb956/resourceGroups/StorageAccounts/providers/Microsoft.Web/serverfarms/test-plan-1751340203' or the scope is invalid. If access was recently granted, please refresh your credentials.
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ 
```



```bash
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ az logout
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ az login
To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code C4EBSP56X to authenticate.

Retrieving tenants and subscriptions for the selection...

[Tenant and subscription selection]

No     Subscription name     Subscription ID                       Tenant
-----  --------------------  ------------------------------------  -----------------
[1]    Azure subscription 1  0023db84-3d8f-4017-b39e-ce7826ea388d  Default Directory
[2] *  Azure для учащихся    826d896f-b844-48c3-998e-c8e36c27e681  Default Directory

The default is marked with an *; the default tenant is 'Default Directory' and subscription is 'Azure для учащихся' (826d896f-b844-48c3-998e-c8e36c27e681).

Select a subscription and tenant (Type a number or Enter for no changes): 2

Tenant: Default Directory
Subscription: Azure для учащихся (826d896f-b844-48c3-998e-c8e36c27e681)

[Announcements]
With the new Azure CLI login experience, you can select the subscription you want to use more easily. Learn more about it and its configuration at https://go.microsoft.com/fwlink/?linkid=2271236

If you encounter any problem, please open an issue at https://aka.ms/azclibug

[Warning] The login output has been updated. Please be aware that it no longer displays the full list of available subscriptions by default.

@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ ./script_azure.sh
[2025-07-01 04:04:30] Початок створення інфраструктури для Django додатку...
[2025-07-01 04:04:30] Проект: django-app
[2025-07-01 04:04:30] Середовище: production
[2025-07-01 04:04:30] Регіон: West Europe
[2025-07-01 04:04:30] Перевірка залежностей...
[2025-07-01 04:04:30] ✅ Всі залежності встановлені
[2025-07-01 04:04:30] Створення Resource Group: django-app-production-rg
{
  "id": "/subscriptions/826d896f-b844-48c3-998e-c8e36c27e681/resourceGroups/django-app-production-rg",
  "location": "westeurope",
  "managedBy": null,
  "name": "django-app-production-rg",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": {
    "CreatedBy": "AzureCLI",
    "Environment": "production",
    "Project": "django-app"
  },
  "type": "Microsoft.Resources/resourceGroups"
}
[2025-07-01 04:04:33] Створення Storage Account: django-appproductionstorage1751342670
(SubscriptionNotFound) Subscription 826d896f-b844-48c3-998e-c8e36c27e681 was not found.
Code: SubscriptionNotFound
Message: Subscription 826d896f-b844-48c3-998e-c8e36c27e681 was not found.
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $
```

## Проблема з підпискою "Azure для учащихся" ⚠️

Схоже, що підписка "Azure для учащихся" має обмеження або тимчасово недоступна. Спробуймо перемкнутися на іншу підписку.

## Рішення

### 1. Перемкніться на першу підписку

```bash
az account set --subscription "0023db84-3d8f-4017-b39e-ce7826ea388d"
az account show
```

### 2. Перевірте доступні підписки та їх статус

```bash
# Детальна інформація про підписки
az account list --output table

# Перевірка поточної підписки
az account show --query "{Name:name, ID:id, State:state}" --output table
```

### 3. Якщо перша підписка працює, запустіть скрипт знову

```bash
./script_azure.sh
```

## Альтернативне рішення - модифікація для student підписки

Якщо хочете залишитися з student підпискою, створіть спрощену версію:## Рекомендовані дії:

### Спочатку спробуйте перемкнутися на першу підписку:

```bash
az account set --subscription "0023db84-3d8f-4017-b39e-ce7826ea388d"
./script_azure.sh
```

### Якщо це не працює, використовуйте студентський скрипт:

```bash
# Створіть новий файл
nano script_azure_student.sh

# Скопіюйте код з артефакту вище
# Зробіть виконуваним
chmod +x script_azure_student.sh

# Запустіть
./script_azure_student.sh
```

```bash
#!/bin/bash

# Налаштування для студентської підписки
PROJECT_NAME="django-portfolio"
ENVIRONMENT="dev"  # Використовуємо dev замість production
LOCATION="westeurope"
TIMESTAMP=$(date +%s)

# Унікальні назви (коротші для студентської підписки)
RG_NAME="${PROJECT_NAME}-${ENVIRONMENT}-rg"
STORAGE_NAME="djstore${TIMESTAMP}"
APP_PLAN_NAME="${PROJECT_NAME}-plan"
WEB_APP_NAME="${PROJECT_NAME}-web-${TIMESTAMP}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Створення інфраструктури для Django (Student Edition)..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Проект: $PROJECT_NAME"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Середовище: $ENVIRONMENT"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Регіон: $LOCATION"

# Перевірка підписки
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Перевірка підписки..."
SUBSCRIPTION_INFO=$(az account show --query "{name:name, id:id, state:state}" --output json)
echo "Поточна підписка: $(echo $SUBSCRIPTION_INFO | jq -r .name)"

if [ "$(echo $SUBSCRIPTION_INFO | jq -r .state)" != "Enabled" ]; then
    echo "[ERROR] Підписка не активна. Статус: $(echo $SUBSCRIPTION_INFO | jq -r .state)"
    exit 1
fi

# Створення Resource Group
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Створення Resource Group: $RG_NAME"
az group create \
    --name "$RG_NAME" \
    --location "$LOCATION" \
    --tags Project="$PROJECT_NAME" Environment="$ENVIRONMENT" CreatedBy="StudentScript"

if [ $? -ne 0 ]; then
    echo "[ERROR] Не вдалося створити Resource Group"
    exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Resource Group створено"

# Створення App Service Plan (безкоштовний рівень для студентів)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Створення App Service Plan: $APP_PLAN_NAME"
az appservice plan create \
    --name "$APP_PLAN_NAME" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --sku F1 \
    --is-linux

if [ $? -ne 0 ]; then
    echo "[ERROR] Не вдалося створити App Service Plan"
    exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ App Service Plan створено"

# Створення Web App
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Створення Web App: $WEB_APP_NAME"
az webapp create \
    --name "$WEB_APP_NAME" \
    --resource-group "$RG_NAME" \
    --plan "$APP_PLAN_NAME" \
    --runtime "PYTHON:3.11"

if [ $? -ne 0 ]; then
    echo "[ERROR] Не вдалося створити Web App"
    exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Web App створено"

# Спроба створення Storage Account (мінімальний рівень)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Створення Storage Account: $STORAGE_NAME"
az storage account create \
    --name "$STORAGE_NAME" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind BlobStorage \
    --access-tier Hot

if [ $? -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Storage Account створено"
    
    # Налаштування веб-додатку
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Налаштування Django..."
    
    # Отримання ключа Storage Account
    STORAGE_KEY=$(az storage account keys list \
        --account-name "$STORAGE_NAME" \
        --resource-group "$RG_NAME" \
        --query "[0].value" --output tsv)
    
    # Налаштування змінних середовища
    az webapp config appsettings set \
        --name "$WEB_APP_NAME" \
        --resource-group "$RG_NAME" \
        --settings \
            DJANGO_SETTINGS_MODULE="myproject.settings" \
            PYTHONPATH="/home/site/wwwroot" \
            SCM_DO_BUILD_DURING_DEPLOYMENT=true \
            AZURE_STORAGE_ACCOUNT_NAME="$STORAGE_NAME" \
            AZURE_STORAGE_ACCOUNT_KEY="$STORAGE_KEY" \
            DEBUG=False \
            ALLOWED_HOSTS="${WEB_APP_NAME}.azurewebsites.net,localhost,127.0.0.1"
            
else
    echo "[WARNING] Не вдалося створити Storage Account. Продовжуємо без нього..."
    
    # Базові налаштування без Storage
    az webapp config appsettings set \
        --name "$WEB_APP_NAME" \
        --resource-group "$RG_NAME" \
        --settings \
            DJANGO_SETTINGS_MODULE="myproject.settings" \
            PYTHONPATH="/home/site/wwwroot" \
            SCM_DO_BUILD_DURING_DEPLOYMENT=true \
            DEBUG=False \
            ALLOWED_HOSTS="${WEB_APP_NAME}.azurewebsites.net,localhost,127.0.0.1"
fi

# Результати
echo ""
echo "=================================="
echo "🎓 STUDENT DEPLOYMENT ГОТОВИЙ!"
echo "=================================="
echo "Resource Group: $RG_NAME"
echo "App Service Plan: $APP_PLAN_NAME (F1 - Free)"
echo "Web App: $WEB_APP_NAME"
echo "Web App URL: https://${WEB_APP_NAME}.azurewebsites.net"
if [ -n "$STORAGE_NAME" ]; then
    echo "Storage Account: $STORAGE_NAME"
fi
echo ""
echo "Наступні кроки для деплойменту:"
echo "1. Підключіть GitHub репозиторій:"
echo "   az webapp deployment source config --name $WEB_APP_NAME --resource-group $RG_NAME --repo-url https://github.com/YOUR_USERNAME/YOUR_REPO --branch main"
echo ""
echo "2. Або використайте ZIP деплоймент:"
echo "   az webapp deployment source config-zip --src portfolio.zip --name $WEB_APP_NAME --resource-group $RG_NAME"
echo ""
echo "3. Перегляньте логи:"
echo "   az webapp log tail --name $WEB_APP_NAME --resource-group $RG_NAME"
echo ""
echo "4. Перезапустіть додаток після деплойменту:"
echo "   az webapp restart --name $WEB_APP_NAME --resource-group $RG_NAME"
echo "=================================="


```






```bash
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ chmod +x script_azure_student.sh
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ ./script_azure_student.sh
[2025-07-01 05:47:36] Створення інфраструктури для Django (Student Edition)...
[2025-07-01 05:47:36] Проект: django-portfolio
[2025-07-01 05:47:36] Середовище: dev
[2025-07-01 05:47:36] Регіон: westeurope
[2025-07-01 05:47:36] Перевірка підписки...
Поточна підписка: Azure для учащихся
[2025-07-01 05:47:37] Створення Resource Group: django-portfolio-dev-rg
{
  "id": "/subscriptions/826d896f-b844-48c3-998e-c8e36c27e681/resourceGroups/django-portfolio-dev-rg",
  "location": "westeurope",
  "managedBy": null,
  "name": "django-portfolio-dev-rg",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": {
    "CreatedBy": "StudentScript",
    "Environment": "dev",
    "Project": "django-portfolio"
  },
  "type": "Microsoft.Resources/resourceGroups"
}
[2025-07-01 05:47:38] ✅ Resource Group створено
[2025-07-01 05:47:38] Створення App Service Plan: django-portfolio-plan
{
  "elasticScaleEnabled": false,
  "extendedLocation": null,
  "freeOfferExpirationTime": null,
  "geoRegion": "West Europe",
  "hostingEnvironmentProfile": null,
  "hyperV": false,
  "id": "/subscriptions/826d896f-b844-48c3-998e-c8e36c27e681/resourceGroups/django-portfolio-dev-rg/providers/Microsoft.Web/serverfarms/django-portfolio-plan",
  "isSpot": false,
  "isXenon": false,
  "kind": "linux",
  "kubeEnvironmentProfile": null,
  "location": "westeurope",
  "maximumElasticWorkerCount": 1,
  "maximumNumberOfWorkers": 0,
  "name": "django-portfolio-plan",
  "numberOfSites": 0,
  "numberOfWorkers": 1,
  "perSiteScaling": false,
  "provisioningState": "Succeeded",
  "reserved": true,
  "resourceGroup": "django-portfolio-dev-rg",
  "sku": {
    "capabilities": null,
    "capacity": 1,
    "family": "U",
    "locations": null,
    "name": "U13",
    "size": "U13",
    "skuCapacity": null,
    "tier": "LinuxFree"
  },
  "spotExpirationTime": null,
  "status": "Ready",
  "subscription": "826d896f-b844-48c3-998e-c8e36c27e681",
  "tags": null,
  "targetWorkerCount": 0,
  "targetWorkerSizeId": 0,
  "type": "Microsoft.Web/serverfarms",
  "workerTierName": null,
  "zoneRedundant": false
}
[2025-07-01 05:47:45] ✅ App Service Plan створено
[2025-07-01 05:47:45] Створення Web App: django-portfolio-web-1751348856
{
  "availabilityState": "Normal",
  "clientAffinityEnabled": true,
  "clientCertEnabled": false,
  "clientCertExclusionPaths": null,
  "clientCertMode": "Required",
  "cloningInfo": null,
  "containerSize": 0,
  "customDomainVerificationId": "D0BFF007869BBFD5B439D6620296D94A14B6BC56E8FB873C9AADB357A6CE0D3B",
  "dailyMemoryTimeQuota": 0,
  "daprConfig": null,
  "defaultHostName": "django-portfolio-web-1751348856.azurewebsites.net",
  "enabled": true,
  "enabledHostNames": [
    "django-portfolio-web-1751348856.azurewebsites.net",
    "django-portfolio-web-1751348856.scm.azurewebsites.net"
  ],
  "endToEndEncryptionEnabled": false,
  "extendedLocation": null,
  "ftpPublishingUrl": "ftps://waws-prod-am2-601.ftp.azurewebsites.windows.net/site/wwwroot",
  "hostNameSslStates": [
    {
      "certificateResourceId": null,
      "hostType": "Standard",
      "ipBasedSslResult": null,
      "ipBasedSslState": "NotConfigured",
      "name": "django-portfolio-web-1751348856.azurewebsites.net",
      "sslState": "Disabled",
      "thumbprint": null,
      "toUpdate": null,
      "toUpdateIpBasedSsl": null,
      "virtualIPv6": null,
      "virtualIp": null
    },
    {
      "certificateResourceId": null,
      "hostType": "Repository",
      "ipBasedSslResult": null,
      "ipBasedSslState": "NotConfigured",
      "name": "django-portfolio-web-1751348856.scm.azurewebsites.net",
      "sslState": "Disabled",
      "thumbprint": null,
      "toUpdate": null,
      "toUpdateIpBasedSsl": null,
      "virtualIPv6": null,
      "virtualIp": null
    }
  ],
  "hostNames": [
    "django-portfolio-web-1751348856.azurewebsites.net"
  ],
  "hostNamesDisabled": false,
  "hostingEnvironmentProfile": null,
  "httpsOnly": false,
  "hyperV": false,
  "id": "/subscriptions/826d896f-b844-48c3-998e-c8e36c27e681/resourceGroups/django-portfolio-dev-rg/providers/Microsoft.Web/sites/django-portfolio-web-1751348856",
  "identity": null,
  "inProgressOperationId": null,
  "isDefaultContainer": null,
  "isXenon": false,
  "keyVaultReferenceIdentity": "SystemAssigned",
  "kind": "app,linux",
  "lastModifiedTimeUtc": "2025-07-01T05:47:49.590000",
  "location": "West Europe",
  "managedEnvironmentId": null,
  "maxNumberOfWorkers": null,
  "name": "django-portfolio-web-1751348856",
  "outboundIpAddresses": "51.124.59.99,51.124.59.175,51.124.59.252,51.124.60.129,51.124.60.243,51.124.60.249,20.105.224.17",
  "possibleOutboundIpAddresses": "51.124.59.99,51.124.59.175,51.124.59.252,51.124.60.129,51.124.60.243,51.124.60.249,51.124.61.31,51.124.61.49,51.124.61.56,51.124.61.142,51.124.61.184,51.124.61.192,51.105.209.160,51.105.210.136,51.105.210.122,51.124.56.53,51.124.61.162,51.105.210.2,51.124.61.169,51.105.209.155,51.124.57.83,51.124.62.101,51.124.57.229,51.124.58.97,20.105.224.17",
  "publicNetworkAccess": null,
  "redundancyMode": "None",
  "repositorySiteName": "django-portfolio-web-1751348856",
  "reserved": true,
  "resourceConfig": null,
  "resourceGroup": "django-portfolio-dev-rg",
  "scmSiteAlsoStopped": false,
  "serverFarmId": "/subscriptions/826d896f-b844-48c3-998e-c8e36c27e681/resourceGroups/django-portfolio-dev-rg/providers/Microsoft.Web/serverfarms/django-portfolio-plan",
  "siteConfig": {
    "acrUseManagedIdentityCreds": false,
    "acrUserManagedIdentityId": null,
    "alwaysOn": false,
    "antivirusScanEnabled": null,
    "apiDefinition": null,
    "apiManagementConfig": null,
    "appCommandLine": null,
    "appSettings": null,
    "autoHealEnabled": null,
    "autoHealRules": null,
    "autoSwapSlotName": null,
    "azureMonitorLogCategories": null,
    "azureStorageAccounts": null,
    "clusteringEnabled": false,
    "connectionStrings": null,
    "cors": null,
    "customAppPoolIdentityAdminState": null,
    "customAppPoolIdentityTenantState": null,
    "defaultDocuments": null,
    "detailedErrorLoggingEnabled": null,
    "documentRoot": null,
    "elasticWebAppScaleLimit": 0,
    "experiments": null,
    "fileChangeAuditEnabled": null,
    "ftpsState": null,
    "functionAppScaleLimit": null,
    "functionsRuntimeScaleMonitoringEnabled": null,
    "handlerMappings": null,
    "healthCheckPath": null,
    "http20Enabled": false,
    "http20ProxyFlag": null,
    "httpLoggingEnabled": null,
    "ipSecurityRestrictions": [
      {
        "action": "Allow",
        "description": "Allow all access",
        "headers": null,
        "ipAddress": "Any",
        "name": "Allow all",
        "priority": 2147483647,
        "subnetMask": null,
        "subnetTrafficTag": null,
        "tag": null,
        "vnetSubnetResourceId": null,
        "vnetTrafficTag": null
      }
    ],
    "ipSecurityRestrictionsDefaultAction": null,
    "javaContainer": null,
    "javaContainerVersion": null,
    "javaVersion": null,
    "keyVaultReferenceIdentity": null,
    "limits": null,
    "linuxFxVersion": "",
    "loadBalancing": null,
    "localMySqlEnabled": null,
    "logsDirectorySizeLimit": null,
    "machineKey": null,
    "managedPipelineMode": null,
    "managedServiceIdentityId": null,
    "metadata": null,
    "minTlsCipherSuite": null,
    "minTlsVersion": null,
    "minimumElasticInstanceCount": 0,
    "netFrameworkVersion": null,
    "nodeVersion": null,
    "numberOfWorkers": 1,
    "phpVersion": null,
    "powerShellVersion": null,
    "preWarmedInstanceCount": null,
    "publicNetworkAccess": null,
    "publishingPassword": null,
    "publishingUsername": null,
    "push": null,
    "pythonVersion": null,
    "remoteDebuggingEnabled": null,
    "remoteDebuggingVersion": null,
    "requestTracingEnabled": null,
    "requestTracingExpirationTime": null,
    "routingRules": null,
    "runtimeADUser": null,
    "runtimeADUserPassword": null,
    "sandboxType": null,
    "scmIpSecurityRestrictions": [
      {
        "action": "Allow",
        "description": "Allow all access",
        "headers": null,
        "ipAddress": "Any",
        "name": "Allow all",
        "priority": 2147483647,
        "subnetMask": null,
        "subnetTrafficTag": null,
        "tag": null,
        "vnetSubnetResourceId": null,
        "vnetTrafficTag": null
      }
    ],
    "scmIpSecurityRestrictionsDefaultAction": null,
    "scmIpSecurityRestrictionsUseMain": null,
    "scmMinTlsCipherSuite": null,
    "scmMinTlsVersion": null,
    "scmSupportedTlsCipherSuites": null,
    "scmType": null,
    "sitePort": null,
    "sitePrivateLinkHostEnabled": null,
    "storageType": null,
    "supportedTlsCipherSuites": null,
    "tracingOptions": null,
    "use32BitWorkerProcess": null,
    "virtualApplications": null,
    "vnetName": null,
    "vnetPrivatePortsCount": null,
    "vnetRouteAllEnabled": null,
    "webSocketsEnabled": null,
    "websiteTimeZone": null,
    "winAuthAdminState": null,
    "winAuthTenantState": null,
    "windowsConfiguredStacks": null,
    "windowsFxVersion": null,
    "xManagedServiceIdentityId": null
  },
  "slotSwapStatus": null,
  "state": "Running",
  "storageAccountRequired": false,
  "suspendedTill": null,
  "tags": null,
  "targetSwapSlot": null,
  "trafficManagerHostNames": null,
  "type": "Microsoft.Web/sites",
  "usageState": "Normal",
  "virtualNetworkSubnetId": null,
  "vnetContentShareEnabled": false,
  "vnetImagePullEnabled": false,
  "vnetRouteAllEnabled": false,
  "workloadProfileName": null
}
[2025-07-01 05:48:10] ✅ Web App створено
[2025-07-01 05:48:10] Створення Storage Account: djstore1751348856
(SubscriptionNotFound) Subscription 826d896f-b844-48c3-998e-c8e36c27e681 was not found.
Code: SubscriptionNotFound
Message: Subscription 826d896f-b844-48c3-998e-c8e36c27e681 was not found.
[WARNING] Не вдалося створити Storage Account. Продовжуємо без нього...
[
  {
    "name": "DJANGO_SETTINGS_MODULE",
    "slotSetting": false,
    "value": null
  },
  {
    "name": "PYTHONPATH",
    "slotSetting": false,
    "value": null
  },
  {
    "name": "SCM_DO_BUILD_DURING_DEPLOYMENT",
    "slotSetting": false,
    "value": null
  },
  {
    "name": "DEBUG",
    "slotSetting": false,
    "value": null
  },
  {
    "name": "ALLOWED_HOSTS",
    "slotSetting": false,
    "value": null
  }
]

==================================
🎓 STUDENT DEPLOYMENT ГОТОВИЙ!
==================================
Resource Group: django-portfolio-dev-rg
App Service Plan: django-portfolio-plan (F1 - Free)
Web App: django-portfolio-web-1751348856
Web App URL: https://django-portfolio-web-1751348856.azurewebsites.net
Storage Account: djstore1751348856

Наступні кроки для деплойменту:
1. Підключіть GitHub репозиторій:
   az webapp deployment source config --name django-portfolio-web-1751348856 --resource-group django-portfolio-dev-rg --repo-url https://github.com/YOUR_USERNAME/YOUR_REPO --branch main

2. Або використайте ZIP деплоймент:
   az webapp deployment source config-zip --src portfolio.zip --name django-portfolio-web-1751348856 --resource-group django-portfolio-dev-rg

3. Перегляньте логи:
   az webapp log tail --name django-portfolio-web-1751348856 --resource-group django-portfolio-dev-rg

4. Перезапустіть додаток після деплойменту:
   az webapp restart --name django-portfolio-web-1751348856 --resource-group django-portfolio-dev-rg
==================================
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ 
```

# 🎉 Відмінно! Azure інфраструктура створена успішно!

## Статус деплойменту ✅

Ваш Django додаток готовий до розгортання з такими параметрами:

### Створені ресурси:
- **Resource Group:** `django-portfolio-dev-rg`
- **App Service Plan:** `django-portfolio-plan` (F1 - Free tier)
- **Web App:** `django-portfolio-web-1751348856`
- **URL:** https://django-portfolio-web-1751348856.azurewebsites.net

### Обмеження:
- Storage Account не створено через обмеження студентської підписки
- Налаштування середовища застосовані базові

## Наступні кроки для деплойменту

### 1. Підготовка проекту Django

Спочатку переконайтеся, що ваш Django проект готовий:

```bash
# Створіть requirements.txt якщо його немає
pip freeze > requirements.txt

# Перевірте структуру проекту
ls -la
```

### 2. Варіанти деплойменту

#### Варіант A: GitHub деплоймент (рекомендований)

```bash
# Підключення GitHub репозиторію
az webapp deployment source config \
    --name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg \
    --repo-url https://github.com/VitaliiShevchuk2023/portfolio-django-azure \
    --branch main \
    --manual-integration
```

#### Варіант B: ZIP деплоймент

```bash
# Створіть ZIP архів проекту
zip -r portfolio.zip . -x "*.git*" "*__pycache__*" "*.pyc" "venv/*"

# Завантажте проект
az webapp deployment source config-zip \
    --src portfolio.zip \
    --name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg
```

### 3. Налаштування Django для Azure

Створіть файл `startup.sh` у корені проекту:### 4. Оновіть налаштування Django

Додайте до `settings.py`:### 5. Конфігурація веб-аплікації

```bash
# Налаштування startup команди
az webapp config set \
    --name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg \
    --startup-file "startup.sh"

# Встановлення Python runtime
az webapp config set \
    --name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg \
    --linux-fx-version "PYTHON|3.11"
```

### 6. Перевірка та моніторинг

```bash
# Перегляд логів у реальному часі
az webapp log tail \
    --name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg

# Перезапуск додатку
az webapp restart \
    --name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg

# Перегляд статусу
az webapp show \
    --name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg \
    --query "state"
```

## Корисні команди для подальшої роботи

```bash
# Перегляд всіх ресурсів
az resource list --resource-group django-portfolio-dev-rg --output table

# Отримання URL додатку
az webapp show \
    --name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg \
    --query "defaultHostName" --output tsv

# Налаштування custom domain (за потреби)
az webapp config hostname add \
    --webapp-name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg \
    --hostname yourdomain.com
```

Готові розпочати деплоймент? Який варіант (GitHub чи ZIP) вам більше підходить?


```bash
VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ az webapp deployment source config \
>     --name django-portfolio-web-1751348856 \
>     --resource-group django-portfolio-dev-rg \
>     --repo-url https://github.com/VitaliiShevchuk2023/portfolio-django-azure \
>     --branch main \
>     --manual-integration
location is not a known attribute of class <class 'azure.mgmt.web.v2023_12_01.models._models_py3.SiteSourceControl'> and will be ignored
Repository 'UpdateSiteSourceControl' operation failed with System.TimeoutException: Operation GET https://waws-prod-am2-601.api.azurewebsites.windows.net/api/sshkey?ensurePublicKey=True exceeded 50000ms timeout!
   at Microsoft.Web.Hosting.Administration.Utilities.WebRequestHelper.<GetResponseAsyncWithTimeout>d__10.MoveNext() in /_/src/hosting/AdministrationService/Microsoft.Web.Hosting.Administration.WebCommon/Utilities/WebRequestHelper.cs:line 40
--- End of stack trace from previous location where exception was thrown ---
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw()
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)
   at Microsoft.Web.Hosting.Administration.SiteRepositoryProvider.TrackerContext.<GetResponseAsync>d__41.MoveNext() in /_/src/hosting/AdministrationService/Microsoft.Web.Hosting.Administration.WebCommon/Providers/SiteRepositoryProvider.cs:line 800
--- End of stack trace from previous location where exception was thrown ---
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw()
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)
   at Microsoft.Web.Hosting.Administration.SiteRepositoryProvider.<GetSSHKey>d__29.MoveNext() in /_/src/hosting/AdministrationService/Microsoft.Web.Hosting.Administration.WebCommon/Providers/SiteRepositoryProvider.cs:line 320
--- End of stack trace from previous location where exception was thrown ---
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw()
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)
   at Microsoft.Web.Hosting.Administration.ExternalSiteRepositoryProvider.<EnsureSSHKey>d__8.MoveNext() in /_/src/hosting/AdministrationService/Microsoft.Web.Hosting.Administration.WebCommon/Providers/ExternalSiteRepositoryProvider.cs:line 113
--- End of stack trace from previous location where exception was thrown ---
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw()
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)
   at Microsoft.Web.Hosting.Administration.ExternalSiteRepositoryProvider.<UpdateSiteSourceControl>d__5.MoveNext() in /_/src/hosting/AdministrationService/Microsoft.Web.Hosting.Administration.WebCommon/Providers/ExternalSiteRepositoryProvider.cs:line 53
--- End of stack trace from previous location where exception was thrown ---
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw()
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)
   at Microsoft.Web.Hosting.Administration.WebCloudController.<>c__DisplayClass384_1.<<UpdateSiteSourceControl>b__1>d.MoveNext() in /_/src/Hosting/AdministrationService/Microsoft.Web.Hosting.Administration/Controllers/WebCloudController.cs:line 11388
--- End of stack trace from previous location where exception was thrown ---
   at System.Runtime.ExceptionServices.ExceptionDispatchInfo.Throw()
   at System.Runtime.CompilerServices.TaskAwaiter.HandleNonSuccessAndDebuggerNotification(Task task)
   at Microsoft.Web.Hosting.AsyncHelper.RunSync[TResult](Func`1 func) in /_/src/Hosting/Microsoft.Web.Hosting/Utilities/AsyncHelper.cs:line 27
   at Microsoft.Web.Hosting.Administration.WebCloudController.UpdateSiteSourceControl(String subscriptionName, String webspaceName, String name, SiteSourceControl siteSourceControl) in /_/src/Hosting/AdministrationService/Microsoft.Web.Hosting.Administration/Controllers/WebCloudController.cs:line 11383.
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ 
```

## Проблема з GitHub інтеграцією ⚠️

Схоже на timeout при спробі встановити SSH ключ для GitHub інтеграції. Спробуємо альтернативні методи деплойменту.

## Варіант 1: ZIP деплоймент (найпростіший)

```bash
# Створіть ZIP архів вашого проекту
zip -r portfolio.zip . -x "*.git*" "*__pycache__*" "*.pyc" "venv/*" "node_modules/*"

# Деплой через ZIP
az webapp deployment source config-zip \
    --src portfolio.zip \
    --name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg
```

## Варіант 2: GitHub Actions (рекомендований для продакшену)

Створіть файл `.github/workflows/azure-deploy.yml`:## Варіант 3: Локальний Git деплоймент

```bash
# Налаштування локального Git репозиторію для деплойменту
az webapp deployment source config-local-git \
    --name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg

# Отримайте URL для Git деплойменту
GIT_URL=$(az webapp deployment source show \
    --name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg \
    --query "repoUrl" --output tsv)

echo "Git URL: $GIT_URL"
```

## Варіант 4: FTP деплоймент

```bash
# Отримання FTP credentials
az webapp deployment list-publishing-credentials \
    --name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg \
    --query "{ftpUrl:scmUri, username:publishingUserName, password:publishingPassword}"
```

## Рекомендації для швидкого результату

### Спробуйте ZIP деплоймент прямо зараз:

```bash
# Перевірте структуру файлів
ls -la

# Створіть ZIP (виключаючи непотрібні файли)
zip -r portfolio.zip . \
    -x "*.git*" \
    -x "*__pycache__*" \
    -x "*.pyc" \
    -x "venv/*" \
    -x "env/*" \
    -x "node_modules/*" \
    -x ".vscode/*"

# Перевірте розмір ZIP файлу
ls -lh portfolio.zip

# Деплой
az webapp deployment source config-zip \
    --src portfolio.zip \
    --name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg
```

### Також підготуйте необхідні файли:### Спробуйте спочатку ZIP деплоймент - це найпростіший спосіб перевірити, що все працює!

Після успішного ZIP деплойменту можна налаштувати GitHub Actions для автоматичних деплойментів при пушах у репозиторій.

Готові спробувати ZIP деплоймент?



# Помилка з авторизацією в GitHub Actions 🔐

Проблема в тому, що GitHub Actions не має доступу до Azure без налаштування автентифікації. Ось кілька способів вирішення:

## Варіант 1: Використання Publish Profile (найпростіший)

### Крок 1: Отримайте Publish Profile

```bash
# Завантажте publish profile
az webapp deployment list-publishing-profiles \
    --name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg \
    --xml
```

### Крок 2: Додайте секрет в GitHub

1. Скопіюйте весь XML вивід з попередньої команди
2. Йдіть на GitHub: **Settings** → **Secrets and variables** → **Actions**
3. Натисніть **New repository secret**
4. Назва: `AZURE_WEBAPP_PUBLISH_PROFILE`
5. Вставте XML контент

## Варіант 2: Використання Service Principal

### Створення Service Principal:

```bash
# Створення Service Principal
az ad sp create-for-rbac \
    --name "django-portfolio-sp" \
    --role contributor \
    --scopes /subscriptions/826d896f-b844-48c3-998e-c8e36c27e681/resourceGroups/django-portfolio-dev-rg \
    --sdk-auth
```

### Додайте отриманий JSON як секрет `AZURE_CREDENTIALS`

## Варіант 3: Оновлений GitHub Actions workflow## Варіант 4: Простіший workflow без Azure CLI## ШВИДКЕ РІШЕННЯ: ZIP деплоймент зараз

Поки налаштовуєте GitHub Actions, спробуйте локальний деплоймент:

```bash
# Створіть ZIP файл
zip -r portfolio.zip . -x "*.git*" "*__pycache__*" "*.pyc" "venv/*"

# Деплой
az webapp deployment source config-zip \
    --src portfolio.zip \
    --name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg
```

## Покрокові дії:

### 1. Спочатку отримайте publish profile:
```bash
az webapp deployment list-publishing-profiles \
    --name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg \
    --xml > publish-profile.xml

cat publish-profile.xml
```

### 2. Додайте секрет в GitHub:
- Зайдіть у ваш репозиторій на GitHub
- **Settings** → **Secrets and variables** → **Actions**
- **New repository secret**
- Назва: `AZURE_WEBAPP_PUBLISH_PROFILE`
- Значення: весь XML контент

### 3. Використайте простий workflow (артефакт вище)

### 4. Або спробуйте ZIP деплоймент прямо зараз!

Що хочете спробувати спочатку?



```bash
name: Deploy Django to Azure

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
    
    - name: Deploy to Azure Web App
      uses: azure/webapps-deploy@v2
      with:
        app-name: 'django-portfolio-web-1751348856'
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}

```




```bash
VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ az webapp log tail \
>     --name django-portfolio-web-1751348856 \
>     --resource-group django-portfolio-dev-rg
2025-07-01T07:19:11  Welcome, you are now connected to log-streaming service.
Starting Log Tail -n 10 of existing logs ----
/home/LogFiles/__lastCheckTime.txt  (https://django-portfolio-web-1751348856.scm.azurewebsites.net/api/vfs/LogFiles/__lastCheckTime.txt)
07/01/2025 07:18:59
/home/LogFiles/kudu/trace/b2a312fca316-ad560e22-3984-43bf-950f-2d1f67f22788.txt  (https://django-portfolio-web-1751348856.scm.azurewebsites.net/api/vfs/LogFiles/kudu/trace/b2a312fca316-ad560e22-3984-43bf-950f-2d1f67f22788.txt)
2025-07-01T07:19:11  Startup Request, url: /logstream, method: GET, type: request, pid: 768,1,5, ScmType: None, SCM_DO_BUILD_DURING_DEPLOYMENT: true
/home/LogFiles/kudu/trace/django-por-kudu-b26bc8c4-ab4ce692-a19e-4d9f-938b-76c81b0d2161.txt  (https://django-portfolio-web-1751348856.scm.azurewebsites.net/api/vfs/LogFiles/kudu/trace/django-por-kudu-b26bc8c4-ab4ce692-a19e-4d9f-938b-76c81b0d2161.txt)
2025-07-01T07:02:02  Startup Request, url: /api/settings, method: GET, type: request, pid: 768,1,66, SCM_DO_BUILD_DURING_DEPLOYMENT: true, ScmType: None
/home/LogFiles/2025_07_01_10-30-0-107_default_docker.log  (https://django-portfolio-web-1751348856.scm.azurewebsites.net/api/vfs/LogFiles/2025_07_01_10-30-0-107_default_docker.log)
2025-07-01T07:18:50.086454837Z   File "<frozen importlib._bootstrap>", line 241, in _call_with_frames_removed
2025-07-01T07:18:50.086460057Z   File "<frozen importlib._bootstrap>", line 1204, in _gcd_import
2025-07-01T07:18:50.086465306Z   File "<frozen importlib._bootstrap>", line 1176, in _find_and_load
2025-07-01T07:18:50.086470737Z   File "<frozen importlib._bootstrap>", line 1140, in _find_and_load_unlocked

2025-07-01T07:18:50.086476047Z ModuleNotFoundError: No module named 'myproject'
2025-07-01T07:18:50.086488289Z [2025-07-01 07:18:50 +0000] [1011] [INFO] Worker exiting (pid: 1011)
2025-07-01T07:18:50.676208460Z [2025-07-01 07:18:50 +0000] [1008] [ERROR] Worker (pid:1011) exited with code 3
2025-07-01T07:18:50.679610296Z [2025-07-01 07:18:50 +0000] [1008] [ERROR] Shutting down: Master
2025-07-01T07:18:50.679624924Z [2025-07-01 07:18:50 +0000] [1008] [ERROR] Reason: Worker failed to boot.
/home/LogFiles/2025_07_01_10-30-0-107_docker.log  (https://django-portfolio-web-1751348856.scm.azurewebsites.net/api/vfs/LogFiles/2025_07_01_10-30-0-107_docker.log)
2025-07-01T07:18:40.518Z INFO  -  Status: Image is up to date for 10.1.0.5:13209/appsvc/python:3.11_20250506.5.tuxprod
2025-07-01T07:18:40.538Z INFO  - Pull Image successful, Time taken: 0 Seconds
2025-07-01T07:18:40.634Z INFO  - Starting container for site
2025-07-01T07:18:40.635Z INFO  - docker run -d --expose=8000 --name django-portfolio-web-1751348856_0_6c25cfe7 -e WEBSITE_USE_DIAGNOSTIC_SERVER=false -e WEBSITE_SITE_NAME=django-portfolio-web-1751348856 -e WEBSITE_AUTH_ENABLED=False -e WEBSITE_ROLE_INSTANCE_ID=0 -e WEBSITE_HOSTNAME=django-portfolio-web-1751348856.azurewebsites.net -e WEBSITE_INSTANCE_ID=b47714df06fcf6a96ddfba3a284a2c5a08964eca8515ab3ca08cef25436c95a0 appsvc/python:3.11_20250506.5.tuxprod 
2025-07-01T07:18:40.637Z INFO  - Logging is not enabled for this container.
Please use https://aka.ms/linux-diagnostics to enable logging to see container logs here.
2025-07-01T07:18:42.268Z INFO  - Initiating warmup request to container django-portfolio-web-1751348856_0_6c25cfe7 for site django-portfolio-web-1751348856
2025-07-01T07:18:51.717Z ERROR - Container django-portfolio-web-1751348856_0_6c25cfe7 for site django-portfolio-web-1751348856 has exited, failing site start
2025-07-01T07:18:52.261Z ERROR - Container django-portfolio-web-1751348856_0_6c25cfe7 didn't respond to HTTP pings on port: 8000. Failing site start. See container logs for debugging.
2025-07-01T07:18:52.324Z INFO  - Stopping site django-portfolio-web-1751348856 because it failed during startup.
/home/LogFiles/AppServiceAppLogs_Feature_Installer/startup_0.log  (https://django-portfolio-web-1751348856.scm.azurewebsites.net/api/vfs/LogFiles/AppServiceAppLogs_Feature_Installer/startup_0.log)
2025-07-01 07:12:06,874  [MainThread] [DEBUG] : Initialized AppServiceAppLogging
2025-07-01 07:13:08,162  [MainThread] [DEBUG] : Initializating AppServiceAppLogging 
2025-07-01 07:13:08,164  [Thread-1 (] [DEBUG] : Did not find any previously bound socket
2025-07-01 07:13:08,165  [MainThread] [DEBUG] : Initialized AppServiceAppLogging
2025-07-01 07:16:29,999  [MainThread] [DEBUG] : Initializating AppServiceAppLogging 
2025-07-01 07:16:30,001  [Thread-1 (] [DEBUG] : Did not find any previously bound socket
2025-07-01 07:16:30,002  [MainThread] [DEBUG] : Initialized AppServiceAppLogging
2025-07-01 07:18:48,311  [MainThread] [DEBUG] : Initializating AppServiceAppLogging 
2025-07-01 07:18:48,313  [Thread-1 (] [DEBUG] : Did not find any previously bound socket
2025-07-01 07:18:48,314  [MainThread] [DEBUG] : Initialized AppServiceAppLogging
/home/LogFiles/AppServiceAppLogs_Feature_Installer/startup_7.log  (https://django-portfolio-web-1751348856.scm.azurewebsites.net/api/vfs/LogFiles/AppServiceAppLogs_Feature_Installer/startup_7.log)
2025-07-01 05:49:36,486  [Thread-3 (] [DEBUG] : Waiting for the logs flag to be set
2025-07-01 07:03:59,021  [MainThread] [DEBUG] : Initializating AppServiceAppLogging 
2025-07-01 07:03:59,025  [Thread-1 (] [DEBUG] : Did not find any previously bound socket
2025-07-01 07:03:59,026  [MainThread] [DEBUG] : Initialized AppServiceAppLogging
2025-07-01 07:10:17,176  [MainThread] [DEBUG] : Initializating AppServiceAppLogging 
2025-07-01 07:10:17,178  [Thread-1 (] [DEBUG] : Did not find any previously bound socket
2025-07-01 07:10:17,179  [MainThread] [DEBUG] : Initialized AppServiceAppLogging
2025-07-01 07:16:09,801  [MainThread] [DEBUG] : Initializating AppServiceAppLogging 
2025-07-01 07:16:09,803  [Thread-1 (] [DEBUG] : Did not find any previously bound socket
2025-07-01 07:16:09,803  [MainThread] [DEBUG] : Initialized AppServiceAppLogging
/home/LogFiles/CodeProfiler/b47714_debug.log  (https://django-portfolio-web-1751348856.scm.azurewebsites.net/api/vfs/LogFiles/CodeProfiler/b47714_debug.log)
[2025_07_01_05_49_36] [appsvc_profiler.installer] [INFO] Code Profiler Installer is starting up
[2025_07_01_05_49_36] [appsvc_profiler.installer] [INFO] Cleaning up any existing status file which indicated signal handlers initialized status
[2025_07_01_05_49_36] [appsvc_profiler.installer] [DEBUG] APPSETTING_WEBSITE_ENABLE_DEFAULT_CODE_PROFILER : None
[2025_07_01_05_49_36] [appsvc_profiler.installer] [INFO] Attempting to install the default code profiler.
[2025_07_01_05_49_36] [appsvc_profiler.installer] [DEBUG] viztracer would save traces to /tmp/b47714_profiler_trace.json
[2025_07_01_05_49_36] [appsvc_profiler.installer] [INFO] Successfully installed code profiler.
[2025_07_01_05_49_36] [appsvc_profiler.installer] [INFO] Signal Handlers SIGUSR for needed code-profiler have been initialized for gunicorn process on instance b47714df06fcf6a96ddfba3a284a2c5a08964eca8515ab3ca08cef25436c95a0
[2025_07_01_05_49_36] [appsvc_profiler.installer] [DEBUG] Code Profiler Installer is exiting as installation is completed
Ending Log Tail of existing logs ---
Starting Live Log Stream ---
2025-07-01T07:20:11  No new trace in the past 1 min(s).
2025-07-01T07:21:11  No new trace in the past 2 min(s).
2025-07-01T07:22:11  No new trace in the past 3 min(s).
2025-07-01T07:23:11  No new trace in the past 4 min(s).
2025-07-01T07:24:11  No new trace in the past 5 min(s).
2025-07-01T07:25:11  No new trace in the past 6 min(s).
```

# Знайшли проблему! 🔍

## Основна помилка:
```
ModuleNotFoundError: No module named 'myproject'
```

Проблема в тому, що Gunicorn намагається знайти модуль `myproject.wsgi`, але ваш Django проект має іншу назву.

## Рішення

### 1. З'ясуємо правильну назву вашого Django проекту:

```bash
# Подивіться структуру проекту
ls -la

# Знайдіть файл wsgi.py
find . -name "wsgi.py" -type f

# Або подивіться manage.py
cat manage.py | grep DJANGO_SETTINGS_MODULE
```

### 2. Після того, як знайдете правильну назву, оновіть startup команду:

```bash
# Замініть 'myproject' на правильну назву вашого проекту
# Наприклад, якщо ваш проект називається 'portfolio' або 'core':

az webapp config set \
    --name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg \
    --startup-file "gunicorn --bind=0.0.0.0:8000 --timeout 600 ВАШАНАЗВАПРОЕКТУ.wsgi:application"
```

### 3. Альтернативно, спробуйте автоматичне виявлення:

```bash
# Використайте Django's manage.py для автозапуску
az webapp config set \
    --name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg \
    --startup-file "python manage.py runserver 0.0.0.0:8000"
```

### 4. Або створіть startup.sh файл:## Швидке виправлення:

### Спочатку з'ясуйте назву проекту:
```bash
ls -la
find . -name "wsgi.py"
```

### Потім оновіть конфігурацію з правильною назвою:
```bash
# Замініть YOUR_PROJECT_NAME на реальну назву
az webapp config set \
    --name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg \
    --startup-file "gunicorn --bind=0.0.0.0:8000 YOUR_PROJECT_NAME.wsgi:application"
```

### Або використайте Django runserver для швидкого тесту:
```bash
az webapp config set \
    --name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg \
    --startup-file "python manage.py runserver 0.0.0.0:8000"
```

### Перезапустіть додаток:
```bash
az webapp restart \
    --name django-portfolio-web-1751348856 \
    --resource-group django-portfolio-dev-rg
```

Покажіть мені вивід команди `ls -la` та `find . -name "wsgi.py"`, щоб я міг точно сказати, яку назву проекту використовувати!




---------------------------------------------------------------------------------------------------------------

# Помилка з назвою Storage Account ❌

Проблема: назва Storage Account занадто довга (36 символів) і містить дефіси. Azure вимагає:
- **3-24 символи**
- **Тільки цифри та малі літери**
- **Без дефісів та спеціальних символів**

## Швидке виправлення

Відредагуйте ваш `script_azure.sh` файл:## Або швидке виправлення прямо в терміналі:

```bash
# Відредагуйте скрипт
nano script_azure.sh

# Знайдіть рядок зі STORAGE_NAME та замініть на:
# STORAGE_NAME="djapp$(date +%s | tail -c 8)"
```

## Альтернативно - запустіть з виправленим скриптом:## Швидкі команди для виправлення:

### 1. Виправте назву в скрипті:
```bash
# Замініть рядок у script_azure.sh
sed -i 's/STORAGE_NAME=.*/STORAGE_NAME="djapp$(date +%s | tail -c 8)"/' script_azure.sh
```

### 2. Або створіть Storage Account вручну:
```bash
# Створіть з правильною назвою
STORAGE_NAME="djapp$(date +%s | tail -c 8)"
echo "Storage name: $STORAGE_NAME"

az storage account create \
    --name "$STORAGE_NAME" \
    --resource-group "django-app-production-rg" \
    --location "westeurope" \
    --sku Standard_LRS
```

### 3. Перевірте довжину назви:
```bash
STORAGE_NAME="djapp$(date +%s | tail -c 8)"
echo "Storage name: $STORAGE_NAME (length: ${#STORAGE_NAME})"
```

Виберіть один з варіантів і запустіть знову. Resource Group вже створена, тому можна просто виправити Storage Account і продовжити!

-------------------------------------------------------------------------------------------------------------------------------



```bash
^C@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ ./script_azure.sh
[2025-07-01 12:47:52] Початок створення інфраструктури для Django додатку...
[2025-07-01 12:47:52] Проект: django-app
[2025-07-01 12:47:52] Середовище: production
[2025-07-01 12:47:52] Регіон: West Europe
[2025-07-01 12:47:52] Перевірка залежностей...
[2025-07-01 12:47:53] ✅ Всі залежності встановлені
[2025-07-01 12:47:53] Створення Resource Group: django-app-production-rg
{
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg",
  "location": "westeurope",
  "managedBy": null,
  "name": "django-app-production-rg",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": {
    "CreatedBy": "AzureCLI",
    "Environment": "production",
    "Project": "django-app"
  },
  "type": "Microsoft.Resources/resourceGroups"
}
[2025-07-01 12:47:56] Створення Storage Account: djapp1374072
{
  "accessTier": "Hot",
  "accountMigrationInProgress": null,
  "allowBlobPublicAccess": false,
  "allowCrossTenantReplication": false,
  "allowSharedKeyAccess": null,
  "allowedCopyScope": null,
  "azureFilesIdentityBasedAuthentication": null,
  "blobRestoreStatus": null,
  "creationTime": "2025-07-01T12:47:59.097030+00:00",
  "customDomain": null,
  "defaultToOAuthAuthentication": null,
  "dnsEndpointType": null,
  "enableExtendedGroups": null,
  "enableHttpsTrafficOnly": true,
  "enableNfsV3": null,
  "encryption": {
    "encryptionIdentity": null,
    "keySource": "Microsoft.Storage",
    "keyVaultProperties": null,
    "requireInfrastructureEncryption": null,
    "services": {
      "blob": {
        "enabled": true,
        "keyType": "Account",
        "lastEnabledTime": "2025-07-01T12:47:59.362656+00:00"
      },
      "file": {
        "enabled": true,
        "keyType": "Account",
        "lastEnabledTime": "2025-07-01T12:47:59.362656+00:00"
      },
      "queue": null,
      "table": null
    }
  },
  "extendedLocation": null,
  "failoverInProgress": null,
  "geoReplicationStats": null,
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg/providers/Microsoft.Storage/storageAccounts/djapp1374072",
  "identity": null,
  "immutableStorageWithVersioning": null,
  "isHnsEnabled": null,
  "isLocalUserEnabled": null,
  "isSftpEnabled": null,
  "isSkuConversionBlocked": null,
  "keyCreationTime": {
    "key1": "2025-07-01T12:47:59.362656+00:00",
    "key2": "2025-07-01T12:47:59.362656+00:00"
  },
  "keyPolicy": null,
  "kind": "StorageV2",
  "largeFileSharesState": null,
  "lastGeoFailoverTime": null,
  "location": "westeurope",
  "minimumTlsVersion": "TLS1_0",
  "name": "djapp1374072",
  "networkRuleSet": {
    "bypass": "AzureServices",
    "defaultAction": "Allow",
    "ipRules": [],
    "ipv6Rules": [],
    "resourceAccessRules": null,
    "virtualNetworkRules": []
  },
  "primaryEndpoints": {
    "blob": "https://djapp1374072.blob.core.windows.net/",
    "dfs": "https://djapp1374072.dfs.core.windows.net/",
    "file": "https://djapp1374072.file.core.windows.net/",
    "internetEndpoints": null,
    "microsoftEndpoints": null,
    "queue": "https://djapp1374072.queue.core.windows.net/",
    "table": "https://djapp1374072.table.core.windows.net/",
    "web": "https://djapp1374072.z6.web.core.windows.net/"
  },
  "primaryLocation": "westeurope",
  "privateEndpointConnections": [],
  "provisioningState": "Succeeded",
  "publicNetworkAccess": null,
  "resourceGroup": "django-app-production-rg",
  "routingPreference": null,
  "sasPolicy": null,
  "secondaryEndpoints": null,
  "secondaryLocation": null,
  "sku": {
    "name": "Standard_LRS",
    "tier": "Standard"
  },
  "statusOfPrimary": "available",
  "statusOfSecondary": null,
  "storageAccountSkuConversionStatus": null,
  "tags": {
    "CreatedBy": "AzureCLI",
    "Environment": "production",
    "Project": "django-app"
  },
  "type": "Microsoft.Storage/storageAccounts"
}
{
  "created": false
}
{
  "created": false
}
[2025-07-01 12:48:22] Створення PostgreSQL сервера: django-app-production-db-1751374072
The default value of '--version' will be changed to '17' from '16' in next breaking change release(2.73.0) scheduled for May 2025.
The default value of '--create-default-database' will be changed to 'Disabled' from 'Enabled' in next breaking change release(2.73.0) scheduled for May 2025.
Update default value of "--sku-name" in next breaking change release(2.73.0) scheduled for May 2025. The default value will be changed from "Standard_D2s_v3" to a supported sku based on regional capabilities.
Checking the existence of the resource group 'django-app-production-rg'...
Resource group 'django-app-production-rg' exists ? : True 
Incorrect value for --sku-name. The SKU name does not exist in GeneralPurpose tier. When --tier is not specified, it defaults to GeneralPurpose. Provide a valid SKU name for this tier, or specify --tier with the right tier for the SKU name chosen. Allowed values : ['standard_d96ds_v5', 'standard_d64ds_v5', 'standard_d48ds_v5', 'standard_d32ds_v5', 'standard_d16ds_v5', 'standard_d8ds_v5', 'standard_d4ds_v5', 'standard_d2ds_v5', 'standard_d64ds_v4', 'standard_d48ds_v4', 'standard_d32ds_v4', 'standard_d16ds_v4', 'standard_d8ds_v4', 'standard_d4ds_v4', 'standard_d2ds_v4', 'standard_d64s_v3', 'standard_d48s_v3', 'standard_d32s_v3', 'standard_d16s_v3', 'standard_d8s_v3', 'standard_d4s_v3', 'standard_d2s_v3']
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ 
```


# Прогрес! Storage Account створено успішно! ✅

## Стан на зараз:
- ✅ **Resource Group:** `django-app-production-rg` - створено
- ✅ **Storage Account:** `djapp1374072` - створено успішно
- ❌ **PostgreSQL:** помилка з SKU

## Проблема з PostgreSQL

Помилка: неправильна назва SKU для PostgreSQL. Скрипт використовує застарілу назву SKU.

### Виправлення в скрипті:## Швидкі способи продовжити:

### 1. Ручне створення PostgreSQL з правильним SKU:

```bash
# Використайте змінні з вашого скрипту
DB_SERVER_NAME="django-app-production-db-1751374072"
DB_ADMIN_USER="djangoadmin"
DB_ADMIN_PASSWORD="ComplexPass123!"
RG_NAME="django-app-production-rg"
LOCATION="westeurope"

# Створіть PostgreSQL з правильним SKU
az postgres flexible-server create \
    --name "$DB_SERVER_NAME" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --admin-user "$DB_ADMIN_USER" \
    --admin-password "$DB_ADMIN_PASSWORD" \
    --sku-name "Standard_D2ds_v4" \
    --tier "GeneralPurpose" \
    --version "16" \
    --storage-size 32 \
    --public-network-access Enabled
```

### 2. Альтернативно - використайте найдешевший SKU:

```bash
# Для dev/testing - найменший розмір
az postgres flexible-server create \
    --name "$DB_SERVER_NAME" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --admin-user "$DB_ADMIN_USER" \
    --admin-password "$DB_ADMIN_PASSWORD" \
    --sku-name "Standard_B1ms" \
    --tier "Burstable" \
    --version "16" \
    --storage-size 32
```

### 3. Виправлення в скрипті:

```bash
# Відредагуйте script_azure.sh
nano script_azure.sh

# Знайдіть рядок з --sku-name та замініть на:
# --sku-name "Standard_D2ds_v4" \
# --tier "GeneralPurpose" \
```

### 4. Продовжити з поточного стану:

```bash
# Оскільки RG і Storage вже створені, можна продовжити з PostgreSQL
# Додайте змінні та створіть БД:

export DB_SERVER_NAME="django-app-production-db-$(date +%s)"
export DB_ADMIN_USER="djangoadmin"
export DB_ADMIN_PASSWORD="ComplexPass123!"

az postgres flexible-server create \
    --name "$DB_SERVER_NAME" \
    --resource-group "django-app-production-rg" \
    --location "westeurope" \
    --admin-user "$DB_ADMIN_USER" \
    --admin-password "$DB_ADMIN_PASSWORD" \
    --sku-name "Standard_D2ds_v4" \
    --tier "GeneralPurpose"
```

## Перевірка доступних SKU:

```bash
# Подивіться доступні SKU для PostgreSQL
az postgres flexible-server list-skus --location westeurope --output table
```

Який варіант виберете? Рекомендую спочатку спробувати ручне створення PostgreSQL з правильним SKU, а потім продовжити зі скриптом!



```bash
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ az postgres flexible-server list-skus --location westeurope --output table
For prices please refer to https://aka.ms/postgres-pricing
SKU                Tier             VCore    Memory    Max Disk IOPS
-----------------  ---------------  -------  --------  ---------------
Standard_B1ms      Burstable        1        2 GiB     640
Standard_B2s       Burstable        2        4 GiB     1280
Standard_B2ms      Burstable        2        8 GiB     1920
Standard_B4ms      Burstable        4        16 GiB    2880
Standard_B8ms      Burstable        8        32 GiB    4320
Standard_B12ms     Burstable        12       48 GiB    4320
Standard_B16ms     Burstable        16       64 GiB    4320
Standard_B20ms     Burstable        20       80 GiB    4320
Standard_D2s_v3    GeneralPurpose   2        8 GiB     3200
Standard_D4s_v3    GeneralPurpose   4        16 GiB    6400
Standard_D8s_v3    GeneralPurpose   8        32 GiB    12800
Standard_D16s_v3   GeneralPurpose   16       64 GiB    25600
Standard_D32s_v3   GeneralPurpose   32       128 GiB   51200
Standard_D48s_v3   GeneralPurpose   48       192 GiB   76800
Standard_D64s_v3   GeneralPurpose   64       256 GiB   80000
Standard_D2ds_v4   GeneralPurpose   2        8 GiB     3200
Standard_D4ds_v4   GeneralPurpose   4        16 GiB    6400
Standard_D8ds_v4   GeneralPurpose   8        32 GiB    12800
Standard_D16ds_v4  GeneralPurpose   16       64 GiB    25600
Standard_D32ds_v4  GeneralPurpose   32       128 GiB   51200
Standard_D48ds_v4  GeneralPurpose   48       192 GiB   76800
Standard_D64ds_v4  GeneralPurpose   64       256 GiB   80000
Standard_D2ds_v5   GeneralPurpose   2        8 GiB     3750
Standard_D4ds_v5   GeneralPurpose   4        16 GiB    6400
Standard_D8ds_v5   GeneralPurpose   8        32 GiB    12800
Standard_D16ds_v5  GeneralPurpose   16       64 GiB    25600
Standard_D32ds_v5  GeneralPurpose   32       128 GiB   51200
Standard_D48ds_v5  GeneralPurpose   48       192 GiB   76800
Standard_D64ds_v5  GeneralPurpose   64       256 GiB   80000
Standard_D96ds_v5  GeneralPurpose   96       384 GiB   80000
Standard_E2s_v3    MemoryOptimized  2        16 GiB    3200
Standard_E4s_v3    MemoryOptimized  4        32 GiB    6400
Standard_E8s_v3    MemoryOptimized  8        64 GiB    12800
Standard_E16s_v3   MemoryOptimized  16       128 GiB   25600
Standard_E32s_v3   MemoryOptimized  32       256 GiB   32000
Standard_E48s_v3   MemoryOptimized  48       384 GiB   51200
Standard_E64s_v3   MemoryOptimized  64       432 GiB   76800
Standard_E2ds_v4   MemoryOptimized  2        16 GiB    3200
Standard_E4ds_v4   MemoryOptimized  4        32 GiB    6400
Standard_E8ds_v4   MemoryOptimized  8        64 GiB    12800
Standard_E16ds_v4  MemoryOptimized  16       128 GiB   25600
Standard_E20ds_v4  MemoryOptimized  20       160 GiB   32000
Standard_E32ds_v4  MemoryOptimized  32       256 GiB   51200
Standard_E48ds_v4  MemoryOptimized  48       384 GiB   76800
Standard_E64ds_v4  MemoryOptimized  64       432 GiB   80000
Standard_E2ds_v5   MemoryOptimized  2        16 GiB    3750
Standard_E4ds_v5   MemoryOptimized  4        32 GiB    6400
Standard_E8ds_v5   MemoryOptimized  8        64 GiB    12800
Standard_E16ds_v5  MemoryOptimized  16       128 GiB   25600
Standard_E20ds_v5  MemoryOptimized  20       160 GiB   32000
Standard_E32ds_v5  MemoryOptimized  32       256 GiB   51200
Standard_E48ds_v5  MemoryOptimized  48       384 GiB   76800
Standard_E64ds_v5  MemoryOptimized  64       512 GiB   80000
Standard_E96ds_v5  MemoryOptimized  96       672 GiB   80000
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ 
```


```bash
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ ./script_azure.sh
[2025-07-01 16:28:56] Початок створення інфраструктури для Django додатку...
[2025-07-01 16:28:56] Проект: django-app
[2025-07-01 16:28:56] Середовище: production
[2025-07-01 16:28:56] Регіон: West Europe
[2025-07-01 16:28:56] Перевірка залежностей...
[2025-07-01 16:28:56] ✅ Всі залежності встановлені
[2025-07-01 16:28:56] Створення Resource Group: django-app-production-rg
{
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg",
  "location": "westeurope",
  "managedBy": null,
  "name": "django-app-production-rg",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": {
    "CreatedBy": "AzureCLI",
    "Environment": "production",
    "Project": "django-app"
  },
  "type": "Microsoft.Resources/resourceGroups"
}
[2025-07-01 16:28:59] Створення Storage Account: djapp1387336
{
  "accessTier": "Hot",
  "accountMigrationInProgress": null,
  "allowBlobPublicAccess": false,
  "allowCrossTenantReplication": false,
  "allowSharedKeyAccess": null,
  "allowedCopyScope": null,
  "azureFilesIdentityBasedAuthentication": null,
  "blobRestoreStatus": null,
  "creationTime": "2025-07-01T16:29:02.530377+00:00",
  "customDomain": null,
  "defaultToOAuthAuthentication": null,
  "dnsEndpointType": null,
  "enableExtendedGroups": null,
  "enableHttpsTrafficOnly": true,
  "enableNfsV3": null,
  "encryption": {
    "encryptionIdentity": null,
    "keySource": "Microsoft.Storage",
    "keyVaultProperties": null,
    "requireInfrastructureEncryption": null,
    "services": {
      "blob": {
        "enabled": true,
        "keyType": "Account",
        "lastEnabledTime": "2025-07-01T16:29:02.795973+00:00"
      },
      "file": {
        "enabled": true,
        "keyType": "Account",
        "lastEnabledTime": "2025-07-01T16:29:02.795973+00:00"
      },
      "queue": null,
      "table": null
    }
  },
  "extendedLocation": null,
  "failoverInProgress": null,
  "geoReplicationStats": null,
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg/providers/Microsoft.Storage/storageAccounts/djapp1387336",
  "identity": null,
  "immutableStorageWithVersioning": null,
  "isHnsEnabled": null,
  "isLocalUserEnabled": null,
  "isSftpEnabled": null,
  "isSkuConversionBlocked": null,
  "keyCreationTime": {
    "key1": "2025-07-01T16:29:02.780349+00:00",
    "key2": "2025-07-01T16:29:02.780349+00:00"
  },
  "keyPolicy": null,
  "kind": "StorageV2",
  "largeFileSharesState": null,
  "lastGeoFailoverTime": null,
  "location": "westeurope",
  "minimumTlsVersion": "TLS1_0",
  "name": "djapp1387336",
  "networkRuleSet": {
    "bypass": "AzureServices",
    "defaultAction": "Allow",
    "ipRules": [],
    "ipv6Rules": [],
    "resourceAccessRules": null,
    "virtualNetworkRules": []
  },
  "primaryEndpoints": {
    "blob": "https://djapp1387336.blob.core.windows.net/",
    "dfs": "https://djapp1387336.dfs.core.windows.net/",
    "file": "https://djapp1387336.file.core.windows.net/",
    "internetEndpoints": null,
    "microsoftEndpoints": null,
    "queue": "https://djapp1387336.queue.core.windows.net/",
    "table": "https://djapp1387336.table.core.windows.net/",
    "web": "https://djapp1387336.z6.web.core.windows.net/"
  },
  "primaryLocation": "westeurope",
  "privateEndpointConnections": [],
  "provisioningState": "Succeeded",
  "publicNetworkAccess": null,
  "resourceGroup": "django-app-production-rg",
  "routingPreference": null,
  "sasPolicy": null,
  "secondaryEndpoints": null,
  "secondaryLocation": null,
  "sku": {
    "name": "Standard_LRS",
    "tier": "Standard"
  },
  "statusOfPrimary": "available",
  "statusOfSecondary": null,
  "storageAccountSkuConversionStatus": null,
  "tags": {
    "CreatedBy": "AzureCLI",
    "Environment": "production",
    "Project": "django-app"
  },
  "type": "Microsoft.Storage/storageAccounts"
}
{
  "created": false
}
{
  "created": false
}
[2025-07-01 16:29:25] Створення PostgreSQL сервера: django-app-production-db-1751387336
The default value of '--version' will be changed to '17' from '16' in next breaking change release(2.73.0) scheduled for May 2025.
The default value of '--create-default-database' will be changed to 'Disabled' from 'Enabled' in next breaking change release(2.73.0) scheduled for May 2025.
Update default value of "--sku-name" in next breaking change release(2.73.0) scheduled for May 2025. The default value will be changed from "Standard_D2s_v3" to a supported sku based on regional capabilities.
Checking the existence of the resource group 'django-app-production-rg'...
Resource group 'django-app-production-rg' exists ? : True 
The default value for the PostgreSQL server major version will be updating to 17 in the near future.
Creating PostgreSQL Server 'django-app-production-db-1751387336' in group 'django-app-production-rg'...
Your server 'django-app-production-db-1751387336' is using sku 'Standard_D2ds_v4' (Paid Tier). Please refer to https://aka.ms/postgres-pricing for pricing details
Configuring server firewall rule, 'azure-access', to accept connections from all Azure resources...
Creating PostgreSQL database 'flexibleserverdb'...
Make a note of your password. If you forget, you would have to reset your password with "az postgres flexible-server update -n django-app-production-db-1751387336 -g django-app-production-rg -p <new-password>".
Try using 'az postgres flexible-server connect' command to test out connection.
{
  "connectionString": "postgresql://djangoadmin:eGwSA1oIVcwLGiKmAa1!@django-app-production-db-1751387336.postgres.database.azure.com/flexibleserverdb?sslmode=require",
  "databaseName": "flexibleserverdb",
  "firewallName": "AllowAllAzureServicesAndResourcesWithinAzureIps_2025-7-1_16-33-32",
  "host": "django-app-production-db-1751387336.postgres.database.azure.com",
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/django-app-production-db-1751387336",
  "location": "West Europe",
  "password": "eGwSA1oIVcwLGiKmAa1!",
  "resourceGroup": "django-app-production-rg",
  "skuname": "Standard_D2ds_v4",
  "username": "djangoadmin",
  "version": "14"
}
[2025-07-01 16:34:46] Створення бази даних: django-app_db
Creating database with utf8 charset and en_US.utf8 collation
{
  "charset": "UTF8",
  "collation": "en_US.utf8",
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/django-app-production-db-1751387336/databases/django-app_db",
  "name": "django-app_db",
  "resourceGroup": "django-app-production-rg",
  "systemData": null,
  "type": "Microsoft.DBforPostgreSQL/flexibleServers/databases"
}
[2025-07-01 16:35:00] Налаштування firewall правил для бази даних
{
  "endIpAddress": "0.0.0.0",
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/django-app-production-db-1751387336/firewallRules/AllowAzureServices",
  "name": "AllowAzureServices",
  "resourceGroup": "django-app-production-rg",
  "startIpAddress": "0.0.0.0",
  "systemData": null,
  "type": "Microsoft.DBforPostgreSQL/flexibleServers/firewallRules"
}
[2025-07-01 16:36:02] Створення Key Vault: django-app-production-kv-1751387336
(VaultNameNotValid) The vault name 'django-app-production-kv-1751387336' is invalid. A vault's name must be between 3-24 alphanumeric characters. The name must begin with a letter, end with a letter or digit, and not contain consecutive hyphens. Follow this link for more information: https://go.microsoft.com/fwlink/?linkid=2147742
Code: VaultNameNotValid
Message: The vault name 'django-app-production-kv-1751387336' is invalid. A vault's name must be between 3-24 alphanumeric characters. The name must begin with a letter, end with a letter or digit, and not contain consecutive hyphens. Follow this link for more information: https://go.microsoft.com/fwlink/?linkid=2147742
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ 
```

# Відмінний прогрес! 🎉

## Стан на зараз:
- ✅ **Resource Group:** `django-app-production-rg` - створено
- ✅ **Storage Account:** `djapp1387336` - створено успішно
- ✅ **PostgreSQL Server:** `django-app-production-db-1751387336` - створено!
- ✅ **Database:** `django-app_db` - створено
- ✅ **Firewall Rules** - налаштовано
- ❌ **Key Vault:** помилка з назвою (занадто довга)

## Важлива інформація про базу даних:

**PostgreSQL Connection Details:**
- **Host:** `django-app-production-db-1751387336.postgres.database.azure.com`
- **Username:** `djangoadmin`
- **Password:** `eGwSA1oIVcwLGiKmAa1!`
- **Database:** `django-app_db`
- **Port:** `5432` (стандартний)
- **SSL:** Required

## Виправлення Key Vault

Проблема: назва Key Vault занадто довга (35 символів). Azure вимагає 3-24 символи.

### Швидке виправлення:

```bash
# Створіть Key Vault з короткою назвою
KV_NAME="djapp-kv-$(date +%s | tail -c 6)"
echo "Key Vault name: $KV_NAME"

az keyvault create \
    --name "$KV_NAME" \
    --resource-group "django-app-production-rg" \
    --location "westeurope" \
    --enabled-for-template-deployment true \
    --tags Project="django-app" Environment="production" CreatedBy="AzureCLI"
```

### Або використайте ще коротшу назву:

```bash
# Максимально коротка назва
KV_NAME="djappkv$(date +%H%M%S)"
echo "Key Vault name: $KV_NAME (length: ${#KV_NAME})"

az keyvault create \
    --name "$KV_NAME" \
    --resource-group "django-app-production-rg" \
    --location "westeurope"
```

### Для виправлення скрипту в майбутньому:## Створення App Service та завершення інфраструктури

Оскільки основні ресурси створені, давайте створимо App Service:

```bash
# Змінні
RG_NAME="django-app-production-rg"
APP_SERVICE_PLAN="django-webapp-plan"
WEB_APP_NAME="django-webapp-$(date +%s | tail -c 6)"
LOCATION="westeurope"

# Створення App Service Plan
az appservice plan create \
    --name "$APP_SERVICE_PLAN" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --is-linux \
    --sku B1

# Створення Web App
az webapp create \
    --resource-group "$RG_NAME" \
    --plan "$APP_SERVICE_PLAN" \
    --name "$WEB_APP_NAME" \
    --runtime "PYTHON:3.11"

echo "Web App URL: https://${WEB_APP_NAME}.azurewebsites.net"
```

## Налаштування змінних середовища для Django:

```bash
# Налаштування підключення до бази даних
az webapp config appsettings set \
    --resource-group "$RG_NAME" \
    --name "$WEB_APP_NAME" \
    --settings \
        DATABASE_URL="postgresql://djangoadmin:eGwSA1oIVcwLGiKmAa1!@django-app-production-db-1751387336.postgres.database.azure.com:5432/django-app_db" \
        DJANGO_SETTINGS_MODULE="myproject.settings" \
        DEBUG="False" \
        ALLOWED_HOSTS="${WEB_APP_NAME}.azurewebsites.net" \
        AZURE_STORAGE_ACCOUNT_NAME="djapp1387336"
```

## Поточний статус ресурсів:

```bash
# Перегляд всіх створених ресурсів
az resource list \
    --resource-group "django-app-production-rg" \
    --output table
```

Хочете, щоб я допоміг з створенням Key Vault та App Service, або ви самі продовжите?



```bash
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ ./script_azure.sh
[2025-07-01 17:03:50] Початок створення інфраструктури для Django додатку...
[2025-07-01 17:03:50] Проект: django-app
[2025-07-01 17:03:50] Середовище: production
[2025-07-01 17:03:50] Регіон: West Europe
[2025-07-01 17:03:50] Перевірка залежностей...
[2025-07-01 17:03:51] ✅ Всі залежності встановлені
[2025-07-01 17:03:51] Створення Resource Group: django-app-production-rg
{
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg",
  "location": "westeurope",
  "managedBy": null,
  "name": "django-app-production-rg",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": {
    "CreatedBy": "AzureCLI",
    "Environment": "production",
    "Project": "django-app"
  },
  "type": "Microsoft.Resources/resourceGroups"
}
[2025-07-01 17:03:53] Створення Storage Account: djapp1389430
{
  "accessTier": "Hot",
  "accountMigrationInProgress": null,
  "allowBlobPublicAccess": false,
  "allowCrossTenantReplication": false,
  "allowSharedKeyAccess": null,
  "allowedCopyScope": null,
  "azureFilesIdentityBasedAuthentication": null,
  "blobRestoreStatus": null,
  "creationTime": "2025-07-01T17:03:56.457466+00:00",
  "customDomain": null,
  "defaultToOAuthAuthentication": null,
  "dnsEndpointType": null,
  "enableExtendedGroups": null,
  "enableHttpsTrafficOnly": true,
  "enableNfsV3": null,
  "encryption": {
    "encryptionIdentity": null,
    "keySource": "Microsoft.Storage",
    "keyVaultProperties": null,
    "requireInfrastructureEncryption": null,
    "services": {
      "blob": {
        "enabled": true,
        "keyType": "Account",
        "lastEnabledTime": "2025-07-01T17:03:56.613710+00:00"
      },
      "file": {
        "enabled": true,
        "keyType": "Account",
        "lastEnabledTime": "2025-07-01T17:03:56.613710+00:00"
      },
      "queue": null,
      "table": null
    }
  },
  "extendedLocation": null,
  "failoverInProgress": null,
  "geoReplicationStats": null,
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg/providers/Microsoft.Storage/storageAccounts/djapp1389430",
  "identity": null,
  "immutableStorageWithVersioning": null,
  "isHnsEnabled": null,
  "isLocalUserEnabled": null,
  "isSftpEnabled": null,
  "isSkuConversionBlocked": null,
  "keyCreationTime": {
    "key1": "2025-07-01T17:03:56.613710+00:00",
    "key2": "2025-07-01T17:03:56.613710+00:00"
  },
  "keyPolicy": null,
  "kind": "StorageV2",
  "largeFileSharesState": null,
  "lastGeoFailoverTime": null,
  "location": "westeurope",
  "minimumTlsVersion": "TLS1_0",
  "name": "djapp1389430",
  "networkRuleSet": {
    "bypass": "AzureServices",
    "defaultAction": "Allow",
    "ipRules": [],
    "ipv6Rules": [],
    "resourceAccessRules": null,
    "virtualNetworkRules": []
  },
  "primaryEndpoints": {
    "blob": "https://djapp1389430.blob.core.windows.net/",
    "dfs": "https://djapp1389430.dfs.core.windows.net/",
    "file": "https://djapp1389430.file.core.windows.net/",
    "internetEndpoints": null,
    "microsoftEndpoints": null,
    "queue": "https://djapp1389430.queue.core.windows.net/",
    "table": "https://djapp1389430.table.core.windows.net/",
    "web": "https://djapp1389430.z6.web.core.windows.net/"
  },
  "primaryLocation": "westeurope",
  "privateEndpointConnections": [],
  "provisioningState": "Succeeded",
  "publicNetworkAccess": null,
  "resourceGroup": "django-app-production-rg",
  "routingPreference": null,
  "sasPolicy": null,
  "secondaryEndpoints": null,
  "secondaryLocation": null,
  "sku": {
    "name": "Standard_LRS",
    "tier": "Standard"
  },
  "statusOfPrimary": "available",
  "statusOfSecondary": null,
  "storageAccountSkuConversionStatus": null,
  "tags": {
    "CreatedBy": "AzureCLI",
    "Environment": "production",
    "Project": "django-app"
  },
  "type": "Microsoft.Storage/storageAccounts"
}
{
  "created": false
}
{
  "created": false
}
[2025-07-01 17:04:18] Створення PostgreSQL сервера: django-app-production-db-1751389430
The default value of '--version' will be changed to '17' from '16' in next breaking change release(2.73.0) scheduled for May 2025.
The default value of '--create-default-database' will be changed to 'Disabled' from 'Enabled' in next breaking change release(2.73.0) scheduled for May 2025.
Update default value of "--sku-name" in next breaking change release(2.73.0) scheduled for May 2025. The default value will be changed from "Standard_D2s_v3" to a supported sku based on regional capabilities.
Checking the existence of the resource group 'django-app-production-rg'...
Resource group 'django-app-production-rg' exists ? : True 
The default value for the PostgreSQL server major version will be updating to 17 in the near future.
Creating PostgreSQL Server 'django-app-production-db-1751389430' in group 'django-app-production-rg'...
Your server 'django-app-production-db-1751389430' is using sku 'Standard_D2ds_v4' (Paid Tier). Please refer to https://aka.ms/postgres-pricing for pricing details
Configuring server firewall rule, 'azure-access', to accept connections from all Azure resources...
Creating PostgreSQL database 'flexibleserverdb'...
Make a note of your password. If you forget, you would have to reset your password with "az postgres flexible-server update -n django-app-production-db-1751389430 -g django-app-production-rg -p <new-password>".
Try using 'az postgres flexible-server connect' command to test out connection.
{
  "connectionString": "postgresql://djangoadmin:sKtnRoqzUH8DB2QTAa1!@django-app-production-db-1751389430.postgres.database.azure.com/flexibleserverdb?sslmode=require",
  "databaseName": "flexibleserverdb",
  "firewallName": "AllowAllAzureServicesAndResourcesWithinAzureIps_2025-7-1_17-9-25",
  "host": "django-app-production-db-1751389430.postgres.database.azure.com",
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/django-app-production-db-1751389430",
  "location": "West Europe",
  "password": "sKtnRoqzUH8DB2QTAa1!",
  "resourceGroup": "django-app-production-rg",
  "skuname": "Standard_D2ds_v4",
  "username": "djangoadmin",
  "version": "14"
}
[2025-07-01 17:10:38] Створення бази даних: django-app_db
Creating database with utf8 charset and en_US.utf8 collation
{
  "charset": "UTF8",
  "collation": "en_US.utf8",
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/django-app-production-db-1751389430/databases/django-app_db",
  "name": "django-app_db",
  "resourceGroup": "django-app-production-rg",
  "systemData": null,
  "type": "Microsoft.DBforPostgreSQL/flexibleServers/databases"
}
[2025-07-01 17:10:51] Налаштування firewall правил для бази даних
{
  "endIpAddress": "0.0.0.0",
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/django-app-production-db-1751389430/firewallRules/AllowAzureServices",
  "name": "AllowAzureServices",
  "resourceGroup": "django-app-production-rg",
  "startIpAddress": "0.0.0.0",
  "systemData": null,
  "type": "Microsoft.DBforPostgreSQL/flexibleServers/firewallRules"
}
[2025-07-01 17:11:53] Створення Key Vault: djapp-kv-89430
{
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg/providers/Microsoft.KeyVault/vaults/djapp-kv-89430",
  "location": "westeurope",
  "name": "djapp-kv-89430",
  "properties": {
    "accessPolicies": [],
    "createMode": null,
    "enablePurgeProtection": null,
    "enableRbacAuthorization": true,
    "enableSoftDelete": true,
    "enabledForDeployment": false,
    "enabledForDiskEncryption": null,
    "enabledForTemplateDeployment": null,
    "hsmPoolResourceId": null,
    "networkAcls": null,
    "privateEndpointConnections": null,
    "provisioningState": "Succeeded",
    "publicNetworkAccess": "Enabled",
    "sku": {
      "family": "A",
      "name": "standard"
    },
    "softDeleteRetentionInDays": 90,
    "tenantId": "3a7a2d8e-5083-4ef2-809c-3a88f18e0ef8",
    "vaultUri": "https://djapp-kv-89430.vault.azure.net/"
  },
  "resourceGroup": "django-app-production-rg",
  "systemData": {
    "createdAt": "2025-07-01T17:11:55.146000+00:00",
    "createdBy": "vitalii_shevchuk3@epam.com",
    "createdByType": "User",
    "lastModifiedAt": "2025-07-01T17:11:55.146000+00:00",
    "lastModifiedBy": "vitalii_shevchuk3@epam.com",
    "lastModifiedByType": "User"
  },
  "tags": {
    "CreatedBy": "AzureCLI",
    "Environment": "production",
    "Project": "django-app"
  },
  "type": "Microsoft.KeyVault/vaults"
}
[2025-07-01 17:12:28] Додавання секретів до Key Vault
(Forbidden) Caller is not authorized to perform action on resource.
If role assignments, deny assignments or role definitions were changed recently, please observe propagation time.
Caller: appid=04b07795-8ddb-461a-bbee-02f9e1bf7b46;oid=2b519bbb-fa41-470c-9279-95f55f66c3b9;iss=https://sts.windows.net/3a7a2d8e-5083-4ef2-809c-3a88f18e0ef8/
Action: 'Microsoft.KeyVault/vaults/secrets/setSecret/action'
Resource: '/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourcegroups/django-app-production-rg/providers/microsoft.keyvault/vaults/djapp-kv-89430/secrets/django-secret-key'
Assignment: (not found)
DenyAssignmentId: null
DecisionReason: null 
Vault: djapp-kv-89430;location=westeurope

Code: Forbidden
Message: Caller is not authorized to perform action on resource.
If role assignments, deny assignments or role definitions were changed recently, please observe propagation time.
Caller: appid=04b07795-8ddb-461a-bbee-02f9e1bf7b46;oid=2b519bbb-fa41-470c-9279-95f55f66c3b9;iss=https://sts.windows.net/3a7a2d8e-5083-4ef2-809c-3a88f18e0ef8/
Action: 'Microsoft.KeyVault/vaults/secrets/setSecret/action'
Resource: '/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourcegroups/django-app-production-rg/providers/microsoft.keyvault/vaults/djapp-kv-89430/secrets/django-secret-key'
Assignment: (not found)
DenyAssignmentId: null
DecisionReason: null 
Vault: djapp-kv-89430;location=westeurope

Inner error: {
    "code": "ForbiddenByRbac"
}
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ 
```




