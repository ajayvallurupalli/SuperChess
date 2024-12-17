import ../piece
from sequtils import filterIt, mapIt
from strutils import toLower
import std/options

func toGlassType*(str: string): GlassType = 
    if str.toLower() == "sky":
        return Sky
    elif str.toLower() == "zero":
        return Zero
    elif str.toLower() == "steel":
        return Steel
    elif str.toLower() == "reverie":
        return Reverie
    else:
        raiseAssert "????, " & str & " is not a glass"

#I'm plutting the glass stuff here instead of a new file
#since its only like two things
func hasGlass*(side: Color, state: BoardState): bool =
    for g in GlassType:
        if state.side[side].glass[g].isSome(): return true #kind of ugly, maybe I should rename glass to glasses?
    return false

#TODO clean this function, it's so ugly
#It should take pieces, corresponsingTiles, and a GlassAction (which is just OnAction)
#and return a function which handles if the piece disappears or moves
func packageGlass*(pieces: seq[Piece], tiles: seq[Tile], action: OnAction): BoardAction =
        let indexes = pieces.mapIt(it.index)
        result = proc (_: Color, board: var ChessBoard, state: var BoardState) =
            for i, j in board.rankAndFile:
                for indexIndex, index in indexes:
                    if index == board[i][j].index:
                        action(board[i][j], tiles[indexIndex], board, state)