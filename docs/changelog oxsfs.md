# Changelog `oxsfs.sh`

## v.0.1.7

- DATE: **21/12/2023**
- FEATURES:
  - La carpeta de contenidos `/oxdata/content/sys` pasa a llamarse `/oxdata/content/system_base` y de esta forma encaja con la distribución de archivos `sfs`

## v.0.1.6

- DATE: **21/12/2023**
- FEATURES:
  - Modifica el comando de configuración y activación WiFi
  - Modifica el comando para habilitar la conexión `ssh`

## v.0.1.5

- DATE: **21/12/2023**
- FEATURES:
  - Se elimina la instalación del paquete `zip` puesto que viene por defecto en la distribución
  - Activa el arranque vía SFS por defecto copiando el contenido del `cmdline-overlay.txt` en el `cmdline.txt`

## v.0.1.4

- DATE: **20/12/2023**
- FEATURES:
  - Incluye la configuración del teclado en el idioma detallado en la variable global `keyboard`
  - Incluye la configuración del País detallado en la variable global `language`

## v.0.1.3

- DATE: **20/12/2023**
- FEATURES:
  - Admite los parámetros de entrada `user` y `password` para efectuar el proceso de configuración con un usuario diferente al definido por defecto
  - Crea el usuario siempre que este sea diferente al usuario por defecto
  - Obtiene la información del disco para conocer el tamaño del mismo y crear la partición (definida por defecto) `/oxdata`
  - Se clona la configuración del `.bash_profile` para el usuario `root`
  - Actualiza el sistema operativo
  - Instala los paquetes:
    - squashfs-tools
    - tree
    - python3-pip
    - zip
    - jq
  - Deshabilita el SWAP
  - Crea la estructura de carpeta de los archivos `SFS`
  - Copia los archivos `sfs` ubicados en la carpeta `oxsfs` del USB
  - Borra el histórico de comandos

## Contacto

- Twitter. [**@0xDA_bit**](https://twitter.com/0xDA_bit)
- Github. [**OxDAbit**](https://github.com/OxDAbit)
- Mail. **<oxdabit@protonmail.com>**s
