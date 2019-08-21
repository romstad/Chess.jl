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

@test coloropp(WHITE) == BLACK
@test coloropp(BLACK) == WHITE

@test colorfromchar('w') == WHITE
@test colorfromchar('b') == BLACK
@test colorfromchar('?') == nothing

@test tochar(WHITE) == 'w'
@test tochar(BLACK) == 'b'

@test piecetypefromchar('p') == PAWN
@test piecetypefromchar('P') == PAWN
@test piecetypefromchar('n') == KNIGHT
@test piecetypefromchar('N') == KNIGHT
@test piecetypefromchar('b') == BISHOP
@test piecetypefromchar('B') == BISHOP
@test piecetypefromchar('r') == ROOK
@test piecetypefromchar('R') == ROOK
@test piecetypefromchar('q') == QUEEN
@test piecetypefromchar('Q') == QUEEN
@test piecetypefromchar('k') == KING
@test piecetypefromchar('K') == KING

@test tochar(PAWN, false) == 'p'
@test tochar(PAWN, true) == 'P'
@test tochar(KNIGHT, false) == 'n'
@test tochar(KNIGHT, true) == 'N'
@test tochar(BISHOP, false) == 'b'
@test tochar(BISHOP, true) == 'B'
@test tochar(ROOK, false) == 'r'
@test tochar(ROOK, true) == 'R'
@test tochar(QUEEN, false) == 'q'
@test tochar(QUEEN, true) == 'Q'
@test tochar(KING, false) == 'k'
@test tochar(KING, true) == 'K'

const ALL_COLORS = [WHITE, BLACK]
const ALL_PIECE_TYPES = [PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING]

for t in ALL_PIECE_TYPES
    @test piecetypefromchar(tochar(t)) == t
end

for c in ALL_COLORS
    for t in ALL_PIECE_TYPES
        p = Piece(c, t)
        @test c == pcolor(p)
        @test t == ptype(p)
    end
end

const ALL_PIECES = [PIECE_WP, PIECE_WN, PIECE_WB, PIECE_WR, PIECE_WQ, PIECE_WK,
                    PIECE_BP, PIECE_BN, PIECE_BB, PIECE_BR, PIECE_BQ, PIECE_BK]

for p in ALL_PIECES
    @test p == Piece(pcolor(p), ptype(p))
    @test p == piecefromchar(tochar(p))
end


@test !isslider(PIECE_WP)
@test !isslider(PIECE_WN)
@test isslider(PIECE_WB)
@test isslider(PIECE_WR)
@test isslider(PIECE_WQ)
@test !isslider(PIECE_WK)
@test !isslider(PIECE_BP)
@test !isslider(PIECE_BN)
@test isslider(PIECE_BB)
@test isslider(PIECE_BR)
@test isslider(PIECE_BQ)
@test !isslider(PIECE_BK)
