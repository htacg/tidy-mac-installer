HTACG HTML Tidy Installer for macOS
===================================

About
-----

This directory contains the project files that are required to build the
installer package for HTACG **HTML Tidy**. Although CMAKE is capable of
generating DMG installer packages, Mac users have higher expectations of
installers than the rudimentary installer provided by CMAKE. Additionally this
gives us the opportunity to sign the installer package before building the disk
image.

These materials are available at [HTACG' Repository for this project][3].


Releases and versioning
-----------------------

Disk images will be added to [HTACG binaries repository][4] any time other
builds are added to the repository. We will strive to ensure that this only
happens coincident with official [HTML Tidy releases][5] (as of 2021-April there
is still some mismatch).


General
-------

In general the public has no reason to use these tools since they depend on
building Tidy locally, in which case there’s no need for an installer. However
it’s available here in the event the original maintainer has children late in
his life.


Packaging Requirements
----------------------

Note that the maintainer has taken the time to write scripts to perform these
steps rather than counting on GUI-only software. As such, some prerequisites
need to be installed on the machine building the images. For convenience, the
`brew install` lines below can be copy and pasted:

~~~
brew install ImageMagick
brew install libmagic
brew install create-dmg
~~~

Why ImageMagick? It allows us to script adding the version number to the
background image of the disk image. Users of macOS are detail oriented, after
all.


Process
-------

This script is designed to run both in the macOS terminal and in Github's
macOS virtual machine runners. In both cases, some environment variables with
your credentials have to be supplied before running the build script. Once
supplied, running the script will perform everything automatically.

### Environment variables.

Take a look at `build_installer_image.sh` to see the variables you have to set.
You can `export APPLE_ID=toad@mac.com` (etc.) before running the script. And
you *do* have to supply your own credentials.


### Run the Build Package

Ensure that your `tidy-html5` and `tidy-mac-installer` directories are siblings.
Whichever branch/version of `tidy-html5` that is checked out will be built.

Then run `./build_installer_image.sh`.

The build will happen quickly, but the script will take a few minutes while
waiting for Apple to notarize the disk image. When the script exits
successfully, you'll find the important bits in the in-source `build` directory.


 [3]: https://github.com/htacg/tidy-mac-installer
 [4]: https://github.com/htacg/binaries
 [5]: https://github.com/htacg/tidy-html5/releases
