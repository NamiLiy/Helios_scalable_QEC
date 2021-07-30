from copy import deepcopy

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
            print(board[i+offset[x][1]][j+offset[x][0]])
            if board[i+offset[x][1]][j+offset[x][0]] != p:
                ret = ret + (2**x)
                print(ret)
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

def direction(i, j, board):
    board[i][j]
def printGrid(grid):
    for row in grid:
        string = ""
        for el in row:
            string = string + (str(el) if el == -1 else " " + str(el))
        print(string)

def findOptBoard(x,y, maxP, maxN, depth=3):
    board = [[-1]*x for _ in range(y)]
    board[0][0] = 0
    for i in range(maxP*maxN):
        suggestion = score(depth, board, maxP, maxN)
        board[suggestion[2]][suggestion[3]]=suggestion[1]
#        print(chr(27) + "[2J")
#        printGrid(board)
    return board
