# Messenger Client — «Диалог»

Кроссплатформенный клиент (**iOS, macOS, Android, Windows**) в стиле макетов: бежевая палитра, боковая навигация, список диалогов, чат с «срезанными» пузырями и экран профиля.

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

- Экран входа / регистрации «Диалог» (вкладки, запомнить меня, соц-кнопки — заглушки)
- **Диалоги** — список чатов, поиск, закрепление (долгое нажатие), чат со статусами ✓✓
- **Контакты** — поиск пользователей на сервере
- **Заметки** — локальные заметки на устройстве
- **Настройки профиля** — имя (API), «О себе», статус, аватары, тема, сервер API
- Локальная SQLite + sync + WebSocket

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
