# Mock Example

In this demo, the FOTA service is used to transfer a binary from the host PC into the flash of the target. A basic _FOTA client_, implemented in Python using [bleak](https://pypi.org/project/bleak/), is used to read/write the binary stream, control and status characteristics. 

> **Note**: Please refer to the [FOTA Service Structure](https://github.com/ARMmbed/mbed-os-experimental-ble-services/tree/fota-service-github-ci/services/FOTA/docs#fota-service-structure) section of the service specification to learn more about these characteristics.

To verify the success of the transfer, the application computes the [SHA-256](https://en.wikipedia.org/wiki/SHA-2) of the binary and prints it to the serial port. The SHA-256 is also computed on the host using [sha256sum](https://man7.org/linux/man-pages/man1/sha256sum.1.html). The transfer is considered a success if the hashes are equal.

## Pre-requisites

To use the Python client, the host computer must have Bluetooth capabilites, either through an inbuilt chipset or via an external USB adapter. You will need the [GNU ARM Embedded](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm) toolchain and `python3` in your path to build the example.

> **Important**: For macOS users, your terminal emulator would have to be granted access to Bluetooth through `System Preferences > Security & Privacy > Pirvacy > Bluetooth`. Click on the padlock to make changes and check the box next to your terminal app. If the app is missing from the menu, click on the `+` icon to add your terminal app to the list.

## Build 

To build the example, please run the following command from the repository root. To view more information on the steps involved in the build, please refer to the comments in [mock.sh](../scripts/mock.sh).
```shell
./scripts/fota.sh -b=DISCO_L475VG_IOT01A -e=mock --flash
```
> **Note**: You can build the example without a connected target board. The script indicates the location of the flash binary at the end of the build; this binary would have to be flashed manually when the target board is indeed connected later.

## Demonstration

Please make sure to activate the virtual environment, located in the root folder, before proceeding further. Also, ensure that the target board is connected and has been flashed with the generated binary from the build stage.

1. Open a serial terminal on the host computer to receive serial prints from the _FOTA target_:
   ```shell 
   mbed term -b 115200
   ```
2. In a separate shell window, run the test script from the client directory:
   ```shell
   python client.py
   ```
   
   It scans for a device named _"FOTA"_ and attempts to connect to it.
   Once connected, it asks the user to enter the path to the binary.
   Use the binary already running on the target:
   
   ```
   Enter the path to the binary: ../target/cmake_build/NRF52840_DK/develop/GCC_ARM/BLE_GattServer_FOTAService.bin
   ```
3. The client initiates the transfer once the FOTA session begins and commits the update once the entire binary has been sent.
   Subsequently, the target computes the SHA-256 of the binary and prints it to the serial.
   Verify the `<hash>` with sha256sum:
   ```shell
   echo "<hash> ../cmake_build/<target>/develop/<toolchain>/BLE_GattServer_FOTAService.bin" | sha256sum --check
   ```
