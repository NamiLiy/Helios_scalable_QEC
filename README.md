# FPGA implementation of distributed union find algorithm

## Algorithm

## Folder Structure

    .
    ├── design                  # RTL design files
    ├── test_benches            # Unit tests and other verification tests
    ├── parameters              # Parameters shared by both design file and test benches
    ├── ip_repo                 # ips used in the project
    ├── old_files               # Previous versions of the design (No longer in use)
    └── scripts                 # Scripts to build the Vivado Project and run verification tests
    
## Build

### Requirements

This project requires Vivado 2020.2 for simulation and ZCU106 development board for FPGA implementation
This project is tested on Xilinx Vivado 2019.1 and 2020.2 verisons only.
It may or may not work in other versions of Vivado.
This project is tested on ZCU106 development board only.
Running on other FPGA boards require modifications on pin assignments and block deisgn generation.

### Build project

```sh
cd scripts
vivado total.tcl
```

### Run on FPGA

### Branches

Multi fpga version of this design is in multi_fpga branch. Please checkout and follow the script to run the multi FPGA version.
