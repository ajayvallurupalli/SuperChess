import piece, moves
from std/sequtils import foldr, mapIt, filterIt
from std/random import randomize, rand

randomize()

type
    Tier* = enum
        Common, Uncommon, Rare, UltraRare
    FilePath* = string

    Power* = object
        name*: string
        synergy*: bool = true
        tier*: Tier
        rarity*: int = 8
        description*: string
        icon*: FilePath = ""
        onStart*: proc (side: Color, b: var ChessBoard)

    Synergy* = tuple
        power: Power
        requirements: seq[string]
        replacement: string = ""

var 
    powers: seq[Power]
    synergies: seq[Synergy]
    commonPowers: seq[Power]
    uncommonPowers: seq[Power]
    rarePowers: seq[Power]
    ultraRarePowers: seq[Power]


proc hasIcon*(p: Power): bool = 
    return p.icon != ""

proc registerSynergy*(s: Synergy) = 
    synergies.add(s)

proc synergize(pool: seq[Power], currentPowers: seq[Power] ): seq[Power] = 
    for s in synergies:
        if currentPowers.filterIt(it.name in s.requirements).len == s.requirements.len:
            if s.replacement == "":
                return pool & s.power
            else: 
                return pool.filterIt(it.name != s.replacement) & s.power


proc registerPower*(p: Power) = 
    powers.add(p)
    case p.tier
    of Common: commonPowers.add(p)
    of Uncommon: uncommonPowers.add(p)
    of Rare: rarePowers.add(p)
    of UltraRare: ultraRarePowers.add(p)

proc randomPower*(t: Tier, currentPowers: seq[Power]): Power = 
    let search = case t 
        of Common: commonPowers.synergize(currentPowers)
        of Uncommon: uncommonPowers.synergize(currentPowers)
        of Rare: rarePowers.synergize(currentPowers)
        of UltraRare: ultraRarePowers.synergize(currentPowers)

    let sum = foldr(search.mapIt(it.rarity), a + b)
    var x: int = rand(sum)

    for p in search:
        x -= p.rarity
        if x <= 0: return p

