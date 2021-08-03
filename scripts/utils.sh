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
# This shell script contains utility functions for use in the main fota script
# as well as the setup and build scripts of the examples.

# Constants for text formatting:
setup_formatting () {
  _clear='\e[0m'
  _bold='\e[1m'
  _red='\e[31m'
  _green='\e[32m'
  _yellow='\e[33m'
}

# Says (i.e. prints) a message to the console with formatting based on the selected formatting mode.
say () {
  case $1 in
    error)
      # The first line of the message is treated as the message heading and is marked in bold red along with an "ERROR:"
      # prefix. Subsequent message lines are presented with default formatting unless otherwise formatted beforehand.
      # All output is directed to stderr.
      heading=${2-"ERROR"}
      printf "%b\n" \
             "${_bold}${_red}ERROR: $heading${_clear}" \
             "${@:3}" >&2
      ;;
    success)
      heading=${2-"SUCCESS"}
      printf "%b\n" \
             "${_bold}${_green}SUCCESS: $heading${_clear}" \
             "${@:3}"
      ;;
    message)
      printf "%b\n" "${@:2}"
      ;;
    note)
      heading=${2-"NOTE"}
      printf "%b\n" \
             "${_bold}${_yellow}NOTE: $heading${_clear}" \
             "${@:3}"
      ;;
    *) # Unknown error
      ;;
  esac
}

# Prints an error message to stderr and exits (or returns) with a code of 1
fail () {
  local mode=${1}
  local msg=( "${@:2}" )
  say error "${msg[@]}"
  $mode 1
}