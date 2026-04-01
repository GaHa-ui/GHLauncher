# GHLauncher — Сборка .ipa

## 1. На Mac с Xcode (через Package.swift)

```bash
# Клонируем/переходим в проект
cd GHLauncher_iOS

# Проверяем что Package.swift валиден
swift package dump-package

# Собираем (debug)
swift build -Xswiftc "-sdk" -Xswiftc "`xcrun --sdk iphonesimulator --show-sdk-path`" -Xswiftc "-target" -Xswiftc "x86_64-apple-ios17.0-simulator"

# Для Release на реальное устройство:
swift build -c release \
  -Xswiftc "-sdk" -Xswiftc "`xcrun --sdk iphoneos --show-sdk-path`" \
  -Xswiftc "-target" -Xswiftc "arm64-apple-ios17.0"
```

## 2. На Mac с Xcode (через .xcodeproj рекомендуемый)

Package.swift для SPM-библиотеки. Для `.ipa` лучше создать Xcode-проект:

1. Файл → Новый проект → iOS → App → SwiftUI
2. Назови "GHLauncher"
3. Скопируй все `.swift` файлы из папки `GHLauncher/` в проект
4. Убедись что Info.plist существует
5. Product → Archive
6. Window → Organizer → Distribute App → Ad Hoc
7. Получишь `.ipa`

### Или через CLI:
```bash
xcodebuild archive \
  -project GHLauncher.xcodeproj \
  -scheme GHLauncher \
  -configuration Release \
  -destination generic/platform=iOS \
  -archivePath ./GHLauncher.xcarchive

xcodebuild -exportArchive \
  -archivePath ./GHLauncher.xcarchive \
  -exportOptionsPlist export.plist \
  -exportPath ./build
```

## 3. Без Mac — через GitHub Actions

Создай `.github/workflows/build.yml`:

```yaml
name: Build IPA
on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode.app
      - name: Build
        run: |
          mkdir -p Payload
          xcodebuild -project GHLauncher.xcodeproj \
            -scheme GHLauncher \
            -configuration Release \
            -destination "generic/platform=iOS" \
            -derivedDataPath ./build \
            build
          cp -r build/Build/Products/Release-iphoneos/GHLauncher.app Payload/
          zip -r GHLauncher.ipa Payload
          rm -rf Payload
      - name: Upload
        uses: actions/upload-artifact@v4
        with:
          name: GHLauncher.ipa
          path: GHLauncher.ipa
```

## 4. Установка на iPhone

### AltStore (бесплатно)
1. Скачай AltStore на Mac/PC
2. Подключи iPhone кабелем
3. Добавь `.ipa` в AltStore
4. Пере-подписывай каждые 7 дней (бесплатный Apple ID)

### Sideloadly (Windows/Mac)
1. Скачай sideloadly.io
2. Перетащи `.ipa`
3. Введи Apple ID
4. Нажми Start

### TrollStore (без ограничения по времени)
- Работает только на iOS 16.0–16.6.1 и 17.0
- Установи TrollStore
- Просто кинь `.ipa` в приложение

## Структура проекта
```
GHLauncher_iOS/
├── Package.swift                 # SPM манифест
├── GHLauncher/
│   ├── GHLauncherApp.swift       # @main entry point
│   ├── Info.plist                # bundle config
│   ├── Resources/                # Assets.xcassets
│   ├── Core/
│   │   ├── Models/               # Model structs
│   │   ├── Networking/           # API services
│   │   └── Storage/              # UserDefaults, profiles
│   ├── ViewModels/               # Business logic
│   ├── Views/
│   │   ├── Home/
│   │   ├── Mods/
│   │   ├── Settings/
│   │   ├── More/
│   │   ├── Logs/
│   │   └── Components/
│   └── Extensions/
```

## Экспорт через export.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>ad-hoc</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
```
