import std/jsffi, std/strutils
from sugar import `=>`
from random import randomize, rand

type
    Peer = JsObject
    Connection = JsObject
    MessageType* = enum
        Id, Handshake, Move, Options

const baseId: cstring = "9e4ada91-c493-4fd4-881d-3e05db99e100"

proc newPeer*(): Peer {.importjs:
 """new Peer(null, {config: {
                        iceServers: [
                            {
                                urls: "turn:standard.relay.metered.ca:80",
                                username: "4eadefa5a1ad93a461469d19",
                                credential: "wLlcdHP/D2ZcRAg/",
                            }
                        ]
                    }
                })""".}
proc newPeer*(data: cstring): Peer {.importjs: 
"""new Peer(#, {config: {
                        iceServers: [
                            {
                                urls: "turn:standard.relay.metered.ca:80",
                                username: "4eadefa5a1ad93a461469d19",
                                credential: "wLlcdHP/D2ZcRAg/",
                            }
                        ]
                    }
                })""".}

func messageType(data: cstring): MessageType =  
    var str = $data
    if "id:" in str:
        return Id
    elif "handshake:" in str:
        return Handshake
    elif "move:" in str:
        return Move
    elif "options:" in str:
        return Options

func cutMessage(data: cstring): string = 
    return split($data, ':')[1]

proc newHost*(cb: proc(data: string, messageType: MessageType)): tuple[send: proc(data: cstring), destroy: proc()] =
    randomize()
    let roomId: int = rand(10000..99999)
    var peer: Peer = newPeer(baseId & cstring($roomId))
    var conn: Connection

    peer.on("open", ((id: cstring) => cb($roomId, Id)))
    peer.on("connection", proc (c: Connection) =
        conn = c
        conn.on("data", (data: cstring) => cb(cutMessage(data), messageType(data))))

    result.destroy =  proc() = 
        peer.destroy()

    result.send = proc(data: cstring) = 
        conn.send(data)


proc newJoin*(id: cstring, cb: proc(data: string, messageType: MessageType)): tuple[send: proc(data: cstring), destroy: proc()] =
    var peer: Peer = newPeer()
    var conn: Connection
    peer.on("open", proc () = 
        conn = peer.connect(baseId & id)
        conn.on("open", () => conn.send("handshake:hello"))
        conn.on("data", (data: cstring) => cb(cutMessage(data), messageType(data))))
    
    result.destroy = proc () = 
        peer.destroy()
    
    result.send = proc(data: cstring) = 
        conn.send(data)