# Academia360 Flutter Frontend

Flutter frontend for the Erasmus+ Academia360 project.

The running application interface is in Portuguese because it is intended for use in a Portuguese school environment. This README is written in English for documentation, repository and portfolio purposes.

---

## Purpose

This frontend supports two main workflows:

1. **Attendance punching** through NFC/RFID-style input, QR/barcode or manual entry.
2. **Automatic timetable management** through configuration screens and schedule generation.

The app is connected to the Academia360 FastAPI backend.

---

## Current Features

- Login connected to the backend.
- JWT token storage.
- Role-based dashboard navigation with a desktop sidebar and mobile drawer.
- Academia-branded splash screen and favicon.
- Administrative dashboard with quick actions, grouped submenus and project map.
- Attendance punching screen.
- Attendance dashboard and absenteeism indicators.
- Offline attendance queue with later synchronization.
- CRUD screens for:
  - users,
  - students,
  - professors,
  - courses,
  - classes,
  - disciplines,
  - rooms.
- Configuration screens for:
  - school years,
  - school calendar,
  - teacher availability,
  - discipline workload,
  - professor-discipline assignments.
- Timetable generation and export screen with:
  - readiness check,
  - dry-run preview,
  - replacement of existing schedules,
  - generation limits,
  - status selection,
  - PDF export,
  - Excel export.
- Reports, attendance views and absence justification management.
- User password creation and update flow.
- Improved error handling so forms remain open when validation fails.

---

## Branding

The app includes custom Academia-style branding:

- custom splash screen,
- custom favicon,
- custom web icons,
- white/blue visual identity,
- branded loading states,
- dashboard branding aligned with the school identity.

---

## Run Locally

Start the backend first, then run Flutter:

```powershell
cd C:\Users\GU603\Documents\GitHub\academia360_app
flutter clean
flutter pub get
flutter analyze
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

---

## Important Notes

The timetable generator depends on backend data. Before generating a timetable, make sure the selected class has:

- disciplines configured,
- teachers assigned,
- teacher availability,
- valid school days in the calendar,
- available rooms,
- practical rooms when required.

For attendance punching tests, use a student card UID from the seed database, for example:

```text
CARD001
CARD002
CARD003
```

---


## Role-Based UI

The frontend uses a central permission layer in `lib/core/permissions.dart`. The sidebar, dashboard actions and CRUD buttons adapt to the authenticated role:

- Admin: full access.
- Director: dashboards, reports, timetables and justification review.
- Secretary: students, classes, attendance and justifications.
- Professor: timetable/attendance views and manual attendance punching.

Backend authorization still remains the source of truth; hiding UI actions is only the first layer.

## Future Frontend Improvements

- Real NFC integration on mobile using `flutter_nfc_kit`.
- QR/barcode camera scanning.
- More advanced offline storage using Hive or Isar.
- Automatic sync on reconnection.
- Attendance report export UI.
