#!/usr/bin/env bash

################################################################################
# Build a macOS Installer.
#
# Although CMake generates macOS installers, it's kind of inflexible and sucks
#   a little bit. We can do better, as well as sign and notarize the image as
#   well.
#
# This script tries to be flexible enough to run from both Github Actions'
#   environment as well as in the local environment. Note that the assumption
#   both locally and in Github is that tidy-html5 and tidy-mac-installer are
#   siblings in the filesystem. No checks are performed to ensure that this
#   is the case.
################################################################################


#---------------------------------------------------------------------
# Get our base directories in the filesystem.
#---------------------------------------------------------------------

DIR_PWD="${GITHUB_WORKSPACE:-$(dirname $(pwd))}"
DIR_TIDY="${DIR_PWD}/tidy-html5"
DIR_DIMG="${DIR_PWD}/tidy-mac-installer"

if [ ! -d "${DIR_TIDY}" ] || [ ! -d "${DIR_DIMG}" ]; then
    echo "One or more expected base project directories is missing or malnamed:"
    echo " -> ${DIR_TIDY}"
    echo " -> ${DIR_DIMG}"
    exit 1
fi

if [[ -z "${MACOS_PRODUCTSIGN_ID}" ]]; then
    echo "The environment variable MACOS_PRODUCTSIGN_ID needs to be set, and it's not."
    echo "It should look something like 'Developer ID Installer: Bob Marley'."
    exit 1
fi

if [[ -z "${MACOS_CODESIGN_ID}" ]]; then
    echo "The environment variable MACOS_CODESIGN_ID needs to be set, and it's not."
    echo "It should look something like 'Developer ID Application: Bob Marley'."
    exit 1
fi

if [[ -z "${APPLE_ID}" ]]; then
    echo "The environment variable APPLE_ID needs to be set, and it's not."
    echo "It should look something like 'toad@mac.com'."
    exit 1
fi

if [[ -z "${APPLE_APP_SPECIFIC_PASSWORD}" ]]; then
    echo "The environment variable APPLE_APP_SPECIFIC_PASSWORD needs to be set, and it's not."
    echo "It should look something like 'watr-huis-bier-kant'."
    exit 1
fi


#---------------------------------------------------------------------
# We'll use the following Tidy versions a few times throughout.
#---------------------------------------------------------------------

VERSION_TIDY=$(head -1 "${DIR_TIDY}/version.txt")
VERSION_MAJOR=$(echo "${VERSION_TIDY}" | awk -F \. {'print $1'})

echo "Tidy Version is ${VERSION_TIDY}, major version ${VERSION_MAJOR}."


#---------------------------------------------------------------------
# Build the executable and libraries.
#---------------------------------------------------------------------

cd "${DIR_TIDY}/build/cmake"

cmake ../.. -DCMAKE_BUILD_TYPE=Release '-DCMAKE_OSX_ARCHITECTURES=x86_64;arm64'
cmake --build . --config Release


#---------------------------------------------------------------------
# Prepare build directory: system root
#   Note: the cp on libtidy.dylib will either copy the target if it's
#     a link, or the file itself if it's not. In either case, we get
#     the correct file. CMake seems to vary on local vs. Github.
#---------------------------------------------------------------------

cd "${DIR_DIMG}"

rm -rf "build"

mkdir -p "build/system_root/usr/local/bin"
mkdir -p "build/system_root/usr/local/lib"
mkdir -p "build/system_root/usr/local/share/man/man1"

cp "${DIR_TIDY}/build/cmake/tidy"          "build/system_root/usr/local/bin/"
cp "${DIR_TIDY}/build/cmake/libtidy.dylib" "build/system_root/usr/local/lib/libtidy.${VERSION_TIDY}.dylib"
cp "${DIR_TIDY}/build/cmake/libtidy.a"     "build/system_root/usr/local/lib/"
cp "${DIR_TIDY}/build/cmake/tidy.1"        "build/system_root/usr/local/share/man/man1/"


#---------------------------------------------------------------------
# These have to be signed if we want to notarize.
#---------------------------------------------------------------------

codesign -f -s "${MACOS_CODESIGN_ID}" \
    --options runtime \
    "build/system_root/usr/local/bin/tidy"

codesign -f -s "${MACOS_CODESIGN_ID}" \
    "build/system_root/usr/local/lib/libtidy.${VERSION_TIDY}.dylib"

codesign -f -s "${MACOS_CODESIGN_ID}" \
    "build/system_root/usr/local/lib/libtidy.a"


#---------------------------------------------------------------------
# Prepare build directory: Scripts
#---------------------------------------------------------------------

cd "${DIR_DIMG}"

mkdir "build/Scripts"

cp "source/Scripts/Tidy README.rtf" "build/Scripts/"

sed "s/@@VERSION@@/${VERSION_TIDY}/g; s/@@VERS_MAJOR@@/${VERSION_MAJOR}/g" \
    "source//Scripts/postinstall.in" \
    > "build/Scripts/postinstall" 
    
chmod +x "build/Scripts/postinstall"


#---------------------------------------------------------------------
# Build "Tidy Quick Reference.html" and add it to Scripts.
#---------------------------------------------------------------------

cd "${DIR_TIDY}/build/cmake"

XSL_FILE="${DIR_DIMG}/source/quickref.xsl"
CFG_FILE="${DIR_DIMG}/source/quickref.cfg"
OUT_FILE="${DIR_DIMG}/build/Scripts/Tidy Quick Reference.html"

./tidy -xml-config > "tidy-config.xml"
xsltproc "${XSL_FILE}" "tidy-config.xml" > "${OUT_FILE}"
./tidy -quiet -config "${CFG_FILE}" -modify "${OUT_FILE}" >& /dev/null


#---------------------------------------------------------------------
# Prepare build directory: Resources
#   Update Localizable.strings with version information. Note that we
#   must use iconv on the .strings file because macOS requires this
#   to be UTF-16LE for some reason.
#---------------------------------------------------------------------

cd "${DIR_DIMG}"

cp -R "${DIR_DIMG}/source/Resources" "${DIR_DIMG}/build/"

iconv -f utf-16 -t utf-8 < "${DIR_DIMG}/build//Resources/en.lproj/Localizable.strings.in" \
    | sed "s/@@ITDY_VERSION_STRING@@/HTML Tidy ${VERSION_TIDY}/" \
    | iconv -f utf-8 -t utf-16 \
    > "${DIR_DIMG}/build//Resources/en.lproj/Localizable.strings"

rm "${DIR_DIMG}/build/Resources/en.lproj/Localizable.strings.in"


#---------------------------------------------------------------------
# Build the component package.
#---------------------------------------------------------------------

mkdir -p "${DIR_DIMG}/build/packages"

pkgbuild \
    --root "${DIR_DIMG}/build/system_root" \
    --scripts "${DIR_DIMG}/build/Scripts" \
    --identifier com.balthisar.pkg.TidyCommandLine \
    --version ${VERSION_TIDY} \
    "${DIR_DIMG}/build/packages/HTML_Tidy.pkg"


#---------------------------------------------------------------------
# Build and sign the product package.
#---------------------------------------------------------------------

mkdir -p "${DIR_DIMG}/build/dmg_contents"

productbuild \
    --distribution "${DIR_DIMG}/source//Distribution.xml" \
    --package-path "${DIR_DIMG}/build/packages" \
    --resources "${DIR_DIMG}/build/Resources" \
    "${DIR_DIMG}/build/dmg_contents/unsigned.pkg"

/usr/bin/productsign \
    -s "${MACOS_PRODUCTSIGN_ID}" \
    "build/dmg_contents/unsigned.pkg" \
    "build/dmg_contents/Install HTML Tidy.pkg"

rm "build/dmg_contents/unsigned.pkg"


#---------------------------------------------------------------------
# Build the background image.
#   Note: if necessary, brew install ImageMagick and libmagic.
#---------------------------------------------------------------------

cd "${DIR_DIMG}"

convert \
    -background none  \
    -fill '#d91e1e' \
    -font 'Arial-Black' \
    -pointsize 42 \
    label:"version ${VERSION_TIDY}" \
    miff:- | \
composite \
    -geometry +825+152 - \
    "source/dmg_background.png" \
    "build/dmg_background.png"


#---------------------------------------------------------------------
# Start working on building the disk image.
#   Note: if necessary, make sure you do brew install create-dmg.
#---------------------------------------------------------------------

cd "${DIR_DIMG}"
mkdir -p "build/artifacts"

FILE_IMAGE="${DIR_DIMG}/build/artifacts/tidy-${VERSION_TIDY}-macos-x86_64+arm.dmg"

create-dmg \
    --volname "HTML Tidy for macOS" \
    --background "build/dmg_background.png" \
    --window-pos 200 120 \
    --window-size 640 512 \
    --icon-size 164 \
    --icon "Install HTML Tidy.pkg" 320 240 \
    --no-internet-enable \
    "${FILE_IMAGE}" \
    "build/dmg_contents/"
    

#---------------------------------------------------------------------
# Sign the disk image.
#---------------------------------------------------------------------

xcrun codesign \
    -f -s "${MACOS_CODESIGN_ID}" \
    "${FILE_IMAGE}"


#---------------------------------------------------------------------
# Perform the notarization process.
#---------------------------------------------------------------------

UUID=$( \
    xcrun altool \
        --notarize-app \
        --primary-bundle-id org.htacg.html-tidy.tidy5 \
        -u "${APPLE_ID}" \
        -p "${APPLE_APP_SPECIFIC_PASSWORD}" \
        --file "${FILE_IMAGE}" 2>&1 |
        grep 'RequestUUID' |
        awk '{ print $3 }'
)
echo "UUID: ${UUID}"
sleep 30

while : ; do
    NOTARY_STATUS=$(xcrun altool -u "${APPLE_ID}" -p "${APPLE_APP_SPECIFIC_PASSWORD}" --notarization-info "${UUID}" 2>&1)
    STATUS=$(echo "$NOTARY_STATUS" | grep 'Status\:' | awk '{ print $2 }')
    if [ "$STATUS" = "success" ]; then
        xcrun stapler staple "${FILE_IMAGE}"
        xcrun stapler validate -v "${FILE_IMAGE}"
        echo "Notarized successfully."
        break
    elif [ "$STATUS" = "in" ]; then
        echo "Notarization in progress."
        sleep 30
    else
        echo "Notarization failed:"
        echo "$NOTARY_STATUS"
    exit 1
    fi
done


#---------------------------------------------------------------------
# We're done with the .pkg for the .dmg, so let's rename it for
# solo use and copy it into artifacts, too.
#---------------------------------------------------------------------

FILE_PKG="tidy-${VERSION_TIDY}-macos-x86_64+arm.pkg"
cp \
    "${DIR_DIMG}/build/dmg_contents/Install HTML Tidy.pkg" \
    "${DIR_DIMG}/build/artifacts/${FILE_PKG}"


#---------------------------------------------------------------------
# Because everything else has an sha256, let's provide them for our
# packages, too, even though it's stupid and senseless with signed
# code.
#---------------------------------------------------------------------
cd "${DIR_DIMG}/build/artifacts"

shasum -a 256 "$(basename ${FILE_IMAGE})" > "$(basename ${FILE_IMAGE}).sha256"
shasum -a 256 "$(basename ${FILE_PKG})" > "$(basename ${FILE_PKG}).sha256"


#---------------------------------------------------------------------
# Let's also prepare the binaries.html-tidy.org manifest.
# brew install coreutils for gstat, if necessary.
#---------------------------------------------------------------------
manifest="../binaries-partial.yml"
touch "${manifest}"
for filename in *.*[^sha256]; do
    filesize=$(numfmt --to=si --suffix=B $(wc -c < ${filename}))
    modified=$(gstat -c %y "${filename}" | cut -d'.' -f1)
    modified="${modified//-//}"
    sha256=$(shasum -a 256 "${filename}" | awk '{print $1}')
    echo "    - filename: ${filename}" >> "${manifest}"
    echo "      filesize: ${filesize}" >> "${manifest}"
    echo "      modified: ${modified}" >> "${manifest}"
    echo "      describe: ''"          >> "${manifest}"
    echo "      sha256: ${sha256}"     >> "${manifest}"
    echo ""                            >> "${manifest}"
done;


#---------------------------------------------------------------------
# Output (if on Github) the finished name of the dmg and pkg.
#---------------------------------------------------------------------

echo "::set-output name=DMG_NAME::$(basename ${FILE_IMAGE})"
echo "::set-output name=PKG_NAME::$(basename ${FILE_PKG})"
