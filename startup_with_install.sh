#!/bin/bash
echo "🚀 Starting Django deployment with dependency installation..."

# Встановлення залежностей
echo "📦 Installing dependencies..."
pip install --upgrade pip
pip install Django==4.2.11 gunicorn==20.1.0

# Перевірка встановлення
echo "🔍 Checking Django installation..."
python -c "import django; print(f'Django version: {django.get_version()}')"

# Запуск gunicorn
echo "🌐 Starting gunicorn server..."
gunicorn --bind=0.0.0.0:8000 --timeout 600 --workers 1 working_django:application
