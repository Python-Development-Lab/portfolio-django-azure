#!/bin/bash
# =============================================================================
# Скрипт для створення БЮДЖЕТНОЇ інфраструктури Azure для Django додатку
# Вартість: ~$20-25/місяць
# =============================================================================

set -e  # Зупинити скрипт при помилці

# Кольори для виводу
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# =============================================================================
# БЮДЖЕТНА КОНФІГУРАЦІЯ - НАЛАШТУВАННЯ ДЛЯ МІНІМАЛЬНИХ ВИТРАТ
# =============================================================================

# Основні параметри
PROJECT_NAME="django-app"
ENVIRONMENT="budget"              # budget, dev, staging, production
LOCATION="West Europe"
TIMESTAMP=$(date +%s)

# Імена ресурсів
RESOURCE_GROUP_NAME="${PROJECT_NAME}-${ENVIRONMENT}-rg"
APP_SERVICE_PLAN_NAME="${PROJECT_NAME}-${ENVIRONMENT}-plan"
WEB_APP_NAME="${PROJECT_NAME}-${ENVIRONMENT}-${TIMESTAMP}"
DATABASE_SERVER_NAME="${PROJECT_NAME}-${ENVIRONMENT}-db-${TIMESTAMP}"
DATABASE_NAME="${PROJECT_NAME}_db"
STORAGE_ACCOUNT_NAME="djapp$(date +%s | tail -c 8)"
KEY_VAULT_NAME="djapp-kv-$(date +%s | tail -c 6)"
APP_INSIGHTS_NAME="${PROJECT_NAME}-${ENVIRONMENT}-insights"

# 💰 БЮДЖЕТНА КОНФІГУРАЦІЯ
APP_SERVICE_SKU="F1"              # 🆓 БЕЗКОШТОВНО (з обмеженнями)
PYTHON_VERSION="3.11"
DB_SKU="Standard_B1ms"            # 💵 $12-15/місяць (1 vCore, 2GB RAM)
DB_STORAGE_SIZE="32"              # Мінімальний розмір
STORAGE_SKU="Standard_LRS"        # Найдешевший тип сховища

# Конфігурація бази даних
DB_ADMIN_USER="djangoadmin"
DB_ADMIN_PASSWORD="$(openssl rand -base64 32 | tr -d '=/+' | cut -c1-16)Aa1!"

# Теги для ресурсів
TAGS="Environment=${ENVIRONMENT} Project=${PROJECT_NAME} CreatedBy=AzureCLI CostProfile=Budget"

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}💰 БЮДЖЕТНА AZURE INFRASTRUCTURE${NC}"
echo -e "${BLUE}============================================${NC}"
echo -e "${CYAN}Орієнтовна вартість: $20-25/місяць${NC}"
echo ""
echo "📊 Конфігурація:"
echo "  🚀 App Service: F1 (безкоштовно)"
echo "  🗄️  Database: Standard_B1ms (~$12-15)"
echo "  💾 Storage: Standard_LRS (~$2-5)"
echo "  🔐 Key Vault: ~$1"
echo "  📈 App Insights: безкоштовно (до 5GB)"
echo ""

log "Початок створення БЮДЖЕТНОЇ інфраструктури для Django додатку..."
log "Проект: ${PROJECT_NAME}"
log "Середовище: ${ENVIRONMENT}"
log "Регіон: ${LOCATION}"

# =============================================================================
# ПЕРЕВІРКА ЗАЛЕЖНОСТЕЙ
# =============================================================================

log "Перевірка залежностей..."

if ! command -v az &> /dev/null; then
    error "Azure CLI не встановлено. Встановіть його з https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
fi

if ! az account show &> /dev/null; then
    error "Ви не авторизовані в Azure CLI. Виконайте 'az login'"
fi

if ! command -v openssl &> /dev/null; then
    error "OpenSSL не встановлено"
fi

log "✅ Всі залежності встановлені"

# =============================================================================
# ПОКРОКОВИЙ АЛГОРИТМ СТВОРЕННЯ РЕСУРСІВ
# =============================================================================

info "🔄 КРОК 1/11: Створення Resource Group"
log "Створення Resource Group: ${RESOURCE_GROUP_NAME}"
az group create \
    --name "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --tags $TAGS

info "🔄 КРОК 2/11: Створення Storage Account (бюджетна конфігурація)"
log "Створення Storage Account: ${STORAGE_ACCOUNT_NAME}"
az storage account create \
    --name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --sku "$STORAGE_SKU" \
    --kind StorageV2 \
    --access-tier Hot \
    --tags $TAGS

# Створення контейнерів для статичних файлів та медіа
log "Створення контейнерів для статичних файлів"
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

info "🔄 КРОК 3/11: Створення PostgreSQL Database (бюджетна конфігурація)"
log "Створення PostgreSQL сервера: ${DATABASE_SERVER_NAME}"
warning "Використовується найдешевший SKU: $DB_SKU"
az postgres flexible-server create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$DATABASE_SERVER_NAME" \
    --location "$LOCATION" \
    --admin-user "$DB_ADMIN_USER" \
    --admin-password "$DB_ADMIN_PASSWORD" \
    --sku-name "$DB_SKU" \
    --storage-size "$DB_STORAGE_SIZE" \
    --version 14 \
    --public-access 0.0.0.0 \
    --tags $TAGS

info "🔄 КРОК 4/11: Створення бази даних"
log "Створення бази даних: ${DATABASE_NAME}"
az postgres flexible-server db create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --server-name "$DATABASE_SERVER_NAME" \
    --database-name "$DATABASE_NAME"

info "🔄 КРОК 5/11: Налаштування firewall правил"
log "Налаштування firewall правил для бази даних"
az postgres flexible-server firewall-rule create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$DATABASE_SERVER_NAME" \
    --rule-name "AllowAzureServices" \
    --start-ip-address 0.0.0.0 \
    --end-ip-address 0.0.0.0

info "🔄 КРОК 6/11: Створення Key Vault"
log "Створення Key Vault: ${KEY_VAULT_NAME}"
az keyvault create \
    --name "$KEY_VAULT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --enable-rbac-authorization false \
    --tags $TAGS

# Налаштування доступу до Key Vault
log "Налаштування прав доступу до Key Vault"
az keyvault set-policy \
    --name "$KEY_VAULT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --object-id "$(az ad signed-in-user show --query id --output tsv)" \
    --secret-permissions get list set delete

info "🔄 КРОК 7/11: Додавання секретів до Key Vault"
log "Генерація та додавання секретів"
DJANGO_SECRET_KEY=$(openssl rand -base64 50 | tr -d '=/+')

# Додавання секретів з перевіркою помилок
if az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "django-secret-key" \
    --value "$DJANGO_SECRET_KEY" >/dev/null 2>&1; then
    log "✅ Django secret key додано"
else
    warning "❌ Помилка додавання Django secret key"
fi

if az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "database-password" \
    --value "$DB_ADMIN_PASSWORD" >/dev/null 2>&1; then
    log "✅ Database password додано"
else
    warning "❌ Помилка додавання database password"
fi

if az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "storage-account-key" \
    --value "$STORAGE_KEY" >/dev/null 2>&1; then
    log "✅ Storage account key додано"
else
    warning "❌ Помилка додавання storage account key"
fi

info "🔄 КРОК 8/11: Створення Application Insights"
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

info "🔄 КРОК 9/11: Створення App Service Plan (БЕЗКОШТОВНИЙ F1)"
log "Створення App Service Plan: ${APP_SERVICE_PLAN_NAME}"
warning "Використовується безкоштовний план F1 з обмеженнями!"
az appservice plan create \
    --name "$APP_SERVICE_PLAN_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --sku "$APP_SERVICE_SKU" \
    --is-linux \
    --tags $TAGS

info "🔄 КРОК 10/11: Створення Web App"
log "Створення Web App: ${WEB_APP_NAME}"
az webapp create \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --plan "$APP_SERVICE_PLAN_NAME" \
    --runtime "PYTHON:${PYTHON_VERSION}" \
    --tags $TAGS

info "🔄 КРОК 11/11: Налаштування додатку"
log "Налаштування змінних середовища"
DATABASE_URL="postgresql://${DB_ADMIN_USER}:${DB_ADMIN_PASSWORD}@${DATABASE_SERVER_NAME}.postgres.database.azure.com:5432/${DATABASE_NAME}?sslmode=require"

az webapp config appsettings set \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --settings \
        DJANGO_SETTINGS_MODULE="config.settings.budget" \
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
        DJANGO_LOG_LEVEL="WARNING" \
        PYTHONPATH="/home/site/wwwroot"

# Налаштування startup команди для бюджетного режиму
log "Налаштування бюджетної конфігурації App Service"
az webapp config set \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --startup-file "gunicorn --bind=0.0.0.0 --timeout 300 --workers 1 config.wsgi"

# Обмежене логування для економії ресурсів
az webapp log config \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --application-logging filesystem \
    --level warning \
    --detailed-error-messages false \
    --failed-request-tracing false \
    --web-server-logging off

# Налаштування managed identity
log "Налаштування Managed Identity"
az webapp identity assign \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME"

# Отримання Principal ID та надання доступу до Key Vault
PRINCIPAL_ID=$(az webapp identity show \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --query "principalId" \
    --output tsv)

az keyvault set-policy \
    --name "$KEY_VAULT_NAME" \
    --object-id "$PRINCIPAL_ID" \
    --secret-permissions get list

# Увімкнення HTTPS
log "Увімкнення HTTPS"
az webapp update \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --https-only true

# =============================================================================
# СТВОРЕННЯ БЮДЖЕТНИХ ФАЙЛІВ КОНФІГУРАЦІЇ
# =============================================================================

log "Створення бюджетних файлів конфігурації"

# Створення мінімального requirements.txt для бюджетного режиму
cat > requirements.txt << 'EOF'
# БЮДЖЕТНА ВЕРСІЯ - мінімальні залежності
Django>=4.2,<5.0
psycopg2-binary>=2.9.0
gunicorn>=20.1.0
django-storages[azure]>=1.13.0
python-decouple>=3.6
whitenoise>=6.0.0
EOF

# Створення .env.example для бюджетного режиму
cat > .env.budget << EOF
# БЮДЖЕТНА КОНФІГУРАЦІЯ DJANGO
SECRET_KEY=your-secret-key-here
DEBUG=False
ALLOWED_HOSTS=${WEB_APP_NAME}.azurewebsites.net

# Database (бюджетна конфігурація)
DATABASE_URL=postgresql://user:password@host:port/database

# Azure Storage (бюджетна конфігурація)
AZURE_STORAGE_ACCOUNT_NAME=${STORAGE_ACCOUNT_NAME}
AZURE_STORAGE_ACCOUNT_KEY=your-storage-key
AZURE_STORAGE_CONTAINER_STATIC=static
AZURE_STORAGE_CONTAINER_MEDIA=media

# Application Insights (безкоштовна версія)
APPINSIGHTS_INSTRUMENTATIONKEY=${INSTRUMENTATION_KEY}

# Бюджетні налаштування
DJANGO_LOG_LEVEL=WARNING
WORKERS=1
TIMEOUT=300
EOF

# Створення бюджетного startup.sh
cat > startup.sh << 'EOF'
#!/bin/bash
# БЮДЖЕТНИЙ STARTUP СКРИПТ

echo "Starting Django application in BUDGET mode..."

# Швидке збирання статичних файлів
python manage.py collectstatic --noinput --clear

# Запуск міграцій
python manage.py migrate --noinput

# Бюджетний запуск з мінімальними ресурсами
exec gunicorn --bind=0.0.0.0:8000 --timeout 300 --workers 1 --max-requests 1000 --max-requests-jitter 100 config.wsgi:application
EOF

chmod +x startup.sh

# Створення бюджетних Django settings
cat > budget_settings.py << 'EOF'
"""
БЮДЖЕТНІ НАЛАШТУВАННЯ DJANGO
Оптимізовано для мінімальних витрат на Azure F1 + B1ms
"""

from decouple import config
import os

# БАЗОВІ НАЛАШТУВАННЯ
DEBUG = config('DEBUG', default=False, cast=bool)
SECRET_KEY = config('SECRET_KEY')
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='').split(',')

# БЮДЖЕТНА БАЗА ДАНИХ
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': config('DATABASE_URL'),
        'CONN_MAX_AGE': 600,  # Переіспользування з'єднань
        'OPTIONS': {
            'MAX_CONNS': 2,   # Мінімум з'єднань для B1ms
        }
    }
}

# БЮДЖЕТНІ МЕДІА ФАЙЛИ
DEFAULT_FILE_STORAGE = 'storages.backends.azure_storage.AzureStorage'
STATICFILES_STORAGE = 'django.contrib.staticfiles.storage.StaticFilesStorage'

# Azure Storage (тільки для медіа, статика через whitenoise)
AZURE_ACCOUNT_NAME = config('AZURE_STORAGE_ACCOUNT_NAME')
AZURE_ACCOUNT_KEY = config('AZURE_STORAGE_ACCOUNT_KEY')
AZURE_CONTAINER = config('AZURE_STORAGE_CONTAINER_MEDIA')

# Whitenoise для статичних файлів (економія на Storage операціях)
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',  # Бюджетна статика
    # ... інші middleware
]

STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# БЮДЖЕТНЕ КЕШУВАННЯ (без Redis - економія коштів)
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'budget-cache',
        'OPTIONS': {
            'MAX_ENTRIES': 300,  # Обмежений кеш
        }
    }
}

# МІНІМАЛЬНЕ ЛОГУВАННЯ
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'level': 'WARNING',  # Тільки попередження та помилки
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'WARNING',
    },
}

# БЮДЖЕТНІ НАЛАШТУВАННЯ ПРОДУКТИВНОСТІ
SESSION_ENGINE = 'django.contrib.sessions.backends.cached_db'
SESSION_CACHE_ALIAS = 'default'
SESSION_COOKIE_AGE = 1209600  # 2 тижні

# Вимкнення DEBUG toolbar та інших dev інструментів в budget режимі
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # Мінімальний набір для бюджетного режиму
]
EOF

# =============================================================================
# СТВОРЕННЯ CLEANUP СКРИПТУ
# =============================================================================

# Створення cleanup скрипту
cat > cleanup_budget_infrastructure.sh << 'EOF'
#!/bin/bash
# Скрипт видалення бюджетної інфраструктури

RESOURCE_GROUP_NAME="$RESOURCE_GROUP_NAME"

echo "🗑️  Видалення бюджетної інфраструктури..."
echo "Resource Group: $RESOURCE_GROUP_NAME"

read -p "Підтвердіть видалення (yes/no): " confirmation
if [[ "$confirmation" == "yes" ]]; then
    az group delete --name "$RESOURCE_GROUP_NAME" --yes --no-wait
    echo "✅ Бюджетна інфраструктура помічена для видалення"
else
    echo "❌ Операція скасована"
fi
EOF

chmod +x cleanup_budget_infrastructure.sh

# =============================================================================
# ПІДСУМОК БЮДЖЕТНОГО РОЗГОРТАННЯ
# =============================================================================

# Отримання URL додатку
APP_URL=$(az webapp show \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --query "defaultHostName" \
    --output tsv)

log "✅ БЮДЖЕТНА інфраструктура успішно створена!"

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}💰 БЮДЖЕТНЕ РОЗГОРТАННЯ ЗАВЕРШЕНО!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${CYAN}💵 ОРІЄНТОВНА ВАРТІСТЬ: $20-25/місяць${NC}"
echo ""
echo "📋 СТВОРЕНІ РЕСУРСИ:"
echo "🌍 Resource Group: $RESOURCE_GROUP_NAME"
echo "🚀 Web App: $WEB_APP_NAME (F1 - безкоштовно)"
echo "🔗 URL: https://$APP_URL"
echo "📊 App Service Plan: $APP_SERVICE_PLAN_NAME (F1)"
echo "🗄️  PostgreSQL Server: $DATABASE_SERVER_NAME (B1ms - ~$12-15)"
echo "🗃️  Database: $DATABASE_NAME"
echo "💾 Storage Account: $STORAGE_ACCOUNT_NAME (LRS - ~$2-5)"
echo "🔐 Key Vault: $KEY_VAULT_NAME (~$1)"
echo "📈 Application Insights: $APP_INSIGHTS_NAME (безкоштовно до 5GB)"
echo ""
echo -e "${YELLOW}⚠️  ОБМЕЖЕННЯ БЮДЖЕТНОЇ ВЕРСІЇ:${NC}"
echo "- F1 план: 60 хвилин CPU/день, 1GB RAM"
echo "- B1ms DB: 1 vCore, 2GB RAM, 32GB storage"
echo "- Без Always On (cold start можливий)"
echo "- Обмежене логування"
echo "- 1 worker process"
echo ""
echo "📁 СТВОРЕНІ ФАЙЛИ:"
echo "  ✅ requirements.txt - мінімальні залежності"
echo "  ✅ .env.budget - бюджетна конфігурація"
echo "  ✅ startup.sh - оптимізований startup"
echo "  ✅ budget_settings.py - бюджетні Django settings"
echo "  ✅ cleanup_budget_infrastructure.sh - видалення"
echo ""
echo "🔧 ДОСТУПИ:"
echo "Database Admin User: $DB_ADMIN_USER"
echo "Database Admin Password: $DB_ADMIN_PASSWORD"
echo ""
echo "🚀 НАСТУПНІ КРОКИ:"
echo "1. Використовуйте budget_settings.py у вашому Django проекті"
echo "2. Розгорніть код: az webapp deployment source config-zip"
echo "3. Моніторьте використання CPU (ліміт 60 хв/день для F1)"
echo "4. При необхідності оновіть до B1 (~$13/міс додатково)"
echo ""
echo -e "${GREEN}Ваш бюджетний Django додаток готовий! 🐍💰${NC}"
echo ""

# Збереження бюджетної конфігурації
cat > budget-infrastructure-summary.txt << EOF
БЮДЖЕТНА AZURE INFRASTRUCTURE SUMMARY
=====================================
Created: $(date)
Project: $PROJECT_NAME (Budget Edition)
Estimated Cost: $20-25/month

Resources:
- Resource Group: $RESOURCE_GROUP_NAME
- Web App: $WEB_APP_NAME (F1 Free)
- URL: https://$APP_URL
- Database Server: $DATABASE_SERVER_NAME (B1ms)
- Database: $DATABASE_NAME
- Storage Account: $STORAGE_ACCOUNT_NAME (LRS)
- Key Vault: $KEY_VAULT_NAME
- Application Insights: $APP_INSIGHTS_NAME

Cost Breakdown:
- App Service F1: $0/month (Free tier)
- PostgreSQL B1ms: $12-15/month
- Storage LRS: $2-5/month
- Key Vault: $1/month
- App Insights: $0/month (up to 5GB)

Limitations:
- F1: 60 CPU minutes/day, 1GB RAM
- No Always On (cold starts possible)
- Limited logging
- Single worker process

Database Credentials:
- Admin User: $DB_ADMIN_USER
- Admin Password: $DB_ADMIN_PASSWORD

Files Created:
- requirements.txt (minimal)
- .env.budget
- startup.sh (optimized)
- budget_settings.py
- cleanup_budget_infrastructure.sh

Next Steps:
1. Use budget_settings.py in your Django project
2. Deploy code with ZIP deployment
3. Monitor CPU usage (60 min/day limit)
4. Upgrade to B1 if needed (+$13/month)
EOF

log "📄 Бюджетна конфігурація збережена у файл: budget-infrastructure-summary.txt"

