# Dulce Hogar - Aplicación Móvil

## Descripción del proyecto

Dulce Hogar es una aplicación móvil orientada a la venta de electrodomésticos para el hogar. La aplicación permite a los usuarios explorar productos, consultar información detallada, gestionar favoritos, agregar productos al carrito de compras, realizar pedidos y acceder a funcionalidades relacionadas con la experiencia de compra.

Este proyecto hace parte del sistema Dulce Hogar, el cual está compuesto por una aplicación móvil para clientes, un panel administrativo web y un backend encargado de gestionar la información, autenticación, productos, pedidos y demás procesos del sistema.

## Objetivo de la aplicación

Brindar a los usuarios una plataforma móvil sencilla, intuitiva y funcional para consultar y comprar electrodomésticos, facilitando el acceso a productos del hogar desde dispositivos móviles.

## Tecnologías utilizadas

- Flutter
- Dart
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

La estructura del proyecto puede variar según la organización final del equipo, pero de manera general se maneja una estructura similar a la siguiente:

```bash
lib/
│
├── main.dart
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── product_detail_screen.dart
│   ├── cart_screen.dart
│   ├── favorites_screen.dart
│   ├── orders_screen.dart
│   └── profile_screen.dart
│
├── services/
│   ├── auth_service.dart
│   ├── product_service.dart
│   ├── cart_service.dart
│   ├── order_service.dart
│   └── notification_service.dart
│
├── models/
│   ├── product_model.dart
│   ├── user_model.dart
│   ├── cart_model.dart
│   └── order_model.dart
│
├── widgets/
│   ├── product_card.dart
│   ├── custom_button.dart
│   ├── custom_input.dart
│   └── loading_widget.dart
│
└── utils/
    ├── constants.dart
    └── helpers.dart
