# ✅ Minex — Checklist de Desarrollo

> Seguimiento paso a paso del desarrollo. Basado en `plan_buscaminas_minex.md`.
> Marca cada `[ ]` → `[x]` conforme se completa. Orden pensado para salir rápido (publicar tras F5).

**Reglas inmutables (recordatorio):** Flutter 3.44.0 · solo Provider · Hive CE · 100% offline · ads solo google_mobile_ads · lógica de juego pura en `domain/engine/`.

---

## 🔧 Fase 0 — Setup del proyecto ✅
- [x] ~~`flutter create`~~ (ya existía) y estructura de carpetas (`core/`, `data/`, `domain/`, `providers/`, `services/`, `ui/`) según §6.3
- [x] `flutter pub add` de dependencias **sin fijar versión** (provider, hive_ce, hive_ce_flutter, google_mobile_ads, flutter_animate, google_fonts, audioplayers, path_provider, package_info_plus, url_launcher, intl)
- [x] Configurar `flutter_localizations` + ARB (`app_es.arb`, `app_en.arb`) desde el día 1 — `generate: true` + `l10n.yaml`
- [x] Bloquear orientación portrait (`SystemChrome.setPreferredOrientations` en `main.dart`)
- [x] `AndroidManifest.xml`: meta-data `APPLICATION_ID` de AdMob (App ID de test por ahora, `INTERNET` permission) — ⚠️ reemplazar por App ID real antes del release

## 🎮 Fase 1 — Núcleo (MVP jugable) ✅
- [x] **Modelos:** `Cell`, `Board`, `GameConfig`, `GameResult` (`domain/models/`) — + `GameMode`, `GameStatus`, `WaveModifier`
- [x] **Engine puro:** `board_generator.dart` (seed + primer clic seguro con vecinas), `minesweeper_engine.dart` (revelar, flood fill BFS, chording, win check, revealAllMines)
- [x] **Unit tests del engine** (prioridad máxima §10): seed reproducible, primer clic seguro, flood fill, chording, victoria — **20/20 en verde**
- [x] `HiveService` + boxes `settingsBox` y `recordsBox` (+ `SettingsRepository`, `RecordsRepository`)
- [x] `GameProvider` con máquina de estados (idle→generating→playing⇄paused→won/lost), scoped a GameScreen — + tests de orquestación
- [x] `BoardWidget` con **CustomPaint** + `_BoardPainter` (+ `InteractiveViewer` para tableros grandes, `RepaintBoundary`)
- [x] HUD superior (pause, contador minas, cronómetro en `ValueNotifier` aparte), toggle 💣/🚩, chording por doble tap
- [x] Dificultades (Fácil→Experto) — presets + `DifficultySelectScreen`. _(Personalizado: config listo, falta UI — Fase 2)_
- [x] Animaciones firma: **cascada de flood fill en ondas** (delay BFS 18ms) + **explosión de mina** (shake + onda expansiva)
- [x] HomeScreen básico y navegación a partida (Navigator 1.0 + `onGenerateRoute` + transiciones custom)

## ✨ Fase 2 — Juice + estructura ✅
- [x] Resto de animaciones §5.2 (flip de celda, bandera con bounce, victoria/confeti) — en `board_widget.dart` (flip real + bounce + wave de victoria) y `effects/confetti.dart`
- [x] `AudioService` (audioplayers) + `HapticsService` — háptica cableada a revelar/bandera/explosión/victoria. _AudioService listo y tolerante; faltan los `.mp3` en `assets/audio/` (no-op silencioso mientras tanto)_
- [x] Temas claro/oscuro/sistema + tipografías (Nunito + mono) — `BoardPalette` (ThemeExtension) + `AppTheme`, conmutable en Ajustes. _Nota: google_fonts descarga en runtime; considerar bundlear las fuentes para 100% offline_
- [x] Navegación completa (Navigator 1.0 + `onGenerateRoute`, `PageRouteBuilder`, `PopScope` en GameScreen)
- [x] Pantallas: ModeSelect (carrusel), Stats (CustomPaint), Settings
- [x] Localización completa de todos los strings (es/en)
- [x] _Pendiente arrastrado de F1:_ UI de dificultad **Personalizada** — `custom_setup_screen.dart` con sliders y validación de densidad máx 30%

## 💰 Fase 3 — Ads
- [ ] `ad_config.dart` con switch test/prod y doble candado (`kReleaseMode`)
- [ ] `AdService` (carga, retry con backoff, dispose, banner por pantalla)
- [ ] `AdsProvider` con **frequency capping** (§7.2) — clase pura con clock inyectable + su test
- [ ] Rewarded "Revivir" + "Doblar monedas"; interstitial al volver al menú; banner en Home/ModeSelect
  - [ ] Rewarded **"Revivir con escudo"** en el modo Torre 3D (§2.6): al tocar una mina, ver anuncio → la capa se conserva y se continúa (1 vez por partida).
- [ ] Consentimiento **UMP** antes de inicializar ads

## 🕹️ Fase 4 — Modos nuevos (en este orden de complejidad)
- [x] **Blitz** (`scoring.dart` con combos + tests, cronómetro descendente, +20s, regen de tablero, HUD combo, ítem Congelador) — jugable desde ModeSelect
- [x] **Niebla** (`fog_engine.dart` puro + tests, radio de visibilidad con fade por reloj de pared, overlay en el painter, ítem Linterna 5s) — jugable con dificultades del clásico. _Puntaje ×1.5 y récords propios → Fase 5 (economía)_
- [x] **Mentiroso** (`liar_engine.dart` puro + tests, 15% mienten ±1, marca de esquina doblada en el painter, ítem Escáner 3 cargas) — solo Medio+. _Puntaje ×2 → Fase 5 (economía)_
- [x] **Oleadas** (`waves_engine.dart` puro + tests, 3 vidas, crecimiento alternado +0.5%, mejoras roguelike 1-de-3, escudo/radar/visión, game over, **savegame** run-level en `savegameBox` + "Continuar" en Home) — jugable.
- [x] **Modificadores de oleada ≥5** (§2.5): minas encadenadas (`generateChained`), niebla parcial (reusa FogEngine), 5% números mentirosos (reusa LiarEngine), minas con retardo (`injectMines` a mitad de oleada + aviso) — con tests.
- [x] **Savegame a nivel de tablero exacto** (§6.2): `Board.toMap/fromMap` + `Cell.toMap/fromMap` (serialización pura), persistencia tras cada revelado/bandera y restauración exacta (celdas, banderas, minas inyectadas, modificador y pantalla de mejora) — "kill+reabrir restaura Oleadas" tal cual estaba (§12), con tests de round-trip.

## 🏆 Fase 5 — Economía (punto de publicación recomendado) ✅
- [x] **Monedas** + `EconomyProvider`/`EconomyRepository` (economyBox) — `economy_engine.dart` puro calcula recompensas por modo/dificultad (Niebla ×1.5, Mentiroso ×2, Reto Diario ×2) + tests. `GameProvider` emite `GameOutcome` al terminar; `GameScreen` orquesta el otorgado (monedas + racha + logros) y el `ResultOverlay` muestra "+monedas" y logros nuevos.
- [x] **Tienda offline** (`ShopScreen`, 3 pestañas): recargas de ítems (Linterna/Congelador/Escáner → cargas iniciales extra vía inventario), **skins de tablero** (6, `core/theme/skins.dart`) y **skins de piezas** (4). Compra/equipa con monedas; el `BoardWidget` pinta la skin equipada. _Ítems no usables en Clásico (récords puros) — solo cargan en su modo._
- [x] **~30 logros** + `AchievementsRepository` (achievementsBox) — `achievements_catalog.dart` puro (predicados sobre `AchievementContext`) + `AchievementsProvider` que ensambla el contexto desde los repos, desbloquea y devuelve monedas. `AchievementsScreen` con progreso. Con tests.
- [x] **Reto Diario** (`DailyEngine` puro: seed `yyyyMMdd`, rotación de modo lun→dom, fallback torre→clásico hasta F6) + `DailyRepository` (dailyBox) + `DailyProvider` (reloj inyectable) con **racha** y recompensas crecientes (cofre al día 7). `DailyChallengeScreen` + tarjeta y racha 🔥 en Home. Con tests. _Reintento vía rewarded ad → Fase 3 (Ads)._
  - _Pendiente menor: desbloqueo progresivo de modos (§8.3: Mentiroso 5 victorias / 3D 10) — hoy todos accesibles._

## 🧊 Fase 6 — Modo 3D (update 1.1) ✅
- [x] **`tower_engine.dart`** puro + modelo `Tower` (capas apiladas, capa activa): genera N capas 8×8 con centro seguro y calcula la adyacencia 3D — **8 vecinas de la capa + la celda directamente debajo** (9 vecinas), marcando `Cell.minedBelow`. `towerConfig` 3/5/7 capas (Fácil/Medio/Difícil). Con unit tests (adyacencia con celda inferior, determinismo, centro seguro).
- [x] **Render 2.5D** (`TowerBoardWidget`) con `Transform`/`Matrix4` (perspectiva + `rotateX` isométrico), capas inferiores semitransparentes y atenuadas, **solo la superior interactiva**, **punto indicador de "mina debajo"**, y **rotación de dos dedos ±30°** (cosmética). Integrado en `GameProvider` (avance de capa al completar, victoria al despejar la torre, derrota al tocar mina, HUD "capa X/N" + reloj) y emite `GameOutcome` (monedas/logros). El Reto Diario del domingo ya usa la Torre real (5 capas). Con tests de flujo (provider) + smoke.

## 🚀 Fase 7 — Release
- [ ] QA en Android gama baja (60fps en Experto, `--profile`), modo avión, kill+reabrir restaura Oleadas
- [ ] Iconos adaptativos + splash nativo (`flutter_launcher_icons`, `flutter_native_splash`)
- [ ] Política de privacidad publicada, cuestionario Play Console ("Contiene anuncios: Sí", 13+)
- [ ] Crear ad units reales en AdMob, `_useProductionAds = true` **solo en el commit final**, `flutter build appbundle --release`
- [ ] Post-release: vincular a Play Store + publicar `app-ads.txt`

---

## 📌 Recordatorios transversales (aplican en todas las fases)
- [ ] Nunca hardcodear strings — todo a ARB desde F1
- [ ] `flutter analyze` sin warnings antes de cerrar cada fase
- [ ] Tests del engine en verde como criterio de avance
- [ ] App ID de AdMob en el manifest desde el inicio, pero **ad units siempre de test** hasta el commit final
- [ ] Usar `Selector`/`Consumer` granulares (no reconstruir el tablero completo por el cronómetro)

---
*Checklist derivado de `plan_buscaminas_minex.md` v1.0 — Minex.*
