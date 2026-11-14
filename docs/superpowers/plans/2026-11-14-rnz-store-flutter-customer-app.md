# RnZ Store Flutter Customer App — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a fully runnable Flutter customer app for RnZ Store with local persistence, covering US-01–22 from the PRD.

**Architecture:** Feature-first Flutter app with Provider `ChangeNotifier` controllers over repositories, a `LocalStore` backed by `SharedPreferences` JSON, and `go_router` for guarded navigation. No backend; admin verification is simulated in a demo panel.

**Tech Stack:** Flutter 3.47 / Dart 3.13, provider, go_router, shared_preferences, intl, crypto, image_picker, url_launcher, flutter_localizations.

**Spec:** `docs/superpowers/specs/2026-11-14-rnz-store-flutter-customer-app-design.md`

## Global Constraints

- All money is `int` rupiah; display as `Rp 1.250.000`.
- All user-facing copy is Indonesian. Dates: `14 Nov 2026, 14.30 WIB`.
- No network calls at runtime; product images and fonts are bundled assets.
- Passwords are stored only as SHA-256 + random salt; never displayed or logged.
- One local user session at a time; session persists in prefs until logout.
- Stock never negative; a failed checkout changes nothing.
- Order status final states: `Selesai`, `Dibatalkan`.
- Auth-required routes: `/cart`, `/checkout`, `/addresses*`, `/orders*`, `/profile*`, `/change-password`, `/delete-account`.
- Minimum tap target 48 dp; text contrast ≥ 4.5:1; text scale up to 200% must not overflow.
- `flutter analyze` must report zero issues; `flutter test` must pass.
- Demo-only admin actions must be visibly labeled "Mode Demo".

## Review Focus

1. **Insufficient stock in one of several cart lines** — checkout must fail atomically, keep the cart, and show which lines are short (Task 9).
2. **Double-submitted checkout** — the same idempotency key must return the existing order and decrement stock once (Task 9).
3. **Time-based transitions after restart** — overdue orders cancel and shipped orders complete using an injected clock (Task 10).
4. **Corrupt local JSON** — startup must show recovery, never crash (Task 4 and Task 18).
5. **Guest redirect return path + 200% text scale** — login returns to the intended private route and key screens do not overflow (Tasks 12/13/18).

---

### Task 1: Scaffold, dependencies, fonts, and product images

**Files:**
- Create: Flutter scaffold (`pubspec.yaml`, `analysis_options.yaml`, `lib/main.dart`, platform dirs)
- Create: `assets/fonts/Fraunces.ttf`, `assets/fonts/Manrope.ttf`
- Create: `assets/images/products/rnz_01.jpg` … `rnz_14.jpg`
- Create: `assets/images/CREDITS.md`
- Create: `lib/core/app_theme.dart`, `lib/core/constants.dart`, `lib/core/ids.dart`

**Interfaces:**
- Produces: `AppTheme.light` (`ThemeData`), `AppColors` constants, `AppSpacing`, `AppRadius`, `newId([String prefix])`.
- Asset paths are fixed: `assets/images/products/rnz_01.jpg` … `rnz_14.jpg`.

- [ ] **Step 1: Scaffold the project**

Run in the repo root:

```powershell
flutter create --project-name rnz_store --org com.rnzstore --platforms=android,ios,web .
flutter pub add provider go_router shared_preferences intl crypto image_picker url_launcher
flutter pub add flutter_localizations --sdk=flutter
```

Expected: `flutter pub get` succeeds and `lib/main.dart` exists.

- [ ] **Step 2: Download bundled fonts**

```powershell
New-Item -ItemType Directory -Force assets/fonts | Out-Null
Invoke-WebRequest -UseBasicParsing 'https://github.com/google/fonts/raw/main/ofl/fraunces/Fraunces%5BSOFT%2CWONK%2Copsz%2Cwght%5D.ttf' -OutFile 'assets/fonts/Fraunces.ttf'
Invoke-WebRequest -UseBasicParsing 'https://github.com/google/fonts/raw/main/ofl/manrope/Manrope%5Bwght%5D.ttf' -OutFile 'assets/fonts/Manrope.ttf'
```

Expected: both files > 100 KB.

- [ ] **Step 3: Download and normalize 14 product images**

Resolve each Openverse ID with `https://api.openverse.org/v1/images/{id}/`, download `url`, resize to max 1200 px on the long side, and save as `rnz_NN.jpg`. IDs in order:

```text
01 3e5a26b2-2508-4a23-8cec-c77813056762  Hijab portrait / Ferian-pz / CC BY 2.0
02 aaba667b-0d6b-4dac-9ccf-35ba4852cd8f  Nur Amirah / emannyahaya / CC BY 2.0
03 8b2178c9-b662-4a90-a868-ac69af08ae80  Iranian Beauty / Hamed Saber / CC BY 2.0
04 76dbfe7a-9e81-4ef2-9db4-4c2526425f28  Abaya / denn / CC BY-SA 2.0
05 58cba64f-55aa-4081-adbc-4fb44d33f6bd  Abaya fashions / Lars Plougmann / CC BY-SA 2.0
06 5fc6ae6c-a036-486e-93e4-3a85eba22427  silk scarf / DU Jenny / CC BY-SA 2.0
07 d7d8e9ba-ef56-460c-b970-45d5890a168a  Sari Scarf Fabric / CC0 1.0
08 556d0d0f-3377-400c-b7ab-043cc249b5fd  Beautiful Girl in Hijab / tim-johnson / CC BY 2.0
09 9e64f67e-064e-4384-8a2e-bf915af36168  Pashmina style / PhMaury / CC BY-SA 2.0
10 0ac1c34a-783f-4e6b-a14c-5d6884978d1c  pashminas udaipur / liketearsintherain / CC BY-SA 2.0
11 cafd684a-428f-48e9-89a7-827a9d50a92a  Muslim fashion / dalecruse / CC BY 2.0
12 5e14185d-0796-46e8-a414-bf9b7bfbb475  2 Pack of Pashminas / bsabarnowl / CC BY 2.0
13 704e9d1d-ebe7-42ff-abfe-b2d05ab57f8b  Chaperone / colinlogan / CC BY-SA 2.0
14 1aacc53e-dbc3-481f-a63d-a91f64c21dcf  three abayas / Ranoush. / CC BY-SA 2.0
```

Expected: 14 JPEG files; each opens and is at most 1200 px on the long side.

- [ ] **Step 4: Write `assets/images/CREDITS.md`**

One line per image with: file, title, creator, license, and source URL. Include the font licenses (Fraunces OFL, Manrope OFL) with links to the Google Fonts repositories.

- [ ] **Step 5: Declare assets and fonts in `pubspec.yaml`**

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/products/
  fonts:
    - family: Fraunces
      fonts:
        - asset: assets/fonts/Fraunces.ttf
    - family: Manrope
      fonts:
        - asset: assets/fonts/Manrope.ttf
```

- [ ] **Step 6: Write theme tokens**

`AppColors`: `ivory 0xFFF7F2E9`, `surface 0xFFFFFCF6`, `forest 0xFF223A2D`, `terracotta 0xFFC06B4E`, `ink 0xFF1B1A17`, `muted 0xFF6F6A60`, `line 0xFFE3DACB`, `success 0xFF3D6B4F`, `danger 0xFFA84532`, `warning 0xFFB07A2A`.
`AppTheme.light` must use Material 3, Manrope body, Fraunces display, 20 dp horizontal page padding, 4/8/12/16/24/32 spacing, and 4/12/999 radii.

- [ ] **Step 7: Run checks**

Delete the generated counter test `test/widget_test.dart` (it references the removed counter app). Run: `flutter pub get; flutter analyze`
Expected: no errors.

- [ ] **Step 8: Commit**

```bash
git add pubspec.yaml pubspec.lock assets lib/main.dart lib/core analysis_options.yaml android ios web
git commit -m "chore: scaffold Flutter project with theme and bundled assets"
```

---

### Task 2: Core result type, formatters, validators, password hashing

**Files:**
- Create: `lib/core/result.dart`, `lib/core/formatters.dart`, `lib/core/validators.dart`, `lib/core/password_hasher.dart`
- Test: `test/core/core_test.dart`

**Interfaces:**
- Produces:
  - `AppError({required String code, required String message, Map<String,String> fields})`
  - `AppResult<T>.ok(T value)`, `AppResult<T>.fail(AppError error)`, `bool get isOk`, `T? get value`, `AppError? get error`
  - `String formatRupiah(int amount)`, `String formatDateWib(DateTime value)`, `String formatShortDate(DateTime value)`, `String formatCountdown(Duration value)`
  - `Validators.required`, `.name`, `.email`, `.phone`, `.password`, `.confirmPassword`, `.postalCode`
  - `PasswordHasher.newSalt()`, `.hash(String password, String salt)`, `.verify(String password, String salt, String hash)`

- [ ] **Step 1: Write failing tests**

In `test/core/core_test.dart`, import `package:intl/date_symbol_data_local.dart`, add `setUpAll(() async { await initializeDateFormatting('id_ID'); });`, then:

```dart
test('formatRupiah uses Indonesian thousands', () {
  expect(formatRupiah(1250000), 'Rp 1.250.000');
});
test('formatDateWib uses Indonesian month and WIB', () {
  expect(formatDateWib(DateTime(2026, 11, 14, 14, 30)), '14 Nov 2026, 14.30 WIB');
});
test('validators accept Indonesian phone variants', () {
  expect(Validators.phone('081234567890'), isNull);
  expect(Validators.phone('+6281234567890'), isNull);
  expect(Validators.phone('12345'), isNotNull);
});
test('password requires 8 chars, a letter, and a digit', () {
  expect(Validators.password('Hijab1234'), isNull);
  expect(Validators.password('hijabbbb'), isNotNull);
  expect(Validators.password('12345678'), isNotNull);
});
test('password hasher verifies only the right password', () {
  final salt = PasswordHasher.newSalt();
  final hash = PasswordHasher.hash('Hijab1234', salt);
  expect(PasswordHasher.verify('Hijab1234', salt, hash), isTrue);
  expect(PasswordHasher.verify('Wrong1234', salt, hash), isFalse);
});
test('AppResult failure keeps field errors', () {
  final r = AppResult<int>.fail(const AppError(code: 'validation', message: 'x', fields: {'email': 'Terdaftar'}));
  expect(r.isOk, isFalse);
  expect(r.error!.fields['email'], 'Terdaftar');
});
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/core/core_test.dart`
Expected: FAIL because the core files do not exist.

- [ ] **Step 3: Implement the core utilities**

- `formatRupiah` uses `NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)`.
- `formatDateWib` uses `DateFormat('d MMM yyyy, HH.mm', 'id_ID')` plus ` WIB`; `formatShortDate` uses `d MMM yyyy`.
- Phone validation strips spaces/dashes, converts `+62` to `0`, then accepts `^08[0-9]{7,13}$` (9–15 digits).
- Email is trimmed and lowercased before validation; regex `^[^@\s]+@[^@\s]+\.[^@\s]+$`.
- Password requires ≥8 chars, at least one letter and one digit.
- Postal code requires exactly 5 digits.
- `PasswordHasher.hash` is `sha256('$salt:$password')`; salt is 16 random bytes in base64Url.

- [ ] **Step 4: Run tests**

Run: `flutter test test/core/core_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core test/core
git commit -m "feat: add core result, formatters, validators, and password hashing"
```

---

### Task 3: Data models and JSON round-trip

**Files:**
- Create: `lib/data/models/user.dart`, `address.dart`, `catalog.dart`, `cart.dart`, `order.dart`, `master.dart`
- Test: `test/data/models_test.dart`

**Interfaces:**
- Produces models (all immutable with `toJson`, `fromJson`, and `copyWith` where mutation is needed):
  - `User(id, name, email, phone, passwordHash, passwordSalt, role, status, deletedAt, createdAt)`
  - `Address(id, userId, label, recipientName, recipientPhone, province, city, district, addressLine, postalCode, isDefault)` plus `AddressDraft(label, recipientName, recipientPhone, province, city, district, addressLine, postalCode)`
  - `Category(id, name, slug, isActive)`
  - `Product(id, categoryId, name, description, price, isActive, deletedAt, images, variants, createdAt)`, `int get totalStock`
  - `ProductVariant(id, productId, color, size, sku, stock, isActive)`, `String get label`
  - `PagedProducts(items, total, page, perPage)`, `bool get hasMore`
  - `CartItem(variantId, qty)`, `CartLine(product, variant, qty)`, `int get lineTotal`
  - `PaymentMethod(id, type, provider, accountNo, accountName, isActive, sortOrder)`, enum `PaymentType.bank|ewallet`
  - `ShippingRate(id, regionName, cost, isActive)`
  - `OrderStatus.awaitingPayment|paymentVerification|processing|shipped|completed|cancelled` with `label` and `isFinal`
  - `Order(...)`, `OrderItem(...)`, `PaymentProof(...)`, `PaymentProofStatus.pending|approved|rejected`, `Shipment(...)`, `StatusLog(...)`, `ActorType.customer|admin|system`
  - `CheckoutSummary(lines, subtotal, shippingCost, shippingNote, total)`

- [ ] **Step 1: Write failing round-trip tests**

```dart
test('product round-trips and sums stock', () {
  final p = Product(/* full fixture with two variants: 2 and 3 stock */);
  final copy = Product.fromJson(p.toJson());
  expect(copy.name, p.name);
  expect(copy.totalStock, 5);
});
test('order round-trips nested items and logs', () {
  final o = Order(/* fixture with 1 item and 1 status log */);
  final copy = Order.fromJson(o.toJson());
  expect(copy.items.single.productName, o.items.single.productName);
  expect(copy.statusLogs.single.toStatus, OrderStatus.awaitingPayment);
});
test('status labels are Indonesian', () {
  expect(OrderStatus.awaitingPayment.label, 'Menunggu Pembayaran');
  expect(OrderStatus.paymentVerification.label, 'Verifikasi Pembayaran');
  expect(OrderStatus.cancelled.isFinal, isTrue);
});
test('variant label joins color and size', () {
  expect(const ProductVariant(/* Sage, M */).label, 'Sage / M');
  expect(const ProductVariant(/* Sage, null */).label, 'Sage');
});
```

Use a shared fixture file `test/fixtures.dart` for sample products/orders so later tests reuse it.

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/data/models_test.dart`
Expected: FAIL (models missing).

- [ ] **Step 3: Implement models**

Rules:
- Dates serialize with `toIso8601String()` and parse with `DateTime.parse`.
- `PaymentType` serializes as `bank`/`ewallet`; statuses serialize as camelCase string names.
- `OrderStatus.fromJson` throws `FormatException` on unknown values.
- `Product.totalStock` sums only `isActive` variants.
- `CartLine.lineTotal` is `product.price * qty`.
- `Order` includes `latestRejectReason`, `completedAt`, `shippedAt` getter from `shipment`.

- [ ] **Step 4: Run tests**

Run: `flutter test test/data/models_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/models test/data/models_test.dart test/fixtures.dart
git commit -m "feat: add data models with JSON serialization"
```

---

### Task 4: LocalStore and seed data

**Files:**
- Create: `lib/data/local_store.dart`, `lib/data/seed_data.dart`
- Test: `test/data/local_store_test.dart`

**Interfaces:**
- Produces:
  - `class StoreCorruptException implements Exception`
  - `LocalStore.open()`, `List<dynamic> list(String key)`, `Map<String,dynamic> map(String key)`, `String? string(String key)`, `bool flag(String key)`
  - `Future<void> write(String key, Object? value)`, `remove`, `clearAll`
  - `bool get onboardingSeen`, `Future<void> setOnboardingSeen()`
  - `String? get sessionUserId`, `Future<void> setSessionUserId(String? id)`
  - `String? proof(String key)`, `Future<void> setProof(String key, String dataUrl)`, `Future<void> removeProof(String key)`
  - `Future<void> seedIfNeeded()`
  - `SeedData.run(LocalStore)` and `SeedData.demoEmail = 'nadia@rnzstore.id'`, `demoPassword = 'Hijab1234'`

- [ ] **Step 1: Write failing tests with mocked prefs**

```dart
setUp(() => SharedPreferences.setMockInitialValues({}));
test('seed creates demo account and catalog once', () async {
  final store = await LocalStore.open();
  await store.seedIfNeeded();
  await store.seedIfNeeded();
  expect(store.list('users').length, 1);
  expect(store.list('categories').length, 5);
  expect(store.list('products').length, 21);
  final user = User.fromJson(store.list('users').single as Map<String, dynamic>);
  expect(PasswordHasher.verify('Hijab1234', user.passwordSalt, user.passwordHash), isTrue);
});
test('seed includes 4 payment methods, 4 shipping rates, and 2 demo orders', () async {
  final store = await LocalStore.open();
  await store.seedIfNeeded();
  expect(store.list('payment_methods').length, 4);
  expect(store.list('shipping_rates').length, 4);
  expect(store.list('orders').length, 2);
});
test('corrupt JSON throws StoreCorruptException', () async {
  SharedPreferences.setMockInitialValues({'rnz.v1.products': '{not json'});
  final store = await LocalStore.open();
  expect(() => store.list('products'), throwsA(isA<StoreCorruptException>()));
});
test('clearAll removes every rnz key but keeps foreign keys', () async {
  SharedPreferences.setMockInitialValues({'other': 'keep'});
  final store = await LocalStore.open();
  await store.write('products', []);
  await store.clearAll();
  expect(store.list('products'), isEmpty);
  final prefs = await SharedPreferences.getInstance();
  expect(prefs.getString('other'), 'keep');
});
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/data/local_store_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `LocalStore`**

- Keys are prefixed `rnz.v1.`.
- `list`/`map` decode JSON and throw `StoreCorruptException` on `FormatException`.
- Writes are awaited; `clearAll` removes only keys starting with the prefix.
- `seedIfNeeded` checks `seed_version == '1'`; if absent, writes all seed collections (users, addresses, categories, products, cart, orders, payment_methods, shipping_rates) and sets the version.
- Never overwrite existing user/order data when the version already matches.

- [ ] **Step 4: Implement seed data**

- Demo user `Nadia Putri`, email `nadia@rnzstore.id`, phone `081234567890`, password `Hijab1234`; 2 addresses (one default).
- 5 categories: Hijab Segiempat, Pashmina, Dalaman, Gamis/Set Koko, Aksesori.
- 20 active products + 1 inactive. Assign images `rnz_01`…`rnz_14` round-robin; 2–6 variants per product; prices 35.000–325.000; some variant stock 0 and one product fully out of stock.
- 4 payment methods: BCA, Mandiri (active banks), DANA (active e-wallet), OVO (inactive).
- 4 rates: Pontianak 15000, Kubu Raya 18000, Mempawah 25000, Singkawang 30000.
- 2 demo orders for Nadia: one `shipped` with JNE resi, one `completed`; include status logs and snapshots. Do not decrement seed stock for these demo orders.

- [ ] **Step 5: Run tests**

Run: `flutter test test/data/local_store_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/data/local_store.dart lib/data/seed_data.dart test/data/local_store_test.dart
git commit -m "feat: add local store and seed catalog"
```

---

### Task 5: Authentication repository

**Files:**
- Create: `lib/data/repositories/auth_repository.dart`
- Test: `test/data/auth_repository_test.dart`

**Interfaces:**
- Consumes: `LocalStore`, `User`, `AddressDraft`, `PasswordHasher`, `AppResult`.
- Produces:
  - `AuthRepository(LocalStore store)`
  - `User? currentUser()`, `List<Address> addressesFor(String userId)`
  - `Future<AppResult<User>> register({required String name, required String email, required String phone, required String password, required AddressDraft address, DateTime? now})`
  - `Future<AppResult<User>> login({required String email, required String password, DateTime? now})`
  - `Future<void> logout()`
  - `Future<AppResult<String?>> requestResetCode(String email, {DateTime? now})` — returns the code only for demo display; `null` value when the email is unknown
  - `Future<AppResult<void>> resetPassword({required String email, required String code, required String newPassword, DateTime? now})`

- [ ] **Step 1: Write failing tests**

```dart
test('register creates a hashed user, default address, and session', () async {
  final result = await repo.register(name: 'Aisyah', email: 'AISYAH@example.com', phone: '+628111222333', password: 'Hijab1234', address: draft);
  expect(result.isOk, isTrue);
  expect(store.sessionUserId, result.value!.id);
  expect(result.value!.email, 'aisyah@example.com');
  expect(PasswordHasher.verify('Hijab1234', result.value!.passwordSalt, result.value!.passwordHash), isTrue);
  expect(repo.addressesFor(result.value!.id).single.isDefault, isTrue);
});
test('register rejects duplicate email case-insensitively and duplicate phone', ...);
test('five failed logins lock the account for 15 minutes', () async {
  for (var i = 0; i < 5; i++) { await repo.login(email: demoEmail, password: 'Wrong1234', now: t0); }
  final locked = await repo.login(email: demoEmail, password: 'Hijab1234', now: t0.add(const Duration(minutes: 5)));
  expect(locked.error!.code, 'locked');
  final ok = await repo.login(email: demoEmail, password: 'Hijab1234', now: t0.add(const Duration(minutes: 16)));
  expect(ok.isOk, isTrue);
});
test('reset code expires after 30 minutes and is single use', () async {
  final code = (await repo.requestResetCode(demoEmail, now: t0)).value!;
  expect(code, matches(RegExp(r'^\d{6}$')));
  expect((await repo.resetPassword(email: demoEmail, code: code, newPassword: 'Baru1234', now: t0.add(const Duration(minutes: 31)))).error!.code, 'expired');
  ...
});
test('unknown email returns ok with null code and a generic message', ...);
test('logout clears the session', ...);
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/data/auth_repository_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement the repository**

Rules:
- Normalize email to lowercase/trim and phone to `0` prefix before uniqueness checks.
- Register validates all fields; duplicates return `fields` errors with specific Indonesian messages.
- Login failures increment `login_attempts`; at 5 set `lockedUntil = now + 15 min`; lockout returns `code: 'locked'` with remaining minutes; success clears the attempt.
- `requestResetCode`: always `AppResult.ok(null)` for unknown email; for known email generate 6 digits, store `codeHash` + salt + expiry 30 min + `usedAt: null`, return the code.
- `resetPassword`: reject wrong/expired/used with codes `invalid_code`/`expired`/`used`; update hash; mark used; clear session if same user.

- [ ] **Step 4: Run tests**

Run: `flutter test test/data/auth_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/auth_repository.dart test/data/auth_repository_test.dart
git commit -m "feat: add local authentication repository"
```

---

### Task 6: Profile, addresses, and account deletion

**Files:**
- Create: `lib/data/repositories/profile_repository.dart`
- Test: `test/data/profile_repository_test.dart`

**Interfaces:**
- Produces:
  - `ProfileRepository(LocalStore store)`
  - `User? currentUser()`
  - `Future<AppResult<User>> updateProfile({required String name, required String phone})`
  - `Future<AppResult<void>> changePassword({required String currentPassword, required String newPassword})`
  - `Future<AppResult<void>> deleteAccount({required String password, DateTime? now})`
  - `List<Address> addresses(String userId)`, `Address? defaultAddress(String userId)`, `Address? addressById(String userId, String id)`
  - `Future<AppResult<Address>> addAddress(String userId, AddressDraft draft)`
  - `Future<AppResult<Address>> updateAddress(String userId, Address address)`
  - `Future<AppResult<void>> deleteAddress(String userId, String id)`
  - `Future<AppResult<void>> setDefaultAddress(String userId, String id)`

- [ ] **Step 1: Write failing tests**

```dart
test('first address becomes default and the sixth is rejected', ...);
test('deleting the default promotes another address', ...);
test('changing password requires the current password', ...);
test('delete account is blocked while an order is active', ...);
test('delete account anonymizes the user, addresses, and order snapshots', () async {
  final r = await profile.deleteAccount(password: 'Hijab1234', now: t0);
  expect(r.isOk, isTrue);
  expect(store.sessionUserId, isNull);
  final user = User.fromJson(store.list('users').first as Map<String, dynamic>);
  expect(user.name, 'Pelanggan');
  expect(user.status, 'deleted');
  expect(store.list('addresses'), isEmpty);
  final order = Order.fromJson(store.list('orders').first as Map<String, dynamic>);
  expect(order.addressSnapshot['recipientName'], 'Dianonimkan');
});
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/data/profile_repository_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement the repository**

Rules:
- Phone uniqueness on profile update uses the normalized phone of other users.
- Addresses cap at 5; the first is default; `setDefaultAddress` clears other defaults.
- Deleting an address that is default promotes the first remaining (if any).
- `deleteAccount`: reject with `code: 'active_orders'` if any order is not `isFinal`; otherwise anonymize user (name `Pelanggan`, email `deleted-<id>@rnz.local`, phone `deleted-<id>`, empty hash/salt, status `deleted`, `deletedAt`), delete addresses, replace each order's `addressSnapshot` recipient/contact/address values with `Dianonimkan`, clear session.
- Keep order totals/items/logs intact.

- [ ] **Step 4: Run tests**

Run: `flutter test test/data/profile_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/profile_repository.dart test/data/profile_repository_test.dart
git commit -m "feat: add profile and address management"
```

---

### Task 7: Catalog repository

**Files:**
- Create: `lib/data/repositories/catalog_repository.dart`
- Test: `test/data/catalog_repository_test.dart`

**Interfaces:**
- Produces:
  - `CatalogRepository(LocalStore store)`
  - `List<Category> categories({bool activeOnly = true})`
  - `PagedProducts search({String query = '', String? categoryId, int page = 1, int perPage = 20})`
  - `Product? productById(String id)`, `ProductVariant? variantById(String id)`
  - `List<Product> allActive()`

- [ ] **Step 1: Write failing tests**

```dart
test('search is case-insensitive and matches partial words', () {
  expect(repo.search(query: 'pash').items.map((p) => p.name), everyElement(contains('Pashmina')));
});
test('category filter combines with query and counts results', ...);
test('inactive products are never listed', ...);
test('pagination returns perPage items and hasMore', () {
  final p1 = repo.search(page: 1, perPage: 5);
  expect(p1.items.length, 5);
  expect(p1.hasMore, isTrue);
  final p2 = repo.search(page: 2, perPage: 5);
  expect(p2.items.first.id, isNot(p1.items.first.id));
});
test('productById returns variants and total stock', ...);
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/data/catalog_repository_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement search**

- Exclude inactive/deleted products and products whose category is inactive.
- Filter query on lowercased `name.contains`.
- Sort by `createdAt` descending, then name.
- Pagination is 1-based; `total` is the filtered count; `hasMore = page * perPage < total`.

- [ ] **Step 4: Run tests**

Run: `flutter test test/data/catalog_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/catalog_repository.dart test/data/catalog_repository_test.dart
git commit -m "feat: add catalog search and pagination"
```

---

### Task 8: Cart repository

**Files:**
- Create: `lib/data/repositories/cart_repository.dart`
- Test: `test/data/cart_repository_test.dart`

**Interfaces:**
- Produces:
  - `CartRepository(LocalStore store, CatalogRepository catalog)`
  - `List<CartLine> lines(String userId)`, `List<String> reconcile(String userId)`
  - `AppResult<void> add(String userId, String variantId, {int qty = 1})`
  - `AppResult<void> setQty(String userId, String variantId, int qty)`
  - `Future<void> remove(String userId, String variantId)`, `Future<void> clear(String userId)`
  - `int itemCount(String userId)`, `int subtotal(String userId)`

- [ ] **Step 1: Write failing tests**

```dart
test('adding the same variant merges quantities', ...);
test('adding beyond stock fails with "Stok tersisa N"', ...);
test('setQty below 1 fails and above stock clamps through failure', ...);
test('remove and clear update the count and subtotal', ...);
test('reconcile clamps quantities and removes zero-stock lines with warnings', () async {
  // seed cart qty 99 for a variant with stock 3
  final warnings = cart.reconcile(userId);
  expect(cart.lines(userId).single.qty, 3);
  expect(warnings.single, contains('Stok'));
});
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/data/cart_repository_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement the repository**

Rules:
- Cart is stored per `userId`; missing cart returns empty.
- `add` rejects inactive product/variant, qty < 1, and resulting qty > stock with `fields: {variantId: 'Stok tersisa N'}`.
- `setQty` enforces 1..stock.
- `lines` resolves current product price and variant stock; skip missing variants.
- `reconcile` clamps >stock, removes stock 0, and returns Indonesian warnings; persists only if changed.

- [ ] **Step 4: Run tests**

Run: `flutter test test/data/cart_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/cart_repository.dart test/data/cart_repository_test.dart
git commit -m "feat: add cart repository with stock reconciliation"
```

---

### Task 9: Checkout summary and order creation

**Files:**
- Create: `lib/data/repositories/checkout_repository.dart`, `lib/data/repositories/order_repository.dart`
- Test: `test/data/checkout_order_test.dart`

**Interfaces:**
- Produces:
  - `CheckoutRepository(LocalStore store, CartRepository cart, CatalogRepository catalog)`
  - `List<PaymentMethod> activePaymentMethods()`, `PaymentMethod? paymentMethodById(String id)`
  - `ShippingRate? rateForCity(String city)`
  - `CheckoutSummary summary({required String userId, required Address address})`
  - `OrderRepository(LocalStore store, CartRepository cart, ProfileRepository profile, CheckoutRepository checkout)`
  - `Future<AppResult<Order>> createOrder({required String userId, required String addressId, required String paymentMethodId, required String idempotencyKey, DateTime? now})`
  - `List<Order> ordersFor(String userId, {OrderStatus? status})`, `Order? orderById(String orderId, String userId)`

- [ ] **Step 1: Write failing tests**

```dart
test('summary uses the city rate and falls back to admin confirmation', ...);
test('createOrder snapshots items/address/payment, decrements stock, clears cart', () async {
  final result = await orders.createOrder(userId: userId, addressId: addressId, paymentMethodId: pmId, idempotencyKey: 'k1', now: t0);
  final order = result.value!;
  expect(order.orderNo, matches(RegExp(r'^RNZ-\d{6}-\d{4}$')));
  expect(order.total, order.subtotal + order.shippingCost);
  expect(order.payBefore, t0.add(const Duration(hours: 24)));
  expect(order.items.single.productName, isNotEmpty);
  expect(cart.lines(userId), isEmpty);
  expect(variantById(order.items.single.variantId)!.stock, stockBefore - order.items.single.qty);
});
test('insufficient stock fails atomically and names short lines', () async {
  final before = stockOf(v);
  final r = await orders.createOrder(/* qty 99 via manipulated stock */);
  expect(r.error!.fields.keys, contains(variantId));
  expect(stockOf(v), before);
  expect(cart.lines(userId), isNotEmpty);
  expect(orders.ordersFor(userId), isEmpty);
});
test('same idempotency key returns the same order and decrements once', () async {
  final a = await orders.createOrder(..., idempotencyKey: 'same');
  final b = await orders.createOrder(..., idempotencyKey: 'same');
  expect(b.value!.id, a.value!.id);
  expect(stockOf(v), stockBefore - qty);
});
test('order numbers increment per day', ...);
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/data/checkout_order_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement checkout summary**

- Active payment methods sorted by `sortOrder`.
- Rate lookup is case-insensitive on trimmed city; unknown city → `shippingCost = 0`, `shippingNote = 'Ongkir dikonfirmasi admin'`.
- Summary totals come from current catalog prices.

- [ ] **Step 4: Implement `createOrder`**

Order of operations:
1. Return existing order if `userId + idempotencyKey` exists.
2. Validate address belongs to user and payment method is active.
3. Load cart lines; fail `empty_cart` if empty.
4. Validate every line against current stock. On any shortage, return `AppError(code: 'stock', fields: {variantId: 'Stok tersisa N'})` without mutation.
5. Compute subtotal/shipping/total.
6. Generate `RNZ-yyMMdd-NNNN`, using count of orders with the same date prefix + 1, incrementing until unique.
7. Decrement stock for all lines; write products.
8. Build snapshots and order items; write order with status `awaitingPayment`, one log.
9. Clear cart.
10. Return the order.

- [ ] **Step 5: Run tests**

Run: `flutter test test/data/checkout_order_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/data/repositories/checkout_repository.dart lib/data/repositories/order_repository.dart test/data/checkout_order_test.dart
git commit -m "feat: add checkout summary and atomic order creation"
```

---

### Task 10: Order lifecycle, payment proof, and timed transitions

**Files:**
- Modify: `lib/data/repositories/order_repository.dart`
- Test: `test/data/order_lifecycle_test.dart`

**Interfaces:**
- Produces on `OrderRepository`:
  - `Future<void> applyTimeBasedTransitions({DateTime? now})`
  - `Future<AppResult<void>> uploadProof({required String orderId, required String userId, required Uint8List bytes, required String fileName, DateTime? now})`
  - `Future<AppResult<void>> cancelByCustomer({required String orderId, required String userId, DateTime? now})`
  - `Future<AppResult<void>> completeByCustomer({required String orderId, required String userId, DateTime? now})`
  - `Future<AppResult<void>> adminApprovePayment({required String orderId, DateTime? now})`
  - `Future<AppResult<void>> adminRejectPayment({required String orderId, required String reason, DateTime? now})`
  - `Future<AppResult<void>> adminShip({required String orderId, required String courier, required String trackingNo, DateTime? now})`
  - `Future<AppResult<void>> adminCancel({required String orderId, required String reason, DateTime? now})`
  - `String? proofDataUrl(PaymentProof proof)`

- [ ] **Step 1: Write failing tests**

```dart
test('uploading a JPEG moves the order to verification', ...);
test('non-image bytes and files over 5 MB are rejected', ...);
test('admin rejection requires a reason and returns to awaiting payment', ...);
test('admin approval then shipping exposes tracking', ...);
test('customer cancel restores stock exactly once and is final', ...);
test('invalid transitions are rejected', ...);
test('auto-cancel happens 24 hours after payBefore and is idempotent', () async {
  await orders.applyTimeBasedTransitions(now: payBefore.add(const Duration(minutes: 1)));
  expect(order.status, OrderStatus.cancelled);
  expect(stockAfter, stockBefore);
  await orders.applyTimeBasedTransitions(now: payBefore.add(const Duration(hours: 1)));
  expect(stockAfter, stockBefore);
});
test('auto-complete happens 7 days after shipping', ...);
test('every transition appends a status log', ...);
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/data/order_lifecycle_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement proof validation and storage**

- Magic bytes: JPEG `FF D8 FF`, PNG `89 50 4E 47`, WEBP starts `RIFF` and has `WEBP` at offset 8.
- Reject > 5 MB with `file_too_large`; reject unknown types with `invalid_type`.
- Store base64 data URL under `proof.<orderId>.<proofId>`; add a `pending` proof; status `paymentVerification`; clear `latestRejectReason`; log actor customer.
- Allow upload only from `awaitingPayment`.

- [ ] **Step 4: Implement transitions**

Use a guard:

```dart
const allowed = {
  OrderStatus.awaitingPayment: {OrderStatus.paymentVerification, OrderStatus.cancelled},
  OrderStatus.paymentVerification: {OrderStatus.processing, OrderStatus.awaitingPayment, OrderStatus.cancelled},
  OrderStatus.processing: {OrderStatus.shipped, OrderStatus.cancelled},
  OrderStatus.shipped: {OrderStatus.completed},
};
```

- Approve: `paymentVerification → processing`; mark pending proof approved.
- Reject: reason required; proof rejected with reason; back to `awaitingPayment`; keep `payBefore`.
- Ship: courier must be one of JNE, J&T, SiCepat, Pos Indonesia, Lainnya; tracking matches `^[A-Za-z0-9]{5,30}$`; set `shipment` and log.
- Admin cancel: only `paymentVerification`/`processing`; reason required; restore stock.
- Customer cancel: only `awaitingPayment`; restore stock.
- Complete: only `shipped`; set `completedAt`.
- Restore stock once per order (status becomes final, so later calls fail).
- `applyTimeBasedTransitions`: cancel overdue `awaitingPayment`; complete `shipped` whose `shippedAt + 7 days` passed; log actor system; write once.

- [ ] **Step 5: Run tests**

Run: `flutter test test/data/order_lifecycle_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/data/repositories/order_repository.dart test/data/order_lifecycle_test.dart
git commit -m "feat: add payment proof and order lifecycle rules"
```

---

### Task 11: App controllers

**Files:**
- Create: `lib/state/auth_controller.dart`, `catalog_controller.dart`, `cart_controller.dart`, `order_controller.dart`
- Test: `test/state/controllers_test.dart`

**Interfaces:**
- Produces:
  - `AuthController(AuthRepository, ProfileRepository)` with `User? user`, `bool isLoggedIn`, `Address? defaultAddress`, `login`, `register`, `logout`, `requestResetCode`, `resetPassword`, `refresh`.
  - `CatalogController(CatalogRepository)` with `categories`, `products`, `loading`, `loadingMore`, `error`, `hasMore`, `total`, `query`, `categoryId`, `load`, `refresh`, `loadMore`, `search`, `selectCategory`, `resetFilters`.
  - `CartController(CartRepository, AuthController)` with `lines`, `count`, `subtotal`, `warnings`, `loading`, `load`, `add`, `setQty`, `remove`, `clear`, `clearLocal`.
  - `OrderController(OrderRepository, AuthController)` with `orders`, `selected`, `statusFilter`, `loading`, `load`, `loadDetail`, `createOrder`, `uploadProof`, `cancel`, `complete`, `adminApprove`, `adminReject`, `adminShip`, `adminCancel`, `setStatusFilter`, `applyTimedTransitions`.

- [ ] **Step 1: Write failing controller tests**

```dart
test('AuthController notifies and exposes the logged-in user', ...);
test('CartController add updates count and subtotal', ...);
test('CartController load reconciles stock and exposes warnings', ...);
test('OrderController create clears the cart through CartController', ...);
test('OrderController status filter reloads the filtered list', ...);
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/state/controllers_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement controllers**

- Controllers catch repository failures? No: repository returns `AppResult`; controllers return it to the UI and set `error` only for load failures.
- `CartController.load` calls `reconcile` then `lines`; warnings stored; no-op when guest.
- `OrderController.load` calls `applyTimeBasedTransitions` first, then fetches; `loadDetail` also applies transitions.
- `createOrder` calls the repository, then `cart.clearLocal()`; notify.
- Every mutating method calls `notifyListeners()`.

- [ ] **Step 4: Run tests**

Run: `flutter test test/state/controllers_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/state test/state
git commit -m "feat: add auth, catalog, cart, and order controllers"
```

---

### Task 12: Shared widgets, router, and app shell

**Files:**
- Create: `lib/widgets/rnz_button.dart`, `rnz_text_field.dart`, `product_card.dart`, `status_pill.dart`, `empty_state.dart`, `skeleton_grid.dart`, `quantity_stepper.dart`, `section_header.dart`, `copy_field.dart`, `main_scaffold.dart`
- Create: `lib/routing/app_router.dart`, `lib/app.dart` (app widget only; navigation destinations are placeholders until later tasks)
- Test: `test/widgets/shared_widgets_test.dart`, `test/routing/router_test.dart`

**Interfaces:**
- Produces:
  - `RnzButton({required String label, VoidCallback? onPressed, bool loading, RnzButtonVariant variant})`
  - `RnzTextField({required String label, String? errorText, ...})`
  - `ProductCard({required Product product, required VoidCallback onTap})`
  - `StatusPill({required OrderStatus status})`
  - `EmptyState({required String title, String? message, String? actionLabel, VoidCallback? onAction})`
  - `SkeletonGrid({int itemCount = 6})`
  - `QuantityStepper({required int value, required int min, required int max, required ValueChanged<int> onChanged})`
  - `SectionHeader({required String title, String? actionLabel, VoidCallback? onAction})`
  - `CopyField({required String label, required String value, String? helper})`
  - `MainScaffold({required int currentIndex, required Widget child})`
  - `GoRouter buildRouter(AuthController auth)`

- [ ] **Step 1: Write failing widget/router tests**

```dart
testWidgets('ProductCard shows price and out-of-stock badge', (tester) async {
  await tester.pumpWidget(/* MaterialApp with ProductCard for zero-stock product */);
  expect(find.text('Rp 85.000'), findsOneWidget);
  expect(find.text('Stok Habis'), findsOneWidget);
});
testWidgets('QuantityStepper respects min and max', ...);
testWidgets('guest opening /cart is redirected to /login', (tester) async {
  final auth = AuthController(authRepo, profileRepo); // no session
  final router = buildRouter(auth);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  router.go('/cart');
  await tester.pumpAndSettle();
  expect(find.text('Masuk'), findsWidgets);
});
testWidgets('logged-in user opening /login is sent home', ...);
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/widgets/shared_widgets_test.dart test/routing/router_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement widgets**

- `RnzButton` has a 48 dp minimum height, full-width option, and a spinner inside when loading.
- `ProductCard` uses 3:4 image, `Hero(tag: 'product-<id>')`, name (max 2 lines), `formatRupiah`, and the stock badge.
- `EmptyState` centers a line-art icon, title, optional message and action.
- `SkeletonGrid` shows shimmerless pulsing placeholders (subtle opacity animation).
- `CopyField` copies to clipboard and shows a SnackBar `Nomor disalin`.
- All images use `semanticLabel`.
- `MainScaffold` bottom nav: Beranda, Pesanan, Profil; cart icon lives in each screen's app bar, not the bottom nav.

- [ ] **Step 4: Implement router and app shell**

- Initial route `/splash`.
- Public paths: `/splash`, `/onboarding`, `/login`, `/register`, `/forgot-password`, `/reset-password`, `/home`, `/search`, `/product/:id`, `/privacy`.
- Private prefix guard as in Global Constraints; redirect to `/login?from=<encoded full URI>`.
- On login/register when already logged in, redirect to `from` or `/home`.
- Placeholder screens are allowed in this task only; they are replaced in Tasks 13–17.

- [ ] **Step 5: Run tests**

Run: `flutter test test/widgets/shared_widgets_test.dart test/routing/router_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets lib/routing lib/app.dart test/widgets test/routing
git commit -m "feat: add design-system widgets and guarded router"
```

---

### Task 13: Splash, onboarding, and auth screens

**Files:**
- Create: `lib/screens/splash_screen.dart`, `onboarding_screen.dart`
- Create: `lib/screens/auth/login_screen.dart`, `register_screen.dart`, `forgot_password_screen.dart`, `reset_password_screen.dart`
- Test: `test/screens/auth_screens_test.dart`

**Interfaces:**
- Consumes: `AuthController`, `ProfileRepository` (via Provider), `go_router`.
- Produces routes `/splash`, `/onboarding`, `/login`, `/register`, `/forgot-password`, `/reset-password`.

- [ ] **Step 1: Write failing widget tests**

```dart
testWidgets('login shows field errors for empty submit', ...);
testWidgets('login with demo account navigates home', ...);
testWidgets('login from /cart returns to cart after success', ...);
testWidgets('register shows duplicate email message', ...);
testWidgets('forgot password shows demo code dialog and reset works', ...);
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/screens/auth_screens_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement splash and onboarding**

- Splash shows the RnZ monogram and tagline, waits 900 ms, then goes to `/onboarding` if not seen, otherwise `/home`.
- Onboarding: 3 pages (Koleksi pilihan, Stok akurat, Pesanan terlacak), skip/next, "Mulai Belanja" sets `onboardingSeen` and goes `/home`.
- Use bundled product images in the onboarding art; no network.

- [ ] **Step 4: Implement login and register**

- Login form: email, password, "Masuk", link to register and forgot password, guest link "Lihat katalog".
- Show `AppError.message` and `fields` inline; lockout message includes remaining minutes.
- After success, `context.go(from ?? '/home')`.
- Register: name, email, phone, password, confirm, address fields, privacy checkbox. Disable submit until consent checked. On success, go home.
- Use `AutovalidateMode.onUserInteraction`; first invalid field receives focus.

- [ ] **Step 5: Implement forgot/reset**

- Forgot: email field; on submit always show `Jika email terdaftar, kode reset telah dibuat.`; if a code is returned, show a dialog labeled "Mode Demo" with the 6-digit code and a "Lanjut Reset" button to `/reset-password?email=...`.
- Reset: email (prefilled), code, new password, confirm; on success show SnackBar and go `/login`.

- [ ] **Step 6: Run tests**

Run: `flutter test test/screens/auth_screens_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/screens/splash_screen.dart lib/screens/onboarding_screen.dart lib/screens/auth test/screens/auth_screens_test.dart
git commit -m "feat: add onboarding and authentication screens"
```

---

### Task 14: Home, search, and product detail

**Files:**
- Create: `lib/screens/home/home_screen.dart`, `search_screen.dart`, `lib/screens/product/product_detail_screen.dart`
- Test: `test/screens/catalog_screens_test.dart`

**Interfaces:**
- Consumes: `CatalogController`, `CatalogRepository`, `CartController`.
- Produces routes `/home`, `/search`, `/product/:id`.

- [ ] **Step 1: Write failing widget tests**

```dart
testWidgets('home renders the hero, category chips, and product grid', ...);
testWidgets('home shows Stok Habis badge for an out-of-stock product', ...);
testWidgets('search debounces and shows result count', ...);
testWidgets('empty search shows Produk tidak ditemukan', ...);
testWidgets('product detail disables add until a variant is chosen', ...);
testWidgets('choosing a variant enables add and increments the cart badge', ...);
testWidgets('gallery can be zoomed with InteractiveViewer', ...);
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/screens/catalog_screens_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement home**

- App bar: greeting + search icon + cart icon with `Badge` count.
- Hero: `rnz_05.jpg` with a dark forest gradient overlay and serif headline "Tenang, anggun, siap menemani harimu." + CTA to `/search`.
- Category chips scroll horizontally; tap filters the grid with the active chip underlined.
- Section "Pilihan Minggu Ini" (first 6) and "Terbaru" (remaining) or one grid with `SectionHeader`; use a 2-column `SliverGrid` and infinite scroll.
- Skeleton while loading; empty state; error + "Coba Lagi"; `RefreshIndicator` calls `refresh`.
- Tapping a card goes to `/product/:id`.

- [ ] **Step 4: Implement search**

- Text field autofocus; a 400 ms `Timer` debounces calls to `CatalogController.search`.
- Category chips + "Reset"; result count `N hasil` above the grid.
- Empty state title "Produk tidak ditemukan", message "Coba hapus kata kunci atau pilih kategori lain."
- Maintain the grid, pagination, skeleton, and pull-to-refresh behavior from home.

- [ ] **Step 5: Implement product detail**

- `PageView` gallery with dots; each page wrapped in `InteractiveViewer(minScale: 1, maxScale: 4)`.
- Name, category, price, description, total stock, variant color chips and size chips (size hidden if all null).
- Variants with stock 0 are disabled and labeled "Habis".
- Quantity stepper 1..stock for the selected variant; "Tambah ke Keranjang" disabled until a variant is selected.
- Add: call `CartController.add`; on failure show "Stok tersisa N"; on success show SnackBar and update badge.
- Guest: `context.push('/login?from=/product/<id>')` instead of adding.
- On init, re-read the product from the repository to get current stock.

- [ ] **Step 6: Run tests**

Run: `flutter test test/screens/catalog_screens_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/screens/home lib/screens/product test/screens/catalog_screens_test.dart
git commit -m "feat: add catalog, search, and product detail screens"
```

---

### Task 15: Cart, checkout, and addresses

**Files:**
- Create: `lib/screens/cart/cart_screen.dart`, `lib/screens/checkout/checkout_screen.dart`
- Create: `lib/screens/address/address_list_screen.dart`, `address_form_screen.dart`
- Test: `test/screens/cart_checkout_test.dart`

**Interfaces:**
- Consumes: `CartController`, `OrderController`, `ProfileRepository`, `CheckoutRepository`, `AuthController`.
- Produces routes `/cart`, `/checkout`, `/addresses`, `/addresses/new`, `/addresses/:id/edit`.

- [ ] **Step 1: Write failing widget tests**

```dart
testWidgets('empty cart shows the empty state and no checkout button', ...);
testWidgets('quantity change updates the line and total', ...);
testWidgets('removing a line shows Undo and restores it', ...);
testWidgets('checkout blocks when there is no address', ...);
testWidgets('checkout shows shipping fallback for an unknown city', ...);
testWidgets('address form rejects the sixth address', ...);
testWidgets('create order navigates to the payment screen', ...);
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/screens/cart_checkout_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement cart**

- List lines with image, name, variant, unit price, stepper, line total; show warning banners from `CartController.warnings`.
- Remove: remove immediately, show SnackBar with "Urungkan" for 5 seconds; undo restores the previous qty/line; if the SnackBar closes, keep the removal.
- Clear cart: confirmation dialog.
- Bottom panel: subtotal, "Lanjut ke Checkout" (disabled if empty).
- Empty state + "Mulai Belanja".

- [ ] **Step 4: Implement checkout**

- Load default address and active payment methods; address card with "Ubah" opens `/addresses?select=1`.
- Payment method cards; selecting shows account info.
- Summary: lines, subtotal, shipping (or "Ongkir dikonfirmasi admin"), total.
- "Buat Pesanan" disabled while submitting; generate an idempotency key once when the screen opens; call `OrderController.createOrder`; on success go to `/orders/<id>/payment` with `pushReplacement`; on failure show inline/SnackBar, including short-stock lines.
- Block with clear messages for empty cart or no address.

- [ ] **Step 5: Implement addresses**

- List with default badge; actions edit/delete/set default; "Tambah Alamat" disabled at 5 with explanation.
- Form fields: label, recipient name, phone, province, city, district, address line, postal code, default switch.
- When opened with `select=1`, tapping an address sets it as the checkout selection and pops with the address id; "Tambah Alamat" returns to checkout with the new address selected.
- Delete confirmation; deleting the default promotes another (repository handles it).

- [ ] **Step 6: Run tests**

Run: `flutter test test/screens/cart_checkout_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/screens/cart lib/screens/checkout lib/screens/address test/screens/cart_checkout_test.dart
git commit -m "feat: add cart, checkout, and address screens"
```

---

### Task 16: Payment, order history, and order detail

**Files:**
- Create: `lib/screens/orders/payment_screen.dart`, `orders_screen.dart`, `order_detail_screen.dart`
- Test: `test/screens/orders_screens_test.dart`

**Interfaces:**
- Consumes: `OrderController`, `OrderRepository`, `CartController`, `AuthController`.
- Produces routes `/orders`, `/orders/:id`, `/orders/:id/payment`.
- `PaymentScreen` accepts an optional `Future<Uint8List?> Function()? pickImage` for tests; production defaults to `ImagePicker.pickImage`.

- [ ] **Step 1: Write failing widget tests**

```dart
testWidgets('orders list filters by status', ...);
testWidgets('detail shows the timeline and rejection reason', ...);
testWidgets('tracking is hidden before Dikirim and visible after', ...);
testWidgets('customer can cancel an awaiting order and stock is restored', ...);
testWidgets('Pesanan Diterima completes a shipped order', ...);
testWidgets('payment screen shows the exact total and copy fields', ...);
testWidgets('proof upload accepts a valid JPEG and moves to verification', ...);
testWidgets('demo admin approve -> ship flow updates the status', ...);
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/screens/orders_screens_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement orders list**

- App bar "Pesanan Saya"; filter chips: Semua + 6 statuses; newest first; pull-to-refresh; empty state per filter.
- Each card: order number, date, status pill, item count, total, first item thumbnail, "Lihat Detail".
- Load calls `applyTimeBasedTransitions` first (controller does it).

- [ ] **Step 4: Implement order detail**

- Header: order no, date, status pill.
- Items list with unit price/qty/total, address snapshot, payment snapshot, totals.
- Timeline: dots + status + timestamp + actor label + note.
- Rejection reason banner when present.
- Shipment section only when `status == shipped` or `completed` and shipment exists: courier, tracking, copy button.
- Actions:
  - `awaitingPayment`: "Bayar Sekarang" → payment route; "Batalkan Pesanan" → confirm → cancel.
  - `shipped`: "Pesanan Diterima" → confirm → complete.
- Demo admin panel (expanded tile labeled "Mode Demo — aksi admin"): approve/reject with reason, ship with courier dropdown + tracking field, cancel with reason. Hide actions invalid for the current status.

- [ ] **Step 5: Implement payment screen**

- Show `payBefore` countdown (`formatCountdown`), total, and all active payment methods with copy buttons.
- Upload card: "Pilih Bukti Transfer" uses `ImagePicker.pickImage(source: gallery, maxWidth: 1600, maxHeight: 1600, imageQuality: 70)`; preview via `Image.memory`; "Kirim Bukti" with progress; on failure show "Coba Lagi" and keep the bytes.
- On success: SnackBar "Bukti terkirim. Menunggu verifikasi." and refresh detail/list.
- If `latestRejectReason` exists, show a warning banner and allow re-upload.

- [ ] **Step 6: Run tests**

Run: `flutter test test/screens/orders_screens_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/screens/orders test/screens/orders_screens_test.dart
git commit -m "feat: add payment, order history, and detail screens"
```

---

### Task 17: Profile, security, and legal screens

**Files:**
- Create: `lib/screens/profile/profile_screen.dart`, `profile_edit_screen.dart`, `change_password_screen.dart`, `delete_account_screen.dart`
- Create: `lib/screens/legal/privacy_screen.dart`
- Test: `test/screens/profile_screens_test.dart`

**Interfaces:**
- Consumes: `AuthController`, `ProfileRepository`, `LocalStore` (reset demo), `url_launcher`.
- Produces routes `/profile`, `/profile/edit`, `/change-password`, `/delete-account`, `/privacy`.

- [ ] **Step 1: Write failing widget tests**

```dart
testWidgets('profile shows the user name and menu items', ...);
testWidgets('change password rejects a wrong current password', ...);
testWidgets('delete account is blocked while an order is active', ...);
testWidgets('privacy screen shows the local-data notice', ...);
testWidgets('logout returns to the public home', ...);
```

- [ ] **Step 2: Run and confirm failure**

Run: `flutter test test/screens/profile_screens_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement profile**

- Header: avatar monogram (first letter), name, email, phone.
- Menu: Edit Profil, Kelola Alamat, Ubah Sandi, Kebijakan Privasi, Hubungi Toko (`wa.me`), Keluar.
- Demo section separated by a divider: "Mode Demo" → "Reset Data Demo" with a confirmation dialog; calls `store.clearAll()`, reseeds, logs out, goes `/home`.
- Edit: name/phone; save; update auth state.
- Change password: current, new, confirm; success SnackBar; logout not required.
- Delete account: explanation, password field, confirm; on `active_orders` show a specific message listing that active orders must finish first; success logs out and goes `/home`.
- Privacy: static Indonesian text explaining local storage, data collected, deletion, and demo limitations.
- "Hubungi Toko" uses `launchUrl(Uri.parse('https://wa.me/6281234567890'))` from `AppConstants.storeWhatsApp` and shows a SnackBar if launch fails.

- [ ] **Step 4: Run tests**

Run: `flutter test test/screens/profile_screens_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/profile lib/screens/legal test/screens/profile_screens_test.dart
git commit -m "feat: add profile, security, and privacy screens"
```

---

### Task 18: Final wiring, recovery, accessibility, and verification

**Files:**
- Modify: `lib/main.dart`, `lib/app.dart`, `lib/routing/app_router.dart` (replace placeholders)
- Create: `lib/screens/recovery_screen.dart`, `README.md`
- Modify: tests as needed

**Interfaces:**
- Consumes: all previous tasks.
- Produces: runnable app with providers, bootstrap, and final routes.

- [ ] **Step 1: Wire bootstrap and providers**

`main()`:
1. `WidgetsFlutterBinding.ensureInitialized()`.
2. `await initializeDateFormatting('id_ID')`.
3. Open `LocalStore`; catch `StoreCorruptException` → run `RecoveryScreen` with a "Reset Data Demo" action.
4. `await store.seedIfNeeded()`.
5. Construct repositories and controllers; `runApp(RnzApp(...))`.

`RnzApp` uses `MultiProvider` (`LocalStore` + repositories + auth/cart/order controllers), `MaterialApp.router` with `buildRouter(auth)`, `AppTheme.light`, locale `id_ID`, and delegates.

- [ ] **Step 2: Replace all placeholder screens**

Confirm every route from the spec has a real screen. Guest cart/product add flows redirect to login and return correctly.

- [ ] **Step 3: Add recovery behavior**

`RecoveryScreen` shows "Data lokal tidak dapat dibaca" with a "Reset Data Demo" button that clears prefs, reseeds, and restarts the app state without a crash.

- [ ] **Step 4: Accessibility and responsive pass**

- Verify 48 dp targets on icon buttons, steppers, chips.
- Add `Semantics` labels for product images and cart icon.
- Test 360×640, 800×1280, and text scale 2.0; fix overflows with `Flexible`/`Wrap`/scroll views.
- Check contrast for muted text on ivory; darken if below 4.5:1.

- [ ] **Step 5: Write README**

Include: what it is, scope/deviation (local demo), setup, demo account, run commands (`flutter run -d chrome`, Android), test commands, asset credits, and the "Mode Demo" explanation.

- [ ] **Step 6: Run full verification**

```powershell
flutter analyze
flutter test
flutter build web --release
```

Expected: analyze 0 issues; all tests pass; web build succeeds.

- [ ] **Step 7: Manual smoke test**

Run `flutter run -d chrome` and walk: onboarding → login demo → home → search "pash" → product → variant → cart → checkout → address → payment → upload proof → demo admin approve → ship → confirm received → view tracking → profile → change password → delete account. Confirm no overflow at 360 dp.

- [ ] **Step 8: Commit**

```bash
git add lib/main.dart lib/app.dart lib/routing lib/screens/recovery_screen.dart README.md
git commit -m "feat: wire app bootstrap, recovery, and final routes"
```

---

## Plan Self-Review

- **Spec coverage:** US-01–22 map to Tasks 13–17 with repositories in 5–10; §14 deviations are implemented as the demo admin panel, local reset code, and local session; UI tokens are Task 1/12; testing is covered per task and Task 18.
- **Type consistency:** `AppResult`, `AddressDraft`, `CartLine`, `CheckoutSummary`, `OrderStatus`, and controller names are defined once and reused. `OrderRepository` constructor order is fixed as store/cart/profile/checkout.
- **Review focus tests:** stock atomicity (Task 9), idempotency (Task 9), timed transitions (Task 10), corrupt JSON (Task 4/18), guest return path and text scale (Tasks 12/13/18).
- **Proportion:** interfaces and test assertions are pinned; implementation bodies are left to the coder except for the state-machine guard and order-creation ordering, which are decisions the tests do not determine.
