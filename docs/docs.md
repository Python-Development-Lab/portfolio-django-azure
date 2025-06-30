

# 🚀 Django + PostgreSQL Deployment в Azure - Повний гайд

## 🎯 Рекомендовані стратегії deployment

### **🏆 Варіант 1: App Service + Azure Database (Рекомендований для EPAM SECLAB UA)**

**Ідеально для:** Навчальних проектів, MVP, швидкого deployment

#### **Сервіси:**
- **Azure App Service** (Linux) - для Django додатку
- **Azure Database for PostgreSQL Flexible Server** - керована база даних
- **Azure Storage Account** - для статичних та media файлів
- **Application Insights** - моніторинг та логування

#### **Переваги:**
- ✅ **Managed services** - мінімум адміністрування
- ✅ **Автоскейлінг** - масштабування за потребою  
- ✅ **Backup** - автоматичні бекапи БД
- ✅ **SSL** - автоматичні HTTPS сертифікати
- ✅ **CI/CD** - легка інтеграція з GitHub Actions

---

### **🐳 Варіант 2: Container Instances + Container Apps**

**Ідеально для:** Мікросервісної архітектури, складних додатків

#### **Сервіси:**
- **Azure Container Apps** - для Django контейнерів
- **Azure Database for PostgreSQL** - керована база даних
- **Azure Container Registry** - Docker registry
- **Azure Service Bus** - для черг та повідомлень

#### **Переваги:**
- ✅ **Контейнеризація** - консистентність середовищ
- ✅ **Мікросервіси** - легке розділення компонентів
- ✅ **Auto-scaling** - масштабування до нуля
- ✅ **Multi-cloud** готовність

---

### **⚙️ Варіант 3: Virtual Machines (Традиційний)**

**Ідеально для:** Повний контроль, legacy системи

#### **Сервіси:**
- **Azure Virtual Machines** - Linux VM для Django
- **Azure Database for PostgreSQL** або PostgreSQL на VM
- **Azure Load Balancer** - балансування навантаження
- **Azure Backup** - резервні копії

#### **Переваги:**
- ✅ **Повний контроль** - доступ до ОС
- ✅ **Гнучкість** - будь-які конфігурації
- ✅ **Legacy підтримка** - старі версії ПЗ

---

## 🏆 **Детальний розбір: App Service + PostgreSQL (Рекомендований)**

### **Архітектура рішення:**

```
┌─────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│   GitHub        │    │   Azure App Service  │    │  Azure Database     │
│   Repository    │───▶│   (Django App)       │───▶│  for PostgreSQL     │
│                 │    │                      │    │                     │
└─────────────────┘    └──────────────────────┘    └─────────────────────┘
                                │
                                ▼
                       ┌──────────────────────┐
                       │  Azure Storage       │
                       │  (Static/Media)      │
                       └──────────────────────┘
                                │
                                ▼
                       ┌──────────────────────┐
                       │ Application Insights │
                       │   (Monitoring)       │
                       └──────────────────────┘
```

### **1. Azure App Service налаштування:**

#### **План App Service:**
```bash
# Basic (B1) для розробки
az appservice plan create \
    --name portfolio-plan \
    --resource-group portfolio-rg \
    --sku B1 \
    --is-linux

# Production (P1V2) для прод
az appservice plan create \
    --name portfolio-plan \
    --resource-group portfolio-rg \
    --sku P1V2 \
    --is-linux
```

#### **Web App створення:**
```bash
az webapp create \
    --resource-group portfolio-rg \
    --plan portfolio-plan \
    --name portfolio-django-app \
    --runtime "PYTHON|3.11" \
    --deployment-container-image-name ""
```

#### **Конфігурація Django:**
```bash
# Налаштування змінних середовища
az webapp config appsettings set \
    --resource-group portfolio-rg \
    --name portfolio-django-app \
    --settings \
        SCM_DO_BUILD_DURING_DEPLOYMENT=true \
        ENABLE_ORYX_BUILD=true \
        DJANGO_SETTINGS_MODULE=portfolio_project.settings \
        SECRET_KEY="your-secret-key" \
        DEBUG=False \
        ALLOWED_HOSTS="portfolio-django-app.azurewebsites.net"
```

### **2. Azure Database for PostgreSQL:**

#### **Flexible Server (Рекомендований):**
```bash
# Створення PostgreSQL сервера
az postgres flexible-server create \
    --resource-group portfolio-rg \
    --name portfolio-postgres \
    --admin-user portfolioadmin \
    --admin-password "SecurePassword123!" \
    --sku-name Standard_B1ms \
    --tier Burstable \
    --version 15
```

#### **База даних:**
```bash
az postgres flexible-server db create \
    --resource-group portfolio-rg \
    --server-name portfolio-postgres \
    --database-name portfolio_db
```

#### **Firewall правила:**
```bash
# Дозволити Azure сервіси
az postgres flexible-server firewall-rule create \
    --resource-group portfolio-rg \
    --name portfolio-postgres \
    --rule-name AllowAzureServices \
    --start-ip-address 0.0.0.0 \
    --end-ip-address 0.0.0.0
```

### **3. Azure Storage для статичних файлів:**

```bash
# Створення Storage Account
az storage account create \
    --name portfoliostorage \
    --resource-group portfolio-rg \
    --location eastus \
    --sku Standard_LRS

# Створення контейнерів
az storage container create \
    --name static \
    --account-name portfoliostorage \
    --public-access blob

az storage container create \
    --name media \
    --account-name portfoliostorage \
    --public-access blob
```

---

## 🛠️ **Terraform конфігурація (IaC approach):**

### **Основний файл (main.tf):**
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "portfolio-django-rg"
  location = "East US"
  
  tags = {
    Environment = "Production"
    Project     = "Django Portfolio"
    Purpose     = "EPAM SECLAB UA Capstone"
  }
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "portfolio-plan"
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  os_type            = "Linux"
  sku_name           = "B1"
}

# Linux Web App
resource "azurerm_linux_web_app" "main" {
  name                = "portfolio-django-app"
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_service_plan.main.location
  service_plan_id    = azurerm_service_plan.main.id

  site_config {
    always_on = false
    
    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "ENABLE_ORYX_BUILD"              = "true"
    "DJANGO_SETTINGS_MODULE"         = "portfolio_project.settings"
    "SECRET_KEY"                     = var.django_secret_key
    "DEBUG"                          = "False"
    "DATABASE_URL"                   = "postgresql://${azurerm_postgresql_flexible_server.main.administrator_login}:${var.postgres_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.main.name}"
    "AZURE_STORAGE_ACCOUNT_NAME"     = azurerm_storage_account.main.name
    "AZURE_STORAGE_ACCOUNT_KEY"      = azurerm_storage_account.main.primary_access_key
  }

  identity {
    type = "SystemAssigned"
  }
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "portfolio-postgres"
  resource_group_name    = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  version               = "15"
  administrator_login    = "portfolioadmin"
  administrator_password = var.postgres_password
  sku_name              = "B_Standard_B1ms"
  storage_mb            = 32768
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "portfolio_db"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = "portfoliostorage"
  resource_group_name      = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  account_tier            = "Standard"
  account_replication_type = "LRS"
}

# Storage Containers
resource "azurerm_storage_container" "static" {
  name                  = "static"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "blob"
}

resource "azurerm_storage_container" "media" {
  name                  = "media"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "blob"
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "portfolio-insights"
  location           = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type   = "web"
}
```

---

## 📊 **Порівняння варіантів:**

| Критерій | App Service | Container Apps | Virtual Machines |
|----------|-------------|----------------|------------------|
| **Складність** | 🟢 Низька | 🟡 Середня | 🔴 Висока |
| **Управління** | 🟢 Managed | 🟡 Semi-managed | 🔴 Self-managed |
| **Масштабування** | 🟢 Автоматичне | 🟢 До нуля | 🟡 Ручне |
| **Вартість** | 🟡 Середня | 🟢 Низька | 🟡 Варіативна |
| **Швидкість deployment** | 🟢 Швидко | 🟡 Середньо | 🔴 Повільно |
| **Підходить для навчання** | 🟢 Так | 🟡 Так | 🔴 Ні |

---

## 🎯 **Рекомендація для EPAM SECLAB UA проекту:**

### **Використовуйте App Service + PostgreSQL Flexible Server**

#### **Чому саме цей варіант:**
1. **🎓 Навчальна цінність** - показує знання PaaS сервісів
2. **⚡ Швидкий результат** - мінімум налаштувань
3. **💰 Економічно** - Basic tier для навчання
4. **🔒 Безпечно** - managed сервіси з вбудованою безпекою
5. **📊 Моніторинг** - Application Insights з коробки

#### **Кроки для реалізації:**
1. **Terraform конфігурація** - Infrastructure as Code
2. **GitHub Actions** - автоматичний deployment
3. **Azure Storage** - статичні файли
4. **Application Insights** - моніторинг

### **Вартість (приблизно):**
- **App Service B1:** ~$13/місяць
- **PostgreSQL B1ms:** ~$12/місяць  
- **Storage:** ~$2/місяць
- **Application Insights:** Безкоштовно (до 5GB)

**Загалом:** ~$27/місяць для production-ready середовища

### **Результат:**
Професійний Django додаток з PostgreSQL, готовий до production, з повним Infrastructure as Code та моніторингом! 🚀
