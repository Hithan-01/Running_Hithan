# RUSH - Campus Running & Fitness Gamification App

## Descripcion

App movil gamificada de running para el campus de la Universidad de Montemorelos. Combina tracking GPS con elementos de juego: desbloquear POIs, misiones, XP y leaderboards.

---

## Gamificacion

### Sistema de XP y Niveles
- XP por kilometro corrido
- Niveles: Rookie Runner → Campus Jogger → Fitness Explorer → Trail Master → UM Athlete → Campus Legend
- Barra de progreso visual

### Puntos de Interes (POIs)
Checkpoints del campus que se desbloquean al pasar corriendo:
- Edificios academicos (Biblioteca, Facultades)
- Puntos deportivos (Gimnasio, Canchas, Pista)
- Lugares iconicos (Capilla, Cafeteria, Lago)

### Logros
- **Exploracion:** Visitar POIs, desbloquear mapa
- **Distancia:** 5K, 10K, acumulados
- **Consistencia:** Rachas de dias consecutivos
- **Velocidad:** Records de pace
- **Secretos:** Easter eggs (correr π km, correr a las 3am)

### Misiones
- **Diarias:** Metas simples que resetean cada 24h
- **Semanales:** Desafios mas grandes
- **Eventos:** Competencias especiales del campus

### Recompensas
- Badges coleccionables
- Titulos para el leaderboard
- RUSH Coins para personalizacion

### Leaderboards
- Global, por facultad, por semestre
- Semanal y mensual

---

## Features MVP

### Core
- [ ] Tracking GPS (iniciar/pausar/detener)
- [ ] Metricas en vivo: distancia, tiempo, pace
- [ ] Mapa del campus con ruta actual
- [ ] Guardar carreras (SQLite)

### Gamificacion Basica
- [ ] Sistema XP y niveles
- [ ] 5 POIs principales
- [ ] 10-15 logros
- [ ] Misiones diarias
- [ ] Leaderboard global

### Perfil
- [ ] Nivel y barra XP
- [ ] Stats totales
- [ ] Badges desbloqueados
- [ ] Historial de carreras

---

## Arquitectura

### Stack
- **Framework:** Flutter
- **Mapas:** Google Maps Flutter
- **GPS:** Geolocator
- **DB Local:** SQLite (sqflite)
- **State:** Provider

### Estructura
```
lib/
├── models/         # run, user, achievement, poi, mission
├── screens/        # dashboard, map, profile, leaderboard, history
├── widgets/        # xp_bar, mission_card, poi_marker, stats_panel
├── services/       # location, gamification, database
└── utils/          # constants, formatters
```

### Tablas SQLite
- users, runs, achievements, pois_visited, missions_completed

---

## Roadmap

1. **MVP Core** - Tracking, mapa, XP basico, 5 POIs, 10 logros
2. **Gamificacion** - 15+ POIs, 30+ logros, misiones, leaderboard
3. **Social** - Amigos, feed, desafios, crews
4. **Polish** - Graficas, rutas guardadas, eventos, tienda

---

## Flow Principal

```
Dashboard (XP, misiones, boton START)
    ↓
Mapa en vivo (stats, POIs)
    ↓
[Desbloqueo POI] → +XP, popup
    ↓
[Mision completada] → +XP, badge
    ↓
Fin carrera → Resumen con XP ganados, logros
```

---

**"RUSH - Run. Unlock. Share. Hustle."**



En esta unidad implementé el consumo de servicios externos en la app. El componente principal es el mapa interactivo, que consume la API de CartoDB para renderizar los tiles del campus y usa el servicio de geolocalización para rastrear la posición del usuario y dibujar su ruta en tiempo real. Además se integró Firebase Firestore para sincronizar las carreras completadas y consultar el leaderboard global.




