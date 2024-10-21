import power, moves, piece, basePieces, extraMoves

#[prioity rules: 
    higher priority happens later
    5 - New Pieces. Any `Power.onStart` which reassigns the `Piece.moves` or `Piece.takes`
    10 - default. Any `Power.onStart` which can't conflict should be here
    15 - buffs. Any `Power.onStart` which adds elements to `Piece.moves` or `Piece.takes`, but does not reassign it
    20 - premoves. Any `Power.onStart` which moves `Piece`s around the `ChessBoard`
]#

const empress*: Power = Power(
    name: "Empress",
    tier: Uncommon,
    priority: 15,
    description: "Your queen ascends, gaining the movement of a standard knight. ",
    icon: "queen.svg",
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item == queen and b[i][j].isColor(side):
                        b[i][j].takes.add(knightTakes)
                        b[i][j].moves.add(knightMoves)
)

const silverGeneralPromote*: OnAction = proc(taker: Tile, taken: Tile, board: var ChessBoard) = 
    if (taken.rank == 0 or taken.rank == 7) and not board[taken.rank][taken.file].promoted: 
        board[taken.rank][taken.file].moves &= leftRightMoves
        board[taken.rank][taken.file].moves &= leftRightTakes
        board[taken.rank][taken.file].promoted = true
        board[taken.rank][taken.file].filePath = "promotedsilvergeneral.svg"

const mysteriousSwordsmanLeft*: Power = Power(
    name: "Mysterious Swordsman", 
    tier: Common,
    priority: 5, 
    rarity: 4, 
    description: 
        """A mysterious swordsman joins your rank. 
        Your second pawn from the left is replaced with a silver general from Shogi.""",
    icon: "silvergeneral.svg",
    rotatable: true,
    noColor: true,
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            let rank = if side == black: 1 else: 6
            if side == black:
                b[rank][1].moves = @[diagnalMoves, blackForwardMoves]
                b[rank][1].takes = @[diagnalTakes, blackForwardTakes]
            else:
                b[rank][1].moves = @[diagnalMoves, whiteForwardMoves]
                b[rank][1].takes = @[diagnalTakes, whiteForwardTakes]
            b[rank][1].onEndTurn = @[silverGeneralPromote]
            b[rank][1].filePath = "silvergeneral.svg"
            if side != viewSide: b[rank][1].rotate = true
)

const mysteriousSwordsmanRight*: Power = Power(
    name: "Mysterious Swordsman", 
    tier: Common, 
    priority: 5, 
    rarity: 4,
    description: 
        """A mysterious swordsman joins your rank. 
        Your second pawn from the right is replaced with a silver general from Shogi.""",
    icon: "silvergeneral.svg",
    rotatable: true,
    noColor: true,
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            let rank = if side == black: 1 else: 6
            if side == black:
                b[rank][6].moves = @[diagnalMoves, blackForwardMoves]
                b[rank][6].takes = @[diagnalTakes, blackForwardTakes]
            else:
                b[rank][6].moves = @[diagnalMoves, whiteForwardMoves]
                b[rank][6].takes = @[diagnalTakes, whiteForwardTakes]
            b[rank][6].onEndTurn = @[silverGeneralPromote]
            b[rank][6].item = fairy
            b[rank][6].filePath = "silvergeneral.svg"
            if side != viewSide: b[rank][6].rotate = true
)

const developed*: Power = Power(
    name: "Developed",
    tier: Common,
    priority: 20, 
    description: 
        """Your board arrives a little developed. Your 2 center pawns start one tile forward. 
        They can still move up 2 for their first move.""",
    icon: "pawn.svg",
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            if side == black:
                b[1][3].pieceMove(2, 3, b)
                b[1][4].pieceMove(2, 4, b)
            else:
                b[6][3].pieceMove(5, 3, b)
                b[6][4].pieceMove(5, 4, b)         
)

const stepOnMe*: Power = Power(
    name: "Step on me",
    tier: Common,
    priority: 15, 
    description:
        """Your Queen can take your own pieces. It's literally useless, but if that's your thing...""",
    icon: "queen.svg",
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard) = 
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item == queen and b[i][j].isColor(side):
                        b[i][j].moves &= @[cannibalBishopTakes, cannibalKingTakes, cannibalRookTakes]
)

const illegalFormationRL: Power = Power(
    name: "Illegal Formation", 
    tier: Common, 
    rarity: 2,
    priority: 20,
    description: 
        """ILLEGAL FORMATION: YOUR PAWN ABOVE YOUR LEFT ROOK SWAPS PLACES WITH YOUR LEFT ROOK""",
    icon: "rook.svg",
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
    icon: "rook.svg",
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
    icon: "bishop.svg",
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
    icon: "bishop.svg",
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
    priority: 10, 
    description:
        """Get to work son. If any of your pawns take 3 pieces, they automatically promote.""",
    icon: "pawn.svg",
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
    priority: 5, 
    rarity: 4, 
    description: 
        """A wandering Ronin joins your rank. 
        Your third pawn from the left is replaced with a gold general from Shogi.""",
    icon: "goldgeneral.svg",
    rotatable: true,
    noColor: true,
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard) =
            let rank = if side == black: 1 else: 6
            if side == black:
                b[rank][2].moves = @[diagnalMoves, blackForwardMoves, leftRightMoves]
                b[rank][2].takes = @[diagnalTakes, blackForwardTakes, leftRightTakes]
            else:
                b[rank][2].moves = @[diagnalMoves, whiteForwardMoves, leftRightMoves]
                b[rank][2].takes = @[diagnalTakes, whiteForwardTakes, leftRightTakes]                
            b[rank][2].onEndTurn = @[defaultOnEndTurn] #Gold generals do not promote
            b[rank][2].item = fairy
            b[rank][2].filePath = "goldgeneral.svg"
            if side != viewSide: b[rank][2].rotate = true
)

const wanderingRoninRight*: Power = Power(
    name: "Wandering Ronin", 
    tier: Uncommon, 
    priority: 5, 
    rarity: 4, 
    description: 
        """A wandering Ronin joins your rank. 
        Your third pawn from the right is replaced with a gold general from Shogi.""",
    icon: "goldgeneral.svg",
    rotatable: true,
    noColor: true,
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            let rank = if side == black: 1 else: 6
            if side == black:
                b[rank][5].moves = @[diagnalMoves, blackForwardMoves, leftRightMoves]
                b[rank][5].takes = @[diagnalTakes, blackForwardTakes, leftRightTakes]
            else:
                b[rank][5].moves = @[diagnalMoves, whiteForwardMoves, leftRightMoves]
                b[rank][5].takes = @[diagnalTakes, whiteForwardTakes, leftRightTakes]  
            b[rank][5].onEndTurn = @[defaultOnEndTurn] #Gold generals do not promote
            b[rank][5].item = fairy
            b[rank][5].filePath = "goldgeneral.svg"
            if side != viewSide: b[rank][5].rotate = true

)

const werewolfEndTurn: OnAction = proc (taker: Tile, taken: Tile, board: var ChessBoard) = 
    if board[taken.rank][taken.file].piecesTaken == 1 and not board[taken.rank][taken.file].promoted:
        board[taken.rank][taken.file].moves &= knightMoves
        board[taken.rank][taken.file].takes &= knightTakes
        board[taken.rank][taken.file].promoted = true

const warewolves*: Power = Power(
    name: "Werewolves",
    tier: Uncommon,
    priority: 5, 
    description: 
        """Your leftmost and rightmost pawns are secretly werewolves! When they take a piece, they eat it and gain the ability to jump like a knight. They do not promote.""",
    icon: "pawn.svg",
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            let rank = if side == black: 1 else: 6
            b[rank][0].onEndTurn = @[werewolfEndTurn]
            b[rank][0].item = fairy
            b[rank][7].onEndTurn = @[werewolfEndTurn]
            b[rank][7].item = fairy     
)

const archBishops: Power = Power(
    name: "Archbishops",
    tier: Rare,
    priority: 15, 
    description:
        """Your bishops ascend to archbishops, gaining the movement of a knight.""",
    icon: "bishop.svg",
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item == bishop and b[i][j].isColor(side):
                        b[i][j].moves &= knightMoves   
                        b[i][j].takes &= knightTakes        
)

const giraffe*: Power = Power(
    name: "Giraffe",
    tier: Uncommon,
    priority: 5, 
    description:
        """Your knights try riding giraffes. It works surprisingly well. Their leap is improved, moving 3 across instead of 2 across.""",
    icon: "giraffe.svg",
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item == knight and b[i][j].isColor(side):
                        b[i][j].moves = @[giraffeMoves]   
                        b[i][j].takes = @[giraffeTakes]
                        b[i][j].filePath = if side == black: "blackgiraffe.svg" else: "whitegiraffe.svg"
)

const calvary*: Power = Power(
    name: "Calvary",
    tier: Common,
    priority: 15,
    description: 
        """Your knights learn to ride forward. They aren't very good at it, but they're trying their best. 
            They can charge forward 2 tiles, but they cannot jump for this move.""",
    icon: "knight.svg",
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard) = 
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item == knight and b[i][j].isColor(side):
                        if side == black:                            
                            b[i][j].moves &= blackForwardTwiceMoves 
                            b[i][j].takes &= blackForwardTwiceTakes
                        else:
                            b[i][j].moves &= whiteForwardTwiceMoves 
                            b[i][j].takes &= whiteForwardTwiceTakes                            
)

const anime*: Power = Power(
    name: "Anime Battle",
    tier: Rare,
    priority: 5, 
    rarity: 0,
    description:
        """Your board is imbued with the power of anime. You feel a odd sense of regret. Or is it guilt?""",
    icon: "goldgeneral.svg",
    rotatable: true,
    noColor: true,
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

const masochistEmpressPower: Power = Power(
    name: "Masochist Empress",
    tier: UltraRare,
    rarity: 0,
    priority: 15,
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item == queen and b[i][j].isColor(side):
                        b[i][j].takes.add(cannibalKnightTakes)
                        b[i][j].moves.add(knightMoves)
                        
)

const masochistEmpress: Synergy = (
    power: masochistEmpressPower,
    rarity: 0,
    requirements: @[empress.name, stepOnMe.name],
    replacements: @[empress.name, stepOnMe.name],
    index: -1
)

proc sacrificeWhenTaken*(taker: Tile, taken: Tile, board: var ChessBoard): tuple[endTile: Tile, takeSuccess: bool] = 
    if ((taker.file == taken.file) and (taker.rank == taken.rank)):
        for i in 0..<board.len:
            for j in 0..<board[0].len:
                if board[i][j].sameColor(board[taker.rank][taker.file]):
                    piecePromote((file: j, rank: i), board)

    board[taker.rank][taker.file].tile = taken
    board[taken.rank][taken.file] = board[taker.rank][taker.file]
    board[taker.rank][taker.file] = Piece(item: none, tile: taker)
    board[taker.rank][taker.file].piecesTaken += 1
    return ((taken.file, taken.rank), true)


const sacrifice*: Power = Power(
    name: "Sacrificial Maiden",
    tier: UltraRare,
    priority: 15,
    description: """SACRIFICE THY MAIDENS TO THE BLOOD GOD""",
    icon: "queen.svg",
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) =
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item == queen and b[i][j].isColor(side):
                        b[i][j].whenTake = sacrificeWhenTaken
                        b[i][j].takes &= takeSelf
)

proc sacrificeWhenTakenEmpress*(taker: Tile, taken: Tile, board: var ChessBoard): tuple[endTile: Tile, takeSuccess: bool] = 
    if ((taker.file == taken.file) and (taker.rank == taken.rank)):
        for i in 0..<board.len:
            for j in 0..<board[0].len:
                if board[i][j].sameColor(board[taker.rank][taker.file]):
                    piecePromote((file: j, rank: i), board)
                    board[i][j].moves &= knightMoves
                    board[i][j].takes &= knightTakes

    board[taker.rank][taker.file].tile = taken
    board[taken.rank][taken.file] = board[taker.rank][taker.file]
    board[taker.rank][taker.file] = Piece(item: none, tile: taker)
    board[taker.rank][taker.file].piecesTaken += 1
    return ((taken.file, taken.rank), true)


const exodiaPower: Power = Power(
    name: "Exodia",
    tier: UltraRare,
    priority: 15,
    description: "You had your fun, but the game is over. Too bad right?",
    icon: "queen.svg",
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item == queen and b[i][j].isColor(side):
                        b[i][j].whenTake = sacrificeWhenTakenEmpress
                        b[i][j].takes &= takeSelf            
)

const exodia: Synergy = (
    power: exodiaPower,
    rarity: 0,
    requirements: @[empress.name, sacrifice.name],
    replacements: @[empress.name, sacrifice.name],
    index: -1
)

const backStep: Power = Power(
    name: "Backstep",
    tier: Rare,
    priority: 15,
    description: "Your pawns receive some training. They can move one tile back. They cannot take this way.",
    icon: "pawn.svg",
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item == pawn and b[i][j].isColor(side):
                        if b[i][j].color == black:
                            b[i][j].moves &= blackBackwardMove
                        elif b[i][j].color == white:
                            b[i][j].moves &= whiteBackwardMove
)

const headStart: Power = Power(
    name: "Headstart",
    tier: Uncommon,
    priority: 15,
    description: "Your pawns can always move 2 forward. They still take like normal. It's kind of boring, don't you think?",
    icon: "pawn.svg",
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item == pawn and b[i][j].isColor(side):
                        if b[i][j].color == black:
                            b[i][j].moves &= blackForwardTwiceMoves
                        elif b[i][j].color == white:
                            b[i][j].moves &= whiteForwardTwiceMoves
)

const queenTrade*: Power = Power(
    name: "Queen Trade",
    tier: Rare,
    priority: 20,
    description: "The patriarchy continues. Both queens mysteriously die.",
    icon: "queen.svg",
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item == queen:
                        b[i][j] = Piece(item: none, tile: b[i][j].tile)
)

const superPawnPower: Power = Power(
    name: "Super Pawn",
    tier: UltraRare,
    rarity: 0,
    priority: 15,
    description: "You have insane pawns. Please don't sacrifice them.",
    icon: "pawn.svg",
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            headStart.onStart(side, viewSide, b)
            backStep.onStart(side, viewSide, b)
            putInTheWork.onStart(side, viewSide, b)
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item == pawn and b[i][j].isColor(side):
                        if b[i][j].color == black:
                            b[i][j].takes &= blackForwardTwiceTakes
                        elif b[i][j].color == white:
                            b[i][j].takes &= whiteForwardTwiceTakes
)

const superPawn: Synergy = (
    power: superPawnPower,
    rarity: 0,
    requirements: @[backStep.name, headStart.name],
    replacements: @[backStep.name, headStart.name],
    index: -1    
)

const lesbianPride*: Power = Power(
    name: "Lesbian Pride",
    tier: UltraRare,
    priority: 1,
    description: "🧡🤍🩷",
    icon: "lesbianprideflag.svg",
    noColor: true,
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item == king and b[i][j].isColor(side):
                        b[i][j] = whiteQueen.pieceCopy(color = b[i][j].color, item = king, tile = b[i][j].tile, rotate = true) 
                    elif b[i][j].item == bishop and b[i][j].isColor(side):
                        b[i][j] = Piece(item: none, tile: b[i][j].tile)
                        #`Piece.item` is still king so win/loss works
)

const queensWrathPower: Power = Power(
    name: "Queen's Wrath",
    tier: UltraRare,
    rarity: 0,
    priority: 1,
    description: "Why must she die?",
    icon: "queen.svg",
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item != queen and b[i][j].isColor(side):
                        b[i][j] = Piece(item: none, tile: b[i][j].tile)
                    elif b[i][j].item == queen and b[i][j].isColor(side):
                        b[i][j].moves &= @[knightMoves, giraffeMoves]
                        b[i][j].takes &= @[knightTakes, giraffeTakes]
                        b[i][j].item = king
            
)

const queensWrathSuperPower: Power = Power(
    name: "Fallen Queen's Wrath",
    tier: UltraRare,
    rarity: 0,
    priority: 0,
    description: """Why must she die? They will suffer. They will suffer. They will suffer. 
                    They will suffer. They will suffer. They will suffer. They will suffer. 
                    They will suffer. They will suffer. They will suffer. They will suffer.
                    They will suffer. They will suffer. They will suffer. They will suffer.""",
    icon: "queen.svg",
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item != queen and b[i][j].isColor(side):
                        b[i][j] = Piece(item: none, tile: b[i][j].tile)
                    elif b[i][j].item == queen and b[i][j].isColor(side):
                        b[i][j].moves &= @[knightMoves, giraffeMoves]
                        b[i][j].takes &= @[knightTakes, giraffeTakes]
                        b[i][j].item = king
                    elif b[i][j].item == bishop and not b[i][j].isColor(side):
                        b[i][j] = Piece(item: none, tile: b[i][j].tile)
)

const queensWrath: Synergy = (
    power: queensWrathPower,
    rarity: 0,
    requirements: @[lesbianPride.name, queenTrade.name],
    replacements: @[lesbianPride.name, queenTrade.name],
    index: -1    
)

const queensWrath2: Synergy = (
    power: queensWrathPower,
    rarity: 0,
    requirements: @[lesbianPride.name, sacrifice.name],
    replacements: @[lesbianPride.name, sacrifice.name],
    index: -1    
)

const queensWrathSuper: Synergy = (
    power: queensWrathSuperPower,
    rarity: 0,
    requirements: @[lesbianPride.name, queenTrade.name, sacrifice.name],
    replacements: @[lesbianPride.name, queenTrade.name, sacrifice.name],
    index: -1
)

const knightChargePower*: Power = Power(
    name: "Knight's Charge",
    tier: Rare,
    rarity: 4,
    priority: 20,
    description: "CHARGE! Your knights start 3 tiles ahead.",
    icon: "knight.svg",
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) =   
            let offset = if side == white: -3 else: 3
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item == knight and b[i][j].isColor(side) and b[i][j].timesMoved == 0:
                        b[i][j].timesMoved += 1
                        b[i][j].pieceMove(i + offset, j, b)
)

const calvaryCharge: Synergy = (
    power: knightChargePower,
    rarity: 16,
    requirements: @[calvary.name],
    replacements: @[],
    index: -1    
)

const battleFormationPower: Power = Power(
    name: "Battle Formation!",
    tier: UltraRare,
    rarity: 0,
    priority: 20,
    description: "Real Estate is going crazy with how developed the board is.",
    icon: "knight.svg",
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            knightChargePower.onStart(side, viewSide, b)
            if side == black:
                b[1][3].pieceMove(3, 3, b)
                b[1][4].pieceMove(3, 4, b)
            else:
                b[6][3].pieceMove(4, 3, b)
                b[6][4].pieceMove(4, 4, b)      
)

const battleFormation: Synergy = (
    power: battleFormationPower,
    rarity: 0,
    requirements: @[knightChargePower.name, developed.name],
    replacements: @[knightChargePower.name, developed.name],
    index: -1
)

const differentGamePower: Power = Power(
    name: "Criminal Formation",
    tier: Common,
    rarity: 0,
    priority: 20,
    description: "I guess the rules didn't get to you. Your pawns above both knights and both rooks swap places with those pieces.",
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) =
            illegalFormationBL.onStart(side, viewSide, b)
            illegalFormationBR.onStart(side, viewSide, b)
            illegalFormationRL.onStart(side, viewSide, b)
            illegalFormationRR.onStart(side, viewSide, b)
)

const differentGame: Synergy = (
    power: differentGamePower,
    rarity: 12,
    requirements: @[illegalFormationBR.name],
    replacements: @[illegalFormationBR.name],
    index: -1
)

const lineBackersPower: Power = Power(
    name: "Linebackers",
    tier: Rare,
    rarity: 0,
    priority: 15,
    description: "Your pawns learn to fight like men. They can two spaces ahead too.",
    icon: "pawn.svg",
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item == pawn and b[i][j].isColor(side):
                        if b[i][j].color == black:
                            b[i][j].takes &= blackForwardTwiceTakes
                        elif b[i][j].color == white:
                            b[i][j].takes &= whiteForwardTwiceTakes

)

const linebackers: Synergy = (
    power: lineBackersPower,
    rarity: 0,
    requirements: @[putInTheWork.name, headStart.name],
    replacements: @[],
    index: -1
)

const nightRider: Power = Power(
    name: "Nightrider",
    tier: UltraRare,
    priority: 5,
    description: "Nightrider.",
    icon: "nightrider.svg",
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item == knight and b[i][j].isColor(side):
                        b[i][j].moves &= nightriderMoves
                        b[i][j].takes &= nightriderTakes
)

const desegregation: Power = Power(
    name: "Desgregation and Integration",
    tier: Uncommon,
    priority: 15,
    description: "Your bishops learn to accept their differences. They can move left and right.",
    icon: "bishop.svg",
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            for i in 0 ..< b.len:
                for j in 0 ..< b[0].len:
                    if b[i][j].item == bishop and b[i][j].isColor(side):
                        b[i][j].moves &= leftRightMoves
                        b[i][j].takes &= leftRightTakes
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
registerPower(giraffe)
registerPower(sacrifice)
registerPower(calvary)
registerPower(backstep)
registerPower(headStart)
registerPower(queenTrade)
registerPower(lesbianPride)
registerPower(knightChargePower)
registerPower(nightRider)
registerPower(desegregation)

registerSynergy(samuraiSynergy)
registerSynergy(calvaryCharge)
registerSynergy(differentGame)
registerSynergy(linebackers)
registerSynergy(masochistEmpress, true, true)
registerSynergy(exodia, true)
registerSynergy(superPawn, true)
registerSynergy(queensWrath, true)
registerSynergy(queensWrath2, true)
registerSynergy(battleFormation, true)
registerSynergy(queensWrathSuper, true)
