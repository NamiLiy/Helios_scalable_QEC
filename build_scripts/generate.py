import partitionScheme as partition
import math

numSplit = 2
codeDistance = 3
binWidth = math.ceil(math.log(codeDistance, 2))
vOut = []
splitBoard = partition.findOptBoard(codeDistance, codeDistance, numSplit, math.ceil((codeDistance**2)/numSplit))
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
    vOut[i] = vOut[i].replace("$$PU_COORD_WIDTH", str(2*binWidth*2*sum(splitBoard,[]).count(i)))
    vOut[i] = vOut[i].replace("$$PU_COORDS", puCoords)
    vOut[i] = vOut[i].replace("$$PU_CONT", puCont)
    vOut[i] = vOut[i].replace("$$EDGE_DIRS_WIDTH", str(5*sum(splitBoard,[]).count(i)))
    vOut[i] = vOut[i].replace("$$BIN_WIDTH", str(binWidth))
    vOut[i] = vOut[i].replace("$$PU_INST", str(len(puCoords)))
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
