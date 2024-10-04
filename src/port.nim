import std/jsffi, std/strutils
from sugar import `=>`

type
    Peer = JsObject
    Connection = JsObject
    MessageType* = enum
        Id, Handshake, Move

proc newPeer*(): Peer {.importjs: "new Peer()".}

func messageType(data: cstring): MessageType =  
    var str = $data
    if "id:" in str:
        return Id
    elif "handshake:" in str:
        return Handshake
    elif "move: " in str:
        return Move

func cutMessage(data: cstring): string = 
    return split($data, ':')[1]

proc newHost*(cb: proc(data: string, messageType: MessageType)): tuple[send: proc(data: cstring), destroy: proc()] =
    var peer: Peer = newPeer()
    var conn: Connection

    peer.on("open", ((id: cstring) => cb($id, Id)))
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
        conn = peer.connect(id)
        conn.on("open", () => conn.send("handshake: hello"))
        conn.on("data", (data: cstring) => cb(cutMessage(data), messageType(data))))
    
    result.destroy = proc () = 
        peer.destroy()
    
    result.send = proc(data: cstring) = 
        conn.send(data)