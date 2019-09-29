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

using Dates;

export Game, GameHeader, GameHeaders, GameNode, SimpleGame

export addcomment!, adddata!, addmove!, addmoves!, addnag!, addprecomment!,
    back!, blackelo, board, comment, continuations, dateplayed, domove!,
    domoves!, forward!, headervalue, isatbeginning, isatend, isleaf, isterminal,
    nag, nextmove, ply, precomment, removeallchildren!, removedata!, removenode!,
    replacemove!, setheadervalue!, tobeginning!, tobeginningofvariation!,
    toend!, tonode!, undomove!, whiteelo


"""
    GameHeader

Type representing a PGN header tag.

Contains `name` and `value` slots, both of which are strings.
"""
mutable struct GameHeader
    name::String
    value::String
end


"""
    GameHeaders

Type representing the PGN header tags for a game.

Contains a slot for each the seven required PGN tags `event`, `site`, `date`,
`round`, `white`, `black` and `result`, all of which are strings. Remaining
tags are included in the `othertags` slot, which contains a vector of
`GameHeader`s.
"""
mutable struct GameHeaders
    event::String
    site::String
    date::String
    round::String
    white::String
    black::String
    result::String
    fen::Union{String, Nothing}
    othertags::Vector{GameHeader}
end


function GameHeaders()
    GameHeaders("?", "?", "?", "?", "?", "?", "*", nothing, GameHeader[])
end


mutable struct GameHistoryEntry
    move::Union{Move, Nothing}
    undo::Union{UndoInfo, Nothing}
    key::UInt64
end


"""
    SimpleGame

A type representing a simple game, with no support for comments or variations.
"""
mutable struct SimpleGame
    headers::GameHeaders
    startboard::Board
    board::Board
    history::Vector{GameHistoryEntry}
    ply::Int
end


function Base.show(io::IO, g::SimpleGame)
    print(io, "SimpleGame:\n ")
    b = deepcopy(g.startboard)
    ply = 1
    for ghe in g.history
        if ply == g.ply
            print(io, "* ")
        end
        if ghe.move ≠ nothing
            print(io, movetosan(b, ghe.move), " ")
            domove!(b, ghe.move)
        end
        ply += 1
    end
    if ply == g.ply
        print(io, "* ")
    end
end


"""
    SimpleGame(startboard::Board=startboard())

Constructor that creates a `SimpleGame` from the provided starting position.
"""
function SimpleGame(startboard::Board=startboard())
    result = SimpleGame(GameHeaders(),
                        deepcopy(startboard),
                        deepcopy(startboard),
                        GameHistoryEntry[GameHistoryEntry(nothing, nothing,
                                                          startboard.key)],
                        1)
    if fen(startboard) ≠ START_FEN
        setheadervalue!(result, "FEN", fen(startboard))
    end
    result
end


"""
    SimpleGame(startfen::String)

Constructor that creates a `SimpleGame` from the position given by the provided
FEN string.
"""
function SimpleGame(startfen::String)
    SimpleGame(fromfen(startfen))
end


"""
    GameNode

Type representing a node in a `Game`.

Game can contain variations, so this type actually represents a node in a
tree-like structure.

A `GameNode` is a mutable struct with the following slots:

- `parent`: The parent `GameNode`, or `nothing` if this node is the root of the
  game.
- `board`: The board position at this node.
- `children`: A vector of `GameNode`s, the children of the current node. The
  first entry is the main continuation, the remaining entries are alternative
  variations.
- `data`: A `Dict{String, Any}` used to store information about this node. This
  is used for comments and numeric annotation glyphs, but can also be used to
  store other data.
- `id`: An `Int`, used to look up this node in a `Game`, which contains a
  dictionary mapping ids to `GameNode`s.
"""
mutable struct GameNode
    parent::Union{GameNode, Nothing}
    board::Board
    children::Vector{GameNode}
    data::Dict{String, Any}
    id::Int
    ply::Int
end


function Base.show(io::IO, n::GameNode)
    print(io, "GameNode(id = $(n.id), board = $(fen(n.board)))")
end


"""
    GameNode(parent::GameNode, move::Move, id::Int)

Constructor that creates a `GameNode` from a parent node and a move.

The move must be a legal move from the board at the parent node.
"""
function GameNode(parent::GameNode, move::Move, id::Int)
    GameNode(parent,
             domove(parent.board, move),
             GameNode[],
             Dict{String, Any}(),
             id,
             parent.ply + 1)
end


"""
    GameNode(board::Board, id::Int)

Constructor that creates a root `GameNode` with the given board.

The resulting `GameNode` has no parent. This constructor is used to create the
root node of a game.
"""
function GameNode(board::Board, id::Int, ply::Int = 1)
    GameNode(nothing, deepcopy(board), GameNode[], Dict{String, Any}(), id, ply)
end


"""
    Game

Type representing a chess game, with support for comments and variations.
"""
mutable struct Game
    headers::GameHeaders
    root::GameNode
    node::GameNode
    nodemap::Dict{Int, GameNode}
    nodecounter::Int
end


function Base.show(io::IO, g::Game)
    function formatvariation(node)
        if !isempty(node.children)
            if node == g.node
                print(io, "* ")
            end
            child = first(node.children)
            print(io, movetosan(node.board, lastmove(child.board)))
            for child in node.children[2:end]
                print(io, " (")
                print(io, movetosan(node.board, lastmove(child.board)))
                if !isempty(child.children)
                    print(io, " ")
                    formatvariation(child)
                elseif child == g.node
                    print(io, " *")
                end
                print(io, ")")
            end
            if !isleaf(child)
                print(io, " ")
            end
            formatvariation(first(node.children))
        elseif node == g.node
            print(io, " *")
        end
    end
    print(io, "Game:\n ")
    formatvariation(g.root)
end


"""
    Game(startboard::Board)

Constructor that creates a `Game` from the provided starting position.
"""
function Game(startboard::Board)
    root = GameNode(startboard, 1)
    result = Game(GameHeaders(), root, root, Dict(root.id => root), 1)
    if fen(startboard) ≠ START_FEN
        setheadervalue!(result, "FEN", fen(startboard))
    end
    result
end


"""
    Game(startfen::String)

Constructor that creates a `Game` from the position given by the provided FEN
string.
"""
function Game(startfen::String)
    Game(fromfen(startfen))
end


"""
    Game()

Constructor that creates a new `Game` from the regular starting position.
"""
function Game()
    Game(startboard())
end


"""
    headervalue(ghs::GameHeaders, name::String)
    headervalue(g::SimpleGame, name::String)
    headervalue(g::Game, name::String)

Looks up the value for the header with the given name.

Returns the value as a `String`, or `nothing` if no header with the provided
name exists.
"""
function headervalue(ghs::GameHeaders, name::String)::Union{String, Nothing}
    if name == "Event"
        ghs.event
    elseif name == "Site"
        ghs.site
    elseif name == "Date"
        ghs.date
    elseif name == "Round"
        ghs.round
    elseif name == "White"
        ghs.white
    elseif name == "Black"
        ghs.black
    elseif name == "Result"
        ghs.result
    elseif name == "FEN" || name == "Fen"
        ghs.fen
    else
        for gh in ghs.othertags
            if gh.name == name
                return gh.value
            end
        end
        nothing
    end
end

function headervalue(g::SimpleGame, name::String)::Union{String, Nothing}
    headervalue(g.headers, name)
end

function headervalue(g::Game, name::String)::Union{String, Nothing}
    headervalue(g.headers, name)
end


const PGN_DATE_FORMAT = DateFormat("y-m-d")
const PGN_DATE_FORMAT_2 = DateFormat("y-m")
const PGN_DATE_FORMAT_3 = DateFormat("y")


function parsedate(datestr::String)::Union{Date, Nothing}
    datestr = replace(datestr, "." => "-")
    try
        Date(datestr[1:10], PGN_DATE_FORMAT)
    catch _
        try
            Date(datestr[1:7], PGN_DATE_FORMAT_2)
        catch _
            try
                Date(datestr[1:4], PGN_DATE_FORMAT_3)
            catch _
                nothing
            end
        end
    end
end


"""
    dateplayed(g::SimpleGame)::Union{Date, Nothing}
    dateplayed(g::Game)::Union{Date, Nothing}

The date at which the game was played, or `nothing`.

This function makes use of the PGN date tag, trying to behave robustly with
sensible defaults when the date is incomplete or incorrectly formatted. It
handles both ISO format YYYY-MM-DD dates and PGN format YYYY.MM.DD dates. If
either the month or the day is missing, they are replaced with 1. On failure,
returns `nothing`.

# Examples

```julia-repl
julia> g = Game();

julia> setheadervalue!(g, "Date", "2019.09.20");

julia> dateplayed(g)
2019-09-20

julia> setheadervalue!(g, "Date", "2019.09.??");

julia> dateplayed(g)
2019-09-01

julia> setheadervalue!(g, "Date", "2019.??.??");

julia> dateplayed(g)
2019-01-01

julia> setheadervalue!(g, "Date", "*");

julia> dateplayed(g) == nothing
true
```
"""
function dateplayed(g::SimpleGame)::Union{Date, Nothing}
    parsedate(headervalue(g, "Date"))
end

function dateplayed(g::Game)::Union{Date, Nothing}
    parsedate(headervalue(g, "Date"))
end


"""
    whiteelo(g::SimpeGame)
    whiteelo(g::Game)

The Elo of the white player (as given by the "WhiteElo" tag), or `nothing`.
"""
function whiteelo(g::SimpleGame)::Union{Int, Nothing}
    elo = headervalue(g, "WhiteElo")
    elo ≠ nothing ? tryparse(Int, elo) : nothing
end

function whiteelo(g::Game)::Union{Int, Nothing}
    elo = headervalue(g, "WhiteElo")
    elo ≠ nothing ? tryparse(Int, elo) : nothing
end


"""
    blackelo(g::SimpeGame)
    blackelo(g::Game)

The Elo of the black player (as given by the "BlackElo" tag), or `nothing`.
"""
function blackelo(g::SimpleGame)::Union{Int, Nothing}
    elo = headervalue(g, "BlackElo")
    elo ≠ nothing ? tryparse(Int, elo) : nothing
end

function blackelo(g::Game)::Union{Int, Nothing}
    elo = headervalue(g, "BlackElo")
    elo ≠ nothing ? tryparse(Int, elo) : nothing
end


"""
    setheadervalue!(ghs::GameHeaders, name::String, value::String)
    setheadervalue!(g::SimpleGame, name::String, value::String)
    setheadervalue!(g::Game, name::String, value::String)

Sets a header value, creating the header if it doesn't exist.
"""
function setheadervalue!(ghs::GameHeaders, name::String, value::String)
    if name == "Event"
        ghs.event = value
    elseif name == "Site"
        ghs.site = value
    elseif name == "Date"
        ghs.date = value
    elseif name == "Round"
        ghs.round = value
    elseif name == "White"
        ghs.white = value
    elseif name == "Black"
        ghs.black = value
    elseif name == "Result"
        ghs.result = value
    elseif name == "FEN" || name == "Fen"
        ghs.fen = value
    else
        for t in ghs.othertags
            if t.name == name
                t.value = value
                return
            end
        end
        push!(ghs.othertags, GameHeader(name, value))
    end
end

function setheadervalue!(g::SimpleGame, name::String, value::String)
    setheadervalue!(g.headers, name, value)
end

function setheadervalue!(g::Game, name::String, value::String)
    setheadervalue!(g.headers, name, value)
end


"""
    board(g::SimpleGame)
    board(g::Game)

The board position at the current node in a game.
"""
function board(g::SimpleGame)::Board
    g.board
end

function board(g::Game)::Board
    g.node.board
end


"""
    ply(g::SimpleGame)
    ply(g::Game)

The ply count of the current node.

Returns 1 for the root node, 2 for children of the root node, etc.

# Examples
```julia-repl
julia> g = Game();

julia> addmoves!(g, "d4", "Nf6", "c4", "g6", "Nc3", "Bg7");

julia> ply(g)
7

julia> back!(g);

julia> ply(g)
6

julia> tobeginning!(g);

julia> ply(g)
1
```
"""
function ply(g::SimpleGame)::Int
    g.ply
end

function ply(g::Game)::Int
    g.node.ply
end


"""
    continuations(n::GameNode)::Vector{Move}
    continuations(g::Game)::Vector{Move}

All moves at this node in the game tree.

One move for each child node of the current node.

# Examples

```julia-repl
julia> g = Game();

julia> addmoves!(g, "e4", "e5");

julia> back!(g);

julia> addmove!(g, "c5");

julia> back!(g);

julia> continuations(g)
2-element Array{Move,1}:
 Move(e7e5)
 Move(c7c5)
```
"""
function continuations(n::GameNode)::Vector{Move}
    map(ch -> lastmove(ch.board), n.children)
end

function continuations(g::Game)::Vector{Move}
    continuations(g.node)
end


"""
    domove!(g::SimpleGame, m::Move)
    domove!(g::SimpleGame, m::String)
    domove!(g::Game, m::Move)
    domove!(g::Game, m::String)

Adds a new move at the current location in the game move list.

If the supplied move is a string, this function tries to parse the move as a UCI
move first, then as a SAN move.

If we are at the end of the game, all previous moves are kept, and the new move
is added at the end. If we are at any earlier point in the game (because we
have taken back one or more moves), the existing game continuation will be
deleted and replaced by the new move. All variations starting at this point in
the game will also be deleted. If you want to add the new move as a variation
instead, make sure you use the `Game` type instead of `SimpleGame`, and use
`addmove!` instead of `domove!`.

The move `m` is assumed to be a legal move. It's the caller's responsibility
to ensure that this is the case.
"""
function domove!(g::SimpleGame, m::Move)
    g.history[g.ply].move = m
    g.ply += 1
    deleteat!(g.history, g.ply:length(g.history))
    u = domove!(g.board, m)
    push!(g.history, GameHistoryEntry(nothing, u, g.board.key))
    g
end

function domove!(g::SimpleGame, m::String)
    mv = movefromstring(m)
    if mv == nothing
        mv = movefromsan(board(g), m)
    end
    domove!(g, mv)
end

function domove!(g::Game, m::Move)
    removeallchildren!(g)
    addmove!(g, m)
    g
end

function domove!(g::Game, m::String)
    removeallchildren!(g)
    addmove!(g, m)
end


"""
    domoves!(g::SimpleGame, moves::Vararg{Union{Move, String}})
    domoves!(g::Game, moves::Vararg{Union{Move, String}})

Adds a sequence of new moves at the current location in the game move list.

The moves can be either `Move` values or strings. In the case of strings, the
function tries to parse them first as UCI moves, then as SAN moves.

If we are at the end of the game, all previous moves are kept, and the new moves
are added at the end. If we are at any earlier point in the game (because we
have taken back one or more moves), the existing game continuation will be
deleted and replaced by the new moves. All variations starting at this point in
the game will also be deleted. If you want to add the new moves as a variation
instead, make sure you use the `Game` type instead of `SimpleGame`, and use
`addmoves!` instead of `domoves!`.
"""
function domoves!(g::SimpleGame, moves::Vararg{Union{Move, String}})
    for m in moves
        domove!(g, m)
    end
end

function domoves!(g::Game, moves::Vararg{Union{Move, String}})
    for m in moves
        domove!(g, m)
    end
end


"""
    addmove!(g::Game, m::Move)
    addmove!(g::Game, m::String)

Adds the move `m` to the game `g` at the current node.

If the supplied move is a string, this function tries to parse the move as a UCI
move first, then as a SAN move.

The move `m` must be a legal move from the current node board position. A new
game node with the board position after the move has been made is added to the
end of the current node's children vector, and that node becomes the current
node of the game.

The move `m` is assumed to be a legal move. It's the caller's responsibility
to ensure that this is the case.
"""
function addmove!(g::Game, m::Move)
    g.nodecounter += 1
    node = GameNode(g.node, m, g.nodecounter)
    push!(g.node.children, node)
    g.nodemap[node.id] = node
    g.node = node
    g
end

function addmove!(g::Game, m::String)
    mv = movefromstring(m)
    if mv == nothing
        mv = movefromsan(board(g), m)
    end
    addmove!(g, mv)
end


"""
    addmoves!(g::Game, moves::Vararg{Union{Move, String}})

Adds a sequence of moves to the game `g` at the current node.

The moves can be either `Move` values or strings. In the case of strings, the
function tries to parse them first as UCI moves, then as SAN moves.

This function works by calling `addmove!` repeatedly for all input moves. It's
the caller's responsibility to ensure that all moves are legal and unambiguous.
"""
function addmoves!(g::Game, moves::Vararg{Union{Move, String}})
    for m in moves
        addmove!(g, m)
    end
    g
end


"""
    nextmove(g::SimpleGame)
    nextmove(g::Game)

The next move in the game, or `nothing` if we're at the end of the game.
"""
function nextmove(g::SimpleGame)::Union{Move, Nothing}
    g.history[g.ply].move
end

function nextmove(g::Game)::Union{Move, Nothing}
    if !isleaf(g.node)
        lastmove(first(g.node.children).board)
    end
end



"""
    isatbeginning(g::SimpleGame)::Bool
    isatbeginning(g::Game)::Bool

Return `true` if we are at the beginning of the game, and `false` otherwise.

We can be at the beginning of the game either because we haven't yet added
any moves to the game, or because we have stepped back to the beginning.

# Examples

```julia-repl
julia> g = SimpleGame();

julia> isatbeginning(g)
true

julia> domove!(g, "e4");

julia> isatbeginning(g)
false

julia> back!(g);

julia> isatbeginning(g)
true
```
"""
function isatbeginning(g::SimpleGame)::Bool
    g.history[g.ply].undo == nothing
end

function isatbeginning(g::Game)::Bool
    g.node.parent == nothing
end


"""
    isatend(g::SimpleGame)::Bool
    isatend(g::Game)::Bool

Return `true` if we are at the end of the game, and `false` otherwise.

# Examples

```julia-repl
julia> g = SimpleGame();

julia> isatend(g)
true

julia> domove!(g, "Nf3");

julia> isatend(g)
true

julia> back!(g);

julia> isatend(g)
false
```
"""
function isatend(g::SimpleGame)::Bool
    g.history[g.ply].move == nothing
end

function isatend(g::Game)
    isleaf(g.node)
end


"""
    back!(g::SimpleGame)
    back!(g::Game)

Go one step back in the game by retracting a move.

If we're already at the beginning of the game, the game is unchanged.
"""
function back!(g::SimpleGame)
    if !isatbeginning(g)
        undomove!(g.board, g.history[g.ply].undo)
        g.ply -= 1
    end
    g
end

function back!(g::Game)
    if !isatbeginning(g)
        g.node = g.node.parent
    end
    g
end


"""
    forward!(g::SimpleGame)
    forward!(g::Game)
    forward!(g::Game, m::Move)
    forward!(g::Game, m::String)

Go one step forward in the game by replaying a previously retracted move.

If we're already at the end of the game, the game is unchanged. If the current
node has multiple children, we always pick the first child (i.e. the main line).
If any child other than the first child is desired, supply the move leading to
the child node as the second argument. It's the caller's responsibility that
the move supplied leads to one of the existing child nodes.
"""
function forward!(g::SimpleGame)
    if !isatend(g)
        domove!(g.board, g.history[g.ply].move)
        g.ply += 1
    end
    g
end

function forward!(g::Game)
    if !isatend(g)
        g.node = first(g.node.children)
    end
    g
end

function forward!(g::Game, m::Move)
    i = findfirst(ch -> lastmove(ch.board) == m, g.node.children)
    if i != nothing
        g.node = g.node.children[i]
    end
    g
end

function forward!(g::Game, m::String)
    mv = movefromstring(m)
    if mv == nothing
        mv = movefromsan(board(g), m)
    end
    if mv == nothing
        throw("Illegal or ambiguous move: $m")
    end
    forward!(g, mv)
end


"""
    tobeginning!(g::SimpleGame)
    tobeginning!(g::Game)

Go back to the beginning of a game by taking back all moves.

If we're already at the beginning of the game, the game is unchanged.
"""
function tobeginning!(g::SimpleGame)
    while !isatbeginning(g)
        back!(g)
    end
    g
end

function tobeginning!(g::Game)
    while !isatbeginning(g)
        back!(g)
    end
    g
end



"""
    toend!(g::SimpleGame)
    toend!(g::Game)

Go forward to the end of a game by replaying all moves, following the main line.

If we're already at the end of the game, the game is unchanged.
"""
function toend!(g::SimpleGame)
    while !isatend(g)
        forward!(g)
    end
    g
end

function toend!(g::Game)
    while !isatend(g)
        forward!(g)
    end
    g
end


"""
    tobeginningofvariation!(g::Game)

Go to the beginning of the variation containing the current node of the game.

Steps back up the game tree until we reach the point where the first child node
(i.e. the main line) is not contained in the current variation.
"""
function tobeginningofvariation!(g::Game)
    while !isatbeginning(g)
        n = g.node
        back!(g)
        if n ≠ first(g.node.children)
            break
        end
    end
    g
end


"""
    tonode!(g::Game, id::Int)

Go to the game tree node with the given node id, if it exists.
"""
function tonode!(g::Game, id::Int)
    g.node = g.nodemap[id]
    g
end


"""
    isleaf(n::GameNode)::Bool

Tests whether a `GameNode` is a leaf, i.e. that it has no children.
"""
function isleaf(n::GameNode)::Bool
    isempty(n.children)
end


"""
    comment(n::GameNode)

The comment after the move leading to this node, or `nothing`.
"""
function comment(n::GameNode)::Union{String, Nothing}
    get(n.data, "comment", nothing)
end


"""
    precomment(n::GameNode)

The comment before the move leading to this node, or `nothing`.
"""
function precomment(n::GameNode)::Union{String, Nothing}
    get(n.data, "precomment", nothing)
end


"""
    nag(n::GameNode)

The numeric annotation glyph for the move leading to this node, or `nothing`.
"""
function nag(n::GameNode)::Union{Int, Nothing}
    get(n.data, "nag", nothing)
end


"""
    removeallchildren!(g::Game, node::GameNode = g.node)

Recursively remove all children of the given node in the game.

If no node is supplied, removes the children of the current node.
"""
function removeallchildren!(g::Game, node::GameNode = g.node)
    while !isempty(node.children)
        c = popfirst!(node.children)
        removeallchildren!(g, c)
        delete!(g.nodemap, c.id)
    end
    g
end


"""
    removenode!(g::Game, node::GameNode = g.node)

Remove a node (by default, the current node) in a `Game`, and go to the parent
node.

All children of the node are also recursively deleted.
"""
function removenode!(g::Game, node::GameNode = g.node)
    if node.parent ≠ nothing
        removeallchildren!(g, node)
        deleteat!(node.parent.children, ch .== node)
        delete!(g.nodemap, node.id)
        g.node = node.parent
    end
    g
end


"""
    adddata!(n::GameNode, key::String, value)

Add a piece of data to the given node's data dictionary.

This is a low-level function that is mainly used to add comments and NAGs, but
can also be used to add any type of custom annotation data to a game node.
"""
function adddata!(n::GameNode, key::String, value)
    n.data[key] = value
end


"""
    adddata!(g::Game, key::String, value)

Add a piece of data to the current game node's data dictionary.

This is a low-level function that is mainly used to add comments and NAGs, but
can also be used to add any type of custom annotation data to a game node.
"""
function adddata!(g::Game, key::String, value)
    adddata!(g.node, key, value)
end


"""
    removedata!(n::GameNode, key::String)

Remove a piece of data from the game node's data dictionary.

This is a low-level function that is mainly used to delete comments and NAGs.
"""
function removedata!(n::GameNode, key::String)
    delete!(n.data, key)
end


"""
    removedata!(n::GameNode, key::String)

Remove a piece of data from the current game node's data dictionary.

This is a low-level function that is mainly used to delete comments and NAGs.
"""
function removedata!(g::Game, key::String)
    removedata!(g.node, key)
end


"""
    addcomment!(g::Game, comment::String)

Adds a comment to the current game node.

In PGN and other text ouput formats, the comment is printed _after_ the move
leading to the node.
"""
function addcomment!(g::Game, comment::String)
    adddata!(g, "comment", comment)
end


"""
    addprecomment!(g::Game, comment::String)

Adds a pre-comment to the current game node.

In PGN and other text ouput formats, the comment is printed _before_ the move
leading to the node.
"""
function addprecomment!(g::Game, comment::String)
    adddata!(g, "precomment", comment)
end


"""
    addnag!(g::Game, nag::Int)

Adds a Numeric Annotation Glyph (NAG) to the current game node.
"""
function addnag!(g::Game, nag::Int)
    adddata!(g, "nag", nag)
end


function isrepetitiondraw(g::SimpleGame)::Bool
    key = board(g).key
    rcount = 1
    for i in 2:2:board(g).r50
        if g.history[g.ply - i].key == key
            rcount += 1
            if rcount == 3
                return true
            end
        end
    end
    false
end

function isrepetitiondraw(g::Game)::Bool
    rcount = 1
    key = g.node.board.key
    n = g.node.parent
    while n != nothing
        if n.board.key == key
            rcount += 1
            if rcount == 3
                return true
            end
        end
        if n.board.r50 == 0
            break
        end
        n = n.parent
    end
    false
end


"""
    isdraw(g::SimpleGame)
    isdraw(g::Game)

Checks whether the current game position is drawn.
"""
function isdraw(g::SimpleGame)::Bool
    isdraw(board(g)) || isrepetitiondraw(g)
end

function isdraw(g::Game)::Bool
    isdraw(board(g)) || isrepetitiondraw(g)
end


"""
    ischeckmate(g::SimpleGame)
    ischeckmate(g::Game)

Checks whether the current game position is a checkmate.
"""
function ischeckmate(g::SimpleGame)::Bool
    ischeckmate(board(g))
end

function ischeckmate(g::Game)::Bool
    ischeckmate(board(g))
end


"""
    isterminal(g::SimpleGame)
    isterminal(g::Game)

Checks whether the current game position is terminal, i.e. mate or drawn.
"""
function isterminal(g::SimpleGame)
    isterminal(board(g)) || isrepetitiondraw(g)
end

function isterminal(g::Game)
    isterminal(board(g)) || isrepetitiondraw(g)
end
