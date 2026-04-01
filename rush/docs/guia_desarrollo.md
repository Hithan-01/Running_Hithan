# Guía de Desarrollo — RUSH

> Guía para desarrolladores que trabajan o contribuyen al proyecto RUSH.

---

## Tabla de Contenidos

1. [Configuración del Entorno](#1-configuración-del-entorno)
2. [Estructura de Archivos](#2-estructura-de-archivos)
3. [Flujo de Trabajo Git](#3-flujo-de-trabajo-git)
4. [Generación de Código (Hive)](#4-generación-de-código-hive)
5. [Cómo Agregar una Nueva Pantalla](#5-cómo-agregar-una-nueva-pantalla)
6. [Cómo Agregar un Nuevo Modelo Hive](#6-cómo-agregar-un-nuevo-modelo-hive)
7. [Cómo Agregar un POI](#7-cómo-agregar-un-poi)
8. [Cómo Agregar un Achievement](#8-cómo-agregar-un-achievement)
9. [Cómo Agregar una Misión](#9-cómo-agregar-una-misión)
10. [Pruebas](#10-pruebas)
11. [Build y Distribución](#11-build-y-distribución)
12. [Convenciones de Código](#12-convenciones-de-código)
13. [Solución de Problemas Comunes](#13-solución-de-problemas-comunes)
14. [Comandos de Referencia](#14-comandos-de-referencia)

---

## 1. Configuración del Entorno

### Requisitos previos

| Herramienta | Versión mínima | Instalación |
|-------------|---------------|-------------|
| Flutter SDK | 3.9.0 | [flutter.dev](https://flutter.dev) |
| Dart SDK | 3.0 | Incluido con Flutter |
| Android Studio | 2023+ | Para emulador y build Android |
| Xcode | 15+ | Solo macOS, para iOS |
| Git | 2.x | git-scm.com |

### Instalación inicial

```bash
# 1. Clonar el repositorio
git clone <repo-url>
cd rush

# 2. Instalar dependencias Flutter
flutter pub get

# 3. Generar adaptadores Hive
dart run build_runner build --delete-conflicting-outputs

# 4. Configurar Firebase (ver sección de Firebase)
# Colocar google-services.json en android/app/
# Colocar GoogleService-Info.plist en ios/Runner/

# 5. Verificar entorno
flutter doctor

# 6. Ejecutar la app
flutter run
```

### Verificación de instalación

```bash
flutter doctor -v
# Debe mostrar ✓ para Flutter, Dart, Android toolchain y Xcode (macOS)
```

---

## 2. Estructura de Archivos

```
rush/
├── lib/
│   ├── main.dart                    # Punto de entrada, inicialización
│   ├── models/
│   │   ├── user.dart                # Modelo User + HiveAdapter
│   │   ├── run.dart                 # Modelos Run + RunPoint
│   │   ├── achievement.dart         # Achievement + UnlockedAchievement
│   │   ├── poi.dart                 # Poi + VisitedPoi
│   │   ├── mission.dart             # Mission + ActiveMission
│   │   └── notification_item.dart   # NotificationItem
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── run_hub_screen.dart      # Pantalla principal de carrera
│   │   ├── map_screen.dart
│   │   ├── history_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── leaderboard_screen.dart
│   │   ├── achievements_screen.dart
│   │   ├── missions_screen.dart
│   │   ├── run_summary_screen.dart
│   │   └── notification_center_screen.dart
│   ├── services/
│   │   ├── database_service.dart    # CRUD Hive
│   │   ├── gamification_service.dart # Lógica XP, logros, misiones
│   │   ├── location_service.dart    # GPS tracking
│   │   ├── notification_service.dart
│   │   ├── audio_coach_service.dart # TTS
│   │   └── sync_service.dart        # Sincronización Firebase
│   ├── widgets/
│   │   ├── xp_bar.dart
│   │   ├── mission_card.dart
│   │   ├── poi_marker.dart
│   │   ├── run_stats_panel.dart
│   │   └── circular_step_gauge.dart
│   └── utils/
│       ├── constants.dart           # Colores, temas, config del campus
│       └── formatters.dart          # Utilidades de formato
├── docs/
│   ├── manual_usuario.md
│   ├── manual_tecnico.md
│   └── guia_desarrollo.md           # Este archivo
├── pubspec.yaml
├── workflow.md
└── comandos.md
```

---

## 3. Flujo de Trabajo Git

### Branches

| Branch | Propósito |
|--------|-----------|
| `main` | Código estable, versiones de producción |
| `feature/nombre` | Nuevas funcionalidades |
| `fix/nombre` | Corrección de bugs |

### Flujo recomendado

```bash
# Crear rama para nueva funcionalidad
git checkout -b feature/nueva-funcionalidad

# Trabajar y hacer commits descriptivos
git add lib/screens/nueva_screen.dart
git commit -m "feat: agregar pantalla de nueva funcionalidad"

# Actualizar con cambios de main
git fetch origin
git rebase origin/main

# Abrir Pull Request a main
```

### Formato de commits

Usa el formato convencional:
- `feat:` nueva funcionalidad
- `fix:` corrección de bug
- `refactor:` refactorización sin cambio funcional
- `docs:` cambios en documentación
- `style:` cambios de formato/estilo
- `test:` agregar o modificar pruebas

---

## 4. Generación de Código (Hive)

Los adaptadores Hive se generan automáticamente a partir de anotaciones en los modelos.

### Cuándo regenerar

- Al agregar un nuevo campo a un modelo Hive
- Al crear un nuevo modelo con `@HiveType`
- Al cambiar el `typeId` de un campo

### Comando

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Archivos generados

Por cada modelo, se genera un archivo `.g.dart`:
- `user.g.dart` — `UserAdapter`
- `run.g.dart` — `RunAdapter`, `RunPointAdapter`
- etc.

> **Importante:** Los archivos `.g.dart` NO deben editarse manualmente. Se sobreescriben con `build_runner`.

### Reglas de TypeId

Cada tipo Hive necesita un `typeId` único global. La tabla actual:

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

**Al agregar un nuevo modelo, usa el siguiente TypeId disponible (10, 11, ...).**

---

## 5. Cómo Agregar una Nueva Pantalla

1. Crear el archivo en `lib/screens/nueva_screen.dart`:

```dart
import 'package:flutter/material.dart';

class NuevaScreen extends StatelessWidget {
  const NuevaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Pantalla')),
      body: const Center(child: Text('Hola desde nueva pantalla')),
    );
  }
}
```

2. Registrar la ruta en `main.dart` o en el widget de navegación:

```dart
// En el Navigator o router
'/nueva': (context) => const NuevaScreen(),
```

3. Navegar desde otra pantalla:

```dart
Navigator.pushNamed(context, '/nueva');
// o
Navigator.push(context, MaterialPageRoute(
  builder: (_) => const NuevaScreen(),
));
```

---

## 6. Cómo Agregar un Nuevo Modelo Hive

1. Crear el modelo en `lib/models/nuevo_modelo.dart`:

```dart
import 'package:hive_ce/hive.dart';

part 'nuevo_modelo.g.dart';

@HiveType(typeId: 10)  // Usar el siguiente TypeId disponible
class NuevoModelo extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String nombre;
}
```

2. Registrar el adaptador en `main.dart`:

```dart
Hive.registerAdapter(NuevoModeloAdapter());
```

3. Abrir el box en la inicialización:

```dart
await Hive.openBox<NuevoModelo>('nuevo_box');
```

4. Regenerar código:

```bash
dart run build_runner build --delete-conflicting-outputs
```

5. Agregar métodos CRUD en `DatabaseService`.

---

## 7. Cómo Agregar un POI

Los POIs se definen en `lib/utils/constants.dart` o cargados desde `DatabaseService`.

```dart
Poi(
  id: 'poi_nueva_ubicacion',
  name: 'Nueva Ubicación',
  latitude: 25.XXXXXX,
  longitude: -99.XXXXXX,
  category: 'academic',  // academic | sports | landmark
  xpReward: 20,
  description: 'Descripción breve del lugar.',
)
```

**Para obtener coordenadas precisas:**
1. Abre Google Maps en la ubicación deseada
2. Toca y mantén presionado para ver coordenadas
3. Usa las coordenadas con 6 decimales de precisión

---

## 8. Cómo Agregar un Achievement

En `GamificationService`, en la lista de achievements y en la lógica de verificación:

```dart
// 1. Definir el achievement
Achievement(
  id: 'nuevo_logro',
  title: 'Título del Logro',
  description: 'Descripción de cómo desbloquearlo',
  icon: '🏆',
  xpReward: 100,
  category: 'distance',  // exploration|distance|consistency|speed|secrets
)

// 2. Agregar condición en checkAchievements()
if (condicion && !isUnlocked('nuevo_logro')) {
  await unlockAchievement('nuevo_logro', user);
}
```

---

## 9. Cómo Agregar una Misión

En `GamificationService`, en las listas de misiones diarias/semanales:

```dart
Mission(
  id: 'mission_nueva',
  title: 'Título de la Misión',
  description: 'Descripción del objetivo',
  type: 'daily',           // daily | weekly
  targetValue: 3.0,        // Valor objetivo (ej. 3 km)
  metric: 'distance',      // distance | duration | pois | runs
  xpReward: 100,
)
```

El progreso se actualiza automáticamente en `updateMissions()` al finalizar una carrera.

---

## 10. Pruebas

### Ejecutar tests unitarios

```bash
flutter test
```

### Probar en emulador

```bash
# Listar dispositivos disponibles
flutter devices

# Ejecutar en dispositivo específico
flutter run -d emulator-5554
```

### Modo de simulación GPS

`LocationService` incluye un modo de simulación para probar sin GPS real. Útil en emuladores:

```dart
// Activar modo simulación en LocationService
locationService.enableSimulationMode();
```

---

## 11. Build y Distribución

### Android APK (debug)

```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Android APK (release)

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (para Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (requiere macOS + Xcode)

```bash
flutter build ios --release
```

### Limpiar build

```bash
flutter clean && flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

---

## 12. Convenciones de Código

### Nomenclatura

| Elemento | Convención | Ejemplo |
|----------|-----------|---------|
| Clases | PascalCase | `GamificationService` |
| Variables | camelCase | `totalDistance` |
| Constantes | camelCase o SCREAMING_SNAKE | `kPrimaryColor` / `POI_RADIUS` |
| Archivos | snake_case | `gamification_service.dart` |
| Métodos | camelCase | `processRunCompletion()` |

### Organización de imports

```dart
// 1. Imports de Dart SDK
import 'dart:async';

// 2. Imports de Flutter
import 'package:flutter/material.dart';

// 3. Imports de paquetes externos
import 'package:provider/provider.dart';

// 4. Imports internos del proyecto
import '../models/run.dart';
import '../services/database_service.dart';
```

### Widgets

- Prefiere `StatelessWidget` cuando no hay estado local.
- Extrae widgets complejos a archivos separados en `lib/widgets/`.
- Usa `const` constructores cuando sea posible.

---

## 13. Solución de Problemas Comunes

### Error: `HiveError: Box not found`

El box no fue abierto antes de usarlo.
**Solución:** Asegúrate de que `Hive.openBox<T>('nombre')` se llame en la inicialización de `DatabaseService.init()`.

### Error: `type 'Null' is not a subtype of type 'UserAdapter'`

El adaptador no fue registrado.
**Solución:** Agregar `Hive.registerAdapter(UserAdapter())` antes de `Hive.openBox()`.

### Error de build_runner: conflictos de archivos `.g.dart`

**Solución:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

### GPS no funciona en emulador

Los emuladores de Android no tienen GPS real.
**Solución:** Usa el modo de simulación en `LocationService` o configura ubicación simulada en el emulador (Extended Controls → Location).

### `firebase_options.dart` no encontrado

**Solución:** Configura Firebase con `flutterfire configure` o crea el archivo manualmente siguiendo el Manual Técnico, sección 16.

### App no detecta POIs

Posibles causas:
1. GPS impreciso: asegúrate de `LocationAccuracy.high`
2. Radio muy pequeño: el radio por defecto es 30m, revisar en `constants.dart`
3. Coordenadas del POI incorrectas: verificar con más de 5 decimales de precisión

---

## 14. Comandos de Referencia

```bash
# Instalar dependencias
flutter pub get

# Generar código Hive
dart run build_runner build --delete-conflicting-outputs

# Ejecutar en modo debug
flutter run

# Ejecutar en dispositivo específico
flutter run -d <device_id>

# Ver dispositivos disponibles
flutter devices

# Análisis estático de código
flutter analyze

# Ejecutar tests
flutter test

# Build APK release
flutter build apk --release

# Build iOS release (macOS)
flutter build ios --release

# Limpiar proyecto
flutter clean && flutter pub get

# Ver logs en tiempo real
flutter logs

# Actualizar dependencias
flutter pub upgrade

# Verificar entorno Flutter
flutter doctor -v
```
