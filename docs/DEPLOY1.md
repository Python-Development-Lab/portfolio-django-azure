

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



