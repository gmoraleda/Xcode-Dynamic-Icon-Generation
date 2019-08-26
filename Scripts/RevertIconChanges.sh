if [ "${CONFIGURATION}" != "ReleaseProduction" ]; then
IFS=$'\n'
git checkout -- `find "${SRCROOT}/${PRODUCT_NAME}" -name AppIcon.appiconset -type d`
fi