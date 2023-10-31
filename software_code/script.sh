#!/bin/bash

gcc main.c random_seeds.c -o main -lm
gcc union_find.c -o uf -lm
gcc context_fix.c -o ctx_fix
./main 
./uf
./ctx_fix 