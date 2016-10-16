#!/bin/sh
#to be run as root
rm -r /opt/zyn-fusion
mkdir /opt/zyn-fusion
chown mark:users /opt/zyn-fusion
echo "3.0.0 Pre-Release " >> /opt/zyn-fusion/VERSION
echo "Build on"           >> /opt/zyn-fusion/VERSION
echo `date`               >> /opt/zyn-fusion/VERSION
cp   -a /usr/local/lib/lv2/ZynAddSubFX.lv2presets /opt/zyn-fusion/
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
cd /opt/
rm -f zyn-fusion-3.0.0pre.tar zyn-fusion-3.0.0pre.tar.bz2
tar cf zyn-fusion-3.0.0pre.tar ./zyn-fusion
bzip2 zyn-fusion-3.0.0pre.tar
