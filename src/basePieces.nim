import piece, moves

#I dont' know why mentioning any base pieces causes a fatal error, but don't do it I guess

proc rookWhenTake(taker: Tile, taken: Tile, board: var ChessBoard): Tile =
    echo board[taker.rank][taker.file].item, board[taken.rank][taken.file].item
    if board[taker.rank][taker.file].item == king and 
        board[taken.rank][taken.file].item == rook: 
            assert board[taken.rank][taken.file].timesMoved == 0
            if taken.file == 0:
                board[taker.rank][taker.file - 2] = board[taker.rank][taker.file]
                board[taker.rank][taker.file] = Piece(item: none, tile: (taker.rank, taker.file))
                board[taker.rank][taker.file - 1] = board[taken.rank][taken.file]
                board[taken.rank][taken.file] = Piece(item: none, tile: (taker.rank, taker.file))
                return (0, 0)
            else:
                board[taker.rank][taker.file + 2] = board[taker.rank][taker.file]
                board[taker.rank][taker.file] = Piece(item: none, tile: (taker.rank, taker.file))
                board[taker.rank][taker.file + 1] = board[taken.rank][taken.file]
                board[taken.rank][taken.file] = Piece(item: none, tile: (taker.rank, taker.file))
                return (0, 0)
    else:
        return defaultWhenTake(taker, taken, board)

#base pieces, should be copied and not used on their own
#its annoying to have to do the defaults here, but I couldn't find another way
const
    blackRook*: Piece = Piece(item: rook, color: black, moves: @[rookMoves], takes: @[rookTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: rookWhenTake, onEndTurn: defaultOnEndTurn)
    blackKnight*: Piece = Piece(item: knight, color: black, moves: @[knightMoves], takes: @[knightTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn)
    blackQueen*: Piece = Piece(item: queen, color: black, moves: queenMoves, takes: queenTakes, onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn)
    blackKing*: Piece = Piece(item: king, color: black, moves: @[kingMoves], takes: @[kingTakes, kingCastles], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn)
 
    blackBishop*: Piece = Piece(item: bishop, color: black, moves: @[bishopMoves], takes: @[bishopTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn)

    whiteRook*: Piece = Piece(item: rook, color: white, moves: @[rookMoves], takes: @[rookTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: rookWhenTake, onEndTurn: defaultOnEndTurn)
    whiteKnight*: Piece = Piece(item: knight, color: white, moves: @[knightMoves], takes: @[knightTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn)
    whiteQueen*: Piece = Piece(item: queen, color: white, moves: queenMoves, takes: queenTakes, onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn)
    whiteKing*: Piece = Piece(item: king, color: white, moves: @[kingMoves], takes: @[kingTakes, kingCastles], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn)
    whiteBishop*: Piece = Piece(item: bishop, color: white, moves: @[bishopMoves], takes: @[bishopTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn)
    air*: Piece = Piece(item: none, color: white)

proc onPawnEnd*(taker: Tile, taken: Tile, board: var ChessBoard) = 
    let pawn = board[taken.rank][taken.file]
    if taken.rank == 0 and not pawn.promoted:
        board[taken.rank][taken.file] = whiteQueen.pieceCopy(piecesTaken=pawn.piecesTaken, tile=pawn.tile, promoted = true)
    elif taken.rank == 7 and not pawn.promoted:
        board[taken.rank][taken.file] = blackQueen.pieceCopy(piecesTaken=pawn.piecesTaken, tile=pawn.tile, promoted = true)

#wierd order is because pawn requires onPawnEnd, which requires whiite queen. I wish Nim had hoisting, I think its the only thing that's missing
#edit it turns out you can do hoist like in moves.nim but I can't figure out how to do it here
const 
    blackPawn*: Piece = Piece(item: pawn, color: black, moves: @[blackPawnMoves], takes: @[blackPawnTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: onPawnEnd) 
    whitePawn*: Piece = Piece(item: pawn, color: white, moves: @[whitePawnMoves], takes: @[whitePawnTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: onPawnEnd)

proc startingBoard*(): ChessBoard = 
    result = [[blackRook, blackKnight, blackBishop, blackQueen, blackKing, blackBishop, blackKnight, blackRook],
              [blackPawn, blackPawn,   blackPawn,   blackPawn,  blackPawn, blackPawn,   blackPawn,   blackPawn],
              [air,       air,         air,         air,        air,       air,         air,         air],
              [air,       air,         air,         air,        air,       air,         air,         air],
              [air,       air,         air,         air,        air,       air,         air,         air],
              [air,       air,         air,         air,        air,       air,         air,         air],
              [whitePawn, whitePawn,   whitePawn,   whitePawn,  whitePawn, whitePawn,   whitePawn,   whitePawn],
              [whiteRook, whiteKnight, whiteBishop, whiteQueen, whiteKing, whiteBishop, whiteKnight, whiteRook]]

    for j, r in result:
        for i, x in r:
            result[j][i] = x.pieceCopy(tile = (i, j))

when isMainModule:
    assert blackKnight.moves.typeof() is seq[MoveProc]

