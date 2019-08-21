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

const ALL_FILES = [FILE_A, FILE_B, FILE_C, FILE_D, FILE_E, FILE_F, FILE_G, FILE_H]
const ALL_RANKS = [RANK_1, RANK_2, RANK_3, RANK_4, RANK_5, RANK_6, RANK_7, RANK_8]

for f in ALL_FILES
    @test f == filefromchar(tochar(f))
end

for r in ALL_RANKS
    @test r == rankfromchar(tochar(r))
end

const ALL_SQUARES = [Square(f, r) for f in ALL_FILES, r in ALL_RANKS]

for s in ALL_SQUARES
    @test s == Square(file(s), rank(s))
    @test s == squarefromstring(tostring(s))
end

@test SQ_D5 - SQ_D6 == DELTA_S
@test SQ_D5 - SQ_D4 == DELTA_N
@test SQ_D5 - SQ_E5 == DELTA_W
@test SQ_D5 - SQ_C5 == DELTA_E
@test SQ_D5 - SQ_E4 == DELTA_NW
@test SQ_D5 - SQ_C4 == DELTA_NE
@test SQ_D5 - SQ_E6 == DELTA_SW
@test SQ_D5 - SQ_C6 == DELTA_SE
