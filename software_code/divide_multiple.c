#include <stdio.h>
#include <stdlib.h>
#include <string.h> // Include for string handling functions

int handle_input_data(int distance, char *syndrome_filename, int num_fpgas) {

    FILE* syndrome_file = fopen(syndrome_filename, "r");
    if (syndrome_file == NULL) {
        printf("Error opening file %s.\n", syndrome_filename);
        return -1;
    }

    FILE** syndrome_out_file = malloc(num_fpgas * sizeof(FILE*));
    if (syndrome_out_file == NULL) {
        perror("Error allocating memory for file pointers");
        fclose(syndrome_file);
        return 1;
    }

    for (int i = 0; i < num_fpgas; i++) {
        char base_filename[256]; // Buffer for the base filename
        strncpy(base_filename, syndrome_filename, strlen(syndrome_filename) - 4); // Copy filename without '.txt'
        base_filename[strlen(syndrome_filename) - 4] = '\0'; // Null-terminate the string

        char output_filename[256]; // Buffer for the final output filename
        snprintf(output_filename, sizeof(output_filename), "%s_%d.txt", base_filename, i + 1);

        syndrome_out_file[i] = fopen(output_filename, "w");
        if (syndrome_out_file[i] == NULL) {
            perror("Error opening output file");
            fclose(syndrome_file);
            // Close any previously opened files before exiting
            for (int j = 0; j < i; ++j) {
                fclose(syndrome_out_file[j]);
            }
            free(syndrome_out_file);
            return 1;
        }
    }

    int distance_k = distance;
    int distance_i = (distance+1)*num_fpgas;
    int distance_j = (distance-1)/2;

    int initial_syndrome_array[distance_k][distance_i][distance_j];

    while(1) {
        int test_id;
        if (fscanf(syndrome_file, "%x", &test_id) != 1) {
            printf("Error reading file.\n");
            fclose(syndrome_file);
            for (int j = 0; j < num_fpgas; ++j) {
                fclose(syndrome_out_file[j]);
            }
            free(syndrome_out_file);
            return 1;
        }


        for(int k=0;k<distance_k; k++){
            for(int i=0; i< distance_i; i++){
                for(int j=0; j< distance_j ;j++){
                    int value;
                    if (fscanf(syndrome_file, "%x", &value) != 1) {
                        printf("Error reading file.\n");
                            fclose(syndrome_file);
                        for (int j = 0; j < num_fpgas; ++j) {
                            fclose(syndrome_out_file[j]);
                        }
                        free(syndrome_out_file);
                        return 1;
                    }
                    initial_syndrome_array[k][i][j] = value;
                }
            }
        }

        for (int l = 0; l < num_fpgas; l++) {
            fprintf(syndrome_out_file[l], "%08X\n", test_id);
            for(int k=0;k<distance_k; k++){
                for(int i=0; i< distance + 1; i++){
                    for(int j=0; j< distance_j ;j++){
                        fprintf(syndrome_out_file[l], "%08X\n", initial_syndrome_array[k][l*(distance + 1) + i][j]);
                    }
                }
            }
        }
    }

    return 0;
}

int handle_output_data(int distance, char *syndrome_filename, int num_fpgas) {

    FILE* syndrome_file = fopen(syndrome_filename, "r");
    if (syndrome_file == NULL) {
        printf("Error opening file %s.\n", syndrome_filename);
        return -1;
    }

    FILE** syndrome_out_file = malloc(num_fpgas * sizeof(FILE*));
    if (syndrome_out_file == NULL) {
        perror("Error allocating memory for file pointers");
        fclose(syndrome_file);
        return 1;
    }

    for (int i = 0; i < num_fpgas; i++) {
        char base_filename[256]; // Buffer for the base filename
        strncpy(base_filename, syndrome_filename, strlen(syndrome_filename) - 4); // Copy filename without '.txt'
        base_filename[strlen(syndrome_filename) - 4] = '\0'; // Null-terminate the string

        char output_filename[256]; // Buffer for the final output filename
        snprintf(output_filename, sizeof(output_filename), "%s_%d.txt", base_filename, i + 1);

        syndrome_out_file[i] = fopen(output_filename, "w");
        if (syndrome_out_file[i] == NULL) {
            perror("Error opening output file");
            fclose(syndrome_file);
            // Close any previously opened files before exiting
            for (int j = 0; j < i; ++j) {
                fclose(syndrome_out_file[j]);
            }
            free(syndrome_out_file);
            return 1;
        }
    }

    int distance_k = distance;
    int distance_i = (distance+1)*num_fpgas;
    int distance_j = (distance-1)/2;

    int initial_syndrome_array[distance_k][distance_i][distance_j];

    while(1) {
        int test_id;
        if (fscanf(syndrome_file, "%x", &test_id) != 1) {
            printf("Error reading file.\n");
            fclose(syndrome_file);
            for (int j = 0; j < num_fpgas; ++j) {
                fclose(syndrome_out_file[j]);
            }
            free(syndrome_out_file);
            return 1;
        }


        for(int k=0;k<distance_k; k++){
            for(int i=0; i< distance_i; i++){
                for(int j=0; j< distance_j ;j++){
                    int value;
                    if (fscanf(syndrome_file, "%x", &value) != 1) {
                        printf("Error reading file.\n");
                            fclose(syndrome_file);
                        for (int j = 0; j < num_fpgas; ++j) {
                            fclose(syndrome_out_file[j]);
                        }
                        free(syndrome_out_file);
                        return 1;
                    }
                    initial_syndrome_array[k][i][j] = value;
                }
            }
        }

        for (int l = 0; l < num_fpgas; l++) {
            fprintf(syndrome_out_file[l], "%08X\n", test_id);
            for(int k=0;k<distance_k; k++){
                for(int i=0; i< distance + 1; i++){
                    for(int j=0; j< distance_j ;j++){
                        int value =  initial_syndrome_array[k][l*(distance + 1) + i][j];
                        int f_id = (value >> 24) & 0xFF; // Extracts the first 8 bits
                        int k_id = (value >> 16) & 0xFF; // Extracts the second 8 bits
                        int i_id = (value >> 8) & 0xFF;  // Extracts the third 8 bits
                        int j_id = value & 0xFF;         // Extracts the fourth 8 bits
                        f_id = f_id/(distance + 1) + 1;
                        i_id = f_id%(distance + 1);
                        fprintf(syndrome_out_file[l], "%02X%02X%02X%02X\n", f_id, k_id, i_id, j_id);
                    }
                }
            }
        }
    }

    return 0;
}


int main(int argc, char *argv[]) {
    if (argc != 5) {
        fprintf(stderr, "Usage: %s <distance> <syndrome_filename> <root_filename> <num_fpgas>\n", argv[0]);
        return 1;
    }

    int distance = atoi(argv[1]);
    char *syndrome_filename = argv[2];
    char *root_filename = argv[3];
    int num_fpgas = atoi(argv[4]);

    handle_input_data(distance, syndrome_filename, num_fpgas);
    handle_output_data(distance, root_filename, num_fpgas);
    return 0;
}

