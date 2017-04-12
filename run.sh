#!/bin/bash

docker build -t gem5_arm_fullsystem_files_generator .

docker run -v $PWD:/shared_vol --privileged=true gem5_arm_fullsystem_files_generator

