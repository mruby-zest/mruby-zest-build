#!/bin/sh
#to be run as root
rm -r /opt/zyn-fusion
mkdir /opt/zyn-fusion
chown mark:users /opt/zyn-fusion
echo "Version 3.0.0" >> /opt/zyn-fusion/VERSION
echo "Build on"      >> /opt/zyn-fusion/VERSION
echo `date`          >> /opt/zyn-fusion/VERSION
cp   -a /usr/lib/lv2/ZynAddSubFX.lv2presets       /opt/zyn-fusion/
cp   -a /home/mark/zynaddsubfx/instruments/banks  /opt/zyn-fusion/
cp      ./package/glpsol                          /opt/zyn-fusion/
cp      ./package/libzest.so                      /opt/zyn-fusion/
cp      ./package/zest                            /opt/zyn-fusion/zyn-fusion
cp   -a ./package/font                            /opt/zyn-fusion/
mkdir  /opt/zyn-fusion/qml
touch  /opt/zyn-fusion/qml/MainWindow.qml
cp   -a ./package/schema                          /opt/zyn-fusion/
mkdir   /opt/zyn-fusion/ZynAddSubFX.lv2
cp      /home/mark/zynaddsubfx/build/src/Plugin/ZynAddSubFX/lv2/* /opt/zyn-fusion/ZynAddSubFX.lv2/
cp      /home/mark/zynaddsubfx/build/src/Plugin/ZynAddSubFX/vst/ZynAddSubFX.so /opt/zyn-fusion/
cp      /home/mark/zynaddsubfx/build/src/zynaddsubfx /opt/zyn-fusion/
cp      ./install-linux.sh /opt/zyn-fusion/
cp      ./package-README.txt /opt/zyn-fusion/README.txt
cp      ./zyn-fusion-ELUA.txt /opt/zyn-fusion/
cp      /home/mark/zynaddsubfx/COPYING /opt/zyn-fusion/COPYING.zynaddsubfx
cp      ./deps/glpk-4.52/COPYING       /opt/zyn-fusion/COPYING.glpsol
cd /opt/
rm -f zyn-fusion-3.0.0.tar zyn-fusion-3.0.0.tar.bz2
tar cf zyn-fusion-3.0.0.tar ./zyn-fusion
bzip2 zyn-fusion-3.0.0.tar
