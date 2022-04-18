# Code distance to handle
codeDistanceX = 3
codeDistanceZ = 2

# Number of FPGAs to split between
numSplit = 2

# Maximum number of PUs per FPGA, leave as 0 for even balancing
presetArrange = [[0,0],[0,0],[1,1]]

def retConfig():
    return (codeDistanceX, codeDistanceZ, numSplit, presetArrange)
