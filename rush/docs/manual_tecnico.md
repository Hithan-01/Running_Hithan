# Manual Técnico — RUSH

> **RUSH** — App de running gamificada para la Universidad de Montemorelos
> Versión: 5.x | Framework: Flutter | Plataformas: Android / iOS

---

## Tabla de Contenidos

1. [Resumen del Sistema](#1-resumen-del-sistema)
2. [Stack Tecnológico](#2-stack-tecnológico)
3. [Arquitectura de la Aplicación](#3-arquitectura-de-la-aplicación)
4. [Modelos de Datos](#4-modelos-de-datos)
5. [Base de Datos Local (Hive)](#5-base-de-datos-local-hive)
6. [Servicios](#6-servicios)
7. [Gestión de Estado (Provider)](#7-gestión-de-estado-provider)
8. [Autenticación (Firebase Auth)](#8-autenticación-firebase-auth)
9. [Sincronización (Firebase / Firestore)](#9-sincronización-firebase--firestore)
10. [Mapas y GPS](#10-mapas-y-gps)
11. [Sistema de Gamificación](#11-sistema-de-gamificación)
12. [Notificaciones Locales](#12-notificaciones-locales)
13. [Audio Coach (TTS)](#13-audio-coach-tts)
14. [Dependencias Completas](#14-dependencias-completas)
15. [Permisos Requeridos](#15-permisos-requeridos)
16. [Configuración de Firebase](#16-configuración-de-firebase)

---

## 1. Resumen del Sistema

RUSH es una aplicación móvil multiplataforma (Android/iOS) desarrollada con Flutter. Permite a los usuarios registrar carreras con GPS, acumular puntos de experiencia (XP), desbloquear logros, completar misiones y competir en una tabla de clasificación. Los datos se almacenan localmente con Hive y se sincronizan con Firebase cuando hay conexión.

---

## 2. Stack Tecnológico

| Tecnología | Versión | Rol |
|------------|---------|-----|
| Flutter | 3.9+ | Framework UI multiplataforma |
| Dart | 3.x | Lenguaje de programación |
| Hive CE | 2.7.0 | Base de datos NoSQL local |
| Firebase Auth | 6.1.4 | Autenticación de usuarios |
| Cloud Firestore | 6.1.2 | Sincronización en la nube |
| flutter_map | 8.2.2 | Mapas basados en OpenStreetMap |
| Geolocator | 14.0.2 | Tracking GPS |
| Provider | 6.1.0 | Gestión de estado |
| flutter_local_notifications | 18.0.1 | Notificaciones locales |
| flutter_tts | 4.2.0 | Text-to-Speech (Audio Coach) |

---

## 3. Arquitectura de la Aplicación

La aplicación sigue una arquitectura en capas limpia:

```
┌──────────────────────────────────────────────┐
│            Capa de Presentación              │
│         Screens + Widgets (Flutter UI)       │
├──────────────────────────────────────────────┤
│             Capa de Estado                   │
│           Provider (ChangeNotifier)          │
├──────────────────────────────────────────────┤
│             Capa de Servicios                │
│  ┌──────────┬──────────┬──────────────────┐  │
│  │Location  │Database  │  Gamification    │  │
│  │Service   │Service   │  Service         │  │
│  ├──────────┼──────────┼──────────────────┤  │
│  │Notific.  │  Audio   │  Sync Service    │  │
│  │Service   │  Coach   │  (Firebase)      │  │
│  └──────────┴──────────┴──────────────────┘  │
├──────────────────────────────────────────────┤
│              Capa de Datos                   │
│      Hive (local) + Firebase (nube)          │
└──────────────────────────────────────────────┘
```

### Flujo de inicialización (`main.dart`)

```
1. WidgetsFlutterBinding.ensureInitialized()
2. Firebase.initializeApp()
3. DatabaseService.init()  ← Hive boxes
4. NotificationService.init()
5. AudioCoachService.init()
6. MultiProvider setup (LocationService, GamificationService)
7. runApp(RushApp)
```

---

## 4. Modelos de Datos

Todos los modelos usan **anotaciones de Hive** para persistencia local. Se generan con `build_runner`.

### User (TypeId: 0)

```dart
class User extends HiveObject {
  String id;           // UUID
  String username;     // Nombre de usuario
  String email;        // Correo Firebase
  int xp;             // XP acumulado total
  int level;          // Nivel calculado (1-6)
  double totalDistance; // Km totales
  int totalRuns;       // Número de carreras
  int currentStreak;   // Racha de días activos
  String? profilePhotoPath; // Ruta foto local
  DateTime createdAt;
  DateTime lastActiveAt;
}
```

### Run (TypeId: 1)

```dart
class Run extends HiveObject {
  String id;
  String userId;
  DateTime startTime;
  DateTime? endTime;
  double distanceKm;
  Duration duration;
  double paceMinPerKm;
  int xpEarned;
  List<RunPoint> route;    // Lista de coordenadas GPS
  bool syncedToFirebase;
}
```

### RunPoint (TypeId: 2)

```dart
class RunPoint {
  double latitude;
  double longitude;
  DateTime timestamp;
}
```

### Achievement (TypeId: 3)

```dart
class Achievement {
  String id;
  String title;
  String description;
  String icon;
  int xpReward;
  String category;  // exploration, distance, consistency, speed, secrets
}
```

### UnlockedAchievement (TypeId: 4)

```dart
class UnlockedAchievement extends HiveObject {
  String achievementId;
  String userId;
  DateTime unlockedAt;
}
```

### Poi (TypeId: 5)

```dart
class Poi {
  String id;
  String name;
  double latitude;
  double longitude;
  String category;  // academic, sports, landmark
  int xpReward;
  String description;
}
```

### Mission (TypeId: 7)

```dart
class Mission {
  String id;
  String title;
  String description;
  String type;         // daily / weekly
  double targetValue;  // Ej: 2.0 (km), 15 (minutos)
  String metric;       // distance, duration, pois, runs
  int xpReward;
}
```

### ActiveMission (TypeId: 8)

```dart
class ActiveMission extends HiveObject {
  String missionId;
  String userId;
  double progress;   // Progreso actual
  bool completed;
  DateTime assignedAt;
  DateTime? completedAt;
}
```

---

## 5. Base de Datos Local (Hive)

Hive CE es la base de datos principal. Todos los datos persisten localmente en el dispositivo.

### Boxes registradas

| Box | Tipo de valor | Descripción |
|-----|---------------|-------------|
| `users` | `User` | Datos del perfil local |
| `runs` | `Run` | Historial de carreras |
| `achievements` | `UnlockedAchievement` | Logros desbloqueados |
| `visited_pois` | `VisitedPoi` | Registro de POIs visitados |
| `active_missions` | `ActiveMission` | Misiones en progreso |
| `notification_history` | `NotificationItem` | Historial de notificaciones |

### Inicialización

```dart
await Hive.initFlutter();
Hive.registerAdapter(UserAdapter());
Hive.registerAdapter(RunAdapter());
Hive.registerAdapter(RunPointAdapter());
Hive.registerAdapter(AchievementAdapter());
Hive.registerAdapter(UnlockedAchievementAdapter());
Hive.registerAdapter(PoiAdapter());
Hive.registerAdapter(VisitedPoiAdapter());
Hive.registerAdapter(MissionAdapter());
Hive.registerAdapter(ActiveMissionAdapter());
Hive.registerAdapter(NotificationItemAdapter());

await Hive.openBox<User>('users');
await Hive.openBox<Run>('runs');
// ... etc
```

---

## 6. Servicios

### DatabaseService

Centraliza todas las operaciones CRUD sobre Hive. Es un singleton.

**Métodos principales:**

| Método | Descripción |
|--------|-------------|
| `saveUser(User)` | Guarda o actualiza el usuario |
| `getUser(String id)` | Obtiene usuario por ID |
| `saveRun(Run)` | Guarda una carrera completada |
| `getRuns(String userId)` | Obtiene todas las carreras del usuario |
| `saveUnlockedAchievement(...)` | Registra un logro desbloqueado |
| `getUnlockedAchievements(...)` | Lista logros del usuario |
| `saveVisitedPoi(...)` | Registra visita a un POI |
| `getVisitedPois(String userId)` | Lista POIs visitados |
| `getActiveMissions(...)` | Obtiene misiones activas |
| `updateMissionProgress(...)` | Actualiza progreso de una misión |

---

### GamificationService

Extiende `ChangeNotifier`. Gestiona toda la lógica de XP, niveles, misiones y logros.

**Responsabilidades:**
- Calcular XP ganado por carrera
- Verificar y desbloquear achievements tras cada carrera
- Actualizar progreso de misiones activas
- Resetear misiones diarias/semanales
- Notificar a la UI sobre cambios de estado

**Métodos clave:**

| Método | Descripción |
|--------|-------------|
| `processRunCompletion(Run, List<VisitedPoi>)` | Punto de entrada tras finalizar una carrera |
| `calculateXpForRun(Run)` | Calcula XP base (km + minutos + bonos) |
| `checkAchievements(User, Run)` | Evalúa si se cumplen condiciones de logros |
| `updateMissions(Run, List<VisitedPoi>)` | Actualiza progreso de misiones |
| `resetDailyMissions()` | Genera nuevas misiones diarias |
| `resetWeeklyMissions()` | Genera nuevas misiones semanales |
| `getLevelName(int level)` | Retorna nombre del nivel (ej. "Campus Jogger") |

**Fórmula de XP:**

```
XP = (distanciaKm × 50) + (minutos × 2) + xpPOIs + xpMisiones
```

**Umbrales de nivel:**

```dart
static const levelThresholds = [0, 500, 1500, 3500, 7000, 15000];
```

---

### LocationService

Extiende `ChangeNotifier`. Gestiona el GPS y el tracking de rutas.

**Estados:**
- `idle` — Sin carrera activa
- `running` — Carrera en progreso
- `paused` — Pausada

**Funcionalidades:**
- Iniciar/pausar/reanudar/detener tracking
- Acumular puntos GPS en `List<RunPoint>`
- Calcular distancia usando la fórmula de Haversine
- Detectar proximidad a POIs (radio 30m) durante la carrera
- Modo simulación para pruebas sin GPS real

**Configuración GPS:**

```dart
LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 5, // metros entre actualizaciones
)
```

---

### NotificationService

Gestiona notificaciones locales con `flutter_local_notifications`.

**Canales:**
- `run_notifications` — Alertas de carrera
- `achievement_notifications` — Logros desbloqueados
- `mission_notifications` — Misiones nuevas/completadas
- `reminder_notifications` — Recordatorios de actividad

---

### AudioCoachService

Usa `flutter_tts` para proporcionar feedback de voz durante las carreras.

**Anuncios automáticos:**
- Cada kilómetro completado
- Cada 5 minutos de carrera
- Al visitar un POI
- Al desbloquear un logro

---

### SyncService

Maneja la sincronización de carreras locales con Cloud Firestore.

**Lógica:**
1. Al finalizar una carrera, se guarda localmente con `syncedToFirebase = false`
2. `SyncService` verifica conectividad periódicamente
3. Sube carreras pendientes a Firestore
4. Marca como `syncedToFirebase = true`

---

## 7. Gestión de Estado (Provider)

El estado de la aplicación se gestiona con el paquete `provider`.

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => LocationService()),
    ChangeNotifierProvider(create: (_) => GamificationService()),
  ],
  child: RushApp(),
)
```

Los widgets acceden al estado con:
```dart
final location = context.watch<LocationService>();
final gamification = context.read<GamificationService>();
```

---

## 8. Autenticación (Firebase Auth)

Se utiliza Firebase Authentication con el proveedor **Email/Password**.

**Flujo:**
1. Usuario ingresa email y contraseña
2. `firebase_auth` verifica credenciales
3. Al autenticarse, se crea/carga el usuario en Hive con el UID de Firebase como `id`
4. Las sesiones persisten automáticamente entre lanzamientos de la app

---

## 9. Sincronización (Firebase / Firestore)

**Colecciones de Firestore:**

| Colección | Documentos | Uso |
|-----------|-----------|-----|
| `users` | `{userId}` | Perfil público (username, xp, level) |
| `runs` | `{runId}` | Historial de carreras sincronizadas |

**Política de conflictos:**
- Hive es la fuente de verdad local.
- Firestore recibe réplica de los datos para el leaderboard.
- En caso de conflicto, prevalece el dato más reciente.

---

## 10. Mapas y GPS

### flutter_map + OpenStreetMap

Los mapas se renderizan usando tiles de OpenStreetMap, sin necesidad de API key ni costo.

```dart
FlutterMap(
  options: MapOptions(
    center: LatLng(25.192661, -99.845885), // Campus UM
    zoom: 17.0,
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    ),
    MarkerLayer(markers: poiMarkers),
    PolylineLayer(polylines: routePolylines),
  ],
)
```

### Detección de POIs

La detección usa distancia Haversine con radio de 30 metros:

```dart
double distanceTo(LatLng a, LatLng b) {
  // Fórmula de Haversine
  // Retorna distancia en metros
}

if (distanceTo(userPosition, poi.position) <= 30) {
  // POI visitado
}
```

---

## 11. Sistema de Gamificación

### Cálculo de XP por carrera

```
xpBase = (distanciaKm × 50) + (duracionMinutos × 2)
xpPOIs = suma de xpReward de POIs visitados
xpTotal = xpBase + xpPOIs
```

### Verificación de logros

Cada logro tiene una condición evaluada tras cada carrera:

```dart
// Ejemplo: Logro "Primer Kilómetro"
if (user.totalDistance >= 1.0 && !alreadyUnlocked('first_km')) {
  unlockAchievement('first_km');
}

// Ejemplo: Logro "Pi Runner"
if ((run.distanceKm - 3.14).abs() < 0.05) {
  unlockAchievement('pi_runner');
}
```

### Reset de misiones

```dart
// Diarias: se resetean cada medianoche
if (lastResetDate != today) {
  await resetDailyMissions();
}

// Semanales: se resetean cada lunes
if (lastWeeklyReset.weekday != DateTime.monday) {
  await resetWeeklyMissions();
}
```

---

## 12. Notificaciones Locales

Las notificaciones se programan con `flutter_local_notifications` y la zona horaria del dispositivo.

**Configuración Android:**

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

---

## 13. Audio Coach (TTS)

Configuración de `flutter_tts`:

```dart
await flutterTts.setLanguage("es-MX");
await flutterTts.setSpeechRate(0.5);
await flutterTts.setVolume(1.0);
await flutterTts.setPitch(1.0);
```

---

## 14. Dependencias Completas

```yaml
dependencies:
  flutter:
    sdk: flutter
  hive_ce: ^2.7.0
  hive_ce_flutter: ^2.1.0
  flutter_map: ^8.2.2
  latlong2: ^0.9.0
  geolocator: ^14.0.2
  firebase_core: ^4.4.0
  firebase_auth: ^6.1.4
  cloud_firestore: ^6.1.2
  provider: ^6.1.0
  flutter_local_notifications: ^18.0.1
  timezone: ^0.10.0
  flutter_tts: ^4.2.0
  connectivity_plus: ^7.0.0
  intl: ^0.20.2
  uuid: ^4.2.1
  image_picker: ^1.1.2
  path_provider: ^2.1.4

dev_dependencies:
  hive_ce_generator: ^1.4.0
  build_runner: ^2.4.6
  flutter_test:
    sdk: flutter
```

---

## 15. Permisos Requeridos

### Android (`AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

### iOS (`Info.plist`)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para trackear tu carrera</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para trackear tu carrera en segundo plano</string>
<key>NSMicrophoneUsageDescription</key>
<string>Necesitamos el audio para el coach de voz</string>
```

---

## 16. Configuración de Firebase

1. Crear proyecto en [Firebase Console](https://console.firebase.google.com/)
2. Agregar app Android con el package name del proyecto
3. Agregar app iOS con el Bundle ID
4. Descargar archivos de configuración:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`
5. Habilitar en Firebase Console:
   - **Authentication** → Email/Password
   - **Firestore Database** → Modo producción con reglas apropiadas

### Reglas de Firestore recomendadas

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /runs/{runId} {
      allow read, write: if request.auth.uid == resource.data.userId;
    }
  }
}
```
