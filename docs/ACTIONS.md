Є кілька способів зупинити виконання GitHub Action для деплою на Azure:

## Швидке зупинення поточного виконання

1. **Через веб-інтерфейс GitHub:**
   - Перейдіть до вкладки "Actions" у вашому репозиторії
   - Знайдіть поточне виконання (воно буде з жовтою іконкою)
   - Натисніть на нього та оберіть "Cancel workflow"

2. **Через GitHub CLI:**
   ```bash
   gh run cancel <run-id>
   ```

## Тимчасове відключення workflow

Додайте в початок вашого `.github/workflows/*.yml` файлу:

```yaml
name: Deploy to Azure
on:
  push:
    branches: [ main ]
  # Закоментуйте trigger щоб тимчасово відключити
  # push:
  #   branches: [ main ]

jobs:
  deploy:
    if: false  # Це також зупинить виконання
    runs-on: ubuntu-latest
    # решта конфігурації...
```

## Постійне відключення

1. **Видалити workflow файл:**
   ```bash
   rm .github/workflows/deploy-azure.yml
   git add .
   git commit -m "Remove Azure deployment workflow"
   git push
   ```

2. **Відключити через настройки репозиторію:**
   - Settings → Actions → General
   - Оберіть "Disable actions" або "Allow select actions"

## Умовне виконання

Якщо потрібно контролювати деплой через коміт-повідомлення:

```yaml
jobs:
  deploy:
    if: "!contains(github.event.head_commit.message, '[skip deploy]')"
    runs-on: ubuntu-latest
```

Тоді просто додавайте `[skip deploy]` до коміт-повідомлень, коли не потрібен деплой.

Який саме спосіб вам підходить залежить від того, чи потрібно зупинити лише поточне виконання, чи відключити автоматичний деплой назавжди.
