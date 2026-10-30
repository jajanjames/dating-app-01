# JDATE Mobile (Flutter)

Mobile application built with Flutter, using GetX for state management, `flutter_screenutil` for responsive UI, and the `http` package for API calls.

## Stack

- Flutter
- GetX (`GetBuilder` — no Bindings, no `Obx`)
- flutter_screenutil
- http

## State management convention

- No Bindings — controllers are instantiated directly in each screen via `GetBuilder<Controller>(init: Controller(), builder: ...)`.
- No `Obx` — all reactive rebuilds happen through `GetBuilder` + `update()`.

## Getting started

```bash
flutter pub get
flutter run
```

Update the API base URL in `lib/app/config/app_config.dart`.

## Project structure

```
lib/
├── main.dart
└── app/
    ├── config/          # App-wide configuration (API base URL, timeouts)
    ├── data/
    │   ├── models/       # Data models
    │   └── services/     # ApiService (http package wrapper)
    ├── modules/
    │   ├── splash/        # Splash screen + controller
    │   ├── auth/
    │   │   ├── login/      # Login screen + controller
    │   │   └── register/   # Register screen + controller
    │   ├── home/           # Home screen + controller
    │   └── profile/        # Profile screen + controller
    ├── routes/            # Route names and GetPage definitions (no bindings)
    ├── utils/             # Colors, strings, text styles
    └── widgets/           # Shared widgets (CustomButton, CustomTextField)
```
