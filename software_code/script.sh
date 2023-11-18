#!/bin/bash

gcc main.c random_seeds.c -o main -lm
gcc union_find.c -o uf -lm
./main 
./uf