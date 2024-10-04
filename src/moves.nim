import board, piece, std/options
#export Shooter, ShooterFactory

#checks if `shoot(t)` is air in `board`. 
#If it is, `shoot(t)` is added to `addTo` and returns true
#if `shoot(t)` is occupied, or if it is out of bounds of `board`, then it returns false
#####The return value allows for conditionals on whether to continue searching
#`shoot(t)` is of type `shooter` (see `tile.Shooter`)
func addIfFree*(addTo: var Moves, board: ChessBoard, t: Tile, shoot: Shooter): bool = 
    let target: Option[Piece] = board.boardRef(shoot(t)) #Options is used to avoid index errors
    if target.isSome() and target.get().isAir():  #checks if tile exists and if it is empty
        addTo.add(shoot(t))
        return true
    return false

#like `proc addIfFree`, but checks if `shoot(t)` is occupied in `board` (see `proc moves.addIfFree`)
#unlike `addIfFree`, returns true if air is found
#and returns false if an occupied tile is found, unless if `throughFlag` is changed from default of false
#this means that, in a loop, it continues until it finds a `Tile` to take, unless if can go through pieces
#if `canabalismFlag` is true, pieces can take same colored pieces
func addIfTake*(addTo: var Moves, board: ChessBoard, initialPiece: Piece, t: Tile, 
                shoot: Shooter, throughFlag: bool = false, canabalismFlag: bool = false): bool = 
    let target: Option[Piece] = board.boardRef(shoot(t)) #Options again used to avoid index errors
    if target.isSome() and not target.get().isAir() and #checks if tile exists and that it is occupied
        (not sameColor(initialPiece, target.get()) or canabalismFlag): #only allows same color if `canabalismFlag` is true
            addTo.add(shoot(t))
            return false or throughFlag #returns false unless if through flag is enabled
    return target.isSome() and (target.get().isAir() or throughFlag)

# on `board`, returns sequence possible moves for a `Piece` at `Tile` `t`,
#following any move pattern descriped by `Shooter` `shoot` (see `tile.Shooter`)
func lineMoves*(board: ChessBoard, p: Piece, shoot: Shooter): Moves =
    var next: Tile = p.tile
    while result.addIfFree(board, next, shoot):
        next = shoot(next)

# on `board`, returns sequence possible takes for a `Piece` at `Tile` `t`
#following any move pattern descriped by `Shooter` `shoot` (see `tile.Shooter`)
#`p` is used to stop same color takes, unless if `canabalismFlag` is true
#and takes will stop once the first is found, unless if `throughFlag` is enabled
func lineTakes*(board: ChessBoard, p: Piece, shoot: Shooter, 
                throughFlag: bool = false, canabalismFlag: bool = false): Moves = 
    var next: Tile = p.tile
    while result.addIfTake(board, p, next, shoot, throughFlag = throughFlag, canabalismFlag = canabalismFlag):
        next = shoot(next)


#returns sequence of possible moves for a `PieceType.pawn` at `Tile` `t`. 
#for a pawn of `Color.white`
#does not include potential takes, see `proc pawnTakes`
#checks whether the pawn has been moved, but does not increment `Piece.timesMoved`
const whitePawnMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    if p.timesMoved == 0:
        let next: bool = result.addIfFree(board, p.tile, tileAbove)
        if next:
            discard result.addIfFree(board, p.tile.tileAbove(), tileAbove)
    else:
        discard result.addIfFree(board, p.tile, tileAbove)

#returns sequence of possible takes for a `PieceType.pawn` at `Tile` `t`. 
#for a pawn of `Color.white`
#does not include potential nontaking moves, see `proc pawnMoves`
const whitePawnTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, shooterFactory(1, -1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1, -1))

#returns sequence of possible moves for a `PieceType.pawn` at `Tile` `t`. 
#for pawns of `Color.black` since black pawns technically go the other way
#does not include potential takes, see `proc pawnTakes`
#checks whether the pawn has been moved, but does not increment `Piece.timesMoved`
const blackPawnMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    if p.timesMoved == 0:
        let next: bool = result.addIfFree(board, p.tile, tileBelow)
        if next:
            discard result.addIfFree(board, p.tile.tileBelow(), tileBelow)
    else:
        discard result.addIfFree(board, p.tile, tileBelow)

#returns sequence of possible takes for a `PieceType.pawn` at `Tile` `t`. 
#for pawns of `Color.black` since black pawns technically go the other way
#does not include potential nontaking moves, see `proc pawnMoves`
const blackPawnTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, shooterFactory(1, 1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1, 1))

const kingMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    for i in -1..1:
        for j in -1..1:
            discard result.addIfFree(board, p.tile, shooterFactory(i,j))

const kingTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    for i in -1..1:
        for j in -1..1:
            discard result.addIfTake(board, p, p.tile, shooterFactory(i,j))

const rookMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    result.add(lineMoves(board, p, tileAbove))
    result.add(lineMoves(board, p, tileBelow))
    result.add(lineMoves(board, p, tileLeft))
    result.add(lineMoves(board, p, tileRight))

const rookTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    result.add(lineTakes(board, p, tileAbove))
    result.add(lineTakes(board, p, tileBelow))
    result.add(lineTakes(board, p, tileLeft))
    result.add(lineTakes(board, p, tileRight))

const bishopMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves =
    result.add(lineMoves(board, p, shooterFactory(1, 1)))
    result.add(lineMoves(board, p, shooterFactory(-1, 1)))
    result.add(lineMoves(board, p, shooterFactory(1, -1)))
    result.add(lineMoves(board, p, shooterFactory(-1, -1)))


const bishopTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    result.add(lineTakes(board, p,  shooterFactory(1, 1)))
    result.add(lineTakes(board, p, shooterFactory(-1, 1)))
    result.add(lineTakes(board, p,  shooterFactory(1, -1)))
    result.add(lineTakes(board, p, shooterFactory(-1, -1)))

const queenMoves*: seq[MoveProc] = @[bishopMoves,  rookMoves, kingMoves]
const queenTakes*: seq[MoveProc] = @[bishopTakes,  rookTakes, kingTakes]


const knightMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfFree(board, p.tile, shooterFactory(1, 2))
    discard result.addIfFree(board, p.tile, shooterFactory(-1, 2))
    discard result.addIfFree(board, p.tile, shooterFactory(1, -2))
    discard result.addIfFree(board, p.tile, shooterFactory(-1, -2))
    discard result.addIfFree(board, p.tile, shooterFactory(2, 1))
    discard result.addIfFree(board, p.tile, shooterFactory(2, -1))
    discard result.addIfFree(board, p.tile, shooterFactory(-2, 1))
    discard result.addIfFree(board, p.tile, shooterFactory(-2, -1))

const knightTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, shooterFactory(1, 2))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1, 2))
    discard result.addIfTake(board, p, p.tile, shooterFactory(2, 1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(2, -1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(1, -2))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1, -2))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-2, 1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-2, -1))



#TESTS
when isMainModule:
    let whitePawn: Piece = Piece(item: pawn, color: white, tile: (0,5))
    let blackPawn: Piece = Piece(item: pawn, color: black, tile: (0,5))
    let testBoard: ChessBoard = emptyBoard()

    assert lineTakes(testBoard, whitePawn, tileAbove) == @[(0,1)]
    assert lineTakes(testBoard, whitePawn, tileAbove, throughFlag = true) == @[(0,1), (0,0)]
    assert lineTakes(testBoard, blackPawn, tileAbove) == @[]
    assert lineTakes(testBoard, blackPawn, tileAbove, canabalismFlag = true) == @[(0,1)]
    assert lineTakes(testBoard, blackPawn, tileAbove, canabalismFlag = true, throughFlag = true) == @[(0,1), (0,0)]
    assert lineTakes(testBoard, whitePawn, tileLeft, canabalismFlag = true, throughFlag = true) == @[]