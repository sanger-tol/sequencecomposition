#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
NAME="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}" | cut -d_ -f1)"
METROMAP=metro_map
LOGO=logo
render () {
  nf-metro render "${NAME}_${METROMAP}.mmd" -o "${NAME}_${METROMAP}_$1.svg" --theme "$2" --logo "${NAME}_${LOGO}_$1.png" --no-chrome-css
  cairosvg "${NAME}_${METROMAP}_$1.svg" -o "${NAME}_${METROMAP}_$1.png"
  nf-metro render "${NAME}_${METROMAP}.mmd" -o "${NAME}_${METROMAP}_$1.svg" --theme "$2" --logo "${NAME}_${LOGO}_$1.png"
}
render dark nfcore
render light light
