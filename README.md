HTACG HTML Tidy Installer for macOS
===================================

About
-----

This directory contains the project files that are required to build the installer package
for HTACG **HTML Tidy**. Although CMAKE is capable of generating DMG installer packages,
Mac users have higher expectations of installers than the rudimentary installer provided
by CMAKE. Additionally this gives us the opportunity to sign the installer package before
building the disk image.

These materials are available at [HTACG' Repository for this project][3].


Releases and versioning
-----------------------

Disk images will be added to [HTACG binaries repository][4] any time other builds are
added to the repository. We will strive to ensure that this only happens coincident with
official [HTML Tidy releases][5] (as of 2021-April there is still some mismatch).


General
-------

In general the public has no reason to use these tools since they depend on building Tidy
locally, in which case there’s no need for an installer. However it’s available here in
the event the original maintainer has children late in his life.


Packaging Requirements
----------------------

The project requires two pieces of software in order to build:

- [Packages][1] by Stéphane Sudre (free of charge), for the `HTML Tidy.pkgproj` file.
- [DMG Canvas][2] by Araelium (paid) for the `DMG Prokect.dmgCanvas` file.


Note that DMG Architect was previously used and was free of charge, but hasn’t been
updated in many years, and no longer works on current versions of macOS.


Prerequisites
-------------

Of course you have to have used CMAKE to build tidy and its libraries, as well as the
documentation.

~~~
cd tidy-html5-xxx/build/cmake/
cmake ../.. -DCMAKE_BUILD_TYPE=Release "-DCMAKE_OSX_ARCHITECTURES=x86_64;arm64"
make
cmake ../.. -DBUILD_DOCUMENTATION=YES
make
~~~

Move the following files from the build directories to the `tidy-mac-installer/install`
directory:

- `libtidy.x.x.x.dylib`, and remove any older versions of the dylib.
- `libtidys.a`
- `tidy`
- `quickref.html`, and rename it to Mac-friendly `Tidy Quick Reference.html`
- `tidy.1`

Note the `tidy-mac-installer/install` will already contain a `Tidy README.rtf`.


Process
-------

We will complete the following steps:

- Use Packages to build an installation package
- Sign the package with a developer certificate
- Build the disk image


### Use Packages to build an installation package

Verify that Packages correctly located all of the files in `install/` and `source/`. If
they are red then you will have to re-add the file.

Remove any references to previous versions of the dylib, and add the correct version in
the `install` directory.

Update the version number to match the HTML Tidy version.

- **Project** > **Presentation** (tab) > **Title** (popup menu)
- **Packages** > **HTML Tidy** > **Scripts** > **Installer-Post.sh** > V_ORIG, V_MAJOR

You can also use **Project** > **Set Certificate** (or **Change Certificate**) to choose
your installed Developer ID Installer Certificate. This will ensure that the package is
signed when it is built.


### Sign the package with a developer certificate

If you let _Packages_ sign your built package in the previous step, then you can skip
this step (or skip ahead to verifying the signature).

We should strive to deliver signed installer packages in order to maintain user trust.
macOS GateKeeper policies will, by default, prevent installation of unsigned packages.
Although there are workarounds for this, it’s very unfriendly for unsophisticated users
who may give up and decide not to install.

A valid Apple Developer ID certificate is required to sign packages.

To sign a package:

~~~
/usr/bin/productsign --sign "Developer ID Installer: FirstName LastName" unsigned_package.pkg new_package.pkg
~~~

To verify signatures

Signing information can be verified with either of the following two terminal commands:

~~~
pkgutil --check-signature new_package.pkg
~~~

Or

~~~
spctl -a -v --type install new_package.pkg
~~~


### Build the disk image

Pretty, Mac-like disk images can be built manually, but for convenience this repo
contains a _DMG Canvas_ project. Open the project and modify the disk image metaphore
that is presented.

- Delete the existing installer.
- Change the version number.
- Build and then Finalize the disk image.

Ensure that your project settings in the **Contents** tab, **Volume** panel (depicted by
a hard drive icon) include the setting **Code Sign without Notarizing**, and a valid
Developer ID Application chosen for **Code Signing Certificate**.

We will notarize from the command line, because I’m not supplying my credentials in the
the project. However, feel free to use the built-in notarization feature yourself, if
you care to.

When you’re ready, build and finalize the disk image.

### Notarize the disk image

Notarizing the disk image will ensure that Gatekeeper is happy.

~~~
xcrun altool \
    --notarize-app \
    --primary-bundle-id org.htacg.html-tidy.tidy5 \
    -u "your_apple_id@exampled.com" \
    -p "your-app=specific-password"  \
    --file /path/to/tidy-5.6.0-macos.dmg
~~~

Once uploaded, you will receive a response which includes something like:

~~~
RequestUUID = some_uuid
~~~

The status of the notarization process can be checked so:

~~~
xcrun altool \
    --notarization-info some_uuid \
    -u "your_apple_id@exampled.com" \
    -p "your-app=specific-password"
~~~

Once notarization is successfully completed, simply staple the authorization to the
disk image, and verify that it’s notarized:

~~~
xcrun stapler staple /path/to/tidy-5.6.0-macos.dmg
spctl -a -t open --context context:primary-signature -v /path/to/tidy-5.6.0-macos.dmg
~~~


 [1]: http://s.sudre.free.fr/Software/Packages/about.html
 [2]: https://www.araelium.com/dmgcanvas
 [3]: https://github.com/htacg/tidy-mac-installer
 [4]: https://github.com/htacg/binaries
 [5]: https://github.com/htacg/tidy-html5/releases
