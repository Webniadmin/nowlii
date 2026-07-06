# Support / Contact chat

_Added 2026-07-03. Replaces the old UI-only mockups with a working DB-backed support
conversation + email notifications. Verified end-to-end from the Android app._

## How it works

- **Source of truth is the DB** (`SupportMessage`), not email. Each user has one thread; every
  row is one message with `sender = user | admin`.
- **User → support:** the app `POST`s a message → stored + an **email alert** goes to the
  support inbox (`SUPPORT_EMAIL`). The app also lists the thread with `GET`.
- **Support → user:** you reply from the **Django admin** → a `sender='admin'` message is created
  → it appears in the user's in-app Support chat (pull-to-refresh) and the user is emailed.
- No fragile inbound-email parsing. (If you later want to reply from your own mailbox and have it
  land in the chat, that's a separate phase — ingest IMAP/inbound-webhook → create an admin message.)

## Backend (`nowli-backend/Apps/support/`)

- `models.py` — `SupportMessage(user, sender, category, body, is_read, created_at)`.
- `serializers.py` — `sender/is_read/created_at` are read-only (server-managed).
- `views.py` — `SupportMessageViewSet` (list + create only). `get_queryset()` filters
  **`user=request.user`**, so a user only ever sees/creates their **own** messages
  (verified: a different user gets 0 of another's). `perform_create` sets `sender='user'` and
  emails `SUPPORT_EMAIL`.
- `urls.py` → mounted at **`/api/support/messages/`** (`GET` list, `POST` create; auth required).
- `admin.py` — registered with a **"✏️ Reply to this user"** box on each message's page: open a
  message, type a reply, **Save** → creates the admin reply + emails the user. (Uses the SMTP
  from `nowliiapp@gmail.com`.)
- Wired in `core/settings.py` (`Apps.support` in `LOCAL_APPS`), `core/urls.py`, and
  `SUPPORT_EMAIL` in `.env` (currently `justweb.rs@gmail.com`).

## Frontend (`nowli-frontend-app/`)

- `lib/services/support_service.dart` — `SupportMessage` model + `getMessages()` / `sendMessage()`.
- `lib/api/api_constant.dart` — `supportMessages = '/api/support/messages/'`.
- `screen/settings/contact_support/support/support.dart` — the **"Send Message"** form now really
  posts (category + body), with loading + error handling (was a UI-only mock).
- `screen/settings/contact_support/chat_boot/support_chat_screen.dart` — the **Support Chat** now
  loads the real thread (pull-to-refresh) and sends messages (was hardcoded dummy data).

## Admin — how to reply

1. `http://localhost:8000/admin/`  (in production: the deployed backend's `/admin/`).
   Login: `justweb.rs@gmail.com` / `lozinka_123` (superuser created 2026-07-03).
2. **Support messages** → click a message (the date column).
3. Type into **"✏️ Reply to this user"** → **SAVE**.

## Verified 2026-07-03
- Backend: `GET /api/support/messages/` → 200, `POST` → 201; per-user isolation (other user sees 0).
- From the Android app (logged in): chat loads (GET 200) and sends (POST 201); the send emails the
  support inbox. Admin reply → appears in the app + emails the user.

## Follow-ups
- Nicer chat UX (auto-refresh/websocket instead of pull-to-refresh); mark-as-read.
- Optional inbound-email → chat (reply from your mailbox) as a later phase.
