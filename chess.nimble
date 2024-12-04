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
task jsc, "compiles just the js, instead of doing all that rewriting":
    exec "nim js --out:app.js src/main.nim"

task jscr, "compiles for release": 
    try :
        exec "grep 'debug: bool = false' src/main.nim" #this will do nothing if true, and error if false
        exec "nim js --out:app.js -d:release src/main.nim"
    except OSError:
        echo "YOU FORGOT TO TURN OFF THE DEBUG SWITCH. STUPID STUPID STUPID."

task host, "hosts app.html, build from main.nim with task html":
    exec "npx parcel app/app.html"

task sass, "adds watcher to scss":
    exec "sass --watch styles.scss main.css"
