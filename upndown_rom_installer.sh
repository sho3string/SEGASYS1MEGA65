#!/bin/bash

echo "+-----------------------------------+"
echo "|  Building Up'n Down Arcade ROMs   |"
echo "+-----------------------------------+"

WORKING_DIR=$(pwd)
OUTPUT_PATH="$WORKING_DIR/arcade/upndown"
mkdir -p "$OUTPUT_PATH"

# XOR Table for encryption (saved as binary)
XOR_HEX="08 88 00 80 a0 20 80 00 a8 a0 28 20 88 a8 80 a0
88 80 08 00 28 08 a8 88 88 a8 80 a0 28 08 a8 88
88 a8 80 a0 a0 20 80 00 a8 a0 28 20 a8 a0 28 20
88 80 08 00 88 a8 80 a0 88 a8 80 a0 88 a8 80 a0
a0 20 80 00 a0 20 80 00 08 88 00 80 28 08 a8 88
88 a8 80 a0 88 80 08 00 88 a8 80 a0 28 08 a8 88
88 a8 80 a0 88 a8 80 a0 88 a8 80 a0 88 a8 80 a0
88 80 08 00 88 80 08 00 08 88 00 80 28 08 a8 88"

echo "$XOR_HEX" | xxd -r -p > "$OUTPUT_PATH/xortable.bin"
echo "XOR table dumped"

# CPU ROM build
cat epr5516a.129 epr5517a.130 epr-5518.131 epr-5519.132 > "$OUTPUT_PATH/rom1.bin"
echo "CPU ROM built"

# Non-encrypted ROM
cat epr-5520.133 epr-5521.134 > "$OUTPUT_PATH/rom2.bin"
echo "Non-encrypted ROM copied"

# Sound ROM (same file twice)
cat epr-5535.3 epr-5535.3 > "$OUTPUT_PATH/epr-5535.3"
echo "Sound ROM copied"

# Tile ROMs
for tile in epr-5527.82 epr-5526.65 epr-5525.81 epr-5524.64 epr-5523.80 epr-5522.63; do
    cp "$tile" "$OUTPUT_PATH/"
done
echo "Tile ROMs copied"

# Sprite ROM build (files duplicated)
cat epr-5514.86 epr-5515.93 epr-5514.86 epr-5515.93 > "$OUTPUT_PATH/sprites.bin"
echo "Sprite ROM built"

# Lookup PROM
cp pr-5317.106 "$OUTPUT_PATH/"
echo "Lookup PROM copied"

# Create blank udcfg (filled with 0xFF)
head -c 74 < /dev/zero | tr '\000' '\377' > "$OUTPUT_PATH/udcfg"
echo "Blank udcfg created"

echo "All done!"
