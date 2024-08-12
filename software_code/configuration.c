#include <stdio.h>
#include "random_seeds.h"
#include <stdlib.h>
#include <math.h>
#include <time.h>

int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("Usage: %s <filename> <test_runs>\n", argv[0]);
        return 1;
    }

    char *filename = argv[1];
    int test_runs = atoi(argv[2]);

    FILE *file = fopen(filename, "w");
    if (file == NULL) {
        printf("Failed to open file: %s\n", filename);
        return 1;
    }

    // Your code here
    // Initialize decoding
    fprintf(file, "%08x\n", 0x00000000);
    fprintf(file, "%08x\n", 0x00000000);

    for (int i = 0; i < test_runs; i++) {
        fprintf(file, "%08x\n", 0x0000000f);
        fprintf(file, "%08x\n", 0x00020000);
    }

    fclose(file);
    return 0;
}