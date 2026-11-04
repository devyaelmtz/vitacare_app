// Requiere PostgreSQL local y schema.sql. Ejecutar: node --test test/registros.test.js
const { test } = require('node:test')
const assert = require('node:assert/strict')
const { randomUUID } = require('node:crypto')
const { app, pool } = require('../server')

test('cuentas públicas y clasificación administrativa de usuarios existentes', async t => {
    const server = app.listen(0, '127.0.0.1')
    await new Promise(resolve => server.once('listening', resolve))
    const prefix = randomUUID()
    const base = `http://127.0.0.1:${server.address().port}`
    const makeUser = suffix => ({ email: `${prefix}-${suffix}@example.invalid`, password: randomUUID(),
        nombre: 'Prueba', app: 'Registro', apm: 'Local', telefono: '5550000000' })
    const request = async (path, body, token) => {
        const r = await fetch(base + path, { method: body ? 'POST' : 'GET',
            headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
            ...(body ? { body: JSON.stringify(body) } : {}) })
        return { status: r.status, body: await r.json() }
    }
    const create = async suffix => {
        const user = makeUser(suffix)
        const r = await request('/api/users', user)
        assert.equal(r.status, 201)
        return { ...user, id: r.body.user.id }
    }
    try {
        const user = await create('base')
        await t.test('registro sin rol crea solo users y nunca acepta el rol del cliente', async () => {
            for (const rol of ['ADMIN', 'CUIDADOR']) {
                const r = await request('/api/users', { ...makeUser(rol), rol, fechaNac: '2000-01-01' })
                assert.equal(r.status, 201)
                assert.equal(r.body.user.rol, 'PACIENTE')
                assert.equal(r.body.user.password, undefined)
                for (const table of ['pacientes', 'cuidadores']) {
                    assert.equal((await pool.query(`SELECT * FROM ${table} WHERE usuario_id=$1`, [r.body.user.id])).rowCount, 0)
                }
            }
            assert.equal((await request('/api/users', { ...makeUser('incompleto'), nombre: '' })).status, 400)
            assert.equal((await request('/api/users', user)).status, 409)
            const list = await request('/api/users')
            assert.equal(list.status, 200)
            assert.ok(list.body.some(u => u.id === user.id))
            assert.ok(list.body.every(u => u.password === undefined))
        })
        await t.test('login usa correo/contraseña y protege ambos perfiles', async () => {
            const login = await request('/api/login', { email: user.email, password: user.password })
            assert.equal(login.status, 200)
            for (const path of ['/api/pacientes', '/api/cuidadores']) {
                assert.equal((await request(path, { usuario_id: user.id })).status, 401)
                assert.equal((await request(path, { usuario_id: user.id }, login.body.token)).status, 403)
            }
        })
        const admin = makeUser('admin')
        await pool.query(`INSERT INTO users (id,email,password,nombre,app,apm,telefono,rol)
            VALUES ($1,$2,$3,$4,$5,$6,$7,'ADMIN')`,
            [Date.now() + 10000000, admin.email, admin.password, admin.nombre, admin.app, admin.apm, admin.telefono])
        const token = (await request('/api/login', admin)).body.token
        const medical = { fechaNac: '2000-01-01', contactoEmergencia: 'Contacto', telefonoEmergencia: '5551111111' }
        await t.test('vincula perfiles, cambia roles y conserva cuentas y datos base', async () => {
            const patient = await create('paciente'), carer = await create('cuidador')
            await pool.query("UPDATE users SET rol='CUIDADOR' WHERE id=$1", [patient.id])
            const count = (await pool.query('SELECT count(*) FROM users')).rows[0].count
            const p = await request('/api/pacientes', { usuario_id: patient.id, ...medical,
                nombre: 'Ignorar', email: 'ignored@example.invalid' }, token)
            assert.equal(p.status, 201)
            assert.equal(p.body.user.id, patient.id)
            assert.equal(p.body.user.rol, 'PACIENTE')
            assert.equal(p.body.user.nombre, patient.nombre)
            assert.equal(p.body.user.email, patient.email)
            const profile = (await pool.query('SELECT * FROM pacientes WHERE usuario_id=$1', [patient.id])).rows[0]
            assert.equal(profile.contacto_emergencia, medical.contactoEmergencia)
            const c = await request('/api/cuidadores', { usuario_id: carer.id, numeroLicencia: 'L123', parentescoRelacion: 'Familiar' }, token)
            assert.equal(c.status, 201)
            assert.equal(c.body.user.rol, 'CUIDADOR')
            assert.equal((await pool.query('SELECT * FROM cuidadores WHERE usuario_id=$1', [carer.id])).rows[0].numero_licencia, 'L123')
            assert.equal((await pool.query('SELECT count(*) FROM users')).rows[0].count, count)
            assert.equal((await request('/api/login', carer)).body.usuario.rol, 'CUIDADOR')
            await pool.query("UPDATE users SET rol='PACIENTE' WHERE id=$1", [carer.id])
            assert.equal((await request('/api/cuidadores', { usuario_id: carer.id }, token)).status, 409)
            assert.equal((await pool.query('SELECT rol FROM users WHERE id=$1', [carer.id])).rows[0].rol, 'PACIENTE')
        })
        await t.test('fallo de INSERT revierte UPDATE de rol y conserva la cuenta', async () => {
            const account = await create('rollback')
            await pool.query("UPDATE users SET rol='CUIDADOR' WHERE id=$1", [account.id])
            assert.equal((await request('/api/pacientes', { usuario_id: account.id, ...medical, fechaNac: 'invalida' }, token)).status, 400)
            assert.equal((await pool.query('SELECT rol FROM users WHERE id=$1', [account.id])).rows[0].rol, 'CUIDADOR')
            assert.equal((await pool.query('SELECT * FROM pacientes WHERE usuario_id=$1', [account.id])).rowCount, 0)
            assert.equal((await request('/api/pacientes', { usuario_id: account.id, ...medical }, token)).status, 201)
        })
        await t.test('rechaza IDs inválidos/inexistentes y datos médicos incompletos', async () => {
            assert.equal((await request('/api/cuidadores', { usuario_id: '9223372036854775807' }, token)).status, 404)
            for (const usuario_id of [null, '', 'abc', -1]) {
                assert.equal((await request('/api/cuidadores', { usuario_id }, token)).status, 400)
            }
            assert.equal((await request('/api/pacientes', { usuario_id: user.id }, token)).status, 400)
        })
    } finally {
        await pool.query('DELETE FROM users WHERE email LIKE $1', [`${prefix}-%@example.invalid`])
        await new Promise(resolve => server.close(resolve))
        await pool.end()
    }
})
