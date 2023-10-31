#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#define D 7
#define TOTAL_MEASUREMENTS D



int loadFileData(FILE* file, int (*array)[D][D+1][(D-1)/2]) {
    int test_id;
    if (fscanf(file, "%x", &test_id) != 1) {
        printf("Error reading file. No more test cases.\n");
        fclose(file);
        return -1;
    }
    for(int k=0;k<D;k++){
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
    // printf("Test id : %x loaded\n",test_id);
    return test_id;
}

int print_output(FILE* file, int (*array)[D][D+1][(D-1)/2], int test) {
    fprintf(file, "%08X\n", test);
    for(int k=0;k<=(D/2);k++){
        for(int i=0; i< D + 1;i++){
            for(int j=0; j< (D-1)/2;j++){
                fprintf(file, "00%06X\n", (*array)[k][i][j]);
            }
        }
    }
    for(int k=D-1;k>=(D/2);k--){
        for(int i=0; i< D + 1;i++){
            for(int j=0; j< (D-1)/2;j++){
                fprintf(file, "00%06X\n", (*array)[k][i][j]);
            }
        }
    }
    return 0;
}

int input_handle(){
    // load syndrome
    int distance = D;
    char filename[100];
    sprintf(filename, "../test_benches/test_data/input_data_%d_rsc.txt", distance);
    FILE* file = fopen(filename, "r");
    if (file == NULL) {
        printf("Error opening file %s.\n", filename);
        return -1;
    }

    char output_filename[100];
    sprintf(output_filename, "../test_benches/test_data/input_data_%d_ctx.txt", distance);
    FILE* file_op = fopen(output_filename, "wb");
    if (file_op == NULL) {
        printf("Error opening file %s.\n", output_filename);
        return -1;
    }

    while(1){
        int syndrome[D][D+1][(D-1)/2];
        int ret_val = loadFileData(file, &syndrome);
        if(ret_val < 0) {
            break;
        }
        print_output(file_op, &syndrome, ret_val);
    }

    fclose(file_op);
    return 0;
}

int output_handle(){
    // load syndrome
    int distance = D;
    char filename[100];
    sprintf(filename, "../test_benches/test_data/output_data_%d_rsc.txt", distance);
    FILE* file = fopen(filename, "r");
    if (file == NULL) {
        printf("Error opening file %s.\n", filename);
        return -1;
    }

    char output_filename[100];
    sprintf(output_filename, "../test_benches/test_data/output_data_%d_ctx.txt", distance);
    FILE* file_op = fopen(output_filename, "wb");
    if (file_op == NULL) {
        printf("Error opening file %s.\n", output_filename);
        return -1;
    }

    while(1){
        int syndrome[D][D+1][(D-1)/2];
        int ret_val = loadFileData(file, &syndrome);
        if(ret_val < 0) {
            break;
        }
        print_output(file_op, &syndrome, ret_val);
    }

    fclose(file_op);
    return 0;
}

int main(){
    input_handle();
    output_handle();
    return 0;
}