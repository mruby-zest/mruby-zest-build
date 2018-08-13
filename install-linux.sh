#!/bin/bash

#This script needs:
# - To be run in the directory of the extracted tarball
# - To be run as root
echo "This install script:"
echo "  1. Removes old ZynAddSubFX installs"
echo "  2. Installs zyn-fusion to /opt/zyn-fusion/"
echo "  3. Creates symbolic links in /usr to the zyn-fusion install in /opt"
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

#Clean up any old installs
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

echo "Installing Zyn Fusion"
mkdir -p /opt/zyn-fusion/
cp -a ./* /opt/zyn-fusion

echo "Installing Symbolic Links"

echo "...Zyn-Fusion"
ln -s /opt/zyn-fusion/zyn-fusion  /usr/bin/

echo "...ZynAddSubFX"
ln -s /opt/zyn-fusion/zynaddsubfx /usr/bin/

echo "...Banks"
mkdir -p /usr/share/zynaddsubfx/
ln -s /opt/zyn-fusion/banks /usr/share/zynaddsubfx/banks

echo "...vst version"
if [ -d "/usr/lib64/vst/" ]
then
    ln -s /opt/zyn-fusion/ZynAddSubFX.so /usr/lib64/vst/
else
    mkdir -p /usr/lib/vst
    ln -s /opt/zyn-fusion/ZynAddSubFX.so /usr/lib/vst/
fi

echo "...lv2 version"
if [ -d "/usr/lib64/lv2/" ]
then
    ln -s /opt/zyn-fusion/ZynAddSubFX.lv2        /usr/lib64/lv2/
    ln -s /opt/zyn-fusion/ZynAddSubFX.lv2presets /usr/lib64/lv2/
else
    mkdir -p  /usr/lib/lv2/
    ln -s /opt/zyn-fusion/ZynAddSubFX.lv2        /usr/lib/lv2/
    ln -s /opt/zyn-fusion/ZynAddSubFX.lv2presets /usr/lib/lv2/
fi

echo "...bash completion"
bashcompdir=$(pkg-config --variable=completionsdir bash-completion)
if [ "$bashcompdir" ]
then
    echo ln -s /opt/zyn-fusion/completions/zyn-fusion $bashcompdir/zyn-fusion
fi

echo ""
echo "Thank you for supporting Zyn-Fusion"
echo "You can now use the 3.0.3 release via a LV2/VST plugin host or"
echo "by running the standalone via 'zynaddsubfx'"
