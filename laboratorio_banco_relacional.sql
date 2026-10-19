-- ============================================================================
-- 🏦 LABORATORIO SQL BANCARIO COMPLETO: BANCO HORIZONTE
-- Archivo oficial para ejecutar en las mesas de clase (Clase 34)
-- Entorno: PostgreSQL 14+ / pgAdmin 4 / psql / DBeaver
-- ============================================================================

-- ============================================================================
-- FASE 1: PRIMEROS PASOS BÁSICOS EN SQL (Punto 07)
-- ============================================================================
DROP TABLE IF EXISTS demo_cuentas CASCADE;

-- 1.1. CREATE TABLE: Definir columnas y tipos de datos
CREATE TABLE demo_cuentas (
    id SERIAL PRIMARY KEY,
    titular VARCHAR(100) NOT NULL,
    saldo NUMERIC(10, 2) NOT NULL DEFAULT 0.00
);

-- 1.2. INSERT INTO: Guardar datos en disco
INSERT INTO demo_cuentas (titular, saldo) VALUES
('Elena Navarro', 3450.00),
('Carlos Benítez', 5200.00);

-- 1.3. SELECT: Proyectar y consultar
SELECT id, titular, saldo FROM demo_cuentas WHERE saldo > 4000;


-- ============================================================================
-- FASE 2: HACERLO MAL PRIMERO (El Monolito Plano: Acoplar Persona a Transacción - Puntos 12-14)
-- ============================================================================
DROP TABLE IF EXISTS transacciones_monolito CASCADE;

CREATE TABLE transacciones_monolito (
    id SERIAL PRIMARY KEY,
    nombre_cliente VARCHAR(100),
    dni VARCHAR(15),
    telefono_movil VARCHAR(20),
    email_contacto VARCHAR(100),
    direccion_cliente VARCHAR(150),
    concepto_transaccion VARCHAR(120),
    importe NUMERIC(10, 2),
    fecha_transaccion DATE
);

-- Insertamos 4 transacciones legítimas de Elena Navarro:
INSERT INTO transacciones_monolito 
(nombre_cliente, dni, telefono_movil, email_contacto, direccion_cliente, concepto_transaccion, importe, fecha_transaccion) 
VALUES
('Elena Navarro Soler', '11223344A', '+34 611 111 222', 'elena@email.com', 'Calle Mayor 102, 2ºC (Madrid)', 'Abono Nómina Tech Corp', 3450.00, '2026-01-15'),
('Elena Navarro Soler', '11223344A', '+34 611 111 222', 'elena@email.com', 'Calle Mayor 102, 2ºC (Madrid)', 'Compra Mercadona Gran Vía', -86.45, '2026-02-02'),
('Elena Navarro Soler', '11223344A', '+34 611 111 222', 'elena@email.com', 'Calle Mayor 102, 2ºC (Madrid)', 'Recibo Electricidad Iberdrola', -112.30, '2026-03-05'),
('Elena Navarro Soler', '11223344A', '+34 611 111 222', 'elena@email.com', 'Calle Mayor 102, 2ºC (Madrid)', 'Cena Restaurante El Cenador', -145.00, '2026-10-10');

-- Demostración de la incoherencia y pérdida de juego operativo:
-- Si Elena cambia de casa o de móvil, en el monolito habría que ejecutar un UPDATE masivo:
UPDATE transacciones_monolito 
SET direccion_cliente = 'Calle Gran Vía 45, 4ºB (Madrid)',
    telefono_movil = '+34 699 999 999' 
WHERE dni = '11223344A';

-- Si el administrativo actualiza por descuido solo una fila, tenemos dos direcciones para la misma persona:
SELECT id, nombre_cliente, telefono_movil, direccion_cliente, concepto_transaccion 
FROM transacciones_monolito;


-- ============================================================================
-- FASE 3: HACERLO BIEN (Modelo Relacional 3NF - Puntos 16-18)
-- ============================================================================
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS customer_addresses CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- 3.1. Tabla de Clientes
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    tax_id VARCHAR(15) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL
);

-- 3.2. Tabla de Direcciones (Viviendas con dimensión temporal SCD Tipo 2)
CREATE TABLE customer_addresses (
    id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    address_type VARCHAR(30) NOT NULL,
    street_address VARCHAR(150) NOT NULL,
    city VARCHAR(50) NOT NULL,
    postal_code VARCHAR(10) NOT NULL,
    is_correspondence BOOLEAN NOT NULL DEFAULT FALSE,
    valid_from DATE NOT NULL,
    valid_to DATE -- NULL si es la dirección activa hoy
);

-- 3.3. Tabla de Transacciones y Movimientos
CREATE TABLE transactions (
    id BIGSERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    account_iban VARCHAR(34) NOT NULL,
    concept VARCHAR(120) NOT NULL,
    category VARCHAR(40) NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    transaction_timestamp TIMESTAMPTZ NOT NULL
);

-- Índices en claves foráneas
CREATE INDEX idx_addresses_cust ON customer_addresses(customer_id);
CREATE INDEX idx_tx_cust ON transactions(customer_id);
CREATE INDEX idx_tx_time ON transactions(transaction_timestamp DESC);

-- ============================================================================
-- FASE 4: POBLACIÓN DE DATOS REALES (3 Clientes, 10 Casas, 10 Transacciones)
-- ============================================================================
BEGIN;

-- 4.1. 3 Clientes del Banco
INSERT INTO customers (id, full_name, tax_id, email, phone) VALUES
(1, 'Elena Navarro Soler', '11223344A', 'elena.navarro@email.com', '+34 611 111 222'),
(2, 'Carlos Benítez Vega', '22334455B', 'carlos.benitez@email.com', '+34 622 333 444'),
(3, 'Lucía Morales Prado', '33445566C', 'lucia.morales@email.com', '+34 633 555 666');

SELECT setval('customers_id_seq', (SELECT MAX(id) FROM customers));

-- 4.2. 10 Viviendas distribuidas
INSERT INTO customer_addresses 
(customer_id, address_type, street_address, city, postal_code, is_correspondence, valid_from, valid_to) 
VALUES
-- Elena (4 casas): Hasta 2020 residió en Calle Mayor 102; desde 2020 en Gran Vía 45
(1, 'Principal', 'Calle Gran Vía 45, 4ºB', 'Madrid', '28013', TRUE, '2020-01-15', NULL),
(1, 'Veraneo', 'Paseo Marítimo 12', 'Alicante', '03001', FALSE, '2022-06-01', NULL),
(1, 'Inversión', 'Calle Sierpes 8', 'Sevilla', '41004', FALSE, '2023-09-10', NULL),
(1, 'Histórica Anterior', 'Calle Mayor 102, 2ºC', 'Madrid', '28005', TRUE, '2015-02-01', '2020-01-14'),

-- Carlos (3 casas)
(2, 'Principal', 'Avinguda Diagonal 500', 'Barcelona', '08006', TRUE, '2018-04-10', NULL),
(2, 'Veraneo', 'Camí de Ronda 22', 'Cadaqués', '17488', FALSE, '2021-07-15', NULL),
(2, 'Despacho', 'Rambla Catalunya 40', 'Barcelona', '08007', FALSE, '2019-11-01', NULL),

-- Lucía (3 casas)
(3, 'Principal', 'Calle Colón 15', 'Valencia', '46004', TRUE, '2021-03-01', NULL),
(3, 'Veraneo', 'Avenida del Faro 5', 'Dénia', '03700', FALSE, '2023-05-20', NULL),
(3, 'Inversión', 'Calle Uría 30', 'Oviedo', '33003', FALSE, '2024-01-15', NULL);

-- 4.3. 10 Transacciones Financieras Reales (con fechas históricas y recientes)
INSERT INTO transactions 
(customer_id, account_iban, concept, category, amount, transaction_timestamp) 
VALUES
-- Elena (Transacción antigua en 2018 y recientes en 2026)
(1, 'ES91 2100 0418 4502 0005 1111', 'Factura Antigua Préstamo', 'Comisiones', -120.00, '2018-06-15 10:00:00+02'),
(1, 'ES91 2100 0418 4502 0005 1111', 'Abono Nómina Tech Corp', 'Nómina', 3450.00, '2026-10-01 08:30:00+02'),
(1, 'ES91 2100 0418 4502 0005 1111', 'Compra Mercadona Gran Vía', 'Supermercado', -86.45, '2026-10-02 18:15:00+02'),
(1, 'ES91 2100 0418 4502 0005 1111', 'Cena Restaurante El Cenador', 'Ocio', -145.00, '2026-10-10 21:45:00+02'),

-- Carlos
(2, 'ES91 2100 0418 4502 0005 2222', 'Factura Cliente Consultoría', 'Nómina', 5200.00, '2026-10-01 11:00:00+02'),
(2, 'ES91 2100 0418 4502 0005 2222', 'Gasolinera Repsol Diagonal', 'Transporte', -75.50, '2026-10-03 09:20:00+02'),
(2, 'ES91 2100 0418 4502 0005 2222', 'Seguro Médico Sanitas', 'Salud', -85.00, '2026-10-07 07:45:00+02'),

-- Lucía
(3, 'ES91 2100 0418 4502 0005 3333', 'Transferencia Nómina Empresa', 'Nómina', 2850.00, '2026-10-01 09:00:00+02'),
(3, 'ES91 2100 0418 4502 0005 3333', 'Farmacia Central Valencia', 'Salud', -34.20, '2026-10-04 12:10:00+02'),
(3, 'ES91 2100 0418 4502 0005 3333', 'Compra Online Fnac Libros', 'Ocio', -62.80, '2026-10-08 16:30:00+02');

COMMIT;

-- ============================================================================
-- FASE 5: CONSULTAS DIDÁCTICAS CRÍTICAS
-- ============================================================================

-- 5.1. INNER JOIN vs LEFT JOIN (Punto 19)
-- Insertamos a David (Cliente 4 sin transacciones para comprobar la diferencia)
INSERT INTO customers (id, full_name, tax_id, email, phone) 
VALUES (4, 'David Ruiz Gómez', '44556677D', 'david@email.com', '+34 644 777 888')
ON CONFLICT (id) DO NOTHING;

-- Con INNER JOIN: David desaparece
SELECT c.full_name, t.concept, t.amount
FROM customers c
INNER JOIN transactions t ON c.id = t.customer_id;

-- Con LEFT JOIN: David se conserva con NULL
SELECT c.full_name, COALESCE(t.concept, 'Sin transacciones') AS concepto, COALESCE(t.amount, 0.00) AS importe
FROM customers c
LEFT JOIN transactions t ON c.id = t.customer_id;


-- 5.2. LA TRAMPA DEL JOIN EN CORRESPONDENCIA (Punto 20)
-- A) Consulta errónea sin filtros: Elena sale 16 veces
SELECT c.full_name, t.concept, t.amount, a.street_address
FROM customers c
JOIN transactions t ON c.id = t.customer_id
JOIN customer_addresses a ON c.id = a.customer_id
WHERE c.id = 1;

-- B) Consulta correcta con correspondencia actual: Exactamente 4 filas
SELECT c.full_name, t.concept, t.amount, a.street_address AS direccion_envio
FROM customers c
JOIN transactions t ON c.id = t.customer_id
JOIN customer_addresses a 
    ON c.id = a.customer_id 
   AND a.is_correspondence = TRUE 
   AND a.valid_to IS NULL
WHERE c.id = 1;


-- 5.3. EL ENIGMA DE LAS FACTURAS HISTÓRICAS (SCD Tipo 2 - Punto 21)
-- ¿A qué casa se envió una factura de 2018?
SELECT 
    c.full_name,
    t.concept AS movimiento,
    t.amount,
    t.transaction_timestamp::DATE AS fecha_factura,
    a.street_address AS direccion_historica_real,
    a.valid_from,
    COALESCE(a.valid_to::TEXT, 'Vigente hoy') AS hasta_fecha
FROM customers c
JOIN transactions t ON c.id = t.customer_id
JOIN customer_addresses a 
    ON c.id = a.customer_id 
   AND a.is_correspondence = TRUE
   -- Condición temporal estricta de vigencia en la fecha de la factura:
   AND t.transaction_timestamp::DATE >= a.valid_from 
   AND (a.valid_to IS NULL OR t.transaction_timestamp::DATE <= a.valid_to)
WHERE c.id = 1
ORDER BY t.transaction_timestamp ASC;


-- ============================================================================
-- FASE 6: PIPELINE ETL PARA ALIMENTAR HBASE EN 1 MILISEGUNDO (Puntos 25-26)
-- ============================================================================
DROP TABLE IF EXISTS etl_hbase_feed CASCADE;

CREATE TABLE etl_hbase_feed AS
SELECT 
    -- FÓRMULA DE ROWKEY CON TIMESTAMP INVERTIDO:
    'CUST#' || LPAD(c.id::TEXT, 5, '0') || '_' || 
    (922337036854775807 - EXTRACT(EPOCH FROM t.transaction_timestamp)::BIGINT)::TEXT AS hbase_rowkey,
    
    -- Familia personal_data:
    c.full_name AS personal_name,
    c.tax_id AS personal_dni,
    a.street_address AS personal_address,
    
    -- Familia financial:
    t.concept AS tx_concept,
    t.category AS tx_category,
    t.amount AS tx_amount,
    t.transaction_timestamp AS tx_timestamp
FROM customers c
JOIN transactions t ON c.id = t.customer_id
JOIN customer_addresses a 
    ON c.id = a.customer_id 
   AND a.is_correspondence = TRUE 
   AND a.valid_to IS NULL;

-- Al consultar por hbase_rowkey ASC, los movimientos recientes aparecen primerísimos en disco:
SELECT hbase_rowkey, personal_name, tx_concept, tx_amount 
FROM etl_hbase_feed 
ORDER BY hbase_rowkey ASC;
