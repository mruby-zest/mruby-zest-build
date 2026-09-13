#!/bin/bash

test `id -u` -ne 0 && echo "ERROR: This script needs to be run by root. Try \"sudo $0\"" && exit 50
which stow >& /dev/null
test $? -ne 0  && echo "ERROR: You need to install the \"stow\" program first" && exit 51

# What's the compiled version and date?
Cwd=`pwd`
NewZyn=`basename $Cwd`
Date=`date +%Y-%m-%d`

#This script needs:
# - To be run in the directory of the extracted tarball
# - To be run as root
echo "This install script:"
echo "  1. Installs zyn-fusion to /opt/$NewZyn-$Date/"
echo "  2. Creates symbolic links in /usr/local to the zyn-fusion install in /opt"
echo "  3. Removes or unlinks old versions"
echo ""
echo "If you're ok with this press enter, otherwise press CTRL+C"
echo "and read the script for specifics"

read

#Verify this script is run in the correct directory
if [ ! -f ./zynaddsubfx ]
then
    echo "zynaddsubfx wasn't found in the current directory"
    echo "please run the script from witin the package directory"
    exit
fi

if [ ! -f ./zyn-fusion ]
then
    echo "zyn-fusion wasn't found in the current directory"
    echo "please run the script from witin the package directory"
    exit
fi

if [ ! -f ./libzest.so ]
then
    echo "libzest.so wasn't found in the current directory"
    echo "please run the script from witin the package directory"
    exit
fi

MkDirCpStow() {
    mkdir -p /opt/$NewZyn-$Date/lib/lv2
    mkdir -p /opt/$NewZyn-$Date/lib/vst
    mkdir -p /opt/$NewZyn-$Date/share/zynaddsubfx
    mkdir -p /opt/$NewZyn-$Date/bin
    mkdir -p /opt/$NewZyn-$Date/share/bash-completion
    cp -a zynaddsubfx zyn-fusion /opt/$NewZyn-$Date/bin
    cp -a banks /opt/$NewZyn-$Date/share/zynaddsubfx
    cp -a ZynAddSubFX.lv2presets ZynAddSubFX.lv2 /opt/$NewZyn-$Date/lib/lv2
    cp -a libzest.so /opt/$NewZyn-$Date/lib/
    cp -a schema qml font /opt/$NewZyn-$Date/lib
    cp -a ZynAddSubFX.so /opt/$NewZyn-$Date/lib/vst

    bashcompdir=$(pkg-config --variable=completionsdir bash-completion)
    if [ "$bashcompdir" ]
    then
      mkdir -p /opt/$NewZyn-$Date/share/bash-completion/completions/
      cp ../../tmp/prefix/zynfx_install/usr/share/bash-completion/completions/zynaddsubfx \
        /opt/$NewZyn-$Date/share/bash-completion/completions/
    fi

    echo "Creating symlinks from /opt/$NewZyn-$Date to /usr/local" 
    stow -d /opt -t /usr/local $NewZyn-$Date && ldconfig

    echo ""
    echo "========================================================="
    echo " Thank you for supporting Zyn-Fusion"
    echo " You can now use the release via a LV2/VST plugin host or"
    echo " by running the standalone via 'zynaddsubfx'"
    echo "========================================================="    
}

# Use stow if the previous version was stowed
# or if this is the first install
which zyn-fusion >& /dev/null
ZInst=$?
test `readlink /usr/local/bin/zyn-fusion` && readlink /usr/local/bin/zyn-fusion| grep -q "../../../opt/zyn-fusion"
# If z-f is not installed or it's a stow link
if [ $ZInst -eq 1 -o $? -eq 0 ]
then
    OldZyn=`readlink -f /usr/local/bin/zyn-fusion| cut -d\/ -f3 `
    echo "Removing any /usr/local symlinks for old zyn-fusion in /opt/$OldZyn"
   test -L /usr/local/bin/zyn-fusion && stow -D -d /opt -t /usr/local $OldZyn
    echo "Intalling and symlinking the program"
    MkDirCpStow
    if [ $ZInst -eq 0 ]
    then
      echo ""
      echo "Run \"rm -rf /opt/$OldZyn\" to remove the old version" 
      echo "Or keep it as a backup: "
      echo " stow -D -d /opt -t /usr/local $NewZyn-$Date"
      echo " stow -d /opt -t /usr/local $OldZyn"
      echo "changes the symlinks from the new install and back to the old, if necessary"
      echo ""
    fi
    exit 0
fi

# If the old version wasn't stowed
# Clean up any old installs if it exists
if [ -d /opt/zyn-fusion ]
then 
  echo "Cleaning Up Any Old Zyn Installs"
  echo "...Zyn-Fusion data dir"
  rm -rf /opt/zyn-fusion

  echo "...ZynAddSubFX binaries"
  rm -f /usr/bin/zynaddsubfx
  rm -f /usr/local/bin/zynaddsubfx
  rm -f /usr/bin/zyn-fusion
  rm -f /usr/local/bin/zyn-fusion

  echo "...ZynAddSubFX banks"
  rm -rf /usr/share/zynaddsubfx/banks
  rm -rf /usr/local/share/zynaddsubfx/banks

  echo "...ZynAddSubFX vst"
  rm -rf /usr/lib/vst/ZynAddSubFX.so
  rm -rf /usr/lib64/vst/ZynAddSubFX.so
  rm -rf /usr/local/lib/vst/ZynAddSubFX.so
  rm -rf /usr/local/lib64/vst/ZynAddSubFX.so

  echo "...ZynAddSubFX lv2"
  rm -rf /usr/lib/lv2/ZynAddSubFX.lv2
  rm -rf /usr/lib64/lv2/ZynAddSubFX.lv2
  rm -rf /usr/lib/lv2/ZynAddSubFX.lv2presets
  rm -rf /usr/lib64/lv2/ZynAddSubFX.lv2presets
  rm -rf /usr/local/lib/lv2/ZynAddSubFX.lv2
  rm -rf /usr/local/lib64/lv2/ZynAddSubFX.lv2
  rm -rf /usr/local/lib/lv2/ZynAddSubFX.lv2presets
  rm -rf /usr/local/lib64/lv2/ZynAddSubFX.lv2presets
fi

# Stow this version
echo "Installing Zyn Fusion using stow"
MkDirCpStow
