-- ============================================================================
-- 🏫 LABORATORIO DIDÁCTICO: ARQUITECTURA DE DATOS Y RELACIONES EN POSTGRESQL
-- Archivo complementario a 'laboratorio_arquitectura_relaciones_sql.md'
-- Entorno: PostgreSQL 14+ / pgAdmin / psql
-- ============================================================================

-- ============================================================================
-- 1. LIMPIEZA INICIAL DEL ENTORNO (DDL)
-- ============================================================================
DROP TABLE IF EXISTS homework_submission CASCADE;
DROP TABLE IF EXISTS enrollment CASCADE;
DROP TABLE IF EXISTS contact_detail CASCADE;
DROP TABLE IF EXISTS class CASCADE;
DROP TABLE IF EXISTS teacher CASCADE;
DROP TABLE IF EXISTS student CASCADE;

-- ============================================================================
-- 2. CREACIÓN DE TABLAS Y RESTRICCIONES (MODELO FÍSICO NORMALIZADO 3NF)
-- ============================================================================

-- 2.1. Tabla Alumnos (Entidad Independiente)
CREATE TABLE student (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    lastname VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    enrollment_year INT NOT NULL CHECK (enrollment_year >= 2000),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2.2. Tabla Profesores
CREATE TABLE teacher (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    department VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE
);

-- 2.3. Tabla Clases / Materias
-- Relación 1:N con Profesor (Una clase tiene un profesor; un profesor imparte varias clases)
CREATE TABLE class (
    id SERIAL PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    title VARCHAR(100) NOT NULL,
    teacher_id INT,
    CONSTRAINT fk_class_teacher 
        FOREIGN KEY (teacher_id) REFERENCES teacher(id) 
        ON DELETE SET NULL -- Si el profesor deja la escuela, la clase se conserva sin profesor
);

-- 2.4. Relación Uno a Uno (1:1) -> Ficha de Contacto y Emergencia
-- La clave primaria es a la vez clave foránea (student_id PK = FK)
CREATE TABLE contact_detail (
    student_id INT PRIMARY KEY,
    phone VARCHAR(20) NOT NULL,
    emergency_contact VARCHAR(100),
    address VARCHAR(200),
    CONSTRAINT fk_contact_student 
        FOREIGN KEY (student_id) REFERENCES student(id) 
        ON DELETE CASCADE -- Si se da de baja al alumno, su ficha de contacto se elimina
);

-- 2.5. Relación Uno a Muchos (1:N) -> Entregas de Tareas
-- La clave foránea SIEMPRE va en el lado del "muchos" (la tabla hija)
CREATE TABLE homework_submission (
    id SERIAL PRIMARY KEY,
    student_id INT NOT NULL,
    title VARCHAR(100) NOT NULL,
    mark NUMERIC(4,2) CHECK (mark >= 0.0 AND mark <= 10.0),
    submitted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_submission_student 
        FOREIGN KEY (student_id) REFERENCES student(id) 
        ON DELETE CASCADE
);

-- 2.6. Relación Muchos a Muchos (N:M) -> Tabla Puente de Matrículas (Enrollment)
-- Convierte la relación N:M en dos relaciones 1:N
CREATE TABLE enrollment (
    student_id INT NOT NULL,
    class_id INT NOT NULL,
    enrollment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    academic_year VARCHAR(9) NOT NULL DEFAULT '2024-2025',
    final_grade NUMERIC(4,2) CHECK (final_grade >= 0.0 AND final_grade <= 10.0),
    -- Clave primaria compuesta para impedir duplicidad de matrícula en el mismo curso
    PRIMARY KEY (student_id, class_id, academic_year),
    CONSTRAINT fk_enrollment_student 
        FOREIGN KEY (student_id) REFERENCES student(id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_enrollment_class 
        FOREIGN KEY (class_id) REFERENCES class(id) 
        ON DELETE RESTRICT -- Impide borrar una asignatura si ya tiene alumnos inscritos
);

-- ============================================================================
-- 3. ÍNDICES DE RENDIMIENTO PARA CLAVES FORÁNEAS
-- (PostgreSQL NO crea índices automáticos en las FKs; crearlos acelera JOINs y borrados)
-- ============================================================================
CREATE INDEX idx_submission_student ON homework_submission(student_id);
CREATE INDEX idx_enrollment_class ON enrollment(class_id);
CREATE INDEX idx_class_teacher ON class(teacher_id);

-- ============================================================================
-- 4. POBLACIÓN DE DATOS (DML EN TRANSACCIÓN ATÓMICA)
-- ============================================================================
BEGIN;

-- Insertar Alumnos
INSERT INTO student (id, name, lastname, email, enrollment_year) VALUES
(1, 'Angela', 'Torres', 'angela@escuela.es', 2024),
(2, 'Jack', 'Miller', 'jack@escuela.es', 2024),
(3, 'Carlos', 'Gómez', 'carlos@escuela.es', 2025);

SELECT setval('student_id_seq', (SELECT MAX(id) FROM student));

-- Insertar Ficha 1:1 (Angela tiene ficha; Jack y Carlos aún no tienen)
INSERT INTO contact_detail (student_id, phone, emergency_contact, address) VALUES
(1, '+34 612 345 678', 'Rosa Torres (Madre)', 'Calle Sol 12, Madrid');

-- Insertar Profesores
INSERT INTO teacher (id, name, department, email) VALUES
(1, 'Dr. Alan Turing', 'Ciencias Exactas', 'turing@escuela.es'),
(2, 'Dra. Ada Lovelace', 'Computación', 'lovelace@escuela.es');

SELECT setval('teacher_id_seq', (SELECT MAX(id) FROM teacher));

-- Insertar Clases
INSERT INTO class (id, code, title, teacher_id) VALUES
(10, 'MAT101', 'Matemáticas Discretas', 1),
(20, 'ENG101', 'Inglés Técnico', NULL), -- Asignatura temporalmente sin profesor
(30, 'PHY101', 'Física Cuántica', 1);

SELECT setval('class_id_seq', (SELECT MAX(id) FROM class));

-- Insertar Entregas 1:N (Angela tiene 3 tareas; Jack y Carlos ninguna)
INSERT INTO homework_submission (student_id, title, mark) VALUES
(1, 'Tarea 1: Conjuntos y Lógica', 8.50),
(1, 'Tarea 2: Inducción Matemática', 9.00),
(1, 'Tarea 3: Grafos y Árboles', 7.50);

-- Insertar Matrículas N:M (Angela: Inglés y Matemáticas; Jack: Matemáticas y Física)
INSERT INTO enrollment (student_id, class_id, academic_year, final_grade) VALUES
(1, 20, '2024-2025', 9.00), -- Angela en Inglés
(1, 10, '2024-2025', 8.50), -- Angela en Matemáticas
(2, 10, '2024-2025', 7.50), -- Jack en Matemáticas
(2, 30, '2024-2025', 8.00); -- Jack en Física

COMMIT;

-- ============================================================================
-- 5. CONSULTAS DIDÁCTICAS (RECONSTRUCCIÓN DE DATOS MEDIANTE JOINS)
-- ============================================================================

-- Consulta 5.1: Relación 1:1 con LEFT JOIN (Mostrar todos los alumnos tengan o no ficha)
SELECT 
    s.id,
    s.name || ' ' || s.lastname AS alumno_completo,
    s.email,
    COALESCE(c.phone, 'Sin ficha de contacto') AS telefono,
    COALESCE(c.emergency_contact, 'No especificado') AS contacto_emergencia
FROM student s
LEFT JOIN contact_detail c ON s.id = c.student_id;

-- Consulta 5.2: Relación N:M cruzando la tabla puente (Alumnos matriculados por clase)
SELECT 
    s.name AS alumno,
    c.code AS codigo_materia,
    c.title AS materia,
    COALESCE(t.name, 'Sin profesor asignado') AS docente,
    e.academic_year AS curso,
    e.final_grade AS nota_final
FROM student s
JOIN enrollment e ON s.id = e.student_id
JOIN class c ON e.class_id = c.id
LEFT JOIN teacher t ON c.teacher_id = t.id
ORDER BY s.name, c.title;

-- Consulta 5.3: El peligro de COUNT(*) vs COUNT(columna) con LEFT JOIN
-- Demostración: Carlos debe aparecer con 0 entregas, NO con 1.
SELECT 
    s.name AS alumno,
    COUNT(h.id) AS total_entregas_correctas,
    COUNT(*) AS conteo_filas_brutas_erroneo,
    COALESCE(ROUND(AVG(h.mark), 2), 0.00) AS media_calificacion
FROM student s
LEFT JOIN homework_submission h ON s.id = h.student_id
GROUP BY s.id, s.name
ORDER BY total_entregas_correctas DESC;

-- ============================================================================
-- 6. LABORATORIO DE RESTRICCIONES (COMPROBACIÓN DE CASOS PROHIBIDOS)
-- Descomenta cada bloque individualmente para verificar cómo PostgreSQL protege la base de datos
-- ============================================================================

-- CASO A: Violación de Integridad Referencial FK (Alumno inexistente)
-- Esperado: ERROR: insert or update on table "homework_submission" violates foreign key constraint "fk_submission_student"
-- INSERT INTO homework_submission (student_id, title, mark) VALUES (999, 'Tarea Huérfana', 9.5);

-- CASO B: Violación de Relación 1:1 (Intentar dar de alta una segunda ficha médica para Angela)
-- Esperado: ERROR: duplicate key value violates unique constraint "contact_detail_pkey"
-- INSERT INTO contact_detail (student_id, phone, address) VALUES (1, '+34 600 000 000', 'Calle Nueva 4');

-- CASO C: Violación de Clave Compuesta N:M (Intentar matricular a Angela de nuevo en Matemáticas en 2024-2025)
-- Esperado: ERROR: duplicate key value violates unique constraint "enrollment_pkey"
-- INSERT INTO enrollment (student_id, class_id, academic_year) VALUES (1, 10, '2024-2025');

-- CASO D: Violación de Política ON DELETE RESTRICT (Intentar borrar la clase de Matemáticas mientras haya alumnos)
-- Esperado: ERROR: update or delete on table "class" violates foreign key constraint "fk_enrollment_class"
-- DELETE FROM class WHERE id = 10;
