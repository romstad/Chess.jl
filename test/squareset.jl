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

@test SS_FILE_D ∩ SS_RANK_3 == SquareSet(SQ_D3)

@test SS_FILE_D ∪ SS_RANK_3 ==
    SquareSet(SQ_D1, SQ_D2, SQ_D3, SQ_D4, SQ_D5, SQ_D6, SQ_D7, SQ_D8,
              SQ_A3, SQ_B3, SQ_C3, SQ_D3, SQ_E3, SQ_F3, SQ_G3, SQ_H3)

@test SS_FILE_D - SS_RANK_3 ==
    SquareSet(SQ_D1, SQ_D2, SQ_D4, SQ_D5, SQ_D6, SQ_D7, SQ_D8)

@test SS_RANK_5 - SQ_E5 ==
    SquareSet(SQ_A5, SQ_B5, SQ_C5, SQ_D5, SQ_F5, SQ_G5, SQ_H5)

@test SS_RANK_5 - SQ_E6 == SS_RANK_5

@test SS_RANK_5 + SQ_E6 ==
    SquareSet(SQ_A5, SQ_B5, SQ_C5, SQ_D5, SQ_E5, SQ_F5, SQ_G5, SQ_H5, SQ_E6)

@test issingleton(SquareSet(SQ_D5))
@test !issingleton(SquareSet(SQ_D5, SQ_C5))
@test !issingleton(SS_EMPTY)

@test issubset(SquareSet(SQ_E5, SQ_E3, SQ_E1), SS_FILE_E)
@test !issubset(SquareSet(SQ_E5, SQ_E3, SQ_D1), SS_FILE_E)
@test issubset(SS_EMPTY, SquareSet(SQ_C2))

for s in ALL_SQUARES
    @test s ∈ filesquares(file(s))
    @test s ∈ ranksquares(rank(s))
end

@test squarecount(SS_FILE_A ∪ SS_RANK_4) == 15
@test squarecount(SS_EMPTY) == 0

@test shift_n(SS_RANK_2) == SS_RANK_3
@test shift_n(SquareSet(SQ_D3, SQ_E4, SQ_F8)) == SquareSet(SQ_D4, SQ_E5)
@test shift_s(SS_RANK_2) == SS_RANK_1
@test shift_s(SquareSet(SQ_C3, SQ_D2, SQ_E1)) == SquareSet(SQ_C2, SQ_D1)
@test shift_e(SS_FILE_F) == SS_FILE_G
@test shift_e(SquareSet(SQ_F5, SQ_G6, SQ_H7)) == SquareSet(SQ_G5, SQ_H6)
@test shift_w(SS_FILE_C) == SS_FILE_B
@test shift_w(SquareSet(SQ_C5, SQ_B6, SQ_A7)) == SquareSet(SQ_B5, SQ_A6)

const BLOCKERS = SquareSet(SQ_B2, SQ_E3, SQ_A5, SQ_E7)

@test bishopattacks(BLOCKERS, SQ_E5) ==
    SquareSet(SQ_B2, SQ_C3, SQ_D4, SQ_F6, SQ_G7, SQ_H8, SQ_H2, SQ_G3, SQ_F4,
              SQ_D6, SQ_C7, SQ_B8)

@test rookattacks(BLOCKERS, SQ_E5) ==
    SquareSet(SQ_E3, SQ_E4, SQ_E6, SQ_E7, SQ_A5, SQ_B5, SQ_C5, SQ_D5, SQ_F5,
              SQ_G5, SQ_H5)

@test queenattacks(BLOCKERS, SQ_E5) ==
    bishopattacks(BLOCKERS, SQ_E5) ∪ rookattacks(BLOCKERS, SQ_E5)

@test knightattacks(SQ_E5) ==
    SquareSet(SQ_D3, SQ_F3, SQ_C4, SQ_G4, SQ_C6, SQ_G6, SQ_D7, SQ_F7)

@test kingattacks(SQ_E5) ==
    SquareSet(SQ_D4, SQ_E4, SQ_F4, SQ_D5, SQ_F5, SQ_D6, SQ_E6, SQ_F6)

@test pawnattacks(WHITE, SQ_E5) == SquareSet(SQ_D6, SQ_F6)
@test pawnattacks(BLACK, SQ_E5) == SquareSet(SQ_D4, SQ_F4)

@test squaresbetween(SQ_A4, SQ_D4) == SquareSet(SQ_B4, SQ_C4)

@test squaresbetween(SQ_F7, SQ_A2) == SquareSet(SQ_B3, SQ_C4, SQ_D5, SQ_E6)
