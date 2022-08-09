module Book

using Artifacts
using Dates
using Formatting
using Printf
using StatsBase

using ..Chess, ..Chess.PGN

export BookEntry

export createbook,
    findbookentries, pickbookmove, printbookentries, purgebook, writebooktofile


"""
    BookEntry

A struct representing an opening book entry.

Book entries contain the following slots:

- `key`: The hash key of the board position this book entry represents.
- `move`: The move played, encoded as an `Int32`. In order to get the actual
  `Move` value representing the move stored in a book entry `e`, you should do
  `Move(e.move)`.
- `elo`: The highest Elo rating of a player who played this move.
- `oppelo`: The highest Elo of the opponent in a game where this move was
  played.
- `wins`: The number of times the player who played this move won the game.
- `draws`: The number of times the player who played this move drew the game.
- `losses`: The number of times the player who played this move lost the game.
- `firstyear`: The year this move was first played.
- `lastyear`: The year this move was last played.
- `score`: The score of this move, used to obtain a probability distribution
  when picking a book move for a position. The score is computed based on the
  W/L/D stats for the move, the ratings of the players who have played it, and
  on its popularity in more recent games.
"""
mutable struct BookEntry
    key::UInt64
    move::Int32
    elo::Int16
    oppelo::Int16
    wins::Int32
    draws::Int32
    losses::Int32
    firstyear::Int16
    lastyear::Int16
    score::Float32
end

function BookEntry()
    BookEntry(0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
end

function Base.show(io::IO, e::BookEntry)
    println(io, "BookEntry:")
    println(io, "  key: $(e.key)")
    println(io, "  move: $(Move(e.move))")
    println(io, "  top elo: $(e.elo)")
    println(io, "  top opponent elo: $(e.oppelo)")
    println(io, "  (w, d, l): ($(e.wins), $(e.draws), $(e.losses))")
    println(io, "  first played: $(e.firstyear)")
    println(io, "  last played: $(e.lastyear)")
    println(io, "  score: $(e.score)")
end


const ENTRY_SIZE = 36
const COMPACT_ENTRY_SIZE = 16


function entrytobytes(entry::BookEntry, compact::Bool)::Vector{UInt8}
    io = IOBuffer(
        UInt8[],
        read = true,
        write = true,
        maxsize = compact ? COMPACT_ENTRY_SIZE : ENTRY_SIZE,
    )
    write(io, entry.key)
    write(io, entry.move)
    write(io, entry.score)
    if !compact
        write(io, entry.elo)
        write(io, entry.oppelo)
        write(io, entry.wins)
        write(io, entry.draws)
        write(io, entry.losses)
        write(io, entry.firstyear)
        write(io, entry.lastyear)
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
        result.firstyear = read(io, Int16)
        result.lastyear = read(io, Int16)
    end
    result
end


function computescore(
    result,
    color,
    elo,
    date,
    scorewhitewin,
    scorewhitedraw,
    scorewhiteloss,
    scoreblackwin,
    scoreblackdraw,
    scoreblackloss,
    scoreunknown,
    highelofactor,
    yearlydecay,
)::Float32
    base = if result == "1-0" && color == WHITE
        scorewhitewin
    elseif result == "1/2-1/2" && color == WHITE
        scorewhitedraw
    elseif result == "0-1" && color == WHITE
        scorewhiteloss
    elseif result == "0-1" && color == BLACK
        scoreblackwin
    elseif result == "1/2-1/2" && color == BLACK
        scoreblackdraw
    elseif result == "1-0" && color == BLACK
        scoreblackloss
    else
        scoreunknown
    end
    base *
    max(1.0, 0.01 * highelofactor * (2300 - elo)) *
    exp(log(yearlydecay) * (Dates.value(today() - date) / 365.25))
end


function mergeable(e1::BookEntry, e2::BookEntry)::Bool
    e1.key == e2.key && e1.move == e2.move
end


function merge(e1::BookEntry, e2::BookEntry)::BookEntry
    BookEntry(
        e1.key,
        e1.move,
        max(e1.elo, e2.elo),
        max(e1.oppelo, e2.oppelo),
        e1.wins + e2.wins,
        e1.draws + e2.draws,
        e1.losses + e2.losses,
        min(e1.firstyear, e2.firstyear),
        max(e1.lastyear, e2.lastyear),
        e1.score + e2.score,
    )
end


function compress!(entries::Vector{BookEntry})
    i = 1
    j = 1
    n = length(entries)
    while j + 1 < n
        for k ∈ j+1:n
            if !mergeable(entries[i], entries[k]) || k == n
                j = k
                i += 1
                entries[i] = entries[k]
                break
            end
            entries[i] = merge(entries[i], entries[k])
        end
    end
    entries[1:i-1]
end


function compareentries(e1::BookEntry, e2::BookEntry)::Bool
    e1.key < e2.key || (e1.key == e2.key && e1.move < e2.move)
end


function sortentries!(entries::Vector{BookEntry})
    sort!(entries, lt = compareentries)
end


function addgame!(
    entries::Vector{BookEntry},
    g::SimpleGame,
    scorewhitewin,
    scorewhitedraw,
    scorewhiteloss,
    scoreblackwin,
    scoreblackdraw,
    scoreblackloss,
    scoreunknown,
    highelofactor,
    yearlydecay,
    maxply,
    minelo,
    maxelo,
)
    result = headervalue(g, "Result")
    if result ≠ "*"
        w = result == "1-0" ? 1 : 0
        d = result == "1/2-1/2" ? 1 : 0
        l = result == "0-1" ? 1 : 0
        welo = !isnothing(whiteelo(g)) ? whiteelo(g) : 0
        belo = !isnothing(blackelo(g)) ? blackelo(g) : 0
        if !(minelo ≤ welo ≤ maxelo) && !(minelo ≤ belo ≤ maxelo)
            return
        end
        date = !isnothing(dateplayed(g)) ? dateplayed(g) : Date(1900, 1, 1)
        year = Dates.year(date)
        wscore = computescore(
            result,
            WHITE,
            welo,
            date,
            scorewhitewin,
            scorewhitedraw,
            scorewhiteloss,
            scoreblackwin,
            scoreblackdraw,
            scoreblackloss,
            scoreunknown,
            highelofactor,
            yearlydecay,
        )
        bscore = computescore(
            result,
            BLACK,
            belo,
            date,
            scorewhitewin,
            scorewhitedraw,
            scorewhiteloss,
            scoreblackwin,
            scoreblackdraw,
            scoreblackloss,
            scoreunknown,
            highelofactor,
            yearlydecay,
        )

        tobeginning!(g)
        while !isatend(g) && g.ply <= maxply
            b = board(g)
            wtm = sidetomove(b) == WHITE
            m = nextmove(g)
            if (wtm && minelo ≤ welo ≤ maxelo) || (!wtm && minelo ≤ belo ≤ maxelo)
                push!(
                    entries,
                    BookEntry(
                        b.key,
                        m.val,
                        wtm ? welo : belo,
                        wtm ? belo : welo,
                        wtm ? w : l,
                        d,
                        wtm ? l : w,
                        year,
                        year,
                        wtm ? wscore : bscore,
                    ),
                )
            end
            forward!(g)
        end
    end
end


function addgamefile!(
    entries::Vector{BookEntry},
    filename::AbstractString,
    scorewhitewin,
    scorewhitedraw,
    scorewhiteloss,
    scoreblackwin,
    scoreblackdraw,
    scoreblackloss,
    scoreunknown,
    highelofactor,
    yearlydecay,
    maxply,
    minelo,
    maxelo,
    maxgames,
    maxentries,
    count,
)
    for g ∈ PGN.gamesinfile(filename)
        addgame!(
            entries,
            g,
            scorewhitewin,
            scorewhitedraw,
            scorewhiteloss,
            scoreblackwin,
            scoreblackdraw,
            scoreblackloss,
            scoreunknown,
            highelofactor,
            yearlydecay,
            maxply,
            minelo,
            maxelo,
        )
        count += 1
        if count % 1000 == 0
            @info "$count games added, $(length(entries)) entries."
        end
        if (!isnothing(maxgames) && count ≥ maxgames) ||
           (!isnothing(maxentries) && length(entries) ≥ maxentries)
            break
        end
    end
    count
end


"""
    createbook(pgnfiles::Vararg{String};
               scorewhitewin = 8.0,
               scorewhitedraw = 4.0,
               scorewhiteloss = 1.0,
               scoreblackwin = 8.0,
               scoreblackdraw = 5.0,
               scoreblackloss = 1.0,
               scoreunknown = 0.0,
               highelofactor = 6.0,
               yearlydecay = 0.85,
               maxply = 60,
               minelo = 0,
               maxelo = 10_000,
               maxgames = nothing,
               maxentries = nothing,
    )

Creates an opening book tree from one or more PGN files.

The opening tree is stored in RAM. You will probably want to save it to disk
using `writebooktofile` afterwards, for instance like this:

```julia-repl
julia> bk = createbook("my-pgn-file.pgn");

julia> writebooktofile(bk, "my-book.obk")
```

The createbook function takes a number of optional named parameters that
can be used to control what moves are included in the opening tree, and the
scoring of the moves (which is used to produce move probabilities when picking
a move using `pickbookmove`). These are:

- `scorewhitewin`: The base score for all white moves in a game won by white.
- `scorewhitedraw`: The base score for all white moves in a drawn game.
- `scorewhiteloss`: The base score for all black moves in a game won by black.
- `scoreblackwin`: The base score for all black moves in a game won by black.
- `scoreblackdraw`: The base score for all black moves in a drawn game.
- `scoreblackloss`: The base score for all black moves in a game won by white.
- `scoreunknown`: The base score for all moves in a game with an unknown result.
- `highelofactor`: Score multiplier for moves played by a player with high
  rating. The base score is multiplied by
  `max(1.0, 0.01 * highelofactor * (2300 - elo))`
- `yearlydecay`: Controls exponential yearly reduction of scores. If a game was
  played `n` years ago, all scores are multiplied by `yearlydecay^n`.
- `maxply`: Maximum depth of the opening tree. If `maxply` equals 60 (the
  default), no moves after move 30 are included in the opening tree.
- `minelo`: Minimum Elo for book moves. Moves played by players below this
  number are not included in the opening tree.
- `maxelo`: Maximum Elo for book moves. Moves played by players above this
  number are not included in the opening tree.
- `maxgames`: Maximum number of games to include. If no value is supplied, all
  games in the input PGNs will be used.
- `maxentries`: Maximum number of book entries to include. If no value is
  supplied, all entries will be included.
"""
function createbook(
    pgnfiles::Vararg{String};
    scorewhitewin = 8.0,
    scorewhitedraw = 4.0,
    scorewhiteloss = 1.0,
    scoreblackwin = 8.0,
    scoreblackdraw = 5.0,
    scoreblackloss = 1.0,
    scoreunknown = 0.0,
    highelofactor = 6.0,
    yearlydecay = 0.85,
    maxply = 60,
    minelo = 0,
    maxelo = 10_000,
    maxgames = nothing,
    maxentries = nothing,
)
    result = Vector{BookEntry}()
    count = 0
    for filename ∈ pgnfiles
        count = addgamefile!(
            result,
            filename,
            scorewhitewin,
            scorewhitedraw,
            scorewhiteloss,
            scoreblackwin,
            scoreblackdraw,
            scoreblackloss,
            scoreunknown,
            highelofactor,
            yearlydecay,
            maxply,
            minelo,
            maxelo,
            maxgames,
            maxentries,
            count,
        )
    end
    result = compress!(sortentries!(result))
    result
end


"""
    writebooktofile(entries::Vector{BookEntry}, filename::AbstractString,
                    compact = false)

Writes a book (as created by `createbookfile`) to a binary file.

If the optional parameter `compact` is `true`, the book is written in a more
compact format that does not include W/L/D counts, Elo numbers and years.
"""
function writebooktofile(entries::Vector{BookEntry}, filename::AbstractString, compact = false)
    open(filename, "w") do f
        write(f, UInt8(compact ? 1 : 0))
        for e ∈ entries
            write(f, entrytobytes(e, compact))
        end
    end
end


"""
    purgebook(infilename::AbstractString, outfilename::AbstractString;
              minscore = 0, mingamecount = 5, compact = false)

Creates a smaller version of an opening book file by removing unimportant lines.

Book moves with score lower than `minscore` or which have been played in fewer
than `mingamecount` games are not included in the output file.

If the optional parameter `compact` is `true`, the output file is written in a
more compact format that does not include W/L/D counts, Elo numbers and years.
"""
function purgebook(
    infilename::AbstractString,
    outfilename::AbstractString;
    minscore = 0,
    mingamecount = 5,
    compact = false,
)
    open(infilename, "r") do inf
        open(outfilename, "w") do outf
            write(outf, UInt8(compact ? 1 : 0))
            incompact = read(inf, UInt8) == 1
            entrysize = incompact ? COMPACT_ENTRY_SIZE : ENTRY_SIZE
            entrycount = div(filesize(infilename) - 1, entrysize)
            for i = 1:entrycount
                e = readentry(inf, i - 1, incompact)
                if e.wins + e.draws + e.losses ≥ mingamecount && e.score > minscore
                    write(outf, entrytobytes(e, compact))
                end
                if i % 100000 == 0
                    @printf(
                        "%d/%d (%.1f%%) entries processed.\n",
                        i,
                        entrycount,
                        100 * i / entrycount
                    )
                end
            end
        end
    end
end


function readkey(f::IO, index::Int, entrysize::Int)::UInt64
    seek(f, 1 + entrysize * index)
    read(f, UInt64)
end


function findkey(
    f::IO,
    key::UInt64,
    left::Int,
    right::Int,
    entrysize::Int,
)::Union{Int,Nothing}
    while left <= right
        middle = div(left + right, 2)
        midkey = readkey(f, middle, entrysize)
        if key == midkey && (middle == 0 || key ≠ readkey(f, middle - 1, entrysize))
            return middle
        elseif midkey < key
            left = middle + 1
        else
            right = middle - 1
        end
    end
end


function readentry(f::IO, index::Int, compact = false)::Union{BookEntry,Nothing}
    entrysize = compact ? COMPACT_ENTRY_SIZE : ENTRY_SIZE
    seek(f, 1 + entrysize * index)
    entryfrombytes(read(f, entrysize), compact)
end


"""
    findbookentries(b::Board, bookfile = nothing)
    findbookentries(key::UInt64, bookfile = nothing)

Returns all book entries for the given board or key.

If `bookfile` is nothing, use the default built-in opening book.

The return value is a (possibly empty) `Vector{BookEntry}`, sorted by
descending scores.
"""
function findbookentries(key::UInt64, bookfile = nothing)::Vector{BookEntry}
    if isnothing(bookfile)
        bookfile = joinpath(artifact"book", "default-book.obk")
    end
    result = Vector{BookEntry}()
    open(bookfile, "r") do f
        compact = read(f, UInt8) == 1
        entrysize = compact ? COMPACT_ENTRY_SIZE : ENTRY_SIZE
        entrycount = div(filesize(bookfile) - 1, entrysize)
        i = findkey(f, key, 0, entrycount - 1, entrysize)
        if !isnothing(i)
            for j = i:entrycount
                e = readentry(f, j, compact)
                if e.key == key
                    push!(result, e)
                else
                    break
                end
            end
        end
    end
    sort(result, by = e -> -e.score)
end

function findbookentries(b::Board, bookfile = nothing)::Vector{BookEntry}
    findbookentries(b.key, bookfile)
end


"""
    printbookentries(b::Board, bookfile = nothing)


Pretty-print the book entries for the provided board.

If `bookfile` is nothing, use the default built-in opening book.

The output columns have the following meanings:

* `move`: The move.
* `prob`: Probability that this move will be played when calling `pickbookmove`.
* `score`: Percentage score of this move in the games used to produce this
  book file.
* `won`: Number of games won with this move.
* `drawn`: Number of games drawn with this move.
* `lost`: Number of games lost with this move.
* `elo`: Maximum Elo of players that played this move.
* `oelo`: Maximum Elo of opponents against which this move was played.
* `first`: The first year this move was played.
* `last`: The last year this move was played.

# Examples

```julia-repl
julia> printbookentries(@startboard d4 Nf6 c4 e6 Nc3)
move     prob   score     won   drawn    lost    elo oelo  first last
Bb4    71.92%  48.18%   32327   35691   36120   3936 3936   1854 2020
d5     20.82%  40.46%    4481    6545    8137   3796 3796   1880 2020
c5      4.20%  43.13%    1560    1192    2247   3794 3851   1922 2020
b6      2.16%  34.51%     217     170     488   2652 2762   1902 2020
Be7     0.51%  27.47%      28      33     101   2585 2640   1911 2020
c6      0.20%  36.05%      13       5      25   2448 2670   1932 2020
g6      0.12%  31.94%       9       5      22   2289 2405   1943 2020
Nc6     0.06%  33.33%       6      10      17   3809 3809   1938 2020
```
"""
function printbookentries(b::Board, bookfile = nothing)
    entries = findbookentries(b, bookfile)
    scoresum = sum(map(e -> e.score, entries))
    printfmt(
        "{1:<5s} {2:>7s} {3:>7s} {4:>7s} {5:>7s} {6:>7s} {7:>6s} {8:>4s} {9:>6s} {10:>4s}\n",
        "move",
        "prob",
        "score",
        "won",
        "drawn",
        "lost",
        "elo",
        "oelo",
        "first",
        "last",
    )
    for e ∈ entries
        printfmt(
            "{1:<5s} {2:>6.2f}% {3:>6.2f}% {4:>7d} {5:>7d} {6:>7d} {7:>6d} {8:>4d} {9:>6d} {10:>4d}\n",
            movetosan(b, Move(e.move)),
            100 * e.score / scoresum,
            100 * ((e.wins + 0.5 * e.draws) / (e.wins + e.draws + e.losses)),
            e.wins,
            e.draws,
            e.losses,
            e.elo,
            e.oppelo,
            e.firstyear,
            e.lastyear,
        )
    end
end


"""
    pickbookmove(
        b::Board;
        bookfile = nothing,
        minscore = 0,
        mingamecount = 1
    )

Picks a book move for the board `b`, returning `nothing` when out of book.

If `bookfile` is `nothing`, uses the built-in default book.

The move is selected with probabilities given by the `score` slots in the
`BookEntry` objects. The `minscore` and `mingamecount` parameters can be used
to exclude moves with low score or low play counts.
"""
function pickbookmove(
    b::Board;
    bookfile = nothing,
    minscore = 0,
    mingamecount = 0,
)::Union{Move,Nothing}
    entries = filter(
        e -> e.wins + e.draws + e.losses >= mingamecount && e.score >= minscore,
        findbookentries(b, bookfile),
    )
    if length(entries) == 0
        nothing
    else
        w = Weights(map(e -> e.score, entries))
        Move(sample(entries, w).move)
    end
end


end # module
