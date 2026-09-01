# ANDROID PERFORMANCE & UX FRAMEWORK
## Master PRD — Telegram-Class Lightweight Android Application Standard

**Document Type:** Master Product Requirements Document / Engineering Framework  
**Version:** 1.0.0  
**Status:** Standard  
**Primary Platform:** Android  
**Default UI Framework:** Flutter  
**Audience:** Developer, AI Coding Agent, Tech Lead  
**Purpose:** Menjadi standar reusable untuk setiap pengembangan aplikasi Android agar ringan, cepat, responsif, stabil, dan memiliki UI/UX berkualitas tinggi.

---

# 1. Visi

Setiap aplikasi Android yang dibangun dengan framework ini harus memiliki karakteristik:

- Cepat saat startup.
- Responsif saat interaksi.
- Tidak bergantung pada network untuk menampilkan data yang sudah pernah dimuat.
- Hemat RAM, CPU, baterai, dan bandwidth.
- Halaman dengan banyak data tetap lancar.
- UI konsisten, bersih, modern, dan mudah dipelihara.
- Perubahan data hanya menyebabkan bagian UI yang relevan diperbarui.
- Operasi database, network, parsing, dan pekerjaan berat tidak memblokir UI thread.
- Semua keputusan performance harus dapat diukur melalui profiling.

## Prinsip utama

> **Local-first → Cache-first → Async → Incremental → Virtualized → Reactive → Measured**

---

# 2. Tujuan Framework

Framework ini menetapkan standar untuk:

1. Arsitektur aplikasi.
2. Struktur project.
3. UI/UX.
4. State management.
5. Local database.
6. Caching.
7. Networking.
8. Synchronization.
9. Image handling.
10. Performance.
11. Memory management.
12. Error handling.
13. Security.
14. Testing.
15. Build dan release.
16. Observability.
17. Integrasi AI coding agent.

Framework ini bersifat **technology-agnostic pada level prinsip**, tetapi contoh implementasi menggunakan Flutter.

---

# 3. Non-Goals

Framework ini tidak memaksakan:

- Satu library state management untuk semua proyek.
- Satu backend technology.
- Satu database server.
- Satu design style.
- Penggunaan dependency hanya demi mengikuti tren.
- Kompleksitas arsitektur yang tidak diperlukan.

Prinsip:

> **Gunakan kompleksitas hanya jika kompleksitas tersebut memberikan nilai yang terukur.**

---

# 4. Quality Standards

Setiap aplikasi harus memenuhi target berikut, kecuali terdapat alasan teknis yang terdokumentasi.

| Area | Standard |
|---|---|
| UI responsiveness | Tidak ada interaksi utama yang terasa blocking |
| Frame budget | Target ≤16.67 ms/frame untuk 60 FPS |
| High-refresh devices | Optimalkan agar dapat mengikuti 90/120 Hz jika perangkat mendukung |
| Startup | Minimalkan pekerjaan sebelum first usable screen |
| Network | Tidak menjadi satu-satunya sumber data UI |
| Lists | Gunakan virtualization/lazy rendering |
| Images | Gunakan ukuran sesuai display |
| State | Hindari global rebuild |
| Database | Query terukur dan memiliki index yang sesuai |
| API | Pagination untuk collection besar |
| Errors | Semua network/database operation memiliki failure state |
| Offline | Aplikasi tetap berguna untuk data yang telah disinkronkan |
| Logging | Gunakan structured logging |
| Testing | Unit + widget/integration test untuk critical flows |
| Release | Production build harus dianalisis sebelum release |

---

# 5. Arsitektur Referensi

Gunakan feature-oriented architecture.

```text
lib/
├── app/
│   ├── app.dart
│   ├── routes.dart
│   └── bootstrap.dart
│
├── core/
│   ├── config/
│   ├── database/
│   ├── network/
│   ├── cache/
│   ├── storage/
│   ├── logging/
│   ├── errors/
│   ├── theme/
│   └── utils/
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── home/
│   ├── profile/
│   └── settings/
│
└── shared/
    ├── widgets/
    ├── models/
    └── extensions/
```

## Dependency direction

```text
Presentation
     ↓
Domain
     ↓
Data
     ↓
Infrastructure
```

Jangan membuat:

```text
UI → API client langsung
UI → Database langsung
Widget → HTTP request
Widget → SQL query
```

Gunakan:

```text
UI
 ↓
State / ViewModel
 ↓
Use Case
 ↓
Repository
 ↓
Local DB / API
```

---

# 6. Local-First Architecture

## Requirement

UI harus membaca sumber data lokal terlebih dahulu apabila data tersedia secara lokal.

Flow:

```text
User opens screen
       ↓
Local DB / Cache
       ↓
Render immediately
       ↓
Background synchronization
       ↓
Server response
       ↓
Update local DB
       ↓
Reactive UI update
```

Bukan:

```text
User opens screen
       ↓
API
       ↓
Loading
       ↓
Render
```

## Acceptance Criteria

- Data yang telah tersedia lokal dapat ditampilkan tanpa menunggu network.
- Network request tidak memblokir UI.
- Data server menjadi sumber sinkronisasi.
- Local database menjadi sumber pembacaan UI untuk data yang sudah disimpan.

---

# 7. Repository Pattern

Repository menjadi boundary antara aplikasi dengan data source.

```text
Feature
  ↓
Repository
  ├── LocalDataSource
  └── RemoteDataSource
```

Contoh:

```dart
abstract class UserRepository {
  Future<User?> getUser(String id);
  Stream<User?> watchUser(String id);
  Future<void> syncUser(String id);
}
```

Implementasi:

```text
UserRepositoryImpl
 ├── UserLocalDataSource
 └── UserRemoteDataSource
```

UI tidak mengetahui apakah data berasal dari:

- SQLite.
- REST API.
- GraphQL.
- Cache.
- File.
- Memory.

---

# 8. State Management

## Rules

1. State harus memiliki scope sekecil mungkin.
2. Jangan menggunakan global state untuk semua hal.
3. Hindari rebuild seluruh halaman.
4. Pisahkan:
   - UI state.
   - Domain state.
   - Persistent state.
   - Remote synchronization state.

Contoh:

```text
AppState
├── AuthState
├── UserState
├── NotificationState
└── FeatureState
```

Perubahan `NotificationState` tidak boleh menyebabkan seluruh aplikasi rebuild.

## Flutter Rules

Prioritaskan:

- `const` constructors.
- Widget kecil.
- Immutable state.
- Selector/watch yang granular.
- Lazy builders.

---

# 9. Rendering & Widget Performance

## Wajib

Gunakan lazy/virtualized rendering:

```dart
ListView.builder(...)
```

atau:

```dart
SliverList(...)
```

Hindari:

```dart
Column(
  children: hugeList.map(...).toList(),
)
```

untuk dataset besar.

## Widget rules

- Widget harus memiliki tanggung jawab kecil.
- Jangan melakukan network request di `build()`.
- Jangan melakukan database query di `build()`.
- Jangan melakukan expensive computation di `build()`.
- Jangan membuat object berat berulang kali di `build()`.
- Gunakan `const` jika memungkinkan.
- Hindari rebuild yang tidak diperlukan.

---

# 10. Frame Performance

Target frame budget:

```text
60 FPS  = 16.67 ms/frame
90 FPS  = 11.11 ms/frame
120 FPS =  8.33 ms/frame
```

## Prinsip

Setiap frame harus melakukan pekerjaan seminimal mungkin.

Hindari pada UI thread:

- Parsing JSON besar.
- Sorting dataset besar.
- Image processing berat.
- Database operation berat.
- Network request.
- File operation berat.
- Algoritma kompleks.

Pindahkan pekerjaan CPU-heavy ke background isolate/thread sesuai kebutuhan.

---

# 11. List Performance

Untuk list besar:

- Lazy rendering.
- Pagination/cursor.
- Stable item identity.
- Hindari nested scrolling yang tidak diperlukan.
- Hindari widget tree yang terlalu dalam.
- Gunakan item yang ringan.
- Jangan load seluruh dataset ke memory tanpa alasan.

## Pagination

Default:

```http
GET /items?page=1&limit=30
```

Untuk dataset besar, prefer:

```http
GET /items?limit=30&cursor=<cursor>
```

Response:

```json
{
  "data": [],
  "next_cursor": "abc123",
  "has_more": true
}
```

---

# 12. Image Performance

## Rules

Jangan menampilkan original image jika ukuran layar tidak membutuhkannya.

Gunakan pipeline:

```text
Original
   ↓
Thumbnail
   ↓
Medium
   ↓
Original only when necessary
```

API ideal:

```json
{
  "thumbnail": "...",
  "medium": "...",
  "original": "..."
}
```

## Requirements

- Gunakan WebP/AVIF bila kompatibel dengan kebutuhan aplikasi.
- Resize image di server/CDN bila memungkinkan.
- Cache image.
- Hindari download image 4K untuk thumbnail 100 px.
- Hindari menyimpan bitmap besar di memory tanpa kebutuhan.
- Gunakan placeholder/skeleton.
- Gunakan progressive loading jika sesuai.

---

# 13. Caching Strategy

Gunakan multi-level cache jika diperlukan.

```text
L1 Memory Cache
       ↓ miss
L2 Disk Cache
       ↓ miss
L3 Local Database
       ↓ miss
L4 Network
```

## Cache policy

Setiap cache harus memiliki:

- Key.
- TTL bila relevan.
- Invalidation strategy.
- Maximum size.
- Eviction policy.

Jangan membuat cache tanpa strategi invalidation.

---

# 14. Database

Local database harus digunakan untuk data yang:

- Dibutuhkan saat startup.
- Sering dibaca.
- Harus tersedia offline.
- Mahal jika selalu diambil dari network.

## Database rules

- Buat index berdasarkan query nyata.
- Hindari `SELECT *` jika tidak diperlukan.
- Pagination query besar.
- Jangan melakukan query blocking pada UI.
- Gunakan transaction untuk operasi terkait.
- Jangan menyimpan data duplikat tanpa alasan.

## Schema evolution

Setiap perubahan schema harus memiliki migration.

Tidak boleh:

```text
hapus database
↓
buat ulang
```

sebagai strategi production migration.

---

# 15. Networking

Networking layer wajib menyediakan:

- Timeout.
- Error mapping.
- Retry yang terkontrol.
- Request cancellation bila relevan.
- Authentication.
- Logging yang aman.
- Serialization/deserialization.
- Connectivity handling.

Contoh:

```text
UI
 ↓
Repository
 ↓
API Client
 ↓
HTTP
```

## Timeout

Setiap request harus memiliki timeout yang masuk akal.

Jangan membiarkan request menggantung tanpa batas.

## Retry

Retry hanya untuk error yang layak di-retry.

Jangan melakukan infinite retry.

---

# 16. API Contract

API harus:

- Versioned.
- Konsisten.
- Memiliki pagination.
- Memiliki error format standar.
- Memiliki response yang efisien.
- Tidak mengirim field yang tidak diperlukan jika payload menjadi besar.

Contoh error:

```json
{
  "error": {
    "code": "USER_NOT_FOUND",
    "message": "User not found",
    "details": {}
  }
}
```

---

# 17. Synchronization Engine

Untuk aplikasi yang memerlukan sinkronisasi:

```text
Local DB
   ↕
Sync Engine
   ↕
Remote API
```

Sync engine harus menangani:

- Initial sync.
- Incremental sync.
- Retry.
- Conflict handling.
- Offline queue.
- Last synchronized timestamp/version.
- Partial failure.

Contoh:

```text
last_sync = 2026-08-31T10:00:00
```

Server dapat menyediakan:

```http
GET /sync?since=2026-08-31T10:00:00
```

Jangan melakukan full synchronization jika incremental synchronization tersedia.

---

# 18. Offline Behavior

Setiap feature harus mendefinisikan:

| State | Behavior |
|---|---|
| Online | Local + sync |
| Offline | Local data |
| First install offline | Empty state |
| Request failed | Cached data + error indicator |
| Sync failed | Retry later |
| Auth expired | Re-authentication flow |

Offline bukan berarti semua fitur harus bekerja penuh.

Targetnya:

> **Kegagalan network tidak boleh membuat aplikasi yang sebenarnya memiliki data lokal menjadi unusable.**

---

# 19. Loading UX

Hindari:

```text
Loading...
```

untuk seluruh halaman jika sebagian data sudah tersedia.

Gunakan:

- Skeleton.
- Progressive rendering.
- Cached content.
- Inline loading.
- Optimistic UI bila aman.

Contoh:

```text
Cached UI
   ↓
Skeleton hanya untuk data baru
   ↓
Data baru masuk
```

---

# 20. Error UX

Error harus:

- Spesifik.
- Dapat dipahami user.
- Dapat dipulihkan jika memungkinkan.
- Tidak membocorkan stack trace.

Gunakan kategori:

```text
NetworkError
AuthenticationError
ValidationError
PermissionError
ServerError
DatabaseError
UnknownError
```

Contoh UI:

```text
Tidak dapat memuat data.

[ Coba Lagi ]
```

Bukan:

```text
DioException: SocketException...
```

---

# 21. Design System

Setiap project harus memiliki design token.

## Spacing

Gunakan scale konsisten:

```text
4
8
12
16
20
24
32
40
48
```

## Typography

Definisikan:

```text
Display
Headline
Title
Body
Label
Caption
```

## Components

Minimal:

```text
AppButton
AppTextField
AppCard
AppAvatar
AppDialog
AppBottomSheet
AppListTile
AppLoading
AppSkeleton
AppErrorState
AppEmptyState
```

## Rules

- Jangan membuat komponen visual yang sama berkali-kali.
- Jangan menggunakan nilai spacing acak.
- Jangan menggunakan warna hard-coded di seluruh widget.
- Semua warna utama berasal dari theme/design tokens.

---

# 22. UI/UX Principles

Gunakan:

### Visual hierarchy

User harus dapat memahami:

1. Apa halaman ini?
2. Apa informasi paling penting?
3. Apa action utama?
4. Apa action sekunder?

### Consistency

Komponen dengan fungsi sama harus terlihat dan berperilaku sama.

### Feedback

Setiap action penting harus memiliki feedback:

```text
Tap
 ↓
Visual feedback
 ↓
Action
 ↓
Success / error state
```

### Progressive disclosure

Jangan menampilkan semua informasi sekaligus jika tidak diperlukan.

### Simplicity

Hilangkan elemen yang tidak memberikan fungsi.

---

# 23. Animation System

Animasi digunakan untuk:

- Feedback.
- Navigation.
- State transition.
- Spatial continuity.

Bukan sekadar dekorasi.

Gunakan animasi pendek dan konsisten.

Contoh:

```text
Fast       120 ms
Normal     200 ms
Emphasis   300 ms
```

Nilai aktual harus disesuaikan dengan design system.

Hindari animasi yang:

- Menghalangi user.
- Terlalu panjang.
- Membuat scrolling terasa berat.
- Memicu rebuild besar.

---

# 24. Memory Management

Wajib memperhatikan:

- Image bitmap.
- Large JSON response.
- Large collections.
- Controllers.
- Streams.
- Subscriptions.
- Timers.
- Animation controllers.

Setiap resource yang memiliki lifecycle harus dilepas pada lifecycle yang tepat.

Contoh:

```text
Controller created
       ↓
Screen active
       ↓
Screen disposed
       ↓
Controller disposed
```

Tidak boleh ada listener/subscription yang terus hidup tanpa kebutuhan.

---

# 25. Startup Performance

Startup harus dibagi:

```text
Critical initialization
       ↓
First usable screen
       ↓
Non-critical initialization
       ↓
Background initialization
```

Jangan menjalankan semua initialization sebelum UI pertama muncul.

Contoh pekerjaan non-critical:

- Analytics initialization.
- Preloading tertentu.
- Background synchronization.
- Cache maintenance.

Harus dipindahkan setelah aplikasi siap digunakan jika memungkinkan.

---

# 26. Dependency Policy

Setiap dependency harus menjawab:

1. Apa manfaatnya?
2. Mengapa tidak menggunakan platform/framework bawaan?
3. Dampaknya terhadap APK size?
4. Dampaknya terhadap startup?
5. Dampaknya terhadap RAM?
6. Apakah aktif dipelihara?
7. Apakah menambah native dependency?

Rule:

> **Dependency harus dibenarkan oleh value, bukan convenience semata.**

---

# 27. Security Baseline

Minimal:

- HTTPS.
- Secure token storage.
- Jangan hard-code secret.
- Jangan log access token.
- Jangan log password.
- Jangan menyimpan credential plaintext.
- Validate server responses.
- Implement authentication expiration.
- Gunakan least privilege.
- Obfuscation/release hardening bila sesuai kebutuhan.

---

# 28. Logging

Gunakan structured logging.

Contoh:

```text
INFO  auth.login.start
INFO  auth.login.success
WARN  api.request.retry
ERROR database.query.failed
```

Jangan:

```text
print(password)
print(accessToken)
print(full sensitive response)
```

Production logging harus dikontrol.

---

# 29. Observability

Pantau minimal:

- Crash rate.
- ANR.
- Startup time.
- API latency.
- API error rate.
- Memory usage.
- Frame performance.
- Sync failures.
- Database errors.

Performance harus diukur pada:

- Low-end device.
- Mid-range device.
- High-end device.

Jangan hanya menguji pada device developer.

---

# 30. Testing Strategy

## Unit tests

Untuk:

- Business logic.
- Repository.
- Serialization.
- Pagination.
- Cache policy.
- Sync logic.

## Widget tests

Untuk:

- Component.
- Loading.
- Error.
- Empty state.
- State transitions.

## Integration tests

Untuk critical flow:

```text
Login
 ↓
Home
 ↓
Detail
 ↓
Create/update
 ↓
Logout
```

## Performance tests

Uji:

- Startup.
- Long list.
- Large image.
- Network latency.
- Offline mode.
- Memory behavior.

---

# 31. Build Configuration

Gunakan environment:

```text
development
staging
production
```

Jangan memasukkan konfigurasi production secara hard-coded ke source code development.

Contoh:

```text
API_BASE_URL
API_TIMEOUT
ENVIRONMENT
FEATURE_FLAGS
```

---

# 32. Release Checklist

Sebelum production:

### Functional

- [ ] Authentication bekerja.
- [ ] Critical flows bekerja.
- [ ] Offline state diuji.
- [ ] Error state diuji.
- [ ] Empty state diuji.

### Performance

- [ ] Startup diprofiling.
- [ ] Long list diprofiling.
- [ ] Memory diprofiling.
- [ ] Frame rendering diperiksa.
- [ ] Image loading diperiksa.
- [ ] APK/AAB size diperiksa.

### Security

- [ ] Tidak ada secret.
- [ ] Tidak ada token dalam log.
- [ ] HTTPS aktif.
- [ ] Production configuration benar.

### Quality

- [ ] Unit tests lulus.
- [ ] Widget tests lulus.
- [ ] Integration tests critical flow lulus.
- [ ] Static analysis bersih.
- [ ] Tidak ada TODO kritis.

---

# 33. Performance Budget

Setiap aplikasi harus menetapkan budget sebelum development selesai.

Minimal:

```text
UI frame target       ≤ 16.67 ms
Unnecessary rebuilds  = 0 untuk critical screen
Unbounded list        = 0
Infinite retry        = 0
Unbounded cache       = 0
Blocking network UI   = 0
Blocking DB UI        = 0
Sensitive logging     = 0
```

APK size dan memory budget harus ditentukan berdasarkan karakteristik aplikasi dan target device.

---

# 34. AI Coding Agent Rules

Dokumen ini dapat digunakan sebagai system specification untuk AI coding agent.

Sebelum mengubah code, agent wajib:

1. Membaca struktur project.
2. Memahami architecture saat ini.
3. Mengidentifikasi dependency.
4. Mengidentifikasi data flow.
5. Mengidentifikasi performance bottleneck.
6. Tidak melakukan refactor besar tanpa alasan.
7. Tidak mengubah API contract tanpa persetujuan.
8. Tidak menghapus functionality yang sudah berjalan.
9. Tidak menambahkan dependency jika native/framework solution cukup.
10. Menjalankan test setelah perubahan.
11. Menjelaskan perubahan yang memengaruhi architecture.

## Agent must reject bad patterns

Agent harus memberi peringatan jika menemukan:

```text
Widget → API langsung
Widget → DB langsung
API call di build()
Huge Column untuk dataset besar
Full list tanpa pagination
Full image tanpa resizing
Global rebuild
Blocking operation di UI
Infinite retry
Unbounded cache
Sensitive logging
```

---

# 35. Definition of Done

Feature dianggap selesai hanya jika:

- [ ] UI selesai.
- [ ] Loading state tersedia.
- [ ] Empty state tersedia.
- [ ] Error state tersedia.
- [ ] Offline behavior didefinisikan.
- [ ] API integration selesai.
- [ ] Local persistence diterapkan bila diperlukan.
- [ ] Cache policy ditentukan bila diperlukan.
- [ ] Pagination diterapkan untuk dataset besar.
- [ ] State scope benar.
- [ ] Tidak ada unnecessary rebuild.
- [ ] Tidak ada blocking operation di UI.
- [ ] Test tersedia untuk logic penting.
- [ ] Performance diperiksa.
- [ ] Security diperiksa.
- [ ] Tidak ada debug code.
- [ ] Tidak ada sensitive logging.

---

# 36. Standard Development Workflow

```text
1. Requirement
      ↓
2. Architecture
      ↓
3. Data model
      ↓
4. API contract
      ↓
5. Local storage strategy
      ↓
6. State model
      ↓
7. UI design
      ↓
8. Implementation
      ↓
9. Unit tests
      ↓
10. Integration tests
      ↓
11. Performance profiling
      ↓
12. Security review
      ↓
13. Release build
      ↓
14. Final QA
```

---

# 37. Feature Design Template

Setiap feature baru harus memiliki:

```text
Feature:
Purpose:
User:
Inputs:
Outputs:
API:
Local data:
Cache:
Offline behavior:
Loading behavior:
Error behavior:
Pagination:
State:
Security:
Performance considerations:
Tests:
```

---

# 38. Golden Rules

## Rule 01
**UI tidak boleh menunggu network jika data lokal tersedia.**

## Rule 02
**Jangan render sesuatu yang belum terlihat atau belum diperlukan.**

## Rule 03
**Jangan rebuild sesuatu yang tidak berubah.**

## Rule 04
**Jangan download resource yang lebih besar dari kebutuhan display.**

## Rule 05
**Jangan melakukan pekerjaan berat di UI thread.**

## Rule 06
**Jangan menambahkan dependency tanpa alasan.**

## Rule 07
**Jangan membuat cache tanpa invalidation strategy.**

## Rule 08
**Jangan mengambil dataset besar tanpa pagination.**

## Rule 09
**Jangan membuat API request langsung dari widget.**

## Rule 10
**Performance harus diukur, bukan diasumsikan.**

---

# 39. Reference Data Flow

```text
                    ┌───────────────┐
                    │    Flutter    │
                    │      UI       │
                    └───────┬───────┘
                            │
                     Reactive State
                            │
                    ┌───────▼───────┐
                    │   ViewModel   │
                    └───────┬───────┘
                            │
                    ┌───────▼───────┐
                    │    UseCase    │
                    └───────┬───────┘
                            │
                    ┌───────▼───────┐
                    │  Repository   │
                    └───────┬───────┘
                       ┌────┴────┐
                       │         │
                ┌──────▼───┐ ┌───▼────────┐
                │ Local DB │ │ API Client │
                └──────┬───┘ └────┬───────┘
                       │           │
                       │      ┌────▼─────┐
                       │      │  Server  │
                       │      └────┬─────┘
                       │           │
                       └─────┬─────┘
                             ↓
                       Sync / Update
                             ↓
                         Local DB
                             ↓
                            UI
```

---

# 40. Reference Performance Model

```text
                  USER
                   │
                   ↓
             ┌───────────┐
             │ Fast UI   │
             └─────┬─────┘
                   │
             Local-first
                   │
          ┌────────▼────────┐
          │ Local Database  │
          └────────┬────────┘
                   │
                 Cache
                   │
          Background Sync
                   │
          ┌────────▼────────┐
          │      API        │
          └────────┬────────┘
                   │
                Server
```

The user should experience:

```text
Tap
 ↓
Immediate feedback
 ↓
Cached/local content
 ↓
Background synchronization
 ↓
Incremental update
```

not:

```text
Tap
 ↓
Spinner
 ↓
Network
 ↓
Spinner
 ↓
JSON parsing
 ↓
Rebuild everything
```

---

# 41. Project Initialization Checklist

Saat membuat aplikasi Android baru:

```text
[ ] Define product requirements
[ ] Define target devices
[ ] Define performance budget
[ ] Define design system
[ ] Define architecture
[ ] Define API contract
[ ] Define local data requirements
[ ] Define offline requirements
[ ] Define caching strategy
[ ] Define state management
[ ] Create feature structure
[ ] Create core infrastructure
[ ] Configure environments
[ ] Configure logging
[ ] Configure testing
[ ] Configure CI/CD
[ ] Establish profiling workflow
```

---

# 42. Framework Philosophy

Framework ini mengadopsi prinsip yang membuat aplikasi seperti Telegram terasa ringan:

```text
SIMPLE UI
    +
LOCAL DATA
    +
SMART CACHE
    +
ASYNC PROCESSING
    +
VIRTUALIZED RENDERING
    +
SMALL WIDGET TREE
    +
MINIMAL REBUILD
    +
OPTIMIZED IMAGES
    +
EFFICIENT NETWORK
    +
MEASUREMENT
    =
FAST APPLICATION
```

Target akhir bukan sekadar:

> "APK berukuran kecil."

Target sebenarnya:

> **Aplikasi terasa instan, responsif, stabil, hemat resource, dan tetap mudah dikembangkan.**

---

# 43. Mandatory Review Questions

Sebelum merge feature apa pun, developer/AI agent harus menjawab:

### Architecture
- Apakah feature mengikuti architecture?
- Apakah UI bergantung langsung pada infrastructure?

### Performance
- Apakah ada rebuild yang tidak perlu?
- Apakah ada operasi berat di UI?
- Apakah list sudah lazy?
- Apakah image sudah dioptimalkan?

### Data
- Apakah data harus disimpan lokal?
- Apakah caching diperlukan?
- Bagaimana invalidation-nya?
- Apakah pagination diperlukan?

### Network
- Apa yang terjadi ketika offline?
- Apa yang terjadi ketika timeout?
- Apakah retry aman?

### UX
- Apa loading state?
- Apa empty state?
- Apa error state?
- Apa feedback setelah action?

### Security
- Apakah ada secret?
- Apakah data sensitif masuk log?

### Testing
- Apa critical path?
- Bagaimana feature tersebut diuji?

Jika pertanyaan tersebut tidak dapat dijawab, feature belum dianggap production-ready.

---

# 44. Final Engineering Principle

Gunakan urutan prioritas berikut:

```text
1. Correctness
2. Security
3. Reliability
4. Performance
5. Maintainability
6. UX polish
```

Jangan mengorbankan correctness dan security hanya demi performance.

Namun jangan pula menerima architecture yang lambat hanya karena:

> "Nanti dioptimasi."

Performance harus menjadi bagian dari architecture sejak awal.

---

# APPENDIX A — Recommended Flutter Baseline

Baseline dapat disesuaikan per proyek:

```text
Framework       Flutter
Language        Dart
Architecture    Feature-oriented + Repository
State           Reactive / granular state
Database        SQLite-compatible local database
Network         HTTP client with timeout/interceptor
Serialization   Typed models
Image           Cached + appropriately resized
Navigation      Centralized routing
Theme           Design-token based
Testing         Unit + Widget + Integration
Profiling       Flutter DevTools
Build           Debug / Profile / Release
```

Library tertentu harus dipilih berdasarkan kebutuhan proyek, bukan dipasang sebagai kewajiban framework.

---

# APPENDIX B — Anti-Pattern Catalog

Jangan:

```dart
FutureBuilder(
  future: api.getEverything(),
  builder: ...
)
```

sebagai pola utama untuk seluruh aplikasi.

Jangan:

```dart
build() {
  fetchData();
  return ...
}
```

Jangan:

```dart
Column(
  children: hugeDataset.map(...).toList(),
)
```

Jangan:

```dart
Image.network(originalHugeImage)
```

untuk semua kondisi.

Jangan:

```dart
setState(() {
  // entire application state
});
```

untuk state global yang besar.

Jangan:

```text
Screen → HTTP → Server → Screen
```

sebagai satu-satunya data flow.

Gunakan:

```text
Screen
 ↓
Reactive State
 ↓
Repository
 ↓
Local DB
 ↓
Background Sync
 ↓
API
```

---

# APPENDIX C — AI Agent Prompt

Gunakan dokumen ini sebagai aturan engineering:

```text
You are working on an Android application governed by
ANDROID PERFORMANCE & UX FRAMEWORK v1.0.

Before changing code:

1. Inspect the existing architecture.
2. Preserve working functionality.
3. Follow feature-oriented architecture.
4. Keep UI independent from API/database infrastructure.
5. Use repository/data-source boundaries.
6. Prefer local-first data access when local data exists.
7. Use asynchronous operations for network/database/heavy work.
8. Avoid unnecessary widget rebuilds.
9. Use lazy/virtualized lists for large collections.
10. Optimize image dimensions and caching.
11. Use pagination for large datasets.
12. Do not introduce unnecessary dependencies.
13. Do not expose secrets or sensitive information in logs.
14. Implement loading, empty, error, and offline states.
15. Add or update tests for critical behavior.
16. Profile performance when modifying performance-sensitive code.
17. Do not change API contracts without explicit approval.
18. Do not perform large architectural rewrites unless necessary.
19. Explain any architectural deviation from this framework.
20. Prefer measurable performance improvements over speculative optimization.

Definition of done:
- Functional
- Tested
- Secure
- Offline behavior defined
- Performance reviewed
- Maintainable
- Production-ready
```

---

# Document Control

**Name:** Android Performance & UX Framework  
**Version:** 1.0.0  
**Status:** Master Standard  
**Intended use:** Reusable baseline for Android application development  
**Primary objective:** Lightweight, responsive, beautiful, maintainable applications
