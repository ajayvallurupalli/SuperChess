include karax / prelude
import piece, basePieces, port, karax/errors
from strutils import split, parseInt

type Screen {.pure.} = enum 
    Lobby, CreateRoom, JoinRoom, Game

var roomId: tuple[loaded: bool, value: kstring] = (false, "Waiting...")
var peer: tuple[send: proc(data: cstring), destroy: proc()]
var side: Color
var turn: bool
var theBoard: ChessBoard = startingBoard()
var selectedTile: Tile = (file: -1, rank: -1)
var possibleMoves: Moves = @[]
var possibleTakes: Moves = @[]
var currentScreen = Lobby

proc pieceOf(tile: Tile): Piece = 
    theBoard[tile.rank][tile.file]

proc isSelected(m: int, n: int): bool = 
    return selectedTile.rank == m and selectedTile.file == n

proc otherMove(d: string) = 
    let data = split(d, ",")
    let mover: Tile = (parseInt(data[2]), parseInt(data[1]))
    let moveTo: Tile = (parseInt(data[4]), parseInt(data[3]))
    echo mover, moveTo
    if data[0] == " move":
        pieceOf(mover).onMove(mover, moveTo, theBoard)
    elif data[0] == " take":
        pieceOf(mover).onTake(mover, moveTo, theBoard)
    pieceOf(moveTo).onEndTurn(moveTo, mover, theBoard)
    turn = not turn

proc sendMove(mode: string, start: Tile, to: Tile) = 
    peer.send("move: " & mode & "," & $start.rank & "," & $start.file & "," & $to.rank & "," & $to.file)
    turn = not turn

proc hostLogic(d: string, m: MessageType) = 
    echo $m, " of ", d, "\n"
    case m
    of Id: 
        roomId = (true, d.kstring)
    of HandShake: 
        peer.send("handshake: game start")
        side = white
        turn = true
        currentScreen = Game
    of Move: otherMove(d)
    else: echo "unimplemented"
    redraw()

proc joinLogic(d: string, m: MessageType) = 
    echo $m, " of ", d, "\n"
    case m
    of Handshake:
        side = black
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
                    pieceOf(p.tile).onEndTurn(p.tile, selectedTile, theBoard)
                    possibleMoves = @[]
                    selectedTile = (-1,-1)
                    possibleTakes = @[]
                elif possibleTakes.contains(p.tile) and not p.isAir() and turn and pieceOf(selectedTile).isColor(side):
                    sendMove("take", selectedTile, p.tile)
                    pieceOf(selectedTile).onTake(selectedTile, p.tile, theBoard)
                    pieceOf(p.tile).onEndTurn(p.tile, selectedTile, theBoard)
                    possibleTakes = @[]
                    selectedTile = (-1, -1)
                    possibleMoves = @[]
                elif not isSelected(n, m):
                    selectedTile = (n, m)
                    possibleMoves = p.getMovesOn(theBoard)        
                    possibleTakes = p.getTakesOn(theBoard)            
                else:
                    selectedTile = (-1,-1)
                    possibleMoves = @[]

            text $p

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

proc main(): VNode = 
    result = buildHtml(tdiv(class="main")):
        case currentScreen
        of Lobby: createLobby()
        of CreateRoom: createRoomMenu()
        of JoinRoom: createJoinMenu()
        of Game: 
            if side == white: createBoard() else: reverseBoard()


setRenderer main