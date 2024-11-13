import power, moves, piece, basePieces, extraMoves

#[TODO
create synergy constructor which automatically sets index to -1
or maybe just make it an object, since I don't think performance has ever mattered for this
or remove `Synergy.index`, since I'm honestly not sure what it does

Create secret secret synergy for bombard + reinforcements
]#

#[prioity rules: 
    higher priority happens later
    5 - New Pieces. Any `Power.onStart` which reassigns the `Piece.moves` or `Piece.takes`
    10 - default. Any `Power.onStart` which can't conflict should be here
    15 - buffs. Any `Power.onStart` which adds elements to `Piece.moves` or `Piece.takes`, but does not reassign it
    20 - premoves. Any `Power.onStart` which moves `Piece`s around the `ChessBoard`
]#

#[Synergies:   
    
    There are three types of synergies, decided by flags in `addSynergy`
    TLDR: Normal Synergies must be drafted seperately
          Secret Synergies are automatically added when the game starts
          Secret Secret Synergies are like Secret Synergies, but they are completely hidden to the user
            These are meant to be used as bandages for when powers conflict

    Normal Synergies - 
        if the drafter has all of its `Synergy.requirements`, then `Synergy.Power` become available.
            with a rarity of `Synergy.rarity`. If picked, the users powers in `Synergy.requirements` are removed. 
        The drafter than has to find and draft it.
        The description of `Synergy.power` is automatically updated to say "Synergy (list of synergies)"
    Secret Synergies - 
        if the drafter has all of its `Synergy.requirements`, then when the game starts, `Synergy.requirements` is 
            automatically replaced with `Synergy.power`
        The description of `Synergy.power` is automatically updated to say "Secret Synergy (list of synergies)"
    Secret Secret Synergies - 
        if the drafter has all of its `Synergy.requirements`, then when the game starts, `Synergy.requirements` is 
            automatically replaced with `Synergy.power`
        The drafter has no choice, these are automatically added

    Synergies take the `Power.priority` of `Synergy.power`
    Always set index to -1
]#

#default paths for the main pieces
const kingIcon: string = "king.svg"
const queenIcon: string = "queen.svg"
const rookIcon: string = "rook.svg"
const bishopIcon: string = "bishop.svg"
const knightIcon: string = "knight.svg"
const pawnIcon: string = "pawn.svg"

const empress*: Power = Power(
    name: "Empress",
    tier: Uncommon,
    priority: 15,
    description: "Your queen ascends, gaining the movement of a standard knight. ",
    icon: queenIcon,
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == queen and b[i][j].isColor(side):
                    b[i][j].takes.add(knightTakes)
                    b[i][j].moves.add(knightMoves)
)

const silverGeneralPromote*: OnPiece = proc(piece: var Piece, board: var ChessBoard) = 
    piece.moves &= leftRightMoves
    piece.takes &= leftRightTakes
    piece.promoted = true
    piece.filePath = "promotedsilvergeneral.svg"

const silverGeneralPromoteConditions*: OnPiece = proc(piece: var Piece, board: var ChessBoard) = 
    if (piece.tile.rank == 0 or piece.tile.rank == 7) and not piece.promoted:  
        piece.promote(board)

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
            b[rank][1].onEndTurn = @[silverGeneralPromoteConditions]
            b[rank][1].onPromote = @[silverGeneralPromote]
            b[rank][1].item = fairy
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
            b[rank][6].onEndTurn = @[silverGeneralPromoteConditions]
            b[rank][6].onPromote = @[silverGeneralPromote]
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
    icon: pawnIcon,
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
    icon: queenIcon,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == queen and b[i][j].isColor(side):
                    b[i][j].takes &= @[cannibalBishopTakes, cannibalKingTakes, cannibalRookTakes]
)

const illegalFormationRL: Power = Power(
    name: "Illegal Formation", 
    tier: Common, 
    rarity: 2,
    priority: 20,
    description: 
        """ILLEGAL FORMATION: YOUR PAWN ABOVE YOUR LEFT ROOK SWAPS PLACES WITH YOUR LEFT ROOK""",
    icon: rookIcon,
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
    icon: rookIcon,
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
    icon: bishopIcon,
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
    icon: bishopIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            let rank = if side == black: 0 else: 6
            pieceSwap(b[rank][5], b[rank + 1][5], b)
)

const putInTheWorkCondition: OnPiece = proc(piece: var Piece, board: var ChessBoard) =
    if piece.piecesTaken == 3:
        piece.promote(board)

#...
#Just don't look at it and it's not that bad
const putInTheWork*: Power = Power(
    name: "Put in the work!", 
    tier: Common,
    priority: 10, 
    description:
        """Get to work son. If any of your pawns take 3 pieces, they automatically promote.""",
    icon: pawnIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == pawn and b[i][j].isColor(side):
                    b[i][j].onEndTurn &= putInTheWorkCondition

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

const werewolfPromoteConditions: OnPiece = proc(piece: var Piece, board: var ChessBoard) =
    if piece.piecesTaken == 1 and not piece.promoted:
        piece.promote(board)

const werewolfPromote: OnPiece = proc(piece: var Piece, board: var ChessBoard) =
    piece.moves &= @[knightMoves, giraffeMoves]
    piece.takes &= @[knightTakes, giraffeTakes]
    piece.promoted = true

const warewolves*: Power = Power(
    name: "Werewolves",
    tier: Uncommon,
    priority: 5, 
    description: 
        """Your leftmost and rightmost pawns are secretly werewolves! When they take a piece, they eat it and gain the ability to jump like a knight and giraffe. They do not promote.""",
    icon: pawnIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            let rank = if side == black: 1 else: 6
            b[rank][0].onEndTurn = @[werewolfPromoteConditions]
            b[rank][0].onPromote = @[werewolfPromote]

            b[rank][7].onEndTurn = @[werewolfPromoteConditions]
            b[rank][0].onPromote = @[werewolfPromote]
)

const archBishops: Power = Power(
    name: "Archbishops",
    tier: Rare,
    priority: 15, 
    description:
        """Your bishops ascend to archbishops, gaining the movement of a knight.""",
    icon: bishopIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            for i, j in b.rankAndFile:
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
            for i, j in b.rankAndFile:
                if b[i][j].item == knight and b[i][j].isColor(side):
                    b[i][j].moves = @[giraffeMoves]   
                    b[i][j].takes = @[giraffeTakes]
                    b[i][j].filePath = if side == black: "blackgiraffe.svg" else: "whitegiraffe.svg"
)

const calvary*: Power = Power(
    name: "Calvary",
    tier: Uncommon,
    priority: 15,
    description: 
        """Your knights learn to ride forward. They aren't very good at it, but they're trying their best. 
            They can charge forward up to 2 tiles, but only to take a piece. They cannot jump for this move.""",
    icon: knightIcon,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == knight and b[i][j].isColor(side):
                    if side == black:                            
                        b[i][j].takes &= blackForwardTwiceTakes
                    else:
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
            for i, j in b.rankAndFile:
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

const sacrificeWhenTaken*: WhenTaken = proc (taken: var Piece, taker: var Piece, board: var ChessBoard): tuple[endTile: Tile, takeSuccess: bool] =
    if (taken.tile == taker.tile):
        for i, j in board.rankAndFile:
            if board[i][j].sameColor(taken) and not board[i][j].promoted:
                board[i][j].promote(board)
        return (taken.tile, true)
    else:
        return defaultWhenTaken(taken, taker, board)


const sacrifice*: Power = Power(
    name: "Sacrificial Maiden",
    tier: UltraRare,
    priority: 15,
    description: """SACRIFICE THY MAIDENS TO THE BLOOD GOD""",
    icon: queenIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) =
            for i, j in b.rankAndFile:
                if b[i][j].item == queen and b[i][j].isColor(side):
                    b[i][j].whenTaken = sacrificeWhenTaken
                    b[i][j].takes &= takeSelf
)

const sacrificeWhenTakenEmpress*: WhenTaken = proc (taken: var Piece, taker: var Piece, board: var ChessBoard): tuple[endTile: Tile, takeSuccess: bool] =
    if (taken.tile == taker.tile):
        for i, j in board.rankAndFile:
            if board[i][j].sameColor(taken):
                board[i][j].promote(board)
                board[i][j].moves &= knightMoves
                board[i][j].takes &= knightTakes

        return (taken.tile, true)
    else:
        return defaultWhenTaken(taken, taker, board)


const exodiaPower: Power = Power(
    name: "Exodia",
    tier: UltraRare,
    priority: 15,
    description: "You had your fun, but the game is over. Too bad right?",
    icon: queenIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == queen and b[i][j].isColor(side):
                    b[i][j].whenTaken = sacrificeWhenTakenEmpress
                    b[i][j].takes &= takeSelf            
)

const exodia: Synergy = (
    power: exodiaPower,
    rarity: 0,
    requirements: @[empress.name, sacrifice.name],
    replacements: @[empress.name, sacrifice.name],
    index: -1
)

const backStep*: Power = Power(
    name: "Backstep",
    tier: Rare,
    priority: 15,
    description: "Your pawns receive some training. They can move one tile back. They cannot take this way.",
    icon: pawnIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == pawn and b[i][j].isColor(side):
                    if b[i][j].color == black:
                        b[i][j].moves &= blackBackwardMove
                    elif b[i][j].color == white:
                        b[i][j].moves &= whiteBackwardMove
)

const headStart*: Power = Power(
    name: "Headstart",
    tier: Uncommon,
    priority: 15,
    description: "Your pawns can always move 2 forward. They still take like normal. It's kind of boring, don't you think?",
    icon: pawnIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            for i, j in b.rankAndFile:
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
    icon: queenIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == queen:
                    b[i][j] = Piece(item: none, tile: b[i][j].tile)
)

const superPawnPower: Power = Power(
    name: "Super Pawn",
    tier: UltraRare,
    rarity: 0,
    priority: 15,
    description: "You have insane pawns. Please don't sacrifice them.",
    icon: pawnIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            headStart.onStart(side, viewSide, b)
            backStep.onStart(side, viewSide, b)
            putInTheWork.onStart(side, viewSide, b)
            for i, j in b.rankAndFile:
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
            for i, j in b.rankAndFile:
                if b[i][j].item == king and b[i][j].isColor(side):
                    b[i][j] = whiteQueen.pieceCopy(color = b[i][j].color, item = king, tile = b[i][j].tile, rotate = true, filePath = $side & queenIcon) 
                    #`Piece.item` is still king so win/loss works. `Piece.rotate` = true should hopefully suggest this
                elif b[i][j].item == bishop and b[i][j].isColor(side):
                    b[i][j] = Piece(item: none, tile: b[i][j].tile)
)

const queensWrathPower: Power = Power(
    name: "Queen's Wrath",
    tier: UltraRare,
    rarity: 0,
    priority: 1,
    description: "Why must she die?",
    icon: queenIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            sacrifice.onStart(side, viewSide, b)
            for i, j in b.rankAndFile:
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
    icon: queenIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            for i, j in b.rankAndFile:
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
    icon: knightIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) =   
            let offset = if side == white: -3 else: 3
            for i, j in b.rankAndFile:
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
    icon: knightIcon,
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
    description: "Your pawns learn to fight like men. They can take one spaces ahead too.",
    icon: pawnIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == pawn and b[i][j].isColor(side):
                    if b[i][j].color == black:
                        b[i][j].takes &= blackForwardTakes
                    elif b[i][j].color == white:
                        b[i][j].takes &= whiteForwardTakes

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
    priority: 3,
    description: "Nightrider.",
    icon: "nightrider.svg",
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == knight and b[i][j].isColor(side):
                    b[i][j].moves &= nightriderMoves
                    b[i][j].takes &= nightriderTakes
                    b[i][j].item = fairy
                    b[i][j].filePath = $side & "nightrider.svg"
)

const desegregation: Power = Power(
    name: "Desegregation and Integration",
    tier: Uncommon,
    priority: 15,
    description: "Your bishops learn to accept their differences. They can move left and right.",
    icon: bishopIcon,
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == bishop and b[i][j].isColor(side):
                    b[i][j].moves &= leftRightMoves
                    b[i][j].takes &= leftRightTakes
)

const holyBishopPower*: Power = Power(
    name: "Holy Bishops",
    tier: Rare,
    priority: 15,
    description: "God has blessed your bishops. ",
    icon: "cross.svg",
    noColor: true,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == bishop and b[i][j].isColor(side):
                    b[i][j].moves &= @[knightMoves, blackForwardTwiceJumpMove, whiteForwardTwiceJumpMove]  
                    b[i][j].takes &= @[knightTakes, blackForwardTwiceJumpTake, whiteForwardTwiceJumpTake]    

)

const holyBishop: Synergy = (
    power: holyBishopPower,
    rarity: 8,
    requirements: @[archBishops.name, holy.name],
    replacements: @[archBishops.name],
    index: -1
)

const concubineWhenTake = proc (taken: var Piece, taker: var Piece, board: var ChessBoard): tuple[endTile: Tile, takeSuccess: bool] =
    if taker.item == king and 
        taken.item == rook and
        taker.timesMoved == 0 and
        taken.timesMoved == 0: 
            echo "before"
            taken.promote(board)
            echo "after"
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

const concubine*: Power = Power(
    name: "Concubine",
    tier: Rare,
    priority: 15,
    description: "Your rook becomes a queen when it castles.... You're sick.",
    icon: rookIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            var dna: Piece = if side == white: whiteQueen.pieceCopy() else: blackQueen.pieceCopy()

            for i, j in b.rankAndFile:
                if b[i][j].item == queen and b[i][j].isColor(side):
                    dna = b[i][j]
                    break

            let concubinePromote: OnPiece =  proc (piece: var Piece, board: var ChessBoard) =
                piece = dna.pieceCopy(piecesTaken = piece.piecesTaken, tile = piece.tile, promoted = true)

            for i, j in b.rankAndFile:
                if b[i][j].item == rook and b[i][j].isColor(side):
                    b[i][j].onPromote &= concubinePromote 
                    b[i][j].whenTaken = concubineWhenTake
)

const reinforcements*: Power = Power(
    name: "Reinforcements",
    tier: Uncommon,
    priority: 25,
    description: "Do you really need more than 8 pawns? Your rooks spawn a pawn for every 2 pieces they takes.",
    icon: rookIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            var dna: Piece = if side == white: whitePawn.pieceCopy() else: blackPawn.pieceCopy()

            for i, j in b.rankAndFile:
                if b[i][j].item == pawn and b[i][j].isColor(side):
                    dna = b[i][j]
                    break

            let reinforcementsOntake: OnAction = proc(piece: var Piece, to: Tile, board: var ChessBoard) =
                assert piece.getTakesOn(board).contains(to)
                let takeResults = to.takenBy(piece, board)
                let originalRookTile = piece.tile
                board[takeResults.endTile.rank][takeResults.endTile.file].timesMoved += 1

                if takeResults.takeSuccess:
                    board[takeResults.endTile.rank][takeResults.endTile.file].piecesTaken += 1
                    if board[takeResults.endTile.rank][takeResults.endTile.file].piecesTaken mod 2 == 0:
                        board[originalRookTile.rank][originalRookTile.file] = dna.pieceCopy(tile = originalRookTile)

            for i, j in b.rankAndFile:
                if b[i][j].item == rook and b[i][j].isColor(side):
                    b[i][j].onTake = reinforcementsOntake

)

const shotgunKingOnTake*: OnAction = proc (piece: var Piece, to: Tile, board: var ChessBoard) = 
    assert piece.getTakesOn(board).contains(to)
    let originalKingTile = piece.tile
    let takeResult = to.takenBy(piece, board)
    piece.timesMoved += 1
    if takeResult.takeSuccess:
        piece.piecesTaken += 1

        if (originalKingTile.rank + 2 == takeResult.endTile.rank):
            takeResult.endTile.pieceMove(originalKingTile, board)
        elif (originalKingTile.rank - 2 == takeResult.endTile.rank):
            takeResult.endTile.pieceMove(originalKingTile, board)

const shotgunKing*: Power = Power(
    name: "Shotgun King",
    tier: Common,
    priority: 5,
    description: """Your king knows its 2nd ammendment rights. It can take pieces two ahead or two behind. 
                    If it does this take, it does not move from its initial tile.""",
    icon: kingIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == king and b[i][j].isColor(side):
                    b[i][j].onTake = shotgunKingOnTake
                    b[i][j].takes &= @[blackForwardTwiceJumpTake, whiteForwardTwiceJumpTake]
)

const bountyHunterOnEndTurn*: OnPiece = proc (piece: var Piece, board: var ChessBoard) = 
        if piece.piecesTaken == 3:
            for i, j in board.rankAndFile:
                #searches for enemy king and deletes is
                if board[i][j].item == king and not board[i][j].sameColor(piece):
                    board[i][j] = Piece(item: none, tile: board[i][j].tile)  

const bountyHunterPower*: Power = Power(
    name: "Bounty Hunter",
    tier: Common,
    rarity: 0,
    priority: 15,
    description: "It's hard to make a living these days. If your king takes 3 pieces, you automatically win.",
    icon: kingIcon,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == king and b[i][j].isColor(side):
                    b[i][j].onEndTurn &= bountyHunterOnEndTurn
)

const bountyHunter: Synergy = (
    power: bountyHunterPower,
    rarity: 16,
    requirements: @[shotgunKing.name],
    replacements: @[],
    index: -1
)

const coward: Power = Power(
    name: "Coward",
    tier: Common,
    priority: 25,
    description: "You coward. Your king swaps pieces with the king's side knight.",
    icon: kingIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == king and b[i][j].isColor(side):
                    if b[i][j].timesMoved == 0:
                        inc b[i][j].timesMoved
                        pieceSwap(b[i][j], b[i][j + 2], b)      
)

const bombardOnTake*: OnAction = proc (piece: var Piece, to: Tile, board: var ChessBoard) = 
    assert piece.getTakesOn(board).contains(to)
    let originalTile = piece.tile
    let takeResult = to.takenBy(piece, board)
    piece.timesMoved += 1
    if takeResult.takeSuccess:
        piece.piecesTaken += 1

        if ((originalTile.rank - takeResult.endTile.rank != 0) and (originalTile.file - takeResult.endTile.file) != 0):
            takeResult.endTile.pieceMove(originalTile, board)

const bombard: Power = Power(
    name: "Bombard",
    tier: Uncommon,
    priority: 15,
    description: "Your rooks get upgraded with some new cannons. They can shoot up to two tiles diagnal in each direction.",
    icon: "bombard.svg",
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == rook and b[i][j].isColor(side):
                    b[i][j].takes &= rookBombard
                    b[i][j].onTake = bombardOnTake
                    b[i][j].filePath = if side == black: "blackbombard.svg" else: "whitebombard.svg"
)

const lancePromote*: OnPiece = proc(piece: var Piece, board: var ChessBoard) = 
    piece.moves = @[leftRightMoves, diagnalMoves, blackForwardMoves, whiteForwardMoves]
    piece.takes = @[leftRightTakes, diagnalTakes, blackForwardTakes, whiteForwardTakes]
    piece.promoted = true
    piece.filePath = "promotedlance.svg"

const lancePromoteConditions*: OnPiece = proc(piece: var Piece, board: var ChessBoard) = 
    if (piece.tile.rank == 0 or piece.tile.rank == 7) and not piece.promoted:  
        piece.promote(board)

const lanceLeft*: Power = Power(
    name: "Kamikaze", 
    tier: Uncommon,
    priority: 5, 
    rarity: 4, 
    description: 
        """The divine wind is behind you. 
        Your right pawn is replaced with a lance from Shogi.""",
    icon: "lance.svg",
    rotatable: true,
    noColor: true,
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            let rank = if side == black: 1 else: 6
            if side == black:
                b[rank][0].moves = @[blackLanceMoves]
                b[rank][0].takes = @[blackLanceTakes]
            else:
                b[rank][0].moves = @[whiteLanceMoves]
                b[rank][0].takes = @[whiteLanceTakes]
            b[rank][0].onEndTurn = @[lancePromoteConditions]
            b[rank][0].onPromote = @[lancePromote]
            b[rank][0].item = fairy
            b[rank][0].filePath = "lance.svg"
            if side != viewSide: b[rank][0].rotate = true
)

const lanceRight*: Power = Power(
    name: "Kamikaze", 
    tier: Uncommon,
    priority: 5, 
    rarity: 4, 
    description: 
        """The divine wind is behind you. 
        Your left pawn is replaced with a lance from Shogi.""",
    icon: "lance.svg",
    rotatable: true,
    noColor: true,
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard) = 
            let rank = if side == black: 1 else: 6
            if side == black:
                b[rank][7].moves = @[blackLanceMoves]
                b[rank][7].takes = @[blackLanceTakes]
            else:
                b[rank][7].moves = @[whiteLanceMoves]
                b[rank][7].takes = @[whiteLanceTakes]
            b[rank][7].onEndTurn = @[lancePromoteConditions]
            b[rank][7].onPromote = @[lancePromote]
            b[rank][7].item = fairy
            b[rank][7].filePath = "lance.svg"
            if side != viewSide: b[rank][7].rotate = true
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
registerPower(concubine)
registerPower(reinforcements)
registerPower(shotgunKing)
registerPower(coward)
#registerPower(bombard)
registerPower(lanceLeft)
registerPower(lanceRight)

registerSynergy(samuraiSynergy)
registerSynergy(calvaryCharge)
registerSynergy(differentGame)
registerSynergy(linebackers)
registerSynergy(holyBishop)
registerSynergy(bountyHunter)
registerSynergy(masochistEmpress, true, true)
registerSynergy(exodia, true)
registerSynergy(superPawn, true)
registerSynergy(queensWrath, true)
registerSynergy(queensWrath2, true)
registerSynergy(battleFormation, true)
registerSynergy(queensWrathSuper, true)
