# Code distance to handle
codeDistance = 13

# Number of FPGAs to split between
numSplit = 4

# Maximum number of PUs per FPGA, leave as 0 for even balancing
maxPU = 0

def retConfig():
    return (codeDistance, numSplit, maxPU)