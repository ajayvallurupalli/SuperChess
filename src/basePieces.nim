import piece, moves

#I dont' know why printing any base pieces causes a fatal error, but don't do it I guess

const rookWhenTaken*: WhenTaken = proc (taken: var Piece, taker: var Piece, board: var ChessBoard): tuple[endTile: Tile, takeSuccess: bool] =
    if taker.item == king and 
        taken.item == rook and
        taker.timesMoved == 0 and
        taken.timesMoved == 0: 
            let kingTile = taker.tile
            if taken.tile.file == 0:
                taker.pieceMove(kingTile.rank, kingTile.file - 2, board)
                taken.pieceMove(kingTile.rank, kingTile.file - 1, board)
                return ((kingTile.file - 1, kingTile.rank), false)
            else:
                taker.pieceMove(kingTile.rank, kingTile.file + 2, board)
                taken.pieceMove(kingTile.rank, kingTile.file + 1, board)
                return ((kingTile.file + 1, kingTile.rank), false)
    else:
        return defaultWhenTaken(taken, taker, board)

#base pieces, should be copied and not used on their own
#its annoying to have to do the defaults here, but I couldn't find another way
const
    blackRook*: Piece = Piece(item: rook, color: black, moves: @[rookMoves], takes: @[rookTakes], onMove: defaultOnMove, onTake: defaultOnTake,
                                whenTaken: rookWhenTaken, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "blackrook.svg")
    blackKnight*: Piece = Piece(item: knight, color: black, moves: @[knightMoves], takes: @[knightTakes], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTaken: defaultWhenTaken, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "blackknight.svg")
    blackQueen*: Piece = Piece(item: queen, color: black, moves: queenMoves, takes: queenTakes, onMove: defaultOnMove, onTake: defaultOnTake,
                                whenTaken: defaultWhenTaken, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "blackqueen.svg")
    blackKing*: Piece = Piece(item: king, color: black, moves: @[kingMoves], takes: @[kingTakes, kingCastles], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTaken: defaultWhenTaken, onEndTurn: @[defaultOnEndTurn],  onPromote: @[defaultOnEndTurn],
                                filePath: "blackking.svg")
    blackBishop*: Piece = Piece(item: bishop, color: black, moves: @[bishopMoves], takes: @[bishopTakes], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTaken: defaultWhenTaken, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "blackbishop.svg")
    whiteRook*: Piece = Piece(item: rook, color: white, moves: @[rookMoves], takes: @[rookTakes], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTaken: rookWhenTaken, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "whiterook.svg")
    whiteKnight*: Piece = Piece(item: knight, color: white, moves: @[knightMoves], takes: @[knightTakes], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTaken: defaultWhenTaken, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "whiteknight.svg")
    whiteQueen*: Piece = Piece(item: queen, color: white, moves: queenMoves, takes: queenTakes, onMove: defaultOnMove, onTake: defaultOnTake,
                                whenTaken: defaultWhenTaken, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "whitequeen.svg")
    whiteKing*: Piece = Piece(item: king, color: white, moves: @[kingMoves], takes: @[kingTakes, kingCastles], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTaken: defaultWhenTaken, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "whiteking.svg")
    whiteBishop*: Piece = Piece(item: bishop, color: white, moves: @[bishopMoves], takes: @[bishopTakes], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTaken: defaultWhenTaken, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "whitebishop.svg")
    air*: Piece = Piece(item: none, color: white)

const onPawnPromote*: OnPiece = proc (piece: var Piece, board: var ChessBoard) = 
    piece = blackQueen.pieceCopy(piecesTaken=piece.piecesTaken, tile=piece.tile, promoted = true, color = piece.color, filePath = $piece.color & "queen.svg")

const onPawnEnd*: OnPiece = proc (piece: var Piece, board: var ChessBoard) = 
    if piece.isAtEnd() and not piece.promoted:
        piece.promote(board)

#wierd order is because pawn requires onPawnEnd, which requires whiite queen. I wish Nim had hoisting
#edit it turns out you can do hoist like in moves.nim but I can't figure out how to do it here
const 
    blackPawn*: Piece = Piece(item: pawn, color: black, moves: @[blackPawnMoves], takes: @[blackPawnTakes], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTaken: defaultWhenTaken, onEndTurn: @[onPawnEnd], onPromote: @[onPawnPromote],
                                filePath: "blackpawn.svg")
    whitePawn*: Piece = Piece(item: pawn, color: white, moves: @[whitePawnMoves], takes: @[whitePawnTakes], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTaken: defaultWhenTaken, onEndTurn: @[onPawnEnd], onPromote: @[onPawnPromote],
                                filePath: "whitepawn.svg")

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

