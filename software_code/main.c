#include <stdio.h>
#include "random_seeds.h"
#include <stdlib.h>
#include <math.h>
#include <time.h>

int max(int a, int b) {
    return (a > b) ? a : b;
}

struct FPGA_ranges {
    int i_min;
    int i_max;
    int j_min;
    int j_max;
}

double normal_random(double mean, double std_dev);

int main(int argc, char *argv[]) {
    if (argc != 8) {
        fprintf(stderr, "Usage: %s <distance> <p> <test_runs> <syndrome_file_prefix> <m_fusion> <qubits_per_dim> <num_leaves>\n", argv[0]);
        return 1;
    }

    int distance = atoi(argv[1]);
    double p = atof(argv[2]);
    int test_runs = atoi(argv[3]);

    char *filename = argv[4];

    int m_fusion = atoi(argv[5]); //0 no fusion, 1 fusion
    int qubits_per_dim = atoi(argv[6]);
    int num_leaves = atoi(argv[7]);

    int distance_i = (distance+1)*qubits_per_dim; //This is ancillas in i direction
    int distance_j = ((distance-1)/2)*qubits_per_dim; //This is ancillas in j direction
    int data_qubits_i = distance_i - 1;//This is data qubits in i direction
    int data_qubits_j = distance_j*2+1;//This is data qubits in j direction
    int meas_rounds = distance*(m_fusion + 1);

    struct FPGA_ranges fpga_ranges[num_leaves];
    for(int f=0; f <num_leaves; f++){
        fpga_ranges[f].i_min = (f < 2) ? 0 : distance_i / 2;
        fpga_ranges[f].i_max = (f < 2) ? (distance_i / 2 - 1 + ((distance + 3)/4)*2) : (distance_i -1);
        fpga_ranges[f].j_min = (f % 2 == 0) ? 0 : (distance_j / 2);
        fpga_ranges[f].j_max = (f % 2 == 0) ?  (distance_j / 2 - 1 + (distance + 1)/4) : (distance_j -1);
    }

    double mean, std_dev;
    mean = p;
    std_dev = 0;

    int max_weight = 2;
    int min_weight = 2;
    int median_weight = (max_weight + min_weight)/2;    

    int data_qubits = data_qubits_i*data_qubits_j;
    int m_error_per_round = distance_i*distance_j;
    int data_errors[meas_rounds][data_qubits_i][data_qubits_j];
    int m_errors[meas_rounds+1][distance_i][distance_j];

    int syndrome [meas_rounds][distance_i][distance_j];

    int errors = 0;
    int syndrome_count = 0;

    struct RandomSeeds* rs = init_random_seeds(data_qubits + m_error_per_round);

    int total_error_count = data_qubits + m_error_per_round;

    double p_array[total_error_count];
    int error_list_scrambled[total_error_count];

    srand(time(NULL));

    printf("\n");

    for (int i = 0; i < total_error_count; i++) {
        p_array[i] = normal_random(mean, std_dev);
        if(p_array[i] < 0.0) p_array[i] = 0.00000000001;
        double weight = -log(p_array[i])/-log(0.001)*median_weight;
        int weight_rounded = (int)round(weight);
        if(weight_rounded > max_weight) weight_rounded = max_weight;
        if(weight_rounded < min_weight) weight_rounded = min_weight;
        error_list_scrambled[i] = weight_rounded;
        //printf("%f %f %d\n", p_array[i], weight, weight_rounded);
    }

    // int ns_count = 0;
    // int ew_count = 0;
    // int ns_weight_list[(distance_i-1)*(distance_j)];
    // int ew_weight_list[(distance_i-1)*distance_j + 1];

    // for (int i = 0; i < data_qubits_i; i++) {
    //     for (int j = 0; j < data_qubits_j; j++) {
    //         if(i==0){ //First row
    //             if(j%2==0 && j < distance - 1){ // Odd columns 
    //                 ew_weight_list[ew_count] = error_list_scrambled[i*data_qubits_j+j];
    //                 ew_count++;
    //             }
    //             else if(j%2==1){ //Even columns
    //                 ns_weight_list[ns_count] = error_list_scrambled[i*data_qubits_j+j];
    //                 ns_count++;
    //             }
    //         } else if(i==distance -1){ // LAst row
    //             if(j==0){
    //                 ew_weight_list[ew_count] = max(error_list_scrambled[i*data_qubits_j+j],error_list_scrambled[(i-1)*data_qubits_j+j]);
    //                 ew_count++;
    //             }
    //             else if(j==distance-1){
    //                 ew_weight_list[ew_count] = error_list_scrambled[i*distance+j];
    //                 ew_count++;
    //             }
    //             else if(j%2==0) {
    //                 ew_weight_list[ew_count] = error_list_scrambled[i*distance+j];
    //                 ew_count++;
    //             }
    //             else if(j%2==1) {
    //                 ns_weight_list[ns_count] = error_list_scrambled[i*distance+j];
    //                 ns_count++;
    //             }
    //         } else if(i%2 ==0) {
    //             if(j==0){
    //                 ew_weight_list[ew_count] = max(error_list_scrambled[i*distance+j],error_list_scrambled[(i-1)*distance+j]);
    //                 ew_count++;
    //             }
    //             else if(j%2 == 0 && j < distance - 1) {
    //                 ew_weight_list[ew_count] = error_list_scrambled[i*distance+j];
    //                 ew_count++;
    //             }
    //             else if(j%2 == 1) {
    //                 ns_weight_list[ns_count] = error_list_scrambled[i*distance+j];
    //                 ns_count++;
    //             }
    //         } else if(i%2 == 1) {
    //             if(j==distance-1){
    //                 ns_weight_list[ns_count] = max(error_list_scrambled[i*distance+j],error_list_scrambled[(i-1)*distance+j]);
    //                 ns_count++;
    //             }
    //             else if(j%2 == 0 && j > 0 && j < distance - 1) {
    //                 ns_weight_list[ns_count] = error_list_scrambled[i*distance+j];
    //                 ns_count++;
    //             }
    //             else if(j%2 == 1) {
    //                 ew_weight_list[ew_count] = error_list_scrambled[i*distance+j];
    //                 ew_count++;
    //             }
    //         }
    //     }
    // }

    // printf("\n");
    // for (int i = 0; i < ns_count; i++) {
    //     printf("32'd%d, ", ns_weight_list[i]);
    // }
    // printf("\n");

    // for (int i = 0; i < ew_count; i++) {
    //     printf("32'd%d, ", ew_weight_list[i]);
    // }
    // printf("\n");

    // for (int i=data_qubits; i < total_error_count; i++) {
    //     printf("32'd%d, ", error_list_scrambled[i]);
    // }
    // printf("\n");



    FILE* out_fp[num_leaves], 
    int c;
    for (int i = 0; i < num_leaves; i++) {
        char filename[100];
        sprintf(filename, "%s_%d.txt", filename, i);
        out_fp[i] = fopen(filename, "wb");
        if (out_fp[i] == NULL) {
            fprintf(stderr, "Can't open output file %s!\n", filename);
            exit(1);
        }
    }

    // out_fp = fopen(filename, "wb");
    // if (out_fp == NULL) {
    //     fprintf(stderr, "Can't open output file %s!\n", "output_3.txt");
    //     exit(1);
    // }

    for (int t = 0; t < test_runs; t++) {
        for (int k = 0; k < meas_rounds; k++) {
            double* values = next_random_values(rs);
            int count = 0;
            for (int i = 0; i < data_qubits_i; i++) {
                for (int j = 0; j < data_qubits_j; j++) {
                    // printf("%f ", values[count]);
                    if (values[count] < p_array[count]) data_errors[k][i][j] = 1;
                    else data_errors[k][i][j] = 0;
                    count++;
                    if(data_errors[k][i][j] == 1) {
                        errors++;
                    }
                }
            }
            for (int i = 0; i < distance_i; i++) {
                for (int j = 0; j < distance_j; j++) {
                    if (values[count] < p) m_errors[k][i][j] = 1;
                    else m_errors[k][i][j] = 0;
                    count++;
                    if(m_errors[k][i][j] == 1) {
                        errors++;
                    }
                }
            }
            free(values);
        }

        for (int i = 0; i < distance_i; i++) {
            for (int j = 0; j < distance_j; j++) {
                m_errors[meas_rounds][i][j] = 0.0;
            }
        }

        // for (int k = 0; k < distance; k++) {
        //     for (int i = 0; i < distance; i++) {
        //         for (int j = 0; j < distance; j++) {
        //             printf("%d ", data_errors[k][i][j]);
                    
        //         }
        //         printf("\n");
        //     }
        //     printf("\n");

        //     for (int i = 0; i < distance+1; i++) {
        //         for (int j = 0; j < (distance-1)/2; j++) {
        //             printf("%d ", m_errors[k][i][j]);
                    
        //         }
        //         printf("\n");
        //     }
        //     printf("\n");
        // }

        for (int k = 0; k < meas_rounds; k++) {
            for (int i = 0; i < distance_i; i++) {
                for (int j = 0; j < distance_j; j++) {
                    if(i==0){
                        syndrome[k][i][j] = data_errors[k][i][j*2] ^ data_errors[k][i][j*2+1] ^ m_errors[k][i][j] ^ m_errors[k+1][i][j];
                    }
                    else if(i==distance_i-1) {
                        syndrome[k][i][j] = data_errors[k][i-1][j*2+1] ^ data_errors[k][i-1][j*2+2] ^ m_errors[k][i][j] ^ m_errors[k+1][i][j];
                    }
                    else if(i%2 == 1) {
                        syndrome[k][i][j] = data_errors[k][i-1][j*2+1] ^ data_errors[k][i-1][j*2+2] ^ data_errors[k][i][j*2+1] ^ data_errors[k][i][j*2+2] ^ m_errors[k][i][j] ^ m_errors[k+1][i][j];
                    } else {
                        syndrome[k][i][j] = data_errors[k][i-1][j*2] ^ data_errors[k][i-1][j*2+1] ^ data_errors[k][i][j*2] ^ data_errors[k][i][j*2+1] ^ m_errors[k][i][j] ^ m_errors[k+1][i][j];
                    }
                    if(syndrome[k][i][j] == 1) {
                        syndrome_count++;
                        // printf("Syndrome at %d %d %d\n", k, i, j);
                    }
                }
            }
        }

        fprintf(out_fp, "%08X\n", t+1);
        for (int k = 0; k < meas_rounds; k++) {
            for (int i = 0; i < distance_i; i++) {
                for (int j = 0; j < distance_j; j++) {
                    //fprintf(out_fp, "%08X\n", syndrome[k][i][j]);
                    if(syndrome[k][i][j] == 1) {
                        for(int f=0; f <num_leaves; f++){
                            if(i >= fpga_ranges[f].i_min && i <= fpga_ranges[f].i_max && j >= fpga_ranges[f].j_min && j <= fpga_ranges[f].j_max){
                                int new_i = i - fpga_ranges[f].i_min;
                                int new_j = j - fpga_ranges[f].j_min;
                                int new_distance_i = fpga_ranges[f].i_max - fpga_ranges[f].i_min + 1;
                                int new_distance_j = fpga_ranges[f].j_max - fpga_ranges[f].j_min + 1;
                                unsigned int defect_address = new_j + (new_i<<((int)(ceil(log2(new_distance_j))))) + (k<<((int)(ceil(log2(new_distance_j)))+(int)(ceil(log2(new_distance_i))));
                                fprintf(out_fp[f], "%08X\n", defect_address);
                            }
                            // unsigned int defect_address = j + (i<<((int)(ceil(log2(distance_j))))) + (k<<((int)(ceil(log2(distance_j)))+(int)(ceil(log2(distance_i))));
                            // fprintf(out_fp[f], "%08X\n", defect_address);
                        }
                    }
                }
                // printf("\n");
            }
            // printf("\n");
        }
        for(int f=0; f <num_leaves; f++){
            printf(out_fp[f], "FFFFFFFF\n");
        }

        // These data is for the FPGA
        /*int write_address = 0x10;
        for (int k = 0; k < distance; k++) {
            unsigned int val = 0;
            unsigned int shift = 0;
            for (int i = 0; i < distance+1; i++) {
                for (int j = 0; j < (distance-1)/2; j++) {
                    val = val | (syndrome[k][i][j] << shift);
                    shift++;
                    if(shift == 8) {
                        if(val>0){
                            printf("Xil_Out32(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + 0x%x, 0x%x);\n", write_address, val);
                        }
                        write_address += 4;
                        fputc(val, out_fp);
                        shift = 0;
                        val = 0;
                    }
                }
            }
            if(shift != 0) {
                if(val>0){
                    printf("Xil_Out32(XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR + 0x%x, 0x%x);\n", write_address, val);
                }
                write_address += 4;
                fputc(val, out_fp);
            }
        }*/
    }
    for (int i = 0; i < num_leaves; i++) {
        fclose(out_fp[i]);
    }

    // in_fp = fopen("../test_benches/test_data/test_file_d17_p001.bin", "rb");
    // while ((c = fgetc(in_fp)) != EOF) {
    //     printf("%d\n", c);
    // }

    // fclose(out_fp);


    printf("Errors: %d\n", errors);
    printf("Error rate actual %f\n", (double)errors/(double)(test_runs*(data_qubits + m_error_per_round)*distance));
    printf("Syndrome count: %d\n", syndrome_count);
    printf("Syndrome rate actual %f\n", (double)syndrome_count/(double)(test_runs*(distance+1)*((distance-1)/2)*(distance)));

    free_random_seeds(rs);

    return 0;
}

// Generate a random number from a standard normal distribution
double normal_random(double mean, double std_dev)
{
    double u1 = (double)rand() / RAND_MAX;
    double u2 = (double)rand() / RAND_MAX;

    double z = sqrt(-2.0 * log(u1)) * cos(2.0 * M_PI * u2);

    return mean + std_dev * z;
}
