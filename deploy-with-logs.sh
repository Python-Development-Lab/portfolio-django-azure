#!/bin/bash
# =============================================================================
# Wrapper скрипт для запуску deployment з логуванням
# =============================================================================

# Кольори
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Створити папку для логів
mkdir -p logs

# Генерація назви файлу лога
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="logs/azure-deploy-${TIMESTAMP}.log"

echo -e "${BLUE}🚀 Запуск Azure Django Deployment${NC}"
echo -e "${BLUE}📝 Логи зберігаються у: ${LOG_FILE}${NC}"
echo ""

# Функція для створення header лога
create_log_header() {
    cat << EOF
================================================================================
Azure Django Infrastructure Deployment Log
================================================================================
Date: $(date)
User: $(whoami)
Working Directory: $(pwd)
Git Branch: $(git branch --show-current 2>/dev/null || echo 'N/A')
Git Commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'N/A')
Azure Account: $(az account show --query user.name -o tsv 2>/dev/null || echo 'Not logged in')
Azure Subscription: $(az account show --query name -o tsv 2>/dev/null || echo 'N/A')
Script: $1
================================================================================

EOF
}

# Функція для показу підсумку
show_summary() {
    local exit_code=$1
    local duration=$2
    
    echo ""
    echo "================================================================================"
    echo "DEPLOYMENT SUMMARY"
    echo "================================================================================"
    echo "Status: $([ $exit_code -eq 0 ] && echo "✅ SUCCESS" || echo "❌ FAILED")"
    echo "Duration: ${duration} seconds"
    echo "Log file: ${LOG_FILE}"
    echo "Exit code: ${exit_code}"
    echo "Completed: $(date)"
    echo "================================================================================"
}

# Основна функція
main() {
    local script_name="$1"
    
    # Перевірка чи існує скрипт
    if [ ! -f "$script_name" ]; then
        echo -e "${YELLOW}❌ Скрипт '$script_name' не знайдено${NC}"
        echo "Доступні скрипти:"
        ls -la *.sh 2>/dev/null || echo "Немає .sh файлів у поточній папці"
        exit 1
    fi
    
    # Перевірка прав на виконання
    if [ ! -x "$script_name" ]; then
        echo -e "${YELLOW}⚠️  Надання прав на виконання для $script_name${NC}"
        chmod +x "$script_name"
    fi
    
    # Початок таймера
    start_time=$(date +%s)
    
    # Створення header лога
    create_log_header "$script_name" > "$LOG_FILE"
    
    echo -e "${GREEN}▶️  Запуск: $script_name${NC}"
    echo ""
    
    # Запуск скрипту з логуванням
    if "./$script_name" 2>&1 | tee -a "$LOG_FILE"; then
        exit_code=0
    else
        exit_code=$?
    fi
    
    # Кінець таймера
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    # Додати підсумок у лог
    show_summary $exit_code $duration | tee -a "$LOG_FILE"
    
    # Показати корисні команди
    echo ""
    echo -e "${BLUE}📋 Корисні команди:${NC}"
    echo "Переглянути лог:     cat $LOG_FILE"
    echo "Відкрити лог:        code $LOG_FILE"
    echo "Останні помилки:     grep -i error $LOG_FILE"
    echo "Останні кроки:       grep 'КРОК' $LOG_FILE"
    echo ""
    
    exit $exit_code
}

# Перевірка аргументів
if [ $# -eq 0 ]; then
    echo "Використання: $0 <script-name>"
    echo ""
    echo "Приклади:"
    echo "  $0 budget-azure-deploy.sh"
    echo "  $0 azure-infrastructure.sh"
    echo "  $0 cleanup-infrastructure.sh"
    echo ""
    echo "Доступні скрипти:"
    ls -la *.sh 2>/dev/null | grep -v "$0" || echo "Немає .sh файлів"
    exit 1
fi

main "$1"
