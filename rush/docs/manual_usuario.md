# Manual de Usuario — RUSH

> **RUSH** — *Run. Unlock. Share. Hustle.*
> App de running gamificada para el campus de la Universidad de Montemorelos.

---

## Tabla de Contenidos

1. [Introducción](#1-introducción)
2. [Requisitos del Dispositivo](#2-requisitos-del-dispositivo)
3. [Registro e Inicio de Sesión](#3-registro-e-inicio-de-sesión)
4. [Pantalla Principal (Dashboard)](#4-pantalla-principal-dashboard)
5. [Iniciar una Carrera](#5-iniciar-una-carrera)
6. [Mapa del Campus](#6-mapa-del-campus)
7. [Puntos de Interés (POIs)](#7-puntos-de-interés-pois)
8. [Sistema de Gamificación](#8-sistema-de-gamificación)
9. [Misiones](#9-misiones)
10. [Logros (Achievements)](#10-logros-achievements)
11. [Tabla de Clasificación (Leaderboard)](#11-tabla-de-clasificación-leaderboard)
12. [Historial de Carreras](#12-historial-de-carreras)
13. [Perfil de Usuario](#13-perfil-de-usuario)
14. [Notificaciones](#14-notificaciones)
15. [Preguntas Frecuentes](#15-preguntas-frecuentes)

---

## 1. Introducción

RUSH es una aplicación móvil diseñada para motivar a los estudiantes y miembros del campus de la Universidad de Montemorelos a hacer ejercicio corriendo. La app combina seguimiento GPS con mecánicas de videojuego: gana XP, sube de nivel, desbloquea logros y compite con otros usuarios mientras exploras el campus.

---

## 2. Requisitos del Dispositivo

| Plataforma | Versión Mínima |
|------------|---------------|
| Android    | Android 6.0 (API 23) |
| iOS        | iOS 12.0 |

**Permisos necesarios:**
- **Ubicación** — Indispensable para el rastreo GPS durante las carreras.
- **Ubicación en segundo plano** *(opcional)* — Para rastrear incluso con la pantalla apagada.
- **Notificaciones** — Para recibir recordatorios y alertas de misiones.
- **Micrófono / Audio** — Para el coach de voz durante las carreras.

---

## 3. Registro e Inicio de Sesión

### Registro de cuenta nueva

1. Abre la app y toca **"Crear cuenta"**.
2. Ingresa tu nombre de usuario, correo electrónico y una contraseña segura.
3. Toca **"Registrarse"** para crear tu cuenta.
4. Se creará automáticamente tu perfil de corredor con nivel 1.

### Iniciar sesión

1. Ingresa tu correo electrónico y contraseña.
2. Toca **"Iniciar sesión"**.

> **Nota:** La autenticación es gestionada por Firebase. Tu contraseña nunca se almacena en el dispositivo.

---

## 4. Pantalla Principal (Dashboard)

El Dashboard es tu punto de partida. Desde aquí puedes ver:

| Elemento | Descripción |
|----------|-------------|
| **Barra de XP** | Muestra tu progreso hacia el siguiente nivel |
| **Nivel actual** | Tu rango de corredor (ej. "Campus Jogger") |
| **Estadísticas rápidas** | Distancia total, carreras completadas, racha actual |
| **Misiones activas** | Vista previa de tus retos del día |
| **Notificaciones** | Ícono con contador de notificaciones pendientes |

---

## 5. Iniciar una Carrera

### Pasos para empezar a correr

1. Desde el menú inferior, toca el ícono central **Run Hub**.
2. Asegúrate de que el GPS esté activo en tu dispositivo.
3. Toca el botón **"Iniciar Carrera"**.
4. La app comenzará a rastrear tu ruta en tiempo real.

### Durante la carrera verás:

- **Tiempo transcurrido**
- **Distancia recorrida** (en kilómetros)
- **Pace actual** (minutos por kilómetro)
- **Mapa en vivo** con tu ruta trazada
- **POIs cercanos** marcados en el mapa

### Audio Coach

RUSH incluye un asistente de voz que te informa periódicamente sobre:
- Kilómetros completados
- Tiempo transcurrido
- Pace actual

### Pausar y reanudar

- Toca **"Pausar"** para detener temporalmente el rastreo.
- Toca **"Continuar"** para reanudar.

### Terminar la carrera

1. Toca **"Finalizar Carrera"**.
2. Se mostrará el **Resumen de Carrera** con todas tus estadísticas.
3. Se calculará y acreditará el XP ganado automáticamente.

---

## 6. Mapa del Campus

El mapa muestra el campus de la Universidad de Montemorelos en tiempo real, con:

- **Tu posición actual** (punto azul parpadeante)
- **POIs del campus** marcados con íconos de colores
- **Ruta recorrida** durante la carrera activa
- **Zona del campus** delimitada

> Los mapas son provistos por **OpenStreetMap** y no requieren conexión especial.

---

## 7. Puntos de Interés (POIs)

El campus tiene más de 30 POIs distribuidos en tres categorías:

### Categorías

| Categoría | Color | Ejemplos |
|-----------|-------|---------|
| **Académico** | Azul | Biblioteca, FITEC, FACSA, Sistemas |
| **Deportivo** | Verde azulado | Gimnasio, Canchas, Pista de Atletismo |
| **Landmark** | Amarillo | Capilla, Cafetería, Lago, Entrada Principal |

### Cómo visitar un POI

Mientras corres, pasa a menos de **30 metros** del POI. La app detectará automáticamente la visita y recibirás:

- **XP bonus** (15–35 XP según el POI)
- Notificación de descubrimiento
- El POI se marca como visitado en tu perfil

---

## 8. Sistema de Gamificación

### XP (Puntos de Experiencia)

Ganas XP de las siguientes formas:

| Acción | XP ganado |
|--------|-----------|
| Correr 1 kilómetro | 50 XP |
| Correr 1 minuto | 2 XP |
| Visitar un POI | 15–35 XP |
| Completar una misión | 40–250 XP |
| Desbloquear un logro | 25–500 XP |

### Niveles

| Nivel | Nombre | XP requerido |
|-------|--------|-------------|
| 1 | Rookie Runner | 0 XP |
| 2 | Campus Jogger | 500 XP |
| 3 | Fitness Explorer | 1,500 XP |
| 4 | Trail Master | 3,500 XP |
| 5 | UM Athlete | 7,000 XP |
| 6 | Campus Legend | 15,000 XP |

La barra de XP en la pantalla principal siempre muestra tu progreso hacia el próximo nivel.

---

## 9. Misiones

Las misiones son retos periódicos que te dan XP extra. Se dividen en:

### Misiones Diarias (5 por día)

| Misión | Objetivo | XP |
|--------|----------|----|
| Correr 1 km | Completar 1 kilómetro | 40 XP |
| Correr 2 km | Completar 2 kilómetros | 80 XP |
| Correr 15 minutos | Mantenerte activo 15 min | 60 XP |
| Visitar 2 POIs | Pasar cerca de 2 puntos | 70 XP |
| Completar 1 carrera | Finalizar cualquier carrera | 50 XP |

### Misiones Semanales (3 por semana)

| Misión | Objetivo | XP |
|--------|----------|----|
| Correr 10 km totales | Acumular 10 km en la semana | 200 XP |
| 5 carreras | Completar 5 carreras | 150 XP |
| Visitar 5 POIs | Descubrir 5 puntos distintos | 250 XP |

> Las misiones diarias se reinician cada medianoche. Las semanales, cada lunes.

---

## 10. Logros (Achievements)

Hay 16 logros desbloqueables organizados en 5 categorías:

### Exploración
- **Primer Paso** — Visita tu primer POI
- **Explorador** — Visita 5 POIs distintos
- **Maestro del Campus** — Visita todos los POIs

### Distancia
- **Primer Kilómetro** — Corre 1 km en total
- **5K Runner** — Acumula 5 km totales
- **10K Club** — Acumula 10 km totales
- **Maratonista** — Acumula 25 km totales
- **Ultra Runner** — Acumula 50 km totales

### Consistencia
- **Primera Carrera** — Completa tu primera carrera
- **Racha de 3 días** — Corre 3 días consecutivos
- **Racha de 7 días** — Corre 7 días consecutivos
- **Veterano** — Completa 10 carreras

### Velocidad
- **Rápido** — Logra un pace menor a 6:00 min/km
- **Corredor Élite** — Logra un pace menor a 5:00 min/km

### Secretos
- **Pi Runner** — Corre exactamente 3.14 km
- **Madrugador** — Completa una carrera antes de las 6:00 AM

---

## 11. Tabla de Clasificación (Leaderboard)

La pantalla de Leaderboard muestra el ranking de todos los usuarios ordenados por XP total. Puedes ver:

- Tu posición en el ranking
- Los corredores más activos del campus
- XP y nivel de cada usuario

---

## 12. Historial de Carreras

En la sección **History** puedes revisar todas tus carreras pasadas con:

- Fecha y hora de la carrera
- Distancia recorrida
- Tiempo total
- Pace promedio
- XP ganado en esa carrera
- Mapa de la ruta recorrida

---

## 13. Perfil de Usuario

Desde la sección **Profile** puedes:

- Ver tus estadísticas acumuladas (distancia total, carreras, XP)
- Ver tus logros desbloqueados
- Cambiar tu foto de perfil (toma foto o elige de galería)
- Ver tu nivel y barra de progreso

---

## 14. Notificaciones

RUSH envía notificaciones para:

- **Nuevas misiones disponibles** (cada día/semana)
- **Recordatorios de actividad** si llevas días sin correr
- **Logros desbloqueados** al completar un achievement
- **POIs cercanos** descubiertos durante una carrera

Puedes revisar el historial de notificaciones en el **Centro de Notificaciones** (ícono de campana en el Dashboard).

---

## 15. Preguntas Frecuentes

**¿La app funciona sin internet?**
Sí. El rastreo GPS, los datos locales y la gamificación funcionan sin conexión. La sincronización con el leaderboard y Firebase se realiza cuando hay conexión disponible.

**¿Por qué no detecta mi ubicación?**
Verifica que el GPS esté activado en tu dispositivo y que hayas otorgado permisos de ubicación a la app.

**¿Puedo usar la app fuera del campus?**
Sí puedes correr fuera del campus, pero los POIs solo se detectan dentro del área universitaria.

**¿Se pierden mis datos si desinstalo la app?**
Los datos locales (Hive) se eliminan con la desinstalación. Tu cuenta de Firebase permanece activa y puede sincronizarse al reinstalar.

**¿El audio coach habla en español?**
Sí, el coach de voz usa el idioma del sistema del dispositivo; por defecto está configurado en español.
