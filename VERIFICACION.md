# Verificación de la demo de Sistema EVE — compilación y tests

Fecha: 2026-11-09. Verificado en esta VM (Linux), no en la PC de Juan.

## Entorno

- Flutter SDK instalado para esta verificación en `~/workspace/flutter-sdk`
  (clon `--depth 1 --branch stable` del repo oficial de Flutter).
- Versión: **Flutter 3.47.9, channel stable, Dart 3.13.7**
  (framework revisión c197ca5199, 2026-10-29).
- `flutter pub get` resolvió **79 dependencias** y actualizó `pubspec.lock`
  (estaba desactualizado). `analysis_options.yaml` solo ganó el `exclude`
  de `build/**` que añade la propia herramienta de Flutter.

> Incidencia del entorno (no del proyecto): el primer `flutter pub get`
> falló extrayendo el Gradle wrapper porque `tar` como root intentaba
> preservar un uid inexistente en este contenedor. Se extrajo a mano el
> `.tgz` ya descargado con `--no-same-owner` en
> `flutter-sdk/bin/cache/artifacts/gradle_wrapper` y se escribió su
> archivo de stamp. No afecta al proyecto ni a la PC de Juan.

## Cómo se verificó

1. Se copió `lib/firebase_options.dart.example` a
   `lib/firebase_options.dart` **solo para compilar** (ese archivo está en
   `.gitignore`). Al terminar se borró y se comprobó que no queda
   (`ls: cannot access 'lib/firebase_options.dart'`).
2. `flutter pub get`, `flutter analyze`, `flutter test` y
   `flutter build web --release` en esta copia demo.
3. Las mismas correcciones se aplicaron también en
   `Sistema-EVE-refactor/` y allí se volvieron a correr analyze y test.

## Resultados

| Comprobación | Resultado |
|---|---|
| `flutter pub get` | OK, 79 dependencias |
| `flutter analyze` (demo) | **0 errores, 0 infos, 1 warning** |
| `flutter test` (demo) | **24/24 tests pasaron** |
| `flutter build web --release` | OK (`✓ Built build/web`, 42 MB, luego borrado) |
| `flutter analyze` (refactor) | **No issues found!** (0 de todo) |
| `flutter test` (refactor) | **24/24 tests pasaron** |

El único warning de analyze en la demo es un import sin uso en la
**plantilla temporal** `firebase_options.dart` (copia del `.example`).
Ese archivo se borra siempre antes de subir y el `firebase_options.dart`
real que genera `flutterfire configure` no tiene ese import, así que con
la config real el análisis queda en 0 issues, como se comprobó en la
copia refactor (que sí tiene su `firebase_options.dart` real).

## Errores que había y se corrigieron (demo y refactor)

El refactor traía código que **no compilaba**: 8 errores de análisis.

**Causa:** `Transaction.get()` de Firestore solo acepta
`DocumentReference`, no `Query`. El refactor hacía
`transaction.get(collection.where(...))` en 3 sitios, lo que además
hacía imposible la atomicidad que pretendía.

**Corrección (misma idea en los 3 sitios):** la mesa se resuelve con una
consulta normal **antes** de la transacción y dentro solo se lee su
documento por referencia (`transaction.get(tableRef)`). La lectura
autoritativa sigue dentro de la transacción (p. ej. la comprobación de
que la mesa está `available` al crear la orden).

- `lib/features/waiter/data/repositories/order_repository.dart`:
  `createOrder`, `markAsPaid`, `cancelOrder`. Se eliminaron
  `_findTableInTransaction` / `_findFirstTableInTransaction` y se crearon
  `_resolveTableRefForOrder`, `_findTableRefByNumberAndSection` y
  `_findFirstTableRefByNumber` (consultas normales, fuera de transacción).
- `lib/features/cashier/providers/cashier_providers.dart`:
  `_confirmPaymentInTransaction`: pre-lectura de la orden y de la mesa
  antes de la transacción; dentro ya no hay consulta.

**Tests que fallaban y se corrigieron (2 de 24):**

1. `test/report_csv_generator_test.dart` — el CSV ponía
   `Periodo,Este Mes` (etiqueta de `DateRange.displayText`) y el test
   esperaba fechas explícitas. El test tenía razón para un archivo
   exportado: una etiqueta como "Este Mes" es ambigua semanas después.
   Se añadió `_explicitRange()` en `report_csv_generator.dart` y los 3
   CSV (ventas, ingredientes, items) ahora ponen `d/M/yyyy - d/M/yyyy`.
   El PDF en pantalla sigue usando la etiqueta amistosa.
2. `test/widget_test.dart` — "A Timer is still pending even after the
   widget tree was disposed": el splash usaba `Future.delayed(1.5 s)` y
   el test terminaba con el temporizador pendiente. Se cambió a un
   `Timer` guardado en `_splashTimer` y cancelado en `dispose()` en
   `lib/features/auth/presentation/screens/splash_screen.dart`.
   Sin cambio de comportamiento para el usuario.

**Avisos/info limpiados (34 infos + 1 warning, demo y refactor):**

- 12× `withOpacity(x)` → `withValues(alpha: x)` en `reports_screen.dart`.
- 7× `(_, __)` → `(_, _)` en callbacks de error.
- `Table.fromTextArray` → `TableHelper.fromTextArray` (2×, PDF).
- `onReorder` obsoleto → `onReorderItem` en el diálogo de categorías,
  quitando el ajuste manual de `newIndex` (el nuevo callback ya lo
  ajusta; dejarlo habría reordenado mal).
- **Bug real:** `ReportFilters.operator ==` comparaba
  `dateRange == other` (un `DateRange` contra un `ReportFilters`,
  siempre falso). Ahora es `dateRange == other.dateRange`.
- 3× parámetro `sum` → `total` en `fold` (chocaba con nombre de tipo).
- `super.key` añadido a `PaidOrdersTab` y `PendingPaymentsTab`.
- Limpiezas menores: `'${x}'` → `'$x'`, `...lista.toList()` → `...lista`,
  `'${...}'` como string completo → expresión directa, import sin uso de
  `app_colors.dart` en `cashier_dashboard.dart`.
- `dart format` aplicado a los 13 archivos tocados (6 tenían formato
  pendiente).

## Secretos: comprobado en la demo

- No existe `android/app/google-services.json` ni
  `lib/firebase_options.dart` (el temporal se borró al final).
- `.gitignore` cubre ambos (`lib/firebase_options.dart`,
  `android/app/google-services.json`, `**/google-services.json`).
- Grep de `apiKey`, credenciales y contraseñas literales en `lib/`,
  `android/app/`, `firebase.json`, `firestore.rules`, `docs/`,
  `FIRESTORE_INDEX_SETUP.md`, `README.md` y `DEMO-SETUP.md`: sin
  secretos (solo aparecen identificadores de código como
  `_passwordController` o el validador de contraseña).
- Marca ficticia "La Esquina Demo" en README y docs.

## Lo que NO se verificó aquí (falta en la PC de Juan)

- **APK Android no compilado:** no hay Android SDK en esta VM.
  En su PC: `flutter build apk --debug` (o `flutter run` en su POCO).
- **Nada contra Firebase real:** no hay proyecto Firebase demo creado
  ni datos cargados. En su PC, seguir `DEMO-SETUP.md`:
  `flutterfire configure` en un proyecto nuevo, desplegar
  `firestore:rules,firestore:indexes` (incluye la regla de `counters`),
  crear usuarios demo por rol, menú, mesas e inventario ficticios y una
  orden de ejemplo en cada estado.
- **Flujo completo en vivo sin probar:** crear orden → cocina/bar →
  caja → reportes/PDF/CSV. Los tests cubren la lógica pura (idempotencia
  del descuento, cancelación, CSV, número de orden), pero las rutas que
  tocan Firestore (`createOrder`, `confirmPayment`, `cancelOrder`) no
  tienen tests de integración: no hay `fake_cloud_firestore` en pubspec.
- **Órdenes viejas (aviso heredado del refactor):** las órdenes creadas
  antes del refactor no tienen `inventoryDeducted` y se leen como
  `false` aunque su stock sí se descontó al crearlas; pagarlas podría
  descontar otra vez. No hay migración escrita. Solo afecta al negocio
  real, no a la demo (que parte vacía).
- Avisos cosméticos del build web (no bloquean): el paquete externo
  `image` tiene 2 lints que impiden build WASM, y falta la fuente
  `CupertinoIcons` aunque ningún código la usa (el paquete
  `cupertino_icons` se quitó como dependencia muerta).

## Veredicto

**La demo está lista para subir a GitHub.** Compila (`flutter analyze`
sin errores, `flutter test` 24/24, `flutter build web` OK) y no contiene
secretos. El repo se sube **sin** `firebase_options.dart` ni
`google-services.json`: quien la clone debe generarlos con
`flutterfire configure` en su propio proyecto Firebase demo, como
explica `DEMO-SETUP.md`.
