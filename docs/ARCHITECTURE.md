# TheKoordinasi — System Architecture Document

> **Version**: 1.0.0  
> **Status**: Draft — Menunggu Persetujuan  
> **Last Updated**: 2026-02-20

---

## 1. Executive Summary

**TheKoordinasi** adalah aplikasi mobile private untuk koordinasi touring motor komunitas. Fokus utama adalah **keamanan**, **visibilitas real-time**, dan **kemudahan koordinasi** antara leader dan anggota selama perjalanan touring antar kota/provinsi.

### Masalah Utama yang Diselesaikan

| #   | Masalah                      | Solusi                                    |
| --- | ---------------------------- | ----------------------------------------- |
| 1   | Anggota sering tertinggal    | Live tracking + alert otomatis jarak      |
| 2   | Ada yang ngebut terlalu jauh | Geofencing formasi + speed monitoring     |
| 3   | Komunikasi sulit saat riding | Quick signal system (bukan chat)          |
| 4   | Leader kewalahan memantau    | Leader dashboard dengan bird-eye view     |
| 5   | Drama saat checkpoint        | Visibility posisi real-time semua anggota |

---

## 2. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                         │
│                                                             │
│  ┌──────────────┐   ┌──────────────┐   ┌────────────────┐  │
│  │  Flutter App  │   │  Background  │   │  Notification  │  │
│  │  (UI Layer)   │   │  Location    │   │  Handler       │  │
│  │              │   │  Service     │   │                │  │
│  └──────┬───────┘   └──────┬───────┘   └───────┬────────┘  │
│         │                  │                    │           │
│         └──────────────────┼────────────────────┘           │
│                            │                                │
│                   ┌────────▼────────┐                       │
│                   │  Local State    │                       │
│                   │  Management    │                       │
│                   │  (Riverpod)    │                       │
│                   └────────┬────────┘                       │
└────────────────────────────┼────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │   API Gateway   │
                    │  (HTTPS/WSS)    │
                    └────────┬────────┘
                             │
┌────────────────────────────┼────────────────────────────────┐
│                     BACKEND LAYER                           │
│                     (Firebase)                              │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  Firebase     │  │  Cloud       │  │  Firebase        │  │
│  │  Auth         │  │  Firestore   │  │  Cloud           │  │
│  │              │  │  (Database)  │  │  Messaging (FCM) │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  Cloud        │  │  Firebase     │  │  Firebase        │  │
│  │  Functions    │  │  Realtime DB  │  │  Storage         │  │
│  │  (Logic)     │  │  (Live Track) │  │  (Files)         │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Mengapa Firebase?

| Pertimbangan          | Alasan                                                        |
| --------------------- | ------------------------------------------------------------- |
| **Realtime Database** | Native support untuk live location tracking, latency rendah   |
| **Serverless**        | Tidak perlu manage server, fokus ke fitur                     |
| **Auth**              | Built-in phone/email auth, cocok untuk private community      |
| **FCM**               | Push notification untuk emergency alert                       |
| **Cost**              | Free tier cukup untuk komunitas kecil-menengah (< 100 member) |
| **Offline Support**   | Firestore memiliki offline persistence bawaan                 |

### Alternatif yang Dipertimbangkan

| Opsi                     | Pro                                        | Kontra                                       | Keputusan |
| ------------------------ | ------------------------------------------ | -------------------------------------------- | --------- |
| Supabase                 | Open source, PostgreSQL                    | Realtime kurang mature vs Firebase RTDB      | ❌        |
| Custom Backend (Node.js) | Full control                               | Butuh infra management, lebih lambat develop | ❌        |
| Firebase                 | Realtime native, serverless, offline-first | Vendor lock-in                               | ✅        |

---

## 3. Arsitektur Client (Flutter)

### 3.1 Layer Architecture

```
┌─────────────────────────────────────────┐
│            PRESENTATION LAYER           │
│  ┌─────────┐  ┌─────────┐  ┌────────┐  │
│  │ Screens  │  │ Widgets │  │ Themes │  │
│  └────┬─────┘  └────┬────┘  └────────┘  │
│       │              │                   │
│  ┌────▼──────────────▼────┐              │
│  │   State Management     │              │
│  │   (Riverpod Providers) │              │
│  └────────────┬───────────┘              │
├───────────────┼──────────────────────────┤
│          DOMAIN LAYER                    │
│  ┌────────────▼───────────┐              │
│  │   Use Cases / Services │              │
│  │   • RideService       │              │
│  │   • TrackingService   │              │
│  │   • AuthService       │              │
│  │   • EmergencyService  │              │
│  └────────────┬───────────┘              │
│  ┌────────────▼───────────┐              │
│  │   Models / Entities    │              │
│  └────────────┬───────────┘              │
├───────────────┼──────────────────────────┤
│            DATA LAYER                    │
│  ┌────────────▼───────────┐              │
│  │   Repositories         │              │
│  │   • RideRepository    │              │
│  │   • UserRepository    │              │
│  │   • LocationRepository│              │
│  └────────────┬───────────┘              │
│  ┌────────────▼───────────┐              │
│  │   Data Sources         │              │
│  │   • Firebase Remote   │              │
│  │   • Local Storage     │              │
│  │   • GPS/Location      │              │
│  └────────────────────────┘              │
└──────────────────────────────────────────┘
```

### 3.2 Folder Structure

```
lib/
├── main.dart
├── app.dart                          # MaterialApp configuration
├── core/
│   ├── constants/
│   │   ├── app_constants.dart        # App-wide constants
│   │   ├── firebase_constants.dart   # Collection names, paths
│   │   └── ride_constants.dart       # Ride-specific constants
│   ├── theme/
│   │   ├── app_theme.dart            # ThemeData
│   │   ├── app_colors.dart           # Color palette
│   │   └── app_typography.dart       # Text styles
│   ├── utils/
│   │   ├── location_utils.dart       # Distance calculation, etc
│   │   ├── battery_utils.dart        # Battery optimization helpers
│   │   └── date_utils.dart
│   ├── errors/
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   └── services/
│       ├── background_location_service.dart
│       ├── notification_service.dart
│       └── connectivity_service.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   └── datasources/
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   └── services/
│   │   └── presentation/
│   │       ├── screens/
│   │       ├── widgets/
│   │       └── providers/
│   │
│   ├── ride/                         # Create & Join Ride
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── tracking/                     # Live Tracking
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── dashboard/                    # Leader Dashboard
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── emergency/                    # Emergency Button
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── summary/                      # Ride Summary
│       ├── data/
│       ├── domain/
│       └── presentation/
│
├── shared/
│   ├── widgets/
│   │   ├── big_action_button.dart    # Tombol besar untuk riding
│   │   ├── rider_avatar.dart
│   │   ├── status_indicator.dart
│   │   └── map_view.dart
│   └── providers/
│       └── common_providers.dart
│
└── routing/
    └── app_router.dart               # GoRouter configuration
```

### 3.3 Technology Stack (Client)

| Kategori             | Package                                                                                        | Alasan                                            |
| -------------------- | ---------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| **State Management** | `flutter_riverpod`                                                                             | Compile-safe, testable, cocok untuk complex state |
| **Routing**          | `go_router`                                                                                    | Declarative routing, deep linking support         |
| **Maps**             | `google_maps_flutter`                                                                          | Paling mature untuk Flutter                       |
| **Location**         | `geolocator` + `flutter_background_geolocation`                                                | Background tracking yang reliable                 |
| **Local Storage**    | `hive`                                                                                         | Fast NoSQL, cocok untuk cache lokasi              |
| **DI**               | Built-in Riverpod                                                                              | Sudah termasuk dalam Riverpod                     |
| **Firebase**         | `firebase_core`, `cloud_firestore`, `firebase_auth`, `firebase_database`, `firebase_messaging` | Official packages                                 |
| **Notifications**    | `flutter_local_notifications`                                                                  | Local notification untuk alert                    |
| **Connectivity**     | `connectivity_plus`                                                                            | Monitor network status                            |
| **Permissions**      | `permission_handler`                                                                           | Handle location permissions                       |
| **Battery**          | `battery_plus`                                                                                 | Monitor battery level                             |

---

## 4. Struktur Data Utama

### 4.1 Entity Relationship Diagram

```
┌─────────────┐       ┌─────────────────┐       ┌──────────────┐
│    User      │       │      Ride       │       │  Checkpoint  │
│─────────────│  1:N  │─────────────────│  1:N  │──────────────│
│ uid          │◄──────│ rideId          │──────►│ checkpointId │
│ displayName  │       │ title           │       │ rideId       │
│ phone        │       │ leaderId        │       │ name         │
│ photoUrl     │       │ status          │       │ lat          │
│ createdAt    │       │ startPoint      │       │ lng          │
│              │       │ endPoint        │       │ radius       │
│              │       │ checkpoints[]   │       │ order        │
│              │       │ scheduledAt     │       │ arrivedCount │
│              │       │ createdAt       │       └──────────────┘
│              │       │ endedAt         │
└──────┬───────┘       └────────┬────────┘
       │                        │
       │    ┌───────────────┐   │
       │    │  RideParticipant│  │
       │ N:M│───────────────│  │
       └────│ odId           │──┘
            │ rideId         │
            │ userId         │
            │ role           │    ┌──────────────────┐
            │ status         │    │  LocationUpdate   │
            │ joinedAt       │    │──────────────────│
            │ lastLocation   │───►│ odId              │
            │ lastSpeed      │    │ oderId/odId       │
            │ batteryLevel   │    │ lat               │
            │ isOnline       │    │ lng               │
            └────────────────┘    │ speed             │
                                  │ heading           │
            ┌────────────────┐    │ altitude          │
            │  Emergency     │    │ accuracy          │
            │────────────────│    │ batteryLevel      │
            │ emergencyId    │    │ timestamp         │
            │ rideId         │    └──────────────────┘
            │ userId         │
            │ type           │
            │ lat            │
            │ lng            │
            │ message        │
            │ status         │
            │ respondedBy    │
            │ timestamp      │
            └────────────────┘
```

### 4.2 Data Models Detail

#### **User**

```dart
class UserModel {
  final String uid;
  final String displayName;
  final String phone;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastActiveAt;
}
```

> **Storage**: Cloud Firestore → `users/{uid}`

#### **Ride**

```dart
class RideModel {
  final String rideId;
  final String title;
  final String description;
  final String leaderId;        // userId of leader
  final String? sweeperId;      // userId of sweeper (penyapu)
  final RideStatus status;      // draft, active, paused, completed, cancelled
  final GeoPoint startPoint;
  final String startAddress;
  final GeoPoint endPoint;
  final String endAddress;
  final List<Checkpoint> checkpoints;
  final DateTime scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String joinCode;        // 6-digit code untuk join
  final int maxParticipants;
  final RideSettings settings;
  final DateTime createdAt;
}

class RideSettings {
  final double maxDistanceFromLeader;  // meter, trigger alert jika terlalu jauh
  final double maxSpeedLimit;          // km/h
  final int locationUpdateInterval;    // detik
  final bool enableSpeedAlert;
  final bool enableDistanceAlert;
}

enum RideStatus {
  draft,      // Ride dibuat, belum dimulai
  active,     // Sedang berlangsung
  paused,     // Istirahat/checkpoint
  completed,  // Selesai
  cancelled,  // Dibatalkan
}
```

> **Storage**: Cloud Firestore → `rides/{rideId}`

#### **RideParticipant**

```dart
class RideParticipant {
  final String odId;            // document ID
  final String rideId;
  final String userId;
  final ParticipantRole role;   // leader, sweeper, member
  final ParticipantStatus status; // joined, riding, arrived, left, emergency
  final GeoPoint? lastLocation;
  final double? lastSpeed;      // km/h
  final double? heading;        // bearing/direction
  final int? batteryLevel;      // 0-100
  final bool isOnline;
  final DateTime joinedAt;
  final DateTime? lastLocationUpdate;
}

enum ParticipantRole {
  leader,     // Pemimpin rombongan
  sweeper,    // Penyapu (paling belakang, memastikan tidak ada yg tertinggal)
  member,     // Anggota biasa
}

enum ParticipantStatus {
  joined,     // Sudah join, belum mulai riding
  riding,     // Sedang dalam perjalanan
  checkpoint, // Sudah sampai di checkpoint
  arrived,    // Sudah sampai tujuan akhir
  left,       // Keluar dari ride
  emergency,  // Dalam keadaan darurat
}
```

> **Storage**: Cloud Firestore → `rides/{rideId}/participants/{odId}`

#### **LocationUpdate** (High-frequency data)

```dart
class LocationUpdate {
  final String odId;
  final String oderId;          // reference ke participant
  final double lat;
  final double lng;
  final double speed;           // km/h
  final double heading;         // 0-360 degrees
  final double altitude;        // meter
  final double accuracy;        // meter
  final int batteryLevel;
  final DateTime timestamp;
}
```

> **Storage**: Firebase Realtime Database → `rides/{rideId}/locations/{userId}`
>
> ⚠️ **Mengapa Realtime DB dan bukan Firestore?**
>
> - Realtime DB lebih murah untuk high-frequency writes
> - Latency lebih rendah untuk location streaming
> - Billing model per-data, bukan per-read/write operation
> - Firestore digunakan untuk data yang jarang berubah (ride, user, participants)

#### **Emergency**

```dart
class EmergencyModel {
  final String emergencyId;
  final String rideId;
  final String userId;
  final EmergencyType type;     // breakdown, accident, lost, medical, other
  final GeoPoint location;
  final String? message;
  final EmergencyStatus status; // active, responding, resolved
  final String? respondedBy;    // userId yang merespons
  final DateTime timestamp;
  final DateTime? resolvedAt;
}

enum EmergencyType {
  breakdown,  // Motor mogok
  accident,   // Kecelakaan
  lost,       // Tersesat/tertinggal jauh
  medical,    // Masalah kesehatan
  other,      // Lainnya
}
```

> **Storage**: Cloud Firestore → `rides/{rideId}/emergencies/{emergencyId}`

#### **RideSummary** (Generated saat ride selesai)

```dart
class RideSummary {
  final String rideId;
  final String title;
  final Duration totalDuration;
  final double totalDistanceKm;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final int totalParticipants;
  final int totalCheckpoints;
  final int emergencyCount;
  final List<ParticipantSummary> participantSummaries;
  final List<GeoPoint> routePolyline;  // Simplified route
  final DateTime completedAt;
}

class ParticipantSummary {
  final String userId;
  final String displayName;
  final double distanceTraveled;
  final double avgSpeed;
  final double maxSpeed;
  final int checkpointsReached;
  final Duration ridingDuration;
}
```

> **Storage**: Cloud Firestore → `ride_summaries/{rideId}`

---

## 5. Data Flow Diagrams

### 5.1 Create & Join Ride Flow

```
LEADER                          FIRESTORE                    MEMBER
  │                                │                           │
  │─── Create Ride ───────────────►│                           │
  │    (title, route, checkpoints) │                           │
  │                                │                           │
  │◄── Return joinCode (6-digit) ──│                           │
  │                                │                           │
  │─── Share joinCode ─────────────┼──────────────────────────►│
  │    (via WhatsApp/verbal)       │                           │
  │                                │                           │
  │                                │◄── Enter joinCode ────────│
  │                                │    Join Ride              │
  │                                │                           │
  │                                │──► Add to participants ──►│
  │                                │    Notify leader          │
  │◄── New member notification ────│                           │
  │                                │                           │
  │─── Start Ride ────────────────►│                           │
  │    (status → active)           │──► Notify all ───────────►│
  │                                │    "Ride dimulai!"        │
```

### 5.2 Live Tracking Flow

```
┌──────────────────────────────────────────────────────────────┐
│                    SETIAP DEVICE (MEMBER)                     │
│                                                              │
│  GPS Sensor ──► Background Service ──► Throttle (5-10 sec)   │
│                                              │               │
│                                    ┌─────────▼──────────┐    │
│                                    │ Firebase RTDB       │    │
│                                    │ /rides/{id}/        │    │
│                                    │  locations/{userId} │    │
│                                    └─────────┬──────────┘    │
└──────────────────────────────────────────────┼───────────────┘
                                               │
                                    ┌──────────▼──────────┐
                                    │  REALTIME LISTENER   │
                                    │  (semua participant  │
                                    │   listen ke semua    │
                                    │   location updates)  │
                                    └──────────┬──────────┘
                                               │
                              ┌────────────────┼────────────────┐
                              │                │                │
                    ┌─────────▼──┐   ┌────────▼─────┐  ┌──────▼───────┐
                    │ Map View    │   │ Leader       │  │ Alert        │
                    │ (semua user │   │ Dashboard    │  │ Engine       │
                    │  see pins)  │   │ (bird-eye)   │  │ (distance,   │
                    └─────────────┘   └──────────────┘  │  speed)      │
                                                        └──────────────┘
```

### 5.3 Emergency Flow

```
MEMBER (darurat)              FIREBASE                 LEADER + ALL MEMBERS
     │                           │                           │
     │── TEKAN EMERGENCY ──────►│                           │
     │   BUTTON (3 sec hold)    │                           │
     │                          │                           │
     │   Auto-capture:          │                           │
     │   • GPS location         │                           │
     │   • Timestamp            │                           │
     │   • Battery level        │                           │
     │                          │                           │
     │                          │── FCM Push Notification ─►│
     │                          │   "⚠️ DARURAT!"           │
     │                          │   + lokasi di map         │
     │                          │                           │
     │                          │   Participant status      │
     │                          │   → "emergency"           │
     │                          │                           │
     │                          │◄── Leader responds ───────│
     │◄── Notification ─────────│   "Bantuan menuju"        │
     │   "Leader merespons"     │                           │
```

---

## 6. Strategi Penyimpanan Data

### 6.1 Database Split Strategy

| Data               | Storage         | Alasan                                 |
| ------------------ | --------------- | -------------------------------------- |
| User profile       | Firestore       | Jarang berubah, butuh query            |
| Ride metadata      | Firestore       | CRUD biasa, offline support            |
| Participants       | Firestore       | Medium frequency updates               |
| **Live locations** | **Realtime DB** | **High frequency, low latency kritis** |
| Emergencies        | Firestore       | Butuh persistence & query              |
| Ride summaries     | Firestore       | Read-heavy, generated sekali           |
| Location history   | Hive (local)    | Cache untuk route playback             |

### 6.2 Data Lifecycle

```
RIDE LIFECYCLE:

  ┌─────┐    ┌────────┐    ┌────────┐    ┌────────┐    ┌──────────┐
  │Draft │───►│ Active │───►│Paused  │───►│ Active │───►│Completed │
  └─────┘    └────────┘    └────────┘    └────────┘    └──────────┘
                 │                                          │
                 │              ┌──────────┐                │
                 └─────────────►│Cancelled │                │
                                └──────────┘                │
                                                            │
                                              ┌─────────────▼──────┐
                                              │ Generate Summary    │
                                              │ Clean up RTDB data │
                                              │ Archive locations   │
                                              └────────────────────┘
```

**Setelah Ride selesai:**

1. Cloud Function generate `RideSummary` dari location history
2. Location data di RTDB di-delete (hemat storage)
3. Summary disimpan permanen di Firestore

---

## 7. Risiko Teknis Utama

### 🔴 CRITICAL RISKS

#### R1: Background Location Tracking yang Unreliable

| Aspek            | Detail                                                                                                                                                                                                                                                                    |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Risiko**       | OS Android & iOS agresif kill background processes. Location tracking bisa mati tanpa notifikasi                                                                                                                                                                          |
| **Impact**       | Leader kehilangan visibility anggota → tujuan utama app gagal                                                                                                                                                                                                             |
| **Probabilitas** | TINGGI — ini masalah umum di semua location tracking app                                                                                                                                                                                                                  |
| **Mitigasi**     | 1. Gunakan `flutter_background_geolocation` (paling reliable) <br> 2. Foreground notification persistent <br> 3. Heartbeat system: jika tidak ada update > 30 detik, tandai user sebagai "signal lost" <br> 4. Panduan user untuk disable battery optimization per device |
| **Fallback**     | Manual check-in di setiap checkpoint sebagai backup                                                                                                                                                                                                                       |

#### R2: Konsumsi Baterai Berlebihan

| Aspek            | Detail                                                                                                                                                                                                                                                                                                                                               |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Risiko**       | GPS + network continuous drain baterai cepat. Touring bisa 6-12 jam                                                                                                                                                                                                                                                                                  |
| **Impact**       | HP mati di tengah jalan → tidak bisa tracking & komunikasi                                                                                                                                                                                                                                                                                           |
| **Probabilitas** | TINGGI                                                                                                                                                                                                                                                                                                                                               |
| **Mitigasi**     | 1. **Adaptive interval**: jarak dekat → update 15 detik, jauh → 5 detik <br> 2. **Batch upload**: kumpulkan 5-10 location points, kirim sekaligus <br> 3. **Monitor battery**: alert leader jika ada anggota battery < 20% <br> 4. **Low power mode**: kurangi akurasi GPS saat battery < 15% <br> 5. **Recommend**: user bawa power bank + mount HP |
| **Target**       | < 10% battery drain per jam (industry standard untuk tracking app)                                                                                                                                                                                                                                                                                   |

#### R3: Koneksi Internet Tidak Stabil

| Aspek            | Detail                                                                                                                                                                                                                                                                                                                                                               |
| ---------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Risiko**       | Touring antar kota melewati area tanpa sinyal (pegunungan, hutan)                                                                                                                                                                                                                                                                                                    |
| **Impact**       | Live tracking terputus, emergency button tidak berfungsi                                                                                                                                                                                                                                                                                                             |
| **Probabilitas** | TINGGI — Indonesia punya banyak "dead zone"                                                                                                                                                                                                                                                                                                                          |
| **Mitigasi**     | 1. **Offline queue**: simpan location updates lokal, sync saat ada sinyal <br> 2. **Firestore offline mode**: otomatis sync saat reconnect <br> 3. **Last known position**: selalu tampilkan posisi terakhir yang diketahui <br> 4. **Offline indicator**: jelas tampilkan siapa yang sedang offline <br> 5. **SMS fallback** untuk emergency (future consideration) |

### 🟡 MODERATE RISKS

#### R4: Akurasi GPS di Kecepatan Tinggi

| Aspek            | Detail                                                                                                                        |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **Risiko**       | GPS accuracy menurun di kecepatan tinggi, terutama di dalam kota dengan gedung tinggi                                         |
| **Impact**       | Posisi di map tidak akurat, jarak calculation salah                                                                           |
| **Probabilitas** | MEDIUM                                                                                                                        |
| **Mitigasi**     | 1. Filter lokasi dengan accuracy > 50m <br> 2. Tampilkan accuracy radius di map <br> 3. Gunakan Kalman filter untuk smoothing |

#### R5: Scalability dengan Banyak Peserta

| Aspek            | Detail                                                                                                                                    |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| **Risiko**       | 50+ rider broadcast location setiap 5-10 detik → banyak reads di RTDB                                                                     |
| **Impact**       | Biaya Firebase membengkak, app lag                                                                                                        |
| **Probabilitas** | LOW-MEDIUM (komunitas biasanya < 30 orang)                                                                                                |
| **Mitigasi**     | 1. Limit peserta per ride (default: 50) <br> 2. Cluster nearby riders di map <br> 3. Progressive loading (load detail hanya saat zoom in) |

#### R6: Keamanan & Privasi Lokasi

| Aspek            | Detail                                                                                                                                                                                                 |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Risiko**       | Data lokasi real-time adalah data sensitif                                                                                                                                                             |
| **Impact**       | Jika bocor, bisa disalahgunakan                                                                                                                                                                        |
| **Probabilitas** | LOW                                                                                                                                                                                                    |
| **Mitigasi**     | 1. Firestore security rules ketat: hanya participant bisa lihat lokasi <br> 2. Location data di-delete setelah ride selesai <br> 3. Join code expire setelah ride dimulai <br> 4. Tidak ada public API |

### 🟢 LOW RISKS

#### R7: Multi-platform Consistency

| Aspek            | Detail                                                                                     |
| ---------------- | ------------------------------------------------------------------------------------------ |
| **Risiko**       | Perilaku background service berbeda antara Android dan iOS                                 |
| **Probabilitas** | LOW (Flutter abstraction + package handle ini)                                             |
| **Mitigasi**     | Testing di kedua platform, prioritas Android dulu (mayoritas komunitas motor di Indonesia) |

---

## 8. Keputusan Arsitektur (ADR)

### ADR-001: Dual Database (Firestore + Realtime DB)

- **Keputusan**: Menggunakan Firestore untuk data general + Realtime DB untuk live location
- **Alasan**: Optimasi biaya dan latency. Firestore charge per-operation (mahal untuk high-frequency writes), Realtime DB charge per-bandwidth (lebih murah untuk streaming data kecil)

### ADR-002: Riverpod untuk State Management

- **Keputusan**: Menggunakan Riverpod instead of BLoC/Provider
- **Alasan**: Type-safe, testable, no context dependency, better untuk complex async streams (cocok untuk location streaming)

### ADR-003: Feature-First Folder Structure

- **Keputusan**: Organize by feature, bukan by type
- **Alasan**: Scalability — setiap fitur is self-contained, mudah di-maintain

### ADR-004: Join Code Instead of Invite Link

- **Keputusan**: 6-digit alphanumeric code untuk join ride
- **Alasan**: Sederhana, bisa dishare verbal saat briefing, tidak perlu URL/deep link handling untuk MVP

### ADR-005: Foreground Service untuk Tracking

- **Keputusan**: Selalu menampilkan persistent notification saat tracking aktif
- **Alasan**: Regulatory requirement di Android 10+ untuk background location, plus memberikan user awareness bahwa GPS aktif

---

## 9. Security Architecture

### 9.1 Authentication Flow

```
┌──────────┐     ┌──────────────┐     ┌─────────────┐
│ User     │────►│ Firebase Auth │────►│ Custom      │
│ Login    │     │ (Phone/Email) │     │ Claims      │
└──────────┘     └──────────────┘     │ (role info) │
                                      └─────────────┘
```

### 9.2 Firestore Security Rules (Simplified)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can only read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }

    // Rides: creator can write, participants can read
    match /rides/{rideId} {
      allow read: if isParticipant(rideId);
      allow create: if request.auth != null;
      allow update: if isLeader(rideId);

      // Participants subcollection
      match /participants/{participantId} {
        allow read: if isParticipant(rideId);
        allow create: if request.auth != null;
        allow update: if request.auth.uid == resource.data.userId
                      || isLeader(rideId);
      }

      // Emergencies subcollection
      match /emergencies/{emergencyId} {
        allow read: if isParticipant(rideId);
        allow create: if isParticipant(rideId);
        allow update: if isLeader(rideId);
      }
    }
  }
}
```

---

## 10. Strategi Implementasi MVP

### Phase 1: Foundation (Week 1-2)

- [ ] Setup project structure & dependencies
- [ ] Firebase project setup (Auth, Firestore, RTDB)
- [ ] Authentication (phone number / email)
- [ ] User profile CRUD
- [ ] Basic theme & design system

### Phase 2: Core Ride (Week 3-4)

- [ ] Create Ride (dengan checkpoints)
- [ ] Join Ride (via 6-digit code)
- [ ] Ride status management (draft → active → completed)
- [ ] Participant list view

### Phase 3: Live Tracking (Week 5-7)

- [ ] Background location service setup
- [ ] Location streaming ke RTDB
- [ ] Map view dengan semua rider pins
- [ ] Distance & speed alert engine
- [ ] Leader dashboard (bird-eye view)
- [ ] Battery monitoring & optimization

### Phase 4: Safety Features (Week 8-9)

- [ ] Emergency button (long press)
- [ ] Emergency notification (FCM)
- [ ] Emergency response flow
- [ ] Checkpoint arrival detection (geofencing)

### Phase 5: Summary & Polish (Week 10-11)

- [ ] Ride summary generation
- [ ] Route replay/review
- [ ] UI polish & dari prinsip desain
- [ ] Battery optimization testing
- [ ] Offline scenario testing

### Phase 6: Testing & Launch (Week 12)

- [ ] Integration testing
- [ ] Field testing (real touring)
- [ ] Bug fixing
- [ ] Beta release ke komunitas

---

## 11. Non-Functional Requirements

| Requirement                  | Target                | Measurement                      |
| ---------------------------- | --------------------- | -------------------------------- |
| **Location update latency**  | < 3 detik             | Time from GPS read to map update |
| **Battery drain**            | < 10% per jam         | Lab testing di 3 device berbeda  |
| **Offline tolerance**        | 10 menit tanpa sinyal | Queue & sync saat reconnect      |
| **App startup**              | < 3 detik             | Cold start ke home screen        |
| **Map rendering**            | 30+ FPS               | Dengan 30 rider pins aktif       |
| **Emergency alert delivery** | < 5 detik             | FCM delivery time                |
| **Minimum Android**          | Android 8.0 (API 26)  |                                  |
| **Minimum iOS**              | iOS 14.0              |                                  |

---

## 12. Pertanyaan Terbuka untuk Didiskusikan

1. **Authentication method**: Phone number (via OTP) atau Email + Password? Phone number lebih cocok untuk komunitas motor, tapi butuh biaya SMS.

2. **Map provider**: Google Maps (paling akurat di Indonesia, tapi berbayar di scale besar) atau Mapbox (lebih murah, tapi kurang akurat untuk jalan kecil)?

3. **Ride creation**: Apakah leader harus menentukan route lengkap di awal, atau cukup start point + end point + checkpoints?

4. **Sweeper role**: Apakah perlu role khusus "sweeper" (orang paling belakang) sebagai fitur MVP, atau cukup leader saja?

5. **Jumlah maksimal peserta per ride**: Berapa batas yang masuk akal? Saran: 50 orang sebagai default.

6. **Offline emergency**: Jika tidak ada sinyal, apakah emergency button tetap harus bisa trigger SMS ke leader? (butuh SMS permission)

---

_Dokumen ini harus di-review dan disetujui sebelum memulai implementasi._
