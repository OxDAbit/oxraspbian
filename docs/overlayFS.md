# overlayFS

Squash File System sobre OverlayFS

## Estructura de archivos necesario para montar el `overlayFS`

```plaintext
/
├── boot
│   ├── cmdline-no_overlay.txt      # Configura el arranque sin el OverlayFS
│   └── cmdline-overlay.txt         # Configura el arranque con el OverlayFS
└── sbin
    └── overlayRoot.sh              # SquashFS sobre OverlayFS script
```

## Habilitar / Deshbilitar OverlayFS

Copiar el archivo `cmdline-no_overlay.txt` y `cmdline-overlay.txt` en el _path_ `/boot/`.

Para habilitar o deshabilitar el `overlayFS`

- **Habilitar** OverlayFS:

    ```plaintext
    cp /boot/cmdline-overlay.txt /boot/cmdline.txt
    ```

- **Deshabilitar** OverlayFS:

    ```plaintext
    cp  /boot/cmdline-no_overlay.txt /boot/cmdline.txt
    ```

- Después de modificar el archivo `cmdline.txt` se debe reiniciar el dispositivo para aplicar los cambios mediante el comando `sudo reboot`

## Creación del Squash file

Para esta explicación se parte de la base que el sistema operativo **NO** tiene habilitado el `overlayFS`, por lo que la partición `rootfs` es persistente.
Para este ejemplo se han creado 3 archivos de tst los cuales están localizados en los _path_ `/home` y `/etc`.

1. Crear una carpeta temporal en el _path_ `/home/user`:

    ```plaintext
    sudo -s
    mkdir /home/user/squahsfs_tmp
    ```

2. Dentro de la carpeta temporal, se crean 2 nuevas carpetas:

    ```plaintext
    cd /home/user/squahsfs_tmp
    mkdir etc
    mkdir home
    ```

3. Creamos varios archivos _mock_ para hacer la prueba:

    ```plaintext
    touch etc/hello_etc
    touch home/home_file_01
    touch home/home_file_02
    ```

4. Una vez creados/modificados/borrados los archivos, se creará el archivo `sfs`:

    ```plaintext
    cd ..                                               # Estamos ubiados en el path /home/user
    squashfs squahsfs_tmp file_system.sfs -comp xz      # Crea el archivo SFS file_system.sfs
    ```

    El comando detallo genera el archivo `sfs` `file_system.sfs` el cual contendrá la información que hay en la carpeta temporal `squashfs_tmp` creada anteriormente.

5. La ubicación de los archivos `sfs` para que los monté posteriormente en el sistema operativo es el _path_ `/lib/live/squashfs`, por lo que el archivo generado se debe copiar allí.

    ```plaintext
    mv /home/user/squahsfs_tmp /lib/live/squashfs
    ```

6. Eliminamos la carpeta **squasfs_tmp**

    ```plaintext
    rm -rf /home/user/squashfs_tmp
    ```

7. Habilitamos el overlayFS

    ```plaintext
    cp /boot/cmdline-overlay.txt /boot/cmdline.txt
    ```

8. Reiniciamos el sistema para que se monte el `sfs`

    ```plaintext
    reboot
    ```

9. Si todo ha funcionado correctamente, se deben mostrar los archivos creados anteriormente tal y como se detalla a continuación:

    ```plaintext
    ls /home
     ├── home_file_01
     ├── home_file_02
     └── other /home files...

    ls /etc
     ├── hello_etc
     └── other /etc files...
    ```

## Actualizar Squash file

Para actualizar un archivo `sfs` ya existente:

1. Reiniciamos el dispositvo deshabilitando el `overlayFS`

    ```plaintext
    sudo -s
    cp  /boot/cmdline-no_overlay.txt /boot/cmdline.txt
    reboot
    ```

2. Accdemos al _path_ `/lib/live/squashfs`

    ```plaintext
    sudo -s
    cd /lib/live/squashfs
    ```

3. Desomprimimos el archivo `sfs` llamado **file_system.sfs**

    ```plaintext
    unsquashfs -f file_system.sfs
    ```

    Tras ejecutar el comando, se crea una carpeta llamada **squashfs-root** con todo el contenido del archivo `sfs`

    ```plaintext
    /lib/live/squashfs
      ├── file_sytem.sfs
      └── squashfs-root
    ```

4. Modicamr/crear/eliminar el archivo que se desee dentro de la carpeta **squashfs-root** (por ejemplo, se eliminará el archivo **home_file_02**):

    ```plaintext
    rm -rf squashfs-root/home/home_file_02
    ```

5. Eliminamos el archivo `sfs` orginal **file_system.sfs**

    ```plaintext
    rm -rf file_system.sfs
    ```

6. Creamos el archivo _sfs_ nuevamente con los cambios aplicados

    ```plaintext
    squashfs squashfs-root file_system.sfs -comp xz
    ```

7. Modificamos el `cmdline.txt` par habilitar el `overlayFS`

    ```plaintext
    cp /boot/cmdline-overlay.txt /boot/cmdline.txt
    ```

8. Reiniciamos el dispositivo para que aplique los cambios

    ```plaintext
    reboot
    ```

Otra forma de modificar los archivos `sfs` sin necesidad de habilitar/deshabilitar el `overlayFS` es la detallada a continuación:

1. Se remonta la partición de RO a RW

    ```plaintext
    sudo -s
    mount -o remount,rw /lib/live/mounted/ro
    ```

2. Accedemos a la carpeta **squashfs** del directorio persistente, puesto que el sistema operativo se ha montado con `overlayFS`

    ```plaintext
    cd /lib/live/mounted/ro/lib/live/squashfs
    ```

3. Repetir los pasos anterior del punto 3 al punto 8

## Contacto

- Twitter. [**@0xDA_bit**](https://twitter.com/0xDA_bit)
- Github. [**OxDAbit**](https://github.com/OxDAbit)
- Mail. **<oxdabit@protonmail.com>**
