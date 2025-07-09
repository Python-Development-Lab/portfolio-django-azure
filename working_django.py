import os
import django
from django.conf import settings
from django.http import HttpResponse
from django.urls import path
from django.core.wsgi import get_wsgi_application

settings.configure(
    DEBUG=False,
    SECRET_KEY='azure-hardcoded-key-12345',
    ALLOWED_HOSTS=['django-app-budget-1751947063.azurewebsites.net', '*.azurewebsites.net', '*'],
    ROOT_URLCONF=__name__,
    INSTALLED_APPS=[],
    MIDDLEWARE=[],
)

def home(request):
    return HttpResponse(f"""
    <html>
    <head>
        <title>Django на Azure - Працює!</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }}
            .container {{ background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
            h1 {{ color: #28a745; text-align: center; }}
            .status {{ background: #d4edda; padding: 15px; border-radius: 5px; border-left: 4px solid #28a745; }}
            .info {{ background: #f8f9fa; padding: 15px; margin: 15px 0; border-radius: 5px; }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🎉 Django успішно працює на Azure!</h1>
            
            <div class="status">
                <h3>✅ Статус розгортання: УСПІШНО</h3>
                <p>Ваша Azure інфраструктура готова до роботи!</p>
            </div>
            
            <div class="info">
                <h3>📋 Технічна інформація:</h3>
                <ul>
                    <li><strong>Python версія:</strong> {os.sys.version.split()[0]}</li>
                    <li><strong>Django версія:</strong> {django.get_version()}</li>
                    <li><strong>Хост:</strong> {request.get_host()}</li>
                    <li><strong>Метод запиту:</strong> {request.method}</li>
                    <li><strong>Поточна директорія:</strong> {os.getcwd()}</li>
                </ul>
            </div>
            
            <div class="info">
                <h3>🔧 Azure компоненти:</h3>
                <ul>
                    <li>✅ App Service Plan: F1 (Free)</li>
                    <li>✅ Web App: django-app-budget-1751947063</li>
                    <li>✅ PostgreSQL: django-app-budget-db-1751947063</li>
                    <li>✅ Storage Account: djapp1947063</li>
                    <li>✅ Key Vault: djapp-kv-47063</li>
                </ul>
            </div>
            
            <div class="status">
                <h3>🚀 Наступні кроки:</h3>
                <ol>
                    <li>Додати ваш portfolio проект</li>
                    <li>Налаштувати статичні файли</li>
                    <li>Підключити PostgreSQL базу даних</li>
                    <li>Додати custom domain (опціонально)</li>
                </ol>
            </div>
        </div>
    </body>
    </html>
    """)

urlpatterns = [path('', home)]
application = get_wsgi_application()
