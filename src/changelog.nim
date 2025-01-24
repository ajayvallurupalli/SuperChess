import std/jsfetch
import std/asyncjs
from std/sugar import `=>`
import std/jsffi
import std/tables

const logLocation: cstring = "https://api.github.com/repos/ajayvallurupalli/SuperChess/contents/change_logs"
const rawLocation: cstring = "https://raw.githubusercontent.com/ajayvallurupalli/SuperChess/refs/heads/main/change_logs/"


#yeah I have no clue how async works
#and I don't really care for such a minor data fetch
#so I do it like this i guess
#enjoy the await's nest

proc getLogs(json: JsObject, place: var Table[cstring, cstring]): void {.async.} = 
    for j in json:
        await fetch(rawLocation & j.name.to(cstring))
            .then((response: Response) => response.text())
            .then((text: cstring) => (place[j.name.to(cstring)] = text))

proc getChangeLogs*(place: var Table[cstring, cstring]): void {.async.} = 
    await(fetch(logLocation)
        .then((response: Response) => response.json())
        .then((json: JsObject) => getLogs(json, place))
        .catch((_: Error) => (place["Error"] = "Logs cannot be found. Maybe check your internet?")))
