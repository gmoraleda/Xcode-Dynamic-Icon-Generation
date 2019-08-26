
#!/bin/bash

#
# Preflight: Check if tools are installed
#

export MAGICK_HOME="${SRCROOT}/Tools/ImageMagick-7.0.8"

if hash $MAGICK_HOME/bin/identify 2>/dev/null && hash $MAGICK_HOME/bin/convert 2>/dev/null; then
	echo "----------------------------------	"
	echo "ImageMagick already installed ✅		"
	echo "----------------------------------	"
else
	echo "-------------------------------	"
	echo "ImageMagick is not installed💥 	"
	echo "-------------------------------	"
	
	installImageMagick
fi

export PATH="$MAGICK_HOME/bin:$PATH"
export DYLD_LIBRARY_PATH="$MAGICK_HOME/lib/"

#
# Access AppIcon
#
IFS=$'\n'
BASE_ICONS_DIR=$(find ${SRCROOT}/${PRODUCT_NAME} -name "AppIcon.appiconset")
IFS=$' '
CONTENTS_JSON="${BASE_ICONS_DIR}/Contents.json"

#
# Read Read configuration, version and build number
#
version=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${INFOPLIST_FILE}"`
buildNumber=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${INFOPLIST_FILE}"`

caption="${CONFIGURATION}\n${version}\n($buildNumber)"
echo $caption

#
# Generate icons
#
function generateIcons() {
ICON_PATH=$1

width=`identify -format %w ${ICON_PATH}`
[ $? -eq 0 ] || exit 1

height=$((width * 30 / 100))

if [ "${CONFIGURATION}" != "ReleaseProduction" ]; then

width=`identify -format %w ${ICON_PATH}`
height=`identify -format %h ${ICON_PATH}`
band_height=$((($height * 50) / 100))
band_position=$(($height - $band_height))
text_position=$(($band_position - 1))
point_size=$(((14 * $width) / 100))

#
# Band color
#
band_color='rgba(0,0,0,0.8)'

production_configurations=("BetaProduction", "AlphaProduction", "DebugProduction", "ReleaseProduction")
staging_configurations=("BetaStaging", "AlphaStaging", "DebugStaging")


if [[ " ${production_configurations[@]} " =~ "${CONFIGURATION}" ]]; then
	band_color='rgba(224,40,40,0.8)'
fi

#
# Blur band and text
#
convert ${ICON_PATH} -blur 10x8 /tmp/blurred.png
convert /tmp/blurred.png -gamma 0 -fill white -draw "rectangle 0,$band_position,$width,$height" /tmp/mask.png
convert -size ${width}x${band_height} xc:none -fill $band_color -draw "rectangle 0,0,$width,$band_height" /tmp/labels-base.png
convert -background none -size ${width}x${band_height} -pointsize $point_size -fill white -gravity center -gravity South -font ArialNarrowB caption:"$caption" /tmp/labels.png

convert ${ICON_PATH} /tmp/blurred.png /tmp/mask.png -composite /tmp/temp.png

rm /tmp/blurred.png
rm /tmp/mask.png

#
# Compose final image
#
convert /tmp/temp.png /tmp/labels-base.png -geometry +0+$band_position -composite /tmp/labels.png -geometry +0+$text_position -geometry +${w}-${h} -composite "${ICON_PATH}"

#
# Clean up
#
rm /tmp/temp.png
rm /tmp/labels-base.png
rm /tmp/labels.png
fi
}

ICONS=(`grep 'filename' "${CONTENTS_JSON}" | cut -f2 -d: | tr -d ',' | tr -d '\n' | tr -d '"'`)

ICONS_COUNT=${#ICONS[*]}

IFS=$'\n'

for (( i=0; i<ICONS_COUNT; i++ )); do
generateIcons "$BASE_ICONS_DIR/${ICONS[$i]}"
done

#
# Helpers
#
function installImageMagick() {
curl https://imagemagick.org/download/binaries/ImageMagick-x86_64-apple-darwin17.7.0.tar.gz --output imagemagick.tar.gz
mkdir Tools
tar xvzf imagemagick.tar.gz -C Tools/
rm imagemagick.tar.gz
}
