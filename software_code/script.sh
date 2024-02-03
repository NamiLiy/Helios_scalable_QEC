#!/bin/bash

distance=5
p=0.005
test_runs=1000
num_fpgas=2 #only the leaves
multi_fpga_mode=1

if [ $multi_fpga_mode -eq 0 ]; then

    # Loop over the range of FPGA IDs
    for (( fpga_id=1; fpga_id<=num_fpgas; fpga_id++ ))
    do
        gcc main.c random_seeds.c -o main -lm
        gcc union_find.c -o uf -lm

        # Use variable substitution in file names
        input_file="../test_benches/test_data/input_data_${distance}_${fpga_id}.txt"
        output_file="../test_benches/test_data/output_data_${distance}_${fpga_id}.txt"

        # Call the programs with these arguments
        ./main $distance $p $test_runs $input_file 1
        ./uf $distance $input_file $output_file 1
        sleep 1
    done
fi

if [ $multi_fpga_mode -eq 1 ]; then

    gcc main.c random_seeds.c -o main -lm
    gcc union_find.c -o uf -lm
    gcc divide_multiple.c -o dm -lm

    # Use variable substitution in file names
    input_file="../test_benches/test_data/input_data_${distance}.txt"
    output_file="../test_benches/test_data/output_data_${distance}.txt"

    # Call the programs with these arguments
    ./main $distance $p $test_runs $input_file $num_fpgas
    ./uf $distance $input_file $output_file $num_fpgas
    ./dm $distance $input_file $output_file $num_fpgas
fi