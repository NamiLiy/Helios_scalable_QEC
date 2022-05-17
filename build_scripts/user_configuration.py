# Code distance to handle
from email.errors import NoBoundaryInMultipartDefect
from pickletools import long4


codeDistanceX = 3
codeDistanceZ = 2

class Node:
    def __init__(self, id):
        self.children = []
        self.id = id
        self.level = 0
        self.parent = 0
        self.child_id = 0
        self.num_children = 0
        self.leaf_id = 0
        self.grid = {0,0,0,0}  #x_start x_end z_start z_end
        self.edge_count = 0

class UserProperties:
    def __init__(self, codeDistanceX, codeDistanceY):
        self.codeDistanceX = codeDistanceX
        self.codeDistanceZ = codeDistanceZ
        self.interconnectWidth = 128


def populate_other_tree_params(node, level):
    node.level = 0
    node.num_children = len(node.children)
    child_id = 0
    for child in node.children:
        child.parent = node.id
        child.child_id = child_id
        child_id = child_id + 1
        populate_other_tree_params(child, level+1)
    return

def initialize():
    root = Node(0)
    l1 = Node(1)
    l2 = Node(2)
    root.children = [l1,l2]

    # l3 = Node(3)
    # l4 = Node(4)
    # l1.children = [l3,l4]

    # l5 = Node(5)
    # l6 = Node(6)
    # l2.children = [l5,l6]
    populate_other_tree_params(root,0)
    return root

# Maximum number of PUs per FPGA, leave as 0 for even balancing
presetArrange = [[0,0],[0,0],[1,1]]
treeStructure = [[0,2],[1,2],[1,1]]

def populate_global_details():
    global_details = UserProperties(codeDistanceX,codeDistanceZ)
    return global_details

def retConfig():
    return (codeDistanceX, codeDistanceZ, numSplit, presetArrange)

def treeConfig():
    # All leafs will be indexed from zero...
    # Structure should be child to parent relations... 
    tree = initialize()
    global_details = populate_global_details()
    return (tree, global_details)

def numLeaves():
    return 2

def numHubs():
    return 1

