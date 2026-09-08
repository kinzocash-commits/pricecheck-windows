# Price Checker (Windows) — ported from the Android app

This is a Flutter Windows desktop app that replicates the Android price-checker's
core behavior: scan a barcode (via a USB/serial "keyboard wedge" scanner) and
look up the price directly from your MySQL database — same query, same schema,
same approach (no separate backend server needed).

## What was recovered from the Android app

- It connects to MySQL directly from the client using the `mysql1` Dart package.
- Connection settings (host/port/user/password/database) are entered by the
  user in a Settings screen and saved locally — not hardcoded.
- The barcode lookup query joins `tbl_item_barcode` → `tbl_item` → `tbl_currency`
  on the scanned barcode value. This app uses that same query (see
  `lib/services/db_service.dart`).
- This assumes your MySQL server already has the `tbl_item`, `tbl_item_barcode`,
  `tbl_currency` tables (and the `func_get_item_cost2` function, if you want the
  extra cost/price tiers — this port only selects the tiers already exposed as
  plain columns: RetailPrice, WholesalePrice, HalfWholesalePrice, ExportPrice,
  ConsumerPrice). The customer-facing screen shows **RetailPrice**, per your choice.

## One-time setup (on your Windows dev machine)

1. Install Flutter: https://docs.flutter.dev/get-started/install/windows
2. Enable Windows desktop support:
   ```
   flutter config --enable-windows-desktop
   ```
3. Confirm it's ready:
   ```
   flutter doctor
   ```

## Get this project building

1. Copy this whole folder to your machine.
2. Generate the missing platform scaffolding (this project ships only
   `pubspec.yaml` + `lib/`, since the Windows/Linux/macOS runner folders are
   large generated boilerplate — `flutter create` regenerates them):
   ```
   flutter create --platforms=windows .
   ```
   This adds a `windows/` folder without touching your `lib/` code.
3. Install dependencies:
   ```
   flutter pub get
   ```
4. Run it (with a Windows device/emulator target — on Windows this just means
   your desktop):
   ```
   flutter run -d windows
   ```
5. Build a distributable release exe:
   ```
   flutter build windows
   ```
   The output lands in `build\windows\x64\runner\Release\` — copy that whole
   folder (the `.exe` needs its accompanying `.dll` files) to the kiosk PC.

## First run

- On first launch (no saved DB settings), it opens straight to the Settings
  screen. Enter your MySQL host, port, username, password, and database name,
  hit **Test connection**, then **Save**.
- Back on the main screen, the barcode field is auto-focused — plug in your
  USB/serial scanner and scan. Since these scanners act as a keyboard (type
  the digits, then send Enter), no special scanner SDK or driver is needed;
  it just needs that field focused, which the app maintains automatically.

## Notes / things worth double-checking against your actual DB

- The exact price tier shown, and the join logic (`it_unit_id = it_barcode_unit_id`),
  match the version of the query recovered from the binary — if your schema
  has since changed, adjust `lib/services/db_service.dart`.
- If your MySQL server isn't reachable from the kiosk network, or requires
  SSL, you'll need to adjust `ConnectionSettings` in `db_service.dart`
  (`mysql1` supports SSL — see its docs) — the Android app's binary didn't
  show any SSL-specific config, so this port doesn't enable it by default.
- Consider a firewall rule / VPN for the MySQL port (3306) if the kiosk is on
  a different network than the DB server, since this app connects straight to
  MySQL rather than through an API.
