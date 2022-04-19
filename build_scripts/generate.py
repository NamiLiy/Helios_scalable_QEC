import user_configuration
import partitionScheme as pt
import math
import copy

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

# This is a very temporary workaround
codeDistanceX = 3
codeDistanceZ = 2
numSplit = 2
edgeCount = 2
templateSV = ""

with open("./templates/standard_planar_code_2d.sv","r") as f:
    templateSV = f.read()
for i in range(numSplit):
    x_start = math.ceil(codeDistanceX *i / numSplit)
    x_end = math.ceil(codeDistanceX *(i+1) / numSplit) - 1
    print(x_start)
    print(x_end)
    OF = hdlTemplate(templateSV)
    OF.r("ID", str(i))
    OF.r("CODE_DISTANCE_X", codeDistanceX)
    OF.r("CODE_DISTANCE_Z", codeDistanceZ)
    OF.r("EDGE_COUNT", edgeCount) # This is split edges per measurement round
    OF.r("X_START", x_start) # This is split edges per measurement round
    OF.r("X_END", x_end) # This is split edges per measurement round

    # Write to file
    f = open("../design/generated/standard_planar_code_2d_" + str(i) + ".sv", "w")
    f.write(OF.out)
    f.close()

with open("./templates/decoder_stage_controller_dummy.sv","r") as f:
    templateSV = f.read()
for i in range(numSplit):
    x_start = math.ceil(codeDistanceX *i / numSplit)
    x_end = math.ceil(codeDistanceX *(i+1) / numSplit) - 1
    OF = hdlTemplate(templateSV)
    OF.r("ID", str(i))
    OF.r("CODE_DISTANCE_X", codeDistanceX)
    OF.r("CODE_DISTANCE_Z", codeDistanceZ)
    OF.r("EDGE_COUNT", edgeCount) # This is split edges per measurement round
    OF.r("X_START", x_start) # This is split edges per measurement round
    OF.r("X_END", x_end) # This is split edges per measurement round

    # Write to file
    f = open("../design/generated/decoder_stage_controller_dummy_" + str(i) + ".sv", "w")
    f.write(OF.out)
    f.close()

with open("./templates/top_module_for_leaf.sv","r") as f:
    templateSV = f.read()
for i in range(numSplit):
    x_start = math.ceil(codeDistanceX *i / numSplit)
    x_end = math.ceil(codeDistanceX *(i+1) / numSplit) - 1
    OF = hdlTemplate(templateSV)
    OF.r("ID", str(i))
    OF.r("CODE_DISTANCE_X", codeDistanceX)
    OF.r("CODE_DISTANCE_Z", codeDistanceZ)
    OF.r("EDGE_COUNT", edgeCount) # This is split edges per measurement round
    OF.r("X_START", x_start) # This is split edges per measurement round
    OF.r("X_END", x_end) # This is split edges per measurement round

    # Write to file
    f = open("../design/generated/top_module_for_leaf_" + str(i) + ".sv", "w")
    f.write(OF.out)
    f.close()


