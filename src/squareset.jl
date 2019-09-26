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

import Base.+, Base.-, Base.first, Base.in, Base.intersect, Base.isempty,
    Base.issubset, Base.union

export SquareSet

export bishopattacks, bishopattacksempty, filesquares, isempty, issingleton,
    kingattacks, knightattacks, onlyfirst, pawnattacks, pawnshift_n,
    pawnshift_ne, pawnshift_nw, pawnshift_s,  pawnshift_sw, pawnshift_se,
    pprint, ranksquares, removefirst, rookattacks, rookattacksempty,
    queenattacks, queenattacksempty, shift_e, shift_n, shift_s, shift_w,
    squarecount, squares, squaresbetween, toarray

export SS_EMPTY, SS_FILE_A, SS_FILE_B, SS_FILE_C, SS_FILE_D, SS_FILE_E,
    SS_FILE_F, SS_FILE_G, SS_FILE_H, SS_RANK_1, SS_RANK_2, SS_RANK_3, SS_RANK_4,
    SS_RANK_5, SS_RANK_6, SS_RANK_7, SS_RANK_8


"""
    SquareSet

A type representing a set of squares on the chess board.

The most common ways of obtaining a square set are:

  * Initializing it with one or more squares, for instance `SquareSet(SQ_D4,
    SQ_E4, SQ_D5, SQ_E5)`.

  * From one of the predefined square set constants, like `SS_FILE_C` (the
    squares on the C file) or `SS_RANK_7` (the squares on the 7th rank).

  * By extracting it from a chess board. See the `Board` type for details
    about this.

  * By performing operations transforming or combining one or more square sets
    to a new square set.

The union or intersection of two sets can be computed by the functions `union`
and `intersect`, or by the corresponding binary operators `∪` and `∩`. The
complement of a square set is denoted by the unary `-` operator. The difference
between two set is obtained by the `setdiff` function or by the binary `-`
operator. Subset relationships can be tested by the `issubset` function or the
binary operator `⊆`.

To add or remove a square to a square set, use the `+` or `-` operators with
the square set as the left operand and the square as the right operand. To test
whether a square set contains a square, use `s in ss` or `s ∈ ss`.
"""
struct SquareSet
    val::UInt64
end


function Base.show(io::IO, ss::SquareSet)
    println(io, "SquareSet:")
    for ri in 1:8
        r = SquareRank(ri)
        for fi in 1:8
            f = SquareFile(fi)
            if Square(f, r) ∈ ss
                print(io, " # ")
            else
                print(io, " - ")
            end
        end
        if ri < 8
            println(io, "")
        end
    end
end


"""
    SquareSet(ss::Vararg{Square})

Construct a square set with the provided squares.

# Examples

```julia-repl
julia> SquareSet(SQ_A1, SQ_A2, SQ_A3, SQ_A4)
SquareSet:
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 #  -  -  -  -  -  -  -
 #  -  -  -  -  -  -  -
 #  -  -  -  -  -  -  -
 #  -  -  -  -  -  -  -
```
"""
function SquareSet(ss::Vararg{Square})
    result = UInt64(0)
    for s in ss
        result |= UInt64(1) << (s.val - 1)
    end
    SquareSet(result)
end


"""
    SS_EMPTY

An empty square set, containing no squares.
"""
const SS_EMPTY = SquareSet(0x0)


"""
    SS_FILE_A

The square set containing all the squares along the A file.
"""
const SS_FILE_A = SquareSet(0xff)


"""
    SS_FILE_B

The square set containing all the squares along the B file.
"""
const SS_FILE_B = SquareSet(0xff00)


"""
    SS_FILE_C

The square set containing all the squares along the C file.
"""
const SS_FILE_C = SquareSet(0xff0000)


"""
    SS_FILE_D

The square set containing all the squares along the D file.
"""
const SS_FILE_D = SquareSet(0xff000000)


"""
    SS_FILE_E

The square set containing all the squares along the E file.
"""
const SS_FILE_E = SquareSet(0xff00000000)


"""
    SS_FILE_F

The square set containing all the squares along the F file.
"""
const SS_FILE_F = SquareSet(0xff0000000000)


"""
    SS_FILE_G

The square set containing all the squares along the G file.
"""
const SS_FILE_G = SquareSet(0xff000000000000)


"""
    SS_FILE_H

The square set containing all the squares along the H file.
"""
const SS_FILE_H = SquareSet(0xff00000000000000)


"""
    SS_RANK_1

The square set containing all the squares along the 1st rank.
"""
const SS_RANK_1 = SquareSet(0x8080808080808080)


"""
    SS_RANK_2

The square set containing all the squares along the 2nd rank.
"""
const SS_RANK_2 = SquareSet(0x4040404040404040)


"""
    SS_RANK_3

The square set containing all the squares along the 3rd rank.
"""
const SS_RANK_3 = SquareSet(0x2020202020202020)


"""
    SS_RANK_4

The square set containing all the squares along the 4th rank.
"""
const SS_RANK_4 = SquareSet(0x1010101010101010)


"""
    SS_RANK_5

The square set containing all the squares along the 5th rank.
"""
const SS_RANK_5 = SquareSet(0x0808080808080808)


"""
    SS_RANK_6

The square set containing all the squares along the 6th rank.
"""
const SS_RANK_6 = SquareSet(0x0404040404040404)


"""
    SS_RANK_7

The square set containing all the squares along the 7th rank.
"""
const SS_RANK_7 = SquareSet(0x0202020202020202)


"""
    SS_RANK_8

The square set containing all the squares along the 8th rank.
"""
const SS_RANK_8 = SquareSet(0x0101010101010101)


const FILE_SQUARES = SVector(
    SS_FILE_A, SS_FILE_B, SS_FILE_C, SS_FILE_D,
    SS_FILE_E, SS_FILE_F, SS_FILE_G, SS_FILE_H
)

const RANK_SQUARES = SVector(
    SS_RANK_8, SS_RANK_7, SS_RANK_6, SS_RANK_5,
    SS_RANK_4, SS_RANK_3, SS_RANK_2, SS_RANK_1
)


"""
    filesquares(f::SquareFile)

The set of all squares on the provided file.

# Examples

```julia-repl
julia> filesquares(FILE_G) == SS_FILE_G
true
```
"""
function filesquares(f::SquareFile)::SquareSet
    FILE_SQUARES[f.val]
end


"""
    ranksquares(r::SquareRank)

The set of all squares on the provided rank.

# Examples

```julia-repl
julia> ranksquares(RANK_2) == SS_RANK_2
true
```
"""
function ranksquares(r::SquareRank)::SquareSet
    RANK_SQUARES[r.val]
end


"""
    isempty(ss::SquareSet)

Determine whether a square set is the empty set.

# Examples

```julia-repl
julia> isempty(SS_RANK_1)
false

julia> isempty(SS_EMPTY)
true

julia> isempty(SS_RANK_1 ∩ SS_RANK_2)
true
```
"""
function isempty(ss::SquareSet)::Bool
    ss == SS_EMPTY
end


"""
    union(ss1::SquareSet, ss2::SquareSet)
    ∪(ss1::SquareSet, ss2::SquareSet)

Compute the union of two square sets.

The binary operator `∪` can be used instead of the named function.

# Examples

```julia-repl
julia> SS_FILE_C ∪ SS_RANK_3
SquareSet:
 -  -  #  -  -  -  -  -
 -  -  #  -  -  -  -  -
 -  -  #  -  -  -  -  -
 -  -  #  -  -  -  -  -
 -  -  #  -  -  -  -  -
 #  #  #  #  #  #  #  #
 -  -  #  -  -  -  -  -
 -  -  #  -  -  -  -  -
```
"""
function union(ss1::SquareSet, ss2::SquareSet)
    SquareSet(ss1.val | ss2.val)
end


"""
    intersect(ss1::SquareSet, ss2::SquareSet)
    ∩(ss1::SquareSet, ss2::SquareSet)

Compute the intersection of two square sets.

The binary operator `∩` can be used instead of the named function.

# Examples

```julia-repl
julia> SS_FILE_D ∩ SS_RANK_7
SquareSet:
 -  -  -  -  -  -  -  -
 -  -  -  #  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
```
"""
function intersect(ss1::SquareSet, ss2::SquareSet)
    SquareSet(ss1.val & ss2.val)
end


"""
    -(ss::SquareSet)

The complement of a square set.

# Examples

```julia-repl
julia> ss = SquareSet(SQ_C4);

julia> SQ_C4 ∈ ss
true

julia> SQ_D4 ∈ ss
false

julia> SQ_C4 ∈ -ss
false

julia> SQ_D4 ∈ -ss
true
```
"""
function -(ss::SquareSet)
    SquareSet(~ss.val)
end


"""
    setdiff(ss1::SquareSet, ss2::SquareSet)
    -(ss1::SquareSet, ss2::SquareSet)

The set of all squares that are in `ss1`, but not in `ss2`.

# Examples

```julia-repl
julia> SquareSet(SQ_A1, SQ_A2, SQ_A3, SQ_B1, SQ_B2, SQ_B3) - SS_RANK_2
SquareSet:
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 #  #  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 #  #  -  -  -  -  -  -
```
"""
function setdiff(ss1::SquareSet, ss2::SquareSet)
    ss1 ∩ -ss2
end,

function -(ss1::SquareSet, ss2::SquareSet)
    setdiff(ss1, ss2)
end


"""
    +(ss::SquareSet, s::Square)

Add a square to a square set.

If a square is added that is already a member is added to the set, the set is
returned unchanged.

# Examples

```julia-repl
julia> SquareSet(SQ_A1) + SQ_H8 == SquareSet(SQ_A1, SQ_H8)
true

julia> SS_FILE_A + SQ_A1 == SS_FILE_A
true
```
"""
function +(ss::SquareSet, s::Square)
    SquareSet(ss.val | (UInt64(1) << (s.val - 1)))
end


"""
    -(ss::SquareSet, s::Square)

Remove a square from a square set.

If a non-member square is removed, the set is returned unchanged.

# Examples

```julia-repl
julia> SquareSet(SQ_A1, SQ_B1) - SQ_B1 == SquareSet(SQ_A1)
true

julia> SS_FILE_A - SQ_H8 == SS_FILE_A
true
```
"""
function -(ss::SquareSet, s::Square)
    SquareSet(ss.val & ~(UInt64(1) << (s.val - 1)))
end


"""
    issubset(ss1::SquareSet, ss2::SquareSet)
    ⊆(ss1::SquareSet, ss2::SquareSet)

Determine whether `ss1` is a subset of `ss2`.

# Examples

```julia-repl
julia> SquareSet(SQ_A1, SQ_A2) ⊆ SS_FILE_A
true

julia> SquareSet(SQ_A1, SQ_B1) ⊆ SS_FILE_A
false
```
"""
issubset(ss1::SquareSet, ss2::SquareSet) = ss1 ∩ ss2 == ss1


"""
    in(s::Square, ss::SquareSet)
    ∈(s::Square, ss::SquareSet)

Determine whether a square is a member of a square set.

# Examples

```julia-repl
julia> SQ_D7 ∈ SS_RANK_8
false

julia> SQ_D8 ∈ SS_RANK_8
true
```
"""
function in(s::Square, ss::SquareSet)::Bool
    (ss.val & (UInt64(1) << (s.val - 1))) ≠ 0
end


"""
    toarray(ss::SquareSet)

Convert a square set to a two-dimensional array.

The returned array's columns corresponds to the files, and the rows to the
ranks. The array entries are 1 for the members of the square set, and 0
for non-members.

# Examples

```julia-repl
julia> toarray(SS_FILE_C ∪ SS_RANK_5)
8×8 Array{Int64,2}:
 0  0  1  0  0  0  0  0
 0  0  1  0  0  0  0  0
 0  0  1  0  0  0  0  0
 1  1  1  1  1  1  1  1
 0  0  1  0  0  0  0  0
 0  0  1  0  0  0  0  0
 0  0  1  0  0  0  0  0
 0  0  1  0  0  0  0  0
```
"""
function toarray(ss::SquareSet)::Array{Int, 2}
    reshape([Square(i) ∈ ss ? 1 : 0 for i in 1:64],
            8, 8)
end


"""
    squarecount(ss::SquareSet)

The number of members of a square set.
"""
function squarecount(ss::SquareSet)::Int
    count_ones(ss.val)
end


"""
    first(ss::SquareSet)

The first square in a square set.

Returns SQ_NONE for an empty square set.
"""
function first(ss::SquareSet)::Square
    Square(trailing_zeros(ss.val) + 1)
end


"""
    removefirst(ss::SquareSet)

Remove the first member of a square set.

# Examples

```julia-repl
julia> removefirst(SquareSet(SQ_A4, SQ_D5, SQ_F6)) == SquareSet(SQ_D5, SQ_F6)
true
```
"""
function removefirst(ss::SquareSet)::SquareSet
    SquareSet(ss.val & (ss.val - 1))
end


"""
    issingleton(ss::SquareSet)

Determine whether `ss` contains exactly one square.

# Examples

```julia-repl
julia> issingleton(SquareSet(SQ_D5))
true

julia> issingleton(SquareSet(SQ_D5, SQ_C5))
false

julia> issingleton(SS_EMPTY)
false
```
"""
function issingleton(ss::SquareSet)::Bool
    ss ≠ SS_EMPTY && removefirst(ss) == SS_EMPTY
end


"""
    onlyfirst(ss::SquareSet)

Return a square set with all squares excep the first removed.

# Examples

```julia-repl
julia> onlyfirst(SquareSet(SQ_A4, SQ_D5, SQ_F6)) == SquareSet(SQ_A4)
true
```
"""
function onlyfirst(ss::SquareSet)::SquareSet
    SquareSet(ss.val & -ss.val)
end


function Base.iterate(ss::SquareSet, state = ss)
    if isempty(state)
        nothing
    else
        (first(state), removefirst(state))
    end
end


"""
    squares(ss::SquareSet)

Convert a square set to a vector of squares.

# Examples

```julia-repl
julia> tostring.(squares(SS_RANK_1))
8-element Array{String,1}:
 "a1"
 "b1"
 "c1"
 "d1"
 "e1"
 "f1"
 "g1"
 "h1"
```
"""
function squares(ss::SquareSet)::Array{Square, 1}
    result = Array{Square, 1}()
    for s in ss
        push!(result, s)
    end
    result
end


"""
    shift_n(ss::SquareSet)

Shift the square set one step in the 'north' direction.

Squares that are shifted off the edge of the board disappear.

```julia-repl
julia> shift_n(SS_RANK_2) == SS_RANK_3
true

julia> shift_n(SquareSet(SQ_D3, SQ_E4, SQ_F8)) == SquareSet(SQ_D4, SQ_E5)
true
```
"""
function shift_n(ss::SquareSet)::SquareSet
    SquareSet(ss.val >> 1) - SS_RANK_1
end


"""
    shift_s(ss::SquareSet)

Shift the square set one step in the 'south' direction.

Squares that are shifted off the edge of the board disappear.

# Examples

```julia-repl
julia> shift_s(SS_RANK_3) == SS_RANK_2
true

julia> shift_s(SquareSet(SQ_C3, SQ_D2, SQ_E1)) == SquareSet(SQ_C2, SQ_D1)
true
```
"""
function shift_s(ss::SquareSet)::SquareSet
    (SquareSet)(ss.val << 1) - SS_RANK_8
end


"""
    shift_e(ss::SquareSet)

Shift the square set one step in the 'east' direction.

Squares that are shifted off the edge of the board disappear.

# Examples

```julia-repl
julia> shift_e(SS_FILE_F) == SS_FILE_G
true

julia> shift_e(SquareSet(SQ_F5, SQ_G6, SQ_H7)) == SquareSet(SQ_G5, SQ_H6)
true
```
"""
function shift_e(ss::SquareSet)::SquareSet
    SquareSet(ss.val << 8)
end


"""
    shift_w(ss::SquareSet)

Shift the square set one step in the 'west' direction.

Squares that are shifted off the edge of the board disappear.

```julia-repl
julia> shift_w(SS_FILE_C) == SS_FILE_B
true

julia> shift_w(SquareSet(SQ_C5, SQ_B6, SQ_A7)) == SquareSet(SQ_B5, SQ_A6)
true
```
"""
function shift_w(ss::SquareSet)::SquareSet
    SquareSet(ss.val >> 8)
end


"""
    pawnshift_n(ss::SquareSet)

Shift a square set of pawns one step in the 'north' direction.

This is identical to the `shift_n` function except that `pawnshift_n` is a
little faster, but will not work for square sets containing squares on the 1st
or 8th rank.
"""
function pawnshift_n(ss::SquareSet)::SquareSet
    SquareSet(ss.val >> 1)
end


"""
    pawnshift_s(ss::SquareSet)

Shift a square set of pawns one step in the 'south' direction.

This is identical to the `shift_s` function except that `pawnshift_s` is a
little faster, but will not work for square sets containing squares on the 1st
or 8th rank.
"""
function pawnshift_s(ss::SquareSet)::SquareSet
    SquareSet(ss.val << 1)
end


"""
    pawnshift_nw(ss::SquareSet)

Shift a square set of pawns one step in the 'north west' direction.

This is identical to calling `shift_n` followed by `shift_w`, except that
`pawnshift_nw` is a little faster, but will not work for square sets
containing squares on the 1st or 8th rank.
"""
function pawnshift_nw(ss::SquareSet)::SquareSet
    SquareSet(ss.val >> 9)
end


"""
    pawnshift_ne(ss::SquareSet)

Shift a square set of pawns one step in the 'north east' direction.

This is identical to calling `shift_n` followed by `shift_e`, except that
`pawnshift_ne` is a little faster, but will not work for square sets
containing squares on the 1st or 8th rank.
"""
function pawnshift_ne(ss::SquareSet)::SquareSet
    SquareSet(ss.val << 7)
end


"""
    pawnshift_sw(ss::SquareSet)

Shift a square set of pawns one step in the 'south west' direction.

This is identical to calling `shift_s` followed by `shift_w`, except that
`pawnshift_sw` is a little faster, but will not work for square sets
containing squares on the 1st or 8th rank.
"""
function pawnshift_sw(ss::SquareSet)::SquareSet
    SquareSet(ss.val >> 7)
end


"""
    pawnshift_se(ss::SquareSet)

Shift a square set of pawns one step in the 'south east' direction.

This is identical to calling `shift_s` followed by `shift_e`, except that
`pawnshift_se` is a little faster, but will not work for square sets
containing squares on the 1st or 8th rank.
"""
function pawnshift_se(ss::SquareSet)::SquareSet
    SquareSet(ss.val << 9)
end


"""
    bishopattacks(blockers::SquareSet, s::Square)

The squares attacked by a bishop on `s`, with `blockers` being the occupied
squares.
"""
function bishopattacks(blockers::SquareSet, s::Square)::SquareSet
    SquareSet(bishopattacks(blockers.val, s.val))
end


"""
    rookattacks(blockers::SquareSet, s::Square)

The squares attacked by a rook on `s`, with `blockers` being the occupied
squares.
"""
function rookattacks(blockers::SquareSet, s::Square)::SquareSet
    SquareSet(rookattacks(blockers.val, s.val))
end


"""
    queenattacks(blockers::SquareSet, s::Square)

The squares attacked by a queen on `s`, with `blockers` being the occupied
squares.
"""
function queenattacks(blockers::SquareSet, s::Square)::SquareSet
    bishopattacks(blockers, s) ∪ rookattacks(blockers, s)
end


function computestepattacks(s, deltas)
    foldl((acc, d) -> distance(s, s + d) ≤ 2 ? acc + (s + d) : acc,
          deltas,
          init = SS_EMPTY)
end


function computeknightattacks(s::Square)::SquareSet
    computestepattacks(s, [2 * DELTA_N + DELTA_E, 2 * DELTA_N + DELTA_W,
                           DELTA_N + 2 * DELTA_E, DELTA_N + 2 * DELTA_W,
                           DELTA_S + 2 * DELTA_E, DELTA_S + 2 * DELTA_W,
                           2 * DELTA_S + DELTA_E, 2 * DELTA_S + DELTA_W])
end


function computekingattacks(s::Square)::SquareSet
    computestepattacks(s, [DELTA_NE, DELTA_N, DELTA_NW, DELTA_E,
                           DELTA_W, DELTA_SE, DELTA_S, DELTA_SW])
end


function computewpattacks(s::Square)::SquareSet
    computestepattacks(s, [DELTA_NE, DELTA_NW])
end


function computebpattacks(s::Square)::SquareSet
    computestepattacks(s, [DELTA_SE, DELTA_SW])
end


const N_ATTACKS = @SVector [computeknightattacks(Square(i)) for i in 1:64]
const K_ATTACKS = @SVector [computekingattacks(Square(i)) for i in 1:64]
const WP_ATTACKS = @SVector [computewpattacks(Square(i)) for i in 1:64]
const BP_ATTACKS = @SVector [computebpattacks(Square(i)) for i in 1:64]


"""
    knightattacks(s::Square)

The set of squares attacked by a knight on the square `s`.
"""
function knightattacks(s::Square)::SquareSet
    @inbounds N_ATTACKS[s.val]
end


"""
    kingattacks(s::square)

the set of squares attacked by a king on the square `s`.
"""
function kingattacks(s::Square)::SquareSet
    @inbounds K_ATTACKS[s.val]
end


"""
    pawnttacks(c::PieceColor, s::square)

the set of squares attacked by a pawn of color `c` on the square `s`.
"""
function pawnattacks(c::PieceColor, s::Square)::SquareSet
    if c == WHITE
        @inbounds WP_ATTACKS[s.val]
    else
        @inbounds BP_ATTACKS[s.val]
    end
end


const B_ATTACKS_EMPTY =
    @SVector [bishopattacks(SS_EMPTY, Square(i)) for i in 1:64]

const R_ATTACKS_EMPTY =
    @SVector [rookattacks(SS_EMPTY, Square(i)) for i in 1:64]

const Q_ATTACKS_EMPTY =
    @SVector [queenattacks(SS_EMPTY, Square(i)) for i in 1:64]


"""
    bishopattacksempty(s::Square)

The set of squares a bishop on `s` would attack on an otherwise empty board.
"""
function bishopattacksempty(s::Square)::SquareSet
    @inbounds B_ATTACKS_EMPTY[s.val]
end


"""
    rookattacksempty(s::Square)

The set of squares a rook on `s` would attack on an otherwise empty board.
"""
function rookattacksempty(s::Square)::SquareSet
    @inbounds R_ATTACKS_EMPTY[s.val]
end


"""
    queenattacksempty(s::Square)

The set of squares a queen on `s` would attack on an otherwise empty board.
"""
function queenattacksempty(s::Square)::SquareSet
    @inbounds Q_ATTACKS_EMPTY[s.val]
end


function computesquaresbetween(s1::Square, s2::Square)::SquareSet
    if s2 ∉ queenattacksempty(s1)
        SS_EMPTY
    else
        result = SS_EMPTY
        si1 = min(s1.val, s2.val)
        si2 = max(s1.val, s2.val)
        for si3 in (si1 + 1):(si2 - 1)
            s3 = Square(si3)
            ss = SquareSet(s3)
            if s2 ∈ queenattacksempty(s1) && s2 ∉ queenattacks(ss, s1)
                result += s3
            end
        end
        result
    end
end


const SQUARES_BETWEEN =
    [computesquaresbetween(Square(i), Square(j)) for i in 1:64, j in 1:64]


"""
    squaresbetween(s1::Square, s2::Square)

The set of squares on the line, file or diagonal between `s1` and `s2`.

When a queen on `s1` would attack `s2` on an otherwise empty board, this
function returns the set of squares where a piece would block the queen
on `s1` from attacking `s2`.

# Examples

```julia-repl
julia> squaresbetween(SQ_A4, SQ_D4) == SquareSet(SQ_B4, SQ_C4)
true

julia> squaresbetween(SQ_F7, SQ_A2)
SquareSet:
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  #  -  -  -
 -  -  -  #  -  -  -  -
 -  -  #  -  -  -  -  -
 -  #  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
```
"""
function squaresbetween(s1::Square, s2::Square)::SquareSet
    @inbounds SQUARES_BETWEEN[s1.val, s2.val]
end


function colorpprint(ss::SquareSet)
    for ri in 1:8
        r = SquareRank(ri)
        for fi in 1:8
            f = SquareFile(fi)
            bg = (ri + fi) % 2 == 0 ? 0x87CEFF : 0x6CA6CD
            #bg = (ri + fi) % 2 == 0 ? 0xCDA776 : 0xA0522D
            bg = (ri + fi) % 2 == 0 ? 0x8accc0 : 0x66b0a3
            if Square(f, r) ∈ ss
                print(Crayon(background = bg, foreground = 0xff1654), " * ")
            else
                print(Crayon(background = bg), "   ")
            end
        end
        println(Crayon(reset = true), "")
    end
end


"""
    pprint(ss::SquareSet)

Pretty-print a square set to the standard output.
"""
function pprint(ss::SquareSet; color = false)
    if color
        colorpprint(ss)
        return
    end
    for ri in 1:8
        r = SquareRank(ri)
        println("+---+---+---+---+---+---+---+---+")
        for fi in 1:8
            f = SquareFile(fi)
            if Square(f, r) ∈ ss
                print("| # ")
            else
                print("|   ")
            end
        end
        println("|")
    end
    println("+---+---+---+---+---+---+---+---+")
end
