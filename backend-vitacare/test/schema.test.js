const { test } = require('node:test')
const assert = require('node:assert/strict')
const { randomUUID } = require('node:crypto')
const fs = require('node:fs')
const path = require('node:path')
const { pool } = require('../server')
const schema = fs.readFileSync(path.join(__dirname, '../../schema.sql'), 'utf8')
const migration = fs.readFileSync(path.join(__dirname, '../migrations/001_serial_ids_pending_role.sql'), 'utf8')
const insert = `INSERT INTO users (email,password,nombre,app,apm,telefono)
    VALUES ('test@example.invalid','password','Prueba','Local','SQL','5551111111') RETURNING id,rol`

test('IDs seriales y migración no destructiva', async t => {
    const client = await pool.connect()
    const namespaces = []
    const isolated = async () => {
        const name = 'test_' + randomUUID().replaceAll('-', '')
        namespaces.push(name)
        await client.query(`CREATE SCHEMA ${name}`)
        await client.query(`SET search_path TO ${name}`)
        return name
    }
    try {
        await t.test('esquema nuevo genera 1 y 2 con rol PENDIENTE', async () => {
            await isolated()
            await client.query(schema)
            assert.deepEqual((await client.query(insert)).rows[0], { id: '1', rol: 'PENDIENTE' })
            await client.query('DELETE FROM users')
            assert.deepEqual((await client.query(insert)).rows[0], { id: '2', rol: 'PENDIENTE' })
        })
        await t.test('migración conserva IDs y referencias, sincroniza contador y admite repetición', async () => {
            const namespace = await isolated()
            await client.query(schema.replace(", 'PENDIENTE'", '').replace('BIGSERIAL', 'BIGINT').replace(" DEFAULT 'PENDIENTE'", ''))
            await client.query(`INSERT INTO users (id,email,password,nombre,app,apm,telefono,rol)
                VALUES (1730000000000,'legacy@example.invalid','password','Prueba','Local','SQL','5551111111','CUIDADOR')`)
            await client.query("INSERT INTO cuidadores (usuario_id, numero_licencia) VALUES (1730000000000,'L123')")
            const apply = async () => {
                const sql = migration.replaceAll('public.', namespace + '.')
                const boundary = sql.indexOf('\nBEGIN;')
                await client.query(sql.slice(0, boundary))
                await client.query(sql.slice(boundary))
            }
            await apply()
            assert.deepEqual((await client.query('SELECT usuario_id,numero_licencia FROM cuidadores')).rows[0],
                { usuario_id: '1730000000000', numero_licencia: 'L123' })
            assert.deepEqual((await client.query(insert)).rows[0], { id: '1730000000001', rol: 'PENDIENTE' })
            await apply()
            await client.query("UPDATE users SET email='updated@example.invalid' WHERE email='test@example.invalid'")
            assert.equal((await client.query(insert)).rows[0].id, '1730000000002')
            await client.query('DELETE FROM users')
            await apply()
            assert.equal((await client.query(insert)).rows[0].id, '1')
        })
    } finally {
        await client.query('ROLLBACK')
        await client.query('RESET search_path')
        for (const name of namespaces) await client.query(`DROP SCHEMA ${name} CASCADE`)
        client.release()
        await pool.end()
    }
})
