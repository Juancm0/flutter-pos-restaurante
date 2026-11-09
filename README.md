# Sistema EVE

Aplicación Android de punto de venta para restaurantes y negocios de
comida rápida, desarrollada en Flutter con Firebase. La uso todos los
días en un negocio real con alrededor de 100 clientes al día, con
órdenes sincronizadas en tiempo real entre meseros, cocina, bar y caja.

## Qué hace

- **Meseros:** creo órdenes por mesa o para llevar, con modificadores
  y notas por producto.
- **Cocina / Bar:** cada sección ve solo sus órdenes y marca los
  platillos listos.
- **Caja:** confirmo el pago, hago el corte de caja y exporto reportes.
- **Administración:** gestiono menú, inventario, mesas, usuarios y
  reportes con exportación a PDF y CSV.

El inventario se descuenta una sola vez por orden, al confirmar el
pago, y cada movimiento queda registrado. Las órdenes se crean de
forma atómica, así que dos meseros pueden trabajar a la vez sin
duplicar números ni sobrescribir el stock. Cancelar una orden la deja
en el historial como cancelada y restaura el stock cuando corresponde.

## Stack

Flutter, Dart, Riverpod, Firebase (Auth, Cloud Firestore, Storage y
Analytics), Clean Architecture por features.

## Instalación

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

### Configuración de Firebase

Necesitas tu propio proyecto Firebase:

1. Crea un proyecto en Firebase Console y activa Auth
   (correo/contraseña), Cloud Firestore y Storage.
2. Genera la configuración con FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Esto crea `lib/firebase_options.dart` y
   `android/app/google-services.json`. Esos archivos no se suben al
   repositorio (están en `.gitignore`).
3. Despliega las reglas y los índices incluidos:
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes
   ```

### Datos de ejemplo

Para probar la app, crea en Firestore:

- **Usuarios** (uno por rol): admin, mesero, cocina, bar y caja.
- **Menú** (`menu_items`): por ejemplo, Hamburguesa Clásica 85,
  Hamburguesa Doble 120, Papas Fritas 45, Refresco 30, Agua 20,
  Hot Dog 60, Alitas 6 pzas 95, Nachos 70 (MXN).
- **Mesas** (`tables`): Mesa 1 a Mesa 8, más "Para llevar".
- **Inventario** (`inventory_items`): Pan, Carne, Queso, Papas y
  Refresco, con stock inicial de 100 unidades cada uno.

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

## Autor

Juan Carlos Martínez Mendoza — Desarrollador Flutter / Android.
GitHub: [Juancm0](https://github.com/Juancm0) · LinkedIn:
[juancm-mendoza](https://www.linkedin.com/in/juancm-mendoza)
