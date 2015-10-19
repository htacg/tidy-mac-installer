#!/bin/sh

# Add documents to the user's desktop.
QR="Tidy Quick Reference.html"
RM="Tidy README.rtf"

cp "$QR" "$HOME/Desktop/"
cp "$RM" "$HOME/Desktop/"

chown $USER "$QR"
chown $USER "$RM"

# Create symbolic links to dylib
V_ORIG="libtidy.5.1.8.dylib"
V_MAJOR="libtidy.5.dylib"
V_GEN="libtidy.dylib"

# 
ln -sf "/usr/local/lib/$V_ORIG" "/usr/local/lib/$V_MAJOR"
ln -sf "/usr/local/lib/$V_MAJOR" "/usr/local/lib/$V_GEN"

# Add path to .bash_profile.
new=/usr/local/bin
BP="$HOME/.bash_profile"
touch $BP
chown $USER $BP 
echo "\n" >> $BP
echo "# Tidy for Mac OS X by balthisar.com is adding the new path for Tidy." >> $BP
echo "export PATH=$new:\$PATH" >> $BP
echo "\n" >> $BP
