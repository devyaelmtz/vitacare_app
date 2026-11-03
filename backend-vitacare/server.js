const express = require('express') //Establecer servicios de API REST y conexión a base de datos | Node.js
const { Pool } = require('pg') //Crear la ruta para la  y grupo de conexiones: Postgres
// const multer = require('multer') //Procesar datos/archivos sensibles (usuario, contraseña, correo, imágenes, etc)
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
                pool.query(`SELECT * FROM users
            ORDER BY id DESC`)
        res.json(resultado.rows)
    } catch (error) {
        console.error(error)
        res.status(500).json( //500 Error de syntaxis o conexión
            { error: 'Error al obtener los usuarios' })
    }
})

app.post('/api/users', /*upload.single('imagen'),*/
    async (req, res) => {
        try {
            const { email, password, nombre, app, apm, telefono, rol }
                = req.body
            /*
            if (!req.file) {
                return
                res.status(400).json(
                    { error: 'La imagen es requerida' })
            }
    
            const host = req.headers.host
            const rutaImagen = `http://${host}/uploads/${req.file.filename}` //interpolacion ${variable}
            */

            const query = `
        INSERT INTO users
        (id, email, password, nombre, app, apm, telefono, rol)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *;
        `
            const values = [Date.now(), email, password, nombre, app, apm, telefono, rol]
            const resultado = await pool.query(query, values)

            res.status(201).json({
                status: 'success', // <-- Se corrigió 'succes' por 'success' aquí también para consistencia
                user: resultado.rows[0]
            })
        } catch (error) {
            console.error(error)
            res.status(500).json(
                { error: 'Error interno del servidor' })
        }
    })

const PORT = 3000
app.listen(PORT, () => { //función callback
    console.log(`Servidor de usuarios
        corriendo in http://localhost:${PORT}`)
})

// 3. Modificar un usuario (PUT)
app.put('/api/users/:id', async (req, res) => {
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
app.delete('/api/users/:id', async (req, res) => {
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
            return res.status(200).json({
                status: 'success',
                message: 'Autenticación exitosa',
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