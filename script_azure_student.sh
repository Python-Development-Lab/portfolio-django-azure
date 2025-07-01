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
