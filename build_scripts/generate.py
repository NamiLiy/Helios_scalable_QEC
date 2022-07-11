from pickle import FALSE, TRUE
import user_configuration
import partitionScheme as pt
import math
import copy
from  user_configuration import Route_Entry
from  user_configuration import Node_Grid  

codeDistanceX = 3
codeDistanceZ = 2
hub_fifo_width = 16
fpga_id_width = 4
fifo_id_width = 4
global_pointer_to_parent = None
dealy_for_pe_busy = 9 #Critical parameter please choose wisely
interconnect_physical_width = 0
interconnection_latency = 0
ll_connections = False
num_leaf_fpgas = 0

class hdlTemplate:
    out = ""
    def __init__(self, out):
        self.out = out
    def r(self, keyword, repl):
        self.out = self.out.replace("/*$$" + str(keyword) + "*/", str(repl))
def inlineCase(var, pairs, otw):
    ret = ""
    for p in pairs:
        conditions = ""
        conditionsInit = False
        for i in range(len(var)):
            if(not conditionsInit):
                conditionsInit = True
            else:
                conditions = conditions + "&&"
            conditions = conditions + var[i] + "==" + str(p[i])
        ret = ret + conditions + "?" + str(p[-1]) + ":"
    if(ret == "" or ret[-1]==":"):
        ret = ret + str(otw)
    return ret

# codeDistanceX, codeDistanceZ, numSplit, presetArrange = user_configuration.retConfig()
# binWidth = math.ceil(math.log(max(codeDistanceZ, codeDistanceX), 2))
# vOut = []
# if presetArrange == [[]]:
#     totalFIFOs, splitBoard = pt.findOptBoard(codeDistanceX, codeDistanceZ, numSplit)
#     print("FIFOs: " + str(totalFIFOs))
# else:
#     splitBoard = presetArrange
# pt.printGrid(splitBoard)

# templateSV = ""
# with open("./templates/standard_planar_code_2d.sv","r") as f:
#     templateSV = f.read()
# for i in range(numSplit):
#     puInst = 0
#     puCoords = ""
#     puCont = ""
#     initLoop = True
#     puCoordList = []
#     for x in range(len(splitBoard)):
#         for y in range(len(splitBoard[0])):
#             if(splitBoard[x][y] == i):
#                 if(initLoop):
#                     initLoop=False
#                 else:
#                     puCont = puCont + " || "
#                 puCoordList.append(str(binWidth)+"\'d" + str(x))
#                 puCoordList.append(str(binWidth)+"\'d" + str(y))
#                 puCont = puCont + "i == " + str(x) + " && " + "j == " + str(y)
#                 puInst = puInst + 1
#     puCoordList.reverse()
#     print(puCoordList)
#     print(puCont)
#     initLoop = True
#     for pc in puCoordList:
#         if(initLoop):
#             initLoop = False
#         else:
#             puCoords = puCoords + ", "
#         puCoords = puCoords + pc
#     print(puCoords)
#     edgeCount = pt.getEdgeCount(splitBoard, i)
#     print(edgeCount)
#     gridFifos = pt.gridIO(splitBoard,i)
#     print(gridFifos)
#     OF = hdlTemplate(templateSV)
#     OF.r("ID", str(i))
#     OF.r("CODE_DISTANCE_X", codeDistanceX)
#     OF.r("CODE_DISTANCE_Z", codeDistanceZ)
#     OF.r("EDGE_COUNT", edgeCount) # This is split edges per measurement round
#     OF.r("PU_COORDS_WIDTH", 2*binWidth*sum(splitBoard,[]).count(i))
#     OF.r("PU_COORDS", puCoords)
#     OF.r("PU_CONT", puCont)
#     OF.r("EDGE_DIRS_WIDTH", str(5*sum(splitBoard,[]).count(i)))
#     OF.r("BIN_WIDTH", str(binWidth))
#     OF.r("PU_INST", str(puInst))
#     OF.r("X_TO_Y",  inlineCase(["x","dir"], pt.xToY(splitBoard,i), 0))

#     # Bugs likely to occur below, wrapping badly understood still
#     OF.r("IS_FIFO_VERT_INPUT", inlineCase(["x"], pt.fifosHere(gridFifos,0),0))
#     OF.r("IS_FIFO_HOR_INPUT", inlineCase(["x"], pt.fifosHere(gridFifos,1),0))
#     OF.r("IS_FIFO_VERT_OUTPUT", inlineCase(["x"], pt.fifosHere(gridFifos,2),0))
#     OF.r("IS_FIFO_HOR_OUTPUT", inlineCase(["x"], pt.fifosHere(gridFifos,3),0))
#     OF.r("IS_FIFO_WRAP_VERT", inlineCase(["x"], pt.vertWrap(splitBoard, i),0))
#     OF.r("IS_FIFO_WRAP_HOR", inlineCase(["x"], pt.horWrap(splitBoard, i),0))
#     OF.r("INC_I", inlineCase(["x"], pt.incI(splitBoard, i), 0))
#     OF.r("INC_J", inlineCase(["x"], pt.incJ(splitBoard, i), 0))

#     # Write to file
#     f = open("../design/generated/standard_planar_code_2d_" + str(i) + ".sv", "w")
#     f.write(OF.out)
#     f.close()

def add_routing_table(node):
    with open("./templates/routing_table.sv","r") as f:
        templateSV = f.read()
        OF = hdlTemplate(templateSV)
        OF.r("ID", node.id)
        OF.r("FPGAID_WIDTH", fpga_id_width)
        OF.r("DOWNSTREAM_FIFO_COUNT", node.num_children)

        # Write to file
        f = open("../design/generated/routing_table_." + str(node.id) + ".sv", "w")
        f.write(OF.out)
        f.close()

        f = open("../design/generated/routing_table_." + str(node.id) + ".sv", "a")

        # Routing logic
        for idx, child in enumerate(node.children):
            l1 = get_child_list(child)
            for fpga in l1:
                f.write("\n" + str(fpga_id_width)+"'d"+str(fpga)+" : destination_index = 1 << "+ str(idx)+";")

        f.write("\ndefault : destination_index = 1 << " + str(node.num_children) + ";") 
        f.write("\nendcase")
        f.write("\nend")
        f.write("\n\nendmodule")
        f.close()
    return

# Not the top module of the root hub though
def add_hub_top_module(node):
    with open("./templates/top_module_hub.sv","r") as f:
        templateSV = f.read()
        OF = hdlTemplate(templateSV)
        OF.r("ID", node.id)
        OF.r("FPGAID_WIDTH", fpga_id_width)
        OF.r("FIFO_IDWIDTH", fifo_id_width)
        OF.r("DOWNSTREAM_FIFO_COUNT", node.num_children)
        OF.r("HUB_FIFO_WIDTH", hub_fifo_width)
        OF.r("HUB_FIFO_PHYSICAL_WIDTH_DWN", interconnect_physical_width)
        if node.id == 0:
            OF.r("HUB_FIFO_PHYSICAL_WIDTH_UP", hub_fifo_width)
        else :
            OF.r("HUB_FIFO_PHYSICAL_WIDTH_UP", interconnect_physical_width)

        # Write to file
        f = open("../design/generated/top_module_hub_" + str(node.id) + ".sv", "w")
        f.write(OF.out)
        f.close()

def add_hub(node):
    print("Hub " + str(node.id))
    with open("./templates/hub_wrapper.sv","r") as f:
        templateSV = f.read()
        OF = hdlTemplate(templateSV)
        OF.r("ID", node.id)
        OF.r("CODE_DISTANCE_X", codeDistanceX)
        OF.r("CODE_DISTANCE_Z", codeDistanceZ)
        OF.r("ID", node.id)
        OF.r("LEVEL", node.level)
        OF.r("PARENT", node.parent)
        OF.r("CHILD_ID", node.child_id)
        OF.r("NUM_CHILDREN", node.num_children)
        # OF.r("HUB_FIFO_PHYSICAL_WIDTH", interconnect_physical_width)

        # Write to file
        f = open("../design/generated/top_level_test_bench.sv", "a")
        f.write(OF.out)
        f.close()

    # Add hub top module
    add_hub_top_module(node)

    # Add routing table
    add_routing_table(node)
    return

def add_leaf(node):
    print("Leaf " + str(node.id))

    # Add test bench
    if(ll_connections == True):
        with open("./templates/leaf_wrapper_ll_connected.sv","r") as f:
            templateSV = f.read()
            OF = hdlTemplate(templateSV)
            OF.r("ID", node.id)
            OF.r("CODE_DISTANCE_X", codeDistanceX)
            OF.r("CODE_DISTANCE_Z", codeDistanceZ)
            OF.r("ID", node.id)
            OF.r("PARENT", node.parent)
            OF.r("CHILD_ID", node.child_id)
            x_start = node.grid.x_start
            x_end = node.grid.x_end
            OF.r("X_START", x_start) # This is split edges per measurement round
            OF.r("X_END", x_end) # This is split edges per measurement round

            # Write to file
            f = open("../design/generated/top_level_test_bench.sv", "a")
            f.write(OF.out)
            f.close()
    else:
        with open("./templates/leaf_wrapper.sv","r") as f:
            templateSV = f.read()
            OF = hdlTemplate(templateSV)
            OF.r("ID", node.id)
            OF.r("CODE_DISTANCE_X", codeDistanceX)
            OF.r("CODE_DISTANCE_Z", codeDistanceZ)
            OF.r("ID", node.id)
            OF.r("PARENT", node.parent)
            OF.r("CHILD_ID", node.child_id)
            x_start = node.grid.x_start
            x_end = node.grid.x_end
            OF.r("X_START", x_start) # This is split edges per measurement round
            OF.r("X_END", x_end) # This is split edges per measurement round

            # Write to file
            f = open("../design/generated/top_level_test_bench.sv", "a")
            f.write(OF.out)
            f.close()

    # Add leaf top module'
    if(ll_connections == True):
        with open("./templates/top_module_for_leaf_ll_connected.sv","r") as f:
            templateSV = f.read()
            x_start = node.grid.x_start
            x_end = node.grid.x_end
            OF = hdlTemplate(templateSV)
            OF.r("ID", node.id)
            OF.r("CODE_DISTANCE_X", codeDistanceX)
            OF.r("CODE_DISTANCE_Z", codeDistanceZ)
            OF.r("FPGAID_WIDTH", fpga_id_width)
            OF.r("FIFO_IDWIDTH", fifo_id_width)
            OF.r("EDGE_COUNT", node.edge_count) # This is split edges per measurement round
            OF.r("X_START", x_start) # This is split edges per measurement round
            OF.r("X_END", x_end) # This is split edges per measurement round
            OF.r("HUB_FIFO_WIDTH", hub_fifo_width)
            OF.r("MESSAGE_FLYING_DELAY",dealy_for_pe_busy)
            OF.r("HUB_FIFO_PHYSICAL_WIDTH",interconnect_physical_width)
            OF.r("LL_NEIGHBORS",2)
            neighbor_FPGA_list = generate_neighbor_FPGA_list(node)
            OF.r("LL_NEIGHBOR_IDS",neighbor_FPGA_list)
            # Write to file
            f = open("../design/generated/top_module_for_leaf_" + str(node.id) + ".sv", "w")
            f.write(OF.out)
            f.close()
    else:
        with open("./templates/top_module_for_leaf.sv","r") as f:
            templateSV = f.read()
            x_start = node.grid.x_start
            x_end = node.grid.x_end
            OF = hdlTemplate(templateSV)
            OF.r("ID", node.id)
            OF.r("CODE_DISTANCE_X", codeDistanceX)
            OF.r("CODE_DISTANCE_Z", codeDistanceZ)
            OF.r("FPGAID_WIDTH", fpga_id_width)
            OF.r("FIFO_IDWIDTH", fifo_id_width)
            OF.r("EDGE_COUNT", node.edge_count) # This is split edges per measurement round
            OF.r("X_START", x_start) # This is split edges per measurement round
            OF.r("X_END", x_end) # This is split edges per measurement round
            OF.r("HUB_FIFO_WIDTH", hub_fifo_width)
            OF.r("MESSAGE_FLYING_DELAY",dealy_for_pe_busy)
            OF.r("HUB_FIFO_PHYSICAL_WIDTH",interconnect_physical_width)
            
            # Write to file
            f = open("../design/generated/top_module_for_leaf_" + str(node.id) + ".sv", "w")
            f.write(OF.out)
            f.close()

    with open("./templates/standard_planar_code_2d.sv","r") as f:
        templateSV = f.read()
        x_start = node.grid.x_start
        x_end = node.grid.x_end

        OF = hdlTemplate(templateSV)
        OF.r("ID", node.id)
        OF.r("CODE_DISTANCE_X", codeDistanceX)
        OF.r("CODE_DISTANCE_Z", codeDistanceZ)
        OF.r("EDGE_COUNT", node.edge_count) # This is split edges per measurement round
        OF.r("X_START", x_start) # This is split edges per measurement round
        OF.r("X_END", x_end) # This is split edges per measurement round
        OF.r("FPGAID_WIDTH", fpga_id_width)
        OF.r("FIFO_IDWIDTH", fifo_id_width)
        OF.r("HUB_FIFO_WIDTH", hub_fifo_width)
        neighbor_routes = generate_routing_string(node.route_directions_neighbour)
        direct_routes = generate_routing_string(node.route_directions_direct)
        OF.r("NEIGBOUR_PATH", neighbor_routes)
        OF.r("DIRECT_PATH", direct_routes)
        # Write to file
        f = open("../design/generated/standard_planar_code_2d_" + str(node.id) + ".sv", "w")
        f.write(OF.out)
        f.close()

    with open("./templates/decoder_stage_controller_dummy.sv","r") as f:
        templateSV = f.read()
        OF = hdlTemplate(templateSV)
        OF.r("ID", node.id)
        OF.r("CODE_DISTANCE_X", codeDistanceX)
        OF.r("CODE_DISTANCE_Z", codeDistanceZ)
        OF.r("HUB_FIFO_WIDTH", hub_fifo_width)
        x_start = node.grid.x_start
        x_end = node.grid.x_end
        OF.r("X_START", x_start) # This is split edges per measurement round
        OF.r("X_END", x_end) # This is split edges per measurement round

        # Write to file
        f = open("../design/generated/decoder_stage_controller_dummy_" + str(node.id) + ".sv", "w")
        f.write(OF.out)
        f.close()
    return


def add_root_hub(node):
    print("Root hub " + str(node.id))
    with open("./templates/root_hub_wrapper.sv","r") as f:
        templateSV = f.read()
        OF = hdlTemplate(templateSV)
        OF.r("ID", node.id)
        OF.r("CODE_DISTANCE_X", codeDistanceX)
        OF.r("CODE_DISTANCE_Z", codeDistanceZ)
        OF.r("ID", node.id)
        OF.r("LEVEL", node.level)
        OF.r("CHILD_ID", node.child_id)
        OF.r("NUM_CHILDREN", node.num_children)
        OF.r("HUB_FIFO_WIDTH", hub_fifo_width)
        OF.r("HUB_FIFO_PHYSICAL_WIDTH", interconnect_physical_width)
        if ll_connections==True:
            OF.r("DIRECT_CONNECTED_NEIGHBORS", 2)
        else:
            OF.r("DIRECT_CONNECTED_NEIGHBORS", 0)

        # Write to file
        f = open("../design/generated/top_level_test_bench.sv", "w")
        f.write(OF.out)
        f.close()

    # Add root hub module
    with open("./templates/root_hub.sv","r") as f:
        templateSV = f.read()
        OF = hdlTemplate(templateSV)
        OF.r("ID", node.id)
        OF.r("CODE_DISTANCE_X", codeDistanceX)
        OF.r("CODE_DISTANCE_Z", codeDistanceZ)
        OF.r("FPGAID_WIDTH", fpga_id_width)
        OF.r("FIFO_IDWIDTH", fifo_id_width)
        OF.r("DOWNSTREAM_FIFO_COUNT", node.num_children)
        OF.r("HUB_FIFO_WIDTH", hub_fifo_width)
        OF.r("HUB_FIFO_PHYSICAL_WIDTH", interconnect_physical_width)

        # Write to file
        f = open("../design/generated/root_hub_" + str(node.id) + ".sv", "w")
        f.write(OF.out)
        f.close()

    # Add hub top module
    add_hub_top_module(node)

    # Add routing table
    add_routing_table(node)

    # Add stage controller master
    with open("./templates/decoder_stage_controller_master.sv","r") as f:
        templateSV = f.read()
        OF = hdlTemplate(templateSV)
        OF.r("ID", str(node.id))
        OF.r("CODE_DISTANCE_X", codeDistanceX)
        OF.r("CODE_DISTANCE_Z", codeDistanceZ)
        OF.r("MESSAGE_FLYING_DELAY",dealy_for_pe_busy)

        # Write to file
        f = open("../design/generated/decoder_stage_controller_master_" + str(node.id) + ".sv", "w")
        f.write(OF.out)
        f.close()

    return

def add_interconnection(node):
    print("interconnection " + str(node.id))
    with open("./templates/interconnection_model_wrapper.sv","r") as f:
        templateSV = f.read()
        OF = hdlTemplate(templateSV)
        OF.r("ID", node.id)
        OF.r("NUM_CHILDREN", node.num_children)
        OF.r("INTERCONNECTION_LATENCY", interconnection_latency)
        # Write to file
        f = open("../design/generated/top_level_test_bench.sv", "a")
        f.write(OF.out)
        f.close()
    return

def add_ll_interconnection(node):
    print("interconnection " + str(node.id))
    with open("./templates/interconnection_model_wrapper_ll_connected.sv","r") as f:
        templateSV = f.read()
        OF = hdlTemplate(templateSV)
        OF.r("INTERCONNECT_ID", node.id)
        OF.r("NUM_CHILDREN", 1)
        OF.r("INTERCONNECTION_LATENCY", interconnection_latency)
        predecessor = find_node_from_leaf_id(node.leaf_id - 1)
        successor = find_node_from_leaf_id(node.leaf_id + 1)
        last_leaf = find_node_from_leaf_id(num_leaf_fpgas - 1)
        # first_leaf = find_node_from_leaf_id(0)
        if(node.leaf_id == 0):
            OF.r("WEST_ID", last_leaf.id)
        else:
            OF.r("WEST_ID", predecessor.id)
        OF.r("EAST_ID", node.id)
        # Write to file
        f = open("../design/generated/top_level_test_bench.sv", "a")
        f.write(OF.out)
        f.close()
    return

def write_ll_interconnections(node):
    print(node.id)
    if node.children == []:
        add_ll_interconnection(node)
    for child in node.children:
        # add_interconnection(node.id, child.id)
        write_ll_interconnections(child)
    return

def write_verilog_files(node):
    print(node.id)
    if node.children:
        if node.id == 0:
            add_root_hub(node)
        else:
            add_hub(node)
        add_interconnection(node)
    else:
        add_leaf(node)
    for child in node.children:
        # add_interconnection(node.id, child.id)
        write_verilog_files(child)

    if node.id == 0:
        if ll_connections==True:
            write_ll_interconnections(node)
        f = open("../design/generated/top_level_test_bench.sv", "a")
        f.write("\n\nendmodule")
        f.close()
    return

def num_FPGAs(node):
    # print(node.id)
    total_dependents = 0
    for child in node.children:
        total_dependents = total_dependents + num_FPGAs(child)
    return total_dependents + 1

def num_leafs(node, current_leaf_id):
    # print(node.id)
    for child in node.children:
        node.leaf_id = -1
        current_leaf_id = num_leafs(child, current_leaf_id)
    if node.children ==[]:
        node.leaf_id = current_leaf_id
        current_leaf_id = current_leaf_id + 1
    if node.id == 0:
        #root node also has a max leaf id for convenince
        node.leaf_id = current_leaf_id
    return current_leaf_id

def populate_grid_of_each_fpga(node, numSplit):
    if node.children == []:
        x_start = math.ceil(codeDistanceX *node.leaf_id / numSplit)
        x_end = math.ceil(codeDistanceX *(node.leaf_id+1) / numSplit) - 1
        z_start = 0
        z_end = codeDistanceZ - 1
        node.grid = Node_Grid(x_start, x_end, z_start, z_end)
        print(str(node.leaf_id) + " : " + str(x_start)+" " + str(x_end))
        edgeCount = 0
        if(node.leaf_id == 0 and node.leaf_id == numSplit - 1):
            edgeCount = 0
        elif(node.leaf_id == 0 or node.leaf_id == numSplit - 1):
            edgeCount = codeDistanceZ
        else:
            edgeCount = codeDistanceZ*2
        node.edge_count = edgeCount
    for child in node.children:
        populate_grid_of_each_fpga(child, numSplit)
    return

def find_node_from_leaf_id_internal(node, leaf_id):
    if (node.leaf_id == leaf_id):
        return (node, TRUE)
    else:
        for child in node.children:
            return_node, result = find_node_from_leaf_id_internal(child, leaf_id)
            if(result == TRUE):
                return (return_node, TRUE)
    return (node, FALSE)

def find_node_from_leaf_id(leaf_id):
    # print("REquest for "+str(leaf_id))
    result = find_node_from_leaf_id_internal(global_pointer_to_parent, leaf_id)
    return result[0]

def generate_neighbor_FPGA_list(node):
    predecessor = find_node_from_leaf_id(node.leaf_id - 1)
    print("Predecessor of  "+str(node.id)+"("+str(node.leaf_id)+") : "+ str(predecessor.id))
    successor = find_node_from_leaf_id(node.leaf_id + 1)
    last_leaf = find_node_from_leaf_id(num_leaf_fpgas - 1)
    first_leaf = find_node_from_leaf_id(0)
    print("Num leaf FPGAs "+str(num_leaf_fpgas))
    if(node.leaf_id == 0):
        fpga_list = [last_leaf,successor]
    elif(node.leaf_id == num_leaf_fpgas - 1):
        fpga_list = [predecessor,first_leaf]
    else:
        fpga_list = [predecessor,successor]
    for element in fpga_list:
        print("Neighbor of  "+str(node.id)+"("+str(node.leaf_id)+") : "+ str(element.id))
    bit_width = fpga_id_width
    start_string = str(bit_width) + "'d"
    output_string = ""
    for idx, element in enumerate(fpga_list):
        if(idx < 1):
            output_string = output_string + start_string + str(element.leaf_id) + ", "
        else:
            output_string = output_string + start_string + str(element.leaf_id)

    return output_string


def create_routing_destinations(node, numSplit):
    print(str(node.leaf_id) + str(node.grid))
    if node.children == []:
        x_start = node.grid.x_start
        x_end = node.grid.x_end
        predecessor = find_node_from_leaf_id(node.leaf_id - 1)
        successor = find_node_from_leaf_id(node.leaf_id + 1)
        last_leaf = find_node_from_leaf_id(numSplit - 1)
        # print(neighbour_routing_list)
        # if(node.leaf_id == 0):
        #     print(str(successor.leaf_id)+" "+str(last_leaf.leaf_id))

        for round in range(0,codeDistanceX):
            for edge in range(0,node.edge_count):
                if(edge < codeDistanceZ): # All northern edges except the first one
                    if(node.leaf_id == 0):
                        # print(node.route_directions_neighbour)
                        node.route_directions_neighbour.append(Route_Entry(successor.leaf_id, edge + round*(successor.edge_count)))
                        # print(node.route_directions_neighbour)
                    else:
                        if(predecessor.leaf_id == 0):
                            node.route_directions_neighbour.append(Route_Entry(predecessor.leaf_id, edge + round*(predecessor.edge_count)))
                        else:
                            node.route_directions_neighbour.append(Route_Entry(predecessor.leaf_id, edge + codeDistanceZ + round*(predecessor.edge_count)))
                else: # All southern edges
                    node.route_directions_neighbour.append(Route_Entry(successor.leaf_id, edge - codeDistanceZ + round*(successor.edge_count)))
                    # print(node.route_directions_neighbour)

        # node.route_directions_neighbour = neighbour_routing_list;

        for round in range(0,codeDistanceX):
            for edge in range(0,node.edge_count):
                if(edge < codeDistanceZ):
                    if(node.leaf_id == 0):
                        node.route_directions_direct.append(Route_Entry(last_leaf.leaf_id, edge + round*(successor.edge_count)))
                    else:
                        node.route_directions_direct.append(Route_Entry(predecessor.leaf_id, edge + round*(predecessor.edge_count)))
                else:
                    node.route_directions_direct.append(Route_Entry(0 , 0))

        # node.route_directions_direct = direct_routing_list;
        print("Neighbor entries")
        for entry in node.route_directions_neighbour:
            print(str(entry.fpga)+" "+str(entry.fifo))
        print("Direct entries")
        for entry in node.route_directions_direct:
            print(str(entry.fpga)+" "+str(entry.fifo))

    for child in node.children:
        create_routing_destinations(child, numSplit)

def generate_routing_string(route_list):
    bit_width = fpga_id_width + fifo_id_width
    start_string = str(bit_width) + "'d"
    output_string = ""
    for element in route_list:
        output_string = output_string + start_string + str((element.fpga << fifo_id_width) + element.fifo) + ", "

    output_string = output_string + "32'd0"
    return output_string

def get_max_edge_count(node):
    max_edge_count = 0
    if node.children == []:
        max_edge_count = node.edge_count 
    for child in node.children:
        max_edge_count = max(max_edge_count, get_max_edge_count(child))
    return max_edge_count

def get_child_list(node):
    list = []
    if node.children == []:
        list.append(node.leaf_id)
    for child in node.children:
        list = list + get_child_list(child)
    return list

def calculate_fpga_id_width(node):
    # FPGA ID is based on total number of FPGAs on the tree + rootFPGA
    # num_leaf_fpgas = num_leafs(node, 0)
    print("NUM leaf FPGAs = " + str(num_leaf_fpgas)) # +1 for root FPGA and +1 for broadcast message
    return math.ceil(math.log2(num_leaf_fpgas + 2))

def calculate_fifo_id_width(node):
    # FPGA ID is based on total number of FPGAs on the tree + rootFPGA
    # num_leaf_fpgas = num_leafs(node, 0)
    populate_grid_of_each_fpga(node, num_leaf_fpgas)
    create_routing_destinations(node, num_leaf_fpgas)
    max_edges = get_max_edge_count(node)
    print("max_edges = " + str(max_edges * codeDistanceX))
    return math.ceil(math.log2(max(max_edges*codeDistanceX + 1,2))) #+1 for stage controller

def calculate_hub_fifo_width():
    per_dimesnion_width = math.ceil(math.log2(codeDistanceX))
    direct_message_width = per_dimesnion_width*3 + 2
    total_width = fpga_id_width + fifo_id_width + 1 + direct_message_width
    print("logical_width_hub_fifo = " + str(total_width))
    return total_width


numSplit = 2
leaf_to_hub_fifo_width = 32 #Pick a proper number
treeStructure, global_details = user_configuration.treeConfig()
global_pointer_to_parent = treeStructure
codeDistanceX = global_details.codeDistanceX
codeDistanceZ = global_details.codeDistanceZ
hub_fifo_width = global_details.interconnectWidth
interconnect_physical_width = global_details.interconnectPhysicalWidth
interconnection_latency = global_details.interconnection_latency
ll_connections = global_details.ll_connections

dealy_for_pe_busy = interconnection_latency + 6;
num_leaf_fpgas = num_leafs(treeStructure, 0)
fpga_id_width = calculate_fpga_id_width(treeStructure)
print("FPGA ID WIDTH = " + str(fpga_id_width))
fifo_id_width = calculate_fifo_id_width(treeStructure)
print("FIFO ID WIDTH = " + str(fifo_id_width))
hub_fifo_width = calculate_hub_fifo_width()
# interconnect_physical_width = hub_fifo_width
# edgeCount = 2
templateSV = ""

write_verilog_files(treeStructure)

# Now let's calculate dimensions for l2 and above hub cards










