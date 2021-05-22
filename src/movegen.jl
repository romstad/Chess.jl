export moveispseudo,
    pseudocaptures, pseudochecks, pseudoislegal, pseudomoves, pseudoquiets, pseudoevasions


function is_attacked_after_move(b::Board, s::Square, m::Move)::Bool
    f = from(m)
    t = to(m)
    us = sidetomove(b)
    theirs = pieces(b, -us)

    # Remove captured piece, if any:
    if pieceon(b, t) != EMPTY
        theirs -= t
    elseif moveisep(b, m)
        theirs -= t - (us == WHITE ? DELTA_N : DELTA_S)
    end

    # Test for attacks by non-sliding pieces:
    if !isempty(pawnattacks(us, s) ∩ pawns(b) ∩ theirs)
        return true
    end
    if !isempty(knightattacks(s) ∩ knights(b) ∩ theirs)
        return true
    end
    if !isempty(kingattacks(s) ∩ kings(b) ∩ theirs)
        return true
    end

    # Test for attacks by sliding pieces:
    ours = pieces(b, us) - f + t
    occ = ours ∪ theirs

    if !isempty(bishopattacks(occ, s) ∩ bishoplike(b) ∩ theirs)
        return true
    end
    if !isempty(rookattacks(occ, s) ∩ rooklike(b) ∩ theirs)
        return true
    end

    # Square not attacked!
    return false
end


"""
    moveispseudo(b::Board, m::Move)

Test whether the move `m` is pseudo-legal.

This means that the move `m` is legal except for possibly leaving the king in
check.

# Examples
```julia-repl
julia> b = @startboard e4 c5 Nf3 d6 Bb5;

julia> moveispseudo(b, Move(SQ_G8, SQ_F6))
true

julia> moveispseudo(b, Move(SQ_B8, SQ_C6))
true

julia> moveispseudo(b, Move(SQ_G8, SQ_G6))
false
```
"""
function moveispseudo(b::Board, m::Move)::Bool
    f = from(m)
    t = to(m)
    us = sidetomove(b)
    them = -us

    # The piece on the source square must belong to the current side to move:
    pcolor(pieceon(b, f)) == us || return false

    # The piece on the destination square cannot belong to the current side to
    # move. TODO: Chess960 castling
    pcolor(pieceon(b, t)) ≠ us || return false

    p = pieceon(b, f)
    Δ = t - f

    if ptype(p) == PAWN
        # If the destination square is on the 1st or 8th rank, the move must be
        # a promotion:
        if t ∈ SS_RANK_1 ∪ SS_RANK_8 && !ispromotion(m)
            return false
        end

        # Is this a normal pawn push?
        push = us == WHITE ? DELTA_N : DELTA_S
        if Δ == push
            return pieceon(b, t) == EMPTY
        end

        # Is this a double pawn push?
        if Δ == 2 * push && f ∈ SS_RANK_2 ∪ SS_RANK_7
            return pieceon(b, t) == EMPTY && pieceon(b, f + push) == EMPTY
        end

        # Is this a capture?
        if t ∈ pawnattacks(us, f)
            return pcolor(pieceon(b, t)) == them || t == epsquare(b)
        end

        # Neither a pawn push nor a pawn capture -- cannot be a legal move:
        return false
    else # Non-pawn move
        # Non-pawn  moves cannot be promotions:
        ispromotion(m) && return false

        pt = ptype(p)

        if pt == KNIGHT
            return t ∈ knightattacks(f)
        elseif pt == BISHOP
            return t ∈ bishopattacks(b, f)
        elseif pt == ROOK
            return t ∈ rookattacks(b, f)
        elseif pt == QUEEN
            return t ∈ queenattacks(b, f)
        elseif pt == KING
            if t ∈ kingattacks(f)
                return true
            elseif Δ == 2 * DELTA_E
                # Kingside castling
                return cancastlekingside(b, us) &&
                       !ischeck(b) &&
                       pieceon(b, f + DELTA_E) == EMPTY &&
                       pieceon(b, t) == EMPTY
            elseif Δ == 2 * DELTA_W
                # Queenside castling
                return cancastlequeenside(b, us) &&
                       !ischeck(b) &&
                       pieceon(b, f + DELTA_W) == EMPTY &&
                       pieceon(b, t) == EMPTY &&
                       pieceon(b, f + 3 * DELTA_W) == EMPTY
            else
                return false
            end
        else
            return false
        end
    end
end


"""
    pseudoislegal(b::Board, m::Move)::Bool

Tests whether the pseudo-legal move `m` is legal.

# Examples
```julia-repl
julia> b = @startboard e4 c5 Nf3 d6 Bb5;

julia> pseudoislegal(b, Move(SQ_C8, SQ_D7))
true

julia> pseudoislegal(b, Move(SQ_G8, SQ_F6))
false
```
"""
function pseudoislegal(b::Board, m::Move)::Bool
    f = from(m)
    t = to(m)
    us = sidetomove(b)
    them = -us
    ksq = kingsquare(b, us)
    check = ischeck(b)

    # If we're not in check, any non-king, non-en-passant move of a non-pinned
    # piece is legal:
    if !check && f ∉ pinned(b) && f ≠ ksq && !moveisep(b, m)
        return true
    end

    # Castling moves are legal if we're not in check and both the destination
    # square and the square we're passing over are not under attack by the
    # opponent:
    if moveisshortcastle(b, m)
        return !check && !isattacked(b, f + DELTA_E, them) && !isattacked(b, t, them)
    end
    if moveislongcastle(b, m)
        return !check && !isattacked(b, f + DELTA_W, them) && !isattacked(b, t, them)
    end

    # For king moves, make sure the king is not under attack on the new square:
    if f == ksq
        return !is_attacked_after_move(b, t, m)
    end

    # When in check or when making an en passant capture, check in a slow way
    # that the move does not leave the king in check:
    if check || moveisep(b, m)
        return !is_attacked_after_move(b, ksq, m)
    end

    # If we are here, we are not in check, and we're moving a pinned piece. The
    # move is legal if it's moving along the ray towards/away from the friendly
    # king.
    return t ∈ squaresbetween(ksq, f) || f ∈ squaresbetween(ksq, t)
end


function addmove!(list::MoveList, f::Square, t::Square)
    push!(list, Move(f, t))
end

function addpromotions!(list::MoveList, f::Square, t::Square)
    for p ∈ [QUEEN, ROOK, BISHOP, KNIGHT]
        push!(list, Move(f, t, p))
    end
end

function addpawnmoves!(list::MoveList, target::SquareSet, Δ::SquareDelta)
    for t ∈ target
        addmove!(list, t - Δ, t)
    end
end

function addpawnpromotions!(list::MoveList, target::SquareSet, Δ::SquareDelta)
    for t ∈ target
        addpromotions!(list, t - Δ, t)
    end
end

function knight_pseudomoves(b::Board, list::MoveList, src::SquareSet, target::SquareSet)
    for f ∈ src
        for t ∈ knightattacks(f) ∩ target
            addmove!(list, f, t)
        end
    end
end

function bishop_pseudomoves(b::Board, list::MoveList, src::SquareSet, target::SquareSet)
    for f ∈ src
        for t ∈ bishopattacks(b, f) ∩ target
            addmove!(list, f, t)
        end
    end
end

function rook_pseudomoves(b::Board, list::MoveList, src::SquareSet, target::SquareSet)
    for f ∈ src
        for t ∈ rookattacks(b, f) ∩ target
            addmove!(list, f, t)
        end
    end
end

function queen_pseudomoves(b::Board, list::MoveList, src::SquareSet, target::SquareSet)
    for f ∈ src
        for t ∈ queenattacks(b, f) ∩ target
            addmove!(list, f, t)
        end
    end
end

function king_pseudomoves(b::Board, list::MoveList, src::SquareSet, target::SquareSet)
    for f ∈ src
        for t ∈ kingattacks(f) ∩ target
            addmove!(list, f, t)
        end
    end
end

function pawn_pseudocaptures(b::Board, list::MoveList)
    us = sidetomove(b)
    them = -us
    ps = pawns(b, us)

    if us == WHITE
        # Promotions (captures and non-captures)
        source1 = ps ∩ SS_RANK_7
        addpawnpromotions!(list, pawnshift_ne(source1) ∩ pieces(b, them), DELTA_NE)
        addpawnpromotions!(list, pawnshift_nw(source1) ∩ pieces(b, them), DELTA_NW)
        addpawnpromotions!(list, pawnshift_n(source1) ∩ emptysquares(b), DELTA_N)

        # Non-promotion captures
        source2 = ps ∩ -SS_RANK_7
        addpawnmoves!(list, pawnshift_ne(source2) ∩ pieces(b, them), DELTA_NE)
        addpawnmoves!(list, pawnshift_nw(source2) ∩ pieces(b, them), DELTA_NW)
    else
        # Promotions (captures and non-captures)
        source1 = ps ∩ SS_RANK_2
        addpawnpromotions!(list, pawnshift_se(source1) ∩ pieces(b, them), DELTA_SE)
        addpawnpromotions!(list, pawnshift_sw(source1) ∩ pieces(b, them), DELTA_SW)
        addpawnpromotions!(list, pawnshift_s(source1) ∩ emptysquares(b), DELTA_S)

        # Non-promotion captures
        source2 = ps ∩ -SS_RANK_2
        addpawnmoves!(list, pawnshift_se(source2) ∩ pieces(b, them), DELTA_SE)
        addpawnmoves!(list, pawnshift_sw(source2) ∩ pieces(b, them), DELTA_SW)
    end
end

function pawn_pseudopushes(b::Board, list::MoveList, target::SquareSet)
    us = sidetomove(b)
    ps = pawns(b, us)
    if us == WHITE
        source1 = ps ∩ -SS_RANK_7
        source2 = ps ∩ SS_RANK_2
        target1 = pawnshift_n(source1) ∩ emptysquares(b) ∩ target
        target2 =
            pawnshift_n(pawnshift_n(source2) ∩ emptysquares(b)) ∩ emptysquares(b) ∩ target
        addpawnmoves!(list, target1, DELTA_N)
        addpawnmoves!(list, target2, 2 * DELTA_N)
    else
        source1 = ps ∩ -SS_RANK_2
        source2 = ps ∩ SS_RANK_7
        target1 = pawnshift_s(source1) ∩ emptysquares(b) ∩ target
        target2 =
            pawnshift_s(pawnshift_s(source2) ∩ emptysquares(b)) ∩ emptysquares(b) ∩ target
        addpawnmoves!(list, target1, DELTA_S)
        addpawnmoves!(list, target2, 2 * DELTA_S)
    end
end


function pawn_promotion_pseudopushes(b::Board, list::MoveList, target::SquareSet)
    us = sidetomove(b)
    ps = pawns(b, us)
    if us == WHITE
        source = ps ∩ SS_RANK_7
        target = pawnshift_n(source) ∩ emptysquares(b) ∩ target
        addpawnpromotions!(list, target, DELTA_N)
    else
        source = ps ∩ SS_RANK_2
        target = pawnshift_s(source) ∩ emptysquares(b) ∩ target
        addpawnpromotions!(list, target, DELTA_N)
    end
end


function pseudo_ep_captures(b::Board, list::MoveList)
    us = sidetomove(b)
    if epsquare(b) != SQ_NONE
        for f ∈ pawnattacks(-us, epsquare(b)) ∩ pawns(b, us)
            addmove!(list, f, epsquare(b))
        end
    end
end


function pseudo_castles(b::Board, list::MoveList)
    us = sidetomove(b)
    ksq = kingsquare(b, us)
    if cancastlekingside(b, us)
        if isempty(squaresbetween(ksq, ksq + 3 * DELTA_E) ∩ occupiedsquares(b))
            addmove!(list, ksq, ksq + 2 * DELTA_E)
        end
    end
    if cancastlequeenside(b, us)
        if isempty(squaresbetween(ksq, ksq + 4 * DELTA_W) ∩ occupiedsquares(b))
            addmove!(list, ksq, ksq + 2 * DELTA_W)
        end
    end
end

function non_pawn_moves_to_target(b::Board, list::MoveList, target::SquareSet)
    us = sidetomove(b)
    knight_pseudomoves(b, list, knights(b, us) ∩ -pinned(b), target)
    bishop_pseudomoves(b, list, bishops(b, us), target)
    rook_pseudomoves(b, list, rooks(b, us), target)
    queen_pseudomoves(b, list, queens(b, us), target)
    king_pseudomoves(b, list, kings(b, us), target)
end

function pawn_discovered_checks(b::Board, list::MoveList, src::SquareSet)
    us = sidetomove(b)
    source = src ∩ pawns(b, us) ∩ -filesquares(file(kingsquare(b, -us)))
    push = us == WHITE ? DELTA_N : DELTA_S
    for f ∈ source
        if f + push ∉ (SS_RANK_1 ∪ SS_RANK_8) && pieceon(b, f + push) == EMPTY
            addmove!(list, f, f + push)
            if f ∈ SS_RANK_2 ∪ SS_RANK_7 && pieceon(b, f + 2 * push) == EMPTY
                addmove!(list, f, f + 2 * push)
            end
        end
    end
end

function pawn_plain_checks(b::Board, list::MoveList, src::SquareSet)
    us = sidetomove(b)
    ksq = kingsquare(b, -us)
    source = src ∩ pawns(b, us) ∩ adjacentfilesquares(ksq)
    push = us == WHITE ? DELTA_N : DELTA_S

    for f ∈ source
        if f + push ∉ (SS_RANK_1 ∪ SS_RANK_8) && pieceon(b, f + push) == EMPTY
            if ksq ∈ pawnattacks(us, f + push)
                addmove!(list, f, f + push)
            end
            if f ∈ (SS_RANK_2 ∪ SS_RANK_7) && pieceon(b, f + 2 * push) == EMPTY
                if ksq ∈ pawnattacks(us, f + 2 * push)
                    addmove!(list, f, f + 2 * push)
                end
            end
        end
    end
end

function discovered_checks(b::Board, list::MoveList, source::SquareSet)
    us = sidetomove(b)
    them = -us
    ksq = kingsquare(b, them)
    target = emptysquares(b)

    knight_pseudomoves(b, list, knights(b, us) ∩ source, target)
    bishop_pseudomoves(b, list, bishops(b, us) ∩ source, target)
    rook_pseudomoves(b, list, rooks(b, us) ∩ source, target)
    pawn_discovered_checks(b, list, source)
    for f ∈ kings(b, us) ∩ source
        for t ∈ kingattacks(f) ∩ target
            if t ∉ squaresbetween(f, ksq) && f ∉ squaresbetween(t, ksq)
                addmove!(list, f, t)
            end
        end
    end
end

function plain_checks(b::Board, list::MoveList, source::SquareSet)
    us = sidetomove(b)
    them = -us
    ksq = kingsquare(b, them)
    target = emptysquares(b)
    b_check_sqs = bishopattacks(b, ksq) ∩ target
    r_check_sqs = rookattacks(b, ksq) ∩ target
    q_check_sqs = b_check_sqs ∪ r_check_sqs

    knight_pseudomoves(b, list, knights(b, us) ∩ source, knightattacks(ksq) ∩ target)
    bishop_pseudomoves(b, list, bishops(b, us) ∩ source, b_check_sqs)
    rook_pseudomoves(b, list, rooks(b, us) ∩ source, r_check_sqs)
    queen_pseudomoves(b, list, queens(b, us) ∩ source, q_check_sqs)
    pawn_plain_checks(b, list, source)
end


"""
    pseudocaptures(b::Board, list::MoveList)

Generates all pseudo-legal captures and promotions.
"""
function pseudocaptures(b::Board, list::MoveList)
    target = pieces(b, -sidetomove(b))
    pawn_pseudocaptures(b, list)
    non_pawn_moves_to_target(b, list, target)
    pseudo_ep_captures(b, list)
end


"""
    pseudoquiets(b::Board, list::MoveList)

Generates all pseudo-legal quiet moves.

Captures and promotions will not be included.
"""
function pseudoquiets(b::Board, list::MoveList)
    target = emptysquares(b)
    pawn_pseudopushes(b, list, target)
    non_pawn_moves_to_target(b, list, target)
    pseudo_castles(b, list)
end


"""
    pseudomoves(b::Board, list::MoveList)

Generates all pseudo-legal moves.
"""
function pseudomoves(b::Board, list::MoveList)
    pseudocaptures(b, list)
    pseudoquiets(b, list)
end


"""
    pseudoevasions(b::Board, list::MoveList)

Generates pseudo-legal moves when in check.

Most obviously illegal moves are excluded.
"""
function pseudoevasions(b::Board, list::MoveList)
    us = sidetomove(b)

    # Generate all pseudo-legal moves for the king.
    king_pseudomoves(b, list, kings(b, us), -pieces(b, us))

    # Other moves are only possible if this is not a double check:
    if issingleton(b.checkers)
        ksq = kingsquare(b, us)
        chsq = first(b.checkers)
        target = squaresbetween(ksq, chsq) + chsq

        # Blocking pawn pushes:
        pawn_pseudopushes(b, list, target)
        pawn_promotion_pseudopushes(b, list, target)

        # Pawn captures of checking piece:
        for f ∈ pawnattacks(-us, chsq) ∩ pawns(b, us) ∩ -pinned(b)
            if chsq ∈ (SS_RANK_8 ∪ SS_RANK_1)
                addpromotions!(list, f, chsq)
            else
                addmove!(list, f, chsq)
            end
        end
        if chsq == epsquare(b) - (us == WHITE ? DELTA_N : DELTA_S)
            pseudo_ep_captures(b, list)
        end

        # Remaining pieces: Generate moves to target for non-pinned pieces.
        knight_pseudomoves(b, list, knights(b, us) ∩ -pinned(b), target)
        bishop_pseudomoves(b, list, bishops(b, us) ∩ -pinned(b), target)
        rook_pseudomoves(b, list, rooks(b, us) ∩ -pinned(b), target)
        queen_pseudomoves(b, list, queens(b, us) ∩ -pinned(b), target)
    end
end


"""
    pseudochecks(b::Board, list::MoveList)

Generates all pseudo-legal non-capturing checking moves.
"""
function pseudochecks(b::Board, list::MoveList)
    dc = discovered_check_candidates(b)
    discovered_checks(b, list, dc)
    plain_checks(b, list, pieces(b, sidetomove(b)) ∩ -dc)
end
