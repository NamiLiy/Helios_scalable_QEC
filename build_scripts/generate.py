import user_configuration
import partitionScheme as partition
import math
import copy

def inlineCase(var, pairs, otw):
    ret = ""
    for p in pairs:
        ret = ret + var + "==" + str(p[0]) + "?" + str(p[1]) + ":"
    if(ret[-1]==":"):
        ret = ret + str(otw)
    return ret
def xToY(grid, p):
    offset=[(1,0),(0,-1),(-1,0),(0,1)]
    ret = []
    index = 0
    y = 0
    for i in range(len(grid)):
        for j in range(len(grid[0])):
            ySet = False
            for off in offset:
                if i+off[0]<len(grid) and  i+off[0]>=0 and j+off[1]<len(grid[0]) and j+off[1]>=0:
                    if(grid[i+off[0]][j+off[1]] != grid[i][j]):
                        if(not ySet):
                            ret.append((index,y))
                            y = y + 1
                            ySet = True
            index = index + 1
    return ret
codeDistance, numSplit, maxPU = user_configuration.retConfig()
binWidth = math.ceil(math.log(codeDistance, 2))
vOut = []
#edgeCount, splitBoard = partition.findOptBoard(codeDistance, codeDistance, numSplit) if maxPU == 0 else partition.findOptBoard(codeDistance, codeDistance, numSplit, maxPU)
edgeCount, splitBoard = (19, [
    [1, 1, 1, 1, 0, 0, 0, 0, 0],
    [1, 1, 1, 1, 0, 0, 0, 0, 0],
    [1, 1, 1, 1, 0, 0, 0, 0, 0],
    [1, 1, 1, 1, 0, 0, 0, 0, 0],
    [1, 1, 1, 1, 3, 3, 3, 3, 3],
    [2, 2, 2, 2, 2, 3, 3, 3, 3],
    [2, 2, 2, 2, 2, 3, 3, 3, 3],
    [2, 2, 2, 2, 2, 3, 3, 3, 3],
    [2, 2, 2, 2, 2, 3, 3, 3, 3]])
print("Boundaries: " + str(edgeCount))
partition.printGrid(splitBoard)

templateSV = ""
with open("./templates/standard_planar_code_2d.sv","r") as f:
    templateSV = f.read()
for i in range(numSplit):
    puCoords = ""
    puCont = ""
    initComma = True
    for y in range(len(splitBoard)):
        for x in range(len(splitBoard[0])):
            if(splitBoard[x][y] == i):
                if(initComma):
                    initComma=False
                else:
                    puCoords = puCoords + ", "
                    puCont = puCont + " || "
                puCoords= puCoords + str(binWidth) + "d'" + str(x) + ", " + str(binWidth) + "d'" + str(y)
                puCont = puCont + "i == " + str(x) + " && " + "j == " + str(y)
    vOut.append(templateSV)
    vOut[i] = vOut[i].replace("$$ID", str(i))
    vOut[i] = vOut[i].replace("$$EDGE_COUNT", str(edgeCount))
    vOut[i] = vOut[i].replace("$$PU_COORD_WIDTH", str(2*binWidth*2*sum(splitBoard,[]).count(i)))
    vOut[i] = vOut[i].replace("$$PU_COORDS", puCoords)
    vOut[i] = vOut[i].replace("$$PU_CONT", puCont)
    vOut[i] = vOut[i].replace("$$EDGE_DIRS_WIDTH", str(5*sum(splitBoard,[]).count(i)))
    vOut[i] = vOut[i].replace("$$BIN_WIDTH", str(binWidth))
    vOut[i] = vOut[i].replace("$$PU_INST", str(len(puCoords)))
    vOut[i] = vOut[i].replace("$$X_TO_Y", inlineCase("x", xToY(splitBoard,i), 0))
    #vOut[i] = vOut[i].replace("$$GEN0_K", "k=0; k < CODE_DISTANCE; k = k+1")
    #vOut[i] = vOut[i].replace("$$GEN0_J", "j=0; k < CODE_DISTANCE-1; k = k+1")
    #if(i==1):
        #vOut[i] = vOut[i].replace("$$GEN2_LOW", "0")
    #else:
        #vOut[i] = vOut[i].replace("$$GEN2_LOW", "(CODE_DISTANCE % " + str(numSplit) + ") + " + str(i) + " * (CODE_DISTANCE - CODE_DISTANCE % " + str(numSplit) + ") / " + str(numSplit))
    #vOut[i] = vOut[i].replace("$$GEN2_HIGH", "(CODE_DISTANCE % " + str(numSplit) + ") + " + str(i) + " * (CODE_DISTANCE - CODE_DISTANCE % " + str(numSplit) + ") / " + str(numSplit)) 
    f = open("standard_planar_code_2d_" + str(i) + ".sv", "w")
    f.write(vOut[i])
    f.close()
