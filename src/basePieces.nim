import piece, moves

#I dont' know why mentioning any base pieces causes a fatal error, but don't do it I guess


#base pieces, should be copied and not used on their own
#its annoying to have to do the defaults here, but I couldn't find another way
const
    blackRook*: Piece = Piece(item: rook, color: black, moves: @[rookMoves], takes: @[rookTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn)
    blackKnight*: Piece = Piece(item: knight, color: black, moves: @[knightMoves], takes: @[knightTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn)
    blackQueen*: Piece = Piece(item: queen, color: black, moves: queenMoves, takes: queenTakes, onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn)
    blackKing*: Piece = Piece(item: king, color: black, moves: @[kingMoves], takes: @[kingTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn)
 
    blackBishop*: Piece = Piece(item: bishop, color: black, moves: @[bishopMoves], takes: @[bishopTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn)

    whiteRook*: Piece = Piece(item: rook, color: white, moves: @[rookMoves], takes: @[rookTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn)
    whiteKnight*: Piece = Piece(item: knight, color: white, moves: @[knightMoves], takes: @[knightTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn)
    whiteQueen*: Piece = Piece(item: queen, color: white, moves: queenMoves, takes: queenTakes, onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn)
    whiteKing*: Piece = Piece(item: king, color: white, moves: @[kingMoves], takes: @[kingTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn)
    whiteBishop*: Piece = Piece(item: bishop, color: white, moves: @[bishopMoves], takes: @[bishopTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: defaultOnEndTurn)

    air*: Piece = Piece(item: none, color: white)

proc onPawnEnd(taker: Tile, taken: Tile, board: var ChessBoard) = 
    let pawn = board[taken.rank][taken.file]
    if taken.rank == 0:
        board[taken.rank][taken.file] = whiteQueen.pieceCopy(piecesTaken=pawn.piecesTaken, tile=pawn.tile)
    elif taken.rank == 7:
        board[taken.rank][taken.file] = blackQueen.pieceCopy(piecesTaken=pawn.piecesTaken, tile=pawn.tile)

#wierd order is because pawn requires onPawnEnd, which requires whiite queen. I wish Nim had hoisting, I think its the only thing that's missing
const 
    blackPawn*: Piece = Piece(item: pawn, color: black, moves: @[blackPawnMoves], takes: @[blackPawnTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: onPawnEnd) 
    whitePawn*: Piece = Piece(item: pawn, color: white, moves: @[whitePawnMoves], takes: @[whitePawnTakes], onMove: defaultOnMove, onTake: defaultOnTake, whenTake: defaultWhenTake, onEndTurn: onPawnEnd)

proc startingBoard*(): ChessBoard = 
    result = [[blackRook, blackKnight, blackBishop, blackqueen, blackKing, blackBishop, blackKnight, blackRook],
              [blackPawn, blackPawn,   blackPawn,   blackPawn,  blackPawn, blackPawn,   blackPawn,   blackPawn],
              [air,       air,         air,         air,        air,       air,         air,         air],
              [air,       air,         air,         air,        air,       air,         air,         air],
              [air,       air,         air,         air,        air,       air,         air,         air],
              [air,       air,         air,         air,        air,       air,         air,         air],
              [whitePawn, whitePawn,   whitePawn,   whitePawn,  whitePawn, whitePawn,   whitePawn,   whitePawn],
              [whiteRook, whiteKnight, whiteBishop, whitequeen, whiteKing, whiteBishop, whiteKnight, whiteRook]]

    for j, r in result:
        for i, x in r:
            result[j][i] = x.pieceCopy(tile = (i, j))

when isMainModule:
    assert blackKnight.moves.typeof() is seq[MoveProc]

