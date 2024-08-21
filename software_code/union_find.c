#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#define D 100
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
    int fpga_id;
    int is_boundary_address; // 1 not touching boundary 0 touching boundary. we do it this way to bring the addressses lower
};

struct Node {
    struct Address root;
    struct Address id;
    int parity;
    int boundary; // 1 boundary 0 not touching boundary
};

struct Edge {
    int growth;
    struct Address a;
    struct Address b;
    int to_be_updated;
    int is_boundary;
    int is_fusion_boundary; //0 no fusion 1 fusion from bottom 2 fusion from top 3 fusion from both ends
    int is_ignored; //non-existant edges in FPGA logic
};

int max(int a, int b) {
    return (a > b) ? a : b;
}

struct Node node_array[D][D+1][(D-1)/2];
struct Edge hor_edges[D][D][D];
struct Edge ver_edges[D+1][D+1][(D-1)/2];

struct Address get_root(struct Address a){
    if(node_array[a.k][a.i][a.j].id.k == node_array[a.k][a.i][a.j].root.k &&
        node_array[a.k][a.i][a.j].id.i == node_array[a.k][a.i][a.j].root.i &&
        node_array[a.k][a.i][a.j].id.j == node_array[a.k][a.i][a.j].root.j){
            struct Address ret = {node_array[a.k][a.i][a.j].id.k,
                                    node_array[a.k][a.i][a.j].id.i,
                                    node_array[a.k][a.i][a.j].id.j,
                                    node_array[a.k][a.i][a.j].id.fpga_id,
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

int print_roots(struct Distance distance){
    for(int k=0;k<distance.k;k++){
        for(int i=0; i< distance.i;i++){
            for(int j=0; j< distance.j;j++){
                struct Address root = get_root(node_array[k][i][j].root);
                if(root.k != k || root.i != i && root.j != j){
                     printf("Root of %d %d %d is %d %d %d and parity %d and boundary %d \n", k, i, j, root.k, root.i, root.j, node_array[root.k][root.i][root.j].parity, node_array[root.k][root.i][root.j].boundary);
                }
            }
        }
    }
    return 0;
}

int grow(int k, int i, int j, int direction){ //fusion_direction 0 is no fusion, 1 is lower, 2 is upper, 3 fusion from both ends
    // If odd increase growth
    // If fully grown mark as to_be_updated
    // Update change_occur
    int grow_ret = 0;
    if(direction ==0){
        if(hor_edges[k][i][j].is_ignored == 1){
            return 0;
        }
        if(hor_edges[k][i][j].is_boundary == 1){
            int is_odd = get_parity(hor_edges[k][i][j].a);
            if (is_odd && hor_edges[k][i][j].growth < 2) {
                //printf("Growth called %d %d %d %d\n", hor_edges[k][i][j].a.k, hor_edges[k][i][j].a.i, hor_edges[k][i][j].a.j, hor_edges[k][i][j].a.fpga_id);
                hor_edges[k][i][j].growth = hor_edges[k][i][j].growth + 1;
                grow_ret = 1;
                if(hor_edges[k][i][j].growth == 2){
                    hor_edges[k][i][j].to_be_updated = 1;
                }
            }
        } else{
            int is_odd = get_parity(hor_edges[k][i][j].a);
            if (is_odd && hor_edges[k][i][j].growth < 2) {
                //printf("Growth called %d %d %d %d\n", hor_edges[k][i][j].a.k, hor_edges[k][i][j].a.i, hor_edges[k][i][j].a.j, hor_edges[k][i][j].a.fpga_id);
                hor_edges[k][i][j].growth = hor_edges[k][i][j].growth + 1;
                grow_ret = 1;
                if(hor_edges[k][i][j].growth == 2){
                    hor_edges[k][i][j].to_be_updated = 1;
                }
            }
            is_odd = get_parity(hor_edges[k][i][j].b);
            if (is_odd && hor_edges[k][i][j].growth < 2) {
                //printf("Growth called %d %d %d %d\n", hor_edges[k][i][j].b.k, hor_edges[k][i][j].b.i, hor_edges[k][i][j].b.j, hor_edges[k][i][j].b.fpga_id);
                hor_edges[k][i][j].growth = hor_edges[k][i][j].growth + 1;
                grow_ret = 1;
                if(hor_edges[k][i][j].growth == 2){
                    hor_edges[k][i][j].to_be_updated = 1;
                }
            }
        }
    } else {
        // if(k==10){
        //     printf("Growth called %d %d %d %d %d\n", k, i, j, ver_edges[k][i][j].is_boundary, get_parity(ver_edges[k][i][j].a) );
        // }
        if(ver_edges[k][i][j].is_ignored == 1){
            return 0;
        }
        if(ver_edges[k][i][j].is_boundary == 1){
            int is_odd = get_parity(ver_edges[k][i][j].a);
            if (is_odd && ver_edges[k][i][j].growth < 2) {
                printf("Growth called boundary %d %d %d %d\n", ver_edges[k][i][j].a.k, ver_edges[k][i][j].a.i, ver_edges[k][i][j].a.j, ver_edges[k][i][j].a.fpga_id);
                ver_edges[k][i][j].growth = ver_edges[k][i][j].growth + 1;
                grow_ret = 1;
                if(ver_edges[k][i][j].growth == 2){
                    ver_edges[k][i][j].to_be_updated = 1;
                    printf("Fully grown %d %d %d %d\n", ver_edges[k][i][j].a.k, ver_edges[k][i][j].a.i, ver_edges[k][i][j].a.j, ver_edges[k][i][j].a.fpga_id);
                }
            }
        } else if(ver_edges[k][i][j].is_fusion_boundary == 1){
            int is_odd = get_parity(ver_edges[k][i][j].a);
            if (is_odd && ver_edges[k][i][j].growth < 2) {
                printf("Growth called fusion boundary low %d %d %d %d\n", ver_edges[k][i][j].a.k, ver_edges[k][i][j].a.i, ver_edges[k][i][j].a.j, ver_edges[k][i][j].a.fpga_id);
                ver_edges[k][i][j].growth = ver_edges[k][i][j].growth + 1;
                grow_ret = 1;
                if(ver_edges[k][i][j].growth == 2){
                    ver_edges[k][i][j].to_be_updated = 1;
                    printf("Fully grown %d %d %d %d\n", ver_edges[k][i][j].a.k, ver_edges[k][i][j].a.i, ver_edges[k][i][j].a.j, ver_edges[k][i][j].a.fpga_id);
                }
            }
        } else if(ver_edges[k][i][j].is_fusion_boundary == 2){
            int is_odd = get_parity(ver_edges[k][i][j].b);
            if (is_odd && ver_edges[k][i][j].growth < 2) {
                printf("Growth called fusion boundary high %d %d %d %d\n", ver_edges[k][i][j].b.k, ver_edges[k][i][j].b.i, ver_edges[k][i][j].b.j, ver_edges[k][i][j].b.fpga_id);
                ver_edges[k][i][j].growth = ver_edges[k][i][j].growth + 1;
                grow_ret = 1;
                if(ver_edges[k][i][j].growth == 2){
                    ver_edges[k][i][j].to_be_updated = 1;
                }
            }
        } else{
            int is_odd = get_parity(ver_edges[k][i][j].a);
            if (is_odd && ver_edges[k][i][j].growth < 2) {
                printf("Growth called interim edge a %d %d %d %d\n", ver_edges[k][i][j].a.k, ver_edges[k][i][j].a.i, ver_edges[k][i][j].a.j, ver_edges[k][i][j].a.fpga_id);
                ver_edges[k][i][j].growth = ver_edges[k][i][j].growth + 1;
                grow_ret = 1;
                if(ver_edges[k][i][j].growth == 2){
                    ver_edges[k][i][j].to_be_updated = 1;
                }
            }
            is_odd = get_parity(ver_edges[k][i][j].b);
            if (is_odd && ver_edges[k][i][j].growth < 2) {
                printf("Growth called interim edge b %d %d %d %d\n", ver_edges[k][i][j].b.k, ver_edges[k][i][j].b.i, ver_edges[k][i][j].b.j, ver_edges[k][i][j].b.fpga_id);
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
        (root.is_boundary_address == 0  && a.fpga_id < root.fpga_id) ||
        (root.is_boundary_address == 0  && a.fpga_id == root.fpga_id && a.k < root.k) || 
        (root.is_boundary_address == 0  && a.fpga_id == root.fpga_id && a.k == root.k && a.i < root.i) || 
        (root.is_boundary_address == 0  && a.fpga_id == root.fpga_id && a.k == root.k && a.i == root.i && a.j < root.j)){
            printf("Root goes to %d %d %d %d\n", a.k, a.i, a.j, a.fpga_id);
            // This node should now be the root
            node_array[root.k][root.i][root.j].root.k = a.k;
            node_array[root.k][root.i][root.j].root.i = a.i;
            node_array[root.k][root.i][root.j].root.j = a.j;
            node_array[root.k][root.i][root.j].root.fpga_id = a.fpga_id;

            node_array[a.k][a.i][a.j].parity = 0;
            node_array[a.k][a.i][a.j].boundary = 1;
            node_array[a.k][a.i][a.j].root.k = a.k;
            node_array[a.k][a.i][a.j].root.i = a.i;
            node_array[a.k][a.i][a.j].root.j = a.j;
            node_array[a.k][a.i][a.j].root.fpga_id = a.fpga_id;
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
    printf("Roots are %d %d %d %d and %d %d %d %d\n", root_a.k, root_a.i, root_a.j, root_a.fpga_id, root_b.k, root_b.i, root_b.j, root_b.fpga_id);
    if(root_a.is_boundary_address < root_b.is_boundary_address ||
        (root_a.is_boundary_address == root_b.is_boundary_address  && root_a.fpga_id < root_b.fpga_id) ||
        (root_a.is_boundary_address == root_b.is_boundary_address  && root_a.fpga_id == root_b.fpga_id && root_a.k < root_b.k) ||
        (root_a.is_boundary_address == root_b.is_boundary_address  && root_a.fpga_id == root_b.fpga_id && root_a.k == root_b.k && root_a.i < root_b.i) ||
        (root_a.is_boundary_address == root_b.is_boundary_address  && root_a.fpga_id == root_b.fpga_id && root_a.k == root_b.k && root_a.i == root_b.i && root_a.j < root_b.j)){
        // A has a lower root
        if(node_array[root_b.k][root_b.i][root_b.j].boundary == 1){
            node_array[root_a.k][root_a.i][root_a.j].parity = 0;
            node_array[root_a.k][root_a.i][root_a.j].boundary = 1;
        } else if(node_array[root_a.k][root_a.i][root_a.j].boundary == 1){
            ;
        } else {
            node_array[root_a.k][root_a.i][root_a.j].parity = node_array[root_a.k][root_a.i][root_a.j].parity ^ node_array[root_b.k][root_b.i][root_b.j].parity;
        }

        printf("A has lower root. B's root goes to %d %d %d %d\n", root_a.k, root_a.i, root_a.j, root_a.fpga_id);

        node_array[root_b.k][root_b.i][root_b.j].root.k = root_a.k;
        node_array[root_b.k][root_b.i][root_b.j].root.i = root_a.i;
        node_array[root_b.k][root_b.i][root_b.j].root.j = root_a.j;
        node_array[root_b.k][root_b.i][root_b.j].root.fpga_id = root_a.fpga_id;
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

        printf("B has lower root. A's root goes to %d %d %d %d\n", root_b.k, root_b.i, root_b.j, root_b.fpga_id);
        node_array[root_a.k][root_a.i][root_a.j].root.k = root_b.k;
        node_array[root_a.k][root_a.i][root_a.j].root.i = root_b.i;
        node_array[root_a.k][root_a.i][root_a.j].root.j = root_b.j;
        node_array[root_a.k][root_a.i][root_a.j].root.fpga_id = root_b.fpga_id;
        node_array[root_a.k][root_a.i][root_a.j].root.is_boundary_address = root_b.is_boundary_address;
    }
    printf("Updated roots are %d %d %d %d and %d %d %d %d\n", node_array[root_a.k][root_a.i][root_a.j].root.k, node_array[root_a.k][root_a.i][root_a.j].root.i, node_array[root_a.k][root_a.i][root_a.j].root.j, node_array[root_a.k][root_a.i][root_a.j].root.fpga_id, node_array[root_b.k][root_b.i][root_b.j].root.k, node_array[root_b.k][root_b.i][root_b.j].root.i, node_array[root_b.k][root_b.i][root_b.j].root.j, node_array[root_b.k][root_b.i][root_b.j].root.fpga_id);
    return 0;
}


int merge(int k, int i, int j, int direction){
    if(direction ==0){
        if(hor_edges[k][i][j].is_ignored == 1){
            return 0;
        }
        if(hor_edges[k][i][j].to_be_updated == 1){
           hor_edges[k][i][j].to_be_updated == 0;
            if(hor_edges[k][i][j].is_boundary == 1){
                printf("Update_boundary hor called %d %d %d %d\n", hor_edges[k][i][j].a.k, hor_edges[k][i][j].a.i, hor_edges[k][i][j].a.j, hor_edges[k][i][j].a.fpga_id);
                update_boundary(hor_edges[k][i][j].a);
            } else if (hor_edges[k][i][j].is_fusion_boundary == 3){
                printf("Update_boundary hor called %d %d %d %d\n", hor_edges[k][i][j].a.k, hor_edges[k][i][j].a.i, hor_edges[k][i][j].a.j, hor_edges[k][i][j].a.fpga_id);
                update_boundary(hor_edges[k][i][j].a);
                update_boundary(hor_edges[k][i][j].b);
            } else {
                printf("Merge_internal hor called %d %d %d %d and %d %d %d %d\n", hor_edges[k][i][j].a.k, hor_edges[k][i][j].a.i, hor_edges[k][i][j].a.j, hor_edges[k][i][j].a.fpga_id, hor_edges[k][i][j].b.k, hor_edges[k][i][j].b.i, hor_edges[k][i][j].b.j, hor_edges[k][i][j].b.fpga_id);
                merge_internal(hor_edges[k][i][j].a, hor_edges[k][i][j].b);
            }
        }
    } else {
        if(ver_edges[k][i][j].is_ignored == 1){
            return 0;
        }
        if(ver_edges[k][i][j].to_be_updated == 1){
           ver_edges[k][i][j].to_be_updated == 0;
            if(ver_edges[k][i][j].is_boundary == 1){
                printf("Update_boundary ver called %d %d %d %d\n", ver_edges[k][i][j].a.k, ver_edges[k][i][j].a.i, ver_edges[k][i][j].a.j, ver_edges[k][i][j].a.fpga_id);
                update_boundary(ver_edges[k][i][j].a);
            } else if (ver_edges[k][i][j].is_fusion_boundary == 1){
                printf("Update_boundary ver called %d %d %d %d\n", ver_edges[k][i][j].a.k, ver_edges[k][i][j].a.i, ver_edges[k][i][j].a.j, ver_edges[k][i][j].a.fpga_id);
                update_boundary(ver_edges[k][i][j].a);
            } else if (ver_edges[k][i][j].is_fusion_boundary == 2){
                printf("Update_boundary ver called %d %d %d %d\n", ver_edges[k][i][j].a.k, ver_edges[k][i][j].a.i, ver_edges[k][i][j].a.j, ver_edges[k][i][j].a.fpga_id);
                update_boundary(ver_edges[k][i][j].b);
            } else {
                printf("Merge_internal ver called %d %d %d %d and %d %d %d %d\n", ver_edges[k][i][j].a.k, ver_edges[k][i][j].a.i, ver_edges[k][i][j].a.j, ver_edges[k][i][j].a.fpga_id, ver_edges[k][i][j].b.k, ver_edges[k][i][j].b.i, ver_edges[k][i][j].b.j, ver_edges[k][i][j].b.fpga_id);
                merge_internal(ver_edges[k][i][j].a, ver_edges[k][i][j].b);
            }
        }
    }
    return 0;
}

int grow_merge_cycle(struct Distance distance){ // This is only valid for the full graph
    int change_occur = 0;
    for(int k=0;k<distance.k;k++){
        for(int i=0; i< distance.i + 1;i++){
            for(int j=0; j< 2*distance.j + 1;j++){
                int grow_ret = grow(k,i,j,0); //horizontal_edge
                change_occur = change_occur | grow_ret;
            }
        }
    }

    for(int k=0;k<distance.k + 1;k++){
        for(int i=0; i< distance.i;i++){
            for(int j=0; j< distance.j;j++){
                int grow_ret = grow(k,i,j,1); //vertical_edge
                change_occur = change_occur | grow_ret;
            }
        }
    }

    // print_edges_array();

    // Merge cycle
    for(int k=0;k<distance.k + 1;k++){
        for(int i=0; i< distance.i;i++){
            for(int j=0; j< distance.j;j++){
                merge(k,i,j,1); //vertical_edge
            }
        }
    }

    for(int k=0;k<distance.k;k++){
        for(int i=0; i< distance.i+1;i++){
            for(int j=0; j< 2*distance.j+1;j++){
                merge(k,i,j,0); //horizontal_edge
            }
        }
    }
    return change_occur;
    // print_roots_parity_boundary();
}

void union_find (int syndrome[TOTAL_MEASUREMENTS][D+1][(D-1)/2], struct Distance distance, int num_fpgas, int is_fusion, int d, int leaf_id){
    // //printf("%d", syndrome[0][0][0]);

    //Initialize Nodearray

    for(int k=0;k<distance.k;k++){
        for(int i=0; i< distance.i;i++){
            for(int j=0; j< distance.j;j++){
                node_array[k][i][j].parity = syndrome[k][i][j];
                node_array[k][i][j].id.k = k;
                node_array[k][i][j].id.i = i;
                node_array[k][i][j].id.j = j;
                node_array[k][i][j].id.fpga_id = 0;
                //printf("Node array %d %d %d %d\n", node_array[k][i][j].id.k, node_array[k][i][j].id.i, node_array[k][i][j].id.j, node_array[k][i][j].id.fpga_id);
                node_array[k][i][j].id.is_boundary_address = 1;
                node_array[k][i][j].root.k = k;
                node_array[k][i][j].root.i = i;
                node_array[k][i][j].root.j = j;
                node_array[k][i][j].root.fpga_id = 0;
                node_array[k][i][j].root.is_boundary_address = 1;
                node_array[k][i][j].boundary = 0;
            }
        }
    }


    //Initialize edge array


    for(int k=0;k<distance.k;k++){
        for(int i=0; i< distance.i + 1 ;i++){
            for(int j=0; j< 2*distance.j + 1;j++){
		        hor_edges[k][i][j].growth = 0;
		        hor_edges[k][i][j].to_be_updated = 0;
                hor_edges[k][i][j].is_ignored = 0;
                if(j==0|| j== 2*distance.j){ //left and right borders
                    if(j==0){
                        if (leaf_id == 0 || leaf_id == 2){
                            hor_edges[k][i][j].is_boundary = 1;
                            hor_edges[k][i][j].is_ignored = 0;
                        } else {
                            hor_edges[k][i][j].is_boundary = 0;
                            hor_edges[k][i][j].is_ignored = 1;
                        }

                        if(i==distance.i){
                            hor_edges[k][i][j].is_boundary = 0;
                            hor_edges[k][i][j].is_ignored = 1;
                        }
                    }
                    if(j==2*distance.j){
                        hor_edges[k][i][j].is_boundary = 1;
                        hor_edges[k][i][j].is_ignored = 0;

                        if(i==0){
                            hor_edges[k][i][j].is_boundary = 0;
                            hor_edges[k][i][j].is_ignored = 1;
                        }
                    }

                    hor_edges[k][i][j].a.k = k;

                    if(i%2==1 && j==0){
                        hor_edges[k][i][j].a.i = i-1;
                        hor_edges[k][i][j].a.j = 0;
                    } else if(i%2==0 && j==0 && i < distance.i){                                        
                        hor_edges[k][i][j].a.i = i;
                        hor_edges[k][i][j].a.j = 0;
                    } else if(i%2==1 && j==2*distance.j){
                        hor_edges[k][i][j].a.i = i;
                        hor_edges[k][i][j].a.j = j/2 - 1;
                    } else if(i%2==0 && j==2*distance.j && i > 0){
                        hor_edges[k][i][j].a.i = i-1;
                        hor_edges[k][i][j].a.j = j/2 - 1;
                    }
                } else {
                    hor_edges[k][i][j].is_boundary = 0;
                    hor_edges[k][i][j].a.k = k;
                    hor_edges[k][i][j].b.k = k;

                    if(i==0){
                        hor_edges[k][i][j].is_ignored = 1;
                    }
                    if(i==distance.i){
                        if(leaf_id == 0 || leaf_id == 1){
                            hor_edges[k][i][j].is_ignored = 0;
                            hor_edges[k][i][j].is_boundary = 1;
                        } else {
                            hor_edges[k][i][j].is_ignored = 1;
                        }
                    }
                    if(i==0){
                        hor_edges[k][i][j].a.i = i;
                        hor_edges[k][i][j].a.j = j/2;
                    } else if(i==distance.i){
                        hor_edges[k][i][j].a.i = i-1;
                        hor_edges[k][i][j].a.j = (j-1)/2;
                    }
                    else if(i%2==1 && j%2 == 0){
                        hor_edges[k][i][j].a.i = i-1;
                        hor_edges[k][i][j].a.j = j/2;
                        hor_edges[k][i][j].b.i = i;
                        hor_edges[k][i][j].b.j = j/2 - 1;
                    } else if (i%2==1 && j%2 == 1){
                        hor_edges[k][i][j].a.i = i-1;
                        hor_edges[k][i][j].a.j = j/2;
                        hor_edges[k][i][j].b.i = i;
                        hor_edges[k][i][j].b.j = j/2;
                    } else if (i%2==0 && j%2 == 0){
                        hor_edges[k][i][j].a.i = i-1;
                        hor_edges[k][i][j].a.j = j/2  - 1;
                        hor_edges[k][i][j].b.i = i;
                        hor_edges[k][i][j].b.j = j/2;
                    } else if (i%2==0 && j%2 == 1) {
                        hor_edges[k][i][j].a.i = i-1;
                        hor_edges[k][i][j].a.j = j/2;
                        hor_edges[k][i][j].b.i = i;
                        hor_edges[k][i][j].b.j = j/2;
                    }
                }
                hor_edges[k][i][j].to_be_updated = 0;
                hor_edges[k][i][j].a.fpga_id = 0;
                hor_edges[k][i][j].b.fpga_id = 0;
                hor_edges[k][i][j].is_fusion_boundary = 0;

                // printf("Real distance %d\n", real_distance);
                if((i>0) && (i < distance.i) && (i % (d+1) == 0) && (j>0) &&(j < 2*distance.j)){
                    hor_edges[k][i][j].is_fusion_boundary = 3;
                }else if(j > 0 && j < 2*distance.j && j % (d-1) == 0 && (i>0) && (i < distance.i)){
                    hor_edges[k][i][j].is_fusion_boundary = 3;
                }
            }
        }
	}

    for(int k=0;k<distance.k + 1;k++){
        for(int i=0; i< distance.i;i++){
            for(int j=0; j< distance.j;j++){
		        ver_edges[k][i][j].growth = 0;
		        ver_edges[k][i][j].to_be_updated = 0;
                if(k==0){ // Bottom layer is an open boundary
                    ver_edges[k][i][j].is_boundary = 1;
                    // printf("Vertical boundary %d %d %d\n", k, i, j);
                    ver_edges[k][i][j].a.k = k;
                    ver_edges[k][i][j].a.i = i;
                    ver_edges[k][i][j].a.j = j;
                } else if(k==distance.k){ // Top layer is an open boundary
                    ver_edges[k][i][j].is_boundary = 1;
                    // printf("Vertical boundary %d %d %d\n", k, i, j);
                    ver_edges[k][i][j].a.k = k-1;
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

                if(is_fusion == 1 && k == distance.k / 2){
                    ver_edges[k][i][j].is_fusion_boundary = 1; //later we have to change it to two
                    // printf("Fusion boundary %d %d %d\n", k, i, j);
                } else {
                    ver_edges[k][i][j].is_fusion_boundary = 0;
                }
                ver_edges[k][i][j].a.fpga_id = 0;
                ver_edges[k][i][j].b.fpga_id = 0;
            }
        }
	}

    int change_occur = 1;

    // print_edges_array();
    // print_roots_parity_boundary();
    if(is_fusion == 0){
        while(change_occur == 1){
            change_occur = grow_merge_cycle(distance);
        }

        // Remove fusion details
        for(int k=0;k<distance.k;k++){
            for(int i=0; i< distance.i+1;i++){
                for(int j=0; j< 2*distance.j+1;j++){
                    if((i>0) && (i < distance.i) && (i % (d+1) == 0) && (j>0) &&(j < 2*distance.j)){
                        hor_edges[k][i][j].is_fusion_boundary = 0;
                    }else if(j > 0 && j < 2*distance.j && j % (d-1) == 0 && (i>0) && (i < distance.i)){
                        hor_edges[k][i][j].is_fusion_boundary = 0;
                    }
                }
            }
        }

        //Delete all roots
        for(int k=0;k<distance.k;k++){
            for(int i=0; i< distance.i;i++){
                for(int j=0; j< distance.j;j++){
                    node_array[k][i][j].parity = syndrome[k][i][j];
                    node_array[k][i][j].id.k = k;
                    node_array[k][i][j].id.i = i;
                    node_array[k][i][j].id.j = j;
                    node_array[k][i][j].id.fpga_id = 0;
                    //printf("Node array %d %d %d %d\n", node_array[k][i][j].id.k, node_array[k][i][j].id.i, node_array[k][i][j].id.j, node_array[k][i][j].id.fpga_id);
                    node_array[k][i][j].id.is_boundary_address = 1;
                    node_array[k][i][j].root.k = k;
                    node_array[k][i][j].root.i = i;
                    node_array[k][i][j].root.j = j;
                    node_array[k][i][j].root.fpga_id = 0;
                    node_array[k][i][j].root.is_boundary_address = 1;
                    node_array[k][i][j].boundary = 0;
                }
            }
        }

        // Mark all 
        for(int k=0;k<distance.k;k++){
            for(int i=0; i< distance.i + 1;i++){
                for(int j=0; j< 2*distance.j + 1;j++){
                    if(hor_edges[k][i][j].growth == 2) {
                        hor_edges[k][i][j].to_be_updated = 1;
                    }
                }
            }
        }

        for(int k=0;k<distance.k + 1;k++){
            for(int i=0; i< distance.i;i++){
                for(int j=0; j< distance.j;j++){
                    if(ver_edges[k][i][j].growth == 2) {
                        ver_edges[k][i][j].to_be_updated = 1;
                    }
                }
            }
        }

        // print_edges_array();

        // Merge cycle
        for(int k=0;k<distance.k + 1;k++){
            for(int i=0; i< distance.i;i++){
                for(int j=0; j< distance.j;j++){
                    merge(k,i,j,1); //vertical_edge
                }
            }
        }

        for(int k=0;k<distance.k;k++){
            for(int i=0; i< distance.i+1;i++){
                for(int j=0; j< 2*distance.j+1;j++){
                    merge(k,i,j,0); //horizontal_edge
                }
            }
        }

        // Now do the fusion
        // printf("Fusion starting\n");
        change_occur = 1;
        while(change_occur == 1){
            change_occur = grow_merge_cycle(distance);
        }



    } else {
        // Lower half
        while(change_occur == 1){
            change_occur = 0;
            for(int k=0;k<distance.k/2;k++){
                for(int i=0; i< distance.i-1;i++){
                    for(int j=0; j< 2*distance.j + 1;j++){
                        int grow_ret = grow(k,i,j,0); //horizontal_edge
                        change_occur = change_occur | grow_ret;
                    }
                }
            }

            for(int k=0;k<distance.k/2 + 1;k++){
                for(int i=0; i< distance.i;i++){
                    for(int j=0; j< distance.j;j++){
                        int grow_ret = grow(k,i,j,1); //vertical_edge
                        change_occur = change_occur | grow_ret;
                    }
                }
            }

            // print_edges_array();

            // Merge cycle
            for(int k=0;k<distance.k/2 + 1;k++){
                for(int i=0; i< distance.i;i++){
                    for(int j=0; j< distance.j;j++){
                        merge(k,i,j,1); //vertical_edge
                    }
                }
            }

            for(int k=0;k<distance.k/2;k++){
                for(int i=0; i< distance.i-1;i++){
                    for(int j=0; j< 2*distance.j+1;j++){
                        merge(k,i,j,0); //horizontal_edge
                    }
                }
            }

            print_roots(distance);
            printf("Grow merge cycle completed bottom half\n");
        }

        for(int i=0; i< distance.i;i++){
            for(int j=0; j< distance.j;j++){
                ver_edges[distance.k / 2][i][j].is_fusion_boundary = 2;
                if(ver_edges[distance.k / 2][i][j].growth == 2) {
                    ver_edges[distance.k / 2][i][j].to_be_updated = 1;
                    printf("To be updated %d %d %d\n", distance.k / 2, i, j);
                }
            }
        }

        print_roots(distance);
        printf("Top half starting\n");

        

        change_occur = 1;

        // Top half
        while(change_occur == 1){
            change_occur = 0;
            for(int k=distance.k/2; k<distance.k; k++){
                for(int i=0; i< distance.i-1;i++){
                    for(int j=0; j< 2*distance.j + 1;j++){
                        int grow_ret = grow(k,i,j,0); //horizontal_edge
                        change_occur = change_occur | grow_ret;
                    }
                }
            }

            for(int k=distance.k/2; k< distance.k + 1;k++){
                for(int i=0; i< distance.i;i++){
                    for(int j=0; j< distance.j;j++){
                        int grow_ret = grow(k,i,j,1); //vertical_edge
                        change_occur = change_occur | grow_ret;
                    }
                }
            }

            // print_edges_array();

            // Merge cycle
            for(int k=distance.k/2;k< distance.k + 1;k++){
                for(int i=0; i< distance.i;i++){
                    for(int j=0; j< distance.j;j++){
                        merge(k,i,j,1); //vertical_edge
                    }
                }
            }

            for(int k=distance.k/2; k<distance.k;k++){
                for(int i=0; i< distance.i-1;i++){
                    for(int j=0; j< 2*distance.j+1;j++){
                        merge(k,i,j,0); //horizontal_edge
                    }
                }
            }
            // print_roots_parity_boundary();
            print_roots(distance);
            printf("Grow merge cycle completed top half\n");
        }


        // Remove fusion details
        for(int i=0; i< distance.i;i++){
            for(int j=0; j< distance.j;j++){
                ver_edges[distance.k / 2][i][j].is_fusion_boundary = 0;
            }
        }

        //Delete all roots
        for(int k=0;k<distance.k;k++){
            for(int i=0; i< distance.i;i++){
                for(int j=0; j< distance.j;j++){
                    node_array[k][i][j].parity = syndrome[k][i][j];
                    node_array[k][i][j].id.k = k;
                    node_array[k][i][j].id.i = i;
                    node_array[k][i][j].id.j = j;
                    node_array[k][i][j].id.fpga_id = 0;
                    //printf("Node array %d %d %d %d\n", node_array[k][i][j].id.k, node_array[k][i][j].id.i, node_array[k][i][j].id.j, node_array[k][i][j].id.fpga_id);
                    node_array[k][i][j].id.is_boundary_address = 1;
                    node_array[k][i][j].root.k = k;
                    node_array[k][i][j].root.i = i;
                    node_array[k][i][j].root.j = j;
                    node_array[k][i][j].root.fpga_id = 0;
                    node_array[k][i][j].root.is_boundary_address = 1;
                    node_array[k][i][j].boundary = 0;
                }
            }
        }

        // Mark all 
        for(int k=0;k<distance.k;k++){
            for(int i=0; i< distance.i-1;i++){
                for(int j=0; j< 2*distance.j + 1;j++){
                    if(hor_edges[k][i][j].growth == 2) {
                        hor_edges[k][i][j].to_be_updated = 1;
                    }
                }
            }
        }

        for(int k=0;k<distance.k + 1;k++){
            for(int i=0; i< distance.i;i++){
                for(int j=0; j< distance.j;j++){
                    if(ver_edges[k][i][j].growth == 2) {
                        ver_edges[k][i][j].to_be_updated = 1;
                    }
                }
            }
        }

        // print_edges_array();

        // Merge cycle
        for(int k=0;k<distance.k + 1;k++){
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

        // Now do the fusion
        // printf("Fusion starting\n");
        change_occur = 1;
        while(change_occur == 1){
            change_occur = grow_merge_cycle(distance);
        }
    }


}

int loadFileData(FILE* file, int (*array)[D][D+1][(D-1)/2], struct Distance distance) {
    int test_id;
    if (fscanf(file, "%x", &test_id) != 1) {
        //printf("Error reading file. No more test cases.\n");
        fclose(file);
        return -1;
    }
    for(int k=0;k<distance.k; k++){
        for(int i=0; i< distance.i; i++){
            for(int j=0; j< distance.j ;j++){
                (*array)[k][i][j] = 0;
            }
        }
    }
    int value;
    while(1){
        if (fscanf(file, "%x", &value) == 1){
            // printf("Value = %X\n", value);
            if(value == 0xFFFFFFFF){
                break;
            }
            int j_range = (int)(ceil(log2(distance.j)));
            int j = value & ((1 << j_range) - 1);
            int i_range = (int)(ceil(log2(distance.i)));
            int i = (value >> j_range) & ((1 << i_range) - 1);
            int k_range = (int)(ceil(log2(distance.k)));
            int k = (value >> (j_range + i_range)) & ((1 << k_range) - 1);
            (*array)[k][i][j] = 1;
            printf("Test id : %d error at %d %d %d\n",test_id,k,i,j);
        }
    }
    // //printf("Test id : %x loaded\n",test_id);
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

    if (argc != 8) {
        fprintf(stderr, "Usage: %s <distance> <input_filename> <output_filename> <num_fpgas> <m_fusion> <qubits_per_dim> <fpga_id>\n", argv[0]);
        return 1;
    }

    // Convert first argument to integer for distance
    int d = atoi(argv[1]);
    
    // The second and third arguments are file names
    char *input_filename = argv[2];
    char *output_filename = argv[3];

    int num_fpgas = atoi(argv[4]); //This is num leaves
    int m_fusion = atoi(argv[5]); //0 no fusion, 1 fusion
    int qubits_per_dim = atoi(argv[6]);
    int fpga_id = atoi(argv[7]);

    int leaf_id = fpga_id - 1;
    printf("Parameters %d %d %d %d %d\n", d, num_fpgas, m_fusion, qubits_per_dim, leaf_id);

    int dist_i = (d +1)*qubits_per_dim / 2;
    int dist_j = ((d -1)/2)*qubits_per_dim / 2;
    int dist_i_extra = (leaf_id < 2) ? (((d + 3)/4)*2) : 0;
    int dist_j_extra = (leaf_id % 2 == 0) ? ((d + 1)/4) : 0;
 
    struct Distance distance = {d*(m_fusion + 1), dist_i + dist_i_extra, dist_j + dist_j_extra};
    printf("Distance %d %d %d\n", distance.k, distance.i, distance.j);
    if(distance.k > D || distance.i > D || distance.j > D) {
        fprintf(stderr, "Some distance is greater than %d please change the parameter in source\n", D);
        return 1;
    }


    // s//printf(filename, "../test_benches/test_data/input_data_%d_rsc.txt", distance);
    FILE* file = fopen(input_filename, "r");
    if (file == NULL) {
        //printf("Error opening file %s.\n", input_filename);
        return -1;
    }

    // char output_filename[100];
    // s//printf(output_filename, "../test_benches/test_data/output_data_%d_rsc.txt", distance);
    FILE* file_op = fopen(output_filename, "wb");
    if (file_op == NULL) {
        //printf("Error opening file %s.\n", output_filename);
        return -1;
    }

    while(1){
        int syndrome[D][D+1][(D-1)/2];
        int ret_val = loadFileData(file, &syndrome, distance);
        if(ret_val < 0) {
            break;
        }
        union_find(syndrome, distance, num_fpgas, m_fusion, d, leaf_id);
        print_output(file_op, ret_val, distance);
    }

    fclose(file_op);
    return 0;
}
