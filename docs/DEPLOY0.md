# Документація: Azure Infrastructure для Django додатку

## 📋 Загальний огляд

Цей документ описує повну інфраструктуру Azure для розгортання Django додатку в production-середовищі. Скрипт автоматизує створення всіх необхідних ресурсів з дотриманням best practices безпеки та масштабованості.Я створив повну документацію з детальними схемами та діаграмами для вашої Azure інфраструктури Django додатку. Документація включає:

## 🎯 **Ключові розділи документації:**

### 1. **Архітектурні діаграми**
- Загальна схема інфраструктури з Mermaid
- Діаграма безпеки та компонентів
- Схема CI/CD pipeline
- Monitoring stack візуалізація

### 2. **Детальний опис компонентів**
- Resource Group та організація
- App Service конфігурація
- PostgreSQL налаштування
- Key Vault та безпека
- Storage Account структура
- Application Insights моніторинг

### 3. **Безпека та Compliance**
- Multi-layer security архітектура
- Zero Trust принципи
- Identity management
- Network security

### 4. **Моніторинг та алерти**
- Ключові метрики performance
- Business metrics
- Alert configuration
- Dashboard setup

### 5. **Оптимізація витрат**
- Cost breakdown діаграма
- Стратегії оптимізації
- Right-sizing recommendations

### 6. **Backup та DR**
- Disaster Recovery схема
- Backup стратегії
- Recovery procedures

### 7. **Практичні секції**
- Deployment процедури
- Налаштування Django
- Troubleshooting guide
- Post-deployment checklist

## 🔧 **Додаткові можливості:**

Документація також включає:
- **Mermaid діаграми** для візуалізації
- **Практичні приклади** команд
- **Code snippets** для конфігурації
- **Best practices** для кожного компонента
- **Troubleshooting** секції
- **Security checklists**

Ця документація може служити як:
- **Technical specification** для команди
- **Onboarding guide** для нових розробників
- **Operations manual** для DevOps
- **Architecture review** для stakeholders

Чи потрібно додати якісь специфічні розділи або деталізувати певні аспекти?

-----------------------------------------------------------------------------

# Azure Infrastructure для Django додатку - Повна документація

## 🏗️ Архітектурна схема

```mermaid
graph TB
    User[👥 Користувачі] --> CDN[🌐 Azure CDN]
    CDN --> AppGW[🔒 Application Gateway]
    AppGW --> WebApp[🚀 Azure App Service]
    
    WebApp --> KeyVault[🔐 Azure Key Vault]
    WebApp --> DB[(🗄️ PostgreSQL Flexible Server)]
    WebApp --> Storage[💾 Azure Storage Account]
    WebApp --> Insights[📊 Application Insights]
    
    subgraph "Resource Group"
        WebApp
        KeyVault
        DB
        Storage
        Insights
        AppPlan[📋 App Service Plan]
    end
    
    subgraph "Security Layer"
        KeyVault
        Identity[🆔 Managed Identity]
        Firewall[🔥 Database Firewall]
    end
    
    subgraph "Monitoring & Logging"
        Insights
        Logs[📋 Application Logs]
        Metrics[📈 Performance Metrics]
    end
```

## 🎯 Цілі та вимоги

### Основні цілі:
- **Безпека**: Захист даних та конфіденційної інформації
- **Масштабованість**: Можливість збільшення навантаження
- **Надійність**: Високий рівень доступності (SLA 99.9%+)
- **Моніторинг**: Повний контроль над станом системи
- **Автоматизація**: Infrastructure as Code підхід

### Технічні вимоги:
- Python 3.11+ для Django
- PostgreSQL 14+ для бази даних
- HTTPS-only з'єднання
- Централізоване управління секретами
- Автоматичне масштабування
- Backup та disaster recovery

## 🧩 Компоненти інфраструктури

### 1. Resource Group (`django-app-production-rg`)
**Призначення**: Логічне групування всіх ресурсів

```bash
az group create \
    --name "django-app-production-rg" \
    --location "West Europe" \
    --tags Environment=production Project=django-app
```

**Переваги**:
- Централізоване управління
- Групове видалення ресурсів
- Контроль доступу на рівні групи
- Консолідована звітність по витратам

### 2. Azure App Service (`django-app-production-{timestamp}`)

```mermaid
graph LR
    Client[HTTP Request] --> LB[Load Balancer]
    LB --> App1[App Instance 1]
    LB --> App2[App Instance 2]
    LB --> App3[App Instance N]
    
    App1 --> Runtime[Python 3.11 Runtime]
    App2 --> Runtime
    App3 --> Runtime
```

**Конфігурація**:
- **SKU**: B1 (Basic) - можна масштабувати до Premium
- **Runtime**: Python 3.11
- **OS**: Linux
- **HTTPS**: Примусово увімкнено
- **Startup Command**: `gunicorn --bind=0.0.0.0 --timeout 600 config.wsgi`

**Змінні середовища**:
```bash
DJANGO_SETTINGS_MODULE="config.settings.production"
SECRET_KEY="@Microsoft.KeyVault(...)"
DATABASE_URL="postgresql://..."
AZURE_STORAGE_ACCOUNT_NAME="djapp..."
DEBUG="False"
ALLOWED_HOSTS="*.azurewebsites.net"
```

### 3. PostgreSQL Flexible Server

```mermaid
graph TB
    App[Django App] --> Conn[Connection Pool]
    Conn --> Primary[(Primary DB)]
    Primary --> Backup[(Automated Backup)]
    Primary --> Replica[(Read Replica)]
    
    subgraph "Security"
        Firewall[Database Firewall]
        SSL[SSL/TLS Encryption]
        VNet[Virtual Network]
    end
```

**Специфікація**:
- **Версія**: PostgreSQL 14
- **SKU**: Standard_D2ds_v4 (2 vCores, 8GB RAM)
- **Storage**: 32GB (auto-scaling enabled)
- **Backup**: 7 днів retention
- **SSL**: Обов'язкове шифрування

**Firewall Rules**:
```bash
# Azure Services access
Start IP: 0.0.0.0
End IP: 0.0.0.0

# Specific IP ranges (production)
Start IP: YOUR_OFFICE_IP
End IP: YOUR_OFFICE_IP
```

### 4. Azure Key Vault (`djapp-kv-{shortcode}`)

```mermaid
graph LR
    App[Django App] --> MSI[Managed Identity]
    MSI --> KV[Key Vault]
    
    subgraph "Stored Secrets"
        Secret1[Django Secret Key]
        Secret2[DB Password]
        Secret3[Storage Key]
        Secret4[API Keys]
    end
    
    KV --> Secret1
    KV --> Secret2
    KV --> Secret3
    KV --> Secret4
```

**Безпека**:
- **Access Policy**: Managed Identity з правами get/list
- **Soft Delete**: Увімкнено (90 днів)
- **Network Access**: Public з обмеженнями
- **Audit Logging**: Всі операції логуються

**Секрети**:
```bash
django-secret-key      # 50-символьний ключ
database-password      # Згенерований пароль БД
storage-account-key    # Ключ доступу до Storage
app-insights-key       # Instrumentation key
```

### 5. Azure Storage Account

```mermaid
graph TB
    Django[Django App] --> Static[Static Files Container]
    Django --> Media[Media Files Container]
    
    subgraph "Storage Account"
        Static --> Blob1[CSS/JS/Images]
        Media --> Blob2[User Uploads]
    end
    
    CDN[Azure CDN] --> Static
    CDN --> Media
```

**Конфігурація**:
- **Type**: StorageV2 (General Purpose v2)
- **Performance**: Standard
- **Replication**: LRS (Locally Redundant)
- **Access Tier**: Hot
- **Public Access**: Blob level

**Containers**:
```bash
static/     # Django static files (CSS, JS, images)
media/      # User uploaded content
backups/    # Database backups (optional)
```

### 6. Application Insights

```mermaid
graph LR
    App[Django App] --> SDK[AI SDK]
    SDK --> AI[Application Insights]
    
    subgraph "Telemetry"
        Requests[HTTP Requests]
        Exceptions[Exceptions]
        Dependencies[Dependencies]
        Performance[Performance]
    end
    
    AI --> Requests
    AI --> Exceptions
    AI --> Dependencies
    AI --> Performance
    
    AI --> Alerts[Smart Alerts]
    AI --> Dashboard[Monitoring Dashboard]
```

**Моніторинг**:
- **Request Tracking**: Автоматичний моніторинг HTTP запитів
- **Exception Tracking**: Автоматичне виявлення помилок
- **Performance Counters**: CPU, Memory, Disk I/O
- **Custom Metrics**: Бізнес-метрики Django
- **Dependency Tracking**: Database, External APIs

## 🔄 Процес розгортання

### Схема CI/CD Pipeline

```mermaid
graph TB
    Dev[👨‍💻 Developer] --> Git[📝 Git Push]
    Git --> GHA[🔄 GitHub Actions]
    
    GHA --> Test[🧪 Run Tests]
    Test --> Build[🏗️ Build App]
    Build --> Deploy[🚀 Deploy to Azure]
    
    Deploy --> WebApp[App Service]
    Deploy --> DB[Run Migrations]
    Deploy --> Static[Upload Static Files]
    
    WebApp --> Health[Health Check]
    Health --> Monitor[Start Monitoring]
```

### Крок за кроком:

1. **Підготовка коду**:
   ```bash
   # requirements.txt
   Django>=4.2,<5.0
   psycopg2-binary>=2.9.0
   gunicorn>=20.1.0
   django-storages[azure]>=1.13.0
   ```

2. **Конфігурація Django**:
   ```python
   # settings/production.py
   import os
   from .base import *
   
   DEBUG = False
   ALLOWED_HOSTS = [os.environ.get('ALLOWED_HOSTS')]
   
   # Database
   DATABASES = {
       'default': dj_database_url.parse(os.environ.get('DATABASE_URL'))
   }
   
   # Azure Storage
   DEFAULT_FILE_STORAGE = 'storages.backends.azure_storage.AzureStorage'
   STATICFILES_STORAGE = 'storages.backends.azure_storage.AzureStorage'
   ```

3. **Deployment**:
   ```bash
   # ZIP deployment
   az webapp deployment source config-zip \
       --src app.zip \
       --name $WEB_APP_NAME \
       --resource-group $RESOURCE_GROUP
   ```

## 🔒 Безпека та Compliance

### Security Layers

```mermaid
graph TB
    Internet[🌐 Internet] --> WAF[🛡️ Web Application Firewall]
    WAF --> TLS[🔐 TLS 1.2+ Encryption]
    TLS --> App[🚀 App Service]
    
    App --> MSI[🆔 Managed Identity]
    MSI --> KV[🔐 Key Vault]
    
    App --> DB[(🗄️ Database)]
    DB --> Encryption[🔒 Encryption at Rest]
    
    subgraph "Network Security"
        VNet[Virtual Network]
        NSG[Network Security Groups]
        Firewall[Database Firewall]
    end
    
    subgraph "Identity & Access"
        RBAC[Role-Based Access Control]
        AAD[Azure Active Directory]
        MSI
    end
```

### Принципи безпеки:

1. **Zero Trust Architecture**:
   - Немає довіри за замовчуванням
   - Перевірка кожного запиту
   - Мінімальні права доступу

2. **Encryption Everywhere**:
   - HTTPS для всього трафіку
   - TLS 1.2+ для база даних
   - Encryption at rest для Storage

3. **Identity Management**:
   - Managed Identity для автентифікації
   - RBAC для контролю доступу
   - Azure AD інтеграція

4. **Network Security**:
   - Database firewall rules
   - Private endpoints (за потреби)
   - DDoS protection

## 📊 Моніторинг та алерти

### Monitoring Stack

```mermaid
graph TB
    App[Django Application] --> Metrics[📈 Custom Metrics]
    App --> Logs[📋 Application Logs]
    App --> Traces[🔍 Distributed Tracing]
    
    Metrics --> AI[Application Insights]
    Logs --> AI
    Traces --> AI
    
    AI --> Alerts[🚨 Smart Alerts]
    AI --> Dashboard[📊 Dashboard]
    AI --> Reports[📑 Reports]
    
    subgraph "Alert Types"
        Performance[Performance Degradation]
        Errors[Error Rate Increase]
        Availability[Availability Issues]
        Security[Security Events]
    end
    
    Alerts --> Performance
    Alerts --> Errors
    Alerts --> Availability
    Alerts --> Security
```

### Ключові метрики:

1. **Performance Metrics**:
   - Response time (< 500ms target)
   - Throughput (requests/second)
   - Error rate (< 1% target)
   - Database query performance

2. **Infrastructure Metrics**:
   - CPU utilization (< 80%)
   - Memory usage (< 85%)
   - Disk I/O
   - Network latency

3. **Business Metrics**:
   - User registrations
   - Page views
   - Feature usage
   - Conversion rates

## 💰 Оптимізація витрат

### Cost Breakdown

```mermaid
pie title Щомісячні витрати (USD)
    "App Service B1" : 55
    "PostgreSQL D2ds_v4" : 120
    "Storage Account" : 10
    "Application Insights" : 20
    "Key Vault" : 5
    "Bandwidth" : 15
```

### Стратегії оптимізації:

1. **Right-sizing Resources**:
   - Моніторинг використання ресурсів
   - Автоматичне масштабування
   - Reserved Instances для довгострокових проектів

2. **Storage Optimization**:
   - Lifecycle policies для старих файлів
   - Cool/Archive tiers для резервних копій
   - CDN для статичних файлів

3. **Database Optimization**:
   - Connection pooling
   - Query optimization
   - Read replicas для read-heavy workloads

## 🔧 Налаштування та конфігурація

### Структура проекту Django

```
django-project/
├── config/
│   ├── settings/
│   │   ├── base.py
│   │   ├── production.py
│   │   └── development.py
│   ├── wsgi.py
│   └── urls.py
├── apps/
│   └── your_app/
├── static/
├── media/
├── requirements/
│   ├── base.txt
│   └── production.txt
├── startup.sh
├── web.config
└── infrastructure-summary.txt
```

### Ключові конфігурації:

1. **Django Settings**:
   ```python
   # config/settings/production.py
   from .base import *
   import dj_database_url
   
   DEBUG = False
   ALLOWED_HOSTS = [os.environ.get('ALLOWED_HOSTS')]
   
   # Database
   DATABASES = {
       'default': dj_database_url.parse(
           os.environ.get('DATABASE_URL'),
           conn_max_age=600
       )
   }
   
   # Azure Storage
   DEFAULT_FILE_STORAGE = 'storages.backends.azure_storage.AzureStorage'
   AZURE_ACCOUNT_NAME = os.environ.get('AZURE_STORAGE_ACCOUNT_NAME')
   AZURE_ACCOUNT_KEY = os.environ.get('AZURE_STORAGE_ACCOUNT_KEY')
   ```

2. **Startup Configuration**:
   ```bash
   #!/bin/bash
   echo "Starting Django application..."
   
   # Install dependencies
   pip install -r requirements.txt
   
   # Collect static files
   python manage.py collectstatic --noinput
   
   # Run migrations
   python manage.py migrate --noinput
   
   # Start Gunicorn
   exec gunicorn --bind=0.0.0.0:8000 --timeout 600 --workers 3 config.wsgi
   ```

## 🚀 Розгортання та управління

### Команди управління:

1. **Повне розгортання**:
   ```bash
   ./script_azure.sh
   ```

2. **Оновлення додатку**:
   ```bash
   az webapp deployment source config-zip \
       --src app.zip \
       --name django-app-production-{timestamp} \
       --resource-group django-app-production-rg
   ```

3. **Моніторинг логів**:
   ```bash
   az webapp log tail \
       --name django-app-production-{timestamp} \
       --resource-group django-app-production-rg
   ```

4. **Масштабування**:
   ```bash
   az appservice plan update \
       --name django-app-production-plan \
       --resource-group django-app-production-rg \
       --sku P1V2
   ```

## 🔄 Backup та Disaster Recovery

### Backup Strategy

```mermaid
graph TB
    App[Production App] --> DB[(Primary DB)]
    DB --> AutoBackup[Automated Backup]
    DB --> Replica[(Read Replica)]
    
    Storage[Storage Account] --> GeoReplication[Geo-Replication]
    
    AutoBackup --> Retention[7-day Retention]
    AutoBackup --> PITR[Point-in-Time Recovery]
    
    subgraph "Disaster Recovery"
        SecondaryRegion[Secondary Region]
        DR_App[DR App Service]
        DR_DB[(DR Database)]
    end
    
    Replica --> DR_DB
    GeoReplication --> SecondaryRegion
```

### Recovery Procedures:

1. **Database Recovery**:
   ```bash
   # Point-in-time restore
   az postgres flexible-server restore \
       --source-server django-app-production-db-{timestamp} \
       --target-server django-app-restored-{date} \
       --restore-time "2023-10-01T12:00:00Z"
   ```

2. **Application Recovery**:
   ```bash
   # Deploy from backup
   az webapp deployment source config-zip \
       --src backup-{date}.zip \
       --name django-app-dr-{timestamp}
   ```

## 📋 Чеклист після розгортання

### Immediate Tasks:
- [ ] Перевірити доступність додатку
- [ ] Протестувати підключення до БД
- [ ] Верифікувати HTTPS
- [ ] Перевірити логи на помилки
- [ ] Підтвердити роботу Application Insights

### Security Review:
- [ ] Перевірити firewall rules
- [ ] Валідувати SSL/TLS конфігурацію
- [ ] Перевірити права доступу Key Vault
- [ ] Протестувати Managed Identity

### Performance Testing:
- [ ] Load testing
- [ ] Database performance
- [ ] Static files delivery
- [ ] Response time monitoring

### Monitoring Setup:
- [ ] Налаштувати алерти
- [ ] Створити dashboard
- [ ] Конфігурувати notifications
- [ ] Перевірити метрики

## 🔗 Корисні посилання

- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [PostgreSQL on Azure](https://docs.microsoft.com/en-us/azure/postgresql/)
- [Azure Key Vault Best Practices](https://docs.microsoft.com/en-us/azure/key-vault/general/best-practices)
- [Django Deployment Guide](https://docs.djangoproject.com/en/4.2/howto/deployment/)
- [Application Insights for Python](https://docs.microsoft.com/en-us/azure/azure-monitor/app/opencensus-python)

---

## 📞 Підтримка

Для питань та підтримки:
- **Technical Lead**: [your-email@company.com]
- **DevOps Team**: [devops@company.com]
- **Emergency**: [emergency-contact]


------------------------------------------------------

```bash
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
#STORAGE_ACCOUNT_NAME="${PROJECT_NAME}${ENVIRONMENT}storage${TIMESTAMP}"
STORAGE_ACCOUNT_NAME="djapp$(date +%s | tail -c 8)"
#KEY_VAULT_NAME="${PROJECT_NAME}-${ENVIRONMENT}-kv-${TIMESTAMP}"
KEY_VAULT_NAME="djapp-kv-$(date +%s | tail -c 6)"  # Коротша назва (16 символів)
APP_INSIGHTS_NAME="${PROJECT_NAME}-${ENVIRONMENT}-insights"

# Конфігурація App Service
APP_SERVICE_SKU="B1"  # F1 (Free), B1 (Basic), S1 (Standard), P1V2 (Premium)
PYTHON_VERSION="3.11"

# Конфігурація бази даних
DB_ADMIN_USER="djangoadmin"
DB_ADMIN_PASSWORD="$(openssl rand -base64 32 | tr -d '=/+' | cut -c1-16)Aa1!"
#DB_SKU="GP_Gen5_1"  # General Purpose, 1 vCore
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
    --enable-rbac-authorization false \
    --tags $TAGS

# Отримайте ваш User Principal ID
USER_ID=$(az ad signed-in-user show --query id --output tsv)
echo "Your User ID: $USER_ID"

# Отримайте поточну підписку ID
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
echo "Subscription ID: $SUBSCRIPTION_ID"

# Створіть динамічний scope для поточного Key Vault
KEY_VAULT_SCOPE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.KeyVault/vaults/${KEY_VAULT_NAME}"

# Використовуйте Access Policy замість RBAC (швидше і надійніше)
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

#-------------
#log "Створення Key Vault: ${KEY_VAULT_NAME}"
#az keyvault create \
#    --name "$KEY_VAULT_NAME" \
#    --resource-group "$RESOURCE_GROUP_NAME" \
#    --location "$LOCATION" \
#    --tags $TAGS


# Отримайте ваш User Principal ID
#USER_ID=$(az ad signed-in-user show --query id --output tsv)
#echo "Your User ID: $USER_ID"

# Надайте собі роль Key Vault Secrets Officer
#az role assignment create \
#    --assignee "$USER_ID" \
#    --role "Key Vault Secrets Officer" \
#    --scope "/subscriptions/f7dc8823-4f06-4346-9de0-badbe6273a54/resourceGroups/django-app-production-rg/providers/Microsoft.KeyVault/vaults/djapp-kv-89430"

# Зачекайте 2-3 хвилини для поширення прав, потім додайте секрети
#sleep 180


# Додавання секретів до Key Vault
#log "Додавання секретів до Key Vault"
#DJANGO_SECRET_KEY=$(openssl rand -base64 50 | tr -d '=/+')

#az keyvault secret set \
#    --vault-name "$KEY_VAULT_NAME" \
#    --name "django-secret-key" \
#    --value "$DJANGO_SECRET_KEY"

#az keyvault secret set \
#    --vault-name "$KEY_VAULT_NAME" \
#    --name "database-password" \
#    --value "$DB_ADMIN_PASSWORD"

#az keyvault secret set \
#    --vault-name "$KEY_VAULT_NAME" \
#    --name "storage-account-key" \
#    --value "$STORAGE_KEY"

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
