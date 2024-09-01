#include <stdio.h>
#include "random_seeds.h"
#include <stdlib.h>
#include <math.h>
#include <time.h>


int main(int argc, char *argv[]) {
    if (argc != 6) {
        printf("Usage: %s <filename> <test_runs> <logical_qubits_per_dim> <num_fpgas> <p_merge>\n", argv[0]);
        return 1;
    }

    char *filename = argv[1];
    int test_runs = atoi(argv[2]);
    int logical_qubits_per_dim = atoi(argv[3]);
    int num_fpgas = atoi(argv[4]);
    double p_merge = atof(argv[5]);

    struct RandomSeeds* rs = init_random_seeds((logical_qubits_per_dim-1)*logical_qubits_per_dim*2);

    int horizontal_borders[logical_qubits_per_dim][logical_qubits_per_dim-1];
    int vertical_borders[logical_qubits_per_dim-1][logical_qubits_per_dim];

    


    int merge_prob = 0;

    FILE *file = fopen(filename, "w");
    if (file == NULL) {
        printf("Failed to open file: %s\n", filename);
        return 1;
    }

    // Your code here
    // Initialize decoding
    fprintf(file, "%08x\n", 0x00000000); //LSB
    fprintf(file, "%08x\n", 0x00000000); //MSB

    for (int i = 0; i < test_runs; i++) {
        fprintf(file, "%08x\n", 0x0000000f);
        fprintf(file, "%08x\n", 0x00020000);
        double* values = next_random_values(rs);
        
        int index = 0;
        for(int j = 0; j < logical_qubits_per_dim; j++){
            for(int k = 0; k < logical_qubits_per_dim-1; k++){
                horizontal_borders[j][k] = 0;
            }
        }
        for(int j = 0; j < logical_qubits_per_dim-1; j++){
            for(int k = 0; k < logical_qubits_per_dim; k++){
                vertical_borders[j][k] = 0;
            }
        }

        //horizintal merges
        for (int j = 0; j < logical_qubits_per_dim; j++) {
            for(int k = 0; k < logical_qubits_per_dim-1; k++){
                // horizontal_borders[j][k] = index;
                if(values[index] < p_merge){
                    horizontal_borders[j][k] = 1;
                    merge_prob++;
                }
                index++;
            }
        }

        //vertical merges
        for (int j = 0; j < logical_qubits_per_dim-1; j++) {
            for(int k = 0; k < logical_qubits_per_dim; k++){
                // vertical_borders[j][k] = index;
                if(values[index] < p_merge){
                    vertical_borders[j][k] = 1;
                    merge_prob++;
                }
                index++;
            }
        }

        // handle fpga_1

        for(int n=0;n<num_fpgas;n++){
            int num_borders = 0;
            if(n == 0){
                num_borders = (logical_qubits_per_dim/2 + 2)*(logical_qubits_per_dim/2+1) + (logical_qubits_per_dim/2 + 2)*(logical_qubits_per_dim/2+1);
            } else if(n==1 || n==2){
                num_borders = (logical_qubits_per_dim/2 + 1)*(logical_qubits_per_dim/2+1) + (logical_qubits_per_dim/2 + 2)*(logical_qubits_per_dim/2);
            } else if(n==3){
                num_borders = (logical_qubits_per_dim/2 + 1)*(logical_qubits_per_dim/2) + (logical_qubits_per_dim/2 + 1)*(logical_qubits_per_dim/2);
            }
            int fpga_borders[num_borders];
            index = 0;

            // horizontal borders
            int j_start = (n==0 || n==1) ? 0 : (logical_qubits_per_dim/2);
            int j_end = (n==0 || n==1) ? (logical_qubits_per_dim/2) : (logical_qubits_per_dim-1);
            int k_start = (n==0 || n==2) ? 0 : (logical_qubits_per_dim/2-1);
            int k_end = (n==0 || n==2) ? (logical_qubits_per_dim/2-1) : (logical_qubits_per_dim-2);
            for (int j = j_start; j <= j_end; j++) {
                if(n==0 || n==2){
                    fpga_borders[index] = 0;
                    index++;
                }
                for(int k = k_start; k <= k_end; k++){
                    fpga_borders[index] = horizontal_borders[j][k];
                    index++;
                }
                fpga_borders[index] = 0;
                index++;
            }

            // vertical borders
            j_start = (n==0 || n==1) ? 0 : (logical_qubits_per_dim/2-1);
            j_end = (n==0 || n==1) ? (logical_qubits_per_dim/2-1) : (logical_qubits_per_dim-2);
            k_start = (n==0 || n==2) ? 0 : (logical_qubits_per_dim/2);
            k_end = (n==0 || n==2) ? (logical_qubits_per_dim/2) : (logical_qubits_per_dim-1);
            if(n==0 || n==1){
                for(int k = k_start; k <= k_end; k++){
                    fpga_borders[index] = 0;
                    index++;
                }
            }

            for (int j = j_start; j <=j_end; j++) {
                for(int k = k_start; k <= k_end; k++){
                    fpga_borders[index] = vertical_borders[j][k];
                    index++;
                }
            }

            for(int k = k_start; k <= k_end; k++){
                fpga_borders[index] = 0;
                index++;
            }

            for(int j = 0; j < num_borders; j++){
                printf("%d ", fpga_borders[j]);
            }
            printf("\n");

            for(int j = (num_borders+47)/48-1; j >= 0; j--){
                int value = 0;
                for(int k = 0; k < 32; k++){
                    value = value | (fpga_borders[j*48+k] << k);
                    if(j*48+k == num_borders-1){
                        break;
                    }
                }
                fprintf(file, "%08x\n", value);
                value = 0;
                for(int k = 32; k < 48; k++){
                    if(j*48+32+k > num_borders-1){
                        break;
                    }
                    value = value | (fpga_borders[j*48+32+k] << k);
                }
                fprintf(file, "%02x03%04x\n", (n+1),value);
            }
        }
        
        free(values);

        
        
    }

    free_random_seeds(rs);

    printf("Merge probability: %f\n", (double)merge_prob/(test_runs*(logical_qubits_per_dim-1)*logical_qubits_per_dim*2));
    fclose(file);
    return 0;
}