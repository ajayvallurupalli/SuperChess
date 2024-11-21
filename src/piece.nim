#TODO remove Rank and File types since I forgot to use them, or maybe try to use them
#all the types are defined here, even though their implementations are in other files, to fix cyclical definitons with `Piece`
#I could have put it in a new file, but I didn't. The reason remains one of the world's greatest mysteries. 

type
    Tile* = tuple[file: File, rank: Rank] #used for position of all pieces
    Rank* = int #chess terminology, though I completely forgot to follow it
    File* = int #it probably should have been an enum. Too late. Maybe just change to normal ints

    #The main data structure which holds the entire state of the board
    #It is created in `basePieces.startingBoard.nim`
    ChessRow* = array[0..7, Piece]
    ChessBoard* = array[0..7, Chessrow] 

    #none is used for empty spaces
    #fairy is used for custom spaces defined in `Powers.nim`
    PieceType* = enum
        king, queen, bishop, pawn, rook, knight, none, fairy
    Color* = enum
        black, white

    #The functions and implementations of these are defined in `moves.nim` and `board.nim`
    Moves* = seq[Tile] 
    #takes the state of the board and a piece, and returns possible `Moves` by that piece
    #It only needs to return one type of moves (like one row forward), since 
    #`Piece` takes a `seq` of `Moves`
    MoveProc* = proc(board: ChessBoard, piece: Piece): Moves {.noSideEffect.}
    Shooter* = proc(tile: Tile): Tile {.noSideEffect.}

    #`OnAction` is used when `piece` tries to move to `to`
    #it mutates the piece and the board
    OnAction* = proc(piece: var Piece, to: Tile, board: var ChessBoard)
    #`WhenTaken` is called by the `taker Piece` when it attempts to take `taken Piece`
    #It can mutate both pieces, so `endTile` should be used to access `taker` after, since `taken` and `taker` will can after this is called
    #This is one of the sad truths of the code base, but I couldn't find anyway to change the board and not change the object given
    #`takeSuccess` also returns true if the `taken` piece is killed by `taker`
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
        colorable*: bool = true
        rotate*: bool = false
        rand*: tuple[drunk: bool, seed: int]  = (false, 0) #used for some of the powers with rng

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
                colorable: bool = initial.colorable,
                rotate: bool = initial.rotate,
                rand: tuple[drunk: bool, seed: int] = initial.rand): Piece = 
    return Piece(item: item, color: color, timesMoved: timesMoved, piecesTaken: piecesTaken,
                tile: tile, moves: moves, takes: takes, onMove: onMove, onTake: onTake,
                whenTaken: whenTaken, onEndTurn: onEndTurn, onPromote: onPromote,promoted: promoted, filePath: filePath, rotate: rotate,
                rand: rand, colorable: colorable)

func isAir*(p: Piece): bool = 
    return p.item == none

func sameColor*(a: Piece, b: Piece): bool = 
    return a.color == b.color and not a.isAir() and not b.isAir()

func isColor*(a: Piece, b: Color): bool = 
    return a.color == b and not a.isAir()

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

func isAtEnd*(piece: Piece): bool = 
    return (piece.tile.rank == 7 and piece.color == black) or (piece.tile.rank == 0 and piece.color == white)