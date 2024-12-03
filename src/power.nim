import piece
from std/sequtils import foldr, mapIt, filterIt, concat
from std/algorithm import sortedByIt
from std/random import randomize, rand

type
    Tier* = enum
        Common, Uncommon, Rare, UltraRare
    FilePath* = string

    OnStart* = proc (drafterSide: Color, viewerSide: Color, b: var ChessBoard, s: var BoardState)

    Power* = object
        name*: string
        technicalName*: string = ""
        synergy*: bool = true #can i delete?
        tier*: Tier
        rarity*: int = 8
        description*: string = "NONE"
        icon*: FilePath = ""
        rotatable*: bool = false
        noColor*: bool = false
        onStart*: OnStart
        index*: int = -1
        priority*: int = 10

    Synergy* = tuple
        power: Power
        rarity: int
        requirements: seq[string]
        replacements: seq[string]
        index: int
    
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

#holy is a special power used in `draftRandomPower`, so it's defined here instead
const holy*: Power = Power(
    name: "Holy",
    tier: Common,
    priority: 20,
    rarity: 12,
    description: "You are favored slightly more by god. Your next powers are more likely to be uncommon, rare, and ultra rare",
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
    commonPowers*: seq[Power]
    uncommonPowers*: seq[Power]
    rarePowers*: seq[Power]
    ultraRarePowers*: seq[Power]

#I know I should use an enum instead of secret and secretSecret, but I think this is funner
proc registerSynergy*(s: Synergy, secret: bool = false, secretSecret = false) = 
    assert secret or not secretSecret #ensures that secretSecret is true if and only if secret is true
    var x = s
    
    x.power.rarity = x.rarity
    x.power.index = powers[powers.len - 1].index + 1
    x.index = x.power.index

    let requirements = s.requirements.foldr(a & " + " & b)

    if secret and not secretSecret: #Secret Synergies
        x.power.description = "Secret synergy! (" & requirements & ") -- "  & x.power.description
        x.power.technicalName = 
            if x.power.technicalName == "": x.power.name & " (Secret Synergy of " & requirements & ")"
            else: x.power.technicalName & " (Secret Synergy of " & requirements & ")"
    elif not secret: #Normal Synergies
        x.power.description = "Synergy! (" & requirements & ") "  & x.power.description   
        x.power.technicalName = 
            if x.power.technicalName == "": x.power.name & " (Synergy of " & requirements & ")"
            else: x.power.technicalName & " (Synergy of " & requirements & ")"
    else: #Secret Secret Synergies
        x.power.technicalName = 
            if x.power.technicalName == "": x.power.name & " (Secret Secret Synergy of " & requirements & ")"
            else: x.power.technicalName & " (Secret Secret Synergy of " & requirements & ")"

    powers.add(x.power)
    if secretSecret: secretSecretSynergies.add(x) 
    elif secret: secretSynergies.add(x)
    else: draftSynergies.add(x)

proc synergize(pool: seq[Power], currentPowers: seq[Power], t: Tier): seq[Power] =
    result = pool 
    for s in draftSynergies:
        if currentPowers.filterIt(it.name in s.requirements).len == s.requirements.len:
                if s.replacements.len == 0:
                    result &= powers[s.index]
                else: 
                    result = result.filterIt(it.name notin s.replacements) & powers[s.index]

proc secretSynergize(currentPowers: seq[Power], synergies: seq[Synergy]): seq[Power] = 
    result = currentPowers

    for s in synergies.sortedByIt(it.power.priority):
        if result.filterIt(it.name in s.requirements).len == s.requirements.len:
            if s.replacements.len == 0:
                result &= powers[s.index]
            else: 
                result = result.filterIt(it.name != "Illegal Formation") & powers[s.index]

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

proc randomPower(t: Tier, currentPowers: seq[Power], alreadySelected: seq[Power] = @[]): Power = 
    let search = seqOf(t).synergize(currentPowers, t).filterIt(it.name notin alreadySelected.mapIt(it.name))
    if search.len == 0: return emptyPower

    let sum = foldr(search.mapIt(it.rarity), a + b)
    var x: int = rand(sum)

    for p in search:
        x -= p.rarity
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

proc draftRandomPowerTier*(t: Tier, allSelected: seq[Power], drafterSelected: seq[Power], options: int = 1, normalWeights: TierWeights = defaultWeight, buffedWeights: TierWeights = defaultBuffedWeights): seq[Power] = 
    for x in 0..options - 1:
        result.add(randomPower(t, drafterSelected, allSelected & result))

proc draftRandomPower*(allSelected: seq[Power], drafterSelected: seq[Power], options: int = 1, normalWeights: TierWeights = defaultWeight, buffedWeights: TierWeights = defaultBuffedWeights): seq[Power] = 
    let weights = if holy in drafterSelected: buffedWeights else: normalWeights
    for x in 0..options - 1:
        result.add(randomPower(randomTier(weights), drafterSelected, allSelected & result))

#assumes that there is no intersection between myDrafts and opponentDrafts
proc execute*(myDrafts: seq[Power], opponentDrafts: seq[Power], mySide: Color, board: var ChessBoard, state: var BoardState) = 
    for x in myDrafts:
        assert x notin opponentDrafts and x.name != emptyPower.name, x.name & " is somehow in both pools"

    let mySynergizedDrafts = myDrafts.secretSynergize(secretSynergies & secretSecretSynergies)
    let opponentSynergizedDrafts = opponentDrafts.secretSynergize(secretSynergies & secretSecretSynergies)

    for d in concat(mySynergizedDrafts, opponentSynergizedDrafts).sortedByIt(it.priority):
        if d in mySynergizedDrafts:
            d.onStart(mySide, mySide, board, state)
        else:
            d.onStart(otherSide(mySide), mySide, board, state)

proc replaceAnySynergies*(powers: seq[Power]): seq[Power] = 
    return powers.secretSynergize(secretSynergies)

registerPower(holy)