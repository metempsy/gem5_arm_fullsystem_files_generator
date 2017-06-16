# Copyright (C) 2017 Metempsy Technology Consulting
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# Author: Pau Cabre

# Most of the steps below are copied from http://gem5.org/ARM_Linux_Kernel

FROM ubuntu:16.04

RUN date +%Y%m%d > /release_date.txt

RUN apt-get -y update
RUN apt-get install -y gcc make python git swig scons g++ python-dev zlib1g-dev m4 device-tree-compiler gcc-aarch64-linux-gnu wget xz-utils bc gcc-arm-linux-gnueabi gcc-4.8-aarch64-linux-gnu gcc-4.8-arm-linux-gnueabihf gcc-arm-linux-gnueabihf

RUN mkdir /generated_files
RUN mkdir /generated_files/binaries
RUN mkdir /generated_files/disks
RUN mkdir /generated_files/revisions

#clone gem5
RUN git clone https://gem5.googlesource.com/public/gem5
WORKDIR gem5
RUN git rev-parse --short HEAD > /generated_files/revisions/gem5

#generate DTBs for VExpress_GEM5_V1
WORKDIR /gem5/system/arm/dt
RUN make
RUN for i in *dtb; do filename=$(basename $i .dtb); cp $i /generated_files/binaries/$filename.$(cat /release_date.txt).dtb; done

#generate up-to-date bootloaders
WORKDIR /gem5/system/arm/aarch64_bootloader
RUN make
RUN cp boot_emm.arm64 /generated_files/binaries
WORKDIR /gem5/system/arm/simple_bootloader
RUN make
RUN cp boot.arm boot_emm.arm /generated_files/binaries

#checkout and build kernel for VExpress_GEM5_V1
WORKDIR /
RUN git clone https://github.com/gem5/linux-arm-gem5.git -b gem5/v4.4 linux-arm-gem5_4.4
WORKDIR linux-arm-gem5_4.4
RUN git rev-parse --short HEAD > /generated_files/revisions/linux-arm-gem5_4.4
RUN make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- gem5_defconfig
RUN make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j4
RUN cp vmlinux /generated_files/binaries/vmlinux.vexpress_gem5_v1_64.$(cat /release_date.txt)
RUN make distclean
RUN make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- gem5_defconfig
RUN make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j4
RUN cp vmlinux /generated_files/binaries/vmlinux.vexpress_gem5_v1.$(cat /release_date.txt)

#checkout and build kernel and DTBs for VExpress_EMM64
WORKDIR /
RUN git clone https://github.com/gem5/linux-arm64-gem5.git
WORKDIR linux-arm64-gem5
RUN git rev-parse --short HEAD > /generated_files/revisions/linux-arm64-gem5
RUN make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CC=aarch64-linux-gnu-gcc-4.8 gem5_defconfig
RUN make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CC=aarch64-linux-gnu-gcc-4.8 -j4
RUN cp vmlinux /generated_files/binaries/vmlinux.vexpress_emm64.$(cat /release_date.txt)
RUN cp arch/arm64/boot/dts/aarch64_gem5_server.dtb /generated_files/binaries/aarch64_gem5_server.$(cat /release_date.txt).dtb

#checkout and build kernel and DTBs for VExpress_EMM
WORKDIR /
RUN git clone https://github.com/gem5/linux-arm-gem5.git -b gem5/linaro linux-arm-gem5_linaro
WORKDIR linux-arm-gem5_linaro
RUN git rev-parse --short HEAD > /generated_files/revisions/linux-arm-gem5_linaro
RUN make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- CC=arm-linux-gnueabihf-gcc-4.8 vexpress_gem5_server_defconfig
RUN make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- CC=arm-linux-gnueabihf-gcc-4.8 -j4
RUN cp vmlinux /generated_files/binaries/vmlinux.vexpress_emm.$(cat /release_date.txt)
WORKDIR arch/arm/boot/dts
#indicate that vexpress-v2p-ca15-tc1-gem5.dtb is actually for 1 cpu
RUN cp vexpress-v2p-ca15-tc1-gem5.dtb vexpress-v2p-ca15-tc1-gem5_1cpus.dtb
RUN for i in *gem5_*dtb; do filename=$(basename $i .dtb); cp $i /generated_files/binaries/$filename.$(cat /release_date.txt).dtb; done

#Compile up-to-date m5 binary for the disk images
WORKDIR /gem5/util/m5
RUN make -f Makefile.aarch64
RUN mv m5 m5.aarch64
RUN make clean -f Makefile.aarch64
RUN make -f Makefile.arm
RUN mv m5 m5.aarch32

#Get old ARM FS files
WORKDIR /
RUN mkdir /old_m5_path
WORKDIR /old_m5_path
RUN wget http://www.gem5.org/dist/current/arm/aarch-system-2014-10.tar.xz
RUN tar xJvf aarch-system-2014-10.tar.xz


#Install sfdisk 2.20 (needed by gem5img.py Newer versions have a different output format and do not recognize some parameters)
WORKDIR /
RUN mkdir /sfdisk_2.20
WORKDIR /sfdisk_2.200
RUN wget https://www.kernel.org/pub/linux/utils/util-linux/v2.20/util-linux-2.20.1.tar.gz
RUN tar xzvf util-linux-2.20.1.tar.gz
WORKDIR util-linux-2.20.1
RUN ./configure --without-ncurses
RUN make
#cp sfdisk to a directory with more preference in PATH
RUN cp fdisk/sfdisk /usr/local/sbin

RUN mkdir /mount

WORKDIR /generated_files

#This is thought to run with "docker run --privileged=true -v $PWD:/shared_vol <image_name>" in order to get the file
#For some reason we need to copy the .img files from the built docker image to the running cointainer in order to be able to mount them
CMD \
for image in aarch64-ubuntu-trusty-headless linaro-minimal-aarch64;   \
do                                                                    \
    (cp /old_m5_path/disks/$image.img disks                        && \
     /gem5/util/gem5img.py mount disks/$image.img /mount           && \
     cp /gem5/util/m5/m5.aarch64 /mount/sbin/m5                    && \
     /gem5/util/gem5img.py umount /mount                              \
    ) || exit 1;                                                      \
done                                                               && \
for image in aarch32-ubuntu-natty-headless linux-aarch32-ael;         \
do                                                                    \
    (cp /old_m5_path/disks/$image.img disks                        && \
     /gem5/util/gem5img.py mount disks/$image.img /mount           && \
     cp /gem5/util/m5/m5.aarch32 /mount/sbin/m5                    && \
     /gem5/util/gem5img.py umount /mount                              \
    ) || exit 1;                                                      \
done                                                               && \
tar cJvf ../aarch-system-$(cat /release_date.txt).tar.xz binaries disks revisions   && \
cp /aarch-system-$(cat /release_date.txt).tar.xz /shared_vol

