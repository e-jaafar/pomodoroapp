#!/bin/bash
# Script pour créer une icône simple avec un emoji tomate

ICONSET_DIR="/Users/jaafarito/Desktop/taff:ecole/pomodoroapp/AppIcon.iconset"
RESOURCES_DIR="/Users/jaafarito/Desktop/taff:ecole/pomodoroapp/Pomodoro.app/Contents/Resources"

# Tailles requises pour icns
sizes=(16 32 64 128 256 512)

for size in "${sizes[@]}"; do
    # Créer une image avec le texte emoji
    convert -size ${size}x${size} xc:'#E74C3C' \
        -gravity center \
        -fill white \
        -font "Apple Color Emoji" \
        -pointsize $((size * 6 / 10)) \
        -annotate +0+0 "🍅" \
        "$ICONSET_DIR/icon_${size}x${size}.png" 2>/dev/null
    
    # Version @2x
    double=$((size * 2))
    convert -size ${double}x${double} xc:'#E74C3C' \
        -gravity center \
        -fill white \
        -font "Apple Color Emoji" \
        -pointsize $((double * 6 / 10)) \
        -annotate +0+0 "🍅" \
        "$ICONSET_DIR/icon_${size}x${size}@2x.png" 2>/dev/null
done

# Convertir en icns
iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns" 2>/dev/null

echo "Done"
