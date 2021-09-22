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

# Prompt the end-user on whether they'd like the script to automatically update the application version number in the
# mbed_app.json file. This is especially useful for the CI workflow where "yes" would be piped into the script.
prompt_auto_update () {
  while true; do
    read -rp "Do you wish to auto-update the version number in application/mbed_app.json? " response
    case $response in
        [Yy]*) auto_update=1                          ; break ;;
        [Nn]*) auto_update=0                          ; break ;;
        *)     log message "Please answer yes or no." ;;
    esac
  done
}

# Builds the mcuboot example and flashes the binaries if -f or --flash is provided
# Please refer to the commented steps for more information
# Pre: Arguments passed here are all valid
mcuboot_build () {
  toolchain=$1; board=$2; skip=$3; root=$4

  # Paths to application and bootloader
  application=$root/MCUboot/target/application
  bootloader=$root/MCUboot/target/bootloader

  log message "Installing/updating example-specific dependencies..."
  # 1. Install application dependencies - mbed-os
  # shellcheck disable=SC2015
  cd "$application" && mbed-tools deploy || \
    fail "Unable to install application dependencies" \
         "Please check mcuboot.lib, mbed-os.lib, and mbed-os-experimental-ble-services.lib"

  # 2. Install bootloader dependencies
  # shellcheck disable=SC2015
  cd "$bootloader" && mbed-tools deploy || \
    fail "Unable to install bootloader dependencies" \
         "Please check mcuboot.lib and mbed-os.lib"

  # 3. Install mbed-os python dependencies (silently)
  pip install -q -r mbed-os/requirements.txt || \
    fail "Unable to install mbed-os requirements" "Please take a look at mbed-os/requirements.txt"

  # A short message addressing the known Click dependency conflict - this should be removed once resolved.
  log note "Click dependency conflict" \
           "This is a known issue and does not hinder the build process" \
           "Refer to the documentation for more information"

  # 4. Install mcuboot requirements (silently)
  pip install -q -r mcuboot/scripts/requirements.txt || \
    fail "Unable to install mcuboot requirements" "Please take a look at MCUboot/scripts/requirements.txt"

  # 5. Run mcuboot setup script
  python mcuboot/scripts/setup.py install || \
    fail "MCUboot setup script failed"

  log success "Example requirements installed/updated"
  log message "Creating the signing keys and building the bootloader..."

  # 6. Create the signing keys
  # shellcheck disable=SC2015
  mcuboot/scripts/imgtool.py keygen -k signing-keys.pem -t rsa-2048 && \
    mcuboot/scripts/imgtool.py getpub -k signing-keys.pem >> signing_keys.c || \
      fail "Unable to create the signing keys"

  # 7. Build the bootloader using mbed-tools
  # Note: This does not silence errors
  mbed-tools compile -t "$toolchain" -m "$board" || \
    fail "Failed to compile the bootloader" "Please check the sources"

  log success "Created signing keys and built the bootloader"
  log message "Building and signing the primary application..."

  # 8. Build the primary application using mbed-tools
  # shellcheck disable=SC2015  
  out="cmake_build/$board/develop/$toolchain"
  cd "$application" && mbed-tools compile -t "$toolchain" -m "$board" || \
    fail "Failed to compile the bootloader" "Please check the sources"

  # shellcheck disable=SC2015
  cp "$out/application.hex" "$bootloader" && cd "$bootloader" && \
    mcuboot/scripts/imgtool.py sign -k signing-keys.pem \
    --align 4 -v 0.1.0 --header-size 4096 --pad-header -S 0xC0000 \
    application.hex signed_application.hex || \
      fail "Unable to sign the primary application"

  log success "Built and signed the primary application"
  log message "Deactivating virtual environment to setup a new one..."
  log note "PyYAML dependency conflict" \
           "pyocd and mbed-os confict in their version requirements of PyYAML" \
           "Refer to the documentation for more information."

  # 9. Deactivate the primary virtual environment
  deactivate

  log message "Creating temporary virtual environment..."

  # 10. Create a new, temporary virtual environment just for pyocd and intelhex
  # shellcheck disable=SC2015
  mkdir venv && python3 -m venv venv || \
    fail "Virtual environment creation failed!" "Tip: Check your python installation!"

  # 11. Activate temporary virtual environment
  source venv/bin/activate

  log success "Temporary virtual environment activated"
  log message "Installing requirements (pyocd and intelhex) silently..."

  # 12. Install requirements (pyocd and intelhex) for temporary environment (silently)
  # shellcheck disable=SC2015
  pip install -q --upgrade pip && pip install -q pyocd==0.30.3 intelhex==2.3.0 || \
    fail "Unable to install temporary venv requirements" "Please check scripts/mcuboot.sh"

  log success "Requirements installed/updated"

  # 13. Create the factory firmware
  hexmerge.py -o merged.hex --no-start-addr "$out/bootloader.hex" signed_application.hex || \
    fail "Unable to create factory firmware"

  # 14. Flash the board with the binary (if skip is 0)
  if [[ "$skip" -eq 0 ]]; then
    pyocd erase --chip && pyocd flash merged.hex || \
      fail "Unable to flash firmware!" "Please ensure the board is connected"
    log success "Factory firmware flashed"
  else
    log message "Factory firmware at $root/MCUboot/target/bootloader/merged.hex"
  fi

  # 15. Deactivate and restore virtual environment
  deactivate && rm -rf venv && source "$root/venv/bin/activate"

  # 16. Creating the update binary
  # This involves changing the application's version number in mbed_app.json to 0.1.1 and rebuilding it, copying the
  # hex file into the bootloader folder, signing the updated application with the RSA-2048 keys and generating the raw
  # binary file from the signed_update.hex so that it can be transported over BLE.
  prompt_auto_update

  if [[ "$auto_update" -eq 0 ]]; then
    # User updates the binary manually, in which case we wait for them to do so
    log message "Please update the app version number in application/mbed_app.json" \
                "Once done, press ENTER to continue..."
    while read -r -n 1 key
    do
      # if input == ENTER key
      [ -z "$key" ] && break
    done
  else
    # Use jq to update the binary
    # shellcheck disable=SC2015
    cd "$application" && \
      jq '."config"."version-number"."value" = "\"0.1.1\""' --indent 4 mbed_app.json > tmp.$$.json \
        && mv tmp.$$.json mbed_app.json || \
          fail "Failed in updating application/mbed_app.json" "Please check scripts/mcuboot.sh"
  fi

  log message "Creating the update binary..."

  # shellcheck disable=SC2015
  cd "$application" && mbed-tools compile -t "$toolchain" -m "$board" || \
    fail "Failed to compile the application" "Please check the sources"

  # shellcheck disable=SC2015
  cp "$out/application.hex" "$bootloader" && cd "$bootloader" && \
    mcuboot/scripts/imgtool.py sign -k signing-keys.pem \
    --align 4 -v 0.1.1 --header-size 4096 --pad-header -S 0x55000 \
    application.hex signed_update.hex || \
      fail "Unable to sign the updated application"

  arm-none-eabi-objcopy -I ihex -O binary signed_update.hex signed_update.bin || \
    fail "Failed to extract binary from elf" "Tip: Check if arm-none-eabi-objcopy is in your path"

  log message "Update binary at $root/MCUboot/target/bootloader/signed_update.bin"
  log success "Build Complete" "Please refer to the documentation for demonstration instructions"
}

# Clean build files and dependencies specific to this example
# Pre: root is valid
mcuboot_clean () {
  root=$1
  application="$root/MCUboot/target/application"
  bootloader="$root/MCUboot/target/bootloader"

  # Remove generated files and folders in bootloader folder
  rm -rf "$bootloader"/sign* "$bootloader/application.hex" "$bootloader/merged.hex"
  rm -rf "$bootloader/cmake_build" "$bootloader/dist" "$bootloader/imgtool.egg-info"

  # Remove bootloader dependencies
  rm -rf "$bootloader/mbed-os" "$bootloader/mcuboot"

  # Remove application build folder and dependencies
  rm -rf "$application/cmake_build" "$application/mbed-os" "$application/mbed-os-experimental-ble-services" "$application/mcuboot"
}
