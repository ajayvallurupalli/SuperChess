import piece, moves, board
from sequtils import filterIt

#[
This file has extra moves used by powers
Normal Chess moves are found in moves.nim
]#

#I just realized I've been spelling diagonal wrong this whole time
#oh well

const whiteDiagnalMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfFree(board, p.tile, shooterFactory(1,-1))
    discard result.addIfFree(board, p.tile, shooterFactory(-1,-1))

const blackDiagnalMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfFree(board, p.tile, shooterFactory(1,1))
    discard result.addIfFree(board, p.tile, shooterFactory(-1,1))

const whiteDiagnalTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, shooterFactory(1,-1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1,-1))

const blackDiagnalTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, shooterFactory(1,1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1,1))

const diagnalMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfFree(board, p.tile, shooterFactory(1,1))
    discard result.addIfFree(board, p.tile, shooterFactory(-1,1))
    discard result.addIfFree(board, p.tile, shooterFactory(1,-1))
    discard result.addIfFree(board, p.tile, shooterFactory(-1,-1))

const diagnalTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, shooterFactory(1,1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1,1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(1,-1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1,-1))

const leftRightMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfFree(board, p.tile, tileLeft)
    discard result.addIfFree(board, p.tile, tileRight)

const leftTwiceMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    let next = result.addIfFree(board, p.tile, tileLeft)
    if next:
        discard result.addIfFree(board, p.tile.tileLeft, tileLeft)

const rightTwiceMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    let next = result.addIfFree(board, p.tile, tileRight)
    if next:
        discard result.addIfFree(board, p.tile.tileRight, tileRight)

const leftTwiceTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    let next = result.addIfTake(board, p, p.tile, tileLeft)
    if next:
        discard result.addIfTake(board, p, p.tile.tileLeft, tileLeft)

const rightTwiceTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    let next = result.addIfTake(board, p, p.tile, tileRight)
    if next:
        discard result.addIfTake(board, p, p.tile.tileRight, tileRight)

const leftRightTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, tileLeft)
    discard result.addIfTake(board, p, p.tile, tileRight)

const whiteForwardMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfFree(board, p.tile, tileAbove)

const blackForwardMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfFree(board, p.tile, tileBelow)

const whiteForwardTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, tileAbove)

const blackForwardTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, tileBelow)

const blackBackwardMove* = whiteForwardMoves
const whiteBackwardMove* = blackForwardMoves

const whiteForwardTwiceTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    let next = result.addIfTake(board, p, p.tile, tileAbove)
    if next: 
        discard result.addIfTake(board, p, p.tile.tileAbove(), tileAbove)

const blackForwardTwiceTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    let next = result.addIfTake(board, p, p.tile, tileBelow)
    if next: 
        discard result.addIfTake(board, p, p.tile.tileBelow(), tileBelow)

const whiteForwardTwiceMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    let next = result.addIfFree(board, p.tile, tileAbove)
    if next: 
        discard result.addIfFree(board, p.tile.tileAbove(), tileAbove)

const blackForwardTwiceMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    let next = result.addIfFree(board, p.tile, tileBelow)
    if next: 
        discard result.addIfFree(board, p.tile.tileBelow(), tileBelow)

const cannibalRookTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    result.add(lineTakes(board, p, tileAbove, cannibalismFlag = true))
    result.add(lineTakes(board, p, tileBelow, cannibalismFlag = true))
    result.add(lineTakes(board, p, tileLeft, cannibalismFlag = true))
    result.add(lineTakes(board, p, tileRight, cannibalismFlag = true))

const cannibalBishopTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves =
    result.add(lineTakes(board, p, shooterFactory(1, 1), cannibalismFlag = true))
    result.add(lineTakes(board, p, shooterFactory(-1, 1), cannibalismFlag = true))
    result.add(lineTakes(board, p, shooterFactory(1, -1), cannibalismFlag = true))
    result.add(lineTakes(board, p, shooterFactory(-1, -1), cannibalismFlag = true))

const cannibalKingTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    for i in -1..1:
        for j in -1..1:
            discard result.addIfTake(board, p, p.tile, shooterFactory(i,j), cannibalismFlag = true)
    result.filterIt(it != p.tile)

const cannibalKnightTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, shooterFactory(1, 2), cannibalismFlag = true)
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1, 2), cannibalismFlag = true)
    discard result.addIfTake(board, p, p.tile, shooterFactory(2, 1), cannibalismFlag = true)
    discard result.addIfTake(board, p, p.tile, shooterFactory(2, -1), cannibalismFlag = true)
    discard result.addIfTake(board, p, p.tile, shooterFactory(1, -2), cannibalismFlag = true)
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1, -2), cannibalismFlag = true)
    discard result.addIfTake(board, p, p.tile, shooterFactory(-2, 1), cannibalismFlag = true)
    discard result.addIfTake(board, p, p.tile, shooterFactory(-2, -1), cannibalismFlag = true)

const cannibalGiraffeTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, shooterFactory(1, 3), cannibalismFlag = true)
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1, 3), cannibalismFlag = true)
    discard result.addIfTake(board, p, p.tile, shooterFactory(3, 1), cannibalismFlag = true)
    discard result.addIfTake(board, p, p.tile, shooterFactory(3, -1), cannibalismFlag = true)
    discard result.addIfTake(board, p, p.tile, shooterFactory(1, -3), cannibalismFlag = true)
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1, -3), cannibalismFlag = true)
    discard result.addIfTake(board, p, p.tile, shooterFactory(-3, 1), cannibalismFlag = true)
    discard result.addIfTake(board, p, p.tile, shooterFactory(-3, -1), cannibalismFlag = true)


const giraffeTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, shooterFactory(1,3))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1,3))
    discard result.addIfTake(board, p, p.tile, shooterFactory(1,-3))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1,-3))
    discard result.addIfTake(board, p, p.tile, shooterFactory(3,1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(3,-1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-3,1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-3,-1))

const giraffeMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfFree(board, p.tile, shooterFactory(1,3))
    discard result.addIfFree(board, p.tile, shooterFactory(-1,3))
    discard result.addIfFree(board, p.tile, shooterFactory(1,-3))
    discard result.addIfFree(board, p.tile, shooterFactory(-1,-3))
    discard result.addIfFree(board, p.tile, shooterFactory(3,1))
    discard result.addIfFree(board, p.tile, shooterFactory(3,-1))
    discard result.addIfFree(board, p.tile, shooterFactory(-3,1))
    discard result.addIfFree(board, p.tile, shooterFactory(-3,-1))

const takeSelf*: MoveProc = func(board: ChessBoard, p: Piece): Moves = 
    result.add(p.tile)

const nightriderTakes*: MoveProc = func(board: ChessBoard, p: Piece): Moves = 
    result.add(lineTakes(board, p, shooterFactory(1, 2), cannibalismFlag = true))
    result.add(lineTakes(board, p, shooterFactory(-1, 2), cannibalismFlag = true))
    result.add(lineTakes(board, p, shooterFactory(2, 1), cannibalismFlag = true))
    result.add(lineTakes(board, p, shooterFactory(2, -1), cannibalismFlag = true))
    result.add(lineTakes(board, p, shooterFactory(1, -2), cannibalismFlag = true))
    result.add(lineTakes(board, p, shooterFactory(-1, -2), cannibalismFlag = true))
    result.add(lineTakes(board, p, shooterFactory(-2, 1), cannibalismFlag = true))
    result.add(lineTakes(board, p, shooterFactory(-2, -1), cannibalismFlag = true))

const nightriderMoves*: MoveProc = func(board: ChessBoard, p: Piece): Moves = 
    result.add(lineMoves(board, p, shooterFactory(1, 2)))
    result.add(lineMoves(board, p, shooterFactory(-1, 2)))
    result.add(lineMoves(board, p, shooterFactory(2, 1)))
    result.add(lineMoves(board, p, shooterFactory(2, -1)))
    result.add(lineMoves(board, p, shooterFactory(1, -2)))
    result.add(lineMoves(board, p, shooterFactory(-1, -2)))
    result.add(lineMoves(board, p, shooterFactory(-2, 1)))
    result.add(lineMoves(board, p, shooterFactory(-2, -1)))

const blackForwardTwiceJumpMove*: MoveProc = func(board: ChessBoard, p: Piece): Moves = 
    discard result.addIfFree(board, p.tile, shooterFactory(0, 1))
    discard result.addIfFree(board, p.tile, shooterFactory(0, 2))

const blackForwardTwiceJumpTake*: MoveProc = func(board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, shooterFactory(0, 1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(0, 2))

const whiteForwardTwiceJumpMove*: MoveProc = func(board: ChessBoard, p: Piece): Moves = 
    discard result.addIfFree(board, p.tile, shooterFactory(0, -1))
    discard result.addIfFree(board, p.tile, shooterFactory(0, -2))

const whiteForwardTwiceJumpTake*: MoveProc = func(board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, shooterFactory(0, -1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(0, -2))

const whiteForwardThriceJumpTake*: MoveProc = func(board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, shooterFactory(0, -1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(0, -2))
    discard result.addIfTake(board, p, p.tile, shooterFactory(0, -3))

const blackForwardThriceJumpTake*: MoveProc = func(board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, shooterFactory(0, 1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(0, 2))
    discard result.addIfTake(board, p, p.tile, shooterFactory(0, 3))

const rookBombard*: MoveProc = func(board: ChessBoard, p: Piece): Moves = 
    if result.addIfTake(board, p, p.tile, shooterFactory(1, 1)):
        discard result.addIfTake(board, p, p.tile, shooterFactory(2, 2))
    if result.addIfTake(board, p, p.tile, shooterFactory(-1, 1)):
        discard result.addIfTake(board, p, p.tile, shooterFactory(-2, 2))
    if result.addIfTake(board, p, p.tile, shooterFactory(1, -1)):
        discard result.addIfTake(board, p, p.tile, shooterFactory(2, -2))
    if result.addIfTake(board, p, p.tile, shooterFactory(-1, -1)):
        discard result.addIfTake(board, p, p.tile, shooterFactory(-2, -2))

const whiteLanceMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    result.add(lineMoves(board, p, tileAbove))

const blackLanceMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    result.add(lineMoves(board, p, tileBelow))

const whiteLanceTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    result.add(lineTakes(board, p, tileAbove))

const blackLanceTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    result.add(lineTakes(board, p, tileBelow))

const clarityMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    result.add(leftTwiceMoves(board, p))
    result.add(rightTwiceMoves(board, p))
    result.add(whiteForwardTwiceMoves(board, p))
    result.add(blackForwardTwiceMoves(board, p))

const clarityTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    result.add(leftTwiceTakes(board, p))
    result.add(rightTwiceTakes(board, p))
    result.add(whiteForwardTwiceTakes(board, p))
    result.add(blackForwardTwiceTakes(board, p))