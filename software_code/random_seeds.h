#ifndef RANDOM_SEEDS_H
#define RANDOM_SEEDS_H

#include <stdlib.h>
#include <time.h>

struct RandomSeeds {
    int num_seeds;
    int* seeds;
    double* values;
};

struct RandomSeeds* init_random_seeds(int num_seeds);

double* next_random_values(struct RandomSeeds* rs);

void free_random_seeds(struct RandomSeeds* rs);

#endif /* RANDOM_SEEDS_H */