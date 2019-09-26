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

module PGN

using Chess

export PGNException, PGNReader

export gamesinfile, gotonextgame!, gamefromstring, gametopgn, readgame

struct PGNException <: Exception
    message::String
end


"""
    PGNReader

A type for reading PGN data from a stream.
"""
mutable struct PGNReader
    io::IO
    unreadchar::Union{Char, Nothing}
end


"""
    PGNReader(io::IO)

Initializes a `PGNReader` from an `IO` object.
"""
PGNReader(io::IO) = PGNReader(io, nothing)


@enum TokenType begin
    str
    integer
    period
    asterisk
    leftbracket
    rightbracket
    leftparen
    rightparen
    leftangle
    rightangle
    nag
    symbol
    comment
    linecomment
    nullmove
    endoffile
end


struct Token
    ttype::TokenType
    value::String
end


function terminatesgame(t::Token)
    t.ttype == asterisk || t.ttype == eof ||
        (t.ttype == symbol &&
         (t.value == "1-0" ||
          t.value == "0-1" ||
          t.value == "1/2-1/2"))
end


function issymbolstart(c::Char)::Bool
    occursin(c, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-")
end


function issymbolcontinuation(c::Char)::Bool
    occursin(c, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_+#=:-/")
end


function readchar(p::PGNReader)::Char
    if p.unreadchar ≠ nothing
        result = p.unreadchar
        p.unreadchar = nothing
        result
    else
        read(p.io, Char)
    end
end


function unread(p::PGNReader, c::Char)
    p.unreadchar = c
end


function peek(p::PGNReader)::Char
    result = readchar(p)
    unread(p, result)
    result
end


function skipwhitespace(p::PGNReader)
    while !eof(p.io)
        c = readchar(p)
        if !isspace(c)
            unread(p, c)
            break
        end
    end
end


function readstring(p::PGNReader)::Token
    c = readchar(p)
    @assert c == '"'
    result = IOBuffer()

    while true
        if eof(p.io)
            throw(PGNException("EOF while reading string"))
        end
        pc = c
        c = readchar(p)
        if c == '"'
            if pc == '\\'
                write(result, c)
            else
                break
            end
        elseif c == '\\'
            if pc == '\\'
                write(result, c)
            end
        else
            write(result, c)
        end
    end
    Token(str, String(take!(result)))
end


function readsymbol(p::PGNReader)::Token
    c = readchar(p)
    @assert issymbolstart(c)

    tt = isdigit(c) ? integer : symbol
    result = IOBuffer()
    write(result, c)

    while !eof(p.io)
        c = readchar(p)
        if !issymbolcontinuation(c)
            break
        end
        write(result, c)
        if !isdigit(c)
            tt = symbol
        end
    end
    unread(p, c)
    Token(tt, String(take!(result)))
end


function readperiod(p::PGNReader)::Token
    c = readchar(p)
    @assert c == '.'
    Token(period, ".")
end


function readasterisk(p::PGNReader)::Token
    c = readchar(p)
    @assert c == '*'
    Token(asterisk, "*")
end


function readleftbracket(p::PGNReader)::Token
    c = readchar(p)
    @assert c == '['
    Token(leftbracket, "[")
end


function readrightbracket(p::PGNReader)::Token
    c = readchar(p)
    @assert c == ']'
    Token(rightbracket, "]")
end


function readleftparen(p::PGNReader)::Token
    c = readchar(p)
    @assert c == '('
    Token(leftparen, "(")
end


function readrightparen(p::PGNReader)::Token
    c = readchar(p)
    @assert c == ')'
    Token(rightparen, ")")
end


function readleftangle(p::PGNReader)::Token
    c = readchar(p)
    @assert c == '<'
    Token(leftangle, "<")
end


function readrightangle(p::PGNReader)::Token
    c = readchar(p)
    @assert c == '>'
    Token(rightangle, ">")
end


function readnag(p::PGNReader)::Token
    c = readchar(p)
    @assert c == '$'
    result = IOBuffer()
    c = readchar(p)
    while isdigit(c)
        write(result, c)
        if eof(p.io)
            break
        end
        c = readchar(p)
    end
    unread(p, c)
    Token(nag, String(take!(result)))
end


function readfakenag(p::PGNReader)::Token
    c = readchar(p)
    @assert c == '!' || c == '?'
    result = IOBuffer()
    write(result, c)
    c = readchar(p)
    while c == '!' || c == '?'
        write(result, c)
        if eof(p.io)
            break
        end
        c = readchar(p)
    end
    unread(p, c)
    s = String(take!(result))
    if startswith(s, "!!")
        Token(nag, "3")
    elseif startswith(s, "??")
        Token(nag, "4")
    elseif startswith(s, "!?")
        Token(nag, "5")
    elseif startswith(s, "?!")
        Token(nag, "6")
    elseif startswith(s, "!")
        Token(nag, "1")
    else
        Token(nag, "2")
    end
end


function readcomment(p::PGNReader)::Token
    c = readchar(p)
    @assert c == '{'
    result = IOBuffer()
    c = readchar(p)
    while c ≠ '}'
        write(result, c)
        if eof(p.io)
            throw(PGNException("EOF while reading comment"))
        end
        c = readchar(p)
    end
    Token(comment, String(take!(result)))
end


function readlinecomment(p::PGNReader)::Token
    c = readchar(p)
    @assert c == ';'
    result = IOBuffer()
    c = readchar(p)
    while c ≠ '\n'
        write(result, c)
        if eof(p.io)
            break
        end
        c = readchar(p)
    end
    Token(linecomment, String(take!(result)))
end


function readnullmove(p::PGNReader)::Token
    c = readchar(p)
    @assert c == '-'
    while c == '-'
        c = readchar(p)
    end
    Token(nullmove, "--")
end


function readtoken(p::PGNReader)::Token
    skipwhitespace(p)

    if eof(p.io)
        return Token(endoffile, "")
    end

    c = peek(p)

    if c == '"'
        readstring(p)
    elseif c == '-'
        readnullmove(p)
    elseif issymbolstart(c)
        readsymbol(p)
    elseif c == '.'
        readperiod(p)
    elseif c == '*'
        readasterisk(p)
    elseif c == '['
        readleftbracket(p)
    elseif c == ']'
        readrightbracket(p)
    elseif c == '('
        readleftparen(p)
    elseif c == ')'
        readrightparen(p)
    elseif c == '<'
        readleftangle(p)
    elseif c == '>'
        readrightangle(p)
    elseif c == '{'
        readcomment(p)
    elseif c == ';'
        readlinecomment(p)
    elseif c == '$'
        readnag(p)
    elseif c == '!' || c == '?'
        readfakenag(p)
    else
        throw(PGNException("Invalid character: " * c))
    end
end


"""
    gotonextgame!(p::PGNReader)::Bool

Tries to go to the next game, returns `true` on success.
"""
function gotonextgame!(p::PGNReader)::Bool
    while true
        t = readtoken(p)
        if t.ttype == endoffile
            return false
        end
        if t.ttype == leftbracket
            unread(p, '[')
            return true
        end
    end
    false
end


function readheader(p::PGNReader)::Tuple{String, String}
    lb = readtoken(p)
    k = readtoken(p)
    v = readtoken(p)
    rb = readtoken(p)
    skipwhitespace(p)
    if lb.ttype == leftbracket && rb.ttype == rightbracket &&
        k.ttype == symbol && v.ttype == str
        (k.value, v.value)
    else
        throw(PGNException("Malformed header pair"))
    end
end


function readheaders(p::PGNReader)::GameHeaders
    result = GameHeaders()
    while peek(p) == '['
        (name, value) = readheader(p)
        setheadervalue!(result, name, value)
    end
    result
end


function skipvariation(p::PGNReader)
    while true
        t = readtoken(p)
        if t.ttype == leftparen
            skipvariation(p)
        elseif t.ttype == rightparen
            break
        elseif t.ttype == endoffile
            throw(PGNException("EOF while reading variation"))
        end
    end
end


"""
    readgame(p::PGNReader; annotations=false)

Attempts to parse a PGN game and use it to create a `Game` or a `SimpleGame`.

If the optional parameter `annotations` is `true`, the return value will be a
`Game` containing all comments, variations and numeric annotation glyphs in the
PGN. Otherwise, it will be a `SimpleGame` with only the game moves.

This function assumes that the `PGNReader` is pointed at the beginning of a
game. If you are not sure this is the case, call `gotonextgame!` on the
`PGNReader` first.

If parsing fails or the notation contains illegal or ambiguous moves, the
function raises a `PGNException`.
"""
function readgame(p::PGNReader; annotations=false)
    headers = readheaders(p)
    if headers.fen == nothing
        result = annotations ? Game() : SimpleGame()
    else
        result = annotations ? Game(headers.fen) : SimpleGame(headers.fen)
    end
    result.headers = headers
    precomment = nothing
    nullmoveseen = false
    while true
        t = readtoken(p)
        if terminatesgame(t) || t.ttype == endoffile
            break
        elseif t.ttype == nullmove
            nullmoveseen = true
        elseif t.ttype == leftparen
            if !annotations
                skipvariation(p)
            else
                back!(result)
            end
        elseif t.ttype == rightparen
            @assert annotations
            tobeginningofvariation!(result)
            forward!(result)
        elseif t.ttype == comment
            if annotations
                if isatbeginning(result) || !isatend(result)
                    precomment = t.value
                else
                    addcomment!(result, t.value)
                end
            end
        elseif t.ttype == nag
            if annotations
                addnag!(result, parse(Int, t.value))
            end
        elseif t.ttype == symbol && !nullmoveseen
            # Try to parse the symbol as a move in short algebraic notation,
            # and add it to the game if successful
            m = movefromsan(board(result), t.value)
            if m ≠ nothing
                if annotations
                    addmove!(result, m)
                    if precomment ≠ nothing
                        addprecomment!(result, precomment)
                        precomment = nothing
                    end
                else
                    domove!(result, m)
                end
            end
        end
    end
    tobeginning!(result)
    result
end


"""
    gamesinfile(filename::String; annotations=false)

Creates a `Channel` of `Game`/`SimpleGame` objects read from the PGN file with
the provided file name.

If the optional parameter `annotations` is `true`, the return value will be a
channel of `Game` objects containing all comments, variations and numeric
annotation glyphs in the PGN. Otherwise, it will consist of `SimpleGame` objects
with only the game moves.
"""
function gamesinfile(filename::String; annotations=false)
    function createchannel(ch::Channel)
        open(filename, "r") do io
            pgnr = PGNReader(io)
            while !eof(pgnr.io)
                put!(ch, readgame(pgnr, annotations = annotations))
                gotonextgame!(pgnr)
            end
        end
    end
    Channel(createchannel)
end


"""
    gamefromstring(s::String; annotations=false)

Attempts to create a `Game` or `SimpleGame` object from the provided PGN string.

If the optional parameter `annotations` is `true`, the return value will be a
`Game` containing all comments, variations and numeric annotation glyphs in the
PGN. Otherwise, it will be a `SimpleGame` with only the game moves.

If the string does not parse as valid PGN, or if the notation contains illegal
or ambiguous moves, the function raises a `PGNException`
"""
function gamefromstring(s::String; annotations=false)
    readgame(PGNReader(IOBuffer(s)), annotations = annotations)
end


function formatstring(s::String)::String
    "\"" * replace(replace(s, "\\" => "\\\\"), "\"" => "\\\"") * "\""
end


function formatheader(name::String, value::String)
    "[" * name * " " * formatstring(value) * "]\n"
end


function formatmoves(g::SimpleGame)::String
    result = IOBuffer()
    g = deepcopy(g)
    tobeginning!(g)
    while !isatend(g)
        m = g.history[g.ply].move
        if sidetomove(g.board) == WHITE
            write(result, string(1 + div(g.ply, 2)), ". ")
        end
        write(result, movetosan(g.board, m), " ")
        forward!(g)
    end
    String(take!(result))
end


function formatmoves(g::Game)::String
    function formatvariation(buffer, node, movenum)
        if !isempty(node.children)
            child = first(node.children)

            # Pre-comment
            if precomment(child) ≠ nothing
                write(buffer, "{", precomment(child), "} ")
            end

            # Move number, if white to move or at the beginning of the game.
            if sidetomove(node.board) == WHITE
                write(buffer, string(movenum ÷ 2 + 1), ". ")
            elseif node.parent == nothing
                write(buffer, string(movenum ÷ 2 + 1), "... ")
            end

            # Move in SAN notation
            write(buffer, movetosan(node.board, lastmove(child.board)))

            # Numeric Annotation Glyph
            if Chess.nag(child) ≠ nothing
                write(buffer, " \$", string(Chess.nag(child)))
            end

            # Post-comment
            if Chess.comment(child) ≠ nothing
                write(buffer, " {", Chess.comment(child), "}")
            end

            if !isleaf(child)
                write(buffer, " ")
            end

            # Recursive annotation variations
            for child in node.children[2:end]
                # Variation start
                write(buffer, "(")

                # Pre-comment
                if precomment(child) ≠ nothing
                    write(buffer, "{", precomment(child), "} ")
                end

                # Move number
                if sidetomove(node.board) == WHITE
                    write(buffer, string(movenum ÷ 2 + 1), ". ")
                else
                    write(buffer, string(movenum ÷ 2 + 1), "... ")
                end

                # Move in SAN notation
                write(buffer, movetosan(node.board, lastmove(child.board)))

                # Post-comment
                if Chess.comment(child) ≠ nothing
                    write(buffer, " {", Chess.comment(child), "}")
                end

                # Continuation of variation
                if !isempty(child.children)
                    write(buffer, " ")
                    formatvariation(buffer, child, movenum + 1)
                end

                # Variation end
                write(buffer, ") ")
            end

            # Continuation of variation
            formatvariation(buffer, first(node.children), movenum + 1)
        end
    end

    result = IOBuffer()
    formatvariation(result, g.root, 0)
    write(result, " ")

    String(take!(result))
end


"""
    gametopgn(g)::String

Exports a `Game` or a `SimpleGame` to a PGN string.

# Limitations

- The movetext section is written in a single long line, with no line breaks.
"""
function gametopgn(g)::String
    result = IOBuffer()
    write(result, formatheader("Event", g.headers.event))
    write(result, formatheader("Site", g.headers.site))
    write(result, formatheader("Date", g.headers.date))
    write(result, formatheader("Round", g.headers.round))
    write(result, formatheader("White", g.headers.white))
    write(result, formatheader("Black", g.headers.black))
    write(result, formatheader("Result", g.headers.result))
    if headervalue(g, "FEN") ≠ nothing
        write(result, formatheader("Setup", "1"))
        write(result, formatheader("FEN", headervalue(g, "FEN")))
    end
    for gh in g.headers.othertags
        write(result, formatheader(gh.name, gh.value))
    end
    write(result, "\n", formatmoves(g), g.headers.result, "\n")
    String(take!(result))
end


end # module
