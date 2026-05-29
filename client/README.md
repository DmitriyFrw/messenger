# Messenger Client (Flutter)

Кроссплатформенный клиент для **iOS**, **macOS**, **Android** и **Windows** с локальной SQLite-историей, статусами сообщений и WebSocket в реальном времени.

## Требования

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.19+
- Запущенный бэкенд (`uvicorn` на порту 8000)

## Первоначальная настройка

```bash
cd client
chmod +x setup.sh
./setup.sh
```

Скрипт создаёт нативные проекты (`ios/`, `android/`, `macos/`, `windows/`) и выполняет `flutter pub get`.

## Запуск

| Платформа | Команда |
|-----------|---------|
| macOS | `flutter run -d macos` |
| Windows | `flutter run -d windows` |
| Android (эмулятор) | `flutter run -d android` |
| iOS (симулятор) | `flutter run -d ios` |

Список устройств: `flutter devices`

## Адрес сервера

| Среда | URL по умолчанию |
|-------|------------------|
| macOS / Windows / iOS Simulator | `http://127.0.0.1:8000` |
| Android Emulator | `http://10.0.2.2:8000` |
| Физическое устройство | IP компьютера в Wi‑Fi, напр. `http://192.168.1.10:8000` |

Сменить адрес: **Настройки** → «Сервер API».

## Возможности клиента

- Регистрация и вход (JWT)
- Отображаемое имя (редактирование в настройках)
- Список диалогов и чат
- Время отправки у каждого сообщения
- Статусы исходящих: не доставлено / доставлено / прочитано
- **Локальная БД** (`sqflite` / `sqflite_ffi` на десктопе) + инкрементальная синхронизация `/api/sync`
- WebSocket для новых сообщений и обновления статусов

## Структура

```
lib/
├── config/       # URL сервера
├── data/         # API, WebSocket, SQLite, репозиторий
├── models/
├── screens/      # auth, home, chat, settings
└── widgets/      # пузырь сообщения, индикатор статуса
```

## Сборка релиза

```bash
flutter build apk          # Android
flutter build ios          # iOS (нужен Xcode)
flutter build macos        # macOS
flutter build windows      # Windows
```
