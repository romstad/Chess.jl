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

export movefromsan, movetosan, variationtosan


"""
    movefromsan((b::Board, san::String))::Union{Move, Nothing}

Tries to read a move in Short Algebraic Notation.

Returns `nothing` if the provided string is an impossible or ambiguous move.

# Examples

```julia-repl
julia> movefromsan(b, "Nf3")
Move(g1f3)

julia> movefromsan(b, "???") == nothing
true
```
"""
function movefromsan(b::Board, san::String)::Union{Move, Nothing}
    ms = moves(b)

    # Castling moves
    if length(san) >= 5 && san[1:5] == "O-O-O"
        for m in ms
            if ptype(pieceon(b, from(m))) == KING && to(m) - from(m) == 2 * DELTA_W
                return m
            end
        end
        return nothing
    elseif length(san) >= 3 && san[1:3] == "O-O"
        for m in ms
            if ptype(pieceon(b, from(m))) == KING && to(m) - from(m) == 2 * DELTA_E
                return m
            end
        end
        return nothing
    end

    # Normal moves
    s = replace(san, r"\+|x|-|=|#" => "")
    left = 1
    right = length(s)
    pt = PIECE_TYPE_NONE
    ff = nothing
    fr = nothing
    f = nothing
    t = nothing

    # Promotion
    prom = piecetypefromchar(s[right])
    if prom != nothing
        right -= 1
    end

    # Moving piece
    if left < right
        if isuppercase(s[left])
            pt = piecetypefromchar(s[left])
            if pt == nothing
                pt = PAWN
            end
            left += 1
        else
            pt = PAWN
        end
    end

    # Destination square
    if left < right
        #t = squarefromstring(s[end - 1:end])
        t = squarefromstring(s[right - 1:right])
        right -= 2
    else
        return nothing
    end

    # Source square file/rank
    if left <= right
        ff = filefromchar(s[left])
        if ff != nothing
            left += 1
        end
        fr = rankfromchar(s[left])
    end

    # Look for matching move
    result = nothing
    matches = 0
    for m in ms
        match = true
        if ptype(pieceon(b, from(m))) != pt
            match = false
        elseif to(m) != t
            match = false
        elseif prom != nothing && prom != promotion(m)
            match = false
        elseif prom == nothing && ispromotion(m)
            match = false
        elseif ff != nothing && ff != file(from(m))
            match = false
        elseif fr != nothing && fr != rank(from(m))
            match = false
        end
        if match
            result = m
            matches += 1
        end
    end

    matches == 1 ? result : nothing
end


"""
    function movetosan(b::Board, m::Move)

Converts a move to a string in short algebraic notation.

# Examples
```julia-repl
julia> b = startboard();

julia> movetosan(b, Move(SQ_D2, SQ_D4))
"d4"
```
"""
function movetosan(b::Board, m::Move)::String
    f = from(m)
    t = to(m)
    pt = ptype(pieceon(b, f))
    result = IOBuffer()

    # Castling
    if pt == KING && t - f == 2 * DELTA_W
        write(result, "O-O-O")
    elseif pt == KING && t - f == 2 * DELTA_E
        write(result, "O-O")
    elseif pt == PAWN
        if file(f) != file(t) # Capture
            write(result, tochar(file(f)), 'x')
        end
        write(result, tostring(t))
        if ispromotion(m)
            write(result, '=', uppercase(tochar(promotion(m))))
        end
    else
        write(result, uppercase(tochar(pt)))
        ms = filter(m -> to(m) == t && ptype(pieceon(b, from(m))) == pt,
                    collect(moves(b)))
        if length(ms) > 1
            # Several moves, need disambiguation character(s)
            samefilecount = 0
            samerankcount = 0
            for m in ms
                if file(from(m)) == file(f)
                    samefilecount += 1
                end
                if rank(from(m)) == rank(f)
                    samerankcount += 1
                end
            end
            if samefilecount == 1
                write(result, tochar(file(f)))
            elseif samerankcount == 1
                write(result, tochar(rank(f)))
            else
                write(result, tostring(f))
            end
        end

        # Capture?
        if pieceon(b, t) != EMPTY
            write(result, 'x')
        end

        # Destination square
        write(result, tostring(t))
    end

    # Check/Checkmate?
    u = domove!(b, m)
    check = ischeck(b)
    mate = ischeckmate(b)
    undomove!(b, u)
    if mate
        write(result, '#')
    elseif check
        write(result, '+')
    end

    String(take!(result))
end


"""
    variationtosan(board::Board, v::Vector{Move};
                   startply=1, movenumbers=true)::String

Converts a variation to a string in short algebraic notation.

The vector of moves `v` should be a sequence of legal moves from the board
position. If `movenumbers` is `true`, move numbers will be included in the
string. The moves are numbered from 1, unless some other variable is supplied
through the `startply` parameter.

# Examples
```julia-repl
julia> b = startboard();

julia> variationtosan(b, map(movefromstring, ["e2e4", "e7e5", "g1f3", "b8c6"]))
"1. e4 e5 2. Nf3 Nc6"
```
"""
function variationtosan(board::Board, v::Vector{Move};
                        startply=1, movenumbers=true)::String
    result = IOBuffer()
    b = deepcopy(board)
    ply = startply
    if movenumbers && sidetomove(b) == BLACK
        write(result, string(div(startply, 2)))
        write(result, "... ")
    end
    for m ∈ v
        if movenumbers && sidetomove(b) == WHITE
            write(result, string(1 + div(ply, 2)))
            write(result, ". ")
        end
        write(result, movetosan(b, m))
        write(result, " ")
        ply += 1
        domove!(b, m)
    end
    rstrip(String(take!(result)))
end


"""
    variationtosan(g::SimpleGame, v::Vector{Move}; movenumbers=true)::String
    variationtosan(g::Game, v::Vector{Move}; movenumbers=true)::String

Converts a variation to a string in short algebraic notation.

The vector of moves `v` should be a sequence of legal moves from the current
board position of the game. If `movenumbers` is `true`, move numbers will be
included in the string.
# Examples
```julia-repl
julia> g = Game();

julia> domoves!(g, "d4", "Nf6", "c4", "e6", "Nf3");

julia> variationtosan(g, map(movefromstring, ["f8b4", "c1d2", "d8e7"]))
"3... Bb4+ 4. Bd2 Qe7"
```
"""
function variationtosan(g::SimpleGame, v::Vector{Move}; movenumbers=true)::String
    variationtosan(board(g), v, movenumbers = movenumbers, startply = ply(g))
end

function variationtosan(g::Game, v::Vector{Move}; movenumbers=true)::String
    variationtosan(board(g), v, movenumbers = movenumbers, startply = ply(g))
end
