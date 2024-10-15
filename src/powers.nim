import power, moves, piece, board, basePieces

const empress: Power = Power(
    name: "Empress",
    tier: Uncommon,
    description: "Your queen ascends, gaining the movement of a standard knight. ",
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard) =
            let rank = if side == black: 0 else: 7
            b[rank][3].moves.add(knightMoves)
            b[rank][3].takes.add(knightTakes)
)

const diagnalMoves: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfFree(board, p.tile, shooterFactory(1,1))
    discard result.addIfFree(board, p.tile, shooterFactory(-1,1))
    discard result.addIfFree(board, p.tile, shooterFactory(1,-1))
    discard result.addIfFree(board, p.tile, shooterFactory(-1,-1))

const diagnalTakes: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, shooterFactory(1,1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1,1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(1,-1))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1,-1))

const leftRightMoves: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfFree(board, p.tile, tileLeft)
    discard result.addIfFree(board, p.tile, tileRight)

const leftRightTakes: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, tileLeft)
    discard result.addIfTake(board, p, p.tile, tileRight)

const whiteForwardMoves: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfFree(board, p.tile, tileAbove)

const blackForwardMoves: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfFree(board, p.tile, tileBelow)

const whiteForwardTakes: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, tileAbove)

const blackForwardTakes: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, tileBelow)

const silverGeneralPromote: OnAction = proc(taker: Tile, taken: Tile, board: var ChessBoard) = 
    if (taken.rank == 0 or taken.rank == 7) and not board[taken.rank][taken.file].promoted: 
        board[taken.rank][taken.file].moves &= leftRightMoves
        board[taken.rank][taken.file].moves &= leftRightTakes
        board[taken.rank][taken.file].promoted = true
        board[taken.rank][taken.file].filePath = "promotedsilvergeneral.svg"

const mysteriousSwordsmanLeft*: Power = Power(
    name: "Mysterious Swordsman", 
    tier: Common, 
    rarity: 4, 
    description: 
        """A mysterious swordsman joins your rank. 
        Your second pawn from the left is replaced with a silver general from Shogi.""",
    icon: "silvergeneral.svg",
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            let rank = if side == black: 1 else: 6
            b[rank][1].moves = @[diagnalMoves, blackForwardMoves]
            b[rank][1].takes = @[diagnalTakes, blackForwardTakes]
            b[rank][1].onEndTurn = @[silverGeneralPromote]
            b[rank][1].filePath = "silvergeneral.svg"
            if side != viewSide: b[rank][1].rotate = true
)

const mysteriousSwordsmanRight*: Power = Power(
    name: "Mysterious Swordsman", 
    tier: Common, 
    rarity: 4,
    description: 
        """A mysterious swordsman joins your rank. 
        Your second pawn from the right is replaced with a silver general from Shogi.""",
    icon: "silvergeneral.svg",
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            let rank = if side == black: 1 else: 6
            b[rank][6].moves = @[diagnalMoves, blackForwardMoves]
            b[rank][6].takes = @[diagnalTakes, blackForwardTakes]
            b[rank][6].onEndTurn = @[silverGeneralPromote]
            b[rank][6].item = fairy
            b[rank][6].filePath = "silvergeneral.svg"
            if side != viewSide: b[rank][6].rotate = true
)

const developed*: Power = Power(
    name: "Developed",
    tier: Common,
    description: 
        """Your board arrives a little developed. Your 2 center pawns start one tile forward. 
        They can still move up 2 for their first move.""",
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            if side == black:
                b[1][3].pieceMove(2, 3, b)
                b[1][4].pieceMove(2, 4, b)
            else:
                b[6][3].pieceMove(5, 3, b)
                b[6][4].pieceMove(5, 4, b)         
)

const cannibalRookTakes: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    result.add(lineTakes(board, p, tileAbove, cannibalismFlag = true))
    result.add(lineTakes(board, p, tileBelow, cannibalismFlag = true))
    result.add(lineTakes(board, p, tileLeft, cannibalismFlag = true))
    result.add(lineTakes(board, p, tileRight, cannibalismFlag = true))

const cannibalBishopTakes: MoveProc = func (board: ChessBoard, p: Piece): Moves =
    result.add(lineTakes(board, p, shooterFactory(1, 1), cannibalismFlag = true))
    result.add(lineTakes(board, p, shooterFactory(-1, 1), cannibalismFlag = true))
    result.add(lineTakes(board, p, shooterFactory(1, -1), cannibalismFlag = true))
    result.add(lineTakes(board, p, shooterFactory(-1, -1), cannibalismFlag = true))

const cannibalKingTakes: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    for i in -1..1:
        for j in -1..1:
            discard result.addIfTake(board, p, p.tile, shooterFactory(i,j), cannibalismFlag = true)

const stepOnMe: Power = Power(
    name: "Step on me",
    tier: Common,
    description:
        """Your Queen can take your own pieces. It's literally useless, but if that's your thing...""",
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard) = 
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item == queen and b[i][j].isColor(side):
                        b[i][j].moves = @[cannibalBishopTakes, cannibalKingTakes, cannibalRookTakes]
)

const illegalFormationRL: Power = Power(
    name: "Illegal Formation", 
    tier: Common, 
    rarity: 2,
    priority: 20,
    description: 
        """ILLEGAL FORMATION: YOUR PAWN ABOVE YOUR LEFT ROOK SWAPS PLACES WITH YOUR LEFT ROOK""",
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            let rank = if side == black: 0 else: 6
            pieceSwap(b[rank][0], b[rank + 1][0], b)
)

const illegalFormationRR: Power = Power(
    name: "Illegal Formation", 
    tier: Common, 
    rarity: 2,
    priority: 20,
    description: 
        """ILLEGAL FORMATION: YOUR PAWN ABOVE YOUR RIGHT ROOK SWAPS PLACES WITH YOUR RIGHT ROOK""",
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            let rank = if side == black: 0 else: 6
            pieceSwap(b[rank][7], b[rank + 1][7], b)
)

const illegalFormationBL*: Power = Power(
    name: "Illegal Formation", 
    tier: Common, 
    rarity: 2,
    priority: 20,
    description: 
        """ILLEGAL FORMATION: YOUR PAWN ABOVE YOUR LEFT BISHOP SWAPS PLACES WITH YOUR LEFT BISHOP""",
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            let rank = if side == black: 0 else: 6
            pieceSwap(b[rank][2], b[rank + 1][2], b)
)

const illegalFormationBR: Power = Power(
    name: "Illegal Formation", 
    tier: Common, 
    rarity: 2,
    priority: 20,
    description: 
        """ILLEGAL FORMATION: YOUR PAWN ABOVE YOUR RIGHT BISHOP SWAPS PLACES WITH YOUR RIGHT BISHOP""",
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            let rank = if side == black: 0 else: 6
            pieceSwap(b[rank][5], b[rank + 1][5], b)
)

proc putInTheWorkPromotion(taker: Tile, taken: Tile, board: var ChessBoard) =
    onPawnEnd(taker, taken, board)
    let pawn = board[taken.rank][taken.file]
    if pawn.piecesTaken == 3:
        for f in pawn.onPromote:
            f(taker, taken, board)

#...
#Just don't look at it and it's not that bad
const putInTheWork*: Power = Power(
    name: "Put in the work!", 
    tier: Common,
    description:
        """Get to work son. If any of your pawns takes 3 pieces, it automatically promotes""",
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item == pawn and b[i][j].isColor(side):
                        b[i][j].onEndTurn &= putInTheWorkPromotion

)

const wanderingRoninLeft*: Power = Power(
    name: "Wandering Ronin", 
    tier: Uncommon, 
    rarity: 4, 
    description: 
        """A wandering Ronin joins your rank. 
        Your third pawn from the left is replaced with a gold general from Shogi.""",
    icon: "goldgeneral.svg",
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard) =
            let rank = if side == black: 1 else: 6
            b[rank][2].moves = @[diagnalMoves, blackForwardMoves, leftRightMoves]
            b[rank][2].takes = @[diagnalTakes, blackForwardTakes, leftRightTakes]
            b[rank][2].onEndTurn = @[defaultOnEndTurn] #Gold generals do not promote
            b[rank][2].item = fairy
            b[rank][2].filePath = "goldgeneral.svg"
            if side != viewSide: b[rank][2].rotate = true
)

const wanderingRoninRight*: Power = Power(
    name: "Wandering Ronin", 
    tier: Uncommon, 
    rarity: 4, 
    description: 
        """A wandering Ronin joins your rank. 
        Your third pawn from the right is replaced with a gold general from Shogi.""",
    icon: "goldgeneral.svg",
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            let rank = if side == black: 1 else: 6
            b[rank][5].moves = @[diagnalMoves, blackForwardMoves, leftRightMoves]
            b[rank][5].takes = @[diagnalTakes, blackForwardTakes, leftRightTakes]
            b[rank][5].onEndTurn = @[defaultOnEndTurn] #Gold generals do not promote
            b[rank][5].item = fairy
            b[rank][5].filePath = "goldgeneral.svg"
            if side != viewSide: b[rank][5].rotate = true

)

const warewolves*: Power = Power(
    name: "Warewolves",
    tier: Uncommon,
    description: 
        """Your leftmost and rightmost pawns are secretly warewolves! When they take a piece, they eat it and gain the ability to jump like a knight. They do not promote.""",
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            let update: OnAction = proc (taker: Tile, taken: Tile, board: var ChessBoard) = 
                if board[taken.rank][taken.file].piecesTaken == 1 and not board[taken.rank][taken.file].promoted:
                    board[taken.rank][taken.file].moves &= knightMoves
                    board[taken.rank][taken.file].takes &= knightTakes
                    board[taken.rank][taken.file].promoted = true

            let rank = if side == black: 1 else: 6
            b[rank][0].onEndTurn = @[update]
            b[rank][0].item = fairy
            b[rank][7].onEndTurn = @[update]
            b[rank][7].item = fairy
                
)

const archBishops: Power = Power(
    name: "Archbishops",
    tier: Uncommon,
    description:
        """Your bishops ascend to archbishops, gaining the movement of a knight.""",
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item == bishop and b[i][j].isColor(side):
                        b[i][j].moves &= knightMoves   
                        b[i][j].takes &= knightTakes        
)

const anime*: Power = Power(
    name: "Anime Battle",
    tier: Rare,
    rarity: 4,
    description:
        """Your board is imbued with the power of anime. You feel a odd sense of regret. Or is it guilt?""",
    onStart:
        proc (side: Color, viewerSide: Color, b: var ChessBoard) = 
            mysteriousSwordsmanLeft.onStart(side, viewerSide, b)
            mysteriousSwordsmanRight.onStart(side, viewerSide, b)
            wanderingRoninLeft.onStart(side, viewerSide, b)
            wanderingRoninRight.onStart(side, viewerSide, b)
)

const samuraiSynergy: Synergy = (
    power: anime,
    rarity: 32,
    requirements: @[mysteriousSwordsmanLeft.name, wanderingRoninLeft.name],
    replacements: @[mysteriousSwordsmanLeft.name, wanderingRoninLeft.name, mysteriousSwordsmanRight.name, wanderingRoninRight.name, anime.name],
    index: -1
)

const giraffeTakes: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfTake(board, p, p.tile, shooterFactory(1,4))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1,4))
    discard result.addIfTake(board, p, p.tile, shooterFactory(1,-4))
    discard result.addIfTake(board, p, p.tile, shooterFactory(-1,-4))

const giraffeMoves: MoveProc = func (board: ChessBoard, p: Piece): Moves = 
    discard result.addIfFree(board, p.tile, shooterFactory(1,4))
    discard result.addIfFree(board, p.tile, shooterFactory(-1,4))
    discard result.addIfFree(board, p.tile, shooterFactory(1,-4))
    discard result.addIfFree(board, p.tile, shooterFactory(-1,-4))

const giraffe: Power = Power(
    name: "Giraffe",
    tier: Rare,
    description:
        """Your knights try riding giraffes. It works surprisingly well. Their leap is improved, moving 4 across instead of 2 across.""",
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item == bishop and b[i][j].isColor(side):
                        b[i][j].moves &= knightMoves   
                        b[i][j].takes &= knightTakes        
)

registerPower(empress)
registerPower(mysteriousSwordsmanLeft)
registerPower(mysteriousSwordsmanRight)
registerPower(developed)
registerPower(stepOnMe)
registerPower(illegalFormationBL)
registerPower(illegalFormationBR)
registerPower(illegalFormationRL)
registerPower(illegalFormationRR)
registerPower(putInTheWork)
registerPower(wanderingRoninLeft)
registerPower(wanderingRoninRight)
registerPower(archBishops)
registerPower(warewolves)
registerPower(anime)

registerSynergy(samuraiSynergy)