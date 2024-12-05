import power, moves, piece, basePieces, extraMoves, board, capitalism
import std/options
from sequtils import filterIt, mapIt, concat
from strutils import contains
from random import sample, rand, randomize, shuffle

#[TODO
create synergy constructor which automatically sets index to -1
or maybe just make it an object, since I don't think performance has ever mattered for this
or remove `Synergy.index`, since I'm honestly not sure what it does
powers are exported for debug, so remove that eventually

Create secret secret synergy for bombard + reinforcements
Add alternative exodia for alternative empress
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
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Queen and b[i][j].isColor(side):
                    b[i][j].takes &= @[knightTakes]
                    b[i][j].moves &= @[knightMoves]
)

const altEmpress*: Power = Power(
    name: "Empress",
    technicalName: "Alternate Empress",
    tier: Uncommon,
    priority: 15,
    rarity: 4, #slightly less common, cuz
    description: "Your queen ascends, gaining the movement of a giraffe. ",
    icon: queenIcon,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Queen and b[i][j].isColor(side):
                    b[i][j].takes &= @[giraffeTakes]
                    b[i][j].moves &= @[giraffeMoves]
)


const silverGeneralPromote: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) = 
    piece.moves = piece.moves.filterIt(it != diagnalMoves) #new technology to remove specific moves, since I apparently
    piece.takes = piece.takes.filterIt(it != diagnalTakes) #didn't read the wikipedia article properly
    #also apparently shogi pieces can promote earlier, though I'll probably never add that
    if piece.isColor(white):
        #blackForwardMoves for white is a backward move
        #we add this, since it can already go forward
        piece.moves &= @[blackForwardMoves, whiteDiagnalMoves, leftRightMoves]
        piece.takes &= @[blackForwardTakes, whiteDiagnalTakes, leftRightTakes]
    else:
        piece.moves &= @[whiteForwardMoves, blackDiagnalMoves, leftRightMoves]
        piece.takes &= @[whiteForwardTakes, blackDiagnalTakes, leftRightTakes]
    piece.promoted = true
    piece.filePath = "promotedsilvergeneral.svg"

const silverGeneralPromoteConditions*: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) = 
    if piece.isAtEnd() and not piece.promoted:  
        piece.promote(board, state)

const mysteriousSwordsmanLeft*: Power = Power(
    name: "Mysterious Swordsman", 
    technicalName: "Mysterious Swordsman Left",
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
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            let rank = if side == black: 1 else: 6
            assert b[rank][1].color == side
            if side == black:
                b[rank][1].moves = @[diagnalMoves, blackForwardMoves]
                b[rank][1].takes = @[diagnalTakes, blackForwardTakes]
            else:
                b[rank][1].moves = @[diagnalMoves, whiteForwardMoves]
                b[rank][1].takes = @[diagnalTakes, whiteForwardTakes]
            b[rank][1].onEndTurn = @[silverGeneralPromoteConditions]
            b[rank][1].onPromote = @[silverGeneralPromote]
            b[rank][1].item = Fairy
            b[rank][1].filePath = "silvergeneral.svg"
            b[rank][1].colorable = false
            if side != viewSide: b[rank][1].rotate = true
)

const mysteriousSwordsmanRight*: Power = Power(
    name: "Mysterious Swordsman", 
    technicalName: "Mysterious Swordsman Right",
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
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            let rank = if side == black: 1 else: 6
            assert b[rank][6].color == side
            if side == black:
                b[rank][6].moves = @[diagnalMoves, blackForwardMoves]
                b[rank][6].takes = @[diagnalTakes, blackForwardTakes]
            else:
                b[rank][6].moves = @[diagnalMoves, whiteForwardMoves]
                b[rank][6].takes = @[diagnalTakes, whiteForwardTakes]
            b[rank][6].onEndTurn = @[silverGeneralPromoteConditions]
            b[rank][6].onPromote = @[silverGeneralPromote]
            b[rank][6].item = Fairy
            b[rank][6].filePath = "silvergeneral.svg"
            b[rank][6].colorable = false
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
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            #TODO: fix hard coded moves to prevent conflict. 
            #fix would just stop move attempt if it would kill a piece
            if side == black:
                b[1][3].pieceMove(2, 3, b, s)
                b[1][4].pieceMove(2, 4, b, s)
            else:
                b[6][3].pieceMove(5, 3, b, s)
                b[6][4].pieceMove(5, 4, b, s)         
)

const stepOnMe*: Power = Power(
    name: "Step on me",
    tier: Common,
    priority: 15, 
    description:
        """Your Queen can take your own pieces. It's literally useless, but if that's your thing...""",
    icon: queenIcon,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Queen and b[i][j].isColor(side):
                    b[i][j].takes &= @[cannibalBishopTakes, cannibalKingTakes, cannibalRookTakes]
)

const illegalFormationRL: Power = Power(
    name: "Illegal Formation", 
    technicalName: "Illegal Formation Left Rook",
    tier: Common, 
    rarity: 2,
    priority: 20,
    description: 
        """ILLEGAL FORMATION: YOUR PAWN ABOVE YOUR LEFT ROOK SWAPS PLACES WITH YOUR LEFT ROOK""",
    icon: rookIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            let rank = if side == black: 0 else: 6
            pieceSwap(b[rank][0], b[rank + 1][0], b)
)

const illegalFormationRR: Power = Power(
    name: "Illegal Formation", 
    technicalName: "Illegal Formation Right Rook",
    tier: Common, 
    rarity: 2,
    priority: 20,
    description: 
        """ILLEGAL FORMATION: YOUR PAWN ABOVE YOUR RIGHT ROOK SWAPS PLACES WITH YOUR RIGHT ROOK""",
    icon: rookIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            let rank = if side == black: 0 else: 6
            pieceSwap(b[rank][7], b[rank + 1][7], b)
)

const illegalFormationBL*: Power = Power(
    name: "Illegal Formation", 
    technicalName: "Illegal Formation Left Bishop",
    tier: Common, 
    rarity: 2,
    priority: 20,
    description: 
        """ILLEGAL FORMATION: YOUR PAWN ABOVE YOUR LEFT BISHOP SWAPS PLACES WITH YOUR LEFT BISHOP""",
    icon: bishopIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            let rank = if side == black: 0 else: 6
            pieceSwap(b[rank][2], b[rank + 1][2], b)
)

const illegalFormationBR: Power = Power(
    name: "Illegal Formation", 
    technicalName: "Illegal Formation Right Bishop",
    tier: Common, 
    rarity: 2,
    priority: 20,
    description: 
        """ILLEGAL FORMATION: YOUR PAWN ABOVE YOUR RIGHT BISHOP SWAPS PLACES WITH YOUR RIGHT BISHOP""",
    icon: bishopIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            let rank = if side == black: 0 else: 6
            pieceSwap(b[rank][5], b[rank + 1][5], b)
)

const putInTheWorkCondition: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) =
    if piece.piecesTaken == 3:
        piece.promote(board, state)

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
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Pawn and b[i][j].isColor(side):
                    b[i][j].onEndTurn &= putInTheWorkCondition

)

const wanderingRoninLeft*: Power = Power(
    name: "Wandering Ronin", 
    technicalName: "Wandering Ronin Left",
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
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) =
            let rank = if side == black: 1 else: 6
            assert b[rank][2].color == side
            if side == black:
                b[rank][2].moves = @[diagnalMoves, blackForwardMoves, leftRightMoves]
                b[rank][2].takes = @[diagnalTakes, blackForwardTakes, leftRightTakes]
            else:
                b[rank][2].moves = @[diagnalMoves, whiteForwardMoves, leftRightMoves]
                b[rank][2].takes = @[diagnalTakes, whiteForwardTakes, leftRightTakes]             
            b[rank][2].onPromote = @[defaultOnEndTurn]    #Gold generals do not promote
            b[rank][2].item = Fairy
            b[rank][2].filePath = "goldgeneral.svg"
            b[rank][2].colorable = false
            if side != viewSide: b[rank][2].rotate = true
)

const wanderingRoninRight*: Power = Power(
    name: "Wandering Ronin", 
    technicalName: "Wandering Ronin Right",
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
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            let rank = if side == black: 1 else: 6
            assert b[rank][5].color == side
            if side == black:
                b[rank][5].moves = @[diagnalMoves, blackForwardMoves, leftRightMoves]
                b[rank][5].takes = @[diagnalTakes, blackForwardTakes, leftRightTakes]
            else:
                b[rank][5].moves = @[diagnalMoves, whiteForwardMoves, leftRightMoves]
                b[rank][5].takes = @[diagnalTakes, whiteForwardTakes, leftRightTakes]  
            b[rank][5].onPromote = @[defaultOnEndTurn]    #Gold generals do not promote
            b[rank][5].item = Fairy
            b[rank][5].filePath = "goldgeneral.svg"
            b[rank][5].colorable = false
            if side != viewSide: b[rank][5].rotate = true

)

#this is different than a normal promote, using clojure for transform state
#idk why, but now things are even more spaghetti
proc createWerewolf(): OnPiece =
    var transformed = false

    result = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) =
        if piece.piecesTaken >= 1 and not transformed:
            piece.moves &= @[knightMoves, giraffeMoves]
            piece.takes &= @[knightTakes, giraffeTakes]
            piece.rotate = true
            transformed = true

const werewolves*: Power = Power(
    name: "Werewolves",
    tier: Uncommon,
    priority: 15, 
    description: 
        """Your leftmost and rightmost pawns are secretly werewolves! When they take a piece, they eat it and gain the ability to jump like a knight and giraffe. They can still promote.""",
    icon: pawnIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            let rank = if side == black: 1 else: 6
            b[rank][0].onEndTurn &= createWerewolf()
            b[rank][7].onEndTurn &= createWerewolf()
)

const archBishops: Power = Power(
    name: "Archbishops",
    tier: Rare,
    priority: 15, 
    description:
        """Your bishops ascend to archbishops, gaining the movement of a knight.""",
    icon: bishopIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Bishop and b[i][j].isColor(side):
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
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Knight and b[i][j].isColor(side):
                    assert b[i][j].color == side
                    b[i][j].moves = @[giraffeMoves]   
                    b[i][j].takes = @[giraffeTakes]
                    b[i][j].filePath = "giraffe.svg"
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
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Knight and b[i][j].isColor(side):
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
        proc (side: Color, viewerSide: Color, b: var ChessBoard, s: var BoardState) = 
            mysteriousSwordsmanLeft.onStart(side, viewerSide, b, s)
            mysteriousSwordsmanRight.onStart(side, viewerSide, b, s)
            wanderingRoninLeft.onStart(side, viewerSide, b, s)
            wanderingRoninRight.onStart(side, viewerSide, b, s)
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
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Queen and b[i][j].isColor(side):
                    b[i][j].takes.add(cannibalKnightTakes)
                        
)

const masochistEmpress: Synergy = (
    power: masochistEmpressPower,
    rarity: 0,
    requirements: @[empress.name, stepOnMe.name],
    replacements: @[],
    index: -1
)

const masochistAltEmpressPower: Power = Power(
    name: "Masochist Empress",
    tier: UltraRare,
    rarity: 0,
    priority: 15,
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Queen and b[i][j].isColor(side):
                    b[i][j].takes.add(cannibalGiraffeTakes)
                        
)

const masochistAltEmpress: Synergy = (
    power: masochistAltEmpressPower,
    rarity: 0,
    requirements: @[altEmpress.name, stepOnMe.name],
    replacements: @[],
    index: -1
)

const sacrificeWhenTaken*: WhenTaken = 
    proc (taken: var Piece, taker: var Piece, board: var ChessBoard, state: var BoardState): tuple[endTile: Tile, takeSuccess: bool] =
        if (taken.tile == taker.tile):
            for i, j in board.rankAndFile:
                if board[i][j].sameColor(taken) and not board[i][j].promoted:
                    board[i][j].promote(board, state)
            board[taken.tile] = air.pieceCopy(index = taken.index, tile = taken.tile)
            return (taken.tile, false)
        else:
            return defaultWhenTaken(taken, taker, board, state)


const sacrifice*: Power = Power(
    name: "Sacrificial Maiden",
    tier: UltraRare,
    rarity: 1,
    priority: 25,
    description: """SACRIFICE THY MAIDENS TO THE BLOOD GOD""",
    icon: queenIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) =
            for i, j in b.rankAndFile:
                if b[i][j].item == Queen and b[i][j].isColor(side):
                    b[i][j].whenTaken = sacrificeWhenTaken
                    b[i][j].takes &= takeSelf
)

const sacrificeWhenTakenEmpress*: WhenTaken = 
    proc (taken: var Piece, taker: var Piece, board: var ChessBoard, state: var BoardState): tuple[endTile: Tile, takeSuccess: bool] =
        if (taken.tile == taker.tile):
            for i, j in board.rankAndFile:
                if board[i][j].sameColor(taken):
                    board[i][j].promote(board, state)
                    board[i][j].moves &= knightMoves
                    board[i][j].takes &= knightTakes

            taken = air.pieceCopy(index = taken.index, tile = taken.tile)
            return (taken.tile, true)
        else:
            return defaultWhenTaken(taken, taker, board, state)


const exodiaPower: Power = Power(
    name: "Exodia",
    tier: UltraRare,
    rarity: 0,
    priority: 25,
    description: "You had your fun, but the game is over. Too bad right?",
    icon: queenIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Queen and b[i][j].isColor(side):
                    b[i][j].whenTaken = sacrificeWhenTakenEmpress
                    b[i][j].takes &= takeSelf            
)

const exodia: Synergy = (
    power: exodiaPower,
    rarity: 0,
    requirements: @[empress.name, sacrifice.name],
    replacements: @[sacrifice.name],
    index: -1
)

const sacrificeWhenTakenAltEmpress*: WhenTaken = 
    proc (taken: var Piece, taker: var Piece, board: var ChessBoard, state: var BoardState): tuple[endTile: Tile, takeSuccess: bool] =
        if (taken.tile == taker.tile):
            for i, j in board.rankAndFile:
                if board[i][j].sameColor(taken):
                    board[i][j].promote(board, state)
                    board[i][j].moves &= giraffeMoves
                    board[i][j].takes &= giraffeTakes

            taken = air.pieceCopy(index = taken.index, tile = taken.tile)
            return (taken.tile, true)
        else:
            return defaultWhenTaken(taken, taker, board, state)


const altExodiaPower: Power = Power(
    name: "Exodia",
    tier: UltraRare,
    rarity: 0,
    priority: 25,
    description: "You had your fun, but the game is over. Too bad right?",
    icon: queenIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Queen and b[i][j].isColor(side):
                    b[i][j].whenTaken = sacrificeWhenTakenAltEmpress
                    b[i][j].takes &= takeSelf            
)

const altExodia: Synergy = (
    power: altExodiaPower,
    rarity: 0,
    requirements: @[altEmpress.name, sacrifice.name],
    replacements: @[sacrifice.name],
    index: -1
)

const backStep*: Power = Power(
    name: "Backstep",
    tier: Rare,
    priority: 15,
    description: "Your pawns receive some training. They can move one tile back. They cannot take this way.",
    icon: pawnIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Pawn and b[i][j].isColor(side):
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
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Pawn and b[i][j].isColor(side):
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
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Queen:
                    b[i][j] = air.pieceCopy(index = b[i][j].index, tile = b[i][j].tile)
)

const superPawnPower: Power = Power(
    name: "Super Pawn",
    tier: UltraRare,
    rarity: 0,
    priority: 15,
    description: "You have insane pawns. Please don't sacrifice them.",
    icon: pawnIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard, state: var BoardState) = 
            headStart.onStart(side, viewSide, b, state)
            backStep.onStart(side, viewSide, b, state)
            putInTheWork.onStart(side, viewSide, b, state)
            for i, j in b.rankAndFile:
                if b[i][j].item == Pawn and b[i][j].isColor(side):
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
    rarity: 1,
    priority: 1,
    description: "🧡🤍🩷",
    icon: "lesbianprideflag.svg",
    noColor: true,
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == King and b[i][j].isColor(side):
                    b[i][j] = whiteQueen.pieceCopy(index = b[i][j].index,
                        color = b[i][j].color, item = King, tile = b[i][j].tile, rotate = true, filePath = queenIcon) 
                    #`Piece.item` is still king so win/loss works. `Piece.rotate` = true should hopefully suggest this
                elif b[i][j].item == Bishop and b[i][j].isColor(side):
                    b[i][j] = air.pieceCopy(index = b[i][j].index, tile = b[i][j].tile)
)

const queensWrathPower: Power = Power(
    name: "Queen's Wrath",
    tier: UltraRare,
    rarity: 0,
    priority: 1,
    description: "Why must she die?",
    icon: queenIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item != Queen and b[i][j].isColor(side):
                    b[i][j] = air.pieceCopy(index = b[i][j].index, tile = b[i][j].tile)
                elif b[i][j].item == Queen and b[i][j].isColor(side):
                    b[i][j].moves &= @[knightMoves, giraffeMoves]
                    b[i][j].takes &= @[knightTakes, giraffeTakes]
                    b[i][j].item = King
            
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
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item != Queen and b[i][j].isColor(side):
                    b[i][j] =air.pieceCopy(index = b[i][j].index, tile = b[i][j].tile)
                elif b[i][j].item == Queen and b[i][j].isColor(side):
                    b[i][j].moves &= @[knightMoves, giraffeMoves, whiteForwardTwiceJumpMove, blackForwardTwiceJumpMove]
                    b[i][j].takes &= @[knightTakes, giraffeTakes, whiteForwardTwiceJumpTake, blackForwardTwiceJumpTake]
                    b[i][j].item = King
                elif b[i][j].item == Bishop and not b[i][j].isColor(side):
                    b[i][j] = air.pieceCopy(index = b[i][j].index, tile = b[i][j].tile)
)

const queensWrath: Synergy = (
    power: queensWrathPower,
    rarity: 0,
    requirements: @[lesbianPride.name, queenTrade.name],
    replacements: @[lesbianPride.name],
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
    replacements: @[lesbianPride.name, sacrifice.name],
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
        proc (side: Color, viewSide: Color, b: var ChessBoard, s: var BoardState) =   
            let offset = if side == white: -3 else: 3
            for i, j in b.rankAndFile:
                if b[i][j].item == Knight and b[i][j].isColor(side) and b[i][j].timesMoved == 0:
                    inc b[i][j].timesMoved
                    b[i][j].pieceMove(i + offset, j, b, s)
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
        proc (side: Color, viewSide: Color, b: var ChessBoard, s: var BoardState) = 
            if side == black:
                b[1][3].pieceMove(3, 3, b, s)
                b[1][4].pieceMove(3, 4, b, s)
            else:
                b[6][3].pieceMove(4, 3, b, s)
                b[6][4].pieceMove(4, 4, b, s)      
)

const battleFormation: Synergy = (
    power: battleFormationPower,
    rarity: 0,
    requirements: @[knightChargePower.name, developed.name],
    replacements: @[developed.name],
    index: -1
)

const differentGamePower*: Power = Power(
    name: "Criminal Formation",
    tier: Common,
    rarity: 0,
    priority: 20,
    description: "I guess the rules didn't get to you. Your pawns above both knights and both rooks swap places with those pieces.",
    icon: pawnIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard, state: var BoardState) =
            illegalFormationBL.onStart(side, viewSide, b, state)
            illegalFormationBR.onStart(side, viewSide, b, state)
            illegalFormationRL.onStart(side, viewSide, b, state)
            illegalFormationRR.onStart(side, viewSide, b, state)
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
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Pawn and b[i][j].isColor(side):
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
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Knight and b[i][j].isColor(side):
                    b[i][j].moves &= nightriderMoves
                    b[i][j].takes &= nightriderTakes
                    b[i][j].item = Fairy
                    b[i][j].filePath = "nightrider.svg"
)

const desegregation: Power = Power(
    name: "Desegregation and Integration",
    tier: Uncommon,
    priority: 15,
    description: "Your bishops learn to accept their differences. They can move left and right.",
    icon: bishopIcon,
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Bishop and b[i][j].isColor(side):
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
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Bishop and b[i][j].isColor(side):
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

const concubineWhenTake = 
    proc (taken: var Piece, taker: var Piece, board: var ChessBoard, state: var BoardState): tuple[endTile: Tile, takeSuccess: bool] =
        if taker.item == King and 
            taken.item == Rook and
            taken.sameColor(taker) and
            taker.timesMoved == 0 and
            taken.timesMoved == 0: 
                taken.promote(board, state)
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
            return defaultWhenTaken(taken, taker, board, state)

const concubine*: Power = Power(
    name: "Concubine",
    tier: Rare,
    priority: 15,
    description: "Your rook becomes a queen when it castles.... You're sick.",
    icon: rookIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            var dna: Piece = 
                if side == white: whiteQueen.pieceCopy(index = 0)  #index not needed because we just use original rooks index
                else: blackQueen.pieceCopy(index = 0) 

            for i, j in b.rankAndFile:
                if b[i][j].item == Queen and b[i][j].isColor(side):
                    dna = b[i][j]
                    break

            let concubinePromote: OnPiece =  proc (piece: var Piece, board: var ChessBoard, state: var BoardState) =
                piece = dna.pieceCopy(
                    index = piece.index,
                    piecesTaken = piece.piecesTaken, 
                    timesMoved = piece.timesMoved, 
                    tile = piece.tile,
                    promoted = true)

            for i, j in b.rankAndFile:
                if b[i][j].item == Rook and b[i][j].isColor(side):
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
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            var dna: Piece = 
                if side == white: whitePawn.pieceCopy(index = 0) #index is assigned when piece is created, so default now
                else: blackPawn.pieceCopy(index = 0)

            for i, j in b.rankAndFile:
                if b[i][j].item == Pawn and b[i][j].isColor(side):
                    dna = b[i][j]
                    break

            let reinforcementsOntake: OnAction = proc (piece: var Piece, to: Tile, board: var ChessBoard, state: var BoardState) =
                let takeResults = to.takenBy(piece, board,state)
                let originalRookTile = piece.tile
                board[takeResults.endTile].timesMoved += 1

                if takeResults.takeSuccess:
                    board[takeResults.endTile].piecesTaken += 1
                    if board[takeResults.endTile].piecesTaken mod 2 == 0:
                        board[originalRookTile.rank][originalRookTile.file] = dna.pieceCopy(index = newIndex(state), tile = originalRookTile)

            for i, j in b.rankAndFile:
                if b[i][j].item == Rook and b[i][j].isColor(side):
                    b[i][j].onTake = reinforcementsOntake

)

const shotgunKingOnTake*: OnAction = proc (piece: var Piece, to: Tile, board: var ChessBoard, state: var BoardState) = 
    let originalKingTile = piece.tile
    let takeResult = to.takenBy(piece, board, state)
    piece.timesMoved += 1
    if takeResult.takeSuccess:
        piece.piecesTaken += 1

        if (originalKingTile.rank + 2 == takeResult.endTile.rank):
            takeResult.endTile.pieceMove(originalKingTile, board, state)
        elif (originalKingTile.rank - 2 == takeResult.endTile.rank):
            takeResult.endTile.pieceMove(originalKingTile, board, state)

const shotgunKing*: Power = Power(
    name: "Shotgun King",
    tier: Common,
    priority: 5,
    description: """Your king knows its 2nd ammendment rights. It can take pieces two ahead or two behind. 
                    If it does this take, it does not move from its initial tile.""",
    icon: kingIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == King and b[i][j].isColor(side):
                    assert b[i][j].color == side
                    b[i][j].onTake = shotgunKingOnTake
                    b[i][j].takes &= @[blackForwardTwiceJumpTake, whiteForwardTwiceJumpTake]
)

const bountyHunterOnEndTurn*: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) = 
        if piece.piecesTaken == 3:
            for i, j in board.rankAndFile:
                #searches for enemy king and deletes is
                if board[i][j].item == King and not board[i][j].sameColor(piece):
                    board[i][j] = air.pieceCopy(index = board[i][j].index, tile = board[i][j].tile)

const bountyHunterPower*: Power = Power(
    name: "Bounty Hunter",
    tier: Common,
    rarity: 0,
    priority: 15,
    description: "It's hard to make a living these days. If your king takes 3 pieces, you automatically win.",
    icon: kingIcon,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == King and b[i][j].isColor(side):
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
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == King and b[i][j].isColor(side):
                    if b[i][j].timesMoved == 0:
                        inc b[i][j].timesMoved
                        pieceSwap(b[i][j], b[i][j + 2], b)      
)

const bombardOnTake*: OnAction = proc (piece: var Piece, to: Tile, board: var ChessBoard, state: var BoardState) = 
    let originalTile = piece.tile
    let takeResult = rookWhenTaken(piece, board[to.rank][to.file], board, state)
    if takeResult.takeSuccess:
        if ((originalTile.rank - takeResult.endTile.rank != 0) and (originalTile.file - takeResult.endTile.file) != 0):
            takeResult.endTile.pieceMove(originalTile, board, state)

const bombard: Power = Power(
    name: "Bombard",
    tier: Uncommon,
    priority: 15,
    description: "Your rooks get upgraded with some new cannons. They can shoot up to two tiles diagnal in each direction.",
    icon: "bombard.svg",
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Rook and b[i][j].isColor(side):
                    b[i][j].takes &= rookBombard
                    b[i][j].onTake = bombardOnTake
                    b[i][j].filePath = "bombard.svg"
)

#unfinished, TODO
const bombardWithReinforcements: Power = Power(
    name: "Bombard",
    tier: Uncommon,
    description: "Your rooks get upgraded with some new cannons. They can shoot up to two tiles diangal in each direction.",
    icon: "bombard.svg",
    onStart:
            proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            var dna: Piece = 
                if side == white: whitePawn.pieceCopy(index = 0) 
                else: blackPawn.pieceCopy(index = 0)

            for i, j in b.rankAndFile:
                if b[i][j].item == Rook and b[i][j].isColor(side):
                    dna = b[i][j]
                    break

            let reinforcementsOntake: OnAction = proc (piece: var Piece, to: Tile, board: var ChessBoard, state: var BoardState) =
                let takeResults = to.takenBy(piece, board, state)
                let originalRookTile = piece.tile
                board[takeResults.endTile].timesMoved += 1

                if takeResults.takeSuccess:
                    board[takeResults.endTile].piecesTaken += 1
                    if board[takeResults.endTile].piecesTaken mod 2 == 0:
                        board[originalRookTile.rank][originalRookTile.file] = dna.pieceCopy(index = newIndex(state), tile = originalRookTile)

            for i, j in b.rankAndFile:
                if b[i][j].item == Rook and b[i][j].isColor(side):
                    b[i][j].onTake = reinforcementsOntake
)

const lancePromote*: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) = 
    piece.moves = @[leftRightMoves, diagnalMoves, blackForwardMoves, whiteForwardMoves]
    piece.takes = @[leftRightTakes, diagnalTakes, blackForwardTakes, whiteForwardTakes]
    piece.promoted = true
    piece.filePath = "promotedlance.svg"

const lancePromoteConditions*: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) = 
    if piece.isAtEnd() and not piece.promoted:  
        piece.promote(board, state)

const lanceRight*: Power = Power(
    name: "Kamikaze", 
    technicalName: "Kamikaze Right",
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
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            let rank = if side == black: 1 else: 6
            assert b[rank][0].color == side
            if side == black:
                b[rank][0].moves = @[blackLanceMoves]
                b[rank][0].takes = @[blackLanceTakes]
            else:
                b[rank][0].moves = @[whiteLanceMoves]
                b[rank][0].takes = @[whiteLanceTakes]
            b[rank][0].onEndTurn = @[lancePromoteConditions]
            b[rank][0].onPromote = @[lancePromote]
            b[rank][0].item = Fairy
            b[rank][0].filePath = "lance.svg"
            b[rank][0].colorable = false
            if side != viewSide: b[rank][0].rotate = true
)

const lanceLeft*: Power = Power(
    name: "Kamikaze", 
    technicalName: "Kamikaze Left",
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
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            let rank = if side == black: 1 else: 6
            assert b[rank][7].color == side
            if side == black:
                b[rank][7].moves = @[blackLanceMoves]
                b[rank][7].takes = @[blackLanceTakes]
            else:
                b[rank][7].moves = @[whiteLanceMoves]
                b[rank][7].takes = @[whiteLanceTakes]
            b[rank][7].onEndTurn = @[lancePromoteConditions]
            b[rank][7].onPromote = @[lancePromote]
            b[rank][7].item = Fairy
            b[rank][7].filePath = "lance.svg"
            b[rank][7].colorable = false
            if side != viewSide: b[rank][7].rotate = true
)


const drunkOnEndTurn*: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) = 
    if not piece.drunk:
        piece.drunk = true #after move, piece is different, so we drunk now
        #random seed is linked to location and `Piece.rand.seed`, which is made from id
        #this ensures that both sides generate same move, even though they do it seperately
        #it would be ideal to just send move over, but it's too late to add such a system
        #also maybe research if the location *10 *100 is nesscary
        randomize(10 * piece.tile.rank + 100 * piece.tile.file + state.shared.randSeed)
        let takes = piece.getTakesOn(board)
        let moves = piece.getMovesOn(board)
        if len(moves) == 0: return # I don't really like how this looks


        var attempt = moves.filterIt(it notin takes).sample()

        #it prioritizes takes to avoid potentially moving into another piece
        if attempt in moves:
            piece.move(attempt, board, state)

const drunkVirus*: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) = 
    if not piece.drunk:
        piece.drunk = true #after move, piece is different, so we drunk now
        #random seed is linked to location and `Piece.rand.seed`, which is made from id
        #this ensures that both sides generate same move, even though they do it seperately
        #it would be ideal to just send move over, but it's too late to add such a system
        #also maybe research if the location *10 *100 is nesscary
        randomize(10 * piece.tile.rank + 100 * piece.tile.file + state.shared.randSeed)
        let takes = piece.getTakesOn(board)
        let moves = piece.getMovesOn(board)
        if len(moves & takes) == 0: return # I don't really like how this looks


        let randomAction = sample(moves & takes)

        #it prioritizes takes to avoid potentially moving into another piece
        if randomAction in takes:
            piece.take(randomAction, board, state)
        elif randomAction in moves:
            piece.move(randomAction, board, state)

const drunkKnights: Power = Power(
    name: "Drunk Knights",
    tier: Rare,
    priority: 15,
    description: 
        """Drunk riding is dangerous, your knights should be ashamed of themselves. 
        After every other turn, they randomly move.""",
    icon: knightIcon,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Knight and b[i][j].isColor(side):
                    b[i][j].onEndTurn &= drunkOnEndTurn
)

const alcoholism*: Power = Power(
    name: "Alcoholism",
    tier: UltraRare,
    rarity: 4,
    priority: 15,
    description: """You're families and friends miss you. The real you.""",
    icon: pawnIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].isColor(side):
                    b[i][j].onEndTurn &= drunkOnEndTurn
                    b[i][j].rotate = true
)

const drunkNightRiderPower: Power = Power(
    name: "nighetriedder",
    tier: UltraRare,
    priority: 17,
    rarity: 0,
    description: "nighetriedder.?",
    icon: "nightrider.svg",
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].filePath.contains("nightrider") and b[i][j].isColor(side):
                    #I usually try to avoid this filtering, I'm not sure why
                    #it works fine, and performance has never been an issue
                    b[i][j].onEndTurn = b[i][j].onEndTurn.filterIt(it != drunkOnEndTurn)
                    b[i][j].onEndTurn &= drunkVirus
)

const drunkNightRider: Synergy = (
    power: drunkNightRiderPower,
    rarity: 0,
    requirements: @[drunkKnights.name, nightRider.name],
    replacements: @[],
    index: -1
)

const drunkNightRider2: Synergy = (
    power: drunkNightRiderPower,
    rarity: 0,
    requirements: @[alcoholism.name, nightRider.name],
    replacements: @[],
    index: -1
)

const virusPower*: Power = Power(
    name: "virus",
    tier: UltraRare,
    priority: 15,
    description: "They're dying. They're dying. They're dying.",
    rarity: 0,
    icon: "",
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) =
            for i, j in b.rankAndFile:
                if b[i][j].isColor(side):
                    b[i][j].onEndTurn &= drunkVirus
                    b[i][j].rotate = true
)  

#virus powers just have random stuff
#but still decided in advance so that I don't have to sync random seed
const virus: Synergy = (
    power: virusPower,
    rarity: 0,
    requirements: @[alcoholism.name, lanceLeft.name, headStart.name, mysteriousSwordsmanLeft.name],
    replacements: @[alcoholism.name],
    index: -1
)

const virus2: Synergy = (
    power: virusPower,
    rarity: 0,
    requirements: @[alcoholism.name, backStep.name, knightChargePower.name, altEmpress.name],
    replacements: @[alcoholism.name],
    index: -1
)

const virus3: Synergy = (
    power: virusPower,
    rarity: 0,
    requirements: @[alcoholism.name, wanderingRoninLeft.name, superPawnPower.name, empress.name],
    replacements: @[alcoholism.name],
    index: -1
)

const virus4: Synergy = (
    power: virusPower,
    rarity: 0,
    requirements: @[alcoholism.name, stepOnMe.name, coward.name, shotgunKing.name],
    replacements: @[alcoholism.name],
    index: -1
)

const virus5: Synergy = (
    power: virusPower,
    rarity: 0,
    requirements: @[alcoholism.name, reinforcements.name, empress.name, giraffe.name, werewolves.name],
    replacements: @[alcoholism.name],
    index: -1
)

const virus6: Synergy = (
    power: virusPower,
    rarity: 0,
    requirements: @[alcoholism.name, anime.name, developed.name, sacrifice.name, illegalFormationBR.name],
    replacements: @[alcoholism.name],
    index: -1
)

const virus7: Synergy = (
    power: virusPower,
    rarity: 0,
    requirements: @[alcoholism.name, linebackersPower.name, nightrider.name, desegregation.name, holy.name],
    replacements: @[alcoholism.name],
    index: -1
)

#moves for civilian are put here so that it can't be moved normally
const randomCivilianEndTurn*: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) = 
    if not piece.drunk:
        piece.drunk = true
        randomize(10 * piece.tile.rank + 100 * piece.tile.file + state.shared.randSeed)

        piece.moves &= kingMoves
        let moves = kingMoves(board, piece)
        let takes = kingTakes(board, piece)
        var attempt = moves.filterIt(it notin takes) #remove takes to prevent conflict

        if attempt.len == 0: return
        else: piece.move(attempt.sample(), board, state)

#TODO: SEE IF I CAN KILL THE PIECE WHEN THIS HAPPENS. WHY CAPS LOCK
const attemptedWarCrimes*: WhenTaken = proc (taken: var Piece, taker: var Piece, board: var ChessBoard, state: var BoardState): tuple[endTile: Tile, takeSuccess: bool] = 
    return (taker.tile, false)

const civilians*: Power = Power(
    name: "Civilians",
    tier: Uncommon,
    priority: 30,
    description: """Of course, a battle will have its civillians. And of course, the enemy won't kill them.
                    3 civillians spawn on the enemy side. They randomly move and cannot be taken.""",
    icon: "civilian.svg",
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, state: var BoardState) =
            randomize(state.shared.randSeed)
            let rank: int = if side == black: 5 else: 2
            let commoner = Piece(item: Fairy, color: side, moves: @[kingMoves], takes: @[], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTaken: attemptedWarCrimes, onEndTurn: @[randomCivilianEndTurn], onPromote: @[defaultOnEndTurn],
                                filePath: "civilian.svg")

            var spawns = 0
            var failsafe = 20
            var attempt: int = rand(7)
            while spawns != 3 and failSafe != 0:
                if b[rank][attempt].isAir:
                    let tile = b[rank][attempt].tile
                    b[rank][attempt] = commoner.pieceCopy(index = newIndex(state), tile = tile)
                    inc spawns
                else:
                    dec failSafe

                attempt = rand(7)
)

const calvaryGiraffePower: Power = Power(
    name: "Bandaid",
    tier: UltraRare,
    rarity: 0,
    priority: 26, #after calvary charge
    description: """It turns out that calvary plus giraffe is an automatic checkmate for white, 
                    so I'm making the giraffes start one tile back. Sorry.""",
    icon: "giraffe.svg",
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Knight and 
                    b[i][j].iscolor(side) and 
                    b[i][j].timesMoved == 1: # `== 1` because it was already incremented in knightCharge. Prevents double activation
                        let back = if side == black: -1 else: 1
                        inc b[i][j].timesMoved
                        b[i][j].pieceMove(b[i][j].tile.rank + back, b[i][j].tile.file, b, s)

)

const calvaryGiraffe: Synergy = (
    power: calvaryGiraffePower,
    rarity: 0,
    requirements: @[knightChargePower.name, giraffe.name],
    replacements: @[],
    index: -1
)

const lesbianBountyHunterOnEndTurn*: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) = 
        if piece.piecesTaken == 7:
            for i, j in board.rankAndFile:
                #searches for enemy king and deletes is
                if board[i][j].item == King and not board[i][j].sameColor(piece):
                    board[i][j] = air.pieceCopy(index = board[i][j].index, tile = board[i][j].tile)

const lesbianBountyHunterPower*: Power = Power(
    name: "Bounty Hunter Nerf",
    tier: Common,
    rarity: 0,
    priority: 15,
    description: "Yeah, 3 pieces is way too easy for our lesbian queens, so now it's 7 pieces. You got this!",
    icon: kingIcon,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == King and b[i][j].isColor(side):
                    b[i][j].onEndTurn &= lesbianBountyHunterOnEndTurn
)

const lesbianBountyHunter: Synergy = (
    power: lesbianBountyHunterPower,
    rarity: 0,
    requirements: @[lesbianPride.name, bountyHunterPower.name],
    replacements: @[bountyHunterPower.name],
    index: -1
)

proc createLottery(): OnPiece = 
    var lastTimesMoved = 0
    #closure is used to hold state
    #this is preferable when state does not need to interact with the rest of the game's systems
    #to better modularize the power's state, I think
    #`Piece.rand` powers can't do this because it needs the seed, and a global clear of drunkenness
    #which has to happen after all `Piece.onEndTurn` stuff, not during
    result = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) =
        if piece.timesMoved != lastTimesMoved:
            randomize(10 * piece.tile.rank + 100 * piece.tile.file + state.shared.randSeed)
            let ticket = rand(100)
            if ticket == 42: #arbitrary
                piece.promote(board, state)
        lastTimesMoved = piece.timesMoved
    

const slumdogMillionaire*: Power = Power(
    name: "Slumdog Millionaire",
    tier: Common,
    priority: 15,
    description: """Have you seen the movie Slumdog Millionaire? It's kind of like that. 
                    Your pawns have a 1% chance of promoting whenever they move.""",
    icon: pawnIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Pawn and b[i][j].isColor(side):
                    b[i][j].onEndTurn &= createLottery()
)


const stupidOnEndTurn: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) =
    randomize(10 * piece.tile.rank + 100 * piece.tile.file + state.shared.randSeed)
    let ticket = rand(1000)
    if ticket == 42: #arbitrary
        for i, j in board.rankAndFile:
            if board[i][j].item == King and 
                board[i][j].isColor(piece.color.otherSide()):
                    board[i][j].item = None #kills king

const stupidPower*: Power = Power(
    name: "Stupid Power",
    tier: Common,
    priority: 15,
    description: """You have a 0.1% chance to automatically win each turn. Yeah, I'm out of ideas. I'm sorry.""",
    icon: kingIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == King and b[i][j].isColor(side):
                    b[i][j].onEndTurn &= stupidOnEndTurn
)

const convertingTake: OnAction = proc (piece: var Piece, taking: Tile, board: var ChessBoard, state: var BoardState) = 
    randomize(10 * piece.tile.rank + 100 * piece.tile.file + state.shared.randSeed)
    let dice = rand(20)

    inc piece.timesMoved
    if dice <= 3: #creates odds of 3/20 or 15%
        board[taking].color = piece.color
        board[taking].index = newIndex(state)
        pieceSwap(piece, board[taking], board)
    else:
        let takeResult = taking.takenBy(piece, board, state)
        if takeResult.takeSuccess:
            board[takeResult.endTile].piecesTaken += 1

const conversion: Power = Power(
    name: "Conversion",
    tier: Uncommon,
    priority: 15,
    description: """When your bishop takes a piece, it has a 15% chance to convert it to your color. 
                    When this happens, your bishop swaps places with it instead of taking it.""",
    icon: bishopIcon,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Bishop and b[i][j].isColor(side):
                    b[i][j].onTake = convertingTake
)

const holyConvertingTake: OnAction = proc (piece: var Piece, taking: Tile, board: var ChessBoard, state: var BoardState) = 
    randomize(10 * piece.tile.rank + 100 * piece.tile.file + state.shared.randSeed)
    let dice = rand(20)

    inc piece.timesMoved
    if dice <= 6: #creates odds of 6/20 or 30%
        board[taking].color = piece.color
        board[taking].index = newIndex(state)
        pieceSwap(piece, board[taking], board)
    else:
        let takeResult = taking.takenBy(piece, board, state)
        if takeResult.takeSuccess:
            board[takeResult.endTile].piecesTaken += 1

const holyConversionPower: Power = Power(
    name: "God's Disciple",
    tier: Uncommon,
    priority: 15,
    description: """Your bishop has now seen god. When it takes, it has a 30% chance to convert it to your color. 
                    When this happens, your bishop swaps places with it instead of taking it.""",
    icon: bishopIcon,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Bishop and b[i][j].isColor(side):
                    b[i][j].onTake = holyConvertingTake
)

const holyConversion: Synergy = (
    power: holyConversionPower,
    rarity: 16,
    requirements: @[conversion.name, holy.name],
    replacements: @[conversion.name],
    index: -1
)

#since end turn stuff now runs at the end of every turn, we have new 
#tech like global powers
const killPromoted: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) =
    for i, j in board.rankAndFile:
        if board[i][j].promoted:
                board[i][j] = air.pieceCopy(index = newIndex(state), tile = board[i][j].tile)

const americanDream: Power = Power(
    name: "American Dream",
    tier: Rare,
    priority: 30, 
    description: "All pieces, you and your opponent, are killed when they promote. It's not real.",
    icon: "usflag.svg",
    noColor: true,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                #added to the king so that it stops when the game ends
                if b[i][j].item == King and b[i][j].isColor(side):
                    b[i][j].onEndTurn &= killPromoted
)

const sleeperAgent*: Power = Power(
    name: "Sleeper Agent",
    tier: Common,
    priority: 30,
    description: """The silent river collapses in pieces. 
                    One of your pawns is a sleeper agent. They can take forward.""",
    icon: pawnIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, state: var BoardState) =
            randomize(state.shared.randSeed)
            var sleeper = rand(b.len - 1) #I don't know why I don't just hardcode it
            var failsafe = b.len + 1
            let rank = if side == black: 1 else: 6

            #if sleeper is not a pawn, then it tries next piece
            #after 10 tries it gives up
            while b[rank][sleeper].item != Pawn and failsafe != 0:
                inc sleeper
                dec failsafe
                sleeper = sleeper mod 8 

            #only places piece if it knows that search succeeded
            if failsafe != 0:
                if side == black:
                    b[1][sleeper].takes &= blackForwardTakes
                else:
                    b[6][sleeper].takes &= whiteForwardTakes
            
            
)

#we capture the moves, and give it back the next turn, so that you can't do a one turn promote + checkmate
const promoteBuying: OnPiece = proc (piece: var Piece, b: var ChessBoard, s: var BoardState) =
    piece.promote(b, s)
    let captureMove = piece.moves
    let captureTake = piece.takes
    let turnOfPromote = s.shared.turnNumber
    var release = false
    piece.moves = @[]
    piece.takes = @[]
    piece.promoted = true

    piece.onEndTurn &= 
        proc (piece: var Piece, board: var ChessBoard, state: var BoardState) =
            if state.shared.turnNumber != turnOfPromote and not release:
                piece.moves &= captureMove
                piece.takes &= captureTake
                release = true

const promoteBuyingCondition: BuyCondition = func (piece: Piece, board: ChessBoard, s: BoardState): bool =
    return not piece.promoted and piece.onPromote != @[defaultOnEndTurn]

#this is attatched to the King, which tracks all piecesTaken
#I originally had it on each piece, but then I would have to add it to each new piece
proc moneyForTake(): OnPiece = 
    var lastPiecesTaken = 0
    #closure is used to hold state
    #this is preferable when state does not need to interact with the rest of the game's systems
    #to better modularize the power's state, I think
    result = proc (piece: var Piece, b: var ChessBoard, state: var BoardState) =
        var allPiecesTaken = 0
        for i, j in b.rankAndFile:
            if b[i][j].sameColor(piece):
                allPiecesTaken += b[i][j].piecesTaken

        allPiecesTaken += state.side[piece.color].abilityTakes #includes takes which are not by any piece

        if allPiecesTaken > lastPiecesTaken:
            addMoney(piece.color, 3, state)
        lastPiecesTaken = allPiecesTaken

const capitalismPower*: Power = Power(
    name: "Capitalism",
    tier: Uncommon,
    rarity: 24,
    priority: 30,
    description: """The power of the free market is unmatched. 
                    All of your pieces get the ability to buy upgrades. 
                    You get 3 dollars for taking a piece.
                    With 30 dollars, you can promote one piece. The promoted piece cannot move on the turn it is promoted.""",
    icon: "usflag.svg",
    noColor: true,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            s.side[side].buys &= (name: "Promote", cost: alwaysCost(30), action: promoteBuying, condition: promoteBuyingCondition)
            side.initWallet(s)
            for i, j in b.rankAndFile:
                if b[i][j].item == King and b[i][j].color == side: 
                    b[i][j].onEndTurn &= moneyForTake()
                    

)

#helper function to create capitalism powers, since they need to be synergies to ensure use has money
proc createCapitalism(power: Power, rarity: int = 24, requirements: seq[string] = @[], replacements: seq[string] = @[]): Synergy =
        return (
            power: power,
            rarity: rarity,
            requirements: @[capitalismPower.name] & requirements,
            replacements: replacements,
            index: -1
        )

const whiteMoveUp: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) = 
    piece.move(tileAbove(piece.tile), board, state)
    board[piece.tile.tileAbove.rank][piece.tile.file].endTurn(board, state) #piece changes after move, so we onEndTurn on where it should be    

const whiteMoveUpCondition: BuyCondition = func (piece: Piece, board: ChessBoard, s: BoardState): bool = 
    return piece.tile.rank != 0 and board[piece.tile.tileAbove.rank][piece.tile.file].isAir

const blackMoveUp: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) = 
    piece.move(tileBelow(piece.tile), board, state)
    board[piece.tile.tileBelow.rank][piece.tile.file].endTurn(board, state) #piece changes after move, so we onEndTurn on where it should be    

const blackMoveUpCondition: BuyCondition = func (piece: Piece, board: ChessBoard, s: BoardState): bool = 
    return piece.tile.rank != 7 and board[piece.tile.tileBelow.rank][piece.tile.file].isAir

const moveUp*: Power = Power(
    name: "Capitalism II",
    technicalName: "Capitalism: Move Up",
    tier: Common,
    rarity: 0,
    priority: 15,
    description: """Money is pretty neat right? You can spend 8 dollars to move a piece one tile forward. It cannot take with this action.""",
    icon: "usflag.svg",
    noColor: true,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            if side == black:
                s.side[side].buys &= (name: "Move Up", cost: alwaysCost(7), action: blackMoveUp, condition: blackMoveUpCondition)
            else:
                s.side[side].buys &= (name: "Move Up", cost: alwaysCost(7), action: whiteMoveUp, condition: whiteMoveUpCondition)
)

const capitalismTwo1: Synergy = createCapitalism(moveUp)

#I'm feeling explicit today so I'm giving proper names
#instead of just giving the blackMoveUp to white
const whiteMoveBack = blackMoveUp
const whiteMoveBackConditions = blackMoveUpCondition
const blackMoveBack = whiteMoveUp
const blackMoveBackCondition = whiteMoveUpCondition

const moveBack*: Power = Power(
    name: "Capitalism II",
    technicalName: "Capitalism: Move Back",
    tier: Common,
    rarity: 0,
    priority: 15,
    description: """Money is pretty neat right? You can spend 7 dollars to move a piece one tile backwards. It cannot take with this action.""",
    icon: "usflag.svg",
    noColor: true,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            if side == black:
                s.side[side].buys &= (name: "Move Back", cost: alwaysCost(7), action: blackMoveBack, condition: blackMoveBackCondition)
            else:
                s.side[side].buys &= (name: "Move Back", cost: alwaysCost(7), action: whiteMoveBack, condition: whiteMoveBackConditions)
)

const capitalismTwo2: Synergy = createCapitalism(moveBack)

const income*: Power = Power(
    name: "Capitalism II",
    technicalName: "Capitalism: Income",
    tier: Common,
    rarity: 0,
    priority: 35,
    description: """Here, have 10 dollars""",
    icon: "usflag.svg",
    noColor: true,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            addMoney(side, 10, s)
)

const capitalismTwo3: Synergy = createCapitalism(income)

const upgrade*: Power = Power(
    name: "Capitalism III",
    technicalName: "Capitalism: Upgrade Knight",
    tier: Uncommon,
    rarity: 0, #rarity 0 because it should only be gotten through synergy
    priority: 15,
    description: """Money can be used in exchange for goods and services. You can spend 8 dollars to give a piece the movement of a knight.
                    This upgrade is 30 dollars more expensive for the king. The upgraded piece still cannot take like a knight.""",
    icon: "usflag.svg",
    noColor: true,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            let action = buyMoveUpgrade(knightMoves)
            let condition = buyMoveUpgradeCondition(knightMoves)
            s.side[side].buys &= (name: "Upgrade", cost: exceptCost(8, King, 38), action: action, condition: condition)
)

const capitalismThree1: Synergy = createCapitalism(upgrade)

const upgrade2*: Power = Power(
    name: "Capitalism III",
    technicalName: "Capitalism: Upgrade Giraffe",
    tier: Uncommon,
    rarity: 0, #rarity 0 because it should only be gotten through synergy
    priority: 15,
    description: """Money can be used in exchange for goods and services. You can spend 8 dollars to give a piece the movement of a knight. 
                    This upgrade is 30 dollars more expensive for the king. The upgraded piece still cannot take like a giraffe.""",
    icon: "usflag.svg",
    noColor: true,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            let action = buyMoveUpgrade(giraffeMoves)
            let condition = buyMoveUpgradeCondition(giraffeMoves)
            s.side[side].buys &= (name: "Upgrade", cost: exceptCost(8, King, 38), action: action, condition: condition)
)

const capitalismThree2: Synergy = createCapitalism(upgrade2)


const sellPiece: OnPiece = proc (piece: var Piece, b: var ChessBoard, state: var BoardState) =
    b[piece.tile.rank][piece.tile.file] = air.pieceCopy(index = b[piece.tile.rank][piece.tile.file].index, tile = piece.tile)
    inc state.side[piece.color].piecesSold

const notKing: BuyCondition = func (piece: Piece, board: ChessBoard, s: BoardState): bool = 
    return piece.item != King

proc createPieceMarket(cost: int, rate: int): BuyCost =
    var lastTurnSold = -1
    var lastPiecesSold = 0

    result = func (piece: Piece, b: ChessBoard, s: BoardState): int =
        let piecesSold = s.side[piece.color].piecesSold
        if s.shared.turnNumber != lastTurnSold:
            lastTurnSold = s.shared.turnNumber
            lastPiecesSold = piecesSold

        result = cost + (rate * (lastPiecesSold - piecesSold))

#TODO constraint
const sell*: Power = Power(
    name: "Capitalism IV",
    technicalName: "Capitalism: Sell",
    tier: Uncommon,
    rarity: 0, #rarity 0 because it should only be gotten through synergy
    priority: 15,
    description: """Who needs these pieces? AFUERA! You can sell a piece for 3 dollars. Each subsequent piece sold gives one less. """,
    icon: "usflag.svg",
    noColor: true,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            s.side[side].buys &= (name: "Sell", cost: createPieceMarket(-3, -1), action: sellPiece, condition: notKing)
)

const capitalismFour1: Synergy = createCapitalism(sell)

#altered `createLottery()`, but also adds 10 dollars to King's wallet
proc createSuperLottery(): OnPiece = 
    var lastTimesMoved = 0
    #closure is used to hold state
    #this is preferable when state does not need to interact with the rest of the game's systems
    #to better modularize the power's state, I think
    #`Piece.rand` powers can't do this because it needs the seed, and a global clear of drunkenness
    #which has to happen after all `Piece.onEndTurn` stuff, not during
    result = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) =
        if piece.timesMoved != lastTimesMoved:
            randomize(10 * piece.tile.rank + 100 * piece.tile.file + state.shared.randSeed)
            let ticket = rand(100)
            if ticket == 42: #arbitrary
                addMoney(piece.color, 10, state)
                piece.promote(board, state)
        lastTimesMoved = piece.timesMoved

const slumdogBillionairePower*: Power = Power(
    name: "Slumdog Billionaire",
    tier: Common,
    rarity: 0,
    priority: 15,
    description: """Have you seen the movie Slumdog Millionaire? It's kind of like that but more. 
                    Your pawns have a 2% chance of promoting whenever they move. When this happens, you get 10 dollars.""",
    icon: pawnIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Pawn and b[i][j].isColor(side):
                    b[i][j].onEndTurn &= createSuperLottery()
)

const slumdogBillionaire: Synergy = createCapitalism(slumdogBillionairePower, 8, @[slumdogMillionaire.name], @[slumdogMillionaire.name])

const exponentialGrowthOnEndTurn: OnPiece = proc (piece: var Piece, _: var ChessBoard, state: var BoardState) =
    let currentMoney = getMoney(piece.color, state)
    let next = currentMoney * 2 - currentMoney #I want it to double, but not sum of doubling. 
    addMoney(piece.color, next, state)

const exponentialGrowth*: Power = Power(
    name: "Capitalism MM",
    tier: UltraRare, 
    rarity: 0,
    priority: 15,
    description: "TO THE MOON!!!!",
    icon: "usflag.svg",
    noColor: true,
    onStart:  
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == King and b[i][j].isColor(side):
                    b[i][j].onEndTurn &= exponentialGrowthOnEndTurn
)

const capitalismTwoThousand: Synergy = (
    power: exponentialGrowth,
    rarity: 16,
    requirements: @[capitalismPower.name, capitalismTwo2.power.name, capitalismThree1.power.name, capitalismFour1.power.name],
    replacements: @[],
    index: -1
)

const canSkyGlass: GlassMoves = 
    func (side: Color, piece: Piece, b: ChessBoard, _: BoardState): Moves =
        if piece.color != side: return @[]
        else: 
            for tile in b.rankAndFile:
                if b[tile].item == None and not piece.wouldCheckAt(tile, b):
                    result.add(tile)


const skyGlassAction: OnAction = proc (piece: var Piece, to: Tile, b: var ChessBoard, s: var BoardState) = 
    #this is not in the condition because it can change after
    #but it should still be a viable attempt before
    if b[to.rank][to.file].item != None: return
    piece.move(to, b, s)

const canZeroGlass: GlassMoves = 
    func (side: Color, piece: Piece, b: ChessBoard, s: BoardState): Moves =
        if s.shared.turnNumber == 0: return @[]

        for i, j in b.rankAndFile:
            if b[i][j].item != King:
                result.add(b[i][j].tile)

#we use a proc creator because we need to pass the side that has the ability
#since I want it to work on all pieces (which means we can't assume color)
#I could just make it not count towards taking, but I love overcomplicated systems
proc createZeroGlassAction(side: Color): OnAction = 
    result = proc (_: var Piece, to: Tile, b: var ChessBoard, s: var BoardState) = 
        if b[to.rank][to.file].item == None: return
        b[to.rank][to.file] = air.pieceCopy(index = b[to].index, tile = to)
        inc s.side[side].abilityTakes

const canSteelGlass: GlassMoves = 
    func (side: Color, piece: Piece, b: ChessBoard, _: BoardState): Moves =
        if not piece.isAtEnd():
            if piece.color == white:
                return @[piece.tile.tileAbove]
            else:
                return @[piece.tile.tileBelow]
        else: return @[]

const steelGlassAction: OnAction = proc (piece: var Piece, to: Tile, b: var ChessBoard, s: var BoardState) = 
    #this is not in the condition because it can change after
    #but it should still be a viable attempt before
    if b[to.rank][to.file].item == None: return
    piece.take(to, b, s)

#helper function to create  the "On Glass Powers" part
#so that I can just update it here
#which i will need to do because it doesn't make sense
#strength indicates how many pieces the power works for
proc createGlassDescription(): string = 
    return """Glass powers take one turn to start casting, one turn waiting to draw glass power, and one turn when the cast completes."""

const skyGlass*: Power = Power(
    name: "Glass: Sky",
    tier: Uncommon,
    rarity: 6, 
    priority: 15,
    description: """On your turn, instead of moving, you can choose 2 pieces to each cast Sky on any 
                    open tile. These pieces teleport to their selected tile when the cast completes. 
                    Pieces cannot try to teleport to a tile where they would check the king. """ & createGlassDescription(),
    icon: "skyglass.svg",
    noColor: true,
    onStart: 
        proc (side: Color, _: Color, _: var ChessBoard, s: var BoardState) = 
            s.side[side].glass[Sky] = some((
                strength: 2,
                action: skyGlassAction,
                condition: canSkyGlass,
            ))
)

const zeroGlass*: Power = Power(
    name: "Glass: Zero",
    tier: Rare,
    rarity: 6,
    priority: 15,
    description: """On your turn, instead of moving, you can choose 2 pieces to each cast Zero on  
                    any non-king tile. Any piece on these tiles will die if the cast completes. Zero cannot be cast turn one. """ &
                    createGlassDescription(),
    icon: "zeroglass.svg",
    noColor: true,
    onStart: 
        proc (side: Color, _: Color, _: var ChessBoard, s: var BoardState) = 
            s.side[side].glass[Zero] = some((
                strength: 2,
                action: createZeroGlassAction(side),
                condition: canZeroGlass,
            ))
)

const steelMove: OnPiece = proc (piece: var Piece, _: var ChessBoard, state: var BoardState) = 
    #i'm not sure how to iterate a variable
    for i, c in piece.casts:
        if c.glass == Steel:
            piece.casts[i].on = piece.forward()

const steelGlass*: Power = Power(
    name: "Glass: Steel",
    tier: Common,
    rarity: 6,
    priority: 15,
    description: """On your turn, instead of moving, you can choose 5 pieces to each cast Steel. 
                    If there is an enemy one tile in front of them when the cast completes, they take forward. """ &
                    createGlassDescription(),
    icon: "steelglass.svg",
    noColor: true,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            s.side[side].glass[Steel] = some((
                strength: 5,
                action: steelGlassAction,
                condition: canSteelGlass,
            ))

            for i, j in b.rankAndFile:
                if b[i][j].isColor(side):
                    b[i][j].onEndTurn &= steelMove
)

const divineMove: OnPiece = proc (piece: var Piece, b: var ChessBoard, state: var BoardState) = 
    randomize(state.shared.randSeed)

    #I split this in two to avoid insane tabbing
    for i, j in b.rankAndFile:
        if Sky in b[i][j].casts.mapIt(it.glass):
            piece.take(piece.getTakesOn(b).sample(), b, state)
            break
        

const divineWindPower*: Power = Power(
    name: "Divine Wind",
    tier: Uncommon,
    priority: 15,
    description: """The divine wind briskly brushes your back. Your lances will take forward while sky is casting.""",
    icon: "lance.svg",
    noColor: true,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].isColor(side) and b[i][j].filePath.contains("lance"): #since namesystem is not done yet, this is a cheeky way to find lances
                    b[i][j].onEndTurn &= divineMove


)

const divineWind: Synergy = (
    power: divineWindPower,
    rarity: 12,
    requirements: @[skyGlass.name, lanceLeft.name],
    replacements: @[],
    index: -1
)

const canBankruptGlass: GlassMoves = 
    func (side: Color, piece: Piece, b: ChessBoard, s: BoardState): Moves =
        assert s.side[side].wallet.isSome()
        
        #can only do it when money is 0
        if s.shared.turnNumber == 0 or 
             s.side[side].wallet.get() != 0 : return @[]

        for i, j in b.rankAndFile:
            if b[i][j].item != King:
                result.add(b[i][j].tile)

const bankruptGlassPower*: Power = Power(
    name: "Glass: Bankruptcy",
    tier: Rare,
    rarity: 6, #while new
    priority: 0,
    description: """On your turn, if you have only 0 dollars, instead of moving you can choose 3 pieces to each cast Bankruptcy on  
                    any non-king tiles. Any piece on these tiles will die if the cast completes. Bankruptcy cannot be cast turn one. """ &
                    createGlassDescription(),
    icon: "zeroglass.svg",
    noColor: true,
    onStart: 
        proc (side: Color, _: Color, _: var ChessBoard, s: var BoardState) = 
            s.side[side].glass[Zero] = some((
                strength: 3,
                action: createZeroGlassAction(side),
                condition: canBankruptGlass,
            ))
)

const bankruptcyGlass: Synergy = (
    power: bankruptGlassPower,
    rarity: 8,
    requirements: @[zeroGlass.name, capitalismPower.name],
    replacements: @[zeroGlass.name],
    index: -1
)

const canReverieGlass: GlassMoves = 
    func (side: Color, piece: Piece, b: ChessBoard, s: BoardState): Moves =
        for i, j in b.rankAndFile:
            if b[i][j].item != King and not b[i][j].isAir():
                result.add(b[i][j].tile)

const reverieGlassAction: OnAction = proc (piece: var Piece, to: Tile, b: var ChessBoard, s: var BoardState) = 
    if b[to].isAir or b[to].item == King or piece.item == King: return

    randomize(s.shared.randSeed + piece.tile.rank * 10 + piece.tile.file * 100)

    var allMoves = piece.moves & b[to].moves
    var allTakes = piece.takes & b[to].takes

    allMoves.shuffle()
    allTakes.shuffle()

    let casterMoves = piece.moves.len
    let casterTakes = piece.takes.len

    #shuffles and returns slices, with the same size to ensure they technically have the same moves
    #though a move could be doubled up
    piece.moves = allMoves[0..<casterMoves]
    b[to].moves = allMoves[casterMoves..^1]
    piece.takes = allTakes[0..<casterTakes]
    b[to].takes = allTakes[casterTakes..^1]

const reverieGlass*: Power = Power(
    name: "Glass: Reverie",
    tier: Common,
    rarity: 6, #while new
    priority: 0,
    description: """On your turn, instead of moving you can choose 3 pieces to each cast Reverie on 
                    an opponent tile. When the cast completes, 
                    they swap moves and takes with whatever piece is on that tile. If that piece 
                    is a king, the cast fails. """ &
                    createGlassDescription(),
    icon: "reverieglass.svg",
    noColor: true,
    onStart: 
        proc (side: Color, _: Color, _: var ChessBoard, s: var BoardState) = 
            s.side[side].glass[Reverie] = some((
                strength: 3,
                action: reverieGlassAction,
                condition: canReverieGlass,
            ))
)

registerPower(empress)
registerPower(altEmpress)
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
registerPower(werewolves)
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
registerPower(drunkKnights)
registerPower(alcoholism)
#registerPower(civilians)
registerPower(slumdogMillionaire)
registerPower(stupidPower)
registerPower(conversion)
registerPower(americanDream)
registerPower(sleeperAgent)
registerPower(capitalismPower)

registerPower(skyGlass)
registerPower(zeroGlass)
registerSynergy(bankruptcyGlass)
registerPower(steelGlass)
registerPower(reverieGlass)

registerSynergy(samuraiSynergy)
registerSynergy(calvaryCharge)
registerSynergy(differentGame)
registerSynergy(linebackers)
registerSynergy(holyBishop)
registerSynergy(bountyHunter)
registerSynergy(holyConversion)
registerSynergy(divineWind)
registerSynergy(exodia, true)
registerSynergy(altExodia, true)
registerSynergy(superPawn, true)
registerSynergy(queensWrath, true)
registerSynergy(queensWrath2, true)
registerSynergy(battleFormation, true)
registerSynergy(queensWrathSuper, true)
registerSynergy(calvaryGiraffe, true) #both of these would be secret synergies
registerSynergy(lesbianBountyHunter, true) #but flavor text is fun
registerSynergy(drunkNightRider, true)
registerSynergy(drunkNightRider2, true)

registerSynergy(capitalismTwo1)
registerSynergy(capitalismTwo2)
registerSynergy(capitalismTwo3)
registerSynergy(capitalismThree1)
registerSynergy(capitalismThree2)
registerSynergy(capitalismFour1)
registerSynergy(capitalismTwoThousand, true)
registerSynergy(slumdogBillionaire, true)

registerSynergy(virus, true)
registerSynergy(virus2, true)
registerSynergy(virus3, true)
registerSynergy(virus4, true)
registerSynergy(virus5, true)
registerSynergy(virus6, true)
registerSynergy(virus7, true)

registerSynergy(masochistEmpress, true, true)
registerSynergy(masochistAltEmpress, true, true)

#All powers with rng involved
#so user can disable them if they want
const rngPowers* = @[alcoholism, drunkKnights, civilians, slumdogMillionaire, stupidPower, sleeperAgent, conversion]
const experimentalPowers* = @[skyGlass, zeroGlass, steelGlass, reverieGlass]