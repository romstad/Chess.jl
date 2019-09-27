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

module UCI

using Chess

export BestMoveInfo, BoundType, Engine, Option, OptionType, OptionValue, Score,
    SearchInfo

export parsebestmove, parsesearchinfo, quit, runengine, search, sendcommand,
    setboard, setoption, touci


"""
    OptionType

Type representing an UCI option type. This is an enum with values corresponding
to the option types defined in the UCI protocol: `check`, `spin`, `combo`,
`button` and `string`.
"""
@enum OptionType begin
    check
    spin
    combo
    button
    string
end


"""
    OptionValue

Type representing the value of a UCI option. This is a union type containing
the types `Nothing` (for options of type `button`), `Bool` (for options of type
`check`, `Int` (for options of type `spin`) and `String` (for options of type
`combo` or `string`).)
"""
const OptionValue = Union{Nothing, Bool, Int, String}


"""
    Option

Type representing a UCI option. This is a mutable struct with the following slots:

- `name`: A `String`, the name of the option, as provided by the engine.
- `type`: An `OptionType`, the type of the option, as provided by the engine.
- `defaultValue`: An `OptionValue`, as provided by the engine.
- `value`: An `OptionValue`, the current value of the option.
- `min`: The minimum value of this option. Only used for options of type `spin`.
- `max`: The maximum value of this option. Only used for options of type `spin`.
- `combovals`: Vector of the possible values for this option. Only used for
  options of type `Combo`.
"""
mutable struct Option
    name::String
    type::OptionType
    defaultvalue::OptionValue
    value::OptionValue
    min::Int
    max::Int
    combovals::Vector{String}
end


function parseoptionname(s::String)::Tuple{String, String}
    @assert startswith(s, "name ")
    result = ""
    for c in s[6:end]
        result *= c
        endswith(result, " type") && break
    end
    (result[1:end - 5], s[length(result) + 2:end])
end


function parseoptiontype(s::String)::Tuple{OptionType, String}
    @assert startswith(s, "type ")
    result = ""
    for c in s[6:end]
        c == ' ' && break
        result *= c
    end
    optionsbyname = Dict("check" => check,
                         "spin" => spin,
                         "combo" => combo,
                         "button" => button,
                         "string" => string)
    (optionsbyname[result], s[length(result) + 6:end])
end


function parseoptiondefault(ot::OptionType, s::String)::Tuple{OptionValue, String}
    if ot == button
        (nothing, s)
    else
        @assert(startswith(s, " default "))
        s = s[10:end]
        if ot == check
            (startswith(s, "true"), s)
        elseif ot == spin
            result = ""
            for c in s
                c == ' ' && break
                result *= c
            end
            (parse(Int, result), s[length(result) + 1:end])
        elseif ot == combo
            result = ""
            for c in s
                endswith(result, " var ") && break
                result *= c
            end
            (result[1:end - 5], s[length(result) - 3:end])
        elseif ot == string
            (s, s)
        end
    end
end


function parsespinminmax(s::String)::Tuple{Int, Int}
    @assert startswith(s, " min ")
    tokens = split(s[2:end], r"\s+")
    @assert length(tokens) >= 4
    @assert tokens[1] == "min" && tokens[3] == "max"
    (parse(Int, tokens[2]), parse(Int, tokens[4]))
end


function parsecombovar(s::String)::Tuple{String, String}
    @assert startswith(s, "var ")
    result = ""
    for c in s[5:end]
        endswith(result, " var ") && break
        result *= c
    end
    if endswith(result, " var ")
        (result[1:end - 5], s[length(result) + 1: end])
    else
        (result, "")
    end
end


function parsecombovars(s::String)::Vector{String}
    result = String[]
    while startswith(s, "var ")
        (next, rest) = parsecombovar(s)
        push!(result, next)
        s = rest
    end
    result
end


function parseoption(s::String)::Option
    @assert startswith(s, "option name")
    s = s[8:end]
    (name, s) = parseoptionname(s)
    (otype, s) = parseoptiontype(s)
    (default, s) = parseoptiondefault(otype, s)
    (min, max) = otype == spin ? parsespinminmax(s) : (0, 0)
    combovals = otype == combo ? parsecombovars(s) : String[]
    Option(name, otype, default, default, min, max, combovals)
end


"""
    Engine

Type representing a UCI chess engine.

This is a struct with the following slots:

- `name`: The engine name, as provided by the engine in response to the `uci`
  command.
- `author`: The engine author name, as provided by the engine in response to
  the `uci` command.
- `options`: The UCI options for this engine. This is a dictionary mapping
  option names (`String`s) to options (instances of the `Option` type).
- `io`: A `Base.Process` object used to communicate with the engine.

Engines are created by calling the `runengine` function, which takes a pathname
for an UCI engine as input, runs the engine, and returns an `Engine` object.

# Examples

The below is a typical interaction with a UCI engine. The example assumes that
you have a UCI engine with the file name `stockfish` somewhere in your `PATH`.

```julia-repl
julia> sf = runengine("stockfish");

julia> setoption(sf, "Hash", 128)

julia> setboard(sf, fromfen("1kbr3r/pp6/8/P1n2ppq/2N3n1/R3Q1P1/3B1P2/2R2BK1 w - -"))

julia> search(sf, "go depth 18", infoaction=println)
info depth 1 seldepth 1 multipv 1 score cp -842 nodes 88 nps 88000 tbhits 0 time 1 pv f1g2 g4e3 d2e3
info depth 2 seldepth 2 multipv 1 score cp -842 nodes 207 nps 103500 tbhits 0 time 2 pv f1g2 g4e3
info depth 3 seldepth 3 multipv 1 score cp -844 nodes 270 nps 135000 tbhits 0 time 2 pv f1g2 g4e3 d2e3 d8d1 c1d1 h5d1 g2f1
info depth 4 seldepth 5 multipv 1 score cp -844 nodes 367 nps 183500 tbhits 0 time 2 pv f1g2 g4e3 d2e3 d8d1 c1d1
info depth 5 seldepth 7 multipv 1 score cp -953 nodes 866 nps 433000 tbhits 0 time 2 pv f1g2 h5h2 g1f1 g4e3 d2e3 c5d3 e3g5
info depth 6 seldepth 8 multipv 1 score cp -1060 nodes 1507 nps 753500 tbhits 0 time 2 pv f1g2 g4e3 d2e3 c5d3 e3d2 d3c1
info depth 7 seldepth 11 multipv 1 score cp -876 nodes 1995 nps 665000 tbhits 0 time 3 pv f1g2 g4e3
info depth 8 seldepth 10 multipv 1 score cp -882 nodes 2771 nps 923666 tbhits 0 time 3 pv f1g2 g4e3 d2e3 c8e6 e3c5 d8d1 c1d1 h5d1 g2f1 e6c4
info depth 9 seldepth 15 multipv 1 score cp -1068 nodes 12059 nps 1339888 tbhits 0 time 9 pv f1g2 g4e3 a3e3 c8e6 e3e6 c5e6 d2e1 d8d1 c1d1 h5d1
info depth 10 seldepth 15 multipv 1 score cp -1050 nodes 17558 nps 1463166 tbhits 0 time 12 pv f1g2 g4e3 a3e3 c8e6 g1f1 h5g4 e3e6 c5e6 c4e3 g4a4 d2c3
info depth 11 seldepth 17 multipv 1 score cp -1013 nodes 23543 nps 1569533 tbhits 0 time 15 pv f1g2 g4e3 a3e3 c8e6 g1f1 h5g4 e3e6 c5e6 c4e3 g4a4 d2c3
info depth 12 seldepth 20 multipv 1 score cp -995 nodes 48497 nps 1672310 tbhits 0 time 29 pv f1g2 g4e3 a3e3 c8e6 g1f1 c5e4 d2e1 d8c8 g3g4 h5g4 c4e5 g4h4 c1c8 h8c8
info depth 13 seldepth 29 multipv 1 score cp -1116 nodes 205726 nps 1959295 tbhits 0 time 105 pv f1g2 g4e3 f2e3 c5e4 a3a2 h5h2 g1f1 e4g3 f1f2 g3e4 f2f1 e4d2 c4d2 h2g3 d2f3 d8d3 f1g1 d3e3 f3d4 e3e8 a2e2
info depth 14 seldepth 28 multipv 1 score cp -148 nodes 247247 nps 1993927 tbhits 0 time 124 pv e3f4 g5f4 d2f4 b8a8 c4b6 a7b6 a5b6 c5a6
info depth 15 seldepth 16 multipv 1 score cp 120 nodes 248911 nps 1991288 tbhits 0 time 125 pv e3f4 g5f4 d2f4 g4e5 f4e5 d8d6 e5d6 b8a8 f1g2 c8e6 d6c5
info depth 16 seldepth 24 multipv 1 score cp 1117 nodes 251829 nps 1982905 tbhits 0 time 127 pv e3f4 g4e5 f4e5 d8d6 e5d6 b8a8 f1g2 h5h2 g1f1 c5e4 g2e4 f5e4 d2g5 c8h3 f1e2
info depth 17 seldepth 22 multipv 1 score cp 1500 nodes 258707 nps 1990053 tbhits 0 time 130 pv e3f4 g4e5 f4e5 d8d6 e5d6 b8a8 f1g2 h5h2 g1f1 c5e4 g2e4 h2h3 e4g2
info depth 18 seldepth 22 multipv 1 score mate 11 nodes 281736 nps 1984056 tbhits 0 time 142 pv e3f4 g5f4 d2f4 g4e5 f4e5 d8d6 e5d6 b8a8 c4b6 a7b6 a5b6 c5a6 c1c8 h8c8
BestMoveInfo (best=e3f4, ponder=g5f4)
```
"""
mutable struct Engine
    name::String
    author::String
    options::Dict{String, Option}
    io::Base.Process
end


Base.show(io::IO, engine::Engine) = print(io, "Engine: $(engine.name)")

"""
    function runengine(path::String)::Engine

Runs the engine at the specified path, returning an `Engine`.
"""
function runengine(path::String)::Engine
    process = open(`$path`, "r+")
    options = Dict{String, Option}()
    println(process, "uci")
    name = path
    author = ""
    while true
        line = readline(process)
        line == "uciok" && break
        if startswith(line, "id name ")
            name = line[9:end]
        elseif startswith(line, "id author ")
            author = line[11:end]
        elseif startswith(line, "option name")
            o = parseoption(line)
            options[o.name] = o
        end
    end
    Engine(name, author, options, process)
end


"""
    sendcommand(e::Engine, cmd::String)

Sends the UCI command `cmd` to the engine `e`.
"""
function sendcommand(e::Engine, cmd::String)
    println(e.io, cmd)
end


function isvalidvalueforoption(o::Option, v::OptionValue)::Bool
    if o.type == string
        typeof(v) == String
    elseif o.type == combo
        typeof(v) == String && any(cv -> cv == v, o.combovals)
    elseif o.type == check
        typeof(v) == Bool
    elseif o.type == spin
        typeof(v) == Int && v >= o.min && v <= o.max
    elseif o.type == button
        v == nothing
    else
        false
    end
end


"""
    function setoption(e::Engine, name::String, value::OptionValue = nothing)

Sets the UCI option named `name` to the new value `value`.

Throws an error if the engine `e` does not have an option with the provided
name, or if the value is incompatible with the type of the option.
"""
function setoption(e::Engine, name::String, value::OptionValue = nothing)
    if !haskey(e.options, name)
        throw("Engine $(e.name) has no option named $name")
    elseif !isvalidvalueforoption(e.options[name], value)
        throw("Invalid value $value for option $name")
    else
        e.options[name].value = value
        if value == nothing
            sendcommand(e, "setoption name $name")
        else
            sendcommand(e, "setoption name $name value $value")
        end
    end
end


"""
    function quit(e::Engine)

Sends the UCI engine `e` the `"quit"` command.
"""
function quit(e::Engine)
    sendcommand(e, "quit")
end


"""
    BoundType

An enum type representing the score bound types `lower`, `upper` and `exact`.
"""
@enum BoundType begin
    lower = 1
    upper = 2
    exact = 3
end


"""
    Score

A struct type representing a score returned by a UCI engine.

The struct has the following slots:

- `value`: An `Int` representing the score value.
- `ismate`: A `Bool` that tells whether this is a mate score.
- `bound`: A `BoundType`, indicating whether this score is a lower bound, an
  upper bound, or an exact value.
"""
struct Score
    value::Int
    ismate::Bool
    bound::BoundType
end


"""
    BestMoveInfo

A struct representing the contents of a UCI engine's `bestmove` output.

Contains the following slots:

- `bestmove`: The `Move` returned by the engine as the best move.
- `ponder`: The engine's expected reply to the best move, a `Move` or
  `nothing`.
"""
struct BestMoveInfo
    bestmove::Move
    ponder::Union{Move, Nothing}
end


function Base.show(io::IO, bmi::BestMoveInfo)
    if bmi.ponder == nothing
        print(io, "BestMoveInfo (best=$(tostring(bmi.bestmove)))")
    else
        print(io, "BestMoveInfo (best=$(tostring(bmi.bestmove)), ponder=$(tostring(bmi.ponder)))")
    end
end


"""
    parsebestmove(line::String)::BestMoveInfo

Parses a `bestmove` line printed by a UCI engine to a `BestMoveInfo` object.
"""
function parsebestmove(line::String)::BestMoveInfo
    @assert startswith(line, "bestmove")
    tokens = split(line, r"\s+")
    bestmove = movefromstring(String(tokens[2]))
    ponder = if length(tokens) >= 4 && tokens[3] == "ponder"
        movefromstring(String(tokens[4]))
    else
        nothing
    end
    BestMoveInfo(bestmove, ponder)
end


"""
    SearchInfo

A struct representing the contents of a UCI engine's `info` output.

Contains the following slots, all of which can be `nothing` for a given line
of search output:

- `depth`: The current search depth.
- `seldepth`: The current selective search depth.
- `time`: The time spent searching so far, in milliseconds.
- `nodes`: The number of nodes searched so far.
- `pv`: The main line, as a vector of `Move` values.
- `multipv`: The multipv index of the line currently printed.
- `score`: The score, a value of type `Score`.
- `currmove`: The move currently searched, a value of type `Move`.
- `currmovenumber`: The index of the move currently searched in the move list.
- `hashfull`: A number in the range 0--100, indicating the transposition table
  saturation percentage.
- `nps`: Nodes/second count.
- `tbhits`: Number of tablebase hits.
- `cpuload`: CPU load percentage.
- `string`: An arbitrary string sent by the engine.
"""
mutable struct SearchInfo
    depth::Union{Nothing, Int}
    seldepth::Union{Nothing, Int}
    time::Union{Nothing, Int}
    nodes::Union{Nothing, Int}
    pv::Union{Nothing, Vector{Move}}
    multipv::Union{Nothing, Int}
    score::Union{Nothing, Score}
    currmove::Union{Nothing, Move}
    currmovenumber::Union{Nothing, Int}
    hashfull::Union{Nothing, Int}
    nps::Union{Nothing, Int}
    tbhits::Union{Nothing, Int}
    cpuload::Union{Nothing, Int}
    string::Union{Nothing, String}
end


function SearchInfo()
    SearchInfo(nothing, nothing, nothing, nothing, nothing, nothing, nothing,
               nothing, nothing, nothing, nothing, nothing, nothing, nothing,)
end


function Base.show(io::IO, si::SearchInfo)
    println(io, "SearchInfo:")
    if si.depth != nothing
        println(io, " depth: $(si.depth)")
    end
    if si.seldepth != nothing
        println(io, " seldepth: $(si.seldepth)")
    end
    if si.time != nothing
        println(io, " time: $(si.time)")
    end
    if si.nodes != nothing
        println(io, " nodes: $(si.nodes)")
    end
    if si.nps != nothing
        println(io, " nps: $(si.nps)")
    end
    if si.score != nothing
        println(io, " score: $(si.score)")
    end
    if si.currmove != nothing
        println(io, " currmove: $(tostring(si.currmove))")
    end
    if si.currmovenumber != nothing
        println(io, " currmovenumber: $(si.currmovenumber)")
    end
    if si.hashfull != nothing
        println(io, " hashfull: $(si.hashfull)")
    end
    if si.tbhits != nothing
        println(io, " tbhits: $(si.tbhits)")
    end
    if si.cpuload != nothing
        println(io, " cpuload: $(si.cpuload)")
    end
    if si.string != nothing
        println(io, " string: $(si.string)")
    end
    if si.multipv != nothing
        println(io, " multipv: $(si.multipv)")
    end
    if si.pv != nothing
        print(io, " pv:")
        for m ∈ si.pv
            print(io, " $(tostring(m))")
        end
        print(io, "\n")
    end
end


const TokenList = Vector{SubString{String}}


function parseinfoint(tokens::TokenList)::Tuple{Int, TokenList}
    (parse(Int, tokens[2]), tokens[3:end])
end


function parseinfocurrmove(tokens::TokenList)::Tuple{Move, TokenList}
    (movefromstring(String(tokens[2])), tokens[3:end])
end


function parseinfoscore(tokens::TokenList)::Tuple{Score, TokenList}
    ismate = tokens[2] == "mate"
    value = parse(Int, tokens[3])
    bound = exact
    if length(tokens) >= 4
        if tokens[4] == "lowerbound"
            bound = lower
        elseif tokens[4] == "upperbound"
            bound = upper
        end
    end
    (Score(value, ismate, bound), bound == exact ? tokens[4:end] : tokens[5:end])
end


function parseinfopv(tokens::TokenList)::Vector{Move}
    result = Move[]
    for t in tokens
        if !isempty(t)
            push!(result, movefromstring(String(t)))
        end
    end
    result
end


"""
    parsesearchinfo(line::String)::SearchInfo

Parses an `info` line printed by a UCI engine to a `SearchInfo` object.

See the documentation for `SearchInfo` for information about how to inspect
and use the return value.
"""
function parsesearchinfo(line::String)::SearchInfo
    @assert startswith(line, "info")
    result = SearchInfo()
    tokens = split(line, r"\s+")[2:end]
    while !isempty(tokens)
        if tokens[1] == "depth"
            (result.depth, tokens) = parseinfoint(tokens)
        elseif tokens[1] == "seldepth"
            (result.seldepth, tokens) = parseinfoint(tokens)
        elseif tokens[1] == "time"
            (result.time, tokens) = parseinfoint(tokens)
        elseif tokens[1] == "nodes"
            (result.nodes, tokens) = parseinfoint(tokens)
        elseif tokens[1] == "multipv"
            (result.multipv, tokens) = parseinfoint(tokens)
        elseif tokens[1] == "currmove"
            (result.currmove, tokens) = parseinfocurrmove(tokens)
        elseif tokens[1] == "currmovenumber"
            (result.currmovenumber, tokens) = parseinfoint(tokens)
        elseif tokens[1] == "hashfull"
            (result.hashfull, tokens) = parseinfoint(tokens)
        elseif tokens[1] == "nps"
            (result.nps, tokens) = parseinfoint(tokens)
        elseif tokens[1] == "tbhits"
            (result.tbhits, tokens) = parseinfoint(tokens)
        elseif tokens[1] == "cpuload"
            (result.cpuload, tokens) = parseinfoint(tokens)
        elseif tokens[1] == "score"
            (result.score, tokens) = parseinfoscore(tokens)
        elseif tokens[1] == "pv"
            result.pv = parseinfopv(tokens[2:end])
            break
        else
            tokens = tokens[2:end]
        end
    end
    result
end


"""
    function search(e::Engine, gocmd::String; infoaction = nothing)

Tells a UCI engine to start searching.

The parameter `gocmd` is the actual command you want to send to the engine;
e.g. `"go movetime 10000"` or `"go infinite"`. The named parameter `infoaction`
is a function accepting the output of the engine's `"info"` commands and doing
something with the output. Usually, it will be some function making internal use
of `parsesearchinfo()`.

The return value is of type `BestMoveInfo`.
"""
function search(e::Engine, gocmd::String; infoaction = nothing)::BestMoveInfo
    sendcommand(e, gocmd)
    while true
        line = readline(e.io)
        if startswith(line, "bestmove")
            return parsebestmove(line)
        elseif infoaction != nothing && startswith(line, "info")
            infoaction(line)
        end
    end
end


"""
    setboard(e::Engine, b::Board)
    setboard(e::Engine, g::SimpleGame)
    setboard(e::Engine, g::Game)

Set the engine's current board position to the given board/game state.
"""
function setboard(e::Engine, b::Board)
    sendcommand(e, touci(b))
end

function setboard(e::Engine, g::SimpleGame)
    sendcommand(e, touci(g))
end

function setboard(e::Engine, g::Game)
    sendcommand(e, touci(g))
end


"""
    touci(b::Board)
    touci(g::SimpleGame)
    touci(g::Game)

Create a UCI string representation of a board or a game.

# Examples
```julia-repl
julia> touci(startboard())
"position fen rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -"

julia> sg = SimpleGame(); domove!(sg, "e4"); domove!(sg, "c5"); domove!(sg, "Nf3");

julia> touci(sg)
"position fen rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - moves e2e4 c7c5 g1f3"

julia> g = Game(); domove!(g, "d4"); domove!(g, "Nf6"); domove!(g, "c4");

julia> touci(g)
"position fen rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - moves d2d4 g8f6 c2c4"
```
"""
function touci(b::Board)::String
    "position fen $(fen(b))"
end

function touci(g::SimpleGame)::String
    result = "position fen $(fen(g.startboard))"
    if !isatbeginning(g)
        result *= " moves"
        for ply in 1:(g.ply - 1)
            result *= " " * tostring(g.history[ply].move)
        end
    end
    result
end

function touci(g::Game)::String
    result = "position fen $(fen(g.root.board))"
    if !isatbeginning(g)
        result *= " moves"
        moves = String[]
        n = g.node
        while n.parent != nothing
            push!(moves, tostring(lastmove(n.board)))
            n = n.parent
        end
        for m in reverse(moves)
            result *= " " * m
        end
    end
    result
end


end
