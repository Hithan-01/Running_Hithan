# RUSH — Guía Técnica

> Referencia técnica y guía de desarrollo para contribuidores del proyecto RUSH.
> Para la documentación general del proyecto ver `documentacion_final.md`.

---

## Tabla de Contenidos

1. [Modelos de datos completos](#1-modelos-de-datos-completos)
2. [Métodos clave de los servicios](#2-métodos-clave-de-los-servicios)
3. [Configuración de Firebase](#3-configuración-de-firebase)
4. [Permisos requeridos](#4-permisos-requeridos)
5. [Dependencias](#5-dependencias)
6. [Requisitos del entorno](#6-requisitos-del-entorno)
7. [Flujo de trabajo Git](#7-flujo-de-trabajo-git)
8. [Generación de código Hive](#8-generación-de-código-hive)
9. [Cómo agregar un POI](#9-cómo-agregar-un-poi)
10. [Cómo agregar un Achievement](#10-cómo-agregar-un-achievement)
11. [Cómo agregar una Misión](#11-cómo-agregar-una-misión)
12. [Build y distribución](#12-build-y-distribución)
13. [Convenciones de código](#13-convenciones-de-código)
14. [Solución de problemas comunes](#14-solución-de-problemas-comunes)
15. [Comandos de referencia rápida](#15-comandos-de-referencia-rápida)

---

## 1. Modelos de datos completos

### User (HiveType 0)

```dart
class User extends HiveObject {
  String id;                       // UID de Firebase Auth
  String name;
  String? faculty;                 // Facultad (para leaderboard)
  int? semester;                   // Semestre (para leaderboard)
  int xp;
  int level;                       // 1–6, calculado desde XP
  int totalDistance;               // metros
  int totalRuns;
  int totalTime;                   // segundos
  int currentStreak;               // días consecutivos
  int bestStreak;
  DateTime createdAt;
  DateTime? lastRunAt;
  String? photoPath;               // ruta local de foto de perfil
  String? equippedTitleId;
  int coins;                       // RUSH Coins
  String? equippedAvatarColorId;
  String? equippedAvatarFrameId;
  String? equippedRouteColorId;
  List<String> purchasedItemIds;
}
```

### Run (HiveType 1)

```dart
class Run extends HiveObject {
  String id;
  String oderId;                   // UID del propietario
  int distance;                    // metros
  int duration;                    // segundos
  double avgPace;                  // min/km
  List<RunPoint> route;
  int xpEarned;
  List<String> poisVisited;
  List<String> achievementsUnlocked;
  DateTime createdAt;
  bool isSynced;
}
```

### Tabla de HiveTypes

| TypeId | Clase |
|--------|-------|
| 0 | User |
| 1 | Run |
| 2 | RunPoint |
| 3 | Achievement |
| 4 | UnlockedAchievement |
| 5 | Poi |
| 6 | VisitedPoi |
| 7 | Mission |
| 8 | ActiveMission |
| 9 | NotificationItem |

> Al agregar un nuevo modelo, usar el siguiente TypeId disponible (10, 11, ...).

---

## 2. Métodos clave de los servicios

### GamificationService

| Método | Descripción |
|--------|-------------|
| `ensureUser(uid, name, {faculty, semester})` | Crea o restaura usuario desde Firestore |
| `processRun(Run)` | Calcula XP/coins, evalúa logros/misiones, sincroniza |
| `purchaseItem(StoreItem)` | Compra cosmético con coins |
| `equipStoreItem(StoreItem)` | Equipa cosmético comprado |
| `equipTitle(String)` | Equipa título |
| `updateUserProfile({name, faculty, semester})` | Actualiza perfil localmente y en Firestore |
| `_syncProgress()` | Sube todo el progreso a Firestore |

### SyncService

| Método | Descripción |
|--------|-------------|
| `initNewUser(uid, name, {faculty, semester})` | Inicializa doc de usuario nuevo en Firestore |
| `syncUserProgress(uid, ...)` | Sube XP, coins, logros, POIs, cosméticos |
| `updateUserProfile(uid, ...)` | Actualiza nombre/facultad/semestre en Firestore |
| `syncPendingRuns(uid, oderId)` | Sube carreras locales no sincronizadas |
| `fetchLeaderboard({since, faculty, semester})` | Obtiene leaderboard con filtros |
| `getUserStats(uid)` | Lee el documento de usuario de Firestore |

---

## 3. Configuración de Firebase

1. Crear proyecto en [Firebase Console](https://console.firebase.google.com/)
2. Agregar app Android (`com.ha.rushapp`) e iOS
3. Descargar `google-services.json` → `android/app/` y `GoogleService-Info.plist` → `ios/Runner/`
4. Habilitar **Authentication → Email/Password**
5. Crear **Firestore Database** en modo producción
6. Aplicar reglas de seguridad:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /runs/{runId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == request.resource.data.userId;
    }
  }
}
```

### Estructura de colecciones en Firestore

#### `users/{uid}`

```
users/
  {uid}/                         ← UID de Firebase Auth
    name:                String   ← Nombre del usuario
    faculty:             String?  ← Facultad (para leaderboard por facultad)
    semester:            int?     ← Semestre (para leaderboard por semestre)
    xp:                  int      ← Puntos de experiencia acumulados
    level:               int      ← Nivel actual (1–6)
    totalDistance:       int      ← Distancia total en metros
    totalRuns:           int      ← Número de carreras completadas
    totalTime:           int      ← Tiempo total en segundos
    currentStreak:       int      ← Racha de días consecutivos
    bestStreak:          int      ← Mejor racha histórica
    coins:               int      ← Monedas actuales
    purchasedItemIds:    [String] ← IDs de cosméticos comprados
    equippedTitleId:     String?  ← ID del título equipado
    equippedAvatarColorId:  String? ← Color de avatar equipado
    equippedAvatarFrameId:  String? ← Marco de avatar equipado
    equippedRouteColorId:   String? ← Color de ruta equipado
    unlockedAchievementIds: [String] ← IDs de logros desbloqueados
    visitedPoiIds:       [String] ← IDs de POIs visitados
```

#### `runs/{runId}`

```
runs/
  {runId}/                       ← UUID generado por la app
    userId:       String         ← UID del usuario dueño de la carrera
    userName:     String         ← Nombre (para mostrar en leaderboard)
    distanceKm:   double         ← Distancia en kilómetros
    durationSeconds: int         ← Duración en segundos
    startTime:    Timestamp      ← Inicio de la carrera
    endTime:      Timestamp      ← Fin de la carrera
```

> **Nota:** La ruta GPS (`routePoints`) se guarda solo en Hive local para no exceder el límite de 1MB por documento de Firestore.

---

## 4. Permisos requeridos

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
<string>Necesitamos tu ubicación en segundo plano para trackear tu carrera</string>
```

---

## 5. Dependencias

```yaml
dependencies:
  flutter_map: ^8.2.2
  latlong2: ^0.9.0
  geolocator: ^14.0.2
  hive_ce: ^2.7.0
  hive_ce_flutter: ^2.1.0
  firebase_core: ^4.4.0
  firebase_auth: ^6.1.4
  cloud_firestore: ^6.1.2
  provider: ^6.1.0
  flutter_local_notifications: ^18.0.1
  timezone: ^0.10.0
  flutter_tts: ^4.2.0
  share_plus: ^7.2.2
  connectivity_plus: ^7.0.0
  intl: ^0.20.2
  uuid: ^4.2.1
  image_picker: ^1.1.2
  path_provider: ^2.1.4
  path: ^1.9.0
  sensors_plus: ^6.1.0

dev_dependencies:
  hive_ce_generator: ^1.4.0
  build_runner: ^2.4.6
```

---

## 6. Requisitos del entorno

| Herramienta | Versión mínima |
|-------------|---------------|
| Flutter SDK | 3.9.0 |
| Dart SDK | 3.0 (incluido con Flutter) |
| Android Studio | 2023+ |
| Xcode | 15+ (solo macOS, para iOS) |
| Git | 2.x |

### Instalación inicial

```bash
git clone <repo-url>
cd rush
flutter pub get
dart run build_runner build --delete-conflicting-outputs
# Colocar google-services.json en android/app/
flutter run
```

---

## 7. Flujo de trabajo Git

| Branch | Propósito |
|--------|-----------|
| `main` | Código estable, versiones de producción |
| `feature/nombre` | Nuevas funcionalidades |
| `fix/nombre` | Corrección de bugs |

**Formato de commits:**
- `feat:` nueva funcionalidad
- `fix:` corrección de bug
- `refactor:` refactorización sin cambio funcional
- `docs:` cambios en documentación
- `style:` cambios de formato/estilo
- `test:` agregar o modificar pruebas

---

## 8. Generación de código Hive

Regenerar siempre que se agregue o modifique un campo/modelo:

```bash
dart run build_runner build --delete-conflicting-outputs
```

> Los archivos `.g.dart` son generados automáticamente — nunca editarlos a mano.

---

## 9. Cómo agregar un POI

En `lib/models/poi.dart`, dentro de `CampusPois.all`:

```dart
Poi(
  id: 'id_unico',
  name: 'Nombre del Lugar',
  description: 'Descripción breve',
  latitude: 25.XXXXXX,
  longitude: -99.XXXXXX,
  categoryIndex: 0,  // 0=académico | 1=deportes | 2=servicios/landmark
  xpReward: 20,      // 15–35 XP recomendado
  icon: '🏛️',
)
```

Para obtener coordenadas precisas: usar geojson.io trazando puntos sobre el campus con mínimo 6 decimales.

---

## 10. Cómo agregar un Achievement

En `GamificationService`, definir el achievement y agregar su condición en `_checkAchievements()`:

```dart
// 1. Definir
Achievement(
  id: 'nuevo_logro',
  title: 'Título del Logro',
  description: 'Descripción de cómo desbloquearlo',
  icon: '🏆',
  xpReward: 100,
  category: 'distance',  // exploration|distance|consistency|speed|secrets
)

// 2. Condición en _checkAchievements()
if (condicion && !isUnlocked('nuevo_logro')) {
  await unlockAchievement('nuevo_logro', user);
}
```

---

## 11. Cómo agregar una Misión

En `GamificationService`, en las listas de misiones diarias/semanales:

```dart
Mission(
  id: 'mission_nueva',
  title: 'Título de la Misión',
  description: 'Descripción del objetivo',
  type: 'daily',        // daily | weekly
  targetValue: 3.0,     // valor objetivo (ej. 3 km)
  metric: 'distance',   // distance | duration | pois | runs
  xpReward: 100,
)
```

---

## 12. Build y distribución

```bash
# APK debug
flutter build apk --debug

# APK release
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release

# iOS (requiere macOS + Xcode)
flutter build ios --release

# Limpiar proyecto
flutter clean && flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

---

## 13. Convenciones de código

| Elemento | Convención | Ejemplo |
|----------|-----------|---------|
| Clases | PascalCase | `GamificationService` |
| Variables | camelCase | `totalDistance` |
| Archivos | snake_case | `gamification_service.dart` |
| Métodos | camelCase | `processRunCompletion()` |

**Orden de imports:**
1. `dart:` SDK
2. `package:flutter/`
3. Paquetes externos
4. Imports internos del proyecto

---

## 14. Solución de problemas comunes

**`HiveError: Box not found`**
El box no fue abierto antes de usarlo. Asegurarse de que `Hive.openBox<T>('nombre')` se llame en `DatabaseService.init()`.

**`type 'Null' is not a subtype of type 'UserAdapter'`**
El adaptador no fue registrado. Agregar `Hive.registerAdapter(UserAdapter())` antes de `Hive.openBox()`.

**Error de build_runner (conflictos `.g.dart`)**
Ejecutar `dart run build_runner build --delete-conflicting-outputs`.

**GPS no funciona en emulador**
Usar Extended Controls → Location en el emulador, o enviar coordenadas via ADB:
```bash
adb emu geo fix <longitud> <latitud>
```

**`firebase_options.dart` no encontrado**
Configurar Firebase con `flutterfire configure` o crear el archivo manualmente.

---

## 15. Comandos de referencia rápida

```bash
flutter pub get                                          # instalar dependencias
dart run build_runner build --delete-conflicting-outputs # generar código Hive
flutter run -d <device_id>                              # ejecutar en dispositivo
flutter devices                                          # listar dispositivos
flutter analyze                                          # análisis estático
flutter test                                             # ejecutar tests
flutter build apk --release                             # APK release
flutter clean && flutter pub get                        # limpiar proyecto
flutter logs                                             # ver logs en tiempo real
flutter pub upgrade                                      # actualizar dependencias
flutter doctor -v                                        # verificar entorno
```
