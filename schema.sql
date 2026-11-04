CREATE TYPE user_role AS ENUM ('ADMIN', 'PACIENTE', 'CUIDADOR', 'PENDIENTE');

CREATE TABLE users (
	id BIGSERIAL PRIMARY KEY,
	email VARCHAR(255) NOT NULL UNIQUE,
	password VARCHAR(255) NOT NULL,
	nombre VARCHAR(100) NOT NULL,
	app VARCHAR(100) NOT NULL,
	apm VARCHAR(100) NOT NULL,
	telefono VARCHAR(20) NOT NULL,
	rol user_role NOT NULL DEFAULT 'PENDIENTE',
	created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE pacientes (
	usuario_id BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
	fecha_nac DATE NOT NULL,
	contacto_emergencia VARCHAR(100) NOT NULL,
	telefono_emergencia VARCHAR(20) NOT NULL
);

CREATE TABLE cuidadores (
	usuario_id BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
	numero_licencia VARCHAR(50),
	parentesco_relacion VARCHAR(50)
);

CREATE TABLE paciente_cuidador (
	paciente_id BIGINT REFERENCES pacientes(usuario_id) ON DELETE CASCADE,
	cuidador_id BIGINT REFERENCES cuidadores(usuario_id) ON DELETE CASCADE,
	fecha_vinculacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (paciente_id, cuidador_id)
);