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

export BookEntry

mutable struct BookEntry
    key::UInt64
    move::Int32
    elo::Int16
    oppelo::Int16
    wins::Int32
    draws::Int32
    losses::Int32
    year::Int16
    score::Float32
end

function BookEntry()
    BookEntry(0, 0, 0, 0, 0, 0, 0, 0, 0)
end


const ENTRY_SIZE = 34
const COMPACT_ENTRY_SIZE = 16


function entrytobytes(entry::BookEntry, compact::Bool)::Vector{UInt8}
    io = IOBuffer(UInt8[], read = true, write = true,
                  maxsize = compact ? COMPACT_ENTRY_SIZE : ENTRY_SIZE)
    write(io, entry.key)
    write(io, entry.move)
    write(io, entry.score)
    if !compact
        write(io, entry.elo)
        write(io, entry.oppelo)
        write(io, entry.wins)
        write(io, entry.draws)
        write(io, entry.losses)
        write(io, entry.year)
    end
    take!(io)
end


function entryfrombytes(bytes::Vector{UInt8}, compact::Bool)::BookEntry
    io = IOBuffer(bytes)
    result = BookEntry()
    result.key = read(io, UInt64)
    result.move = read(io, Int32)
    result.score = read(io, Float32)
    if !compact
        result.elo = read(io, Int16)
        result.oppelo = read(io, Int16)
        result.wins = read(io, Int32)
        result.draws = read(io, Int32)
        result.losses = read(io, Int32)
        result.year = read(io, Int16)
    end
    result
end


const SCORE_WHITE_WIN = 8.0
const SCORE_WHITE_DRAW = 4.0
const SCORE_WHITE_LOSS = 1.0
const SCORE_BLACK_WIN = 8.0
const SCORE_BLACK_DRAW = 5.0
const SCORE_BLACk_LOSS = 1.0
const YEARLY_DECAY = 0.85
const HIGH_ELO_FACTOR = 6.0
const MAX_PLY = 60
const MIN_SCORE = 0
const MIN_GAME_COUNT = 5
