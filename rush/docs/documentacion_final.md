# RUSH — Documentación Final del Proyecto

> **RUSH** · *Run. Unlock. Share. Hustle.*
> Aplicación móvil de running gamificada para la Universidad de Montemorelos
> Desarrollado con Flutter · Android / iOS

---

## Tabla de Contenidos

1. [Descripción General](#1-descripción-general)
2. [Objetivo del Proyecto](#2-objetivo-del-proyecto)
3. [Flujo de la Aplicación](#3-flujo-de-la-aplicación)
4. [Stack Tecnológico](#4-stack-tecnológico)
5. [Módulos del Sistema](#5-módulos-del-sistema)
   - 5.1 [Autenticación](#51-autenticación)
   - 5.2 [Tracking GPS y Métricas](#52-tracking-gps-y-métricas)
   - 5.3 [Mapa del Campus](#53-mapa-del-campus)
   - 5.4 [Sistema de Gamificación](#54-sistema-de-gamificación)
   - 5.5 [Puntos de Interés (POIs)](#55-puntos-de-interés-pois)
   - 5.6 [Tienda y Cosméticos](#56-tienda-y-cosméticos)
   - 5.7 [Leaderboard](#57-leaderboard)
   - 5.8 [Sincronización Offline-First](#58-sincronización-offline-first)
   - 5.9 [Notificaciones Locales](#59-notificaciones-locales)
   - 5.10 [Audio Coach](#510-audio-coach)
6. [Persistencia de Datos](#6-persistencia-de-datos)
7. [Manual de Usuario](#7-manual-de-usuario)
8. [Glosario](#8-glosario)
9. [Referencias](#9-referencias)

> Para detalles de implementación, modelos, servicios y guía de desarrollo ver [`guia_tecnica.md`](guia_tecnica.md).

---

## 1. Descripción General

**RUSH** es una aplicación móvil multiplataforma (Android e iOS) desarrollada para motivar a estudiantes y miembros de la comunidad universitaria de la **Universidad de Montemorelos** a adoptar el hábito de correr dentro del campus. La app combina seguimiento GPS en tiempo real con mecánicas propias de videojuegos: acumulación de puntos de experiencia, subida de niveles, desbloqueo de logros, misiones diarias y semanales, exploración de puntos de interés reales del campus y competencia entre usuarios a través de un leaderboard.

El proyecto está construido con **Flutter**, lo que permite una única base de código para Android e iOS. Usa **Firebase** como plataforma de backend (autenticación y base de datos en la nube) y **Hive** como base de datos local para garantizar funcionamiento sin conexión.

---

## 2. Objetivo del Proyecto

El objetivo central de RUSH es **incentivar la actividad física** dentro del campus universitario a través de la gamificación. En lugar de presentar el ejercicio como una obligación, la app lo convierte en una experiencia con progresión visible, recompensas, exploración y competencia social.

### Objetivos específicos

- Registrar carreras con métricas precisas (distancia, tiempo, pace) usando GPS del dispositivo.
- Gamificar la experiencia con XP, niveles, logros, misiones y rachas diarias.
- Conectar el campus físico con la app mediante 38 Puntos de Interés (POIs) georeferenciados con coordenadas reales.
- Fomentar la competencia sana a través de un leaderboard filtrable por facultad y semestre.
- Permitir el uso offline completo con sincronización automática al recuperar conexión.

---

## 3. Flujo de la Aplicación

### 3.1 Diagrama general

```
┌───────────────────────────────────────────────────────┐
│                  INICIO DE SESIÓN                     │
│         Registrarse  ──────  Iniciar sesión           │
│    (nombre, correo,              (correo +            │
│     contraseña,                   contraseña)         │
│     facultad, semestre)                               │
└───────────────────────┬───────────────────────────────┘
                        │
                        ▼
┌───────────────────────────────────────────────────────┐
│                     DASHBOARD                         │
│   Barra XP · Nivel · Racha · Misiones activas         │
└──────┬──────────┬──────────────┬───────────────┬──────┘
       │          │              │               │
       ▼          ▼              ▼               ▼
  ┌────────┐ ┌─────────┐ ┌───────────┐ ┌──────────────┐
  │CORRER  │ │ RANKING │ │  LOGROS   │ │  ACTIVIDAD   │
  └────┬───┘ └────┬────┘ └─────┬─────┘ └──────┬───────┘
       │          │            │               │
       ▼          ▼            ├── Logros      ▼
  ┌─────────┐ Leaderboard      ├── Misiones  Historial
  │  Mapa   │ (Hoy/Semana/     └── Tienda    de carreras
  │  GPS    │  Mes/Total)           │         │
  └────┬────┘  Global /             ▼         ▼
       │       Facultad /      Comprar /   Ver detalle
       │       Semestre        Equipar     Compartir
       ▼       cosmético
  ┌─────────┐
  │  Play ▶ │
  └────┬────┘
       │
       ▼
  ┌──────────────────────────────────┐
  │         CARRERA EN CURSO         │
  │  Distancia · Tiempo · Pace       │
  │  Ruta en mapa · POIs             │
  │  Audio Coach                     │
  │                                  │
  │   [Pausar]  ──►  [Continuar]     │
  │   [Terminar]                     │
  └────────────────┬─────────────────┘
                   │
                   ▼
  ┌──────────────────────────────────┐
  │        RESUMEN DE CARRERA        │
  │  Distancia · Tiempo · Pace       │
  │  XP ganado (distancia + tiempo   │
  │   + POIs + logros)               │
  │  Nuevos logros desbloqueados     │
  │  POIs visitados por primera vez  │
  │  [Compartir]   [Volver]          │
  └──────────────────────────────────┘
```

---

### 3.2 Primer uso (registro)

1. El usuario abre RUSH por primera vez y toca **"Crear cuenta"**.
2. Ingresa nombre, correo, contraseña y opcionalmente facultad y semestre.
3. Firebase crea la cuenta. Se genera un perfil local con Nivel 1, 0 XP y 0 coins.
4. Se asignan las **5 misiones diarias** iniciales.
5. El usuario llega al **Dashboard**.

---

### 3.3 Uso diario típico

```
Abrir app
    │
    ├─ ¿Hay misiones nuevas? ──► Notificación a las 06:00
    │
    ▼
Dashboard
    │
    ├─ Revisar misiones activas en tarjetas
    ├─ Ver progreso de XP y racha
    │
    └─► Ir a correr
            │
            ▼
        Mapa carga con posición actual
            │
            ▼
        Play ▶ → GPS activo
            │
            ├─ Cada 1 km → Audio Coach anuncia distancia y pace
            ├─ Cada 5 min → Audio Coach anuncia resumen
            ├─ Al pasar por POI (< 30 m) → XP bonus + anuncio
            │
            ▼
        Terminar carrera
            │
            ▼
        Resumen: XP, logros, POIs
            │
            ├─ ¿Subió de nivel? → Notificación de nivel
            ├─ ¿Misión completada? → XP extra
            └─ ¿Logro desbloqueado? → XP + coins extra
```

---

### 3.4 Flujo de gamificación al terminar una carrera

Cada vez que el usuario termina una carrera, el sistema ejecuta automáticamente:

| Paso | Acción | Resultado |
|------|--------|-----------|
| 1 | Calcular XP base | `distancia_km × 50 + minutos × 2` |
| 2 | Procesar POIs visitados | XP bonus por cada POI nuevo |
| 3 | Evaluar 17 logros | Desbloquear los que apliquen, sumar XP |
| 4 | Actualizar misiones | Incrementar progreso, completar si alcanzó meta |
| 5 | Calcular coins | `distancia_km × 10` + bonus por logros/nivel |
| 6 | Actualizar racha | Si corrió hoy y no lo había hecho |
| 7 | Verificar subida de nivel | Comparar XP total contra umbrales |
| 8 | Guardar en Hive | Persistencia local inmediata |
| 9 | Sincronizar con Firestore | Si hay conexión disponible |

---

### 3.5 Flujo de la tienda

```
Pestaña Logros → Tienda
        │
        ▼
    Ver ítems disponibles
    (colores, marcos, colores de ruta)
        │
        ├─ ¿Ya comprado? → [Equipar]
        │
        └─ ¿No comprado?
                │
                ├─ ¿Coins suficientes? ──► [Comprar] → se equipa automáticamente
                │                                       se descuentan coins
                │                                       se sube a Firestore
                └─ ¿Coins insuficientes? → botón deshabilitado
```

---

### 3.6 Restauración en dispositivo nuevo

```
Instalar RUSH en dispositivo nuevo
        │
        ▼
    Iniciar sesión con correo y contraseña
        │
        ▼
    Firebase Auth valida credenciales
        │
        ▼
    ensureUser() detecta: Hive local vacío
        │
        ▼
    Consulta Firestore → descarga perfil completo
    (XP, nivel, coins, logros, POIs, cosméticos)
        │
        ▼
    Restaura todo en Hive local
        │
        ▼
    Dashboard con todos los datos intactos
```

---

## 4. Stack Tecnológico

### Framework y Lenguaje

| Tecnología | Versión | Rol |
|------------|---------|-----|
| **Flutter** | 3.9+ | Framework UI multiplataforma (Android / iOS desde una sola base de código) |
| **Dart** | 3.7+ | Lenguaje de programación compilado |

### Mapas y Geolocalización

| Tecnología | Versión | Rol |
|------------|---------|-----|
| **flutter_map** | 8.2.2 | Renderizado de mapas con tiles raster. Compatible con cualquier proveedor de tiles (OpenStreetMap, CartoDB, Google Maps). |
| **latlong2** | 0.9.x | Tipos de coordenadas geográficas (LatLng) utilizados por flutter_map. |
| **Geolocator** | 14.x | Acceso al GPS del dispositivo: posición actual, stream de posiciones con filtro de distancia, cálculo de distancia entre puntos (fórmula de Haversine integrada). |
| **CartoDB Voyager** | — | Proveedor de tiles para el mapa en modo normal. Gratuito, sin API key. |
| **Google Maps Tiles** | — | Proveedor de tiles para el modo satélite. URL pública sin autenticación. |

### Backend y Autenticación

| Tecnología | Versión | Rol |
|------------|---------|-----|
| **Firebase Authentication** | 6.x | Autenticación de usuarios con Email/Password. Gestiona sesiones persistentes entre lanzamientos. |
| **Cloud Firestore** | 6.x | Base de datos NoSQL en la nube. Almacena perfiles de usuario, carreras, progreso de gamificación y sirve como fuente del leaderboard. |

### Persistencia Local

| Tecnología | Versión | Rol |
|------------|---------|-----|
| **Hive CE** | 2.7.0 | Base de datos NoSQL embebida, almacenada directamente en el dispositivo. Permite operar sin conexión. Acceso por clave sin SQL. |
| **hive_ce_flutter** | 2.1.0 | Integración de Hive con Flutter (inicialización, paths de almacenamiento). |

### Gestión de Estado

| Tecnología | Versión | Rol |
|------------|---------|-----|
| **Provider** | 6.x | Patrón de inyección de dependencias y gestión de estado reactivo. Los servicios centrales (`GamificationService`, `LocationService`) son `ChangeNotifier` consumidos por los widgets con `Consumer`. |

### Funcionalidades Adicionales

| Tecnología | Versión | Rol |
|------------|---------|-----|
| **flutter_tts** | 4.x | Text-to-Speech en español. Usado por el Audio Coach para anunciar kilómetros, tiempo y POIs durante la carrera. |
| **flutter_local_notifications** | 18.x | Notificaciones locales programadas en Android e iOS. Canales separados para recordatorios y misiones. |
| **share_plus** | 7.x | Compartir texto con estadísticas de la carrera a cualquier app instalada (WhatsApp, Instagram, etc.). |
| **connectivity_plus** | 7.x | Monitoreo del estado de red. Dispara la sincronización pendiente automáticamente al recuperar conexión. |
| **image_picker** | 1.x | Selección de foto de perfil desde la galería del dispositivo. |
| **uuid** | 4.x | Generación de identificadores únicos (UUID v4) para carreras y otros registros. |
| **intl** | 0.20.x | Internacionalización: formateo de fechas, números y duraciones. |

---

## 5. Módulos del Sistema

### 5.1 Autenticación

La autenticación usa **Firebase Authentication** con proveedor **Email/Password**. El UID generado por Firebase es el identificador maestro del usuario tanto en la base de datos local (Hive) como en la nube (Firestore).

Las sesiones persisten automáticamente entre cierres de la app. Al detectar un usuario autenticado en un dispositivo nuevo (sin datos locales), `GamificationService.ensureUser()` consulta Firestore y restaura completamente el perfil: XP, nivel, monedas, logros, POIs visitados, cosméticos comprados y equipados.

---

### 5.2 Tracking GPS y Métricas

El tracking usa **Geolocator** con las siguientes configuraciones:

- **Precisión**: `LocationAccuracy.high` (GPS de alta precisión)
- **Filtro de distancia**: actualizaciones cada 5 metros mínimo (evita ruido GPS)
- **Filtro de procesamiento**: solo se suma distancia si el desplazamiento desde el último punto es ≥ 3 metros

Las métricas calculadas en tiempo real son:
- **Distancia** acumulada en metros, mostrada en kilómetros
- **Duración** en segundos (timer independiente del GPS)
- **Pace** (ritmo) en minutos por kilómetro: `(duración_min / distancia_km)`

La ruta completa se almacena como una lista de `RunPoint` (coordenada + timestamp) y se dibuja en el mapa como una `Polyline`.

---

### 5.3 Mapa del Campus

El mapa se renderiza con **flutter_map 8.2.2** usando tiles raster externos:

| Modo | Proveedor | Característica |
|------|-----------|----------------|
| Normal | CartoDB Voyager | Mapa de calle, gratuito, sin API key |
| Satélite | Google Maps | Imagen satelital reciente del campus |

El campus está delimitado visualmente por un **polígono de 26 vértices** extraído de un GeoJSON trazado sobre la imagen real de la universidad. El polígono se renderiza con `PolygonLayer` de flutter_map con relleno semitransparente y borde naranja.

La cámara del mapa tiene una restricción (`CameraConstraint.containCenter`) que impide que el centro del mapa salga de los límites del campus. Los niveles de zoom van de 14 (campus completo visible) a 21 (máximo detalle).

---

### 5.4 Sistema de Gamificación

El sistema de gamificación es el núcleo de la app, implementado en `GamificationService`. Todos los cálculos ocurren localmente al finalizar cada carrera.

#### XP (Puntos de Experiencia)

| Fuente | XP |
|--------|----|
| 1 kilómetro corrido | 50 XP |
| 1 minuto de carrera | 2 XP |
| Visitar un POI nuevo | 15–35 XP (según el POI) |
| Completar una misión diaria | 40–100 XP |
| Completar una misión semanal | 100–250 XP |
| Desbloquear un logro | 25–500 XP |

#### Niveles

| Nivel | Nombre | XP requerido |
|-------|--------|-------------|
| 1 | Rookie Runner | 0 XP |
| 2 | Campus Jogger | 500 XP |
| 3 | Fitness Explorer | 1,500 XP |
| 4 | Trail Master | 3,500 XP |
| 5 | UM Athlete | 7,000 XP |
| 6 | Campus Legend | 15,000 XP |

#### RUSH Coins

Las monedas son la divisa de la tienda. Se obtienen corriendo (10 coins/km), subiendo de nivel (50 coins) y desbloqueando logros (~20% del XP del logro en coins).

#### Logros (17 en total)

Distribuidos en 5 categorías, se evalúan automáticamente al finalizar cada carrera:

| Categoría | Logros |
|-----------|--------|
| Exploración | Primer Paso, Explorador, Maestro del Campus |
| Distancia | Primer Kilómetro, 5K Runner, 10K Club, Maratonista, Ultra Runner |
| Consistencia | Primera Carrera, Racha de 3 días, Racha de 7 días, Veterano |
| Velocidad | Rápido (<6:00 min/km), Corredor Élite (<5:00 min/km) |
| Secretos | Pi Runner (3.14 km ±0.02), Madrugador (carrera antes de las 6:00 AM) |

#### Misiones

- **5 misiones diarias**: se asignan al crear cuenta y se reinician cada día.
- **3 misiones semanales**: objetivos de mayor escala.
- El progreso se actualiza automáticamente al procesar cada carrera.

#### Rachas

El sistema registra días consecutivos de carrera. Si el usuario no corre en un día, la racha se reinicia. Se guarda tanto la racha actual como la racha máxima histórica.

---

### 5.5 Puntos de Interés (POIs)

El campus tiene **38 POIs** con coordenadas GPS reales, obtenidas mediante GeoJSON trazado sobre el campus. Se detectan durante la carrera cuando el usuario pasa a menos de **30 metros** de uno (radio calculado con Haversine). Cada visita otorga XP y es anunciada por el Audio Coach.

#### Distribución por categoría

**Académico (13 POIs)**

| POI | Coordenadas |
|-----|-------------|
| Biblioteca | 25.193333, -99.844389 |
| Laboratorio FITEC | 25.193624, -99.847332 |
| FITEC | 25.190638, -99.846515 |
| Sistemas | 25.191779, -99.844708 |
| FATEO | 25.192068, -99.844211 |
| FACSA | 25.193093, -99.843808 |
| ARTCOM | 25.194248, -99.844920 |
| ESCEST y QCB | 25.193855, -99.842915 |
| Idiomas | 25.190294, -99.846212 |
| Psicología | 25.190371, -99.847089 |
| UM Virtual | 25.190643, -99.846859 |
| FACED | 25.190444, -99.846833 |
| Preparatoria | 25.192146, -99.846929 |

**Deportes (5 POIs)**

| POI | Coordenadas |
|-----|-------------|
| Gym | 25.193222, -99.846334 |
| Cancha Principal | 25.195022, -99.844113 |
| Canchas de Tenis | 25.194750, -99.843529 |
| Campo de Softball | 25.193708, -99.843529 |
| Cancha la Carlota | 25.194228, -99.840565 |

**Servicios / Landmarks (20 POIs)**

| POI | Coordenadas |
|-----|-------------|
| Cajeros | 25.193580, -99.844871 |
| Planta Física | 25.194020, -99.846055 |
| Garden | 25.193930, -99.846439 |
| Carpintería | 25.193471, -99.847490 |
| Correos | 25.193267, -99.848095 |
| Soymart | 25.193243, -99.848302 |
| Casa del Rector | 25.191925, -99.848535 |
| Dormitorio 1 | 25.192189, -99.847688 |
| Dormitorio 2 | 25.191709, -99.846223 |
| Dormitorio 3 | 25.193639, -99.845556 |
| Dormitorio 4 | 25.192742, -99.845719 |
| COAE | 25.190677, -99.847588 |
| Museo UM | 25.191141, -99.846223 |
| Vicerrectoría | 25.191862, -99.845571 |
| Arco Principal | 25.191983, -99.843508 |
| Rectoría | 25.192624, -99.843905 |
| Plaza 5 de Mayo | 25.193067, -99.845024 |
| Comedor | 25.193091, -99.845475 |
| Jardines Rectoría | 25.192834, -99.844593 |
| Casa de Andrei | 25.193467, -99.842942 |

---

### 5.6 Tienda y Cosméticos

La tienda permite gastar **RUSH Coins** en elementos visuales que personalizan la experiencia del usuario:

| Categoría | Efecto visual |
|-----------|--------------|
| **Colores de avatar** | Color del círculo que enmarca la foto de perfil |
| **Marcos de avatar** | Borde decorativo alrededor del avatar |
| **Colores de ruta** | Color de la línea de la carrera dibujada en el mapa |

Los cosméticos se sincronizan a Firestore y se restauran al iniciar sesión en cualquier dispositivo.

---

### 5.7 Leaderboard

El leaderboard consulta **Firestore** y muestra a los usuarios ordenados por XP. Soporta dos dimensiones de filtrado:

**Por período:**

| Filtro | Fuente de datos |
|--------|----------------|
| Total | Colección `users`, campo `xp` |
| Mes | Agregación de `runs` del mes actual |
| Semana | Agregación de `runs` de la semana actual |
| Hoy | Agregación de `runs` del día actual |

**Por alcance:**

| Filtro | Condición |
|--------|-----------|
| Global | Todos los usuarios |
| Mi Facultad | Usuarios con el mismo valor de `faculty` |
| Mi Semestre | Usuarios con el mismo valor de `semester` |

Los primeros 3 lugares se presentan en un podio visual con medallas.

---

### 5.8 Sincronización Offline-First

RUSH está diseñado para funcionar completamente sin internet. El ciclo de datos es:

1. **Escritura local primero**: toda acción (terminar carrera, comprar item, editar perfil) se guarda inmediatamente en Hive.
2. **Intento de sync**: se intenta subir a Firestore en el mismo momento.
3. **Cola pendiente**: si no hay conexión, la carrera queda marcada con `isSynced: false`.
4. **Sync automático**: `connectivity_plus` escucha cambios de red. Al detectar conexión, `SyncService.syncPendingRuns()` procesa la cola completa.

---

### 5.9 Notificaciones Locales

Las notificaciones usan **flutter_local_notifications** con soporte para Android 13+ (permiso `POST_NOTIFICATIONS`). Son notificaciones locales programadas — no requieren servidor:

| Notificación | Condición | Hora |
|-------------|-----------|------|
| Recordatorio de racha | Si el usuario no corrió hoy | 20:00 |
| Misiones disponibles | Diariamente | 06:00 |

Todas las notificaciones también se registran en el historial interno de la app (box `notification_history`).

---

### 5.10 Audio Coach

El Audio Coach usa **flutter_tts** (Text-to-Speech) configurado en español mexicano (`es-MX`). Anuncia automáticamente durante la carrera:

- Cada kilómetro completado: distancia, tiempo transcurrido y pace
- Cada 5 minutos: resumen de progreso
- Al pasar por un POI: nombre del punto de interés
- Al desbloquear un logro: nombre del logro

---

## 6. Persistencia de Datos

### Base de datos local — Hive

Hive almacena todos los datos del usuario directamente en el dispositivo, organizados en "boxes" (colecciones tipadas):

| Box | Tipo de dato | Contenido |
|-----|-------------|-----------|
| `users` | `User` | Perfil completo del usuario (XP, nivel, coins, cosméticos, racha...) |
| `runs` | `Run` | Historial de todas las carreras con ruta GPS |
| `achievements` | `UnlockedAchievement` | Registro de logros desbloqueados |
| `visited_pois` | `VisitedPoi` | POIs visitados con fecha |
| `active_missions` | `ActiveMission` | Misiones asignadas con progreso actual |
| `notification_history` | `NotificationItem` | Historial de notificaciones recibidas |

### Base de datos en la nube — Firestore

Firestore almacena el progreso para habilitar el leaderboard y la restauración en nuevos dispositivos:

**Colección `users/{uid}`** — un documento por usuario con:
`name`, `faculty`, `semester`, `xp`, `level`, `totalDistance`, `totalRuns`, `totalTime`, `currentStreak`, `bestStreak`, `coins`, `purchasedItemIds`, `equippedTitleId`, `equippedAvatarColorId`, `equippedAvatarFrameId`, `equippedRouteColorId`, `unlockedAchievementIds`, `visitedPoiIds`

**Colección `runs/{runId}`** — un documento por carrera con:
`userId`, `userName`, `distanceKm`, `durationSeconds`, `startTime`, `endTime`

### Reglas de seguridad de Firestore

```
- users/{userId}: lectura si autenticado, escritura solo el propio usuario
- runs/{runId}:   lectura si autenticado, escritura si el userId coincide con el auth
```

---

## 7. Manual de Usuario

### Registro e inicio de sesión

**Crear una cuenta nueva:**
1. Abre RUSH y toca **"Crear cuenta"**.
2. Ingresa tu nombre, correo y contraseña.
3. Opcionalmente selecciona tu **facultad** y **semestre** (necesarios para aparecer en el leaderboard por facultad).
4. Toca **"Registrarse"** — tu cuenta queda creada con Nivel 1 y 0 XP.

**Iniciar sesión:**
1. Ingresa tu correo y contraseña.
2. Toca **"Iniciar sesión"**.
> Si inicias sesión en un dispositivo nuevo, todos tus datos (XP, monedas, logros, cosméticos, POIs) se restauran automáticamente desde la nube.

---

### Dashboard (pantalla principal)

Al abrir la app llegas al Dashboard, donde se muestra:

- **Barra de XP**: progreso hacia el siguiente nivel
- **Estadísticas rápidas**: nivel actual, racha de días y distancia total
- **Misiones activas**: vista previa de tus retos del día en tarjetas horizontales deslizables
- **Historial de la semana**: gráfica de kilómetros por día
- **Notificaciones**: ícono de campana con contador de alertas nuevas

---

### Iniciar una carrera

1. Toca el botón **Correr** en la barra de navegación inferior o el botón de inicio en el Dashboard.
2. Asegúrate de que el GPS esté activado en tu dispositivo.
3. Toca el botón de **Play (▶)** en la pantalla del mapa.
4. La app comienza a rastrear tu ruta.

**Durante la carrera verás en la parte superior:**
- Distancia recorrida (km)
- Tiempo transcurrido
- Pace actual (min/km)

**Controles disponibles:**
- **Pausar**: detiene el rastreo temporalmente, el tiempo se congela.
- **Continuar**: reanuda el rastreo.
- **Terminar**: finaliza la carrera y muestra el resumen.

---

### Resumen de carrera

Al terminar aparece el resumen con:
- Estadísticas finales (distancia, tiempo, pace promedio)
- XP ganado desglosado (por distancia, por tiempo, por POIs, por logros)
- Nuevos logros desbloqueados en esta carrera
- POIs visitados por primera vez
- Botón para **compartir** en redes sociales

---

### Mapa del campus

El mapa muestra el campus de la UM con:
- Tu **posición actual** con flecha de dirección
- La **ruta recorrida** dibujada en el color de ruta que tengas equipado
- El **polígono naranja** que delimita el área universitaria
- Los **POIs** del campus marcados con íconos por categoría

Puedes alternar entre vista de mapa normal y **satélite** con el botón de capas en la esquina inferior izquierda. El mapa no permite desplazarse fuera de los límites del campus.

---

### Puntos de Interés (POIs)

Mientras corres, pasa a menos de **30 metros** de cualquier POI para visitarlo. Al visitarlo:
- Recibes XP bonus (15–35 XP)
- El Audio Coach anuncia el nombre del lugar
- El POI queda registrado como visitado en tu perfil

Los POIs están clasificados en tres categorías visibles por color en el mapa: **académico**, **deportivo** y **servicios/landmark**. Hay 38 POIs distribuidos por todo el campus.

---

### Misiones

Las misiones son retos con objetivos específicos que se reinician cada día (diarias) o cada semana (semanales). Puedes verlas en la pestaña **Logros → Misiones** o en las tarjetas del Dashboard.

| Tipo | Cantidad | Reinicio |
|------|----------|---------|
| Diarias | 5 | Cada día a medianoche |
| Semanales | 3 | Cada semana |

Ejemplos de misiones:
- Correr 1 km (calentamiento) — 40 XP
- Correr 2 km — 80 XP
- Correr 15 minutos — 60 XP
- Visitar 2 POIs — 70 XP
- Completar 1 carrera — 50 XP

---

### Logros

Los logros se desbloquean automáticamente al cumplir sus condiciones durante o al final de cualquier carrera. Puedes verlos en la pestaña **Logros**, en un grid que muestra cuáles están desbloqueados (con ícono a color) y cuáles aún no (bloqueados en gris).

Algunos logros especiales desbloquean **títulos** que puedes equipar en tu perfil y que aparecen junto a tu nombre en el leaderboard.

---

### Tienda y cosméticos

Accede desde **Logros → Tienda**. Aquí puedes gastar tus RUSH Coins en:
- **Colores de avatar**: cambia el color del borde de tu foto de perfil
- **Marcos de avatar**: agrega un borde decorativo especial
- **Colores de ruta**: cambia el color de la línea que dibuja tu carrera en el mapa

Para comprar: selecciona el cosmético y toca **"Comprar"**. Se equipa automáticamente. Para cambiar entre cosméticos ya comprados, toca **"Equipar"**.

---

### Leaderboard (Ranking)

Accede desde la pestaña **Ranking**. Muestra a todos los usuarios ordenados por XP.

**Filtros de período** (parte superior): Hoy · Semana · Mes · Total
**Filtros de alcance**: Global · Mi Facultad · Mi Semestre

> Los filtros de facultad y semestre solo aparecen si tienes esos datos configurados en tu perfil.

Los primeros 3 lugares aparecen en un podio visual con medallas (oro, plata y bronce).

---

### Perfil

Accede tocando tu avatar en la pantalla principal. Desde aquí puedes:
- Ver tus estadísticas acumuladas
- Ver y gestionar tus logros
- Equipar un título desbloqueado
- Cambiar tu foto de perfil
- Editar nombre, facultad y semestre
- Cerrar sesión

---

### Notificaciones

RUSH envía notificaciones locales para:
- **Recordatorio de racha** (20:00): si no has corrido en el día
- **Misiones disponibles** (06:00): aviso de misiones nuevas

El historial completo de notificaciones está disponible tocando el ícono de campana en el Dashboard.

---

### Preguntas frecuentes

**¿La app funciona sin internet?**
Sí. El tracking GPS, la gamificación y el historial funcionan completamente sin conexión. Los datos se sincronizan con Firebase automáticamente cuando vuelve la red.

**¿Por qué no detecta mi ubicación?**
Verifica que el GPS esté activado en la configuración del dispositivo y que hayas otorgado permiso de ubicación a RUSH.

**¿Puedo correr fuera del campus?**
Sí, el tracking GPS funciona en cualquier lugar. Sin embargo, los POIs solo se detectan dentro del área del campus de la UM.

**¿Se pierden mis datos si cambio de teléfono?**
No. Al iniciar sesión en el nuevo dispositivo, todos tus datos se restauran automáticamente desde Firebase.

**¿En qué idioma habla el Audio Coach?**
En español (es-MX), usando el motor TTS del dispositivo.

**¿Qué son los títulos?**
Son etiquetas especiales que se muestran junto a tu nombre en el leaderboard. Se desbloquean al alcanzar ciertos logros o niveles.

---

## 8. Glosario

| Término | Definición |
|---------|-----------|
| **XP** | Puntos de Experiencia. Moneda de progresión principal. Se acumulan corriendo, visitando POIs y completando misiones y logros. |
| **RUSH Coins** | Moneda secundaria de la app usada para comprar cosméticos en la tienda. |
| **Nivel** | Indicador de progreso del usuario. Hay 6 niveles, cada uno con un nombre y un umbral de XP. |
| **POI** | Point of Interest (Punto de Interés). Ubicaciones reales del campus georeferenciadas que el usuario puede visitar durante sus carreras. |
| **Racha** | Número de días consecutivos en que el usuario ha completado al menos una carrera. |
| **Pace** | Ritmo de carrera expresado en minutos por kilómetro (min/km). Indica qué tan rápido corre el usuario. |
| **Logro** | Hito desbloqueado automáticamente al cumplir una condición específica (distancia acumulada, velocidad, consistencia, etc.). |
| **Misión** | Reto con un objetivo medible y recompensa de XP. Las diarias se reinician cada día; las semanales, cada semana. |
| **Cosmético** | Elemento visual sin impacto en el gameplay (color de avatar, marco, color de ruta) que se compra con RUSH Coins. |
| **Título** | Etiqueta textual desbloqueada por logros o niveles, visible junto al nombre en el leaderboard. |
| **Leaderboard** | Tabla de clasificación de usuarios ordenada por XP, filtrable por período (hoy/semana/mes/total) y por alcance (global/facultad/semestre). |
| **Hive** | Base de datos NoSQL embebida en el dispositivo. Permite guardar y leer datos sin conexión a internet. |
| **Firestore** | Base de datos en la nube de Firebase. Almacena el progreso de todos los usuarios para el leaderboard y la restauración entre dispositivos. |
| **Offline-first** | Estrategia de diseño donde los datos se escriben primero localmente y se sincronizan a la nube en cuanto hay conexión disponible. |
| **Tiles** | Imágenes cuadradas que componen el mapa. RUSH usa tiles de CartoDB Voyager (mapa normal) y Google Maps (satélite). |
| **flutter_map** | Librería de Flutter para renderizar mapas con tiles raster de cualquier proveedor, sin depender de Google Maps SDK. |
| **Provider** | Patrón de gestión de estado en Flutter que permite a los widgets suscribirse a cambios en los servicios. |
| **TTS** | Text-to-Speech. Tecnología que convierte texto en voz. Usada por el Audio Coach de RUSH con el motor del propio dispositivo. |
| **Firebase Auth** | Servicio de autenticación de Firebase. Gestiona registro, inicio de sesión y sesiones persistentes. |
| **UUID** | Identificador único universal. Cada carrera recibe un UUID v4 que garantiza que no haya colisiones al sincronizar con Firestore. |
| **Haversine** | Fórmula matemática para calcular la distancia entre dos puntos geográficos sobre la esfera terrestre, usada para detectar la proximidad a POIs. |
| **GeoJSON** | Formato estándar para representar datos geográficos (puntos, polígonos, rutas) en JSON. Usado para definir el polígono del campus. |
| **Audio Coach** | Asistente de voz de RUSH que anuncia estadísticas y eventos durante la carrera usando TTS. |

---

## 9. Referencias

### Framework y lenguaje

- Google LLC. (2024). *Flutter documentation*. https://docs.flutter.dev
- Google LLC. (2024). *Dart programming language*. https://dart.dev/guides

### Mapas y geolocalización

- Fleaflet contributors. (2024). *flutter_map — A versatile mapping package for Flutter*. https://docs.fleaflet.dev
- Baseradder. (2024). *latlong2 package*. https://pub.dev/packages/latlong2
- Baseflow. (2024). *geolocator plugin for Flutter*. https://pub.dev/packages/geolocator
- CARTO. (2024). *CartoDB Voyager tile layer*. https://carto.com/basemaps

### Backend y base de datos

- Google LLC. (2024). *Firebase Authentication documentation*. https://firebase.google.com/docs/auth
- Google LLC. (2024). *Cloud Firestore documentation*. https://firebase.google.com/docs/firestore
- Hive CE contributors. (2024). *Hive CE — Fast & lightweight NoSQL database*. https://pub.dev/packages/hive_ce

### Gestión de estado

- Remi Rousselet. (2024). *Provider package for Flutter*. https://pub.dev/packages/provider

### Notificaciones y audio

- MaikuB. (2024). *flutter_local_notifications plugin*. https://pub.dev/packages/flutter_local_notifications
- Dlutton. (2024). *flutter_tts — Text-to-Speech plugin for Flutter*. https://pub.dev/packages/flutter_tts

### Utilidades

- Rive. (2024). *share_plus — Flutter plugin for sharing content*. https://pub.dev/packages/share_plus
- Baseflow. (2024). *connectivity_plus plugin*. https://pub.dev/packages/connectivity_plus
- Flutter community. (2024). *image_picker plugin*. https://pub.dev/packages/image_picker
- Daurnimator. (2024). *uuid package for Dart*. https://pub.dev/packages/uuid

### Herramientas de desarrollo

- Google LLC. (2024). *Android Studio*. https://developer.android.com/studio
- Apple Inc. (2024). *Xcode*. https://developer.apple.com/xcode
- GeoJSON contributors. (2024). *geojson.io — Draw and edit GeoJSON*. https://geojson.io

---

> _Fin del documento._
