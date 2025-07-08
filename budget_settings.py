"""
БЮДЖЕТНІ НАЛАШТУВАННЯ DJANGO
Оптимізовано для мінімальних витрат на Azure F1 + B1ms
"""

from decouple import config
import os

# БАЗОВІ НАЛАШТУВАННЯ
DEBUG = config('DEBUG', default=False, cast=bool)
SECRET_KEY = config('SECRET_KEY')
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='').split(',')

# БЮДЖЕТНА БАЗА ДАНИХ
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': config('DATABASE_URL'),
        'CONN_MAX_AGE': 600,  # Переіспользування з'єднань
        'OPTIONS': {
            'MAX_CONNS': 2,   # Мінімум з'єднань для B1ms
        }
    }
}

# БЮДЖЕТНІ МЕДІА ФАЙЛИ
DEFAULT_FILE_STORAGE = 'storages.backends.azure_storage.AzureStorage'
STATICFILES_STORAGE = 'django.contrib.staticfiles.storage.StaticFilesStorage'

# Azure Storage (тільки для медіа, статика через whitenoise)
AZURE_ACCOUNT_NAME = config('AZURE_STORAGE_ACCOUNT_NAME')
AZURE_ACCOUNT_KEY = config('AZURE_STORAGE_ACCOUNT_KEY')
AZURE_CONTAINER = config('AZURE_STORAGE_CONTAINER_MEDIA')

# Whitenoise для статичних файлів (економія на Storage операціях)
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',  # Бюджетна статика
    # ... інші middleware
]

STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# БЮДЖЕТНЕ КЕШУВАННЯ (без Redis - економія коштів)
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'budget-cache',
        'OPTIONS': {
            'MAX_ENTRIES': 300,  # Обмежений кеш
        }
    }
}

# МІНІМАЛЬНЕ ЛОГУВАННЯ
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'level': 'WARNING',  # Тільки попередження та помилки
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'WARNING',
    },
}

# БЮДЖЕТНІ НАЛАШТУВАННЯ ПРОДУКТИВНОСТІ
SESSION_ENGINE = 'django.contrib.sessions.backends.cached_db'
SESSION_CACHE_ALIAS = 'default'
SESSION_COOKIE_AGE = 1209600  # 2 тижні

# Вимкнення DEBUG toolbar та інших dev інструментів в budget режимі
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # Мінімальний набір для бюджетного режиму
]
