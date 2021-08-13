import user_configuration
import partitionScheme as partition
import math
import copy

class hdlTemplate:
    out = ""
    def __init__(self, out):
        self.out = out
    def r(self, keyword, repl):
        self.out = self.out.replace("/*$$" + keyword + "*/", repl)
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
    if(ret[-1]==":"):
        ret = ret + str(otw)
    return ret
def gridIO(grid,p):
    offset=[(1,0,0),(0,1,1),(-1,0,2),(-1,0,3)]
    ret = []
    for i in range(len(grid)):
        for j in range(len(grid[0])):
            if(grid[i][j] == p):
                apVal = [0,0,0,0,1 if i==0 or i == len(grid)-1 else 0, 1 if j==0 or j == len(grid[0])-1 else 0]
                for off in offset:
                    if i+off[0]<len(grid) and  i+off[0]>=0 and j+off[1]<len(grid[0]) and j+off[1]>=0:
                        if(grid[i+off[0]][j+off[1]] != grid[i][j]):
                            apVal[off[2]] = 1
                
                ret.append(apVal)
    return ret
def fifosHere(ioList, xDir):
    ret = []
    x=0
    for v in ioList:
        ret.append([[1] if v[xDir] == 1 else [0],x])
        x = x+1
    return ret
def xToY(grid, p):
    offset=[(0,1),(1,0),(0,-1),(-1,0)]
    ret = []
    index = 0
    y = 0
    for i in range(len(grid)):
        for j in range(len(grid[0])):
            if(grid[i][j] == p):
                ySet = False
                offC = 0
                for off in offset:
                    if i+off[0]<len(grid) and  i+off[0]>=0 and j+off[1]<len(grid[0]) and j+off[1]>=0:
                        if(grid[i+off[0]][j+off[1]] != grid[i][j]):
                            ret.append([index, offC, y])
                            y = y + 1
                            ySet = True
                    offC = offC + 1
                index = index + 1
    return ret
def getEdgeCount(grid, p):
    offset=[(0,-1),(0,1),(-1,0),(1,0)]
    ret = 0
    for i in range(len(grid)):
        for j in range(len(grid[0])):
            if(grid[i][j] == p):
                for off in offset:
                    if i+off[0]<len(grid) and  i+off[0]>=0 and j+off[1]<len(grid[0]) and j+off[1]>=0:
                        if(grid[i+off[0]][j+off[1]] != grid[i][j]):
                            ret = ret + 1
    return ret
codeDistance, numSplit, maxPU = user_configuration.retConfig()
binWidth = math.ceil(math.log(codeDistance, 2))
vOut = []
#edgeCount, splitBoard = partition.findOptBoard(codeDistance, codeDistance, numSplit) if maxPU == 0 else partition.findOptBoard(codeDistance, codeDistance, numSplit, maxPU)
totalFIFOs, splitBoard = (19, [
    [1, 1, 1, 1, 0, 0, 0, 0, 0],
    [1, 1, 1, 1, 0, 0, 0, 0, 0],
    [1, 1, 1, 1, 0, 0, 0, 0, 0],
    [1, 1, 1, 1, 0, 0, 0, 0, 0],
    [1, 1, 1, 1, 3, 3, 3, 3, 3],
    [2, 2, 2, 2, 2, 3, 3, 3, 3],
    [2, 2, 2, 2, 2, 3, 3, 3, 3],
    [2, 2, 2, 2, 2, 3, 3, 3, 3],
    [2, 2, 2, 2, 2, 3, 3, 3, 3]])
print("FIFOs: " + str(totalFIFOs))
partition.printGrid(splitBoard)

templateSV = ""
with open("./templates/standard_planar_code_2d.sv","r") as f:
    templateSV = f.read()
for i in range(numSplit):
    puInst = 0
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
                puInst = puInst + 1
    edgeCount = getEdgeCount(splitBoard, i)
    gridFifos = gridIO(splitBoard,i)
    OF = hdlTemplate(templateSV)
    OF.r("ID", str(i))
    OF.r("EDGE_COUNT", str(edgeCount))
    OF.r("PU_COORD_WIDTH", str(2*binWidth*2*sum(splitBoard,[]).count(i)))
    OF.r("PU_COORDS", puCoords)
    OF.r("PU_CONT", puCont)
    OF.r("EDGE_DIRS_WIDTH", str(5*sum(splitBoard,[]).count(i)))
    OF.r("BIN_WIDTH", str(binWidth))
    OF.r("PU_INST", str(puInst))
    OF.r("X_TO_Y",  inlineCase(["x","dir"], xToY(splitBoard,i), 0))
    # Suspect, in particular wrapping is pretty badly understood
    OF.r("IS_FIFO_VERT_INPUT", inlineCase(["x"], fifosHere(gridFifos,0),0))
    OF.r("IS_FIFO_HOR_INPUT", inlineCase(["x"], fifosHere(gridFifos,1),0))
    OF.r("IS_FIFO_VERT_OUTPUT", inlineCase(["x"], fifosHere(gridFifos,2),0))
    OF.r("IS_FIFO_HOR_OUTPUT", inlineCase(["x"], fifosHere(gridFifos,3),0))
    OF.r("IS_WRAP_HOR", inlineCase(["x"], fifosHere(gridFifos,4),0))
    OF.r("IS_WRAP_VERT", inlineCase(["x"], fifosHere(gridFifos,5),0))
    f = open("standard_planar_code_2d_" + str(i) + ".sv", "w")
    f.write(OF.out)
    f.close()
