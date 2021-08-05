# MCUBoot Example

This demo application extends the [Mock](../Mock) example by including a bootloader based on [MCUboot](https://github.com/mcu-tools/mcuboot). 

> **Note**: For more information on the MCUboot port for Mbed™ OS, please click [here](https://mcu-tools.github.io/mcuboot/readme-mbed.html). And, click [here](https://github.com/AGlass0fMilk/mbed-mcuboot-blinky) for an MCUboot/Mbed™ OS blinky example by [AGlassOfMilk](https://github.com/AGlass0fMilk).

## Pre-requisites

To use the Python client, the host computer must have Bluetooth capabilites, either through an inbuilt chipset or via an external USB adapter. This application requires the [NRF52840_DK](https://os.mbed.com/platforms/Nordic-nRF52840-DK/) platform to run; currently, the build tool only supports this platform. You will also need the [GNU ARM Embedded](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm) toolchain and `python3` in your path to build the example.

> **Important**: For macOS users, your terminal emulator would have to be granted access to Bluetooth through `System Preferences > Security & Privacy > Pirvacy > Bluetooth`. Click on the padlock to make changes and check the box next to your terminal app. If the app is missing from the menu, click on the `+` icon to add your terminal app to the list.

If you chose to auto-update the `application/mbed_app.json` file, then the [jq](https://stedolan.github.io/jq/) command-line JSON processor is a required dependency that will need to be installed manually.

## Build

To build the example, please run the following command from the repository root. To view more information on the steps involved in the build, please refer to the comments in [mcuboot.sh](../scripts/mcuboot.sh).
```shell
./scripts/fota.sh -e=mcuboot
```
> **Note**: You can build the example without a connected target board. The script indicates the location of the factory firmware and the update binary. The factory firmware would have to be flashed manually when the target board is indeed connected later. The update binary would be used in the demonstration stage.

## Demonstration

Please make sure to activate the virtual environment, located in the root folder, before proceeding further. Also, ensure that the target board is connected and has been flashed with the factory firmware from the build stage.

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
   Please enter the path to the signed update binary.

   ```
   Enter the path to the binary: ../target/bootloader/signed_update.bin
   ```
   Note the firmware revision of the application running on the device:
   ```
   xxxx-xx-xx xx:xx:xx,xxx - logger - INFO - DFU Service found with firmware rev 0.1.0 for device "Primary MCU"
   ```
3. The client initiates the transfer once the FOTA session begins and commits the update once the entire binary has been sent.
   Subsequently, the target sets the update as pending and initiates a system reboot.
   Once the new application boots, the client reconnects and rereads the Firmware Revision Characteristic:
   ```
   xxxx-xx-xx xx:xx:xx,xxx - logger - INFO - DFU Service found with firmware rev 0.1.1 for device "Primary MCU"
   ```
