#!/bin/bash

distance=5
num_fpgas=4 #only the leaves
measurement_fusion=0
logical_quibits_per_dimension=4
num_contexts=2

configuration_file="../test_benches/test_data/configuration_${distance}_0.txt"

# input_prefix="../test_benches/test_data/input_data_${distance}"
# ./main $distance $p $test_runs $input_prefix $measurement_fusion $logical_quibits_per_dimension $num_fpgas

gcc union_find.c -o uf -lm

# Loop over the range of FPGA IDs
for (( fpga_id=1; fpga_id<=num_fpgas; fpga_id++ ))
do
    

    # Use variable substitution in file names
    input_file="../test_benches/test_data/output_data_${distance}_${fpga_id}.txt"
    output_file="../test_benches/test_data/output_results_${distance}_${fpga_id}.txt"

    input_file_unmodified="${input_file%.*}_unmodified.txt"
    output_file_unmodified="${output_file%.*}_unmodified.txt"


    ./uf $distance $input_file $output_file $num_fpgas $measurement_fusion $logical_quibits_per_dimension $fpga_id $configuration_file $num_contexts
    sleep 1

done
