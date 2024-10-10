include karax / prelude
import piece, basePieces, port, karax/errors
from strutils import split, parseInt

type 
    Screen {.pure.} = enum 
        Lobby, CreateRoom, JoinRoom, Game, Options
    Gamemode = enum 
        Normal

echo "test"

var roomId: tuple[loaded: bool, value: kstring] = (false, "Waiting...")
var peer: tuple[send: proc(data: cstring), destroy: proc()]
var side: Color # = white only for testing, delete
var turn: bool# = true #only for testing
var theBoard: ChessBoard = startingBoard()
var selectedTile: Tile = (file: -1, rank: -1)
var possibleMoves: Moves = @[]
var possibleTakes: Moves = @[]
var currentScreen = Lobby
var gameMode: Gamemode

proc pieceOf(tile: Tile): Piece = 
    theBoard[tile.rank][tile.file]

proc isSelected(n: int, m: int): bool = 
    return selectedTile.rank == n and selectedTile.file == m

proc otherMove(d: string) = 
    let data = split(d, ",")
    let mover: Tile = (parseInt(data[2]), parseInt(data[1]))
    let moveTo: Tile = (parseInt(data[4]), parseInt(data[3]))
    echo mover, moveTo
    if data[0] == " move":
        pieceOf(mover).onMove(mover, moveTo, theBoard)
    elif data[0] == " take":
        pieceOf(mover).onTake(mover, moveTo, theBoard)
    turn = not turn

proc sendMove(mode: string, start: Tile, to: Tile) = 
    peer.send("move: " & mode & "," & $start.rank & "," & $start.file & "," & $to.rank & "," & $to.file)
    turn = not turn

proc hostLogic(d: string, m: MessageType) = 
    echo $m, " of ", d, "\n"
    case m
    of Id: 
        roomId = (true, d.kstring)
        side = white
    of HandShake: 
        peer.send("options:deciding")
        currentScreen = Options
    of Move: otherMove(d)
    else: echo "unimplemented"
    redraw()

proc joinLogic(d: string, m: MessageType) = 
    echo $m, " of ", d, "\n"
    case m
    of Options:
        currentScreen = Options
        side = black
    of Handshake:
        turn = false
        currentScreen = Game
    of Move: otherMove(d)
    else: echo "unimplemented"
    redraw()

proc validateNotEmpty(field: kstring): proc () =
  result = proc () =
    let x = getVNodeById(field).getInputText
    if x.isNil or x == "":
      errors.setError(field, field & " must not be empty")
    else:
      errors.setError(field, "")

proc createTile(p: Piece, m: int, n: int): VNode = 
    var class = if (m*7+n) mod 2 == 0: "whiteTile" else: "blackTile"
    if isSelected(m,n):
        class &= " selected"
    elif possibleMoves.contains(p.tile):
        class &= " can-move"
    elif possibleTakes.contains(p.tile):
        class &= " can-take"

    result = buildHtml():
        td(class=class):
            proc onclick(_: Event; _: VNode) =           
                if possibleMoves.contains(p.tile) and p.isAir() and turn and pieceOf(selectedTile).isColor(side):
                    sendMove("move", selectedTile, p.tile)
                    pieceOf(selectedTile).onMove(selectedTile, p.tile, theBoard)
                    possibleMoves = @[]
                    selectedTile = (-1,-1)
                    possibleTakes = @[]
                elif possibleTakes.contains(p.tile) and not p.isAir() and turn and pieceOf(selectedTile).isColor(side):
                    sendMove("take", selectedTile, p.tile)
                    pieceOf(selectedTile).onTake(selectedTile, p.tile, theBoard)
                    possibleTakes = @[]
                    selectedTile = (-1, -1)
                    possibleMoves = @[]
                elif not isSelected(m, n):
                    selectedTile = (n, m)
                    possibleMoves = p.getMovesOn(theBoard)        
                    possibleTakes = p.getTakesOn(theBoard)            
                else:
                    selectedTile = (-1,-1)
                    possibleMoves = @[]
                    possibleTakes = @[]

            text $p & ""

proc createBoard(): VNode =
    result = buildHtml(tdiv):
        for i,r in theBoard:
            tr:
                for j,p in r:
                    createTile(p, i, j)

proc reverseBoard(): VNode = 
    result = buildHtml(tdiv):
        for i in countdown(7, 0):
            tr:
                for j in countdown(7, 0):
                    createTile(theBoard[i][j], i, j)

proc createLobby(): VNode = 
    result = buildHtml(tdiv(class="main")):
        button: 
            text "Join a Room"
            proc onclick(_: Event; _: VNode) = 
                currentScreen = JoinRoom
        button:
            proc onclick(_: Event; _: VNode) = 
                if not peer.destroy.isNil():
                    peer.destroy()
                peer = newHost(hostLogic)
                
                currentScreen = CreateRoom
            text "Create a Room"

proc createRoomMenu(): VNode = 
    result = buildHtml(tdiv(class="main")):
        if not roomId.loaded:
            text "Creating room key"
        else:
            h2:
                text "Room Key: "
            br()
            text roomId.value

proc createJoinMenu(): VNode = 
    result = buildHtml(tdiv(class="main")):
        label(`for` = "joincode"):
            text "Join Code:"
        input(id = "joincode", onchange = validateNotEmpty("joincode"))
        button:
            proc onclick(_: Event; _: VNode) = 
                let id = getVNodeById("joincode").getInputText
                if not peer.destroy.isNil():
                    peer.destroy()
                peer = newJoin(id, joinLogic)
                
            text "Enter"

proc createOptionsMenu(): VNode = 
    result = buildHtml(tdiv(class="main")):
        if side == black:
            text "Waiting for host to decide ruleset..."
        else:
            tdiv(class="column"):
                button:
                    proc onclick(_: Event, _: VNode) = 
                        peer.send("handshake:gamestart")
                        turn = true
                        currentScreen = Game

                    text "Normal Chess"

                text "Classic Chess, with no special rules or abilites."
                
            tdiv(class="column"):
                button:

                    text "Draft mode"
                text """Take turns drafting power ups for your pieces, then play. 
                        Each side is guaranteed to get power ups of the same tier."""

            tdiv(class="column"):
                button:

                    text "Random mode"

                text """Draft powerups of random strength and quality, then play. 
                        Completely luck based."""
proc main(): VNode = 
    result = buildHtml(tdiv(class="main")):
        case currentScreen
        of Lobby: createLobby()
        of CreateRoom: createRoomMenu()
        of JoinRoom: createJoinMenu()
        of Options: createOptionsMenu()
        of Game: 
            if side == white: createBoard() else: reverseBoard()


setRenderer main