import std/jsffi
import power


{.emit: """
    function incrementWins(item) {
        let last = JSON.parse(localStorage.getItem(item));
        last.wins += 1;
        localStorage.setItem(item, JSON.stringify(last));
    }

    function incrementLosses(item) {
        let last = JSON.parse(localStorage.getItem(item));
        last.losses += 1;
        localStorage.setItem(item, JSON.stringify(last));
    }
""".}

proc storeHas(item: cstring): bool {.importjs: "localStorage.getItem(#) !== null".}
proc addItem(item: cstring) {.importjs: "localStorage.setItem(#, JSON.stringify({wins: 0, losses: 0}))".}
proc incrItemWins(item: cstring) {.importjs: "incrementWins(#)".}
proc incrItemLosses(item: cstring) {.importjs: "incrementLosses(#)".}
proc getWins(item: cstring): int {.importjs: "JSON.parse(localStorage.getItem(#)).wins".}
proc getLosses(item: cstring): int {.importjs: "JSON.parse(localStorage.getItem(#)).losses".}

proc initStorage*() =
    for power in powers:
        if not storeHas(power.technicalName.cstring):
            addItem(power.technicalName.cstring)

    addItem("wins")
    addItem("losses")

proc addWins*(with: seq[Power]) =
    for power in with:
        if not storeHas(power.technicalName.cstring):
            addItem(power.technicalName.cstring)
        incrItemWins(power.technicalName.cstring)
    incrItemWins("wins")

proc addLosses*(with: seq[Power]) =
    for power in with:
        if not storeHas(power.technicalName.cstring):
            addItem(power.technicalName.cstring)
        incrItemLosses(power.technicalName.cstring)
    incrItemLosses("losses")

proc getRecord*(technicalName: string): tuple[wins: int, losses: int] = 
    result.wins = getWins(technicalName)
    result.losses = getLosses(technicalName)
