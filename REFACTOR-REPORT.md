# Informe final — Refactor completo de Sistema EVE

Fecha: 2026-11-08 / 2026-11-09
Fuente original: `Sistema-EVE-source/"APP eve flutter"/` — NO modificada.
Copia de trabajo: `Sistema-EVE-refactor/` — 93 archivos Dart (eran 84), 3,0 MB.
Estado: trabajo terminado en la copia. **No verificado con compilación ni tests en ejecución** (no hay Flutter/Dart en esta VM).

> ✅ **Nota sobre esta copia demo (2026-11-09):** la sanitización sí se hizo después en la copia demo: se eliminaron `android/app/google-services.json` y `lib/firebase_options.dart` (reemplazado por `lib/firebase_options.dart.example`), se quitaron las credenciales de prueba de `FIRESTORE_INDEX_SETUP.md`, la marca real se reemplazó por la ficticia "La Esquina Demo" y `firebase.json` se reemplazó por una plantilla con el proyecto `sistema-eve-demo`. Ver `VERIFICACION.md`. El aviso original describía la copia de refactor antes de esa limpieza y ya no aplica a esta demo.

## 1. Qué se cambió, por agente

### Agente A — Lógica de negocio P0 (ver AGENT-A-CORE-REPORT.md)

**Doble descuento de inventario — corregido.**
- `lib/features/waiter/data/models/order_model.dart`: nuevo `OrderStatus.cancelled` ("Cancelada") y bandera `inventoryDeducted` (por defecto `false`) en constructor, `fromFirestore` (documentos viejos → `false`), `toFirestore` y `copyWith`.
- `lib/features/waiter/data/repositories/order_repository.dart`: `createOrder()` ya NO descuenta inventario. El descuento ocurre una sola vez, al confirmar el pago.
- `lib/features/cashier/providers/cashier_providers.dart`: `confirmPayment` / `processTakeoutPayment` (y `markAsPaid`, que antes dejaba órdenes pagadas sin descontar nunca) descuentan una sola vez, en la misma transacción que marca la orden como `paid` + `inventoryDeducted = true`. Reintentar un pago no descuenta de nuevo. `confirmPayment` / `processTakeoutPayment` mantienen sus firmas; `CashierActions` solo gana un parámetro opcional `{InventoryRepository?}`.
- `lib/features/admin/data/repositories/inventory_repository.dart`: `deductOrderIngredientsInTransaction()` es el único punto de descuento por pago; `restoreOrderIngredientsInTransaction()` es su complemento para cancelación. El descuento al pagar limita a cero si falta stock (no bloquea la venta, como hacía el código de caja); el ajuste manual de admin sigue lanzando error si quedaría negativo.

**Atomicidad.**
- `createOrder`, `markAsPaid`, `cancelOrder` y `addItemsToExistingOrder` usan `runTransaction` (lecturas antes que escrituras, como exige Firestore).
- Número de orden: contador transaccional en la colección `counters`, documento `daily_orders_YYYYMMDD` (antes: contar las órdenes del día y sumar 1, con riesgo de duplicados).
- `adjustStock()` ahora es transaccional y registra cada movimiento en `inventory_movements` (se eliminó el TODO que dejaba la colección vacía). Sin `catch` vacíos en los archivos tocados.
- Funciones puras extraídas y testeables: `formatOrderNumber`, `dailyCounterDocId`, `shouldDeductInventoryAtPayment`, `shouldRestoreInventoryOnCancel`, `computeNewStock`, `aggregateIngredientQuantities`.
- `updateOrderStatus` ahora rechaza pasos directos a `paid` / `cancelled` con error claro, para que nadie se salte el descuento.

**cancelOrder().**
- Marca `status='cancelled'` en vez de hacer `delete()` del documento. Restaura inventario solo si `inventoryDeducted` era `true` y deja la bandera en `false`. Si ya estaba cancelada, no hace nada.

**Exportación CSV real (nuevo).**
- `lib/features/admin/utils/report_csv_generator.dart` (nuevo): usa el paquete `csv`, con las mismas columnas/datos que el PDF de reportes.
- `lib/features/admin/presentation/screens/reports_screen.dart`: botón "Exportar a CSV" con `_exportToCSV()` (espejo del PDF), compartiendo con `share_plus` / `path_provider`. El PDF queda intacto. `reports_providers.dart` no necesitó cambios.

**Tests nuevos.**
- `test/inventory_idempotency_test.dart`: idempotencia del descuento, cancelación con restauración, stock, agregación de ingredientes, número de orden.
- `test/report_csv_generator_test.dart`: columnas y filas del CSV.
- `test/widget_test.dart` intacto.

### Agente B — Limpieza (ver AGENT-B-CLEANUP-REPORT.md)

- **Dependencias muertas** (`pubspec.yaml`): quitadas 10 verificadas con grep (0 imports en `lib/`): `fl_chart`, `lottie`, `shimmer`, `cached_network_image`, `image_picker`, `permission_handler`, `cupertino_icons`, `riverpod_annotation`, `riverpod_generator`, `build_runner`. Conservadas por instrucción expresa: `csv`, `share_plus`, `path_provider`, `firebase_analytics`, `firebase_storage` (todas con 0 imports hoy) y el resto. `pubspec.yaml` parsea como YAML válido. `pubspec.lock` quedó desactualizado: hay que correr `flutter pub get` en la PC de Juan.
- **Análisis — 138 correcciones**: 116× `withOpacity(x)` → `withValues(alpha: x)` en 28 archivos; 16× `(_, __)` → `(_, _)`; 2× parámetro `sum` → `total` en `order_providers.dart`; 2× `DropdownButtonFormField value` → `initialValue` (la categoría del diálogo de menú se conserva con `value:` + `// ignore` porque se auto-asigna por código tras el primer build; con `initialValue` se rompería); 1× `library;` en `business_day.dart`; 1 warning: campo `_currencyFormat` sin uso eliminado de `cashier_dashboard.dart`. `avoid_print`: 0 por corregir (el código actual ya no tenía los `print()` del reporte viejo).
- Hallazgo: `analyze_output.txt` era de enero 2026 y estaba desactualizado — el código real tenía 141 `withOpacity` (no 104). Se corrigió contra el código real verificado con grep.
- **Código muerto**: 22 rutas borradas de `app_routes.dart` (quedan splash, login, 5 dashboards y reportes; 0 referencias restantes); `FirebaseService` borrado (0 usos) más su directorio; 10 carpetas vacías eliminadas (`find lib -type d -empty` = nada). No se borró `inventory_model.dart` (0 usos, fuera del encargo).
- **main.dart**: si Firebase falla al inicializar, ya no arranca la app sin backend; muestra `_FirebaseErrorApp` con el `ErrorDisplay` existente y botón Reintentar.
- Integridad verificada con md5: no tocó los archivos prohibidos; los 2 archivos que cambiaron fuera de su ámbito (`order_model.dart`, `inventory_repository.dart`) fueron modificados por el agente A.

### Agente C — Demo segura: NO SE HIZO

El agente fue rechazado por una política de seguridad. No se reintentó ni se rodeó el bloqueo. Consecuencia: en esta copia **siguen presentes** `android/app/google-services.json`, `lib/firebase_options.dart`, las credenciales de prueba en `FIRESTORE_INDEX_SETUP.md`, el nombre real del negocio en `docs/` y el README de plantilla de Flutter. Hay que hacer esta limpieza a mano antes de publicar (ver "Pendiente" abajo).

### Agente D — UI/UX (ver AGENT-D-UIUX-REPORT.md)

**Correcciones obligatorias (tarea 0), verificadas con grep:**
- Los 3 `switch` exhaustivos sobre `OrderStatus` se movieron a `lib/features/waiter/presentation/widgets/table_status_helpers.dart` (nuevo) con el caso `cancelled` añadido: icono `Icons.cancel_outlined`, color gris apagado, texto "Cancelada".
- `firestore.rules`: nueva regla `match /counters/{counterId} { allow read, create, update: if isAuthenticated(); }` (sin delete). El `create` es necesario porque `createOrder()` hace `transaction.set()` y crea el documento el primer día.

**Reestructuración por rol (sin tocar lógica de datos, providers ni rutas):**
- `table_grid_widget.dart`: 1.171 → 181 líneas. Extraídos `table_card.dart` (487), `table_detail_dialog.dart` (371), `table_section_filter.dart` (180, incluye leyenda de estados nueva) y `table_status_helpers.dart` (139). API pública de `TableGridWidget` intacta.
- `create_order_screen.dart`: 871 → 599 líneas. Extraídos `menu_item_card.dart` y `create_order_floating_bar.dart`; inputs de cliente con `AppTextField`. Flujo crear → añadir → confirmar intacto.
- `cashier_dashboard.dart`: 929 → 361 líneas. Extraídos `pending_payments_tab.dart` y `paid_orders_tab.dart`. En la tarjeta de pago: franja "Pendiente de confirmación en caja", total más grande (28→32), CONFIRMAR como `AppButton` success grande a ancho completo arriba y RECHAZAR secundario debajo (misma lógica `confirmPayment` / `rejectPayment` del agente A). Diálogos de pago: totales 20/22→28, botón confirmar con `AppButton` + `isLoading`, campo de efectivo con `AppNumberField` en caja, 13 `withOpacity` → `withValues` en `payment_dialog.dart`.
- Cocina/bar: nuevo `SectionStatusChip` (Pendiente / En preparación / Lista) en `kitchen_order_card.dart` y `bar_order_card.dart` junto al `UrgentTimerBadge` existente; las pestañas muestran ahora el conteo ("Pendientes (3)").
- Paleta sin cambios. `AppButton` / `AppTextField` / `AppNumberField` adoptados donde era seguro.
- Cambios de flujo documentados en el reporte de D (botones de caja apilados, leyenda, nota de orden cancelada, color del botón confirmar `0xFF4CAF50` → `AppColors.success`, etc.).

## 2. Qué quedó pendiente

1. **Demo segura — HECHO en la copia demo (2026-11-09).** Se quitaron `android/app/google-services.json` y `lib/firebase_options.dart` (reemplazado por `.example`), las credenciales de `FIRESTORE_INDEX_SETUP.md`, el nombre real del negocio en `docs/` (marca ficticia "La Esquina Demo"), se añadieron esos archivos al `.gitignore`, se reescribió el README y `firebase.json` es ahora una plantilla del proyecto `sistema-eve-demo`. Quien clone la demo debe crear su propio proyecto Firebase con `flutterfire configure` + datos ficticios + usuarios demo por rol (ver `DEMO-SETUP.md`).
2. **Verificación de la demo — HECHA en esta VM (ver `VERIFICACION.md`):** Flutter 3.47.9, `flutter analyze` 0 errores, `flutter test` 24/24, `flutter build web` OK. Falta aún en la PC de Juan: `flutter build apk` (no hay Android SDK en esta VM) y probar el flujo completo contra un Firebase demo real. Antes de usar el refactor en el negocio real, probar en un día de poco movimiento con un solo mesero.
3. **Desplegar la regla `counters` en Firebase** (no se desplegó) y la regla ya existente para el resto.
4. **Órdenes viejas (legacy):** sin `inventoryDeducted` se leen como `false` aunque su stock sí se descontó al crearlas. Posible descuento extra al pagarlas y cancelación sin restauración. No hay migración escrita; hay que decidir si se migran o se dejan caducar.
5. **Pendientes menores del agente D:** `reports_screen.dart` no dividido (estaba prohibido en su ámbito), `switch` con `default` en `my_orders_list_widget` / `takeout_orders_widget` que muestran "Desconocido" para cancelada, `AppCard` no adoptado en tarjetas, verdes/naranjas hardcodeados restantes en caja/cocina/bar.
6. **`inventory_model.dart`** (0 usos) sin borrar, anotado por B.
7. **Release con clave debug** (TODO ya existente en `build.gradle.kts`): pendiente separado para Play Store, no tocado.

## 3. Cómo probarlo Juan en su PC / en el negocio

En su PC, dentro de `Sistema-EVE-refactor/`:
1. `flutter pub get`
2. `flutter analyze` — debe quedar limpio o con pocos avisos restantes.
3. `flutter test` — deben pasar `inventory_idempotency_test.dart` y `report_csv_generator_test.dart`.
4. `dart format lib test` y revisar el diff.
5. Conectar su Firebase de producción solo para probar la app del cliente (la copia trae la config de producción; no la compartas): crear una orden de prueba, confirmar el pago en caja y comprobar en Firestore que el stock bajó **una sola vez** y que `inventoryDeducted` quedó en `true`. Cancelar otra orden y comprobar que queda `cancelled` (no borrada) y que el stock se restaura solo si se había descontado.
6. Probar la exportación CSV desde Admin → Reportes y compararla con el PDF.
7. Recorrer por rol: mesero crea orden → cocina/bar la marcan lista → caja confirma pago y corte → admin reportes.
8. **En el negocio, probar primero en un día de poco movimiento** y con un solo mesero, antes de usarlo en hora pico. No desplegar el arreglo en producción sin haberlo probado así.

## 4. Archivos de informe

- `AGENT-A-CORE-REPORT.md` — lógica P0, CSV, tests.
- `AGENT-B-CLEANUP-REPORT.md` — dependencias, análisis, código muerto.
- `AGENT-D-UIUX-REPORT.md` — UI/UX y correcciones de `cancelled` / `counters`.
- No hay `AGENT-C-DEMO-REPORT.md`: el agente C fue rechazado por política de seguridad.
