-- ==============================================================================
-- 🌾 LABORATORIO SQL: CONSULTAS SELECT, FILTROS WHERE Y ANÁLISIS EN POSTGRESQL
-- ==============================================================================
-- Tabla basada en la infografía: 'world_food' (Producción agrícola mundial)
-- Este script es 100% ejecutable en psql, pgAdmin o Supabase SQL Editor.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. PREPARACIÓN Y LIMPIEZA
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS world_food CASCADE;

-- ------------------------------------------------------------------------------
-- 2. CREACIÓN DE LA TABLA
-- ------------------------------------------------------------------------------
-- ¿Qué tipos de datos usamos?
--   - SERIAL: Entero autoincremental que actúa como clave primaria única.
--   - VARCHAR(50): Texto de longitud variable para nombres de países y regiones.
--   - NUMERIC(10, 1): Números decimales precisos para millones de toneladas métricas.
--   - INT: Año de registro estadístico.
CREATE TABLE world_food (
    id SERIAL PRIMARY KEY,
    country VARCHAR(50) NOT NULL,
    region VARCHAR(50) NOT NULL,
    rice_production NUMERIC(10, 1),   -- Millones de toneladas métricas
    wheat_production NUMERIC(10, 1),  -- Millones de toneladas métricas
    year INT DEFAULT 2024
);

-- ------------------------------------------------------------------------------
-- 3. POBLAR LA TABLA CON DATOS DIDÁCTICOS (DATASET VARIADO)
-- ------------------------------------------------------------------------------
-- Insertamos países de diferentes continentes, con producciones variadas y
-- algunos valores NULL intencionados para practicar el tratamiento de nulos.
INSERT INTO world_food (country, region, rice_production, wheat_production, year) VALUES
('China', 'Asia', 214.0, 134.0, 2024),
('India', 'Asia', 178.0, 107.0, 2024),
('Indonesia', 'Asia', 54.6, 0.1, 2024),
('Vietnam', 'Asia', 43.5, 0.0, 2024),
('Bangladesh', 'Asia', 56.4, 1.2, 2024),
('United States', 'Americas', 10.4, 49.7, 2024),
('Brazil', 'Americas', 11.2, 6.1, 2024),
('Canada', 'Americas', 0.0, 35.2, 2024),
('Argentina', 'Americas', 1.4, 17.5, 2024),
('Russia', 'Europe', 1.1, 85.9, 2024),
('Ukraine', 'Europe', 0.5, 26.0, 2024),
('France', 'Europe', 0.1, 33.7, 2024),
('Germany', 'Europe', 0.0, 24.1, 2024),
('Australia', 'Oceania', 0.3, 31.7, 2024),
('Egypt', 'Africa', 4.8, 9.0, 2024),
('Nigeria', 'Africa', 8.5, 0.2, 2024),
('Algeria', 'Africa', NULL, 3.1, 2024),  -- NULL intencionado en arroz
('Iceland', 'Europe', 0.0, NULL, 2024);   -- NULL intencionado en trigo

-- ------------------------------------------------------------------------------
-- 4. CONSULTAS DE LA PÁGINA 1: FUNDAMENTOS DE SELECT
-- ------------------------------------------------------------------------------

-- 4.1. Ver todas las filas y columnas (SELECT *)
SELECT * FROM world_food;

-- 4.2. Proyección de columnas específicas (ahorra memoria y ancho de banda)
SELECT country, wheat_production FROM world_food;

-- 4.3. Renombrar columnas en el resultado con AS (Alias)
SELECT 
    country AS pais, 
    wheat_production AS produccion_trigo 
FROM world_food;

-- 4.4. Obtener valores únicos sin duplicados con DISTINCT
SELECT DISTINCT region FROM world_food;

-- ------------------------------------------------------------------------------
-- 5. CONSULTAS DE LA PÁGINA 2: FILTROS WHERE Y OPERADORES LÓGICOS
-- ------------------------------------------------------------------------------

-- 5.1. Comparación simple: Países de Asia
SELECT country, rice_production 
FROM world_food 
WHERE region = 'Asia';

-- 5.2. Operadores numéricos: Países con producción de trigo mayor o igual a 30M
SELECT country, wheat_production 
FROM world_food 
WHERE wheat_production >= 30.0;

-- 5.3. Combinar condiciones con AND (Ambas deben ser ciertas)
SELECT country, region, rice_production, wheat_production 
FROM world_food 
WHERE rice_production > 10.0 AND wheat_production > 20.0;

-- 5.4. Combinar condiciones con OR (Al menos una debe ser cierta)
SELECT country, region 
FROM world_food 
WHERE country = 'China' OR country = 'India';

-- 5.5. Operador IN: Comprueba si un valor pertenece a una lista de opciones
SELECT country, region 
FROM world_food 
WHERE country IN ('China', 'India', 'Ukraine', 'Egypt');

-- 5.6. Operador BETWEEN: Rango inclusivo (números o fechas)
SELECT country, wheat_production 
FROM world_food 
WHERE wheat_production BETWEEN 10.0 AND 35.0;

-- 5.7. Tratamiento correcto de valores nulos (IS NULL / IS NOT NULL)
-- ⚠️ REGLA DE ORO: En SQL nunca uses '= NULL'. Debes usar 'IS NULL'.
SELECT country, rice_production 
FROM world_food 
WHERE rice_production IS NULL;

-- ------------------------------------------------------------------------------
-- 6. DEDICADO: PATRONES LIKE / ILIKE CON COMBINACIONES AND / OR
-- ------------------------------------------------------------------------------

-- 6.1. LIKE: Empieza por 'U' (sensible a mayúsculas en PostgreSQL)
SELECT country FROM world_food WHERE country LIKE 'U%';

-- 6.2. LIKE: Termina por 'a'
SELECT country FROM world_food WHERE country LIKE '%a';

-- 6.3. ILIKE: Insensible a mayúsculas (busca 'united' sin importar cómo se escriba)
SELECT country FROM world_food WHERE country ILIKE 'united%';

-- 6.4. Comodín guion bajo (_): Exactamente 1 carácter
-- Busca países de 5 letras que terminen en 'a' (ej: China, India):
SELECT country FROM world_food WHERE country LIKE '____a';

-- 6.5. ⚠️ LA TRAMPA DE LA PRECEDENCIA: Mezclar AND y OR con LIKE
-- Caso erróneo (sin paréntesis):
-- El operador AND tiene mayor prioridad que OR, por lo que une:
-- (country LIKE 'C%' AND wheat_production > 20) ... y a eso le aplica OR country LIKE 'B%'.
SELECT country, wheat_production 
FROM world_food 
WHERE country LIKE 'B%' OR country LIKE 'C%' AND wheat_production > 20.0;

-- Caso correcto (con paréntesis explícitos):
-- "Países que empiecen por B o por C, Y ADEMÁS tengan trigo > 20":
SELECT country, wheat_production 
FROM world_food 
WHERE (country LIKE 'B%' OR country LIKE 'C%') AND wheat_production > 20.0;

-- ------------------------------------------------------------------------------
-- 7. CONSULTAS DE LA PÁGINA 3: ORDENAR, LIMITAR Y COLUMNAS CALCULADAS
-- ------------------------------------------------------------------------------

-- 7.1. Ordenar con ORDER BY (DESC = de mayor a menor)
SELECT country, wheat_production 
FROM world_food 
ORDER BY wheat_production DESC;

-- 7.2. Top 5 mundial de productores de trigo (ORDER BY + LIMIT)
SELECT country, wheat_production 
FROM world_food 
WHERE wheat_production IS NOT NULL
ORDER BY wheat_production DESC 
LIMIT 5;

-- 7.3. Paginación con LIMIT y OFFSET
-- Página 1 (primeros 5):
SELECT country, wheat_production FROM world_food LIMIT 5 OFFSET 0;
-- Página 2 (siguientes 5):
SELECT country, wheat_production FROM world_food LIMIT 5 OFFSET 5;

-- 7.4. Columna calculada: Producción total de grano (arroz + trigo)
SELECT 
    country, 
    rice_production, 
    wheat_production,
    (COALESCE(rice_production, 0) + COALESCE(wheat_production, 0)) AS total_grain
FROM world_food
ORDER BY total_grain DESC;

-- ------------------------------------------------------------------------------
-- 8. CONSULTAS DE LA PÁGINA 4: AGREGACIONES, GROUP BY Y HAVING
-- ------------------------------------------------------------------------------

-- 8.1. Funciones de agregación globales
SELECT 
    COUNT(*) AS total_paises,
    SUM(wheat_production) AS trigo_mundial,
    AVG(wheat_production) AS promedio_trigo,
    MIN(wheat_production) AS minimo_trigo,
    MAX(wheat_production) AS maximo_trigo
FROM world_food;

-- 8.2. Agrupar por región (GROUP BY)
SELECT 
    region,
    COUNT(*) AS cantidad_paises,
    SUM(wheat_production) AS total_trigo_region
FROM world_food
GROUP BY region
ORDER BY total_trigo_region DESC;

-- 8.3. Filtrar grupos agregados con HAVING
-- Solo regiones cuya producción total de trigo supere 50M:
SELECT 
    region,
    SUM(wheat_production) AS total_trigo
FROM world_food
GROUP BY region
HAVING SUM(wheat_production) > 50.0;

-- ------------------------------------------------------------------------------
-- 9. LA CONSULTA MAESTRA (COMBINA TODAS LAS CLÁUSULAS SQL)
-- ------------------------------------------------------------------------------
-- Orden mental de ejecución:
-- 1. FROM world_food (toma la tabla)
-- 2. WHERE year = 2024 (descarta años distintos)
-- 3. GROUP BY region (agrupa por continentes)
-- 4. HAVING SUM(wheat_production) > 30 (filtra los grupos)
-- 5. SELECT region, conteo, sumas... (proyecta columnas)
-- 6. ORDER BY total_trigo DESC (ordena el resultado)
-- 7. LIMIT 3 (recorta a los 3 mejores)
SELECT 
    region,
    COUNT(*) AS numero_paises,
    ROUND(SUM(wheat_production), 1) AS total_trigo,
    ROUND(AVG(rice_production), 1) AS promedio_arroz
FROM world_food
WHERE year = 2024
GROUP BY region
HAVING SUM(wheat_production) > 30.0
ORDER BY total_trigo DESC
LIMIT 3;
