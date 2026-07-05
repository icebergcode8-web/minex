# Minex — Buscaminas Retro Moderno

Ver especificación completa en `docs/plan_buscaminas_minex.md` — 
léelo antes de implementar cualquier feature nueva.

## Reglas inmutables
- Flutter 3.44.0. Gestión de estado: SOLO Provider (nunca Riverpod/Bloc/GetX).
- Persistencia: Hive CE (no SQLite).
- 100% offline, sin backend, sin Firebase.
- Ads: SOLO google_mobile_ads. Ver docs/plan_buscaminas_minex.md sección 7 
  para el switch test/producción — NUNCA activar ads de prod sin confirmación explícita.
- Arquitectura: lógica de juego pura en domain/engine/ (sin Flutter), 
  Providers solo orquestan, Repositorios solo tocan Hive.

## Comandos
- flutter pub get
- flutter test
- flutter analyze