


## ✅ **Checklist для успішного deployment**

### **Перед налаштуванням:**
- [ ] Azure App Service створено
- [ ] Всі GitHub Secrets налаштовані
- [ ] Django проект готовий для production
- [ ] requirements.txt містить всі залежності
- [ ] settings.py має production конфігурацію

### **Після налаштування:**
- [ ] Workflow файл створено в `.github/workflows/`
- [ ] Push в main branch trigger deployment
- [ ] Health checks проходять успішно
- [ ] Моніторинг налаштовано
- [ ] Rollback стратегія готова

**Результат: Повністю автоматизований CI/CD pipeline для Django в Azure! 🚀**



## 📋 **GitHub Secrets**

### **Базові secrets:**
```
AZURE_WEBAPP_PUBLISH_PROFILE      # Publish profile з Azure
SECRET_KEY                        # Django secret key
AZURE_CREDENTIALS                 # Service Principal JSON
```

### **Додаткові secrets для повної функціональності:**
```
DATABASE_URL                      # PostgreSQL connection string
AZURE_RESOURCE_GROUP             # Назва resource group
AZURE_CONTAINER_REGISTRY         # ACR login server
REGISTRY_USERNAME                # ACR username
REGISTRY_PASSWORD                # ACR password
SLACK_WEBHOOK_URL               # Для notifications
ARM_CLIENT_ID                   # Terraform Service Principal
ARM_CLIENT_SECRET               # Terraform Service Principal secret
ARM_SUBSCRIPTION_ID             # Azure subscription
ARM_TENANT_ID                   # Azure tenant
```




Детальний гайд по налаштуванню GitHub Secrets для Azure deployment:

## 🎯 **Кроки для налаштування GitHub Secrets**


## 🔑 **SECRET_KEY**

### **Крок 1: Генерація Django Secret Key**

#### **Метод 1: Python скрипт**
```python
# generate_secret_key.py
from django.core.management.utils import get_random_secret_key

secret_key = get_random_secret_key()
print(f"Generated SECRET_KEY: {secret_key}")
```

```bash
# Виконати скрипт
python generate_secret_key.py
```


## 🛠️ **Додавання Secrets в GitHub**

### **Крок 1: Перейти в GitHub Repository**
1. Відкрити ваш репозиторій на GitHub
2. Перейти в **Settings** (вкладка вгорі)
3. В лівому меню обрати **Secrets and variables** → **Actions**

### **Крок 2: Додати кожен secret**

#### **AZURE_WEBAPP_PUBLISH_PROFILE:**
```
Name: AZURE_WEBAPP_PUBLISH_PROFILE
Value: [Вставити весь XML з publish profile файлу]
```

#### **SECRET_KEY:**
```
Name: SECRET_KEY
Value: django-insecure-abc123def456ghi789jkl012mno345pqr678stu901vwx234yz5
```


--------------------------------------------

Створю повний гайд по автоматичному deployment Django через GitHub Actions в Azure:## 🚀 **GitHub Actions Azure Deployment - Покроковий гайд**

### **📋 Швидкий старт:**

## **1. Базовий Workflow (Рекомендований)**
```yaml
# .github/workflows/azure-deploy.yml
name: Deploy to Azure

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
    
    - name: Collect static files
      run: python manage.py collectstatic --noinput
      env:
        SECRET_KEY: ${{ secrets.SECRET_KEY }}
    
    - name: Deploy to Azure
      uses: azure/webapps-deploy@v2
      with:
        app-name: 'your-app-name'
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
```

---

## **🔄 CI/CD Pipeline Етапи:**

### **📊 Повний Production Pipeline:**

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   GitHub    │    │   Testing   │    │    Build    │    │   Deploy    │
│    Push     │───▶│   + Lint    │───▶│   + Static  │───▶│   to Azure  │
│             │    │             │    │    Files    │    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │                   │
   Code Changes      Unit Tests         Package App         Live Site
                    Security Scan      Collect Static       Health Check
```

---

## **🎯 Варіанти Deployment:**

### **1. 🟢 Simple Deployment (Новачкам)**
- Один workflow файл
- Push → Deploy
- Мінімальні налаштування

### **2. 🟡 Advanced Pipeline (Рекомендований)**
- Тестування + Security scan
- Staging → Production
- Health checks

### **3. 🔴 Enterprise Pipeline (Професійний)**
- Blue-green deployment
- Terraform infrastructure
- Повний моніторинг

---

## **⚙️ Налаштування за 5 хвилин:**

### **Крок 1: Створити workflow файл**
```bash
mkdir -p .github/workflows
# Скопіювати базовий workflow з артефакту вище
```

### **Крок 2: Налаштувати Secrets**
```
GitHub → Settings → Secrets → Actions:
- AZURE_WEBAPP_PUBLISH_PROFILE
- SECRET_KEY  
- AZURE_CREDENTIALS (для Terraform)
```

### **Крок 3: Push код**
```bash
git add .github/workflows/azure-deploy.yml
git commit -m "Add Azure deployment workflow"
git push origin main
```

### **Крок 4: Перевірити результат**
```
GitHub → Actions → перегляд workflow
Azure Portal → App Service → перевірка deployment
```

---

## **🔧 Корисні фічі:**

### **🧪 Автоматичне тестування:**
```yaml
- name: Run tests
  run: |
    python manage.py test
    pytest --cov=.
```

### **🔒 Security scanning:**
```yaml
- name: Security scan
  run: |
    pip install bandit safety
    bandit -r .
    safety check
```

### **💬 Slack notifications:**
```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK_URL }}
```

---

## **🎯 Результат автоматизації:**

✅ **Push код → Автоматичний deploy**  
✅ **Тестування перед deployment**  
✅ **Zero-downtime deployment**  
✅ **Rollback у випадку помилок**  
✅ **Notifications про статус**  
✅ **Health checks після deploy**

**Часова економія: З годин ручного deploy до хвилин автоматичного! 🚀**

**Хочете почати з простого workflow або одразу налаштувати повний pipeline?**


--------------------------------------------------------------------------------------------------------------------------

# 🚀 GitHub Actions Azure Deployment для Django

## 📋 Огляд

Повний гайд по налаштуванню автоматичного deployment Django додатку в Azure через GitHub Actions з CI/CD pipeline, тестуванням та моніторингом.

---

## 🏗️ **Архітектура CI/CD Pipeline**

```
GitHub Push → GitHub Actions → Tests → Build → Deploy → Azure App Service
     ↓              ↓            ↓       ↓        ↓           ↓
   Trigger      Checkout     Unit Tests  Package  Deploy   Live App
                              ↓           ↓        ↓
                         Integration  Static Files Azure
                            Tests    Collection  Resources
```

---

## 🔧 **Основний GitHub Actions Workflow**

### **Створити `.github/workflows/azure-deploy.yml`:**

```yaml
name: Deploy Django to Azure

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:  # Manual trigger

env:
  AZURE_WEBAPP_NAME: portfolio-django-app    # Change to your app name
  PYTHON_VERSION: '3.11'

jobs:
  # =============================================
  # JOB 1: TESTING
  # =============================================
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
    - name: 📥 Checkout code
      uses: actions/checkout@v4

    - name: 🐍 Set up Python ${{ env.PYTHON_VERSION }}
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}

    - name: 📦 Cache pip dependencies
      uses: actions/cache@v3
      with:
        path: ~/.cache/pip
        key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
        restore-keys: |
          ${{ runner.os }}-pip-

    - name: 🔧 Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install pytest pytest-django pytest-cov

    - name: ⚙️ Setup test environment
      run: |
        echo "SECRET_KEY=test-secret-key-for-github-actions" > .env
        echo "DEBUG=True" >> .env
        echo "DATABASE_URL=postgresql://postgres:postgres@localhost:5432/test_db" >> .env
        echo "DJANGO_SETTINGS_MODULE=portfolio_project.settings.development" >> .env

    - name: 🗃️ Run database migrations
      run: python manage.py migrate

    - name: 🧪 Run Django tests
      run: |
        python manage.py test --verbosity=2
        pytest --cov=. --cov-report=xml

    - name: 📊 Upload coverage reports
      uses: codecov/codecov-action@v3
      if: github.event_name == 'push'
      with:
        file: ./coverage.xml
        flags: unittests

  # =============================================
  # JOB 2: SECURITY SCAN
  # =============================================
  security:
    runs-on: ubuntu-latest
    needs: test
    
    steps:
    - name: 📥 Checkout code
      uses: actions/checkout@v4

    - name: 🐍 Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}

    - name: 🔒 Install security tools
      run: |
        pip install bandit safety semgrep

    - name: 🛡️ Run Bandit security scan
      run: bandit -r . -f json -o bandit-report.json || true

    - name: 🔍 Check for known vulnerabilities
      run: safety check --json || true

    - name: 📋 Run Semgrep scan
      run: semgrep --config=auto . --json --output=semgrep-report.json || true

    - name: 📤 Upload security reports
      uses: actions/upload-artifact@v3
      with:
        name: security-reports
        path: |
          bandit-report.json
          semgrep-report.json

  # =============================================
  # JOB 3: BUILD & DEPLOY TO STAGING
  # =============================================
  deploy-staging:
    runs-on: ubuntu-latest
    needs: [test, security]
    if: github.ref == 'refs/heads/develop'
    environment: staging
    
    steps:
    - name: 📥 Checkout code
      uses: actions/checkout@v4

    - name: 🐍 Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}

    - name: 🔧 Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt

    - name: ⚙️ Configure Django settings
      run: |
        echo "SECRET_KEY=${{ secrets.SECRET_KEY }}" > .env
        echo "DEBUG=False" >> .env
        echo "DJANGO_SETTINGS_MODULE=portfolio_project.settings.production" >> .env

    - name: 📁 Collect static files
      run: python manage.py collectstatic --noinput

    - name: 🚀 Deploy to Azure Staging
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ env.AZURE_WEBAPP_NAME }}-staging
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE_STAGING }}

  # =============================================
  # JOB 4: DEPLOY TO PRODUCTION
  # =============================================
  deploy-production:
    runs-on: ubuntu-latest
    needs: [test, security]
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
    - name: 📥 Checkout code
      uses: actions/checkout@v4

    - name: 🐍 Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}

    - name: 🔧 Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt

    - name: ⚙️ Configure production settings
      run: |
        echo "SECRET_KEY=${{ secrets.SECRET_KEY }}" > .env
        echo "DEBUG=False" >> .env
        echo "DJANGO_SETTINGS_MODULE=portfolio_project.settings.production" >> .env
        echo "DATABASE_URL=${{ secrets.DATABASE_URL }}" >> .env

    - name: 📁 Collect static files
      run: python manage.py collectstatic --noinput

    - name: 📦 Create deployment package
      run: |
        zip -r deployment.zip . \
          -x "*.git*" "*__pycache__*" "*.pyc" "tests/*" \
             "node_modules/*" ".vscode/*" "*.md"

    - name: 🚀 Deploy to Azure Production
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ env.AZURE_WEBAPP_NAME }}
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
        package: deployment.zip

    - name: 🗃️ Run production migrations
      uses: azure/CLI@v1
      with:
        azcliversion: latest
        inlineScript: |
          az webapp ssh --name ${{ env.AZURE_WEBAPP_NAME }} \
            --resource-group ${{ secrets.AZURE_RESOURCE_GROUP }} \
            --command "cd /home/site/wwwroot && python manage.py migrate --noinput"

  # =============================================
  # JOB 5: POST-DEPLOYMENT TESTS
  # =============================================
  post-deployment-tests:
    runs-on: ubuntu-latest
    needs: deploy-production
    if: github.ref == 'refs/heads/main'
    
    steps:
    - name: 📥 Checkout code
      uses: actions/checkout@v4

    - name: 🐍 Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}

    - name: 🔧 Install test dependencies
      run: |
        pip install requests pytest

    - name: 🌐 Health check
      run: |
        python -c "
        import requests
        import time
        
        url = 'https://${{ env.AZURE_WEBAPP_NAME }}.azurewebsites.net'
        max_retries = 10
        
        for i in range(max_retries):
            try:
                response = requests.get(url, timeout=30)
                if response.status_code == 200:
                    print(f'✅ App is healthy: {response.status_code}')
                    break
                else:
                    print(f'⚠️ Status code: {response.status_code}')
            except Exception as e:
                print(f'❌ Attempt {i+1}: {e}')
                
            if i < max_retries - 1:
                time.sleep(30)
            else:
                raise Exception('❌ Health check failed after all retries')
        "

    - name: 🧪 Smoke tests
      run: |
        python -c "
        import requests
        
        base_url = 'https://${{ env.AZURE_WEBAPP_NAME }}.azurewebsites.net'
        
        # Test endpoints
        endpoints = ['/', '/admin/', '/static/css/style.css']
        
        for endpoint in endpoints:
            url = base_url + endpoint
            try:
                response = requests.get(url, timeout=10)
                print(f'✅ {endpoint}: {response.status_code}')
            except Exception as e:
                print(f'❌ {endpoint}: {e}')
        "

  # =============================================
  # JOB 6: NOTIFICATIONS
  # =============================================
  notify:
    runs-on: ubuntu-latest
    needs: [deploy-production, post-deployment-tests]
    if: always()
    
    steps:
    - name: 📧 Send notification
      uses: 8398a7/action-slack@v3
      if: always()
      with:
        status: ${{ job.status }}
        text: |
          🚀 Django Portfolio Deployment
          📊 Status: ${{ job.status }}
          🌐 URL: https://${{ env.AZURE_WEBAPP_NAME }}.azurewebsites.net
          👤 Author: ${{ github.actor }}
          📝 Commit: ${{ github.event.head_commit.message }}
      env:
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

---

## 🐳 **Альтернативний Workflow з Docker**

### **Створити `.github/workflows/docker-deploy.yml`:**

```yaml
name: Docker Deploy to Azure

on:
  push:
    branches: [ main ]

env:
  REGISTRY: ${{ secrets.AZURE_CONTAINER_REGISTRY }}
  IMAGE_NAME: portfolio-django
  AZURE_WEBAPP_NAME: portfolio-django-app

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    
    steps:
    - name: 📥 Checkout code
      uses: actions/checkout@v4

    - name: 🐳 Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: 🔐 Login to Azure Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ secrets.REGISTRY_USERNAME }}
        password: ${{ secrets.REGISTRY_PASSWORD }}

    - name: 🏗️ Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

  deploy:
    runs-on: ubuntu-latest
    needs: build-and-push
    
    steps:
    - name: 🔐 Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: 🚀 Deploy to Azure Container Instances
      uses: azure/aci-deploy@v1
      with:
        resource-group: ${{ secrets.AZURE_RESOURCE_GROUP }}
        dns-name-label: ${{ env.AZURE_WEBAPP_NAME }}
        image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        registry-login-server: ${{ env.REGISTRY }}
        registry-username: ${{ secrets.REGISTRY_USERNAME }}
        registry-password: ${{ secrets.REGISTRY_PASSWORD }}
        name: ${{ env.AZURE_WEBAPP_NAME }}
        location: 'east us'
```

---

## 🎯 **Workflow з Terraform Infrastructure**

### **Створити `.github/workflows/infrastructure-deploy.yml`:**

```yaml
name: Infrastructure + Application Deploy

on:
  push:
    branches: [ main ]
    paths: [ 'terraform/**', '.github/workflows/**' ]
  workflow_dispatch:

env:
  TF_VERSION: '1.6.0'
  ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}

jobs:
  terraform:
    runs-on: ubuntu-latest
    outputs:
      webapp_name: ${{ steps.tf-output.outputs.webapp_name }}
      resource_group: ${{ steps.tf-output.outputs.resource_group }}
    
    steps:
    - name: 📥 Checkout code
      uses: actions/checkout@v4

    - name: 🏗️ Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: ${{ env.TF_VERSION }}
        terraform_wrapper: false

    - name: 🔧 Terraform Init
      run: terraform init
      working-directory: terraform

    - name: 📋 Terraform Plan
      run: terraform plan -out=tfplan
      working-directory: terraform

    - name: 🚀 Terraform Apply
      run: terraform apply tfplan
      working-directory: terraform

    - name: 📤 Get Terraform Outputs
      id: tf-output
      run: |
        echo "webapp_name=$(terraform output -raw webapp_name)" >> $GITHUB_OUTPUT
        echo "resource_group=$(terraform output -raw resource_group_name)" >> $GITHUB_OUTPUT
      working-directory: terraform

  deploy-app:
    runs-on: ubuntu-latest
    needs: terraform
    
    steps:
    - name: 📥 Checkout code
      uses: actions/checkout@v4

    - name: 🐍 Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'

    - name: 🔧 Install dependencies
      run: |
        pip install -r requirements.txt

    - name: 📁 Collect static files
      run: python manage.py collectstatic --noinput
      env:
        SECRET_KEY: ${{ secrets.SECRET_KEY }}
        DJANGO_SETTINGS_MODULE: portfolio_project.settings.production

    - name: 🚀 Deploy to Azure
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ needs.terraform.outputs.webapp_name }}
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
```

---

## 🔄 **Workflow з Blue-Green Deployment**

### **Створити `.github/workflows/blue-green-deploy.yml`:**

```yaml
name: Blue-Green Deployment

on:
  push:
    branches: [ main ]

env:
  AZURE_WEBAPP_NAME: portfolio-django-app

jobs:
  deploy-green:
    runs-on: ubuntu-latest
    
    steps:
    - name: 📥 Checkout code
      uses: actions/checkout@v4

    - name: 🐍 Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'

    - name: 🔧 Install dependencies
      run: pip install -r requirements.txt

    - name: 📁 Collect static files
      run: python manage.py collectstatic --noinput
      env:
        SECRET_KEY: ${{ secrets.SECRET_KEY }}

    - name: 🟢 Deploy to Green Slot
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ env.AZURE_WEBAPP_NAME }}
        slot-name: green
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}

    - name: 🧪 Run health checks on Green
      run: |
        python -c "
        import requests
        import time
        
        green_url = 'https://${{ env.AZURE_WEBAPP_NAME }}-green.azurewebsites.net'
        
        for i in range(5):
            try:
                response = requests.get(green_url, timeout=30)
                if response.status_code == 200:
                    print('✅ Green slot is healthy')
                    break
            except Exception as e:
                print(f'❌ Health check failed: {e}')
                time.sleep(30)
        else:
            raise Exception('Green slot health check failed')
        "

    - name: 🔄 Swap Green to Production
      uses: azure/CLI@v1
      with:
        azcliversion: latest
        inlineScript: |
          az webapp deployment slot swap \
            --name ${{ env.AZURE_WEBAPP_NAME }} \
            --resource-group ${{ secrets.AZURE_RESOURCE_GROUP }} \
            --slot green \
            --target-slot production
```

---

## 📋 **Додаткові GitHub Secrets**

### **Базові secrets:**
```
AZURE_WEBAPP_PUBLISH_PROFILE      # Publish profile з Azure
SECRET_KEY                        # Django secret key
AZURE_CREDENTIALS                 # Service Principal JSON
```

### **Додаткові secrets для повної функціональності:**
```
DATABASE_URL                      # PostgreSQL connection string
AZURE_RESOURCE_GROUP             # Назва resource group
AZURE_CONTAINER_REGISTRY         # ACR login server
REGISTRY_USERNAME                # ACR username
REGISTRY_PASSWORD                # ACR password
SLACK_WEBHOOK_URL               # Для notifications
ARM_CLIENT_ID                   # Terraform Service Principal
ARM_CLIENT_SECRET               # Terraform Service Principal secret
ARM_SUBSCRIPTION_ID             # Azure subscription
ARM_TENANT_ID                   # Azure tenant
```

---

## 🎯 **Environment Protection Rules**

### **Налаштування в GitHub:**
1. **Repository → Settings → Environments**
2. **Створити environments:** `staging`, `production`
3. **Додати protection rules:**
   - **Required reviewers** для production
   - **Wait timer** перед deployment
   - **Deployment branches** тільки main/develop

---

## 📊 **Моніторинг та Notifications**

### **Slack Integration:**
```yaml
- name: 📧 Slack Notification
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    channel: '#deployments'
    text: |
      🚀 Django Portfolio Deploy: ${{ job.status }}
      📱 App: https://${{ env.AZURE_WEBAPP_NAME }}.azurewebsites.net
      👤 By: ${{ github.actor }}
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

### **Microsoft Teams Integration:**
```yaml
- name: 📧 Teams Notification
  uses: aliencube/microsoft-teams-actions@v0.8.0
  with:
    webhook_uri: ${{ secrets.MS_TEAMS_WEBHOOK_URI }}
    title: Django Portfolio Deployment
    summary: Deployment ${{ job.status }}
    text: App deployed to https://${{ env.AZURE_WEBAPP_NAME }}.azurewebsites.net
```

---

## 🛠️ **Troubleshooting Commands**

### **Debug GitHub Actions:**
```yaml
- name: 🐛 Debug Environment
  run: |
    echo "Python version: $(python --version)"
    echo "Pip version: $(pip --version)"
    echo "Current directory: $(pwd)"
    echo "Files in directory:"
    ls -la
    echo "Environment variables:"
    env | grep -E "(DJANGO|SECRET|DATABASE)" || true
```

### **Azure CLI Debugging:**
```yaml
- name: 🔍 Azure Debug Info
  uses: azure/CLI@v1
  with:
    inlineScript: |
      az webapp show --name ${{ env.AZURE_WEBAPP_NAME }} \
        --resource-group ${{ secrets.AZURE_RESOURCE_GROUP }} \
        --query "{name:name,state:state,defaultHostName:defaultHostName}"
```

---

## ✅ **Checklist для успішного deployment**

### **Перед налаштуванням:**
- [ ] Azure App Service створено
- [ ] Всі GitHub Secrets налаштовані
- [ ] Django проект готовий для production
- [ ] requirements.txt містить всі залежності
- [ ] settings.py має production конфігурацію

### **Після налаштування:**
- [ ] Workflow файл створено в `.github/workflows/`
- [ ] Push в main branch trigger deployment
- [ ] Health checks проходять успішно
- [ ] Моніторинг налаштовано
- [ ] Rollback стратегія готова

**Результат: Повністю автоматизований CI/CD pipeline для Django в Azure! 🚀**


--------------------------------------------------------------------------------------------------------------------------

Створю детальний гайд по налаштуванню GitHub Secrets для Azure deployment:## 🎯 **Кроки для налаштування GitHub Secrets**

### **📋 Швидкий план дій:**

## **1. 🔑 SECRET_KEY (Найпростіший)**
```bash
# Згенерувати Django secret key
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"

# Результат:
django-insecure-a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6
```

## **2. 🌐 AZURE_WEBAPP_PUBLISH_PROFILE**
```bash
# 1. Створити App Service (якщо немає)
az webapp create --resource-group myRG --plan myPlan --name myapp --runtime "PYTHON|3.11"

# 2. Отримати publish profile
az webapp deployment list-publishing-profiles \
    --name myapp \
    --resource-group myRG \
    --xml
```

## **3. 🏢 AZURE_CREDENTIALS (Service Principal)**
```bash
# Створити Service Principal одною командою
az ad sp create-for-rbac \
    --name "github-actions-sp" \
    --role "Contributor" \
    --scopes "/subscriptions/$(az account show --query id -o tsv)" \
    --json-auth
```

---

## **🛠️ Додавання в GitHub:**

### **Крок 1:** GitHub → Repository → **Settings**
### **Крок 2:** **Secrets and variables** → **Actions**  
### **Крок 3:** **New repository secret**

**Додати по черзі:**
1. `SECRET_KEY` = django-secret...
2. `AZURE_WEBAPP_PUBLISH_PROFILE` = весь XML
3. `AZURE_CREDENTIALS` = JSON з Service Principal

---

## **✅ Швидка перевірка:**

```yaml
# Створити .github/workflows/test.yml
name: Test Secrets
on: workflow_dispatch
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - run: echo "Secrets configured ✅"
      env:
        SECRET_KEY: ${{ secrets.SECRET_KEY }}
        AZURE_CREDS: ${{ secrets.AZURE_CREDENTIALS }}
```

**Запустити workflow вручну для перевірки!**

---

## **🚨 Критичні моменти:**

1. **Service Principal** - обов'язково JSON формат
2. **Publish Profile** - весь XML файл цілком
3. **Secret Key** - мінімум 50 символів
4. **Ніколи не commitити** secrets в код!

**Після налаштування всіх трьох secrets, GitHub Actions зможе автоматично деплоїти ваш Django додаток в Azure! 🚀**

---------------------------------------------------------------------------------------------------------------------------------------------



# 🔐 GitHub Secrets Configuration для Azure Deployment

## 📋 Огляд

Детальна інструкція по налаштуванню трьох критично важливих secrets в GitHub для автоматичного deployment Django додатку в Azure.

---

## 🚀 **AZURE_WEBAPP_PUBLISH_PROFILE**

### **Крок 1: Створити Azure Web App**
```bash
# Через Azure CLI
az webapp create \
    --resource-group your-resource-group \
    --plan your-app-service-plan \
    --name your-webapp-name \
    --runtime "PYTHON|3.11"
```

### **Крок 2: Отримати Publish Profile через Azure Portal**

#### **Метод 1: Azure Portal (Графічний інтерфейс)**
1. **Відкрити Azure Portal:** https://portal.azure.com
2. **Знайти ваш App Service:**
   - Перейти в **Resource Groups** → ваша група → App Service
3. **Завантажити publish profile:**
   - Натиснути **"Get publish profile"** у верхньому меню
   - Файл `.PublishSettings` завантажиться автоматично

#### **Метод 2: Azure CLI (Командний рядок)**
```bash
# Отримати publish profile
az webapp deployment list-publishing-profiles \
    --name your-webapp-name \
    --resource-group your-resource-group \
    --xml > publish-profile.xml

# Вміст файлу буде схожий на:
cat publish-profile.xml
```

### **Крок 3: Скопіювати вміст файлу**
```xml
<!-- Приклад publish profile -->
<publishData>
  <publishProfile 
    profileName="your-webapp-name - Web Deploy" 
    publishMethod="MSDeploy" 
    publishUrl="your-webapp-name.scm.azurewebsites.net:443" 
    msdeploysite="your-webapp-name" 
    userName="$your-webapp-name" 
    userPWD="very-long-password-here" 
    destinationAppUrl="https://your-webapp-name.azurewebsites.net" 
    SQLServerDBConnectionString="" 
    mySQLDBConnectionString="" 
    hostingProviderForumLink="" 
    controlPanelLink="http://windows.azure.com" 
    webSystem="WebSites">
    <databases />
  </publishProfile>
</publishData>
```

---

## 🔑 **SECRET_KEY**

### **Крок 1: Генерація Django Secret Key**

#### **Метод 1: Python скрипт**
```python
# generate_secret_key.py
from django.core.management.utils import get_random_secret_key

secret_key = get_random_secret_key()
print(f"Generated SECRET_KEY: {secret_key}")
```

```bash
# Виконати скрипт
python generate_secret_key.py
```

#### **Метод 2: Django команда**
```bash
# В Django проекті
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

#### **Метод 3: Онлайн генератор**
```python
# Альтернативний метод
import secrets
import string

def generate_secret_key(length=50):
    alphabet = string.ascii_letters + string.digits + '!@#$%^&*(-_=+)'
    return ''.join(secrets.choice(alphabet) for i in range(length))

print(generate_secret_key())
```

### **Приклад згенерованого ключа:**
```
django-insecure-abc123def456ghi789jkl012mno345pqr678stu901vwx234yz5
```

---

## 🏢 **AZURE_CREDENTIALS (Service Principal)**

### **Крок 1: Створити Service Principal**

#### **Через Azure CLI:**
```bash
# 1. Логін до Azure
az login

# 2. Отримати Subscription ID
az account show --query id --output tsv

# 3. Створити Service Principal
az ad sp create-for-rbac \
    --name "terraform-sp-portfolio" \
    --role "Contributor" \
    --scopes "/subscriptions/YOUR_SUBSCRIPTION_ID" \
    --json-auth

# 4. Результат буде схожий на:
{
  "clientId": "12345678-1234-1234-1234-123456789012",
  "clientSecret": "very-secret-password-here",
  "subscriptionId": "87654321-4321-4321-4321-210987654321",
  "tenantId": "11111111-1111-1111-1111-111111111111",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

### **Крок 2: Альтернативний формат для Terraform**
```bash
# Для специфічного використання з Terraform
az ad sp create-for-rbac \
    --name "terraform-sp-portfolio" \
    --role "Contributor" \
    --scopes "/subscriptions/YOUR_SUBSCRIPTION_ID"

# Результат:
{
  "appId": "12345678-1234-1234-1234-123456789012",
  "displayName": "terraform-sp-portfolio",
  "password": "very-secret-password-here",
  "tenant": "11111111-1111-1111-1111-111111111111"
}
```

### **Крок 3: Перетворити в правильний формат**
```json
{
  "clientId": "12345678-1234-1234-1234-123456789012",
  "clientSecret": "very-secret-password-here",
  "subscriptionId": "87654321-4321-4321-4321-210987654321",
  "tenantId": "11111111-1111-1111-1111-111111111111"
}
```

---

## 🛠️ **Додавання Secrets в GitHub**

### **Крок 1: Перейти в GitHub Repository**
1. Відкрити ваш репозиторій на GitHub
2. Перейти в **Settings** (вкладка вгорі)
3. В лівому меню обрати **Secrets and variables** → **Actions**

### **Крок 2: Додати кожен secret**

#### **AZURE_WEBAPP_PUBLISH_PROFILE:**
```
Name: AZURE_WEBAPP_PUBLISH_PROFILE
Value: [Вставити весь XML з publish profile файлу]
```

#### **SECRET_KEY:**
```
Name: SECRET_KEY
Value: django-insecure-abc123def456ghi789jkl012mno345pqr678stu901vwx234yz5
```

#### **AZURE_CREDENTIALS:**
```
Name: AZURE_CREDENTIALS
Value: {
  "clientId": "12345678-1234-1234-1234-123456789012",
  "clientSecret": "very-secret-password-here",
  "subscriptionId": "87654321-4321-4321-4321-210987654321",
  "tenantId": "11111111-1111-1111-1111-111111111111"
}
```

---

## 🔧 **Додаткові Secrets (Опціонально)**

### **Для повної функціональності також додайте:**

#### **DATABASE_PASSWORD:**
```bash
# Генерація безпечного паролю для PostgreSQL
openssl rand -base64 32
```

#### **AZURE_STORAGE_ACCOUNT_KEY:**
```bash
# Отримати з Azure CLI
az storage account keys list \
    --resource-group your-resource-group \
    --account-name your-storage-account \
    --query '[0].value' --output tsv
```

#### **APPLICATIONINSIGHTS_CONNECTION_STRING:**
```bash
# Отримати Connection String для Application Insights
az monitor app-insights component show \
    --app your-app-insights-name \
    --resource-group your-resource-group \
    --query 'connectionString' --output tsv
```

---

## ✅ **Верифікація налаштувань**

### **Крок 1: Перевірити secrets в GitHub**
1. Перейти в **Settings** → **Secrets and variables** → **Actions**
2. Переконатися, що всі secrets присутні:
   - ✅ AZURE_WEBAPP_PUBLISH_PROFILE
   - ✅ SECRET_KEY  
   - ✅ AZURE_CREDENTIALS

### **Крок 2: Тестовий GitHub Actions workflow**
```yaml
# .github/workflows/test-secrets.yml
name: Test Secrets

on:
  workflow_dispatch:  # Manual trigger

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - name: Test Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Test Django Secret
      run: |
        echo "SECRET_KEY length: ${#SECRET_KEY}"
      env:
        SECRET_KEY: ${{ secrets.SECRET_KEY }}
    
    - name: Test Publish Profile
      run: |
        echo "Publish profile configured: ✅"
      env:
        PUBLISH_PROFILE: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
```

---

## 🚨 **Безпека та Best Practices**

### **🔒 Безпека:**
1. **Ніколи не commitте secrets** в код
2. **Регулярно оновлюйте** Service Principal паролі
3. **Використовуйте мінімальні дозволи** для Service Principal
4. **Ротуйте secrets** кожні 6 місяців

### **📋 Best Practices:**
1. **Використовуйте окремі Service Principals** для різних середовищ
2. **Додайте expiration date** для Service Principal
3. **Моніторьте використання** secrets через Azure logs
4. **Документуйте всі secrets** та їх призначення

### **🛡️ Додаткові permissions для Service Principal:**
```bash
# Додати specific roles якщо потрібно
az role assignment create \
    --assignee YOUR_SERVICE_PRINCIPAL_ID \
    --role "Storage Blob Data Contributor" \
    --scope "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/YOUR_RESOURCE_GROUP"
```

---

## 🔧 **Troubleshooting**

### **Поширені помилки:**

#### **1. "Invalid publish profile"**
**Рішення:** Переконайтеся що скопіювали весь XML файл включно з `<publishData>` тегами

#### **2. "Authentication failed" для AZURE_CREDENTIALS**
**Рішення:** Перевірте формат JSON та переконайтеся що Service Principal має права

#### **3. "SECRET_KEY too short"**
**Рішення:** Django secret key має бути мінімум 50 символів

### **Перевірка Service Principal:**
```bash
# Тест логіну з Service Principal
az login --service-principal \
    --username YOUR_CLIENT_ID \
    --password YOUR_CLIENT_SECRET \
    --tenant YOUR_TENANT_ID
```

---

## 📋 **Чеклист готовності**

- [ ] **AZURE_WEBAPP_PUBLISH_PROFILE** додано та містить весь XML
- [ ] **SECRET_KEY** згенеровано та додано (50+ символів)  
- [ ] **AZURE_CREDENTIALS** створено Service Principal та додано JSON
- [ ] **Тестовий workflow** пройшов успішно
- [ ] **Service Principal** має необхідні права
- [ ] **Secrets** не присутні в коді репозиторію

**Після налаштування всіх secrets, ваш GitHub Actions workflow зможе автоматично деплоїти Django додаток в Azure! 🚀**
