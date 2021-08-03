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

  say message "Installing/updating example-specific dependencies..."
  # 1. Install application dependencies - mbed-os (silently)
  # shellcheck disable=SC2015
  cd "$root/mcuboot/target/application" && mbed-tools deploy > /dev/null 2>&1 || \
    fail exit "Unable to install application dependencies" \
              "Please check mcuboot.lib, mbed-os.lib, and mbed-os-experimental-ble-services.lib"

  # 2. Install bootloader dependencies (silently)
  # shellcheck disable=SC2015
  cd "$root/mcuboot/target/bootloader" && mbed-tools deploy > /dev/null 2>&1 || \
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
}

# A dummy clean function
mcuboot_clean () {
  : # Do nothing
}