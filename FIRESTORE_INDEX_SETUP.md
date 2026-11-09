# Instrucciones para Crear Índice de Firestore

## ¿Por qué necesito esto?

El módulo de Mesero utiliza queries en Firestore que filtran por tipo de orden (mesa o para llevar).

**Ambas queries usan EL MISMO índice compuesto:**

### Índice Necesario (createdBy + status + orderType + created)
- `createdBy` (ID del mesero)
- `status` (pending, preparing, ready)
- `orderType` (dineIn o takeout) ← Este campo diferencia entre mesas y para llevar
- `timestamps.created` (ordenado descendente)

**Este índice se usa para:**
- ✅ Tab "Mis Órdenes" → filtra por `orderType='dineIn'`
- ✅ Tab "Para Llevar" → filtra por `orderType='takeout'`

**SIN ESTE ÍNDICE, NINGUNA DE LAS DOS TABS FUNCIONARÁ.**

> **Nota:** En Firestore, los índices se diferencian por los campos que contienen, no por el nombre de la colección. Aunque ambas queries consultan "orders", usan el mismo índice compuesto porque filtran por los mismos campos.

---

## Métodos para Crear el Índice

### Método 1: Automático (Recomendado) ✅

1. **Ejecuta la aplicación** en tu dispositivo
2. **Inicia sesión como mesero** (demo@demo.local / (crear en tu proyecto Firebase demo))
3. **Ve al tab "Para Llevar"** o **"Mis Órdenes"**
4. **Intenta ver/crear una orden**
5. Firestore mostrará un error con un **link directo**
6. **Copia el link** del error (será algo como: `https://console.firebase.google.com/...`)
7. **Pégalo en tu navegador** y presiona Enter
8. Firebase Console abrirá con el índice pre-configurado
9. **Click en "Create Index"**
10. Espera 1-2 minutos mientras se construye
11. **Refresca la app** y ambas tabs deberían funcionar

---

### Método 2: Usar Firebase CLI (Más Rápido)

Si tienes Firebase CLI instalado:

```bash
# Navegar a la carpeta del proyecto
cd "<carpeta-del-proyecto>"

# Desplegar el índice
firebase deploy --only firestore:indexes
```

**Ventaja:** Crea el índice automáticamente.  
**Desventaja:** Requiere tener Firebase CLI instalado.

---

### Método 3: Crear Manualmente en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto "sistema-eve-demo"
3. En el menú lateral, ve a **Firestore Database** → **Indexes**
4. Click en **Create Index**

Configura:

**Collection ID:** `orders`

| Field                  | Order       |
|------------------------|-------------|
| `createdBy`            | Ascending   |
| `status`               | Ascending   |
| `orderType`            | Ascending   |
| `timestamps.created`   | Descending  |

**Query scope:** Collection

5. Click **Create**
6. Espera 1-2 minutos mientras se construye

**Este único índice sirve para ambas tabs (Mesas y Para Llevar).**

---

## Verificación

Una vez creado el índice:

### Tab "Mis Órdenes"
1. **Login como mesero**
2. Ve a **"Mis Órdenes"**
3. Crea una orden desde una mesa
4. Verifica que aparece en la lista

### Tab "Para Llevar"
1. Ve al tab **"Para Llevar"**
2. Click en **"Nueva"**
3. Crea una orden sin mesa
4. Verifica que aparece en "Para Llevar"
5. Verifica que NO aparece en "Mis Órdenes"

---

## Troubleshooting

### Error persiste después de crear el índice
- **Solución:** Cierra la app completamente y vuelve a abrirla
- El índice puede tomar hasta 5 minutos en construirse

### Las tabs no muestran órdenes
- **Verificar:** Que el índice esté creado (con `orderType`)
- **Verificar:** En Firebase Console → Indexes que el estado sea "Enabled"
- **Verificar:** Que la orden tenga el campo `orderType` correcto ('dineIn' o 'takeout')

### Firebase CLI no instalado
```bash
npm install -g firebase-tools
firebase login
firebase use sistema-eve-demo
```

---

## Estado del Índice en firestore.indexes.json

El archivo ya tiene configurado el índice necesario:

```json
{
  "indexes": [
    {
      "collectionGroup": "orders",
      "fields": [
        {"fieldPath": "createdBy", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "orderType", "order": "ASCENDING"},
        {"fieldPath": "timestamps.created", "order": "DESCENDING"}
      ]
    }
  ]
}
```

✅ **El índice está listo para desplegarse con `firebase deploy`**

---

## Notas Importantes

✅ **El índice solo necesita crearse UNA VEZ**  
✅ **Es seguro y no afecta datos existentes**  
✅ **Funciona automáticamente una vez creado**  
✅ **Un solo índice sirve para ambas tabs (Mesas y Para Llevar)**  
⚠️ **El index diferencia las órdenes por el valor de `orderType`**, no por tener índices separados

---

**Recomendación:** Usa el **Método 2 (Firebase CLI)** si lo tienes instalado, es más rápido y confiable.

---

## Troubleshooting

### Error persiste después de crear el índice
- **Solución:** Cierra la app completamente y vuelve a abrirla
- El índice puede tomar hasta 5 minutos en construirse para colecciones grandes

### No veo el link en el error
- **Solución:** Copia el mensaje de error completo y pégalo aquí
- Alternativamente, usa el Método 3 (manual)

### Firebase CLI no instalado
```bash
npm install -g firebase-tools
firebase login
firebase use sistema-eve-demo
```

---

## Notas Importantes

✅ **El índice solo necesita crearse UNA VEZ**  
✅ **Es seguro y no afecta datos existentes**  
✅ **Funciona automáticamente una vez  creado**  
⚠️ **NO elimines el archivo `firestore.indexes.json`** (permite regenerar el índice si es necesario)

---

**Siguiente paso:** Una vez creado el índice, prueba crear una orden nueva y verifica que aparezca en "Mis Órdenes".
