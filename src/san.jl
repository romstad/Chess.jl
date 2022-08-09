export movefromsan, movetosan, variationtosan


function islongcastle(san)
    @views (length(san) ≥ 5 && (san[1:5] == "O-O-O" || san[1:5] == "0-0-0")) ||
        (length(san) ≥ 3 && (san[1:3] == "OOO" || san[1:3] == "000"))
end


function isshortcastle(san)
    @views (length(san) ≥ 3 && (san[1:3] == "O-O" || san[1:3] == "0-0")) ||
        (length(san) ≥ 2 && (san[1:2] == "OO" || san[1:2] == "00"))
end


"""
    movefromsan(b::Board, san::AbstractString, movelist::MoveList)::Union{Move,Nothing}
    movefromsan(b::Board, san::AbstractString)::Union{Move,Nothing}

Tries to read a move in Short Algebraic Notation.

Returns `nothing` if the provided string is an impossible or ambiguous move.

This internally calls `moves`, which can be supplied a pre-allocated `MoveList`
in order to save time/space due to unnecessary allocations. If provided, the
`movelist` parameter will be passed to `moves`. It is up to the caller to
ensure that `movelist` has sufficient capacity.

# Examples

```julia-repl
julia> movefromsan(b, "Nf3")
Move(g1f3)

julia> movelist = MoveList(200)
0-element MoveList

julia> movefromsan(b, "Nf3", movelist)
Move(g1f3)

julia> movefromsan(b, "???") == nothing
true
```
"""
movefromsan(b::Board, san::AbstractString)::Union{Move,Nothing} = movefromsan(b, san, MoveList(200))

function movefromsan(b::Board, san::AbstractString, movelist::MoveList)::Union{Move,Nothing}
    recycle!(movelist)
    ms = moves(b, movelist)

    # Castling moves
    if islongcastle(san)
        for m in ms
            if moveislongcastle(b, m)
                return m
            end
        end
        return nothing
    elseif isshortcastle(san)
        for m in ms
            if moveisshortcastle(b, m)
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
    if !isnothing(prom)
        right -= 1
    end

    # Moving piece
    if left < right
        if isuppercase(s[left])
            pt = piecetypefromchar(s[left])
            if isnothing(pt)
                pt = PAWN
            end
            left += 1
        else
            pt = PAWN
        end
    end

    # Destination square
    if left < right
        @views t = squarefromstring(s[right-1:right])
        right -= 2
    else
        return nothing
    end

    # Source square file/rank
    if left <= right
        ff = filefromchar(s[left])
        if !isnothing(ff)
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
        elseif !isnothing(prom) && prom != promotion(m)
            match = false
        elseif isnothing(prom) && ispromotion(m)
            match = false
        elseif !isnothing(ff) && ff != file(from(m))
            match = false
        elseif !isnothing(fr) && fr != rank(from(m))
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
    if m == MOVE_NULL
        return "0000"
    end

    f = from(m)
    t = to(m)
    pt = ptype(pieceon(b, f))
    result = IOBuffer()

    # Castling
    if moveislongcastle(b, m)
        write(result, "O-O-O")
    elseif moveiscastle(b, m)
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
        ms = filter(m -> to(m) == t && ptype(pieceon(b, from(m))) == pt, collect(moves(b)))
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
function variationtosan(
    board::Board,
    v::Vector{Move};
    startply = 1,
    movenumbers = true,
)::String
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
function variationtosan(g::SimpleGame, v::Vector{Move}; movenumbers = true)::String
    variationtosan(board(g), v, movenumbers = movenumbers, startply = ply(g))
end

function variationtosan(g::Game, v::Vector{Move}; movenumbers = true)::String
    variationtosan(board(g), v, movenumbers = movenumbers, startply = ply(g))
end


function formatmoves(g::SimpleGame, currentnodeindicator = nothing)::String
    result = IOBuffer()
    ply = g.ply
    g = deepcopy(g)
    tobeginning!(g)
    while !isatend(g)
        if !isnothing(currentnodeindicator) && ply == g.ply
            write(result, currentnodeindicator)
            write(result, " ")
        end
        m = g.history[g.ply].move
        if sidetomove(g.board) == WHITE
            write(result, string(1 + div(g.ply, 2)), ". ")
        end
        write(result, movetosan(g.board, m), " ")
        forward!(g)
    end
    if !isnothing(currentnodeindicator) && ply == g.ply
        write(result, currentnodeindicator)
    end
    String(take!(result))
end


function formatmoves(g::Game, currentnodeindicator = nothing)

    function formatchild(buffer, node, child, movenum, blackmovenum)
        # Pre-comment
        if !isnothing(precomment(child))
            write(buffer, "{", precomment(child), "} ")
        end

        # Move number, if white to move or at the beginning of the game.
        if sidetomove(node.board) == WHITE
            write(buffer, string(movenum ÷ 2 + 1), ". ")
        elseif blackmovenum || isnothing(node.parent)
            write(buffer, string(movenum ÷ 2 + 1), "... ")
        end

        # Move in SAN notation
        write(buffer, movetosan(node.board, lastmove(child.board)))

        # Numeric Annotation Glyph
        if !isnothing(Chess.nag(child))
            write(buffer, " \$", string(Chess.nag(child)))
        end

        # Post-comment
        if !isnothing(Chess.comment(child))
            write(buffer, " {", Chess.comment(child), "}")
        end
    end

    function formatvariation(buffer, node, movenum)
        if !isempty(node.children)
            # Write current node indicator
            if !isnothing(currentnodeindicator) && node == g.node
                write(buffer, currentnodeindicator)
                write(buffer, " ")
            end

            child = first(node.children)
            formatchild(buffer, node, child, movenum, false)

            if !isleaf(child) || length(node.children) > 1
                write(buffer, " ")
            end

            # Recursive annotation variations
            for child in node.children[2:end]
                # Variation start
                write(buffer, "(")

                formatchild(buffer, node, child, movenum, true)

                # Continuation of variation
                if !isempty(child.children)
                    write(buffer, " ")
                    formatvariation(buffer, child, movenum + 1)
                elseif !isnothing(currentnodeindicator) && child == g.node
                    write(buffer, " ")
                    write(buffer, currentnodeindicator)
                end

                # Variation end
                write(buffer, ")")

                # If this is not the last variation, insert a space before the
                # next
                if child ≠ node.children[end]
                    write(buffer, " ")
                end
            end

            # Continuation of variation
            if length(node.children) > 1 && !isempty(child.children)
                write(buffer, " ")
            end
            formatvariation(buffer, child, movenum + 1)
        elseif !isnothing(currentnodeindicator) && node == g.node
            write(buffer, " ")
            write(buffer, currentnodeindicator)
        end
    end

    result = IOBuffer()
    formatvariation(result, g.root, sidetomove(g.root.board) == WHITE ? 0 : 1)
    write(result, " ")

    String(take!(result))
end
