#Still unfinished
#TODO: MAKE TWO INCREMENT FUNCTIONS: ONE THAT INCREMENTS LOSSES AND ONE THAT INCREMENTS WINS
#AND OF COURSE SPLIT THE DATA ACCORDINGLY

import std/jsffi
import power


{.emit: """
    function increment(item) {
        window.localStorage.setItem(item, parseInt(localStorage.getItem(item)) + 1);
    }
""".}

proc storeHas(item: cstring): bool {.importjs: "window.localStorage.getItem(#) !== null".}
proc addItem(item: cstring) {.importjs: "window.localStorage.setItem(#, 0)".}
proc incrItem(item: cstring) {.importjs: "increment(#)".}

proc initStorage*() =
    for power in powers:
        if not storeHas(power.technicalName.cstring):
            addItem(power.technicalName.cstring)

proc addWins*(with: seq[Power]) =
    for power in with:
        if not storeHas(power.technicalName.cstring):
            addItem(power.technicalName.cstring)
        else:
            incrItem(power.technicalName.cstring)