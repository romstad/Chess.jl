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

using Random

const ZOB_KEYS = begin
    local rng = MersenneTwister(1685)
    [rand(rng, UInt64) for i ∈ 1:64, j ∈ 1:14]
end

function zobrist(p::Piece, s::Square)::UInt64
    @inbounds ZOB_KEYS[s.val, p.val]
end

function zobep(s::Square)::UInt64
    @inbounds ZOB_KEYS[s.val, 7]
end

function zobcastle(castlerights::UInt8)
    @inbounds ZOB_KEYS[castlerights + 1, 8]
end

function zobsidetomove()
    @inbounds ZOB_KEYS[64, 8]
end
