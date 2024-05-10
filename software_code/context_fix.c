#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#define D 5
#define TOTAL_MEASUREMENTS D*2
#define NUM_CONTEXTS 2
#define fpga_id 1

#define distance_per_context ((TOTAL_MEASUREMENTS + NUM_CONTEXTS - 1)/NUM_CONTEXTS)
#define rounded_distance (distance_per_context*NUM_CONTEXTS)



int loadFileData(FILE* file, int (*array)[rounded_distance][D+1][(D-1)/2]) {
    int test_id;
    if (fscanf(file, "%x", &test_id) != 1) {
        printf("Error reading file. No more test cases.\n");
        fclose(file);
        return -1;
    }
    for(int k=0;k<rounded_distance;k++){
        for(int i=0; i< D + 1;i++){
            for(int j=0; j< (D-1)/2;j++){
                (*array)[k][i][j] = 0;
            }
        }
    }
    for(int k=0;k<TOTAL_MEASUREMENTS; k++){
        for(int i=0; i< D + 1;i++){
            for(int j=0; j< (D-1)/2;j++){
                int value;
                if (fscanf(file, "%x", &value) != 1) {
                    printf("Error reading file.\n");
                    fclose(file);
                    return -1;
                }
                (*array)[k][i][j] = value;
            }
        }
    }
    // for(int i=0; i< D + 1;i++){
    //     for(int j=0; j< (D-1)/2;j++){
    //         (*array)[D][i][j] = 0;
    //     }
    // }
    // printf("Test id : %x loaded\n",test_id);
    return test_id;
}

int print_output(FILE* file, int (*array)[rounded_distance][D+1][(D-1)/2], int test, int flag) {

    fprintf(file, "%08X\n", test);

#if NUM_CONTEXTS == 2
    for(int k=0;k<(TOTAL_MEASUREMENTS/2);k++){
        for(int i=0; i< D + 1;i++){
            for(int j=0; j< (D-1)/2;j++){
                fprintf(file, "00%06X\n", (*array)[k][i][j]);
            }
        }
    }
    for(int k=TOTAL_MEASUREMENTS-1;k>=(TOTAL_MEASUREMENTS/2);k--){
        for(int i=0; i< D + 1;i++){
            for(int j=0; j< (D-1)/2;j++){
                fprintf(file, "00%06X\n", (*array)[k][i][j]);
            }
        }
    }
#endif
#if NUM_CONTEXTS > 2
    
    for(int l=0;l<NUM_CONTEXTS;l++){
		if(l%2==0) {
            for(int k=0;k< distance_per_context;k++){
                for(int i=0; i< D + 1;i++){
                    for(int j=0; j< (D-1)/2;j++){
                        if(flag)
                            fprintf(file, "01%06X\n", (*array)[l*distance_per_context + k][i][j]);
                        else
                            fprintf(file, "00%06X\n", (*array)[l*distance_per_context + k][i][j]);
                    }
                }
            }
        } else{
            for(int k=distance_per_context-1; k>=0; k--){
                for(int i=0; i< D + 1;i++){
                    for(int j=0; j< (D-1)/2;j++){
                        if(flag)
                            fprintf(file, "01%06X\n", (*array)[l*distance_per_context + k][i][j]);
                        else
                            fprintf(file, "00%06X\n", (*array)[l*distance_per_context + k][i][j]);
                    }
                }
            }
        }
    }
#endif

    return 0;
}

int print_detailed_output(FILE* file, int (*array)[rounded_distance][D+1][(D-1)/2], int test) {

    fprintf(file, "Test id %d\n", test);

    for(int k=0;k<TOTAL_MEASUREMENTS;k++){
        for(int i=0; i< D + 1;i++){
            for(int j=0; j< (D-1)/2;j++){
                if ((*array)[k][i][j] == 1) {
                    fprintf(file, "k = %d i = %d j = %d\n", k, i, j);
                }
            }
        }
    }

    return 0;
}


int input_handle(FILE* file, FILE* file_op){
    // load syndrome
    int distance = D;
    // char filename[100];
    // // sprintf(filename, "../test_benches/test_data/input_data_%d_rsc.txt", distance);
    // sprintf(filename, "sample_out.csv");
    // FILE* file = fopen(filename, "r");
    // if (file == NULL) {
    //     printf("Error opening file %s.\n", filename);
    //     return -1;
    // }

    char detail_filename[100];
    sprintf(detail_filename, "../test_benches/test_data/input_data_details_rsc.txt");
    //sprintf(detail_filename, "simple_fixed.csv");
    FILE* file_det = fopen(detail_filename, "wb");
    if (file == NULL) {
        printf("Error opening detailed file %s.\n", detail_filename);
        return -1;
    }

    // char output_filename[100];
    // // sprintf(output_filename, "../test_benches/test_data/input_data_%d_%d.txt", distance, fpga_id);
    // sprintf(output_filename, "sample_fixed.csv");
    // FILE* file_op = fopen(output_filename, "wb");
    // if (file_op == NULL) {
    //     printf("Error opening file %s.\n", output_filename);
    //     return -1;
    // }

    while(1){
        int syndrome[rounded_distance][D+1][(D-1)/2];
        int ret_val = loadFileData(file, &syndrome);
        if(ret_val < 0) {
            break;
        }
        print_detailed_output(file_det, &syndrome, ret_val);
        print_output(file_op, &syndrome, ret_val, 0);
    }

    fclose(file_op);
    return 0;
}

int output_handle(FILE* file, FILE* file_op){
    // load syndrome
    int distance = D;
    // char filename[100];
    // sprintf(filename, "../test_benches/test_data/output_data_%d_rsc.txt", distance);
    // FILE* file = fopen(filename, "r");
    // if (file == NULL) {
    //     printf("Error opening file %s.\n", filename);
    //     return -1;
    // }

    // char output_filename[100];
    // sprintf(output_filename, "../test_benches/test_data/output_data_%d_%d.txt", distance, fpga_id);
    // FILE* file_op = fopen(output_filename, "wb");
    // if (file_op == NULL) {
    //     printf("Error opening file %s.\n", output_filename);
    //     return -1;
    // }

    while(1){
        int syndrome[rounded_distance][D+1][(D-1)/2];
        int ret_val = loadFileData(file, &syndrome);
        if(ret_val < 0) {
            break;
        }
        print_output(file_op, &syndrome, ret_val, 1);
    }

    fclose(file_op);
    return 0;
}

int main(int argc, char *argv[]) {

    if (argc != 6) {
        printf("Usage: %s <distance> <input_filename_original> <input_filename_modified> <output_filename_original> <output_filename_modified>\n", argv[0]);
        return 1;
    }

    // Convert first argument to integer for distance
    int d = atoi(argv[1]);
    
    // The second and third arguments are file names
    char *input_filename_original = argv[2];
    char *input_filename_modified = argv[3];
    char *output_filename_original = argv[4];
    char *output_filename_modified = argv[5];

    // Open the original input file
    FILE* file_input_original = fopen(input_filename_original, "r");
    if (file_input_original == NULL) {
        printf("Error opening file %s.\n", input_filename_original);
        return -1;
    }

    // Open the modified input file
    FILE* file_input_modified = fopen(input_filename_modified, "wb");
    if (file_input_modified == NULL) {
        printf("Error opening file %s.\n", input_filename_modified);
        return -1;
    }

    // Open the original output file
    FILE* file_output_original = fopen(output_filename_original, "r");
    if (file_output_original == NULL) {
        printf("Error opening file %s.\n", output_filename_original);
        return -1;
    }

    // Open the modified output file
    FILE* file_output_modified = fopen(output_filename_modified, "wb");
    if (file_output_modified == NULL) {
        printf("Error opening file %s.\n", output_filename_modified);
        return -1;
    }

    // Handle the input files
    input_handle(file_input_original, file_input_modified);
    
    // Handle the output files
    output_handle(file_output_original, file_output_modified);

    // fclose(file_input_original);
    // fclose(file_input_modified);
    // fclose(file_output_original);
    // fclose(file_output_modified);

    return 0;
}
