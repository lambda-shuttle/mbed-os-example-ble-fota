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

# Author's Note:
# The fota cli tool is used to setup and build the ble fota examples in this repository. The tool takes in as
# arguments the example, target board, mount point of the target board, and toolchain. Note that if the mount point
# is not provided (it could be the case that an end-user is trying to build without the board connected), then the
# target binary is not flashed. In the case of the MCUboot example, the "factory firmware" is saved and would require
# manual transfer when the board is indeed connected. In either case, the demonstration step would be the only part
# that requires manual intervention.
#
# Important: The tool assumes the target board and toolchain unless otherwise specified by the end-user. However,
#            currently, the only board and toolchain supported are NRF52840_DK and GCC_ARM respectively.

set -e

source scripts/utils.sh

usage () {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [options]

  A simple cli tool to automate the setup and build process for Bluetooth-LE
  Firmware Over the Air (FOTA) examples

Options:
  -e=, --example=TEXT             The example you are trying to setup and build.
                                  [default: mock]
  -t=, --toolchain=[GCC_ARM|ARM]  The toolchain you are using to build your app.
                                  [default: GCC_ARM]
  -b=, --board=TEXT               A build target for an Mbed-enabled device.
                                  [default: NRF52840_DK]
  -m=, --mount=TEXT               Path to the mount point of the target board.
  -c, --clean                     Clean the example builds and environment
  -h, --help                      Print this message and exit

Note:
  For now, only the NRF52840_DK board and GCC_ARM toolchain are supported. Also,
  if a mount point isn't provided, then the target binary is not flashed.
EOF
  exit
}

clean () {
  exit
}

parse_options () {
  for i in "$@"; do
    case $i in
      -e=*|--example=*)   example="${i#*=}"   ; shift  ;;
      -t=*|--toolchain=*) toolchain="${i#*=}" ; shift  ;;
      -b=*|--board=*)     board="${i#*=}"     ; shift  ;;
      -m=*|--mount=*)     mount="${i#*=}"     ; shift  ;;
      -c|--clean)         clean               ;;
      -h|--help)          usage               ;;
      *)                  return 1            ;;
    esac
  done

  return 0
}

main () {
  # Default Options:
  example="mock"
  toolchain="GCC_ARM"
  board="NRF52840_DK"

  # Root directory of repository
  root=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

  setup_formatting
  parse_options "$@" || fail exit "Unrecognised option" "Please use -h or --help for usage"
}

main "$@"
exit