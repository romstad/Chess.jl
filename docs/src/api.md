# API Reference

## Boards

```@docs
Board
startboard
fromfen
fen
pprint(b::Board)
pieceon
sidetomove
epsquare
kingsquare
pieces
pawns
knights
bishops
rooks
queens
kings
bishoplike
rooklike
occupiedsquares
emptysquares
cancastlekingside
cancastlequeenside
bishopattacks(b::Board, s::Square)
rookattacks(b::Board, s::Square)
queenattacks(b::Board, s::Square)
isattacked
attacksto
lastmove
ischeck
ischeckmate(b::Board)
isstalemate
ismaterialdraw
isrule50draw
isdraw(b::Board)
isterminal(b::Board)
pinned
domove(b::Board, m::Move)
domove!(b::Board, m::Move)
undomove!
domoves(b::Board, moves::Vararg{Move})
domoves!(b::Board, moves::Vararg{Move})
MoveList
push!(list::MoveList, m::Move)
recycle!
moves
movecount
haslegalmoves
perft
divide
START_FEN
```

## Games

```@docs
SimpleGame
SimpleGame(startboard::Board=startboard())
SimpleGame(startfen::String)
Game
Game()
Game(startboard::Board)
Game(startfen::String)
GameHeader
GameHeaders
GameNode
headervalue
dateplayed
whiteelo
blackelo
setheadervalue!
board
domove!(g::SimpleGame, m::Move)
domoves!(g::SimpleGame, moves::Vararg{Union{Move, String}})
addmove!
addmoves!
nextmove
ply
isatbeginning
isatend
back!
forward!
tobeginning!
toend!
tobeginningofvariation!
tonode!
isleaf
comment
precomment
nag
addcomment!
addprecomment!
addnag!
removeallchildren!
removenode!
adddata!
removedata!
continuations
isdraw(g::SimpleGame)
ischeckmate(g::SimpleGame)
isterminal(g::SimpleGame)
```

## Opening Books

```@docs
BookEntry
createbook
writebooktofile
purgebook
findbookentries
pickbookmove
printbookentries
```

## PGN Files

```@docs
PGNReader
PGNReader(io::IO)
readgame
gamefromstring
gametopgn
gamesinfile
gotonextgame!
```

## UCI Chess Engines

```@docs
Engine
runengine
quit
setoption
sendcommand
setboard
search
BestMoveInfo
parsebestmove
SearchInfo
parsesearchinfo
touci
Score
BoundType
Option
OptionType
OptionValue
```

## Pieces, Piece Types and Piece Colors

```@docs
Piece
Piece(c::PieceColor, t::PieceType)
PieceColor
PieceType
pcolor
ptype
coloropp
isslider
colorfromchar
piecetypefromchar
piecefromchar
tochar(c::PieceColor)
tochar(t::PieceType, uppercase = false)
tochar(p::Piece)
```

## Squares

```@docs
Square
Square(f::SquareFile, r::SquareRank)
SquareFile
SquareRank
SquareDelta
file
rank
distance(s1::Square, s2::Square)
distance(f1::SquareFile, f2::SquareFile)
distance(r1::SquareRank, r2::SquareRank)
filefromchar
rankfromchar
tochar(f::SquareFile)
tochar(r::SquareRank)
squarefromstring
tostring(s::Square)
```

## Moves

```@docs
Move
Move(from::Square, to::Square)
Move(from::Square, to::Square, promotion::PieceType)
from(m::Move)
to(m::Move)
ispromotion(m::Move)
promotion(m::Move)
tostring(m::Move)
movefromstring(s::String)
movefromsan
movetosan
variationtosan(board::Board, v::Vector{Move}; startply=1, movenumbers=true)
variationtosan(g::SimpleGame, v::Vector{Move}; movenumbers=true)
```

## Square Sets
```@docs
SquareSet
isempty
in
squares
union
intersect
-
+
issubset
toarray
squarecount
first
removefirst
issingleton
onlyfirst
shift_n
shift_s
shift_e
shift_w
pawnshift_n
pawnshift_s
pawnshift_nw
pawnshift_ne
pawnshift_sw
pawnshift_se
pawnattacks
knightattacks
bishopattacks(blockers::SquareSet, ::Square)
bishopattacksempty
rookattacks(blockers::SquareSet, ::Square)
rookattacksempty
queenattacks(blockers::SquareSet, ::Square)
queenattacksempty
kingattacks
squaresbetween
pprint(ss::SquareSet)
filesquares
ranksquares
SS_EMPTY
SS_FILE_A
SS_FILE_B
SS_FILE_C
SS_FILE_D
SS_FILE_E
SS_FILE_F
SS_FILE_G
SS_FILE_H
SS_RANK_1
SS_RANK_2
SS_RANK_3
SS_RANK_4
SS_RANK_5
SS_RANK_6
SS_RANK_7
SS_RANK_8
```
