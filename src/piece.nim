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
    OnAction* = proc(taker: Tile, taken: Tile, board: var ChessBoard)
    OnTakeAction = proc(taker: Tile, taken: Tile, board: var ChessBoard): tuple[endTile: Tile, takeSuccess: bool]

    Piece* = object
        item*: Piecetype
        color*: Color
        timesMoved*: int = 0
        piecesTaken*: int = 0
        tile*: Tile = (file: -1, rank: -1)
        moves*: seq[MoveProc]
        takes*: seq[MoveProc]
        onMove*: OnAction 
        onTake*: OnAction
        whenTake*: OnTakeAction 
        onEndTurn*: seq[OnAction] 
        onPromote*: seq[OnAction]
        promoted*: bool = false
        filePath*: string = ""
        rotate*: bool = false

func getMovesOn*(p: Piece, board: ChessBoard): Moves = 
    for x in p.moves:
        result.add(x(board, p))

func getTakesOn*(p: Piece, board: ChessBoard): Moves = 
    for x in p.takes:
        result.add(x(board, p))

const defaultOnEndTurn*: OnAction = proc (taker: Tile, taken: Tile, board: var ChessBoard) = 
        discard nil

proc defaultWhenTake*(taker: Tile, taken: Tile, board: var ChessBoard): tuple[endTile: Tile, takeSuccess: bool] = 
    if (taker.file == taken.file) and (taker.rank == taken.file): return (taken, false) #stops pieces from taking themselves, though this can be overridden
    board[taker.rank][taker.file].tile = taken
    board[taken.rank][taken.file] = board[taker.rank][taker.file]
    board[taker.rank][taker.file] = Piece(item: none, tile: taker)
    board[taker.rank][taker.file].piecesTaken += 1
    return ((taken.file, taken.rank), true)

proc defaultOnMove*(taker: Tile, taken: Tile, board: var ChessBoard) = 
    assert board[taker.rank][taker.file].getMovesOn(board).contains(taken)
    board[taker.rank][taker.file].tile = taken
    board[taker.rank][taker.file].timesMoved += 1
    board[taken.rank][taken.file] = board[taker.rank][taker.file]
    board[taker.rank][taker.file] = Piece(item: none, tile: taker)

    for f in board[taken.rank][taken.file].onEndTurn:
        f(taker, taken, board)

proc defaultOnTake*(taker: Tile, taken: Tile, board: var ChessBoard) = 
    assert board[taker.rank][taker.file].getTakesOn(board).contains(taken)
    let newTile = board[taken.rank][taken.file].whenTake(taker, taken, board)
    board[newTile.endTile.rank][newTile.endTile.file].timesMoved += 1
    if newTile.takeSuccess:
        board[newTile.endTile.rank][newTile.endTile.file].piecesTaken += 1

    for f in board[newTile.endTile.rank][newTile.endTile.file].onEndTurn:
        f(newTile.endTile, taken, board)


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
                whenTake: OnTakeAction = initial.whenTake,
                onEndTurn: seq[OnAction] = initial.onEndTurn,
                onPromote: seq[OnAction] = initial.onPromote,
                promoted: bool = initial.promoted,
                filePath: string = initial.filePath,
                rotate: bool = initial.rotate): Piece = 
    return Piece(item: item, color: color, timesMoved: timesMoved, piecesTaken: piecesTaken,
                tile: tile, moves: moves, takes: takes, onMove: onMove, onTake: onTake,
                whenTake: whenTake, onEndTurn: onEndTurn, onPromote: onPromote,promoted: promoted, filePath: filePath, rotate: rotate)
            
proc pieceMove*(p: Piece, rank: int, file: int, board: var ChessBoard) = 
    board[rank][file] = board[p.tile.rank][p.tile.file]
    board[p.tile.rank][p.tile.file] = Piece(item: none, tile: p.tile)
    board[rank][file].tile = (file: file, rank: rank)

proc pieceSwap*(p1: Piece, p2: Piece, board: var ChessBoard) = 
    let temp = p1

    board[p1.tile.rank][p1.tile.file] = p2
    board[p2.tile.rank][p2.tile.file] = temp
    board[p1.tile.rank][p1.tile.file].tile = (file: p1.tile.file, rank: p1.tile.rank)
    board[temp.tile.rank][temp.tile.file].tile = (file: temp.tile.file, rank: temp.tile.rank)

proc piecePromote*(t: Tile, b: var ChessBoard) = 
    for f in b[t.rank][t.file].onPromote:
        f(t, t, b)
    b[t.rank][t.file].promoted = true

func isAir*(p: Piece): bool = 
    return p.item == none

func sameColor*(a: Piece, b: Piece): bool = 
    return a.color == b.color

func isColor*(a: Piece, b: Color): bool = 
    return a.color == b

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