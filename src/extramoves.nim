import piece, basePieces, moves, board

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

const cannibalKnightTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, shooterFactory(1, 2), cannibalismFlag = true)
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1, 2), cannibalismFlag = true)
    discard result.addIfTake(board, p, p.tile, shooterFactory(2, 1), cannibalismFlag = true)
    discard result.addIfTake(board, p, p.tile, shooterFactory(2, -1), cannibalismFlag = true)
    discard result.addIfTake(board, p, p.tile, shooterFactory(1, -2), cannibalismFlag = true)
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1, -2), cannibalismFlag = true)
    discard result.addIfTake(board, p, p.tile, shooterFactory(-2, 1), cannibalismFlag = true)
    discard result.addIfTake(board, p, p.tile, shooterFactory(-2, -1), cannibalismFlag = true)


const giraffeTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, shooterFactory(1,4))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1,4))
    discard result.addIfTake(board, p, p.tile, shooterFactory(1,-4))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1,-4))
    discard result.addIfTake(board, p, p.tile, shooterFactory(4,1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(4,-1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-4,1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-4,-1))

const giraffeMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfFree(board, p.tile, shooterFactory(1,4))
    discard result.addIfFree(board, p.tile, shooterFactory(-1,4))
    discard result.addIfFree(board, p.tile, shooterFactory(1,-4))
    discard result.addIfFree(board, p.tile, shooterFactory(-1,-4))
    discard result.addIfFree(board, p.tile, shooterFactory(4,1))
    discard result.addIfFree(board, p.tile, shooterFactory(4,-1))
    discard result.addIfFree(board, p.tile, shooterFactory(-4,1))
    discard result.addIfFree(board, p.tile, shooterFactory(-4,-1))