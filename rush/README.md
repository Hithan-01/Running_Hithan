# RUSH

App de running gamificada para el campus de la Universidad de Montemorelos.

## Stack Tecnológico

| Tecnología | Uso |
|------------|-----|
| Flutter 3.9+ | Framework UI |
| Dart | Lenguaje |
| flutter_map + OpenStreetMap | Mapas y rutas (gratis, sin API key) |
| Geolocator | Tracking GPS |
| Hive | Base de datos local (NoSQL) |
| Firebase Auth | Autenticación de usuarios |
| Provider | State management |

## Estructura del Proyecto

```
lib/
├── models/
│   ├── user.dart
│   ├── run.dart
│   ├── achievement.dart
│   ├── poi.dart
│   └── mission.dart
├── screens/
│   ├── dashboard_screen.dart
│   ├── map_screen.dart
│   ├── profile_screen.dart
│   ├── leaderboard_screen.dart
│   ├── history_screen.dart
│   └── run_summary_screen.dart
├── widgets/
│   ├── xp_bar.dart
│   ├── mission_card.dart
│   ├── poi_marker.dart
│   ├── run_stats_panel.dart
│   └── circular_step_gauge.dart
├── services/
│   ├── location_service.dart
│   ├── database_service.dart
│   └── gamification_service.dart
└── utils/
    ├── constants.dart
    └── formatters.dart
```

## Base de Datos (Hive)

Hive es una base de datos NoSQL ligera y rápida para Flutter. Los datos se guardan localmente en el dispositivo.

### Boxes (Colecciones)

| Box | Modelo | Descripción |
|-----|--------|-------------|
| `users` | `User` | Datos del usuario |
| `runs` | `Run` | Historial de carreras |
| `achievements` | `UnlockedAchievement` | Logros desbloqueados |
| `visited_pois` | `VisitedPoi` | POIs visitados |
| `active_missions` | `ActiveMission` | Misiones activas |

## Instalación

```bash
# Clonar repositorio
git clone <repo-url>
cd rush

# Instalar dependencias
flutter pub get

# Generar código de Hive (adapters)
dart run build_runner build

# Ejecutar
flutter run
```

## Dependencias

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_map: ^6.1.0        # Mapas OpenStreetMap (gratis)
  latlong2: ^0.9.0           # Coordenadas
  geolocator: ^10.1.0        # GPS
  hive: ^2.2.3               # DB local
  hive_flutter: ^1.1.0
  firebase_core: ^2.24.0     # Firebase
  firebase_auth: ^4.16.0     # Autenticación
  provider: ^6.1.0           # State management
  intl: ^0.18.0
  uuid: ^4.2.1

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.6
```

## Configuración

### Firebase (Autenticación)

1. Crear proyecto en [Firebase Console](https://console.firebase.google.com/)
2. Agregar app iOS/Android
3. Descargar archivo de configuración:
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`
   - Android: `google-services.json` → `android/app/`
4. Habilitar "Email/Password" en Authentication

### Mapas (OpenStreetMap)

**¡No requiere configuración!** Los mapas de OpenStreetMap son gratuitos y no necesitan API key.

### Permisos de Ubicación (iOS)

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para trackear tu carrera</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Necesitamos tu ubicación para trackear tu carrera en segundo plano</string>
```

## Gamificación

### Sistema de XP y Niveles
- 50 XP por kilómetro corrido
- 2 XP por minuto de carrera
- Bonos por visitar POIs y completar misiones

### POIs del Campus (10 puntos)
- **Académicos**: Biblioteca, Facultad de Ingeniería, Facultad de Salud
- **Deportivos**: Gimnasio, Pista de Atletismo, Canchas
- **Landmarks**: Capilla, Cafetería, Lago, Entrada Principal

### Logros (16 achievements)
- Exploración, Distancia, Consistencia, Velocidad, Secretos

### Misiones
- 5 misiones diarias
- 3 misiones semanales

## Arquitectura

```
┌─────────────────────────────────────────┐
│              UI (Screens)               │
├─────────────────────────────────────────┤
│              Widgets                    │
├─────────────────────────────────────────┤
│         Provider (State)                │
├─────────────────────────────────────────┤
│             Services                    │
│  ┌──────────┬──────────┬──────────┐    │
│  │ Location │ Database │ Gamific. │    │
│  └──────────┴──────────┴──────────┘    │
├─────────────────────────────────────────┤
│            Hive / GPS                   │
└─────────────────────────────────────────┘
```

## Comandos Útiles

```bash
# Ejecutar en modo debug
flutter run

# Build Android APK
flutter build apk --release

# Build iOS
flutter build ios --release

# Regenerar código Hive
dart run build_runner build --delete-conflicting-outputs

# Limpiar cache
flutter clean && flutter pub get
```

---

**"RUSH - Run. Unlock. Share. Hustle."**