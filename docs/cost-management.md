

## 💰 Оцінка вартості розгортання Azure інфраструктури

Розглянемо вартість для конфігурації із скрипту:

### 📊 **Поточна конфігурація:**
- **App Service SKU**: B1
- **Database SKU**: Standard_D2ds_v4  
- **Storage**: Standard_LRS
- **Location**: West Europe

---

## 🏷️ **Детальний розрахунок (на місяць):**

### 🚀 **Azure App Service B1**
- **Вартість**: $13.14/місяць
- **Ресурси**: 1 vCore, 1.75 GB RAM, 10 GB storage
- **Особливості**: Always On, Custom domains, SSL certificates

### 🗄️ **PostgreSQL Flexible Server (Standard_D2ds_v4)**
- **Вартість**: $87.60/місяць (West Europe)
- **Ресурси**: 2 vCore, 8 GB RAM
- **Storage**: 32 GB SSD (включено)
- **Backup**: 7 днів безкоштовно

### 💾 **Storage Account (Standard_LRS)**
- **Вартість**: $2-5/місяць
- **Hot tier**: $0.0184/GB
- **Операції**: $0.0004 за 10K операцій
- **Bandwidth**: $0.087/GB (outbound)

### 🔐 **Azure Key Vault**
- **Вартість**: $0.50-1/місяць
- **Операції**: 10,000 безкоштовно
- **Секрети**: Необмежено в Standard

### 📊 **Application Insights**
- **Вартість**: Безкоштовно до 5GB/місяць
- **Після лімітів**: $2.30/GB

---

## 🎯 **ЗАГАЛЬНА ВАРТІСТЬ: ~$103-108/місяць**

---

## 🔧 **Варіанти оптимізації вартості:**

### 💡 **Бюджетна версія (~$20-25/місяць):**
```bash
APP_SERVICE_SKU="F1"              # Безкоштовно (з обмеженнями)
DB_SKU="Standard_B1ms"            # $12-15/місяць (1 vCore, 2GB RAM)
```

### 📈 **Staging версія (~$45-55/місяць):**
```bash
APP_SERVICE_SKU="B1"              # $13/місяць
DB_SKU="Standard_B2s"             # $25-30/місяць (2 vCore, 4GB RAM)
```

### 🚀 **High-Performance Production (~$250-280/місяць):**
```bash
APP_SERVICE_SKU="P1V3"            # $80/місяць
DB_SKU="Standard_D4ds_v4"         # $170-190/місяць (4 vCore, 16GB RAM)
```

---

## 💸 **Способи зменшення витрат:**

### 🎟️ **1. Reserved Instances (до 72% економії)**
- 1-річний план: 38% знижка
- 3-річний план: 72% знижка
- Застосовується до PostgreSQL

### 🧪 **2. Dev/Test тарифи (до 55% економії)**
- Доступно з Visual Studio підписками
- Знижки на App Service та інші сервіси

### ⏰ **3. Автоматичне масштабування**
```bash
# Scale down у нічний час (22:00-06:00)
Економія: ~30% на App Service
```

### 📦 **4. Оптимізація Storage**
```bash
# Cool tier для рідко використовуваних файлів
Економія: ~50% на storage costs
```

---

## 📊 **Порівняння з конкурентами:**

| Провайдер | Аналогічна конфігурація | Вартість/місяць |
|-----------|------------------------|-----------------|
| **Azure** | B1 + Standard_D2ds_v4 | **$103-108** |
| AWS | t3.small + db.t3.small | $95-110 |
| Google Cloud | e2-small + db-n1-standard-1 | $90-105 |
| DigitalOcean | $12 droplet + $15 DB | $35-45 |

---

## ⚠️ **Додаткові витрати:**

### 🌐 **Bandwidth (outbound traffic)**
- **Перші 100 GB**: Безкоштовно щомісяця
- **Після 100 GB**: $0.087/GB
- **Орієнтовно**: $5-15/місяць для середнього трафіку

### 🔄 **Backup та Disaster Recovery**
- **PITR (Point-in-time recovery)**: Включено в DB
- **Geo-redundant backup**: +$3-5/місяць
- **Cross-region replication**: +$20-40/місяць

### 📈 **Monitoring та Alerts**
- **Application Insights**: Безкоштовно до 5GB
- **Log Analytics**: $2.30/GB після лімітів
- **Custom metrics**: $0.10 за метрику

---

## 💡 **Рекомендації по етапах:**

### 🔬 **Development (перші 2-3 місяці)**
```bash
Конфігурація: F1 + B1ms
Вартість: $15-20/місяць
Мета: Тестування та розробка
```

### 🎭 **Staging (наступні 2-3 місяці)**
```bash
Конфігурація: B1 + B2s  
Вартість: $45-55/місяць
Мета: UAT та навантажувальне тестування
```

### 🚀 **Production (стабільна робота)**
```bash
Конфігурація: B1 + D2ds_v4 (поточна)
Вартість: $103-108/місяць
Мета: Стабільна робота з можливістю масштабування
```

### 🏆 **High-Performance (при зростанні)**
```bash
Конфігурація: P1V3 + D4ds_v4
Вартість: $250-280/місяць
Мета: Високе навантаження та performance
```

---

## 🎯 **Висновок:**

**Поточна конфігурація ($103-108/місяць)** оптимальна для:
- ✅ Малий-середній production Django додаток
- ✅ 1000-5000 активних користувачів
- ✅ Стандартне навантаження на БД
- ✅ Можливість горизонтального масштабування

**Економія можлива через:**
- 🎟️ Reserved Instances (-38% до -72%)
- 🧪 Dev/Test підписки (-55%)
- ⏰ Scheduled scaling (-20-30%)
- 📦 Storage optimization (-50% на storage)

**Реальна вартість з оптимізацією: $60-80/місяць**




# 07.07.2025 - Оцінка GitHub Billing Dashboard 💰





# 02.07.2025 - Оцінка GitHub Billing Dashboard 💰

![](https://github.com/Python-Development-Lab/portfolio-django-azure/blob/main/images/github-issue.png)

## 📊 **Загальний фінансовий огляд**

### Поточні витрати:
- **Current metered usage**: $10.84
- **Current included usage**: $10.84  
- **Next payment due**: Не вказано

## 📈 **Аналіз підписок**

### Активні підписки:
- **GitHub Free**: $0.00/месяц ✅
- **Copilot Free**: $0.00/месяц ✅

**Статус**: Використовуються **безкоштовні** плани

## 📋 **Metered Usage аналіз (Jul 1 - Jul 31, 2025)**

### Usage by Repository (Топ репозиторії):
1. **portfolio-django-azure**: $10.81 💰
2. **secureweb-capstone**: $0.01
3. **msdocs-django-postgresql-sample-app**: $0.01  
4. **codespaces-django**: <$0.01

## 🎯 **Ключові висновки**

### ✅ **Позитивні аспекти:**
- **Безкоштовні підписки** - основні сервіси GitHub та Copilot
- **Контрольовані витрати** - $10.84 загальна сума
- **Прозорий billing** - детальна розбивка по репозиторіях

### ⚠️ **Області уваги:**
- **Один репозиторій споживає 99%** витрат (`portfolio-django-azure`)
- **Metered usage** $10.84 - може зростати при активному використанні

## 🔍 **Детальний аналіз витрат**

### Розподіл по сервісах:
- **Actions usage**: <$0.01
- **Actions and Actions Runners**: 2,000 included minutes
- **Git LFS**: Базове використання
- **Codespaces**: Мінімальне використання
- **Packages**: Стандартне використання

## 📊 **Загальна оцінка: 8/10**

### Розподіл балів:
- **Cost Control**: 9/10 ✅ (низькі витрати)
- **Plan Optimization**: 8/10 ✅ (використання Free plans)
- **Usage Distribution**: 6/10 ⚠️ (один репозиторій домінує)
- **Transparency**: 10/10 ✅ (чіткий billing)

## 💡 **Рекомендації**

### 🔴 **Immediate Actions:**
1. **Аналіз `portfolio-django-azure`**:
   - Перевірити, які Actions споживають ресурси
   - Оптимізувати CI/CD pipeline
   - Розглянути обмеження на частоту запусків

### 🟡 **Short-term (1-2 тижні):**
1. **Моніторинг витрат**:
   - Налаштувати spending limits
   - Створити alerts на $15-20/місяць
   - Регулярний огляд usage

2. **Оптимізація workflow**:
   ```yaml
   # Приклад оптимізації GitHub Actions
   name: Optimized CI
   on:
     push:
       branches: [ main ]
     pull_request:
       branches: [ main ]
   
   jobs:
     build:
       runs-on: ubuntu-latest
       if: github.event_name == 'push' || github.event.pull_request.draft == false
   ```

### 🟢 **Long-term (1 місяць):**
1. **Workflow optimization**:
   - Кешування dependencies
   - Паралельне виконання jobs
   - Використання matrix builds розумно

2. **Repository management**:
   - Архівування старих workflows
   - Cleanup unused Actions

## 📈 **Usage Patterns**

### Тренд (Jul 1-31):
- **Стабільне використання** ~$10 рівень
- **Основний споживач**: portfolio-django-azure проект
- **Мінімальне використання** інших репозиторіїв

## 🎯 **Action Items**

### Негайно:
- [ ] Перевірити Actions history для `portfolio-django-azure`
- [ ] Ідентифікувати найдорожчі workflow runs
- [ ] Налаштувати spending alerts

### Цього тижня:
- [ ] Оптимізувати CI/CD pipeline
- [ ] Додати кешування для dependencies  
- [ ] Розглянути використання self-hosted runners (якщо доцільно)

### Цього місяця:
- [ ] Regular usage review
- [ ] Cleanup unused workflows
- [ ] Plan scalability strategy

## 💰 **Budget Forecast**

**Поточний тренд**: ~$10-11/місяць  
**Прогноз**: Стабільні витрати при поточному використанні  
**Рекомендований budget alert**: $15/місяць

## 🚀 **Підсумок**

**Загальний стан**: 🟢 **ЗДОРОВИЙ**

- Низькі та контрольовані витрати
- Ефективне використання безкоштовних планів
- Чітка видимість витрат
- Потребує мінорної оптимізації основного проекту

**Next Review**: Через 2 тижні для перевірки ефекту оптимізацій


-------------------------------------------


![](https://github.com/Python-Development-Lab/portfolio-django-azure/blob/main/images/github-issue-1.png)


Бачу, що у вас є GitHub Pro або GitHub Team план зі значними безкоштовними лімітами. Ваш поточний рахунок складає $10.84, але це після застосування знижок.

## Аналіз вашого використання:

**Codespaces:**
- 15 GB сховища: $0.04 (використано мінімум)
- 120 годин core часу: $10.80 (це основна частина рахунку)

**Інші сервіси:** всі в межах безкоштовних лімітів

## Щоб відновити Codespaces:

1. **Перевірте ліміт витрат:**
   - Settings → Billing and plans → Spending limits
   - Переконайтеся, що для Codespaces встановлено ліміт більше $10.84

2. **Якщо ліміт встановлено на $0:**
   - Збільште його до $15-20 або встановіть "No limit"
   - Це дозволить використовувати понад безкоштовні години

3. **Додайте спосіб оплати** (якщо ще не додано):
   - Payment information → Add payment method

## Чому Codespace відключено:

Ймовірно, ви вичерпали 120 безкоштовних core-годин на місяць, і система заблокувала подальше використання через ліміт витрат.

Після встановлення відповідного ліміту витрат Codespaces відновиться автоматично.




Ось розрахунок вартості для вашої Azure конфігурації Django додатку:

## 💰 Орієнтовна вартість (за місяць)

### 🚀 **App Service B1**
- **Вартість**: ~$13.14/місяць
- **Ресурси**: 1 vCore, 1.75 GB RAM, 10 GB storage
- **Особливості**: Always On підтримується, custom domains

### 🗄️ **PostgreSQL Flexible Server (Standard_D2ds_v4)**
- **Вартість**: ~$85-95/місяць (залежно від регіону)
- **Ресурси**: 2 vCore, 8 GB RAM
- **Storage**: 32 GB (включено в базову ціну)
- **Backup**: 7 днів (безкоштовно)

### 💾 **Storage Account (LRS)**
- **Вартість**: ~$2-5/місяць
- **Hot tier**: для статичних файлів та медіа
- **Операції**: GET/PUT requests

### 🔐 **Key Vault**
- **Вартість**: ~$0.50-1/місяць
- **Операції**: 10,000 операцій безкоштовно
- **Секрети**: необмежено в Standard tier

### 📊 **Application Insights**
- **Вартість**: Безкоштовно до 5 GB/місяць
- **Після лімітів**: ~$2.30/GB

---

## 🏷️ **ЗАГАЛЬНА ВАРТІСТЬ**

### **Production конфігурація**: ~$100-115/місяць

## 💡 **Оптимізація для різних середовищ**

### 🔧 **Development/Testing (економ версія)**
```bash
APP_SERVICE_SKU="F1"              # Безкоштовно (з обмеженнями)
DB_SKU="Standard_B1ms"            # ~$12-15/місяць
```
**Загальна вартість**: ~$15-20/місяць

### 🔄 **Staging (середня версія)**
```bash
APP_SERVICE_SKU="B1"              # ~$13/місяць
DB_SKU="Standard_B2s"             # ~$25-30/місяць
```
**Загальна вартість**: ~$40-50/місяць

### 🚀 **High-Performance Production**
```bash
APP_SERVICE_SKU="P1V3"            # ~$80/місяць
DB_SKU="Standard_D4ds_v4"         # ~$170-190/місяць
```
**Загальна вартість**: ~$255-280/місяць

## 📈 **Способи зменшення вартості**

### 1. **Reserved Instances** (до 72% економії)
```bash
# 1-річний план для DB
az postgres flexible-server update --reservation-id RESERVATION_ID
```

### 2. **Dev/Test тарифи** (до 55% економії)
- Доступно для розробників з Visual Studio підписками

### 3. **Автоматичне масштабування**
```bash
# Scale down у нічний час
az webapp config appsettings set --settings "WEBSITE_TIME_ZONE=UTC"
```

### 4. **Оптимізація Storage**
```bash
# Cool tier для рідко використовуваних файлів
az storage account update --access-tier Cool
```

## ⚠️ **Додаткові витрати, які варто врахувати**

- **Bandwidth**: ~$0.087/GB (вихідний трафік)
- **Backup Storage**: якщо більше 7 днів для DB
- **Monitoring**: розширені metrics Application Insights
- **SSL Certificates**: безкоштовно для *.azurewebsites.net

## 🎯 **Рекомендації**

1. **Початок**: Використовуйте B1 + B1ms (~$30/місяць)
2. **Моніторинг**: Налаштуйте billing alerts
3. **Тестування**: Використовуйте cleanup скрипт після тестів
4. **Production**: Плануйте Reserved Instances після стабілізації навантаження

Ваша поточна конфігурація оптимальна для малого-середнього production додатку з можливістю горизонтального масштабування.
