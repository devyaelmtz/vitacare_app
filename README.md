# vitacare_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Flujo de registro VitaCare

- **Crear cuenta** abre `RegistroUsuarioPage` y envía los siete campos editables a
  `POST /api/users`; el servidor genera `id`. Solo se crea una fila en `users`.
  El registro público admite roles `PACIENTE` y `CUIDADOR`; no concede el rol `ADMIN`.
- Un administrador existente inicia sesión para abrir el dashboard. El botón
  **Registrar Paciente / Cuidador** abre el módulo avanzado. `POST /api/pacientes`
  y `POST /api/cuidadores` guardan cuenta y perfil en una transacción PostgreSQL.
- `POST /api/login` devuelve `token`, utilizado como `Authorization: Bearer <token>`
  para altas avanzadas y modificaciones/eliminaciones de usuarios. Las sesiones
  duran ocho horas, se conservan en memoria y requieren otro login al reiniciar
  el backend. El servidor verifica el rol actual en la base de datos.
- El dashboard carga exclusivamente `GET /api/users`, sin usuarios de ejemplo.
  Las cuentas sin rol administrativo ya no abren el módulo de registro avanzado.

Con PostgreSQL configurado según `backend-vitacare/server.js` y `schema.sql` cargado:

```sh
cd backend-vitacare
npm ci
node server.js
# En otra terminal: pruebas de integración con datos temporales que se eliminan
node --test test/registros.test.js
```

Desde la raíz, con Flutter instalado: `flutter pub get`, `flutter test` y
`flutter build web`. Se conservan las direcciones locales existentes para web y
el emulador Android.
