#include <stdlib.h>
#include <time.h>
#include <limits.h>
#include <stdio.h>

struct RandomSeeds {
    int num_seeds;
    unsigned int* seeds;
    double* values;
};

unsigned int xorshift32(unsigned int seed) {
    unsigned int x = seed;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    // seed = x;
    return x;
}

// Initialize the RandomSeeds struct with n random seeds
struct RandomSeeds* init_random_seeds(int num_seeds) {
    struct RandomSeeds* rs = (struct RandomSeeds*)malloc(sizeof(struct RandomSeeds));
    rs->num_seeds = num_seeds;
    rs->seeds = (int*)malloc(num_seeds * sizeof(int));
    rs->values = (double*)malloc(num_seeds * sizeof(double));

    // Generate random seeds using the current time as a seed
    srand(time(NULL));
    // srand();
    for (int i = 0; i < num_seeds; i++) {
        rs->seeds[i] = rand();
        printf("%d, ", rs->seeds[i]);
        rs->values[i] = 0.0;
    }

    return rs;
}

// Generate the next random value for each seed and return them as an array of doubles between 0 and 1
double* next_random_values(struct RandomSeeds* rs) {
    double* values = (double*)malloc(rs->num_seeds * sizeof(double));
    for (int i = 0; i < rs->num_seeds; i++) {
        // values[i] = (double)rand_r(&rs->seeds[i]) / (double)RAND_MAX;

        //The next two lines are added to test the shiftrandgen replacing the above line
        rs->seeds[i] = xorshift32(rs->seeds[i]);
        values[i] = (double)rs->seeds[i] / (double)UINT_MAX;

        rs->values[i] = values[i];
    }
    return values;
}

// Free the memory used by the RandomSeeds struct
void free_random_seeds(struct RandomSeeds* rs) {
    free(rs->seeds);
    free(rs->values);
    free(rs);
}
