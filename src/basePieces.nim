import piece, moves

#I dont' know why mentioning any base pieces causes a fatal error, but don't do it I guess

proc rookWhenTake(taker: Tile, taken: Tile, board: var ChessBoard): Tile =
    echo board[taker.rank][taker.file].item, board[taken.rank][taken.file].item
    if board[taker.rank][taker.file].item == king and 
        board[taken.rank][taken.file].item == rook: 
            assert board[taken.rank][taken.file].timesMoved == 0
            if taken.file == 0:
                board[taker.rank][taker.file].tile = (taker.file - 2, taker.rank)
                board[taken.rank][taken.file].tile = (taker.file - 1, taker.rank)

                board[taker.rank][taker.file - 2] = board[taker.rank][taker.file]
                board[taker.rank][taker.file] = Piece(item: none, tile: (taker.file, taker.rank))
                board[taker.rank][taker.file - 1] = board[taken.rank][taken.file]
                board[taken.rank][taken.file] = Piece(item: none, tile: (taken.file, taken.rank))
                return (taker.file - 1, taker.rank)
            else:
                board[taker.rank][taker.file].tile = (taker.file + 2, taker.rank)
                board[taken.rank][taken.file].tile = (taker.file + 1, taker.rank)

                board[taker.rank][taker.file + 2] = board[taker.rank][taker.file]
                board[taker.rank][taker.file] = Piece(item: none, tile: (taker.file, taker.rank))
                board[taker.rank][taker.file + 1] = board[taken.rank][taken.file]
                board[taken.rank][taken.file] = Piece(item: none, tile: (taken.file, taken.rank))
                return (taker.file + 1, taker.rank)
    else:
        return defaultWhenTake(taker, taken, board)

#base pieces, should be copied and not used on their own
#its annoying to have to do the defaults here, but I couldn't find another way
const
    blackRook*: Piece = Piece(item: rook, color: black, moves: @[rookMoves], takes: @[rookTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: rookWhenTake, onEndTurn: defaultOnEndTurn,
                                filePath: "https://upload.wikimedia.org/wikipedia/commons/f/ff/Chess_rdt45.svg")
    blackKnight*: Piece = Piece(item: knight, color: black, moves: @[knightMoves], takes: @[knightTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn,
                                filePath: "https://upload.wikimedia.org/wikipedia/commons/e/ef/Chess_ndt45.svg")
    blackQueen*: Piece = Piece(item: queen, color: black, moves: queenMoves, takes: queenTakes, onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn,
                                filePath: "https://upload.wikimedia.org/wikipedia/commons/4/47/Chess_qdt45.svg")
    blackKing*: Piece = Piece(item: king, color: black, moves: @[kingMoves], takes: @[kingTakes, kingCastles], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn, 
                                filePath: "https://upload.wikimedia.org/wikipedia/commons/f/f0/Chess_kdt45.svg")
 
    blackBishop*: Piece = Piece(item: bishop, color: black, moves: @[bishopMoves], takes: @[bishopTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn,
                                filePath: "https://upload.wikimedia.org/wikipedia/commons/9/98/Chess_bdt45.svg")

    whiteRook*: Piece = Piece(item: rook, color: white, moves: @[rookMoves], takes: @[rookTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: rookWhenTake, onEndTurn: defaultOnEndTurn,
                                filePath: "https://upload.wikimedia.org/wikipedia/commons/7/72/Chess_rlt45.svg")
    whiteKnight*: Piece = Piece(item: knight, color: white, moves: @[knightMoves], takes: @[knightTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn,
                                filePath: "https://upload.wikimedia.org/wikipedia/commons/7/70/Chess_nlt45.svg")
    whiteQueen*: Piece = Piece(item: queen, color: white, moves: queenMoves, takes: queenTakes, onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn,
                                filePath: "https://upload.wikimedia.org/wikipedia/commons/1/15/Chess_qlt45.svg")
    whiteKing*: Piece = Piece(item: king, color: white, moves: @[kingMoves], takes: @[kingTakes, kingCastles], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn,
                                filePath: "https://upload.wikimedia.org/wikipedia/commons/4/42/Chess_klt45.svg")
    whiteBishop*: Piece = Piece(item: bishop, color: white, moves: @[bishopMoves], takes: @[bishopTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn,
                                filePath: "https://upload.wikimedia.org/wikipedia/commons/b/b1/Chess_blt45.svg")
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
    blackPawn*: Piece = Piece(item: pawn, color: black, moves: @[blackPawnMoves], takes: @[blackPawnTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: onPawnEnd, 
                                filePath: "https://upload.wikimedia.org/wikipedia/commons/c/c7/Chess_pdt45.svg")
    whitePawn*: Piece = Piece(item: pawn, color: white, moves: @[whitePawnMoves], takes: @[whitePawnTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: onPawnEnd,
                                filePath: "https://upload.wikimedia.org/wikipedia/commons/4/45/Chess_plt45.svg")

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

