


# Огляд навчального шляху "Build community-driven software projects on GitHub"
https://learn.microsoft.com/en-us/training/paths/build-community-driven-projects-github/

## Загальна характеристика

Цей навчальний шлях від Microsoft Learn призначений для вивчення того, як GitHub дозволяє створювати спільноти, які сприяють спілкуванню та співпраці, водночас підтримуючи рекомендовані керівництва, кодекси поведінки та найкращі практики безпеки.

**Рівень складності:** Середній  
**Платформа:** GitHub  
**Формат:** Онлайн навчання з практичними завданнями

## Структура курсу

Навчальний шлях складається з **7 модулів**, кожен з яких охоплює окремий аспект створення спільнот на GitHub:

### Модуль 1: Введення в GitHub
Вивчення ключових функцій GitHub, включаючи issues, сповіщення, гілки, коміти та pull requests.

### Модуль 2: Управління InnerSource програмами
Навчання управління успішною InnerSource програмою на GitHub через ефективну видимість, керівництво та підтримку.

### Модуль 3: Створення open-source проектів
Встановлення керівництва для контрибуторів, дотримання перевірених процесів та використання стандартів спільноти. Включає створення репозиторію з повними інструкціями щодо внесків, кодексами поведінки та шаблонами.

### Модуль 4: Завантаження існуючих проектів
Навчання завантаження вашого існуючого проекту на GitHub.

### Модуль 5: Міграція з legacy систем
Переміщення існуючого проекту на GitHub із застарілої системи контролю версій.

### Модуль 6: Безпека репозиторіїв
Найкращі практики для створення, хостингу та підтримки безпечного репозиторію на GitHub.

### Модуль 7: Внесок у open-source проекти
Навчання знаходження open-source проектів і завдань для внесків, створення pull requests та ефективного спілкування з мейнтейнерами проектів.

## Що ви вивчите

По завершенню курсу ви зможете:
- Створювати залученість спільноти для власних і open-source проектів
- Визначати, чи підходить ваша ідея для open-source проекту
- Переносити існуючі проекти на GitHub
- Забезпечувати безпеку GitHub репозиторіїв
- Ефективно співпрацювати з open-source спільнотами

## Передумови

Необхідний лише обліковий запис GitHub. Попередній досвід роботи з системами контролю версій буде корисним, але не обов'язковим.

## Рекомендації

Цей курс ідеально підходить для:
- Розробників, які хочуть створити власні open-source проекти
- Менеджерів проектів, що планують перехід на GitHub
- Команд, які впроваджують InnerSource практики
- Всіх, хто прагне покращити навички співпраці в розробці












## 🖥️ **Поетапне оновлення репозиторію через GitHub Web Interface**

Покажу, як зробити все через браузер, зберігаючи історію та створюючи Release points.

---

## 🏷️ **Крок 1: Створення Baseline Release (точка відліку)**

### **📍 Створення тегу поточної версії:**

1. **Перейти до репозиторію:** `https://github.com/Python-Development-Lab/portfolio-django-azure`

2. **Клікнути "Releases"** (праворуч від кнопки "Code")

3. **"Create a new release"** або **"Draft a new release"**

4. **Заповнити форму Baseline Release:**
   ```
   🏷️ Tag version: v1.0.0
   🎯 Target: main (default)
   📝 Release title: Baseline Version v1.0.0
   📄 Description:
   ```

5. **Опис Release:**
   ```markdown
   # 📦 Baseline Version - Before Major Update
   
   ## 📋 Current Features
   - ✅ Basic Azure Django deployment
   - ✅ PostgreSQL database setup
   - ✅ Storage account configuration
   - ✅ Key Vault integration
   
   ## ⚠️ Status
   This is a baseline release created before major infrastructure updates.
   
   ## 📁 What's Included
   - Basic deployment scripts
   - Initial configuration files
   - Core Django setup
   
   ## 🔄 Next Steps
   Version 2.0.0 will include:
   - Budget-friendly deployment options
   - Enhanced cleanup utilities
   - Cost optimization features
   ```

6. **✅ Publish release**

---

## 🌿 **Крок 2: Створення гілки для оновлень**

### **🔧 Через GitHub Web Interface:**

1. **Відкрити головну сторінку репозиторію**

2. **Клікнути на dropdown "main"** (ліворуч від зеленої кнопки "Code")

3. **Ввести назву нової гілки:** `feature/infrastructure-update`

4. **"Create branch: feature/infrastructure-update from main"**

5. **Переключитися на нову гілку** (повинна автоматично переключитися)

---

## 🗑️ **Крок 3: Видалення застарілих файлів**

### **📂 Видалення через GitHub:**

1. **Перейти до файлу, який потрібно видалити**

2. **Клікнути на файл** → **🗑️ "Delete this file"** (кнопка з іконкою сміттєвого бака)

3. **Scroll down до "Commit changes"**

4. **Заповнити commit message:**
   ```
   📝 Commit message: 🗑️ Remove deprecated deployment script
   
   📄 Extended description:
   - Removing old deployment script that's no longer maintained
   - Preparing for infrastructure modernization
   - Part of v2.0 cleanup process
   ```

5. **✅ "Commit changes"**

6. **Повторити для кожного файлу що видаляється:**
   - `old-deploy.sh` → 🗑️ Delete
   - `legacy-config.yml` → 🗑️ Delete
   - `outdated-requirements.txt` → 🗑️ Delete

---

## ✏️ **Крок 4: Оновлення існуючих файлів**

### **📝 Редагування через GitHub:**

1. **Перейти до файлу для редагування** (наприклад, `README.md`)

2. **Клікнути ✏️ "Edit this file"** (іконка олівця)

3. **Внести зміни в редакторі**

4. **Scroll down до "Commit changes"**

5. **Детальний commit message:**
   ```
   📝 Commit message: 🔧 Update main README with cost information
   
   📄 Extended description:
   - Added cost breakdown for different deployment tiers
   - Updated installation instructions
   - Added migration guide from v1.x
   - Improved documentation structure
   ```

6. **✅ "Commit changes"**

### **📋 Файли для оновлення:**
- `README.md` → 🔧 Update documentation
- `requirements.txt` → 🔧 Update dependencies  
- `.env.example` → 🔧 Add new environment variables
- `azure-infrastructure.sh` → 🔧 Improve existing script

---

## ➕ **Крок 5: Додавання нових файлів**

### **📁 Створення нових файлів:**

1. **На головній сторінці репозиторію** клікнути **"Add file"** → **"Create new file"**

2. **Ввести назву файлу:** `budget-azure-deploy.sh`

3. **Вставити вміст файлу** в редактор

4. **Scroll down до "Commit new file"**

5. **Детальний commit message:**
   ```
   📝 Commit message: ✨ Add budget-friendly Azure deployment script
   
   📄 Extended description:
   - Created cost-effective deployment option (~$20-25/month)
   - Uses F1 App Service tier (free) + B1ms PostgreSQL
   - Includes comprehensive cost breakdown and limitations
   - Optimized for development and small projects
   ```

6. **✅ "Commit new file"**

### **📋 Нові файли для створення:**
- `budget-azure-deploy.sh` → ✨ Budget deployment script
- `cleanup-infrastructure.sh` → ✨ Cleanup utilities
- `.env.budget` → ✨ Budget environment template
- `budget_settings.py` → ✨ Django budget settings
- `MIGRATION.md` → ✨ Migration guide

---

## 🔄 **Крок 6: Створення Pull Request**

### **📋 Merge через Pull Request:**

1. **Перейти до "Pull requests" tab**

2. **"New pull request"**

3. **Налаштувати merge:**
   ```
   base: main ← compare: feature/infrastructure-update
   ```

4. **Заповнити PR details:**
   ```
   📝 Title: 🚀 Major Infrastructure Update v2.0.0
   
   📄 Description:
   ## 🎯 Overview
   Major infrastructure overhaul with budget-friendly options and enhanced utilities.
   
   ## 💰 New Features
   - ✨ Budget deployment script (~$20-25/month)
   - 🧹 Comprehensive cleanup utilities
   - ⚙️ Environment-specific configurations
   - 📊 Detailed cost breakdowns
   
   ## 🗑️ Cleanup
   - Removed deprecated deployment scripts
   - Cleaned up legacy configuration files
   - Updated dependencies
   
   ## 🔧 Improvements
   - Enhanced documentation
   - Better error handling
   - Improved user experience
   
   ## ⚠️ Breaking Changes
   - Removed old deployment methods
   - Updated environment variable structure
   - Minimum Python 3.11+ requirement
   
   ## 🧪 Testing
   - [x] Budget deployment tested
   - [x] Cleanup scripts verified
   - [x] Documentation reviewed
   - [x] No breaking changes to core functionality
   ```

5. **✅ "Create pull request"**

6. **Після review:** **"Merge pull request"** → **"Confirm merge"**

7. **Видалити feature branch:** **"Delete branch"**

---

## 🏷️ **Крок 7: Створення фінального Release v2.0.0**

### **📦 Новий Release після оновлень:**

1. **Перейти до "Releases"**

2. **"Create a new release"**

3. **Заповнити Major Release:**
   ```
   🏷️ Tag version: v2.0.0
   🎯 Target: main
   📝 Release title: Major Infrastructure Update v2.0.0
   ```

4. **Детальний опис Release:**
   ```markdown
   # 🚀 Version 2.0.0 - Infrastructure Overhaul
   
   ## 💰 What's New
   - ✨ **Budget Deployment**: Cost-effective Azure setup (~$20-25/month)
   - 🧹 **Cleanup Utilities**: Comprehensive infrastructure cleanup
   - ⚙️ **Multi-tier Options**: Budget/Production deployment configs
   - 📊 **Cost Transparency**: Detailed cost breakdowns and comparisons
   
   ## 🗑️ Removed
   - ❌ Deprecated legacy deployment scripts
   - ❌ Outdated configuration files  
   - ❌ Unused development dependencies
   
   ## 🔧 Enhanced
   - 🔧 Improved main deployment script
   - 📝 Comprehensive documentation update
   - 🔒 Better security practices
   - ⚡ Optimized performance settings
   
   ## 📊 Deployment Options
   | Configuration | Monthly Cost | Use Case |
   |---------------|-------------|----------|
   | 💰 Budget | $20-25 | Development, Testing, MVPs |
   | 🏢 Production | $100-120 | Business apps, High traffic |
   
   ## ⚠️ Breaking Changes
   - Removed old deployment methods (use new scripts)
   - Changed environment variable structure (see `.env.budget`)
   - Updated minimum Python requirement to 3.11+
   
   ## 📁 New Files
   - `budget-azure-deploy.sh` - Budget deployment script
   - `cleanup-infrastructure.sh` - Infrastructure cleanup
   - `.env.budget` - Budget environment template
   - `budget_settings.py` - Django budget configuration
   - `MIGRATION.md` - Upgrade guide from v1.x
   
   ## 🚀 Quick Start
   
   ### Budget Deployment
   ```bash
   chmod +x budget-azure-deploy.sh
   ./budget-azure-deploy.sh
   ```
   
   ### Production Deployment  
   ```bash
   chmod +x azure-infrastructure.sh
   ./azure-infrastructure.sh
   ```
   
   ### Cleanup
   ```bash
   ./cleanup-infrastructure.sh
   ```
   
   ## 🔄 Migration from v1.x
   1. Backup existing infrastructure
   2. Review new environment variables in `.env.budget`
   3. Choose appropriate deployment tier
   4. Follow detailed guide in `MIGRATION.md`
   
   ## 🐛 Bug Fixes
   - Fixed Azure Key Vault access issues
   - Resolved PostgreSQL connection timeouts
   - Improved error handling in deployment scripts
   
   ## 📈 Performance Improvements
   - Optimized Docker container startup
   - Reduced deployment time by 40%
   - Better resource utilization
   
   ## 🙏 Contributors
   Thanks to all contributors who helped with this major update!
   
   ---
   
   **Full Changelog**: v1.0.0...v2.0.0
   ```

5. **🎯 Generate release notes** (опціонально для автоматичного changelog)

6. **✅ Publish release**

---

## 📊 **Візуальний Timeline оновлення:**

```
📅 Timeline через GitHub Web Interface:

🏷️ v1.0.0 Baseline Release
   ↓
🌿 Create feature/infrastructure-update branch  
   ↓
🗑️ Delete deprecated files (по одному)
   ↓ 
🔧 Update existing files (по одному)
   ↓
✨ Add new files (по одному)
   ↓
🔄 Create Pull Request
   ↓
✅ Merge to main
   ↓
🏷️ v2.0.0 Major Release
```

---

## 🛡️ **Безпека через GitHub Interface:**

### **🔒 Захист main branch:**
1. **Settings** → **Branches**
2. **Add rule** для `main`
3. **☑️ Require pull request reviews**
4. **☑️ Require status checks to pass**

### **👥 Review Process:**
1. **Створити PR** зі змінами
2. **Request review** від колег  
3. **Дочекатися approve**
4. **Merge після approval**

---

## 💡 **Поради для GitHub Web Interface:**

### **✅ Best Practices:**
- **Детальні commit messages** з емодзі для читабельності
- **Часті коміти** замість одного великого
- **Осмислені назви файлів** і папок
- **Comprehensive release notes** з changelog

### **🔧 GitHub Features:**
- **Draft releases** для підготовки
- **Pre-release** для beta версій
- **Release assets** для binary файлів
- **Auto-generated release notes** для changelog

### **📝 Документація:**
- **README badges** для статусу проекту
- **CHANGELOG.md** для детальної історії
- **MIGRATION.md** для upgrade інструкцій
- **CONTRIBUTING.md** для contributors

**Результат: Професійно оновлений репозиторій зі збереженою історією та чіткими Release points!** 🚀📦

----------------------------------------------------------------------------------------------

## 🎯 **Рекомендація для вашого Baseline Release:**

**ТАК, для цього Baseline Release РЕКОМЕНДУЮ встановити Pre-release!** ✅

---

## 🔍 **Чому саме для Baseline варто встановити Pre-release:**

### **📦 Ваш опис чітко вказує на тимчасовість:**

#### **🚨 Ключові фрази що вказують на Pre-release:**
- **"Before Major Update"** — перед великим оновленням
- **"Baseline release"** — базова/тимчасова версія  
- **"Next Steps: Version 2.0.0 will include"** — вказує що це не фінальна версія
- **"Basic"** скрипти — не повнофункціональна версія

#### **📊 Аналіз вашого опису:**
```markdown
❌ "Basic Azure Django deployment"     # Не повна функціональність
❌ "Basic deployment scripts"          # Мінімальна версія
❌ "Initial configuration files"       # Початкова конфігурація
⚠️ "before major infrastructure updates" # Тимчасова природа
```

---

## 🏷️ **Правильна схема релізів для вашого проекту:**

### **📈 Логічна послідовність:**
```
🟡 v1.0.0 [Pre-release] - Baseline (поточний)
   ↳ "Basic version before major updates"
   ↳ ⚠️ Pre-release - Not production ready
   ↳ 🧪 For testing and evaluation only

🟢 v2.0.0 [Latest] - Major Update (майбутній)
   ↳ "Complete infrastructure overhaul"
   ↳ ✅ Stable - Production ready
   ↳ 🚀 Recommended for all users
```

---

## ⚙️ **Налаштування для вашого Baseline:**

### **🔧 GitHub Release Settings:**
```
🏷️ Tag version: v1.0.0
📝 Release title: Baseline Version - Before Major Update
🎯 Target: main

❌ Set as the latest release     # НЕ latest
☑️ Set as a pre-release          # ✅ ВСТАНОВИТИ
```

### **📝 Покращений опис з Pre-release:**
```markdown
# 📦 Baseline Version - Before Major Update

⚠️ **PRE-RELEASE WARNING**: This is a basic version created before major infrastructure updates. For production use, wait for v2.0.0.

## 📋 Current Features
- ✅ Basic Azure Django deployment
- ✅ PostgreSQL database setup  
- ✅ Storage account configuration
- ✅ Key Vault integration

## ⚠️ Status
This is a **baseline pre-release** created before major infrastructure updates.

**🚫 NOT recommended for:**
- Production deployments
- Business-critical applications
- Cost-sensitive projects

**✅ Suitable for:**
- Testing and evaluation
- Development environments
- Learning purposes

## 📁 What's Included
- Basic deployment scripts
- Initial configuration files
- Core Django setup

## 🔄 Next Steps
Version 2.0.0 (stable release) will include:
- 💰 Budget-friendly deployment options (~$20-25/month)
- 🧹 Enhanced cleanup utilities
- 📊 Cost optimization features
- 📚 Comprehensive documentation
- 🛡️ Production-ready security

## 🎯 Migration Path
1. **Current (v1.0.0-pre)**: Basic functionality testing
2. **Upcoming (v2.0.0)**: Full production deployment
3. **Future (v2.x)**: Advanced features and optimizations

## ⏰ Timeline
- **Now**: v1.0.0 (pre-release) - Basic testing
- **Soon**: v2.0.0 (stable) - Production ready
- **Later**: v2.1+ - Advanced features
```

---

## 🎯 **Переваги встановлення Pre-release:**

### **✅ Чому це правильне рішення:**

#### **👥 Управління очікуваннями:**
- **Користувачі розуміють** що це тимчасова версія
- **Немає розчарувань** від базової функціональності
- **Чіткі очікування** щодо майбутніх оновлень

#### **📊 Правильна комунікація:**
```
🟡 v1.0.0 [Pre-release] ← Люди розуміють: "Це для тестування"
🟢 v2.0.0 [Latest]      ← Люди розуміють: "Це для продакшн"
```

#### **🔍 SEO та Discovery:**
- **GitHub показує** останню стабільну версію як Latest
- **Package managers** не розповсюджують pre-release автоматично
- **Уникнення плутанини** у користувачів

---

## 🚫 **Що буде, якщо НЕ встановити Pre-release:**

### **❌ Проблеми без Pre-release позначки:**
```
🟢 v1.0.0 [Latest] - Baseline Version
   ↳ ❌ Користувачі очікують production-ready
   ↳ ❌ Розчарування від "basic" функціональності  
   ↳ ❌ Плутанина коли вийде v2.0.0
   ↳ ❌ GitHub показує це як рекомендовану версію
```

### **😞 Потенційні скарги користувачів:**
- _"Чому це називається v1.0.0 але така базова?"_
- _"Де обіцяні features?"_
- _"Це не готово для production!"_

---

## 🎯 **Ваша ідеальна Release стратегія:**

### **📅 Timeline релізів:**
```
🟡 v1.0.0 [Pre-release] - Baseline
   📅 Зараз: "Basic version for testing"
   🎯 Мета: Збереження поточного стану
   👥 Аудиторія: Розробники, тестувальники

🟢 v2.0.0 [Latest] - Major Update  
   📅 Незабаром: "Production-ready version"
   🎯 Мета: Повнофункціональний реліз
   👥 Аудиторія: Всі користувачі
```

### **🔄 Коли релізити v2.0.0 як Stable:**
- ✅ Коли додасте budget deployment
- ✅ Коли створите cleanup utilities  
- ✅ Коли завершите документацію
- ✅ Коли протестуєте всі features
- ✅ Коли буде готово для production

---

## 💡 **Фінальна рекомендація:**

### **✅ ДЛЯ ВАШОГО BASELINE:**
```
☑️ Set as a pre-release = ТАК
❌ Set as the latest release = НІ

Причини:
📦 Це справді baseline/тимчасова версія
⚠️ Ви самі пишете "before major updates"  
🔄 Ви плануєте кращу версію v2.0.0
🎯 Це допоможе управляти очікуваннями
```

### **🚀 ДЛЯ МАЙБУТНЬОГО v2.0.0:**
```
❌ Set as a pre-release = НІ  
☑️ Set as the latest release = ТАК

Коли буде готово:
✅ Повна функціональність
✅ Production-ready
✅ Comprehensive documentation
✅ Tested and stable
```

**Встановлюйте Pre-release для Baseline — це професійно та чесно відносно користувачів!** 🎯✅

-----------------------------------------------------------------------

### REFERENCES:

- Semantic Versioning 2.0.0, https://semver.org/
- About release management, https://docs.github.com/ru/repositories/releasing-projects-on-github/managing-releases-in-a-repository
- Build community-driven software projects on GitHub, https://learn.microsoft.com/en-us/training/paths/build-community-driven-projects-github/
- 

