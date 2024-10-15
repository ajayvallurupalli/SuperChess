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
        description*: string = ""
        icon*: FilePath = ""
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

const defaultWeight: TierWeights = (60, 30, 9, 1)

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

var 
    powers*: seq[Power] = @[emptyPower]
    draftSynergies*: seq[Synergy]
    secretSynergies*: seq[Synergy]
    commonPowers*: seq[Power]
    uncommonPowers*: seq[Power]
    rarePowers*: seq[Power]
    ultraRarePowers*: seq[Power]

proc registerSynergy*(s: Synergy, secret: bool = false, secretSecret = false) = 
    var x = s
    x.power.rarity = x.rarity
    x.power.index = powers[powers.len - 1].index + 1
    x.index = x.power.index

    if secret and not secretSecret:
        let str = s.replacements.foldr(a & " + " & b)
        x.power.description = "Secret synergy! (" & str & ") "  & x.power.description
    elif not secret:
        let str = s.replacements.foldr(a & " + " & b)
        x.power.description = "Snergy! (" & str & ") "  & x.power.description   

    powers.add(x.power)
    if secret: secretSynergies.add(x) else: draftSynergies.add(x)

proc synergize(pool: seq[Power], synergies: seq[Synergy], currentPowers: seq[Power], t: Tier, allTiers: bool = false): seq[Power] =
    result = pool 
    for s in synergies:
        if currentPowers.filterIt(it.name in s.requirements).len == s.requirements.len and 
           (s.power.tier == t or allTiers):
                if s.replacements.len == 0:
                    result &= powers[s.index]
                else: 
                    result = result.filterIt(it.name notin s.replacements) & powers[s.index]
    return result

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
    let search = seqOf(t).filterIt(it.name notin alreadySelected.mapIt(it.name)).synergize(draftSynergies, currentPowers, t)
    if search.len == 0: return emptyPower

    let sum = foldr(search.mapIt(it.rarity), a + b)
    var x: int = rand(sum)

    for p in search:
        x -= p.rarity
        if x <= 0: return p

proc randomTier(w: TierWeights = defaultWeight): Tier = 
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

proc draftPowerTier*(t: Tier, allSelected: seq[Power], drafterSelected: seq[Power], options: int = 1): seq[Power] = 
    for x in 0..options - 1:
        result.add(randomPower(t, drafterSelected, allSelected & result))

proc draftRandomPower*(allSelected: seq[Power], drafterSelected: seq[Power], options: int = 1, weights: TierWeights = defaultWeight): seq[Power] = 
    for x in 0..options - 1:
        result.add(randomPower(randomTier(weights), drafterSelected, allSelected & result))

proc executeOn*(drafts: seq[Power], draftSide: Color, mySide: Color, board: var ChessBoard) = 
    for d in drafts.synergize(secretSynergies, drafts, Common, true).sortedByIt(it.priority):
        d.onStart(draftSide, mySide, board)