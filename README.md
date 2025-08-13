## Scripts

Language/Idioma/Idioma:
- Español: Este README está en inglés. Si prefieres otro idioma, cambia a la rama `es` (Español) o `pt` (Português).
- English: This README is in English. If you prefer another language, switch to branch `es` (Español) or `pt` (Português).
- Português: Este README está em inglês. Se preferir outro idioma, mude para a branch `es` (Español) ou `pt` (Português).

A repo where I spent hours automating tasks so I don't have to do 10 minutes of manual work.

This repository contains utility scripts. For now, it includes a single script:

- **`screenshot-renamer.sh`**: renames `.jpg`/`.jpeg` images by detecting the date directly from the image content via OCR, and generates names in the format `DD-MM-YYYY[_N].ext` (where `[_N]` is added automatically to avoid collisions). I built it so I don't have to manually rename every screenshot of my gym logs where I track workout-by-workout progress.

### `screenshot-renamer.sh`

- **What it does**:
  - Looks for a date in the image using Tesseract OCR (ES/EN) and different date patterns (ISO `YYYY-MM-DD`, `DD-MM-YYYY`, `DD de Mes de YYYY`, `Month DD, YYYY`, etc.).
  - If a date is found, it renames the file as `DD-MM-YYYY.ext`. If that name already exists, it creates `DD-MM-YYYY_1.ext`, `DD-MM-YYYY_2.ext`, etc.
  - Only processes files with `.jpg` or `.jpeg` extension.

- **Requirements**:
  - `tesseract` (required)
  - `convert` from ImageMagick (optional, improves image preprocessing for more reliable OCR)

- **Usage**:
  - Quick help: `./screenshot-renamer.sh --help`
  - Process all `.jpg/.jpeg` images in the current directory:
    ```bash
    ./screenshot-renamer.sh
    ```
  - Process specific files:
    ```bash
    ./screenshot-renamer.sh foto1.jpg otra_carpeta/foto2.jpeg
    ```

- **Installation/execution permission**:
  ```bash
  chmod +x screenshot-renamer.sh
  ```

- **Notes**:
  - If no date is detected in the image, the file is left unchanged.
  - Preprocessing (grayscale, contrast, sharpening and threshold) is applied when `convert` is available to improve OCR.

### Demo

- Before running the script:
  
  <img src="./screenshots/before_screenshot_renamer.png" alt="Before" width="420" />

- After running the script (renamed by detected date):

  <img src="./screenshots/after_screenshot_renamer.png" alt="After" width="420" />

