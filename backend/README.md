# JDATE Backend (NestJS)

REST API built with NestJS, PostgreSQL, Prisma ORM, JWT authentication and Swagger documentation.

## Stack

- NestJS 12
- PostgreSQL + Prisma ORM
- JWT authentication (Passport)
- Swagger / OpenAPI docs
- Vitest for testing

## Getting started

```bash
npm install
cp .env.example .env   # adjust DATABASE_URL, JWT_SECRET, etc.
npx prisma migrate dev --name init
npm run start:dev
```

- API base URL: `http://localhost:3000/api/v1`
- Swagger docs: `http://localhost:3000/api/docs`

## Project structure

```
src/
├── auth/            # Authentication module (JWT strategy, guards, DTOs)
├── users/            # Users module (controller, service, DTOs, entity)
├── prisma/           # Prisma service/module (database access)
├── config/           # Environment configuration
├── common/           # Shared decorators, filters, interceptors
├── app.module.ts
└── main.ts            # Bootstrap, Swagger setup, global pipes
prisma/
└── schema.prisma     # Database schema
```

## Scripts

| Command             | Description                   |
| ------------------- | ------------------------------ |
| `npm run start:dev` | Start in watch mode             |
| `npm run build`     | Compile TypeScript              |
| `npm run lint`      | Lint source files                |
| `npm test`          | Run unit tests                   |
| `npm run test:e2e`  | Run end-to-end tests             |
