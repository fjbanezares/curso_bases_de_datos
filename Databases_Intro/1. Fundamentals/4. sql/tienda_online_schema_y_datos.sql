-- ==============================================================================
-- SCHEMA Y SEMILLA DE DATOS: TIENDA ONLINE (SQL DESDE CERO)
-- Compatible con PostgreSQL y SQLite
-- ==============================================================================

DROP TABLE IF EXISTS detalle_pedido;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS clientes;

-- 1. TABLA CLIENTES
CREATE TABLE clientes (
    id_cliente INTEGER PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    ciudad VARCHAR(50) NOT NULL,
    telefono VARCHAR(20) -- Permite NULL deliberadamente para practicar IS NULL
);

-- 2. TABLA PRODUCTOS
CREATE TABLE productos (
    id_producto INTEGER PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    precio NUMERIC(10,2) NOT NULL,
    stock INTEGER NOT NULL,
    categoria VARCHAR(50) NOT NULL
);

-- 3. TABLA PEDIDOS
CREATE TABLE pedidos (
    id_pedido INTEGER PRIMARY KEY,
    id_cliente INTEGER NOT NULL REFERENCES clientes(id_cliente),
    fecha DATE NOT NULL,
    estado VARCHAR(20) NOT NULL CHECK (estado IN ('Pendiente', 'Enviado', 'Entregado', 'Cancelado'))
);

-- 4. TABLA DETALLE_PEDIDO
CREATE TABLE detalle_pedido (
    id_detalle INTEGER PRIMARY KEY,
    id_pedido INTEGER NOT NULL REFERENCES pedidos(id_pedido),
    id_producto INTEGER NOT NULL REFERENCES productos(id_producto),
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(10,2) NOT NULL
);

-- ==============================================================================
-- INSERCIÓN DE DATOS DE PRUEBA (SEEDS REALISTAS)
-- ==============================================================================

-- Clientes (algunos sin teléfono para practicar NULL)
INSERT INTO clientes (id_cliente, nombre, email, ciudad, telefono) VALUES
(1, 'Ana López', 'ana@correo.com', 'Madrid', '600111222'),
(2, 'Carlos Ruiz', 'carlos@correo.com', 'Barcelona', NULL),
(3, 'Laura García', 'laura@correo.com', 'Valencia', '600333444'),
(4, 'David Morales', 'david@correo.com', 'Madrid', '600555666'),
(5, 'Elena Sanz', 'elena@correo.com', 'Sevilla', NULL),
(6, 'Fernando Torres', 'fernando@correo.com', 'Barcelona', '600777888'),
(7, 'Marta Díaz', 'marta@correo.com', 'Murcia', NULL),
(8, 'Javier Gil', 'javier@correo.com', 'Valencia', '600999000');

-- Productos
INSERT INTO productos (id_producto, nombre, precio, stock, categoria) VALUES
(1, 'Portátil Pro 15', 1200.00, 15, 'Electrónica'),
(2, 'Monitor 4K 27"', 450.00, 20, 'Electrónica'),
(3, 'Teclado Mecánico RGB', 85.00, 50, 'Accesorios'),
(4, 'Ratón Inalámbrico', 25.50, 100, 'Accesorios'),
(5, 'Auriculares Cancelación Ruido', 180.00, 30, 'Electrónica'),
(6, 'Camiseta Algodón Tech', 19.99, 80, 'Ropa'),
(7, 'Sudadera Desarrollador', 45.00, 40, 'Ropa'),
(8, 'Alfombrilla XXL Gaming', 18.00, 0, 'Accesorios'), -- Stock cero para practicar filtros
(9, 'Webcam 1080p HD', 65.00, 25, 'Electrónica'),
(10, 'Silla Ergonómica Oficina', 290.00, 10, 'Mobiliario');

-- Pedidos (distintas fechas y estados)
INSERT INTO pedidos (id_pedido, id_cliente, fecha, estado) VALUES
(101, 1, '2026-01-10', 'Entregado'),
(102, 2, '2026-01-15', 'Entregado'),
(103, 3, '2026-02-01', 'Entregado'),
(104, 1, '2026-02-20', 'Entregado'),
(105, 4, '2026-02-28', 'Cancelado'),
(106, 5, '2026-03-05', 'Entregado'),
(107, 2, '2026-03-12', 'Enviado'),
(108, 6, '2026-03-20', 'Enviado'),
(109, 3, '2026-03-25', 'Pendiente'),
(110, 1, '2026-04-02', 'Pendiente'),
(111, 7, '2026-04-10', 'Entregado'),
(112, 4, '2026-04-15', 'Enviado');

-- Detalles de pedido (Líneas de compra)
INSERT INTO detalle_pedido (id_detalle, id_pedido, id_producto, cantidad, precio_unitario) VALUES
(1, 101, 1, 1, 1200.00), -- Ana compró portátil
(2, 101, 4, 1, 25.50),   -- y ratón
(3, 102, 3, 2, 85.00),   -- Carlos compró 2 teclados
(4, 103, 2, 1, 450.00),  -- Laura compró monitor
(5, 103, 5, 1, 180.00),  -- y auriculares
(6, 104, 6, 3, 19.99),   -- Ana compró 3 camisetas
(7, 104, 7, 1, 45.00),   -- y sudadera
(8, 105, 1, 1, 1200.00), -- David (pedido cancelado)
(9, 106, 4, 4, 25.50),   -- Elena compró 4 ratones
(10, 106, 3, 1, 85.00),  -- y 1 teclado
(11, 107, 5, 2, 180.00), -- Carlos compró 2 auriculares
(12, 108, 10, 1, 290.00),-- Fernando compró silla
(13, 108, 2, 1, 450.00), -- y monitor
(14, 109, 9, 1, 65.00),  -- Laura compró webcam
(15, 110, 2, 1, 450.00), -- Ana compró monitor
(16, 110, 3, 1, 85.00),  -- y teclado
(17, 111, 7, 2, 45.00),  -- Marta compró 2 sudaderas
(18, 112, 1, 1, 1200.00),-- David compró portátil
(19, 112, 4, 2, 25.50);  -- y 2 ratones
