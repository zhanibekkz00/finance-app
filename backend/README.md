# Finance App Backend API

Backend для Finance App на NestJS + Prisma + PostgreSQL.

## 🚀 Быстрый старт

### 1. Настройка базы данных

1. Убедись, что PostgreSQL запущен и база `finance_app` создана
2. Скопируй `.env.example` в `.env`:
   ```bash
   copy .env.example .env
   ```
3. Отредактируй `.env` и укажи свои данные подключения:
   ```env
   DATABASE_URL="postgresql://username:password@localhost:5432/finance_app?schema=public"
   JWT_SECRET="your-super-secret-jwt-key-change-this-in-production"
   JWT_EXPIRES_IN="7d"
   PORT=3000
   ```

### 2. Генерация Prisma Client

```bash
npx prisma generate
```

### 3. Запуск backend

```bash
npm run start:dev
```

Backend запустится на `http://localhost:3000`

## 📡 API Endpoints

### Авторизация

#### Регистрация
```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Ответ:**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "createdAt": "2026-01-29T10:00:00Z"
  },
  "token": "jwt-token-here"
}
```

#### Логин
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Ответ:** (тот же формат, что и регистрация)

---

### Настройки (требует авторизации)

#### Получить настройки
```http
GET /settings
Authorization: Bearer <token>
```

#### Обновить настройки
```http
PUT /settings
Authorization: Bearer <token>
Content-Type: application/json

{
  "themeMode": "dark",
  "locale": "kk",
  "currencyCode": "KZT"
}
```

---

### Категории (требует авторизации)

#### Получить все категории
```http
GET /categories?includeDefault=true
Authorization: Bearer <token>
```

#### Создать категорию
```http
POST /categories
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Taxi",
  "colorValue": 4294198070,
  "iconCode": 57946
}
```

#### Удалить категорию
```http
DELETE /categories/:id
Authorization: Bearer <token>
```

---

### Транзакции (требует авторизации)

#### Получить все транзакции
```http
GET /transactions?from=2026-01-01&to=2026-01-31&type=expense&categoryId=uuid
Authorization: Bearer <token>
```

#### Создать транзакцию
```http
POST /transactions
Authorization: Bearer <token>
Content-Type: application/json

{
  "type": "expense",
  "amount": 2500.50,
  "currency": "KZT",
  "categoryId": "uuid",
  "date": "2026-01-29T09:30:00Z",
  "note": "Groceries",
  "isRecurring": false,
  "recurrenceInterval": "none",
  "isPinned": false
}
```

#### Обновить транзакцию
```http
PUT /transactions/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "note": "Updated note",
  "amount": 3000.00
}
```

#### Удалить транзакцию
```http
DELETE /transactions/:id
Authorization: Bearer <token>
```

#### Закрепить/открепить транзакцию
```http
PUT /transactions/:id/pin
Authorization: Bearer <token>
```

#### Статистика по категории
```http
GET /transactions/stats/categories/:categoryId?from=2026-01-01&to=2026-01-31
Authorization: Bearer <token>
```

---

## 🧪 Тестирование API

### Пример с curl

1. **Регистрация:**
```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

2. **Логин (сохрани токен):**
```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

3. **Получить категории:**
```bash
curl -X GET http://localhost:3000/categories \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

4. **Создать транзакцию:**
```bash
curl -X POST http://localhost:3000/transactions \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "expense",
    "amount": 1000,
    "currency": "USD",
    "categoryId": "CATEGORY_UUID",
    "date": "2026-01-29T10:00:00Z",
    "note": "Test transaction"
  }'
```

---

## 📁 Структура проекта

```
backend/
├── src/
│   ├── auth/           # Авторизация (register, login, JWT)
│   ├── settings/       # Настройки пользователя
│   ├── categories/     # Категории
│   ├── transactions/   # Транзакции
│   ├── prisma/         # Prisma service и module
│   ├── app.module.ts   # Главный модуль
│   └── main.ts         # Точка входа
├── prisma/
│   └── schema.prisma   # Схема базы данных
└── .env                # Переменные окружения
```

---

## 🔧 Команды

```bash
# Разработка
npm run start:dev

# Продакшн сборка
npm run build
npm run start:prod

# Генерация Prisma Client
npx prisma generate

# Миграции (если нужно)
npx prisma migrate dev

# Просмотр базы данных
npx prisma studio
```

---

## ⚠️ Важно

- Все защищённые endpoints требуют заголовок `Authorization: Bearer <token>`
- JWT токен истекает через 7 дней (настраивается в `.env`)
- Пароли хранятся в захешированном виде (bcrypt)
- Каждый пользователь видит только свои данные

---

## 🐛 Решение проблем

### Ошибка подключения к базе данных
- Проверь, что PostgreSQL запущен
- Проверь `DATABASE_URL` в `.env`
- Убедись, что база `finance_app` существует

### Prisma Client не найден
```bash
npx prisma generate
```

### Порт 3000 занят
Измени `PORT` в `.env`
