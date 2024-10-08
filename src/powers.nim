import power, moves, piece, board, basePieces

const empress*: Power = Power(
    name: "empress",
    tier: Uncommon,
    description: "Your queen ascends, gaining the movement of a standard knight. ",
    onStart: 
        proc (side: Color, b: var ChessBoard) =
            let rank = if side == black: 0 else: 7
            b[rank][3].moves.add(knightMoves)
            b[rank][3].takes.add(knightTakes)
)

const diagnalMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfFree(board, p.tile, shooterFactory(1,1))
    discard result.addIfFree(board, p.tile, shooterFactory(-1,1))
    discard result.addIfFree(board, p.tile, shooterFactory(1,-1))
    discard result.addIfFree(board, p.tile, shooterFactory(-1,-1))

const diagnalTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, shooterFactory(1,1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1,1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(1,-1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1,-1))

const leftRightMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfFree(board, p.tile, tileLeft)
    discard result.addIfFree(board, p.tile, tileRight)

const leftRightTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, tileLeft)
    discard result.addIfTake(board, p, p.tile, tileRight)

const whiteForwardMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfFree(board, p.tile, tileAbove)

const blackForwardMoves*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfFree(board, p.tile, tileBelow)

const whiteForwardTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, tileAbove)

const blackForwardTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, tileBelow)

proc silverGeneralPromote(taker: Tile, taken: Tile, board: var ChessBoard) = 
    if (taken.rank == 0 or taken.rank == 7) and not board[taken.rank][taken.file].promoted: 
        board[taken.rank][taken.file].moves &= leftRightMoves
        board[taken.rank][taken.file].moves &= leftRightTakes

const mysteriousSwordsmanLeft*: Power = Power(
    name: "Mysterious Swordsman", 
    tier: Common, 
    rarity: 4, 
    description: 
        """A mysterious swordsman joins your rank. 
        Your second pawn from the left is replaced with a silver general from Shogi.""",
    onStart: 
        proc (side: Color, b: var ChessBoard) = 
            if side == black: 
                b[1][1].moves &= [diagnalMoves, blackForwardMoves]
                b[1][1].takes &= [diagnalTakes, blackForwardTakes]
                b[1][1].onEndTurn = silverGeneralPromote
            else: 
                b[6][1].moves &= [diagnalMoves,  whiteForwardMoves]
                b[6][1].takes &= [diagnalTakes,  whiteForwardTakes]
                b[6][1].onEndTurn = silverGeneralPromote
)

const mysteriousSwordsmanRight*: Power = Power(
    name: "Mysterious Swordsman", 
    tier: Common, 
    rarity: 4,
    description: 
        """A mysterious swordsman joins your rank. 
        Your second pawn from the right is replaced with a silver general from Shogi.""",
    onStart: 
        proc (side: Color, b: var ChessBoard) = 
            if side == black: 
                b[1][6].moves &= [diagnalMoves, blackForwardMoves]
                b[1][6].takes &= [diagnalTakes, blackForwardTakes]
                b[1][6].onEndTurn = silverGeneralPromote
                b[1][6].item = fairy
            else: 
                b[6][6].moves &= [diagnalMoves,  whiteForwardMoves]
                b[6][6].takes &= [diagnalTakes,  whiteForwardTakes]
                b[6][6].onEndTurn = silverGeneralPromote
                b[6][6].item = fairy
)

const developed*: Power = Power(
    name: "Developed",
    tier: Common,
    description: 
        """Your board arrives a little developed. Your 2 center pawns start one tile forward. 
        They can still move up 2 for their first move.""",
    onStart:
        proc (side: Color, b: var ChessBoard) = 
            if side == black:
                b[2][3] = b[1][3]
                b[2][4] = b[1][4]
                b[1][3] = air
                b[1][4] = air
            else:
                b[5][3] = b[6][3]
                b[5][4] = b[6][4]
                b[6][3] = air
                b[6][4] = air                
)

const cannibalRookTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    result.add(lineTakes(board, p, tileAbove, cannibalismFlag = true))
    result.add(lineTakes(board, p, tileBelow, cannibalismFlag = true))
    result.add(lineTakes(board, p, tileLeft, cannibalismFlag = true))
    result.add(lineTakes(board, p, tileRight, cannibalismFlag = true))

const cannibalBishopTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves =
    result.add(lineTakes(board, p, shooterFactory(1, 1), cannibalismFlag = true))
    result.add(lineTakes(board, p, shooterFactory(-1, 1), cannibalismFlag = true))
    result.add(lineTakes(board, p, shooterFactory(1, -1), cannibalismFlag = true))
    result.add(lineTakes(board, p, shooterFactory(-1, -1), cannibalismFlag = true))

const cannibalKingTakes*: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    for i in -1..1:
        for j in -1..1:
            discard result.addIfTake(board, p, p.tile, shooterFactory(i,j), cannibalismFlag = true)

const stepOnMe*: Power = Power(
    name: "Step on me",
    tier: Common,
    description:
        """Your Queen can take your own pieces. It's literally useless, but if that's your thing...""",
    onStart: 
        proc (side: Color, b: var ChessBoard) = 
            for i in 0..b.len:
                for j in 0.. b[0].len:
                    if b[i][j].item == queen and b[i][j].isColor(side):
                        b[i][j].moves = @[cannibalBishopTakes, cannibalKingTakes, cannibalRookTakes]
)

const illegalFormationRL*: Power = Power(
    name: "Illegal Formation", 
    tier: Common, 
    rarity: 2,
    description: 
        """ILLEGAL FORMATION: YOUR PAWN ABOVE YOUR LEFT ROOK SWAPS PLACES WITH YOUR LEFT ROOK""",
    onStart:
        proc (side: Color, b: var ChessBoard) = 
            let rank = if side == black: 0 else: 6
            let temp = b[rank][0] 
            b[rank][0] = b[rank + 1][0]
            b[rank + 1][0] = temp
)

const illegalFormationRR*: Power = Power(
    name: "Illegal Formation", 
    tier: Common, 
    rarity: 2,
    description: 
        """ILLEGAL FORMATION: YOUR PAWN ABOVE YOUR RIGHT ROOK SWAPS PLACES WITH YOUR RIGHT ROOK""",
    onStart:
        proc (side: Color, b: var ChessBoard) = 
            let rank = if side == black: 0 else: 6
            let temp = b[rank][7] 
            b[rank][7] = b[rank + 1][7]
            b[rank + 1][7] = temp
)

const illegalFormationBL*: Power = Power(
    name: "Illegal Formation", 
    tier: Common, 
    rarity: 2,
    description: 
        """ILLEGAL FORMATION: YOUR PAWN ABOVE YOUR LEFT BISHOP SWAPS PLACES WITH YOUR LEFT BISHOP""",
    onStart:
        proc (side: Color, b: var ChessBoard) = 
            let rank = if side == black: 0 else: 6
            let temp = b[rank][2] 
            b[rank][2] = b[rank + 1][2]
            b[rank + 1][2] = temp
)

const illegalFormationBR*: Power = Power(
    name: "Illegal Formation", 
    tier: Common, 
    rarity: 2,
    description: 
        """ILLEGAL FORMATION: YOUR PAWN ABOVE YOUR RIGHT BISHOP SWAPS PLACES WITH YOUR RIGHT BISHOP""",
    onStart:
        proc (side: Color, b: var ChessBoard) = 
            let rank = if side == black: 0 else: 6
            let temp = b[rank][5] 
            b[rank][5] = b[rank + 1][5]
            b[rank + 1][5] = temp
)

proc putInTheWorkPromotion(taker: Tile, taken: Tile, board: var ChessBoard) =
    onPawnEnd(taker, taken, board)
    let pawn = board[taken.rank][taken.file]
    if pawn.piecesTaken == 3:
        if pawn.color == black and not pawn.promoted:
            board[taken.rank][taken.file] = whiteQueen.pieceCopy(piecesTaken=pawn.piecesTaken, tile=pawn.tile, promoted = true)
        elif pawn.color == white and not pawn.promoted:
            board[taken.rank][taken.file] = blackQueen.pieceCopy(piecesTaken=pawn.piecesTaken, tile=pawn.tile, promoted = true)

#...
#Just don't look at it and it's not that bad
const putInTheWork*: Power = Power(
    name: "Put in the work!", 
    tier: Common,
    description:
        """Get to work son. If any of your pawns takes 3 pieces, it automatically promotes""",
    onStart:
        proc (side: Color, b: var ChessBoard) = 
            for i in 0..b.len:
                for j in 0..b[0].len:
                    if b[i][j].item == pawn and b[i][j].isColor(side):
                        b[i][j].onEndTurn = putInTheWorkPromotion

)

const wanderingRoninLeft*: Power = Power(
    name: "Wandering Ronin", 
    tier: Uncommon, 
    rarity: 4, 
    description: 
        """A wandering Ronin joins your rank. 
        Your third pawn from the left is replaced with a gold general from Shogi.""",
    onStart: 
        proc (side: Color, b: var ChessBoard) =
            let rank = if side == black: 1 else: 6
            b[rank][2].moves &= [diagnalMoves, blackForwardMoves, leftRightMoves]
            b[rank][2].takes &= [diagnalTakes, blackForwardTakes, leftRightTakes]
            b[rank][2].onEndTurn = defaultOnEndTurn #Gold generals do not promote
            b[rank][2].item = fairy
)

const wanderingRoninRight*: Power = Power(
    name: "Wandering Ronin", 
    tier: Uncommon, 
    rarity: 4, 
    description: 
        """A wandering Ronin joins your rank. 
        Your third pawn from the right is replaced with a gold general from Shogi.""",
    onStart: 
        proc (side: Color, b: var ChessBoard) = 
            let rank = if side == black: 1 else: 6
            b[rank][5].moves &= [diagnalMoves, blackForwardMoves, leftRightMoves]
            b[rank][5].takes &= [diagnalTakes, blackForwardTakes, leftRightTakes]
            b[rank][5].onEndTurn = defaultOnEndTurn #Gold generals do not promote
            b[rank][5].item = fairy
)

const warewolves*: Power = Power(
    name: "Warewolves",
    tier: Uncommon,
    description: 
        """Your leftmost and rightmost pawns are secretly warewolves! When they take a piece, they eat it and gain the ability to jump like a knight. They do not promote.""",
    onStart:
        proc (side: Color, b: var ChessBoard) = 
            let update = proc (taker: Tile, taken: Tile, board: var ChessBoard) = 
                if board[taken.rank][taken.file].piecesTaken == 1 and not board[taken.rank][taken.file].promoted:
                    board[taken.rank][taken.file].moves &= knightMoves
                    board[taken.rank][taken.file].takes &= knightTakes

            let rank = if side == black: 1 else: 6
            b[rank][0].onEndTurn = update
            b[rank][0].item = fairy
            b[rank][7].onEndTurn = update
            b[rank][7].item = fairy
                
)

const archBishops*: Power = Power(
    name: "Archbishops",
    tier: Uncommon,
    description:
        """Your bishops ascend to archbishops, gaining the movement of a knight.""",
    onStart:
        proc (side: Color, b: var ChessBoard) = 
            for i in 0..b.len:
                for j in 0..b[0].len:
                    if b[i][j].item == bishop and b[i][j].isColor(side):
                        b[i][j].moves &= knightMoves   
                        b[i][j].takes &= knightTakes        
)