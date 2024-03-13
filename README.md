# Helios: FPGA implementation of a distributed union find decoder

## Algorithm

Please refer to our paper on arXiv: https://arxiv.org/abs/2301.08419 or in the proceedings of IEEE QCE 2023: https://ieeexplore.ieee.org/document/10313800

## Folder Structure

    .
    ├── build_scripts           # Python scripts to generate final RTL files and tcl scripts for various configurations of Helios
    ├       └── templates       # RTL templates
    ├── design                  # Generic RTL files common to all configurations of Helios
    ├── test_benches            # Unit tests and other verification tests
    ├       ├── unit_tests      # Unit tests for RTL modules
    ├       ├── full_tests      # Test benches for various surface code parameters
    ├       └── test_data       # Input and expected outputs for full_tests
    ├── parameters              # Parameters shared by both the design file and test benches
    ├── plots                   # Scripts to generate plots
    ├── old_files               # Previous versions of the design (No longer in use)
    ├── scripts                 # Scripts to build a simple Vivado Project and run verification tests
    └── scripts                 # Software code to generate test vectors and verify results

## Key Results

We list some of the key results of this implementation below
    
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
3) Run the vivado simulation. Set the distance accordingly and modify the paths in the single_FPGA_FIFO_verification_test_rsc.sv to point to the correct files

### Helios extended versions

#### Weighted edges

Change weight_list in https://github.com/NamiLiy/Helios_scalable_QEC/blob/main/design/wrappers/single_FPGA_decoding_graph_dynamic_rsc.sv

#### Erasure errors

Checkout : https://github.com/NamiLiy/Helios_scalable_QEC/tree/erasure_patch
```sh
cd design/files_for_erasure
./erasure_setup.sh
```

#### Circuit-level noise

Checkout: https://github.com/NamiLiy/Helios_scalable_QEC/tree/circuit_level_noise

#### Streaming decoding (sliding window decoding)

Checkout: https://github.com/NamiLiy/Helios_scalable_QEC/tree/streaming_decoder

#### Time-multiplexing decoding

Checkout: https://github.com/NamiLiy/Helios_scalable_QEC/tree/context_switching

### Helios multi-FPGA version

Note : This section is under construction....

Modify the content in build_scripts/user_configuration.py to change the configuration of Helios.
Currently supported parameters: code distance (X and Z), Helios tree structure of control nodes, physical bit width of interconnect between control nodes, latency of interconnect (for latency estimations)

```sh
cd build_scripts
python generate.py
```

Generated output files will be available at design/generated
