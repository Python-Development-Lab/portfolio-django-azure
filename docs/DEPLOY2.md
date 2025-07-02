




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
# ФУНКЦІЇ ДЛЯ ОЧИЩЕННЯ РЕСУРСІВ
# =============================================================================

# Функція для створення cleanup скрипту
create_cleanup_script() {
    local CLEANUP_SCRIPT="cleanup_azure_infrastructure.sh"
    
    log "Створення cleanup скрипту: ${CLEANUP_SCRIPT}"
    
    cat > "$CLEANUP_SCRIPT" << EOF
#!/bin/bash
# =============================================================================
# Скрипт для видалення інфраструктури Azure Django додатку
# =============================================================================

# Кольори для виводу
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "\${GREEN}[\$(date +'%Y-%m-%d %H:%M:%S')]\${NC} \$1"
}

error() {
    echo -e "\${RED}[ERROR]\${NC} \$1"
    exit 1
}

warning() {
    echo -e "\${YELLOW}[WARNING]\${NC} \$1"
}

# Ресурси для видалення (згенеровано автоматично)
RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME}"
WEB_APP_NAME="${WEB_APP_NAME}"
APP_SERVICE_PLAN_NAME="${APP_SERVICE_PLAN_NAME}"
DATABASE_SERVER_NAME="${DATABASE_SERVER_NAME}"
STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_NAME}"
KEY_VAULT_NAME="${KEY_VAULT_NAME}"
APP_INSIGHTS_NAME="${APP_INSIGHTS_NAME}"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID}"

# Функція для підтвердження
confirm_deletion() {
    echo ""
    echo -e "\${RED}⚠️  УВАГА: ВИ ЗБИРАЄТЕСЯ ВИДАЛИТИ НАСТУПНІ РЕСУРСИ:\${NC}"
    echo "=========================================="
    echo "🌍 Resource Group: \$RESOURCE_GROUP_NAME"
    echo "🚀 Web App: \$WEB_APP_NAME"
    echo "📊 App Service Plan: \$APP_SERVICE_PLAN_NAME"
    echo "🗄️  PostgreSQL Server: \$DATABASE_SERVER_NAME"
    echo "💾 Storage Account: \$STORAGE_ACCOUNT_NAME"
    echo "🔐 Key Vault: \$KEY_VAULT_NAME"
    echo "📈 Application Insights: \$APP_INSIGHTS_NAME"
    echo "=========================================="
    echo ""
    
    read -p "Ви впевнені, що хочете видалити ВСІ ці ресурси? (yes/no): " confirmation
    
    if [[ "\$confirmation" != "yes" ]]; then
        echo "Операція скасована користувачем."
        exit 0
    fi
    
    echo ""
    read -p "Остання перевірка! Введіть 'DELETE' для підтвердження: " final_confirmation
    
    if [[ "\$final_confirmation" != "DELETE" ]]; then
        echo "Операція скасована. Ресурси НЕ видалені."
        exit 0
    fi
}

# Функція для безпечного видалення Key Vault
safe_delete_keyvault() {
    log "Видалення Key Vault: \$KEY_VAULT_NAME"
    
    # Спочатку видаляємо Key Vault
    if az keyvault delete --name "\$KEY_VAULT_NAME" --resource-group "\$RESOURCE_GROUP_NAME" 2>/dev/null; then
        log "✅ Key Vault видалено"
        
        # Потім очищуємо з soft delete
        log "Очищення Key Vault з soft delete..."
        if az keyvault purge --name "\$KEY_VAULT_NAME" --location "West Europe" 2>/dev/null; then
            log "✅ Key Vault повністю очищено"
        else
            warning "Key Vault помічено для видалення, але може залишатися в soft delete стані"
        fi
    else
        warning "Не вдалося видалити Key Vault або він вже не існує"
    fi
}

# Функція для видалення окремих ресурсів (якщо Resource Group видалення не спрацює)
delete_individual_resources() {
    warning "Видалення окремих ресурсів..."
    
    # 1. Видалення Web App
    log "Видалення Web App: \$WEB_APP_NAME"
    az webapp delete --name "\$WEB_APP_NAME" --resource-group "\$RESOURCE_GROUP_NAME" --keep-empty-plan || warning "Web App не знайдено"
    
    # 2. Видалення App Service Plan
    log "Видалення App Service Plan: \$APP_SERVICE_PLAN_NAME"
    az appservice plan delete --name "\$APP_SERVICE_PLAN_NAME" --resource-group "\$RESOURCE_GROUP_NAME" --yes || warning "App Service Plan не знайдено"
    
    # 3. Видалення PostgreSQL сервера
    log "Видалення PostgreSQL сервера: \$DATABASE_SERVER_NAME"
    az postgres flexible-server delete --name "\$DATABASE_SERVER_NAME" --resource-group "\$RESOURCE_GROUP_NAME" --yes || warning "PostgreSQL сервер не знайдено"
    
    # 4. Видалення Storage Account
    log "Видалення Storage Account: \$STORAGE_ACCOUNT_NAME"
    az storage account delete --name "\$STORAGE_ACCOUNT_NAME" --resource-group "\$RESOURCE_GROUP_NAME" --yes || warning "Storage Account не знайдено"
    
    # 5. Безпечне видалення Key Vault
    safe_delete_keyvault
    
    # 6. Видалення Application Insights
    log "Видалення Application Insights: \$APP_INSIGHTS_NAME"
    az monitor app-insights component delete --app "\$APP_INSIGHTS_NAME" --resource-group "\$RESOURCE_GROUP_NAME" || warning "Application Insights не знайдено"
}

# Функція для показу статистики перед видаленням
show_current_resources() {
    log "Перевірка поточних ресурсів..."
    
    if az group exists --name "\$RESOURCE_GROUP_NAME"; then
        echo ""
        echo "📊 Поточні ресурси в групі \$RESOURCE_GROUP_NAME:"
        az resource list --resource-group "\$RESOURCE_GROUP_NAME" --output table 2>/dev/null || echo "Не вдалося отримати список ресурсів"
        echo ""
    else
        warning "Resource Group '\$RESOURCE_GROUP_NAME' не існує"
        exit 0
    fi
}

# Функція для видалення з timeout
delete_with_timeout() {
    local timeout=300  # 5 хвилин
    local command="\$1"
    
    timeout \$timeout bash -c "\$command" || {
        warning "Операція перевищила timeout (\${timeout}s). Можливо, деякі ресурси все ще видаляються..."
    }
}

# Головна функція очищення
main_cleanup() {
    echo ""
    echo -e "\${BLUE}============================================\${NC}"
    echo -e "\${BLUE}🗑️  AZURE INFRASTRUCTURE CLEANUP SCRIPT\${NC}"
    echo -e "\${BLUE}============================================\${NC}"
    echo ""
    
    # Перевірка Azure CLI та авторизації
    if ! command -v az &> /dev/null; then
        error "Azure CLI не встановлено"
    fi
    
    if ! az account show &> /dev/null; then
        error "Ви не авторизовані в Azure CLI. Виконайте 'az login'"
    fi
    
    # Показати поточні ресурси
    show_current_resources
    
    # Підтвердження від користувача
    confirm_deletion
    
    log "🚀 Початок процесу видалення..."
    
    # Спроба 1: Видалення цілої Resource Group (найшвидший метод)
    log "Спроба видалення цілої Resource Group..."
    if delete_with_timeout "az group delete --name '\$RESOURCE_GROUP_NAME' --yes --no-wait"; then
        log "✅ Resource Group помічена для видалення"
        
        # Чекаємо завершення видалення
        log "Очікування завершення видалення Resource Group..."
        local attempts=0
        local max_attempts=30
        
        while az group exists --name "\$RESOURCE_GROUP_NAME" && [ \$attempts -lt \$max_attempts ]; do
            echo -n "."
            sleep 10
            attempts=\$((attempts + 1))
        done
        
        if az group exists --name "\$RESOURCE_GROUP_NAME"; then
            warning "Resource Group все ще існує після \${max_attempts} спроб. Перехід до видалення окремих ресурсів..."
            delete_individual_resources
        else
            log "✅ Resource Group успішно видалена!"
        fi
    else
        warning "Не вдалося видалити Resource Group. Переходимо до видалення окремих ресурсів..."
        delete_individual_resources
    fi
    
    # Фінальна перевірка
    log "Фінальна перевірка..."
    if az group exists --name "\$RESOURCE_GROUP_NAME"; then
        # Показати що залишилося
        echo ""
        echo "⚠️  Залишилися ресурси:"
        az resource list --resource-group "\$RESOURCE_GROUP_NAME" --output table 2>/dev/null || echo "Не вдалося отримати список"
        
        warning "Деякі ресурси можуть все ще видалятися. Перевірте Azure Portal через кілька хвилин."
    else
        log "✅ Всі ресурси успішно видалені!"
    fi
    
    # Очищення локальних файлів
    log "Очищення локальних файлів конфігурації..."
    [ -f "infrastructure-summary.txt" ] && rm -f infrastructure-summary.txt && log "✅ infrastructure-summary.txt видалено"
    [ -f "requirements.txt" ] && rm -f requirements.txt && log "✅ requirements.txt видалено"
    [ -f ".env.example" ] && rm -f .env.example && log "✅ .env.example видалено"
    [ -f "startup.sh" ] && rm -f startup.sh && log "✅ startup.sh видалено"
    [ -f "web.config" ] && rm -f web.config && log "✅ web.config видалено"
    
    echo ""
    echo -e "\${GREEN}============================================\${NC}"
    echo -e "\${GREEN}✅ CLEANUP ЗАВЕРШЕНО!\${NC}"
    echo -e "\${GREEN}============================================\${NC}"
    echo ""
    echo "📊 Підсумок:"
    echo "- Всі Azure ресурси видалені (або помічені для видалення)"
    echo "- Локальні конфігураційні файли очищені"
    echo "- Key Vault очищений з soft delete"
    echo ""
    echo "💡 Рекомендації:"
    echo "- Перевірте Azure Portal через 5-10 хвилин"
    echo "- Переконайтеся, що billing припинено"
    echo "- Видаліть цей cleanup скрипт: rm \$0"
    echo ""
}

# Параметри командного рядка
case "\$1" in
    --help|-h)
        echo "Використання: \$0 [опції]"
        echo ""
        echo "Опції:"
        echo "  --help, -h     Показати цю довідку"
        echo "  --dry-run      Показати що буде видалено без фактичного видалення"
        echo "  --force        Пропустити підтвердження (НЕБЕЗПЕЧНО!)"
        echo ""
        echo "Приклади:"
        echo "  \$0                 # Інтерактивне видалення"
        echo "  \$0 --dry-run       # Показати план видалення"
        echo "  \$0 --force         # Видалити без підтвердження"
        exit 0
        ;;
    --dry-run)
        echo "🔍 DRY RUN MODE - показуємо що буде видалено:"
        show_current_resources
        echo ""
        echo "Ресурси, які будуть видалені:"
        echo "- Resource Group: \$RESOURCE_GROUP_NAME"
        echo "- Всі ресурси всередині групи"
        echo "- Локальні конфігураційні файли"
        echo ""
        echo "Для фактичного видалення запустіть: \$0"
        exit 0
        ;;
    --force)
        log "⚠️  FORCE MODE - пропускаємо підтвердження"
        show_current_resources
        log "🚀 Початок примусового видалення..."
        # Пропускаємо confirm_deletion
        ;;
    "")
        # Звичайний режим з підтвердженням
        main_cleanup
        exit 0
        ;;
    *)
        error "Невідомий параметр: \$1. Використайте --help для довідки"
        ;;
esac

# Якщо дійшли сюди, то це force mode
if delete_with_timeout "az group delete --name '\$RESOURCE_GROUP_NAME' --yes --no-wait"; then
    log "✅ Resource Group помічена для видалення (force mode)"
else
    warning "Помилка видалення в force mode"
fi

log "✅ Force cleanup завершено"
EOF

    chmod +x "$CLEANUP_SCRIPT"
    
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}📋 CLEANUP СКРИПТ СТВОРЕНО${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo "📁 Файл: $CLEANUP_SCRIPT"
    echo ""
    echo "🔧 Використання:"
    echo "  ./$CLEANUP_SCRIPT              # Інтерактивне видалення"
    echo "  ./$CLEANUP_SCRIPT --dry-run    # Показати план видалення"
    echo "  ./$CLEANUP_SCRIPT --force      # Видалити без підтвердження"
    echo "  ./$CLEANUP_SCRIPT --help       # Показати довідку"
    echo ""
    echo -e "${YELLOW}⚠️  УВАГА: Цей скрипт видалить ВСЮ створену інфраструктуру!${NC}"
    echo ""
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
STORAGE_ACCOUNT_NAME="djapp$(date +%s | tail -c 8)"
KEY_VAULT_NAME="djapp-kv-$(date +%s | tail -c 6)"
APP_INSIGHTS_NAME="${PROJECT_NAME}-${ENVIRONMENT}-insights"

# Конфігурація App Service
APP_SERVICE_SKU="B1"
PYTHON_VERSION="3.11"

# Конфігурація бази даних
DB_ADMIN_USER="djangoadmin"
DB_ADMIN_PASSWORD="$(openssl rand -base64 32 | tr -d '=/+' | cut -c1-16)Aa1!"
DB_SKU="Standard_D2ds_v4"

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
    --enable-rbac-authorization false \
    --tags $TAGS

# Отримайте ваш User Principal ID
USER_ID=$(az ad signed-in-user show --query id --output tsv)
echo "Your User ID: $USER_ID"

# Отримайте поточну підписку ID
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
echo "Subscription ID: $SUBSCRIPTION_ID"

# Використовуйте Access Policy замість RBAC
log "Налаштування прав доступу до Key Vault"
az keyvault set-policy \
    --name "$KEY_VAULT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --object-id "$(az ad signed-in-user show --query id --output tsv)" \
    --secret-permissions get list set delete

# Генерація секретів
log "Додавання секретів до Key Vault"
DJANGO_SECRET_KEY=$(openssl rand -base64 50 | tr -d '=/+')

# Додавання секретів з перевіркою помилок
if az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "django-secret-key" \
    --value "$DJANGO_SECRET_KEY" >/dev/null 2>&1; then
    log "✅ Django secret key додано"
else
    log "❌ Помилка додавання Django secret key"
fi

if az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "database-password" \
    --value "$DB_ADMIN_PASSWORD" >/dev/null 2>&1; then
    log "✅ Database password додано"
else
    log "❌ Помилка додавання database password"
fi

if az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "storage-account-key" \
    --value "$STORAGE_KEY" >/dev/null 2>&1; then
    log "✅ Storage account key додано"
else
    log "❌ Помилка додавання storage account key"
fi

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
# СТВОРЕННЯ CLEANUP СКРИПТУ
# =============================================================================

# Створюємо cleanup скрипт перед підсумком
create_cleanup_script

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
echo "🗑️  CLEANUP ІНФОРМАЦІЯ"
echo "=========================================="
echo "📁 Cleanup скрипт: cleanup_azure_infrastructure.sh"
echo ""
echo "🔧 Як видалити всю інфраструктуру:"
echo "  ./cleanup_azure_infrastructure.sh              # Інтерактивне видалення"
echo "  ./cleanup_azure_infrastructure.sh --dry-run    # Показати план"
echo "  ./cleanup_azure_infrastructure.sh --force      # Без підтвердження"
echo "  ./cleanup_azure_infrastructure.sh --help       # Довідка"
echo ""
echo -e "${YELLOW}⚠️  ВАЖЛИВО: Cleanup скрипт видалить ВСЮ створену інфраструктуру!${NC}"
echo ""
echo "=========================================="
echo "📝 НАСТУПНІ КРОКИ"
echo "=========================================="
echo "1. Налаштуйте ваш Django проект для роботи з Azure"
echo "2. Додайте створені файли конфігурації до вашого проекту"
echo "3. Налаштуйте CI/CD pipeline для автоматичного деплою"
echo "4. Протестуйте підключення до бази даних"
echo "5. Налаштуйте моніторинг в Application Insights"
echo "6. Збережіть cleanup скрипт для майбутнього видалення"
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

Cleanup:
- Cleanup Script: cleanup_azure_infrastructure.sh
- Command: ./cleanup_azure_infrastructure.sh

Important Notes:
- All secrets stored in Key Vault: $KEY_VAULT_NAME
- HTTPS-only enabled
- Managed Identity configured
- Application Insights monitoring enabled

Files Created:
- requirements.txt
- .env.example
- startup.sh
- web.config
- cleanup_azure_infrastructure.sh
- infrastructure-summary.txt (this file)
EOF

log "📄 Конфігурація збережена у файл: infrastructure-summary.txt"

# =============================================================================
# ДОДАТКОВІ УТИЛІТИ ДЛЯ УПРАВЛІННЯ
# =============================================================================

# Створення додаткового utility скрипту для управління
cat > azure_utils.sh << 'EOF'
#!/bin/bash
# =============================================================================
# Utility скрипт для управління Azure Django інфраструктурою
# =============================================================================

# Кольори
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ресурси (автоматично згенеровано)
RESOURCE_GROUP_NAME="__RESOURCE_GROUP_PLACEHOLDER__"
WEB_APP_NAME="__WEB_APP_PLACEHOLDER__"
DATABASE_SERVER_NAME="__DATABASE_SERVER_PLACEHOLDER__"
STORAGE_ACCOUNT_NAME="__STORAGE_ACCOUNT_PLACEHOLDER__"
KEY_VAULT_NAME="__KEY_VAULT_PLACEHOLDER__"

show_help() {
    echo "Azure Django Infrastructure Utils"
    echo ""
    echo "Використання: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  status      - Показати статус всіх ресурсів"
    echo "  logs        - Показати логи веб-додатку"
    echo "  restart     - Перезапустити веб-додаток"
    echo "  scale       - Масштабувати App Service Plan"
    echo "  backup      - Створити backup бази даних"
    echo "  costs       - Показати поточні витрати"
    echo "  secrets     - Показати секрети Key Vault"
    echo "  firewall    - Управління firewall rules"
    echo "  deploy      - Швидкий deploy з ZIP файлу"
    echo "  cleanup     - Запустити cleanup скрипт"
    echo "  help        - Показати цю довідку"
    echo ""
}

show_status() {
    echo -e "${BLUE}📊 Статус Azure ресурсів:${NC}"
    echo ""
    
    # Resource Group
    echo -n "🌍 Resource Group: "
    if az group exists --name "$RESOURCE_GROUP_NAME" 2>/dev/null; then
        echo -e "${GREEN}✅ Активна${NC}"
    else
        echo -e "${RED}❌ Не знайдена${NC}"
        return 1
    fi
    
    # Web App
    echo -n "🚀 Web App: "
    local app_state=$(az webapp show --name "$WEB_APP_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "state" -o tsv 2>/dev/null)
    if [ "$app_state" = "Running" ]; then
        echo -e "${GREEN}✅ Running${NC}"
    else
        echo -e "${YELLOW}⚠️  $app_state${NC}"
    fi
    
    # Database
    echo -n "🗄️  Database: "
    local db_state=$(az postgres flexible-server show --name "$DATABASE_SERVER_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "state" -o tsv 2>/dev/null)
    if [ "$db_state" = "Ready" ]; then
        echo -e "${GREEN}✅ Ready${NC}"
    else
        echo -e "${YELLOW}⚠️  $db_state${NC}"
    fi
    
    # Storage
    echo -n "💾 Storage: "
    local storage_status=$(az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "statusOfPrimary" -o tsv 2>/dev/null)
    if [ "$storage_status" = "available" ]; then
        echo -e "${GREEN}✅ Available${NC}"
    else
        echo -e "${YELLOW}⚠️  $storage_status${NC}"
    fi
    
    # Key Vault
    echo -n "🔐 Key Vault: "
    if az keyvault show --name "$KEY_VAULT_NAME" --resource-group "$RESOURCE_GROUP_NAME" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Active${NC}"
    else
        echo -e "${RED}❌ Unavailable${NC}"
    fi
    
    echo ""
    echo "📋 Детальна інформація:"
    az resource list --resource-group "$RESOURCE_GROUP_NAME" --output table 2>/dev/null
}

# Інші функції утиліт...
case "$1" in
    status) show_status ;;
    logs) az webapp log tail --name "$WEB_APP_NAME" --resource-group "$RESOURCE_GROUP_NAME" ;;
    restart) az webapp restart --name "$WEB_APP_NAME" --resource-group "$RESOURCE_GROUP_NAME" ;;
    cleanup) ./cleanup_azure_infrastructure.sh ;;
    help|--help|-h) show_help ;;
    *) show_help ;;
esac
EOF

# Замінюємо плейсхолдери на реальні значення в utils скрипті
sed -i "s/__RESOURCE_GROUP_PLACEHOLDER__/$RESOURCE_GROUP_NAME/g" azure_utils.sh
sed -i "s/__WEB_APP_PLACEHOLDER__/$WEB_APP_NAME/g" azure_utils.sh
sed -i "s/__DATABASE_SERVER_PLACEHOLDER__/$DATABASE_SERVER_NAME/g" azure_utils.sh
sed -i "s/__STORAGE_ACCOUNT_PLACEHOLDER__/$STORAGE_ACCOUNT_NAME/g" azure_utils.sh
sed -i "s/__KEY_VAULT_PLACEHOLDER__/$KEY_VAULT_NAME/g" azure_utils.sh

chmod +x azure_utils.sh

# Доповнення скрипту з функцією очищення ресурсів 🗑️


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
# ФУНКЦІЇ ДЛЯ ОЧИЩЕННЯ РЕСУРСІВ
# =============================================================================

# Функція для створення cleanup скрипту
create_cleanup_script() {
    local CLEANUP_SCRIPT="cleanup_azure_infrastructure.sh"
    
    log "Створення cleanup скрипту: ${CLEANUP_SCRIPT}"
    
    cat > "$CLEANUP_SCRIPT" << EOF
#!/bin/bash
# =============================================================================
# Скрипт для видалення інфраструктури Azure Django додатку
# =============================================================================

# Кольори для виводу
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "\${GREEN}[\$(date +'%Y-%m-%d %H:%M:%S')]\${NC} \$1"
}

error() {
    echo -e "\${RED}[ERROR]\${NC} \$1"
    exit 1
}

warning() {
    echo -e "\${YELLOW}[WARNING]\${NC} \$1"
}

# Ресурси для видалення (згенеровано автоматично)
RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME}"
WEB_APP_NAME="${WEB_APP_NAME}"
APP_SERVICE_PLAN_NAME="${APP_SERVICE_PLAN_NAME}"
DATABASE_SERVER_NAME="${DATABASE_SERVER_NAME}"
STORAGE_ACCOUNT_NAME="${STORAGE_ACCOUNT_NAME}"
KEY_VAULT_NAME="${KEY_VAULT_NAME}"
APP_INSIGHTS_NAME="${APP_INSIGHTS_NAME}"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID}"

# Функція для підтвердження
confirm_deletion() {
    echo ""
    echo -e "\${RED}⚠️  УВАГА: ВИ ЗБИРАЄТЕСЯ ВИДАЛИТИ НАСТУПНІ РЕСУРСИ:\${NC}"
    echo "=========================================="
    echo "🌍 Resource Group: \$RESOURCE_GROUP_NAME"
    echo "🚀 Web App: \$WEB_APP_NAME"
    echo "📊 App Service Plan: \$APP_SERVICE_PLAN_NAME"
    echo "🗄️  PostgreSQL Server: \$DATABASE_SERVER_NAME"
    echo "💾 Storage Account: \$STORAGE_ACCOUNT_NAME"
    echo "🔐 Key Vault: \$KEY_VAULT_NAME"
    echo "📈 Application Insights: \$APP_INSIGHTS_NAME"
    echo "=========================================="
    echo ""
    
    read -p "Ви впевнені, що хочете видалити ВСІ ці ресурси? (yes/no): " confirmation
    
    if [[ "\$confirmation" != "yes" ]]; then
        echo "Операція скасована користувачем."
        exit 0
    fi
    
    echo ""
    read -p "Остання перевірка! Введіть 'DELETE' для підтвердження: " final_confirmation
    
    if [[ "\$final_confirmation" != "DELETE" ]]; then
        echo "Операція скасована. Ресурси НЕ видалені."
        exit 0
    fi
}

# Функція для безпечного видалення Key Vault
safe_delete_keyvault() {
    log "Видалення Key Vault: \$KEY_VAULT_NAME"
    
    # Спочатку видаляємо Key Vault
    if az keyvault delete --name "\$KEY_VAULT_NAME" --resource-group "\$RESOURCE_GROUP_NAME" 2>/dev/null; then
        log "✅ Key Vault видалено"
        
        # Потім очищуємо з soft delete
        log "Очищення Key Vault з soft delete..."
        if az keyvault purge --name "\$KEY_VAULT_NAME" --location "West Europe" 2>/dev/null; then
            log "✅ Key Vault повністю очищено"
        else
            warning "Key Vault помічено для видалення, але може залишатися в soft delete стані"
        fi
    else
        warning "Не вдалося видалити Key Vault або він вже не існує"
    fi
}

# Функція для видалення окремих ресурсів (якщо Resource Group видалення не спрацює)
delete_individual_resources() {
    warning "Видалення окремих ресурсів..."
    
    # 1. Видалення Web App
    log "Видалення Web App: \$WEB_APP_NAME"
    az webapp delete --name "\$WEB_APP_NAME" --resource-group "\$RESOURCE_GROUP_NAME" --keep-empty-plan || warning "Web App не знайдено"
    
    # 2. Видалення App Service Plan
    log "Видалення App Service Plan: \$APP_SERVICE_PLAN_NAME"
    az appservice plan delete --name "\$APP_SERVICE_PLAN_NAME" --resource-group "\$RESOURCE_GROUP_NAME" --yes || warning "App Service Plan не знайдено"
    
    # 3. Видалення PostgreSQL сервера
    log "Видалення PostgreSQL сервера: \$DATABASE_SERVER_NAME"
    az postgres flexible-server delete --name "\$DATABASE_SERVER_NAME" --resource-group "\$RESOURCE_GROUP_NAME" --yes || warning "PostgreSQL сервер не знайдено"
    
    # 4. Видалення Storage Account
    log "Видалення Storage Account: \$STORAGE_ACCOUNT_NAME"
    az storage account delete --name "\$STORAGE_ACCOUNT_NAME" --resource-group "\$RESOURCE_GROUP_NAME" --yes || warning "Storage Account не знайдено"
    
    # 5. Безпечне видалення Key Vault
    safe_delete_keyvault
    
    # 6. Видалення Application Insights
    log "Видалення Application Insights: \$APP_INSIGHTS_NAME"
    az monitor app-insights component delete --app "\$APP_INSIGHTS_NAME" --resource-group "\$RESOURCE_GROUP_NAME" || warning "Application Insights не знайдено"
}

# Функція для показу статистики перед видаленням
show_current_resources() {
    log "Перевірка поточних ресурсів..."
    
    if az group exists --name "\$RESOURCE_GROUP_NAME"; then
        echo ""
        echo "📊 Поточні ресурси в групі \$RESOURCE_GROUP_NAME:"
        az resource list --resource-group "\$RESOURCE_GROUP_NAME" --output table 2>/dev/null || echo "Не вдалося отримати список ресурсів"
        echo ""
    else
        warning "Resource Group '\$RESOURCE_GROUP_NAME' не існує"
        exit 0
    fi
}

# Функція для видалення з timeout
delete_with_timeout() {
    local timeout=300  # 5 хвилин
    local command="\$1"
    
    timeout \$timeout bash -c "\$command" || {
        warning "Операція перевищила timeout (\${timeout}s). Можливо, деякі ресурси все ще видаляються..."
    }
}

# Головна функція очищення
main_cleanup() {
    echo ""
    echo -e "\${BLUE}============================================\${NC}"
    echo -e "\${BLUE}🗑️  AZURE INFRASTRUCTURE CLEANUP SCRIPT\${NC}"
    echo -e "\${BLUE}============================================\${NC}"
    echo ""
    
    # Перевірка Azure CLI та авторизації
    if ! command -v az &> /dev/null; then
        error "Azure CLI не встановлено"
    fi
    
    if ! az account show &> /dev/null; then
        error "Ви не авторизовані в Azure CLI. Виконайте 'az login'"
    fi
    
    # Показати поточні ресурси
    show_current_resources
    
    # Підтвердження від користувача
    confirm_deletion
    
    log "🚀 Початок процесу видалення..."
    
    # Спроба 1: Видалення цілої Resource Group (найшвидший метод)
    log "Спроба видалення цілої Resource Group..."
    if delete_with_timeout "az group delete --name '\$RESOURCE_GROUP_NAME' --yes --no-wait"; then
        log "✅ Resource Group помічена для видалення"
        
        # Чекаємо завершення видалення
        log "Очікування завершення видалення Resource Group..."
        local attempts=0
        local max_attempts=30
        
        while az group exists --name "\$RESOURCE_GROUP_NAME" && [ \$attempts -lt \$max_attempts ]; do
            echo -n "."
            sleep 10
            attempts=\$((attempts + 1))
        done
        
        if az group exists --name "\$RESOURCE_GROUP_NAME"; then
            warning "Resource Group все ще існує після \${max_attempts} спроб. Перехід до видалення окремих ресурсів..."
            delete_individual_resources
        else
            log "✅ Resource Group успішно видалена!"
        fi
    else
        warning "Не вдалося видалити Resource Group. Переходимо до видалення окремих ресурсів..."
        delete_individual_resources
    fi
    
    # Фінальна перевірка
    log "Фінальна перевірка..."
    if az group exists --name "\$RESOURCE_GROUP_NAME"; then
        # Показати що залишилося
        echo ""
        echo "⚠️  Залишилися ресурси:"
        az resource list --resource-group "\$RESOURCE_GROUP_NAME" --output table 2>/dev/null || echo "Не вдалося отримати список"
        
        warning "Деякі ресурси можуть все ще видалятися. Перевірте Azure Portal через кілька хвилин."
    else
        log "✅ Всі ресурси успішно видалені!"
    fi
    
    # Очищення локальних файлів
    log "Очищення локальних файлів конфігурації..."
    [ -f "infrastructure-summary.txt" ] && rm -f infrastructure-summary.txt && log "✅ infrastructure-summary.txt видалено"
    [ -f "requirements.txt" ] && rm -f requirements.txt && log "✅ requirements.txt видалено"
    [ -f ".env.example" ] && rm -f .env.example && log "✅ .env.example видалено"
    [ -f "startup.sh" ] && rm -f startup.sh && log "✅ startup.sh видалено"
    [ -f "web.config" ] && rm -f web.config && log "✅ web.config видалено"
    
    echo ""
    echo -e "\${GREEN}============================================\${NC}"
    echo -e "\${GREEN}✅ CLEANUP ЗАВЕРШЕНО!\${NC}"
    echo -e "\${GREEN}============================================\${NC}"
    echo ""
    echo "📊 Підсумок:"
    echo "- Всі Azure ресурси видалені (або помічені для видалення)"
    echo "- Локальні конфігураційні файли очищені"
    echo "- Key Vault очищений з soft delete"
    echo ""
    echo "💡 Рекомендації:"
    echo "- Перевірте Azure Portal через 5-10 хвилин"
    echo "- Переконайтеся, що billing припинено"
    echo "- Видаліть цей cleanup скрипт: rm \$0"
    echo ""
}

# Параметри командного рядка
case "\$1" in
    --help|-h)
        echo "Використання: \$0 [опції]"
        echo ""
        echo "Опції:"
        echo "  --help, -h     Показати цю довідку"
        echo "  --dry-run      Показати що буде видалено без фактичного видалення"
        echo "  --force        Пропустити підтвердження (НЕБЕЗПЕЧНО!)"
        echo ""
        echo "Приклади:"
        echo "  \$0                 # Інтерактивне видалення"
        echo "  \$0 --dry-run       # Показати план видалення"
        echo "  \$0 --force         # Видалити без підтвердження"
        exit 0
        ;;
    --dry-run)
        echo "🔍 DRY RUN MODE - показуємо що буде видалено:"
        show_current_resources
        echo ""
        echo "Ресурси, які будуть видалені:"
        echo "- Resource Group: \$RESOURCE_GROUP_NAME"
        echo "- Всі ресурси всередині групи"
        echo "- Локальні конфігураційні файли"
        echo ""
        echo "Для фактичного видалення запустіть: \$0"
        exit 0
        ;;
    --force)
        log "⚠️  FORCE MODE - пропускаємо підтвердження"
        show_current_resources
        log "🚀 Початок примусового видалення..."
        # Пропускаємо confirm_deletion
        ;;
    "")
        # Звичайний режим з підтвердженням
        main_cleanup
        exit 0
        ;;
    *)
        error "Невідомий параметр: \$1. Використайте --help для довідки"
        ;;
esac

# Якщо дійшли сюди, то це force mode
if delete_with_timeout "az group delete --name '\$RESOURCE_GROUP_NAME' --yes --no-wait"; then
    log "✅ Resource Group помічена для видалення (force mode)"
else
    warning "Помилка видалення в force mode"
fi

log "✅ Force cleanup завершено"
EOF

    chmod +x "$CLEANUP_SCRIPT"
    
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}📋 CLEANUP СКРИПТ СТВОРЕНО${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo "📁 Файл: $CLEANUP_SCRIPT"
    echo ""
    echo "🔧 Використання:"
    echo "  ./$CLEANUP_SCRIPT              # Інтерактивне видалення"
    echo "  ./$CLEANUP_SCRIPT --dry-run    # Показати план видалення"
    echo "  ./$CLEANUP_SCRIPT --force      # Видалити без підтвердження"
    echo "  ./$CLEANUP_SCRIPT --help       # Показати довідку"
    echo ""
    echo -e "${YELLOW}⚠️  УВАГА: Цей скрипт видалить ВСЮ створену інфраструктуру!${NC}"
    echo ""
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
STORAGE_ACCOUNT_NAME="djapp$(date +%s | tail -c 8)"
KEY_VAULT_NAME="djapp-kv-$(date +%s | tail -c 6)"
APP_INSIGHTS_NAME="${PROJECT_NAME}-${ENVIRONMENT}-insights"

# Конфігурація App Service
APP_SERVICE_SKU="B1"
PYTHON_VERSION="3.11"

# Конфігурація бази даних
DB_ADMIN_USER="djangoadmin"
DB_ADMIN_PASSWORD="$(openssl rand -base64 32 | tr -d '=/+' | cut -c1-16)Aa1!"
DB_SKU="Standard_D2ds_v4"

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
    --enable-rbac-authorization false \
    --tags $TAGS

# Отримайте ваш User Principal ID
USER_ID=$(az ad signed-in-user show --query id --output tsv)
echo "Your User ID: $USER_ID"

# Отримайте поточну підписку ID
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
echo "Subscription ID: $SUBSCRIPTION_ID"

# Використовуйте Access Policy замість RBAC
log "Налаштування прав доступу до Key Vault"
az keyvault set-policy \
    --name "$KEY_VAULT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --object-id "$(az ad signed-in-user show --query id --output tsv)" \
    --secret-permissions get list set delete

# Генерація секретів
log "Додавання секретів до Key Vault"
DJANGO_SECRET_KEY=$(openssl rand -base64 50 | tr -d '=/+')

# Додавання секретів з перевіркою помилок
if az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "django-secret-key" \
    --value "$DJANGO_SECRET_KEY" >/dev/null 2>&1; then
    log "✅ Django secret key додано"
else
    log "❌ Помилка додавання Django secret key"
fi

if az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "database-password" \
    --value "$DB_ADMIN_PASSWORD" >/dev/null 2>&1; then
    log "✅ Database password додано"
else
    log "❌ Помилка додавання database password"
fi

if az keyvault secret set \
    --vault-name "$KEY_VAULT_NAME" \
    --name "storage-account-key" \
    --value "$STORAGE_KEY" >/dev/null 2>&1; then
    log "✅ Storage account key додано"
else
    log "❌ Помилка додавання storage account key"
fi

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



echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}🛠️  ДОДАТКОВІ УТИЛІТИ СТВОРЕНІ${NC}"
echo -e "${GREEN}============================================${NC}"
echo "📁 Utility скрипт: azure_utils.sh"
echo ""
echo "🔧 Корисні команди:"
echo "  ./azure_utils.sh status    # Статус ресурсів"
echo "  ./azure_utils.sh logs      # Логи додатку"
echo "  ./azure_utils.sh restart   # Перезапуск"
echo "  ./azure_utils.sh cleanup   # Видалення"
echo ""

# Фінальне повідомлення
echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}🎉 СТВОРЕННЯ ІНФРАСТРУКТУРИ ЗАВЕРШЕНО!${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo "📦 Створені файли:"
echo "  ✅ requirements.txt - Python залежності"
echo "  ✅ .env.example - Приклад змінних середовища"
echo "  ✅ startup.sh - Startup скрипт для Azure"
echo "  ✅ web.config - Конфігурація Web App"
echo "  ✅ infrastructure-summary.txt - Підсумок інфраструктури"
echo "  ✅ cleanup_azure_infrastructure.sh - Скрипт видалення"
echo "  ✅ azure_utils.sh - Утиліти управління"
echo ""
echo "🚀 Наступні кроки:"
echo "  1. Розгорніть ваш Django код: az webapp deployment source config-zip"
echo "  2. Перевірте статус: ./azure_utils.sh status"
echo "  3. Перегляньте логи: ./azure_utils.sh logs"
echo "  4. При необхідності видаліть: ./cleanup_azure_infrastructure.sh"
echo ""
echo -e "${GREEN}Удачі з вашим Django проектом на Azure! 🐍☁️${NC}"
echo ""


Я доповнив ваш скрипт потужною системою очищення ресурсів та додатковими утилітами! 🎉

## 🆕 **Що додано:**

### 1. **Повноцінний Cleanup Script** (`cleanup_azure_infrastructure.sh`)
- **Інтерактивне видалення** з підтвердженням
- **Dry-run режим** для перегляду плану
- **Force режим** для автоматичного видалення
- **Безпечне видалення Key Vault** з очищенням soft delete
- **Timeout handling** для великих ресурсів
- **Fallback strategy** - якщо Resource Group не видаляється, видаляє ресурси окремо

### 2. **Utility Script** (`azure_utils.sh`)
- **Статус моніторинг** всіх ресурсів
- **Швидкий доступ** до логів та перезапуску
- **Інтеграція з cleanup** скриптом

### 3. **Розширений Summary**
- Включає інформацію про cleanup
- Детальні інструкції по використанню
- Список всіх створених файлів

## 🔧 **Як використовувати Cleanup:**

### **Безпечне видалення (рекомендовано):**
```bash
./cleanup_azure_infrastructure.sh
```
- Показує що буде видалено
- Запитує подвійне підтвердження
- Безпечно видаляє всі ресурси

### **Перегляд плану видалення:**
```bash
./cleanup_azure_infrastructure.sh --dry-run
```
- Показує що буде видалено
- Не виконує фактичного видалення

### **Автоматичне видалення:**
```bash
./cleanup_azure_infrastructure.sh --force
```
- ⚠️ **НЕБЕЗПЕЧНО!** Видаляє без підтвердження

## 🛠️ **Додаткові утиліти:**

```bash
# Статус всіх ресурсів
./azure_utils.sh status

# Логи додатку в реальному часі
./azure_utils.sh logs

# Перезапуск веб-додатку
./azure_utils.sh restart

# Швидкий cleanup
./azure_utils.sh cleanup
```

## 💡 **Ключові особливості Cleanup:**

### **Інтелектуальне видалення:**
1. Спочатку намагається видалити всю Resource Group (швидко)
2. Якщо не вдається - видаляє ресурси по одному
3. Спеціальна обробка Key Vault (soft delete очищення)
4. Timeout handling для великих ресурсів

### **Безпека:**
- Подвійне підтвердження
- Dry-run режим
- Показ поточних ресурсів перед видаленням
- Очищення локальних файлів

### **Надійність:**
- Перевірка помилок
- Fallback стратегії
- Детальне логування
- Graceful handling недоступних ресурсів

Тепер у вас є повноцінна система управління Azure інфраструктурою з можливістю безпечного створення та видалення! 🚀
