## Scripts

Repositorio donde invertí horas de automatización en scripts para no hacer tareas manuales durante 10 minutos.

Este repositorio contiene utilidades en forma de scripts. Por ahora incluye un único script:

- **`screenshot-renamer.sh`**: renombra imágenes `.jpg`/`.jpeg` detectando la fecha directamente desde el contenido de la imagen mediante OCR, y genera nombres en el formato `DD-MM-YYYY[_N].ext` (donde `[_N]` se añade automáticamente para evitar colisiones).

### `screenshot-renamer.sh`

- **Qué hace**: 
  - Busca una fecha en la imagen usando Tesseract OCR (ES/EN) y diferentes patrones de fecha (ISO `YYYY-MM-DD`, `DD-MM-YYYY`, `DD de Mes de YYYY`, `Month DD, YYYY`, etc.).
  - Si encuentra una fecha, renombra el archivo como `DD-MM-YYYY.ext`. Si ese nombre ya existe, crea `DD-MM-YYYY_1.ext`, `DD-MM-YYYY_2.ext`, etc.
  - Solo procesa archivos con extensión `.jpg` o `.jpeg`.

- **Requisitos**:
  - `tesseract` (obligatorio)
  - `convert` de ImageMagick (opcional, mejora el preprocesado de la imagen para un OCR más fiable)

- **Uso**:
  - Ayuda rápida: `./screenshot-renamer.sh --help`
  - Procesar todas las imágenes `.jpg/.jpeg` del directorio actual:
    ```bash
    ./screenshot-renamer.sh
    ```
  - Procesar archivos específicos:
    ```bash
    ./screenshot-renamer.sh foto1.jpg otra_carpeta/foto2.jpeg
    ```

- **Instalación/permiso de ejecución**:
  ```bash
  chmod +x screenshot-renamer.sh
  ```

- **Notas**:
  - Si no se detecta fecha en la imagen, el archivo se omite sin cambios.
  - El preprocesado (escala de grises, contraste, afinado y umbral) se aplica cuando `convert` está disponible para mejorar el OCR.

### Demostración

- Antes de ejecutar el script:
  
  ![Antes](./screenshots/before_screenshot_renamer.png)

- Después de ejecutar el script (renombrado por fecha detectada):

  ![Después](./screenshots/after_screenshot_renamer.png)


