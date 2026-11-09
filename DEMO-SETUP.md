# Cómo correr la demo de Sistema EVE

Todo con datos ficticios. Nada de esto toca el Firebase de producción
ni los datos del negocio real.

## 1. Proyecto Firebase demo (nuevo, vacío)

1. En Firebase Console crea un proyecto nuevo, por ejemplo `sistema-eve-demo`.
2. Activa Auth (correo/contraseña), Firestore y Storage.
3. Instala FlutterFire CLI y genera la config:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure --project=sistema-eve-demo
   ```
   Eso crea `lib/firebase_options.dart` y `android/app/google-services.json`.
   Esos dos archivos **nunca** se suben a GitHub (están en `.gitignore`).
4. Despliega las reglas e índices que trae el repo:
   ```
   firebase deploy --only firestore:rules,firestore:indexes
   ```
   Incluye la regla de la colección `counters` (contador de órdenes del día).

## 2. Datos de ejemplo (ficticios)

Crea en Firestore, a mano o desde Admin en la app:

- **Usuarios demo** (Auth, correo/contraseña, uno por rol):
  admin@demo.local, mesero@demo.local, cocina@demo.local,
  bar@demo.local, caja@demo.local (contraseñas a tu elección).
- **Menú** (colección `menu_items`, precios ficticios en MXN):
  Hamburguesa Clásica 85, Hamburguesa Doble 120, Papas Fritas 45,
  Refresco 30, Agua 20, Hot Dog 60, Alitas 6 pzas 95, Nachos 70.
- **Mesas** (`tables`): Mesa 1 a Mesa 8, más "Para llevar".
- **Inventario** (`inventory_items`): Pan, Carne, Queso, Papas, Refresco,
  con stock inicial, por ejemplo 100 unidades cada uno.
- **Una orden de ejemplo en cada estado:** una pendiente, una en
  preparación, una lista y una pagada, para mostrar el flujo completo
  en entrevista sin tener que crearlas en vivo.

## 3. Correr

```
flutter pub get
flutter analyze
flutter test
flutter run
```

## 4. Flujo para mostrar en entrevista (2-3 minutos)

1. Mesero crea una orden en una mesa.
2. Cocina/Bar la marcan como lista.
3. Caja confirma el pago y el stock baja una sola vez.
4. Admin abre Reportes y exporta PDF y CSV.

## Seguridad

- La cuenta de prueba que venía en `FIRESTORE_INDEX_SETUP.md` fue
  quitada. Si esa cuenta existe en tu Firebase de producción,
  desactívala o cambia su contraseña: era una contraseña débil y
  estaba escrita en el repo.
- El `google-services.json` y `firebase_options.dart` de producción
  fueron eliminados de esta copia. No los vuelvas a copiar aquí.
