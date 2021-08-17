import user_configuration
import partitionScheme as pt
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

codeDistanceX, codeDistanceY, numSplit, maxPU = user_configuration.retConfig()
binWidth = math.ceil(math.log(max(codeDistanceX, codeDistanceY), 2))
vOut = []
totalFIFOs, splitBoard = pt.findOptBoard(codeDistanceX, codeDistanceY, numSplit)
print("FIFOs: " + str(totalFIFOs))
pt.printGrid(splitBoard)

templateSV = ""
with open("./templates/standard_planar_code_2d.sv","r") as f:
    templateSV = f.read()
for i in range(numSplit):
    puInst = 0
    puCoords = ""
    puCont = ""
    initComma = True
    for x in range(len(splitBoard)):
        for y in range(len(splitBoard[0])):
            if(splitBoard[x][y] == i):
                if(initComma):
                    initComma=False
                else:
                    puCoords = puCoords + ", "
                    puCont = puCont + " || "
                puCoords= puCoords + str(binWidth) + "d'" + str(x) + ", " + str(binWidth) + "d'" + str(y)
                puCont = puCont + "i == " + str(x) + " && " + "j == " + str(y)
                puInst = puInst + 1
    edgeCount = pt.getEdgeCount(splitBoard, i)
    gridFifos = pt.gridIO(splitBoard,i)
    OF = hdlTemplate(templateSV)
    OF.r("ID", str(i))
    OF.r("EDGE_COUNT", str(edgeCount))
    OF.r("PU_COORD_WIDTH", str(2*binWidth*2*sum(splitBoard,[]).count(i)))
    OF.r("PU_COORDS", puCoords)
    OF.r("PU_CONT", puCont)
    OF.r("EDGE_DIRS_WIDTH", str(5*sum(splitBoard,[]).count(i)))
    OF.r("BIN_WIDTH", str(binWidth))
    OF.r("PU_INST", str(puInst))
    OF.r("X_TO_Y",  inlineCase(["x","dir"], pt.xToY(splitBoard,i), 0))

    # Bugs likely to occur below, wrapping badly understood still
    OF.r("IS_FIFO_VERT_INPUT", inlineCase(["x"], pt.fifosHere(gridFifos,0),0))
    OF.r("IS_FIFO_HOR_INPUT", inlineCase(["x"], pt.fifosHere(gridFifos,1),0))
    OF.r("IS_FIFO_VERT_OUTPUT", inlineCase(["x"], pt.fifosHere(gridFifos,2),0))
    OF.r("IS_FIFO_HOR_OUTPUT", inlineCase(["x"], pt.fifosHere(gridFifos,3),0))
    OF.r("IS_WRAP_HOR", inlineCase(["x"], pt.fifosHere(gridFifos,4),0))
    OF.r("IS_WRAP_VERT", inlineCase(["x"], pt.fifosHere(gridFifos,5),0))
    OF.r("INC_I", inlineCase(["x"], pt.incI(splitBoard, i), 0))
    OF.r("INC_J", inlineCase(["x"], pt.incJ(splitBoard, i), 0))

    # Write to file
    f = open("standard_planar_code_2d_" + str(i) + ".sv", "w")
    f.write(OF.out)
    f.close()
