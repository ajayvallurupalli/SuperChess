include karax / prelude
import karax/errors
import piece, basePieces, port, power, powers, store, capitalism #powers import for debug
from board import tileAbove, tileBelow
import extrapower/glass
import std/dom, std/strformat #im not sure why dom stuff fails if I don't import the whole package
import std/options, std/tables #try to expand use of this, instead of wierd tuple[has: bool stuff
from strutils import split, parseInt, join, toLower
from std/editdistance import editDistance
from sequtils import foldr, mapIt, cycle, filterIt, toSeq
from std/algorithm import reversed, sortedByIt

{.warning[CStringConv]: off.} 
#fixing the issue makes the code look bad, so I'm turning it off. Genius, I know

#[TO DO
--add consts for paths for piece svgs in powers.nim
--see if I completely failed the design and all of the OnActions should accept Pieces instead of this roundabout board indexijng
    consider rewriting it. I don't think it will be too bad since its just default methods and a few powers
--fix bombard power for castling, 
and make secret secret synergy with reinforcements so everything works. Then enable it
click enter to enter join code. I actually have no idea how to do this
make moves a set instead of a seq so that I don't have to do wierd not in stuff, and instead I can just difference
 
SUPER IMPORTANT ****If you cancel, send cancel so that the animation stops****

for steam realease
100 $
show opponent powers when drafting / waiting
--(mostly): fix css
--add screen to show all powers
    A cool animation for the more wins you have would be cool
add sandbox mode
add some more powers
learn how to use electron
try steam servers?
I want a change log which gets text files, stored in a change_logs directory on github, decodes them from base64, and loads them in
so that it is up to date whenever a new file is added to this folder
]#

const iconsPath: string  = "./icons/"
const defaultBaseDrafts: int = 3
const defaultBaseDraftChoices: int = 3

#CSS Classes
#TODO migrate to these constants
#spaces made concat easy
#maybe I should make a css type with a & that auto does this
const 
    menuButton = " menu-button "
    pieceRow = " piece-row "
    glassMenu = " glass-menu "
    height100 = " height-100 "
    width100 = " width-100 "
    settingItem = " setting-item "
    castingAnimations: array[GlassType, string] = 
        [" casting-sky ", " casting-zero ", " casting-steel ", " casting-reverie ", " casting-daybreak "] #corresponding css classes for each type
    castingOnAnimations: array[GlassType, string] = 
        [" casting-on-sky ", " casting-on-zero ", " casting-on-steel ", " casting-on-reverie ", " casting-on-daybreak "]#corresponding css classes for each type

type 
    Screen {.pure.} = enum 
        Lobby, CreateRoom, JoinRoom, Game, Options, Draft, 
        Results, Rematch, Disconnect, Settings, Other, SeePower, Test
    Gamemode {.pure.} = enum 
        Normal, RandomTier, TrueRandom, SuperRandom
    Tab {.pure.} = enum
        My, Opponent, Control, Debug
    ActionContext = tuple
        name: string
        turns: int
        group: int
        action: BoardAction
        cancelable: bool
        passthrough: bool
        send: proc ()
        cancel: proc ()

#I really went for 2 months changing the values by hand each time
const debug: bool = false
const debugScreen: Screen = Game 
const myDebugPowers: seq[Power] = @[daybreakGlass]
const opponentDebugPowers: seq[Power] = @[]

var 
    #state for coordination with other player
    roomId: tuple[loaded: bool, value: kstring] = (false, "Waiting...")
    peer: tuple[send: proc(data: cstring), destroy: proc()]
    side: Color = if debug: white else: black
    turn: bool = if debug: true else: false
    myDrafts: seq[Power] = @[]
    opponentDrafts: seq[Power] = @[]

    #state for draft
    baseDrafts: int
    draftOptions: seq[Power]
    draftChoices: int = 3
    draftsLeft: int #ignore how this is one less than actual draft, i will fix eventually
    draftTier: Tier

    #state for game
    rematch = false
    theBoard: ChessBoard #also for debug
    theState: BoardState
    selectedTile: Tile = (file: -1, rank: -1) #negative means unselected
    possibleMoves: Moves = @[]
    possibleTakes: Moves = @[]
    lastMove: Moves = @[]
    piecesChecking: Moves = @[]

    practiceMode: bool = false

    #settings decided by player
    showTechnicalNames: bool = false
    disableRNGPowers: bool = false
    showDebug: bool = false
    enableExperimental: bool = true

    #state for webapp
    currentScreen: Screen = if debug: debugScreen else: Lobby
    currentTab: Tab = My
    gameMode: Gamemode# = TrueRandom #deubg
    screenWidth: int = window.innerWidth

    #for glass stuff
    #i'll namespace in a tuple if I feel like there are too many globals
    selectedGlass: Option[GlassType] = none(GlassType)

    actionStack: seq[ActionContext] = @[]
    nextActionStack: seq[ActionContext] = @[]
    toSend: seq[ActionContext] = @[] 
    promptHistory: seq[string] = @[]
    promptStack: seq[string] = @[]
    picksLeft: int = 0
    getPickOptions: proc(): seq[Tile]
    pickOptions: seq[Tile]
    picks: seq[Tile] = @[] 
    whenCollected: proc()

    selectedSubPower: Table[string, int]
    allPowers = getAllPowers()

proc alert(s: cstring) {.importjs: "alert(#)".}
proc onresize(cb: proc()) {.importjs: "window.addEventListener('resize', #)".}

proc resize() = 
    screenWidth = window.innerWidth
    redraw()

proc pieceOf(tile: Tile): var Piece = 
    theBoard[tile.rank][tile.file]

proc isSelected(n: int, m: int): bool = 
    return selectedTile.rank == n and selectedTile.file == m

proc busy(): bool = 
    return actionStack.len != 0 or picksLeft != 0 or not turn

proc initGame() = 
    theState = startingState()
    theBoard = startingBoard(theState)
    if not debug: theState.shared.randSeed = roomId.value.parseInt()
    myDrafts = @[]
    opponentDrafts = @[]
    lastMove = @[]
    piecesChecking = @[]

proc clear() =
    selectedTile = (-1, -1)
    possibleMoves = @[]
    possibleTakes = @[]

proc initSelectedSubPower() = 
    for p in allpowers:
        selectedSubPower[p[0].name] = 0

proc endRound() = 
    inc theState.shared.turnNumber

    for i, j in rankAndFile(theBoard):
        theBoard[i][j].endTurn(theBoard, theState)

    #this is needed by the random move powers to prevent double moves
    #It needs to happen after so that all drunkness is cleared after end turn stuff
    for i, j in rankAndFile(theBoard): 
        #this is hardcoded in because we need it to happen last, and it needs to happen even if the piece moves   
        #TODO rework onEndTurn to ensure that it is the same piece
        #So I don't need these bandaids
        #this isn't the most important
        #but I could do something with indexes
        #though indexes still kind of suck
        for ic, c in theBoard[i][j].casts:
            if c.glass == Steel:
                if theBoard[i][j].isColor(white):
                    theBoard[i][j].casts[ic].on = theBoard[i][j].tile.tileAbove()
                else:
                    theBoard[i][j].casts[ic].on = theBoard[i][j].tile.tileBelow()
        theBoard[i][j].drunk = false

    piecesChecking = theBoard.getPiecesChecking(side)
    if gameIsOver(theBoard):
        currentScreen = Results

        if not practiceMode:
            if side.alive(theBoard): 
                addWins(myDrafts)
            else:
                addLosses(myDrafts)
        

    #TODO remove after tests
    #ensuring that indexes are never duplicated
    var test: seq[int] = @[]
    for i, j in theBoard.rankAndFile:
        assert theBoard[i][j].index notin test, fmt"{theBoard[i][j]} has some issues"
        test.add(theBoard[i][j].index)

proc sendAction(data: string, `end`: bool) =
    if not debug and not practiceMode: #skip send whn debugging because peer is undefined
        peer.send(fmt"action:{data}") 
        if `end`: 
            turn = false #I also want turn to be always true when in debug
            echo "send action changing turn"
    if `end`: endRound() 

proc updateActionStack() = 
    echo "as", actionStack
    echo "nas", nextActionStack
    echo "s", toSend
    if actionStack.len == 0:
        if nextActionStack.len != 0:
            for i, x in nextActionStack:
                dec nextActionStack[i].turns

        if not debug and not practiceMode:
            if toSend.len != 0:
                for x in toSend:
                    x.send()
                    echo "send, this ends turn if .send does"
            else:
                #if all of them are not passThough, then pass
                if nextActionStack.len != 0 and not nextActionStack.mapIt(it.passthrough).foldr(a and b):
                    sendAction("pass", true)

        actionStack = nextActionStack
        nextActionStack = @[]
        toSend = @[]

proc sendMove(moveType: string, start: Tile, to: Tile) = 
    sendAction(fmt"{$moveType},{$start.rank},{& $start.file},{$to.rank},{$to.file}", true)

proc sendBuy(option: BuyOption, tile: Tile) = 
    sendAction(fmt"buy,{option.name},{$tile.rank},{$tile.file}", false)

proc createSendGlass(group: int): proc () = 
    result = proc () =
        sendAction(fmt"castingcomplete,{group}", true)

proc createCancelGlass(group: int): proc () = 
    result = proc () =
        for i, j in theBoard.rankAndFile:
            theBoard[i][j].casts = theBoard[i][j].casts.filterIt(it.group != group)
        sendAction(fmt"castingcancel,{group}", true)

proc otherBuy(d: string) = 
    let data = d.split(",")
    assert data[0] == "buy"
    let piece = (parseInt(data[3]), parseInt(data[2]))
    assert pieceOf(piece).color.hasWallet(theState)

    for option in theState.side[otherSide(side)].buys:
        if option.name == data[1]:
            buy(pieceOf(piece), option, theBoard, theState)

proc otherMove(d: string) = 
    let data = split(d, ",")
    let mover: Tile = (parseInt(data[2]), parseInt(data[1]))
    let moveTo: Tile = (parseInt(data[4]), parseInt(data[3]))

    lastMove = @[mover, moveTo]
    possibleMoves = @[]
    possibleTakes = @[]

    echo d, data[0], mover, moveTo
    if data[0] == "move":
        pieceOf(mover).move(moveTo, theBoard, theState)
    elif data[0] == "take":
        pieceOf(mover).take(moveTo, theBoard, theState)

proc otherGlass(d: string) = 
    let data = split(d, ",")
    if data[0] == "castingstart":
        theBoard[parseInt(data[1])][parseInt(data[2])].casts.add((
            on: (file: parseInt(data[4]), rank: parseInt(data[3])).Tile,
            group: parseInt(data[5]),
            glass: data[6].toGlassType()
        ))
        discard newGroup(theState) #this ensures that group is properly incremented
        #it does it more than needed, but that shouldn't be an issue
    elif data[0] == "castingcancel":
        turn = true
        echo "turn equals true: otherglass cancel"
        for i, j in theBoard.rankAndFile:
            theBoard[i][j].casts = theBoard[i][j].casts.filterIt(it.group != parseInt(data[1]))
    elif data[0] == "castingcomplete": #TODO clean code
        turn = true
        echo "turn equals true: otherglass complete"
        for i, j in theBoard.rankAndFile:
            for c in theBoard[i][j].casts:
                if c.group == parseInt(data[1]):
                    #we filterit out first because it could move away during the action 
                    theBoard[i][j].casts = theBoard[i][j].casts.filterIt(it.group != c.group)
                    theState.side[otherSide(side)].glass[c.glass].get().action(
                        theBoard[i][j], c.on, theBoard, theState
                    )


proc otherAction(d: string) = 
    let data = d.split(",")
    if data[0] == "buy":
        otherBuy(d)
        endRound()
    elif data[0] == "move" or data[0] == "take":
        turn = true
        echo "otheraction of move/take: turn equals true"
        otherMove(d)
        endRound()
    elif data[0].contains("casting"):
        otherGlass(d)
    elif data[0] == "pass":
        turn = true
        echo "otheraction of pass: turn equals true"
        endRound()

proc cancelPick() = 
    if promptHistory.len > 0:
        inc picksLeft
        discard picks.pop() #remove pick
        promptStack.add(promptHistory.pop()) #push back to history
        pickOptions = getPickOptions()
    
proc cancelPick(_: Event, _: VNode) = 
    cancelPick()

proc cancelAllPicks() =
    promptHistory = @[]
    promptStack = @[]
    picks = @[]
    picksLeft = 0

    pickOptions = @[]

    whenCollected = nil
    getPickOptions = nil

proc cancelAllPicks(_: Event, _: VNode) =
    cancelAllPicks()
    
proc draft(allDrafts: seq[Power] = @[], drafter: seq[Power] = @[]) = 
    var disabled: seq[Power] = @[]

    if disableRNGPowers:
        disabled &= rngPowers
    if not enableExperimental:
        disabled &= experimentalPowers

    if gameMode == TrueRandom:
        draftOptions = draftRandomPower(allDrafts & disabled, drafter, draftChoices)
    elif gameMode == RandomTier:
        #doesn't allow holy to be drafted in tierDraft because luck is consistent here
        draftOptions = draftRandomPowerTier(draftTier, allDrafts & holy & disabled, drafter, draftChoices)
    elif gameMode == SuperRandom:
        draftOptions = draftRandomPower(allDrafts & disabled, drafter, draftChoices, insaneWeights, buffedInsaneWeights)

proc hostLogic(d: string, m: MessageType) = 
    echo $m, " of ", d, "\n"
    case m
    of Id: 
        roomId = (true, d.kstring)
        side = white
    of HandShake: 
        peer.send("options:deciding")
        currentScreen = Options
        initGame()
        #this is only used when `gameMode == TrueRandom`
        draftTier = randomTier(defaultBuffedWeights) 
    of Draft:
        var x = d.split(",")
        if x[0] == "my":
            turn = true
            opponentDrafts.add(powers[parseInt(x[1])])
            if draftsLeft >= 1:
                dec draftsLeft
                draftTier = randomTier(defaultBuffedWeights)
                draft(myDrafts & opponentDrafts, myDrafts)
            else:
                execute(myDrafts, opponentDrafts, side, theBoard, theState)
                peer.send("handshake:gamestart")
                currentScreen = Game
    of Action: otherAction(d)
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
        initGame()
    of Handshake:
        execute(myDrafts, opponentDrafts, side, theBoard, theState)
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
    of Action: otherAction(d)
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

    for i, j in theBoard.rankAndFile:
        for c in theBoard[i][j].casts:
            if p.tile == c.on:
                class &= castingOnAnimations[c.glass]

    for c in p.casts:
        class &= castingAnimations[c.glass]

    if isSelected(m, n) and possibleTakes.contains(p.tile):
        class &= " can-take"
    elif isSelected(m,n):
        class &= " selected"
    elif p.tile in picks: 
        class &= " picking"
    elif possibleMoves.contains(p.tile) or p.tile in pickOptions:
        class &= " can-move"
    elif possibleTakes.contains(p.tile):
        class &= " can-take"
    else:
        class &= " unselected"

    if piecesChecking.contains(p.tile):
        class &= " checking"
    elif lastMove.contains(p.tile):
        class &= " last-move"
    

    result = buildHtml():
        td(class=class):
            proc onclick(_: Event; _: VNode) =     
                if picksLeft != 0 and p.tile in pickOptions:
                    dec picksLeft
                    picks.add(p.tile)
                    promptHistory.add(promptStack.pop()) #moves from stack to history
                    pickOptions = getPickOptions()
                    clear()
                    if picksLeft == 0: 
                        echo "when collected start"
                        whenCollected()
                        echo "When Collected"
                        cancelAllPicks()
                        echo "Cancel All"
                elif possibleMoves.contains(p.tile) and 
                    pieceOf(selectedTile).isColor(side) and not busy(): #picksLeft == 0 stops moves during pick
                        pieceOf(selectedTile).move(p.tile, theBoard, theState)
                        sendMove("move", selectedTile, p.tile)
                        echo "send"
                        clear()
                elif possibleTakes.contains(p.tile) and 
                    pieceOf(selectedTile).isColor(side) and not busy(): #picksLeft == 0 stops moves during pick:
                        pieceOf(selectedTile).take(p.tile, theBoard, theState)
                        sendMove("take", selectedTile, p.tile)
                        clear()
                elif not isSelected(m, n):
                    selectedTile = (n, m)
                    possibleMoves = p.getMovesOn(theBoard)        
                    possibleTakes = p.getTakesOn(theBoard)            
                else:
                    clear()

            if p.filePath == "":
                text ""
            else:
                let class = if p.rotate: "rotate" else: ""
                let color = if p.colorable: $p.color else: ""
                img(src = iconsPath & color & p.filePath, class = class)

proc createBoard(): VNode =
    result = buildHtml(table):
        for i,r in theBoard:
            tr:
                for j,p in r:
                    createTile(p, i, j)

proc reverseBoard(): VNode = 
    result = buildHtml(table):
        for i in countdown(7, 0):
            tr:
                for j in countdown(7, 0):
                    createTile(theBoard[i][j], i, j)

proc createLobby(): VNode = 
    result = buildHtml(tdiv(class="start-column height-100")):     
        tdiv(class="main"):         
            tdiv(class="start-column"):
                button(class=menuButton): 
                    text "Join a Room"
                    proc onclick(_: Event; _: VNode) = 
                        currentScreen = JoinRoom
                button(class=menuButton):
                    text "See Powers"
                    proc onclick(ev: Event, _: VNode) =
                        initSelectedSubPower()
                        echo "setting screen to See Power"
                        currentScreen = SeePower


            tdiv(class="start-column"):
                button(class=menuButton): 
                    text "Create a Room"
                    proc onclick(ev: Event; _: VNode) = 
                        if not peer.destroy.isNil():
                            peer.destroy()
                        peer = newHost(hostLogic)
                        
                        currentScreen = CreateRoom
                        
                button(class=menuButton): 
                    text "Other"
                    proc onclick(ev: Event, _: VNode) =
                        currentScreen = Other
                        
proc createRoomMenu(): VNode = 
    result = buildHtml(tdiv(class="main")):
        if not roomId.loaded:
            text "Creating room key"
        else:
            h2:
                text "Room Key: "
            br()
            text roomId.value

proc join(_: Event, _: VNode) =
    let id = getVNodeById("joincode").getInputText 
    roomId.value = id
    echo getVNodeById("joincode")
    if not peer.destroy.isNil():
        peer.destroy()
    peer = newJoin(id, joinLogic)

proc createJoinMenu(): VNode = 
    result = buildHtml(tdiv(class="main cut-down", id = "join", onkeyupenter = join)):
        label(`for` = "joincode"):
            text "Join Code:"
        input(id = "joincode", onchange = validateNotEmpty("joincode"))
        button(onclick = join):
            text "Enter"

proc createOptionsMenu(): VNode = 
    result = buildHtml(tdiv(class="main")):
        if side == black:
            text "Waiting for host to decide ruleset..."
        else:
            tdiv(class="column cut-down"):
                button:
                    proc onclick(_: Event, _: VNode) = 
                        peer.send("handshake:gamestart")
                        turn = true
                        currentScreen = Game

                    text "Normal Chess"

                text "Classic Chess, with no special rules or abilites."
                

            tdiv(class="column cut-down"):
                tdiv(class="column"):
                    button:
                        proc onclick(_: Event, _: VNode) = 
                            peer.send("draft:start")
                            currentScreen = Draft
                            gameMode = RandomTier
                            turn = true
                            baseDrafts = parseInt(getVNodeById("draftTierNumber").getInputText)
                            draftsLeft = baseDrafts - 1
                            draftChoices = parseInt(getVNodeById("draftChoiceTierNumber").getInputText)

                            draft()

                        text "Draft mode"
                    text """Take turns drafting power ups for your pieces, then play. 
                            Each side is guaranteed to get power ups of the same tier."""
                    
                    label(`for` = "draftTierNumber"):
                        text "Number of powers drafted"
                    input(id = "draftTierNumber", `type` = "number", onchange = validateNotEmpty("draftTierNumber"), 
                            step = "1", min = "1", max = "10", value = $defaultBaseDrafts)

                    label(`for` = "draftChoiceTierNumber"): #i'm insane at naming things
                        text "Number of choices each round"
                    input(id = "draftChoiceTierNumber", `type` = "number", onchange = validateNotEmpty("draftChoiceTierNumber"), 
                            step = "1", min = "1", max = "5", value = $defaultBaseDraftChoices)

                hr()

                tdiv(class="column"):
                    button:
                        proc onclick(_: Event, _: VNode) = 
                            peer.send("draft:start")
                            currentScreen = Draft
                            gameMode = TrueRandom
                            turn = true

                            baseDrafts = parseInt(getVNodeById("draftRandNumber").getInputText)
                            draftsLeft = baseDrafts - 1
                            draftChoices = parseInt(getVNodeById("draftChoiceRandNumber").getInputText)

                            draft()
                            

                        text "Random mode"

                    text """Draft powerups of random strength and quality, then play. 
                            Completely luck based."""
                            
                    label(`for` = "draftRandNumber"):
                        text "Number of powers drafted"
                    input(id = "draftRandNumber", `type` = "number", onchange = validateNotEmpty("draftRandNumber"), 
                            step = "1", min = "1", max = "10", value = $defaultBaseDrafts)

                    label(`for` = "draftChoiceRandNumber"): #i'm insane at naming things
                        text "Number of choices each round"
                    input(id = "draftChoiceRandNumber", `type` = "number", onchange = validateNotEmpty("draftChoiceRandNumber"), 
                            step = "1", min = "1", max = "5", value = $defaultBaseDraftChoices)

                hr()
                
                tdiv(class="column"):
                    button:
                        proc onclick(_: Event, _: VNode) = 
                            peer.send("draft:start")
                            currentScreen = Draft
                            gameMode = SuperRandom
                            turn = true

                            baseDrafts = parseInt(getVNodeById("draftSuperRandNumber").getInputText)
                            draftsLeft = baseDrafts - 1
                            draftChoices = parseInt(getVNodeById("draftChoiceSuperRandNumber").getInputText)

                            draft()
                            

                        text "Super Random mode"

                    text """Draft powerups of random strength and quality, then play. 
                            Completely luck based, with higher chances for rare pieces."""
                            
                    label(`for` = "draftSuperRandNumber"):
                        text "Number of powers drafted"
                    input(id = "draftSuperRandNumber", `type` = "number", onchange = validateNotEmpty("draftSuperRandNumber"), 
                            step = "1", min = "1", max = "10", value = $defaultBaseDrafts)

                    label(`for` = "draftChoiceSuperRandNumber"): #i'm insane at naming things
                        text "Number of choices each round"
                    input(id = "draftChoiceSuperRandNumber", `type` = "number", onchange = validateNotEmpty("draftChoiceSuperRandNumber"), 
                            step = "1", min = "1", max = "5", value = $defaultBaseDraftChoices)

proc createPowerMenu(p: Power): VNode = 
    result = buildHtml(tdiv(class="power")):
        h1:
            text if showTechnicalNames and p.technicalName != "": p.technicalName else: p.name
        if p.icon != "":
            var src = iconsPath
            if not p.noColor: src &= $side
            img(src=src & p.icon)
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

proc createPowerSummary(p: Power, ofSide: Color): VNode = 
    var class = "image "
    if side != ofSide and p.rotatable:
        class &= " rotate "
    
    var src = iconsPath #base icon oath
    if not p.noColor: src &= $ofSide

    result = buildHtml(tdiv(class="power-grid")):
        h4(class = "title"):
            text if showTechnicalNames and p.technicalName != "": p.technicalName else: p.name
        p(class="desc"):
            text p.description
        if p.icon != "":
            img(class = class, src = src & p.icon)
        else:
            img(class = class, src = iconsPath & "blackbishop.svg") #placeholder

proc createBuyButton(option: BuyOption, p: var Piece): VNode =
    if not option.condition(p, theBoard, theState): 
        return buildHtml(tdiv())
    else:
        let cost = option.cost(p, theBoard, theState)
        let disabled = busy() or getMoney(side, theState) < cost
        #technically, a positive cost means that you pay that much, but that isn't very intuitive
        let sign = if cost >= 0: "-" else: "+" 
        buildHtml(button(disabled=disabled)):
            text fmt"{option.name}: {sign}${abs(cost)}" #abs beacuse sign should be infront of dollar sign
            proc onclick(_: Event; _: VNode) = 
                sendBuy(option, p.tile)
                buy(p, option, theBoard, theState)
                clear() #clears since piece could be in a different spot

proc createPieceProfile(p: var Piece): VNode = 
    var imgClass = ""
    if side != p.color and p.rotate:
        imgClass &= "rotate "
    
    var src = iconsPath #base icon path
    if p.colorable: src &= $p.color

    let name = $p.item

    result = buildHtml(tdiv(class=pieceRow)):
        h4:
            text name
        img(class=imgClass, src=src & p.filePath)
        p(class="take"):
            text fmt"Kills: {p.piecesTaken} pieces."
        if p.isColor(side): #only show buttons when its your piece
            tdiv(class="row"):
                for option in theState.side[p.color].buys:
                    createBuyButton(option, p)

proc createInfo(): VNode = 
    result = buildHtml(tdiv(class="bottom-info")):
        if turn and actionStack.len != 0:
            if actionStack[^1].turns == 0: #it has to be your turn, or it has to be passThrough
                h3:
                    if actionStack[^1].passThrough:
                        text fmt"Execute {actionStack[^1].name} (This will end your turn, after all other actions are resolved): "
                    else:
                        text fmt"Execute {actionStack[^1].name}: "
                button:
                    text "Execute!"
                proc onclick(_: Event, _: VNode) =
                    actionStack[^1].action(theBoard, theState)
                    echo "action complete"
                    for i, j in theBoard.rankAndFile:
                        theBoard[i][j].casts = theBoard[i][j].casts.filterIt(it.group != actionStack[^1].group)
                    toSend.add(actionStack.pop())
                    echo "sent"
                    updateActionStack()
            elif actionStack[^1].cancelable:
                h3:
                    if actionStack[^1].passThrough:
                        text fmt"""{actionStack[^1].name} will complete in {actionStack[^1].turns}. Continuing does not end your turn. """
                    else:
                        text fmt"""{actionStack[^1].name} will complete in {actionStack[^1].turns}. Your turn will end if you continue."""
                tdiv(class="column"):
                    button:
                        text "Continue"
                        proc onclick(_: Event, _: VNode) = 
                            nextActionStack.add(actionStack.pop())
                            updateActionStack()
                    button:
                        text "Cancel"
                        proc onclick(_: Event, _: VNode) = 
                            actionStack[^1].cancel()
                            discard actionStack.pop()
                            updateActionStack()
            else:
                h3:
                    if actionStack[^1].passThrough:
                        text fmt"{actionStack[^1].name} will resolve in {actionStack[^1].turns} turns." 
                    else:
                        text fmt"""{actionStack[^1].name} will resolve in {actionStack[^1].turns} turns.
                                    This will end your turn, once all other actions are resolved."""
                button:
                    text "Ok"
                    proc onclick(_: Event, _: VNode) = 
                        nextActionStack.add(actionStack.pop())
                        updateActionStack()
        elif promptStack.len == 0:
            var text = if turn: "It is your turn. " else: "Opponent is moving. "
            if hasWallet(side, theState):
                text &= fmt"You have {getMoney(side, theState)} dollars."
            h3:
                text text
        else:
            h3:
                text promptStack[^1] #last
            button(onclick=cancelPick):
                text "Undo last"


proc createGlassOnClick(glass: GlassType): proc (_: Event, _: VNode) = 
    result = proc (_: Event, _: VNode) =
        if selectedGlass.isNone() or selectedGlass.get() != glass:
            selectedGlass = some(glass)
        else:
            selectedGlass = none(GlassType)

proc createGlassMenu(): VNode =
    result = buildHtml(tdiv(class=glassMenu)):
        h4(class="title"):
            text "Glasses"

        tdiv(class="glasses"):
            for glass in GlassType:
                tdiv(class="glass"):
                    if theState.side[side].glass[glass].isSome():
                        span(class = "circle " & ($glass).toLower(), onclick=createGlassOnClick(glass))
                    else:
                        span(class = "circle empty")
                    p:
                        text $glass
        if selectedGlass.isSome():
            let glass = selectedGlass.get()
            if picksLeft != 0:
                button(class="cancel", onclick=cancelAllPicks):
                    text "Cancel"
            #I'm just going to hardcode this condition for now
            let zerocond = glass == Zero and theState.shared.turnNumber <= 1
            button(class="use", disabled = busy() or zerocond):
                text fmt"Use {glass}"
                proc onclick(_: Event, _: VNode) = 
                    let strength = theState.side[side].glass[glass].get().strength
                    let group = newGroup(theState)
                    var newCasting: seq[Casting]
                    var pieces: seq[Piece] = @[]
                    var tiles: seq[Tile] = @[]
                    let action = theState.side[side].glass[glass].get().action

                    picksLeft = strength * 2
                    promptStack = [
                        fmt"Pick a piece to start casting {glass}.", 
                        fmt"Pick a tile to cast {glass} on."
                    ].cycle(strength).reversed() #reversed so that I can write them in order, which looks nice
                    assert promptStack.len == picksLeft
                    whenCollected = proc () =
                        for piece, tile in byTwo(picks):
                            echo "piecetile", piece, "tile, ", tile
                            pieces.add(theBoard[piece])
                            tiles.add(tile)
                            newCasting.add(( 
                                on: tile,
                                group: group,
                                glass: glass
                            ))

                            theBoard[piece].casts.add(( 
                                on: tile,
                                group: group,
                                glass: glass
                            ))

                            sendAction(fmt"""castingstart,{piece.rank},{piece.file},{tile.rank},{tile.file},{group},{glass}""", false)
                            discard newGroup(theState) #this ensures that group is properly incremented
                            #it does it more than needed, but that shouldn't be an issue
                        echo "adding actionStack"
                        actionStack.add((
                            name: "Casting " & $glass,
                            turns: 1,
                            group: group,
                            action: packageGlass(pieces, tiles, action),
                            cancelable: true,
                            passThrough: false,
                            send: createSendGlass(group),
                            cancel: createCancelGlass(group)
                        ))
                        echo "avtionstack added"
                        sendAction("pass", true)
                    getPickOptions = proc (): Moves =
                        if picksLeft mod 2 == 0: #picking piece
                            for i, j in theBoard.rankAndFile:
                                if theBoard[i][j].isColor(side):
                                    result.add(theBoard[i][j].tile)
                        else: #picking tile
                            let condition = theState.side[side].glass[glass].get().condition
                            #theBoard[^1] is the last element, which would be the corresonding piece
                            result.add(condition(side, theBoard[picks[^1]], theBoard, theState))
                    pickOptions = getPickOptions() #we run once so that there are intitial options
                    clear()

proc createGame(): VNode = 
    let topClass = if screenWidth > 1200: "main" else: "column height-100"
    let nextClass = if screenWidth > 1200: "tab-column" else: "tab-column long"
    buildHtml(tdiv(class=topClass)):
        tdiv(class=nextClass):
            if practiceMode:
                let class = if screenWidth  > 1200: "move-up width-70" else: "move-right"
                button(class = class, id = "exit-practice"):
                    text "Exit practice"
                    proc onclick(_: Event, _: VNode) = 
                        clear()
                        practiceMode = false
                        currentScreen = SeePower
            tdiv(class="tab-row extra-right"):
                if myDrafts.len != 0:
                    button:
                        text "Your Drafts"
                        proc onclick(_: Event, _: VNode) =
                            currentTab = My
                if opponentDrafts.len != 0:
                    button:
                        text "Opponent Drafts"
                        proc onclick(_: Event, _: VNode) =
                            currentTab = Opponent
                button:
                    text "Power Control"
                    proc onclick(_: Event, _: VNode) =
                        currentTab = Control
                if debug or showDebug:
                    button:
                        text "Debug"
                        proc onclick(_: Event, _: VNode) =
                            currentTab = Debug
                            #TODO find out why this crashes in practice mode
                            #I'm actually so confused, why does changing a bool 
                            #cause a enum to overflow

            tdiv(class="column-scroll"):
                case currentTab
                of My:
                    for p in myDrafts.replaceAnySynergies():
                        createPowerSummary(p, side)
                    if not practiceMode: #since this crashes in practiceMode for some reasons
                        tdiv(class="debug"): #cheeky dev button
                            proc onclick(_: Event, _: VNode) = 
                                showDebug = true

                of Opponent:
                    for p in opponentDrafts.replaceAnySynergies():
                        createPowerSummary(p, otherSide(side))
                of Control:
                    if isSelected(-1, -1) or theBoard[selectedTile].isAir():
                        createPieceProfile(theBoard[getKing(side, theBoard)]) #default    
                    else: 
                        createPieceProfile(pieceOf(selectedTile))
                    if side.hasGlass(theState):
                        createGlassMenu()
                of Debug:
                    tdiv(class="main"):
                        text fmt"Shared: {$theState.shared}"
                    tdiv(class="main"):
                        text fmt"White: {$theState.side[white]}"
                    tdiv(class="main"):
                        text fmt"Black: {$theState.side[black]}"
                    if not isSelected(-1, -1):
                        tdiv(class="main"):
                            text fmt"Selected piece: {$pieceOf(selectedTile)}"
                    tdiv(class="main"):
                        text fmt"Action Stack: {actionStack}"
                    tdiv(class="main"):
                        text fmt"Next ActionStack: {nextActionStack}"

        tdiv(class="column"):
            if side == white: createBoard() else: reverseBoard()
            createInfo()

proc createResults(): VNode = 
    result = buildHtml(tdiv(class="start-column")):
        if side.alive(theBoard):
            h1:
                text "You won!"
        else:
            h1: 
                text "You lost..."
        
        if practiceMode:    
            button:
                proc onclick(_: Event, _: VNode) = 
                    currentScreen = Lobby
                    practiceMode = false #i think i do this twice, but redundancy is good

                text "Back to Lobby"
        else:
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
    result = buildHtml(tdiv(class="start-column")):
        text "Your opponent disconnected"
        button:
            proc onclick(_: Event, _: VNode) = 
                currentScreen = Lobby
            text "Back to Lobby"

proc createOther(): VNode = 
    result = buildHtml(tdiv(class="start-column")):
        tdiv(class="main"):
            button(class=menuButton):
                text "Settings"
                proc onclick(_: Event, _: VNode) = 
                    currentScreen = Settings

            button(class=menuButton):
                text "Change Log"
                proc onclick(ev: Event, _: VNode) =
                    alert("Unimplemented")

        button(class="width-100"):
            text "Credits"
            proc onclick(ev: Event, _: VNode) =
                alert("Unimplemented")

        button(class="width-100"):
            text "Return To Lobby"
            proc onclick(_: Event, _: VNode) = 
                currentScreen = Lobby

#if default option is true, then first change disables it
proc createSetting(setting: var bool, title: string, description: string, defaultOption = false): VNode =
    result = buildHtml(tdiv(class="start-column")):
        tdiv(class=settingItem):
            h4():
                text $title
            p():
                text $description
            button():
                text if defaultOption: 
                        if not setting: "Disable" else: "Enable"
                    else:
                        if setting: "Disable" else: "Enable"
                proc onclick(_: Event, _: VNode) = 
                    setting = not setting
        hr()

proc createSettings(): VNode = 
    result = buildHtml(tdiv(class="start-column gap-10")):
        createSetting(
            showTechnicalNames,
            "Technical Names",
            "Shows the technical names for synergy powers and powers with multiple variations.",
        )
        createSetting(
            disableRNGPowers,
            "Disable RNG Powers",
            "Removes RNG based powers, like civilians, from the draft pool. Only works when you are the host.",
            true
        )
        createSetting(
            enableExperimental,
            "Include Experimental Powers",
            "Adds the cutting edge of SuperChess. It is likely to break or be unbalanced.",
        )
        button(class="width-100"):
            text "Return to Other"
            proc onclick(_: Event, _: VNode) = 
                currentScreen = Other

proc createSeePowerDescription(p: Power): VNode =     
    var src = if p.noColor: p.icon else: $black & p.icon
    let record = (wins: 0, losses: 0)#getRecord(p.technicalName)
    let class = if record.wins > 0: "see-power has-won" else: "see-power"
    result = buildHtml(tdiv(class=class)):
        h4:
            text p.technicalName
        p(class="desc"):
            text p.description
        if p.icon != "":
            img(src = iconsPath & src)
        else:
            img(src = iconsPath & "blackbishop.svg") #placeholder
        p(class="win"):
            text fmt"Wins: {record.wins}, Losses: {record.losses}"
        button:
            text "Practice"
            proc onclick(_: Event, _: VNode) = 
                initGame()
                side = black
                turn = true
                practiceMode = true

                theState.shared.randSeed = 0

                if p.synergy:
                    var alreadyAdded: seq[string] = @[]
                    let synergy = getSynergyOf(p.index)
                    if synergy in draftSynergies: 
                        mydrafts.add(synergy.power)
                        alreadyAdded.add(synergy.power.name)
                    for name in synergy.requirements:
                        if name in synergy.replacements or
                            name in alreadyAdded: continue

                        for reqPower in power.powers:
                            if reqPower.name == name:
                                myDrafts.add(reqPower)
                                alreadyAdded.add(reqPower.name)

                else:
                    myDrafts.add(p)
                
                execute(myDrafts, opponentDrafts, side, theBoard, theState)
                currentScreen = Game

proc createSeePowerOnclick(name: string, index: int): proc (_: Event, _: VNode)  = 
    result = proc (_: Event, _: VNode) = 
        selectedSubPower[name] = index

proc getPowerTabLength(powers: seq[Power]): int = 
    for p in powers:
        result += p.technicalName.len * 15 #15 is font size

proc createSeePower(): VNode = 
    echo "creating See Power"
    result = buildHtml(tdiv(class = "tab-column")):
        button(class = "top-button"):
            text "Return to Lobby"
            proc onclick(_: Event, _: VNode) = 
                currentScreen = Lobby

        tdiv(class = "search move-up"):
            label(`for` = "search"):
                text "Search: "
            input(id = "search", onchange = validateNotEmpty("search"))

        let search = 
            try: getVNodeById("search").getInputText
            except: ""
        
        #i'll fix the function later. I really need the clean code update
        for subpowers in allPowers.sortedByIt(editDistance(it[0].name, $search)):
            if subpowers.len == 1:
                createSeePowerDescription(powers[0])
            else:
                tdiv(class = "tab-row margin-t-20"):
                    for index, power in subpowers:
                        let class = if index == selectedSubPower[subpowers[0].name]: "selected-tab font-20" else: "font-20"
                        button(class = class, onclick = createSeePowerOnClick(power.name, index)):
                            text if screenWidth < getPowerTabLength(subpowers): $(index + 1) else: power.technicalName
                createSeePowerDescription(subpowers[selectedSubPower[subpowers[0].name]])

            hr()

proc main(): VNode = 
    result = buildHtml(tdiv(class="main scroll")):
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
        of Other: createOther()
        of Settings: createSettings()
        of SeePower: createSeePower()
        of Test: tdiv()


initStorage()
onresize(resize)
initSelectedSubPower()

if debug: 
    case currentScreen
    of Game:
        initGame()
        theState.shared.randSeed = 0
        myDrafts = myDebugPowers
        opponentDrafts = opponentDebugPowers
        execute(myDrafts, opponentDrafts, side, theBoard, theState)
    of Draft: 
        gameMode = TrueRandom
        draft()
    else: discard nil

setRenderer main