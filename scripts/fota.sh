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
# arguments the example, target board and toolchain. Note that if the flash option is not provided (it could be the case
# that an end-user is trying to build without the board connected), then the target binary is not flashed. In the case 
# of the MCUboot example, the "factory firmware" is saved and would require manual transfer when the board is indeed 
# connected. In either case, the demonstration step would be the only part that requires manual intervention.
#
# Important: The tool assumes the target board and toolchain unless otherwise specified by the end-user. However,
#            currently, the only boards and toolchain supported are NRF52840_DK and DISCO_L475VG_IOT01A and GCC_ARM 
#            respectively.

set -e
trap 'cleanup $?' SIGINT SIGTERM ERR EXIT

source scripts/utils.sh
source scripts/mock.sh
source scripts/mcuboot.sh

# Display a neatly formatted message on how to use this tool
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
  -f, --flash                     Flash the connected target board
  -c, --clean                     Clean the example builds and environment
  -h, --help                      Print this message and exit

Note:
  For now, only the NRF52840_DK and DISCO_L475VG_IOT01A boards and GCC_ARM 
  toolchain are supported. Please connect only one target board when flashing. 
EOF
  exit
}

# This function would clean up the example builds and generated files
clean () {
  log message "Cleaning builds and generated files..."
  
  rm -rf "$root/venv"

  # Clean example-specific files and folders
  mock_clean "$root"
  mcuboot_clean "$root"

  log success "All neat and tidy now" && exit
}

# Parses the options specified by the end-user and either assigns the corresponding variable or calls a function and
# exits (i.e. in the case of help and clean). If the option is unrecognised, the function returns 1, which triggers
# a fail that exits the tools and displays an error on stderr.
parse_options () {
  for i in "$@"; do
    case $i in
      -e=*|--example=*)   example="${i#*=}"   ; shift  ;;
      -t=*|--toolchain=*) toolchain="${i#*=}" ; shift  ;;
      -b=*|--board=*)     board="${i#*=}"     ; shift  ;;
      -f|--flash)         skip=1              ; shift  ;;
      -c|--clean)         clean               ;;
      -h|--help)          usage               ;;
      *)                  return 1            ;;
    esac
  done
}

# Checks if the example is either mock or mcuboot. If more examples, are added in the future, this function would have
# to be modified accordingly.
valid_example () {
  case $example in
    mock|mcuboot) ;;
    *) fail "Invalid example" "Supported examples - [mock|mcuboot]" ;;
  esac
}

# Checks if the board is NRF52840_DK as it's currently the only supported board. This function will have to be modified
# when DISCO_L475VG_IOT01A (and maybe other boards) are supported at a later point.
valid_board () {
  case $board in
    NRF52840_DK) ;;
    DISCO_L475VG_IOT01A) ;;
    *) fail "Unsupported board" "The only supported boards are NRF52840_DK and DISCO_L475VG_IOT01A"
  esac
}

# Checks if the toolchain is GCC_ARM as it's the only one supported. The ARM toolchain may be supported in the future.
valid_toolchain () {
  case $toolchain in
    GCC_ARM) ;;
    *) fail "Unsupported toolchain" "The only supported toolchain is GCC_ARM"
  esac
}

# A series of checks to make sure that the program options are valid
check_usage () {
  valid_example
  valid_board
  valid_toolchain
}

# Sets up the main virtual environment and activates it
setup_virtualenv () {
  if [[ -d venv ]]; then
    log message "Using existing virtual environment venv..."
  else
    log message "Creating virtual environment..."

    # Create the venv directory and setup the virtual environment
    # shellcheck disable=SC2015
    mkdir venv && python3 -m venv venv \
      || fail "Virtual environment creation failed!" "Tip: Check your python installation!"
  fi
  source venv/bin/activate
  log success "Virtual environment activated"
}

# Installs the required python dependencies silently and notify if there's any issue in the installation.
install_requirements () {
  log message "Installing/updating requirements silently..."
  # shellcheck disable=SC2015
  pip install -q --upgrade pip && pip install -q -r "$root/requirements.txt" \
    || fail "Unable to install requirements!" "Please take a look at requirements.txt"
  log success "General requirements installed/updated"
}

# Call the build functions corresponding to the selected example
# Pre: The example is valid and so are all other arguments.
build_example () {
  args=("$toolchain" "$board" "$skip" "$root")
  case $example in
    mock)    mock_build "${args[@]}"    ;;
    mcuboot) mcuboot_build "${args[@]}" ;;
  esac
}

# Cleanup routine that runs when the program exits (either successfully or abruptly)
cleanup () {
  # If unsuccessful termination, then clean the build
  if [[ "$1" -eq 1 ]]; then clean; fi
}

#-----------------------------------------------------------------------------------------------------------------------
# Main Program
#-----------------------------------------------------------------------------------------------------------------------
main () {
  # Default Options:
  example="mock"
  toolchain="GCC_ARM"
  board="NRF52840_DK"
  skip=0               # Skip the binary flashing if the -f or --flash is missing - Default: false

  # Root directory of repository
  root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd -P)

  setup_formatting
  parse_options "$@" || fail "Unrecognised option" "Please use -h or --help for usage"

  check_usage
  setup_virtualenv
  install_requirements
  build_example
}

main "$@"
exit
