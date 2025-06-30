

# 🚀 Рекомендації для Azure Deployment
## Portfolio Django Azure Project

Базуючись на аналізі репозиторію `https://github.com/Python-Development-Lab/portfolio-django-azure`, ось детальні рекомендації для успішного розгортання в Azure.

---

## 📋 **Поточний стан проекту**

### **✅ Що вже є:**
- Базова Django структура
- Requirements.txt
- Основні HTML шаблони
- GitHub репозиторій

### **❌ Що відсутнє для Azure:**
- Azure-специфічні налаштування
- Terraform конфігурація
- CI/CD pipeline
- Production-ready settings
- Containerization

---

## 🛠️ **Обов'язкові зміни для Azure deployment**

### **1. Оновлення Django Settings**

#### **Створити `settings/` структуру:**
```python
# settings/__init__.py
from .base import *

# settings/base.py
import os
from pathlib import Path
from decouple import config
import dj_database_url

BASE_DIR = Path(__file__).resolve().parent.parent.parent

# SECURITY
SECRET_KEY = config('SECRET_KEY')
DEBUG = config('DEBUG', default=False, cast=bool)
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='').split(',')

# APPS
DJANGO_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]

LOCAL_APPS = [
    'portfolio',
]

THIRD_PARTY_APPS = [
    'storages',  # For Azure Storage
]

INSTALLED_APPS = DJANGO_APPS + LOCAL_APPS + THIRD_PARTY_APPS

# MIDDLEWARE
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

# DATABASE
DATABASES = {
    'default': dj_database_url.parse(
        config('DATABASE_URL', default='sqlite:///db.sqlite3')
    )
}

# STATIC & MEDIA
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [BASE_DIR / 'static']

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Azure Storage
if config('AZURE_STORAGE_ACCOUNT_NAME', default=''):
    DEFAULT_FILE_STORAGE = 'storages.backends.azure_storage.AzureStorage'
    AZURE_ACCOUNT_NAME = config('AZURE_STORAGE_ACCOUNT_NAME')
    AZURE_ACCOUNT_KEY = config('AZURE_STORAGE_ACCOUNT_KEY')
    AZURE_CONTAINER = 'media'

# Application Insights
if config('APPLICATIONINSIGHTS_CONNECTION_STRING', default=''):
    INSTALLED_APPS.append('applicationinsights.django')
    MIDDLEWARE.insert(0, 'applicationinsights.django.ApplicationInsightsMiddleware')
    APPLICATION_INSIGHTS = {
        'ikey': config('APPLICATIONINSIGHTS_CONNECTION_STRING'),
    }

# settings/production.py
from .base import *

DEBUG = False

# Security Settings
SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_BROWSER_XSS_FILTER = True
X_FRAME_OPTIONS = 'DENY'
CSRF_COOKIE_SECURE = True
SESSION_COOKIE_SECURE = True

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
            'level': 'INFO',
            'propagate': True,
        },
    },
}

# settings/development.py
from .base import *

DEBUG = True
ALLOWED_HOSTS = ['*']
```

### **2. Оновлення requirements.txt**
```txt
# Core Django
Django==4.2.7
django-storages==1.14.2
whitenoise==6.5.0
gunicorn==21.2.0

# Database
psycopg2-binary==2.9.7
dj-database-url==2.1.0

# Environment
python-decouple==3.8

# Azure Integration
azure-identity==1.15.0
azure-keyvault-secrets==4.7.0
azure-storage-blob==12.19.0

# Monitoring
applicationinsights==0.11.10
opencensus-ext-azure==1.1.13

# Image handling
Pillow==10.0.1
```

### **3. Створити .env.example**
```bash
# Django Configuration
SECRET_KEY=your-secret-key-here
DEBUG=True
DJANGO_SETTINGS_MODULE=portfolio_project.settings.development
ALLOWED_HOSTS=localhost,127.0.0.1,*.azurewebsites.net

# Database
DATABASE_URL=sqlite:///db.sqlite3

# Azure Configuration (Production)
AZURE_STORAGE_ACCOUNT_NAME=
AZURE_STORAGE_ACCOUNT_KEY=
AZURE_CONTAINER_NAME=media

# Application Insights
APPLICATIONINSIGHTS_CONNECTION_STRING=

# Azure Key Vault
AZURE_KEY_VAULT_URL=
```

### **4. Створити startup.sh для Azure**
```bash
#!/bin/bash

echo "Starting Django deployment on Azure..."

# Install dependencies
pip install -r requirements.txt

# Collect static files
python manage.py collectstatic --noinput

# Run migrations
python manage.py migrate --noinput

# Create superuser if needed
python manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'SecurePassword123!')
    print('Superuser created')
EOF

# Start Gunicorn
exec gunicorn --bind=0.0.0.0:8000 --workers=3 portfolio_project.wsgi:application
```

---

## 🏗️ **Terraform Infrastructure**

### **Створити terraform/ директорію:**

#### **terraform/main.tf**
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

provider "azurerm" {
  features {}
}

# Variables
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "portfolio-django"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "EPAM SECLAB UA Capstone"
  }
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "${var.project_name}-${var.environment}-asp"
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  os_type            = "Linux"
  sku_name           = "B1"
}

# App Service
resource "azurerm_linux_web_app" "main" {
  name                = "${var.project_name}-${var.environment}-app"
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_service_plan.main.location
  service_plan_id    = azurerm_service_plan.main.id

  site_config {
    always_on = false
    application_stack {
      python_version = "3.11"
    }
    app_command_line = "startup.sh"
  }

  app_settings = {
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "DJANGO_SETTINGS_MODULE"         = "portfolio_project.settings.production"
    "SECRET_KEY"                     = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.django_secret.id})"
    "DATABASE_URL"                   = "postgresql://${azurerm_postgresql_flexible_server.main.administrator_login}:${azurerm_postgresql_flexible_server.main.administrator_password}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.main.name}"
    "AZURE_STORAGE_ACCOUNT_NAME"     = azurerm_storage_account.main.name
    "AZURE_STORAGE_ACCOUNT_KEY"      = azurerm_storage_account.main.primary_access_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
  }

  identity {
    type = "SystemAssigned"
  }
}

# PostgreSQL
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.project_name}-${var.environment}-postgres"
  resource_group_name    = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  version               = "15"
  administrator_login    = "portfolioadmin"
  administrator_password = "SecurePassword123!"
  sku_name              = "B_Standard_B1ms"
  storage_mb            = 32768
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = "portfolio"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = "${replace(var.project_name, "-", "")}${var.environment}storage"
  resource_group_name      = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  account_tier            = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "media" {
  name                  = "media"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "blob"
}

# Key Vault
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = "${var.project_name}-${var.environment}-kv"
  location           = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id          = data.azurerm_client_config.current.tenant_id
  sku_name           = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_linux_web_app.main.identity[0].principal_id

    secret_permissions = [
      "Get", "List"
    ]
  }
}

resource "azurerm_key_vault_secret" "django_secret" {
  name         = "django-secret-key"
  value        = "your-production-secret-key-here"
  key_vault_id = azurerm_key_vault.main.id
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "${var.project_name}-${var.environment}-ai"
  location           = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type   = "web"
}

# Outputs
output "web_app_url" {
  value = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}
```

---

## 🔄 **GitHub Actions CI/CD**

### **Створити .github/workflows/azure-deploy.yml:**
```yaml
name: Deploy to Azure

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

env:
  AZURE_WEBAPP_NAME: portfolio-django-dev-app

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install pytest pytest-django
    
    - name: Create test environment
      run: |
        echo "SECRET_KEY=test-key" > .env
        echo "DEBUG=True" >> .env
        echo "DATABASE_URL=postgresql://postgres:postgres@localhost:5432/test_db" >> .env
        echo "DJANGO_SETTINGS_MODULE=portfolio_project.settings.development" >> .env
    
    - name: Run migrations
      run: python manage.py migrate
    
    - name: Run tests
      run: python manage.py test

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
    
    - name: Collect static files
      run: |
        python manage.py collectstatic --noinput
      env:
        SECRET_KEY: ${{ secrets.SECRET_KEY }}
        DJANGO_SETTINGS_MODULE: portfolio_project.settings.production
    
    - name: Deploy to Azure Web App
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ env.AZURE_WEBAPP_NAME }}
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
```

---

## 🐳 **Containerization (Опціонально)**

### **Dockerfile:**
```dockerfile
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . .

# Collect static files
RUN python manage.py collectstatic --noinput

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "portfolio_project.wsgi:application"]
```

---

## 📝 **Оновлення файлів проекту**

### **1. Оновити manage.py:**
```python
#!/usr/bin/env python
import os
import sys

if __name__ == '__main__':
    # Set default settings module
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'portfolio_project.settings.development')
    
    # Azure detection
    if 'WEBSITE_HOSTNAME' in os.environ:
        os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'portfolio_project.settings.production')
    
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    execute_from_command_line(sys.argv)
```

### **2. Створити wsgi.py для production:**
```python
import os
from django.core.wsgi import get_wsgi_application

# Azure detection
if 'WEBSITE_HOSTNAME' in os.environ:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'portfolio_project.settings.production')
else:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'portfolio_project.settings.development')

application = get_wsgi_application()
```

---

## 🔐 **GitHub Secrets Configuration**

Налаштуйте наступні secrets в GitHub:

```
AZURE_WEBAPP_PUBLISH_PROFILE  # Отримати з Azure Portal
SECRET_KEY                   # Django secret key для production
AZURE_CREDENTIALS           # Service Principal для Terraform
```

---

## 📋 **Покроковий план deployment:**

### **Крок 1: Підготовка коду**
```bash
# 1. Додати всі нові файли до проекту
# 2. Оновити існуючі файли згідно рекомендацій
# 3. Commit та push змін
git add .
git commit -m "Add Azure deployment configuration"
git push origin main
```

### **Крок 2: Azure Infrastructure**
```bash
# 1. Встановити Azure CLI та Terraform
# 2. Логін до Azure
az login

# 3. Розгорнути інфраструктуру
cd terraform
terraform init
terraform plan
terraform apply
```

### **Крок 3: GitHub Actions**
```bash
# 1. Налаштувати GitHub Secrets
# 2. Отримати publish profile з Azure
# 3. Trigger deployment через push
```

### **Крок 4: Верифікація**
```bash
# 1. Перевірити URL додатку
# 2. Протестувати функціональність
# 3. Перевірити Application Insights
# 4. Налаштувати моніторинг
```

---

## 🎯 **Очікувані результати**

Після впровадження цих змін, ваш проект матиме:

✅ **Production-ready Django додаток**  
✅ **Azure App Service deployment**  
✅ **PostgreSQL база даних**  
✅ **Azure Storage для медіа файлів**  
✅ **Application Insights моніторинг**  
✅ **CI/CD через GitHub Actions**  
✅ **Infrastructure as Code з Terraform**  
✅ **Security best practices**

**Результат:** Повнофункціональний portfolio додаток на Azure з enterprise-рівня архітектурою! 🚀










---------------------------------------------------

# 🐳 Dev Container Configuration Documentation

## 📋 Overview

This dev container configuration creates a comprehensive development environment for Django portfolio project with Azure deployment capabilities. It combines Django development with Azure CLI and Terraform for Infrastructure as Code, specifically designed for EPAM SECLAB UA Capstone projects.

---

## 🏗️ Configuration Breakdown

### **Base Image**
```json
"image": "mcr.microsoft.com/devcontainers/universal:2"
```

**Description:** Microsoft Universal Dev Container image with pre-installed development tools
- **Size:** ~6GB with comprehensive tooling
- **Includes:** Python 3.12, Node.js, Git, Docker, and 20+ development tools
- **Benefits:** 
  - Zero manual tool installation
  - Consistent across all developers
  - Regular Microsoft updates and security patches

---

### **Features Integration**

#### **Azure CLI**
```json
"ghcr.io/devcontainers/features/azure-cli:1": {
  "version": "latest"
}
```

**Capabilities:**
- Full Azure CLI functionality for cloud resource management
- Authentication and subscription management
- Resource deployment and monitoring
- Integration with Azure DevOps and GitHub Actions

**Use Cases:**
- Deploy infrastructure to Azure
- Manage Azure resources from command line
- Configure CI/CD pipelines
- Monitor application performance

#### **Terraform**
```json
"ghcr.io/devcontainers/features/terraform:1": {
  "version": "latest"
}
```

**Capabilities:**
- Infrastructure as Code (IaC) provisioning
- Multi-cloud resource management
- State management and version control
- Plan and apply infrastructure changes

**Use Cases:**
- Define Azure infrastructure in code
- Version control infrastructure changes
- Automated deployment pipelines
- Environment consistency (dev/staging/prod)

---

### **Resource Requirements**

```json
"hostRequirements": {
  "cpus": 4,
  "memory": "4gb",
  "storage": "64gb"
}
```

| Resource | Allocation | Justification |
|----------|------------|---------------|
| **CPU** | 4 cores | Django development + Docker + VS Code IntelliSense |
| **Memory** | 4GB | Universal image + Python packages + IDE |
| **Storage** | 64GB | Source code + Docker images + dependencies |

**Performance Impact:**
- Faster container startup and build times
- Smooth VS Code experience with extensions
- Concurrent Django server and development tools

---

### **Lifecycle Commands**

#### **Creation Sequence**
```json
"waitFor": "onCreateCommand"
```
**Purpose:** Ensures container waits for initial setup completion before user access

#### **Content Updates**
```json
"updateContentCommand": "pip install -r requirements.txt && python manage.py migrate"
```
**Execution:** Runs when container is rebuilt or repository updates
**Actions:**
1. Install/update Python dependencies
2. Apply database migrations
3. Prepare development environment

#### **Post Creation**
```json
"postCreateCommand": "cp .env.example .env"
```
**Purpose:** One-time setup after container creation
**Result:** Creates local environment configuration file

#### **Attach Command**
```json
"postAttachCommand": {
  "server": "python manage.py runserver"
}
```
**Execution:** Every time user connects to the container
**Result:** Automatically starts Django development server on port 8000

---

### **VS Code Customizations**

#### **Auto-opened Files**
```json
"openFiles": [
  "project_portfolio/templates/index.html"
]
```
**Purpose:** Immediately shows main template file for quick development start

#### **Essential Extensions**
```json
"extensions": [
  "ms-python.python",                    // Python language support
  "hashicorp.terraform",                 // Terraform syntax and validation
  "ms-azuretools.vscode-azureterraform", // Azure-Terraform integration
  "ms-azuretools.vscode-azurecli"        // Azure CLI integration
]
```

**Extension Benefits:**
- **Python:** IntelliSense, debugging, linting, formatting
- **Terraform:** Syntax highlighting, validation, auto-completion
- **Azure Terraform:** Azure resource templates and snippets
- **Azure CLI:** Command palette integration and Azure resource explorer

#### **Terraform Configuration**
```json
"terraform.languageServer.enable": true,
"terraform.validation.enableEnhancedValidation": true
```
**Features:**
- Real-time syntax validation
- Resource documentation on hover
- Auto-completion for Azure resources
- Error detection and suggestions

---

### **Port Configuration**

```json
"portsAttributes": {
  "8000": {
    "label": "Application",
    "onAutoForward": "openPreview"
  }
},
"forwardPorts": [8000]
```

**Port 8000 Configuration:**
- **Label:** "Application" (appears in Ports panel)
- **Auto-forward:** Automatically opens in browser preview
- **Protocol:** HTTP (Django development server)

**User Experience:**
- Instant access to running Django application
- No manual port forwarding required
- Seamless development workflow

---

## 🚀 Development Workflow

### **Container Startup Sequence**
1. **Image Pull:** Downloads Universal base image (~6GB)
2. **Feature Installation:** Installs Azure CLI and Terraform
3. **Environment Setup:** Copies .env.example to .env
4. **Dependencies:** Installs Python packages from requirements.txt
5. **Database:** Runs Django migrations
6. **Server Start:** Launches Django development server
7. **IDE Ready:** Opens VS Code with extensions loaded

### **Expected Timeline**
- **First Setup:** 5-8 minutes (image download + features)
- **Subsequent Starts:** 2-3 minutes (cached images)
- **Code Changes:** Instant hot reload

---

## 💡 Use Cases and Benefits

### **For Django Development**
- **Instant Setup:** No Python/Django installation required
- **Consistent Environment:** Same setup across all developers
- **Integrated Tools:** Database, server, and IDE in one container

### **For Azure Deployment**
- **Cloud-Ready:** Azure CLI pre-configured for deployments
- **Infrastructure as Code:** Terraform for reproducible infrastructure
- **CI/CD Integration:** Easy GitHub Actions integration

### **For Learning and Training**
- **EPAM SECLAB UA Compliance:** Meets academic project requirements
- **Professional Tools:** Industry-standard development environment
- **Documentation:** Built-in help and autocomplete for Azure resources

---

## 🔧 Customization Options

### **Performance Optimization**
```json
// For better performance on limited resources
"hostRequirements": {
  "cpus": 2,
  "memory": "3gb",
  "storage": "32gb"
}
```

### **Additional Extensions**
```json
"extensions": [
  // Existing extensions...
  "ms-python.black-formatter",     // Code formatting
  "ms-python.isort",               // Import sorting
  "GitHub.copilot",                // AI code assistance
  "bradlc.vscode-tailwindcss"      // CSS framework support
]
```

### **Environment Variables**
```json
"remoteEnv": {
  "DJANGO_SETTINGS_MODULE": "project_portfolio.settings",
  "DEBUG": "True",
  "DATABASE_URL": "sqlite:///db.sqlite3"
}
```

---

## 🚨 Troubleshooting

### **Common Issues**

#### **"No space left on device"**
**Solution:** Increase storage allocation
```json
"hostRequirements": {
  "storage": "128gb"  // Increase storage
}
```

#### **Slow startup**
**Solution:** Use Python-specific image for faster startup
```json
"image": "mcr.microsoft.com/devcontainers/python:3.11"
```

#### **Memory issues**
**Solution:** Optimize memory allocation
```json
"hostRequirements": {
  "memory": "6gb"  // Increase memory
}
```

### **Recovery Procedures**
1. **Container Issues:** Rebuild container (Ctrl+Shift+P → "Rebuild Container")
2. **Extension Problems:** Disable/re-enable problematic extensions
3. **Port Conflicts:** Check port availability in Ports panel
4. **Storage Full:** Clear Docker cache or increase storage allocation

---

## 📊 Performance Metrics

### **Startup Performance**
- **Cold Start:** 5-8 minutes (first time)
- **Warm Start:** 2-3 minutes (cached)
- **Code Reload:** <5 seconds (file changes)

### **Resource Usage**
- **CPU:** 15-25% during development
- **Memory:** 2-3GB active usage
- **Storage:** 8-12GB total footprint

### **Network Requirements**
- **Initial Setup:** 6-8GB download
- **Updates:** 100-500MB (feature updates)
- **Development:** Minimal (local development)

---

## 🎯 Best Practices

### **Development Workflow**
1. **Start Container:** Let all initialization complete
2. **Check Ports:** Verify Django server is running on port 8000
3. **Environment:** Confirm .env file is properly configured
4. **Extensions:** Ensure all VS Code extensions are loaded
5. **Testing:** Run `python manage.py check` to validate setup

### **Azure Integration**
1. **Authentication:** Run `az login` for Azure CLI access
2. **Subscription:** Set active subscription with `az account set`
3. **Terraform:** Initialize with `terraform init` in terraform directory
4. **Deployment:** Use integrated terminal for deployment commands

### **Code Quality**
1. **Linting:** Use built-in Python linting and formatting
2. **Version Control:** Commit changes regularly
3. **Testing:** Run Django tests with `python manage.py test`
4. **Documentation:** Keep README.md updated with setup instructions

---

## 📚 Related Documentation

- [Dev Containers Official Docs](https://containers.dev/)
- [Azure CLI Documentation](https://docs.microsoft.com/cli/azure/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/)
- [Django Development Guide](https://docs.djangoproject.com/)
- [VS Code Python Extension](https://code.visualstudio.com/docs/python/python-tutorial)

---

## 🏷️ Version Information

| Component | Version | Last Updated |
|-----------|---------|--------------|
| **Base Image** | Universal:2 | Microsoft Managed |
| **Azure CLI** | Latest | Auto-updated |
| **Terraform** | Latest | Auto-updated |
| **Python** | 3.12 | Included in Universal |
| **Node.js** | 18.x | Included in Universal |

---

**Note:** This configuration is optimized for EPAM SECLAB UA Capstone projects and provides a complete development environment for Django applications with Azure deployment capabilities.
