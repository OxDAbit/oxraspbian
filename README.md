# oxraspbian

## Qué es `oxraspbian`?

`oxraspbian` es la distribución debian oficial de **Rasbperry Pi** dónde se monta un _file system_ custom, mediante `overlayFS` que habilita a la **Raspberry Pi** para trabajar en modo "kiosko".

A nivel de disco, el dispositivo se configura con 3 particiones:

1. `boot`. Corresponde a la partición de arranque del dispositivo
2. `rootfs`. Corresponde a la partición del sistema operativo (partición no persistente)
3. `oxdata`. Corresponde a la partición de datos (partición persistente)

En cada arranque, la **Raspberry** montará el `rootfs`, vía `overlayFS`, con los archivos `squashfs` que estarán ubicados en el _path_ `/lib/live/squashfs/`. De esta forma, una vez iniciado el sistema, toda la información que se cree, borre o modifique durante la sesión, no se perderá en el próximo arranque, puesto que el sistema no estará escribiendo en disco.

Con este _file system_ se pretende alargar la vida del disco para aquellos dispositivos que tenemos montados 24/7

## Montaje `oxraspbian`

Guía con el detalle del montaje del sistema operativo _customizado_ desde cero:

> [!IMPORTANT]
> Esta guía así como el uso del _script_ `oxsfs.sh` está validada con la distribución **Debian Bookworm**

> [!NOTE]
> Para esta guía de ejemplo se recurre al uso de una Rapberry Pi 4 con una SSD de 128Gb.

## Grabación imagen en la SSD

1. Descargar la imagen del SO de Raspberry desde la página [web oficial](https://www.raspberrypi.com/software/operating-systems/) (Para esta guía, se utilizará el SO **Raspberry OS Lite 64Gb**)
2. Descargar el programa para _flashear_ la imagen `Balena Etcher`
3. Seleccionar la imagen descargada, el volumen dónde se grabará la imagen e iniciar el proceso
4. Desconectar el disco y volver a conectar al ordenador puesto que al finalizar el proceso de grabación el volumen se desmonta de forma automática
5. Abrir la partición `bootfs` que se montará en el ordenador al volver a conectar la SSD o la SD y editar el archivo `cmdline.txt` eliminando el último parámetro `init=/usr/lib/raspberrypi-sys-mods/firstboot`

> [!CAUTION]
> Es muy importante realizar el último paso antes de iniciar por primera vez el dispositivo se , de lo contrario, la partición correspondiente al `rootfs` se extenderá a todo el disco y el _script_ no podrá crear la tercera partición persistente de datos `/oxdata`

## Primer arranque

Tras grabar la imagen y arrancar por primera vez el dispositivo, el sistema solicitará que selecciones tú idioma y cambies el usuario por defecto insertando uno nuevo.

Tras realizar este paso, el dispositivo ya está preparado para ser configurado vía USB.

## USB Configuración Automática

Con la idea de automatizar todo el proceso de montaje del sistema operativo, se ha creado el _script_ `oxsfs.sh` para que realice las funciones de asistente y se encargue de todo.

Para poder realizar la configuración del sistema desde el USB, se deben seguir los pasos detallados a continuación:

1. Conectar el USB a nuestro ordenador y crear la estructura de carpetas abajo detallada copiando, directamente del repositorio de Github, el contenido de la carpeta [oxusb](https://github.com/OxDAbit/oxraspbian/oxusb)

    ```plaintext
    ├── content                         # Archivos correspondientes a los contenidos de configuración del sistema
    │   └── oxcpu.conf                  # Archivo de configuración genérico
    ├── oxoverlay                       # Archivos para la configuración del FS Overlay
    │   ├── overlayRoot.sh              # Archivo de configuración SFS
    │   └── overlaySFS.sh               # Archivo de configuración SFS
    ├── oxsfs                           # SFS container
    │   └── 01-package.sfs              # Archivo/s SFS que se copiarán tras la configuración del sistema
    └── oxsfs.sh                        # Script que se encarga de ejecutar la configuración
    ```

> [!NOTE]
> Los _scripts_ `overlaySFS.sh`, `overlayRoot.sh` se mantienen actualizados en el repositorio [overlay-Raspbian](https://github.com/OxDAbit/overlay-Raspbian)

2. Abrir el archivo `oxsfs.sh` y modificar las variables globales `wifi_ssid` y `wifi_pswd` para poder establecer la conexión de red correctamente
3. Conectamos el USB a la **Raspberry Pi**
4. Conectamos un teclado y una pantalla al dispositivo para poder efecutar la configuración
5. Nos logamos como usuario `root` y posteriormente creamos una carpeta dónde montar el dispositivo USB:

    ```plaintext
    sudo -s
    mkdir /media/oxusb
    ```

6. Obtenemos la información del USB (en mi caso, llamado `OXUSB`) mediante el comando `blkid` el cual debe devolver una información similiar a la abajo detallada:

    ```plaintext
    /dev/sdb2: LABEL_FATBOOT="OXUSB" LABEL="OXUSB" UUID="3EA3-1A09" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="e2423cef-095d-4ca2-99b0-051dcb9dea81"
    ```

7. Montamos el dispositivo USB en la carpeta `/media/oxusb`

    ```plaintext
    mount /dev/sda2 /media/oxusb/
    ```

> [!TIP]
> Podemos comprobar mediante el uso del comando `df /media/oxusb` que el volumen se ha montado correctamente
>```plaintext
>Filesystem     1K-blocks  Used Available Use% Mounted on
>/dev/sdb2        7411556  1120   7410436   1% /media/oxusb
>```

8. Por último, llega el momento de ejecutar el _script_, el cual tiene 2 tipos de ejecución:
    1. Sin parámetro de configuración. El _script_ realizará la configuración del dispositivo sin habilitar la conexión WiFi (el dispositivo se conectará por ETH):

        ```bash
        cd /media/oxusb
        chmod +x oxsfs.sh
        ./oxsfs.sh
        ```

> [!IMPORTANT]
> Si se selecciona esta opción se debe conectar el dispositivo a internet mediante un cable Ethernet, de lo contrario, el _script_ no podrá realizar la instalación de los paquetes

    2. Con parámetro de configuración. El _script_ realizará la configuración del dispositivo hablitando la conexión WiFi (el dispositivo se podrá conectar por WiFi y por ETH) detallando el _ssid_ y _password_ informados en las variables globales:

        ```bash
        cd /media/oxusb
        chmod +x oxsfs.sh
        ./oxsfs.sh wifi
        ```

> [!NOTE]
> El funcionamiento del _script_ se detalla en el documento [Changelog oxsfs](/docs/changelog%20oxsfs.md)

9. Tras finalizar la ejecución del _script_ el dispositivo se reiniciará para aplicar los cambios y arrancará con el sistema SFS habilitado.

## Gestión modo de arranque `overlayFS`

Para habilitar/deshabiltar el `overlayFS` así como gestionar (crear/borrar/modificar) los archivos SFS se ha documentado toda la información en el documento [overlayFS.md](/docs/overlayFS.md)

## Contacto

- Twitter. [**@0xDA_bit**](https://twitter.com/0xDA_bit)
- Github. [**OxDAbit**](https://github.com/OxDAbit)
- Mail. **<oxdabit@protonmail.com>**
