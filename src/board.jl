#=
        Chess.jl: A Julia chess programming library
        Copyright (C) 2019 Tord Romstad

        This program is free software: you can redistribute it and/or modify
        it under the terms of the GNU Affero General Public License as
        published by the Free Software Foundation, either version 3 of the
        License, or (at your option) any later version.

        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU Affero General Public License for more details.

        You should have received a copy of the GNU Affero General Public License
        along with this program.  If not, see <https://www.gnu.org/licenses/>.
=#

using Crayons
using StaticArrays

include("key.jl")

import Base.push!

export START_FEN

export Board, MoveList, UndoInfo

export attacksto, bishopattacks, bishoplike, bishops, cancastlekingside,
    cancastlequeenside, copyto!, divide, domove, domove!, domoves, domoves!,
    emptyboard, emptysquares, epsquare, fen, fromfen, haslegalmoves, isattacked,
    ischeck, ischeckmate, isdraw, ismaterialdraw, isrule50draw, isstalemate,
    isterminal, kings, kingsquare, knights, lastmove, movecount, moves,
    occupiedsquares, pawns, perft, pieceon, pieces, pinned, pprint,
    queenattacks, queens, recycle!, rooklike, rookattacks, rooks, sidetomove,
    startboard, undomove!


"""
    Board

Type representing a chess board.

A chess board is most commonly obtained from a FEN string (using the
`fromfen()` function), from the `startboard()` function (which returns a board
in the usual chess starting position), or by making a move on some other chess
board.
"""
mutable struct Board
    board::MVector{64, UInt8}
    bycolor::MVector{2, SquareSet}
    bytype::MVector{6, SquareSet}
    side::UInt8
    castlerights::UInt8
    epsq::UInt8
    r50::UInt8
    ksq::MVector{2, UInt8}
    move::UInt16
    occ::SquareSet
    checkers::SquareSet
    pin::SquareSet
    key::UInt64
end


function Base.show(io::IO, b::Board)
    println(io, "Board ($(fen(b))):")
    for ri in 1:8
        r = SquareRank(ri)
        for fi in 1:8
            f = SquareFile(fi)
            p = pieceon(b, f, r)
            if isok(p)
                print(io, " $(tochar(p)) ")
            else
                print(io, " - ")
            end
        end
        if ri < 8
            println(io, "")
        end
    end
    # print(io, "Board($(fen(b)))")
end


function copyto!(dest::Board, src::Board)
    copyto!(dest.board, src.board)
    copyto!(dest.bycolor, src.bycolor)
    copyto!(dest.bytype, src.bytype)
    dest.side = src.side
    dest.castlerights = src.castlerights
    dest.epsq = src.epsq
    dest.r50 = src.r50
    copyto!(dest.ksq, src.ksq)
    dest.move = src.move
    dest.occ = src.occ
    dest.checkers = src.checkers
    dest.pin = src.pin
    dest.key = src.key
    dest
end


function emptyboard()::Board
    Board(
        @MVector([UInt8(EMPTY.val) for _ in 1:64]),
        @MVector([SS_EMPTY, SS_EMPTY]),
        @MVector([SS_EMPTY, SS_EMPTY, SS_EMPTY, SS_EMPTY, SS_EMPTY, SS_EMPTY]),
        UInt8(WHITE.val),
        0,
        UInt8(SQ_NONE.val),
        0,
        @MVector([SQ_NONE.val, SQ_NONE.val]),
        0,
        SS_EMPTY,
        SS_EMPTY,
        SS_EMPTY,
        0
    )
end


"""
    pieceon(b::Board, s::Square)
    pieceon(b::Board, f::SquareFile, r::SquareRank)
    pieceon(b::Board, s::String)

Find the piece on the given square of the board.

# Examples

```julia-repl
julia> b = startboard();

julia> pieceon(b, SQ_E1)
PIECE_WK

julia> pieceon(b, FILE_B, RANK_8)
PIECE_BN

julia> pieceon(b, SQ_B5)
EMPTY

julia> pieceon(b, "d8")
PIECE_BQ
```
"""
function pieceon(b::Board, s::Square)::Piece
    @inbounds Piece(b.board[s.val])
end

function pieceon(b::Board, f::SquareFile, r::SquareRank)::Piece
    pieceon(b, Square(f, r))
end

function pieceon(b::Board, s::String)
    pieceon(b, squarefromstring(s))
end


"""
    sidetomove(b::Board)

The current side to move, `WHITE` or `BLACK`.

# Examples

```julia-repl
julia> b = startboard();

julia> b2 = domove(b, "e4");

julia> sidetomove(b)
WHITE

julia> sidetomove(b2)
BLACK
```
"""
function sidetomove(b::Board)::PieceColor
    PieceColor(b.side)
end


"""
    epsquare(b::Board)

The square on which an en passant capture is possible, or `SQ_NONE`.
"""
function epsquare(b::Board)::Square
    Square(b.epsq)
end


"""
    kingsquare(b::Board, c::PieceColor)

The square of the king for the given side.

# Examples

```julia-repl
julia> b = startboard();

julia> kingsquare(b, WHITE)
SQ_E1

julia> kingsquare(b, BLACK)
SQ_E8
```
"""
function kingsquare(b::Board, c::PieceColor)::Square
    @inbounds Square(b.ksq[c.val])
end


"""
    pieces(b::Board, c::PieceColor)
    pieces(b::Board, t::PieceType)
    pieces(b::Board, c::PieceColor, t::PieceType)
    pieces(b::Board, p::Piece)

Obtain the set of squares containing various kinds of pieces.

# Examples

```julia-repl
julia> b = startboard();

julia> pieces(b, WHITE) == SS_RANK_1 ∪ SS_RANK_2
true

julia> pieces(b, ROOK) == SquareSet(SQ_A1, SQ_H1, SQ_A8, SQ_H8)
true

julia> pieces(b, BLACK, PAWN) == SS_RANK_7
true

julia> pieces(b, PIECE_WB)
SquareSet:
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  #  -  -  #  -  -
```
"""
function pieces(b::Board, c::PieceColor)::SquareSet
    @inbounds b.bycolor[c.val]
end

function pieces(b::Board, t::PieceType)::SquareSet
    @inbounds b.bytype[t.val]
end

function pieces(b::Board, c::PieceColor, t::PieceType)::SquareSet
    pieces(b, c) ∩ pieces(b, t)
end

function pieces(b::Board, p::Piece)::SquareSet
    pieces(b, pcolor(p), ptype(p))
end


"""
    pawns(b::Board)

The set of squares containing pawns of either color.

# Examples

```julia-repl
julia> b = startboard();

julia> pawns(b) == SS_RANK_2 ∪ SS_RANK_7
true
```
"""
function pawns(b::Board)::SquareSet
    pieces(b, PAWN)
end


"""
    pawns(b::Board, c::PieceColor)

The set of squares containing pawns of the given color.

# Examples

```julia-repl
julia> b = startboard();

julia> pawns(b, WHITE) == SS_RANK_2
true

julia> pawns(b, BLACK) == SS_RANK_7
true
```
"""
function pawns(b::Board, c::PieceColor)::SquareSet
    pieces(b, c, PAWN)
end


"""
    knights(b::Board)

The set of squares containing knights of either color.

# Examples

```julia-repl
julia> b = startboard();

julia> knights(b) == SquareSet(SQ_B1, SQ_G1, SQ_B8, SQ_G8)
true
```
"""
function knights(b::Board)::SquareSet
    pieces(b, KNIGHT)
end


"""
    knights(b::Board, c::PieceColor)

The set of squares containing knights of the given color.

# Examples

```julia-repl
julia> b = startboard();

julia> knights(b, WHITE) == SquareSet(SQ_B1, SQ_G1)
true

julia> knights(b, BLACK) == SquareSet(SQ_B8, SQ_G8)
true
```
"""
function knights(b::Board, c::PieceColor)::SquareSet
    pieces(b, c, KNIGHT)
end


"""
    bishops(b::Board)

The set of squares containing bishops of either color.

# Examples

```julia-repl
julia> b = startboard();

julia> bishops(b) == SquareSet(SQ_C1, SQ_F1, SQ_C8, SQ_F8)
true
```
"""
function bishops(b::Board)::SquareSet
    pieces(b, BISHOP)
end


"""
    bishops(b::Board, c::PieceColor)

The set of squares containing bishops of the given color.

# Examples

```julia-repl
julia> b = startboard();

julia> bishops(b, WHITE) == SquareSet(SQ_C1, SQ_F1)
true

julia> bishops(b, BLACK) == SquareSet(SQ_C8, SQ_F8)
true
```
"""
function bishops(b::Board, c::PieceColor)::SquareSet
    pieces(b, c, BISHOP)
end


"""
    rooks(b::Board)

The set of squares containing rooks of either color.

# Examples

```julia-repl
julia> b = startboard();

julia> rooks(b) == SquareSet(SQ_A1, SQ_H1, SQ_A8, SQ_H8)
true
```
"""
function rooks(b::Board)::SquareSet
    pieces(b, ROOK)
end


"""
    rooks(b::Board, c::PieceColor)

The set of squares containing rooks of the given color.

# Examples

```julia-repl
julia> b = startboard();

julia> rooks(b, WHITE) == SquareSet(SQ_A1, SQ_H1)
true

julia> rooks(b, BLACK) == SquareSet(SQ_A8, SQ_H8)
true
```
"""
function rooks(b::Board, c::PieceColor)::SquareSet
    pieces(b, c, ROOK)
end


"""
    queens(b::Board)

The set of squares containing queens of either color.

# Examples

```julia-repl
julia> b = startboard();

julia> queens(b) == SquareSet(SQ_D1, SQ_D8)
true
```
"""
function queens(b::Board)::SquareSet
    pieces(b, QUEEN)
end


"""
    queens(b::Board, c::PieceColor)

The set of squares containing queens of the given color.

# Examples

```julia-repl
julia> b = startboard();

julia> queens(b, WHITE) == SquareSet(SQ_D1)
true

julia> queens(b, BLACK) == SquareSet(SQ_D8)
true
```
"""
function queens(b::Board, c::PieceColor)::SquareSet
    pieces(b, c, QUEEN)
end


"""
    kings(b::Board)

The set of squares containing kings of either color.

# Examples

```julia-repl
julia> b = startboard();

julia> kings(b) == SquareSet(SQ_E1, SQ_E8)
true
```
"""
function kings(b::Board)::SquareSet
    pieces(b, KING)
end


"""
    kings(b::Board, c::PieceColor)

The set of squares containing kings of the given color.

Unless something is very wrong, this set should always contain exactly one
square.

# Examples

```julia-repl
julia> b = startboard();

julia> kings(b, WHITE) == SquareSet(SQ_E1)
true

julia> kings(b, BLACK) == SquareSet(SQ_E8)
true
```
"""
function kings(b::Board, c::PieceColor)::SquareSet
    pieces(b, c, KING)
end


"""
    bishoplike(b::Board)

The set of squares containing bishoplike pieces of either color.

The bishoplike pieces are the pieces that can move like a bishop, i.e. bishops
and queens.

# Examples

```julia-repl
julia> b = startboard();

julia> bishoplike(b) == SquareSet(SQ_C1, SQ_D1, SQ_F1, SQ_C8, SQ_D8, SQ_F8)
true
```
"""
function bishoplike(b::Board)::SquareSet
    bishops(b) ∪ queens(b)
end


"""
    bishoplike(b::Board, c::PieceColor)

The set of squares containing bishoplike pieces of the given color.

The bishoplike pieces are the pieces that can move like a bishop, i.e. bishops
and queens.

# Examples

```julia-repl
julia> b = startboard();

julia> bishoplike(b, WHITE) == SquareSet(SQ_C1, SQ_D1, SQ_F1)
true

julia> bishoplike(b, BLACK) == SquareSet(SQ_C8, SQ_D8, SQ_F8)
true
```
"""
function bishoplike(b::Board, c::PieceColor)::SquareSet
    bishoplike(b) ∩ pieces(b, c)
end


"""
    rooklike(b::Board)

The set of squares containing rooklike pieces of either color.

The rooklike pieces are the pieces that can move like a rook, i.e. rooks
and queens.

# Examples

```julia-repl
julia> b = startboard();

julia> rooklike(b) == SquareSet(SQ_A1, SQ_D1, SQ_H1, SQ_A8, SQ_D8, SQ_H8)
true
```
"""
function rooklike(b::Board)::SquareSet
    rooks(b) ∪ queens(b)
end


"""
    rooklike(b::Board, c::PieceColor)

The set of squares containing rooklike pieces of the given color.

The rooklike pieces are the pieces that can move like a rook, i.e. rooks
and queens.

# Examples

```julia-repl
julia> b = startboard();

julia> rooklike(b, WHITE) == SquareSet(SQ_A1, SQ_D1, SQ_H1)
true

julia> rooklike(b, BLACK) == SquareSet(SQ_A8, SQ_D8, SQ_H8)
true
```
"""
function rooklike(b::Board, c::PieceColor)::SquareSet
    rooklike(b) ∩ pieces(b, c)
end


"""
    occupiedsquares(b::Board)
    emptysquares(b::Board)

The set of all occupied or empty squares on the board.

# Examples

```julia-repl
julia> b = startboard();

julia> occupiedsquares(b) == pieces(b, WHITE) ∪ pieces(b, BLACK)
true

julia> emptysquares(b) == SS_RANK_3 ∪ SS_RANK_4 ∪ SS_RANK_5 ∪ SS_RANK_6
true

julia> isempty(emptysquares(b) ∩ occupiedsquares(b))
true
```
"""
function occupiedsquares(b::Board)::SquareSet
    b.occ
end,

function emptysquares(b::Board)::SquareSet
    -occupiedsquares(b)
end


"""
    cancastlekingside(b::Board, c::PieceColor)

Determine whether the given side still has the right to castle kingside.
"""
function cancastlekingside(b::Board, c::PieceColor)::Bool
    (b.castlerights & (1 << (2 * (c.val - 1)))) ≠ 0
end


"""
    cancastlequeenside(b::Board, c::PieceColor)

Determine whether the given side still has the right to castle queenside.
"""
function cancastlequeenside(b::Board, c::PieceColor)::Bool
    (b.castlerights & (2 << (2 * (c.val - 1)))) ≠ 0
end


"""
    bishopattacks(b::Board, s::Square)

The set of squares a bishop on square `s` would attack on this board.

Both empty squares and squares occupied by enemy or friendly pieces are
included in the set.

# Examples

```julia-repl
julia> b = fromfen("5k2/8/4q3/8/2B5/8/4P3/3K4 w - -");

julia> pprint(b, highlight=bishopattacks(b, SQ_C4))
+---+---+---+---+---+---+---+---+
|   |   |   |   |   | k |   |   |
+---+---+---+---+---+---+---+---+
|   |   |   |   |   |   |   |   |
+---+---+---+---+---+---+---+---+
| * |   |   |   |*q*|   |   |   |
+---+---+---+---+---+---+---+---+
|   | * |   | * |   |   |   |   |
+---+---+---+---+---+---+---+---+
|   |   | B |   |   |   |   |   |
+---+---+---+---+---+---+---+---+
|   | * |   | * |   |   |   |   |
+---+---+---+---+---+---+---+---+
| * |   |   |   |*P*|   |   |   |
+---+---+---+---+---+---+---+---+
|   |   |   | K |   |   |   |   |
+---+---+---+---+---+---+---+---+
5k2/8/4q3/8/2B5/8/4P3/3K4 w - -
```
"""
function bishopattacks(b::Board, s::Square)::SquareSet
    bishopattacks(b.occ, s)
end


"""
    rookattacks(b::Board, s::Square)

The set of squares a rook on square `s` would attack on this board.

Both empty squares and squares occupied by enemy or friendly pieces are
included in the set.

# Examples

```julia-repl
julia> b = fromfen("2r2k2/8/8/8/2R3P1/8/4P3/3K4 w - -");

julia> pprint(b, highlight=rookattacks(b, SQ_C4))
+---+---+---+---+---+---+---+---+
|   |   |*r*|   |   | k |   |   |
+---+---+---+---+---+---+---+---+
|   |   | * |   |   |   |   |   |
+---+---+---+---+---+---+---+---+
|   |   | * |   |   |   |   |   |
+---+---+---+---+---+---+---+---+
|   |   | * |   |   |   |   |   |
+---+---+---+---+---+---+---+---+
| * | * | R | * | * | * |*P*|   |
+---+---+---+---+---+---+---+---+
|   |   | * |   |   |   |   |   |
+---+---+---+---+---+---+---+---+
|   |   | * |   | P |   |   |   |
+---+---+---+---+---+---+---+---+
|   |   | * | K |   |   |   |   |
+---+---+---+---+---+---+---+---+
2r2k2/8/8/8/2R3P1/8/4P3/3K4 w - -
```
"""
function rookattacks(b::Board, s::Square)::SquareSet
    rookattacks(b.occ, s)
end


"""
    queenattacks(b::Board, s::Square)

The set of squares a queen on square `s` would attack on this board.

Both empty squares and squares occupied by enemy or friendly pieces are
included in the set.

# Examples

```julia-repl
julia> b = fromfen("2r2k2/8/8/8/2Q3P1/8/4P3/3K4 w - -");

julia> pprint(b, highlight=queenattacks(b, SQ_C4))
+---+---+---+---+---+---+---+---+
|   |   |*r*|   |   | k | * |   |
+---+---+---+---+---+---+---+---+
|   |   | * |   |   | * |   |   |
+---+---+---+---+---+---+---+---+
| * |   | * |   | * |   |   |   |
+---+---+---+---+---+---+---+---+
|   | * | * | * |   |   |   |   |
+---+---+---+---+---+---+---+---+
| * | * | Q | * | * | * |*P*|   |
+---+---+---+---+---+---+---+---+
|   | * | * | * |   |   |   |   |
+---+---+---+---+---+---+---+---+
| * |   | * |   |*P*|   |   |   |
+---+---+---+---+---+---+---+---+
|   |   | * | K |   |   |   |   |
+---+---+---+---+---+---+---+---+
2r2k2/8/8/8/2Q3P1/8/4P3/3K4 w - -
```
"""
function queenattacks(b::Board, s::Square)::SquareSet
    queenattacks(b.occ, s)
end


"""
    isattacked(b::Board, s::Square, side::PieceColor)

Determine whether the given square is attacked by the given side.

# Examples

```julia-repl
julia> b = startboard();

julia> isattacked(b, SQ_F3, WHITE)
true

julia> isattacked(b, SQ_F3, BLACK)
false
```
"""
function isattacked(b::Board, s::Square, side::PieceColor)::Bool
    !isempty(pawnattacks(coloropp(side), s) ∩ pawns(b, side)) ||
        !isempty(knightattacks(s) ∩ knights(b, side)) ||
        !isempty(kingattacks(s) ∩ kings(b, side)) ||
        !isempty(bishopattacks(b, s) ∩ bishoplike(b, side)) ||
        !isempty(rookattacks(b, s) ∩ rooklike(b, side))
end


"""
    attacksto(b::Board, s::Square)

The set of squares containing pieces of either color which attack square `s`.

# Examples

```julia-repl
julia> b = fromfen("r1bqkbnr/pppp1ppp/2n5/4p3/3PP3/5N2/PPP2PPP/RNBQKB1R b KQkq - 0 3");

julia> pprint(b, highlight=attacksto(b, SQ_D4))
+---+---+---+---+---+---+---+---+
| r |   | b | q | k | b | n | r |
+---+---+---+---+---+---+---+---+
| p | p | p | p |   | p | p | p |
+---+---+---+---+---+---+---+---+
|   |   |*n*|   |   |   |   |   |
+---+---+---+---+---+---+---+---+
|   |   |   |   |*p*|   |   |   |
+---+---+---+---+---+---+---+---+
|   |   |   | P | P |   |   |   |
+---+---+---+---+---+---+---+---+
|   |   |   |   |   |*N*|   |   |
+---+---+---+---+---+---+---+---+
| P | P | P |   |   | P | P | P |
+---+---+---+---+---+---+---+---+
| R | N | B |*Q*| K | B |   | R |
+---+---+---+---+---+---+---+---+
r1bqkbnr/pppp1ppp/2n5/4p3/3PP3/5N2/PPP2PPP/RNBQKB1R b KQkq -
```
"""
function attacksto(b::Board, s::Square)::SquareSet
    (pawnattacks(BLACK, s) ∩ pawns(b, WHITE)) ∪
        (pawnattacks(WHITE, s) ∩ pawns(b, BLACK)) ∪
        (knightattacks(s) ∩ knights(b)) ∪
        (bishopattacks(b, s) ∩ bishoplike(b)) ∪
        (rookattacks(b, s) ∩ rooklike(b)) ∪
        (kingattacks(s) ∩ kings(b))
end


"""
    lastmove(b::Board)

The last move that was played to reach this board position.
"""
function lastmove(b::Board)::Move
    Move(b.move)
end


"""
    ischeck(b::Board)

Determine whether the current side to move is in check.
"""
function ischeck(b::Board)::Bool
    !isempty(b.checkers)
end


"""
    pinned(b::Board)

The set of squares containing pinned pieces for the current side to move.

# Examples

```julia-repl
julia> b = fromfen("2r4b/1kp5/8/2P1Q3/1P6/2K1P2r/8/8 w - -");

julia> pprint(b, highlight=pinned(b))
+---+---+---+---+---+---+---+---+
|   |   | r |   |   |   |   | b |
+---+---+---+---+---+---+---+---+
|   | k | p |   |   |   |   |   |
+---+---+---+---+---+---+---+---+
|   |   |   |   |   |   |   |   |
+---+---+---+---+---+---+---+---+
|   |   | P |   |*Q*|   |   |   |
+---+---+---+---+---+---+---+---+
|   | P |   |   |   |   |   |   |
+---+---+---+---+---+---+---+---+
|   |   | K |   |*P*|   |   | r |
+---+---+---+---+---+---+---+---+
|   |   |   |   |   |   |   |   |
+---+---+---+---+---+---+---+---+
|   |   |   |   |   |   |   |   |
+---+---+---+---+---+---+---+---+
2r4b/1kp5/8/2P1Q3/1P6/2K1P2r/8/8 w - -
```
"""
function pinned(b::Board)::SquareSet
    b.pin
end


function putpiece!(b::Board, p::Piece, s::Square)
    c = pcolor(p)
    t = ptype(p)
    b.board[s.val] = p.val
    b.bycolor[c.val] += s
    b.bytype[t.val] += s
    b.occ += s
    if t == KING
        b.ksq[c.val] = s.val
    end
    b.key ⊻= zobrist(p, s)
end


function removepiece!(b::Board, s::Square)
    p = pieceon(b, s)
    c = pcolor(p)
    t = ptype(p)
    b.board[s.val] = EMPTY.val
    b.bycolor[c.val] -= s
    b.bytype[t.val] -= s
    b.occ -= s
    b.key ⊻= zobrist(p, s)
end


function movepiece!(b::Board, f::Square, t::Square)
    p = pieceon(b, f)
    c = pcolor(p)
    pt = ptype(p)
    b.board[f.val] = EMPTY.val
    b.board[t.val] = p.val
    b.bycolor[c.val] -= f
    b.bycolor[c.val] += t
    b.bytype[pt.val] -= f
    b.bytype[pt.val] += t
    b.occ -= f
    b.occ += t
    if pt == KING
        b.ksq[c.val] = t.val
    end
    b.key ⊻= zobrist(p, f)
    b.key ⊻= zobrist(p, t)
end


function setep!(b::Board, f::Square, t::Square)
    if t - f == 2 * DELTA_N
        epsq = f + DELTA_N
        if !isempty(pawnattacks(WHITE, epsq) ∩ pawns(b, BLACK))
            b.epsq = epsq.val
            b.key ⊻= zobep(epsq)
        end
    elseif t - f == 2 * DELTA_S
        epsq = f + DELTA_S
        if !isempty(pawnattacks(BLACK, epsq) ∩ pawns(b, WHITE))
            b.epsq = epsq.val
            b.key ⊻= zobep(epsq)
        end
    end
end


function updatecastlerights!(b::Board, f::Square, t::Square)
    CASTLE_RIGHTS = SVector(
        ~UInt8(8), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(2),
        ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0),
        ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0),
        ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0),
        ~UInt8(12), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(3),
        ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0),
        ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0),
        ~UInt8(4), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(0), ~UInt8(1),
    )
    crights = b.castlerights
    b.castlerights &= CASTLE_RIGHTS[f.val]
    b.castlerights &= CASTLE_RIGHTS[t.val]
    b.key ⊻= zobcastle(crights)
    b.key ⊻= zobcastle(b.castlerights)
end



function findcheckers(b::Board)::SquareSet
    us = sidetomove(b)
    them = coloropp(us)
    ksq = kingsquare(b, us)

    (pawnattacks(us, ksq) ∩ pawns(b, them)) ∪
        (knightattacks(ksq) ∩ knights(b, them)) ∪
        (bishopattacks(b, ksq) ∩ bishoplike(b, them)) ∪
        (rookattacks(b, ksq) ∩ rooklike(b, them))
end


function findpinned(b::Board)::SquareSet
    us = sidetomove(b)
    them = coloropp(us)
    ksq = kingsquare(b, us)
    occ = occupiedsquares(b)
    ourpieces = pieces(b, us)
    sliders = (bishopattacksempty(ksq) ∩ bishoplike(b, them)) ∪
        (rookattacksempty(ksq) ∩ rooklike(b, them))
    pinned = SS_EMPTY

    for s in sliders
        blockers = squaresbetween(s, ksq) ∩ occ
        if issingleton(blockers) && !isempty(blockers ∩ ourpieces)
            pinned = pinned ∪ blockers
        end
    end
    pinned
end


"""
    domove(b::Board, m::Move)
    domove(b::Board, m::String)

Do the move `m` on the board `b`, and return the new board.

The board `b` itself is left unchanged, a new board is returned. There is a
much faster destructive function `domove!()` that should be called instead when
high performance is required.

If the supplied move is a string, this function tries to parse the move as a
UCI move first, then as a SAN move.

It's the caller's responsibility to make sure `m` is a legal move on this board.

# Examples

```julia-repl
julia> b = startboard();

julia> domove(b, "Nf3")
Board (rnbqkbnr/pppppppp/8/8/8/5N2/PPPPPPPP/RNBQKB1R b KQkq -):
 r  n  b  q  k  b  n  r
 p  p  p  p  p  p  p  p
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  N  -  -
 P  P  P  P  P  P  P  P
 R  N  B  Q  K  B  -  R
```
"""
function domove(b::Board, m::Move)::Board
    result = deepcopy(b)
    f = from(m)
    t = to(m)
    capture = pieceon(b, t)
    us = sidetomove(b)
    pt = ptype(pieceon(b, f))

    result.side = coloropp(us).val
    result.r50 += 1
    result.epsq = SQ_NONE.val
    result.move = m.val
    result.key ⊻= zobsidetomove()
    if epsquare(b) ≠ SQ_NONE
        result.key ⊻= zobep(epsquare(b))
    end

    if capture ≠ EMPTY
        removepiece!(result, t)
        result.r50 = 0
    end
    if ispromotion(m)
        removepiece!(result, f)
        putpiece!(result, Piece(us, promotion(m)), t)
        result.r50 = 0
    elseif pt == PAWN && t == epsquare(b)
        movepiece!(result, f, t)
        removepiece!(result, Square(file(t), rank(f)))
        result.r50 = 0
    elseif pt == KING && distance(f, t) > 1 # Castle
        movepiece!(result, f, t)
        if file(t) == FILE_C
            rfrom = Square(FILE_A, rank(f))
            movepiece!(result, rfrom, rfrom + 3 * DELTA_E)
        else
            rfrom = Square(FILE_H, rank(f))
            movepiece!(result, rfrom, rfrom + 2 * DELTA_W)
        end
    else
        movepiece!(result, f, t)
        if pt == PAWN
            result.r50 = 0
            setep!(result, f, t)
        end
    end

    updatecastlerights!(result, f, t)
    result.checkers = findcheckers(result)
    result.pin = findpinned(result)

    result
end

function domove(b::Board, m::String)::Board
    mv = movefromstring(m)
    if mv == nothing
        mv = movefromsan(b, m)
    end
    if mv == nothing
        throw("Illegal or ambiguous move: $m")
    end
    domove(b, mv)
end


struct UndoInfo
    castlerights::UInt8
    epsq::UInt8
    r50::UInt8
    move::UInt16
    checkers::SquareSet
    pin::SquareSet
    capture::Piece
    key::UInt64
end


Base.show(io::IO, _::UndoInfo) = print(io, "UndoInfo(...)")


"""
    domove!(b::Board, m::Move)
    domove!(b::Board, m::String)

Destructively modify the board `b` by making the move `m`.

If the supplied move is a string, this function tries to parse the move as a
UCI move first, then as a SAN move.

It's the caller's responsibility to make sure the move `m` is legal.

The function returns a value of type `UndoInfo`. You'll need this if you want
to later call `undomove!()` to take back the move and get the original position
back.

# Examples

```julia-repl
julia> b = startboard();

julia> domove!(b, "d4");

julia> b
Board (rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq -):
 r  n  b  q  k  b  n  r
 p  p  p  p  p  p  p  p
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  P  -  -  -  -
 -  -  -  -  -  -  -  -
 P  P  P  -  P  P  P  P
 R  N  B  Q  K  B  N  R
```
"""
function domove!(b::Board, m::Move)::UndoInfo
    f = from(m)
    if pieceon(b, f) == EMPTY
        pprint(b)
        println(tostring(m))
    end
    t = to(m)
    capture = pieceon(b, t)
    us = sidetomove(b)
    pt = ptype(pieceon(b, f))
    ep = epsquare(b)

    result = UndoInfo(b.castlerights, b.epsq, b.r50, b.move, b.checkers, b.pin, capture, b.key)

    b.side = coloropp(us).val
    b.r50 += 1
    b.epsq = SQ_NONE.val
    b.move = m.val
    b.key ⊻= zobsidetomove()
    if ep ≠ SQ_NONE
        b.key ⊻= zobep(ep)
    end

    if capture ≠ EMPTY
        removepiece!(b, t)
        b.r50 = 0
    end
    if ispromotion(m)
        removepiece!(b, f)
        putpiece!(b, Piece(us, promotion(m)), t)
        b.r50 = 0
    elseif pt == PAWN && t == ep
        movepiece!(b, f, t)
        removepiece!(b, Square(file(t), rank(f)))
        b.r50 = 0
    elseif pt == KING && distance(f, t) > 1 # Castle
        movepiece!(b, f, t)
        if file(t) == FILE_C
            rfrom = Square(FILE_A, rank(f))
            movepiece!(b, rfrom, rfrom + 3 * DELTA_E)
        else
            rfrom = Square(FILE_H, rank(f))
            movepiece!(b, rfrom, rfrom + 2 * DELTA_W)
        end
    else
        movepiece!(b, f, t)
        if pt == PAWN
            b.r50 = 0
            setep!(b, f, t)
        end
    end

    updatecastlerights!(b, f, t)
    b.checkers = findcheckers(b)
    b.pin = findpinned(b)

    result
end

function domove!(b::Board, m::String)::UndoInfo
    mv = movefromstring(m)
    if mv == nothing
        mv = movefromsan(b, m)
    end
    if mv == nothing
        throw("Illegal or ambiguous move: $m")
    end
    domove!(b, mv)
end


"""
    undomove!(b::Board, u::UndoInfo)

Undo a move earlier done by `domove!()`.

The second parameter is the `UndoInfo` value returned by the earlier call to
`domove!()`.

# Examples
```julia-repl
julia> b = startboard();

julia> u = domove!(b, "c4");

julia> b
Board (rnbqkbnr/pppppppp/8/8/2P5/8/PP1PPPPP/RNBQKBNR b KQkq -):
 r  n  b  q  k  b  n  r
 p  p  p  p  p  p  p  p
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  P  -  -  -  -  -
 -  -  -  -  -  -  -  -
 P  P  -  P  P  P  P  P
 R  N  B  Q  K  B  N  R

julia> undomove!(b, u);

julia> b
Board (rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -):
 r  n  b  q  k  b  n  r
 p  p  p  p  p  p  p  p
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 P  P  P  P  P  P  P  P
 R  N  B  Q  K  B  N  R
```
"""
function undomove!(b::Board, u::UndoInfo)
    m = lastmove(b)
    f = from(m)
    t = to(m)
    capture = u.capture
    them = sidetomove(b)
    us = coloropp(them)
    pt = ispromotion(m) ? PAWN : ptype(pieceon(b, t))
    ep = Square(u.epsq)

    b.castlerights = u.castlerights
    b.epsq = u.epsq
    b.r50 = u.r50
    b.move = u.move
    b.checkers = u.checkers
    b.pin = u.pin
    b.side = us.val

    if ispromotion(m)
        removepiece!(b, t)
        putpiece!(b, Piece(us, PAWN), f)
        if capture ≠ EMPTY
            putpiece!(b, capture, t)
        end
    elseif pt == PAWN && t == ep
        movepiece!(b, t, f)
        putpiece!(b, Piece(them, PAWN), Square(file(t), rank(f)))
    elseif pt == KING && distance(f, t) > 1 # Castle
        movepiece!(b, t, f)
        if file(t) == FILE_C
            rfrom = Square(FILE_A, rank(f))
            movepiece!(b, rfrom + 3 * DELTA_E, rfrom)
        else
            rfrom = Square(FILE_H, rank(f))
            movepiece!(b, rfrom + 2 * DELTA_W, rfrom)
        end
    else
        movepiece!(b, t, f)
        if capture ≠ EMPTY
            putpiece!(b, capture, t)
        end
    end
    b.key = u.key
end


"""
    domoves!(b::Board, moves::Vararg{Move})
    domoves!(b::Board, moves::Vararg{String})

Destructively modify the board b by making a sequence of moves.

If the supplied moves are strings, this function tries to parse the moves
as UCI moves first, and as SAN moves if UCI move parsing fails.

It's the caller's responsibility to make sure all moves are legal. If a
plain move is illegal, the consequences are undefined. If a move string cannot
be parsed as an unambiguous legal move, the function throws an exception.

There is also a non-destructive version of this version, named `domoves`.

# Examples
```julia-repl
julia> b = startboard();

julia> domoves!(b, "e4", "c5", "Nf3", "d6", "d4", "cxd4", "Nxd4", "Nf6", "Nc3");

julia> b
Board (rnbqkb1r/pp2pppp/3p1n2/8/3NP3/2N5/PPP2PPP/R1BQKB1R b KQkq -):
 r  n  b  q  k  b  -  r
 p  p  -  -  p  p  p  p
 -  -  -  p  -  n  -  -
 -  -  -  -  -  -  -  -
 -  -  -  N  P  -  -  -
 -  -  N  -  -  -  -  -
 P  P  P  -  -  P  P  P
 R  -  B  Q  K  B  -  R

julia> b = startboard();

julia> domoves!(b, "e4", "Qxe4+")
ERROR: "Illegal or ambiguous move: Qxe4+"
```
"""
function domoves!(b::Board, moves::Vararg{Move})::Board
    for m in moves
        domove!(b, m)
    end
    b
end,

function domoves!(b::Board, moves::Vararg{String})::Board
    for m in moves
        mv = movefromstring(m)
        if mv == nothing
            mv = movefromsan(b, m)
        end
        if mv == nothing
            throw("Illegal or ambiguous move: $m")
        end
        domove!(b, mv)
    end
    b
end


"""
    domoves(b::Board, moves::Vararg{Move})
    domoves(b::Board, moves::Vararg{String})

Return the board achieved from a starting board `b` by making a sequence of
moves.

The input board `b` is left unchanged.

If the supplied moves are strings, this function tries to parse the moves
as UCI moves first, and as SAN moves if UCI move parsing fails.

It's the caller's responsibility to make sure all moves are legal. If a
plain move is illegal, the consequences are undefined. If a move string cannot
be parsed as an unambiguous legal move, the function throws an exception.

There is also a destructive version of this version, named `domoves!`

# Examples
```julia-repl
julia> b = startboard();

julia> domoves(b, "d4", "Nf6", "c4", "e6", "Nc3", "Bb4")
Board (rnbqk2r/pppp1ppp/4pn2/8/1bPP4/2N5/PP2PPPP/R1BQKBNR w KQkq -):
 r  n  b  q  k  -  -  r
 p  p  p  p  -  p  p  p
 -  -  -  -  p  n  -  -
 -  -  -  -  -  -  -  -
 -  b  P  P  -  -  -  -
 -  -  N  -  -  -  -  -
 P  P  -  -  P  P  P  P
 R  -  B  Q  K  B  N  R

julia> domoves(b, "d4", "Nf6", "c5")
ERROR: "Illegal or ambiguous move: c5"
```
"""
function domoves(b::Board, moves::Vararg{Move})::Board
    b = deepcopy(b)
    domoves!(b, moves...)
    b
end

function domoves(b::Board, moves::Vararg{String})::Board
    b = deepcopy(b)
    domoves!(b, moves...)
end


"""
    MoveList

An iterable type containing a a list of moves, as produced by legal move
generators.
"""
mutable struct MoveList <: AbstractArray{Move, 1}
    moves::Array{Move, 1}
    count::Int
end


function Base.iterate(list::MoveList, state = 1)
    if state > list.count
        nothing
    else
        (list.moves[state], state + 1)
    end
end


function Base.length(list::MoveList)
    list.count
end


function Base.eltype(::Type{MoveList})
    Move
end


function Base.size(list::MoveList)
    (list.count,)
end


function Base.IndexStyle(::Type{<:MoveList})
    IndexLinear()
end


function Base.getindex(list::MoveList, i::Int)
    list.moves[i]
end


function MoveList(capacity::Int)
    MoveList(Array{Move}(undef, capacity), 0)
end


"""
    push!(list::MoveList, m::Move)

Add a new move to the move list.
"""
function push!(list::MoveList, m::Move)
    list.count += 1
    list.moves[list.count] = m
end


"""
    recycle!(list::MoveList)

Recycle the move list in order to re-use for generating new moves.

This is useful when you want to avoid allocating too much heap memory. If you
have a `MoveList` lying around that you no longer need, consider reusing it
instead of creating a new one the next time you need to generate some moves.
"""
function recycle!(list::MoveList)
    list.count = 0
end


function genpawnpushes(b::Board, list::MoveList)
    us = sidetomove(b)
    source = pawns(b, us) ∩ (-pinned(b) ∪ filesquares(file(kingsquare(b, us))))
    if us == WHITE
        target = pawnshift_n(source) ∩ emptysquares(b)
        push = DELTA_N
        for s in target ∩ SS_RANK_8
            push!(list, Move(s - push, s, QUEEN))
            push!(list, Move(s - push, s, ROOK))
            push!(list, Move(s - push, s, BISHOP))
            push!(list, Move(s - push, s, KNIGHT))
        end
        for s in target - SS_RANK_8
            push!(list, Move(s - push, s))
        end
        target = pawnshift_n(target) ∩ emptysquares(b) ∩ SS_RANK_4
        for s in target
            push!(list, Move(s - 2 * push, s))
        end
    else
        target = pawnshift_s(source) ∩ emptysquares(b)
        push = DELTA_S
        for s in target ∩ SS_RANK_1
            push!(list, Move(s - push, s, QUEEN))
            push!(list, Move(s - push, s, ROOK))
            push!(list, Move(s - push, s, BISHOP))
            push!(list, Move(s - push, s, KNIGHT))
        end
        for s in target - SS_RANK_1
            push!(list, Move(s - push, s))
        end
        target = pawnshift_s(target) ∩ emptysquares(b) ∩ SS_RANK_5
        for s in target
            push!(list, Move(s - 2 * push, s))
        end
    end
end


function countpawnpushes(b::Board)::Int
    us = sidetomove(b)
    source = pawns(b, us) ∩ (-pinned(b) ∪ filesquares(file(kingsquare(b, us))))
    if us == WHITE
        target = pawnshift_n(source) ∩ emptysquares(b)
        4 * squarecount(target ∩ SS_RANK_8) + squarecount(target - SS_RANK_8) +
            squarecount(pawnshift_n(target) ∩ emptysquares(b) ∩ SS_RANK_4)
    else
        target = pawnshift_s(source) ∩ emptysquares(b)
        4 * squarecount(target ∩ SS_RANK_1) + squarecount(target - SS_RANK_1) +
            squarecount(pawnshift_s(target) ∩ emptysquares(b) ∩ SS_RANK_5)
    end
end


function haspawnpushes(b::Board)::Bool
    us = sidetomove(b)
    source = pawns(b, us) ∩ (-pinned(b) ∪ filesquares(file(kingsquare(b, us))))
    if us == WHITE
        !isempty(pawnshift_n(source) ∩ emptysquares(b))
    else
        !isempty(pawnshift_s(source) ∩ emptysquares(b))
    end
end


function genpawncaptures(b::Board, list::MoveList)
    us = sidetomove(b)
    them = coloropp(us)
    source = pawns(b, us) - pinned(b)
    target = pieces(b, them)
    if us == WHITE
        target2 = pawnshift_nw(source) ∩ target
        delta = DELTA_NW
        for s in target2 ∩ SS_RANK_8
            push!(list, Move(s - delta, s, QUEEN))
            push!(list, Move(s - delta, s, ROOK))
            push!(list, Move(s - delta, s, BISHOP))
            push!(list, Move(s - delta, s, KNIGHT))
        end
        for s in target2 - SS_RANK_8
            push!(list, Move(s - delta, s))
        end
        target2 = pawnshift_ne(source) ∩ target
        delta = DELTA_NE
        for s in target2 ∩ SS_RANK_8
            push!(list, Move(s - delta, s, QUEEN))
            push!(list, Move(s - delta, s, ROOK))
            push!(list, Move(s - delta, s, BISHOP))
            push!(list, Move(s - delta, s, KNIGHT))
        end
        for s in target2 - SS_RANK_8
            push!(list, Move(s - delta, s))
        end
    else
        target2 = pawnshift_sw(source) ∩ target
        delta = DELTA_SW
        for s in target2 ∩ SS_RANK_1
            push!(list, Move(s - delta, s, QUEEN))
            push!(list, Move(s - delta, s, ROOK))
            push!(list, Move(s - delta, s, BISHOP))
            push!(list, Move(s - delta, s, KNIGHT))
        end
        for s in target2 - SS_RANK_1
            push!(list, Move(s - delta, s))
        end
        target2 = pawnshift_se(source) ∩ target
        delta = DELTA_SE
        for s in target2 ∩ SS_RANK_1
            push!(list, Move(s - delta, s, QUEEN))
            push!(list, Move(s - delta, s, ROOK))
            push!(list, Move(s - delta, s, BISHOP))
            push!(list, Move(s - delta, s, KNIGHT))
        end
        for s in target2 - SS_RANK_1
            push!(list, Move(s - delta, s))
        end
    end

    source = pawns(b, us) ∩ pinned(b)
    ksq = kingsquare(b, us)
    for s1 in source
        for s2 in pawnattacks(us, s1) ∩ target
            if s1 ∈ squaresbetween(ksq, s2)
                if s2 ∈ (SS_RANK_1 ∪ SS_RANK_8)
                    push!(list, Move(s1, s2, QUEEN))
                    push!(list, Move(s1, s2, ROOK))
                    push!(list, Move(s1, s2, BISHOP))
                    push!(list, Move(s1, s2, KNIGHT))
                else
                    push!(list, Move(s1, s2))
                end
            end
        end
    end
end


function countpawncaptures(b::Board)::Int
    result = 0
    us = sidetomove(b)
    them = coloropp(us)
    source = pawns(b, us) - pinned(b)
    target = pieces(b, them)
    if us == WHITE
        target2 = pawnshift_nw(source) ∩ target
        result += 4 * squarecount(target2 ∩ SS_RANK_8)
        result += squarecount(target2 - SS_RANK_8)
        target2 = pawnshift_ne(source) ∩ target
        result += 4 * squarecount(target2 ∩ SS_RANK_8)
        result += squarecount(target2 - SS_RANK_8)
    else
        target2 = pawnshift_sw(source) ∩ target
        result += 4 * squarecount(target2 ∩ SS_RANK_1)
        result += squarecount(target2 - SS_RANK_1)
        target2 = pawnshift_se(source) ∩ target
        result += 4 * squarecount(target2 ∩ SS_RANK_1)
        result += squarecount(target2 - SS_RANK_1)
    end

    source = pawns(b, us) ∩ pinned(b)
    ksq = kingsquare(b, us)
    for s1 in source
        for s2 in pawnattacks(us, s1) ∩ target
            if s1 ∈ squaresbetween(ksq, s2)
                result += s2 ∈ (SS_RANK_1 ∪ SS_RANK_8) ? 4 : 1
            end
        end
    end
    result
end


function haspawncaptures(b::Board)::Bool
    us = sidetomove(b)
    them = coloropp(us)
    source = pawns(b, us) - pinned(b)
    target = pieces(b, them)
    if us == WHITE
        if !isempty(pawnshift_nw(source) ∩ target) ||
            !isempty(pawnshift_ne(source) ∩ target)
            return true
        end
    else
        if !isempty(pawnshift_sw(source) ∩ target) ||
            !isempty(pawnshift_se(source) ∩ target)
            return true
        end
    end
    source = pawns(b, us) ∩ pinned(b)
    ksq = kingsquare(b, us)
    for s1 in source
        for s2 in pawnattacks(us, s1) ∩ target
            if s1 ∈ squaresbetween(ksq, s2)
                return true
            end
        end
    end
    false
end


function genpawnevasions(b::Board, chsq::Square, block::SquareSet, list::MoveList)
    us = sidetomove(b)
    them = coloropp(us)
    ps = pawns(b, us) - pinned(b)

    if us == WHITE
        # Capture checking piece
        for s in pawnattacks(them, chsq) ∩ ps
            if rank(s) == RANK_7
                push!(list, Move(s, chsq, QUEEN))
                push!(list, Move(s, chsq, ROOK))
                push!(list, Move(s, chsq, BISHOP))
                push!(list, Move(s, chsq, KNIGHT))
            else
                push!(list, Move(s, chsq))
            end
        end

        # Block check from sliding piece
        target = shift_n(ps) ∩ emptysquares(b)
        delta = DELTA_N
        for s in target ∩ block ∩ SS_RANK_8
            push!(list, Move(s - delta, s, QUEEN))
            push!(list, Move(s - delta, s, ROOK))
            push!(list, Move(s - delta, s, BISHOP))
            push!(list, Move(s - delta, s, KNIGHT))
        end
        for s in (target ∩ block) - SS_RANK_8
            push!(list, Move(s - delta, s))
        end
        for s in shift_n(target ∩ SS_RANK_3) ∩ emptysquares(b) ∩ block
            push!(list, Move(s - 2 * delta, s))
        end
    else
        # Capture checking piece
        for s in pawnattacks(them, chsq) ∩ ps
            if rank(s) == RANK_2
                push!(list, Move(s, chsq, QUEEN))
                push!(list, Move(s, chsq, ROOK))
                push!(list, Move(s, chsq, BISHOP))
                push!(list, Move(s, chsq, KNIGHT))
            else
                push!(list, Move(s, chsq))
            end
        end

        # Block check from sliding piece
        target = shift_s(ps) ∩ emptysquares(b)
        delta = DELTA_S
        for s in target ∩ block ∩ SS_RANK_1
            push!(list, Move(s - delta, s, QUEEN))
            push!(list, Move(s - delta, s, ROOK))
            push!(list, Move(s - delta, s, BISHOP))
            push!(list, Move(s - delta, s, KNIGHT))
        end
        for s in (target ∩ block) - SS_RANK_1
            push!(list, Move(s - delta, s))
        end
        for s in shift_s(target ∩ SS_RANK_6) ∩ emptysquares(b) ∩ block
            push!(list, Move(s - 2 * delta, s))
        end
    end
end


function countpawnevasions(b::Board, chsq::Square, block::SquareSet)::Int
    result = 0
    us = sidetomove(b)
    them = coloropp(us)
    ps = pawns(b, us) - pinned(b)

    if us == WHITE
        # Capture checking piece
        for s in pawnattacks(them, chsq) ∩ ps
            result += rank(s) == RANK_7 ? 4 : 1
        end

        # Block check from sliding piece
        target = shift_n(ps) ∩ emptysquares(b)
        result += 4 * squarecount(target ∩ block ∩ SS_RANK_8)
        result += squarecount((target ∩ block) - SS_RANK_8)
        result += squarecount(shift_n(target ∩ SS_RANK_3) ∩ emptysquares(b) ∩ block)
    else
        # Capture checking piece
        for s in pawnattacks(them, chsq) ∩ ps
            result += rank(s) == RANK_2 ? 4 : 1
        end

        # Block check from sliding piece
        target = shift_s(ps) ∩ emptysquares(b)
        result += 4 * squarecount(target ∩ block ∩ SS_RANK_1)
        result += squarecount((target ∩ block) - SS_RANK_1)
        result += squarecount(shift_s(target ∩ SS_RANK_6) ∩ emptysquares(b) ∩ block)
    end
    result
end


function haspawnevasions(b::Board, chsq::Square, block::SquareSet)::Bool
    us = sidetomove(b)
    them = coloropp(us)
    ps = pawns(b, us) - pinned(b)

    if us == WHITE
        # Capture checking piece
        if !isempty(pawnattacks(them, chsq) ∩ ps)
            return true
        end

        # Block check from sliding piece
        target = shift_n(ps) ∩ emptysquares(b)
        if !isempty(target ∩ block)
            return true
        end
        target = shift_n(target ∩ SS_RANK_3) ∩ emptysquares(b)
        if !isempty(target ∩ block)
            return true
        end
    else
        # Capture checking piece
        if !isempty(pawnattacks(them, chsq) ∩ ps)
            return true
        end

        # Block check from sliding piece
        target = shift_s(ps) ∩ emptysquares(b)
        if !isempty(target ∩ block)
            return true
        end
        target = shift_s(target ∩ SS_RANK_6) ∩ emptysquares(b)
        if !isempty(target ∩ block)
            return true
        end
    end
    false
end


function genpawncaptureevasions(b::Board, chsq::Square, list::MoveList)
    us = sidetomove(b)
    them = coloropp(us)
    if rank(chsq) == RANK_1 || rank(chsq) == RANK_8
        for s in pawnattacks(them, chsq) ∩ pawns(b, us) ∩ -pinned(b)
            push!(list, Move(s, chsq, QUEEN))
            push!(list, Move(s, chsq, ROOK))
            push!(list, Move(s, chsq, BISHOP))
            push!(list, Move(s, chsq, KNIGHT))
        end
    else
        for s in pawnattacks(them, chsq) ∩ pawns(b, us) ∩ -pinned(b)
            push!(list, Move(s, chsq))
        end
    end
    epsq = epsquare(b)
    delta = us == WHITE ? DELTA_N : DELTA_S
    if epsq ≠ SQ_NONE && epsq - delta == chsq
        ksq = kingsquare(b, us)
        occ = occupiedsquares(b)
        occ += epsq
        occ -= chsq
        for s in pawnattacks(them, epsq) ∩ pawns(b, us)
            occ2 = occ - s
            if isempty(bishopattacks(occ2, ksq) ∩ bishoplike(b, them)) &&
                isempty(rookattacks(occ2, ksq) ∩ rooklike(b, them))
                push!(list, Move(s, epsq))
            end
        end
    end
end


function countpawncaptureevasions(b::Board, chsq::Square)::Int
    result = 0
    us = sidetomove(b)
    them = coloropp(us)
    if rank(chsq) == RANK_1 || rank(chsq) == RANK_8
        result += 4 * squarecount(pawnattacks(them, chsq) ∩ pawns(b, us) ∩ -pinned(b))
    else
        result += squarecount(pawnattacks(them, chsq) ∩ pawns(b, us) ∩ -pinned(b))
    end
    epsq = epsquare(b)
    delta = us == WHITE ? DELTA_N : DELTA_S
    if epsq ≠ SQ_NONE && epsq - delta == chsq
        ksq = kingsquare(b, us)
        occ = occupiedsquares(b)
        occ += epsq
        occ -= chsq
        for s in pawnattacks(them, epsq) ∩ pawns(b, us)
            occ2 = occ - s
            if isempty(bishopattacks(occ2, ksq) ∩ bishoplike(b, them)) &&
                isempty(rookattacks(occ2, ksq) ∩ rooklike(b, them))
                result += 1
            end
        end
    end
    result
end


function haspawncaptureevasions(b::Board, chsq::Square)::Bool
    us = sidetomove(b)
    them = coloropp(us)
    if !isempty(pawnattacks(them, chsq) ∩ pawns(b, us) ∩ -pinned(b))
        return true
    end
    epsq = epsquare(b)
    delta = us == WHITE ? DELTA_N : DELTA_S
    if epsq ≠ SQ_NONE && epsq - delta == chsq
        ksq = kingsquare(b, us)
        occ = occupiedsquares(b)
        occ += epsq
        occ -= chsq
        for s in pawnattacks(them, epsq) ∩ pawns(b, us)
            occ2 = occ - s
            if isempty(bishopattacks(occ2, ksq) ∩ bishoplike(b, them)) &&
                isempty(rookattacks(occ2, ksq) ∩ rooklike(b, them))
                return true
            end
        end
    end
    false
end


function genknightmoves(b::Board, target::SquareSet, list::MoveList)
    us = sidetomove(b)
    for s1 in knights(b, us) - pinned(b)
        for s2 in knightattacks(s1) ∩ target
            push!(list, Move(s1, s2))
        end
    end
end


function countknightmoves(b::Board, target::SquareSet)::Int
    result = 0
    us = sidetomove(b)
    for s in knights(b, us) - pinned(b)
        result += squarecount(knightattacks(s) ∩ target)
    end
    result
end


function hasknightmoves(b::Board, target::SquareSet)::Bool
    us = sidetomove(b)
    for s in knights(b, us) - pinned(b)
        if !isempty(knightattacks(s) ∩ target)
            return true
        end
    end
    false
end


function genknightcaptureevasions(b::Board, chsq::Square, list::MoveList)
    us = sidetomove(b)
    for s in knights(b, us) ∩ -pinned(b) ∩ knightattacks(chsq)
        push!(list, Move(s, chsq))
    end
end


function countknightcaptureevasions(b::Board, chsq::Square)::Int
    squarecount(knights(b, sidetomove(b)) ∩ -pinned(b) ∩ knightattacks(chsq))
end


function hasknightcaptureevasions(b::Board, chsq::Square)::Bool
    !isempty(knights(b, sidetomove(b)) ∩ -pinned(b) ∩ knightattacks(chsq))
end


function genbishopmoves(b::Board, target::SquareSet, list::MoveList)
    us = sidetomove(b)
    for s1 in bishops(b, us) - pinned(b)
        for s2 in bishopattacks(b, s1) ∩ target
            push!(list, Move(s1, s2))
        end
    end
    for s1 in bishops(b, us) ∩ pinned(b)
        ksq = kingsquare(b, us)
        for s2 in bishopattacks(b, s1) ∩ target
            if s2 ∈ squaresbetween(ksq, s1) || s1 ∈ squaresbetween(ksq, s2)
                push!(list, Move(s1, s2))
            end
        end
    end
end


function countbishopmoves(b::Board, target::SquareSet)::Int
    result = 0
    us = sidetomove(b)
    for s in bishops(b, us) - pinned(b)
        result += squarecount(bishopattacks(b, s) ∩ target)
    end
    for s1 in bishops(b, us) ∩ pinned(b)
        ksq = kingsquare(b, us)
        for s2 in bishopattacks(b, s1) ∩ target
            if s2 ∈ squaresbetween(ksq, s1) || s1 ∈ squaresbetween(ksq, s2)
                result += 1
            end
        end
    end
    result
end


function hasbishopmoves(b::Board, target::SquareSet)::Bool
    us = sidetomove(b)
    for s in bishops(b, us) - pinned(b)
        if !isempty(bishopattacks(b, s) ∩ target)
            return true
        end
    end
    for s1 in bishops(b, us) ∩ pinned(b)
        ksq = kingsquare(b, us)
        for s2 in bishopattacks(b, s1) ∩ target
            if s2 ∈ squaresbetween(ksq, s1) || s1 ∈ squaresbetween(ksq, s2)
                return true
            end
        end
    end
    false
end


function genbishopevasions(b::Board, target::SquareSet, list::MoveList)
    us = sidetomove(b)
    for s1 in bishops(b, us) - pinned(b)
        for s2 in bishopattacks(b, s1) ∩ target
            push!(list, Move(s1, s2))
        end
    end
end


function countbishopevasions(b::Board, target::SquareSet)::Int
    result = 0
    us = sidetomove(b)
    for s in bishops(b, us) - pinned(b)
        result += squarecount(bishopattacks(b, s) ∩ target)
    end
    result
end


function hasbishopevasions(b::Board, target::SquareSet)::Bool
    us = sidetomove(b)
    for s in bishops(b, us) - pinned(b)
        if !isempty(bishopattacks(b, s) ∩ target)
            return true
        end
    end
    false
end


function genbishoplikecaptureevasions(b::Board, chsq::Square, list::MoveList)
    us = sidetomove(b)
    for s in bishoplike(b, us) ∩ -pinned(b) ∩ bishopattacks(b, chsq)
        push!(list, Move(s, chsq))
    end
end


function countbishoplikecaptureevasions(b::Board, chsq::Square)::Int
    squarecount(bishoplike(b, sidetomove(b)) ∩ -pinned(b) ∩ bishopattacks(b, chsq))
end


function hasbishoplikecaptureevasions(b::Board, chsq::Square)::Bool
    !isempty(bishoplike(b, sidetomove(b)) ∩ -pinned(b) ∩ bishopattacks(b, chsq))
end


function genrookmoves(b::Board, target::SquareSet, list::MoveList)
    us = sidetomove(b)
    for s1 in rooks(b, us) - pinned(b)
        for s2 in rookattacks(b, s1) ∩ target
            push!(list, Move(s1, s2))
        end
    end
    for s1 in rooks(b, us) ∩ pinned(b)
        ksq = kingsquare(b, us)
        for s2 in rookattacks(b, s1) ∩ target
            if s2 ∈ squaresbetween(ksq, s1) || s1 ∈ squaresbetween(ksq, s2)
                push!(list, Move(s1, s2))
            end
        end
    end
end


function countrookmoves(b::Board, target::SquareSet)::Int
    result = 0
    us = sidetomove(b)
    for s in rooks(b, us) - pinned(b)
        result += squarecount(rookattacks(b, s) ∩ target)
    end
    for s1 in rooks(b, us) ∩ pinned(b)
        ksq = kingsquare(b, us)
        for s2 in rookattacks(b, s1) ∩ target
            if s2 ∈ squaresbetween(ksq, s1) || s1 ∈ squaresbetween(ksq, s2)
                result += 1
            end
        end
    end
    result
end


function hasrookmoves(b::Board, target::SquareSet)::Bool
    us = sidetomove(b)
    for s in rooks(b, us) - pinned(b)
        if !isempty(rookattacks(b, s) ∩ target)
            return true
        end
    end
    for s1 in rooks(b, us) ∩ pinned(b)
        ksq = kingsquare(b, us)
        for s2 in rookattacks(b, s1) ∩ target
            if s2 ∈ squaresbetween(ksq, s1) || s1 ∈ squaresbetween(ksq, s2)
                return true
            end
        end
    end
    false
end


function genrookevasions(b::Board, target::SquareSet, list::MoveList)
    us = sidetomove(b)
    for s1 in rooks(b, us) - pinned(b)
        for s2 in rookattacks(b, s1) ∩ target
            push!(list, Move(s1, s2))
        end
    end
end


function countrookevasions(b::Board, target::SquareSet)::Int
    result = 0
    us = sidetomove(b)
    for s in rooks(b, us) - pinned(b)
        result += squarecount(rookattacks(b, s) ∩ target)
    end
    result
end


function hasrookevasions(b::Board, target::SquareSet)::Bool
    us = sidetomove(b)
    for s in rooks(b, us) - pinned(b)
        if !isempty(rookattacks(b, s) ∩ target)
            return true
        end
    end
    false
end


function genrooklikecaptureevasions(b::Board, chsq::Square, list::MoveList)
    us = sidetomove(b)
    for s in rooklike(b, us) ∩ -pinned(b) ∩ rookattacks(b, chsq)
        push!(list, Move(s, chsq))
    end
end


function countrooklikecaptureevasions(b::Board, chsq::Square)::Int
    squarecount(rooklike(b, sidetomove(b)) ∩ -pinned(b) ∩ rookattacks(b, chsq))
end


function hasrooklikecaptureevasions(b::Board, chsq::Square)::Bool
    !isempty(rooklike(b, sidetomove(b)) ∩ -pinned(b) ∩ rookattacks(b, chsq))
end


function genqueenmoves(b::Board, target::SquareSet, list::MoveList)
    us = sidetomove(b)
    for s1 in queens(b, us) - pinned(b)
        for s2 in queenattacks(b, s1) ∩ target
            push!(list, Move(s1, s2))
        end
    end
    for s1 in queens(b, us) ∩ pinned(b)
        ksq = kingsquare(b, us)
        for s2 in queenattacks(b, s1) ∩ target
            if s2 ∈ squaresbetween(ksq, s1) || s1 ∈ squaresbetween(ksq, s2)
                push!(list, Move(s1, s2))
            end
        end
    end
end


function countqueenmoves(b::Board, target::SquareSet)::Int
    result = 0
    us = sidetomove(b)
    for s in queens(b, us) - pinned(b)
        result += squarecount(queenattacks(b, s) ∩ target)
    end
    for s1 in queens(b, us) ∩ pinned(b)
        ksq = kingsquare(b, us)
        for s2 in queenattacks(b, s1) ∩ target
            if s2 ∈ squaresbetween(ksq, s1) || s1 ∈ squaresbetween(ksq, s2)
                result += 1
            end
        end
    end
    result
end


function hasqueenmoves(b::Board, target::SquareSet)::Bool
    us = sidetomove(b)
    for s in queens(b, us) - pinned(b)
        if !isempty(queenattacks(b, s) ∩ target)
            return true
        end
    end
    for s1 in queens(b, us) ∩ pinned(b)
        ksq = kingsquare(b, us)
        for s2 in queenattacks(b, s1) ∩ target
            if s2 ∈ squaresbetween(ksq, s1) || s1 ∈ squaresbetween(ksq, s2)
                return true
            end
        end
    end
    false
end


function genqueenevasions(b::Board, target::SquareSet, list::MoveList)
    us = sidetomove(b)
    for s1 in queens(b, us) - pinned(b)
        for s2 in queenattacks(b, s1) ∩ target
            push!(list, Move(s1, s2))
        end
    end
end


function countqueenevasions(b::Board, target::SquareSet)::Int
    result = 0
    us = sidetomove(b)
    for s in queens(b, us) - pinned(b)
        result += squarecount(queenattacks(b, s) ∩ target)
    end
    result
end


function hasqueenevasions(b::Board, target::SquareSet)::Bool
    us = sidetomove(b)
    for s in queens(b, us) - pinned(b)
        if !isempty(queenattacks(b, s) ∩ target)
            return true
        end
    end
    false
end


function genkingmoves(b::Board, target::SquareSet, list::MoveList)
    us = sidetomove(b)
    them = coloropp(us)
    s1 = kingsquare(b, us)
    for s2 in kingattacks(s1) ∩ target
        if !isattacked(b, s2, them)
            push!(list, Move(s1, s2))
        end
    end
end


function countkingmoves(b::Board, target::SquareSet)::Int
    result = 0
    us = sidetomove(b)
    them = coloropp(us)
    s1 = kingsquare(b, us)
    for s2 in kingattacks(s1) ∩ target
        if !isattacked(b, s2, them)
            result += 1
        end
    end
    result
end


function haskingmoves(b::Board, target::SquareSet)::Bool
    us = sidetomove(b)
    them = coloropp(us)
    s1 = kingsquare(b, us)
    for s2 in kingattacks(s1) ∩ target
        if !isattacked(b, s2, them)
            return true
        end
    end
    false
end


function genkingevasions(b::Board, list::MoveList)
    us = sidetomove(b)
    them = coloropp(us)
    ksq = kingsquare(b, us)
    occ = occupiedsquares(b) - ksq
    for s in kingattacks(ksq) ∩ -pieces(b, us)
        if isempty(pawnattacks(us, s) ∩ pawns(b, them)) &&
            isempty(kingattacks(s) ∩ kings(b, them)) &&
            isempty(knightattacks(s) ∩ knights(b, them)) &&
            isempty(bishopattacks(occ, s) ∩ bishoplike(b, them)) &&
            isempty(rookattacks(occ, s) ∩ rooklike(b, them))
            push!(list, Move(ksq, s))
        end
    end
end


function countkingevasions(b::Board)::Int
    result = 0
    us = sidetomove(b)
    them = coloropp(us)
    ksq = kingsquare(b, us)
    occ = occupiedsquares(b) - ksq
    for s in kingattacks(ksq) ∩ -pieces(b, us)
        if isempty(pawnattacks(us, s) ∩ pawns(b, them)) &&
            isempty(kingattacks(s) ∩ kings(b, them)) &&
            isempty(knightattacks(s) ∩ knights(b, them)) &&
            isempty(bishopattacks(occ, s) ∩ bishoplike(b, them)) &&
            isempty(rookattacks(occ, s) ∩ rooklike(b, them))
            result += 1
        end
    end
    result
end


function haskingevasions(b::Board)::Bool
    us = sidetomove(b)
    them = coloropp(us)
    ksq = kingsquare(b, us)
    occ = occupiedsquares(b) - ksq
    for s in kingattacks(ksq) ∩ -pieces(b, us)
        if isempty(pawnattacks(us, s) ∩ pawns(b, them)) &&
            isempty(kingattacks(s) ∩ kings(b, them)) &&
            isempty(knightattacks(s) ∩ knights(b, them)) &&
            isempty(bishopattacks(occ, s) ∩ bishoplike(b, them)) &&
            isempty(rookattacks(occ, s) ∩ rooklike(b, them))
            return true
        end
    end
    false
end


function gencastles(b::Board, list::MoveList)
    us = sidetomove(b)
    them = coloropp(us)
    ksq = kingsquare(b, us)
    if cancastlequeenside(b, us)
        rsq = Square(FILE_A, rank(ksq))
        if isempty(occupiedsquares(b) ∩ squaresbetween(ksq, rsq)) &&
            !isattacked(b, ksq + DELTA_W, them) &&
            !isattacked(b, ksq + 2 * DELTA_W, them)
            push!(list, Move(ksq, ksq + 2 * DELTA_W))
        end
    end
    if cancastlekingside(b, us)
        rsq = Square(FILE_H, rank(ksq))
        if isempty(occupiedsquares(b) ∩ squaresbetween(ksq, rsq)) &&
            !isattacked(b, ksq + DELTA_E, them) &&
            !isattacked(b, ksq + 2 * DELTA_E, them)
            push!(list, Move(ksq, ksq + 2 * DELTA_E))
        end
    end
end


function countcastles(b::Board)::Int
    result = 0
    us = sidetomove(b)
    them = coloropp(us)
    ksq = kingsquare(b, us)
    if cancastlequeenside(b, us)
        rsq = Square(FILE_A, rank(ksq))
        if isempty(occupiedsquares(b) ∩ squaresbetween(ksq, rsq)) &&
            !isattacked(b, ksq + DELTA_W, them) &&
            !isattacked(b, ksq + 2 * DELTA_W, them)
            result += 1
        end
    end
    if cancastlekingside(b, us)
        rsq = Square(FILE_H, rank(ksq))
        if isempty(occupiedsquares(b) ∩ squaresbetween(ksq, rsq)) &&
            !isattacked(b, ksq + DELTA_E, them) &&
            !isattacked(b, ksq + 2 * DELTA_E, them)
            result += 1
        end
    end
    result
end


function hascastles(b::Board)::Bool
    us = sidetomove(b)
    them = coloropp(us)
    ksq = kingsquare(b, us)
    if cancastlequeenside(b, us)
        rsq = Square(FILE_A, rank(ksq))
        if isempty(occupiedsquares(b) ∩ squaresbetween(ksq, rsq)) &&
            !isattacked(b, ksq + DELTA_W, them) &&
            !isattacked(b, ksq + 2 * DELTA_W, them)
            return true
        end
    end
    if cancastlekingside(b, us)
        rsq = Square(FILE_H, rank(ksq))
        if isempty(occupiedsquares(b) ∩ squaresbetween(ksq, rsq)) &&
            !isattacked(b, ksq + DELTA_E, them) &&
            !isattacked(b, ksq + 2 * DELTA_E, them)
            return true
        end
    end
    false
end


function genep(b::Board, list::MoveList)
    epsq = epsquare(b)
    if epsq ≠ SQ_NONE
        us = sidetomove(b)
        them = coloropp(us)
        ksq = kingsquare(b, us)
        for s in pawnattacks(them, epsq) ∩ pawns(b, us)
            occ = occupiedsquares(b)
            occ -= s
            occ -= Square(file(epsq), rank(s))
            occ += epsq
            if isempty(bishopattacks(occ, ksq) ∩ bishoplike(b, them)) &&
                isempty(rookattacks(occ, ksq) ∩ rooklike(b, them))
                push!(list, Move(s, epsq))
            end
        end
    end
end


function countep(b::Board)::Int
    result = 0
    epsq = epsquare(b)
    if epsq ≠ SQ_NONE
        us = sidetomove(b)
        them = coloropp(us)
        ksq = kingsquare(b, us)
        for s in pawnattacks(them, epsq) ∩ pawns(b, us)
            occ = occupiedsquares(b)
            occ -= s
            occ -= Square(file(epsq), rank(s))
            occ += epsq
            if isempty(bishopattacks(occ, ksq) ∩ bishoplike(b, them)) &&
                isempty(rookattacks(occ, ksq) ∩ rooklike(b, them))
                result += 1
            end
        end
    end
    result
end


function hasep(b::Board)::Bool
    epsq = epsquare(b)
    if epsq ≠ SQ_NONE
        us = sidetomove(b)
        them = coloropp(us)
        ksq = kingsquare(b, us)
        for s in pawnattacks(them, epsq) ∩ pawns(b, us)
            occ = occupiedsquares(b)
            occ -= s
            occ -= Square(file(epsq), rank(s))
            occ += epsq
            if isempty(bishopattacks(occ, ksq) ∩ bishoplike(b, them)) &&
                isempty(rookattacks(occ, ksq) ∩ rooklike(b, them))
                return true
            end
        end
    end
    false
end


function genmoves(b::Board, list::MoveList)::MoveList
    us = sidetomove(b)
    target = -pieces(b, us)
    genpawnpushes(b, list)
    genpawncaptures(b, list)
    genknightmoves(b, target, list)
    genbishopmoves(b, target, list)
    genrookmoves(b, target, list)
    genqueenmoves(b, target, list)
    genkingmoves(b, target, list)
    gencastles(b, list)
    genep(b, list)
    list
end


function genmoves(b::Board)
    genmoves(b, MoveList(200))
end


function countmoves(b::Board)::Int
    us = sidetomove(b)
    target = -pieces(b, us)
    countpawnpushes(b) + countpawncaptures(b) + countknightmoves(b, target) +
        countbishopmoves(b, target) + countrookmoves(b, target) +
        countqueenmoves(b, target) + countkingmoves(b, target) +
        countcastles(b) + countep(b)
end


function genevasions(b::Board, list::MoveList)::MoveList
    genkingevasions(b, list)
    if issingleton(b.checkers)
        chsq = first(b.checkers)
        if isslider(pieceon(b, chsq))
            ksq = kingsquare(b, sidetomove(b))
            blocksqs = squaresbetween(ksq, chsq)
            target = b.checkers ∪ blocksqs
            genpawnevasions(b, chsq, blocksqs, list)
            genknightmoves(b, target, list)
            genbishopevasions(b, target, list)
            genrookevasions(b, target, list)
            genqueenevasions(b, target, list)
        else
            genpawncaptureevasions(b, chsq, list)
            genknightcaptureevasions(b, chsq, list)
            genbishoplikecaptureevasions(b, chsq, list)
            genrooklikecaptureevasions(b, chsq, list)
        end
    end
    list
end


function countevasions(b::Board)::Int
    if !issingleton(b.checkers)
        return countkingevasions(b)
    else
        chsq = first(b.checkers)
        if isslider(pieceon(b, chsq))
            ksq = kingsquare(b, sidetomove(b))
            blocksqs = squaresbetween(ksq, chsq)
            target = b.checkers ∪ blocksqs
            return countkingevasions(b) +
                countpawnevasions(b, chsq, blocksqs) +
                countknightmoves(b, target) +
                countbishopevasions(b, target) +
                countrookevasions(b, target) +
                countqueenevasions(b, target)
        else
            return countkingevasions(b) +
                countpawncaptureevasions(b, chsq) +
                countknightcaptureevasions(b, chsq) +
                countbishoplikecaptureevasions(b, chsq) +
                countrooklikecaptureevasions(b, chsq)
        end
    end
end


function hasevasions(b::Board)::Bool
    if !issingleton(b.checkers)
        return haskingevasions(b)
    else
        chsq = first(b.checkers)
        if isslider(pieceon(b, chsq))
            ksq = kingsquare(b, sidetomove(b))
            blocksqs = squaresbetween(ksq, chsq)
            target = b.checkers ∪ blocksqs
            return haskingevasions(b) ||
                haspawnevasions(b, chsq, blocksqs) ||
                hasknightmoves(b, target) ||
                hasbishopevasions(b, target) ||
                hasrookevasions(b, target) ||
                hasqueenevasions(b, target)
        else
            return haskingevasions(b) ||
                haspawncaptureevasions(b, chsq) ||
                hasknightcaptureevasions(b, chsq) ||
                hasbishoplikecaptureevasions(b, chsq) ||
                hasrooklikecaptureevasions(b, chsq)
        end
    end
    false
end


"""
    moves(b::Board, list::MoveList)
    moves(b::Board)

Obtain a list of all legal moves from this board.

When performance is important, consider using the two-argument method that
supplies a pre-allocated move list.
"""
function moves(b::Board, list::MoveList)::MoveList
    if ischeck(b)
        genevasions(b, list)
    else
        genmoves(b, list)
    end
end

function moves(b::Board)::MoveList
    moves(b, MoveList(200))
end


"""
    movecount(b::Board)::Int

The number of legal moves from this board.
"""
function movecount(b::Board)::Int
    ischeck(b) ? countevasions(b) : countmoves(b)
end


"""
    haslegalmoves(b::Board)::Bool

Returns `true` if the side to move has at least one legal move.
"""
function haslegalmoves(b::Board)::Bool
    if ischeck(b)
        hasevasions(b)
    else
        us = sidetomove(b)
        target = -pieces(b, us)
        haspawnpushes(b) || haspawncaptures(b) || hasknightmoves(b, target) ||
            hasbishopmoves(b, target) || hasrookmoves(b, target) ||
            hasqueenmoves(b, target) || haskingmoves(b, target) ||
            hascastles(b) || hasep(b)
    end
end


"""
    ischeckmate(b::Board)::Bool

Returns `true` if the side to move is checkmated.
"""
function ischeckmate(b::Board)::Bool
    ischeck(b) && !haslegalmoves(b)
end


"""
    isstalemate(b::Board)::Bool

Returns `true` if the board is a stalemate position.
"""
function isstalemate(b::Board)::Bool
    !ischeck(b) && !haslegalmoves(b)
end


"""
    ismaterialdraw(b::Board)::Bool

Returns `true` if the position is a draw by material.
"""
function ismaterialdraw(b::Board)::Bool
    isempty(pawns(b)) && isempty(rooks(b)) && isempty(queens(b)) &&
        squarecount(knights(b) ∪ bishops(b)) ≤ 1
end


"""
    isrule50draw(b::Board)::Bool

Returns `true` if the position is drawn by the 50 moves rule.
"""
function isrule50draw(b::Board)::Bool
    b.r50 ≥ 100
end


"""
    isdraw(b::Board)::Bool

Returns `true` if the position is an immediate draw.
"""
function isdraw(b::Board)::Bool
    isrule50draw(b) || ismaterialdraw(b) || isstalemate(b)
end


"""
    isterminal(b::Board)::Bool

Returns `true` if the game position is terminal, i.e. mate or immediate draw.
"""
function isterminal(b::Board)::Bool
    ischeckmate(b) || isdraw(b)
end


function perftinternal(b::Board, depth::Int, ply::Int, lists)::Int
    if depth == 1
        movecount(b)
    else
        movelist = lists[ply + 1]
        moves(b, movelist)
        result = 0
        for m in moves(b)
            u = domove!(b, m)
            result += perftinternal(b, depth - 1, ply + 1, lists)
            undomove!(b, u)
        end
        recycle!(movelist)
        result
    end
end


"""
    perft(b::Board, depth::Int)

Do a `perft` search to the given depth.

See https://www.chessprogramming.org/Perft.
"""
function perft(b::Board, depth::Int)::Int
    if depth == 0
        1
    else
        lists = [MoveList(200) for _ in 1:depth]
        perftinternal(b, depth, 0, lists)
    end
end


"""
    divide(b::Board, depth::Int)

Do a `divide` search to debug the `perft()` function.

See https://www.chessprogramming.org/Perft.
"""
function divide(b::Board, depth::Int)::Int
    ms = sort(collect(moves(b)), by=tostring)
    result = 0
    for m in ms
        result += perft(domove(b, m), depth - 1)
        println("$(tostring(m)) $result")
    end
    result
end


function initboard!(b::Board)
    b.checkers = findcheckers(b)
    b.pin = findpinned(b)
end


"""
    fromfen(fen::String)

Try to create a `Board` value from a FEN string.

If the supplied string doesn't represent a valid board position, this function
returns `nothing`.
"""
function fromfen(fen::String)::Union{Board, Nothing}
    result = emptyboard()
    components = split(fen, r"\s+")
    r = RANK_8.val
    f = FILE_A.val
    for c in components[1]
        p = piecefromchar(c)
        if p ≠ nothing
            s = Square(SquareFile(f), SquareRank(r))
            putpiece!(result, p, s)
            f += 1
        elseif c ≥ '1' && c ≤ '8'
            f += c - '0'
        elseif c == '/'
            f = FILE_A.val
            r += 1
        else
            return nothing
        end
    end

    comp = get(components, 2, "w")
    c = colorfromchar(comp[1])
    if isok(c)
        result.side = UInt8(c.val)
        if c == BLACK
            result.key ⊻ zobsidetomove()
        end
    end

    comp = get(components, 3, "-")
    for ch in comp
        i = findfirst(isequal(ch), "KQkq")
        if i ≠ nothing
            result.castlerights |= 1 << (i - 1)
        end
    end
    result.key ⊻= zobcastle(result.castlerights)

    comp = get(components, 4, "-")
    s = squarefromstring(String(comp))
    if s ≠ nothing
        result.epsq = s.val
        result.key ⊻= zobep(s)
    end

    initboard!(result)

    result
end


function castlestring(b::Board)::String
    if b.castlerights == 0
        "-"
    else
        ((b.castlerights & 1) ≠ 0 ? "K" : "") *
            ((b.castlerights & 2) ≠ 0 ? "Q" : "") *
            ((b.castlerights & 4) ≠ 0 ? "k" : "") *
            ((b.castlerights & 8) ≠ 0 ? "q" : "")
    end
end


"""
    fen(b::Board)

Convert a board to a FEN string.
"""
function fen(b::Board)::String
    result = IOBuffer()
    for ri in 1:8
        r = SquareRank(ri)
        skip = 0
        for fi in 1:8
            f = SquareFile(fi)
            p = pieceon(b, f, r)
            if p == EMPTY
                skip += 1
            else
                if skip > 0
                    write(result, string(skip))
                end
                write(result, tochar(p))
                skip = 0
            end
        end
        if skip > 0
            write(result, string(skip))
        end
        if ri ≠ 8
            write(result, "/")
        end
    end
    write(result, " ", tochar(sidetomove(b)))
    write(result, " ", castlestring(b))
    write(result, " ")
    write(result, epsquare(b) == SQ_NONE ? '-' : tostring(epsquare(b)))

    String(take!(result))
end


"""
    START_FEN

The FEN string of the standard chess opening position.
"""
const START_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -"


"""
    startboard()

Gives a `Board` object with the standard chess initial position.
"""
function startboard()::Board
    fromfen(START_FEN)
end


function colorpprint(b::Board, highlight = SS_EMPTY, unicode = false)
    for ri in 1:8
        r = SquareRank(ri)
        for fi in 1:8
            f = SquareFile(fi)
            p = pieceon(b, f, r)
            fg = pcolor(p) == WHITE ? 0xffff88 : 0x000000
            bg = (ri + fi) % 2 == 0 ? 0x8accc0 : 0x66b0a3
            ch = unicode ?
                tounicode(Piece(WHITE, ptype(p))) : tochar(ptype(p))
            if Square(f, r) ∈ highlight
                hc = 0xff1654
                if p == EMPTY
                    print(Crayon(background = bg, foreground = hc), " * ")
                else
                    print(Crayon(background = bg, foreground = hc), "*",
                          Crayon(background = bg, foreground = fg), ch,
                          Crayon(background = bg, foreground = hc), "*")
                end
            else
                if p == EMPTY
                    print(Crayon(background = bg, foreground = fg), "   ")
                else
                    print(Crayon(background = bg, foreground = fg),
                          " $ch ")
                end
            end
        end
        println(Crayon(reset = true), "")
    end
end


"""
    pprint(b::Board, color = false, highlight = SS_EMPTY, unicode = false)

Pretty-print a `Board` to the standard output.

On terminals with 24-bit color support, use `color = true` for a colored board.
Use the parameter `highlight` to include a `SquareSet` you want to be
highlighted.

Use `unicode = true` for Unicode piece output, if your font and terminal
supports it.

# Examples

```julia-repl
julia> pprint(startboard(), highlight = SquareSet(SQ_D4, SQ_E4, SQ_D5, SQ_E5))
+---+---+---+---+---+---+---+---+
| r | n | b | q | k | b | n | r |
+---+---+---+---+---+---+---+---+
| p | p | p | p | p | p | p | p |
+---+---+---+---+---+---+---+---+
|   |   |   |   |   |   |   |   |
+---+---+---+---+---+---+---+---+
|   |   |   | * | * |   |   |   |
+---+---+---+---+---+---+---+---+
|   |   |   | * | * |   |   |   |
+---+---+---+---+---+---+---+---+
|   |   |   |   |   |   |   |   |
+---+---+---+---+---+---+---+---+
| P | P | P | P | P | P | P | P |
+---+---+---+---+---+---+---+---+
| R | N | B | Q | K | B | N | R |
+---+---+---+---+---+---+---+---+
rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -
```
"""
function pprint(b::Board; color = false, highlight = SS_EMPTY, unicode = false)
    if color
        colorpprint(b, highlight, unicode)
    else
        for ri in 1:8
            r = SquareRank(ri)
            println("+---+---+---+---+---+---+---+---+")
            for fi in 1:8
                f = SquareFile(fi)
                ch = unicode ?
                    tounicode(pieceon(b, f, r)) : tochar(pieceon(b, f, r))
                if Square(f, r) ∈ highlight
                    if pieceon(b, f, r) ≠ EMPTY
                        print("|*$ch*")
                    else
                        print("| * ")
                    end
                else
                    if pieceon(b, f, r) ≠ EMPTY
                        print("| $ch ")
                    else
                        print("|   ")
                    end
                end
            end
            println("|")
        end
        println("+---+---+---+---+---+---+---+---+")
    end
    println(fen(b))
end
