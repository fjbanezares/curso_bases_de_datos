# Guía de Supervivencia: Instalación y Problemas Típicos de MySQL (macOS, Linux y Windows)

Esta guía documenta los errores más frecuentes al instalar y configurar **MySQL Community Server** por primera vez, por qué ocurren y cómo solucionarlos paso a paso en los tres sistemas operativos principales.

---

## 1. Antes de instalar en Mac: Arquitectura Intel (x86_64) vs. Apple Silicon (ARM64)

Cuando descargas el instalador oficial `.dmg` desde la web de Oracle para macOS, verás dos opciones muy parecidas:
* **macOS 14/15 (ARM, 64-bit), DMG Archive** -> Para chips **Apple Silicon** (M1, M2, M3, M4...).
* **macOS 14/15 (x86, 64-bit), DMG Archive** -> Para procesadores **Intel** (Macs antiguos, generalmente anteriores a finales de 2020).

### ¿Cómo saber cuál es tu Mac para acertar a la primera?
1. Haz clic en el icono de la manzana **** (esquina superior izquierda) > **Acerca de este Mac**.
2. Fíjate en la primera línea debajo del nombre del ordenador:
   * Si dice **Chip: Apple M1 / M2 / M3 / M4**, debes descargar la versión **ARM, 64-bit**.
   * Si dice **Procesador: Intel Core i5 / i7 / i9**, debes descargar la versión **x86, 64-bit**.
3. *Alternativa por Terminal:* Ejecuta `uname -m`. Si devuelve `arm64`, necesitas ARM. Si devuelve `x86_64`, necesitas Intel.

### ¿Qué pasa si te equivocas de arquitectura al descargar?
* **Si tienes un Mac con chip M1/M2/M3/M4 e instalas la versión Intel (x86_64):**
  * Si no tienes instalado el traductor *Rosetta 2* de Apple, el instalador fallará o el servidor ni siquiera arrancará (`Bad CPU type in executable`).
  * Si tienes *Rosetta 2*, MySQL se instalará y funcionará de forma "emulada", pero **perderás mucho rendimiento**, consumirá más batería/RAM y tendrás problemas de incompatibilidad más adelante cuando intentes conectar lenguajes de programación (como librerías nativas de Python, Node.js o PHP compiladas para ARM) con las librerías cliente de MySQL en x86.
* **Si tienes un Mac Intel e instalas la versión ARM (Apple Silicon):**
  * Directamente no funcionará. macOS bloqueará el instalador o la Terminal devolverá un error de arquitectura incompatible, ya que un procesador Intel no puede ejecutar código ARM64.

---

## 2. Error de contraseña temporal: `ERROR 1820 (HY000)`

### El síntoma
Al instalar MySQL, el asistente genera una contraseña temporal aleatoria y dificilísima (por ejemplo: `_yatH;t&6&xj`). Logras entrar a la consola de MySQL (`mysql>`), pero al intentar ejecutar cualquier comando como `SHOW DATABASES;` aparece esto:

```sql
mysql> show databases;
ERROR 1820 (HY000): You must reset your password using ALTER USER statement before executing this statement.
```

### ¿Por qué ocurre y qué implica?
Por motivos de seguridad, desde MySQL 5.7 y 8.0+, el instalador crea el usuario `root` con una contraseña caducada de un solo uso. **Implica que tu sesión está en "modo cuarentena"**: estás dentro del servidor, pero MySQL bloquea absolutamente cualquier consulta o acción hasta que establezcas tu propia contraseña definitiva.

### Cómo solucionarlo ahora mismo
Sin salir de esa pantalla donde tienes el prompt `mysql>`, ejecuta el siguiente comando cambiando `TuNuevaPassword123!` por la contraseña que tú quieras conservar:

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'TuNuevaPassword123!';
```

*(Nota: No olvides el punto y coma `;` al final de la línea y pulsa Enter).*

Si todo ha ido bien, responderá `Query OK, 0 rows affected`. A partir de ese exacto segundo, tu contraseña vieja (`_yatH;t&6&xj`) deja de existir, ya tienes permisos completos y puedes probar a escribir:

```sql
SHOW DATABASES;
```

> **⚠️ Qué implica para el futuro:**
> 1. La próxima vez que entres desde la terminal con `mysql -u root -p`, tendrás que usar tu nueva contraseña.
> 2. Si usas programas visuales como **MySQL Workbench**, **DBeaver** o conectas una aplicación web, esa nueva contraseña será la que debas poner en la configuración.

---

## 3. El servidor está apagado: `ERROR 2002 (HY000)`

### El síntoma
Intentas conectarte desde la terminal y recibes un error diciendo que no puede conectarse a través del *socket* o del puerto local:
* **macOS / Linux:** `ERROR 2002 (HY000): Can't connect to local MySQL server through socket '/tmp/mysql.sock' (2)` (o `/var/run/mysqld/mysqld.sock`).
* **Windows:** `ERROR 2003 (HY000): Can't connect to MySQL server on 'localhost:3306' (10061)`.

### ¿Por qué ocurre?
El comando `mysql` es solo el **cliente** (la interfaz de texto). Este error indica que el **servidor** en segundo plano (`mysqld`, el motor de la base de datos) está detenido. Cuando el servidor está apagado, el archivo temporal de comunicación (`mysql.sock`) no existe.

### Cómo encender el servidor según tu Sistema Operativo

#### En macOS
* **Método Gráfico:** Abre **Ajustes del Sistema** > baja del todo hasta **MySQL** > haz clic en **Start MySQL Server** para que el indicador pase de rojo a verde.
* **Por Terminal (Instalador oficial DMG):**
  ```bash
  sudo /usr/local/mysql/support-files/mysql.server start
  ```
* **Por Terminal (Si se instaló con Homebrew):**
  ```bash
  brew services start mysql
  ```

#### En Linux (Ubuntu / Debian / RedHat / CentOS)
En Linux el servicio se gestiona mediante `systemd`. Abre la terminal y ejecuta:
```bash
# Iniciar el servidor (en Ubuntu/Debian suele llamarse mysql, en RedHat/Fedora mysqld)
sudo systemctl start mysql

# Hacer que arranque automáticamente cada vez que enciendas el PC
sudo systemctl enable mysql

# Comprobar si está encendido (debe decir "active (running)" en verde)
sudo systemctl status mysql
```

#### En Windows
* **Método Gráfico:**
  1. Pulsa `Win + R`, escribe `services.msc` y pulsa Enter.
  2. Busca en la lista un servicio llamado **MySQL80** (o **MySQL** seguido del número de versión).
  3. Haz clic derecho sobre él y selecciona **Iniciar**.
* **Por Terminal (CMD o PowerShell abierto como Administrador):**
  ```cmd
  net start MySQL80
  ```

---

## 4. Pérdida de permisos en la carpeta de datos (El servidor se apaga solo)

### El síntoma
Le das a "Iniciar" al servidor de MySQL, parece que va a arrancar, pero al cabo de 1 o 2 segundos se vuelve a apagar solo, o la terminal escupe este error clásico:
`ERROR! The server quit without updating PID file (/usr/local/mysql/data/tu-ordenador.pid).`

### ¿Por qué ocurre?
Por seguridad, el motor de MySQL **nunca** se ejecuta con el usuario administrador (`root` del sistema) ni con tu usuario personal, sino con un usuario interno restringido del sistema operativo (llamado `_mysql` en macOS, `mysql` en Linux y `NetworkService` en Windows).

Si por una actualización del sistema operativo, una restauración de copia de seguridad o haber ejecutado un comando manual con `sudo`, la carpeta donde se guardan las bases de datos (`data`) pasa a pertenecer a tu usuario o a `root`, el usuario interno de MySQL no tiene permiso para escribir ahí su archivo de encendido (`.pid`) y se apaga por precaución.

### Cómo reparar los permisos en cada Sistema Operativo

#### En macOS
En macOS el usuario y grupo internos llevan un guion bajo delante (`_mysql`). Ejecuta en la Terminal:
```bash
sudo chown -R _mysql:_mysql /usr/local/mysql/data
sudo chmod -R 750 /usr/local/mysql/data
```

#### En Linux
En distribuciones como Ubuntu, Debian o CentOS, los datos viven en `/var/lib/mysql` y el usuario se llama `mysql` (sin guion bajo):
```bash
sudo chown -R mysql:mysql /var/lib/mysql
sudo chmod -R 750 /var/lib/mysql
```

#### En Windows
En Windows la carpeta de datos está oculta por defecto en `C:\ProgramData\MySQL\MySQL Server 8.0\Data`.
1. Abre una ventana de **Símbolo del sistema (CMD) como Administrador**.
2. Otorga permisos completos al servicio de red sobre la carpeta de datos con `icacls`:
   ```cmd
   icacls "C:\ProgramData\MySQL\MySQL Server 8.0\Data" /grant "NETWORK SERVICE":(OI)(CI)F /T
   ```
   *(También puedes hacerlo gráficamente: entra en `C:\ProgramData\MySQL\MySQL Server 8.0`, clic derecho en la carpeta `Data` > Propiedades > Seguridad > Editar > Añadir permisos de Control Total al usuario `NETWORK SERVICE` o ` Administradores`).*

---

## 5. Configurar el `PATH` (Para no escribir la ruta completa cada vez)

Para poder abrir la terminal y escribir directamente `mysql -u root -p` sin tener que teclear toda la ruta de carpetas (`/usr/local/mysql/bin/...`):

* **En macOS (Terminal Zsh por defecto):**
  ```bash
  echo 'export PATH="/usr/local/mysql/bin:$PATH"' >> ~/.zshrc
  source ~/.zshrc
  ```
* **En Linux:**
  Normalmente al instalar con `apt` o `dnf` se configura solo en `/usr/bin/mysql`. Si instalaste un binario manual en `/usr/local/mysql`:
  ```bash
  echo 'export PATH="/usr/local/mysql/bin:$PATH"' >> ~/.bashrc
  source ~/.bashrc
  ```
* **En Windows:**
  1. Pulsa la tecla Windows y escribe **"Variables de entorno"**.
  2. Entra en *Editar las variables de entorno del sistema* > botón **Variables de entorno...**
  3. En la sección inferior (*Variables del sistema*), busca la variable **Path** y dale a **Editar**.
  4. Haz clic en **Nuevo** y pega la ruta de tu carpeta `bin` (por defecto: `C:\Program Files\MySQL\MySQL Server 8.0\bin`).
  5. Acepta todo, cierra tu ventana de CMD/PowerShell y abre una nueva para que surta efecto.