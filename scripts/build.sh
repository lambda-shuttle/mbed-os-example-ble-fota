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

# A message to indicate that there was some issue in installing/updating
# requirements or dependencies
requirements_failed () {
  printf "%b\n"\
         "\e[1;31mUnable to install requirements!\e[0m"\
         "Please look at requirements.txt."\
         "Aborting..."
}

# A message to indicate that the virtual enviornment creation failed
venv_failed () {
  printf "%b\n"\
         "\e[1;31mFailed to create virtual environment!\e[0m"\
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
  #       the options line in the printf below.
  *)
    printf "%b\n"\
           "\e[1;31mInvalid example \"$example\"!\e[0m"\
           "Options - [\"mock\"|\"mcuboot\"]"
    return 33
    ;;
esac

example_dir_exists $dir || return 33

# I. Setup the enviornment
if [[ -d "venv" ]] ; then
  printf "Using existing virtual environment...\n" 
else 
  printf "Creating virtual environment...\n"

  # Create the directory and setup the virutal environment
  mkdir venv && python3 -m venv venv
  # Safety check for errors and proceed to activate the environment
  if [[ $? -ne 0 ]] ; then 
    venv_failed && return 33
  else 
    source ./venv/bin/activate
    printf "\e[0;32mVirtual enviornment activated!\e[0m\n"
  fi
fi

# Install or update the python dependencies silently and notify if there's any
# issue in the installation.
printf "Installing/updating requirements...\n"
pip install -q --upgrade pip && pip install -q -r requirements.txt

if [[ $? -ne 0 ]] ; then requirements_failed && return 33; fi
