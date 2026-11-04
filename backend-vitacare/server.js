const express = require('express') //Establecer servicios de API REST y conexión a base de datos | Node.js
const { Pool } = require('pg') //Crear la ruta para la  y grupo de conexiones: Postgres
// const multer = require('multer') //Procesar datos/archivos sensibles (usuario, contraseña, correo, imágenes, etc)
const { randomUUID } = require('node:crypto')
const path = require('path') //Ruta del modulo nativo de node.js
const cors = require('cors') //Leer formatos de json | Hacer conexión de dos servidores locales para entrar a la aplicación

//Configuración de elementos
const app = express()
app.use(cors())
app.use(express.json())
// app.use('uploads', express.static
//     (path.join(__dirname, 'uploads')))

//Conexión a la BD
const pool = new Pool({
    user: 'postgres',
    host: 'localhost',
    database: 'vitacare',
    password: 'root',
    port: 5432,
})

//Tomar el archivo (app, bd, cámara) y guardarlo
/*
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/')
    },
    filename: (req, file, cb) => {
        cb(null, Date.now() +
        path.extname (file.originalname))
    }
})
const upload = multer({ storage: storage })
*/

// async : manejo asíncrono
// await : pausa la ejecución de la función dentro de un bloque async
app.get('/api/users', async (req, res) => {
    try {
        const resultado =
            await
                pool.query(`SELECT id, email, nombre, app, apm, telefono, rol, created_at FROM users
            ORDER BY id DESC`)
        res.json(resultado.rows)
    } catch (error) {
        console.error(error)
        res.status(500).json( //500 Error de syntaxis o conexión
            { error: 'Error al obtener los usuarios' })
    }
})

const sessions = new Map()
const baseFields = ['email', 'password', 'nombre', 'app', 'apm', 'telefono']
const validBase = body => body && typeof body === 'object' && baseFields.every(field =>
    typeof body[field] === 'string' && body[field].trim().length > 0)

async function requireAdmin(req, res, next) {
    try {
        const token = req.headers.authorization?.replace(/^Bearer /, '')
        const session = sessions.get(token)
        if (!session || session.expires <= Date.now()) {
            if (token) sessions.delete(token)
            return res.status(401).json({ error: 'Inicia sesión como administrador' })
        }
        const result = await pool.query('SELECT rol FROM users WHERE id = $1', [session.id])
        if (result.rows[0]?.rol !== 'ADMIN') {
            return res.status(403).json({ error: 'Acceso exclusivo del administrador' })
        }
        next()
    } catch (error) {
        console.error(error)
        res.status(500).json({ error: 'Error al verificar permisos' })
    }
}

const insertUser = `INSERT INTO users
    (email, password, nombre, app, apm, telefono, rol)
    VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`
const userValues = (body, rol) => [...baseFields.map(field =>
    field === 'password' ? body[field] : body[field].trim()), rol]
function registrationError(res, error) {
    if (error.code === '23505') return res.status(409).json({ error: 'El correo ya está registrado' })
    if (['22007', '22008', '22001', '22003', '22P02', '23502'].includes(error.code)) {
        return res.status(400).json({ error: 'Revisa los datos del registro' })
    }
    console.error(error)
    res.status(500).json({ error: 'Error al registrar la cuenta' })
}

// Registro público: crea exclusivamente la cuenta base, nunca perfiles ni administradores.
app.post('/api/users', async (req, res) => {
    try {
        if (!validBase(req.body)) {
            return res.status(400).json({ error: 'Completa los datos de la cuenta' })
        }
        const result = await pool.query(insertUser, userValues(req.body, 'PENDIENTE'))
        const { password, ...user } = result.rows[0]
        res.status(201).json({ status: 'success', user })
    } catch (error) {
        registrationError(res, error)
    }
})

// Una única conexión actualiza el rol y vincula el perfil al usuario existente.
for (const tipo of ['pacientes', 'cuidadores']) {
    app.post(`/api/${tipo}`, requireAdmin, async (req, res) => {
        let client
        try {
            const body = req.body
            if (!body || !/^[1-9][0-9]*$/.test(String(body.usuario_id ?? '')) ||
                (tipo === 'pacientes' &&
                !['fechaNac', 'contactoEmergencia', 'telefonoEmergencia'].every(
                    field => typeof body[field] === 'string' && body[field].trim()))) {
                return res.status(400).json({ error: 'Completa todos los campos obligatorios' })
            }
            client = await pool.connect()
            await client.query('BEGIN')
            const result = await client.query(`UPDATE users SET rol = $1 WHERE id = $2
                RETURNING id, email, nombre, app, apm, telefono, rol`,
                [tipo === 'pacientes' ? 'PACIENTE' : 'CUIDADOR', body.usuario_id])
            if (!result.rowCount) {
                await client.query('ROLLBACK')
                return res.status(404).json({ error: 'Usuario no encontrado' })
            }
            const user = result.rows[0]
            if (tipo === 'pacientes') {
                await client.query(`INSERT INTO pacientes
                    (usuario_id, fecha_nac, contacto_emergencia, telefono_emergencia)
                    VALUES ($1, $2, $3, $4)`,
                    [user.id, body.fechaNac, body.contactoEmergencia, body.telefonoEmergencia])
            } else {
                await client.query(`INSERT INTO cuidadores
                    (usuario_id, numero_licencia, parentesco_relacion) VALUES ($1, $2, $3)`,
                    [user.id, body.numeroLicencia || null, body.parentescoRelacion || null])
            }
            await client.query('COMMIT')
            res.status(201).json({ status: 'success', user })
        } catch (error) {
            if (client) await client.query('ROLLBACK')
            if (error.code === '23505') {
                return res.status(409).json({ error: 'Este usuario ya tiene un perfil de este tipo' })
            }
            registrationError(res, error)
        } finally {
            if (client) client.release()
        }
    })
}

// 3. Modificar un usuario (PUT)
app.put('/api/users/:id', requireAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        const { email, password, nombre, app, apm, telefono, rol } = req.body;

        const query = `
            UPDATE users 
            SET email = $1, password = $2, nombre = $3, app = $4, apm = $5, telefono = $6, rol = $7 
            WHERE id = $8 RETURNING *;
        `;
        const values = [email, password, nombre, app, apm, telefono, rol, id];

        const resultado = await pool.query(query, values);

        if (resultado.rows.length === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        res.json({ status: 'success', user: resultado.rows[0] });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: err.message });
    }
});

// 4. Eliminar un usuario (DELETE)
app.delete('/api/users/:id', requireAdmin, async (req, res) => {
    try {
        const { id } = req.params;
        const resultado = await pool.query('DELETE FROM users WHERE id = $1 RETURNING *;', [id]);

        if (resultado.rows.length === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        res.json({
            status: 'success',
            message: 'Usuario eliminado de la base de datos'
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// RUTA DE AUTENTICACIÓN (LOGIN)
app.post('/api/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                status: 'error',
                message: 'Todos los campos son obligatorios'
            });
        }

        // SE AGREGÓ "nombre" EN EL SELECT
        const query = `
            SELECT id, email, nombre, rol 
            FROM users 
            WHERE email = $1 AND password = $2;
        `;

        const resultado = await pool.query(query, [email, password]);

        if (resultado.rows.length > 0) {
            const usuarioEncontrado = resultado.rows[0];
            const token = randomUUID();
            for (const [key, session] of sessions) {
                if (session.expires <= Date.now()) sessions.delete(key);
            }
            sessions.set(token, { id: usuarioEncontrado.id, expires: Date.now() + 8 * 60 * 60 * 1000 });
            return res.status(200).json({
                status: 'success',
                message: 'Autenticación exitosa',
                token,
                usuario: {
                    id: usuarioEncontrado.id,
                    email: usuarioEncontrado.email,
                    nombre: usuarioEncontrado.nombre, // SE AGREGÓ EL NOMBRE AL JSON DE RESPUESTA
                    rol: usuarioEncontrado.rol
                }
            });
        } else {
            return res.status(401).json({
                status: 'error',
                message: 'Correo o contraseña incorrectos',
            });
        }
    } catch (err) {
        console.error(err);
        return res.status(500).json({
            status: 'error',
            message: 'Error interno del servidor en PostgreSQL'
        });
    }
});

// CRUD PARA USUARIOS
// 1. Obtener un solo usuario por ID (GET)
app.get('/api/users/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const query = `
            SELECT id, email, nombre, app, apm, telefono, rol, created_at 
            FROM users 
            WHERE id = $1;
        `;
        const resultado = await pool.query(query, [id]);

        if (resultado.rows.length === 0) {
            return res.status(404).json({ error: 'Usuario no encontrado' });
        }

        res.json(resultado.rows[0]);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error al obtener el usuario' });
    }
});
if (require.main === module) {
    const PORT = 3000
    app.listen(PORT, () => console.log(`Servidor de usuarios en puerto ${PORT}`))
}
module.exports = { app, pool }
