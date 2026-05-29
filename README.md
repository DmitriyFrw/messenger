# Messenger API

Бэкенд мессенджера на **FastAPI** + **SQLite**: регистрация/логин, отображаемое имя, время отправки, статусы сообщений и API для синхронизации истории на устройстве клиента.

## Возможности

| Функция | Описание |
|--------|----------|
| Логин | `POST /api/auth/register`, `POST /api/auth/login` → JWT |
| Отображаемое имя | Поле `display_name` при регистрации, `PATCH /api/users/me` |
| Время сообщения | `sent_at` (UTC, ISO 8601) |
| Статус | `not_delivered` → `delivered` → `read` |
| История на устройстве | Клиент хранит локально; `GET /api/sync?updated_since=...` подтягивает изменения |

## Запуск

```bash
cd messenger
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # при необходимости смените SECRET_KEY
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Документация: http://localhost:8000/docs

## Статусы сообщений

- **`not_delivered`** — получатель офлайн, сообщение ещё не доставлено на его устройство
- **`delivered`** — получатель онлайн (WebSocket) или сообщение принято клиентом
- **`read`** — получатель открыл диалог (`POST /api/conversations/{id}/read` или WS `{"action":"read","conversation_id":1}`)

Отправитель получает обновления статуса через WebSocket (`type: message_status`).

## WebSocket

```
ws://localhost:8000/ws?token=<JWT>
```

События от сервера:

- `new_message` — новое входящее сообщение
- `message_status` — смена статуса
- `pong` — ответ на `{"action":"ping"}`

## Локальное хранение на устройстве

Сервер не заменяет локальную БД клиента — он источник правды для синхронизации между устройствами.

Рекомендуемый поток на клиенте (IndexedDB / SQLite / Room):

1. После логина сохранить `access_token` и профиль (`GET /api/users/me`).
2. Загрузить диалоги: `GET /api/conversations` → сохранить в локальную таблицу `conversations`.
3. Для каждого диалога подгрузить историю: `GET /api/conversations/{id}/messages`.
4. Хранить `last_sync_at` (время последней успешной синхронизации).
5. Периодически и при старте приложения: `GET /api/sync?updated_since=<last_sync_at>` — upsert сообщений по `id`, обновлять `status` и `status_updated_at`.
6. Подключить WebSocket для мгновенных сообщений и статусов; дублировать входящие события в локальную БД.
7. Отправка: `POST /api/messages` → сразу показать в UI с временным id, после ответа заменить на серверный `id`.

Пример синхронизации:

```http
GET /api/sync?updated_since=2026-05-29T10:00:00Z
Authorization: Bearer <token>
```

Ответ содержит все сообщения в ваших диалогах, у которых `status_updated_at` новее указанного времени (включая смену статуса на «прочитано»).

## Примеры API

```bash
# Регистрация
curl -s -X POST http://localhost:8000/api/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"username":"alice","password":"secret12","display_name":"Алиса"}'

# Логин
curl -s -X POST http://localhost:8000/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"alice","password":"secret12"}'

# Отправить сообщение
curl -s -X POST http://localhost:8000/api/messages \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"recipient_id":2,"text":"Привет!"}'
```
