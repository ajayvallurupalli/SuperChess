import piece
from std/sequtils import foldr, mapIt, filterIt, applyIt
from std/algorithm import sortedByIt
from std/random import randomize, rand

type
    Tier* = enum
        Common, Uncommon, Rare, UltraRare
    FilePath* = string

    Power* = object
        name*: string
        synergy*: bool = true
        tier*: Tier
        rarity*: int = 8
        description*: string = "NONE"
        icon*: FilePath = ""
        rotatable*: bool = false
        noColor*: bool = false
        onStart*: proc (drafterSide: Color, viewerSide: Color, b: var ChessBoard)
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

const defaultWeight*: TierWeights = (60, 30, 9, 1)
const defaultBuffedWeights*: TierWeights = (50, 35, 13, 2)
const defaultInsaneWeights*: TierWeights = (20, 40, 30, 10)

#needed to ensure a power is always given with randomPower
const emptyPower: Power = Power(
    name: "Nothing. Nothing...",
    tier: Common,
    description: "This does nothing. Unlucky!",
    index: 0,
    onStart:
        proc (side: Color, _: Color, b: var ChessBoard) = 
            discard nil
)

const holy*: Power = Power(
    name: "Holy",
    tier: Common,
    priority: 20,
    rarity: 12,
    description: "You are favored slightly more by god. Your next powers are more likely to be uncommon, rare, and ultra rare",
    icon: "cross.svg",
    noColor: true,
    onStart: 
        proc (side: Color, _: Color, b: var ChessBoard) = 
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

proc registerSynergy*(s: Synergy, secret: bool = false, secretSecret = false) = 
    assert secret or not secretSecret #ensures that secret is true whenever secretSecret is true
    var x = s
    x.power.rarity = x.rarity
    x.power.index = powers[powers.len - 1].index + 1
    x.index = x.power.index

    if secret and not secretSecret:
        let str = s.requirements.foldr(a & " + " & b)
        x.power.description = "Secret synergy! (" & str & ") -- "  & x.power.description
    elif not secret:
        let str = s.requirements.foldr(a & " + " & b)
        x.power.description = "Synergy! (" & str & ") "  & x.power.description   

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
                    result = result.filterIt(it.name notin s.replacements) & powers[s.index]

proc seqOf(t: Tier): var seq[Power] = 
    case t
    of Common: return commonPowers
    of Uncommon: return uncommonPowers
    of Rare: return rarePowers
    of UltraRare: return ultraRarePowers

proc registerPower*(p: Power) = 
    var x = p #temp var so that we can increment `Power.index`
    x.index = powers[powers.len - 1].index + 1
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

proc executeOn*(drafts: seq[Power], draftSide: Color, mySide: Color, board: var ChessBoard) = 
    for d in drafts.secretSynergize(secretSynergies & secretSecretSynergies).sortedByIt(it.priority):
        d.onStart(draftSide, mySide, board)

proc replaceAnySynergies*(powers: seq[Power]): seq[Power] = 
    return powers.secretSynergize(secretSynergies)

registerPower(holy)