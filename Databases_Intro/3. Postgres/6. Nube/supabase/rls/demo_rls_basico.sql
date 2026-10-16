-- ==============================================================================
-- 🛡️ LABORATORIO PRÁCTICO: ROW LEVEL SECURITY (RLS) EN POSTGRESQL PURO
-- ==============================================================================
-- Este script demuestra de forma 100% visual y práctica cómo funciona RLS.
-- Demuestra que RLS es una característica NATIVA de PostgreSQL (introducida en PG 9.5)
-- y que funciona en cualquier consola psql, pgAdmin o en Supabase SQL Editor.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 0. LIMPIEZA PREVIA
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS mis_secretos CASCADE;
DROP ROLE IF EXISTS usuario_ana;
DROP ROLE IF EXISTS usuario_carlos;

-- Creamos dos roles (usuarios de prueba) sin permisos de superusuario:
CREATE ROLE usuario_ana WITH LOGIN PASSWORD 'clave_ana';
CREATE ROLE usuario_carlos WITH LOGIN PASSWORD 'clave_carlos';

-- ------------------------------------------------------------------------------
-- 1. CREACIÓN DE LA TABLA Y DATOS DE PRUEBA
-- ------------------------------------------------------------------------------
CREATE TABLE mis_secretos (
    id SERIAL PRIMARY KEY,
    propietario VARCHAR(50) NOT NULL,
    secreto TEXT NOT NULL,
    es_publico BOOLEAN DEFAULT false
);

-- Concedemos permiso general (GRANT) a ambos usuarios para consultar e insertar:
GRANT SELECT, INSERT, UPDATE, DELETE ON mis_secretos TO usuario_ana, usuario_carlos;
GRANT USAGE, SELECT ON SEQUENCE mis_secretos_id_seq TO usuario_ana, usuario_carlos;

-- Insertamos 4 secretos (2 de Ana y 2 de Carlos):
INSERT INTO mis_secretos (propietario, secreto, es_publico) VALUES
('usuario_ana', 'Tengo miedo a la oscuridad', false),
('usuario_ana', 'Me encanta programar en Python', true),
('usuario_carlos', 'Perdí las llaves de la oficina el lunes', false),
('usuario_carlos', 'Mi comida favorita es la paella', true);

-- ------------------------------------------------------------------------------
-- 2. COMPROBACIÓN 1: ¿QUÉ PASA ANTES DE ACTIVAR RLS?
-- ------------------------------------------------------------------------------
-- Nos ponemos en la piel de "usuario_ana":
SET ROLE usuario_ana;

-- Ana ejecuta un SELECT:
SELECT * FROM mis_secretos;
-- ❌ RESULTADO: Ana puede leer ABSOLUTAMENTE TODOS los secretos (los suyos y los privados de Carlos).
-- Esto es un fallo grave de privacidad en aplicaciones multiusuario.

-- Volvemos al rol administrador:
RESET ROLE;

-- ------------------------------------------------------------------------------
-- 3. ACTIVAR RLS (ROW LEVEL SECURITY)
-- ------------------------------------------------------------------------------
ALTER TABLE mis_secretos ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- 4. COMPROBACIÓN 2: EFECTO "DEFAULT DENY" (DENEGACIÓN POR DEFECTO)
-- ------------------------------------------------------------------------------
-- Nos ponemos de nuevo en la piel de "usuario_ana":
SET ROLE usuario_ana;

SELECT * FROM mis_secretos;
-- 🔒 RESULTADO: ¡0 filas! No devuelve nada.
-- Al activar RLS sin políticas, PostgreSQL bloquea el acceso a todos los usuarios normales por seguridad.

RESET ROLE;

-- ------------------------------------------------------------------------------
-- 5. CREACIÓN DE POLÍTICA 1: LECTURA DE SECRETOS PÚBLICOS
-- ------------------------------------------------------------------------------
-- Cualquier usuario puede leer las filas donde 'es_publico = true':
CREATE POLICY "Lectura de secretos publicos"
ON mis_secretos
FOR SELECT
USING (es_publico = true);

SET ROLE usuario_ana;
SELECT * FROM mis_secretos;
-- 👁️ RESULTADO: Ahora Ana solo ve 2 filas (los secretos marcados como públicos).
-- Los secretos privados siguen totalmente invisibles.

RESET ROLE;

-- ------------------------------------------------------------------------------
-- 6. CREACIÓN DE POLÍTICA 2: LECTURA DE SECRETOS PROPIOS
-- ------------------------------------------------------------------------------
-- Cada usuario puede leer además cualquier secreto donde el propietario coincida con su usuario actual:
CREATE POLICY "Lectura de secretos propios"
ON mis_secretos
FOR SELECT
USING (propietario = current_user);

SET ROLE usuario_ana;
SELECT * FROM mis_secretos;
-- 🎯 RESULTADO: Ana ahora ve:
--   1. Su secreto privado ("Tengo miedo a la oscuridad")
--   2. Su secreto público ("Me encanta programar en Python")
--   3. El secreto público de Carlos ("Mi comida favorita es la paella")
-- ¡Pero JAMÁS ve el secreto privado de Carlos ("Perdí las llaves...")!

RESET ROLE;

-- ------------------------------------------------------------------------------
-- 7. CREACIÓN DE POLÍTICA 3: ESCRITURA SEGURA (WITH CHECK)
-- ------------------------------------------------------------------------------
-- Ana solo puede insertar secretos asignándoselos a sí misma:
CREATE POLICY "Insercion de secretos propios"
ON mis_secretos
FOR INSERT
WITH CHECK (propietario = current_user);

SET ROLE usuario_ana;

-- Intento legítimo: Ana inserta un secreto propio:
INSERT INTO mis_secretos (propietario, secreto, es_publico)
VALUES ('usuario_ana', 'Aprendí a usar RLS en PostgreSQL', false);
-- ✅ ÉXITO: Se inserta correctamente.

-- Intento malicioso: Ana intenta suplantar la identidad de Carlos:
-- INSERT INTO mis_secretos (propietario, secreto, es_publico)
-- VALUES ('usuario_carlos', 'Carlos confiesa algo falso', true);
-- ❌ ERROR: new row violates row-level security policy for table "mis_secretos".
-- PostgreSQL rechaza la operación automáticamente gracias a WITH CHECK.

RESET ROLE;

-- ------------------------------------------------------------------------------
-- 8. LIMPIEZA FINAL
-- ------------------------------------------------------------------------------
-- DROP TABLE mis_secretos;
-- DROP ROLE usuario_ana;
-- DROP ROLE usuario_carlos;
