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

# Builds the mcuboot example and flashes the binaries if a mount is provided.
# Please refer to the commented steps for more information
# Pre: Arguments passed here are all valid
mcuboot_build () {
  toolchain=$1; board=$2; mount=$3; skip=$4; root=$5

  # Paths to application and bootloader
  application=$root/mcuboot/target/application
  bootloader=$root/mcuboot/target/bootloader

  say message "Installing/updating example-specific dependencies..."
  # 1. Install application dependencies - mbed-os (silently)
  # shellcheck disable=SC2015
  cd "$application" && mbed-tools deploy > /dev/null 2>&1 || \
    fail exit "Unable to install application dependencies" \
              "Please check mcuboot.lib, mbed-os.lib, and mbed-os-experimental-ble-services.lib"

  # 2. Install bootloader dependencies (silently)
  # shellcheck disable=SC2015
  cd "$bootloader" && mbed-tools deploy > /dev/null 2>&1 || \
    fail exit "Unable to install bootloader dependencies" \
              "Please check mcuboot.lib and mbed-os.lib"

  # 3. Install mbed-os python dependencies (silently)
  pip install -q -r mbed-os/requirements.txt || \
    fail exit "Unable to install mbed-os requirements" "Please take a look at mbed-os/requirements.txt"

  # A short message addressing the known Click dependency conflict - this should be removed once resolved.
  say note "Click dependency conflict" \
           "This is a known issue and does not hinder the build process" \
           "Refer to the documentation for more information"

  # 4. Install mcuboot requirements (silently)
  # shellcheck disable=SC2015
  cd mcuboot/scripts && pip install -q -r requirements.txt || \
    fail exit "Unable to install mcuboot requirements" "Please take a look at mcuboot/scripts/requirements.txt"

  # 5. Run mcuboot setup script (silently)
  python setup.py install > /dev/null 2>&1 || \
    fail exit "MCUboot setup script failed"

  say success "Example requirements installed/updated"
  say message "Creating the signing keys and building the bootloader..."

  # 6. Create the signing keys (silently)
  # Note: This does not silence errors.
  # shellcheck disable=SC2015
  cd "$bootloader" && mcuboot/scripts/imgtool.py keygen -k signing-keys.pem -t rsa-2048 >/dev/null && \
    mcuboot/scripts/imgtool.py getpub -k signing-keys.pem >> signing_keys.c || \
      fail exit "Unable to create the signing keys"

  # 7. Build the bootloader using the old mbed-cli
  # Note: This does not silence errors
  mbed compile -t "$toolchain" -m "$board" >/dev/null || \
    fail exit "Failed to compile the bootloader" "Please check the sources"

  say success "Created signing keys and built the bootloader"
  say message "Building and signing the primary application..."

  # 8. Build the primary application using the old mbed-cli
  # Note: This does not silence errors
  # shellcheck disable=SC2015
  cd "$application" && mbed compile -t "$toolchain" -m "$board" >/dev/null || \
    fail exit "Failed to compile the bootloader" "Please check the sources"

  cp "BUILD/$board/$toolchain/application.hex" "$bootloader" && cd "$bootloader" && \
    mcuboot/scripts/imgtool.py sign -k signing-keys.pem \
    --align 4 -v 0.1.0 --header-size 4096 --pad-header -S 0xC0000 \
    --pad application.hex signed_application.hex || \
      fail exit "Unable to sign the primary application"

  say success "Built and signed the primary application"
  say message "Deactivating virtual environment to setup a new one..."
  say note "PyYAML dependency conflict" \
           "pyocd and mbed-os confict in their version requirements of PyYAML" \
           "Refer to the documentation for more information."

  # 9. Deactivate the primary virtual environment
  deactivate

  say message "Creating temporary virtual enviornment..."

  # 10. Create a new, temporary virtual environment just for pyocd and intelhex
  # shellcheck disable=SC2015
  mkdir venv && python3 -m venv venv || \
    fail exit "Virtual environment creation failed!" "Tip: Check your python installation!"

  # 11. Activate temporary virtual environment
  source venv/bin/activate

  say success "Temporary virtual environment activated"
  say message "Installing requirements (pyocd and intelhex) silently..."

  # 12. Install requirements (pyocd and intelhex) for temporary environment (silently)
  # shellcheck disable=SC2015
  pip install -q --upgrade pip && pip install -q pyocd==0.30.3 intelhex==2.3.0 || \
    fail exit "Unable to install temporary venv requirements" "Please check scripts/mcuboot.sh"

  say success "Requirements installed/updated"

  # 13. Create the factory firmware
  hexmerge.py -o merged.hex --no-start-addr "BUILD/$board/$toolchain/bootloader.hex" signed_application.hex || \
    fail exit "Unable to create factory firmware"

  # 14. Flash the board with the binary (if skip is 0)
  if [[ "$skip" -eq 0 ]]; then
    pyocd erase --chip && cp merged.hex "$mount" \\
      fail exit "Unable to flash firmware!" "Please ensure the board is connected"
    say success "Factory firmware flashed"
  else
    say message "Factory firmware at $root/mcuboot/target/bootloader/merged.hex"
  fi

  # 15. Deactivate and restore virtual environment
  deactivate && rm -rf venv && source "$root/venv/bin/activate"
}

# A dummy clean function
mcuboot_clean () {
  : # Do nothing
}