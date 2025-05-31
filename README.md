# Gamecube-to-USB-adapter
A FPGA based adapter to convert Gamecube controller data to the XBOX360 protocol for Windows

The design is based around the Tang Nano 9k board. The end goal is to create a custom PCB that fits into a Gamecube controller shell to use on Windows and Nintendo Switch1/2. The aims are low latency, hall effect sticks, and simplicity of building. I wanted to use the UPduino board, but due to limitations (or my knowledge of FPGA design) the UPduino is not able to run the USB code. All USB code is usedddddd from the repository https://github.com/WangXuan95/FPGA-USB-Device
The FPGA code I created is based on this repository for the HID Keyboard example and modified to create the XBOX360 data send to a PC. 

Future Updates:
1. Nintendo Switch 1/2 support.
2. Full PCB layout to fit in a Gamecube controller.
3. Update to USB to have lower latency (currently at 2ms but should be sub 1ms)
4. Controller calibration and button remapping

![image](https://github.com/user-attachments/assets/22145a31-99e1-41a9-a599-41c29aaa242b)
![image](https://github.com/user-attachments/assets/7bf6e39d-ea18-4c47-bffc-479808dba4da)
