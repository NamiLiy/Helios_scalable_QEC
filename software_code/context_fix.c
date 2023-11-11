#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#define D 27
#define TOTAL_MEASUREMENTS D
#define NUM_CONTEXTS 14

#define distance_per_context ((D + NUM_CONTEXTS - 1)/NUM_CONTEXTS)
#define rounded_distance (distance_per_context*NUM_CONTEXTS)



int loadFileData(FILE* file, int (*array)[rounded_distance][D+1][(D-1)/2]) {
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
    for(int i=0; i< D + 1;i++){
        for(int j=0; j< (D-1)/2;j++){
            (*array)[D][i][j] = 0;
        }
    }
    // printf("Test id : %x loaded\n",test_id);
    return test_id;
}

<<<<<<< HEAD
int print_output(FILE* file, int (*array)[rounded_distance][D+1][(D-1)/2], int test) {
=======
int print_output(FILE* file, int (*array)[D+1][D+1][(D-1)/2], int test) {
>>>>>>> 931f2c2651a264d3a8181a6aaf38e47b42e9c75c

    fprintf(file, "%08X\n", test);

#if NUM_CONTEXTS == 2
    for(int k=0;k<=(D/2);k++){
        for(int i=0; i< D + 1;i++){
            for(int j=0; j< (D-1)/2;j++){
                fprintf(file, "00%06X\n", (*array)[k][i][j]);
            }
        }
    }
    for(int k=D;k>(D/2);k--){
        for(int i=0; i< D + 1;i++){
            for(int j=0; j< (D-1)/2;j++){
                fprintf(file, "00%06X\n", (*array)[k][i][j]);
            }
        }
    }
#endif
<<<<<<< HEAD
#if NUM_CONTEXTS > 2
    
    for(int l=0;l<NUM_CONTEXTS;l++){
		if(l%2==0) {
            for(int k=0;k< distance_per_context;k++){
                for(int i=0; i< D + 1;i++){
                    for(int j=0; j< (D-1)/2;j++){
                        fprintf(file, "00%06X\n", (*array)[l*distance_per_context + k][i][j]);
                    }
                }
            }
        } else{
            for(int k=distance_per_context-1; k>=0; k--){
                for(int i=0; i< D + 1;i++){
                    for(int j=0; j< (D-1)/2;j++){
                        fprintf(file, "00%06X\n", (*array)[l*distance_per_context + k][i][j]);
                    }
                }
=======
#if NUM_CONTEXTS == 4
    for(int k=0;k<=(D/4);k++){
        for(int i=0; i< D + 1;i++){
            for(int j=0; j< (D-1)/2;j++){
                fprintf(file, "00%06X\n", (*array)[k][i][j]);
            }
        }
    }
    for(int k=D/2; k>(D/4); k--){
        for(int i=0; i< D + 1;i++){
            for(int j=0; j< (D-1)/2;j++){
                fprintf(file, "00%06X\n", (*array)[k][i][j]);
            }
        }
    }
    for(int k=D/2 + 1; k<=(3*D/4);k++){
        for(int i=0; i< D + 1;i++){
            for(int j=0; j< (D-1)/2;j++){
                fprintf(file, "00%06X\n", (*array)[k][i][j]);
            }
        }
    }
    for(int k=D; k>(3*D/4); k--){
        for(int i=0; i< D + 1;i++){
            for(int j=0; j< (D-1)/2;j++){
                fprintf(file, "00%06X\n", (*array)[k][i][j]);
>>>>>>> 931f2c2651a264d3a8181a6aaf38e47b42e9c75c
            }
        }
    }
#endif

    return 0;
}

int print_detailed_output(FILE* file, int (*array)[D+1][D+1][(D-1)/2], int test) {

    fprintf(file, "Test id %d\n", test);

    for(int k=0;k<D;k++){
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

    char detail_filename[100];
    sprintf(detail_filename, "../test_benches/test_data/input_data_details_rsc.txt");
    FILE* file_det = fopen(detail_filename, "wb");
    if (file == NULL) {
        printf("Error opening detailed file %s.\n", filename);
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
        int syndrome[D+1][D+1][(D-1)/2];
        int ret_val = loadFileData(file, &syndrome);
        if(ret_val < 0) {
            break;
        }
        print_detailed_output(file_det, &syndrome, ret_val);
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
        int syndrome[D+1][D+1][(D-1)/2];
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