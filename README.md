<p align="center">
  <img src="./assets/images/logo_dulce_hogar.png" alt="Dulce Hogar Logo" width="220"/>
</p>
# Dulce Hogar - Aplicación Móvil

## Descripción del proyecto

Dulce Hogar es una aplicación móvil orientada a la venta de electrodomésticos para el hogar. La aplicación permite a los usuarios explorar productos, consultar información detallada, gestionar favoritos, agregar productos al carrito de compras, realizar pedidos y acceder a funcionalidades relacionadas con la experiencia de compra.

Este proyecto hace parte del sistema Dulce Hogar, el cual está compuesto por una aplicación móvil para clientes, un panel administrativo web y un backend encargado de gestionar la información, autenticación, productos, pedidos y demás procesos del sistema.

## Integrantes del proyecto

- Victor Manuel Tabares Toro
- Jean Michael Buitrago Henao
- Luis Mateo Muñoz Jaramillo
- Diego Alejandro Espinosa
  
## Objetivo de la aplicación

Brindar a los usuarios una plataforma móvil sencilla, intuitiva y funcional para consultar y comprar electrodomésticos, facilitando el acceso a productos del hogar desde dispositivos móviles.

## Tecnologías utilizadas

- Flutter / Dart
- Supabase
- Node.js / Express
- API REST
- Android Studio
- Git y GitHub

## Funcionalidades principales

La aplicación móvil de Dulce Hogar incluye las siguientes funcionalidades:

- Registro de usuarios
- Inicio de sesión
- Recuperación o cambio de contraseña
- Visualización de productos
- Consulta de detalles del producto
- Visualización de imágenes del producto
- Gestión de productos favoritos
- Agregar productos al carrito
- Eliminar productos del carrito
- Actualizar cantidades del carrito
- Visualizar resumen de compra
- Aplicación de descuentos o promociones
- Realización de pedidos
- Consulta del estado del pedido
- Descarga o visualización de factura del pedido
- Gestión básica del perfil de usuario
- Cierre de sesión

## Estructura general del proyecto

```
Dulce_Hogar_Movil/
│
├── assets/
│   ├── fonts/                  # Nunito (Regular, SemiBold, Bold)
│   └── images/                 # Logo y recursos gráficos
│
├── backend/                    # API REST Node.js + Express
│   ├── src/
│   │   ├── config/
│   │   │   ├── db.js           # Conexión a base de datos
│   │   │   ├── server.js       # Configuración del servidor
│   │   │   └── supabase.js     # Cliente Supabase (service role)
│   │   ├── controller/
│   │   │   ├── authController.js
│   │   │   └── authMiddleware.js
│   │   └── routes/
│   │       ├── authRoutes.js
│   │       ├── carritoRoutes.js
│   │       ├── categoriaRoutes.js
│   │       ├── direccionRoutes.js
│   │       ├── favoritosRoutes.js
│   │       ├── marcasRoutes.js
│   │       ├── mercadopagoRoutes.js
│   │       ├── misPedidosRoutes.js
│   │       ├── pedidoRoutes.js
│   │       ├── productoRoutes.js
│   │       ├── promocionesRoutes.js
│   │       ├── resenasRoutes.js
│   │       ├── router.js
│   │       ├── soporteRoutes.js
│   │       └── usuarioRoutes.js
│   ├── .env                    # Variables de entorno (no subir a Git)
│   └── package.json
│
├── lib/                        # Código fuente Flutter
│   ├── config/
│   │   └── api_config.dart     # URLs de la API REST
│   ├── models/
│   │   ├── api_models.dart
│   │   ├── models.dart
│   │   ├── order_models.dart
│   │   └── product_model.dart
│   ├── screens/
│   │   ├── cart_screen.dart
│   │   ├── favorites_screen.dart
│   │   ├── home_screen.dart
│   │   ├── login_screen.dart
│   │   ├── orders_screen.dart
│   │   ├── payment_screen.dart
│   │   ├── perfil_screen.dart
│   │   ├── product_detail_screen.dart
│   │   ├── recuperar_contrasena_screen.dart
│   │   ├── register_screen.dart
│   │   └── support_screen.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── cart_service.dart
│   │   ├── favorites_service.dart
│   │   ├── mercadopago_service.dart
│   │   ├── order_service.dart
│   │   ├── product_service.dart
│   │   └── support_service.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── utils/
│   │   ├── constants.dart      # URLs y constantes globales
│   │   └── formatters.dart
│   ├── widgets/
│   │   └── app_widgets.dart
│   └── main.dart
│
├── pubspec.yaml                # Dependencias Flutter
└── README.md
```

---

## 🛠️ Manual de Instalación y Configuración

### Prerrequisitos del sistema

Antes de comenzar, asegúrate de tener instaladas las siguientes herramientas en tu equipo:

| Herramienta | Versión mínima | Descarga |
|---|---|---|
| Flutter SDK | ≥ 3.0.0 | https://flutter.dev/docs/get-started/install |
| Dart SDK | Incluido con Flutter | — |
| Node.js | ≥ 18.x LTS | https://nodejs.org |
| npm | ≥ 9.x (incluido con Node.js) | — |
| Android Studio | Hedgehog o superior | https://developer.android.com/studio |
| Git | Cualquier versión reciente | https://git-scm.com |
| ngrok | Cualquier versión reciente | https://ngrok.com/download |

**Cuenta requerida:** Supabase (gratuita en https://supabase.com)

**Verificar instalaciones:**
```bash
flutter --version
node --version
npm --version
git --version
```

---

### Paso 1 — Obtener el código fuente

**Opción A: clonar desde Git**
```bash
git clone <URL-del-repositorio>
cd Dulce_Hogar_Movil
```

**Opción B: desde el archivo .zip entregado**
```
1. Descomprimir Dulce_Hogar_Movil.zip
2. Entrar a la carpeta descomprimida:
   cd Dulce_Hogar_Movil
```

---

### Paso 2 — Configurar Supabase

1. Inicia sesión en https://supabase.com y crea un nuevo proyecto.
2. Una vez creado, ve a **Project Settings → API**.
3. Anota los siguientes valores (los necesitarás más adelante):
   - **Project URL** → `https://xxxxxxxxxxxx.supabase.co`
   - **service_role key** (sección *Project API keys*) → solo para el backend
   - **anon public key** → para el cliente Flutter
4. Ve a **SQL Editor** y ejecuta los scripts de creación de tablas del proyecto (usuarios, productos, carrito, pedidos, favoritos, reseñas, etc.).
5. En **Storage**, crea los buckets necesarios para imágenes de productos si el proyecto los requiere.

> ⚠️ La `service_role key` tiene permisos administrativos completos. Úsala **únicamente** en el backend (archivo `.env`). Nunca la expongas en el código Flutter.

---

### Paso 3 — Configurar y ejecutar el Backend (Node.js / Express)

```bash
cd backend
```

#### 3.1 Instalar dependencias

```bash
npm install
```

Esto instalará todos los paquetes definidos en `package.json`, incluyendo: Express, Supabase JS, JWT, bcryptjs, MercadoPago SDK, Brevo, entre otros.

#### 3.2 Crear el archivo de variables de entorno

Crea el archivo `.env` dentro de la carpeta `backend/` con el siguiente contenido:

```env
# Puerto del servidor Express
PORT=3000

# Supabase (solo para el backend)
SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co
SUPABASE_SERVICE_ROLE=tu_service_role_key_aqui

# Autenticación JWT
JWT_SECRET=un_secreto_largo_y_aleatorio_aqui

# MercadoPago (pagos)
MP_ACCESS_TOKEN=tu_access_token_de_mercadopago

# Brevo (correo transaccional)
BREVO_API_KEY=tu_api_key_de_brevo

# CORS - URL del cliente (ngrok o IP local de Flutter)
CLIENT_URL=http://localhost
```

> ⚠️ El archivo `.env` está incluido en `.gitignore`. **Nunca** lo subas a un repositorio público.

#### 3.3 Iniciar el servidor

```bash
# Modo desarrollo (recarga automática con nodemon)
npm run dev

# Modo producción
npm start
```

Si la configuración es correcta, verás en la consola:
```
🚀 Servidor corriendo en el puerto 3000
```

#### 3.4 Exponer el backend con ngrok

La aplicación Flutter (en emulador o dispositivo físico) necesita acceder al backend a través de una URL pública. Usa **ngrok** para crear un túnel:

```bash
# En una terminal aparte, con el backend ya corriendo
ngrok http 3000
```

Ngrok mostrará una URL similar a:
```
Forwarding  https://abc123xyz.ngrok-free.app -> http://localhost:3000
```

Copia esa URL (la que empieza con `https://`). La usarás en el siguiente paso.

> ⚠️ Cada vez que reinicies ngrok, se genera una URL diferente. Deberás actualizar `api_config.dart` y `constants.dart` con la nueva URL.

---

### Paso 4 — Configurar la aplicación Flutter

#### 4.1 Actualizar la URL base de la API

Abre `lib/config/api_config.dart` y reemplaza el valor de `baseUrl` con la URL de tu ngrok:

```dart
// lib/config/api_config.dart
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://TU-URL-NGROK.ngrok-free.app/api';

  // El resto de endpoints se construyen automáticamente a partir de baseUrl
  // ...
}
```

Haz el mismo cambio en `lib/utils/constants.dart`:

```dart
// lib/utils/constants.dart
class AppConstants {
  AppConstants._();

  static const String baseUrl = 'https://TU-URL-NGROK.ngrok-free.app/api';
  // ...
}
```

#### 4.2 Configurar Supabase en Flutter

Abre `lib/main.dart` y verifica que las credenciales de Supabase estén configuradas correctamente:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xxxxxxxxxxxx.supabase.co',  // tu Project URL
    anonKey: 'tu_anon_public_key',            // tu anon key (NO la service_role)
  );

  runApp(const MyApp());
}
```

#### 4.3 Instalar dependencias Flutter

Desde la raíz del proyecto (donde está `pubspec.yaml`):

```bash
flutter pub get
```

Las dependencias principales que se instalarán son:

| Paquete | Uso |
|---|---|
| `supabase_flutter` | Autenticación y cliente Supabase |
| `http` | Peticiones HTTP a la API REST |
| `shared_preferences` | Almacenamiento local (sesión) |
| `flutter_secure_storage` | Almacenamiento seguro del token JWT |
| `flutter_local_notifications` | Notificaciones locales |
| `url_launcher` | Abrir URLs (pasarela de pago) |
| `cached_network_image` | Caché de imágenes de productos |
| `google_fonts` | Tipografías adicionales |

---

### Paso 5 — Ejecutar la aplicación Flutter

#### 5.1 Verificar dispositivos disponibles

```bash
flutter devices
```

Deberías ver al menos un emulador Android (desde Android Studio) o un dispositivo físico conectado.

#### 5.2 Preparar un emulador Android (si no tienes uno)

1. Abre **Android Studio**.
2. Ve a **Tools → Device Manager → Create Device**.
3. Selecciona un dispositivo (recomendado: Pixel 6) con Android API 33 o superior.
4. Descarga la imagen del sistema si se solicita e inicia el emulador.

#### 5.3 Ejecutar la aplicación

```bash
# Ejecutar en el dispositivo/emulador detectado automáticamente
flutter run

# Ejecutar en un dispositivo específico (usar el ID de flutter devices)
flutter run -d emulator-5554

# Modo release para mejor rendimiento
flutter run --release
```

#### 5.4 Compilar APK (para distribución)

```bash
# APK de depuración
flutter build apk --debug

# APK de release (requiere keystore para firma)
flutter build apk --release
```

El archivo APK se genera en:
```
build/app/outputs/flutter-apk/app-release.apk
```

> Para instalar en un dispositivo físico, activa **Opciones de desarrollador → Depuración USB** en el teléfono y acepta el permiso de conexión cuando aparezca.

---

### Paso 6 — Configurar MercadoPago (pagos en línea)

1. Crea una cuenta en https://www.mercadopago.com.co.
2. Ve a **Tu negocio → Configuración → Credenciales**.
3. En el modo **Prueba (sandbox)**, copia el **Access Token** de prueba.
4. Agrégalo a tu `.env`:
   ```env
   MP_ACCESS_TOKEN=TEST-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
5. Para producción, repite el proceso con las credenciales del modo **Producción** y asegúrate de haber completado la verificación de identidad en MercadoPago.

**Cuentas de prueba:** MercadoPago permite crear cuentas de prueba (comprador y vendedor) desde el panel de desarrolladores para simular transacciones sin dinero real.

---

### Paso 7 — Configurar Brevo (correos transaccionales)

Brevo gestiona el envío de correos de recuperación de contraseña y confirmaciones de pedido.

1. Crea una cuenta en https://www.brevo.com (plan gratuito disponible).
2. Ve a **SMTP & API → API Keys → Generar nueva clave**.
3. Copia la clave generada y agrégala a tu `.env`:
   ```env
   BREVO_API_KEY=xkeysib-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
4. En Brevo, verifica el dominio o correo remitente desde el cual se enviarán los mensajes (**Senders & IPs → Domains**).

---

### Resumen de configuración rápida

| Archivo | Qué configurar |
|---|---|
| `backend/.env` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE`, `JWT_SECRET`, `MP_ACCESS_TOKEN`, `BREVO_API_KEY` |
| `lib/config/api_config.dart` | `baseUrl` con la URL de ngrok |
| `lib/utils/constants.dart` | `baseUrl` con la URL de ngrok |
| `lib/main.dart` | `url` y `anonKey` de Supabase |

---


### Solución de problemas frecuentes

| Problema | Causa probable | Solución |
|---|---|---|
| `Connection refused` en Flutter | El backend no está corriendo | Ejecutar `npm run dev` en la carpeta `backend/` |
| `SocketException` o error de red | URL base incorrecta o ngrok no activo | Revisar `api_config.dart`, reiniciar ngrok y actualizar la URL |
| Pantalla en blanco al iniciar | URL de ngrok expirada | Reiniciar ngrok, copiar la nueva URL y actualizar `baseUrl` |
| `JWT malformed` o `Unauthorized` | Token JWT expirado o inválido | Cerrar sesión y volver a autenticarse |
| `Supabase auth error` | Credenciales incorrectas | Verificar `SUPABASE_URL` y las claves en `main.dart` y `.env` |
| `flutter pub get` falla | SDK de Flutter desactualizado | Ejecutar `flutter upgrade` y repetir `flutter pub get` |
| APK no instala en dispositivo | Depuración USB no activada | Activar **Opciones de desarrollador → Depuración USB** en el teléfono |
| Error de CORS en el backend | `CLIENT_URL` mal configurado | Actualizar `CLIENT_URL` en `.env` con la URL del cliente |
| `MercadoPago` no procesa pago | Access Token de prueba incorrecto | Verificar que `MP_ACCESS_TOKEN` corresponde al modo sandbox |
