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
target=NRF5280_DK
toolchain=GCC_ARM

example=$1  # mock or mcuboot

# Check if the file is being sourced instead of executed
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && 
  echo "Script ${BASH_SOURCE[0]} isn't being sourced...\n" &&
    exit 30

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

# Decode the example and assign the directory variable accordingly. If the
# example requested is invalid, print a helpful message and abort.
case $example in
  mock) 
    dir="./mock"
    ;;
  mcuboot)
    dir="./mcuboot"
    ;;
  # Note: If there are additional examples, please add them here and update
  #       the options line in the printf below.
  *)
    printf "%b\n"\
           "\e[1;31mInvalid example \"$example\"!\e[0m"\
           "Options - [\"mock\"|\"mcuboot\"]"
    return 33
    ;;
esac

example_dir_exists $dir || return 33


