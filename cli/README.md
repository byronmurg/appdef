# appdef-tool

This is a command line tool for interacting with appdef

## installation

### The easy way
*make sure that docker is installed and running!*
Run this command:
```
git clone omanom.com:git/appdef.git /tmp/appdef && sh /tmp/appdef/tool/easy_installer
```

This will use docker to build the binary and then install it into your system path.

### Install a pre-built binary
Prebuilt binaries are typically found in the releases section of github.

To install download the file, gzip-decode it and add to your PATH

The steps go like this:
- Open your browser and navigate to https://appdef.io/releases
- Select the latest release
- Download the package for your machine type (If you're on a Mac then it's likely Darwin-arm64)
- Decompress the binary into your path e.g. `gzip -d ~/Downloads/appdef-tool-1.0.0-Darwin-arm64.gz > ~/bin/appdef`
- Make sure that the binary is executable e.g. `chmod 700 ~/bin/appdef`

### Install from source
For source installation, first check out the repo, then:
```
cd tool/
make
sudo make install
```
