# Chiraag e Azaa — Flutter App (SQLite Edition)

All 5,130 lyrics, 196 artists, and 11 categories are stored in a bundled
**SQLite database** (`assets/chiraag_e_azaa.db`). No JSON files needed.

---

## Database Schema

```
categories   id | key | label | icon | sort_order
artists      id | category_key | name
lyrics       id | category_key | artist_id | year | title | content_html | is_rtl
lyrics_fts   FTS5 virtual table (title search)
bookmarks    lyric_id | saved_at        ← created at runtime on device
settings     key | value               ← ltr_font_size, rtl_font_size, etc.
```

---

## How Content Is Managed

### Current flow (bundled DB)
```
data.js  →  scripts/rebuild_db.py  →  assets/chiraag_e_azaa.db  →  App
```
On first launch the app copies the DB from assets to the device's private
storage directory using `sqflite`. User data (bookmarks, settings) is
written to that writable copy on device.

### Rebuilding the database when you add/update lyrics

```bash
# From the flutter_app/ directory:
python3 scripts/rebuild_db.py \
    --input  /path/to/new_data.js \
    --output assets/chiraag_e_azaa.db
```

Then bump `DB_VERSION` in both `rebuild_db.py` and `database_service.dart`
so existing users get the new DB on next launch.

---

## Setup

### 1. Install Flutter ≥ 3.0

### 2. Firebase (Push Notifications)
1. https://console.firebase.google.com → New project → "Chiraag e Azaa"
2. Add Android app (package: `com.chiraag.azaa`)
   - Download `google-services.json` → `android/app/google-services.json`
3. Add iOS app (bundle ID: `com.chiraag.azaa`)
   - Download `GoogleService-Info.plist` → `ios/Runner/GoogleService-Info.plist`
4. `android/app/build.gradle` — add at bottom: `apply plugin: 'com.google.gms.google-services'`
5. `android/build.gradle` — add in dependencies: `classpath 'com.google.gms:google-services:4.4.0'`

### 3. Arabic Fonts
Download from https://fonts.google.com and place in `assets/fonts/`:
- `NotoNaskhArabic-Regular.ttf`
- `NotoNaskhArabic-Bold.ttf`
- `Amiri-Regular.ttf`
- `Amiri-Bold.ttf`

### 4. Audio
Update the URL in `lib/widgets/audio_player_widget.dart`:
```dart
await _player.setUrl('https://yourserver.com/audio/${widget.lyricId}.mp3');
```
Or use local assets:
```dart
await _player.setAsset('assets/audio/${widget.lyricId}.mp3');
```

### 5. Run
```bash
flutter pub get
flutter run
```

---

## Project Structure

```
lib/
├── main.dart                         # Startup: copies DB, loads settings
├── theme.dart                        # Colors & AppTheme
├── models/lyric_item.dart            # Category, Artist, LyricItem, SavedManager
├── services/
│   ├── database_service.dart         # All SQLite queries (categories, lyrics, FTS, bookmarks)
│   ├── settings_service.dart         # Reads/writes settings from DB
│   └── push_service.dart             # Firebase Cloud Messaging
├── widgets/
│   ├── lyric_row.dart                # List row + SectionCard
│   └── audio_player_widget.dart      # just_audio player UI
└── screens/
    ├── home_screen.dart              # Category list (loaded from DB)
    ├── category_screen.dart          # Artists → years drill-down
    ├── lyric_list_screen.dart        # Lyrics list (DB query)
    ├── lyric_detail_screen.dart      # Lyric content + audio + bookmark
    ├── search_screen.dart            # FTS5 live search
    ├── tasbih_screen.dart            # Tasbih counter
    ├── saved_screen.dart             # Bookmarks (from DB)
    └── settings_screen.dart          # Font sliders + push toggle
scripts/
└── rebuild_db.py                     # Rebuilds DB from data.js
assets/
└── chiraag_e_azaa.db                 # Bundled SQLite DB (14 MB)
```

---

## Key DatabaseService Methods

| Method | Description |
|---|---|
| `getCategories()` | All 11 categories with item counts |
| `getArtists(categoryKey)` | Artists in a category |
| `getYearsForArtist(cat, name)` | Years for an artist |
| `getLyricsByCategory(key)` | All lyrics in a category |
| `getLyricsByArtist(key, name, year?)` | Filtered lyrics |
| `getLyricDetail(id)` | Full content HTML for one lyric |
| `search(query)` | FTS5 prefix search |
| `addBookmark(id)` / `removeBookmark(id)` | Bookmark management |
| `getBookmarks()` | All saved lyrics |
| `getSetting(key)` / `setSetting(key, val)` | Persistent settings |

---

## Updating the Database in the Field

### Option A — Ship a new app version
Bump `DB_VERSION` → rebuild → `flutter build appbundle --release`

### Option B — Remote DB update (advanced)
1. Host the new `.db` file at a URL
2. On app start, check a remote version endpoint
3. If remote version > local, download and replace the device DB

```dart
// Pseudocode for remote update
final remoteVersion = await fetchRemoteVersion();
if (remoteVersion > localVersion) {
  final bytes = await http.get(Uri.parse('https://yourserver.com/chiraag_e_azaa.db'));
  await File(dbPath).writeAsBytes(bytes.bodyBytes);
}
```

---

## Building for Release

```bash
# Android
flutter build apk --release
flutter build appbundle --release   # For Play Store

# iOS (requires Mac + Xcode)
flutter build ios --release
```
