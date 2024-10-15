import piece, moves

#I dont' know why mentioning any base pieces causes a fatal error, but don't do it I guess

proc rookWhenTake(taker: Tile, taken: Tile, board: var ChessBoard): tuple[endTile: Tile, takeSuccess: bool] =
    echo board[taker.rank][taker.file].item, board[taken.rank][taken.file].item
    if board[taker.rank][taker.file].item == king and 
        board[taken.rank][taken.file].item == rook and
        board[taker.rank][taker.file].timesMoved == 0 and
        board[taken.rank][taken.file].timesMoved == 0: 
            if taken.file == 0:
                board[taker.rank][taker.file].pieceMove(taker.file - 2, taker.rank, board)
                board[taken.rank][taken.file].pieceMove(taker.file - 1, taker.rank, board)
                return ((taker.file - 1, taker.rank), false)
            else:
                board[taker.rank][taker.file].pieceMove(taker.file + 2, taker.rank, board)
                board[taken.rank][taken.file].pieceMove(taker.file + 1, taker.rank, board)
                return ((taker.file + 1, taker.rank), false)
    else:
        return defaultWhenTake(taker, taken, board)

#base pieces, should be copied and not used on their own
#its annoying to have to do the defaults here, but I couldn't find another way
const
    blackRook*: Piece = Piece(item: rook, color: black, moves: @[rookMoves], takes: @[rookTakes], onMove: defaultOnMove, onTake: defaultOnTake,
                                whenTake: rookWhenTake, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "blackrook.svg")
    blackKnight*: Piece = Piece(item: knight, color: black, moves: @[knightMoves], takes: @[knightTakes], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTake: defaultWhenTake, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "blackknight.svg")
    blackQueen*: Piece = Piece(item: queen, color: black, moves: queenMoves, takes: queenTakes, onMove: defaultOnMove, onTake: defaultOnTake,
                                 whenTake: defaultWhenTake, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "blackqueen.svg")
    blackKing*: Piece = Piece(item: king, color: black, moves: @[kingMoves], takes: @[kingTakes, kingCastles], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTake: defaultWhenTake, onEndTurn: @[defaultOnEndTurn],  onPromote: @[defaultOnEndTurn],
                                filePath: "blackking.svg")
    blackBishop*: Piece = Piece(item: bishop, color: black, moves: @[bishopMoves], takes: @[bishopTakes], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTake: defaultWhenTake, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "blackbishop.svg")
    whiteRook*: Piece = Piece(item: rook, color: white, moves: @[rookMoves], takes: @[rookTakes], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTake: rookWhenTake, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "whiterook.svg")
    whiteKnight*: Piece = Piece(item: knight, color: white, moves: @[knightMoves], takes: @[knightTakes], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTake: defaultWhenTake, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "whiteknight.svg")
    whiteQueen*: Piece = Piece(item: queen, color: white, moves: queenMoves, takes: queenTakes, onMove: defaultOnMove, onTake: defaultOnTake,
                                whenTake: defaultWhenTake, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "whitequeen.svg")
    whiteKing*: Piece = Piece(item: king, color: white, moves: @[kingMoves], takes: @[kingTakes, kingCastles], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTake: defaultWhenTake, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "whiteking.svg")
    whiteBishop*: Piece = Piece(item: bishop, color: white, moves: @[bishopMoves], takes: @[bishopTakes], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTake: defaultWhenTake, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "whitebishop.svg")
    air*: Piece = Piece(item: none, color: white)

const onPawnPromote*: OnAction = proc (taker: Tile, taken: Tile, board: var ChessBoard) = 
    let pawn = board[taken.rank][taken.file]
    board[taken.rank][taken.file] = blackQueen.pieceCopy(piecesTaken=pawn.piecesTaken, tile=pawn.tile, promoted = true)
    board[taken.rank][taken.file] = whiteQueen.pieceCopy(piecesTaken=pawn.piecesTaken, tile=pawn.tile, promoted = true)

const onPawnEnd*: OnAction = proc (taker: Tile, taken: Tile, board: var ChessBoard) = 
    let pawn = board[taken.rank][taken.file]
    if (taken.rank == 0 and pawn.color == white) or 
        (taken.rank == 7 and pawn.color == black) and not pawn.promoted:
        for p in pawn.onPromote:
            p(taker, taken, board)

#wierd order is because pawn requires onPawnEnd, which requires whiite queen. I wish Nim had hoisting, I think its the only thing that's missing
#edit it turns out you can do hoist like in moves.nim but I can't figure out how to do it here
const 
    blackPawn*: Piece = Piece(item: pawn, color: black, moves: @[blackPawnMoves], takes: @[blackPawnTakes], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTake: defaultWhenTake, onEndTurn: @[onPawnEnd], onPromote: @[onPawnPromote],
                                filePath: "blackpawn.svg")
    whitePawn*: Piece = Piece(item: pawn, color: white, moves: @[whitePawnMoves], takes: @[whitePawnTakes], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTake: defaultWhenTake, onEndTurn: @[onPawnEnd], onPromote: @[onPawnPromote],
                                filePath: "whitepawn.svg")

proc startingBoard*(): ChessBoard = 
    result = [[blackRook, blackKnight, blackBishop, blackQueen, blackKing, blackBishop, blackKnight, blackRook],
              [blackPawn, blackPawn,   blackPawn,   blackPawn,  blackPawn, blackPawn,   blackPawn,   blackPawn],
              [air,       air,         air,         air,        air,       air,         air,         air],
              [air,       air,         air,         air,        air,       air,         air,         air],
              [air,       air,         air,         blackpawn,        air,       air,         air,         air],
              [air,       air,         air,         air,        blackPawn,       air,         air,         air],
              [whitePawn, whitePawn,   whitePawn,   whitePawn,  whitePawn, whitePawn,   whitePawn,   whitePawn],
              [whiteRook, whiteKnight, whiteBishop, whiteQueen, whiteKing, whiteBishop, whiteKnight, whiteRook]]

    for j, r in result:
        for i, x in r:
            result[j][i] = x.pieceCopy(tile = (i, j))

when isMainModule:
    assert blackKnight.moves.typeof() is seq[MoveProc]

