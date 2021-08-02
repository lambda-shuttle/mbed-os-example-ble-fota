#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# The idea is to run this script from the top level directory. An example
# command could be as follows:
# source scripts/build <example>

# Variables
target=NRF52840_DK
toolchain=GCC_ARM

example=$1     # mock or mcuboot
mount_point=$2  # mount point of board - use mbedls to find this information

# Check if the file is being sourced instead of executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  printf "%s\n" "Script ${BASH_SOURCE[0]} isn't being sourced..."
  exit 1
fi

# Make sure that the example directory exists; else, print a helpful message
# and return the appropriate value to abort.
example_dir_exists () {
  if [[ ! -d $1 ]] ; then 
    printf "%b\n"\
           "\e[1;31mExample directory \"$1\" missing!\e[0m"\
           "The script should be sourced from the top-level directory."\
           "Also, please make sure that the mock directory exists."
    return 1
  fi
  return 0
}

# A message to indicate that there was some issue in installing/updating
# requirements or dependencies
requirements_failed () {
  printf "%b\n"\
         "\e[1;31mUnable to install requirements!\e[0m"\
         "Please look at requirements.txt."\
         "Aborting..."
}

# A message to indicate that the virtual environment creation failed
venv_failed () {
  printf "%b\n"\
         "\e[1;31mFailed to create virtual environment!\e[0m"\
         "Aborting..."
}

# A message to indicate that building the example failed 
build_failed () {
  printf "%b\n"\
         "\e[1;31mUnable to build the example!\e[0m"\
         "Please check if the board is plugged in."\
         "Aborting..."
}

# A message to indicate that the mount point for the target board is invalid
invalid_mount () {
  printf "%b\n"\
         "\e[1;31mMount point path is invalid!\e[0m"\
         "Please check if the board is plugged in."\
         "Use mbedls to detect the mount point of the board"\
         "Aborting..."
}

# Decode the example and assign the directory variable accordingly. If the
# example requested is invalid, print a helpful message and abort.
# The example variable is re-assigned to a number for use later on.
case $example in
  mock) 
    dir="./mock"
    example=1
    ;;
  mcuboot)
    dir="./mcuboot"
    example=2
    ;;
  # Note: If there are additional examples, please add them here and update
  #       the example options line in the printf below.
  *)
    printf "%b\n"\
           "\e[1;31mInvalid example \"$example\"!\e[0m"\
           "Usage: source scripts/build.sh <example> <mount-point>" \
           "Examples - [\"mock\"|\"mcuboot\"]" \
           "Aborting..."
    return 33
    ;;
esac

# Check if the mount point is provided
if [ -z "$mount_point" ] ; then
    printf "%b\n"\
           "\e[1;31mMount point argument missing!\e[0m"\
           "Use mbedls to detect the mount point of the board." \
           "Usage: source scripts/build.sh <example> <mount-point>" \
           "Aborting..."
    return 33
fi

example_dir_exists $dir || return 33

# I. Setup the environment
if [[ -d "venv" ]] ; then
  printf "Using existing virtual environment...\n" 
else 
  printf "Creating virtual environment...\n"

  # Create the directory and setup the virtual environment
  mkdir venv && python3 -m venv venv
  # Safety check for errors and proceed to activate the environment
  if [[ $? -ne 0 ]] ; then 
    venv_failed && return 33
  else 
    source ./venv/bin/activate
    printf "\e[0;32mVirtual environment activated!\e[0m\n"
  fi
fi

# Install or update the python dependencies silently and notify if there's any
# issue in the installation.
printf "Installing/updating requirements...\n"
pip install -q --upgrade pip && pip install -q -r requirements.txt

if [[ $? -ne 0 ]] ; then requirements_failed && return 33; fi

# Install the MbedOS and other requirements for the selected example
if [[ $example -eq 1 ]] ; then  
  # Mock example
  # 1. Install mbed-os and mbed-os-experimental-ble-services; 
  # 2. Install mbed-os python requirements;
  cd "$dir/target" && mbed-tools deploy &&
    pip install -q -r mbed-os/requirements.txt
else  
  # MCUboot example 
  # 1. Install application dependencies 
  # 2. Install bootloader dependencies
  # 3. Install mbed-os python requirements
  # 4. Install mcuboot requirements and run mcuboot setup script 
  cd "$dir/target/application" && mbed-tools deploy &&
    cd "../bootloader" && mbed-tools deploy &&
      pip install -q -r mbed-os/requirements.txt &&
        pip install -q -r mcuboot/scripts/requirements.txt &&
          python mcuboot/scripts/setup.py install
fi

if [[ $? -ne 0 ]] ; then requirements_failed && return 33; fi
printf "\e[0;32mRequirements successfully installed/updated!\e[0m\n"

# 2. Building application

printf "Building example...\n"

if [[ $example -eq 1 ]] ; then
  # Mock example
  out=cmake_build/$target/develop/$toolchain

  # Check if the mount point is valid
  if [[ -d $mount_point ]] ; then
    # Compile the example and flash the board with the binary
    mbed-tools compile -t $toolchain -m $target &&
      arm-none-eabi-objcopy -O binary \
      $out/BLE_GattServer_FOTAService.elf \
      $out/BLE_GattServer_FOTAService.bin &&
        cp $out/BLE_GattServer_FOTAService.bin $mount_point
  else 
    invalid_mount && return 33
  fi
else 
  # MCUboot example 
  # Create the signing keys and build the bootloader:
  # The former involves generating the RSA-2048 key pair and extracting the
  # public key into a C data structure so that it can be built into the 
  # bootloader
  printf "Creating the signing keys and building the bootloader...\n"
  mcuboot/scripts/imgtool.py keygen -k signing-keys.pem -t rsa-2048 &&
    mcuboot/scripts/imgtool.py getpub -k signing-keys.pem >> signing_keys.c &&
      mbed compile -t $toolchain -m $target

  if [[ $? -ne 0 ]] ; then build_failed && return 33; fi

  # Building and signing the primary application
  # The latter involves copying the hex file into the bootloader folder and
  # signing the application using the RSA-2048 keys
  printf "Building and signing the primary application...\n"
  cd "../application" && mbed compile -t $toolchain -m $target &&
    cp BUILD/$target/$toolchain/application.hex ../bootloader && 
      cd ../bootloader && 
        mcuboot/scripts/imgtool.py sign -k signing-keys.pem \
        --align 4 -v 0.1.0 --header-size 4096 --pad-header -S 0xC0000 \
        --pad application.hex signed_application.hex
  
  if [[ $? -ne 0 ]] ; then build_failed && return 33; fi

  # Deactivate the virtual environment
  deactivate

  # Create a new temporary virtual environment just for pyocd
  if [[ -d "tmp-venv" ]] ; then
    printf "Using existing temporary virtual environment...\n" 
  else 
    printf "Creating temporary virtual environment...\n"

    # Create the directory and setup the virtual environment
    mkdir tmp-venv && python3 -m venv tmp-venv
    # Safety check for errors and proceed to activate the environment
    if [[ $? -ne 0 ]] ; then 
      venv_failed && return 33
    else 
      source ./tmp-venv/bin/activate
      printf "\e[0;32mTemporary virtual environment activated!\e[0m\n"
    fi
  fi

  pip install -q --upgrade pip && pip install -q pyocd==0.30.3 intelhex==2.3.0

  # Creating and flashing the "factory firmware"
  printf "Creating and flashing the factory firmware...\n"
  # Check if the mount point is valid
  if [[ -d $mount_point ]] ; then
    hexmerge.py -o merged.hex --no-start-addr \
    BUILD/$target/$toolchain/bootloader.hex signed_application.hex &&
      pyocd erase --chip &&
        cp merged.hex $mount_point
  else 
    deactivate 
    invalid_mount && return 33
  fi

  # Deactivate and remove temporary virtual environment
  deactivate && rm -rf tmp-venv

  # Activate the primary virtual environment
  source ../../../venv/bin/activate
  printf "\e[0;32mPrimary virtual environment reactivated!\e[0m\n"
  
  if [[ $? -ne 0 ]] ; then build_failed && return 33; fi

  # Creating the update binary
  # This involves changing the application's version number in mbed_app.json
  # to 0.1.1 and rebuilding it, copying the hex file into the bootloader
  # folder, signing the updated application with the RSA-2048 keys and
  # generating the raw binary file from signed_update.hex so that it can be
  # transported over BLE.
  printf "%b\n" \
         "Please update the app version number in mbed_app.json" \
         "Once done, press ENTER to continue..."
  while read -r -n 1 key 
  do
    # if input == ENTER key
    if [[ -z $key ]]; then
      break
    fi
  done 
  printf "Creating the update binary...\n"
  cd ../application && mbed compile -t $toolchain -m $target &&
    cp BUILD/$target/$toolchain/application.hex ../bootloader && 
      cd ../bootloader &&
        mcuboot/scripts/imgtool.py sign -k signing-keys.pem \
        --align 4 -v 0.1.1 --header-size 4096 --pad-header -S 0x55000 \
        application.hex signed_update.hex &&
          arm-none-eabi-objcopy -I ihex -O binary \
          signed_update.hex signed_update.bin
fi

if [[ $? -ne 0 ]] ; then build_failed && return 33; fi
printf "\e[0;32mBuild complete!\e[0m\n"
