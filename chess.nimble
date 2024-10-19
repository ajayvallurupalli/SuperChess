# Package

version       = "0.1.0"
author        = "Ajay Vallurupalli"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["main"]


# Dependencies

requires "nim >= 2.0.8"

requires "karax >= 1.3.3"

#Tasks
task html, "compiles html in main.nim":
    exec "karun src/main.nim"
    exec "awk '{sub(\"/app.js\",\"./app.js\")}1' app.html > app/app.html"
    exec "rm app.html app/app.js || :"
    exec "mv app.js app"

task jsc, "compiles just the js, instead of doing all that rewriting":
    exec "nim js --out:app.js src/main.nim"

task jscr, "compiles for release":
    exec "nim js --out:app.js -d:release src/main.nim"

task host, "hosts app.html, build from main.nim with task html":
    exec "npx parcel app/app.html"
