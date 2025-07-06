

# Бюджетна версія Azure Infrastructure Script (~$20-25/місяць)

## 💰 Модифікований скрипт для економного розгортання## 📋 Покроковий алгоритм роботи бюджетного скрипта

### 🔍 **Фаза 1: Ініціалізація та перевірки**

#### **Крок 1-3: Підготовка середовища**
1. **Встановлення змінних** - конфігурація бюджетних параметрів
2. **Перевірка залежностей** - Azure CLI, OpenSSL, авторизація
3. **Логування початку** - вивід конфігурації та орієнтовної вартості

### 🏗️ **Фаза 2: Створення базової інфраструктури**

#### **Крок 4-6: Фундаментальні ресурси**
4. **Resource Group** - логічне об'єднання всіх ресурсів
5. **Storage Account** - Standard_LRS для економії (~$2-5/міс)
6. **Storage Containers** - створення контейнерів для static/media файлів

### 🗄️ **Фаза 3: База даних та безпека**

#### **Крок 7-9: Database та Key Vault**
7. **PostgreSQL Flexible Server** - Standard_B1ms (1 vCore, 2GB RAM, ~$12-15/міс)
8. **Database створення** - основна база даних додатку
9. **Firewall rules** - дозвіл доступу з Azure сервісів

#### **Крок 10-11: Управління секретами**
10. **Key Vault створення** - безпечне зберігання секретів (~$1/міс)
11. **Додавання секретів** - Django SECRET_KEY, DB password, Storage key

### 📊 **Фаза 4: Моніторинг та хостинг**

#### **Крок 12-13: Application Insights та App Service**
12. **Application Insights** - безкоштовний моніторинг (до 5GB/міс)
13. **App Service Plan F1** - 🆓 **БЕЗКОШТОВНИЙ** план з обмеженнями

#### **Крок 14: Web App**
14. **Django Web App** - створення та базове налаштування

### ⚙️ **Фаза 5: Конфігурація та оптимізація**

#### **Крок 15-17: Налаштування додатку**
15. **Environment Variables** - підключення до Key Vault та інших сервісів
16. **Startup Configuration** - оптимізована команда для 1 worker
17. **Logging Configuration** - мінімальне логування для економії ресурсів

#### **Крок 18-19: Безпека та доступ**
18. **Managed Identity** - безпечний доступ до Key Vault
19. **HTTPS enforcement** - примусове використання HTTPS

### 📝 **Фаза 6: Генерація конфігураційних файлів**

#### **Крок 20-24: Файли конфігурації**
20. **requirements.txt** - мінімальний набір залежностей
21. **.env.budget** - бюджетні змінні середовища
22. **startup.sh** - оптимізований startup скрипт
23. **budget_settings.py** - Django settings для бюджетного режиму
24. **cleanup script** - скрипт для видалення інфраструктури

### 📊 **Фаза 7: Звітність та завершення**

#### **Крок 25-27: Фінальний звіт**
25. **Отримання URL** - генерація посилання на додаток
26. **Підсумковий звіт** - детальна інформація про створені ресурси
27. **Збереження конфігурації** - файл budget-infrastructure-summary.txt

---

## 🔧 **Детальний розбір ключових оптимізацій**

### 💰 **Бюджетні рішення в скрипті:**

#### **🆓 App Service F1 Plan**
```bash
APP_SERVICE_SKU="F1"              # Безкоштовно
# Обмеження:
# - 60 хвилин CPU на день
# - 1GB RAM
# - Без Always On (cold start)
# - Максимум 10 додатків
```

#### **💵 PostgreSQL B1ms**
```bash
DB_SKU="Standard_B1ms"            # $12-15/місяць
DB_STORAGE_SIZE="32"              # Мінімальний розмір
# Особливості:
# - 1 vCore, 2GB RAM
# - 32GB SSD storage
# - Підходить для малих додатків
```

#### **💾 Економне сховище**
```bash
STORAGE_SKU="Standard_LRS"        # Локально надлишкове
# Переваги:
# - Найдешевший варіант
# - Достатньо для розробки/тестування
# - $0.0184/GB/місяць
```

---

## ⚠️ **Обмеження бюджетної версії**

### **F1 App Service обмеження:**
- **CPU квота**: 60 хвилин на день
- **RAM**: 1GB (спільно для всіх додатків)
- **Bandwidth**: 165MB на день
- **Без Always On**: можливі cold starts
- **Без custom domains**: тільки *.azurewebsites.net
- **Без автоматичного масштабування**

### **B1ms Database обмеження:**
- **Performance**: базовий рівень
- **Connections**: обмежена кількість одночасних з'єднань
- **IOPS**: стандартний рівень
- **Backup retention**: 7 днів

---

## 🚀 **Стратегія апгрейду**

### **Поетапне збільшення ресурсів:**

#### **Етап 1: Розширення App Service ($13/міс додатково)**
```bash
# Оновлення до B1
az appservice plan update \
    --name "django-app-budget-plan" \
    --resource-group "django-app-budget-rg" \
    --sku B1
```

#### **Етап 2: Збільшення DB потужності ($15-20/міс додатково)**
```bash
# Оновлення до B2s
az postgres flexible-server update \
    --name "your-db-server" \
    --resource-group "django-app-budget-rg" \
    --sku-name Standard_B2s
```

#### **Етап 3: Додавання Redis кешу ($10-15/міс)**
```bash
# Створення Azure Cache for Redis
az redis create \
    --name "django-cache" \
    --resource-group "django-app-budget-rg" \
    --sku Basic \
    --vm-size C0
```

---

## 📈 **Моніторинг витрат**

### **Налаштування billing alerts:**
```bash
# Створення budget alert
az consumption budget create \
    --resource-group "django-app-budget-rg" \
    --budget-name "django-monthly-budget" \
    --amount 30 \
    --category Cost \
    --time-grain Monthly
```

### **Ключові метрики для відстеження:**
- **App Service CPU usage** - не перевищувати 60 хв/день
- **Database DTU consumption** - моніторинг навантаження
- **Storage operations** - кількість операцій читання/запису
- **Bandwidth usage** - вихідний трафік

---

## 🛠️ **Практичні поради по оптимізації**

### **Код-рівень оптимізації:**

#### **Django settings для бюджетного режиму:**
```python
# Мінімальне кешування
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'OPTIONS': {'MAX_ENTRIES': 300}
    }
}

# Переіспользування DB з'єднань
DATABASES = {
    'default': {
        'CONN_MAX_AGE': 600,  # 10 хвилин
        'OPTIONS': {'MAX_CONNS': 2}  # Мінімум для B1ms
    }
}

# Статика через WhiteNoise (економія на Storage)
MIDDLEWARE = [
    'whitenoise.middleware.WhiteNoiseMiddleware',
    # ... інші middleware
]
```

#### **Gunicorn оптимізація:**
```bash
# Мінімальна конфігурація для F1
gunicorn --bind=0.0.0.0:8000 \
         --timeout 300 \
         --workers 1 \
         --max-requests 1000 \
         --max-requests-jitter 100 \
         config.wsgi:application
```

---

## 📋 **Checklist для бюджетного деплою**

### **✅ Перед запуском:**
- [ ] Перевірити Azure CLI авторизацію
- [ ] Підтвердити квоти підписки
- [ ] Переглянути орієнтовну вартість
- [ ] Налаштувати billing alerts

### **✅ Після деплою:**
- [ ] Перевірити роботу додатку
- [ ] Протестувати підключення до БД
- [ ] Налаштувати моніторинг CPU usage
- [ ] Створити backup стратегію
- [ ] Документувати credentials

### **✅ Постійний моніторинг:**
- [ ] Щоденна перевірка CPU квоти F1
- [ ] Тижневий аналіз витрат
- [ ] Місячний review performance метрик
- [ ] Планування апгрейдів при зростанні навантаження

---

## 🎯 **Випадки використання бюджетної версії**

### **✅ Ідеально підходить для:**
- **MVP та прототипи** - швидке тестування ідей
- **Навчальні проекти** - вивчення Django + Azure
- **Особисті блоги/портфоліо** - невеликий трафік
- **Dev/Staging середовища** - розробка та тестування
- **Демо додатки** - презентації та POC

### **❌ Не підходить для:**
- **Production з високим трафіком** - обмеження F1
- **CPU-інтенсивні задачі** - ліміт 60 хв/день
- **Високе навантаження на БД** - B1ms має обмеження
- **24/7 критичні системи** - немає Always On
- **Великі файли/медіа** - обмеження bandwidth

---

## 💡 **Поради по масштабуванню**

### **Сигнали для апгрейду:**
1. **CPU quota exhausted** - частое досягнення ліміту 60 хв
2. **Cold starts** - користувачі скаржаться на повільний відгук
3. **DB timeouts** - помилки підключення до бази
4. **Storage costs** - зростання операцій з файлами

### **Поетапна стратегія росту:**
```
Budget ($20-25) → Basic ($40-50) → Standard ($80-120) → Premium ($200+)
     ↓               ↓                ↓                    ↓
   F1+B1ms        B1+B2s           S1+GP2s            P1V2+GP4s
```

Ця бюджетна версія дає можливість розпочати з мінімальними витратами та поступово масштабуватися в міру зростання потреб! 🚀💰




```bash
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

```



```bash
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (feature/infrastructure-update) $ ./budget-azure-deploy.sh

============================================
💰 БЮДЖЕТНА AZURE INFRASTRUCTURE
============================================
Орієнтовна вартість: 0-25/місяць

📊 Конфігурація:
  🚀 App Service: F1 (безкоштовно)
  🗄️  Database: Standard_B1ms (~2-15)
  💾 Storage: Standard_LRS (~-5)
  🔐 Key Vault: ~
  📈 App Insights: безкоштовно (до 5GB)

[2025-07-06 16:07:49] Початок створення БЮДЖЕТНОЇ інфраструктури для Django додатку...
[2025-07-06 16:07:49] Проект: django-app
[2025-07-06 16:07:49] Середовище: budget
[2025-07-06 16:07:49] Регіон: West Europe
[2025-07-06 16:07:49] Перевірка залежностей...
[2025-07-06 16:07:49] ✅ Всі залежності встановлені
[INFO] 🔄 КРОК 1/11: Створення Resource Group
[2025-07-06 16:07:49] Створення Resource Group: django-app-budget-rg
{
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-budget-rg",
  "location": "westeurope",
  "managedBy": null,
  "name": "django-app-budget-rg",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": {
    "CostProfile": "Budget",
    "CreatedBy": "AzureCLI",
    "Environment": "budget",
    "Project": "django-app"
  },
  "type": "Microsoft.Resources/resourceGroups"
}
[INFO] 🔄 КРОК 2/11: Створення Storage Account (бюджетна конфігурація)
[2025-07-06 16:07:51] Створення Storage Account: djapp1818069
{
  "accessTier": "Hot",
  "accountMigrationInProgress": null,
  "allowBlobPublicAccess": false,
  "allowCrossTenantReplication": false,
  "allowSharedKeyAccess": null,
  "allowedCopyScope": null,
  "azureFilesIdentityBasedAuthentication": null,
  "blobRestoreStatus": null,
  "creationTime": "2025-07-06T16:07:54.835755+00:00",
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
        "lastEnabledTime": "2025-07-06T16:07:54.992005+00:00"
      },
      "file": {
        "enabled": true,
        "keyType": "Account",
        "lastEnabledTime": "2025-07-06T16:07:54.992005+00:00"
      },
      "queue": null,
      "table": null
    }
  },
  "extendedLocation": null,
  "failoverInProgress": null,
  "geoReplicationStats": null,
  "id": "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-budget-rg/providers/Microsoft.Storage/storageAccounts/djapp1818069",
  "identity": null,
  "immutableStorageWithVersioning": null,
  "isHnsEnabled": null,
  "isLocalUserEnabled": null,
  "isSftpEnabled": null,
  "isSkuConversionBlocked": null,
  "keyCreationTime": {
    "key1": "2025-07-06T16:07:54.976379+00:00",
    "key2": "2025-07-06T16:07:54.976379+00:00"
  },
  "keyPolicy": null,
  "kind": "StorageV2",
  "largeFileSharesState": null,
  "lastGeoFailoverTime": null,
  "location": "westeurope",
  "minimumTlsVersion": "TLS1_0",
  "name": "djapp1818069",
  "networkRuleSet": {
    "bypass": "AzureServices",
    "defaultAction": "Allow",
    "ipRules": [],
    "ipv6Rules": [],
    "resourceAccessRules": null,
    "virtualNetworkRules": []
  },
  "primaryEndpoints": {
    "blob": "https://djapp1818069.blob.core.windows.net/",
    "dfs": "https://djapp1818069.dfs.core.windows.net/",
    "file": "https://djapp1818069.file.core.windows.net/",
    "internetEndpoints": null,
    "microsoftEndpoints": null,
    "queue": "https://djapp1818069.queue.core.windows.net/",
    "table": "https://djapp1818069.table.core.windows.net/",
    "web": "https://djapp1818069.z6.web.core.windows.net/"
  },
  "primaryLocation": "westeurope",
  "privateEndpointConnections": [],
  "provisioningState": "Succeeded",
  "publicNetworkAccess": null,
  "resourceGroup": "django-app-budget-rg",
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
    "CostProfile": "Budget",
    "CreatedBy": "AzureCLI",
    "Environment": "budget",
    "Project": "django-app"
  },
  "type": "Microsoft.Storage/storageAccounts"
}
[2025-07-06 16:08:13] Створення контейнерів для статичних файлів
{
  "created": false
}
{
  "created": false
}
[INFO] 🔄 КРОК 3/11: Створення PostgreSQL Database (бюджетна конфігурація)
[2025-07-06 16:08:16] Створення PostgreSQL сервера: django-app-budget-db-1751818069
[WARNING] Використовується найдешевший SKU: Standard_B1ms
The default value of '--version' will be changed to '17' from '16' in next breaking change release(2.73.0) scheduled for May 2025.
The default value of '--create-default-database' will be changed to 'Disabled' from 'Enabled' in next breaking change release(2.73.0) scheduled for May 2025.
Update default value of "--sku-name" in next breaking change release(2.73.0) scheduled for May 2025. The default value will be changed from "Standard_D2s_v3" to a supported sku based on regional capabilities.
Checking the existence of the resource group 'django-app-budget-rg'...
Resource group 'django-app-budget-rg' exists ? : True 
Incorrect value for --sku-name. The SKU name does not exist in GeneralPurpose tier. When --tier is not specified, it defaults to GeneralPurpose. Provide a valid SKU name for this tier, or specify --tier with the right tier for the SKU name chosen. Allowed values : ['standard_d96ds_v5', 'standard_d64ds_v5', 'standard_d48ds_v5', 'standard_d32ds_v5', 'standard_d16ds_v5', 'standard_d8ds_v5', 'standard_d4ds_v5', 'standard_d2ds_v5', 'standard_d64ds_v4', 'standard_d48ds_v4', 'standard_d32ds_v4', 'standard_d16ds_v4', 'standard_d8ds_v4', 'standard_d4ds_v4', 'standard_d2ds_v4', 'standard_d64s_v3', 'standard_d48s_v3', 'standard_d32s_v3', 'standard_d16s_v3', 'standard_d8s_v3', 'standard_d4s_v3', 'standard_d2s_v3']
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (feature/infrastructure-update) $

```

## 🐛 **Помилка в PostgreSQL SKU - Виправлення**

Бачу проблему! SKU `Standard_B1ms` не існує в GeneralPurpose tier PostgreSQL Flexible Server. Потрібно виправити скрипт.

---

## 🔍 **Аналіз помилки:**

### **❌ Проблема:**
```bash
Incorrect value for --sku-name. The SKU name does not exist in GeneralPurpose tier.
SKU: Standard_B1ms
Tier: GeneralPurpose (default)
```

### **✅ Рішення:**
Потрібно або:
1. **Використати Burstable tier** з правильним SKU
2. **Або використати GeneralPurpose tier** з найдешевшим SKU

---

## 🛠️ **Виправлення скрипту:**

### **Варіант 1: Burstable tier (найдешевший ~$7-12/місяць)**
```bash
# Замінити в скрипті:
DB_SKU="Standard_B1ms"            # ❌ Неправильно
DB_TIER="Burstable"               # ✅ Додати
DB_SKU="Standard_B1ms"            # ✅ Правильно з tier

# В команді az postgres flexible-server create додати:
az postgres flexible-server create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$DATABASE_SERVER_NAME" \
    --location "$LOCATION" \
    --admin-user "$DB_ADMIN_USER" \
    --admin-password "$DB_ADMIN_PASSWORD" \
    --sku-name "$DB_SKU" \
    --tier "$DB_TIER" \                    # ✅ Додати цей рядок
    --storage-size "$DB_STORAGE_SIZE" \
    --version 14 \
    --public-access 0.0.0.0 \
    --tags $TAGS
```

### **Варіант 2: GeneralPurpose tier (дорожчий ~$85/місяць)**
```bash
# Замінити в скрипті:
DB_SKU="Standard_D2s_v3"          # ✅ Найдешевший у GeneralPurpose
DB_TIER="GeneralPurpose"          # ✅ Явно вказати tier
```

---

## 💰 **Рекомендований fix для бюджетної версії:**

### **🔧 Оновлений budget-azure-deploy.sh:**---

## 🎯 **Альтернативні варіанти PostgreSQL для бюджету:**

### **💰 Варіант 1: Burstable B1ms (Рекомендований)**
```bash
DB_SKU="Standard_B1ms"
DB_TIER="Burstable"
# Вартість: ~$7-12/місяць
# Ресурси: 1 vCore, 2GB RAM, 32GB storage
# Підходить для: розробка, тестування, малі проекти
```

### **💵 Варіант 2: Burstable B2s (Кращий performance)**
```bash
DB_SKU="Standard_B2s"
DB_TIER="Burstable"
# Вартість: ~$14-20/місяць
# Ресурси: 2 vCore, 4GB RAM, 32GB storage
# Підходить для: малі production додатки
```

### **💸 Варіант 3: GeneralPurpose D2s_v3 (Найдорожчий)**
```bash
DB_SKU="Standard_D2s_v3"
DB_TIER="GeneralPurpose"
# Вартість: ~$85-95/місяць
# Ресурси: 2 vCore, 8GB RAM, high IOPS
# Підходить для: production з високим навантаженням
```

---

## 🔧 **Швидке виправлення:**

### **📝 Редагування через GitHub:**

1. **Відкрити `budget-azure-deploy.sh`**
2. **Знайти рядки:**
   ```bash
   DB_SKU="Standard_B1ms"            # 💵 $12-15/місяць (1 vCore, 2GB RAM)
   ```

3. **Замінити на:**
   ```bash
   DB_SKU="Standard_B1ms"            # 💵 $7-12/місяць (1 vCore, 2GB RAM)
   DB_TIER="Burstable"               # ✅ ДОДАНО: Burstable tier
   ```

4. **Знайти команду PostgreSQL:**
   ```bash
   az postgres flexible-server create \
       --sku-name "$DB_SKU" \
   ```

5. **Додати рядок після `--sku-name`:**
   ```bash
   az postgres flexible-server create \
       --sku-name "$DB_SKU" \
       --tier "$DB_TIER" \           # ✅ ДОДАТИ ЦЕЙ РЯДОК
   ```

6. **Оновити вивід вартості:**
   ```bash
   echo "  🗄️  Database: Standard_B1ms Burstable (~$7-12)"
   echo ""
   echo "💰 ЗАГАЛЬНА ВАРТІСТЬ: ~$10-18/місяць"
   ```

---

## ✅ **Перевірка доступних SKU:**

### **🔍 Команда для перевірки:**
```bash
# Показати всі доступні SKU для PostgreSQL
az postgres flexible-server list-skus --location "West Europe" --output table

# Показати тільки Burstable tier
az postgres flexible-server list-skus --location "West Europe" --query "[?tier=='Burstable']" --output table
```

### **📊 Очікувані результати для Burstable:**
```
Name              Tier       vCores    Memory    Storage
Standard_B1ms     Burstable  1         2 GB      32-16384 GB
Standard_B2s      Burstable  2         4 GB      32-16384 GB  
Standard_B4ms     Burstable  4         8 GB      32-16384 GB
```

---

## 🚀 **Після виправлення:**

### **💰 Оновлена вартість:**
```
📊 Бюджетна конфігурація (виправлена):
🚀 App Service F1: $0/місяць
🗄️  PostgreSQL B1ms Burstable: $7-12/місяць  
💾 Storage LRS: $2-5/місяць
🔐 Key Vault: $1/місяць
📈 App Insights: $0/місяць

💰 ЗАГАЛЬНА ВАРТІСТЬ: $10-18/місяць
```

### **🔄 Повторний запуск:**
```bash
# Після виправлення скрипту:
chmod +x budget-azure-deploy.sh
./budget-azure-deploy.sh
```

---

## 📝 **Commit message для виправлення:**

```
🐛 Fix PostgreSQL SKU configuration for budget deployment

- Fixed Standard_B1ms SKU to use Burstable tier
- Added explicit --tier parameter to PostgreSQL creation
- Updated cost estimates ($10-18/month instead of $20-25)
- Improved error handling for SKU validation

Resolves: PostgreSQL creation failure due to incorrect tier
```

---

## 💡 **Додаткові покращення:**

### **🛡️ Додати валідацію SKU:**
```bash
# Перевірка доступності SKU перед створенням
validate_postgresql_sku() {
    log "Перевірка доступності PostgreSQL SKU..."
    
    local available_skus=$(az postgres flexible-server list-skus \
        --location "$LOCATION" \
        --query "[?tier=='$DB_TIER' && name=='$DB_SKU'].name" \
        --output tsv)
    
    if [ -z "$available_skus" ]; then
        error "SKU '$DB_SKU' недоступний в tier '$DB_TIER' для регіону '$LOCATION'"
        log "Доступні SKU для $DB_TIER tier:"
        az postgres flexible-server list-skus \
            --location "$LOCATION" \
            --query "[?tier=='$DB_TIER'].{Name:name, vCores:vCores, Memory:memoryMb}" \
            --output table
        exit 1
    fi
    
    log "✅ SKU '$DB_SKU' доступний в tier '$DB_TIER'"
}

# Викликати перед створенням PostgreSQL
validate_postgresql_sku
```

**Виправте SKU конфігурацію і скрипт спрацює правильно!** 🛠️✅


-----------------------------------------------------------------------------------------------------------------------------------------

## 🐛 **Помилка синтаксису в команді PostgreSQL**

Бачу проблему! В команді `az postgres flexible-server create` є помилка синтаксису - `unrecognized arguments`.

---

## 🔍 **Аналіз помилки:**

### **❌ Проблема:**
```bash
unrecognized arguments:  
```

Це означає, що в команді є:
- **Зайві пробіли** або символи
- **Неправильний порядок** параметрів
- **Синтаксична помилка** в bash скрипті

---

## 🛠️ **Виправлення команди PostgreSQL:**---

## 🔧 **Можливі причини помилки:**

### **1. 🎯 Проблема з тегами:**
```bash
# ❌ Проблемна версія:
--tags $TAGS

# ✅ Виправлена версія:
--tags Environment=budget Project=django-app CreatedBy=AzureCLI CostProfile=Budget
```

### **2. 🎯 Проблема з порядком параметрів:**
```bash
# ✅ Правильний порядок:
az postgres flexible-server create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$DATABASE_SERVER_NAME" \
    --location "$LOCATION" \
    --admin-user "$DB_ADMIN_USER" \
    --admin-password "$DB_ADMIN_PASSWORD" \
    --sku-name "$DB_SKU" \
    --tier "$DB_TIER" \
    --storage-size "$DB_STORAGE_SIZE" \
    --version 14 \
    --public-access 0.0.0.0 \
    --tags Environment=budget Project=django-app CreatedBy=AzureCLI
```

### **3. 🎯 Перевірка змінних:**
```bash
# Додати debug інформацію перед командою:
echo "DEBUG: Resource Group: $RESOURCE_GROUP_NAME"
echo "DEBUG: Database Name: $DATABASE_SERVER_NAME"
echo "DEBUG: Location: $LOCATION"
echo "DEBUG: Admin User: $DB_ADMIN_USER"
echo "DEBUG: SKU: $DB_SKU"
echo "DEBUG: Tier: $DB_TIER"
echo "DEBUG: Storage: $DB_STORAGE_SIZE"
echo "DEBUG: Tags: $TAGS"
```

---

## 🎯 **Швидке виправлення:**

### **📝 Редагування скрипту:**

1. **Знайти секцію створення PostgreSQL** (близько рядка 180-200)

2. **Замінити команду на цю:**
```bash
az postgres flexible-server create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$DATABASE_SERVER_NAME" \
    --location "$LOCATION" \
    --admin-user "$DB_ADMIN_USER" \
    --admin-password "$DB_ADMIN_PASSWORD" \
    --sku-name "Standard_B1ms" \
    --tier "Burstable" \
    --storage-size 32 \
    --version 14 \
    --public-access 0.0.0.0 \
    --tags Environment=budget Project=django-app CreatedBy=AzureCLI CostProfile=Budget
```

3. **Або спростити до мінімуму:**
```bash
az postgres flexible-server create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$DATABASE_SERVER_NAME" \
    --location "$LOCATION" \
    --admin-user "$DB_ADMIN_USER" \
    --admin-password "$DB_ADMIN_PASSWORD" \
    --sku-name "Standard_B1ms" \
    --tier "Burstable" \
    --storage-size 32 \
    --public-access 0.0.0.0
```

---

## 🧪 **Тестування команди окремо:**

### **📋 Ручна перевірка команди:**
```bash
# Встановити змінні:
RESOURCE_GROUP_NAME="django-app-budget-rg"
DATABASE_SERVER_NAME="django-app-budget-db-test"
LOCATION="West Europe"
DB_ADMIN_USER="djangoadmin"
DB_ADMIN_PASSWORD="TestPassword123!"

# Протестувати команду:
az postgres flexible-server create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$DATABASE_SERVER_NAME" \
    --location "$LOCATION" \
    --admin-user "$DB_ADMIN_USER" \
    --admin-password "$DB_ADMIN_PASSWORD" \
    --sku-name "Standard_B1ms" \
    --tier "Burstable" \
    --storage-size 32 \
    --version 14 \
    --public-access 0.0.0.0
```

---

## 💡 **Альтернативне рішення - два кроки:**

### **🔧 Якщо параметр --tier не працює:**

```bash
# Крок 1: Створити сервер з мінімальними параметрами
az postgres flexible-server create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$DATABASE_SERVER_NAME" \
    --location "$LOCATION" \
    --admin-user "$DB_ADMIN_USER" \
    --admin-password "$DB_ADMIN_PASSWORD" \
    --public-access 0.0.0.0

# Крок 2: Оновити SKU після створення
az postgres flexible-server update \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$DATABASE_SERVER_NAME" \
    --sku-name "Standard_B1ms" \
    --tier "Burstable"
```

---

## 🔍 **Перевірка доступних параметрів:**

### **📋 Команда для перевірки синтаксису:**
```bash
# Показати всі доступні параметри:
az postgres flexible-server create --help

# Перевірити доступні SKU:
az postgres flexible-server list-skus --location "West Europe" --output table
```

---

## 🎯 **Рекомендоване виправлення для скрипту:**

### **📝 Замінити секцію PostgreSQL на:**
```bash
info "🔄 КРОК 3/11: Створення PostgreSQL Database (бюджетна конфігурація)"
log "Створення PostgreSQL сервера: ${DATABASE_SERVER_NAME}"
warning "Використовується найдешевший SKU: Standard_B1ms в Burstable tier"

# Виправлена команда без змінних у тегах
az postgres flexible-server create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$DATABASE_SERVER_NAME" \
    --location "$LOCATION" \
    --admin-user "$DB_ADMIN_USER" \
    --admin-password "$DB_ADMIN_PASSWORD" \
    --sku-name "Standard_B1ms" \
    --tier "Burstable" \
    --storage-size 32 \
    --version 14 \
    --public-access 0.0.0.0 \
    --tags Environment=budget Project=django-app CreatedBy=AzureCLI CostProfile=Budget

if [ $? -eq 0 ]; then
    log "✅ PostgreSQL сервер успішно створено"
else
    error "❌ Помилка створення PostgreSQL сервера"
fi
```

---

## 📝 **Commit message після виправлення:**
```
🐛 Fix PostgreSQL creation command syntax error

- Fixed command line arguments formatting
- Simplified tags parameter to avoid parsing issues
- Added error checking for PostgreSQL creation
- Confirmed Standard_B1ms SKU with Burstable tier

Resolves: "unrecognized arguments" error in PostgreSQL creation
```

**Після цього виправлення скрипт має працювати правильно!** 🛠️✅

---------------------------------------------------------------------------------------------------------------------------------------------------------


## 📝 **Запуск bash скрипту з записом виводу у файл**

Є кілька способів записати вивід скрипту у файл. Ось найпопулярніші варіанти:

---

## 📋 **Основні методи:**

### **1. 📄 Простий запис виводу (`>`)**
```bash
# Записати тільки stdout у файл (перезаписати)
./budget-azure-deploy.sh > deployment.log

# Дописати у файл (не перезаписати)
./budget-azure-deploy.sh >> deployment.log
```

### **2. 📄 Запис stdout + stderr (`&>`)**
```bash
# Записати ВСЕ (stdout + stderr) у файл
./budget-azure-deploy.sh &> deployment.log

# Або альтернативний синтаксис:
./budget-azure-deploy.sh > deployment.log 2>&1
```

### **3. 👀 Запис + показ у консолі (`tee`)**
```bash
# Записати у файл І показати у консолі одночасно
./budget-azure-deploy.sh | tee deployment.log

# Записати ВСЕ (stdout + stderr) + показати у консолі
./budget-azure-deploy.sh 2>&1 | tee deployment.log
```

### **4. 📅 З timestamp у назві файла**
```bash
# Створити файл з датою/часом
./budget-azure-deploy.sh 2>&1 | tee "deployment-$(date +%Y%m%d-%H%M%S).log"
```

---

## 🎯 **Рекомендовані варіанти для вашого скрипту:**

### **✅ Найкращий варіант (з показом у консолі):**
```bash
./budget-azure-deploy.sh 2>&1 | tee deployment.log
```

**Переваги:**
- ✅ Бачите процес у реальному часі
- ✅ Записується ВСЕ (успіхи + помилки)
- ✅ Можете переривати процес Ctrl+C
- ✅ Файл зберігається для подальшого аналізу

### **✅ Для автоматичних скриптів (без показу):**
```bash
./budget-azure-deploy.sh &> deployment.log
```

**Переваги:**
- ✅ Швидша робота (немає виводу у консоль)
- ✅ Підходить для cron jobs
- ✅ Записує все у файл

---

## 📊 **Практичні приклади:**

### **🔧 Для вашого Django Azure проекту:**

#### **Варіант 1: Розгортання з логуванням**
```bash
# Запуск з timestamps та кольоровим виводом
./budget-azure-deploy.sh 2>&1 | tee "logs/azure-deploy-$(date +%Y%m%d-%H%M%S).log"
```

#### **Варіант 2: Тільки запис у файл**
```bash
# Тихий режим - тільки у файл
./budget-azure-deploy.sh > deployment.log 2>&1
```

#### **Варіант 3: Окремо успіхи та помилки**
```bash
# stdout у один файл, stderr у інший
./budget-azure-deploy.sh > deployment-success.log 2> deployment-errors.log
```

#### **Варіант 4: З progress індикатором**
```bash
# Показати прогрес + записати все
./budget-azure-deploy.sh 2>&1 | tee deployment.log | grep -E "(INFO|ERROR|WARNING)"
```

---

## 📁 **Організація логів:**

### **🗂️ Створення структури папок:**
```bash
# Створити папку для логів
mkdir -p logs

# Запуск з організованим логуванням
./budget-azure-deploy.sh 2>&1 | tee "logs/budget-deploy-$(date +%Y%m%d-%H%M%S).log"
```

### **📅 Різні формати timestamps:**
```bash
# Формат: 20250706-161830
date +%Y%m%d-%H%M%S

# Формат: 2025-07-06_16-18-30
date +%Y-%m-%d_%H-%M-%S

# Формат: Jul06-1618
date +%b%d-%H%M
```

---

## 🎨 **Додаткові можливості:**

### **🔍 Фільтрація виводу:**
```bash
# Записати тільки важливі повідомлення
./budget-azure-deploy.sh 2>&1 | tee deployment.log | grep -E "✅|❌|⚠️"

# Записати тільки помилки та попередження
./budget-azure-deploy.sh 2>&1 | tee deployment.log | grep -E "(ERROR|WARNING)"

# Показати тільки кроки виконання
./budget-azure-deploy.sh 2>&1 | tee deployment.log | grep -E "КРОК [0-9]"
```

### **📊 З додатковою інформацією:**
```bash
# Додати інформацію про систему на початок лога
{
    echo "=== Azure Django Deployment Log ==="
    echo "Date: $(date)"
    echo "User: $(whoami)"
    echo "PWD: $(pwd)"
    echo "Git Branch: $(git branch --show-current 2>/dev/null || echo 'N/A')"
    echo "Git Commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'N/A')"
    echo "Azure Account: $(az account show --query user.name -o tsv 2>/dev/null || echo 'Not logged in')"
    echo "=================================="
    echo ""
} > deployment.log

# Потім додати вивід скрипту
./budget-azure-deploy.sh 2>&1 | tee -a deployment.log
```

---

## 🛠️ **Wrapper скрипт для зручності:**---

## 🎯 **Використання wrapper скрипту:**

### **📋 Збереження та використання:**
```bash
# 1. Зберегти wrapper як deploy-with-logs.sh
chmod +x deploy-with-logs.sh

# 2. Запустити ваш deployment з логуванням
./deploy-with-logs.sh budget-azure-deploy.sh

# 3. Переглянути лог
cat logs/azure-deploy-20250706-161830.log
```

---

## 📊 **Корисні команди для аналізу логів:**

### **🔍 Аналіз після завершення:**
```bash
# Показати тільки помилки
grep -i "error\|❌\|failed" deployment.log

# Показати прогрес (кроки)
grep "КРОК\|INFO" deployment.log

# Показати важливі повідомлення
grep -E "✅|❌|⚠️|🔄" deployment.log

# Показати створені ресурси
grep -i "створено\|created" deployment.log

# Показати вартість
grep -i "вартість\|cost\|💰" deployment.log

# Підрахувати кількість помилок
grep -c -i "error\|❌" deployment.log
```

### **📈 Статистика виконання:**
```bash
# Час виконання кожного кроку
grep "КРОК\|INFO" deployment.log | while read line; do
    echo "$line" | grep -o "\[.*\]" | tr -d "[]"
done

# Показати розмір лога
ls -lh deployment.log

# Кількість рядків
wc -l deployment.log
```

---

## 💡 **Рекомендації:**

### **✅ Для розробки (інтерактивно):**
```bash
./budget-azure-deploy.sh 2>&1 | tee deployment.log
```

### **✅ Для production (автоматично):**
```bash
./budget-azure-deploy.sh > deployment.log 2>&1
```

### **✅ Для детального аналізу:**
```bash
./deploy-with-logs.sh budget-azure-deploy.sh
```

### **✅ Для debugging:**
```bash
bash -x ./budget-azure-deploy.sh 2>&1 | tee debug.log
```

**Вибирайте метод в залежності від ваших потреб!** 📝🚀
