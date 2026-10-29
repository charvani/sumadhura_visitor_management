# Visitor Management

A Flutter visitor-management app for front-desk and security teams. It supports
visitor registration and editing, visitor search and filters, QR passes and
scanning, check-in/check-out, activity history, dashboard statistics, local
caching, pull-to-refresh, and light/dark themes.

## Run

```shell
flutter pub get
flutter run
```

By default, the app runs in **local demo mode**. Visitor records and theme
preferences are stored on-device with `shared_preferences`, and a small set of
sample records is created on first launch. This makes all screens and workflows
usable without a backend.

To connect a REST API compatible with the `/visitors` endpoints, provide its
base URL at build/run time:

```shell
flutter run --dart-define=API_BASE_URL=https://your-mock-api.example.com/api
```

The app appends `/visitors` and `/visitors/{id}` to that URL. The API should
return JSON visitor objects with an `id` field (including after POST) and
support GET collection/item, POST, PUT, and DELETE. Check-in/check-out uses PUT
with the visitor fields, status, timestamps, and `history`. Successful remote
responses update the local cache; when the API is unavailable, the app displays
cached records and an error notice rather than silently treating a failed
request as successful. The API base URL is intentionally not hard-coded.

## Structure

- `lib/app/` – app configuration and theme
- `lib/data/models/` – visitor and visit-event JSON models
- `lib/data/repositories/` – REST API and persistent local data access
- `lib/presentation/controllers/` – GetX application state and business rules
- `lib/presentation/screens/` – dashboard, list, registration, details, scanner
- `lib/presentation/widgets/` – reusable visitor/status/empty-state widgets

GetX is used for reactive application state so list changes, status updates,
dashboard metrics, filters, and theme changes are reflected across screens
without manually passing data or rebuilding unrelated views. API and local
persistence logic stays in the repository, outside the UI.

## Included workflows

- Register/edit visitors with required-field, 10-digit mobile, and optional
  email validation.
- Search by name/mobile and filter by project/status.
- Generate a QR pass containing the server/local visitor ID and scan it using
  the device camera.
- Apply the one-visit status workflow: Registered → Checked In → Checked Out,
  with timestamps and an activity history.
- Refresh the visitor list by pull gesture or refresh action.
- Calculate dashboard statistics using the device's local date.
- Keep records and theme preference in a local cache.

Camera permission is declared for Android and the scanner displays a permission
guidance message if camera access is denied.
