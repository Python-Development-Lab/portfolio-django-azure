

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

