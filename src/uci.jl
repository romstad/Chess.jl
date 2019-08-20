module UCI

using Chess

export BoundType, Engine, Option, OptionType, OptionValue, Score, SearchInfo

export parsesearchinfo, quit, runengine, search, sendcommand, setoption, touci


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
"""
mutable struct Engine
    name::String
    author::String
    options::Dict{String, Option}
    io::Base.Process
end


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
    SearchInfo

A struct representing the contents of a UCI engine's `info` output.

Contains the following slots, all of which can be `nothing` for a given line
of search output:

- `depth`: The current search depth.
- `seldepth`: The current selective search depth.
- `time`: The time spent searching so far, in milliseconds.
- `nodes`: The number of nodes searched so far.
- `pv`: The main line, given of a vector of move strings in coordinate
  notation.
- `multipv`: The multipv index of the line currently printed.
- `score`: The score, a value of type `Score`.
- `currmove`: The move currently searched, in coordinate notation.
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
    pv::Union{Nothing, Vector{String}}
    multipv::Union{Nothing, Int}
    score::Union{Nothing, Score}
    currmove::Union{Nothing, String}
    currmovenumber::Union{Nothing, Int}
    hashfull::Union{Nothing, Int}
    nps::Union{Nothing, Int}
    tbhits::Union{Nothing, Int}
    cpuload::Union{Nothing, Int}
    string::Union{Nothing, String}
end


function SearchInfo()
    SearchInfo(nothing, nothing, nothing, nothing, nothing, nothing, nothing,
               nothing, nothing, nothing, nothing, nothing, nothing, nothing)
end


const TokenList = Vector{SubString{String}}


function parseinfoint(tokens::TokenList)::Tuple{Int, TokenList}
    (parse(Int, tokens[2]), tokens[3:end])
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


function parseinfopv(tokens::TokenList)::Vector{String}
    result = String[]
    for t in tokens
        if !isempty(t)
            push!(result, t)
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
    function search(e::Engine, gocmd::String, bestmoveaction, infoaction = nothing)

Tells a UCI engine to start searching.

The parameter `gocmd` is the actual command you want to send to the engine;
e.g. `"go movetime 10000"` or `"go infinite"`. The parameters `bestmoveaction`
and `infoaction` are functions accepting the output of the engine's
`"bestmove"` and `"info"` commands, respectively, and doing something with
the output. Usually, `infoaction` will be some function making internal use of
`parsesearchinfo()`.
"""
function search(e::Engine, gocmd::String, bestmoveaction, infoaction = nothing)
    sendcommand(e, gocmd)
    while true
        line = readline(e.io)
        if startswith(line, "bestmove")
            bestmoveaction(line)
            break
        elseif infoaction != nothing && startswith(line, "info")
            infoaction(line)
        end
    end
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
