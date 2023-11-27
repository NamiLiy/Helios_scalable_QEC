#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#define D 3

struct Address {
    int k;
    int i;
    int j;
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

int count = 0;

int max(int a, int b) {
    return (a > b) ? a : b;
}

struct Node node_array[D][D+1][(D-1)/2];
struct Edge hor_edges[D][D][D];
struct Edge ver_edges[D][D+1][(D-1)/2];
struct Edge diag_edges[D-1][D][D-2];
struct Edge hook_edges[D-1][D-1][(D-1)/2]; // hook errors can be traced to the boundary

struct Address get_root(struct Address a){
    if(node_array[a.k][a.i][a.j].id.k == node_array[a.k][a.i][a.j].root.k &&
        node_array[a.k][a.i][a.j].id.i == node_array[a.k][a.i][a.j].root.i &&
        node_array[a.k][a.i][a.j].id.j == node_array[a.k][a.i][a.j].root.j){
            struct Address ret = {a.k,a.i,a.j};
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
    if(direction == 0) {
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
    } else if(direction == 1){
        if(ver_edges[k][i][j].is_boundary == 1){
            int is_odd = get_parity(ver_edges[k][i][j].a);
            if (is_odd && ver_edges[k][i][j].growth < 2) {
                ver_edges[k][i][j].growth = ver_edges[k][i][j].growth + 1;
                grow_ret = 1;
                if(ver_edges[k][i][j].growth == 2){
                    ver_edges[k][i][j].to_be_updated = 1;
                }
            }
        } else {
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
    } else if (direction == 2) {
        int is_odd = get_parity(diag_edges[k][i][j].a);
        if (is_odd && diag_edges[k][i][j].growth < 2) {
            diag_edges[k][i][j].growth = diag_edges[k][i][j].growth + 1;
            grow_ret = 1;
            if(diag_edges[k][i][j].growth == 2){
                diag_edges[k][i][j].to_be_updated = 1;
            }
        }
        is_odd = get_parity(diag_edges[k][i][j].b);
        if (is_odd && diag_edges[k][i][j].growth < 2) {
            diag_edges[k][i][j].growth = diag_edges[k][i][j].growth + 1;
            grow_ret = 1;
            if(diag_edges[k][i][j].growth == 2){
                diag_edges[k][i][j].to_be_updated = 1;
            }
        }
    } else {
        int is_odd = get_parity(hook_edges[k][i][j].a);
        if (is_odd && hook_edges[k][i][j].growth < 2) {
            hook_edges[k][i][j].growth = hook_edges[k][i][j].growth + 1;
            grow_ret = 1;
            if(hook_edges[k][i][j].growth == 2){
                hook_edges[k][i][j].to_be_updated = 1;
            }
        }
        is_odd = get_parity(hook_edges[k][i][j].b);
        if (is_odd && hook_edges[k][i][j].growth < 2) {
            hook_edges[k][i][j].growth = hook_edges[k][i][j].growth + 1;
            grow_ret = 1;
            if(hook_edges[k][i][j].growth == 2){
                hook_edges[k][i][j].to_be_updated = 1;
            }
        }
    }
    if(hor_edges[k][i][j].growth == 2){
        hor_edges[k][i][j].to_be_updated = 1;
    }
    return grow_ret;
}

int update_boundary(struct Address a){
    struct Address root = get_root(a);
    node_array[root.k][root.i][root.j].parity = 0;
    node_array[root.k][root.i][root.j].boundary = 1;
    return 0;
}

int merge_internal(struct Address a, struct Address b){
    struct Address root_a = get_root(a);
    struct Address root_b = get_root(b);
    if(root_a.k == root_b.k && root_a.i == root_b.i && root_a.j == root_b.j){
        // They are the same cluster. No merge
        return 0;
    }
    if(root_a.k < root_b.k || (root_a.k == root_b.k && root_a.i < root_b.i) || (root_a.k == root_b.k && root_a.i == root_b.i && root_a.j < root_b.j)){
        // A has a lower root
        if(node_array[root_b.k][root_b.i][root_b.j].boundary == 1){
            node_array[root_a.k][root_a.i][root_a.j].parity = 0;
            node_array[root_a.k][root_a.i][root_a.j].boundary = 1;
        } else if(node_array[root_a.k][root_a.i][root_a.j].boundary == 1){
            ;
        } else {
            node_array[root_a.k][root_a.i][root_a.j].parity = node_array[root_a.k][root_a.i][root_a.j].parity ^ node_array[root_b.k][root_b.i][root_b.j].parity;
            node_array[root_b.k][root_b.i][root_b.j].parity = node_array[root_a.k][root_a.i][root_a.j].parity;
        }
        node_array[root_b.k][root_b.i][root_b.j].root.k = root_a.k;
        node_array[root_b.k][root_b.i][root_b.j].root.i = root_a.i;
        node_array[root_b.k][root_b.i][root_b.j].root.j = root_a.j;
    } else {
        // B has the lower root
        if(node_array[root_a.k][root_a.i][root_b.j].boundary == 1){
            node_array[root_b.k][root_b.i][root_b.j].parity = 0;
            node_array[root_b.k][root_b.i][root_b.j].boundary = 1;
        } else if(node_array[root_b.k][root_b.i][root_b.j].boundary == 1){
            ;
        } else {
            node_array[root_b.k][root_b.i][root_b.j].parity = node_array[root_b.k][root_b.i][root_b.j].parity ^ node_array[root_a.k][root_a.i][root_a.j].parity;
            node_array[root_a.k][root_a.i][root_a.j].parity = node_array[root_b.k][root_b.i][root_b.j].parity;
        }
        node_array[root_a.k][root_a.i][root_a.j].root.k = root_b.k;
        node_array[root_a.k][root_a.i][root_a.j].root.i = root_b.i;
        node_array[root_a.k][root_a.i][root_a.j].root.j = root_b.j;
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
    } else if (direction == 1) {
        if(ver_edges[k][i][j].to_be_updated == 1){
            ver_edges[k][i][j].to_be_updated == 0;
            if(ver_edges[k][i][j].is_boundary == 1){
                update_boundary(ver_edges[k][i][j].a);
            } else {
                merge_internal(ver_edges[k][i][j].a, ver_edges[k][i][j].b);
            }
        }
    } else if (direction == 2){
        if(diag_edges[k][i][j].to_be_updated == 1){
            diag_edges[k][i][j].to_be_updated == 0;
            merge_internal(diag_edges[k][i][j].a, diag_edges[k][i][j].b);
        }
    } else {
        if(hook_edges[k][i][j].to_be_updated == 1){
            hook_edges[k][i][j].to_be_updated == 0;
            if(hook_edges[k][i][j].is_boundary == 1){
                update_boundary(hook_edges[k][i][j].a);
            } else {
                merge_internal(hook_edges[k][i][j].a, hook_edges[k][i][j].b);
            }
        }
    }
    return 0;
}

void verifyVerilogRoots(FILE* file, struct Node node_array[D][D+1][(D-1)/2]) {

    int verilog_root_u;
    int verilog_root_z;
    int verilog_root_x;

    for(int k = 0; k < D; k++) {
        for(int i = 0; i < D+1; i++) {
            for(int j = 0; j < (D-1)/2; j++) {
                if (fscanf(file, "%1d %1d %d", &verilog_root_z, &verilog_root_x, &verilog_root_u) != 3) {
                    printf("Error reading file. No more roots.\n");

                }

                struct Address a;
                a.k = k;
                a.i = i;
                a.j = j;
                struct Address root = get_root(a);

                if(root.k == verilog_root_u && root.i == verilog_root_x && root.j == verilog_root_z) {
                //    printf("roots match %d %d %d \n", root.k, root.i, root.j);
                ;
                } else {
                    printf("fail expected: %d %d %d got %d %d %d \n", root.k, root.i, root.j, verilog_root_u, verilog_root_x, verilog_root_z);
                }
            }
        }
    }
}

void union_find (int syndrome[D][D+1][(D-1)/2]){
    printf("%d", syndrome[0][0][0]);

    //Initialize Nodearray

    for(int k=0;k<D;k++){
        for(int i=0; i< (D+1);i++){
            for(int j=0; j<(D-1)/2;j++){
                node_array[k][i][j].parity = syndrome[k][i][j];
                node_array[k][i][j].id.k = k;
                node_array[k][i][j].id.i = i;
                node_array[k][i][j].id.j = j;
                node_array[k][i][j].root.k = k;
                node_array[k][i][j].root.i = i;
                node_array[k][i][j].root.j = j;
                node_array[k][i][j].boundary = 0;
            }
        }
    }


    //Initialize edge array


    for(int k=0;k<D;k++){
        for(int i=0; i< D;i++){
            for(int j=0; j< D;j++){
		        hor_edges[k][i][j].growth = 0;
		        hor_edges[k][i][j].to_be_updated = 0;
                if(j==0 || j== D - 1){ //left and right borders
                    hor_edges[k][i][j].is_boundary = 1;
                    hor_edges[k][i][j].a.k = k;
                    if(i%2==0 && j==0){
                        hor_edges[k][i][j].a.i = i;
                        hor_edges[k][i][j].a.j = 0;
                    } else if(i%2==1 && j==0){
                        hor_edges[k][i][j].a.i = i+1;
                        hor_edges[k][i][j].a.j = 0;
                    } else if(i%2==0 && j==D - 1){
                        hor_edges[k][i][j].a.i = i+1;
                        hor_edges[k][i][j].a.j = j/2 - 1;
                    } else if(i%2==1 && j==D - 1){
                        hor_edges[k][i][j].a.i = i;
                        hor_edges[k][i][j].a.j = j/2 - 1;
                    }
                } else {
                    hor_edges[k][i][j].is_boundary = 0;
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
                    struct Address broot = get_root(hor_edges[k][i][j].b);
                }
                
            }
        }
	}

    //hook edges
    for(int k=0;k<D-1;k++){
        for(int i=0; i < D-1;i++){
            for(int j=0; j< (D-1)/2;j++){
                if(i%2==0 && j == 0){
                    hook_edges[k][i][j].is_boundary = 1;
                    hook_edges[k][i][j].a.k = k;
                    hook_edges[k][i][j].a.j = j;
                    hook_edges[k][i][j].a.i = i+1;
                } else if(i%2==1 && j == (D-1)/2 - 1){
                    hook_edges[k][i][j].is_boundary = 1;
                    hook_edges[k][i][j].a.k = k;
                    hook_edges[k][i][j].a.j = j;
                    hook_edges[k][i][j].a.i = i+1;
                } else {
                    hook_edges[k][i][j].is_boundary = 0;
                    hook_edges[k][i][j].a.k = k;
                    hook_edges[k][i][j].b.k = k+1;
                    hook_edges[k][i][j].a.j = j;
                    hook_edges[k][i][j].b.j = j+1;
                    hook_edges[k][i][j].a.i = i+1;
                    hook_edges[k][i][j].b.i = i+1;
                }
                hook_edges[k][i][j].growth = 0;
		        hook_edges[k][i][j].to_be_updated = 0;
                // printf("%d %d %d and %d %d %d\n", hook_edges[k][i][j].a.k, hook_edges[k][i][j].a.i, hook_edges[k][i][j].a.j, hook_edges[k][i][j].b.k, hook_edges[k][i][j].b.i, hook_edges[k][i][j].b.j);

            }
        }
    }

    //diag edges
    for(int k=0;k<D-1;k++){
        for(int i=0; i< D;i++){
            for(int j=0; j< D-2;j++){
                diag_edges[k][i][j].growth = 0;
		        diag_edges[k][i][j].to_be_updated = 0;
                diag_edges[k][i][j].is_boundary = 0;
                diag_edges[k][i][j].a.k = k;
                diag_edges[k][i][j].a.i = i;
                diag_edges[k][i][j].b.k = k+1;
                diag_edges[k][i][j].b.i = i+1;
                if(j % 2 == 0) {
                    diag_edges[k][i][j].a.j = j - j/2; // This is = j/2 mathematically for even j
                    diag_edges[k][i][j].b.j = j - j/2; // This is = j/2 mathematically for even j
                } else if (j % 2 == 1 && i % 2 == 0) {
                    diag_edges[k][i][j].a.j = j - j/2; // This is = j/2  + 1 mathematically for odd j
                    diag_edges[k][i][j].b.j = j - (j/2+1); // This is = j/2 mathematically for odd j
                } else if (j % 2 == 1 && i % 2 == 1) {
                    diag_edges[k][i][j].a.j = j/2;
                    diag_edges[k][i][j].b.j = j - j/2;
                }
                // printf("%d %d %d and %d %d %d\n", diag_edges[k][i][j].a.k, diag_edges[k][i][j].a.i, diag_edges[k][i][j].a.j, diag_edges[k][i][j].b.k, diag_edges[k][i][j].b.i, diag_edges[k][i][j].b.j);
            }
        }
    }

    for(int k=0;k<D;k++){
        for(int i=0; i< D + 1;i++){
            for(int j=0; j< (D-1)/2;j++){
		        ver_edges[k][i][j].growth = 0;
		        ver_edges[k][i][j].to_be_updated = 0;
                if(k==0){ //left and right borders
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

    while(change_occur == 1){
	    change_occur = 0;    
        for(int k=0;k<D-1;k++){
            for(int i=0; i< D;i++){
                for(int j=0; j< (D-2);j++){
                    int grow_ret = grow(k,i,j,2); //diagonal edge
                    change_occur = change_occur | grow_ret;
                }
            }
        }

        for(int k=0;k<D;k++){
            for(int i=0; i< D;i++){
                for(int j=0; j< D;j++){
                    int grow_ret = grow(k,i,j,0); //horizontal_edge
                    change_occur = change_occur | grow_ret;
                }
            }
        }

        for(int k=0;k<D;k++){
            for(int i=0; i< D + 1;i++){
                for(int j=0; j< (D-1)/2;j++){
                    int grow_ret = grow(k,i,j,1); //vertical_edge
                    change_occur = change_occur | grow_ret;
                }
            }
        }

        for(int k=0;k<D-1;k++){
            for(int i=0; i< D-1;i++){
                for(int j=0; j< (D-1)/2 - 1;j++){
                    int grow_ret = grow(k,i,j,3); //hook edge
                    change_occur = change_occur | grow_ret;
                }
            }
        }


        // Merge cycle
        for(int k=0;k<D-1;k++){
            for(int i=0; i< D;i++){
                for(int j=0; j< (D-2);j++){
                    merge(k,i,j,2); //diagonal_edge
                }
            }
        }

        for(int k=0;k<D-1;k++){
            for(int i=0; i< D-1;i++){
                for(int j=0; j< (D-1)/2 -1;j++){
                    merge(k,i,j,3); //hook
                }
            }
        }

        for(int k=0;k<D;k++){
            for(int i=0; i< D;i++){
                for(int j=0; j< D;j++){
                    merge(k,i,j,0); //horizontal_edge
                }
            }
        }

        for(int k=0;k<D;k++){
            for(int i=0; i< D + 1;i++){
                for(int j=0; j< (D-1)/2;j++){
                    merge(k,i,j,1); //vertical_edge
                }
            }
        }

    }
}

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
                if(count == 311 && value == 1) {
                    printf("syndrome %d %d %d \n", k, i, j);
                }
            }
        }
    }

   

    
    

    printf("Test id : %x loaded\n",test_id);
    return test_id;
}

int print_output(FILE* file, int test) {
    fprintf(file, "%08X\n", test);
    for(int k=0;k<D;k++){
        for(int i=0; i< D + 1;i++){
            for(int j=0; j< (D-1)/2;j++){
                fprintf(file, "00%02X%02X%02X\n", node_array[k][i][j].root.k, node_array[k][i][j].root.i, node_array[k][i][j].root.j);
            }
        }
    }
    return 0;
}

int main(){
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
    sprintf(output_filename, "../test_benches/test_data/output_data_%d_rsc.txt", distance);
    FILE* file_op = fopen(output_filename, "wb");
    if (file_op == NULL) {
        printf("Error opening file %s.\n", output_filename);
        return -1;
    }

    char verilog_roots_filename[100];
    sprintf(verilog_roots_filename, "../test_benches/test_data/output_data_%d_roots.txt", distance);
    FILE* file_verilog_roots = fopen(verilog_roots_filename, "r");
    if (file_verilog_roots == NULL) {
        printf("Error opening file %s.\n", verilog_roots_filename);
        return -1;
    }

    while(1){
        count++;
        int syndrome[D][D+1][(D-1)/2];
        int ret_val = loadFileData(file, &syndrome);
        if(ret_val < 0) {
            break;
        }
        union_find(syndrome);
        print_output(file_op, ret_val);
        verifyVerilogRoots(file_verilog_roots, node_array);
    }

    fclose(file_op);
    return 0;
}