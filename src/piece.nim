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
    onAction = proc(taker: Tile, taken: Tile, board: var ChessBoard)

    Piece* = object
        item*: Piecetype
        color*: Color
        timesMoved*: int = 0
        piecesTaken*: int = 0
        tile*: Tile = (file: -1, rank: -1)
        moves*: seq[MoveProc]
        takes*: seq[MoveProc]
        onMove*: onAction 
        onTake*: onAction
        whenTake*: onAction 
        onEndTurn*: onAction 
        promoted*: bool = false

func getMovesOn*(p: Piece, board: ChessBoard): Moves = 
    for x in p.moves:
        result.add(x(board, p))

func getTakesOn*(p: Piece, board: ChessBoard): Moves = 
    for x in p.takes:
        result.add(x(board, p))

proc defaultOnEndTurn*(taker: Tile, taken: Tile, board: var ChessBoard) = 
    discard nil

proc defaultWhenTake*(taker: Tile, taken: Tile, board: var ChessBoard) = 
    board[taken.rank][taken.file] = board[taker.rank][taker.file]
    board[taker.rank][taker.file] = Piece(item: none, tile: taker)

proc defaultOnMove*(taker: Tile, taken: Tile, board: var ChessBoard) = 
    assert board[taker.rank][taker.file].getMovesOn(board).contains(taken)
    board[taker.rank][taker.file].tile = taken
    board[taker.rank][taker.file].timesMoved += 1
    board[taken.rank][taken.file] = board[taker.rank][taker.file]
    board[taker.rank][taker.file] = Piece(item: none, tile: taker)

    board[taken.rank][taken.file].onEndTurn(taker, taken, board)

proc defaultOnTake*(taker: Tile, taken: Tile, board: var ChessBoard) = 
    assert board[taker.rank][taker.file].getTakesOn(board).contains(taken)
    board[taker.rank][taker.file].tile = taken
    board[taker.rank][taker.file].timesMoved += 1
    board[taker.rank][taker.file].piecesTaken += 1
    board[taken.rank][taken.file].whenTake(taker, taken, board)

    board[taken.rank][taken.file].onEndTurn(taker, taken, board)


func pieceCopy*(initial: Piece,
                item: PieceType = initial.item, 
                color: Color = initial.color,
                timesMoved: int = initial.timesMoved, 
                piecesTaken: int = initial.piecesTaken,
                tile: Tile = initial.tile,
                moves: seq[MoveProc] = initial.moves,
                takes: seq[MoveProc] = initial.takes,
                onMove: onAction = initial.onMove,
                onTake: onAction = initial.onTake,
                whenTake: onAction = initial.whenTake,
                onEndTurn: onAction = initial.onEndTurn,
                promoted: bool = initial.promoted): Piece = 
    return Piece(item: item, color: color, timesMoved: timesMoved, piecesTaken: piecesTaken,
                tile: tile, moves: moves, takes: takes, onMove: onMove, onTake: onTake,
                whenTake: whenTake, onEndTurn: onEndTurn, promoted: promoted)
            

func isAir*(p: Piece): bool = 
    return p.item == none

func sameColor*(a: Piece, b: Piece): bool = 
    return a.color == b.color

func isColor*(a: Piece, b: Color): bool = 
    return a.color == b

func `$`*(p: Piece): string = 
    if p.item == none:
        return "none at " & $p.tile
    else: 
        return $p.color & $p.item