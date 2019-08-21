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

for f in ALL_SQUARES
    for t in ALL_SQUARES
        m = Move(f, t)
        @test from(m) == f
        @test to(m) == t
        @test !ispromotion(m)
        @test m == movefromstring(tostring(m))
        for prom in [QUEEN, ROOK, BISHOP, KNIGHT]
            m = Move(f, t, prom)
            @test from(m) == f
            @test to(m) == t
            @test ispromotion(m)
            @test promotion(m) == prom
            @test m == movefromstring(tostring(m))
        end
    end
end
