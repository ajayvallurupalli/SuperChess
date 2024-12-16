import piece, moves

#I dont' know why printing any base pieces causes a fatal error, but don't do it I guess

#TODO FIND WHY THIS DOES NOT WORK SOMETHIMES
const rookWhenTaken*: WhenTaken = proc (taken: var Piece, taker: var Piece, board: var ChessBoard, state: var BoardState): tuple[endTile: Tile, takeSuccess: bool] =
    #castling behavior
    if taker.item == King and 
        taken.item == Rook and
        taken.sameColor(taker) and
        taker.timesMoved == 1 and #one move from castling
        taken.timesMoved == 0: 
            state.side[taken.color].hasCastled = true
            let kingTile = taker.tile
            if taken.tile.file == 0:
                taker.pieceMove(kingTile.rank, kingTile.file - 2, board, state)
                taken.pieceMove(kingTile.rank, kingTile.file - 1, board, state)
                return ((kingTile.file - 1, kingTile.rank), false)
            else:
                taker.pieceMove(kingTile.rank, kingTile.file + 2, board, state)
                taken.pieceMove(kingTile.rank, kingTile.file + 1, board, state)
                return ((kingTile.file + 1, kingTile.rank), false)
    else:
        #if not taken by king (how castling works), it does regular behavior
        return defaultWhenTaken(taken, taker, board, state)

#base pieces, should be copied and not used on their own
#its annoying to have to do the defaults here, but I couldn't find another way
const
    blackRook*: Piece = Piece(item: Rook, color: black, moves: @[rookMoves], takes: @[rookTakes], onMove: defaultOnMove, onTake: defaultOnTake,
                                whenTaken: rookWhenTaken, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "rook.svg")
    blackKnight*: Piece = Piece(item: Knight, color: black, moves: @[knightMoves], takes: @[knightTakes], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTaken: defaultWhenTaken, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "knight.svg")
    blackQueen*: Piece = Piece(item: Queen, color: black, moves: queenMoves, takes: queenTakes, onMove: defaultOnMove, onTake: defaultOnTake,
                                whenTaken: defaultWhenTaken, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "queen.svg")
    blackKing*: Piece = Piece(item: King, color: black, moves: @[kingMoves], takes: @[kingTakes, kingCastles], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTaken: defaultWhenTaken, onEndTurn: @[defaultOnEndTurn],  onPromote: @[defaultOnEndTurn],
                                filePath: "king.svg")
    blackBishop*: Piece = Piece(item: Bishop, color: black, moves: @[bishopMoves], takes: @[bishopTakes], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTaken: defaultWhenTaken, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "bishop.svg")
    whiteRook*: Piece = Piece(item: Rook, color: white, moves: @[rookMoves], takes: @[rookTakes], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTaken: rookWhenTaken, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "rook.svg")
    whiteKnight*: Piece = Piece(item: Knight, color: white, moves: @[knightMoves], takes: @[knightTakes], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTaken: defaultWhenTaken, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "knight.svg")
    whiteQueen*: Piece = Piece(item: Queen, color: white, moves: queenMoves, takes: queenTakes, onMove: defaultOnMove, onTake: defaultOnTake,
                                whenTaken: defaultWhenTaken, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "queen.svg")
    whiteKing*: Piece = Piece(item: King, color: white, moves: @[kingMoves], takes: @[kingTakes, kingCastles], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTaken: defaultWhenTaken, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "king.svg")
    whiteBishop*: Piece = Piece(item: Bishop, color: white, moves: @[bishopMoves], takes: @[bishopTakes], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTaken: defaultWhenTaken, onEndTurn: @[defaultOnEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "bishop.svg")
    air*: Piece = Piece(item: None, color: white)

const onPawnPromote*: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) = 
    piece = state.side[piece.color].dna[Queen].pieceCopy(
        index = piece.index,
        piecesTaken = piece.piecesTaken, 
        timesMoved = piece.timesMoved,
        tile = piece.tile, 
        color = piece.color, #this is unncesscary, but I might as well keep it
        filePath = "queen.svg"
    )

const onPawnEnd*: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) = 
    if piece.isAtEnd() and not piece.promoted:
        piece.promote(board, state)

#wierd order is because pawn requires onPawnEnd, which requires whiite queen. I wish Nim had hoisting
#edit it turns out you can do hoist like in moves.nim but I can't figure out how to do it here
const 
    blackPawn*: Piece = Piece(item: Pawn, color: black, moves: @[blackPawnMoves], takes: @[blackPawnTakes], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTaken: defaultWhenTaken, onEndTurn: @[onPawnEnd], onPromote: @[onPawnPromote],
                                filePath: "pawn.svg")
    whitePawn*: Piece = Piece(item: Pawn, color: white, moves: @[whitePawnMoves], takes: @[whitePawnTakes], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTaken: defaultWhenTaken, onEndTurn: @[onPawnEnd], onPromote: @[onPawnPromote],
                                filePath: "pawn.svg")

proc startingBoard*(state: var BoardState): ChessBoard = 
    result = [[blackRook, blackKnight, blackBishop, blackQueen, blackKing, blackBishop, blackKnight, blackRook],
              [blackPawn, blackPawn,   blackPawn,   blackPawn,  blackPawn, blackPawn,   blackPawn,   blackPawn],
              [air,       air,         air,         air,        air,       air,         air,         air],
              [air,       air,         air,         air,        air,       air,         air,         air],
              [air,       air,         air,         air,        air,       air,         air,         air],
              [air,       air,         air,         air,        air,       air,         air,         air],
              [whitePawn, whitePawn,   whitePawn,   whitePawn,  whitePawn, whitePawn,   whitePawn,   whitePawn],
              [whiteRook, whiteKnight, whiteBishop, whiteQueen, whiteKing, whiteBishop, whiteKnight, whiteRook]]

    for i, r in result:
        for j, x in r:
            result[i][j] = x.pieceCopy(index = newIndex(state), tile = (j, i))


proc startingMiniBoard*(state: var BoardState): MiniChessBoard = 
    result = [[air,      air,            air,         air,          air],
              [air,      blackPawn,     blackPawn,    blackPawn,    air],
              [air,      air,           air,          air,          air],
              [air,      whitePawn,     whitePawn,    whitePawn,    air],
              [air,      air,           air,          air,          air]]

    for i, r in result:
        for j, x in r:
            result[i][j] = x.pieceCopy(index = newIndex(state), tile = (j, i))

#I only learned how to do `default` recently, but I'm just going to stick with old implementation
func startingState*(): BoardState = 
    result.shared = SharedState()
    result.side = [SideState(), SideState()]

    result.side[white].dna = [
        King: whiteKing,
        Queen: whiteQueen,
        Bishop: whiteBishop,
        Pawn: whitePawn,
        Rook: whiteRook,
        Knight: whiteRook,
        None: air,
        Fairy: air
    ]

    result.side[black].dna = [
        King: blackKing,
        Queen: blackQueen,
        Bishop: blackBishop,
        Pawn: blackPawn,
        Rook: blackRook,
        Knight: blackRook,
        None: air,
        Fairy: air
    ]


#TESTS
when isMainModule:
    assert blackKnight.moves.typeof() is seq[MoveProc]

