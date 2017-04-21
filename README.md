# gem5_arm_fullsystem_files_generator
Generator of kernels, bootloaders, DTBs and disk images for aarch32 and aarch64 gem5 Full System simulations (updated April 2017)

## List of known changes from [aarch-system-2014-10.tar.xz](http://www.gem5.org/dist/current/arm/aarch-system-2014-10.tar.xz)
1. The aarch64 bootloader is newer ([info](https://gem5.googlesource.com/public/gem5/+/47326f54222af99d96ab57508449d1bb62d03842)).
2. The DTB for the VExpress_EMM64 platform is newer ([info](https://github.com/gem5/linux-arm64-gem5/commit/24fd6238427aad5c212493efeb1)).
3. Added DTBs and kernels for the VExpress_GEM5_V1\* platforms.
4. Updated the /sbin/m5 binary for the different disk images ([info](https://gem5.googlesource.com/public/gem5/+/d4c1600c4e3e4f380f5582f8bfba97fb466a18ce)).
5. Kernel for VExpress_EMM is 3.14 (it used to be 3.13)
6. Kernels for VExpress_EMM\* platforms are compiled with gcc 4.8.5 (it used to be 4.8.2)

## Prerequisites for generating the files (tested on an Ubuntu 16.04 environment)
1. Docker must be installed ([info](https://docs.docker.com/engine/installation/linux/ubuntu/)).
2. Optionally let users run docker as non-root ([info](https://docs.docker.com/engine/installation/linux/linux-postinstall/#manage-docker-as-a-non-root-user)).

## How to generate the files
1. Just run the run.sh script on the cloned repository (use sudo if you did not let users run docker as non-root as indicated above). On a successful run (that may take more than an hour), the user will get the aarch-system-2017-04.tar.xz file in the same directory.
    * `./run.sh`
2. Create a new_m5_path directory and untar the contents of the aarch-system-20170421.tar.xz file into it.
    * `mkdir new_m5_path`
    * `tar xJvf aarch-system-20170421.tar.xz -C new_m5_path`
3. Make the M5_PATH environment variable point to the new directory before running any gem5 arm FullSystem simulation
    * `export M5_PATH=$PWD/new_m5_path`
4. Under new_m5_path/revisions, one will find the SHA-1 hash of the revision used for each repository involved in the files generation. These are the values for the "April 2017" release:
    * `gem5: 3cc6df4`
    * `linux-arm64-gem5: 24fd623`
    * `linux-arm-gem5 (gem5/v4.3 branch): d5545a8`
    * `linux-arm-gem5 (gem5/linaro branch): b2af788`

## How to use the files
There are files generated for the VExpress_GEM5_V1\* (both aarch32 and aarch64), VExpress_EMM (aarch32) and VExpress_EMM64 (aarch64) platforms.

These are some example command lines depending on the simulated platform:

#### VExpress_GEM5_V1 aarch64
```
./build/ARM/gem5.opt \
configs/example/fs.py \
--machine-type=VExpress_GEM5_V1 \
--dtb=armv8_gem5_v1_1cpu.20170421.dtb \
--kernel=vmlinux.vexpress_gem5_v1_64.20170421 \
--script=$PWD/tests/halt.sh
```

#### VExpress_GEM5_V1 aarch32
```
./build/ARM/gem5.opt \
configs/example/fs.py \
--machine-type=VExpress_GEM5_V1 \
--dtb=armv7_gem5_v1_1cpu.20170421.dtb \
--kernel=vmlinux.vexpress_gem5_v1.20170421 \
--script=$PWD/tests/halt.sh
```

#### VExpress_EMM64
For this command to work, one may need to remove the VExpress_EMM64 platform from the `default_kernels` dictionary in `configs/common/FSConfig.py`
```
./build/ARM/gem5.opt \
configs/example/fs.py \
--machine-type=VExpress_EMM64 \
--dtb=aarch64_gem5_server.20170421.dtb \
--kernel=vmlinux.vexpress_emm64.20170421 \
--script=$PWD/tests/halt.sh
```

#### VExpress_EMM
For this command to work, one may need to remove the VExpress_EMM platform from the `default_kernels` dictionary in `configs/common/FSConfig.py`
```
./build/ARM/gem5.opt \
configs/example/fs.py \
--machine-type=VExpress_EMM \
--dtb=vexpress-v2p-ca15-tc1-gem5.20170421.dtb \
--kernel=vmlinux.vexpress_emm.20170421 \
--script=$PWD/tests/halt.sh
```
