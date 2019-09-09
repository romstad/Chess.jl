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

export Move

export from, ispromotion, movefromstring, promotion, to, tostring

"""
    Move

Type representing a chess move.

A `Move` value is usually obtained by asking a chess board for moves, or by
parsing a move string in UCI or SAN format (in the latter case, we also need
a board).
"""
struct Move
    val::Int
end


Base.show(io::IO, m::Move) = print(io, "Move($(tostring(m)))")


"""
    Move(from::Square, to::Square)

Low-level constructor for creating a move with the given `from` and `to`
squares.
"""
function Move(from::Square, to::Square)
    Move((to.val - 1) | ((from.val - 1) << 6))
end


"""
    Move(from::Square, to::Square, promotion::PieceType)

Low-level constructor for creating a move with the given `from` and `to`
squares and promotion piece type.
"""
function Move(from::Square, to::Square, promotion::PieceType)
    Move((to.val - 1) | ((from.val - 1) << 6) | (promotion.val << 12))
end


"""
    from(m::Move)

The source square of a move.

# Examples

```julia-repl
julia> Move(SQ_D2, SQ_D4)
Move(d2d4)

julia> from(Move(SQ_G1, SQ_F3))
SQ_G1

julia> from(Move(SQ_C7, SQ_C8, QUEEN))
SQ_C7
```
"""
function from(m::Move)::Square
    Square(((m.val >> 6) & 63) + 1)
end


"""
    to(m::Move)

The destination square of a move.

# Examples

```julia-repl
julia> to(Move(SQ_G1, SQ_F3))
SQ_F3

julia> to(Move(SQ_C7, SQ_C8, QUEEN))
SQ_C8
true
```
"""
function to(m::Move)::Square
    Square((m.val & 63) + 1)
end


"""
    ispromotion(m::Move)

Determine whether a move is a promotion move.

# Examples

```julia-repl
julia> ispromotion(Move(SQ_G1, SQ_F3))
false

julia> ispromotion(Move(SQ_C7, SQ_C8, QUEEN))
true
```
"""
function ispromotion(m::Move)::Bool
    m.val & (7 << 12) ≠ 0
end


"""
    promotion(m::Move)

Find the promotion piece type of a move.

Use this function only after first using `ispromotion` to determine whether
the move is a promotion move at all.

# Examples

```julia-repl
julia> promotion(Move(SQ_C7, SQ_C8, QUEEN))
QUEEN

julia> promotion(Move(SQ_B2, SQ_B1, KNIGHT))
KNIGHT
```
"""
function promotion(m::Move)::PieceType
    PieceType((m.val >> 12) & 7)
end


"""
    tostring(m::Move)

Convert a move to a string in UCI notation.

# Examples

```julia-repl
julia> tostring(Move(SQ_G1, SQ_F3))
"g1f3"

julia> tostring(Move(SQ_E2, SQ_E1, KNIGHT))
"e2e1n"
```
"""
function tostring(m::Move)::String
    tostring(from(m)) * tostring(to(m)) * (ispromotion(m) ? tochar(promotion(m)) : "")
end


"""
    movefromstring(s::String)

Convert a UCI move string to a move.

Returns `nothing` if the input string is not a valid UCI move.

# Examples

```julia-repl
julia> movefromstring("d2d4") == Move(SQ_D2, SQ_D4)
true

julia> movefromstring("h7h8q") == Move(SQ_H7, SQ_H8, QUEEN)
true

julia> movefromstring("f7f9") == nothing
true

julia> movefromstring("") == nothing
true
```
"""
function movefromstring(s::String)::Union{Move, Nothing}
    if length(s) < 4
        nothing
    else
        f = squarefromstring(s[1:2])
        t = squarefromstring(s[3:4])
        if f ≠ nothing && t ≠ nothing
            p = piecetypefromchar(get(s, 5, '?'))
            if p == nothing
                Move(f, t)
            else
                Move(f, t, p)
            end
        else
            nothing
        end
    end
end
