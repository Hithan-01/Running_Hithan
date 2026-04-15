# RUSH — Workflow y Estado del Proyecto

> Estado actualizado: Abril 2026

---

## Features implementadas ✅

### Core
- [x] Tracking GPS (iniciar / pausar / detener)
- [x] Métricas en vivo: distancia, tiempo, pace
- [x] Mapa del campus con ruta actual (flutter_map 8.2.2)
- [x] Vista satélite (Google Maps tiles) + mapa normal (CartoDB Voyager)
- [x] Polígono del campus delimitado con coordenadas GeoJSON exactas (26 vértices)
- [x] Restricción de cámara al campus (CameraConstraint.containCenter)
- [x] Guardar carreras (Hive local + Firestore sync offline-first)
- [x] Compartir carreras en redes sociales (share_plus)
- [x] Audio Coach TTS en español (km, 5 min, POIs, logros)

### Gamificación
- [x] Sistema XP y niveles (6 niveles: Rookie Runner → Campus Legend)
- [x] 38 POIs reales del campus UM con coordenadas precisas
- [x] 17 logros en 5 categorías
- [x] Misiones diarias (5) y semanales (3)
- [x] Rachas de días consecutivos
- [x] RUSH Coins y tienda de cosméticos
  - [x] Colores de avatar
  - [x] Marcos de avatar
  - [x] Colores de ruta en mapa
- [x] Títulos desbloqueables para el leaderboard

### Perfil
- [x] Nivel y barra de XP
- [x] Stats totales (distancia, carreras, tiempo, racha)
- [x] Logros desbloqueados (grid visual)
- [x] Historial de carreras con gráfica semanal
- [x] Editar nombre, facultad, semestre
- [x] Foto de perfil

### Leaderboard
- [x] Global, por facultad, por semestre
- [x] Filtros: Hoy / Semana / Mes / Total
- [x] Podio visual con medallas para top 3

### Cuenta
- [x] Login y registro con Firebase Auth (Email/Password)
- [x] Restauración completa de datos al relogear en dispositivo nuevo
- [x] Sync automático al recuperar conexión

### Notificaciones
- [x] Recordatorio de racha diaria (20:00 si no has corrido)
- [x] Misiones nuevas disponibles (06:00)
- [x] Historial de notificaciones en app
- [x] Android + iOS

---

## Pendiente / Bugs conocidos ⚠️

- [ ] **Firestore rules**: Configurar reglas de producción (actualmente bloqueando writes en emulador)
- [ ] **Daily mission reset**: Las misiones diarias no se reinician automáticamente a medianoche — solo se asignan al crear cuenta
- [ ] **Callbacks de gamificación**: `onAchievementUnlocked`, `onLevelUp`, `onMissionCompleted` definidos pero no conectados a UI (no hay toast/popup en tiempo real)
- [ ] **Mock data**: `_createMockRuns()` genera 3 carreras de prueba al crear cuenta nueva (intencional para demo, documentar con flag)

---

## Flujo principal de la app

```
Login / Registro
    ↓
Dashboard (XP, misiones activas, stats de la semana)
    ↓
[Correr] → Run Hub Screen
    ├── Mapa en vivo con ruta trazada
    ├── Stats: km / tiempo / pace
    ├── POIs detectados por radio 30m
    └── Audio Coach por km y por 5 min
    ↓
Fin de carrera → Resumen
    ├── XP ganado (distancia + tiempo + POIs + logros)
    ├── Nuevos logros desbloqueados
    ├── POIs nuevos visitados
    └── Botón compartir
    ↓
Sync a Firestore (si hay conexión)
```

---

## Estructura Firestore

### `users/{uid}`
```json
{
  "name": "string",
  "faculty": "string",
  "semester": 3,
  "xp": 500,
  "level": 2,
  "totalDistance": 5.0,
  "totalRuns": 3,
  "totalTime": 1800,
  "currentStreak": 1,
  "bestStreak": 2,
  "coins": 150,
  "purchasedItemIds": ["color_red"],
  "equippedTitleId": "campus_jogger",
  "equippedAvatarColorId": "color_red",
  "equippedAvatarFrameId": null,
  "equippedRouteColorId": null,
  "unlockedAchievementIds": ["first_run", "first_km"],
  "visitedPoiIds": ["biblioteca", "comedor"]
}
```

### `runs/{runId}`
```json
{
  "userId": "string",
  "userName": "string",
  "distanceKm": 3.5,
  "durationSeconds": 1800,
  "startTime": "Timestamp",
  "endTime": "Timestamp"
}
```

### Reglas de Firestore (configurar en consola)
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
      allow write: if request.auth != null
        && request.auth.uid == request.resource.data.userId;
    }
  }
}
```

---

## POIs del campus (38 total)

### Académico (13)
Biblioteca, Laboratorio FITEC, FITEC, Sistemas, FATEO, FACSA, ARTCOM, ESCEST y QCB, Idiomas, Psicología, UM Virtual, FACED, Preparatoria

### Deportes (5)
Gym, Cancha Principal, Canchas de Tenis, Campo de Softball, Cancha la Carlota

### Servicios / Landmarks (20)
Cajeros, Planta Física, Garden, Carpintería, Correos, Soymart, Casa del Rector, Dormitorio 1–4, COAE, Museo UM, Vicerrectoría, Arco Principal, Rectoría, Plaza 5 de Mayo, Comedor, Jardines Rectoría, Casa de Andrei

---

## Tiles del mapa

| Modo | Proveedor | URL |
|------|-----------|-----|
| Normal | CartoDB Voyager | `https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png` |
| Satélite | Google Maps | `https://mt{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}` |

---

## XP y economía

| Acción | XP | Coins |
|--------|----|-------|
| 1 km corrido | 50 XP | 10 |
| 1 minuto corrido | 2 XP | — |
| Visitar POI | 15–35 XP | — |
| Misión diaria | 40–100 XP | — |
| Logro | 25–500 XP | ~20% del XP |
| Subir de nivel | — | 50 |
