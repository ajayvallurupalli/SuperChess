#TODO remove Rank and File types since I forgot to use them, or maybe try to use them
#all the types are defined here, even though their implementations are in other files, to fix cyclical definitons with `Piece`
#I could have put it in a new file, but I didn't. The reason remains one of the world's greatest mysteries. 

type
    Tile* = tuple[file: File, rank: Rank]
    Rank* = int 
    File* = int

    ChessRow* = array[0..7, Piece]
    ChessBoard* = array[0..7, Chessrow]

    PieceType* = enum
        king, queen, bishop, pawn, rook, knight, none, fairy
    Color* = enum
        black, white

    Moves* = seq[Tile]
    MoveProc* = proc(board: ChessBoard, piece: Piece): Moves {.noSideEffect.}
    Shooter* = proc(tile: Tile): Tile {.noSideEffect.}
    OnAction* = proc(piece: var Piece, to: Tile, board: var ChessBoard)
    WhenTaken* = proc(taken: var Piece, taker: var Piece, board: var ChessBoard): tuple[endTile: Tile, takeSuccess: bool]
    OnPiece* = proc (piece: var Piece, board: var ChessBoard)

    Piece* = object
        item*: Piecetype
        color*: Color
        timesMoved*: int = 0
        piecesTaken*: int = 0
        tile*: Tile = (file: -1, rank: -1)
        moves*: seq[MoveProc]  #list of procs which return moves
        takes*: seq[MoveProc]
        onMove*: OnAction  #on___ and whenTaken are methods for the objecy
        onTake*: OnAction   #methods are on the object because it makes them more dynamic
        whenTaken*: WhenTaken 
        onEndTurn*: seq[OnPiece] 
        onPromote*: seq[OnPiece]
        promoted*: bool = false
        filePath*: string = ""
        rotate*: bool = false

#helper templates for `Piece` methods
#since methods are properties of the class, you would usually have to do `Piece.method(Piece)`
#since you need to access it in `Piece` and pass `Piece`
#these templates fix that boilerplate a little bit
template move* (a: var Piece, b: Tile, c: var ChessBoard): untyped = 
    a.onMove(a, b, c)

template take* (a: var Piece, b: Tile, c: var ChessBoard): untyped = 
    a.onTake(a, b, c)

template promote* (a: Piece, c: var ChessBoard): untyped = 
    for p in a.onPromote:
        p(a, c)
        if a.promoted: break

template endTurn* (a: var Piece, c: var ChessBoard): untyped = 
    for p in a.onEndTurn:
        p(a, c)

template takenBy*(taken: var Piece, taker: var Piece, board: var ChessBoard): tuple[endTile: Tile, takeSuccess: bool] = 
    taken.whenTaken(taken, taker, board)

template takenBy*(taken: Tile, taker: var Piece, board: var ChessBoard): tuple[endTile: Tile, takeSuccess: bool] = 
    board[taken.rank][taken.file].whenTaken(board[taken.rank][taken.file], taker, board)

#returns a tuple for each rank file pair of the board
#so this 
#```for i in 0..<board.len:
#        for j in 0..<board[0].len:```
#is replaced with
#```for i, j in rankAndFile(board):```
iterator rankAndFile*(board: ChessBoard): tuple[rank: int, file: int] = 
    for i in 0..<board.len:
        for j in 0..<board[0].len:
            yield (i, j)

func getMovesOn*(p: Piece, board: ChessBoard): Moves = 
    for x in p.moves:
        result.add(x(board, p))

func getTakesOn*(p: Piece, board: ChessBoard): Moves = 
    for x in p.takes:
        result.add(x(board, p))

proc pieceMove*(p: var Piece, rank: int, file: int, board: var ChessBoard) = 
    board[rank][file] = board[p.tile.rank][p.tile.file]
    board[p.tile.rank][p.tile.file] = Piece(item: none, tile: p.tile)
    board[rank][file].tile = (file: file, rank: rank)

proc pieceMove*(p: var Piece, t: Tile, board: var ChessBoard) = 
    pieceMove(p, t.rank, t.file, board)

proc pieceMove*(p: Tile, t: Tile, board: var ChessBoard) = 
    pieceMove(board[p.rank][p.file], t.rank, t.file, board)

proc pieceMove*(p: var Piece, t: Piece, board: var ChessBoard) = 
    pieceMove(p, t.tile.rank, t.tile.file, board)

proc pieceSwap*(p1: Piece, p2: Piece, board: var ChessBoard) = 
    let temp = p1

    board[p1.tile.rank][p1.tile.file] = p2
    board[p2.tile.rank][p2.tile.file] = temp
    board[p1.tile.rank][p1.tile.file].tile = (file: p1.tile.file, rank: p1.tile.rank)
    board[temp.tile.rank][temp.tile.file].tile = (file: temp.tile.file, rank: temp.tile.rank)

const defaultOnEndTurn*: OnPiece = proc(piece: var Piece, board: var ChessBoard) = 
        discard nil

const defaultWhenTaken*: WhenTaken = proc(taken: var Piece, taker: var Piece, board: var ChessBoard): tuple[endTile: Tile, takeSuccess: bool] = 
    taker.pieceMove(taken, board)
    return (taken.tile, true)

const defaultOnMove*: OnAction = proc (piece: var Piece, to: Tile, board: var ChessBoard) = 
    assert piece.getMovesOn(board).contains(to)
    inc piece.timesMoved
    piece.pieceMove(to, board)

const defaultOnTake*: OnAction = proc (piece: var Piece, taking: Tile, board: var ChessBoard) = 
    assert piece.getTakesOn(board).contains(taking)
    let takeResult = taking.takenBy(piece, board)
    inc piece.timesMoved
    if takeResult.takeSuccess:
        board[takeResult.endTile.rank][takeResult.endTile.file].piecesTaken += 1

func pieceCopy*(initial: Piece,
                item: PieceType = initial.item, 
                color: Color = initial.color,
                timesMoved: int = initial.timesMoved, 
                piecesTaken: int = initial.piecesTaken,
                tile: Tile = initial.tile,
                moves: seq[MoveProc] = initial.moves,
                takes: seq[MoveProc] = initial.takes,
                onMove: OnAction = initial.onMove,
                onTake: OnAction = initial.onTake,
                whenTaken: WhenTaken = initial.whenTaken,
                onEndTurn: seq[proc(piece: var Piece, board: var ChessBoard)] = initial.onEndTurn,
                onPromote: seq[proc(piece: var Piece, board: var ChessBoard)] = initial.onPromote,
                promoted: bool = initial.promoted,
                filePath: string = initial.filePath,
                rotate: bool = initial.rotate): Piece = 
    return Piece(item: item, color: color, timesMoved: timesMoved, piecesTaken: piecesTaken,
                tile: tile, moves: moves, takes: takes, onMove: onMove, onTake: onTake,
                whenTaken: whenTaken, onEndTurn: onEndTurn, onPromote: onPromote,promoted: promoted, filePath: filePath, rotate: rotate)

func isAir*(p: Piece): bool = 
    return p.item == none

func sameColor*(a: Piece, b: Piece): bool = 
    return a.color == b.color

func isColor*(a: Piece, b: Color): bool = 
    return a.color == b

func otherSide*(a: Color): Color = 
    return if a == white: black else: white

func `$`*(p: Piece): string = 
    if p.item == none:
        return ""
    else: 
        return $p.color & $p.item

func alive*(c: Color, b: ChessBoard): bool = 
    for row in b:
        for p in row:
            if p.item == king and p.isColor(c):
                return true

    return false

func gameIsOver*(b: ChessBoard): bool = 
    var kings: int = 0
    for row in b:
        for p in row:
            if p.item == king: inc kings

    return kings != 2

func getPiecesChecking*(b: ChessBoard, c: Color): seq[Tile] = 
    var kingTile: Tile = (-1, -1)
    for row in b:
        for p in row:
            if p.item == king and p.isColor(c):
                kingTile = p.tile

    for row in b:
        for p in row:
            if not p.isColor(c) and kingTile in p.getTakesOn(b):
                result.add(p.tile)

