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

1) Average decoding time scales sub-linearly with $d$. We measure the average decoding time for phenomenological noise ($phen$) of 0.005 and 0.001 and circuit level noise ($cct$) of 0.001. (Left) The average decoding time. The average time per measurement round reducing continuously justifies that our decoder is scalable for large surface codes under both phenomenological noise and circuit level noise. The unusual increase at $d=17$ for circuit level noise is caused by reducing the operating frequency to 75 MHz. The dashed line shows the calculated value at 100MHz.
<img src="https://github.com/NamiLiy/Helios_scalable_QEC/blob/main/plots/liyan10.png" alt="drawing" width="500"/>
<img src="https://github.com/NamiLiy/Helios_scalable_QEC/blob/main/plots/liyan11.png" alt="drawing" width="500"/>

2) Distribution of decoding time ($T$) with the mean marked with $\times$. Each distribution includes $10^6$ data points. By default $d=13$, phenomenological noise of $p=0.001$ and is unweighted.
$T$'s distribution has a small mean \& a long tail. 
<img src="https://github.com/NamiLiy/Helios_scalable_QEC/blob/main/plots/liyan12.png" alt="drawing" width="500"/>
$T$ grows with the physical error rate
<img src="https://github.com/NamiLiy/Helios_scalable_QEC/blob/main/plots/liyan13.png" alt="drawing" width="500"/>


3) Helios can optimize for resource usage by mapping multiple virtual PEs to a single physical PE.
Average latency per measurement round for $d=27$ under two different phenomenological noise levels.
<img src="https://github.com/NamiLiy/Helios_scalable_QEC/blob/main/plots/liyan14.png" alt="drawing" width="500"/>
The corresponding resource use for the Helios-n configurations for $d=27$, Helios-n indicates n nodes are mapped per PE
<img src="https://github.com/NamiLiy/Helios_scalable_QEC/blob/main/plots/liyan15.png" alt="drawing" width="500"/>
Distribution of decoding time for $d=51$ with Helios-$51$
<img src="https://github.com/NamiLiy/Helios_scalable_QEC/blob/main/plots/liyan16.png" alt="drawing" width="500"/>

4) Distribution of decoding time ($T$) for decoder extensions. The mean is marked with $\times$. Each distribution includes $10^6$ data points. By default $d=13$, phenomenological noise of $p=0.001$ and is unweighted.
$T$ grows with the weight of the edges
<img src="https://github.com/NamiLiy/Helios_scalable_QEC/blob/main/plots/liyan17.png" alt="drawing" width="500"/>
$T$ shifts with erasures
<img src="https://github.com/NamiLiy/Helios_scalable_QEC/blob/main/plots/liyan18.png" alt="drawing" width="500"/>
$T$ increases with sliding-window
<img src="https://github.com/NamiLiy/Helios_scalable_QEC/blob/main/plots/liyan19.png" alt="drawing" width="500"/>


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
