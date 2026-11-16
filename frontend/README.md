# JDATE Frontend (Next.js)

Server-side rendered web application built with Next.js, TypeScript and the Pages Router. No CSS framework (Tailwind) — plain CSS Modules.

## Stack

- Next.js 16 (Pages Router)
- TypeScript
- CSS Modules (no Tailwind)

## Getting started

```bash
npm install
cp .env.local.example .env.local   # set NEXT_PUBLIC_API_URL
npm run dev
```

App runs at `http://localhost:3001` (or the port you configure).

## Project structure

```
src/
├── pages/            # Routes — SSR via getServerSideProps
│   ├── _app.tsx
│   ├── _document.tsx
│   ├── index.tsx
│   ├── login.tsx
│   ├── register.tsx
│   ├── dashboard.tsx
│   └── profile.tsx
├── components/
│   ├── layout/        # Header, Footer, Layout
│   └── common/         # Reusable UI (Button, Input)
├── services/           # API client (fetch wrapper), auth service
├── hooks/              # Custom React hooks
├── types/              # Shared TypeScript types
├── utils/              # Constants / helpers
└── styles/             # CSS Modules
```

## Scripts

| Command         | Description              |
| --------------- | ------------------------- |
| `npm run dev`   | Start dev server            |
| `npm run build` | Production build             |
| `npm run start` | Start production server      |
| `npm run lint`  | Lint source files              |
