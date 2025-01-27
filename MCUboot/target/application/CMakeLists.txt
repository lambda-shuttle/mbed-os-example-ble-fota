# Copyright (c) 2021 ARM Limited. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# Application

cmake_minimum_required(VERSION 3.19.0 FATAL_ERROR)

set(MBED_PATH ${CMAKE_CURRENT_SOURCE_DIR}/mbed-os CACHE INTERNAL "")
set(EXP_BLE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/mbed-os-experimental-ble-services CACHE INTERNAL "")
set(MCUBOOT_PATH ${CMAKE_CURRENT_SOURCE_DIR}/mcuboot CACHE INTERNAL "")
set(MBED_CONFIG_PATH ${CMAKE_CURRENT_BINARY_DIR} CACHE INTERNAL "")
set(APP_TARGET application)

include(${MBED_PATH}/tools/cmake/app.cmake)

project(${APP_TARGET})

add_subdirectory(${MBED_PATH})
add_subdirectory(${EXP_BLE_PATH}/services/FOTA)
add_subdirectory(${MCUBOOT_PATH}/boot/bootutil/)
add_subdirectory(${MCUBOOT_PATH}/boot/mbed/)  # Mbed-MCUboot Port

include_directories(mbed-os-experimental-ble-services)

add_executable(${APP_TARGET})

project(${APP_TARGET})

target_sources(${APP_TARGET}
    PRIVATE
        source/main.cpp
        source/BlockDeviceFOTAEventHandler.h
        source/BlockDeviceFOTAEventHandler.cpp
        source/PeriodicBlockDeviceEraser.cpp
        source/PeriodicBlockDeviceEraser.h
)

target_link_libraries(${APP_TARGET}
    PUBLIC
        mbed-os
        mbed-ble
    	bootutil
        mbed-events
    	mbed-mcuboot
        mbed-storage
        mbed-mbedtls
        ble-service-fota
)

mbed_set_post_build(${APP_TARGET})

option(VERBOSE_BUILD "Have a verbose build process")
if(VERBOSE_BUILD)
  set(CMAKE_VERBOSE_MAKEFILE ON)
endif()
