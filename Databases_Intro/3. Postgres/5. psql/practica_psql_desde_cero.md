# 🐘 Práctica Guiada: Dominar `psql` desde Cero
### *Sistemas Operativos, Procesos, pgAdmin, Docker, la Nube y la Consola Interactiva*

> *"Para ser un auténtico profesional de las bases de datos no basta con pulsar botones en una ventana gráfica; entender los procesos del sistema operativo y dominar la consola `psql` te da el control total sobre cualquier servidor en el mundo."*

Bienvenido/a a esta guía práctica. Si alguna vez te has preguntado qué ocurre dentro de tu ordenador cuando abres pgAdmin, qué es exactamente un "proceso", por qué existe un programa llamado `psql` que se usa desde una pantalla negra y cómo cambiaría todo si tu base de datos estuviese en un contenedor de Docker o en un servidor en la nube, esta guía responderá a todas esas dudas **desde cero absoluto, sin dar nada por sabido**.

![Consola interactiva de psql](./psql.png)

---

## 📌 Índice de Contenidos

1. [Conceptos Fundamentales del Sistema Operativo (Sin suponer nada previo)](#1-conceptos-fundamentales-del-sistema-operativo)
   - [¿Qué es un Sistema Operativo (OS)?](#11-qué-es-un-sistema-operativo-os)
   - [¿Qué es un Proceso? (Programa vs Proceso)](#12-qué-es-un-proceso-programa-en-disco-vs-proceso-en-memoria)
   - [Procesos en primer plano vs Demonios en segundo plano](#13-procesos-en-primer-plano-vs-demonios-en-segundo-plano-daemons)
   - [Puertos de red: Los timbres de los procesos](#14-puertos-de-red-los-timbres-de-los-procesos)
2. [¿Quién es quién? El Mapa Mental de PostgreSQL](#2-quién-es-quién-el-mapa-mental-de-postgresql)
   - [1. El Motor / Servidor (`postgres`)](#1-el-motor--servidor-de-base-de-datos-postgres)
   - [2. El Cliente CLI (`psql`)](#2-el-cliente-de-terminal-o-cli-psql)
   - [3. El Cliente Gráfico (`pgAdmin`)](#3-el-cliente-gráfico-pgadmin)
   - [4. Aplicaciones externas (Node.js, Python, etc.)](#4-las-aplicaciones-externas-tu-código-de-nodejs)
   - [Diagrama de Arquitectura Cliente-Servidor](#diagrama-de-arquitectura)
3. [¿Cómo saber qué procesos de PostgreSQL corren en tu máquina?](#3-cómo-saber-qué-procesos-de-postgresql-corren-en-tu-máquina)
   - [Comando `ps aux | grep postgres` explicado paso a paso](#comando-ps-aux--grep-postgres)
   - [Comando `pg_isready`](#comando-pg_isready)
   - [Verificar el puerto 5432 con `lsof -i :5432`](#verificar-el-puerto-con-lsof--i-5432)
   - [Comprobarlo visualmente en macOS (Monitor de Actividad)](#comprobarlo-en-el-monitor-de-actividad-de-macos)
4. [¿Cómo se conecta cada cliente? (Local, Docker y la Nube)](#4-cómo-se-conecta-cada-cliente-local-docker-y-la-nube)
   - [Escenario 1: Conexión en tu máquina local (`localhost`)](#escenario-1-conexión-en-tu-máquina-local-localhost)
   - [Escenario 2: PostgreSQL corriendo en un Contenedor Docker](#escenario-2-postgresql-corriendo-en-un-contenedor-docker)
   - [Escenario 3: PostgreSQL en la Nube (AWS, Supabase, Render, Neon)](#escenario-3-postgresql-en-la-nube-aws-supabase-render-neon)
5. [¿Qué es `psql` y por qué es imprescindible?](#5-qué-es-psql-y-por-qué-es-imprescindible)
6. [Cómo entrar a `psql` desde la Terminal de Mac](#6-cómo-entrar-a-psql-desde-la-terminal-de-mac)
   - [Comandos de acceso](#comandos-de-acceso)
   - [¿Qué significa el prompt (`postgres=#` vs `postgres=>`)?](#el-prompt-de-psql)
   - [¡MUY IMPORTANTE! Cómo salir de `psql` (`\q`)](#muy-importante-cómo-salir-de-psql)
7. [Diccionario de Metacomandos Esenciales (`\`)](#7-diccionario-de-metacomandos-esenciales)
8. [🎮 Laboratorio Práctico: Tu Primera Sesión Interactiva en `psql`](#8-laboratorio-práctico-tu-primera-sesión-interactiva-en-psql)
9. [💡 Lo que se extrae de esta práctica (Puntos Clave)](#9-lo-que-se-extrae-de-esta-práctica-puntos-clave)

---

## 1. Conceptos Fundamentales del Sistema Operativo

*(Para entender bases de datos en profundidad, primero debemos entender dónde viven y cómo se ejecutan).*

### 1.1 ¿Qué es un Sistema Operativo (OS)?
Un ordenador físico es solo un conjunto de piezas electrónicas: un procesador (CPU), memoria rápida temporal (RAM), un disco de almacenamiento y tarjetas de red. 

El **Sistema Operativo (OS)** —como **macOS**, **Linux** o **Windows**— es el programa maestro que administra y pone orden entre esas piezas físicas y las aplicaciones que tú usas.
- **Analogía:** Imagina un gran hotel. El hardware son las habitaciones, la cocina y los pasillos. El Sistema Operativo es el **Gerente del Hotel**: decide quién entra, a quién se le asigna cada habitación (memoria RAM), cuánto tiempo puede usar la cocina (CPU) y vigila que ningún huésped interfiera con los demás.

### 1.2 ¿Qué es un Proceso? (Programa en disco vs Proceso en memoria)
- **Un Programa:** Es un archivo inerte guardado en tu disco duro (por ejemplo, el icono de Spotify o los archivos de PostgreSQL instalados). No hace nada hasta que alguien lo abre.
- **Un Proceso:** Es ese programa **en plena acción**, cargado en la memoria RAM y ejecutándose bajo la supervisión de la CPU.
  - Cada proceso que se ejecuta en tu ordenador recibe un número de identificación único asignado por el sistema operativo, llamado **PID** (*Process ID* o Identificador de Proceso).
  - Por ejemplo, si tienes 3 pestañas de Chrome abiertas y un reproductor de música, tu sistema operativo tiene al menos 4 procesos corriendo, cada uno con su propio PID.

### 1.3 Procesos en primer plano vs Demonios en segundo plano (*Daemons*)
1. **Procesos en primer plano (*Foreground*):** Son programas interactivos con los que hablas directamente. Tienen una ventana gráfica (como Google Chrome o pgAdmin) o están ocupando tu terminal mientras escribes. Si cierras la ventana o pulsas `Ctrl + C`, el proceso se detiene.
2. **Procesos en segundo plano / Servicios / Demonios (*Background Processes / Daemons*):** Son programas silenciosos que se inician automáticamente al encender el ordenador y se quedan trabajando de fondo sin abrir ninguna ventana.
   - **PostgreSQL es un demonio:** Cuando instalaste PostgreSQL, se configuró para arrancar discretamente en segundo plano. Aunque no veas ninguna ventana abierta en tu pantalla, el motor de PostgreSQL está vivo en la memoria RAM esperando que alguien le envíe peticiones.

### 1.4 Puertos de red: Los timbres de los procesos
Si tienes 5 programas conectados a Internet o a la red en tu máquina, ¿cómo sabe el ordenador a qué programa le corresponde cada mensaje que llega?
- Mediante los **Puertos**: Un número del 1 al 65535 que funciona como un timbre o número de puerta de apartamento dentro de tu máquina (`localhost`).
- **PostgreSQL tiene reservado por defecto el puerto `5432`**.
- Cuando una aplicación quiere hablar con PostgreSQL, llama a `localhost:5432`.

---

## 2. ¿Quién es quién? El Mapa Mental de PostgreSQL

Uno de los errores más comunes al empezar es confundir **PostgreSQL**, **pgAdmin** y **psql**. Aclaremos sus roles de una vez por todas:

### 1. El Motor / Servidor de Base de Datos (`postgres`)
- **Quién es:** Es el verdadero corazón del sistema. Es el proceso en segundo plano que gestiona los archivos de datos en tu disco, vela por la seguridad, procesa las consultas SQL y escucha en el puerto `5432`.
- **Dato clave:** Él no tiene ventanas con botones bonitos. Solo entiende comandos estructurados que le llegan a través de su conexión.

### 2. El Cliente de Terminal o CLI (`psql`)
- **Quién es:** Es la herramienta oficial de línea de comandos (*Command Line Interface*) incluida con PostgreSQL.
- **Cómo trabaja:** Abres tu terminal, escribes `psql`, y se inicia un proceso ligero que se conecta directamente al motor. Todo lo que escribes viaja en texto directo a PostgreSQL y el resultado se imprime como texto en tu pantalla.
- **Ventaja:** Es ultra rápido, no consume casi memoria y está disponible en el 100% de los servidores del mundo.

### 3. El Cliente Gráfico (`pgAdmin`)
- **Quién es:** Es una aplicación con botones, menús desplegables, árboles de navegación y gráficos.
- **Cómo trabaja en realidad:** pgAdmin **NO** es la base de datos. pgAdmin es un proceso cliente independiente (una aplicación web empaquetada) que se conecta al motor de PostgreSQL exactamente igual que lo hace `psql` o que lo hace tu código de Node.js.
  - Cuando en pgAdmin haces clic derecho en una tabla y eliges *"View/Edit Data"*, pgAdmin construye por debajo la orden `SELECT * FROM tabla;`, se la envía por el puerto `5432` al proceso del motor y dibuja la respuesta en una cuadrícula visual.
  - Además, pgAdmin incluye internamente las herramientas y librerías de cliente de PostgreSQL (entre ellas utilidades basadas en la misma lógica que `psql`).

### 4. Las Aplicaciones Externas (Tu código de Node.js)
- En la práctica anterior ([`World+Capital+Quiz`](file:///Users/fjbanezares/databases_flash_course/Databases_Intro/3.%20Postgres/4.%20select%20in%20postgres/World+Capital+Quiz/)), tu servidor Node.js con la librería `pg` era simplemente **otro cliente más** que abría una conexión al puerto `5432`.

### Diagrama de Arquitectura

```mermaid
graph TD
    subgraph "Clientes (Programas que piden datos)"
        CLI["💻 psql (Consola de comandos)"]
        GUI["🖥️ pgAdmin (Interfaz gráfica)"]
        NODE["🟢 App Web Node.js (Driver 'pg')"]
    end

    subgraph "Sistema Operativo (Tu Máquina, Docker o Cloud)"
        PUERTO["🚪 Puerto 5432 (Socket de Red)"]
        MOTOR["🐘 Proceso Servidor PostgreSQL (postgres engine)"]
        DISCO[("💾 Almacenamiento en Disco")]
    end

    CLI -->|Peticiones SQL texto| PUERTO
    GUI -->|Peticiones SQL visuales| PUERTO
    NODE -->|db.query SELECT...| PUERTO
    PUERTO --> MOTOR
    MOTOR <--> DISCO
```

---

## 3. ¿Cómo saber qué procesos de PostgreSQL corren en tu máquina?

Vamos a usar la terminal para "espiar" lo que tu sistema operativo está haciendo en este preciso instante.

### Comando `ps aux | grep postgres`
Abre tu terminal en Mac y escribe:
```bash
ps aux | grep postgres
```

> **¿Qué significa cada parte de este comando?**
> 1. **`ps` (*Process Status*):** Le pide al Sistema Operativo: *"Dime qué procesos se están ejecutando ahora mismo"*.
> 2. **`aux`:** Son modificadores:
>    - `a`: Muestra los procesos de todos los usuarios.
>    - `u`: Muestra información detallada (usuario propietario, uso de CPU y memoria, PID).
>    - `x`: Incluye procesos que no tienen ventana terminal asociada (los demonios de fondo).
> 3. **`|` (*Pipe* o Tubería):** Uno de los conceptos más brillantes de Unix. Toma la salida del comando de la izquierda y se la pasa directamente como entrada al comando de la derecha.
> 4. **`grep postgres`:** Filtra la enorme lista para mostrar únicamente las líneas que contengan la palabra `"postgres"`.

Si PostgreSQL está en marcha, verás líneas parecidas a esta:
```text
postgres   452   0.0  0.2  ... /Library/PostgreSQL/16/bin/postgres -D /Library/PostgreSQL/16/data
```
Ese número (por ejemplo `452`) es el **PID** del proceso maestro de PostgreSQL.

### Comando `pg_isready`
PostgreSQL incluye una pequeña herramienta diseñada específicamente para comprobar el estado de salud del servidor:
```bash
pg_isready
```
- Si el servidor está activo y funcionando:  
  `localhost:5432 - accepting connections` (Aceptando conexiones con éxito).
- Si el servidor está apagado:  
  `localhost:5432 - no response` (Sin respuesta).

### Verificar el puerto con `lsof -i :5432`
Para comprobar si el proceso que escucha en la "puerta 5432" es realmente PostgreSQL:
```bash
lsof -i :5432
```
Verás claramente que el comando es `postgres`, su `PID` y el estado `LISTEN` (escuchando pacientemente).

### Comprobarlo en el Monitor de Actividad de macOS
Si prefieres verlo con interfaz gráfica:
1. Pulsa `Cmd + Espacio` y escribe **Monitor de Actividad** (*Activity Monitor*).
2. En la pestaña **Memoria** o **CPU**, escribe `postgres` en la barra de búsqueda superior derecha.
3. Verás la lista de procesos con sus respectivos PIDs y consumo de memoria RAM.

---

## 4. ¿Cómo se conecta cada cliente? (Local, Docker y la Nube)

Dependiendo de dónde esté instalado PostgreSQL, la forma en que los clientes se comunican con él cambia ligeramente, pero el protocolo de fondo **siempre es el mismo**.

### Escenario 1: Conexión en tu máquina local (`localhost`)
Es el escenario que tienes configurado actualmente en tu ordenador:
- **Dónde corre el proceso:** Directamente en tu macOS.
- **Parámetros de conexión:**
  - **Host:** `localhost` (o la dirección IP de bucle invertido `127.0.0.1`).
  - **Puerto:** `5432`.
  - **Usuario:** `postgres`.
  - **Contraseña:** Tu clave local.
- **Cómo se conecta pgAdmin:** En el árbol de la izquierda, pgAdmin apunta a `localhost:5432`. Como ambos procesos viven en la misma máquina, la comunicación es instantánea a través de la red local interna.

---

### Escenario 2: PostgreSQL corriendo en un Contenedor Docker

```mermaid
graph LR
    subgraph "Tu Ordenador (Host)"
        PGADMIN["pgAdmin o psql"]
        PORT_HOST["Puerto Local 5432"]
        subgraph "Contenedor Docker (Aislamiento)"
            PORT_CONT["Puerto 5432"]
            PG_DOCKER["🐘 Proceso Postgres"]
        end
    end

    PGADMIN -->|localhost:5432| PORT_HOST
    PORT_HOST -.->|Mapeo de puertos -p 5432:5432| PORT_CONT
    PORT_CONT --> PG_DOCKER
```

#### ¿Qué es Docker?
Imagina que no quieres instalar PostgreSQL directamente en tu Mac para no ensuciar el sistema o porque quieres probar una versión distinta sin riesgos.
- **Docker** te permite ejecutar PostgreSQL dentro de una "caja de zapatos aislada" llamada **Contenedor**.
- El proceso de PostgreSQL corre dentro de esa caja, con sus propios archivos y su propia red interna invisible desde fuera.

#### El puente: Mapeo de Puertos (`-p 5432:5432`)
Para que un programa de tu Mac (como pgAdmin o tu terminal) pueda hablar con ese PostgreSQL aislado, Docker crea un túnel:
```bash
# Ejemplo típico de arranque de Postgres en Docker:
docker run --name mi-postgres -e POSTGRES_PASSWORD=mi_clave -p 5432:5432 -d postgres
```
- La opción **`-p 5432:5432`** significa: *"Conecta el puerto 5432 de mi Mac físico con el puerto 5432 de dentro del contenedor"*.

#### ¿Cómo interactuar con él?
1. **Ver si el contenedor está vivo:**
   ```bash
   docker ps
   ```
   *(Verás el contenedor con su ID, su nombre y los puertos mapeados).*
2. **Entrar a `psql` directamente dentro del contenedor:**
   ```bash
   docker exec -it mi-postgres psql -U postgres
   ```
   - `docker exec`: Ejecuta un comando dentro de un contenedor en marcha.
   - `-it` (*Interactive Terminal*): Abre una sesión interactiva para que puedas escribir con tu teclado dentro del contenedor.
3. **¿Cómo se conecta pgAdmin?**  
   Exactamente igual que en local (`localhost:5432`), porque el mapeo de puertos redirige el tráfico automáticamente hacia el contenedor.

---

### Escenario 3: PostgreSQL en la Nube (AWS, Supabase, Render, Neon)

En entornos de trabajo reales y empresas, la base de datos casi nunca está en el portátil del programador; reside en la **Nube** (*Cloud*), es decir, en potentes servidores de centros de datos de Google Cloud, Amazon Web Services (AWS) o proveedores especializados como Supabase o Neon.

#### ¿Qué cambia al conectarse a la Nube?
1. **El Host ya no es `localhost`:**  
   Ahora es una dirección de dominio pública de Internet. Ejemplo:  
   `db.ref-ejemplo.supabase.co` o `ep-misty-water-12345.us-east-2.aws.neon.tech`.
2. **Cifrado obligatorio (SSL/TLS):**  
   Al viajar por Internet a través de cables intercontinentales y routers públicos, nadie puede enviar contraseñas ni datos en texto plano. Se exige conexión segura mediante certificados SSL (`sslmode=require`).
3. **La Cadena de Conexión (Connection String URI):**  
   En la nube, todos los datos de conexión se empaquetan en una única dirección web estandarizada:
   ```text
   postgresql://usuario:contraseña@servidor-remoto.com:5432/nombre_bd?sslmode=require
   ```

#### ¿Cómo conectarse a la Nube desde `psql`?
Es tan simple como pasarle esa cadena de conexión completa:
```bash
psql "postgresql://postgres:clave_secreta@db.proyecto.supabase.co:5432/postgres?sslmode=require"
```
¡Y listo! Tu terminal local de Mac estará enviando consultas a un servidor situado a miles de kilómetros de distancia.

#### ¿Cómo se conecta pgAdmin a la Nube?
En pgAdmin creas un nuevo Servidor (*Register -> Server*) y en la pestaña **Connection** rellenas:
- **Host name:** `db.proyecto.supabase.co`
- **Port:** `5432`
- **Username:** `postgres`
- **Password:** Tu clave de la nube
- **Pestaña SSL:** Seleccionas `Require` o `Allow`.

---

## 5. ¿Qué es `psql` y por qué es imprescindible?

`psql` es el cliente de terminal oficial suministrado directamente por el equipo de desarrollo de PostgreSQL.

### ¿Por qué aprender `psql` si ya tenemos pgAdmin?
1. **En servidores reales de producción no hay pantallas:**  
   Cuando te conectas por SSH a un servidor Linux en la nube (AWS EC2, DigitalOcean), no hay ratón ni ventanas gráficas; solo hay una pantalla negra. Si no sabes usar `psql`, estás completamente a ciegas.
2. **Velocidad inmediata:**  
   Abrir pgAdmin puede tardar varios segundos en cargar, consumir cientos de megabytes de memoria RAM y requerir clics continuos. `psql` arranca en 0.05 segundos y consume casi 0 recursos.
3. **Automatización y Scripts:**  
   Puedes crear archivos `.sql` y ejecutarlos en bloque desde tu terminal con una sola línea (`psql -U postgres -d world -f script.sql`), ideal para copias de seguridad o despliegues automáticos.

---

## 6. Cómo entrar a `psql` desde la Terminal de Mac

### Comandos de acceso

Abre tu aplicación **Terminal** en macOS.

#### Forma 1: Conexión estándar
```bash
psql -U postgres
```
- **`-U postgres`:** Indica el nombre de usuario (*User*) con el que te identificas.
- Te pedirá la contraseña (la que configuraste al instalar PostgreSQL).  
  *(Nota de seguridad: Mientras tecleas la contraseña en la terminal, no se verán asteriscos ni letras; es una medida de privacidad de Unix. Escríbela normalmente y pulsa Enter).*

#### Forma 2: Especificando la base de datos directamente
```bash
psql -U postgres -d world
```
- **`-d world`:** Se conecta directamente a la base de datos llamada `world` (evitando tener que cambiar luego).

> [!TIP]
> **¿Te sale el error `zsh: command not found: psql`?**  
> Esto ocurre si el instalador de PostgreSQL no añadió la carpeta de comandos a la variable de entorno `PATH` de tu terminal.  
> Puedes ejecutarlo usando su ruta física completa:
> - Si instalaste con el instalador oficial EDB:  
>   `/Library/PostgreSQL/16/bin/psql -U postgres`
> - Si usas Postgres.app:  
>   `/Applications/Postgres.app/Contents/Versions/latest/bin/psql -U postgres`
> - Si instalaste con Homebrew:  
>   `/opt/homebrew/bin/psql -U postgres`

---

### El Prompt de `psql`

Una vez dentro, el aspecto de tu terminal cambiará y verás algo como esto:

```text
postgres=#
```
o si entraste a la base de datos `world`:
```text
world=#
```

#### ¿Qué significa cada símbolo?
1. **La palabra antes del símbolo (`postgres` o `world`):** Es el nombre de la base de datos a la que estás conectado actualmente.
2. **El símbolo `#` (*Almohadilla / Hash*):** Indica que estás conectado como **Superusuario / Administrador** (tienes todos los privilegios para crear, modificar o borrar lo que quieras).
3. **El símbolo `>` (*Mayor que*):** Aparece cuando estás conectado con un usuario estándar con privilegios normales y restringidos (ej: `world=>`).

---

### ¡MUY IMPORTANTE! Cómo salir de `psql`

El problema más habitual de cualquier persona que abre una consola por primera vez es: *"¿Cómo salgo de aquí y regreso a mi terminal normal?"*.

Para salir de `psql` de forma limpia y cerrar la sesión:
```text
\q
```
Escribe `\q` (de *Quit* / Salir) y pulsa **Enter**. Inmediatamente volverás a tu línea de comandos habitual de macOS.

---

## 7. Diccionario de Metacomandos Esenciales

En `psql` existen dos tipos de órdenes:
1. **Consultas SQL estándar:** Como `SELECT * FROM tabla;` o `CREATE TABLE ...;`. **Siempre deben terminar en punto y coma (`;`)**.
2. **Metacomandos internos de `psql`:** Son órdenes propias de la herramienta que **empiezan por una barra invertida (`\`)** y **NO llevan punto y coma**.

Aquí tienes la "chuleta" definitiva que usarás durante toda tu carrera como desarrollador:

| Metacomando | Nombre / Acción | Descripción didáctica |
| :--- | :--- | :--- |
| **`\q`** | **Quit (Salir)** | Cierra la sesión de `psql` y regresa a la terminal del sistema. |
| **`\l`** | **List databases** | Muestra una tabla con todas las bases de datos que existen en este servidor. |
| **`\l+`** | **List databases (detallado)** | Igual que `\l`, pero añade el tamaño físico en disco de cada base de datos y descripción. |
| **`\c nombre_bd`** | **Connect / Change** | Cambia de base de datos activa. Ej: `\c world` te conecta a la base de datos `world`. |
| **`\dt`** | **Describe Tables** | Lista todas las tablas creadas dentro del esquema actual de la base de datos. |
| **`\dt+`** | **Describe Tables (detallado)** | Lista las tablas mostrando además cuánto espacio en disco ocupa cada una. |
| **`\d nombre_tabla`** | **Describe Table Schema** | Inspecciona una tabla en profundidad: muestra sus columnas, tipos de datos (VARCHAR, INT), claves primarias e índices. |
| **`\dn`** | **List Schemas** | Muestra los esquemas disponibles (por defecto verás el esquema `public`). |
| **`\du`** | **List Users / Roles** | Muestra todos los usuarios registrados en PostgreSQL y sus privilegios de administrador. |
| **`\x`** | **Expanded Display (Modo Expandido)** | Alterna entre vista horizontal y vertical. Si una fila tiene 30 columnas, `\x` muestra cada columna en una línea vertical, volviéndolo ultra legible. |
| **`\?`** | **Help Commands** | Abre el manual con todos los metacomandos de barra invertida disponibles. |
| **`\h COMANDO_SQL`** | **Help SQL** | Muestra la sintaxis y opciones de cualquier sentencia SQL (ej: `\h SELECT` o `\h CREATE TABLE`). |
| **`\timing`** | **Toggle Timing** | Activa o desactiva el cronómetro para medir exactamente cuántos milisegundos tarda en responder cada consulta. |
| **`\! comando`** | **Shell Escape** | Ejecuta un comando del sistema operativo Mac sin salir de psql (ej: `\! ls` o `\! clear`). |

---

## 8. 🎮 Laboratorio Práctico: Tu Primera Sesión Interactiva en `psql`

Vamos a realizar un ejercicio práctico completo para familiarizarnos con la terminal de `psql`.

### Paso 1: Conectarte a PostgreSQL
En tu terminal de macOS, ejecuta:
```bash
psql -U postgres
```
Introduce tu contraseña de PostgreSQL y pulsa Enter.

---

### Paso 2: Listar las bases de datos existentes
Una vez dentro del prompt `postgres=#`, escribe:
```text
\l
```
Verás una tabla con las bases de datos de tu sistema (`postgres`, `world`, etc.).  
*(Si la lista es muy larga y se detiene mostrando dos puntos `:`, pulsa la tecla `q` para volver al prompt).*

---

### Paso 3: Crear una base de datos de pruebas
Vamos a crear una base de datos para nuestro experimento llamada `laboratorio`:
```sql
CREATE DATABASE laboratorio;
```
> ⚠️ **¡Recuerda el punto y coma!** Al ser una sentencia SQL, si olvidas el punto y coma y pulsas Enter, `psql` se quedará esperando con `laboratorio-#` hasta que escribas `;` y pulses Enter.

---

### Paso 4: Conectarse a la nueva base de datos
Usa el metacomando `\c`:
```text
\c laboratorio
```
Verás el mensaje de confirmación:
```text
You are now connected to database "laboratorio" as user "postgres".
laboratorio=#
```
Observa cómo el prompt ha cambiado de `postgres=#` a `laboratorio=#`.

---

### Paso 5: Crear una tabla de prueba
Vamos a crear una tabla de personajes aventureros:
```sql
CREATE TABLE aventureros (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    clase VARCHAR(30),
    nivel INT DEFAULT 1,
    oro NUMERIC(10, 2) DEFAULT 0.00
);
```
PostgreSQL responderá:
```text
CREATE TABLE
```

---

### Paso 6: Inspeccionar la estructura con `\dt` y `\d`
1. Comprueba que la tabla existe en la base de datos:
   ```text
   \dt
   ```
   Verás la tabla `aventureros` listada bajo el esquema `public`.

2. Inspecciona su radiografía interna con `\d`:
   ```text
   \d aventureros
   ```
   Aparecerá el desglose detallado de cada columna, sus tipos de datos, valores predeterminados y la clave primaria (`aventureros_pkey`).

---

### Paso 7: Insertar registros
Vamos a poblar la tabla con datos:
```sql
INSERT INTO aventureros (nombre, clase, nivel, oro) VALUES
('Geralt', 'Brujo', 25, 450.50),
('Yennefer', 'Maga', 30, 1200.00),
('Jaskier', 'Bardo', 5, 12.80);
```
Respuesta:
```text
INSERT 0 3
```
*(Indica que se han insertado 3 filas con éxito).*

---

### Paso 8: Consultar los datos con `SELECT`
```sql
SELECT * FROM aventureros;
```
Verás una tabla ASCII formateada en texto:
```text
 id |  nombre  | clase | nivel |   oro   
----+----------+-------+-------+---------
  1 | Geralt   | Brujo |    25 |  450.50
  2 | Yennefer | Maga  |    30 | 1200.00
  3 | Jaskier  | Bardo |     5 |   12.80
(3 rows)
```

---

### Paso 9: Probar el modo expandido con `\x`
Cuando una tabla tiene muchas columnas, las filas se cortan horizontalmente y se vuelven difíciles de leer. El metacomando `\x` soluciona esto:
```text
\x
```
Responderá: `Expanded display is on.`  
Vuelve a ejecutar la misma consulta:
```sql
SELECT * FROM aventureros WHERE nombre = 'Geralt';
```
Ahora la salida se muestra en formato vertical:
```text
-[ RECORD 1 ]--------
id     | 1
nombre | Geralt
clase  | Brujo
nivel  | 25
oro    | 450.50
```
Para desactivarlo y volver a la vista en tabla:
```text
\x
```
*(Responde: `Expanded display is off.`)*.

---

### Paso 10: Limpieza final y Salida
Para dejar tu sistema limpio, borramos la tabla:
```sql
DROP TABLE aventureros;
```
Cambiamos de nuevo a la base de datos principal `postgres`:
```text
\c postgres
```
Eliminamos la base de datos de pruebas:
```sql
DROP DATABASE laboratorio;
```
Y finalmente, **salimos de `psql`**:
```text
\q
```
¡Felicidades! Has ejecutado el ciclo de vida completo de administración de datos directamente desde la línea de comandos.

---

## 9. 💡 Lo que se extrae de esta práctica (Puntos Clave)

<div style="background-color: #f0fdf4; border: 2px solid #22c55e; padding: 22px; border-radius: 8px; margin: 24px 0;">

### 🟢 Conclusiones y Aprendizajes Extraídos

1. **El Motor es un Proceso Independiente:**  
   PostgreSQL es un demonio silencioso que corre en el sistema operativo escuchando peticiones en el puerto `5432`. Ni `pgAdmin` ni `psql` son la base de datos; ambos son **clientes** que le piden cosas a ese motor.

2. **pgAdmin vs psql:**  
   pgAdmin es una aplicación visual orientada a la comodidad en escritorio. `psql` es la herramienta estándar universal en servidores, entornos sin interfaz gráfica y automatización con scripts.

3. **Diferencia entre SQL y Metacomandos:**  
   - Las sentencias **SQL** son universales y terminan obligatoriamente con punto y coma (`;`).
   - Los **metacomandos** de `psql` son órdenes de la consola, empiezan por barra invertida (`\`) y **no** llevan punto y coma (`\l`, `\c`, `\dt`, `\d`, `\q`).

4. **Portabilidad Total (Local, Docker, Cloud):**  
   Ya sea en tu Mac local, dentro de un contenedor Docker aislado (`-p 5432:5432`) o en un clúster en la nube con Supabase/AWS (`sslmode=require`), el protocolo cliente-servidor y el uso de `psql` son exactamente los mismos.

5. **El comando de emergencia:**  
   Recuerda siempre: **`\q`** para salir de `psql` y **`Ctrl + C`** para interrumpir cualquier proceso bloqueado en la terminal.

</div>
