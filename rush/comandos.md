# Comandos - RUSH

## Básicos (los que más usarás)

| Comando | Qué hace |
|---------|----------|
| `flutter run` | Corre la app en el emulador |
| `r` | Hot reload (ver cambios rápido, mientras corre la app) |
| `R` | Hot restart (reinicia el estado) |
| `q` | Cerrar la app |

---

## Dependencias

| Comando | Qué hace |
|---------|----------|
| `flutter pub get` | Descarga dependencias después de modificar pubspec.yaml |

---

## Hive (base de datos)

| Comando | Qué hace |
|---------|----------|
| `dart run build_runner build --delete-conflicting-outputs` | Genera archivos .g.dart después de modificar modelos |

---

## iOS

| Comando | Qué hace |
|---------|----------|
| `cd ios && pod install` | Instala dependencias nativas de iOS |

---

## Solución de problemas

| Comando | Qué hace |
|---------|----------|
| `flutter clean && flutter pub get` | Limpia todo y reinstala (cuando algo no funciona) |
| `flutter doctor` | Diagnostica si algo está mal configurado |
