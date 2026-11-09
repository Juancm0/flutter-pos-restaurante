# Sistema EVE — Demo pública

POS Android en Flutter + Firebase para un negocio ficticio de comida rápida
("La Esquina Demo"). Es la versión pública y segura del proyecto real
Sistema EVE, que Juan Carlos Martínez Mendoza desarrolló para un negocio
real con unos 100 clientes al día.

> Demo, no producción: no contiene datos, precios ni credenciales reales.
> Para correrla necesitas tu propio proyecto Firebase (ver `DEMO-SETUP.md`).

## Qué hace

- **Meseros:** crean órdenes por mesa o para llevar, con modificadores.
- **Cocina / Bar:** ven las órdenes por sección y marcan listas.
- **Caja:** confirma el pago, hace el corte de caja y exporta reportes.
- **Administración:** menú, inventario, mesas, usuarios y reportes (PDF y CSV).

## Lo que se arregló en este refactor

- **Doble descuento de inventario:** antes el stock se descontaba al crear
  la orden y otra vez al confirmar el pago. Ahora se descuenta una sola
  vez, al confirmar el pago, en la misma transacción que marca la orden
  como pagada, con bandera `inventoryDeducted` para que reintentar no
  descuente dos veces.
- **Órdenes atómicas:** la creación usa transacción de Firestore y un
  contador transaccional para el número de orden del día, sin duplicados
  aunque dos meseros creen órdenes a la vez.
- **Cancelar ya no borra:** una orden cancelada queda como `cancelled`
  en el historial, y el stock se restaura solo si ya se había descontado.
- **CSV real:** exportación CSV en Admin → Reportes, además del PDF.
- **Inventario con historial:** `adjustStock` por fin escribe en
  `inventory_movements`.
- **Limpieza:** 10 dependencias muertas quitadas, 138 avisos de análisis
  corregidos, 22 rutas muertas borradas, widgets grandes divididos
  (`table_grid_widget`, `create_order_screen`, `cashier_dashboard`).
- **UI/UX por rol:** caja con total grande y botón CONFIRMAR a ancho
  completo; cocina/bar con conteos por pestaña y estado por sección.

## Stack

Flutter, Dart, Riverpod, Firebase (Auth, Firestore, Storage, Analytics),
Clean Architecture por features.

## Cómo correr la demo

Ver [DEMO-SETUP.md](DEMO-SETUP.md). Resumen: `flutter pub get`,
crea un proyecto Firebase demo, genera `lib/firebase_options.dart` con
`flutterfire configure`, carga los datos de ejemplo y corre con
`flutter run`.

## Tests

`flutter test` — hay tests para idempotencia de inventario y para el
generador CSV. Verificado en esta VM (ver `VERIFICACION.md`): Flutter
3.47.9, `flutter analyze` 0 errores, 24/24 tests, `flutter build web`
OK. Falta compilar el APK en una PC con Android SDK.

## Estructura

```
lib/
  core/        # tema, constantes, widgets comunes, utils
  features/
    admin/     # menú, inventario, mesas, usuarios, reportes
    auth/      # login
    bar/       # órdenes de bar
    cashier/   # pago, corte de caja
    inventory/ # modelos de inventario
    kitchen/   # órdenes de cocina
    waiter/    # órdenes, mesas, pagos
```

Informe completo del refactor: [REFACTOR-REPORT.md](REFACTOR-REPORT.md)
