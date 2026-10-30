# JDATE

Monorepo scaffold containing a NestJS backend, a Next.js (SSR) frontend, a Flutter mobile app, and Docker setup to run everything together.

> This repository contains only the **project structure** — folders, config, module wiring, routing and screens. No business logic / features have been implemented.

## Repository layout

```
JDATE/
├── backend/            # NestJS API (PostgreSQL, Prisma, JWT, Swagger)
├── frontend/           # Next.js web app (SSR, TypeScript, no Tailwind)
├── mobile/             # Flutter app (GetX, GetBuilder, screenutil, http)
├── docker-compose.yml  # Orchestrates postgres + backend + frontend
└── README.md
```

---

## 1. Backend — NestJS

**Stack:** NestJS · PostgreSQL · Prisma ORM · JWT (Passport) · Swagger

```
backend/
├── prisma/
│   └── schema.prisma              # User model, PostgreSQL datasource
├── src/
│   ├── auth/
│   │   ├── dto/
│   │   │   ├── login.dto.ts
│   │   │   └── register.dto.ts
│   │   ├── guards/
│   │   │   └── jwt-auth.guard.ts
│   │   ├── strategies/
│   │   │   └── jwt.strategy.ts
│   │   ├── auth.controller.ts     # POST /auth/register, /auth/login, GET /auth/profile
│   │   ├── auth.service.ts
│   │   └── auth.module.ts
│   ├── users/
│   │   ├── dto/
│   │   │   ├── create-user.dto.ts
│   │   │   └── update-user.dto.ts
│   │   ├── entities/
│   │   │   └── user.entity.ts
│   │   ├── users.controller.ts    # CRUD routes, JWT-protected
│   │   ├── users.service.ts
│   │   └── users.module.ts
│   ├── prisma/
│   │   ├── prisma.service.ts      # PrismaClient lifecycle
│   │   └── prisma.module.ts       # Global module
│   ├── config/
│   │   └── configuration.ts       # Reads env vars (port, db, jwt)
│   ├── common/
│   │   ├── decorators/current-user.decorator.ts
│   │   ├── filters/http-exception.filter.ts
│   │   └── interceptors/transform.interceptor.ts
│   ├── app.module.ts
│   ├── app.controller.ts          # GET /health
│   └── main.ts                    # Swagger + ValidationPipe + CORS bootstrap
├── .env.example
├── Dockerfile
└── package.json
```

**Endpoints (structure only, no logic implemented):**

| Method | Route               | Description                  |
| ------ | ------------------- | ----------------------------- |
| GET    | `/health`             | Health check                   |
| POST   | `/auth/register`      | Register a new user              |
| POST   | `/auth/login`          | Login, returns JWT               |
| GET    | `/auth/profile`        | Get current user (JWT protected) |
| POST   | `/users`               | Create user                        |
| GET    | `/users`               | List users                          |
| GET    | `/users/:id`           | Get a user                           |
| PATCH  | `/users/:id`           | Update a user                         |
| DELETE | `/users/:id`           | Delete a user                          |

- API base path: `/api/v1`
- Swagger UI: `/api/docs`

---

## 2. Frontend — Next.js (SSR)

**Stack:** Next.js (Pages Router) · TypeScript · CSS Modules (no Tailwind)

```
frontend/
├── src/
│   ├── pages/
│   │   ├── _app.tsx
│   │   ├── _document.tsx
│   │   ├── index.tsx        # Home — SSR (getServerSideProps)
│   │   ├── login.tsx         # Login screen
│   │   ├── register.tsx      # Register screen
│   │   ├── dashboard.tsx      # Dashboard — SSR, reads auth cookie
│   │   └── profile.tsx         # Profile — SSR
│   ├── components/
│   │   ├── layout/
│   │   │   ├── Header.tsx
│   │   │   ├── Footer.tsx
│   │   │   └── Layout.tsx
│   │   └── common/
│   │       ├── Button.tsx
│   │       └── Input.tsx
│   ├── services/
│   │   ├── api.ts            # fetch wrapper
│   │   └── auth.service.ts   # login / register / profile calls
│   ├── hooks/
│   │   └── useAuth.ts
│   ├── types/
│   │   └── index.ts
│   ├── utils/
│   │   └── constants.ts
│   └── styles/                # CSS Modules (Layout, Form, Auth, Home)
├── .env.local.example
├── Dockerfile
└── package.json
```

**Screens:**

| Page           | Route         | Rendering                           |
| -------------- | ------------- | ------------------------------------- |
| Home            | `/`             | SSR (`getServerSideProps`)             |
| Login            | `/login`         | Client form, posts to `/auth/login`      |
| Register          | `/register`       | Client form, posts to `/auth/register`    |
| Dashboard           | `/dashboard`         | SSR, checks auth cookie                     |
| Profile               | `/profile`             | SSR, fetches current user                      |

---

## 3. Mobile — Flutter

**Stack:** Flutter · GetX (`GetBuilder` only — no Bindings, no `Obx`) · flutter_screenutil · http

```
mobile/
├── lib/
│   ├── main.dart                     # ScreenUtilInit + GetMaterialApp
│   └── app/
│       ├── config/
│       │   └── app_config.dart        # API base URL
│       ├── data/
│       │   ├── models/
│       │   │   └── user_model.dart
│       │   └── services/
│       │       └── api_service.dart   # http package wrapper
│       ├── modules/
│       │   ├── splash/
│       │   │   ├── splash_screen.dart
│       │   │   └── splash_controller.dart
│       │   ├── auth/
│       │   │   ├── login/
│       │   │   │   ├── login_screen.dart
│       │   │   │   └── login_controller.dart
│       │   │   └── register/
│       │   │       ├── register_screen.dart
│       │   │       └── register_controller.dart
│       │   ├── home/
│       │   │   ├── home_screen.dart
│       │   │   └── home_controller.dart
│       │   └── profile/
│       │       ├── profile_screen.dart
│       │       └── profile_controller.dart
│       ├── routes/
│       │   ├── app_routes.dart        # Route name constants
│       │   └── app_pages.dart         # GetPage list (no bindings)
│       ├── utils/
│       │   ├── app_colors.dart
│       │   ├── app_strings.dart
│       │   └── app_text_styles.dart
│       └── widgets/
│           ├── custom_button.dart
│           └── custom_text_field.dart
├── assets/
│   ├── images/
│   └── icons/
└── pubspec.yaml
```

**Screens:**

| Screen    | Route         | Controller access pattern                                   |
| --------- | ------------- | -------------------------------------------------------------- |
| Splash      | `/splash`       | `GetBuilder<SplashController>(init: SplashController(), ...)`     |
| Login         | `/login`          | `GetBuilder<LoginController>(init: LoginController(), ...)`          |
| Register        | `/register`         | `GetBuilder<RegisterController>(init: RegisterController(), ...)`      |
| Home              | `/home`                | `GetBuilder<HomeController>(init: HomeController(), ...)`                |
| Profile               | `/profile`                 | `GetBuilder<ProfileController>(init: ProfileController(), ...)`              |

State management convention: every screen instantiates its own controller inline via `GetBuilder`'s `init` parameter — **no Bindings module, no `Obx`**. Reactive rebuilds happen through `update()` inside each controller.

---

## 4. Docker

Root-level `docker-compose.yml` runs three services:

| Service    | Image / Build         | Port                     |
| ---------- | ---------------------- | ------------------------- |
| `postgres`   | `postgres:16-alpine`      | `5432`                      |
| `backend`      | `./backend/Dockerfile`       | `3000` → `/api/v1`, `/api/docs` |
| `frontend`         | `./frontend/Dockerfile`          | `3001`                               |

```bash
docker compose up --build
```

The mobile app is built and run locally with the Flutter SDK (`flutter run`) and is not containerized.

---

## Getting started (local development)

```bash
# 1. Database + API
docker compose up -d postgres
cd backend && npm install && npx prisma migrate dev --name init && npm run start:dev

# 2. Frontend
cd frontend && npm install && npm run dev

# 3. Mobile
cd mobile && flutter pub get && flutter run
```
# jdate
