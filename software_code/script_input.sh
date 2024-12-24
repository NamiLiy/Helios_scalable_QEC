#!/bin/bash

distance=5
p=0.000000000001
test_runs=10
num_fpgas=4 #only the leaves
measurement_fusion=0
logical_quibits_per_dimension=4
merge_probability=0.5
num_contexts=2

configuration_file="../test_benches/test_data/configuration_${distance}_0.txt"
gcc configuration.c random_seeds.c -o config -lm
./config $configuration_file $test_runs $logical_quibits_per_dimension $num_fpgas $merge_probability

sleep 1

gcc main.c random_seeds.c -o main -lm
input_prefix="../test_benches/test_data/input_data_${distance}"
./main $distance $p $test_runs $input_prefix $measurement_fusion $logical_quibits_per_dimension $num_fpgas $num_contexts

