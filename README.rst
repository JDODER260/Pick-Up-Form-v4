==============================
Pick Up Form — V4
==============================

Pick Up & Delivery App for Double R Sharpening (Flutter)

This mobile app (v4) is a cross-platform Flutter application that manages pickup forms and delivery receipts. It works offline—data is stored locally in JSON files so the app retains settings, routes, deliveries, and PO data across app restarts.

How to download
===============
Navigate to the project's Releases page and download the latest signed
Android package (APK or AAB) or the source code.

Each release includes an official signed APK. Only official release
builds are permitted for use.


Pick Up & Delivery App
======================
Mobile app for Double R Sharpening to manage pick up forms and delivery receipts.


License and Usage Restrictions
==============================
This project is proprietary software.

You may install and use the app exactly as provided for personal use only.
Business, organizational, or professional use is not permitted without a
paid license.

You may not modify, reuse, redistribute, or incorporate any portion of the
source code into other applications.


Signed Releases
===============
Each official release includes a cryptographically signed APK generated
by the author.

- Signed APKs verify authenticity and integrity
- Modified or rebuilt APKs are not authorized
- Business use of any release requires a paid license


Features
--------
- Delivery Mode: View deliveries by route and generate PDF receipts
- Pickup Mode: Create, save, and upload pick up forms
- PDF Generation: Generate and auto-save receipts to organized folders
- Company Database: Store frequent customers and blade types locally
- Offline-first: All core data saved locally as JSON files
- Update Checking: Optional check for remote updates

How to use
----------
Delivery Mode
^^^^^^^^^^^^^
1. Select your route from the dropdown.
2. Tap "Download Route" to fetch route/delivery data (if online).
3. Navigate deliveries with Previous/Next.
4. Tap "Print Receipt" to generate a PDF; files are auto-saved.

Pickup Mode
^^^^^^^^^^^
1. Select route and company.
2. Tap "Add New" to create a pick up form.
3. Enter description, quantity, and services.
4. Tap "Upload" to send to server when online.

Settings
^^^^^^^^
- Change app mode (Delivery/Pickup)
- Configure API URLs
- Manage company database entries
- Check for updates and app version

Local data files
----------------
To ensure offline reliability, this app stores data as JSON files in the app's documents directory (use the platform's app documents folder / files directory). The app uses path_provider to find the proper location. The following files are used:

- `po_data.json` — saved pickup order (PO) data
- `app_settings.json` — user settings and preferences
- `company_database.json` — saved company/customer database
- `delivery_data.json` — downloaded delivery data for routes
- `route_order_data.json` — route order definitions and metadata
- `route_order_cache.json` — temporary cache for route orders

Files are written/read from the device storage so closing and reopening the app preserves state.

PDF receipt format
------------------
- Company header with contact info
- Delivery details table (address, contact, date)
- Blade information (Qty, Description, Services)
- Signature section
- PDFs are auto-saved organized by route and date (e.g., `Download/PickUpForms/{Route}/{Date}/`)

API requirements
----------------
Example endpoints used by the app (replace with your server URLs):
- Upload PO: `https://doublersharpening.com/api/upload_po/`
- Company DB: `https://doublersharpening.com/api/company_db/`
- Delivery API: `https://doublersharpening.com/api/delivery_pos/`

Authentication and headers are project-specific; configure in Settings.

Project structure (high level)
------------------------------
- `lib/` — main Flutter code (screens, models, providers, services, widgets)
- `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` — platform folders
- `assets/` — icons, fonts, other static assets
- `test/` — unit/widget tests

Building the app (Flutter)
--------------------------
Prerequisites: Install Flutter SDK (stable channel) and platform toolchains.

Debug (run on connected device or emulator):

flutter pub get; flutter run

Build APK (release):

flutter pub get; flutter build apk --release

Build App Bundle (AAB):

flutter pub get; flutter build appbundle --release

Note: For Android signing, configure `android/key.properties` and signingConfigs in the `android` gradle files.

Creating the APK (reference structure)
-------------------------------------
After building, Android outputs appear under `build/app/outputs/apk/` or `build/app/outputs/bundle/` for AABs.

Requirements
------------
- Flutter SDK (stable channel)
- Recommended packages: `path_provider`, `provider`, `http`, `pdf` (or `printing`) — check `pubspec.yaml` for exact dependencies.

All descriptions in this README were adapted from a prior app description; verify release details and endpoints before publishing.

Acknowledgements
----------------
This project is a Flutter rewrite of an earlier app. If you want to contribute or improve features (for example: richer local sync, encryption of stored files, or background download), open an issue or PR.

Changelog
---------
- 4.0.0 — Flutter cross-platform rewrite; local JSON storage for offline use.

License
=======
This project is proprietary software.

Personal use of the app in its original, unmodified form is permitted.
Business, organizational, or professional use is prohibited without a
paid license.

See the LICENSE file for full terms.
