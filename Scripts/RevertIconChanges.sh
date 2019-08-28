if [ "${CONFIGURATION}" != "Release" ]; then
IFS=$'\n'
git checkout -- `find "${SRCROOT}/${PRODUCT_NAME}" -name AppIcon.appiconset -type d`
fi
