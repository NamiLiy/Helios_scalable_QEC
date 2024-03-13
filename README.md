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
    ├── scripts                 # Scripts to build a simple Vivado Project and run verification tests
    └── scripts                 # Software code to generate test vectors and verify results
    
## Build

### Requirements

The system is extensively tested on a VCU129 FPGA. In addition, some versions of this system have been run on  ZCU106 and VMK180 FPGAs.
Running on other FPGA boards requires modifications on pin assignments and block design generation.
We used Vivado versions between 2019.1 to 2023.2 for synthesis and simulation.
However, as the main design (except test benches and inter-FPGA communication) does not rely on FPGA-specific components, the Vivado version will create a minimal impact.

### Helios single FPGA version

#### Build project

```sh
cd scripts
vivado total.tcl
```

#### Run simulation

1) Compile software input and verification files. Set the distance accordingly in the software files
```sh
cd software_code
gcc main.c random_seeds.c -o input_gen
gcc union_find.c -o uf -lm
```
2) Generate software input and verification files
```sh
./input_gen
./uf
```
3) Run the vivado simulation. Set the distance accordingly and modify the paths in the single_FPGA_FIFO_verification_test_rsc.sv to point to correct files

    

### Helios multi-FPGA version

Note : This section is under construction....

Modify the content in build_scripts/user_configuration.py to change the configuration of Helios.
Currently supported parameters : codeDistance (X and Z), Helios tree stucture of control nodes, physical bit width of interconnect between control nodes, laency of interconnect (for latency estimations)

```sh
cd build_scripts
python generate.py
```

Generated output files will be available at design/generated
