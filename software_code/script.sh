#!/bin/bash

distance=5
p=0.001
test_runs=1000
num_fpgas=1 #only the leaves
multi_fpga_mode=0
measurement_fusion=0
logical_quibits_per_dimension=3

if [ $multi_fpga_mode -eq 0 ]; then

    # Loop over the range of FPGA IDs
    for (( fpga_id=1; fpga_id<=num_fpgas; fpga_id++ ))
    do
        gcc main.c random_seeds.c -o main -lm
        gcc union_find.c -o uf -lm
        # Please correct d in this file
        gcc context_fix.c -o cf -lm

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
            # Call the programs with these arguments
            ./main $distance $p $test_runs $input_file 1 $measurement_fusion $logical_quibits_per_dimension
            ./uf $distance $input_file $output_file 1 $measurement_fusion $logical_quibits_per_dimension
            sleep 1
        fi

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