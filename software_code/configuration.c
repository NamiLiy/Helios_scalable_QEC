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

    // It seems I have messed the words horizontal and vertical in this code
    int horizontal_borders[logical_qubits_per_dim][logical_qubits_per_dim-1];
    int vertical_borders[logical_qubits_per_dim-1][logical_qubits_per_dim];

    


    int merge_prob = 0;

    FILE *file = fopen(filename, "w");
    if (file == NULL) {
        printf("Failed to open file: %s\n", filename);
        return 1;
    }

    FILE *file2 = fopen("configuration_dump.txt", "w");
    if (file2 == NULL) {
        printf("Failed to open file: %s\n", "configuration_dump.txt");
        return 1;
    }

    // Your code here
    // Initialize decoding
    fprintf(file, "%08x\n", 0x00000000); //LSB
    fprintf(file, "%08x\n", 0x00000000); //MSB

    for (int i = 0; i < test_runs; i++) {
        
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

        // dump configuration
        fprintf(file2, "Test %d\n",(i+1));
        for (int j = 0; j < logical_qubits_per_dim; j++) {
            for(int k = 0; k < logical_qubits_per_dim-1; k++){
                fprintf(file2, "%d ", horizontal_borders[j][k]);
            }
        }
        fprintf(file2, "\n");
        for (int j = 0; j < logical_qubits_per_dim-1; j++) {
            for(int k = 0; k < logical_qubits_per_dim; k++){
                fprintf(file2, "%d ", vertical_borders[j][k]);
            }
        }
        fprintf(file2, "\n");
        

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

            fprintf(file2, "FPGA %d\n",(n+1));
            for(int j = 0; j < num_borders; j++){
                fprintf(file2, "%d ", fpga_borders[j]);
            }
            fprintf(file2, "\n");

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
                fprintf(file, "%02x01%04x\n", (n+1),value);
            }
        }
        
        free(values);

        // fprintf(file, "%08x\n", 0x0000000f); // Peel and finish
        fprintf(file, "%08x\n", 0x0000000e); // Fuse with the previous round
        fprintf(file, "%08x\n", 0x00020000);
        
    }

    free_random_seeds(rs);

    printf("Merge probability: %f\n", (double)merge_prob/(test_runs*(logical_qubits_per_dim-1)*logical_qubits_per_dim*2));
    fclose(file);
    fclose(file2);
    return 0;
}