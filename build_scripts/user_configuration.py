# Code distance to handle
codeDistanceX = 3
codeDistanceZ = 3

# Number of FPGAs to split between
numSplit = 2

# Maximum number of PUs per FPGA, leave as 0 for even balancing
presetArrange = [[]]

def retConfig():
    return (codeDistanceX, codeDistanceZ, numSplit, presetArrange)
