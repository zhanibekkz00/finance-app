# ⚠️ Важно: Исправление .env файла

## Проблема

В твоём `.env` файле используется **Prisma Accelerate URL** (начинается с `prisma+postgres://`), но для локальной разработки нужен **обычный PostgreSQL URL**.

## Решение

Открой файл `backend/.env` и замени `DATABASE_URL` на:

```env
DATABASE_URL="postgresql://postgres:твой_пароль@localhost:5432/finance_app?schema=public"
JWT_SECRET="my-super-secret-jwt-key-change-this-12345"
JWT_EXPIRES_IN="7d"
PORT=3000
```

**Важно:**
- Замени `postgres` на свой username PostgreSQL (обычно `postgres`)
- Замени `твой_пароль` на свой пароль PostgreSQL
- Если порт PostgreSQL не 5432, укажи правильный
- Убедись, что база `finance_app` существует

## Формат URL

Правильный формат:
```
postgresql://username:password@host:port/database?schema=public
```

**НЕ используй:**
- `prisma+postgres://...` (это для Prisma Accelerate, облачного сервиса)
- `postgres://...` (старый формат, может не работать)

**Используй:**
- `postgresql://...` (правильный формат для PostgreSQL)
