# Built VirtualGL, TurboVNC and libjpeg-turbo for 64-bit Linux For Tegra R24.1.
#
# Largely based on https://devtalk.nvidia.com/default/topic/828974/jetson-tk1/-howto-install-virtualgl-and-turbovnc-to-jetson-tk1/2
#

mkdir tmp
cd tmp
currentDir=$(pwd)

# DEPENDENCIES

# install necessary packages to build them.
sudo apt-get install git
sudo apt-get install autoconf
sudo apt-get install libtool
sudo apt-get install cmake
sudo apt-get install g++
sudo apt-get install libpam0g-dev
sudo apt-get install libssl-dev

# LIBJPEG-TURBO

# Build and install libjpeg-turbo
git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git
cd libjpeg-turbo
git checkout 1.5.1
mkdir build
autoreconf -fiv
cd build
sh ../configure
make -j4
# Change "DEBARCH=aarch64" to "DEBARCH=arm64"
sed -i 's/aarch64/arm64/g' pkgscripts/makedpkg.tmpl
make deb
sudo dpkg -i libjpeg-turbo_1.5.1_arm64.deb
cd ../../

# VIRTUALGL

# Preventing link error from "libGL.so", check this:
# https://devtalk.nvidia.com/default/topic/946136/jetson-tx1/building-an-opengl-application/
# confirm that /usr/lib/aarch64-linux-gnu/libGL.so links to /usr/lib/aarch64-linux-gnu/tegra/libGL.so
# cd /usr/lib/aarch64-linux-gnu
# sudo rm libGL.so
# sudo ln -s /usr/lib/aarch64-linux-gnu/tegra/libGL.so libGL.so

# Build and install VirtualGL
cd $currentDir
git clone https://github.com/VirtualGL/virtualgl.git
cd virtualgl
git checkout 2.5.x
mkdir build
cd build
cmake -G "Unix Makefiles" -DTJPEG_LIBRARY="-L/opt/libjpeg-turbo/lib64/ -lturbojpeg" ..
make -j4
# Change "DEBARCH=aarch64" to "DEBARCH=arm64"
sed -i 's/aarch64/arm64/g' pkgscripts/makedpkg
# Change "Architecture: aarch64" to "Architecture: arm64"
sed -i 's/aarch64/arm64/g' pkgscripts/deb-control
make deb
sudo dpkg -i virtualgl_2.5.3_arm64.deb
cd ../../

# TURBOVNC

# Build and install TurboVNC
git clone https://github.com/TurboVNC/turbovnc.git
cd turbovnc
mkdir build
cd build
cmake -G "Unix Makefiles" -DTVNC_BUILDJAVA=0 -DTJPEG_LIBRARY="-L/opt/libjpeg-turbo/lib64/ -lturbojpeg" ..

# Prevent error like #error "GLYPHPADBYTES must be 4",
# edit ../turbovnc/unix/Xvnc/programs/Xserver/include/servermd.h
# and prepend before "#ifdef __avr32__"
# servermd="$currentDir/turbovnc/unix/Xvnc/programs/Xserver/include/servermd.h"
# line="#ifdef __avr32__"
# defs="#ifdef __aarch64__\n\
# define IMAGE_BYTE_ORDER       LSBFirst\n\
# define BITMAP_BIT_ORDER       LSBFirst\n\
# define GLYPHPADBYTES          4\n\
#endif\n"
# sed -i "/$line/i $defs" "$servermd"
make -j4
# Change "DEBARCH=aarch64" to "DEBARCH=arm64"
sed -i 's/aarch64/arm64/g' pkgscripts/makedpkg
# Change "Architecture: aarch64" to "Architecture: arm64"
sed -i 's/aarch64/arm64/g' pkgscripts/deb-control
make deb
sudo dpkg -i turbovnc_2.2_arm64.deb

# SYSTEM

# Add system-wide configurations
cd $currentDir
echo "/opt/libjpeg-turbo/lib64" > libjpeg-turbo.conf
sudo cp libjpeg-turbo.conf /etc/ld.so.conf.d/
sudo ldconfig
rm ./libjpeg-turbo.conf

# Add TurboVNC to path
if ! grep -Fq "/opt/TurboVNC/bin" "$HOME/.bashrc"; then
    echo 'export PATH=$PATH:/opt/TurboVNC/bin' >> ~/.bashrc
fi

# Add VirtualGL to path
if ! grep -Fq "/opt/VirtualGL/bin" "$HOME/.bashrc"; then
    echo 'export PATH=$PATH:/opt/VirtualGL/bin' >> ~/.bashrc
fi
