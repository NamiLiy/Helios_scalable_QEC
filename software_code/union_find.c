#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#define D 13
#define TOTAL_MEASUREMENTS D

struct Distance {
    int k;
    int i;
    int j;
};

struct Address {
    int k;
    int i;
    int j;
    int is_boundary_address;
};

struct Node {
    struct Address root;
    struct Address id;
    int parity;
    int boundary;
};

struct Edge {
    int growth;
    struct Address a;
    struct Address b;
    int to_be_updated;
    int is_boundary;
};

int max(int a, int b) {
    return (a > b) ? a : b;
}

struct Node node_array[D][D+1][(D-1)/2];
struct Edge hor_edges[D][D][D];
struct Edge ver_edges[D][D+1][(D-1)/2];

struct Address get_root(struct Address a){
    if(node_array[a.k][a.i][a.j].id.k == node_array[a.k][a.i][a.j].root.k &&
        node_array[a.k][a.i][a.j].id.i == node_array[a.k][a.i][a.j].root.i &&
        node_array[a.k][a.i][a.j].id.j == node_array[a.k][a.i][a.j].root.j){
            struct Address ret = {node_array[a.k][a.i][a.j].id.k,
                                    node_array[a.k][a.i][a.j].id.i,
                                    node_array[a.k][a.i][a.j].id.j,
                                    node_array[a.k][a.i][a.j].id.is_boundary_address};
            return ret;
    }  else {
        return get_root(node_array[a.k][a.i][a.j].root);
    }
}

int get_parity(struct Address a){
    struct Address root = get_root(a);
    return node_array[root.k][root.i][root.j].parity;
}

int grow(int k, int i, int j, int direction){
    // If odd increase growth
    // If fully grown mark as to_be_updated
    // Update change_occur
    int grow_ret = 0;
    if(direction ==0){
        if(hor_edges[k][i][j].is_boundary == 1){
            int is_odd = get_parity(hor_edges[k][i][j].a);
            if (is_odd && hor_edges[k][i][j].growth < 2) {
                hor_edges[k][i][j].growth = hor_edges[k][i][j].growth + 1;
                grow_ret = 1;
                if(hor_edges[k][i][j].growth == 2){
                    hor_edges[k][i][j].to_be_updated = 1;
                }
            }
        } else{
            int is_odd = get_parity(hor_edges[k][i][j].a);
            if (is_odd && hor_edges[k][i][j].growth < 2) {
                hor_edges[k][i][j].growth = hor_edges[k][i][j].growth + 1;
                grow_ret = 1;
                if(hor_edges[k][i][j].growth == 2){
                    hor_edges[k][i][j].to_be_updated = 1;
                }
            }
            is_odd = get_parity(hor_edges[k][i][j].b);
            if (is_odd && hor_edges[k][i][j].growth < 2) {
                hor_edges[k][i][j].growth = hor_edges[k][i][j].growth + 1;
                grow_ret = 1;
                if(hor_edges[k][i][j].growth == 2){
                    hor_edges[k][i][j].to_be_updated = 1;
                }
            }
        }
    } else {
        if(ver_edges[k][i][j].is_boundary == 1){
            int is_odd = get_parity(ver_edges[k][i][j].a);
            if (is_odd && ver_edges[k][i][j].growth < 2) {
                ver_edges[k][i][j].growth = ver_edges[k][i][j].growth + 1;
                grow_ret = 1;
                if(ver_edges[k][i][j].growth == 2){
                    ver_edges[k][i][j].to_be_updated = 1;
                }
            }
        } else{
            int is_odd = get_parity(ver_edges[k][i][j].a);
            if (is_odd && ver_edges[k][i][j].growth < 2) {
                ver_edges[k][i][j].growth = ver_edges[k][i][j].growth + 1;
                grow_ret = 1;
                if(ver_edges[k][i][j].growth == 2){
                    ver_edges[k][i][j].to_be_updated = 1;
                }
            }
            is_odd = get_parity(ver_edges[k][i][j].b);
            if (is_odd && ver_edges[k][i][j].growth < 2) {
                ver_edges[k][i][j].growth = ver_edges[k][i][j].growth + 1;
                grow_ret = 1;
                if(ver_edges[k][i][j].growth == 2){
                    ver_edges[k][i][j].to_be_updated = 1;
                }
            }
        }
    }
    return grow_ret;
}

int update_boundary(struct Address a){
    struct Address root = get_root(a);
    if( root.is_boundary_address == 1 ||
        (root.is_boundary_address == 0  && a.k < root.k) || 
        (root.is_boundary_address == 0  && a.k == root.k && a.i < root.i) || 
        (root.is_boundary_address == 0 && a.k == root.k && a.i == root.i && a.j < root.j)){
            // This node should now be the root
            node_array[root.k][root.i][root.j].root.k = a.k;
            node_array[root.k][root.i][root.j].root.i = a.i;
            node_array[root.k][root.i][root.j].root.j = a.j;

            node_array[a.k][a.i][a.j].parity = 0;
            node_array[a.k][a.i][a.j].boundary = 1;
            node_array[a.k][a.i][a.j].root.k = a.k;
            node_array[a.k][a.i][a.j].root.i = a.i;
            node_array[a.k][a.i][a.j].root.j = a.j;
            node_array[a.k][a.i][a.j].root.is_boundary_address = 0;
            node_array[a.k][a.i][a.j].id.is_boundary_address = 0;
    }
    return 0;
}

int merge_internal(struct Address a, struct Address b){
    struct Address root_a = get_root(a);
    struct Address root_b = get_root(b);
    if(root_a.k == root_b.k && root_a.i == root_b.i && root_a.j == root_b.j){
        // They are the same cluster. No merge
        return 0;
    }

    if(root_a.is_boundary_address < root_b.is_boundary_address ||
        (root_a.is_boundary_address == root_b.is_boundary_address  && root_a.k < root_b.k) || 
        (root_a.is_boundary_address == root_b.is_boundary_address  && root_a.k == root_b.k && root_a.i < root_b.i) || 
        (root_a.is_boundary_address == root_b.is_boundary_address && root_a.k == root_b.k && root_a.i == root_b.i && root_a.j < root_b.j)){
        // A has a lower root
        if(node_array[root_b.k][root_b.i][root_b.j].boundary == 1){
            node_array[root_a.k][root_a.i][root_a.j].parity = 0;
            node_array[root_a.k][root_a.i][root_a.j].boundary = 1;
        } else if(node_array[root_a.k][root_a.i][root_a.j].boundary == 1){
            ;
        } else {
            node_array[root_a.k][root_a.i][root_a.j].parity = node_array[root_a.k][root_a.i][root_a.j].parity ^ node_array[root_b.k][root_b.i][root_b.j].parity;
        }

        node_array[root_b.k][root_b.i][root_b.j].root.k = root_a.k;
        node_array[root_b.k][root_b.i][root_b.j].root.i = root_a.i;
        node_array[root_b.k][root_b.i][root_b.j].root.j = root_a.j;
        node_array[root_b.k][root_b.i][root_b.j].root.is_boundary_address = root_a.is_boundary_address;
    } else {
        // B has the lower root
        if(node_array[root_a.k][root_a.i][root_b.j].boundary == 1){
            node_array[root_b.k][root_b.i][root_b.j].parity = 0;
            node_array[root_b.k][root_b.i][root_b.j].boundary = 1;
        } else if(node_array[root_b.k][root_b.i][root_b.j].boundary == 1){
            ;
        } else {
            node_array[root_b.k][root_b.i][root_b.j].parity = node_array[root_b.k][root_b.i][root_b.j].parity ^ node_array[root_a.k][root_a.i][root_a.j].parity;
        }

        node_array[root_a.k][root_a.i][root_a.j].root.k = root_b.k;
        node_array[root_a.k][root_a.i][root_a.j].root.i = root_b.i;
        node_array[root_a.k][root_a.i][root_a.j].root.j = root_b.j;
        node_array[root_a.k][root_a.i][root_a.j].root.is_boundary_address = root_b.is_boundary_address;
    }

    return 0;
}


int merge(int k, int i, int j, int direction){
    if(direction ==0){
        if(hor_edges[k][i][j].to_be_updated == 1){
           hor_edges[k][i][j].to_be_updated == 0;
            if(hor_edges[k][i][j].is_boundary == 1){
                update_boundary(hor_edges[k][i][j].a);
            } else {
                merge_internal(hor_edges[k][i][j].a, hor_edges[k][i][j].b);
            }
        }
    } else {
        if(ver_edges[k][i][j].to_be_updated == 1){
           ver_edges[k][i][j].to_be_updated == 0;
            if(ver_edges[k][i][j].is_boundary == 1){
                update_boundary(ver_edges[k][i][j].a);
            } else {
                merge_internal(ver_edges[k][i][j].a, ver_edges[k][i][j].b);
            }
        }
    }
    return 0;
}

void union_find (int syndrome[TOTAL_MEASUREMENTS][D+1][(D-1)/2], struct Distance distance){
    // printf("%d", syndrome[0][0][0]);

    //Initialize Nodearray

    for(int k=0;k<distance.k;k++){
        for(int i=0; i< distance.i;i++){
            for(int j=0; j< distance.j;j++){
                node_array[k][i][j].parity = syndrome[k][i][j];
                node_array[k][i][j].id.k = k;
                node_array[k][i][j].id.i = i;
                node_array[k][i][j].id.j = j;
                node_array[k][i][j].id.is_boundary_address = 1;
                node_array[k][i][j].root.k = k;
                node_array[k][i][j].root.i = i;
                node_array[k][i][j].root.j = j;
                node_array[k][i][j].root.is_boundary_address = 1;
                node_array[k][i][j].boundary = 0;
            }
        }
    }


    //Initialize edge array


    for(int k=0;k<distance.k;k++){
        for(int i=0; i< distance.i -1 ;i++){
            for(int j=0; j< 2*distance.j + 1;j++){
		        hor_edges[k][i][j].growth = 0;
		        hor_edges[k][i][j].to_be_updated = 0;
                if(j==0 || j== 2*distance.j){ //left and right borders
                    hor_edges[k][i][j].is_boundary = 1;
                    hor_edges[k][i][j].a.k = k;
                    if(i%2==0 && j==0){
                        hor_edges[k][i][j].a.i = i;
                        hor_edges[k][i][j].a.j = 0;
                    } else if(i%2==1 && j==0){
                        hor_edges[k][i][j].a.i = i+1;
                        hor_edges[k][i][j].a.j = 0;
                    } else if(i%2==0 && j==2*distance.j){
                        hor_edges[k][i][j].a.i = i+1;
                        hor_edges[k][i][j].a.j = j/2 - 1;
                    } else if(i%2==1 && j==2*distance.j){
                        hor_edges[k][i][j].a.i = i;
                        hor_edges[k][i][j].a.j = j/2 - 1;
                    }
                } else {
                    hor_edges[k][i][j].is_boundary = 0;
                    hor_edges[k][i][j].a.k = k;
                    hor_edges[k][i][j].b.k = k;
                    if(i%2==0 && j%2 == 0){
                        hor_edges[k][i][j].a.i = i;
                        hor_edges[k][i][j].a.j = j/2;
                        hor_edges[k][i][j].b.i = i+1;
                        hor_edges[k][i][j].b.j = j/2 - 1;
                    } else if (i%2==0 && j%2 == 1){
                        hor_edges[k][i][j].a.i = i;
                        hor_edges[k][i][j].a.j = j/2;
                        hor_edges[k][i][j].b.i = i+1;
                        hor_edges[k][i][j].b.j = j/2;
                    } else if (i%2==1 && j%2 == 0){
                        hor_edges[k][i][j].a.i = i;
                        hor_edges[k][i][j].a.j = j/2  - 1;
                        hor_edges[k][i][j].b.i = i+1;
                        hor_edges[k][i][j].b.j = j/2;
                    } else if (i%2==1 && j%2 == 1) {
                        hor_edges[k][i][j].a.i = i;
                        hor_edges[k][i][j].a.j = j/2;
                        hor_edges[k][i][j].b.i = i+1;
                        hor_edges[k][i][j].b.j = j/2;
                    }
                }
                hor_edges[k][i][j].to_be_updated = 0;
            }
        }
	}

    for(int k=0;k<distance.k;k++){
        for(int i=0; i< distance.i;i++){
            for(int j=0; j< distance.j;j++){
		        ver_edges[k][i][j].growth = 0;
		        ver_edges[k][i][j].to_be_updated = 0;
                if(k==0){ // Bottom layer is an open boundary
                    ver_edges[k][i][j].is_boundary = 1;
                    ver_edges[k][i][j].a.k = k;
                    ver_edges[k][i][j].a.i = i;
                    ver_edges[k][i][j].a.j = j;
                } else {
                    ver_edges[k][i][j].is_boundary = 0;
                    ver_edges[k][i][j].a.k = k-1;
                    ver_edges[k][i][j].a.i = i;
                    ver_edges[k][i][j].a.j = j;
                    ver_edges[k][i][j].b.k = k;
                    ver_edges[k][i][j].b.i = i;
                    ver_edges[k][i][j].b.j = j;
                }

            }
        }
	}

    int change_occur = 1;

    // print_edges_array();
    // print_roots_parity_boundary();

    while(change_occur == 1){
	    change_occur = 0;
        for(int k=0;k<distance.k;k++){
            for(int i=0; i< distance.i-1;i++){
                for(int j=0; j< 2*distance.j + 1;j++){
                    int grow_ret = grow(k,i,j,0); //horizontal_edge
                    change_occur = change_occur | grow_ret;
                }
            }
        }

        for(int k=0;k<distance.k;k++){
            for(int i=0; i< distance.i;i++){
                for(int j=0; j< distance.j;j++){
                    int grow_ret = grow(k,i,j,1); //vertical_edge
                    change_occur = change_occur | grow_ret;
                }
            }
        }

        // print_edges_array();

	    // Merge cycle
        for(int k=0;k<distance.k;k++){
            for(int i=0; i< distance.i;i++){
                for(int j=0; j< distance.j;j++){
                    merge(k,i,j,1); //vertical_edge
                }
            }
        }

        for(int k=0;k<distance.k;k++){
            for(int i=0; i< distance.i-1;i++){
                for(int j=0; j< 2*distance.j+1;j++){
                    merge(k,i,j,0); //horizontal_edge
                }
            }
        }

        // print_roots_parity_boundary();
    }


}

int loadFileData(FILE* file, int (*array)[D][D+1][(D-1)/2], struct Distance distance) {
    int test_id;
    if (fscanf(file, "%x", &test_id) != 1) {
        printf("Error reading file. No more test cases.\n");
        fclose(file);
        return -1;
    }
    for(int k=0;k<distance.k; k++){
        for(int i=0; i< distance.i; i++){
            for(int j=0; j< distance.j ;j++){
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

int print_output(FILE* file, int test, struct Distance distance) {
    fprintf(file, "%08X\n", test);
    for(int k=0;k<distance.k;k++){
        for(int i=0; i< distance.i; i++){
            for(int j=0; j< distance.j; j++){
                struct Address root = get_root(node_array[k][i][j].root);
                fprintf(file, "00%02X%02X%02X\n", root.k, root.i, root.j);
            }
        }
    }
    return 0;
}

int main(int argc, char *argv[]) {

    if (argc != 5) {
        fprintf(stderr, "Usage: %s <distance> <input_filename> <output_filename>\n", argv[0]);
        return 1;
    }

    // Convert first argument to integer for distance
    int d = atoi(argv[1]);
    
    // The second and third arguments are file names
    char *input_filename = argv[2];
    char *output_filename = argv[3];

    int multiplication_factor = atoi(argv[4]);

    struct Distance distance = {d, (d+1)*multiplication_factor, (d-1)/2};
    if(distance.k > D || distance.i > D || distance.j > D) {
        fprintf(stderr, "If distance greater than %d please change the parameter in source\n", D);
        return 1;
    }


    // sprintf(filename, "../test_benches/test_data/input_data_%d_rsc.txt", distance);
    FILE* file = fopen(input_filename, "r");
    if (file == NULL) {
        printf("Error opening file %s.\n", input_filename);
        return -1;
    }

    // char output_filename[100];
    // sprintf(output_filename, "../test_benches/test_data/output_data_%d_rsc.txt", distance);
    FILE* file_op = fopen(output_filename, "wb");
    if (file_op == NULL) {
        printf("Error opening file %s.\n", output_filename);
        return -1;
    }

    while(1){
        int syndrome[D][D+1][(D-1)/2];
        int ret_val = loadFileData(file, &syndrome, distance);
        if(ret_val < 0) {
            break;
        }
        union_find(syndrome, distance);
        print_output(file_op, ret_val, distance);
    }

    fclose(file_op);
    return 0;
}
