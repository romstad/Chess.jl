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

import Base.+, Base.-, Base.*, Base.<, Base.>

export Square, SquareFile, SquareRank, SquareDelta

export distance, file, filefromchar, isok, rank, rankfromchar, squarefromstring,
    tochar, tostring

export FILE_NONE, FILE_A, FILE_B, FILE_C, FILE_D, FILE_E, FILE_F, FILE_G, FILE_H
export RANK_NONE, RANK_1, RANK_2, RANK_3, RANK_4, RANK_5, RANK_6, RANK_7, RANK_8
export FILE_MIN, FILE_MAX, RANK_MIN, RANK_MAX

export SQ_A1, SQ_A2, SQ_A3, SQ_A4, SQ_A5, SQ_A6, SQ_A7, SQ_A8
export SQ_B1, SQ_B2, SQ_B3, SQ_B4, SQ_B5, SQ_B6, SQ_B7, SQ_B8
export SQ_C1, SQ_C2, SQ_C3, SQ_C4, SQ_C5, SQ_C6, SQ_C7, SQ_C8
export SQ_D1, SQ_D2, SQ_D3, SQ_D4, SQ_D5, SQ_D6, SQ_D7, SQ_D8
export SQ_E1, SQ_E2, SQ_E3, SQ_E4, SQ_E5, SQ_E6, SQ_E7, SQ_E8
export SQ_F1, SQ_F2, SQ_F3, SQ_F4, SQ_F5, SQ_F6, SQ_F7, SQ_F8
export SQ_G1, SQ_G2, SQ_G3, SQ_G4, SQ_G5, SQ_G6, SQ_G7, SQ_G8
export SQ_H1, SQ_H2, SQ_H3, SQ_H4, SQ_H5, SQ_H6, SQ_H7, SQ_H8
export SQ_NONE

export DELTA_N, DELTA_S, DELTA_E, DELTA_W
export DELTA_NW, DELTA_NE, DELTA_SW, DELTA_SE


"""
    SquareFile

Type representing the file of a square on a chess board.

Usually, a `SquareFile` is obtained either by calling the function `file()` on a
`Square` or through one of the constants `FILE_A`, `FILE_B`, ..., `FILE_H`.
"""
struct SquareFile
    val::Int
end


"""
    SquareRank

Type representing the rank of a square on a chess board.

Usually, a `SquareRank` is obtained either by calling the function `rank()` on a
`Square` or through one of the constants `RANK_1`, `RANK_2`, ..., `RANK_8`.
"""
struct SquareRank
    val::Int
end


function Base.show(io::IO, f::SquareFile)
    if isok(f)
        print(io, "FILE_$(uppercase(tochar(f)))")
    elseif f == FILE_NONE
        print(io, "FILE_NONE")
    else
        print(io, "SquareFile($(f.val))")
    end
end

function Base.show(io::IO, r::SquareRank)
    if isok(r)
        print(io, "RANK_$(tochar(r))")
    elseif r == RANK_NONE
        print(io, "RANK_NONE")
    else
        print(io, "SquareRank($(r.val))")
    end
end


(<)(f1::SquareFile, f2::SquareFile) = f1.val < f2.val
(<)(r1::SquareRank, r2::SquareRank) = r1.val < r2.val


const FILE_NONE = SquareFile(0)
const FILE_A = SquareFile(1)
const FILE_B = SquareFile(2)
const FILE_C = SquareFile(3)
const FILE_D = SquareFile(4)
const FILE_E = SquareFile(5)
const FILE_F = SquareFile(6)
const FILE_G = SquareFile(7)
const FILE_H = SquareFile(8)
const FILE_MIN = FILE_A
const FILE_MAX = FILE_H

const RANK_NONE = SquareRank(0)
const RANK_1 = SquareRank(8)
const RANK_2 = SquareRank(7)
const RANK_3 = SquareRank(6)
const RANK_4 = SquareRank(5)
const RANK_5 = SquareRank(4)
const RANK_6 = SquareRank(3)
const RANK_7 = SquareRank(2)
const RANK_8 = SquareRank(1)
const RANK_MIN = RANK_8
const RANK_MAX = RANK_1


"""
    isok(f::SquareFile)

Tests whether a `SquareFile` contains a valid value.

# Examples

```julia-repl
julia> isok(FILE_A)
true

julia> isok(SquareFile(0))
false
```
"""
function isok(f::SquareFile)
    f ≥ FILE_MIN && f ≤ FILE_MAX
end


"""
    isok(r::SquareRank)

Tests whether a `SquareRank` contains a valid value.

# Examples

```julia-repl
julia> isok(RANK_6)
true

julia> isok(SquareRank(42))
false
```
"""
function isok(r::SquareRank)
    r ≥ RANK_MIN && r ≤ RANK_MAX
end


"""
    filefromchar(c::Char)

Tries to convert a character to a file.

The return value is a `Union{SquareFile, Nothing}`. The `nothing` is returned
in case the character does not represent a valid file.

# Examples

```julia-repl
julia> filefromchar('c')
FILE_C

julia> filefromchar('2') == nothing
true
```
"""
function filefromchar(c::Char)::Union{SquareFile, Nothing}
    result = SquareFile(Int(c) - Int('a') + 1)
    isok(result) ? result : nothing
end


"""
    rankfromchar(c::Char)

Tries to convert a character to a rank.

The return value is a `Union{SquareRank, Nothing}`. The `nothing` is returned
in case the character does not represent a valid rank.

# Examples

```julia-repl
julia> rankfromchar('2')
RANK_2

julia> rankfromchar('x') == nothing
true
```
"""
function rankfromchar(c::Char)::Union{SquareRank, Nothing}
    result = SquareRank(8 - Int(c) + Int('1'))
    isok(result) ? result : nothing
end


"""
    tochar(f::SquareFile)

Converts a `SquareFile` to a character.

# Examples

```julia-repl
julia> tochar(FILE_E)
'e': ASCII/Unicode U+0065 (category Ll: Letter, lowercase)
```
"""
function tochar(f::SquareFile)
    Char(f.val - 1 + Int('a'))
end


"""
    tochar(r::SquareRank)

Converts `SquareRank` to a character.

# Examples

```julia-repl
julia> tochar(RANK_3)
'3': ASCII/Unicode U+0033 (category Nd: Number, decimal digit)
```
"""
function tochar(r::SquareRank)
    Char(8 - r.val + Int('1'))
end


"""
    Square

Type representing a square on a chess board.

A `Square` can be constructed either with an `Int` (with the convention a8=1,
a7=2, ..., a1=8, b8=9, b7=10, ..., h1=64) or with a `SquareFile` and a
`SquareRank`. There are also constants `SQ_A1`, ..., `SQ_H8` for all 64
squares on the board.

# Examples

```julia-repl
julia> Square(FILE_G, RANK_6)
SQ_G6

julia> Square(8)
SQ_A1
```
"""
struct Square
    val::Int
end


function Base.show(io::IO, s::Square)
    if isok(s)
        print(io, "SQ_$(uppercase(tostring(s)))")
    elseif s == SQ_NONE
        print(io, "SQ_NONE")
    else
        print(io, "Square($(s.val))")
    end
end


"""
    Square(f::SquareFile, r::SquareRank)

Construct a square with the given file and rank.

# Examples

```julia-repl
julia> Square(FILE_D, RANK_5)
SQ_D5
```
"""
Square(f::SquareFile, r::SquareRank) = Square(r.val + 8 * (f.val - 1))


"""
    file(s::Square)

Compute the file of the square `s`.

# Examples

```julia-repl
julia> file(SQ_C4)
FILE_C
```
"""
function file(s::Square)
    SquareFile(fld1(s.val, 8))
end


"""
    rank(s::Square)

Compute the rank of the square `s`.

# Examples

```julia-repl
julia> rank(SQ_C4)
RANK_4
```
"""
function rank(s::Square)
    SquareRank(mod1(s.val, 8))
end


"""
    isok(s::Square)

Tests whether a `Square` has a valid value.

# Examples

```julia-repl
julia> isok(SQ_G7)
true

julia> isok(Square(42))
true

julia> isok(Square(100))
false

julia> isok(Square(0))
false
```
"""
function isok(s::Square)
    isok(file(s)) && isok(rank(s))
end


"""
    tostring(s::Square)

Converts a square to a string in standard algebraic notation. If the square
has an invalid value, the returned string is `"??"`.

# Examples

```julia-repl
julia> tostring(SQ_E4)
"e4"

julia> tostring(Square(100))
"??"
```
"""
function tostring(s::Square)
    if isok(s)
        result = IOBuffer()
        write(result, tochar(file(s)), tochar(rank(s)))
        String(take!(result))
    else
        "??"
    end
end


"""
    squarefromstring(s::String)

Tries to convert a string to a `Square`.

The return value is of type `Union{Square, Nothing}`.

If the input string is too short, or if the two first characters do not
represent a square in standard algebraic notation, returns `nothing`. If the
first two characters do represent avalid square, that square is returned, even
if there are additional characters.

# Examples

```julia-repl
julia> squarefromstring("d6")
SQ_D6

julia> squarefromstring("xy") == nothing
true

julia> squarefromstring("") == nothing
true

julia> squarefromstring("g1f3")
SQ_G1
```
"""
function squarefromstring(s::String)::Union{Square, Nothing}
    if length(s) < 2
        nothing
    else
        f = filefromchar(s[1])
        r = rankfromchar(s[2])
        if isa(f, SquareFile) && isa(r, SquareRank)
            Square(f, r)
        else
            nothing
        end
    end
end


"""
    distance(f1::SquareFile, f2::SquareFile)

The horizontal distance between two files.
"""
function distance(f1::SquareFile, f2::SquareFile)::Int
    abs(f2.val - f1.val)
end


"""
    distance(r1::SquareRank, r2::SquareRank)

The vertical distance between two ranks.
"""
function distance(r1::SquareRank, r2::SquareRank)::Int
    abs(r2.val - r1.val)
end


"""
    distance(s1::Square, s2::Square)

The distance between two squares, counted by number of king moves.
"""
function distance(s1::Square, s2::Square)::Int
    max(distance(file(s1), file(s2)), distance(rank(s1), rank(s2)))
end


"""
    SquareDelta

A type representing the delta or vector between two squares.

A `SquareDelta` value is usually obtained either through one of the constants
`DELTA_N`, `DELTA_S`, `DELTA_E`, `DELTA_W`, `DELTA_NW`, `DELTA_NE`, `DELTA_SW`,
`DELTA_SE`, or by subtracting two square values.

It is possible to add or subtract two `SquareDelta`s, to multiply a
`SquareDelta` by an integer scalar, or to add or subtract a `SquareDelta` to a
`Square`.

# Examples

```julia-repl
julia> DELTA_N + DELTA_W == DELTA_NW
true

julia> SQ_D3 - SQ_C3 == DELTA_E
true

julia> SQ_G8 - 3 * DELTA_N
SQ_G5
```
"""
struct SquareDelta
    val::Int
end

(-)(s1::Square, s2::Square) = SquareDelta(s1.val - s2.val)
(+)(s::Square, d::SquareDelta) = Square(s.val + d.val)
(-)(s::Square, d::SquareDelta) = Square(s.val - d.val)
(+)(d1::SquareDelta, d2::SquareDelta) = SquareDelta(d1.val + d2.val)
(-)(d1::SquareDelta, d2::SquareDelta) = SquareDelta(d1.val - d2.val)
(*)(i::Integer, d::SquareDelta) = SquareDelta(i * d.val)

const SQ_A1 = Square(FILE_A, RANK_1)
const SQ_A2 = Square(FILE_A, RANK_2)
const SQ_A3 = Square(FILE_A, RANK_3)
const SQ_A4 = Square(FILE_A, RANK_4)
const SQ_A5 = Square(FILE_A, RANK_5)
const SQ_A6 = Square(FILE_A, RANK_6)
const SQ_A7 = Square(FILE_A, RANK_7)
const SQ_A8 = Square(FILE_A, RANK_8)

const SQ_B1 = Square(FILE_B, RANK_1)
const SQ_B2 = Square(FILE_B, RANK_2)
const SQ_B3 = Square(FILE_B, RANK_3)
const SQ_B4 = Square(FILE_B, RANK_4)
const SQ_B5 = Square(FILE_B, RANK_5)
const SQ_B6 = Square(FILE_B, RANK_6)
const SQ_B7 = Square(FILE_B, RANK_7)
const SQ_B8 = Square(FILE_B, RANK_8)

const SQ_C1 = Square(FILE_C, RANK_1)
const SQ_C2 = Square(FILE_C, RANK_2)
const SQ_C3 = Square(FILE_C, RANK_3)
const SQ_C4 = Square(FILE_C, RANK_4)
const SQ_C5 = Square(FILE_C, RANK_5)
const SQ_C6 = Square(FILE_C, RANK_6)
const SQ_C7 = Square(FILE_C, RANK_7)
const SQ_C8 = Square(FILE_C, RANK_8)

const SQ_D1 = Square(FILE_D, RANK_1)
const SQ_D2 = Square(FILE_D, RANK_2)
const SQ_D3 = Square(FILE_D, RANK_3)
const SQ_D4 = Square(FILE_D, RANK_4)
const SQ_D5 = Square(FILE_D, RANK_5)
const SQ_D6 = Square(FILE_D, RANK_6)
const SQ_D7 = Square(FILE_D, RANK_7)
const SQ_D8 = Square(FILE_D, RANK_8)

const SQ_E1 = Square(FILE_E, RANK_1)
const SQ_E2 = Square(FILE_E, RANK_2)
const SQ_E3 = Square(FILE_E, RANK_3)
const SQ_E4 = Square(FILE_E, RANK_4)
const SQ_E5 = Square(FILE_E, RANK_5)
const SQ_E6 = Square(FILE_E, RANK_6)
const SQ_E7 = Square(FILE_E, RANK_7)
const SQ_E8 = Square(FILE_E, RANK_8)

const SQ_F1 = Square(FILE_F, RANK_1)
const SQ_F2 = Square(FILE_F, RANK_2)
const SQ_F3 = Square(FILE_F, RANK_3)
const SQ_F4 = Square(FILE_F, RANK_4)
const SQ_F5 = Square(FILE_F, RANK_5)
const SQ_F6 = Square(FILE_F, RANK_6)
const SQ_F7 = Square(FILE_F, RANK_7)
const SQ_F8 = Square(FILE_F, RANK_8)

const SQ_G1 = Square(FILE_G, RANK_1)
const SQ_G2 = Square(FILE_G, RANK_2)
const SQ_G3 = Square(FILE_G, RANK_3)
const SQ_G4 = Square(FILE_G, RANK_4)
const SQ_G5 = Square(FILE_G, RANK_5)
const SQ_G6 = Square(FILE_G, RANK_6)
const SQ_G7 = Square(FILE_G, RANK_7)
const SQ_G8 = Square(FILE_G, RANK_8)

const SQ_H1 = Square(FILE_H, RANK_1)
const SQ_H2 = Square(FILE_H, RANK_2)
const SQ_H3 = Square(FILE_H, RANK_3)
const SQ_H4 = Square(FILE_H, RANK_4)
const SQ_H5 = Square(FILE_H, RANK_5)
const SQ_H6 = Square(FILE_H, RANK_6)
const SQ_H7 = Square(FILE_H, RANK_7)
const SQ_H8 = Square(FILE_H, RANK_8)

const SQ_NONE = Square(65)

const DELTA_N = SQ_A2 - SQ_A1
const DELTA_S = -1 * DELTA_N
const DELTA_E = SQ_B1 - SQ_A1
const DELTA_W = -1 * DELTA_E
const DELTA_NW = DELTA_N + DELTA_W
const DELTA_NE = DELTA_N + DELTA_E
const DELTA_SW = DELTA_S + DELTA_W
const DELTA_SE = DELTA_S + DELTA_E
