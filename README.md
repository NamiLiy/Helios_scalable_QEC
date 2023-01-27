# Helios : FPGA implementation of a distributed union find decoder

## Algorithm

Please refer to our paper on arxiv : https://arxiv.org/abs/2301.08419

## Folder Structure

    .
    ├── build_scripts           # Python scripts to generate final RTL files and tcl scripts for various configurations of Helios
    ├       └── templates       # RTL templates
    ├── design                  # Generic RTL files common to all configurations of Helios
    ├── test_benches            # Unit tests and other verification tests
    ├       ├── unit_tests      # Unit tests for RTL modules
    ├       ├── full_tests      # Test benches for various surface code parameters
    ├       └── test_data       # Input and expected outputs for full_tests
    ├── parameters              # Parameters shared by both design file and test benches
    ├── plots                   # Scripts to generate plots
    ├── old_files               # Previous versions of the design (No longer in use)
    └── scripts                 # Scripts to build a simple Vivado Project and run verification tests
    
## Build

### Requirements

This project requires Vivado 2020.2 for simulation and ZCU106 development board for FPGA implementation
This project is tested on Xilinx Vivado 2019.1 and 2020.2 verisons only.
It may or may not work in other versions of Vivado.
This project is tested on ZCU106 development board only.
Running on other FPGA boards require modifications on pin assignments and block deisgn generation.

### Build project

#### Simple vivado project

```sh
cd scripts
vivado total.tcl
```

#### Complete Helios project

Modify the content in build_scripts/user_configuration.py to change the configuration of Helios.
Currently supported parameters : codeDistance (X and Z), Helios tree stucture of control nodes, physical bit width of interconnect between control nodes, laency of interconnect (for latency estimations)

```sh
cd build_scripts
python generate.py
```

Generated output files will be available at design/generated
