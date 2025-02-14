import power, moves, piece, basePieces, extraMoves, board
from extrapower / glass import isCasting
import extrapower/capitalism
from extrapower/status import freeze
import std/options
from sequtils import filterIt, mapIt, concat
from strutils import contains
from random import sample, rand, randomize, shuffle

#[TODO
--(no)--create synergy constructor which automatically sets index to -1
--(no)--or maybe just make it an object, since I don't think performance has ever mattered for this
--or remove `Synergy.index`, since I'm honestly not sure what it does
powers are exported for debug, so remove that eventually

Create secret secret synergy for bombard + reinforcements
--Add alternative exodia for alternative empress

Vampires - can only be taken by bishop
Headless Horseman - 
Rodeo Knights - pawn spawn when knight is killed
Devil Pawns - cannot be promoted
Holy war - 15% to convert when taken
Gremlins - split 
famine - kills 50% of pawns
pawnpacalps - kills pieces besides pawn, spawns 2 every turn
Make move up and move down cost more if doing so would put the king into checkmate



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
    TLDR: Normal / Draft Synergies must be drafted seperately
          Secret Synergies are automatically added when the game starts
          Secret Secret Synergies are like Secret Synergies, but they are completely hidden to the user
            These are meant to be used as bandages for when powers conflict

    Normal / Draft Synergies - 
        if the drafter has all of its `Synergy.requirements`, then `Synergy.Power` become available.
            with a rarity of `Synergy.rarity`. -- TODO: CHECK IF THIS IS TRUE: If picked, the users powers in `Synergy.requirements` are removed. 
        The drafter than has to find and draft it.
        The description of `Synergy.power` is automatically updated to say "Synergy (list of synergies)"
    Secret Synergies - 
        if the drafter has all of its `Synergy.requirements`, then when the game starts, `Synergy.replacements` is 
            automatically replaced with `Synergy.power`
        The description of `Synergy.power` is automatically updated to say "Secret Synergy (list of synergies)"
    Secret Secret Synergies - 
        if the drafter has all of its `Synergy.requirements`, then when the game starts, `Synergy.replacements` is 
            automatically replaced with `Synergy.power`
        The drafter has no choice, these are automatically added

    Synergies take the `Power.priority` of `Synergy.power`
]#

#default paths for the main pieces
const kingIcon: string = "king.svg"
const queenIcon: string = "queen.svg"
const rookIcon: string = "rook.svg"
const bishopIcon: string = "bishop.svg"
const knightIcon: string = "knight.svg"
const pawnIcon: string = "pawn.svg"

#This proc should be used when buffing all pieces of one type
#it also buffs dna prototype for cleaner code.
proc buff(piece: PieceType, side: Color, b: var ChessBoard, s: var BoardState, 
    moves: seq[MoveProc] = @[], takes: seq[MoveProc] = @[], onEndturn: seq[OnPiece] = @[],
    rotate: bool = false, promoted: bool = false,
    onPromote: seq[OnPiece] = @[], whenTaken: WhenTaken = nil, onTake: OnAction = nil,
    onMove: OnAction = nil) = 
        for i, j in b.rankAndFile:
            if b[i][j].item == piece and b[i][j].isColor(side):
                b[i][j].moves &= moves
                b[i][j].takes &= takes
                b[i][j].onEndTurn &= onEndTurn
                b[i][j].onPromote &= onPromote
                if not whenTaken.isNil: b[i][j].whenTaken = whenTaken
                if not onTake.isNil: b[i][j].onTake = onTake
                if not onMove.isNil: b[i][j].onMove = onMove
                if rotate: b[i][j].rotate = true
                if promoted: b[i][j].promoted = true

        s.side[side].dna[piece].moves &= moves
        s.side[side].dna[piece].takes &= takes
        s.side[side].dna[piece].onEndTurn &= onEndTurn
        s.side[side].dna[piece].onPromote &= onPromote
        if rotate: s.side[side].dna[piece].rotate = true
        if promoted: s.side[side].dna[piece].promoted = true
        if not whenTaken.isNil: s.side[side].dna[piece].whenTaken = whenTaken
        if not onTake.isNil: s.side[side].dna[piece].onTake = onTake
        if not onMove.isNil: s.side[side].dna[piece].onMove = onMove

#This proc should be used when to change a piece
#it overwrites previous moves
proc change(piece: PieceType, side: Color, b: var ChessBoard, s: var BoardState, 
    moves: seq[MoveProc] = @[], takes: seq[MoveProc] = @[], onEndturn: seq[OnPiece] = @[],
    rotate: bool = false, promoted: bool = true, #I'm just going to make it that you can only set this to true
    onPromote: seq[OnPiece] = @[], whenTaken: WhenTaken = nil, onTake: OnAction = nil,
    onMove: OnAction = nil, filePath: string = "") = 
        for i, j in b.rankAndFile:
            if b[i][j].item == piece and b[i][j].isColor(side):
                if moves.len != 0: b[i][j].moves = moves
                if takes.len != 0: b[i][j].takes = takes
                if onEndturn.len != 0: b[i][j].onEndTurn = onEndturn
                if onPromote.len != 0: b[i][j].onPromote = onPromote
                if not whenTaken.isNil: b[i][j].whenTaken = whenTaken
                if not onTake.isNil: b[i][j].onTake = onTake
                if not onMove.isNil: b[i][j].onMove = onMove
                if filePath != "": b[i][j].filePath = filePath
                if rotate: b[i][j].rotate = true
                if promoted: b[i][j].promoted = true

        if moves.len != 0: s.side[side].dna[piece].moves = moves
        if takes.len != 0: s.side[side].dna[piece].takes = takes
        if onEndTurn.len != 0: s.side[side].dna[piece].onEndTurn = onEndTurn
        if onPromote.len != 0: s.side[side].dna[piece].onPromote = onPromote
        if filePath != "": s.side[side].dna[piece].filePath = filePath
        if rotate: s.side[side].dna[piece].rotate = true
        if promoted: s.side[side].dna[piece].promoted = true
        if not whenTaken.isNil: s.side[side].dna[piece].whenTaken = whenTaken
        if not onTake.isNil: s.side[side].dna[piece].onTake = onTake
        if not onMove.isNil: s.side[side].dna[piece].onMove = onMove

const empress*: Power = Power(
    name: "Empress",
    tier: Uncommon,
    priority: 15,
    description: "Your queen ascends, gaining the movement of a standard knight. ",
    tags: @[Queen, Virus],
    icon: queenIcon,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            Queen.buff(side, b, s, 
                moves = @[knightMoves],
                takes = @[knightTakes]
            )
)

const altEmpress*: Power = Power(
    name: "Empress",
    technicalName: "Alternate Empress",
    tier: Uncommon,
    priority: 15,
    rarity: 4, #slightly less common, cuz
    description: "Your queen ascends, gaining the movement of a giraffe. ",
    tags: @[Queen, Virus],
    icon: queenIcon,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            Queen.buff(side, b, s, 
                moves = @[giraffeMoves],
                takes = @[giraffeTakes]
            )
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
    tags: @[Control, Virus],
    icon: "silvergeneral.svg",
    rotatable: true,
    noColor: true,
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            let rank = if side == black: 1 else: 6
            let file = if side == black: 6 else: 1
            assert b[rank][file].color == side
            if side == black:
                b[rank][file].moves = @[diagnalMoves, blackForwardMoves]
                b[rank][file].takes = @[diagnalTakes, blackForwardTakes]
            else:
                b[rank][file].moves = @[diagnalMoves, whiteForwardMoves]
                b[rank][file].takes = @[diagnalTakes, whiteForwardTakes]
            b[rank][file].onEndTurn = @[silverGeneralPromoteConditions]
            b[rank][file].onPromote = @[silverGeneralPromote]
            b[rank][file].item = Fairy
            b[rank][file].filePath = "silvergeneral.svg"
            b[rank][file].colorable = false
            if side != viewSide: b[rank][file].rotate = true
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
    tags: @[Control],
    icon: "silvergeneral.svg",
    rotatable: true,
    noColor: true,
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            let rank = if side == black: 1 else: 6
            let file = if side == black: 1 else: 6
            assert b[rank][file].color == side
            if side == black:
                b[rank][file].moves = @[diagnalMoves, blackForwardMoves]
                b[rank][file].takes = @[diagnalTakes, blackForwardTakes]
            else:
                b[rank][file].moves = @[diagnalMoves, whiteForwardMoves]
                b[rank][file].takes = @[diagnalTakes, whiteForwardTakes]
            b[rank][file].onEndTurn = @[silverGeneralPromoteConditions]
            b[rank][file].onPromote = @[silverGeneralPromote]
            b[rank][file].item = Fairy
            b[rank][file].filePath = "silvergeneral.svg"
            b[rank][file].colorable = false
            if side != viewSide: b[rank][file].rotate = true
)

const developed*: Power = Power(
    name: "Developed",
    tier: Common,
    priority: 20, 
    description: 
        """Your board arrives a little developed. Your 2 center pawns start one tile forward. 
        They can still move up 2 for their first move.""",
    tags: @[Develop, Virus],
    icon: pawnIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            #TODO: fix hard coded moves to prevent conflict. 
            #fix would just stop move attempt if it would kill a piece
            if side == black:
                if b[1][3].item == Pawn and b[2][3].item == None:
                    b[1][3].pieceMove(2, 3, b, s)
                if b[1][4].item == Pawn and b[2][4].item == None:
                    b[1][4].pieceMove(2, 4, b, s)
            elif side == white:
                if b[6][3].item == Pawn and b[5][3].item == None:
                    b[6][3].pieceMove(5, 3, b, s)
                if b[6][4].item == Pawn and b[5][4].item == None:
                    b[6][4].pieceMove(5, 4, b, s)         
)

const stepOnMe*: Power = Power(
    name: "Step on me",
    tier: Common,
    priority: 15, 
    description:
        """Your Queen can take your own pieces. It's literally useless, but if that's your thing...""",
    tags: @[Take, Queen, Push, Virus],
    icon: queenIcon,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            Queen.buff(side, b, s, 
                takes = @[cannibalBishopTakes, cannibalKingTakes, cannibalRookTakes]
            )
)

const illegalFormationRL: Power = Power(
    name: "Illegal Formation", 
    technicalName: "Illegal Formation Left Rook",
    tier: Common, 
    rarity: 2,
    priority: 20,
    description: 
        """ILLEGAL FORMATION: YOUR PAWN ABOVE YOUR LEFT ROOK SWAPS PLACES WITH YOUR LEFT ROOK""",
    tags: @[Develop, Rook],
    icon: rookIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            let rank = if side == black: 0 else: 6
            let file = if side == black: 7 else: 0
            pieceSwap(b[rank][file], b[rank + 1][file], b)
)

const illegalFormationRR: Power = Power(
    name: "Illegal Formation", 
    technicalName: "Illegal Formation Right Rook",
    tier: Common, 
    rarity: 2,
    priority: 20,
    description: 
        """ILLEGAL FORMATION: YOUR PAWN ABOVE YOUR RIGHT ROOK SWAPS PLACES WITH YOUR RIGHT ROOK""",
    tags: @[Develop, Rook],
    icon: rookIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            let rank = if side == black: 0 else: 6
            let file = if side == black: 0 else: 7
            pieceSwap(b[rank][file], b[rank + 1][file], b)

)

const illegalFormationBL*: Power = Power(
    name: "Illegal Formation", 
    technicalName: "Illegal Formation Left Bishop",
    tier: Common, 
    rarity: 2,
    priority: 20,
    description: 
        """ILLEGAL FORMATION: YOUR PAWN ABOVE YOUR LEFT BISHOP SWAPS PLACES WITH YOUR LEFT BISHOP""",
    tags: @[Develop, Bishop],
    icon: bishopIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            let rank = if side == black: 0 else: 6
            let file = if side == black: 5 else: 2
            pieceSwap(b[rank][file], b[rank + 1][file], b)
)

const illegalFormationBR: Power = Power(
    name: "Illegal Formation", 
    technicalName: "Illegal Formation Right Bishop",
    tier: Common, 
    rarity: 2,
    priority: 20,
    description: 
        """ILLEGAL FORMATION: YOUR PAWN ABOVE YOUR RIGHT BISHOP SWAPS PLACES WITH YOUR RIGHT BISHOP""",
    tags: @[Develop, Bishop, Virus],
    icon: bishopIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            let rank = if side == black: 0 else: 6
            let file = if side == black: 2 else: 5
            pieceSwap(b[rank][file], b[rank + 1][file], b)
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
    tags: @[Pawn, Promote],
    icon: pawnIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            Pawn.buff(side, b, s, 
                onEndTurn = @[putInTheWorkCondition]
            )

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
    tags: @[Control],
    icon: "goldgeneral.svg",
    rotatable: true,
    noColor: true,
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) =
            let rank = if side == black: 1 else: 6
            let file = if side == black: 5 else: 2
            assert b[rank][file].color == side
            if side == black:
                b[rank][file].moves = @[diagnalMoves, blackForwardMoves, leftRightMoves]
                b[rank][file].takes = @[diagnalTakes, blackForwardTakes, leftRightTakes]
            else:
                b[rank][file].moves = @[diagnalMoves, whiteForwardMoves, leftRightMoves]
                b[rank][file].takes = @[diagnalTakes, whiteForwardTakes, leftRightTakes]             
            b[rank][file].onPromote = @[defaultOnEndTurn]    #Gold generals do not promote
            b[rank][file].item = Fairy
            b[rank][file].filePath = "goldgeneral.svg"
            b[rank][file].colorable = false
            if side != viewSide: b[rank][file].rotate = true
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
    tags: @[Control],
    icon: "goldgeneral.svg",
    rotatable: true,
    noColor: true,
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            let rank = if side == black: 1 else: 6
            let file = if side == black: 2 else: 5
            assert b[rank][file].color == side
            if side == black:
                b[rank][file].moves = @[diagnalMoves, blackForwardMoves, leftRightMoves]
                b[rank][file].takes = @[diagnalTakes, blackForwardTakes, leftRightTakes]
            else:
                b[rank][file].moves = @[diagnalMoves, whiteForwardMoves, leftRightMoves]
                b[rank][file].takes = @[diagnalTakes, whiteForwardTakes, leftRightTakes]             
            b[rank][file].onPromote = @[defaultOnEndTurn]    #Gold generals do not promote
            b[rank][file].item = Fairy
            b[rank][file].filePath = "goldgeneral.svg"
            b[rank][file].colorable = false
            if side != viewSide: b[rank][file].rotate = true
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
    tags: @[Pawn, Push, Virus],
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
    tags: @[Bishop],
    icon: bishopIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            Bishop.buff(side, b, s, 
                moves = @[knightMoves],
                takes = @[knightTakes]
            )    
)

const giraffe*: Power = Power(
    name: "Giraffe",
    tier: Uncommon,
    priority: 5, 
    description:
        """Your knights try riding giraffes. It works surprisingly well. Their leap is improved, moving 3 across instead of 2 across.""",
    tags: @[Knight, Push, Virus],
    icon: "giraffe.svg",
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            Knight.change(side, b, s,
                moves = @[giraffeMoves],
                takes = @[giraffeTakes],
                filePath = "giraffe.svg"
            )
)

const calvary*: Power = Power(
    name: "Calvary",
    tier: Uncommon,
    priority: 15,
    description: 
        """Your knights learn to ride forward. They aren't very good at it, but they're trying their best. 
            They can charge forward up to 2 tiles, but only to take a piece. They cannot jump for this move.""",
    tags: @[Knight, Push],
    icon: knightIcon,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            let addedTake = if side == white: whiteForwardTwiceTakes else: blackForwardTwiceTakes
            Knight.buff(side, b, s,
                takes = @[addedTake]
            )                       
)

const anime*: Power = Power(
    name: "Anime Battle",
    tier: Rare,
    priority: 5, 
    rarity: -999,
    description:
        """Your board is imbued with the power of anime. You feel a odd sense of regret. Or is it guilt?""",
    tags: @[Control, Control, Virus],
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
    replacements: @[mysteriousSwordsmanLeft.name, wanderingRoninLeft.name, mysteriousSwordsmanRight.name, wanderingRoninRight.name, anime.name]
)

const masochistEmpressPower: Power = Power(
    name: "Masochist Empress",
    tier: UltraRare,
    rarity: -999,
    priority: 15,
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard, s: var BoardState) = 
            let takes = s.side[side].dna[Queen].takes
            if knightTakes in takes:
                Queen.buff(side, b, s, 
                    takes = @[cannibalKnightTakes]
                )
            elif giraffeTakes in takes:
                Queen.buff(side, b, s, 
                    takes = @[cannibalGiraffeTakes]
                )
)

const masochistEmpress: Synergy = (
    power: masochistEmpressPower,
    rarity: -999,
    requirements: @[empress.name, stepOnMe.name],
    replacements: @[]
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
    rarity: -999, #get through tags instead, to make rarer
    priority: 25,
    description: """SACRIFICE THY MAIDENS TO THE BLOOD GOD""",
    tags: @[Special, Virus],
    icon: queenIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard, s: var BoardState) =
            Queen.buff(side, b, s,
                takes = @[takeSelf],
                whenTaken = sacrificeWhenTaken
            )
)

const backStep*: Power = Power(
    name: "Backstep",
    tier: Rare,
    priority: 15,
    description: "Your pawns receive some training. They can move one tile back. They cannot take this way.",
    tags: @[Pawn, Control, Virus],
    icon: pawnIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard, s: var BoardState) = 
            let addedMove = if side == black: blackBackwardMove else: whiteBackwardMove
            Pawn.buff(side, b, s, 
                moves = @[addedMove]
            )
)

const headStart*: Power = Power(
    name: "Headstart",
    tier: Uncommon,
    priority: 15,
    description: "Your pawns can always move 2 forward. They still take like normal. It's kind of boring, don't you think?",
    tags: @[Pawn, Push, Virus],
    icon: pawnIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard, s: var BoardState) = 
            let addedMove = if side == black: blackForwardTwiceMoves else: whiteForwardTwiceMoves
            Pawn.buff(side, b, s, 
                moves = @[addedMove]
            )
)

const queenTrade*: Power = Power(
    name: "Queen Trade",
    tier: Rare,
    priority: 20,
    description: "The patriarchy continues. Both queens mysteriously die.",
    tags: @[Trade, Trade],
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
    rarity: -999,
    priority: 15,
    description: "You have insane pawns. Please don't sacrifice them.",
    icon: pawnIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard, s: var BoardState) = 
            headStart.onStart(side, viewSide, b, s)
            backStep.onStart(side, viewSide, b, s)
            putInTheWork.onStart(side, viewSide, b, s)
            let addedMove = if side == black: blackForwardTwiceTakes else: whiteForwardTwiceTakes
            Pawn.buff(side, b, s, 
                takes = @[addedMove]
            )
)

const superPawn: Synergy = (
    power: superPawnPower,
    rarity: -999,
    requirements: @[backStep.name, headStart.name],
    replacements: @[backStep.name, headStart.name]    
)

const lesbianPride*: Power = Power(
    name: "Lesbian Pride",
    tier: UltraRare,
    rarity: 2,
    priority: 2,
    description: "🧡🤍🩷",
    tags: @[Queen, Special],
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
    rarity: -999,
    priority: 2,
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
    rarity: -999,
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
                    b[i][j] = air.pieceCopy(index = b[i][j].index, tile = b[i][j].tile)
                elif b[i][j].item == Queen and b[i][j].isColor(side):
                    b[i][j].moves &= @[knightMoves, giraffeMoves, whiteForwardTwiceJumpMove, blackForwardTwiceJumpMove]
                    b[i][j].takes &= @[knightTakes, giraffeTakes, whiteForwardTwiceJumpTake, blackForwardTwiceJumpTake]
                    b[i][j].item = King
                elif b[i][j].item == Bishop and not b[i][j].isColor(side):
                    b[i][j] = air.pieceCopy(index = b[i][j].index, tile = b[i][j].tile)
)

const queensWrath: Synergy = (
    power: queensWrathPower,
    rarity: -999,
    requirements: @[lesbianPride.name, queenTrade.name],
    replacements: @[lesbianPride.name]    
)

const queensWrath2: Synergy = (
    power: queensWrathPower,
    rarity: -999,
    requirements: @[lesbianPride.name, sacrifice.name],
    replacements: @[lesbianPride.name, sacrifice.name]    
)

const queensWrathAnti: AntiSynergy = (
    power: queensWrathPower,
    rarity: -999,
    drafterRequirements: @[lesbianPride.name],
    opponentRequirements: @[queenTrade.name] 
)

const queensWrathSuper: Synergy = (
    power: queensWrathSuperPower,
    rarity: -999,
    requirements: @[lesbianPride.name, queenTrade.name, sacrifice.name],
    replacements: @[lesbianPride.name, sacrifice.name]
)

const queensWrathSuperAnti: AntiSynergy = (
    power: queensWrathSuperPower,
    rarity: -999,
    drafterRequirements: @[lesbianPride.name, sacrifice.name],
    opponentRequirements: @[queenTrade.name] 
)


const knightChargePower*: Power = Power(
    name: "Knight's Charge",
    tier: Rare,
    rarity: 4,
    priority: 20,
    description: "CHARGE! Your knights start 3 tiles ahead.",
    tags: @[Develop, Push, Virus],
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
    replacements: @[]    
)

const battleFormationPower: Power = Power(
    name: "Battle Formation!",
    tier: UltraRare,
    rarity: -999,
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
    rarity: -999,
    requirements: @[knightChargePower.name, developed.name],
    replacements: @[developed.name]
)

const differentGamePower*: Power = Power(
    name: "Criminal Formation",
    tier: Common,
    rarity: -999,
    priority: 20,
    description: "I guess the rules didn't get to you. Your pawns above both knights and both rooks swap places with those pieces.",
    tags: @[Develop, Develop, Develop],
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
    rarity: 13,
    requirements: @[illegalFormationBR.name],
    replacements: @[illegalFormationBR.name]
)

const lineBackersPower: Power = Power(
    name: "Linebackers",
    tier: Rare,
    rarity: -999,
    priority: 15,
    description: "Your pawns learn to fight like men. They can take one spaces ahead too.",
    icon: pawnIcon,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard, s: var BoardState) = 
            let addedMove = if side == black: blackForwardTakes else: whiteForwardTakes
            Pawn.buff(side, b, s, 
                moves = @[addedMove]
            )
)

const linebackers: Synergy = (
    power: lineBackersPower,
    rarity: -999,
    requirements: @[putInTheWork.name, headStart.name],
    replacements: @[]
)

const nightRider: Power = Power(
    name: "Nightrider",
    tier: UltraRare,
    priority: 4,
    description: "Nightrider.",
    tags: @[NightRider],
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
    tags: @[Move, Bishop, Virus],
    icon: bishopIcon,
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard, s: var BoardState) = 
            Bishop.buff(side, b, s, 
                moves = @[leftRightMoves],
                takes = @[leftRightTakes]
            )
)

const holyBishopPower*: Power = Power(
    name: "Holy Bishops",
    tier: Rare,
    priority: 15,
    description: "God has blessed your bishops. ",
    tags: @[Move, Bishop, Bishop, Holy],
    icon: "cross.svg",
    noColor: true,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            Bishop.buff(side, b, s, 
                moves = @[knightMoves, blackForwardTwiceJumpMove, whiteForwardTwiceJumpMove],
                takes = @[knightTakes, blackForwardTwiceJumpTake, whiteForwardTwiceJumpTake]
            )
)

const holyBishop: Synergy = (
    power: holyBishopPower,
    rarity: 8,
    requirements: @[archBishops.name, holy.name],
    replacements: @[archBishops.name]
)

const concubineWhenTaken = 
    proc (taken: var Piece, taker: var Piece, board: var ChessBoard, state: var BoardState): tuple[endTile: Tile, takeSuccess: bool] =
        if taker.item == King and 
            taken.item == Rook and
            taken.sameColor(taker) and
            taker.timesMoved == 1 and #one move from castling
            taken.timesMoved == 0: 
                state.side[taken.color].hasCastled = true
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
    tags: @[Queen, UnHoly],
    icon: rookIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            Rook.buff(side, b, s,
                whenTaken = concubineWhenTaken,
                onPromote = @[onPawnPromote]
            )
)

const reinforcementsOntake: OnAction = proc (piece: var Piece, to: Tile, board: var ChessBoard, state: var BoardState) =
    let takeResults = to.takenBy(piece, board,state)
    let originalRookTile = piece.tile
    board[takeResults.endTile].timesMoved += 1

    if takeResults.takeSuccess:
        board[takeResults.endTile].piecesTaken += 1
        if board[takeResults.endTile].piecesTaken mod 2 == 0:
            board[originalRookTile] = 
                state.side[piece.color].dna[Pawn].pieceCopy(index = newIndex(state), tile = originalRookTile)

const reinforcements*: Power = Power(
    name: "Reinforcements",
    tier: Uncommon,
    priority: 25,
    description: "Do you really need more than 8 pawns? Your rooks spawn a pawn for every 2 pieces they takes.",
    tags: @[Take, Rook, Virus],
    icon: rookIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            Rook.buff(side, b, s, 
                onTake = reinforcementsOntake
            )
)

const shotgunKingOnTake*: OnAction = proc (piece: var Piece, to: Tile, board: var ChessBoard, state: var BoardState) = 
    let originalKingTile = piece.tile
    inc piece.timesMoved
    let takeResult = to.takenBy(piece, board, state)
    if takeResult.takeSuccess:
        inc board[takeResult.endTile.rank][takeResult.endTile.file].piecesTaken

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
    tags: @[King, Virus],
    icon: kingIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            King.buff(side, b, s,
                onTake = shotgunKingOnTake,
                takes = @[blackForwardTwiceJumpTake, whiteForwardTwiceJumpTake]
            )
)

const bountyHunterOnEndTurn*: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) = 
        if piece.piecesTaken == 3:
            for i, j in board.rankAndFile:
                #searches for enemy king and deletes is
                if board[i][j].item == King and not board[i][j].sameColor(piece):
                    board[i][j] = air.pieceCopy(index = board[i][j].index, tile = board[i][j].tile)
                    echo "King has been killed by Bounty Hunter"

const bountyHunterPower*: Power = Power(
    name: "Bounty Hunter",
    tier: Common,
    rarity: -999,
    priority: 15,
    description: "It's hard to make a living these days. If your king takes 3 pieces, you automatically win.",
    tags: @[King, Special],
    icon: kingIcon,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            King.buff(side, b, s,
                onEndTurn = @[bountyHunterOnEndTurn]
            )
)

const bountyHunter: Synergy = (
    power: bountyHunterPower,
    rarity: 16,
    requirements: @[shotgunKing.name],
    replacements: @[]
)

const coward: Power = Power(
    name: "Coward",
    tier: Common,
    priority: 25,
    description: "You coward. Your king swaps pieces with the king's side knight.",
    tags: @[King, Develop, Virus],
    icon: kingIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, _: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == King and b[i][j].isColor(side):
                    if b[i][j].timesMoved == 0:
                        inc b[i][j].timesMoved
                        pieceSwap(b[i][j], b[i][j + 2], b)      
)
discard """
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
"""
const lancePromote*: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) = 
    piece.moves = @[leftRightMoves, diagnalMoves, blackForwardMoves, whiteForwardMoves]
    piece.takes = @[leftRightTakes, diagnalTakes, blackForwardTakes, whiteForwardTakes]
    piece.filePath = "promotedlance.svg"

const lancePromoteConditions*: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) = 
    if piece.isAtEnd() and not piece.promoted:  
        piece.promote(board, state)

const lanceRight*: Power = Power(
    name: "Kamikaze", 
    technicalName: "Kamikaze Right",
    tier: Rare,
    priority: 5, 
    rarity: 4, 
    description: 
        """The divine wind is behind you. 
        Your right pawn is replaced with a lance from Shogi.""",
    tags: @[Push, Trade],
    icon: "lance.svg",
    rotatable: true,
    noColor: true,
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            let rank = if side == black: 1 else: 6
            let file = if side == black: 0 else: 7
            assert b[rank][7].color == side
            if side == black:
                b[rank][file].moves = @[blackLanceMoves]
                b[rank][file].takes = @[blackLanceTakes]
            else:
                b[rank][file].moves = @[whiteLanceMoves]
                b[rank][file].takes = @[whiteLanceTakes]
            b[rank][file].onEndTurn = @[lancePromoteConditions]
            b[rank][file].onPromote = @[lancePromote]
            b[rank][file].item = Fairy
            b[rank][file].filePath = "lance.svg"
            b[rank][file].colorable = false
            if side != viewSide: b[rank][file].rotate = true
)

const lanceLeft*: Power = Power(
    name: "Kamikaze", 
    technicalName: "Kamikaze Left",
    tier: Rare,
    priority: 5, 
    rarity: 4, 
    description: 
        """The divine wind is behind you. 
        Your left pawn is replaced with a lance from Shogi.""",
    tags: @[Push, Trade, Virus],
    icon: "lance.svg",
    rotatable: true,
    noColor: true,
    onStart: 
        proc (side: Color, viewSide: Color, b: var ChessBoard, _: var BoardState) = 
            let rank = if side == black: 1 else: 6
            let file = if side == black: 7 else: 0
            assert b[rank][7].color == side
            if side == black:
                b[rank][file].moves = @[blackLanceMoves]
                b[rank][file].takes = @[blackLanceTakes]
            else:
                b[rank][file].moves = @[whiteLanceMoves]
                b[rank][file].takes = @[whiteLanceTakes]
            b[rank][file].onEndTurn = @[lancePromoteConditions]
            b[rank][file].onPromote = @[lancePromote]
            b[rank][file].item = Fairy
            b[rank][file].filePath = "lance.svg"
            b[rank][file].colorable = false
            if side != viewSide: b[rank][file].rotate = true
)

proc drunkMove(predicate: proc(p: Piece): bool {.noSideEffect.}): BoardAction = 
    result.priority = 25
    result.action = proc (side: Color, board: var ChessBoard, state: var BoardState) =  
        randomize(state.shared.randSeed)
        var drankIndexes: seq[int] = @[]

        for i, j in board.rankAndFile:
            if board[i][j].predicate() and board[i][j].index notin drankIndexes:
                drankIndexes.add(board[i][j].index)
                let moves = board[i][j].getMovesOn(board)
                if len(moves) == 0: continue

                var attempt = moves.sample()
                assert attempt notin board[i][j].getTakesOn(board)
                
                board[i][j].move(attempt, board, state)

proc drunkVirus(predicate: proc(p: Piece): bool {.noSideEffect.}, onlyTake: bool = false): BoardAction = 
    result.priority = 25
    result.action = proc (side: Color, board: var ChessBoard, state: var BoardState) =  
        randomize(state.shared.randSeed)
        var drankIndexes: seq[int] = @[]

        for i, j in board.rankAndFile:
            if board[i][j].predicate() and board[i][j].index notin drankIndexes:
                drankIndexes.add(board[i][j].index)
                let moves = if onlyTake: @[] else: board[i][j].getMovesOn(board) #exclude moves if `onlyTake` flag is true
                let takes = board[i][j].getTakesOn(board)
                if len(moves & takes) == 0: continue

                var attempt = sample(moves & takes)
                
                if attempt in takes:
                    board[i][j].take(attempt, board, state)
                elif attempt in moves:
                    board[i][j].move(attempt, board, state)

const drunkKnights: Power = Power(
    name: "Drunk Knights",
    tier: Rare,
    priority: 15,
    description: 
        """Drunk riding is dangerous, your knights should be ashamed of themselves. 
        After every other turn, they randomly move.""",
    tags: @[Special, Knight, UnHoly, NightRider],
    icon: knightIcon,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            s.side[side].onEndTurn.add(
                drunkMove(proc(p: Piece): bool = 
                    (p.isColor(side) or (p.isColor(otherSide(side)) and p.converted)) and p.item == Knight    
                )
            )

            Knight.buff(side, b, s, rotate = true)
)

const alcoholism*: Power = Power(
    name: "Alcoholism",
    tier: UltraRare,
    rarity: 4,
    priority: 15,
    description: """You're families and friends miss you. The real you.""",
    tags: @[Special, UnHoly, Virus],
    icon: pawnIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            s.side[side].onEndTurn.add(drunkMove(
                proc(p: Piece): bool = 
                    (p.isColor(side) or (p.isColor(otherSide(side)) and p.converted))
                )
            )

            for p in PieceType:
                p.buff(side, b, s, rotate = true)
)

const drunkNightRiderPower: Power = Power(
    name: "nighetriedder",
    tier: UltraRare,
    priority: 17,
    rarity: -999,
    description: "nighetriedder.?",
    icon: "nightrider.svg",
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            let condition = #we split this so onlyTake flag is not uglified
                proc(p: Piece): bool = 
                    (p.isColor(side) or (p.isColor(otherSide(side)) and p.converted)) and p.filePath.contains("nightrider")
                
            s.side[side].onEndTurn.add(drunkVirus(condition, onlyTake = true))

            for i, j in b.rankAndFile:
                if b[i][j].filePath.contains("nightrider"):
                    b[i][j].rotate = true
)

const drunkNightRider: Synergy = (
    power: drunkNightRiderPower,
    rarity: -999,
    requirements: @[drunkKnights.name, nightRider.name],
    replacements: @[]
)

const drunkNightRider2: Synergy = (
    power: drunkNightRiderPower,
    rarity: -999,
    requirements: @[alcoholism.name, nightRider.name],
    replacements: @[]
)

const virusPower*: Power = Power(
    name: "virus",
    tier: UltraRare,
    priority: 15,
    description: "They're dying. They're dying. They're dying.",
    rarity: -999,
    icon: "",
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) =
            s.side[side].onEndTurn.add(drunkVirus(
                proc(p: Piece): bool = 
                    (p.isColor(side) or (p.isColor(otherSide(side)) and p.converted))
                )
            )

            for p in PieceType:
                p.buff(side, b, s, rotate = true)
)  

#virus powers just have random stuff
#but still decided in advance so that I don't have to sync random seed
const virus: Synergy = (
    power: virusPower,
    rarity: -999,
    requirements: @[alcoholism.name, lanceLeft.name, headStart.name, mysteriousSwordsmanLeft.name],
    replacements: @[alcoholism.name]
)

const virus2: Synergy = (
    power: virusPower,
    rarity: -999,
    requirements: @[alcoholism.name, backStep.name, knightChargePower.name, altEmpress.name],
    replacements: @[alcoholism.name]
)

const virus3: Synergy = (
    power: virusPower,
    rarity: -999,
    requirements: @[alcoholism.name, wanderingRoninLeft.name, superPawnPower.name, empress.name],
    replacements: @[alcoholism.name]
)

const virus4: Synergy = (
    power: virusPower,
    rarity: -999,
    requirements: @[alcoholism.name, stepOnMe.name, coward.name, shotgunKing.name, "Vampires"],#i just don't feel like moving the definition up
    replacements: @[alcoholism.name]
)

const virus5: Synergy = (
    power: virusPower,
    rarity: -999,
    requirements: @[alcoholism.name, reinforcements.name, empress.name, giraffe.name, werewolves.name],
    replacements: @[alcoholism.name]
)

const virus6: Synergy = (
    power: virusPower,
    rarity: -999,
    requirements: @[alcoholism.name, anime.name, developed.name, sacrifice.name, illegalFormationBR.name],
    replacements: @[alcoholism.name]
)

const virus7: Synergy = (
    power: virusPower,
    rarity: -999,
    requirements: @[alcoholism.name, linebackersPower.name, nightrider.name, desegregation.name, holy.name],
    replacements: @[alcoholism.name]
)

#TODO: SEE IF I CAN KILL THE PIECE WHEN THIS HAPPENS. WHY CAPS LOCK
const attemptedWarCrimes*: WhenTaken = proc (taken: var Piece, taker: var Piece, board: var ChessBoard, state: var BoardState): tuple[endTile: Tile, takeSuccess: bool] = 
    return (taker.tile, false)

const civilians*: Power = Power(
    name: "Civilians",
    tier: Uncommon,
    priority: 30,
    description: """Of course, a battle will have its civillians. And of course, the enemy won't kill them.
                    3 civillians spawn on the enemy side. They randomly move and cannot be taken.""",
    tags: @[Move, Control],
    icon: "civilian.svg",
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) =
            randomize(s.shared.randSeed)
            let rank: int = if side == black: 5 else: 2
            let commoner = Piece(item: Fairy, color: side, moves: @[kingMoves], takes: @[], onMove: defaultOnMove, onTake: defaultOnTake, 
                                whenTaken: attemptedWarCrimes, onEndTurn: @[], onPromote: @[],
                                filePath: "civilian.svg")

            s.side[side].onEndTurn.add(drunkMove(
                proc(p: Piece): bool = 
                    p.filePath.contains("civilian")
            ))

            var spawns = 0
            var failsafe = 20
            var attempt: int = rand(7)
            while spawns != 3 and failSafe != 0:
                if b[rank][attempt].isAir:
                    let tile = b[rank][attempt].tile
                    b[rank][attempt] = commoner.pieceCopy(index = newIndex(s), tile = tile)
                    inc spawns
                else:
                    dec failSafe

                attempt = rand(7)
)

const calvaryGiraffePower: Power = Power(
    name: "Bandaid",
    tier: UltraRare,
    rarity: -999,
    priority: 27, #after calvary charge
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
    rarity: -999,
    requirements: @[knightChargePower.name, giraffe.name],
    replacements: @[]
)

const lesbianBountyHunterOnEndTurn*: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) = 
    echo "Lesbian Bounty Hunter Active"
    if piece.piecesTaken == 7:
        for i, j in board.rankAndFile:
            #searches for enemy king and deletes is
            if board[i][j].item == King and not board[i][j].sameColor(piece):
                board[i][j] = air.pieceCopy(index = board[i][j].index, tile = board[i][j].tile)
                echo "King has been killed by Lesbian Bounty Hunter"

const lesbianBountyHunterPower*: Power = Power(
    name: "Bounty Hunter Nerf",
    tier: Common,
    rarity: -999,
    priority: 15,
    description: "Yeah, 3 pieces is way too easy for our lesbian queens, so now it's 7 pieces. You got this!",
    icon: kingIcon,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            Queen.buff(side, b, s,
                onEndTurn = @[lesbianBountyHunterOnEndTurn],
            )
)

const lesbianBountyHunter: Synergy = (
    power: lesbianBountyHunterPower,
    rarity: -999,
    requirements: @[lesbianPride.name, bountyHunterPower.name],
    replacements: @[bountyHunterPower.name]
)

proc createLottery(): BoardAction = 
    var lastTimesMoved: array[0..ChessRow.len, array[0..ChessBoard.len,int]] 
    #closure is used to hold state
    #this is preferable when state does not need to interact with the rest of the game's systems
    #to better modularize the power's state, I think
    #`Piece.rand` powers can't do this because it needs the seed, and a global clear of drunkenness
    #which has to happen after all `Piece.onEndTurn` stuff, not during
    result.priority = 5
    result.action = proc (side: Color, board: var ChessBoard, state: var BoardState) =
        for i, j in board.rankAndFile:
            if board[i][j].timesMoved != lastTimesMoved[i][j]:
                randomize(10 * j + 100 * i + state.shared.randSeed)
                let ticket = rand(100)
                if ticket == 42: #arbitrary
                    board[i][j].promote(board, state)
            lastTimesMoved[i][j] = board[i][j].timesMoved
        

const slumdogMillionaire*: Power = Power(
    name: "Slumdog Millionaire",
    tier: Common,
    priority: 15,
    description: """Have you seen the movie Slumdog Millionaire? It's kind of like that. 
                    Your pawns have a 1% chance of promoting whenever they move.""",
    tags: @[UnHoly, Move],
    icon: pawnIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            s.side[side].onEndTurn.add(createLottery())
)

#I have no clue why this needs the closure pragma, but I guess it does
const stupidOnEndTurn: BoardActionAction = proc (side: Color, board: var ChessBoard, state: var BoardState) =
    randomize(state.shared.randSeed)
    let ticket = rand(1000)
    if ticket == 42: #arbitrary
        for i, j in board.rankAndFile:
            if board[i][j].item == King and 
                board[i][j].isColor(side):
                    board[i][j].item = None #kills king

const stupidPower*: Power = Power(
    name: "Stupid Power",
    tier: Common,
    priority: 15,
    description: """You have a 0.1% chance to automatically win each turn. Yeah, I'm out of ideas. I'm sorry.""",
    tags: @[UnHoly, UnHoly],
    icon: kingIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            s.side[side].onEndTurn.add((
                action: stupidOnEndTurn,
                priority: 1
            ))
)

proc createConvertingTake(odds: float): OnAction = 
    assert odds <= 1

    result = proc (piece: var Piece, taking: Tile, board: var ChessBoard, state: var BoardState) = 
        randomize(10 * piece.tile.rank + 100 * piece.tile.file + state.shared.randSeed)
        let dice = rand(100)

        inc piece.timesMoved
        if dice <= int(odds * 100) and board[taking].item != King and board[taking].filePath.contains("vampire"): 
            board[taking].color = piece.color
            board[taking].index = newIndex(state) #it is a new piece when it switches
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
    tags: @[Holy, Bishop],
    icon: bishopIcon,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            Bishop.buff(side, b, s, 
                onTake = createConvertingTake(0.15)
            )
)

const holyConversionPower: Power = Power(
    name: "God's Disciple",
    tier: Uncommon,
    rarity: -999, #normal synergy
    priority: 15,
    description: """Your bishop has now seen God. When it takes, it has a 30% chance to convert it to your color. 
                    When this happens, your bishop swaps places with it instead of taking it.""",
    icon: bishopIcon,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            Bishop.buff(side, b, s, 
                onTake = createConvertingTake(0.3)
            )
)

const holyConversion: Synergy = (
    power: holyConversionPower,
    rarity: 16,
    requirements: @[conversion.name, holy.name],
    replacements: @[conversion.name]
)

const americanDream*: Power = Power(
    name: "American Dream",
    tier: Rare,
    priority: 30, 
    description: "All pieces, you and your opponent's, cannot promote. It's not real.",
    tags: @[Trade, Trade],
    icon: "usflag.svg",
    noColor: true,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            Pawn.buff(side, b, s, 
                promoted = true
            )

            Pawn.buff(otherSide(side), b, s, 
                promoted = true
            )
            
)

const sleeperAgent*: Power = Power(
    name: "Sleeper Agent",
    tier: Common,
    rarity: 7, #idk why but im feeling it
    priority: 30,
    description: """The silent river collapses in pieces. 
                    One of your pawns is a sleeper agent. They can take forward.""",
    tags: @[Pawn, Take],
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
proc moneyForTakeAll(): BoardAction = 
    var lastPiecesTaken = 0
    #closure is used to hold state
    #this is preferable when state does not need to interact with the rest of the game's systems
    #to better modularize the power's state, I think
    result.priority = 30
    result.action = proc (side: Color, b: var ChessBoard, state: var BoardState) =
        var allPiecesTaken = 0
        for i, j in b.rankAndFile:
            if b[i][j].isColor(side):
                allPiecesTaken += b[i][j].piecesTaken

        allPiecesTaken += state.side[side].abilityTakes #includes takes which are not by any piece

        echo "all", allPiecesTaken, "last", lastPiecesTaken, "side", side
        if allPiecesTaken > lastPiecesTaken:
            addMoney(side, (allPiecesTaken - lastPiecesTaken) * 3, state)
        lastPiecesTaken = allPiecesTaken

#just tracks one piece
proc moneyForTakeSingle(): OnPiece = 
    var lastPiecesTaken = 0
    result = proc (piece: var Piece, b: var ChessBoard, state: var BoardState) =
        if piece.piecesTaken > lastPiecesTaken:
            addMoney(piece.color, (piece.piecesTaken - lastPiecesTaken) * 3, state)
        lastPiecesTaken = piece.piecesTaken

const capitalismPower*: Power = Power(
    name: "Capitalism",
    tier: Uncommon,
    rarity: 24,
    priority: 30,
    description: """The power of the free market is unmatched. 
                    All of your pieces get the ability to buy upgrades. 
                    You get 3 dollars for taking a piece.
                    With 30 dollars, you can promote one piece. The promoted piece cannot move on the turn it is promoted.""",
    tags: @[UnHoly],
    icon: "usflag.svg",
    noColor: true,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            s.side[side].buys &= (name: "Promote", cost: alwaysCost(30), action: promoteBuying, condition: promoteBuyingCondition)
            side.initWallet(s)
            s.side[side].onEndTurn.add(moneyForTakeAll())
)

const bountyPower*: Power = Power(
    name: "Bounty",
    tier: UltraRare, 
    rarity: -999,
    priority: 15,
    description: "Pieces Wanted: Dead or Alive. Bounty: 6 dollars.",
    icon: kingIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            King.buff(side, b, s, onEndTurn = @[moneyForTakeSingle()])
            King.buff(side, b, s, onEndTurn = @[moneyForTakeSingle()])
)

const bounty: Synergy = (
    power: bountyPower,
    rarity: -999,
    requirements: @[bountyHunterPower.name, capitalismPower.name],
    replacements: @[]
)

const bounty2: Synergy = (
    power: bountyPower,
    rarity: -999,
    requirements: @[lesbianBountyHunterPower.name, capitalismPower.name],
    replacements: @[]
)

#helper function to create capitalism powers, since they need to be synergies to ensure use has money
proc createCapitalism(power: Power, rarity: int = 10, requirements: seq[string] = @[], replacements: seq[string] = @[]): Synergy =
        return (
            power: power,
            rarity: rarity,
            requirements: @[capitalismPower.name] & requirements,
            replacements: replacements
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

const whiteMoveUpCost: BuyCost = func (piece: Piece, b: ChessBoard, s: BoardState): int =
    if piece.wouldCheckAt(piece.tile.tileAbove, b, s): return 32 else: return 7
    
const blackMoveUpCost: BuyCost = func (piece: Piece, b: ChessBoard, s: BoardState): int =
    if piece.wouldCheckAt(piece.tile.tileBelow, b, s): return 32 else: return 7

const whiteMoveBackCost = blackMoveUpCost
const blackMoveBackCost = whiteMoveUpCost

const moveUp*: Power = Power(
    name: "Capitalism II",
    technicalName: "Capitalism II: Move Up",
    tier: Common,
    rarity: -999,
    priority: 15,
    description: """Money is pretty neat right? You can spend 8 dollars to move a piece one tile forward. 
                    It cannot take with this action. If moving would put the king into checkmate, this costs $25 more. """,
    icon: "usflag.svg",
    noColor: true,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            if side == black:
                s.side[side].buys &= (name: "Move Up", cost: blackMoveUpCost, action: blackMoveUp, condition: blackMoveUpCondition)
            else:
                s.side[side].buys &= (name: "Move Up", cost: whiteMoveUpCost, action: whiteMoveUp, condition: whiteMoveUpCondition)
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
    technicalName: "Capitalism II: Move Back",
    tier: Common,
    rarity: -999,
    priority: 15,
    description: """Money is pretty neat right? You can spend 7 dollars to move a piece one tile backwards. 
                    It cannot take with this action. If moving would put the king into checkmate, this costs $25 more. """,
    icon: "usflag.svg",
    noColor: true,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            if side == black:
                s.side[side].buys &= (name: "Move Back", cost: blackMoveBackCost, action: blackMoveBack, condition: blackMoveBackCondition)
            else:
                s.side[side].buys &= (name: "Move Back", cost: whiteMoveBackCost, action: whiteMoveBack, condition: whiteMoveBackConditions)
)

const capitalismTwo2: Synergy = createCapitalism(moveBack)

const income*: Power = Power(
    name: "Capitalism II",
    technicalName: "Capitalism II: Income",
    tier: Common,
    rarity: -999,
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
    technicalName: "Capitalism III: Upgrade Knight",
    tier: Uncommon,
    rarity: -999, #rarity 0 because it should only be gotten through synergy
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
    technicalName: "Capitalism III: Upgrade Giraffe",
    tier: Uncommon,
    rarity: -999, #rarity 0 because it should only be gotten through synergy
    priority: 15,
    description: """Money can be used in exchange for goods and services. You can spend 8 dollars to give a piece the movement of a giraffe. 
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
    inc state.side[piece.color].piecesSold
    inc state.side[piece.color].piecesSoldThisTurn
    echo state.side[piece.color]
    b[piece.tile.rank][piece.tile.file] = air.pieceCopy(index = b[piece.tile.rank][piece.tile.file].index, tile = piece.tile)

const updatePiecesSold: BoardActionAction = proc (_: Color, b: var ChessBoard, state: var BoardState) =
    state.side[white].piecesSoldThisTurn = 0
    state.side[black].piecesSoldThisTurn = 0

const notKing: BuyCondition = func (piece: Piece, board: ChessBoard, s: BoardState): bool = 
    return piece.item != King

proc createPieceMarket(cost: int, rate: int): BuyCost =
    result = func (piece: Piece, b: ChessBoard, s: BoardState): int =
        result = cost + (rate * (s.side[piece.color].piecesSoldThisTurn))

const sell*: Power = Power(
    name: "Capitalism V",
    technicalName: "Capitalism V: Sell",
    tier: Uncommon,
    rarity: -999, #rarity 0 because it should only be gotten through synergy
    priority: 15,
    description: """Who needs these pieces? AFUERA! You can sell a piece for 4 dollars. Each subsequent piece gives one dollar less. """,
    icon: "usflag.svg",
    noColor: true,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            s.side[side].buys &= (name: "Sell", cost: createPieceMarket(-4, 1), action: sellPiece, condition: notKing)
            s.side[side].onEndTurn.add((action: updatePiecesSold, priority: 30))
)

const capitalismFive1: Synergy = createCapitalism(sell)

proc createTaxes(rate: float): BoardAction = 
    result.priority = 35
    result.action = proc (side: Color, b: var ChessBoard, state: var BoardState) =
        var tax: int = int(float(getMoney(side, state)) * rate)
        if tax == 0 and getMoney(side, state) > 0: inc tax #so that it always takes something
        addMoney(side, -tax, state)

const taxes*: Power = Power(
    name: "Capitalism V",
    technicalName: "Capitalism V: Taxes",
    tier: Rare,
    rarity: -999, #rarity 0 because it should only be gotten through synergy
    priority: 15,
    description: """Nothing in the world is certain except for Taxes and one other thing. 
                    You gain 6 more dollars for taking a piece, but you lose 15% every turn.""",
    icon: "usflag.svg",
    noColor: true,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            #We just add two more `moneyForTakeAll`s
            s.side[side].onEndTurn.add(moneyForTakeAll())
            s.side[side].onEndTurn.add(moneyForTakeAll())
            s.side[side].onEndTurn.add(createTaxes(0.15))
)

const capitalismFive2: Synergy = createCapitalism(taxes)

const monopoly*: Power = Power(
    name: "Capitalism IV",
    technicalName: "Capitalism IV: Monopoly",
    tier: Uncommon,
    rarity: -999,
    priority: 15,
    description: """More money equals more money! You get 3 more dollars for taking a piece. """,
    icon: "usflag.svg",
    noColor: true,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            #We just add 1 more `moneyForTakeAll`s
            s.side[side].onEndTurn.add(moneyForTakeAll())
)

const capitalismFour1: Synergy = createCapitalism(monopoly)

proc moneyForMove(): BoardAction = 
    var lastTimesMoved = 0
    #closure is used to hold state
    #this is preferable when state does not need to interact with the rest of the game's systems
    #to better modularize the power's state, I think
    result.priority = 30
    result.action = proc (side: Color, b: var ChessBoard, state: var BoardState) =
        var allTimesMoved = 0
        for i, j in b.rankAndFile:
            if b[i][j].isColor(side):
                allTimesMoved += b[i][j].timesMoved

        if allTimesMoved > lastTimesMoved:
            addMoney(side, (allTimesMoved - lastTimesMoved) * 1, state)
        lastTimesMoved = allTimesMoved

const handouts*: Power = Power(
    name: "Capitalism IV",
    technicalName: """Capitalism IV: Handouts""",
    tier: Uncommon,
    rarity: -999,
    priority: 15,
    description: """What if everyone had money? Then everyone would have money! You get 1 dollar for moving a piece.""",
    icon: "usflag.svg",
    noColor: true,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            #We just add two more `moneyForTakeAll`s
            s.side[side].onEndTurn.add(moneyForMove())
)

const capitalismFour2: Synergy = createCapitalism(handouts)

#altered `createLottery()`, but also adds 10 dollars to wallet
proc createSuperLottery(): BoardAction = 
    var lastTimesMoved: array[0..ChessRow.len, array[0..ChessBoard.len,int]] 
    #closure is used to hold state
    #this is preferable when state does not need to interact with the rest of the game's systems
    #to better modularize the power's state, I think
    #`Piece.rand` powers can't do this because it needs the seed, and a global clear of drunkenness
    #which has to happen after all `Piece.onEndTurn` stuff, not during
    result.priority = 5
    result.action = proc (side: Color, board: var ChessBoard, state: var BoardState) =
        for i, j in board.rankAndFile:
            if board[i][j].timesMoved != lastTimesMoved[i][j]:
                randomize(10 * j + 100 * i + state.shared.randSeed)
                let ticket = rand(100)
                if ticket == 42: #arbitrary
                    addMoney(side, 10, state)
                    board[i][j].promote(board, state)
            lastTimesMoved[i][j] = board[i][j].timesMoved

const slumdogBillionairePower*: Power = Power(
    name: "Slumdog Billionaire",
    tier: Common,
    rarity: -999,
    priority: 15,
    description: """Have you seen the movie Slumdog Millionaire? It's kind of like that but more. 
                    Your pawns have a 2% chance of promoting whenever they move. When this happens, you get 10 dollars.""",
    icon: pawnIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            s.side[side].onEndTurn.add(createSuperLottery())

)

const slumdogBillionaire: Synergy = createCapitalism(slumdogBillionairePower, -999, @[slumdogMillionaire.name], @[slumdogMillionaire.name])

const exponentialGrowthOnEndTurn: BoardActionAction = proc (side: Color, _: var ChessBoard, state: var BoardState) =
    let currentMoney = getMoney(side, state)
    let next = currentMoney * 2 - currentMoney #I want it to double, but not sum of doubling. 
    addMoney(side, next, state)

const exponentialGrowth*: Power = Power(
    name: "Capitalism MM",
    tier: UltraRare, 
    rarity: -999,
    priority: 15,
    description: "TO THE MOON!!!!",
    icon: "usflag.svg",
    noColor: true,
    onStart:  
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            s.side[side].onEndTurn.add((action: exponentialGrowthOnEndTurn, priority: 33))
)

const capitalismTwoThousand: Synergy = (
    power: exponentialGrowth,
    rarity: -999,
    requirements: @[capitalismPower.name, capitalismTwo2.power.name, capitalismThree1.power.name, capitalismFour1.power.name, capitalismFive1.power.name],
    replacements: @[]
)

const canSkyGlass: GlassMoves = 
    func (side: Color, piece: Piece, b: ChessBoard, s: BoardState): Moves =
        if piece.color != side: return @[]
        else: 
            for tile in b.rankAndFile:
                if b[tile].item == None and not piece.wouldCheckAt(tile, b, s):
                    result.add(tile)


const skyGlassAction: OnAction = proc (piece: var Piece, to: Tile, b: var ChessBoard, s: var BoardState) = 
    #this is not in the condition because it can change after
    #but it should still be a viable attempt before
    if b[to.rank][to.file].item != None: return
    piece.move(to, b, s)

const canZeroGlass: GlassMoves = 
    func (side: Color, piece: Piece, b: ChessBoard, s: BoardState): Moves =
        if s.shared.turnNumber <= 1: return @[]

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
    if b[to].item == None or 
        b[to] == piece: return
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
    rarity: 8, 
    priority: 15,
    description: """On your turn, instead of moving, you can choose 2 pieces to each cast Sky on any 
                    open tile. These pieces teleport to their selected tile when the cast completes. 
                    Pieces cannot try to teleport to a tile where they would check the king. """ & createGlassDescription(),
    tags: @[Develop, Push],
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
    rarity: 8,
    priority: 15,
    description: """On your turn, instead of moving, you can choose 2 pieces to each cast Zero on  
                    any non-king tile. Any piece on these tiles will die if the cast completes. Zero cannot be cast turn one. """ &
                    createGlassDescription(),
    tags: @[Take, Push],
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


const steelGlass*: Power = Power(
    name: "Glass: Steel",
    tier: Common,
    rarity: -999, #TODO: rebalance steel glass. for now im just disabling it
    priority: 15,
    description: """On your turn, instead of moving, you can choose 5 pieces to each cast Steel. 
                    If there is an enemy one tile in front of them when the cast completes, they take forward. """ &
                    createGlassDescription(),
    tags: @[Take, Push, Glass, Glass],
    icon: "steelglass.svg",
    noColor: true,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            s.side[side].glass[Steel] = some((
                strength: 5,
                action: steelGlassAction,
                condition: canSteelGlass,
            ))
)

const divineWindPower*: Power = Power(
    name: "Divine Wind",
    tier: Uncommon,
    priority: 15,
    description: """The divine wind briskly brushes your back. Your lances will attack while sky is casting.""",
    tags: @[Take, Push, Glass, Glass, Trade],
    icon: "lance.svg",
    noColor: true,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            let condition =                 
                proc(p: Piece): bool = 
                    (p.isColor(side) or (p.isColor(otherSide(side)) and p.converted)) and 
                    p.filePath.contains("lance") and
                    Sky.isCasting(b)

            s.side[side].onEndTurn.add(drunkVirus(condition, onlyTake = true))
)

const divineWind: Synergy = (
    power: divineWindPower,
    rarity: 12,
    requirements: @[skyGlass.name, lanceLeft.name],
    replacements: @[]
)

const canBankruptGlass: GlassMoves = 
    func (side: Color, piece: Piece, b: ChessBoard, s: BoardState): Moves =
        assert s.side[side].wallet.isSome()
        
        #can only do it when money is 0
        if s.shared.turnNumber <= 1 or 
             s.side[side].wallet.get() != 0 : return @[]

        for i, j in b.rankAndFile:
            if b[i][j].item != King:
                result.add(b[i][j].tile)

const bankruptGlassPower*: Power = Power(
    name: "Glass: Bankruptcy",
    tier: Rare,
    rarity: 8, #while new
    priority: 0,
    description: """On your turn, if you have only 0 dollars, instead of moving you can choose 3 pieces to each cast Bankruptcy on  
                    any non-king tiles. Any piece on these tiles will die if the cast completes. Bankruptcy cannot be cast turn one. """ &
                    createGlassDescription(),
    tags: @[Take, Push, Glass, Glass],
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
    replacements: @[zeroGlass.name]
)

const canReverieGlass: GlassMoves = 
    func (side: Color, piece: Piece, b: ChessBoard, s: BoardState): Moves =
        for i, j in b.rankAndFile:
            if b[i][j].item != King and not b[i][j].isAir():
                result.add(b[i][j].tile)

const reverieGlassAction: OnAction = proc (piece: var Piece, to: Tile, b: var ChessBoard, s: var BoardState) = 
    if b[to].isAir or b[to].item == King and piece.item == King: return

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
    rarity: 8, 
    priority: 0,
    description: """On your turn, instead of moving you can choose 3 pieces to each cast Reverie on 
                    an opponent tile. When the cast completes, 
                    they swap moves and takes with whatever piece is on that tile. If that piece 
                    is a king, the cast fails. """ &
                    createGlassDescription(),
    tags: @[Move, Take, Glass, Glass],
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

const canDaybreakGlass: GlassMoves = 
    func (side: Color, piece: Piece, b: ChessBoard, s: BoardState): Moves =
        for i, j in b.rankAndFile:
            if b[i][j].isColor(side) and
                b[i][j].onPromote != @[defaultOnEndTurn] and
                not b[i][j].promoted:
                    result.add(b[i][j].tile)

const daybreakAction: OnAction = proc (piece: var Piece, to: Tile, b: var ChessBoard, s: var BoardState) = 
    if b[to].isAir or b[to].promoted: return
    b[to].promote(b, s)


const daybreakGlass*: Power = Power(
    name: "Glass: Daybreak",
    tier: Rare,
    rarity: 8,
    priority: 0,
    description: """On your turn, instead of moving you can choose 1 pieces to cast Daybreak on 
                    any tile. When the cast completes, the piece on that tile promotes. """ &
                    createGlassDescription(),
    tags: @[Promote, Promote, Glass, Glass],
    icon: "daybreakglass.svg",
    noColor: true,
    onStart: 
        proc (side: Color, _: Color, _: var ChessBoard, s: var BoardState) = 
            s.side[side].glass[Daybreak] = some((
                strength: 1,
                action: daybreakAction,
                condition: canDaybreakGlass,
            ))
)

proc createWithClarity(): OnPiece = 
    var clarity: bool = false
    result = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) = 
        if clarity:
            #new strategy for removing
            piece.moves.delete(piece.moves.find(clarityMoves))
            piece.takes.delete(piece.takes.find(clarityTakes))
        if state.side[piece.color].hasCastled and not clarity:
            piece.moves.add(clarityMoves)
            piece.takes.add(clarityTakes)
            clarity = true #clarity will short circuit every turn after

const clarityPower: Power = Power(
    name: "Clarity",
    tier: UltraRare,
    rarity: -999,
    priority: 15,
    description: """You now see things in a whole new light. 
                It's not regret as much as self-disappointment.""",
    icon: kingIcon,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            King.buff(side, b, s, onEndTurn = @[createWithClarity()])
)

const clarity: Synergy = (
    power: clarityPower,
    rarity: -999,
    requirements: @[daybreakGlass.name, concubine.name],
    replacements: @[]
)

const masterGlassPower: Power = Power(
    name: "Master Glass",
    tier: UltraRare,
    rarity: -999,
    priority: 30,
    description: """You have good taste. All glasses can be cast one more time.""",
    icon: "skyglass.svg",
    noColor: true,
    onStart: 
        proc (side: Color, _: Color, _: var ChessBoard, s: var BoardState) = 
            for c in s.side[side].glass.mitems:
                if c.isSome:
                    c = c.map(
                        proc(x: GlassAbility): GlassAbility = 
                            result = x
                            inc result.strength
                    )
)

const masterGlass: Synergy = (
    power: masterGlassPower,
    rarity: -999,
    requirements: @[skyGlass.name, reverieGlass.name, zeroGlass.name, steelGlass.name, daybreakGlass.name],
    replacements: @[]
)

const masterGlass2: Synergy = (
    power: masterGlassPower,
    rarity: -999,
    requirements: @[skyGlass.name, reverieGlass.name, bankruptGlassPower.name, steelGlass.name, daybreakGlass.name],
    replacements: @[]
)

const communism*: Power = Power(
    name: "Comunism",
    tier: UltraRare,
    rarity: 1,
    priority: 50,
    description: """The proletariat must revolt to escape the continued shackles subjugation by the bourgeoisie. 
                    We shall create a utopia of equality. """,
    tags: @[Pawn, Pawn, Pawn, Pawn, Pawn],
    icon: "sickleandhammer.svg",
    noColor: true,
    onStart:
        proc (side: Color, viewSide: Color, b: var ChessBoard, s: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].isColor(side):
                    b[i][j] = s.side[side].dna[Pawn].pieceCopy(index = b[i][j].index, tile = b[i][j].tile)

            Pawn.change(side, b, s, 
                promoted = true #so that it can never promote
            )
            backStep.onStart(side, viewSide, b, s) #to fix any issues of them moving backwards
            headStart.onStart(side, viewSide, b, s)
            s.side[side].communist = true

)

#just does nothing
const comucapitalNull*: Power = Power(
    name: "Null",
    tier: Common,
    description: """The tautotology is empty. 
                    The river flows. 
                    Take off thy mask and feel the world. 
                    Where is man? 
                    Where is his kin? 
                    When sight is white,
                    when does it begin?
                    Golden glimpses sunder position. 
                    Beauty discovers in ebb and in flow. 
                    Falling is height, Loss is full.
                    The table must be full for the feast.
                    Capture, take, collapse these pieces. 
                    Destroy it, destroy thyself, destroy thy world.
                    Feel it. 
                    """,
    icon: "",
    onStart:
        proc (_: Color, _: Color, _: var ChessBoard, _: var BoardState) = 
            discard nil
)

const comucapital: Synergy = (
    power: comucapitalNull,
    rarity: -999,
    requirements: @[capitalismPower.name, communism.name],
    replacements: @[communism.name, #needs to remove all money related powers
                        capitalismPower.name, 
                        capitalismTwo1.power.name,
                        capitalismThree1.power.name, 
                        capitalismFour1.power.name,
                        capitalismFive1.power.name,
                        capitalismTwoThousand.power.name,
                        slumdogBillionaire.power.name,
                        bankruptGlassPower.name,
                        bounty.power.name
                    ],
)

#TODO 
#This is going to be for the fture anyisynergy update
#Rbut I first need to do a show power menu while drating
const undevelopedPower*: Power = Power(
    name: "Un-Developed",
    tier: Common,
    priority: 22, #after developed 
    description: """Undevelop your opponent's board. Their 2 center pawns move back to their normal starting place. 
                    It's not even useful, but it is annoying. """,
    antiDescription: "You've been undeveloped.",
    tags: @[Develop, Develop],
    icon: pawnIcon,
    anti: true,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            #TODO: fix hard coded moves to prevent conflict. 
            #fix would just stop move attempt if it would kill a piece
            if side == black:
                if b[2][3].item == Pawn and b[1][3].item == None:
                    b[2][3].pieceMove(1, 3, b, s)
                if b[2][4].item == Pawn and b[1][4].item == None: 
                    b[2][4].pieceMove(1, 4, b, s)
            elif side == white:
                if b[5][3].item == Pawn and b[6][3].item == None:
                    b[5][3].pieceMove(6, 3, b, s)
                if b[5][4].item == Pawn and b[6][4].item == None:
                    b[5][4].pieceMove(6, 4, b, s)         
)

const undeveloped: AntiSynergy = (
    power: undevelopedPower,
    rarity: 10,
    drafterRequirements: @[],
    opponentRequirements: @[developed.name]
)

const coldWarPower*: Power = Power(
    name: "Cold War",
    tier: UltraRare,
    priority: 20,
    description: "Do not press the button.",
    icon: "nuclear.svg",
    noColor: true,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            s.shared.mutuallyAssuredDestruction = true
)

const coldWar1: AntiSynergy = (
    power: coldWarPower,
    rarity: -999,
    drafterRequirements: @[capitalismPower.name],
    opponentRequirements: @[communism.name]
)

const coldWar2: AntiSynergy = (
    power: coldWarPower,
    rarity: -999,
    drafterRequirements: @[communism.name],
    opponentRequirements: @[capitalismPower.name]
)

proc inflateBy(buy: BuyCost, rate: float): BuyCost = 
    result = proc (piece: Piece, board: ChessBoard, state: BoardState): int = 
        int(float(buy(piece, board, state)) * rate) + 1

#this is an OnPiece action because it needs to add a BoardAction. If it was a BoardAction, it would add to seq while iterating over it
#so I'm using kingOnPiece as a type of queue, especially since I don't mind when moneyTakeForAll activates
const inflateAction: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) = 
    state.side[piece.color].onEndTurn.add(moneyForTakeAll())
    for buy in state.side[piece.color].buys.mitems:
        buy.cost = buy.cost.inflateBy(1.25)

const inflationPower*: Power = Power(
    name: "Inflation",
    tier: Rare,
    priority: 25,
    description: "It inflates, what else can be said?",
    antiDescription: "Maybe you should print more money?",
    tags: @[UnHoly, UnHoly],
    icon: "americanflag.svg",
    noColor: true,
    anti: true,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            King.buff(side, b, s, onEndTurn = @[inflateAction])
)

const inflation*: AntiSynergy = (
    power: inflationPower,
    rarity: 12,
    drafterRequirements: @[],
    opponentRequirements: @[capitalismPower.name]
)

const phalanxPower*: Power = Power(
    name: "Phalanx",
    tier: Uncommon,
    rarity: -999,
    priority: 20,
    description: """Your leftmost and rightmost pawns start one tile forward. 
                    It's a classic defense to the lance opening, you can find more information 
                    in your local library. """,
    tags: @[Develop, Develop],
    icon: pawnIcon,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            if side == black:
                if b[1][0].item == Pawn and b[2][0].item == None:
                    b[1][0].pieceMove(2, 0, b, s)
                if b[1][7].item == Pawn and b[2][7].item == None:
                    b[1][7].pieceMove(2, 7, b, s)
            elif side == white:
                if b[6][0].item == Pawn and b[5][0].item == None:
                    b[6][0].pieceMove(5, 0, b, s)
                if b[6][7].item == Pawn and b[5][7].item == None:
                    b[6][7].pieceMove(5, 7, b, s)    
)

const phalanx: AntiSynergy = (
    power: phalanxPower,
    rarity: 8,
    drafterRequirements: @[],
    opponentRequirements: @[lanceLeft.name],
)

#Insane new ref technology, see propagandaPower for more
proc createPropagandaCondition(promotedIndexes: ref seq[int]): BuyCondition = 
    result = 
        func (piece: Piece, board: ChessBoard, s: BoardState): bool =
            return piece.index notin promotedIndexes[] and (piece.onPromote != @[defaultOnEndTurn] and piece.onPromote != @[])

func createPropagandaPromoteBuying(promotedIndexes: var seq[int]): OnPiece = 
    result = proc (piece: var Piece, b: var ChessBoard, s: var BoardState) =
        promotedIndexes.add(piece.index)
        piece.promote(b, s)
        let captureMove = piece.moves
        let captureTake = piece.takes
        let turnOfPromote = s.shared.turnNumber
        var release = false
        piece.moves = @[]
        piece.takes = @[]

        piece.onEndTurn &= 
            proc (piece: var Piece, board: var ChessBoard, state: var BoardState) =
                if state.shared.turnNumber != turnOfPromote and not release:
                    piece.moves &= captureMove
                    piece.takes &= captureTake
                    release = true

const propagandaPower*: Power = Power(
    name: "Propaganda",
    tier: Rare,
    rarity: -999,
    priority: 35,
    description: "Liberty. Freedom. The Pursuit of Happiness. We are righteous.",
    tags: @[UnHoly, Special, Promote, Promote],
    icon: "unclesam.jpg",
    noColor: true,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            #Both buying and condition need the same data, as extra state
            #I could put it under BoardState, but it is too specific since it is only used by this power
            #So I used super advanced reference technology
            #propaganda is allocated as a seq of integers
            #the variable is passed to createPropagandaPromoteBuying
            #and a reference to it is passed to createPropagandaCondition
            #I could pass a variable to both, however this better establishes how they work
            #and ensures that createPropagandaCondition does not alter the propaganda variable, only looks at it

            var propaganda = seq[int].new
            for buy in s.side[side].buys.mitems:
                if buy.name == "Promote":
                    buy.action = createPropagandaPromoteBuying(propaganda[])
                    buy.condition = createPropagandaCondition(propaganda)
)

const propaganda: AntiSynergy = (
    power: propagandaPower,
    rarity: 12,
    drafterRequirements: @[capitalismPower.name],
    opponentRequirements: @[americanDream.name]
)

const faminePower*: Power = Power(
    name: "Famine",
    tier: Rare,
    rarity: -999,
    priority: 55,
    description: "Secret Operation: Famine. If they die they can't be communist.",
    antiDescription: "The communes are struggling to meet our quotas. Too bad.",
    tags: @[UnHoly, UnHoly],
    icon: "sickleandhammer.svg",
    noColor: true,
    anti: true,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            randomize(s.shared.randSeed)

            for i, j in b.rankAndFile:
                if b[i][j].isColor(side) and b[i][j].item == Pawn:
                    let dice = rand(7)
                    if dice <= 2:
                        b[i][j] = air.pieceCopy(index = b[i][j].index, tile = b[i][j].tile)
)

const famine: AntiSynergy = (
    power: faminePower,
    rarity: 12,
    drafterRequirements: @[],
    opponentRequirements: @[communism.name]
)

#default values for some of `Piece`
#TODO: MOVE THESE TO `basePieces.nim`
const vampireWhenTaken*: WhenTaken = proc(taken: var Piece, taker: var Piece, board: var ChessBoard, state: var BoardState): tuple[endTile: Tile, takeSuccess: bool] = 
    if taker.item == Bishop:
        taker.pieceMove(taken, board, state)
        return (taken.tile, true)
    else:
        return (taker.tile, false)

const vampires*: Power = Power(
    name: "Vampires",
    tier: Uncommon,
    priority: 5,
    description: "Muahahaha. Your middle two pawns become vampires. Only God and His bishops can kill them now. Muahaha.",
    tags: @[UnHoly, Virus],
    icon: "vampire.svg",
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            if side == black:
                if b[1][3].item == Pawn:
                    b[1][3].whenTaken = vampireWhenTaken
                    b[1][3].filePath = "vampire.svg"
                if b[1][4].item == Pawn:
                    b[1][4].whenTaken = vampireWhenTaken
                    b[1][4].filePath = "vampire.svg"
            elif side == white:
                if b[6][3].item == Pawn:
                    b[6][3].whenTaken = vampireWhenTaken
                    b[6][3].filePath = "vampire.svg"
                if b[6][4].item == Pawn:
                    b[6][4].whenTaken = vampireWhenTaken   
                    b[6][4].filePath = "vampire.svg"     
)

const godPower*: Power = Power(
    name: "God",
    tier: UltraRare,
    priority: 7,
    description: "Well, I guess He's here. ",
    antiDescription: "Well, I guess He's here. ",
    icon: "cross.svg",
    noColor: true,
    anti: true,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            if side == black:
                if b[1][3].item == Pawn:
                    b[1][3].whenTaken = defaultWhenTaken
                if b[1][4].item == Pawn:
                    b[1][4].whenTaken = defaultWhenTaken
            elif side == white:
                if b[6][3].item == Pawn:
                    b[6][3].whenTaken = defaultWhenTaken
                if b[6][4].item == Pawn:
                    b[6][4].whenTaken = defaultWhenTaken   
)

const god: AntiSynergy = (
    power: godPower,
    rarity: -999,
    drafterRequirements: @["Holy"], #can't do .name because `Holy` is in `power.nim`
    opponentRequirements: @[vampires.name]
)

const buck: WhenTaken = proc (taken: var Piece, taker: var Piece, board: var ChessBoard, state: var BoardState): tuple[endTile: Tile, takeSuccess: bool] = 
    if taken.isColor(white) and board[taken.tile.tileBelow].isAir():
        board[taken.tile.tileBelow] = state.side[white].dna[Pawn].pieceCopy(index = newIndex(state), tile = taken.tile.tileBelow)
    elif taken.isColor(black) and board[taken.tile.tileAbove].isAir():
        board[taken.tile.tileAbove] = state.side[black].dna[Pawn].pieceCopy(index = newIndex(state), tile = taken.tile.tileAbove)

    return defaultWhenTaken(taken, taker, board, state)

const rider*: Power = Power(
    name: "Rider",
    tier: Uncommon,
    priority: 5,
    description: "Someone has to be riding the horse right? A pawn spawns behind your knights when they die, if the space is free.",
    tags: @[Knight, Pawn],
    icon: knightIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            Knight.change(side, b, s,
                whenTaken = buck
            )
)

const huhBuck: WhenTaken = proc (taken: var Piece, taker: var Piece, board: var ChessBoard, state: var BoardState): tuple[endTile: Tile, takeSuccess: bool] = 
    if taker.item == Queen and taker.sameColor(taken):
        for i in -1..1:
            for j in -1..1:
                let shoot = shooterFactory(i, j)
                if board[taken.tile.shoot].isAir():
                    board[taken.tile.shoot] = state.side[taken.color].dna[Pawn].pieceCopy(index = newIndex(state), tile = taken.tile.shoot)
    
    return buck(taken, taker, board, state)

const huhPower*: Power = Power(
    name: "HUH",
    tier: UltraRare,
    rarity: -999,
    priority: 7,
    description: "HUH.",
    icon: knightIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            Knight.change(side, b, s,
                whenTaken = huhbuck
            )
)

const huh: Synergy = (
    power: huhPower,
    rarity: -999,
    requirements: @[stepOnMe.name, rider.name],
    replacements: @[]
)

const frostTake: OnAction = proc (piece: var Piece, taking: Tile, board: var ChessBoard, state: var BoardState) = 
    inc piece.timesMoved
    let takeResult = taking.takenBy(piece, board, state)
    if takeResult.takeSuccess:
        board[takeResult.endTile.rank][takeResult.endTile.file].piecesTaken += 1

        for transform in [tileAbove, tileBelow, tileRight, tileLeft]:
            if board.boardRef(takeResult.endTile.transform).isSome() and not board[takeResult.endTile.transform].isAir(): #if the piece at that location exists
                echo takeResult.endTile.transform
                freeze(takeResult.endTile.transform, 1, piece.color, board)

const frostQueen*: Power = Power(
    name: "Ice Queen",
    tier: Uncommon,
    priority: 15,
    description: 
        """She's a real ice queen. When you queen takes a piece, she applies Frozen 1 to all neighboring pieces (yours and your opponents). 
            Frozen X reduces takes X moves (not takes) from a piece. It lasts 5 turns.""",
    tags: @[Queen, Status, Take],
    icon: queenIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            Queen.change(side, b, s, 
                onTake = frostTake    
            )
)

const kingClaudius*: Power = Power(
    name: "King Claudius",
    tier: Common,
    rarity: 2,
    priority: 40,
    description:
        """The serpent that did sting thy father’s life /
            Now wears his crown.""",
    tags: @[Status, Status],
    icon: kingIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == King and b[i][j].isColor(otherSide(side)):
                    b[i][j].status[Poisoned] = some((
                        strength: 120,
                        turnsLeft: 120, #i dont think this matters, but still
                        afflicter: side
                    ))
)
#[
const frostyWind*: Power = Power(
    name: "Frosty Wind",
    tier: Uncommon,
    rarity: 2,
    priority: 30,
    description: 
        """It's surprisngly chilly. Your opponent's middle 4 pawns start with Frozen 12. 
            Frozen impedes the movment, not taking ability, of pieces for a 5 turns.""",
    tags: @[Status, Develop],
    icon: pawnIcon, #TODO make a better icon
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            let rank = if side == white: 1 else: 6
            for i in 2..5:
                if not b[rank][i].isAir():
                    b[rank][i].tile.freeze(12, side, b) #since freeze needs the tile and i don't feel like writing another version
)

#helper function to give a new tile one off depending on the seed
#I know that its technically uneven, but its a game so who cares
#really it gives it personality
func randTileStep(tile: Tile, seed: int): Tile = 
    if seed <= 2:
        return tile.tileAbove
    elif seed <= 5:
        return tile.tileAbove
    elif seed <= 7:
        return tile.tileLeft
    else:
        return tile.tileRight

proc createBlizzardAction*(seed: int): BoardAction =
    var path: seq[int]

    var counter = 1
    while seed div counter != 0:
        path.add((seed div counter) mod 10)
        counter *= 10


    var location: Tile = (file: 3, rank: 3)
    counter = 0 #Reusing if for the closure
    result.priority = 25
    result.action = proc (side: Color, board: var ChessBoard, state: var BoardState) =  
        let step = path[counter mod path.len]
        location = location.randTileStep(step)
        inc counter

        for i in -1..1:
            for j in -1..1:
                discard nil]#
                


const millerTypeAPlusB*: Power = Power(
    name: "Miller Type A + B Snowstorm",
    tier: Uncommon,
    rarity: 2,
    priority: 30,
    description: 
        """Due to the harmonization of the polar vortexes, a Miller Type A + B Snowstorm is likely. 
            The snowstorm is currently in the middle of the board, though it appears to be moving.""",
    tags: @[Status, Develop],
    icon: pawnIcon, #TODO make a better icon
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            let rank = if side == white: 1 else: 6
            for i in 2..5:
                if not b[rank][i].isAir():
                    b[rank][i].tile.freeze(12, side, b) #since freeze needs the tile and i don't feel like writing another version
)

const terminalIllnessPower*: Power = Power(
    name: "Terminal Illness",
    tier: Uncommon,
    rarity: -999,
    priority: 40,
    description:
        """It's a little cruel, but all's fair in love and war. Give your opponent's queen Poison 17. 
            Poison decrements by 1 each turn, and at Poison 0 the unit dies.""",
    antiDescription: "Better make a last stand...",
    anti: true,
    tags: @[Status, UnHoly],
    icon: queenIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            for i, j in b.rankAndFile:
                if b[i][j].item == Queen and b[i][j].isColor(side):
                    b[i][j].status[Poisoned] = some((
                        strength: 17,
                        turnsLeft: 17, #i dont think this matters, but still
                        afflicter: side
                    ))
)

const terminalIllness: AntiSynergy = (
    power: terminalIllnessPower,
    rarity: 2,
    drafterRequirements: @[],
    opponentRequirements: @[empress.name]
)

const lastStandPower*: Power = Power(
    name: "Last Stand",
    tier: UltraRare,
    rarity: -999,
    priority: 17,
    description: "Take it all.",
    tags: @[Special],
    icon: queenIcon,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard, s: var BoardState) = 
            Queen.buff(side, b, s, 
                moves = @[whiteDiagnalMoves, blackDiagnalMoves, leftTwiceMoves, rightTwiceMoves, 
                            giraffeMoves, knightMoves, nightriderMoves, blackForwardTwiceJumpMove,
                            whiteForwardTwiceJumpMove
                        ],
                takes = @[whiteDiagnalTakes, blackDiagnalTakes, leftTwiceTakes, rightTwiceTakes, 
                            cannibalKnightTakes, cannibalGiraffeTakes, blackForwardTwiceJumpTake,
                            whiteForwardTwiceJumpTake, rookBombard
                        ]
            )

)

const lastStand: Synergy = (
    power: lastStandPower,
    rarity: 12,
    requirements: @[terminalIllness.power.name],
    replacements: @[]
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
registerPower(communism)
registerPower(vampires)
registerPower(rider)
registerPower(frostQueen)
registerPower(kingClaudius)
registerPower(millerTypeAPlusB)

registerPower(skyGlass)
registerPower(zeroGlass)
registerSynergy(bankruptcyGlass)
registerPower(steelGlass)
registerPower(reverieGlass)
registerPower(daybreakGlass)

registerSynergy(samuraiSynergy)
registerSynergy(calvaryCharge)
registerSynergy(differentGame)
registerSynergy(linebackers)
registerSynergy(holyBishop)
registerSynergy(bountyHunter)
registerSynergy(holyConversion)
registerSynergy(divineWind)
registerSynergy(superPawn, true)
registerSynergy(queensWrath, true)
registerSynergy(queensWrath2, true)
registerSynergy(battleFormation, true)
registerSynergy(queensWrathSuper, true)
registerSynergy(calvaryGiraffe, true) #both of these would be secret secret synergies
registerSynergy(lesbianBountyHunter, true) #but flavor text is fun
registerSynergy(drunkNightRider, true)
registerSynergy(drunkNightRider2, true)
registerSynergy(clarity, true)
registerSynergy(masterGlass, true)
registerSynergy(masterGlass2, true)
registerSynergy(comucapital, true)
registerSynergy(huh, true)
registerSynergy(lastStand)

registerSynergy(capitalismTwo1)
registerSynergy(capitalismTwo2)
registerSynergy(capitalismTwo3)
registerSynergy(capitalismThree1)
registerSynergy(capitalismThree2)
registerSynergy(capitalismFour1)
registerSynergy(capitalismFour2)
registerSynergy(capitalismFive1)
registerSynergy(capitalismFive2)
registerSynergy(capitalismTwoThousand, true)
registerSynergy(slumdogBillionaire, true)
registerSynergy(bounty, true)
registerSynergy(bounty2, true)

registerSynergy(virus, true)
registerSynergy(virus2, true)
registerSynergy(virus3, true)
registerSynergy(virus4, true)
registerSynergy(virus5, true)
registerSynergy(virus6, true)
registerSynergy(virus7, true)

registerSynergy(masochistEmpress, true, true)

registerAntiSynergy(undeveloped)
registerAntiSynergy(phalanx)
registerAntiSynergy(coldWar1, true)
registerAntiSynergy(coldWar2, true)
registerAntiSynergy(propaganda)
registerAntiSynergy(famine)
registerAntiSynergy(god, true)
registerAntiSynergy(terminalIllness)
registerAntiSynergy(queensWrathAnti)
registerAntiSynergy(queensWrathSuperAnti)

#All powers with rng involved
#so user can disable them if they want
const rngPowers* = @[alcoholism, drunkKnights, civilians, slumdogMillionaire, stupidPower, sleeperAgent, conversion, faminePower]
const experimentalPowers* = @[skyGlass, zeroGlass, steelGlass, reverieGlass, daybreakGlass]