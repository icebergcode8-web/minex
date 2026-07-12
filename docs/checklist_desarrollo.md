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
- [ ] Consentimiento **UMP** antes de inicializar ads

## 🕹️ Fase 4 — Modos nuevos (en este orden de complejidad)
- [x] **Blitz** (`scoring.dart` con combos + tests, cronómetro descendente, +20s, regen de tablero, HUD combo, ítem Congelador) — jugable desde ModeSelect
- [x] **Niebla** (`fog_engine.dart` puro + tests, radio de visibilidad con fade por reloj de pared, overlay en el painter, ítem Linterna 5s) — jugable con dificultades del clásico. _Puntaje ×1.5 y récords propios → Fase 5 (economía)_
- [x] **Mentiroso** (`liar_engine.dart` puro + tests, 15% mienten ±1, marca de esquina doblada en el painter, ítem Escáner 3 cargas) — solo Medio+. _Puntaje ×2 → Fase 5 (economía)_
- [ ] **Oleadas** (`waves_engine.dart`, mejoras roguelike, modificadores, 3 vidas, **savegame serializado**)

## 🏆 Fase 5 — Economía (punto de publicación recomendado)
- [ ] Monedas + `EconomyProvider`/`EconomyRepo`
- [ ] Tienda offline (ítems, skins tablero, skins piezas)
- [ ] Sistema de ~30 logros + `AchievementsRepo`
- [ ] Reto Diario (seed por fecha, rotación de modo, racha) + `DailyRepo`

## 🧊 Fase 6 — Modo 3D (update 1.1)
- [ ] `tower_engine.dart` (conteo con 9 vecinas incluyendo celda inferior) + su unit test
- [ ] Render 2.5D con `Matrix4`/`Transform`, capas semitransparentes, rotación por gesto

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
