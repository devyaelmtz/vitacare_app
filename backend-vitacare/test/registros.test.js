// Requiere PostgreSQL local con schema.sql cargado. Ejecutar: node --test test/registros.test.js
const { test } = require('node:test')
const assert = require('node:assert/strict')
const { randomUUID } = require('node:crypto')
const { app, pool } = require('../server')

test('registro público y perfiles exclusivos del administrador', async t => {
    const server = app.listen(0, '127.0.0.1')
    await new Promise(resolve => server.once('listening', resolve))
    const base = `http://127.0.0.1:${server.address().port}`
    const prefix = randomUUID()
    const makeUser = suffix => ({ email: `${prefix}-${suffix}@example.invalid`,
        password: randomUUID(), nombre: 'Prueba', app: 'Registro', apm: 'Local',
        telefono: '5550000000', rol: 'PACIENTE' })
    const request = async (path, body, token) => {
        const r = await fetch(base + path, { method: body ? 'POST' : 'GET',
            headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
            ...(body ? { body: JSON.stringify(body) } : {}) })
        return { status: r.status, body: await r.json() }
    }
    try {
        const publicUser = makeUser('publico')
        let publicId, adminToken
        await t.test('público crea solo users, ignora campos de perfil y no expone contraseña', async () => {
            const r = await request('/api/users', { ...publicUser, fechaNac: '2000-01-01' })
            assert.equal(r.status, 201)
            publicId = r.body.user.id
            assert.equal(r.body.user.password, undefined)
            for (const table of ['pacientes', 'cuidadores']) {
                assert.equal((await pool.query(`SELECT * FROM ${table} WHERE usuario_id=$1`, [publicId])).rowCount, 0)
            }
            const list = await request('/api/users')
            assert.equal(list.status, 200)
            assert.ok(list.body.some(u => u.id === publicId))
            assert.ok(list.body.every(u => u.password === undefined))
        })
        await t.test('rechaza campos incompletos, duplicados y autoasignación ADMIN', async () => {
            assert.equal((await request('/api/users', { ...makeUser('admin-publico'), rol: 'ADMIN' })).status, 400)
            assert.equal((await request('/api/users', { ...makeUser('incompleto'), nombre: '' })).status, 400)
            assert.equal((await request('/api/users', publicUser)).status, 409)
        })
        await t.test('rechaza perfiles sin sesión y con sesión de paciente', async () => {
            const login = await request('/api/login', publicUser)
            assert.equal(login.status, 200)
            for (const path of ['/api/pacientes', '/api/cuidadores']) {
                assert.equal((await request(path, makeUser('sin-sesion'))).status, 401)
                assert.equal((await request(path, makeUser('sin-rol'), login.body.token)).status, 403)
            }
        })
        const admin = makeUser('admin')
        await pool.query(`INSERT INTO users (id,email,password,nombre,app,apm,telefono,rol)
            VALUES ($1,$2,$3,$4,$5,$6,$7,'ADMIN')`,
            [Date.now() + 10000000, admin.email, admin.password, admin.nombre, admin.app, admin.apm, admin.telefono])
        adminToken = (await request('/api/login', admin)).body.token
        await t.test('administrador crea cuenta y perfil de paciente/cuidador', async () => {
            const patient = await request('/api/pacientes', { ...makeUser('paciente'),
                fechaNac: '2000-01-01', contactoEmergencia: 'Contacto', telefonoEmergencia: '5551111111' }, adminToken)
            assert.equal(patient.status, 201)
            assert.equal((await pool.query('SELECT * FROM pacientes WHERE usuario_id=$1', [patient.body.user.id])).rowCount, 1)
            const carer = await request('/api/cuidadores', { ...makeUser('cuidador'), numeroLicencia: 'L123', parentescoRelacion: 'Familiar' }, adminToken)
            assert.equal(carer.status, 201)
            assert.equal(carer.body.user.rol, 'CUIDADOR')
            const profile = (await pool.query('SELECT * FROM cuidadores WHERE usuario_id=$1', [carer.body.user.id])).rows[0]
            assert.equal(profile.numero_licencia, 'L123')
        })
        await t.test('fallo de perfil revierte users y permite la siguiente alta', async () => {
            const user = makeUser('rollback')
            const r = await request('/api/pacientes', { ...user, fechaNac: 'fecha-invalida', contactoEmergencia: 'Contacto', telefonoEmergencia: '5551111111' }, adminToken)
            assert.equal(r.status, 400)
            assert.equal((await pool.query('SELECT id FROM users WHERE email=$1', [user.email])).rowCount, 0)
            assert.equal((await request('/api/cuidadores', user, adminToken)).status, 201)
        })
    } finally {
        await pool.query('DELETE FROM users WHERE email LIKE $1', [`${prefix}-%@example.invalid`])
        await new Promise(resolve => server.close(resolve))
        await pool.end()
    }
})
