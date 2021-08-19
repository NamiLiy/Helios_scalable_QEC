import numpy as np
import math
import pymetis
from copy import deepcopy

def vertWrap(grid, p):
    x = 0
    ret = []
    for j in range(len(grid)):
        for i in range(len(grid[0])):
            if(grid[j][i] == p):
                if((i == 0 or i == len(grid[0]) - 1) and (grid[j][0] != grid[j][len(grid[0])-1])):
                    ret.append([x, 1])
            x = x + 1
    return ret
def horWrap(grid, p):
    x = 0
    ret = []
    for j in range(len(grid)):
        for i in range(len(grid[0])):
            if(grid[j][i] == p):
                if((j == 0 or j == len(grid) - 1) and (grid[0][i] != grid[len(grid)-1][i])):
                    ret.append([x, 1])
            x = x + 1
    return ret
def incI(grid, p):
    x = 0
    ret = []
    for j in range(len(grid)):
        for i in range(len(grid[0])):
            if(grid[j][i] == p):
                if(i+1 < len(grid[0]) and grid[j][i+1] == p):
                    ret.append([x,x+1])
                else:
                    m = 0
                    for z in range(i+1):
                        if(grid[j][i-z] == p):
                            m = m + 1
                    # m counts itself so add 1
                    ret.append([x,x-m+1])
                x = x + 1
    return ret
def incJ(grid, p):
    x = 0
    ret = []
    for j in range(len(grid)):
        for i in range(len(grid[0])):
            if(grid[j][i] == p):
                if(j+1 < len(grid) and grid[j+1][i] == p):
                    m = 0
                    for z in range(len(grid[0])-i):
                        if(grid[j][i+z]==p):
                            m = m + 1
                    for z in range(i+1):
                        if(grid[j+1][z] == p):
                            m = m + 1
                    # m counts itself so subtract 1
                    ret.append([x,x+m-1])
                else:
                    m = 0
                    search = True
                    for z in range(len(grid)):
                        if(not search):
                            break
                        for v in range(len(grid[0])):
                            if(grid[z][v] == p):
                                if(v == i):
                                    ret.append([x,m])
                                    search = False
                                    break
                                m = m + 1
                x = x + 1
    return ret
def gridIO(grid, p):
    offset=[(0,1,0),(1,0,1),(0,-1,2),(-1,0,3)]
    ret = []
    for j in range(len(grid)):
        for i in range(len(grid[0])):
            if(grid[j][i] == p):
                apVal = [0,0,0,0]
                for off in offset:
                    if i+off[0]<len(grid[0]) and  i+off[0]>=0 and j+off[1]<len(grid[1]) and j+off[1]>=0:
                        #print(off[2])
                        if(grid[j+off[1]][i+off[0]] != grid[j][i]):
                            apVal[off[2]] = 1
                
                ret.append(apVal)
    return ret
def fifosHere(ioList, xDir):
    ret = []
    x=0
    for v in ioList:
        ret.append([x,1 if v[xDir] == 1 else 0])
        x = x+1
    return ret
def xToY(grid, p):
    offset=[(1,0),(0,1),(-1,0),(-1,0)]
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
    offset=[(0,1),(1,0),(0,-1),(-1,0)]
    ret = 0
    for j in range(len(grid)):
        for i in range(len(grid[0])):
            if(grid[j][i] == p):
                for off in offset:
                    if j+off[1] >= 0 and j+off[1]<len(grid) and  i+off[0]>=0 and i+off[0]<len(grid[0]):
                        if(grid[j+off[1]][i+off[0]] != grid[j][i]):
                            ret = ret + 1
    return ret
def bordering(i, j, board, p):
    offset=[(1,0),(0,-1),(-1,0),(0,1)]
    x = len(board)
    y = len(board[0])
    ret = 0

    # If position is occupied
    if board[i][j] != -1:
        return -1

    # Check if it is bordering proper tile
    for off in offset:
        if i+off[0]<x and  i+off[0]>=0 and j+off[1]<y and j+off[1]>=0:
            if board[i+off[0]][j+off[1]]==p:
                ret = ret + 1
    return ret
def dirPU(board, i, j):
    offset=[(0,1),(1,0),(0,-1),(-1,0),]
    p = board[i][j]
    ret = 0
    w = len(board)
    h = len(board[0])

    for x in range(4):
        if i+offset[x][1]<w and  i+offset[x][1]>=0 and j+offset[x][0]<h and j+offset[x][0]>=0:
#            print(board[i+offset[x][1]][j+offset[x][0]])
            if board[i+offset[x][1]][j+offset[x][0]] != p:
                ret = ret + (2**x)
#                print(ret)
                if board[i+offset[x][1]][j+offset[x][0]] > p:
                    ret = ret + 2**4
    return ret
def vecField(board):
    ret = []
    for i in range(len(board)):
        ret.append([])
        for j in range(len(board[0])):
            ret[i].append(dirPU(board, i, j))
    return ret
def countP(board, p):
    return sum(board,[]).count(p)
def score(depth, board, maxP, maxN):
    x = len(board)
    y = len(board[0])
    boardVals = [[0]*x for _ in range(y)]
    suggest = (0,0,0,0)
    if depth == 0:
        return suggest
    move = False
    
    iterP = 1
    for p in range(0,maxP-1):
        if countP(board, p) != 0:
            iterP = iterP + 1

    for p in range(0, iterP):
        move = True
        if countP(board, p) < maxN and (countP(board, p) > 0 or False not in map(lambda x : countP(board, x) == 0 or countP(board, x) >= maxN - 1, list(range(0,maxP)))):
            for i in range(0, x):
                for j in range(0, y):
                    b = bordering(i, j, board, p)
                    if b != -1 and (b > 0 or sum(board,[]).count(p) == 0):
                        nBoard = deepcopy(board)
                        nBoard[i][j] = p
                        scored = deepcopy(b+score(depth-1,nBoard,maxP,maxN)[0])
                        if scored >= max(sum(boardVals,[])):
                            boardVals[i][j] = scored
                            suggest = (boardVals[i][j],p,i,j)
    if(not move and countP(board,-1) != 0):
        suggest[0] = -100
    return suggest
def adjacentGraph(x,y):
    z=0
    ret = []
    for j in range(y):
        for i in range(x):
            arr = []
            if i != 0:
                arr = arr + [z-1]
            if i != x-1:
                arr = arr + [z+1]
            if j != 0:
                arr = arr + [z-x]
            if j != y-1:
                arr = arr + [z+x]
#            print(str(z) + ", " + str(arr))
            z=z+1
            ret.append(np.array(arr))
    return ret
def direction(i, j, board):
    board[i][j]
def printGrid(grid):
    for row in grid:
        string = ""
        for el in row:
            string = string + (str(el) if el == -1 else " " + str(el))
        print(string)

def findOptBoard(x,z, maxP, maxN=-1, depth=3):
    board = [[-1]*x for _ in range(z)]
    edgeCount = 0
    if maxN != -1:
        board[0][0] = 0
        for i in range(maxP*maxN):
            suggestion = score(depth, board, maxP, maxN)
            board[suggestion[2]][suggestion[3]]=suggestion[1]
    #        print(chr(27) + "[2J")
    #        printGrid(board)
    else:
        edgeCount, membership = pymetis.part_graph(maxP, adjacency=adjacentGraph(x,z))
        for i in range(len(membership)):
            #print(str(math.floor(i / x)) + "," + str(i % x))
            board[math.floor(i/x)][i % x] = membership[i]
    return edgeCount, board
