# 💣 MINEX — Buscaminas Retro Moderno
## Documento Maestro de Diseño y Desarrollo (Game Design Document + Especificación Técnica)

> **Propósito de este documento:** Especificación completa para que una IA desarrolle el juego en Flutter sin ambigüedades. Contiene diseño de juego, arquitectura, dependencias, monetización, navegación, UI/UX y plan de desarrollo por fases.

---

## 1. VISIÓN GENERAL

| Campo | Valor |
|---|---|
| Nombre provisional | **Minex** (alternativas: Minas Pro, Buscaminas X, MineCraft — evitar por trademark) |
| Género | Puzzle / Lógica / Arcade |
| Plataforma | Android (primero), iOS después |
| Conectividad | **100% Offline** (sin backend, sin login, sin Firebase) |
| Monetización | AdMob (banner + interstitial + rewarded) |
| Framework | Flutter **3.44.0** estable |
| Gestión de estado | **Provider (únicamente)** — sin Riverpod, sin Bloc, sin GetX |
| Persistencia | **Hive CE** (ver sección 6 para justificación) |
| Idiomas | Español (default) + Inglés |
| Estilo visual | Minimalista moderno con guiños retro. Flat design + neumorphism sutil |
| Orientación | Portrait (vertical) bloqueado, excepto tableros grandes que permiten zoom/pan |

### 1.1 Pilares de diseño
1. **Respeto al clásico:** el modo clásico debe sentirse EXACTAMENTE como el buscaminas de Windows (primer clic nunca es mina, chording con doble tap, banderas).
2. **Capas de novedad opcionales:** los modos nuevos agregan mecánicas, nunca las imponen sobre el clásico.
3. **Juice visual:** cada interacción tiene feedback (animación, partículas, vibración háptica, sonido).
4. **Sesiones cortas, progresión larga:** partidas de 1-10 min, meta-progresión con monedas y desbloqueos.
5. **Ads no invasivos:** el jugador nunca pierde una partida ni pierde el flow por un anuncio.

---

## 2. MODOS DE JUEGO

### 2.1 🟦 Modo Clásico
El buscaminas tradicional, fiel al original.

**Reglas:**
- Primer toque siempre seguro (el tablero se genera DESPUÉS del primer tap, garantizando que la celda tocada y sus 8 vecinas estén libres de minas).
- Tap corto = revelar. Long press = bandera. Tap en número revelado con banderas correctas alrededor = chording (revela vecinas).
- Cronómetro y contador de minas restantes.
- Récords locales por dificultad (mejor tiempo, winrate, racha).

**Dificultades:**

| Dificultad | Tablero | Minas | Densidad | Vidas |
|---|---|---|---|---|
| Fácil | 9×9 | 10 | 12.3% | 1 |
| Medio | 12×14 | 28 | 16.6% | 1 |
| Difícil | 16×20 | 64 | 20% | 1 |
| Experto | 20×26 | 115 | 22.1% | 1 |
| Personalizado | 5×5 a 30×40 | libre (máx 30%) | — | 1 |

> Tableros grandes usan `InteractiveViewer` para zoom y paneo.

### 2.2 🌫️ Modo Niebla (Fog of War)
- Solo son visibles las celdas en un radio de 3 celdas alrededor del último toque.
- Las celdas fuera del radio se "apagan" con un fade a oscuridad tras 4 segundos (siguen reveladas lógicamente, pero no visibles).
- Ítem **Linterna**: ilumina todo el tablero por 5 segundos (1 carga por partida, +1 con rewarded ad).
- Dificultades: mismas del clásico pero con puntaje ×1.5.

### 2.3 ⚡ Modo Contrarreloj (Blitz)
- Tablero 9×9 con 10 minas. Se resuelve contra un cronómetro descendente (60s).
- Al completar un tablero: +20 segundos y nuevo tablero inmediato (misma pantalla, animación de "barrido").
- El puntaje es la cantidad de tableros resueltos + celdas reveladas.
- Sistema de **combo**: revelar celdas en rápida sucesión sin errores llena una barra de combo que multiplica puntos (×1 → ×2 → ×3 → ×5).
- Ítem **Congelador**: pausa el reloj 10 segundos.

### 2.4 🃏 Modo Mentiroso (Liar's Mines)
- El 15% de los números del tablero mienten (muestran ±1 del valor real).
- Las celdas mentirosas tienen una **marca sutil**: esquina superior doblada (como página de libro). El jugador sabe CUÁLES mienten pero no en qué dirección.
- Ítem **Escáner de verdad**: revela el número real de una celda mentirosa (3 cargas).
- Solo disponible en tableros Medio en adelante. Puntaje ×2.

### 2.5 🌊 Modo Oleadas (Survival Roguelike)
- Empiezas con un tablero 7×7 con 6 minas y **3 vidas**.
- Cada oleada completada: el tablero crece (+1 fila y columna alternadas), la densidad de minas sube +0.5%, y eliges **1 de 3 mejoras aleatorias** (estilo roguelike):
  - +1 vida (máx 5)
  - +1 carga de un ítem aleatorio
  - Escudo (el próximo error no cuesta vida)
  - Radar pasivo (marca 1 mina al azar al inicio de cada oleada)
  - Visión (revela una zona de 3×3 segura al inicio)
- A partir de la oleada 5 se activan **modificadores** aleatorios de oleada: minas encadenadas, niebla parcial, 5% de números mentirosos, minas con retardo (aparecen 3 minas nuevas a mitad de la oleada, con animación de advertencia).
- Game over al perder todas las vidas. Puntaje = oleadas × celdas × multiplicadores. Tabla de récords local.
- **Este es el modo estrella del juego** — el que genera retención y sesiones largas.

### 2.6 🧊 Modo 3D (Torre de Minas)
Buscaminas por capas apiladas, presentado con perspectiva 3D isométrica hecha 100% con Flutter (`Transform` con matrices de perspectiva, sin motores externos).

**Reglas:**
- La torre tiene **N capas** (3, 5 o 7 según dificultad) de tableros 8×8.
- Solo la capa superior es jugable. Las capas inferiores se ven debajo, semitransparentes y desenfocadas (efecto de profundidad con `BackdropFilter` u opacidad escalonada).
- Los números cuentan minas en las 8 vecinas de su capa **más la celda directamente debajo** (9 vecinas totales). Un pequeño punto en la esquina de la celda indica si la mina contada está "debajo".
- Al completar una capa: animación de la capa disolviéndose en partículas y la torre "sube" (la siguiente capa se vuelve jugable) con una rotación sutil de cámara.
- Tocar una mina destruye la capa actual con animación de derrumbe y pierdes (o pierdes vida si tienes escudo).
- Gesto de **dos dedos para rotar la vista** ±30° (solo cosmético, con `GestureDetector` + `Transform`).

**Implementación técnica del 3D (sin librerías externas):**
```dart
// Perspectiva con Matrix4 nativo de Flutter
Transform(
  transform: Matrix4.identity()
    ..setEntry(3, 2, 0.0015)      // profundidad de perspectiva
    ..rotateX(-0.45)               // inclinación isométrica
    ..rotateZ(rotacionUsuario),    // rotación por gesto
  alignment: Alignment.center,
  child: Stack(children: capas),  // cada capa con translate en Z simulado
)
```
Cada capa inferior se renderiza con `Transform.translate` (offset Y creciente), `Opacity` decreciente (1.0, 0.55, 0.3...) y escala ligeramente menor para simular profundidad. Es falso 3D (2.5D) pero visualmente convincente y con rendimiento perfecto.

### 2.7 📅 Reto Diario
- Un tablero único por día generado con seed determinista: `seed = int.parse(DateFormat('yyyyMMdd').format(DateTime.now()))`.
- Rotación de modo: lunes clásico, martes niebla, miércoles blitz, jueves mentiroso, viernes clásico difícil, sábado oleadas (5 oleadas fijas), domingo 3D.
- Una sola oportunidad al día (un reintento viendo un rewarded ad).
- Completa retos consecutivos → **racha** con recompensas de monedas crecientes (día 7: cofre grande).
- 100% offline: la seed depende solo de la fecha local.

---

## 3. SISTEMA DE ÍTEMS Y ECONOMÍA

### 3.1 Ítems

| Ítem | Icono sugerido | Efecto | Cargas base |
|---|---|---|---|
| 🔦 Linterna | flashlight | Ilumina todo el tablero 5s (modo Niebla) | 1 |
| 🛰️ Radar | radar | Marca automáticamente 1 mina aleatoria con bandera dorada | 1 |
| 🛡️ Escudo | shield | El próximo error no termina la partida (la mina se desactiva con animación) | 1 |
| ❄️ Congelador | snowflake | Pausa el cronómetro 10s (Blitz / Reto diario cronometrado) | 1 |
| 🔍 Escáner | search | Revela el valor real de un número mentiroso | 3 (solo Mentiroso) |
| 🎯 Sonda | crosshair | Revela si UNA celda específica tiene mina, sin destaparla | 2 |
| 💥 Desactivador | scissors | Neutraliza una mina ya marcada con bandera (celda se vuelve segura) | 0 (solo por mejoras/monedas) |

**Reglas de economía de ítems:**
- Los ítems NO se pueden usar en Clásico (para mantener récords puros) salvo que el jugador active el "modo asistido" que marca la partida como no-récord.
- Recargar ítems: con monedas en la tienda, con rewarded ads (+1 carga en partida), o con mejoras del modo Oleadas.

### 3.2 Monedas y progresión (todo local)
- **Monedas** ganadas por: victoria (según dificultad y modo), reto diario, logros, rachas.
- **Tienda offline** (solo monedas del juego, SIN compras reales en v1):
  - Recargas de ítems.
  - **Skins de tablero**: Clásico Windows, Neón oscuro, Papel/sketch, Pixel retro, Océano, Espacial.
  - **Skins de banderas y minas**.
- **Logros locales** (~30): "Primera victoria", "Experto sin banderas", "Oleada 10", "Racha de 7 días", "Torre completa sin errores", etc. Cada logro da monedas.

---

## 4. UX / NAVEGACIÓN DE LA APP

### 4.1 Mapa de navegación

```
SplashScreen (logo animado, 1.5s, inicializa Hive + AdMob)
   │
   ▼
HomeScreen ────────────────────────────────┐
   │  - Logo/branding                      │
   │  - Botón grande "JUGAR" (→ ModeSelect)│
   │  - Reto Diario (card destacada)       │
   │  - Racha actual + monedas (header)    │
   │  - Accesos: Tienda | Logros | Stats | Ajustes
   │
   ├──▶ ModeSelectScreen (carrusel de cards de modos con animación)
   │       └──▶ DifficultySelectScreen (según modo)
   │               └──▶ GameScreen
   │                       ├──▶ PauseOverlay (resume/restart/exit)
   │                       └──▶ ResultOverlay (victoria/derrota)
   │                               ├── botón "Revivir" (rewarded ad, 1 vez)
   │                               ├── "Jugar de nuevo"
   │                               └── "Menú" (aquí se muestra interstitial según reglas §7)
   ├──▶ DailyChallengeScreen (calendario del mes + racha)
   ├──▶ ShopScreen (tabs: Ítems | Skins tablero | Skins piezas)
   ├──▶ AchievementsScreen
   ├──▶ StatsScreen (por modo: partidas, winrate, mejor tiempo, gráfica simple con CustomPaint)
   └──▶ SettingsScreen (sonido, vibración, idioma, tema claro/oscuro, controles tap/flag invertidos, créditos, política de privacidad)
```

### 4.2 Navegación técnica
- **Navigator 2.0 NO.** Usar `Navigator 1.0` con rutas nombradas (`onGenerateRoute`) — más simple, suficiente para esta app, y fácil de debuggear.
- Transiciones custom con `PageRouteBuilder`: fade+scale para entrar a juego, slide para pantallas de menú.
- `WillPopScope`/`PopScope` en GameScreen: back físico abre PauseOverlay, nunca sale directo.

### 4.3 Controles del tablero
- Tap = revelar, long-press = bandera (invertible en ajustes).
- **Switch rápido en pantalla**: botón flotante toggle 💣/🚩 para modo bandera (crítico en pantallas táctiles, es el estándar de buscaminas móviles).
- Doble tap en número = chording.
- Vibración háptica: ligera al revelar, media al poner bandera, fuerte al explotar (`HapticFeedback` nativo de Flutter, sin plugins).

---

## 5. DISEÑO VISUAL Y ANIMACIONES (100% Flutter nativo)

### 5.1 Branding
- **Estética:** minimalista moderno con ADN retro. Base flat, sombras suaves tipo neumorphism en celdas sin revelar (recuerda el relieve 3D del buscaminas de Windows 95 pero suavizado).
- **Paleta (tema oscuro default):**

| Rol | Color |
|---|---|
| Fondo | `#0F1420` (azul noche profundo) |
| Superficie/celda oculta | `#1E2636` con highlight superior `#2A3550` |
| Celda revelada | `#141B2A` |
| Acento primario | `#4ADE80` (verde menta — éxito, botones) |
| Acento secundario | `#FBBF24` (ámbar — monedas, banderas doradas) |
| Peligro | `#F87171` (rojo coral — minas) |
| Números 1-8 | Paleta clásica adaptada: azul `#60A5FA`, verde `#4ADE80`, rojo `#F87171`, morado `#A78BFA`, granate `#DC2626`, cian `#22D3EE`, negro→blanco `#E5E7EB`, gris `#9CA3AF` |

- **Tema claro:** fondo `#F1F5F9`, celdas `#FFFFFF` con sombras neumórficas grises.
- **Tipografía:** `google_fonts` → **"Nunito"** para UI (redondeada, amigable) y **"JetBrains Mono"** o "Space Mono" para números del tablero y cronómetro (guiño retro-digital).
- **Iconografía:** minas y banderas dibujadas con `CustomPaint` (vectorial, escalable, sin assets pesados) o emoji-style propios simples.

### 5.2 Animaciones que atrapan (motor: Flutter puro)

Usar `flutter_animate` para el 90% (declarativo, encadena efectos) + `AnimationController`/`CustomPaint` para partículas.

| Momento | Animación |
|---|---|
| Revelar celda | Flip 3D en Y (`Transform` rotateY 0→π/2, swap, π/2→0), 120ms, curve easeOutBack |
| Revelado en cascada (flood fill) | Las celdas se revelan en ONDAS desde el punto de toque, con delay incremental de 18ms por anillo de distancia (efecto dominó hipnótico — LA animación firma del juego) |
| Poner bandera | La bandera "cae" desde arriba con bounce (scale 0→1.15→1, 200ms) + micro partículas |
| Quitar bandera | Bandera sale volando hacia arriba con fade |
| Explosión de mina | 1) Shake del tablero (translate sinusoidal 300ms), 2) onda expansiva radial desde la mina (CustomPaint círculo creciente con fade), 3) partículas de escombros (15-20 partículas físicas simples: posición + velocidad + gravedad en un Ticker), 4) las demás minas se revelan en secuencia con pops escalonados |
| Victoria | Confeti (CustomPaint, ~60 partículas con rotación y física), tablero hace "wave" de brillo verde de izquierda a derecha, contador de puntos con tween numérico |
| Combo (Blitz) | Barra de combo con glow pulsante; al subir multiplicador: flash de color + número flotante "×3!" que escala y sube |
| Capa completada (3D) | Celdas se disuelven en partículas que caen, la torre asciende con easing, sutil rotación de cámara |
| Transición de oleada | Barrido diagonal de color + texto "OLEADA 5" con slide dramático |
| HomeScreen idle | Logo con float suave (sin/cos), mina decorativa que parpadea, cards con hover-scale al presionar |
| Cronómetro < 10s (Blitz) | Números en rojo con pulso de escala + tick háptico por segundo |

**Reglas de rendimiento:**
- Tablero renderizado como **un solo `CustomPaint`** para tableros >12×14 (una sola capa de pintura, hit-testing manual por coordenadas). Tableros pequeños pueden usar GridView de widgets.
- `RepaintBoundary` alrededor del tablero, HUD separado.
- Partículas en un único `Ticker` compartido; pool de partículas reutilizable (sin allocations por frame).
- Objetivo: 60fps estables en gama baja; probar con `flutter run --profile`.

### 5.3 Sonido y háptica
- Paquete `audioplayers` (compatible 3.44) con sonidos cortos .mp3/.ogg de baja latencia: reveal (pop suave), flag (click), explosión, victoria (jingle 8-bit), combo, tick de reloj, moneda.
- Música ambiente opcional en menús (loop lo-fi suave), OFF por default en partida.
- Ajustes independientes: música / SFX / vibración.

---

## 6. ARQUITECTURA TÉCNICA

### 6.1 Stack definido

| Área | Decisión | Justificación |
|---|---|---|
| Flutter | **3.44.0** (Dart 3.10+) | Versión del entorno del desarrollador |
| Estado | **provider ^6.1.x** | Requisito del proyecto. ChangeNotifier + Consumer/Selector |
| Persistencia | **Hive CE (hive_ce ^2.x + hive_ce_flutter)** | Ver justificación abajo |
| Ads | **google_mobile_ads** (última estable en pub.dev, requiere Flutter ≥3.27 ✅) | Plugin oficial de Google |
| Animaciones | **flutter_animate ^4.x** + APIs nativas | Declarativo, mantenido, ligero |
| Fuentes | **google_fonts ^6.x** | Nunito + mono |
| Audio | **audioplayers ^6.x** | Estable, baja latencia suficiente |
| Rutas de sistema | **path_provider ^2.x** | Requerido por Hive |
| Info del paquete | **package_info_plus** | Versión en Settings |
| URL launcher | **url_launcher** | Política de privacidad, links |

> ⚠️ **Instrucción para la IA desarrolladora:** al iniciar el proyecto, ejecutar `flutter pub add <paquete>` SIN fijar versión manualmente, para que pub resuelva la última versión compatible con Flutter 3.44.0. NO copiar versiones de tutoriales viejos.

### 6.2 ¿Por qué Hive y no SQLite?

**Decisión: Hive CE.** Razones:
1. Los datos del juego son **documentos/objetos** (récords, ajustes, inventario, progreso, logros) sin relaciones complejas ni queries — SQLite estaría sobredimensionado y obligaría a escribir SQL + mappers para todo.
2. Hive es **puro Dart** (sin canal nativo), lecturas casi instantáneas en memoria — ideal para leer ajustes/skins al arrancar y guardar partidas en curso sin jank.
3. Guardar/restaurar una **partida en progreso** (para el modo Oleadas o si matan la app) es trivial: serializar el estado del tablero a un objeto y `box.put()`.
4. Usar **`hive_ce`** (Community Edition), el fork mantenido activamente del Hive original (el original quedó sin mantenimiento). API idéntica.

**Cajas (boxes) definidas:**
```
settingsBox      → ajustes (tema, sonido, idioma, controles)
statsBox         → estadísticas por modo/dificultad
recordsBox       → mejores tiempos y puntajes
economyBox       → monedas, inventario de ítems, skins compradas/equipadas
achievementsBox  → estado de logros
dailyBox         → historial reto diario + racha
savegameBox      → partida en curso serializada (JSON string)
```
Todos los modelos se guardan como `Map<String, dynamic>`/JSON string para evitar TypeAdapters generados (menos código, cero build_runner para la BD).

### 6.3 Arquitectura de capas (Clean simplificada, Provider-friendly)

```
lib/
├── main.dart                     # init Hive, AdMob, MultiProvider, runApp
├── app.dart                      # MaterialApp, temas, onGenerateRoute
│
├── core/
│   ├── constants/                # colores, dimensiones, strings, difficulty configs
│   ├── theme/                    # AppTheme claro/oscuro, text styles
│   ├── audio/                    # AudioService (singleton simple)
│   ├── haptics/                  # HapticsService
│   └── utils/                    # seed diario, formateadores, extensiones
│
├── data/
│   ├── local/                    # HiveService (abre boxes, get/put tipados)
│   └── repositories/             # SettingsRepo, StatsRepo, EconomyRepo,
│                                 # AchievementsRepo, DailyRepo, SavegameRepo
│
├── domain/
│   ├── models/                   # Cell, Board, GameConfig, GameResult, Item,
│   │                             # WaveModifier, Achievement, SkinDef
│   └── engine/                   # ★ LÓGICA PURA, SIN FLUTTER ★
│       ├── board_generator.dart  # genera tablero con seed, safe first click
│       ├── minesweeper_engine.dart # revelar, flood fill, chording, win check
│       ├── liar_engine.dart      # capa de números mentirosos
│       ├── fog_engine.dart       # cálculo de visibilidad
│       ├── waves_engine.dart     # oleadas, mejoras, modificadores
│       ├── tower_engine.dart     # lógica 3D multicapa
│       └── scoring.dart          # puntajes y combos
│
├── providers/                    # ChangeNotifiers (estado de UI)
│   ├── game_provider.dart        # ★ estado de la partida actual (orquesta engine)
│   ├── settings_provider.dart
│   ├── economy_provider.dart     # monedas, ítems, skins
│   ├── stats_provider.dart
│   ├── achievements_provider.dart
│   ├── daily_provider.dart
│   └── ads_provider.dart         # estado de carga de ads, cooldowns
│
├── services/
│   └── ads/
│       ├── ad_config.dart        # ★ IDs test/prod + switch (sección 7)
│       └── ad_service.dart       # carga, muestra, retry, frequency capping
│
└── ui/
    ├── screens/                  # una carpeta por pantalla del mapa §4.1
    ├── widgets/
    │   ├── board/                # BoardWidget (CustomPaint), CellPainter
    │   ├── hud/                  # cronómetro, contador minas, barra combo, ítems
    │   ├── effects/              # partículas, confeti, shake, onda expansiva
    │   └── common/               # botones, cards, diálogos con estilo del juego
    └── overlays/                 # PauseOverlay, ResultOverlay, WaveUpgradeOverlay
```

**Reglas de arquitectura (para debugging fácil):**
1. El **engine es Dart puro y determinista**: recibe seed → mismo tablero siempre. 100% testeable con unit tests sin emulador.
2. Los **Providers nunca contienen lógica de juego**, solo orquestan engine ↔ UI y notifican. Si hay un bug de lógica, está en `domain/engine`; si es visual, en `ui`.
3. Los **Repositorios** son la única capa que toca Hive. Los Providers les piden/dan datos.
4. Usar `Selector`/`Consumer` granulares para no reconstruir el tablero completo cuando solo cambia el cronómetro (cronómetro en su propio ChangeNotifier o ValueNotifier).
5. `GameProvider` se crea con `ChangeNotifierProvider` **scoped a GameScreen** (no global) — se destruye al salir de la partida.

### 6.4 Modelo de datos clave (referencia)

```dart
class Cell {
  final int row, col;
  bool hasMine;
  bool isRevealed;
  bool isFlagged;
  int adjacentMines;      // valor real
  int? displayedNumber;   // valor mostrado (difiere en modo Mentiroso)
  bool isLiar;
  bool minedBelow;        // modo 3D: la mina contada está en capa inferior
}

class GameConfig {
  final GameMode mode;          // classic, fog, blitz, liar, waves, tower, daily
  final int rows, cols, mines;
  final int lives;
  final int? seed;              // null = aleatorio; fijo en reto diario
  final List<WaveModifier> modifiers;
  final int layers;             // modo 3D
}
```

### 6.5 Estados del juego (máquina de estados en GameProvider)

```
idle → generating → playing ⇄ paused
                      │
                      ├── exploding → lost → (revive con rewarded → playing)
                      └── won
```

---

## 7. 💰 ESTRATEGIA DE MONETIZACIÓN ADMOB

### 7.1 Filosofía: "El anuncio nunca interrumpe el juego"
Los ads solo aparecen en **momentos de transición natural** (fin de partida, regreso al menú) o son **elegidos por el jugador** (rewarded). Cero ads durante gameplay activo.

### 7.2 Formatos y colocación

| Formato | Dónde | Reglas anti-invasión |
|---|---|---|
| **Banner adaptativo** | Solo en HomeScreen y ModeSelect, anclado abajo | NUNCA en GameScreen (roba espacio y atención del tablero). Anchored adaptive banner |
| **Interstitial** | Al volver al menú tras terminar partida | Reglas de frecuencia abajo. NUNCA al perder inmediatamente (frustración doble = uninstall) |
| **Rewarded** | 100% opt-in del jugador | Es el formato principal de ingresos por su eCPM alto y buena percepción |

**Momentos rewarded (los que generan dinero de verdad):**
1. **"Revivir"** al tocar una mina (continúa la partida, la mina se desactiva). 1 vez por partida. — el más valioso.
2. **+1 carga de ítem** durante partida (botón discreto en HUD de ítems).
3. **Doblar monedas** ganadas en la pantalla de resultado.
4. **Reintento del reto diario**.
5. **+1 mejora extra** al elegir upgrade en Oleadas.

**Reglas de frecuencia del interstitial (frequency capping local):**
- Nunca antes de **3 partidas completadas** en la sesión.
- Cooldown mínimo de **3 minutos** entre interstitials.
- Nunca después de una derrota en la primera partida de la sesión.
- Nunca si el jugador acaba de ver un rewarded (<60s).
- Máximo **6 por sesión**.
- Implementación: contador de partidas + timestamp del último ad en `AdsProvider` (memoria de sesión, no persistente).
- Precargar el interstitial justo al iniciar partida (así está listo al terminar, sin espera).

### 7.3 ⚠️ Protocolo Test → Producción (CRÍTICO para no ser baneado de AdMob)

**Regla de oro: JAMÁS clicar ni mostrar ads de producción en un dispositivo de desarrollo.** Google detecta clics propios/tráfico inválido y suspende cuentas sin apelación fácil.

**Implementación del switch — archivo `lib/services/ads/ad_config.dart`:**

```dart
import 'package:flutter/foundation.dart';

class AdConfig {
  /// ══════════════════════════════════════════════
  /// SWITCH MAESTRO: cambiar a true SOLO para el
  /// build de release que sube a Play Store.
  /// ══════════════════════════════════════════════
  static const bool _useProductionAds = false;

  /// Doble candado: aunque el flag esté en true,
  /// los builds debug SIEMPRE usan test ads.
  static bool get isProduction => _useProductionAds && kReleaseMode;

  // ---- IDs DE PRUEBA OFICIALES DE GOOGLE (Android) ----
  static const _testBanner       = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _testRewarded     = 'ca-app-pub-3940256099942544/5224354917';

  // ---- IDs DE PRODUCCIÓN (rellenar desde consola AdMob) ----
  static const _prodBanner       = 'ca-app-pub-XXXXXXXXXXXXXXXX/BBBBBBBBBB';
  static const _prodInterstitial = 'ca-app-pub-XXXXXXXXXXXXXXXX/IIIIIIIIII';
  static const _prodRewarded     = 'ca-app-pub-XXXXXXXXXXXXXXXX/RRRRRRRRRR';

  static String get bannerId       => isProduction ? _prodBanner       : _testBanner;
  static String get interstitialId => isProduction ? _prodInterstitial : _testInterstitial;
  static String get rewardedId     => isProduction ? _prodRewarded     : _testRewarded;
}
```

> Verificar en la documentación oficial de AdMob los IDs de prueba vigentes al momento de desarrollar (los de arriba son los históricos oficiales de Google para Android; iOS tiene los suyos propios).

**Checklist del protocolo completo:**

- [ ] **Fase desarrollo:** `_useProductionAds = false`. Todo el desarrollo y QA con IDs de test. Los ads de prueba muestran la etiqueta "Test Ad".
- [ ] Crear la app en la consola AdMob y las 3 ad units (banner, interstitial, rewarded) DESDE EL INICIO — pueden tardar horas/días en activarse y las nuevas ad units tardan en servir.
- [ ] El **App ID de AdMob** (el `ca-app-pub-...~...` con tilde ~) va en `AndroidManifest.xml` como meta-data `com.google.android.gms.ads.APPLICATION_ID` — si falta, la app crashea al abrir. Puede ser el App ID real desde el inicio (el App ID no genera tráfico; lo que importa es que las AD UNITS sean de test).
- [ ] **Fase pre-release:** probar el flujo real con ads de producción SOLO registrando el dispositivo físico como **dispositivo de prueba** (`RequestConfiguration(testDeviceIds: [...])`) — así sirve ads reales marcados como test, sin riesgo.
- [ ] **Fase release:** cambiar `_useProductionAds = true`, compilar `flutter build appbundle --release`, verificar en logs que `isProduction == true`, subir a Play Store.
- [ ] **Post-release:** vincular la app publicada en la consola AdMob a su ficha de Play Store, y publicar el archivo **app-ads.txt** en tu dominio de desarrollador (requisito para que sirva el 100% del inventario). Sin app publicada y verificada, AdMob limita el ad serving.
- [ ] **NUNCA** abrir la app de producción y clicar tus propios anuncios, ni pedir a conocidos que cliquen. Ni "solo una vez".
- [ ] Implementar **UMP / consentimiento** (User Messaging Platform, incluido en google_mobile_ads): pedir consentimiento GDPR/regulaciones antes de inicializar ads. Aunque LATAM no lo exige igual, Play Store y AdMob sí lo requieren para tráfico europeo. Es un flujo estándar de ~30 líneas.
- [ ] Declarar los ads en el cuestionario de contenido de Play Console ("Contiene anuncios: Sí") y configurar audiencia (si marcas apto para niños, AdMob restringe a ads certificados para familias — decisión: **marcar 13+** para no limitar eCPM).

### 7.4 Robustez del AdService
- Precarga con reintentos y backoff exponencial (1s, 4s, 16s; máx 3 intentos) si `onAdFailedToLoad`.
- Si un rewarded no está listo cuando el jugador toca "Revivir": mostrar "Anuncio no disponible, intenta en unos segundos" y NO bloquear — nunca dejar botones muertos.
- Recordar: sin conexión no hay ads (juego offline) → todos los botones de ads se ocultan con `Connectivity` implícita (simplemente: si el ad no cargó, no se muestra el botón). El juego funciona perfecto sin internet; los ads son bonus cuando hay red.
- `dispose()` de todo ad mostrado. Un `BannerAd` por pantalla, nunca reusar instancias.

---

## 8. PANTALLAS — ESPECIFICACIÓN DETALLADA

### 8.1 SplashScreen
- Fondo del tema, logo (mina minimalista con destello) escala 0.8→1 con fade, 1.5s.
- En paralelo: `Hive.initFlutter()` + abrir boxes + `MobileAds.instance.initialize()` + precargar SettingsProvider.
- Navega con fade a Home. Si hay `savegameBox` con partida de Oleadas en curso → diálogo "¿Continuar tu partida?".

### 8.2 HomeScreen
- Header: monedas (con animación de contador al cambiar) + racha diaria 🔥 + botón ajustes.
- Centro: logo con float idle + botón JUGAR grande (pill, glow sutil pulsante).
- Card "Reto Diario" con el modo del día y estado (pendiente ✦ / completado ✓).
- Fila inferior: Tienda, Logros, Stats.
- Banner ad anclado al fondo, con placeholder del mismo alto para que la UI no salte al cargar.

### 8.3 ModeSelectScreen
- Carrusel horizontal (`PageView` con viewportFraction 0.82) de cards grandes por modo, cada una con: icono animado del modo, nombre, descripción de 1 línea, mejor récord personal, chip "NUEVO" si aplica.
- Parallax sutil entre card y fondo al deslizar.
- Los modos avanzados (Mentiroso, 3D) se desbloquean con victorias del clásico (Mentiroso: 5 victorias; 3D: 10) — crea progresión y curva de aprendizaje. Desbloqueo anticipado con monedas.

### 8.4 GameScreen (composición)
```
┌──────────────────────────────┐
│ ⏸  💣 042   ⏱ 01:23   🧰(2) │  ← HUD superior (pause, minas, timer, ítems)
│ [═══════ combo ═══════]      │  ← solo Blitz
│                              │
│        TABLERO               │  ← CustomPaint + InteractiveViewer
│                              │
│  [💣/🚩 toggle]  [ítem][ítem]│  ← barra de acción inferior
└──────────────────────────────┘
```
- ResultOverlay (victoria): confeti, tiempo, récord si aplica (badge "¡NUEVO RÉCORD!"), monedas ganadas con tween, botones: Doblar monedas (▶ rewarded) / Jugar de nuevo / Menú.
- ResultOverlay (derrota): la mina culpable resaltada, botón grande "REVIVIR ▶" (rewarded, countdown de 5s para decidir), Reintentar / Menú.

### 8.5 SettingsScreen
- Secciones: Audio (música/sfx sliders), Juego (vibración, invertir tap/bandera, mostrar tutorial), Apariencia (tema claro/oscuro/sistema, idioma ES/EN), Acerca de (versión, política de privacidad — URL obligatoria para Play Store por los ads, créditos).

---

## 9. LOCALIZACIÓN
- `flutter_localizations` + archivos ARB (`intl`): `app_es.arb` (default) y `app_en.arb`.
- Todos los strings de UI en ARB desde el día 1 (nunca hardcodear).

## 10. TESTING MÍNIMO OBLIGATORIO
- **Unit tests del engine** (prioridad máxima): generación con seed reproducible, primer clic seguro, flood fill correcto, chording, condición de victoria, números mentirosos consistentes, conteo 3D con capa inferior, lógica de oleadas.
- Test del frequency capping de ads (clase pura con clock inyectable).
- Golden/widget tests opcionales para el tablero en v1.1.

## 11. PLAN DE DESARROLLO POR FASES (para salir rápido)

| Fase | Contenido | Objetivo |
|---|---|---|
| **F1 — Núcleo (MVP jugable)** | Engine clásico + tests, GameScreen con CustomPaint, HUD, dificultades, animación de cascada y explosión, Home básico, Hive settings/records | Buscaminas clásico pulido y jugable |
| **F2 — Juice + estructura** | Todas las animaciones §5.2, sonidos, háptica, temas claro/oscuro, navegación completa, stats, ajustes, localización | Se siente premium |
| **F3 — Ads** | AdService completo con test ads, frequency capping, rewarded revive + doblar monedas, UMP consent | Monetización lista (en test) |
| **F4 — Modos nuevos** | Blitz → Niebla → Mentiroso → Oleadas (en ese orden de complejidad) | Contenido diferenciador |
| **F5 — Economía** | Monedas, tienda, skins, logros, reto diario + racha | Retención |
| **F6 — Modo 3D** | Torre de minas con perspectiva 2.5D | El "wow" del juego |
| **F7 — Release** | QA en dispositivos reales, iconos/screenshots/ficha de Play Store, switch a prod ads, appbundle firmado, app-ads.txt | Publicación 🚀 |

> **Estrategia de lanzamiento recomendada:** publicar tras F5 (sin el modo 3D) para salir antes, y lanzar el 3D como actualización 1.1 — las actualizaciones con features nuevas ayudan al algoritmo de Play Store y dan material para promoción.

## 12. CHECKLIST PRE-PUBLICACIÓN
- [ ] `flutter analyze` sin warnings; tests del engine en verde.
- [ ] Probado en Android gama baja (60fps en tablero Experto).
- [ ] Modo avión: TODO funciona (ads ocultos, sin errores).
- [ ] Proceso kill + reabrir: partida de Oleadas restaurada.
- [ ] Política de privacidad publicada (mencionando AdMob y datos de publicidad).
- [ ] `_useProductionAds = true` SOLO en el commit del build final.
- [ ] Versioning: `1.0.0+1` en pubspec.
- [ ] Icono adaptativo Android + splash nativo (`flutter_launcher_icons`, `flutter_native_splash`).

---
*Documento v1.0 — Minex. Listo para usarse como especificación de desarrollo asistido por IA.*
