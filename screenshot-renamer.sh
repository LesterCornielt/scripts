#!/usr/bin/env bash

set -o nounset
set -o pipefail

SCRIPT_NAME="$(basename "$0")"
 

print_usage() {
  echo "Uso: $SCRIPT_NAME [archivo1.png ...]"
  echo "  - Procesa .png del directorio actual si no se pasan archivos."
  echo "  - Extrae la fecha via OCR y renombra: 'DD-MM-YYYY.ext'"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: no se encontró '$1' en el sistema. Instálalo e intenta de nuevo." >&2
    exit 1
  fi
}

if command -v convert >/dev/null 2>&1; then
  HAS_CONVERT=1
else
  HAS_CONVERT=0
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      print_usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Opción no reconocida: $1" >&2
      print_usage
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

# Requerir tesseract (siempre usa OCR)
require_cmd tesseract

# Reunir archivos objetivo
declare -a FILES=()
if [[ $# -gt 0 ]]; then
  for f in "$@"; do
    if [[ -f "$f" ]]; then
      FILES+=("$f")
    fi
  done
else
  while IFS= read -r -d '' f; do
    FILES+=("$f")
  done < <(find . -maxdepth 1 -type f -iname '*.png' -print0)
fi

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "No se encontraron archivos .png para procesar."
  exit 0
fi

normalize_whitespace() {
  sed -E 's/[[:space:]]+/ /g; s/^ +| +$//g'
}

# Preprocesamiento para mejorar OCR (si convert está disponible)
preprocess_image() {
  local input="$1"
  local tmpfile
  tmpfile="$(mktemp --suffix=.png)"
  if [[ "$HAS_CONVERT" -eq 1 ]]; then
    convert "$input" -colorspace Gray -contrast-stretch 0.5%x0.5% -sharpen 0x1 -threshold 60% +repage "$tmpfile" 2>/dev/null || cp -- "$input" "$tmpfile"
  else
    cp -- "$input" "$tmpfile"
  fi
  echo "$tmpfile"
}

# Extraer texto con Tesseract (es/en)
ocr_image() {
  local input="$1"
  tesseract "$input" stdout -l spa+eng --psm 6 2>/dev/null | normalize_whitespace
}

# Mapear meses (ES/EN) a número
month_to_num() {
  local m="$1"
  m="$(echo "$m" | tr '[:upper:]' '[:lower:]')"
  case "$m" in
    jan|january|ene|enero) echo 01 ;;
    feb|february|feb|febrero) echo 02 ;;
    mar|march|marzo) echo 03 ;;
    apr|april|abr|abril) echo 04 ;;
    may|mayo) echo 05 ;;
    jun|june|junio) echo 06 ;;
    jul|july|julio) echo 07 ;;
    aug|august|ago|agosto) echo 08 ;;
    sep|sept|september|septiembre) echo 09 ;;
    oct|october|octubre) echo 10 ;;
    nov|november|noviembre) echo 11 ;;
    dec|december|dic|diciembre) echo 12 ;;
    *) echo "" ;;
  esac
}

# Intentar múltiples patrones de fecha, devolver YYYY-MM-DD
extract_date_iso() {
  local text="$1"
  local candidate

  # 1) ISO: YYYY-MM-DD o YYYY/MM/DD o YYYY.MM.DD
  candidate="$(echo "$text" | grep -Eo '\b[12][0-9]{3}[-./][01]?[0-9][-./][0-3]?[0-9]\b' | head -n1)"
  if [[ -n "$candidate" ]]; then
    candidate="${candidate//\./-}"
    candidate="${candidate//\//-}"
    IFS='-' read -r y m d <<<"$candidate"
    printf "%04d-%02d-%02d" "$((10#$y))" "$((10#$m))" "$((10#$d))"
    return 0
  fi

  # 2) DMY: DD-MM-YYYY o con / .
  candidate="$(echo "$text" | grep -Eo '\b[0-3]?[0-9][-./][01]?[0-9][-./][12][0-9]{3}\b' | head -n1)"
  if [[ -n "$candidate" ]]; then
    candidate="${candidate//\./-}"
    candidate="${candidate//\//-}"
    IFS='-' read -r d m y <<<"$candidate"
    printf "%04d-%02d-%02d" "$((10#$y))" "$((10#$m))" "$((10#$d))"
    return 0
  fi

  # 3) Texto: DD de MES de YYYY (ES)
  candidate="$(echo "$text" | grep -Eo '\b([0-3]?[0-9])[ ]*(de)?[ ]*(Ene(ro)?|Feb(rero)?|Mar(zo)?|Abr(il)?|May(o)?|Jun(io)?|Jul(io)?|Ago(sto)?|Sep(tiembre)?|Oct(ubre)?|Nov(iembre)?|Dic(iembre)?)[ ]*(de)?[ ]*([12][0-9]{3})\b' | head -n1)"
  if [[ -n "$candidate" ]]; then
    local d day monthname y
    day="$(echo "$candidate" | grep -Eo '^[0-3]?[0-9]')"
    monthname="$(echo "$candidate" | grep -Eo '(Ene(ro)?|Feb(rero)?|Mar(zo)?|Abr(il)?|May(o)?|Jun(io)?|Jul(io)?|Ago(sto)?|Sep(tiembre)?|Oct(ubre)?|Nov(iembre)?|Dic(iembre)?)' | head -n1)"
    y="$(echo "$candidate" | grep -Eo '[12][0-9]{3}' | tail -n1)"
    d=$(printf "%02d" "$((10#$day))")
    local m
    m="$(month_to_num "$monthname")"
    if [[ -n "$m" ]]; then
      printf "%04d-%02d-%02d" "$((10#$y))" "$((10#$m))" "$((10#$d))"
      return 0
    fi
  fi

  # 4) Texto EN: Month DD, YYYY o DD Month YYYY
  candidate="$(echo "$text" | grep -Eo '\b((Jan(uary)?|Feb(ruary)?|Mar(ch)?|Apr(il)?|May|Jun(e)?|Jul(y)?|Aug(ust)?|Sep(t)?(ember)?|Oct(ober)?|Nov(ember)?|Dec(ember)?)[ ,]+[0-3]?[0-9][ ,]+[12][0-9]{3}|[0-3]?[0-9][ ]+(Jan(uary)?|Feb(ruary)?|Mar(ch)?|Apr(il)?|May|Jun(e)?|Jul(y)?|Aug(ust)?|Sep(t)?(ember)?|Oct(ober)?|Nov(ember)?|Dec(ember)?)[ ,]+[12][0-9]{3})\b' | head -n1)"
  if [[ -n "$candidate" ]]; then
    local d monthname y
    y="$(echo "$candidate" | grep -Eo '[12][0-9]{3}' | tail -n1)"
    monthname="$(echo "$candidate" | grep -Eo '(Jan(uary)?|Feb(ruary)?|Mar(ch)?|Apr(il)?|May|Jun(e)?|Jul(y)?|Aug(ust)?|Sep(t)?(ember)?|Oct(ober)?|Nov(ember)?|Dec(ember)?)' | head -n1)"
    # Día puede estar al inicio o después del mes
    d="$(echo "$candidate" | grep -Eo '(^| )[0-3]?[0-9](,)?( |$)' | grep -Eo '[0-3]?[0-9]' | head -n1)"
    d=$(printf "%02d" "$((10#$d))")
    local m
    m="$(month_to_num "$monthname")"
    if [[ -n "$m" ]]; then
      printf "%04d-%02d-%02d" "$((10#$y))" "$((10#$m))" "$((10#$d))"
      return 0
    fi
  fi

  return 1
}

# Comprobar si el archivo ya está en formato final: DD-MM-YYYY[_N].png
has_final_name() {
  local name="$1"
  [[ "$name" =~ ^[0-3][0-9]-[01][0-9]-[12][0-9]{3}(_[0-9]+)?\.(png|PNG)$ ]]
}

# Generar nombre destino evitando colisiones
target_name() {
  local dir="$1"; shift
  local ext="$1"; shift
  local date="$1"; shift

  local candidate="$dir/${date}${ext}"
  if [[ ! -e "$candidate" ]]; then
    echo "$candidate"
    return 0
  fi
  local i=1
  while :; do
    candidate="$dir/${date}_$i${ext}"
    [[ ! -e "$candidate" ]] && { echo "$candidate"; return 0; }
    i=$((i+1))
  done
}

process_file() {
  local filepath="$1"
  local dir base ext
  dir="$(dirname -- "$filepath")"
  local filename
  filename="$(basename -- "$filepath")"

  # Separar extensión
  if [[ "$filename" =~ \.(png|PNG)$ ]]; then
    ext=".${filename##*.}"
    base="${filename%.*}"
  else
    echo "Omitiendo (extensión no válida): $filepath"
    return
  fi

  if has_final_name "$filename"; then
    return
  fi

  # OCR del contenido y extracción de fecha
  local tmpimg
  tmpimg="$(preprocess_image "$filepath")"
  local text
  text="$(ocr_image "$tmpimg")"
  rm -f -- "$tmpimg"

  local date_iso
  if ! date_iso="$(extract_date_iso "$text")"; then
    echo "Fecha no encontrada en OCR: $filename"
    return
  fi

  # Definir fecha final en DMY
  local y m d
  IFS='-' read -r y m d <<<"$date_iso"
  local date_dmy
  date_dmy="$(printf "%02d-%02d-%04d" "$((10#$d))" "$((10#$m))" "$((10#$y))")"

  local dest
  dest="$(target_name "$dir" "$ext" "$date_dmy")"

  mv -- "$filepath" "$dest"
}

for f in "${FILES[@]}"; do
  process_file "$f"
done


