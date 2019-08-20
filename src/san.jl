export dosanmove, dosanmove!, dosanmoves, dosanmoves!, movefromsan, movetosan


"""
    movefromsan((b::Board, san::String))::Union{Move, Nothing}

Tries to read a move in Short Algebraic Notation.

Returns `Nothing` if the provided string is an impossible or ambiguous move.
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
    dosanmove(b::Board, sanmove::String)::Board

Do the move represented by the SAN string, and return the new board.

If the `sanmove` string does not represent an unambiguous legal move, the
function throws an exception.
"""
function dosanmove(b::Board, sanmove::String)::Board
    m = movefromsan(b, sanmove)
    if m == nothing
        throw("Illegal or ambiguous move: $sanmove")
    else
        domove(b, m)
    end
end


"""
    dosanmove!(b::Board, sanmove::String

Destructively update the board `b` the move represented by the SAN string.

The function returns an `UndoInfo` object that can be used to take back the
move using `undomove!`.

If the `sanmove` string does not represent an unambiguous legal move, the board
is not updated, and an exception is thrown.
"""
function dosanmove!(b::Board, sanmove::String)::UndoInfo
    m = movefromsan(b, sanmove)
    if m == nothing
        throw("Illegal or ambiguous move: $sanmove")
    else
        domove!(b, m)
    end
end


"""
    dosanmoves!(b::Board, sanmoves::Vararg{String})::Board

Destructively update the board `b` with the provided SAN moves.

If one of the SAN strings is not an unambiguous legal move, the function throws
an exception.
"""
function dosanmoves!(b, sanmoves::Vararg{String})::Board
    for sanmove in sanmoves
        dosanmove!(b, sanmove)
    end
    b
end


"""
    dosanmoves(b::Board, sanmoves::Vararg{String})::Board

Do a sequence of SAN moves from the board, and return the resulting board.

If one of the SAN strings is not an unambiguous legal move, the function throws
an exception.
"""
function dosanmoves(b::Board, sanmoves::Vararg{String})::Board
    b = deepcopy(b)
    dosanmoves!(b, sanmoves...)
end
