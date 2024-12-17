#TODO remove Rank and File types since I forgot to use them, or maybe try to use them
#think about unifying GlassMoves and BuyCondition
#all the types are defined here, even though their implementations are in other files, to fix cyclical definitons with `Piece`
#I could have put it in a new file, but I didn't. The reason remains one of the world's greatest mysteries. 
import std/options
from sequtils import filterIt, mapIt

type
    Tile* = tuple[file: int, rank: int] #used for position of all pieces

    #The main data structure which holds the entire state of the board
    #It is created in `basePieces.startingBoard.nim`
    ChessRow* = array[0..7, Piece]
    ChessBoard* = array[0..7, Chessrow] 

    #TODO FINISH
    MiniChessRow* = array[0..4, Piece]
    MiniChessBoard* = array[0..4, MiniChessRow]

    #none is used for empty spaces
    #fairy is used for custom spaces defined in `Powers.nim`
    PieceType* = enum
        King, Queen, Bishop, Pawn, Rook, Knight, None, Fairy
    Color* = enum
        black, white

    #The functions and implementations of these are defined in `moves.nim` and `board.nim`
    Moves* = seq[Tile] 
    #takes the state of the board and a piece, and returns possible `Moves` by that piece
    #It only needs to return one type of moves (like one row forward), since 
    #`Piece` takes a `seq` of `Moves`
    MoveProc* = proc (board: ChessBoard, piece: Piece): Moves {.noSideEffect.}
    Shooter* = proc (tile: Tile): Tile {.noSideEffect.}

    #`OnAction` is used when `piece` tries to move to `to`
    #it mutates the piece and the board
    OnAction* = proc (piece: var Piece, to: Tile, board: var ChessBoard, state: var BoardState)
    #`WhenTaken` is called by the `taker Piece` when it attempts to take `taken Piece`
    #It can mutate both pieces, so `endTile` should be used to access `taker` after, since `taken` and `taker` will can after this is called
    #This is one of the sad truths of the code base, but I couldn't find anyway to change the board and not change the object given
    #`takeSuccess` also returns true if the `taken` piece is killed by `taker`
    WhenTaken* = proc (taken: var Piece, taker: var Piece, board: var ChessBoard, state: var BoardState): tuple[endTile: Tile, takeSuccess: bool]
    #`OnPiece` is used for a transformtion directly on the picece itself
    #TODO rewrite OnPiece or template to track index, so that it can't be hald done
    OnPiece* = proc (piece: var Piece, board: var ChessBoard, state: var BoardState)
    #`BoardAction` is used to describe a transformation on the state itself, build from the current state
    #it is the most general action
    BoardAction* = proc (side: Color, board: var ChessBoard, state: var BoardState)


    #Capitalism stuff
    BuyCondition* = proc (piece: Piece, board: ChessBoard, s: BoardState): bool {.noSideEffect.}
    BuyCost* = proc (piece: Piece, board: ChessBoard, s: BoardState): int {.noSideEffect.}
    BuyOption* = tuple[name: string, cost: BuyCost, action: OnPiece, condition: BuyCondition]

    #Glass Stuff
    Casting* = tuple[on: Tile, group: int, glass: GlassType]
    GlassType* = enum 
        Sky, Zero, Steel, Reverie, Daybreak
    GlassMoves* = proc (side: Color, piece: Piece, b: ChessBoard, s: BoardState): Moves {.noSideEffect.}
    GlassTile* = proc (side: Color, piece: Piece, castedTile: Tile): Tile {.noSideEffect.}#I am the king of over engineering
    GlassAbility* = tuple
        strength: int
        action: OnAction
        condition: GlassMoves
    Glasses* = array[GlassType, Option[GlassAbility]]

    Piece* = object
        item*: Piecetype
        color*: Color
        index*: int #index is used for equality. if `p1.index == p2.index` then `p1 == p2`
        timesMoved*: int = 0
        piecesTaken*: int = 0
        tile*: Tile = (file: -1, rank: -1)
        moves*: seq[MoveProc]  #list of procs which return moves
        takes*: seq[MoveProc]
        onMove*: OnAction  #on___ and whenTaken are methods for the objecy
        onTake*: OnAction   #methods are on the object because it makes them more dynamic
        whenTaken*: WhenTaken 
        onEndTurn*: seq[OnPiece] 
        onPromote*: seq[OnPiece]
        promoted*: bool = false
        filePath*: string = ""
        colorable*: bool = true
        rotate*: bool = false
        drunk*: bool = false
        casts*: seq[Casting]

    #`BoardState` is used for state common to all pieces
    #`.shared` is used by both sides
    #while `.side[white]` or `.side[black]` is for state unique to each side
    BoardState* = tuple[shared: SharedState, side: array[Color, SideState]]

    SharedState*  = object
        nextIndex: int = 1 #hidden because `newIndex` should be used instead to ensure proper management
        nextGroup: int = 1 #hidden because `newGroup` should be used instead to ensure proper management
        randSeed*: int = 0
        turnNumber*: int = 0

        mutuallyAssuredDestruction*: bool = false

    SideState* = object
        abilityTakes*: int = 0 #takes from ability. I could put on a piece, but it would cause issues with some powers
        hasCastled*: bool = false #since this state is very easy to alter and still won't complicate namespace, I might as well go hogwild with variables 
        communist*: bool = false

        #used as prototypes for the pieces. When a piece is buffed, its dna should be buffed too
        #I don't know how to slice PieceType to exclude air and fairy, so just don't use them
        dna*:  array[PieceType, Piece]
        onEndTurn*: seq[BoardAction]

        #For capitalism powers
        wallet*: Option[int] = none(int)
        buys*: seq[BuyOption] = @[]
        piecesSold*: int = 0 #Just for Capitalism Sell
        piecesSoldThisTurn*: int = 0

        glass*: Glasses = arrayWith(none(GlassAbility), GlassType.high.ord.succ) #high.ord.succ finds length of enum. I could do high.ord + 1 but .succ looks cooler

#returns a tuple for each rank file pair of the board
#so this 
#```for i in 0..<board.len:
#        for j in 0..<board[0].len:```
#is replaced with
#```for i, j in rankAndFile(board):```
iterator rankAndFile*(board: ChessBoard): Tile = 
    for i in 0..<board.len:
        for j in 0..<board[0].len:
            yield (i, j)

#takes a sequence and zips it into pairs
iterator byTwo*[T](s: seq[T]): tuple[a: T, b: T] {.inline.} = 
    assert s.len mod 2 == 0 #assert even number
    var index = 0
    while index < s.len:
        yield (s[index], s[index + 1])
        index += 2

#about time I did this
#allows board to be index like `board[tile]`
#instead of previous `board[tile.rank][tile.file]`
#not sure what {.inline.} does, but the docs use it
#TODO: USE THIS EVERYWHERE
func `[]`*(b: ChessBoard, tile: Tile): Piece {.inline.} = 
    return b[tile.rank][tile.file]

#var version
#techincally nim doesn't count refs as side effects, but I do
proc `[]`*(b: var ChessBoard, tile: Tile): var Piece {.inline.} = 
    return b[tile.rank][tile.file]

#for assigning
proc `[]=`*(b: var ChessBoard, tile: Tile, newPiece: Piece) {.inline.} = 
    b[tile.rank][tile.file] = newPiece

#I don't know how to get the option version to work, so I'm returning tile
func tileOf*(board: var ChessBoard, index: int): Option[Tile] = 
    for i, j in board.rankAndFile:
        if board[i][j].index == index: return some(board[i][j].tile)
    
    return none(Tile)

func `==`*(a: Piece, b: Piece): bool = 
    return a.index == b.index

#TODO RENAME TO emptyOnPiece
const defaultOnEndTurn*: OnPiece = proc (piece: var Piece, board: var ChessBoard, state: var BoardState) = 
        discard nil

const emptyOnAction*: OnAction = proc (piece: var Piece, to: Tile, board: var ChessBoard, state: var BoardState) = 
        discard nil

#helper templates for `Piece` methods
#since methods are properties of the class, you would usually have to do `Piece.method(Piece)`
#since you need to access it in `Piece` and pass `Piece`
#these templates fix that boilerplate a little bit
template move* (p: var Piece, to: Tile, b: var ChessBoard, s: var BoardState): untyped = 
    p.onMove(p, to, b, s)

template take* (p: var Piece, to: Tile, b: var ChessBoard, s: var BoardState): untyped = 
    p.onTake(p, to, b, s)

template promote* (p: var Piece, b: var ChessBoard, s: var BoardState): untyped = 
    let promotes = p.onPromote #we copy promotes so that the piece can change without promotes changing mid loop
    for x in promotes:
        x(p, b, s)

    p.promoted = true

template endTurn* (p: var Piece, b: var ChessBoard, s: var BoardState): untyped = 
    for x in p.onEndTurn:
        x(p, b, s)

template takenBy*(taken: var Piece, taker: var Piece, b: var ChessBoard, state: var BoardState): tuple[endTile: Tile, takeSuccess: bool] = 
    taken.whenTaken(taken, taker, board, state)

template takenBy*(taken: Tile, taker: var Piece, b: var ChessBoard, state: var BoardState): tuple[endTile: Tile, takeSuccess: bool] = 
    board[taken.rank][taken.file].whenTaken(board[taken.rank][taken.file], taker, b, state)

#returns a new unique index for `Piece.index`. 
#this ensures that each index given is unique by privately managing `state.shared.nextIndex`
proc newIndex*(s: var BoardState): int = 
    inc s.shared.nextIndex
    return s.shared.nextIndex
    
#returns a new unique group for `Casting.group`. 
#this ensures that each group given is unique by privately managing `state.shared.nextGroup`
proc newGroup*(s: var BoardState): int = 
    inc s.shared.nextGroup
    return s.shared.nextGroup

func getTakesOn*(p: Piece, board: ChessBoard): Moves = 
    for x in p.takes:
        result.add(x(board, p))

#I'm not sure if I've done a perfect job at ensuring that 
#takes and moves are disjoint, so I'm going to be overkill for now
#while running some tests
#I really wish I could use a set, but nim doesn't allow implementing traits like ordinal
#at least I don't think
#I could use hashset, but the conversion seems kind of annoying
func getMovesOn*(p: Piece, board: ChessBoard): Moves = 
    for x in p.moves:
        result.add(x(board, p))
    let takes = getTakesOn(p, board)
    for x in takes: #debug for study
        if x in result: debugEcho $x, " is a take and a move"
    result = result.filterIt(it notin takes)

#handles movement of `Piece p` from `p.tile` to `(rank: rank, file: file)`
#after moving `Piece p`, it kills its past location by setting it to air
#and kills its goal location by replacing it
#this proc mutates `p`, so any effects must happen before or `p` must be found again
#`BoardState` is needed to ensure the new air has a new unique `Piece.index`
proc pieceMove*(p: var Piece, rank: int, file: int, board: var ChessBoard, state: var BoardState) = 
    board[rank][file] = board[p.tile.rank][p.tile.file]
    board[p.tile.rank][p.tile.file] = Piece(index: newIndex(state), item: None, tile: p.tile)
    board[rank][file].tile = (file: file, rank: rank)

#overloads for piece move
proc pieceMove*(p: var Piece, t: Tile, board: var ChessBoard, state: var BoardState) = 
    pieceMove(p, t.rank, t.file, board, state)

proc pieceMove*(p: Tile, t: Tile, board: var ChessBoard, state: var BoardState) = 
    pieceMove(board[p.rank][p.file], t.rank, t.file, board, state)

proc pieceMove*(p: var Piece, t: Piece, board: var ChessBoard, state: var BoardState) = 
    pieceMove(p, t.tile.rank, t.tile.file, board, state)

#like `pieceMove`, but swaps `p1.tile` and `p2.tile` instead of killing `p2.tile`
#it does not need `BoardState` because `Piece.index`s are preserved in swap
proc pieceSwap*(p1: Piece, p2: Piece, board: var ChessBoard) = 
    let temp = p1

    board[p1.tile.rank][p1.tile.file] = p2
    board[p2.tile.rank][p2.tile.file] = temp
    board[p1.tile.rank][p1.tile.file].tile = (file: p1.tile.file, rank: p1.tile.rank)
    board[temp.tile.rank][temp.tile.file].tile = (file: temp.tile.file, rank: temp.tile.rank)

#default values for some of `Piece`
#TODO: MOVE THESE TO `basePieces.nim`
const defaultWhenTaken*: WhenTaken = proc(taken: var Piece, taker: var Piece, board: var ChessBoard, state: var BoardState): tuple[endTile: Tile, takeSuccess: bool] = 
    taker.pieceMove(taken, board, state)
    return (taken.tile, true)

const defaultOnMove*: OnAction = proc (piece: var Piece, to: Tile, b: var ChessBoard, state: var BoardState) = 
    inc piece.timesMoved
    piece.pieceMove(to, b, state)

const defaultOnTake*: OnAction = proc (piece: var Piece, taking: Tile, board: var ChessBoard, state: var BoardState) = 
    inc piece.timesMoved
    let takeResult = taking.takenBy(piece, board, state)
    if takeResult.takeSuccess:
        board[takeResult.endTile.rank][takeResult.endTile.file].piecesTaken += 1

#Very bulky function that creates a new `Piece` using the values of a  `initial Piece`
#it also requires an index so that the user can decide how the new piece is related to the old piece
#I'm sure there is some nim function to do this, but I don't know what. Maybe deepCopy?
func pieceCopy*(initial: Piece, index: int, tile: Tile, #index and tile are required so I don't mess up
                item: PieceType = initial.item, 
                color: Color = initial.color,
                timesMoved: int = initial.timesMoved, 
                piecesTaken: int = initial.piecesTaken,
                moves: seq[MoveProc] = initial.moves,
                takes: seq[MoveProc] = initial.takes,
                onMove: OnAction = initial.onMove,
                onTake: OnAction = initial.onTake,
                whenTaken: WhenTaken = initial.whenTaken,
                onEndTurn: seq[proc(piece: var Piece, board: var ChessBoard, state: var BoardState)] = initial.onEndTurn,
                onPromote: seq[proc(piece: var Piece, board: var ChessBoard, state: var BoardState)] = initial.onPromote,
                promoted: bool = initial.promoted,
                filePath: string = initial.filePath,
                colorable: bool = initial.colorable,
                rotate: bool = initial.rotate,
                drunk: bool= initial.drunk): Piece = 
    return Piece(index: index, item: item, color: color, timesMoved: timesMoved, piecesTaken: piecesTaken,
                tile: tile, moves: moves, takes: takes, onMove: onMove, onTake: onTake,
                whenTaken: whenTaken, onEndTurn: onEndTurn, onPromote: onPromote,promoted: promoted, filePath: filePath, rotate: rotate,
                drunk: drunk, colorable: colorable)

func isAir*(p: Piece): bool = 
    return p.item == None

func sameColor*(a: Piece, b: Piece): bool = 
    return a.color == b.color and not a.isAir() and not b.isAir()

func isColor*(a: Piece, b: Color): bool = 
    return a.color == b and not a.isAir()

func otherSide*(a: Color): Color = 
    return if a == white: black else: white

func alive*(c: Color, b: ChessBoard, s: BoardState): bool = 
    if s.side[c].communist: return true
    for row in b:
        for p in row:
            if p.item == King and p.isColor(c):
                return true

    return false

func gameIsOver*(b: ChessBoard, s: BoardState): bool = 
    var whiteAlive: bool = false
    var blackAlive: bool = false
    for row in b:
        for p in row:
            if p.isColor(white):
                if p.item == King or s.side[white].communist:
                    whiteAlive = true
                    break
            elif p.isColor(black):
                if p.item == King or s.side[black].communist:
                    blackAlive = true
                    break

    return not (whiteAlive and blackAlive)

func getPiecesChecking*(b: ChessBoard, c: Color): seq[Tile] = 
    var kingTile: Tile = (-1, -1)
    for row in b:
        for p in row:
            if p.item == King and p.isColor(c):
                kingTile = p.tile

    for row in b:
        for p in row:
            if not p.isColor(c) and kingTile in p.getTakesOn(b):
                result.add(p.tile)

func wouldCheckAt*(p: Piece, at: Tile, b: ChessBoard): bool = 
    #we make copies to avoid ruining original state
    var testboard = b
    var testpiece = p
    var emptyState: BoardState #sets to default, since we don't really need indexing
    pieceMove(testpiece, at, testboard, emptyState)
    #if the move would cause for more pieces to be checking, then we know that it would cause a check
    return getPiecesChecking(testBoard, otherSide(p.color)).len > getPiecesChecking(b, otherSide(p.color)).len

func isAtEnd*(piece: Piece): bool = 
    return (piece.tile.rank == 7 and piece.color == black) or (piece.tile.rank == 0 and piece.color == white)

func getKing*(side: Color, board: ChessBoard): Tile = 
    for i, j in board.rankAndFile:
        if board[i][j].item == King and board[i][j].color == side:
            return board[i][j].tile

func getKingPiece*(side: Color, board: ChessBoard): Piece = 
    for i, j in board.rankAndFile:
        if board[i][j].item == King and board[i][j].color == side:
            return board[i][j]

