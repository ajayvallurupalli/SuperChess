import std/jsffi, std/strutils
from sugar import `=>`
from random import randomize, rand

type
    Peer = JsObject
    Connection = JsObject
    MessageType* = enum
        Id, Handshake, Options, Draft, End, Rematch, Action

var document* {.importc, nodecl.}: JsObject

#prefix for id, so that the id can still be really long while allowing for a simple extension to be tacked on
const baseId: cstring = "9e4ada91-c493-4fd4-881d-3e05db99e100"
#const selfId: cstring = "98660184-4e83-41a2-f461-63aa65d358bb"

#creates an id automatically
proc newPeer(): Peer {.importjs:"""
new Peer(null, {config: {
                        iceServers: [
                            {
                                urls: "turn:standard.relay.metered.ca:80",
                                username: "4eadefa5a1ad93a461469d19",
                                credential: "wLlcdHP/D2ZcRAg/",
                            }
                        ]
                    }
                })
""".}

#sets id to `data`
proc newPeer(data: cstring): Peer {.importjs: """
new Peer(#, {config: {
                        iceServers: [
                            {
                                urls: "turn:standard.relay.metered.ca:80",
                                username: "4eadefa5a1ad93a461469d19",
                                credential: "wLlcdHP/D2ZcRAg/",
                            }
                        ]
                    }
                })
""".}

func messageType(data: cstring): MessageType =  
    var str = $data
    if "id:" in str:
        return Id
    elif "handshake:" in str:
        return Handshake
    elif "options:" in str:
        return Options
    elif "draft:" in str:
        return Draft
    elif "rematch:" in str:
        return Rematch
    elif "end:" in str:
        return End
    elif "action:" in str:
        return Action

func cutMessage(data: cstring): string = 
    return split($data, ':')[1]

proc newHost*(cb: proc(data: string, messageType: MessageType)): tuple[send: proc(data: cstring), destroy: proc()] =
    randomize()
    let roomId: int = rand(10000..99999)
    var peer: Peer = newPeer(baseId & cstring($roomId))
    var conn: Connection
    var connected: bool = false

    peer.on("open", ((id: cstring) => cb($roomId, Id)))
    peer.on("connection", proc (c: Connection) =
        if not connected:
            conn = c
            connected = true
            conn.on("data", proc (data: cstring) = 
                cb(cutMessage(data), messageType(data))
            )
        else:
            var turnDown = c
            turnDown.on("open", () => conn.send("inuse"))
            turnDown.close())



    peer.on("disconnect", proc () =
        echo "DISCONNECT DISCONNECT DISCONNECT"
        peer.id = baseId & cstring($roomId)
        peer.reconnect())

    result.destroy =  proc() = 
        peer.destroy()

    result.send = proc(data: cstring) = 
        conn.send(data)


proc newJoin*(id: cstring, cb: proc(data: string, messageType: MessageType)): tuple[send: proc(data: cstring), destroy: proc()] =
    var peer: Peer = newPeer()
    var conn: Connection
    var connected: bool = false

    peer.on("open", proc () = 
        if not connected:
            conn = peer.connect(baseId & id)
            conn.on("open", proc () = 
                connected = true
                conn.send("handshake:hello")
            )
            conn.on("data", (data: cstring) => cb(cutMessage(data), messageType(data)))
        )

    peer.on("disconnect", proc () =
        echo "DISCONNECT DISCONNECT DISCONNECT"
        peer.id = baseId & id
        peer.reconnect()
    )
    
    result.destroy = proc () = 
        peer.destroy()
    
    result.send = proc(data: cstring) = 
        conn.send(data)
