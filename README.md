# BLE FOTA Examples

[![Build Examples](https://github.com/ARMmbed/mbed-os-example-ble-fota/actions/workflows/build-examples.yml/badge.svg?branch=main)](https://github.com/ARMmbed/mbed-os-example-ble-fota/actions/workflows/build-examples.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

This repository houses example applications built for the Arm® Mbed™ OS platform that demonstrate the usage and abilities of the Bluetooth® Low Energy (BLE) firmware-over-the air (FOTA) service. The service specification and sources can be found [here](https://github.com/ARMmbed/mbed-os-experimental-ble-services/tree/fota-service-github-ci/services/FOTA). As defined in the specification, the FOTA service facilitates the transfer of firmware updates over BLE.

The examples come with _batteries included!_ They're bundled with an automated build tool, "fota.sh", that eases the build process for the end-user. Please refer to the sections below for more information.

## Pre-requisites
Currently, the only supported target boards for the examples are the [`NRF52840_DK`](https://os.mbed.com/platforms/Nordic-nRF52840-DK/) and [`DISCO_L475VG_IOT01A`](https://os.mbed.com/platforms/ST-Discovery-L475E-IOT01A/). The [BLE documentation](https://os.mbed.com/docs/mbed-os/v6.12/apis/ble.html) describes the BLE APIs available on Mbed™ OS; going through this documentation isn't strictly essential to run the examples, but is helpful in understanding the sources.

## Build Tool
The `fota.sh` cli tool aids in setup and build of the examples in this repository. Please run `./scripts/fota.sh --help` for usage instructions.

> **Note**: If the `-f` or `--flash` option isn't provided (it could be the case that an end-user is trying to build without the board connected), then the target binary is not flashed. This is especially useful for building the examples with a CI workflow. Note that both flashing and erasing is acheived using `pyocd`.
>
> In the case of the MCUboot example, the _"factory firmware"_ is saved and would require manual transfer when the board is indeed connected. In either case, the demonstration step would be the only part that requires manual intervention from the user.
>
> **Important**: The tool assumes the target board (`NRF52840_DK`), toolchain (`GCC_ARM`), and example (`mock`) unless otherwise specified by the end-user. Currently, only the `GCC_ARM` toolchain has been verified to work; the verification of functionality for binaries built using ARM Compiler 6 is pending.

## Examples

Please refer to the example-specific READMEs for build and demonstration instructions.
1. [Mock Example](Mock)
2. [MCUboot Example](MCUboot)

## Known Issues

1. **Dependency Conflicts**: The difference in version requirements of the [PyYAML](https://pyyaml.org) dependency imposed by both mbed-os and pyocd led to the creation of a temporary virtual environment (venv), which is used in the target binary flashing stage of both examples. This is a known issue and would require changes to the `requirements.txt` file in the mbed-os to resolve. Another conflict is that between pyocd and mbed-ls on the version requirement of [PrettyTable](https://pypi.org/project/prettytable/), which is resolved through the temporary venv. \
   \
   Yet another minor conflict that doesn't hinder the build process is one between mbed-tools and mbed-os on the version requirement of the [Click](https://click.palletsprojects.com/en/8.0.x/) dependency; mbed-tools requires that the minimum version of Click to be greater than 7.1 while mbed-os requires it to be greater than 7.0. Now, the dependencies for mbed-os are installed after those of mbed-tools, which overwrites the newer version and generates a conflict. This would (again) require changes to the requirements file in the mbed-os repository to bump up the minimum version number of Click to 7.1.
   
2. **Target Binary Flashing**: For the Mock example, compiling with mbed-tools results in the following error:
    ```
    ERROR: Build program file (firmware) not found <path to mock example>/target/cmake_build/<target board>/develop/<toolchain>/target.hex
    ``` 
   The tool is looking for a hex file under the cmake build output whose name comes from project directory (in this case, "target"). However, the generated one is named `BLE_GattServer_FOTAService.hex`. Again, this is a known issue and has been [filed](https://github.com/ARMmbed/mbed-tools/issues/282) (282) in the mbed-tools repository by [noonfom](https://github.com/noonfom).

## License
The software in this repository is licensed under Apache-2.0. Please refer to [LICENSE](LICENSE) for more information. 

## Contributions
Mbed™ OS is an open-source, device software platform for the Internet of Things. Contributions are an important part of the platform, and our goal is to make it as simple as possible to become a contributor. Contributions to this repository are **greatly appreciated** and accepted under the same Apache-2.0 license. To encourage productive collaboration, as well as robust, consistent and maintainable code, we have a set of guidelines for [contributing to Mbed™ OS](https://os.mbed.com/docs/mbed-os/latest/contributing/index.html).

> **Important**: Please target the `development` branch of this repository for pull requests.

## Related

* [mbed-os-example-ble](https://github.com/ARMmbed/mbed-os-example-ble)
* [mbed-os-experimental-ble-services](https://github.com/ARMmbed/mbed-os-experimental-ble-services)
* [mcuboot](https://github.com/mcu-tools/mcuboot)
* [mbed-mcuboot-demo](https://github.com/AGlass0fMilk/mbed-mcuboot-demo)
* [mbed-mcuboot-blinky](https://github.com/AGlass0fMilk/mbed-mcuboot-blinky)
