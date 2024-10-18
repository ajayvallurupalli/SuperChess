include karax / prelude
import piece, basePieces, port, power, powers, karax/errors
from strutils import split, parseInt
from sequtils import foldr, mapIt

#[TO DO
Check if a handshake is needed when drafting, or if no data would be lost
---add priotirty sustem to powers to fix conflicting issues2
---add invisible borders to prevent odd resizing when clicking
lots of playtesting
---maybe rework promotion to an onpromotion: onAction type thing
    it would be more work, but it could allow for cool sunergies
    instead of restricting extra pieces
    but it would also require a canPromote function
    maybe it would be best to just use synergies 
    as long as it is decently robust by replacing requirements (see below)
---also make synergies cancel their replacements in executeOn
---also make whentake return a flag for if the take succeeded
    so that base function knows to increment piecestaken and do stuff
    also rename it to whenTaken, not sure why that hasn't happened yet
maybe change pieceMove and pieceSwap to have board be the first argument
---change power.icon to only require file name and default include path to icons
and give options for white and black
---and make black options for shogi pieces (fixed with rotate property)
---increase max height for drafts 
---stop queen from taking itself with step on me
click enter to enter join code
why doesn't rematching work?????
]#

const iconsPath: string  = "./icons/"

type 
    Screen {.pure.} = enum 
        Lobby, CreateRoom, JoinRoom, Game, Options, Draft, Results, Rematch, Disconnect
    Gamemode = enum 
        Normal, Random, TrueRandom

var roomId: tuple[loaded: bool, value: kstring] = (false, "Waiting...")
var peer: tuple[send: proc(data: cstring), destroy: proc()]
var side: Color# = white # = white only for testing, delete
var turn: bool# = true# = true#only for testing
var myDrafts: seq[Power]# = @[knightChargePower, calvary]
var opponentDrafts: seq[Power]# = @[knightChargePower, developed]

var draftOptions: seq[Power]
var draftChoices: int = 3
var drafts: int = 2 #ignore how this is one less than actual draft, i will fix eventually
var rematch = false

var theBoard: ChessBoard = startingBoard()
var selectedTile: Tile = (file: -1, rank: -1)
var possibleMoves: Moves = @[]
var possibleTakes: Moves = @[]

var currentScreen: Screen = Lobby # = Draft
var gameMode: Gamemode# = TrueRandom #deubg

#also for debugging
myDrafts.executeOn(white, side, theBoard)
opponentDrafts.executeOn(black, side,theBoard)

proc alert(s: cstring) {.importjs: "alert(#)".}

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
    discard nil

proc draft(allDrafts: seq[Power] = @[], drafter: seq[Power] = @[]) = 
    if gameMode == TrueRandom:
        draftOptions = draftRandomPower(allDrafts, drafter, draftChoices)

proc endRound() = 
    if gameIsOver(theBoard):
        currentScreen = Results

proc hostLogic(d: string, m: MessageType) = 
    echo $m, " of ", d, "\n"
    case m
    of Id: 
        roomId = (true, d.kstring)
        side = white
    of HandShake: 
        peer.send("options:deciding")
        currentScreen = Options
        theBoard = startingBoard()
        myDrafts = @[]
        opponentDrafts = @[]
        drafts = 2
    of Draft:
        var x = d.split(",")
        if x[0] == "my":
            turn = true
            opponentDrafts.add(powers[parseInt(x[1])])
            if drafts >= 1:
                dec drafts
                draft(myDrafts & opponentDrafts, myDrafts)
            else:
                myDrafts.executeOn(white, side, theBoard)
                opponentDrafts.executeOn(black, side, theBoard)
                peer.send("handshake:gamestart")
                currentScreen = Game
                echo myDrafts.mapIt(it.name), opponentDrafts.mapIt(it.name)


    of Move: otherMove(d)
    of End:
        if d == "disconn" or d == "exit":
            currentScreen = Disconnect
        else:
            peer.send("end:exit")
        peer.destroy()
        roomId.loaded = false
    else: echo "unimplemented"
    redraw()

proc joinLogic(d: string, m: MessageType) = 
    echo $m, " of ", d, "\n"
    case m
    of Options:
        currentScreen = Options
        side = black
        turn = false        
        theBoard = startingBoard()
        myDrafts = @[]
        opponentDrafts = @[]
    of Handshake:
        myDrafts.executeOn(black, side, theBoard)
        opponentDrafts.executeOn(white, side, theBoard)
        currentScreen = Game    
    of Rematch:
        if rematch:
            rematch = false
            peer.send("handshake:newgame")
        else: 
            rematch = true
    of Draft: 
        var x = d.split(",")
        if d == "start":
            currentScreen = Draft
        elif x[0] == "my":
            opponentDrafts.add(powers[parseInt(x[1])])
        elif x[0] == "go":
            draftOptions = @[]
            for i in x[1..^1]:
                draftOptions.add(powers[parseInt(i)])
            
            turn = true
    of Move: 
        otherMove(d) 
        endRound()   
    of End:
        if d == "disconn" or d == "exit":
            currentScreen = Disconnect
        else:
            peer.send("end:exit")
        peer.destroy()
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
    if isSelected(m, n) and possibleTakes.contains(p.tile):
        class &= " can-take"
    elif isSelected(m,n):
        class &= " selected"
    elif possibleMoves.contains(p.tile):
        class &= " can-move"
    elif possibleTakes.contains(p.tile):
        class &= " can-take"
    else:
        class &= " unselected"

    result = buildHtml():
        td(class=class):
            proc onclick(_: Event; _: VNode) =           
                if possibleMoves.contains(p.tile) and turn and pieceOf(selectedTile).isColor(side):
                    sendMove("move", selectedTile, p.tile)
                    pieceOf(selectedTile).onMove(selectedTile, p.tile, theBoard)
                    possibleMoves = @[]
                    selectedTile = (-1,-1)
                    possibleTakes = @[]
                    endRound()
                elif possibleTakes.contains(p.tile) and turn and pieceOf(selectedTile).isColor(side):
                    sendMove("take", selectedTile, p.tile)
                    pieceOf(selectedTile).onTake(selectedTile, p.tile, theBoard)
                    possibleTakes = @[]
                    selectedTile = (-1, -1)
                    possibleMoves = @[]
                    endRound()
                elif not isSelected(m, n):
                    selectedTile = (n, m)
                    possibleMoves = p.getMovesOn(theBoard)        
                    possibleTakes = p.getTakesOn(theBoard)            
                else:
                    selectedTile = (-1,-1)
                    possibleMoves = @[]
                    possibleTakes = @[]

            if p.filePath == "":
                text $p
            else:
                let class = if p.rotate: "rotate" else: ""
                img(src = iconsPath & p.filePath, class = class)

proc createBoard(): VNode =
    result = buildHtml(table):
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
    result = buildHtml(tdiv(class="column")):                
        tdiv(class="main"):
            button: 
                text "Join a Room"
                proc onclick(_: Event; _: VNode) = 
                    currentScreen = JoinRoom
            button:
                proc onclick(ev: Event; _: VNode) = 
                    if not peer.destroy.isNil():
                        peer.destroy()
                    peer = newHost(hostLogic)
                    
                    currentScreen = CreateRoom
                text "Create a Room"

        a(href = "https://docs.google.com/forms/d/e/1FAIpQLScSidB_dbpKlsWopscLZZn4ZJP_5U9gqb0WyMJ4-bN_yAruSg/viewform?usp=sf_link", target="_blank", rel="noopener noreferrer"):
            text "Feedback form! Please fill out!"

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
    result = buildHtml(tdiv(class="main", id = "join")):
        label(`for` = "joincode"):
            text "Join Code:"
        input(id = "joincode", onchange = validateNotEmpty("joincode"))
        button:
            proc onclick(ev: Event; v: VNode) = 
                let id = getVNodeById("joincode").getInputText
                echo getVNodeById("joincode")
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
                    proc onclick(_: Event, _: VNode) = 
                        alert("This mode hasn't been made yet. Play random mode if you want to play with powers, or normal if you just want normal chess.")

                    text "Draft mode"
                text """Take turns drafting power ups for your pieces, then play. 
                        Each side is guaranteed to get power ups of the same tier."""

            tdiv(class="column"):
                button:
                    proc onclick(_: Event, _: VNode) = 
                        peer.send("draft:start")
                        currentScreen = Draft
                        gameMode = TrueRandom
                        turn = true
                        draft()
                        

                    text "Random mode"

                text """Draft powerups of random strength and quality, then play. 
                        Completely luck based."""
                        
proc createPowerMenu(p: Power): VNode = 
    result = buildHtml(tdiv(class="power")):
        h1:
            text p.name
        if p.icon != "":
            img(src=iconsPath & p.icon)
        else:
            img(src="./icons/blackbishop.svg") #placeholder, delete when images are found
        h2:
            text $p.tier
        p:
            text p.description
        
        proc onclick(_: Event, _: VNode) = 
            peer.send("draft:my," & $p.index)
            myDrafts.add(p)
            turn = false
            if side == white:
                draft(myDrafts & opponentDrafts, opponentDrafts)
                peer.send("draft:go" &  draftOptions.mapIt("," & $it.index).foldr(a & b))

proc createDraftMenu(): VNode = 
    result = buildHtml(tdiv(class="main power-menu")):
        if turn:
            for p in draftOptions:
                createPowerMenu(p)
        else:
            text "Opponent is drafting..."

proc createPowerSummary(p: Power): VNode = 
    result = buildHtml(tdiv(class="power-grid")):
        h4(class = "title"):
            text p.name
        p(class="small-text desc"):
            text p.description
        if p.icon != "":
            img(class = "image", src = iconsPath & p.icon)
        else:
            img(class = "image", src = iconsPath & "blackbishop.svg")

proc createGame(): VNode = 
    result = buildHtml(tdiv(class="main")):
        tdiv(class="column-scroll"):
            for p in myDrafts.replaceAnySynergies():
                createPowerSummary(p)
        if side == white: createBoard() else: reverseBoard()
        tdiv(class="column-scroll"):
            for p in opponentDrafts.replaceAnySynergies():
                createPowerSummary(p)

proc createResults(): VNode = 
    result = buildHtml(tdiv(class="column")):
        if side.alive(theBoard):
            h1:
                text "You won!"
        else:
            h1: 
                text "You lost..."
        
        button:
            proc onclick(_: Event, _: VNode) = 
                if side == black:
                    joinLogic("", Rematch)
                else:
                    peer.send("rematch:please")
                currentScreen = Rematch
            text "Rematch"

        button: 
            proc onclick(_: Event, _: VNode) = 
                if side == white:
                    hostLogic("", End)
                elif side == black:
                    joinLogic("", End)
                currentScreen = Lobby

            text "Back to Lobby"

proc createRematch(): VNode = 
    result = buildHtml(tdiv(class="main")):
        text "Waiting for opponent to accept..."
        button:
            proc onclick(_: Event, _: VNode) = 
                currentScreen = Lobby
                peer.send("end:exit")
            text "Back to Lobby"


proc createDisconnect(): VNode = 
    result = buildHtml(tdiv(class="column")):
        text "Your opponent disconnected"
        button:
            proc onclick(_: Event, _: VNode) = 
                currentScreen = Lobby
            text "Back to Lobby"

proc main(): VNode = 
    result = buildHtml(tdiv(class="main")):
        case currentScreen
        of Lobby: createLobby()
        of CreateRoom: createRoomMenu()
        of JoinRoom: createJoinMenu()
        of Options: createOptionsMenu()
        of Draft: createDraftMenu()
        of Game: createGame()
        of Results: createResults()
        of Rematch: createRematch()
        of Disconnect: createDisconnect()


setRenderer main