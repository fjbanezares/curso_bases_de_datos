-- ACADEMIA · Práctica para la guía visual MySQL Workbench
-- MySQL 8.0.16+ / 8.4, motor InnoDB. Codificación UTF-8.
-- 1. Abre una conexión de administración a tu servidor de laboratorio.
-- 2. Ejecuta la sección A una sola vez, en un esquema nuevo.
--    No contiene DROP ni borra bases existentes.
--    Si academia ya existe y tiene tablas, elige otro nombre en CREATE y USE.
-- 3. Las secciones B y C pueden repetirse.
-- 4. D y E están comentadas: selecciona una orden cada vez para probarla.
-- Las contraseñas son ejemplos públicos: cámbialas al crear cuentas reales.

-- A · Crear el esquema y datos iniciales (una sola vez)
CREATE DATABASE academia CHARACTER SET utf8mb4;
USE academia;
CREATE TABLE alumno (
  id INT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(80) NOT NULL,
  email VARCHAR(120) NOT NULL UNIQUE
) ENGINE=InnoDB;
CREATE TABLE curso (
  id INT PRIMARY KEY AUTO_INCREMENT,
  titulo VARCHAR(100) NOT NULL
) ENGINE=InnoDB;
CREATE TABLE matricula (
  alumno_id INT NOT NULL,
  curso_id INT NOT NULL,
  nota DECIMAL(3,1) NOT NULL,
  PRIMARY KEY (alumno_id, curso_id),
  CONSTRAINT fk_alumno FOREIGN KEY (alumno_id)
    REFERENCES alumno(id) ON DELETE RESTRICT,
  CONSTRAINT fk_curso FOREIGN KEY (curso_id)
    REFERENCES curso(id) ON DELETE RESTRICT,
  CONSTRAINT ck_nota CHECK (nota BETWEEN 0 AND 10)
) ENGINE=InnoDB;
INSERT INTO alumno (id, nombre, email) VALUES
  (1,'Ana','ana@example.com'),
  (2,'Luis','luis@example.com'),
  (3,'Sara','sara@example.com');
INSERT INTO curso (id, titulo) VALUES
  (1,'SQL'), (2,'Python');
INSERT INTO matricula (alumno_id, curso_id, nota) VALUES
  (1,1,8.5), (1,2,9.0), (2,1,7.0);

-- B · Consultar e inspeccionar
USE academia;
SELECT VERSION(), USER(), CURRENT_USER(), DATABASE();
SHOW VARIABLES LIKE 'datadir';
SHOW TABLES;
SHOW CREATE TABLE matricula;
SELECT a.nombre, c.titulo, m.nota
FROM matricula AS m
JOIN alumno AS a ON a.id=m.alumno_id
JOIN curso AS c ON c.id=m.curso_id
ORDER BY a.nombre, c.titulo;

-- LEFT JOIN permite encontrar también alumnos sin matrícula.
SELECT a.id, a.nombre, COUNT(m.curso_id) AS total_cursos
FROM alumno AS a
LEFT JOIN matricula AS m ON m.alumno_id=a.id
GROUP BY a.id, a.nombre
ORDER BY a.id;
EXPLAIN SELECT * FROM alumno WHERE email='ana@example.com';

-- C · Cambiar datos y deshacer (la nota final seguirá siendo 8.5)
START TRANSACTION;
UPDATE matricula SET nota=9 WHERE alumno_id=1 AND curso_id=1;
SELECT * FROM matricula WHERE alumno_id=1 AND curso_id=1;
ROLLBACK;
SELECT * FROM matricula WHERE alumno_id=1 AND curso_id=1;

-- D · El guardián: descomenta y ejecuta cada caso POR SEPARADO.
-- Todos fallan con los datos iniciales y no deberían cambiar los datos.
-- 1. PK duplicada, error 1062:
-- INSERT INTO matricula VALUES (1,1,9);
-- 2. FK a alumno inexistente, error 1452:
-- INSERT INTO matricula VALUES (999,1,7);
-- 3. CHECK de nota, error 3819:
-- UPDATE matricula SET nota=11 WHERE alumno_id=1;
-- 4. NOT NULL, error 1048:
-- UPDATE alumno SET email=NULL WHERE id=1;
-- 5. UNIQUE, error 1062:
-- UPDATE alumno SET email='luis@example.com' WHERE id=1;
-- 6. ON DELETE RESTRICT, error 1451:
-- DELETE FROM alumno WHERE id=1;

-- E · Administración opcional: ejecutar como administrador, una orden cada vez.
-- CREATE USER 'lector'@'localhost'
--   IDENTIFIED BY 'Cambia-Esta-Clave-2026!';
-- GRANT SELECT ON academia.* TO 'lector'@'localhost';
-- CREATE USER 'app'@'localhost'
--   IDENTIFIED BY 'Otra-Clave-Larga-2026!';
-- GRANT SELECT,INSERT,UPDATE,DELETE ON academia.* TO 'app'@'localhost';
-- SHOW GRANTS FOR 'lector'@'localhost';
-- REVOKE SELECT ON academia.* FROM 'lector'@'localhost';
-- GRANT SELECT ON academia.* TO 'lector'@'localhost';
-- ALTER USER 'lector'@'localhost' IDENTIFIED BY 'Nueva-Clave-Larga-2026!';

-- Acceso a columnas concretas mediante vista:
-- CREATE VIEW academia.directorio AS SELECT id,nombre FROM academia.alumno;
-- CREATE USER 'visitante'@'localhost' IDENTIFIED BY 'Clave-Visitante-2026!';
-- GRANT SELECT ON academia.directorio TO 'visitante'@'localhost';
-- Abre otra conexión con visitante: verá directorio, no alumno.email.
-- No le concedas además SELECT sobre academia.*: acumularía ese acceso.

-- F · Reto final:
-- 1. Obtén el diagrama con Database > Reverse Engineer.
-- 2. Añade una matrícula de Sara en Python y comprueba el JOIN.
-- 3. Consulta cuántos alumnos hay en cada curso, incluidos cursos sin alumnos.
-- 4. Prueba SELECT e INSERT en una nueva conexión de lector.
-- 5. Exporta academia y restaura en academia_restaurada vacía.
-- 6. Explica por qué una FK entre dos shards necesita coordinación.
