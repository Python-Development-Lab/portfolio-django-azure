#!/bin/bash
# =============================================================================
# ВИПРАВЛЕНИЙ скрипт видалення бюджетної інфраструктури Azure Django додатку
# =============================================================================

# Кольори для виводу
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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
# ВИПРАВЛЕНА КОНФІГУРАЦІЯ - ПРАВИЛЬНІ ІМЕНА РЕСУРСІВ
# =============================================================================

# ✅ ВИПРАВЛЕНО: Явно встановити імена ресурсів
PROJECT_NAME="django-app"
ENVIRONMENT="budget"
LOCATION="West Europe"

# ✅ Генерувати імена ресурсів так само як в основному скрипті
RESOURCE_GROUP_NAME="${PROJECT_NAME}-${ENVIRONMENT}-rg"
WEB_APP_NAME_PATTERN="${PROJECT_NAME}-${ENVIRONMENT}-*"
APP_SERVICE_PLAN_NAME="${PROJECT_NAME}-${ENVIRONMENT}-plan"
DATABASE_SERVER_NAME_PATTERN="${PROJECT_NAME}-${ENVIRONMENT}-db-*"
STORAGE_ACCOUNT_NAME_PATTERN="djapp*"
KEY_VAULT_NAME_PATTERN="djapp-kv-*"
APP_INSIGHTS_NAME="${PROJECT_NAME}-${ENVIRONMENT}-insights"

# Функція для знаходження точних імен ресурсів
discover_resource_names() {
    log "🔍 Пошук ресурсів у групі: $RESOURCE_GROUP_NAME"
    
    if ! az group exists --name "$RESOURCE_GROUP_NAME" 2>/dev/null; then
        warning "Resource Group '$RESOURCE_GROUP_NAME' не існує або вже видалена"
        return 1
    fi
    
    # Знайти реальні імена ресурсів
    WEB_APP_NAME=$(az webapp list --resource-group "$RESOURCE_GROUP_NAME" --query "[0].name" -o tsv 2>/dev/null)
    DATABASE_SERVER_NAME=$(az postgres flexible-server list --resource-group "$RESOURCE_GROUP_NAME" --query "[0].name" -o tsv 2>/dev/null)
    STORAGE_ACCOUNT_NAME=$(az storage account list --resource-group "$RESOURCE_GROUP_NAME" --query "[0].name" -o tsv 2>/dev/null)
    KEY_VAULT_NAME=$(az keyvault list --resource-group "$RESOURCE_GROUP_NAME" --query "[0].name" -o tsv 2>/dev/null)
    
    log "✅ Знайдені ресурси:"
    [ -n "$WEB_APP_NAME" ] && log "  🚀 Web App: $WEB_APP_NAME"
    [ -n "$DATABASE_SERVER_NAME" ] && log "  🗄️  Database: $DATABASE_SERVER_NAME"
    [ -n "$STORAGE_ACCOUNT_NAME" ] && log "  💾 Storage: $STORAGE_ACCOUNT_NAME"
    [ -n "$KEY_VAULT_NAME" ] && log "  🔐 Key Vault: $KEY_VAULT_NAME"
    [ -n "$APP_INSIGHTS_NAME" ] && log "  📈 App Insights: $APP_INSIGHTS_NAME"
    
    return 0
}

# Функція для показу поточних ресурсів
show_current_resources() {
    log "Перевірка поточних ресурсів..."
    
    if az group exists --name "$RESOURCE_GROUP_NAME" 2>/dev/null; then
        echo ""
        info "📊 Поточні ресурси в групі $RESOURCE_GROUP_NAME:"
        az resource list --resource-group "$RESOURCE_GROUP_NAME" --output table 2>/dev/null || echo "Не вдалося отримати список ресурсів"
        echo ""
        
        # Підрахувати орієнтовну економію
        local resource_count=$(az resource list --resource-group "$RESOURCE_GROUP_NAME" --query "length(@)" -o tsv 2>/dev/null || echo "0")
        info "💰 Знайдено $resource_count ресурсів. Орієнтовна економія після видалення: ~$10-18/місяць"
        echo ""
    else
        warning "Resource Group '$RESOURCE_GROUP_NAME' не існує або вже видалена"
        echo ""
        info "🔍 Перевірка локальних файлів..."
        check_local_files_only
        exit 0
    fi
}

# Функція для перевірки локальних файлів
check_local_files_only() {
    local files_found=false
    
    echo "📁 Локальні файли для видалення:"
    
    if [ -f "requirements.txt" ]; then
        echo "  - requirements.txt (мінімальні залежності)"
        files_found=true
    fi
    
    if [ -f ".env.budget" ]; then
        echo "  - .env.budget (бюджетна конфігурація)"
        files_found=true
    fi
    
    if [ -f "startup.sh" ]; then
        echo "  - startup.sh (startup скрипт)"
        files_found=true
    fi
    
    if [ -f "budget_settings.py" ]; then
        echo "  - budget_settings.py (Django settings)"
        files_found=true
    fi
    
    if [ -f "budget-infrastructure-summary.txt" ]; then
        echo "  - budget-infrastructure-summary.txt (звіт)"
        files_found=true
    fi
    
    if [ -f "budget-azure-deploy.sh" ]; then
        echo "  - budget-azure-deploy.sh (основний скрипт)"
        files_found=true
    fi
    
    if [ -f "cleanup_budget_infrastructure.sh" ]; then
        echo "  - cleanup_budget_infrastructure.sh (цей скрипт)"
        files_found=true
    fi
    
    if [ "$files_found" = false ]; then
        info "✅ Локальні файли не знайдені або вже видалені"
    fi
}

# Функція для підтвердження
confirm_deletion() {
    echo ""
    echo -e "${RED}⚠️  УВАГА: ВИ ЗБИРАЄТЕСЯ ВИДАЛИТИ БЮДЖЕТНУ ІНФРАСТРУКТУРУ!${NC}"
    echo "=========================================="
    echo "🌍 Resource Group: $RESOURCE_GROUP_NAME"
    echo "💰 Орієнтовна економія: ~$10-18/місяць"
    echo "=========================================="
    echo ""
    
    # Показати знайдені ресурси
    if [ -n "$WEB_APP_NAME" ] || [ -n "$DATABASE_SERVER_NAME" ] || [ -n "$STORAGE_ACCOUNT_NAME" ] || [ -n "$KEY_VAULT_NAME" ]; then
        echo "🗑️  Ресурси для видалення:"
        [ -n "$WEB_APP_NAME" ] && echo "  🚀 Web App: $WEB_APP_NAME"
        [ -n "$DATABASE_SERVER_NAME" ] && echo "  🗄️  PostgreSQL: $DATABASE_SERVER_NAME"
        [ -n "$STORAGE_ACCOUNT_NAME" ] && echo "  💾 Storage: $STORAGE_ACCOUNT_NAME"
        [ -n "$KEY_VAULT_NAME" ] && echo "  🔐 Key Vault: $KEY_VAULT_NAME"
        [ -n "$APP_INSIGHTS_NAME" ] && echo "  📈 App Insights: $APP_INSIGHTS_NAME"
        echo ""
    fi
    
    read -p "Ви впевнені, що хочете видалити ВСЮ бюджетну інфраструктуру? (yes/no): " confirmation
    
    if [[ "$confirmation" != "yes" ]]; then
        echo "❌ Операція скасована користувачем."
        exit 0
    fi
    
    echo ""
    echo -e "${YELLOW}📁 Також будуть видалені локальні файли:${NC}"
    check_local_files_only
    echo ""
    
    read -p "Підтвердіть видалення Azure ресурсів ТА локальних файлів (DELETE/no): " final_confirmation
    
    if [[ "$final_confirmation" != "DELETE" ]]; then
        echo "❌ Операція скасована. Ресурси НЕ видалені."
        exit 0
    fi
}

# Функція для видалення локальних файлів
cleanup_local_files() {
    log "🧹 Очищення локальних файлів..."
    
    # Видалення згенерованих файлів
    [ -f "requirements.txt" ] && rm -f requirements.txt && log "✅ requirements.txt видалено"
    [ -f ".env.budget" ] && rm -f .env.budget && log "✅ .env.budget видалено"
    [ -f "startup.sh" ] && rm -f startup.sh && log "✅ startup.sh видалено"
    [ -f "budget_settings.py" ] && rm -f budget_settings.py && log "✅ budget_settings.py видалено"
    [ -f "budget-infrastructure-summary.txt" ] && rm -f budget-infrastructure-summary.txt && log "✅ budget-infrastructure-summary.txt видалено"
    
    # Опціонально видалити основний deployment скрипт
    if [ -f "budget-azure-deploy.sh" ]; then
        echo ""
        read -p "Видалити також основний скрипт розгортання (budget-azure-deploy.sh)? (yes/no): " delete_main
        if [[ "$delete_main" == "yes" ]]; then
            rm -f "budget-azure-deploy.sh" && log "✅ budget-azure-deploy.sh видалено"
        else
            info "ℹ️  budget-azure-deploy.sh залишено для повторного використання"
        fi
    fi
}

# Функція для самовидалення
self_destruct() {
    echo ""
    read -p "Видалити цей cleanup скрипт після завершення? (yes/no): " delete_self
    if [[ "$delete_self" == "yes" ]]; then
        local script_name=$(basename "$0")
        log "🗑️  Видалення cleanup скрипту..."
        (sleep 2; rm -f "$script_name") &
        log "✅ $script_name буде видалено через 2 секунди"
    else
        info "ℹ️  Cleanup скрипт залишено для повторного використання"
    fi
}

# Головна функція
main_cleanup() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}🗑️  BUDGET AZURE INFRASTRUCTURE CLEANUP${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
    
    # Перевірка Azure CLI
    if ! command -v az &> /dev/null; then
        error "Azure CLI не встановлено"
    fi
    
    if ! az account show &> /dev/null; then
        error "Ви не авторизовані в Azure CLI. Виконайте 'az login'"
    fi
    
    # Знайти ресурси
    if ! discover_resource_names; then
        exit 0
    fi
    
    # Показати поточні ресурси
    show_current_resources
    
    # Підтвердження від користувача
    confirm_deletion
    
    log "🚀 Початок процесу видалення бюджетної інфраструктури..."
    
    # Видалення Resource Group
    log "Видалення Resource Group: $RESOURCE_GROUP_NAME"
    if az group delete --name "$RESOURCE_GROUP_NAME" --yes --no-wait 2>/dev/null; then
        log "✅ Resource Group помічена для видалення"
        
        # Очікування завершення (скорочено для budget версії)
        local attempts=0
        local max_attempts=10  # 5 хвилин max
        
        log "Очікування завершення видалення (максимум 5 хвилин)..."
        while az group exists --name "$RESOURCE_GROUP_NAME" 2>/dev/null && [ $attempts -lt $max_attempts ]; do
            echo -n "."
            sleep 30
            attempts=$((attempts + 1))
        done
        echo ""
        
        if az group exists --name "$RESOURCE_GROUP_NAME" 2>/dev/null; then
            warning "Resource Group все ще видаляється у фоновому режимі"
            info "Перевірте Azure Portal через 10-15 хвилин"
        else
            log "✅ Resource Group успішно видалена!"
        fi
    else
        warning "Не вдалося видалити Resource Group або вона вже не існує"
    fi
    
    # Очищення локальних файлів
    cleanup_local_files
    
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}✅ BUDGET CLEANUP ЗАВЕРШЕНО!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo "📊 Підсумок:"
    echo "- Azure ресурси видалені (або помічені для видалення)"
    echo "- Локальні файли очищені"
    echo "- Орієнтовна економія: ~$10-18/місяць"
    echo ""
    echo "💡 Рекомендації:"
    echo "- Перевірте Azure Portal через 10-15 хвилин"
    echo "- Переконайтеся, що billing припинено"
    echo "- Збережіть налаштування для майбутнього використання"
    echo ""
    
    # Опція самовидалення
    self_destruct
}

# Обробка параметрів командного рядка
case "$1" in
    --help|-h)
        echo "BUDGET Azure Infrastructure Cleanup Script"
        echo ""
        echo "Використання: $0 [опції]"
        echo ""
        echo "Опції:"
        echo "  --help, -h         Показати цю довідку"
        echo "  --dry-run          Показати що буде видалено"
        echo "  --force            Видалити без підтвердження (НЕБЕЗПЕЧНО!)"
        echo "  --files-only       Видалити тільки локальні файли"
        echo ""
        echo "Приклади:"
        echo "  $0                 # Інтерактивне видалення"
        echo "  $0 --dry-run       # Показати план"
        echo "  $0 --files-only    # Очистити тільки файли"
        exit 0
        ;;
    --dry-run)
        echo "🔍 DRY RUN MODE - показуємо що буде видалено:"
        discover_resource_names
        show_current_resources
        echo "Для фактичного видалення запустіть: $0"
        exit 0
        ;;
    --files-only)
        echo "🧹 ФАЙЛИ РЕЖИМ - видалення тільки локальних файлів:"
        check_local_files_only
        echo ""
        read -p "Видалити локальні файли? (yes/no): " confirm
        if [[ "$confirm" == "yes" ]]; then
            cleanup_local_files
            self_destruct
        fi
        exit 0
        ;;
    --force)
        warning "⚠️  FORCE MODE - видалення без підтвердження!"
        discover_resource_names
        if az group delete --name "$RESOURCE_GROUP_NAME" --yes --no-wait 2>/dev/null; then
            log "✅ Resource Group помічена для видалення (force mode)"
            cleanup_local_files
            log "✅ Force cleanup завершено"
        else
            warning "Помилка видалення в force mode"
        fi
        exit 0
        ;;
    "")
        # Звичайний режим
        main_cleanup
        ;;
    *)
        error "Невідомий параметр: $1. Використайте --help для довідки"
        ;;
esac
