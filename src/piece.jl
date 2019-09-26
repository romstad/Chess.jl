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

import Base.<, Base.>

export PieceColor, PieceType, Piece

export colorfromchar, coloropp, isok, isslider, pcolor, piecefromchar,
    piecetypefromchar, ptype, tochar, tounicode
export BISHOP, BLACK, COLOR_NONE, EMPTY, KING, KNIGHT, PAWN, PIECE_BB, PIECE_BK,
    PIECE_BN, PIECE_BP, PIECE_BQ, PIECE_BR, PIECE_TYPE_NONE, PIECE_WB, PIECE_WK,
    PIECE_WN, PIECE_WP, PIECE_WQ, PIECE_WR, QUEEN, ROOK, WHITE


"""
    PieceColor

Type representing the color of a chess piece.

The possible values are `WHITE`, `BLACK` and `COLOR_NONE`. The reason for the
existence of the value `COLOR_NONE` is that we represent a chess board as an
array of pieces, and we need a special `Piece` value `EMPTY` to indicate an
empty square on the board. The color of the `EMPTY` piece is `COLOR_NONE`.
"""
struct PieceColor
    val::Int
end

const WHITE = PieceColor(1)
const BLACK = PieceColor(2)
const COLOR_NONE = PieceColor(3)

function Base.show(io::IO, c::PieceColor)
    if c == WHITE
        print(io, "WHITE")
    elseif c == BLACK
        print(io, "BLACK")
    elseif c == COLOR_NONE
        print(io, "COLOR_NONE")
    else
        print(io, "PieceColor(???)")
    end
end


"""
    isok(c::PieceColor)

Tests whether a `PieceColor` value is a valid.

Returns `true` if and only if `c` is either `WHITE` or `BLACK`.

# Examples

```julia-repl
julia> isok(WHITE)
true

julia> isok(BLACK)
true

julia> isok(COLOR_NONE)
false

julia> isok(PieceColor(42))
false
```
"""
function isok(c::PieceColor)::Bool
    c == WHITE || c == BLACK
end


"""
    coloropp(c::PieceColor)

Returns the opposite of a color.

# Examples

```julia-repl
julia> coloropp(WHITE) == BLACK
true

julia> coloropp(BLACK) == WHITE
true
```
"""
function coloropp(c::PieceColor)::PieceColor
    PieceColor(c.val ⊻ 3)
end


"""
    colorfromchar(c::Char)

Tries to convert a character to a `PieceColor`.

The return value is a `Union{PieceColor, Nothing}`. If the input character is
one of the four characters `'w'`, `'b'`, `'W'`, `'B'`, the function returns the
obvious corresponding color (`WHITE` or `BLACK`). For all other input
characters, the function returns `nothing`.

# Examples

```julia-repl
julia> colorfromchar('w') == WHITE
true

julia> colorfromchar('B') == BLACK
true

julia> colorfromchar('x') == nothing
true
```
"""
function colorfromchar(c::Char)::Union{PieceColor, Nothing}
    i = findfirst(isequal(lowercase(c)), "wb")
    if i == nothing
        nothing
    else
        PieceColor(i)
    end
end


"""
    tochar(c::PieceColor)

Converts a color to a character.

# Examples

```julia-repl
julia> tochar(WHITE)
'w': ASCII/Unicode U+0077 (category Ll: Letter, lowercase)

julia> tochar(BLACK)
'b': ASCII/Unicode U+0062 (category Ll: Letter, lowercase)

julia> tochar(COLOR_NONE)
'?': ASCII/Unicode U+003f (category Po: Punctuation, other)
```
"""
function tochar(c::PieceColor)::Char
    if c == WHITE
        'w'
    elseif c == BLACK
        'b'
    else
        '?'
    end
end


"""
    PieceType

Type representing the type of a chess piece.

This is essentially a piece without color. The possible values are `PAWN`,
`KNIGHT`, `BISHOP`, `ROOK`, `QUEEN`, `KING` and `PIECE_TYPE_NONE`. The reason
for the existence of the value `PIECE_TYPE_NONE` is that we represent a chess
board as an array of pieces, and we need a special `Piece` value `EMPTY` to
indicate an empty square on the board. The type of the `EMPTY` piece is
`PIECE_TYPE_NONE`
"""
struct PieceType
    val::Int
end

(<)(t1::PieceType, t2::PieceType) = t1.val < t2.val

const PAWN = PieceType(1)
const KNIGHT = PieceType(2)
const BISHOP = PieceType(3)
const ROOK = PieceType(4)
const QUEEN = PieceType(5)
const KING = PieceType(6)
const PIECE_TYPE_NONE = PieceType(7)


function Base.show(io::IO, t::PieceType)
    if t == PAWN
        print(io, "PAWN")
    elseif t == KNIGHT
        print(io, "KNIGHT")
    elseif t == BISHOP
        print(io, "BISHOP")
    elseif t == ROOK
        print(io, "ROOK")
    elseif t == QUEEN
        print(io, "QUEEN")
    elseif t == KING
        print(io, "KING")
    elseif t == PIECE_TYPE_NONE
        print(io, "PIECE_TYPE_NONE")
    else
        print(io, "PieceType($(t.val))")
    end
end


"""
    isok(t::PieceType)

Tests whether a `PieceType` value is valid.

Returns `true` for all of `PAWN`, `KNIGHT`, `BISHOP`, `ROOK`, `QUEEN` and
`KING`, and `false` for all other inputs.

# Examples

```julia-repl
julia> isok(QUEEN)
true

julia> isok(KNIGHT)
true

julia> isok(PIECE_TYPE_NONE)
false

julia> isok(PieceType(-1))
false
```
"""
function isok(t::PieceType)::Bool
    t >= PAWN && t <= KING
end


"""
    piecetypefromchar(c::Chars)

Tries to convert a character to a `PieceType`.

The return value is a `Union{PieceType, Nothing}`. If the input character is a
valid upper- or lowercase English piece letter (PNBRQK), the function returns
the corresponding piece type. For all other input characters, the function
returns `nothing`.

# Examples

```julia-repl
julia> piecetypefromchar('n') == KNIGHT
true

julia> piecetypefromchar('B') == BISHOP
true

julia> piecetypefromchar('a') == nothing
true
```
"""
function piecetypefromchar(c::Char)::Union{PieceType, Nothing}
    i = findfirst(isequal(lowercase(c)), "pnbrqk")
    if i == nothing
        nothing
    else
        PieceType(i)
    end
end


"""
    tochar(t::PieceType, uppercase = false)

Converts a `PieceType` value to a character.

A valid piece type value is converted to its standard English algebraic
notation piece letter. Any invalid piece type value is converted to a `'?'`
character. The optional parameter `uppercase` controls whether the character
is an upper- or lower-case letter.

# Examples

```julia-repl
julia> tochar(PAWN)
'p': ASCII/Unicode U+0070 (category Ll: Letter, lowercase)

julia> tochar(ROOK, true)
'R': ASCII/Unicode U+0052 (category Lu: Letter, uppercase)

julia> tochar(PIECE_TYPE_NONE)
'?': ASCII/Unicode U+003f (category Po: Punctuation, other)
```
"""
function tochar(t::PieceType, uppercase = false)::Char
    if isok(t)
        (uppercase ? "PNBRQK" : "pnbrqk")[t.val]
    else
        '?'
    end
end


"""
    Piece

Type representing a chess piece.

The possible values are `PIECE_WP`, `PIECE_WN`, `PIECE_WB`, `PIECE_WR`,
`PIECE_WQ`, `PIECE_WK`, `PIECE_BP`, `PIECE_BN`, `PIECE_BB`, `PIECE_BR`,
`PIECE_BQ`, `PIECE_BK` and `EMPTY`. The reason for the existence of the
value `EMPTY` is that we represent a chess board as an array of pieces, and
we need a value to indicate an empty square on the board.
"""
struct Piece
    val::Int
end


"""
    Piece(c::PieceColor, t::PieceType)

Construct a piece with the given color and type.

# Examples
```julia-repl
julia> Piece(BLACK, QUEEN)
PIECE_BQ
```
"""
Piece(c::PieceColor, t::PieceType) = Piece(((c.val - 1) << 3) | t.val)


const PIECE_WP = Piece(WHITE, PAWN)
const PIECE_WN = Piece(WHITE, KNIGHT)
const PIECE_WB = Piece(WHITE, BISHOP)
const PIECE_WR = Piece(WHITE, ROOK)
const PIECE_WQ = Piece(WHITE, QUEEN)
const PIECE_WK = Piece(WHITE, KING)
const PIECE_BP = Piece(BLACK, PAWN)
const PIECE_BN = Piece(BLACK, KNIGHT)
const PIECE_BB = Piece(BLACK, BISHOP)
const PIECE_BR = Piece(BLACK, ROOK)
const PIECE_BQ = Piece(BLACK, QUEEN)
const PIECE_BK = Piece(BLACK, KING)
const EMPTY = Piece(COLOR_NONE, PIECE_TYPE_NONE)


function Base.show(io::IO, p::Piece)
    if isok(p)
        print(io, "PIECE_$(uppercase(tochar(pcolor(p))))$(uppercase(tochar(ptype(p))))")
    elseif p == EMPTY
        print(io, "EMPTY")
    else
        print(io, "PieceType($(p.val))")
    end
end


"""
    pcolor(p::Piece)

Find the color of a `Piece`.

# Examples

```julia-repl
julia> pcolor(PIECE_WB)
WHITE

julia> pcolor(EMPTY)
COLOR_NONE
```
"""
function pcolor(p::Piece)::PieceColor
    PieceColor(p.val >> 3 + 1)
end


"""
    ptype(p::Piece)

Find the type of a `Piece`.

# Examples

```julia-repl
julia> ptype(PIECE_BQ)
QUEEN

julia> ptype(EMPTY)
PIECE_TYPE_NONE
```
"""
function ptype(p::Piece)::PieceType
    PieceType(p.val & 7)
end


"""
    isok(p::Piece)

Tests wheter a `Piece` value is valid.

Returns `true` if and only if the color and the type of the piece are valid
piece color and piece type values, respectively.

# Examples

```julia-repl
julia> isok(PIECE_WB)
true

julia> isok(PIECE_BQ)
true

julia> isok(EMPTY)
false

julia> isok(Piece(-10))
false
```
"""
function isok(p::Piece)::Bool
    isok(ptype(p)) && isok(pcolor(p))
end


"""
    piecefromchar(ch::Char)

Tries to convert a character to a `Piece`.

The return value is a `Union{Piece, Nothing}`. If the input character is a
valid English piece letter, the corresponding piece is returned. If the piece
letter is uppercase, the piece is white. If the piece letter is lowercase,
the piece is black.

If the input value is not a valid English piece letter, the function returns
`nothing`.

# Examples

```julia-repl
julia> piecefromchar('Q')
PIECE_WQ

julia> piecefromchar('n')
PIECE_BN

julia> piecefromchar('-') == nothing
true
```
"""
function piecefromchar(ch::Char)::Union{Piece, Nothing}
    c = isuppercase(ch) ? WHITE : BLACK
    t = piecetypefromchar(ch)
    if t == nothing
        nothing
    else
        Piece(c, t)
    end
end


"""
    tochar(p::Piece)

Converts a piece to a character.

# Examples

```julia-repl
julia> tochar(PIECE_WN)
'N': ASCII/Unicode U+004e (category Lu: Letter, uppercase)

julia> tochar(PIECE_BK)
'k': ASCII/Unicode U+006b (category Ll: Letter, lowercase)

julia> tochar(EMPTY)
'?': ASCII/Unicode U+003f (category Po: Punctuation, other)
```
"""
function tochar(p::Piece)::Char
    if isok(p)
        tochar(ptype(p), pcolor(p) == WHITE)
    else
        '?'
    end
end


function tounicode(p::Piece)::Char
    chars = ['♙', '♘', '♗', '♖', '♕', '♔', '?', '?',
             '♟', '♞', '♝', '♜', '♛', '♚']
    if isok(p)
        chars[p.val]
    else
        '?'
    end
end


"""
    isslider(t::PieceType)
    isslider(p::Piece)

Determine whether a piece is a sliding piece.
"""
function isslider(t::PieceType)::Bool
    t >= BISHOP && t <= QUEEN
end,

function isslider(p::Piece)::Bool
    isslider(ptype(p))
end
