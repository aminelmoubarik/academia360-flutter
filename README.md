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
- Attendance punching screen with USB-reader/manual input and QR/barcode camera scanning.
- Attendance dashboard, advanced filters, absenteeism indicators and PDF/Excel export actions.
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
- More advanced offline storage using Hive or Isar.
- Automatic sync on reconnection.


## Step 8 - Attendance Alerts

The attendance screen includes an absenteeism alert panel with students missing an entry punch, recurrent absences over the recent period and class-level alert summaries. The filter controls were also adjusted to avoid visual overflow on wide web screens.

## Step 9 - Improved Offline Attendance Queue

The attendance punching screen now keeps richer local queue metadata for offline records:

- local queue identifier,
- queued timestamp,
- sync attempt counter,
- last sync attempt timestamp,
- last sync error message,
- automatic retry while the terminal screen is open,
- manual discard for invalid local records.

This improves the offline workflow requested in the project brief while keeping the implementation compatible with Flutter Web.

## Step 10 - QR/Barcode Camera Scanner

The punching terminal now includes a camera scanner powered by `mobile_scanner`. It supports QR codes and common barcode formats, fills the student card/code field automatically and sets the punching method to `qr` or `barcode` depending on the detected code.

Browser camera permission is required when running on Flutter Web. Android/iOS camera permission messages were added to the platform configuration.


## Step 11 - Attendance Report Export

The attendance screen can now export the filtered register list to PDF or Excel. The export respects the active filters and search text, allowing the school to generate reports by date range, class, discipline, punch type, method and sync status.
