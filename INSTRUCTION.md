# Инструкция: Собрать GHLauncher.ipa через GitHub Actions

Без Mac, без ПК — только телефон + браузер.

---

## Шаг 1: Создай репозиторий на GitHub

1. Открой https://github.com/new
2. Repository name: `GHLauncher`
3. **Public** или **Private** — как хочешь
4. ❌ НЕ ставь галочку "Add README"
5. Нажми **Create repository**
6. Скопируй URL репозитория (типа `https://github.com/ТВОЙ_НИК/GHLauncher.git`)

---

## Шаг 2: Запули код через Termux (на телефоне)

В Termux:

```bash
# Установи git
pkg update && pkg upgrade
pkg install git

# Перейди в папку с кодом (если она там)
cd /путь/к/GHLauncher_iOS

# Инициализируй git
git init
git add .
git commit -m "Initial commit"

# Добавь удалённый репо (замени СВОЙ_НИК)
git remote add origin https://github.com/ТВОЙ_НИК/GHLauncher.git

# Пуш
git push -u origin main
```

Если ругается на авторизацию — сделай **Personal Access Token**:
1. https://github.com/settings/tokens/new
2. Дай права: `repo`
3. Скопируй токен
4. Вместо пароля используй токен:
   ```bash
   git push -u origin main
   # User: твой ник
   # Password: вставь токен
   ```

---

## Шаг 3: Жди сборку

1. Открой https://github.com/ТВОЙ_НИК/GHLauncher/actions
2. Там будет running задача "Build IPA"
3. Подожди 5-15 минут
4. Нажми на задачу → скачай **GHLauncher.ipa** из раздела Artifacts

---

## Шаг 4: Установи на iPhone

**AltStore** (бесплатно, 7 дней, переподпись):
1. Скачай AltServer на ПК (Mac/Windows)
2. Подключи iPhone кабелем к ПК
3. Открой AltServer → Install AltStore → выбери устройство
4. Открой AltStore на iPhone → My Apps → + → выбери downloaded IPA

**Sideloadly** (Windows/Mac):
1. https://sideloadly.io
2. Открой программу → перетащи IPA
3. Введи Apple ID → Start

**TrollStore** (iOS 16.0-16.6.1 или 17.0, без переподписи):
- Просто открой файл через TrollStore

---

## Если Actions не сработает

Зайди в файл `project.yml` и убедись что:
- `bundleId` = `com.ghlauncher.app` (уникальный)
- `deploymentTarget iOS` = 17.0

В `.xcodeproj` на Mac можно собрать без GitHub.
