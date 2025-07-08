#!/bin/bash
# БЮДЖЕТНИЙ STARTUP СКРИПТ

echo "Starting Django application in BUDGET mode..."

# Швидке збирання статичних файлів
python manage.py collectstatic --noinput --clear

# Запуск міграцій
python manage.py migrate --noinput

# Бюджетний запуск з мінімальними ресурсами
exec gunicorn --bind=0.0.0.0:8000 --timeout 300 --workers 1 --max-requests 1000 --max-requests-jitter 100 config.wsgi:application
