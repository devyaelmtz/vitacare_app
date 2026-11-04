-- Ejecutar con autocommit (psql -f archivo.sql, sin --single-transaction).
-- El valor del ENUM debe confirmarse antes de usarlo como DEFAULT.
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'PENDIENTE';

BEGIN;
LOCK TABLE public.users IN ACCESS EXCLUSIVE MODE;

-- BIGSERIAL equivale a BIGINT con una secuencia propia como DEFAULT.
-- No se renumeran IDs ni se modifican las relaciones existentes.
CREATE SEQUENCE IF NOT EXISTS public.users_id_seq AS BIGINT START WITH 1;
ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;
ALTER TABLE public.users ALTER COLUMN id
    SET DEFAULT nextval('public.users_id_seq'::regclass);
ALTER TABLE public.users ALTER COLUMN rol SET DEFAULT 'PENDIENTE';

-- Vacía: el primer ID será 1. Con filas: el siguiente será MAX(id) + 1.
-- ALTER SEQUENCE RESTART es transaccional y evita consumir un ID al verificar.
DO $$
DECLARE siguiente BIGINT;
BEGIN
    SELECT COALESCE(MAX(id), 0) + 1 INTO siguiente FROM public.users;
    EXECUTE format('ALTER SEQUENCE public.users_id_seq RESTART WITH %s', siguiente);
END $$;
COMMIT;
