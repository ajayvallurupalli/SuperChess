from random import randomize, sample
from sequtils import filterIt

const pawnPool = ["Joe", "John"]

proc generateName*(pool: openArray[string], seed: int, 
                  excluding: openArray[string] = @[]): string =
    randomize(seed)
    let cutPool: seq[string] = pool.filterIt(it notin excluding)
    return cutPool.sample()