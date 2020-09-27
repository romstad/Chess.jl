#=
WARNING:

The code in this file is in a very early stage of development. It is likely to
contain major bugs, and breaking changes are almost certainly going to happen.
Use at your own risk!
=#


module DB

using ..Chess, ..Chess.PGN
using SQLite

export createdb!, decodedbgame, insertgame!, pgntodb, readgame


const CONFIG_TABLE = """
    CREATE TABLE IF NOT EXISTS config(
        id INTEGER PRIMARY KEY CHECK (id = 1),
        version INTEGER NOT NULL CHECK (version = 1)
    )
    """

const GAMES_TABLE = """
    CREATE TABLE IF NOT EXISTS games(
        id INTEGER NOT NULL PRIMARY KEY,
        deleted INTEGER NOT NULL DEFAULT 0,
        event VARCHAR(50) NOT NULL,
        site VARCHAR(50) NOT NULL,
        date VARCHAR(20) NOT NULL,
        round VARCHAR(20) NOT NULL,
        white INTEGER NOT NULL,
        black INTEGER NOT NULL,
        result INTEGER NOT NULL,
        fen VARCHAR(100),
        whiteelo INTEGER,
        blackelo INTEGER,
        othertags TEXT,
        moves BLOB,
        FOREIGN KEY(white) REFERENCES players(id),
        FOREIGN KEY(black) REFERENCES players(id)
    )
    """


const PLAYERS_TABLE = """
    CREATE TABLE IF NOT EXISTS players(
        id INTEGER NOT NULL PRIMARY KEY,
        name VARCHAR(50) NOT NULL
    )
    """


"""
    createdb!(dbname::String)

Creates a database at the provided path name.
"""
function createdb!(dbname::String)
    db = SQLite.DB(dbname)
    SQLite.execute!(db, CONFIG_TABLE)
    SQLite.execute!(db, "INSERT INTO config VALUES (1, 1)")
    SQLite.execute!(db, PLAYERS_TABLE)
    SQLite.execute!(db, GAMES_TABLE)
end


function dbversion(db::SQLite.DB)
    q = SQLite.Query(db, "SELECT version FROM config")
    first(q)[:version]
end


function playerid(db::SQLite.DB, playername::String)
    q =
        SQLite.Query(db, "SELECT id FROM players WHERE name=?", values = [playername]) |>
        collect
    if !isempty(q)
        first(q)[:id]
    else
        SQLite.Query(db, "INSERT INTO players (name) VALUES (?)", values = [playername])
        q = SQLite.Query(db, "SELECT last_insert_rowid() AS id")
        first(q)[:id]
    end
end


function encoderesult(result::String)::Int
    if result == "1-0"
        0
    elseif result == "0-1"
        1
    elseif result == "1/2-1/2"
        2
    else
        3
    end
end


function decoderesult(result::Int)::String
    if result == 0
        "1-0"
    elseif result == 1
        "0-1"
    elseif result == 2
        "1/2-1/2"
    else
        "*"
    end
end


"""
    insertgame!(db::SQLite.DB, g::Union{SimpleGame, Game})
    insertgame!(dbname::String, g::Union{SimpleGame, Game})

Inserts a game into the database.

The game is added to the `games` table. If one or both players are missing
from the `players` table, they are added there.
"""
function insertgame!(db::SQLite.DB, g::Union{SimpleGame,Game})
    white = headervalue(g, "White")
    black = headervalue(g, "Black")
    event = headervalue(g, "Event")
    site = headervalue(g, "Site")
    date = headervalue(g, "Date")
    round = headervalue(g, "Round")
    result = headervalue(g, "Result")
    fen = headervalue(g, "FEN")
    welo = whiteelo(g)
    belo = blackelo(g)
    moves = encodemoves(g)

    white = playerid(db, white)
    black = playerid(db, black)

    SQLite.Query(
        db,
        "INSERT INTO games(event, site, date, round, white, black, result, fen, whiteelo, blackelo, othertags, moves) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        values = [
            event,
            site,
            date,
            round,
            white,
            black,
            encoderesult(result),
            isnothing(fen) ? missing : fen,
            isnothing(welo) ? missing : welo,
            isnothing(belo) ? missing : belo,
            missing,
            moves,
        ],
    )
end

function insertgame!(dbname::String, g::Union{SimpleGame,Game})
    db = SQLite.DB(dbname)
    insertgame!(db, g)
end


function decodedbgame(dbgame, annotations = false)
    result = if !ismissing(dbgame[:fen])
        decodemoves(dbgame[:moves], dbgame[:fen])
    else
        decodemoves(dbgame[:moves])
    end
    setheadervalue!(result, "White", dbgame[:white])
    setheadervalue!(result, "Black", dbgame[:black])
    setheadervalue!(result, "Event", dbgame[:event])
    setheadervalue!(result, "Site", dbgame[:site])
    setheadervalue!(result, "Date", dbgame[:white])
    setheadervalue!(result, "Round", dbgame[:white])
    setheadervalue!(result, "White", dbgame[:white])
    setheadervalue!(result, "Result", decoderesult(dbgame[:result]))
    if !ismissing(dbgame[:whiteelo])
        setheadervalue!(result, "WhiteElo", string(dbgame[:whiteelo]))
    end
    if !ismissing(dbgame[:blackelo])
        setheadervalue!(result, "BlackElo", string(dbgame[:blackelo]))
    end
    result
end


"""
    readgame(db::SQLite.DB, id::Int; annotations = false)
    readgame(dbname::String, id::Int; annotations = false)

Reads a game from the database.

If there is no game with the provided ID, returns `nothing`. If there is a
game with the provided ID, returns a `SimpleGame` if `annotations` is `false`,
and a `Game` if `annotations` is `true`.
"""
function readgame(db::SQLite.DB, id::Int; annotations = false)
    qstr = """
        SELECT g.id, g.event, g.site, g.date, g.round,
               w.name AS white, b.name AS black,
               g.result, g.fen, g.whiteelo, g.blackelo, g.othertags, g.moves
        FROM games g
        JOIN players w ON w.id = g.white
        JOIN players b ON b.id = g.black
        WHERE g.id = ?
    """
    q = SQLite.Query(db, qstr, values = [id])
    if !isempty(q)
        decodedbgame(first(q))
    end
end

function readgame(dbname::String, id::Int; annotations = false)
    db = SQLite.DB(dbname)
    readgame(db, id, annotations = annotations)
end


function pgntodb(pgnfilename::String, dbfilename::String; annotations = false)
    createdb!(dbfilename)
    db = SQLite.DB(dbfilename)
    gamecount = 0
    for g ∈ gamesinfile(pgnfilename, annotations = annotations)
        insertgame!(db, g)
        gamecount += 1
        if gamecount % 1000 == 0
            println("$gamecount games converted")
        end
    end
end


end # module
