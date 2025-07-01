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



