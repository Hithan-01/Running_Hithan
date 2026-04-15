# RUSH — Run. Unlock. Share. Hustle.

App móvil gamificada de running para el campus de la **Universidad de Montemorelos**. Combina tracking GPS con mecánicas de videojuego: XP, niveles, logros, misiones, POIs, tienda de cosméticos y leaderboard.

---

## Stack Tecnológico

| Tecnología | Versión | Uso |
|------------|---------|-----|
| Flutter | 3.9+ | Framework UI multiplataforma |
| Dart | 3.7+ | Lenguaje de programación |
| flutter_map | 8.2.2 | Mapas (tiles CartoDB + Google Maps satélite) |
| Geolocator | 14.x | Tracking GPS |
| Hive CE | 2.7.0 | Base de datos NoSQL local |
| Firebase Auth | 6.x | Autenticación Email/Password |
| Cloud Firestore | 6.x | Sincronización en la nube y leaderboard |
| Provider | 6.x | Gestión de estado |
| flutter_tts | 4.x | Audio Coach (TTS en español) |
| flutter_local_notifications | 18.x | Notificaciones locales |
| share_plus | 7.x | Compartir carreras |
| connectivity_plus | 7.x | Detección de conexión para sync |

---

## Estructura del Proyecto

```
rush/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── user.dart
│   │   ├── run.dart
│   │   ├── achievement.dart
│   │   ├── poi.dart                  # 38 POIs reales del campus
│   │   ├── mission.dart
│   │   ├── store_item.dart           # Cosméticos de la tienda
│   │   ├── run_title.dart            # Títulos desbloqueables
│   │   └── notification_item.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── run_hub_screen.dart       # Pantalla principal de carrera
│   │   ├── map_screen.dart
│   │   ├── history_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── leaderboard_screen.dart
│   │   ├── achievements_screen.dart
│   │   ├── missions_screen.dart
│   │   ├── run_summary_screen.dart
│   │   └── notification_center_screen.dart
│   ├── services/
│   │   ├── gamification_service.dart
│   │   ├── database_service.dart
│   │   ├── location_service.dart
│   │   ├── sync_service.dart
│   │   ├── notification_service.dart
│   │   └── audio_coach_service.dart
│   ├── widgets/
│   │   ├── xp_bar.dart
│   │   ├── mission_card.dart
│   │   ├── poi_marker.dart
│   │   ├── run_stats_panel.dart
│   │   └── circular_step_gauge.dart
│   └── utils/
│       ├── constants.dart
│       └── formatters.dart
├── docs/
│   ├── manual_usuario.md
│   ├── manual_tecnico.md
│   └── guia_desarrollo.md
├── workflow.md
└── comandos.md
```

---

## Instalación

```bash
# 1. Clonar el repositorio
git clone <repo-url>
cd rush

# 2. Instalar dependencias
flutter pub get

# 3. Generar adaptadores Hive
dart run build_runner build --delete-conflicting-outputs

# 4. Configurar Firebase
# Colocar google-services.json en android/app/
# Colocar GoogleService-Info.plist en ios/Runner/

# 5. Verificar entorno
flutter doctor

# 6. Ejecutar
flutter run -d emulator-5554
```

---

## Funcionalidades

### Core
- Tracking GPS (iniciar / pausar / detener)
- Métricas en vivo: distancia, tiempo, pace
- Mapa del campus con ruta trazada en tiempo real
- Polígono del campus delimitado con coordenadas GeoJSON exactas
- Vista satélite (Google Maps tiles)
- Guardar carreras (Hive local + Firestore sync offline-first)
- Compartir carreras en redes sociales

### Gamificación
- XP y 6 niveles (Rookie Runner → Campus Legend)
- 38 POIs reales del campus UM con coordenadas precisas
- 17 logros en 5 categorías (exploración, distancia, consistencia, velocidad, secretos)
- Misiones diarias (5) y semanales (3)
- Rachas de días consecutivos
- RUSH Coins y tienda de cosméticos (colores de avatar, marcos, colores de ruta)
- Títulos desbloqueables para el leaderboard
- Audio Coach TTS en español (por km, por 5 min, POIs, logros)

### Perfil y Social
- Foto de perfil, facultad y semestre
- Historial de carreras con gráfica semanal
- Leaderboard global, por facultad y por semestre
- Filtros: Hoy / Semana / Mes / Total
- Podio visual con medallas para top 3

---

## Base de Datos Local (Hive)

| Box | Tipo | Descripción |
|-----|------|-------------|
| `users` | `User` | Perfil local |
| `runs` | `Run` | Historial de carreras |
| `achievements` | `UnlockedAchievement` | Logros desbloqueados |
| `visited_pois` | `VisitedPoi` | POIs visitados |
| `active_missions` | `ActiveMission` | Misiones en progreso |
| `notification_history` | `NotificationItem` | Historial de notificaciones |

---

## Comandos Útiles

```bash
# Ejecutar en emulador
flutter run -d emulator-5554

# Simular GPS en emulador (longitud primero)
adb emu geo fix -99.84588553441621 25.192661242495106

# Regenerar código Hive
dart run build_runner build --delete-conflicting-outputs

# Build APK release
flutter build apk --release

# Limpiar cache
flutter clean && flutter pub get
```

---

**"RUSH — Run. Unlock. Share. Hustle."**
