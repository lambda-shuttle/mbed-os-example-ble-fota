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

source scripts/utils.sh

# Builds the mock example and flashes the binary if a mount point is provided
# Please refer to the commented steps for more information
# Pre: Arguments passed here are all valid
mock_build () {
  toolchain=$1; board=$2; mount=$3; skip=$4; root=$5

  log message "Installing/updating example-specific dependencies..."
  # 1. Install mbed-os and mbed-os experimental-ble-services
  # shellcheck disable=SC2015
  cd "$root/Mock/target" && mbed-tools deploy || \
    fail "Unable to install mbed-os or mbed-os-experimental-ble-services dependency"

  # 2. Install mbed-os python dependencies (silently)
  pip install -q -r mbed-os/requirements.txt || \
    fail "Unable to install mbed-os requirements" "Please take a look at mbed-os/requirements.txt"

  # A short message addressing the known Click dependency conflict - this should be removed once resolved.
  log note "Click dependency conflict" \
           "This is a known issue and does not hinder the build process" \
           "Refer to the documentation for more information"
  log success "Example requirements installed/updated"

  out="cmake_build/$board/develop/$toolchain"
  # 3. Compile the example with the target board and toolchain
  mbed-tools compile -t "$toolchain" -m "$board" || \
    fail "Failed to compile the example" "Please check the sources"

  # 4. Convert the output .elf executable to a .bin as it's what NRF52840_DK requires
  arm-none-eabi-objcopy -O binary "$out/BLE_GattServer_FOTAService.elf" "$out/BLE_GattServer_FOTAService.bin" || \
    fail "Failed to extract binary from elf" "Tip: Check if arm-none-eabi-objcopy is in your path"

  # 5. Flash the board with the binary (if skip is 0)
  # shellcheck disable=SC2015
  if [[ "$skip" -eq 0 ]]; then
    cp "$out/BLE_GattServer_FOTAService.bin" "$mount" || \
      fail "Unable to flash binary!" "Please ensure the board is connected"
    log success "Binary flashed"
  else
    log message "Binary at $root/Mock/target/$out/BLE_GattServer_FOTAService.bin"
  fi

  log success "Build Complete" "Please refer to the documentation for demonstration instructions"
}

# Clean build files and dependencies specific to this example
# Pre: root is valid
mock_clean () {
  root=$1
  rm -rf "$root/Mock/target/cmake_build"
  rm -rf "$root/Mock/target/mbed-os"
  rm -rf "$root/Mock/target/mbed-os-experimental-ble-services"
}
