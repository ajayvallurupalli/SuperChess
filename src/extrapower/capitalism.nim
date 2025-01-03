import ../piece, std/options
from sugar import `=>`

#I put this into a new folder because I don't like tons of files in main src

func hasWallet*(side: Color, s: BoardState): bool =
    return s.side[side].wallet.isSome()

func getMoney*(side: Color, s: BoardState): int =
    let wallet = s.side[side].wallet
    if wallet.isSome():
        return wallet.get()
    else:
        return -1 #default value instead of erroring

proc addMoney*(side: Color, money: int, s: var BoardState) =
    assert s.side[side].wallet.isSome()
    s.side[side].wallet = s.side[side].wallet.map(x => x + money)

proc initWallet*(side: Color, s: var BoardState) =
    s.side[side].wallet = some(0)

proc buy*(piece: var Piece, option: BuyOption, b: var ChessBoard, s: var BoardState) =
    assert piece.color.hasWallet(s)
    assert option.condition(piece, b, s)

    if piece.color.getMoney(s) >= option.cost(piece, b, s):
        piece.color.addMoney(-option.cost(piece, b, s), s)
        option.action(piece, b, s)


proc buyMoveUpgrade*(move: MoveProc): OnPiece = 
    result = proc (piece: var Piece, board: var ChessBoard, _: var BoardState) = 
        piece.moves &= move

proc buyMoveUpgradeCondition*(move: MoveProc): BuyCondition = 
    result = func (piece: Piece, board: ChessBoard, s: BoardState): bool =
        return move notin piece.moves #only allows buy if piece doesn't already have move
    
const alwaysTrue*: BuyCondition = func (piece: Piece, b: ChessBoard, s: BoardState): bool =
    return true

proc alwaysCost*(cost: int): BuyCost = 
    result = func (piece: Piece, b: ChessBoard, s: BoardState): int = 
        return cost

proc exceptCost*(normalCost: int, exceptPiece: PieceType, exceptCost: int): BuyCost =
    result = func (piece: Piece, b: ChessBoard, s: BoardState): int =
        return if piece.item != exceptPiece: normalcost else: exceptCost
