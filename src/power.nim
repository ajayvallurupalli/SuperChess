import piece
from std/sequtils import foldr, mapIt, filterIt, concat
from std/algorithm import sortedByIt
from std/random import randomize, rand
from std/strformat import fmt
import std/tables

type
    Tier* = enum
        Common, Uncommon, Rare, UltraRare

    #`OnStart` is run once when the game starts
    #`OnStart` is run in the order of `Power.priority`
    #`drafterSide` is the side that the power should be applied to
    #`viewerSide` is the side that is running `OnStart`. This means that `OnStart` can have different
        #functionality if the client has the power, or the if the client's opponent has the power
        #this is very dangerous, and can lead to diverging states, so it should only really be used for visual stuff
        #in fact, it only exists so that specific shogi pieces can rotate to face the opponent, if they are owned by the opposite side
    OnStart* = proc (drafterSide: Color, viewerSide: Color, b: var ChessBoard, s: var BoardState)

    Tag* = enum
        Knight, Pawn, Bishop, Rook, Queen, King, 
        Develop, Push, Control, Promote, Move, Take,
        Special, Trade, Holy, UnHoly, NightRider, Glass, Status,
        Virus

    PowerType* = enum
        SyneryPower, AntiSynergyPower, NormalPower

    Power* = object
        name*: string
        technicalName*: string = ""
        item*: PowerType = NormalPower #can i delete? This is used for like one thing
        anti*: bool = false
        secret*: bool = false
        tier*: Tier
        rarity*: int = 8
        description*: string = "NONE"
        antiDescription*: string = ""
        tags*: seq[Tag]
        icon*: string = ""
        rotatable*: bool = false
        noColor*: bool = false #if noColor, it will not try to add white and back to icon path
        onStart*: OnStart
        index*: int = -1
        priority*: int = 10  #TODO find if I've been sorting priority wrong this entire time. No way right??

    Synergy* = tuple
        power: Power
        rarity: int
        requirements: seq[string]
        replacements: seq[string]

    AntiSynergy* = tuple
        power: Power
        rarity: int
        drafterRequirements: seq[string]
        opponentRequirements: seq[string]
    
    #just used to decide the percent chances of getting certain tiers
    #Contract: ```assert common + uncommon + rare + ultraRare == 100```
    TierWeights* = tuple
        common: int
        uncommon: int
        rare: int
        ultraRare: int

#they're called default because I had plans to allow user to change them
#but now it seems to be a relic of the passed
const 
    defaultWeight*: TierWeights = (60, 30, 9, 1)
    defaultBuffedWeights*: TierWeights = (50, 36, 12, 2)
    insaneWeights*: TierWeights = (25, 35, 30, 10) #used in the super random game mode
    buffedInsaneWeights*: TierWeights = (15, 38, 35, 12) #used in the super random game mode

#needed to ensure a power is always given with randomPower
const emptyPower*: Power = Power(
    name: "Nothing. Nothing...",
    tier: Common,
    description: "This does nothing. Unlucky!",
    index: 0,
    onStart:
        proc (_: Color, _: Color, _: var ChessBoard, _: var BoardState) = 
            discard nil
)

#holy is a special power used directly in `draftRandomPower`, so it's defined here instead
const holy*: Power = Power(
    name: "Holy",
    tier: Common,
    priority: 20,
    rarity: 12,
    description: "You are favored slightly more by god. Your next powers are more likely to be uncommon, rare, and ultra rare",
    tags: @[Virus, Holy, Holy],
    icon: "cross.svg",
    noColor: true,
    onStart: 
        proc (_: Color, _: Color, _: var ChessBoard, _: var BoardState) = 
            discard nil
)

var 
    powers*: seq[Power] = @[emptyPower]

    draftSynergies*: seq[Synergy]
    secretSynergies*: seq[Synergy]
    secretSecretSynergies*: seq[Synergy]

    antiSynergies*: seq[AntiSynergy]
    secretAntiSynergies*: seq[AntiSynergy]
    secretSecretAntiSynergies*: seq[AntiSynergy]

    commonPowers: seq[Power]
    uncommonPowers: seq[Power]
    rarePowers: seq[Power]
    ultraRarePowers: seq[Power]

#I know I should use an enum instead of secret and secretSecret, but I think this is funner
proc registerSynergy*(s: Synergy, secret: bool = false, secretSecret = false) = 
    assert secret or not secretSecret #ensures that secretSecret is true if and only if secret is true
    assert s.rarity == 0 or not secret, $s #ensures that rarity is 0 when secret
    var x = s #to edit
    
    x.power.rarity = x.rarity
    x.power.index = powers[powers.len - 1].index + 1
    x.power.item = SyneryPower

    if secret: x.power.secret = true

    let requirements = s.requirements.foldr(a & " + " & b)

    #updating techincal name and description of added power
    let synergyName = 
        if secretSecret: "Secret Secret Synergy"
        elif secret: "Secret Synergy"
        else: "Synergy"
    
    x.power.description = fmt"{synergyName}! ({requirements}) -- {x.power.description}"
    x.power.technicalName = 
        if x.power.technicalName == "": fmt"{x.power.name} ({synergyName} of {requirements})"
        else: fmt"{x.power.technicalName} ({synergyName} of {requirements})"

    powers.add(x.power)
    if secretSecret: secretSecretSynergies.add(x) 
    elif secret: secretSynergies.add(x)
    else: draftSynergies.add(x)

proc registerAntiSynergy*(s: AntiSynergy, secret: bool = false, secretSecret: bool = false) = 
    assert secret or not secretSecret #assert secret implies secretSecret
    var x = s #to edit

    x.power.rarity = x.rarity
    x.power.index = powers[powers.len - 1].index + 1
    x.power.item = AntiSynergyPower

    if secret: x.power.secret = true

    let opponentReqs = s.opponentRequirements.foldr(a & " + " & b)
    let requirements =
        if s.drafterRequirements.len != 0:
            block: #needed to make drafterReqs
                let drafterReqs = s.drafterRequirements.foldr(a & " + " & b)
                fmt"{drafterReqs} vs {opponentReqs}"
        else: opponentReqs
    let synergyName = 
        if secretSecret: "Secret Secret Anti-Synergy"
        elif secret: "Secret Anti-Synergy"
        else: "Anti-Synergy"
    
    x.power.description = fmt"{synergyName}! ({requirements}) -- {x.power.description}"
    x.power.technicalName = 
        if x.power.technicalName == "": fmt"{x.power.name} ({synergyName} of {requirements})"
        else: fmt"{x.power.technicalName} ({synergyName} of {requirements})"

    powers.add(x.power)
    if secretSecret: secretSecretAntiSynergies.add(x) 
    elif secret: secretAntiSynergies.add(x)
    else: antiSynergies.add(x)


proc synergize(pool: seq[Power], currentPowers: seq[Power], synergies: seq[Synergy], t: Tier, allTier: bool = false): seq[Power] =
    result = pool 
    for s in synergies:
        if currentPowers.filterIt(it.name in s.requirements).len == s.requirements.len and 
            (s.power.tier == t or allTier):
                result &= powers[s.power.index]

                if s.replacements.len != 0:
                    result = result.filterIt(it.name notin s.replacements)

proc secretSynergize(drafterPowers: seq[Power], synergies: seq[Synergy]): seq[Power] = 
    #we still need to pass a tier for types. I want tier to be required to avoid default errors
    #and I don't want two functions, so this is the best option
    return synergize(drafterPowers, drafterPowers, synergies, Common, allTier = true)

proc antiSynergize(pool: seq[Power], currentPowers: seq[Power], opponentPowers: seq[Power], synergies: seq[AntiSynergy],
                    t: Tier, allTier: bool = false): seq[Power] = 
        result = pool

        for s in synergies: 
            if currentPowers.filterIt(it.name in s.drafterRequirements).len == s.drafterRequirements.len and
                opponentPowers.filterIt(it.name in s.opponentRequirements).len == s.opponentRequirements.len and 
                (s.power.tier == t or allTier):
                    result &= powers[s.power.index]

proc secretAntiSynergize(drafterPowers: seq[Power], opponentPowers: seq[Power], synergies: seq[AntiSynergy]): seq[Power] = 
    return antiSynergize(drafterPowers, drafterPowers, opponentPowers, synergies, Common, true)

proc seqOf(t: Tier): var seq[Power] = 
    case t
    of Common: return commonPowers
    of Uncommon: return uncommonPowers
    of Rare: return rarePowers
    of UltraRare: return ultraRarePowers

proc registerPower*(p: Power) = 
    var x = p #temp var so that we can increment `Power.index`
    x.index = powers[powers.len - 1].index + 1
    if x.technicalName == "": x.technicalName = x.name

    powers.add(x)
    seqOf(x.tier).add(x)

proc randomPower(t: Tier, currentPowers: seq[Power], opponentPowers: seq[Power], alreadySelected: seq[Power] = @[]): Power = 
    let search = seqOf(t)
        .synergize(currentPowers, draftSynergies, t)
        .antiSynergize(currentPowers, opponentPowers, antiSynergies, t)
        .filterIt(it.name notin alreadySelected.mapIt(it.name))
    if search.len == 0: return emptyPower

    let sum = foldr(search.mapIt(it.rarity), a + b)
    var x: int = rand(sum)

    let tags = 
        if currentPowers.len == 0: @[]
        else: foldr(currentPowers.mapIt(it.tags), a & b)

    for p in search:
        x -= p.rarity

        let connectedTags = tags.filterIt(it in p.tags).len

        if connectedTags >= 3:
            x -= 5
        elif connectedTags >= 1:
            x -= 3


        if x <= 0: return p

proc randomTier*(w: TierWeights = defaultWeight): Tier = 
    assert w.common + w.uncommon + w.rare + w.ultraRare == 100
    let x: int = rand(100)

    if x <= w.common:
        return Common
    elif x <= w.common + w.uncommon:
        return Uncommon
    elif x <= w.common + w.uncommon + w.rare:
        return Rare
    else:
        return UltraRare

proc draftRandomPowerTier*(tier: Tier, drafterSelected: seq[Power], opponentSelected: seq[Power],
                            disabled: seq[Power] = @[], options: int = 1): seq[Power] = 
        for x in 0..options - 1:
            result.add(randomPower(tier, drafterSelected, opponentSelected, drafterSelected & opponentSelected & result & disabled))

proc draftRandomPower*(drafterSelected: seq[Power], opponentSelected: seq[Power], 
                        disabled: seq[Power] = @[], options: int = 1, normalWeights: TierWeights = defaultWeight, buffedWeights: TierWeights = defaultBuffedWeights): seq[Power] = 
    let weights = if holy in drafterSelected: buffedWeights else: normalWeights
    for x in 0..options - 1:
        result.add(randomPower(randomTier(weights), drafterSelected, opponentSelected, drafterSelected & opponentSelected & result & disabled))

#used to increment the prio of white, so that prio is always consistent
proc incrementWhite(ps: seq[Power], side: Color): seq[Power] = 
    if side == black: return ps
    else:
        result = ps
        for p in result.mitems:
            inc p.priority

#assumes that there is no intersection between myDrafts and opponentDrafts
proc execute*(myDrafts: seq[Power], opponentDrafts: seq[Power], mySide: Color, board: var ChessBoard, state: var BoardState) = 
    for x in myDrafts:
        assert x notin opponentDrafts or x == emptyPower, x.name & " is somehow in both pools"

    let mySynergizedDrafts = myDrafts
                                .secretSynergize(secretSynergies & secretSecretSynergies)
                                .secretAntiSynergize(opponentDrafts, secretAntiSynergies & secretSecretAntiSynergies)
                                .incrementWhite(mySide)

    let opponentSynergizedDrafts = opponentDrafts
                                .secretSynergize(secretSynergies & secretSecretSynergies)
                                .secretAntiSynergize(myDrafts, secretAntiSynergies & secretSecretAntiSynergies)
                                .incrementWhite(otherSide(mySide))

    for d in concat(mySynergizedDrafts, opponentSynergizedDrafts).sortedByIt(it.priority):
        echo fmt"Executing {d.name} with prio of {d.priority}"


        var side = mySide
        if d notin mySynergizedDrafts: side = otherSide(side)
        d.onStart(side, mySide, board, state) 


proc replaceAnySynergies*(drafterPowers: seq[Power], opponentPowers: seq[Power]): seq[Power] = 
    return drafterPowers.secretSynergize(secretSynergies).secretAntiSynergize(opponentPowers, secretAntiSynergies)

proc getSynergyOf*(index: int): Synergy = 
    for s in draftSynergies & secretSynergies & secretSecretSynergies:
        if s.power.index == index:
            return s
    
    raise newException(IndexDefect, fmt"power of {$index} does not exist or is not of a synergy.")

proc getAntiSynergyOf*(index: int): AntiSynergy = 
    for s in antiSynergies & secretAntiSynergies & secretSecretAntiSynergies:
        if s.power.index == index:
            return s
    
    raise newException(IndexDefect, fmt"power of {$index} does not exist or is not of a synergy.")

proc getPower*(name: string): Power = 
    for p in powers:
        if p.name == name:
            return p

    raise newException(IndexDefect, fmt"power named {name} does not exist.")

proc getAllPowers*(): Table[string, seq[Power]] = 
    let secretSecretPowers = secretSecretSynergies.mapIt(it.power)

    for p in powers:
        if p in secretSecretPowers: continue
        if result.hasKey(p.name):
            result[p.name].add(p)
        else:
            result[p.name] = @[p]

#recursively searches for all power requirements for p, if p is a synergy, and all of the power requirements for those requirements
#TODO split it into an inner aux function, so that addedNaames and alreadyAdded and drafter state are not in the public proc call
proc getLinkedPowers*(p: Power, alreadyAdded: seq[string] = @[], drafter: bool = true): 
    tuple[drafterPows: seq[Power], opponentPows: seq[Power], addedNames: seq[string]] = 

        #I'm struggling to find a solution for the proc when Last Stand specifically is used
        #Since it is a synergy with an anti synergy
        #So for now I'm just going to hard code it 
        if p.name == "Last Stand": return (
            drafterPows: @[getPower("Empress"), getPower("Last Stand")],
            opponentPows: @[getPower("Terminal Illness")],
            addedNames: @[]
        )

        if p.item == NormalPower or not p.secret:
            if drafter: 
                result.drafterPows.add(p)
                echo fmt"{p.name} added to drafter"
            else:
                result.opponentPows.add(p)
                echo fmt"{p.name} added to opponent"

        result.addedNames = alreadyAdded
        result.addedNames.add(p.name)

        if p.item == SyneryPower:
            let synergy = getSynergyOf(p.index)
            for name in synergy.requirements:
                echo name
                if name in synergy.replacements or
                    name in result.addedNames: continue

                for reqPower in power.powers:
                    if reqPower.name == name:
                        var next = getLinkedPowers(reqPower, result.addedNames, drafter)
                        result.drafterPows.add(next.drafterPows)
                        result.addedNames.add(next.addedNames)
                        break

        elif p.item == AntiSynergyPower:
            let anti = getAntiSynergyOf(p.index)
            
            echo "searching for reqs for ", p.name
            
            for name in anti.drafterRequirements:
                if name in result.addedNames: continue

                for reqPower in power.powers:
                    if reqPower.name == name:
                        echo "searching ", reqPower 
                        echo " for drafter req"
                        var next = getLinkedPowers(reqPower, result.addedNames, drafter)
                        echo "next from drafter req: ", next
                        result.drafterPows.add(next.drafterPows)
                        result.opponentPows.add(next.opponentPows)
                        result.addedNames.add(next.addedNames)
                        echo "new result from drafter req: ", result
                        break
            
            for name in anti.opponentRequirements:
                if name in result.addedNames: continue
                
                for reqPower in power.powers:
                    if reqPower.name == name:
                        echo "searching ", reqPower
                        echo " for opponent req. note that drafter is ", not (drafter or p.anti)
                        var next = getLinkedPowers(reqPower, result.addedNames, not drafter)
                        echo "next from opponent req: ", next
                        result.drafterPows.add(next.drafterPows)
                        result.opponentPows.add(next.opponentPows)
                        result.addedNames.add(next.addedNames)
                        echo "new result from opponent req: ", result
                        break




#`nothing` is not registered because it can only be drawn when a normal power cannot be gotten       
registerPower(holy)