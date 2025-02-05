import ../piece
from ../basePieces import air
import std/tables
import std/options

# a frozen pieces will lose some amount of their moves every turn
#it will be different moves taken every turn
proc frozenAction(): StatusAction = 
    var capturedActions: Table[int, seq[MoveProc]] #indexed by `Piece.index` (which is an int)
    var noise = 42

    result.action = proc (b: var ChessBoard, s: var BoardState) = 
        #first we return previously captured actions
        for i, j in b.rankAndFile:
            if capturedActions.hasKey(b[i][j].index):
                b[i][j].moves &= capturedActions[b[i][j].index]
                capturedActions.del(b[i][j].index) #clear to avoid duping moves

        #then we find and delete some moves, sotring them in the captured actions
        for i, j in b.rankAndFile:
            if b[i][j].status[Frozen].isSome():
                let strength = b[i][j].status[Frozen].get().strength
                capturedActions[b[i][j].index] = @[] #open it for adding
                for _ in 0..strength:
                    let toDelete = b[i][j].moves[noise mod b[i][j].moves.len]
                    b[i][j].moves.delete(b[i][j].moves.find(toDelete))
                    capturedActions[b[i][j].index].add(toDelete)

                    noise += b[i][j].index + b[i][j].timesMoved #i don't know if this does anything
                    #but I want to avoid random since it seems to not be working at the moment

                    if b[i][j].moves.len == 0: break
    
    result.cure = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) =
        assert capturedActions.hasKey(piece.index)
        piece.status[Frozen] = none(StatusData)
        piece.moves &= capturedActions[piece.index]
        capturedActions.del(piece.index)
        


#a poisoned piece will die in some amount of turns turns, no matter what happens
proc poisonAction(): StatusAction = 
    result.action = proc (b: var ChessBoard, s: var BoardState) = 
        for i, j in b.rankAndFile:
            if b[i][j].status[Poisoned].isSome(): 
                    var previous = b[i][j].status[Poisoned].get()
                    dec previous.strength
                    b[i][j].status[Poisoned] = some(previous)

                    if previous.strength == 0: #kill
                        b[i][j] = air.pieceCopy(index = b[i][j].index, tile = b[i][j].tile)
                        inc s.side[previous.afflicter].abilityTakes
                        b[i][j].status[Poisoned] = none(StatusData)

    result.cure = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) =
        piece.status[Poisoned] = none(StatusData)

const decStatuses: UncolorBoardActionAction = proc (b: var ChessBoard, s: var BoardState) = 
    for i, j in b.rankAndFile:
        for name, data in b[i][j].status.pairs:
            if data.isSome():
                var previous = data.get() #i feel like there has to be a better way to do this
                dec previous.turnsLeft
                b[i][j].status[name] = some(previous)

                if previous.turnsLeft == 0 and name != Poisoned: #Poisoned cannot be removeed with time, because it is only removed when the piece dies
                    s.shared.cures[name](b[i][j], b, s) #cure it once turns left is 0


proc initStatusConditions*(s: var BoardState) =
    let poison = poisonAction()
    let frozen = frozenAction()

    s.shared.cures[Poisoned] = poison.cure 
    s.shared.cures[Frozen] = frozen.cure 

    s.shared.onEndTurn.add((
        action: poison.action,
        priority: 4
    ))

    s.shared.onEndTurn.add((
        action: frozen.action,
        priority: 15
    ))

    s.shared.onEndTurn.add((
        action: decStatuses,
        priority: 100
    ))

proc freeze*(tile: Tile, strength: int, afflicter: Color, board: var ChessBoard) =
    if board[tile].status[Frozen].isNone():
        board[tile].status[Frozen] = some((
            strength: strength,
            turnsLeft: 5,
            afflicter: afflicter
        ))