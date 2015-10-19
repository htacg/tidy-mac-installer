HTACG HTML Tidy Installer for Mac OS X
======================================

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
official [HTML Tidy releases][5] (as of 2015-October there is still some mismatch).


General
-------

In general the public has no reason to use these tools since they depend on building Tidy
locally, in which case there’s no need for an installer. However it’s available here in
the event the original maintainer is hit by a bus.


Packaging Requirements
----------------------

The project requires two pieces of freely available software in order to build:

- [Packages][1] by Stéphane Sudre (free of charge), for the `HTML Tidy.pkgproj` file.
- [DMG Architect][2] by Spoonjuice LLC (free of charge), for the `DMG Project.dmgpkg` file.


Prerequisites
-------------

Of course you have to have used CMAKE to build tidy and its libraries, as well as the
documentation.

~~~
cd tidy-html5-xxx/build/cmake/
cmake ../..
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


### Sign the package with a developer certificate

We should strive to deliver signed installer packages in order to maintain user trust.
Mac OS X GateKeeper policies will, by default, prevent installation of unsigned packages.
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

Pretty, Mac-like disk images can be built manually, but for convenience this repot
contains a DMG Architect project. Open the project and modify the disk image metaphore
that is presented.

- Delete the existing installer.
- Change the version number.
- Build and then Finalize the disk image.



 [1]: http://s.sudre.free.fr/Software/Packages/about.html
 [2]: https://itunes.apple.com/us/app/dmg-architect-disk-builder/id426104753?mt=12
 [3]: https://github.com/htacg/tidy-mac-installer
 [4]: https://github.com/htacg/binaries
 [5]: https://github.com/htacg/tidy-html5/releases
