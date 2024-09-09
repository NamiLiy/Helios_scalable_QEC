#!/bin/bash

distance=5
p=0.000001
test_runs=10
num_fpgas=4 #only the leaves
measurement_fusion=0
logical_quibits_per_dimension=4
merge_probability=0.999999

configuration_file="../test_benches/test_data/configuration_${distance}_0.txt"
gcc configuration.c random_seeds.c -o config -lm
./config $configuration_file $test_runs $logical_quibits_per_dimension $num_fpgas $merge_probability

sleep 1

gcc main.c random_seeds.c -o main -lm
input_prefix="../test_benches/test_data/input_data_${distance}"
./main $distance $p $test_runs $input_prefix $measurement_fusion $logical_quibits_per_dimension $num_fpgas

gcc union_find.c -o uf -lm

# Loop over the range of FPGA IDs
for (( fpga_id=1; fpga_id<=num_fpgas; fpga_id++ ))
do
    

    # Use variable substitution in file names
    input_file="../test_benches/test_data/input_data_${distance}_${fpga_id}.txt"
    output_file="../test_benches/test_data/output_data_${distance}_${fpga_id}.txt"

    input_file_unmodified="${input_file%.*}_unmodified.txt"
    output_file_unmodified="${output_file%.*}_unmodified.txt"


    if [ $measurement_fusion -eq 1 ]; then

        # Call the programs with these arguments
        ./main $distance $p $test_runs $input_file_unmodified 1 $measurement_fusion
        ./uf $distance $input_file_unmodified $output_file_unmodified 1 $measurement_fusion
        sleep 1

        # # Unmodified file paths as variables
        # input_file_unmodified="${input_file%.*}_unmodified.txt"
        # output_file_unmodified="${output_file%.*}_unmodified.txt"

        # # Copy files to new '_unmodified' paths
        # cp "$input_file" "$input_file_unmodified"
        # cp "$output_file" "$output_file_unmodified"
        num_contexts=$num_contexts+1
        
        sleep 1
        ./cf $distance $num_contexts $input_file_unmodified $input_file $output_file_unmodified $output_file
        sleep 1
    fi

    if [ $measurement_fusion -eq 0 ]; then
        ./uf $distance $input_file $output_file $num_fpgas $measurement_fusion $logical_quibits_per_dimension $fpga_id $configuration_file
        sleep 1
    fi

done
