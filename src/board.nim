import std/options, piece

#defined to avoid cyclical imports with basePieces
#only needed for testing, so only color and item matter
const air: Piece = Piece(item: None)
const black: Piece = Piece(color: black)
const white: Piece = Piece(color: white)

#used for testing
func emptyBoard*(): ChessBoard = 
    result = [[black, black, black, black, black, black, black, black],
              [black, black, black, black, black, black, black, black],
              [air, air, air, air, air, air, air, air],
              [air, air, air, air, air, air, air, air],
              [air, air, air, air, air, air, air, air],
              [air, air, air, air, air, air, air, air],
              [white, white, white, white, white, white, white, white],
              [white, white, white, white, white, white, white, white]]

    for j,x in result:
        for i,y in x:
            result[j][i] = y.pieceCopy(tile=(j, i))
            
func `==`*(a: Tile, b: Tile): bool = 
    return a.file == b.file and a.rank == b.rank

#returns a `Shooter` (see `Shooter) function which returns 
#a function which takes a `Tile` and returns a `Tile`
# `m` to the right and `n` below
#m is annotated with `piece.File` to not confuse it when `syncio.File`
func shooterFactory*(m: piece.File, n: Rank): Shooter = 
    result = proc(t: Tile): Tile = (t.file + m, t.rank + n)

func tileAbove*(t: Tile): Tile = 
    return (t.file, t.rank - 1)

func tileBelow*(t: Tile): Tile = 
    return (t.file, t.rank + 1)

func tileLeft*(t: Tile): Tile = 
    return (t.file - 1, t.rank)

func tileRight*(t: Tile): Tile = 
    return (t.file + 1, t.rank)

#if `t` is a valid tile for the `ChessBoard b`, it returns `Some(p)`, where `p` is the `Piece` at that tile
#otherwise, it returns none. 
#I kind of forgot to use options in the rest of the project, but it's still needed here for 
#`moves.nim`, to stop addding tiles when they are not on the board
func boardRef*(b: ChessBoard, t: Tile): Option[Piece] = 
    if t.file < 0 or t.file >= b[0].len or
        t.rank < 0 or t.rank >= b.len:
            return none(Piece)
    else:
        return some(b[t.rank][t.file])
    
func pieceAbove*(b: ChessBoard, t: Tile): Option[Piece] = 
    return b.boardRef(t.tileAbove())

func pieceBelow*(b: ChessBoard, t: Tile): Option[Piece] = 
    return b.boardRef(t.tileBelow())

func pieceLeft*(b: ChessBoard, t: Tile): Option[Piece] = 
    return b.boardRef(t.tileLeft())

func pieceRight*(b: ChessBoard, t: Tile): Option[Piece] = 
    return b.boardRef(t.tileRight())

#TESTS
when isMainModule:
    var testBoard: ChessBoard = emptyBoard()
    assert testBoard.pieceBelow((0,0)).isSome()
    assert testBoard.pieceAbove((0,0)).isNone()
    assert testBoard.pieceRight((0,0)).isSome()
    assert testBoard.pieceLeft((0,0)).isNone()

    let a: Tile = (2,2)
    assert a == (2,2)
    assert a == (a).tileAbove().tileBelow()
    assert shooterFactory(0,0)(a) == (a).tileRight().tileLeft()
    assert shooterFactory(1,1)(a) == (a).tileRight().tileBelow()
    assert shooterFactory(-1,-1)(a) == (a).tileAbove().tileLeft()