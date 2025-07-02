




```bash
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $  ./cleanup_azure_infrastructure.sh --help
Використання: ./cleanup_azure_infrastructure.sh [опції]

Опції:
  --help, -h     Показати цю довідку
  --dry-run      Показати що буде видалено без фактичного видалення
  --force        Пропустити підтвердження (НЕБЕЗПЕЧНО!)

Приклади:
  ./cleanup_azure_infrastructure.sh                 # Інтерактивне видалення
  ./cleanup_azure_infrastructure.sh --dry-run       # Показати план видалення
  ./cleanup_azure_infrastructure.sh --force         # Видалити без підтвердження
```


```bash

@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ ./cleanup_azure_infrastructure.sh --dry-run
🔍 DRY RUN MODE - показуємо що буде видалено:
[2025-07-02 16:22:43] Перевірка поточних ресурсів...
true

📊 Поточні ресурси в групі django-app-production-rg:
Name                                                ResourceGroup             Location    Type                                                Status
--------------------------------------------------  ------------------------  ----------  --------------------------------------------------  --------
djapp1374072                                        django-app-production-rg  westeurope  Microsoft.Storage/storageAccounts
djapp1387336                                        django-app-production-rg  westeurope  Microsoft.Storage/storageAccounts
django-app-production-db-1751387336                 django-app-production-rg  westeurope  Microsoft.DBforPostgreSQL/flexibleServers
djapp1389430                                        django-app-production-rg  westeurope  Microsoft.Storage/storageAccounts
django-app-production-db-1751389430                 django-app-production-rg  westeurope  Microsoft.DBforPostgreSQL/flexibleServers
djapp-kv-89430                                      django-app-production-rg  westeurope  Microsoft.KeyVault/vaults
djapp1390690                                        django-app-production-rg  westeurope  Microsoft.Storage/storageAccounts
django-app-production-db-1751390690                 django-app-production-rg  westeurope  Microsoft.DBforPostgreSQL/flexibleServers
djapp-kv-90690                                      django-app-production-rg  westeurope  Microsoft.KeyVault/vaults
djapp1391690                                        django-app-production-rg  westeurope  Microsoft.Storage/storageAccounts
django-app-production-db-1751391690                 django-app-production-rg  westeurope  Microsoft.DBforPostgreSQL/flexibleServers
djapp-kv-91690                                      django-app-production-rg  westeurope  Microsoft.KeyVault/vaults
djapp1393613                                        django-app-production-rg  westeurope  Microsoft.Storage/storageAccounts
django-app-production-db-1751393613                 django-app-production-rg  westeurope  Microsoft.DBforPostgreSQL/flexibleServers
djapp-kv-93613                                      django-app-production-rg  westeurope  Microsoft.KeyVault/vaults
djapp1394601                                        django-app-production-rg  westeurope  Microsoft.Storage/storageAccounts
django-app-production-db-1751394601                 django-app-production-rg  westeurope  Microsoft.DBforPostgreSQL/flexibleServers
djapp-kv-94601                                      django-app-production-rg  westeurope  Microsoft.KeyVault/vaults
djapp1396534                                        django-app-production-rg  westeurope  Microsoft.Storage/storageAccounts
django-app-production-db-1751396534                 django-app-production-rg  westeurope  Microsoft.DBforPostgreSQL/flexibleServers
djapp-kv-96534                                      django-app-production-rg  westeurope  Microsoft.KeyVault/vaults
django-app-production-insights                      django-app-production-rg  westeurope  Microsoft.Insights/components
Application Insights Smart Detection                django-app-production-rg  global      microsoft.insights/actiongroups
Failure Anomalies - django-app-production-insights  django-app-production-rg  global      microsoft.alertsmanagement/smartDetectorAlertRules
djapp1428831                                        django-app-production-rg  westeurope  Microsoft.Storage/storageAccounts
django-app-production-db-1751428831                 django-app-production-rg  westeurope  Microsoft.DBforPostgreSQL/flexibleServers
djapp-kv-28831                                      django-app-production-rg  westeurope  Microsoft.KeyVault/vaults
django-app-production-plan                          django-app-production-rg  westeurope  Microsoft.Web/serverFarms
django-app-production-1751428831                    django-app-production-rg  westeurope  Microsoft.Web/sites
djapp1471130                                        django-app-production-rg  westeurope  Microsoft.Storage/storageAccounts
django-app-production-db-1751471130                 django-app-production-rg  westeurope  Microsoft.DBforPostgreSQL/flexibleServers
djapp-kv-71130                                      django-app-production-rg  westeurope  Microsoft.KeyVault/vaults
django-app-production-1751471130                    django-app-production-rg  westeurope  Microsoft.Web/sites


Ресурси, які будуть видалені:
- Resource Group: django-app-production-rg
- Всі ресурси всередині групи
- Локальні конфігураційні файли

Для фактичного видалення запустіть: ./cleanup_azure_infrastructure.sh
@VitaliiShevchuk2023 ➜ /workspaces/portfolio-django-azure (main) $ 
```

