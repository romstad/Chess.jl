# Manual

## Boards

### Creating Boards

A chess board is represented by the `Board` type. A board is usually obtained in
one of four ways:

1. By calling the `startboard()` function, which returns a board initialized to
   the standard chess opening position.
2. By calling the `fromfen(fen::String)` function, which takes a board string in
   [Forsyth-Edwards
   Notation](https://en.wikipedia.org/wiki/Forsyth–Edwards_Notation) and returns
   the corresponding board.
3. By making a move or a sequence of moves on an existing chess board, using a
   function like `domove()` or `domoves()`.
4. By calling the `board()` function on a `Game` or a `SimpleGame`, obtaining
   the current board position in a game. See the section about games below for a
   discussion of this.

Boards are printed in a readable ASCII notation:

```julia-repl
julia> startboard()
Board (rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -):
 r  n  b  q  k  b  n  r
 p  p  p  p  p  p  p  p
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 P  P  P  P  P  P  P  P
 R  N  B  Q  K  B  N  R
```

### Making and Unmaking Moves

Given a chess board, you will usually want to modify the board by making some
moves. The most straightforward way to do this is with the `domove` function,
which takes two parameters: A chess board and a move. The move can be either a
value of the `Move` type or a string representing a move in UCI or SAN notation.

The `Move` type is described in more detail in the API reference. For now, let's
see how to use `domove` to make a move given in short algebraic notation (SAN):

```julia-repl
julia> domove(b, "e4")
Board (rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq -):
 r  n  b  q  k  b  n  r
 p  p  p  p  p  p  p  p
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  P  -  -  -
 -  -  -  -  -  -  -  -
 P  P  P  P  -  P  P  P
 R  N  B  Q  K  B  N  R
```

There is also a function `domoves` that takes a series of several moves and
executes all of them:

```julia
julia> b = startboard();

julia> domoves(b, "e4", "e5", "Nf3", "Nc6", "Bb5")
Board (r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R b KQkq -):
 r  -  b  q  k  b  n  r
 p  p  p  p  -  p  p  p
 -  -  n  -  -  -  -  -
 -  B  -  -  p  -  -  -
 -  -  -  -  P  -  -  -
 -  -  -  -  -  N  -  -
 P  P  P  P  -  P  P  P
 R  N  B  Q  K  -  -  R
```

Note that both of these functions return new boards: The original board `b` is
left untouched. This is often convenient, but also results in a considerable
amount of copying, and for some types of applications, excessive heap
allocations. When this is a problem, there are alternative functions `domove!`
and `domoves!` that do modify the input board.

The `domove!` function destructively modifies the input board by making a move,
but returns an `UndoInfo` value that can later be used to retract the move,
using the `undomove!` function:

```julia-repl
julia> b = startboard();

julia> u = domove!(b, "d4");

julia> b
Board (rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq -):
 r  n  b  q  k  b  n  r
 p  p  p  p  p  p  p  p
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  P  -  -  -  -
 -  -  -  -  -  -  -  -
 P  P  P  -  P  P  P  P
 R  N  B  Q  K  B  N  R

julia> undomove!(b, u);

julia> b
Board (rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -):
 r  n  b  q  k  b  n  r
 p  p  p  p  p  p  p  p
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 P  P  P  P  P  P  P  P
 R  N  B  Q  K  B  N  R
```

Similarly, `domoves!` takes a board and a sequence of moves and executes them
all, destructively modifying the board. Unlike `domove!`, this operation is
irreversible. There is no way to retract the moves and return to the original
board.

### Extracting Information from a Board

For the purposes of this section, we'll construct an early opening position from
a popular Ruy Lopez line:

```julia-repl
julia> b = domoves(startboard(), "e4", "e5", "Nf3", "Nc6", "Bb5", "Nf6", "O-O")
Board (r1bqkb1r/pppp1ppp/2n2n2/1B2p3/4P3/5N2/PPPP1PPP/RNBQ1RK1 b kq -):
 r  -  b  q  k  b  -  r
 p  p  p  p  -  p  p  p
 -  -  n  -  -  n  -  -
 -  B  -  -  p  -  -  -
 -  -  -  -  P  -  -  -
 -  -  -  -  -  N  -  -
 P  P  P  P  -  P  P  P
 R  N  B  Q  -  R  K  -
```

To ask what piece occupies a given square, use the `pieceon` function, which
takes two arguments: A board and a square. The square can be either a `Square`
value (discussed in the API reference) or a string. The return value is a
`Piece`, which can have one of the values `EMPTY` (for an empty square),
`PIECE_WP`, `PIECE_WN`, `PIECE_WB`, `PIECE_WR`, `PIECE_WQ`, `PIECE_WK`,
`PIECE_BP`, `PIECE_BN`, `PIECE_BB`, `PIECE_BR`, `PIECE_BQ` or `PIECE_BK`:

```julia-repl
julia> pieceon(b, "e4")
PIECE_WP

julia> pieceon(b, "b8")
EMPTY
```

It is also possible to ask for the set of all squares occupied by pieces of a
given color and/or type. Here is an example that returns the set of all squares
occupied by white pawns:

```julia-repl
julia> pawns(b, WHITE)
SquareSet:
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  #  -  -  -
 -  -  -  -  -  -  -  -
 #  #  #  #  -  #  #  #
 -  -  -  -  -  -  -  -
```

The return value is of type `SquareSet`, which is discussed in depth in the API
reference.

Here is a similar example that returns all squares occupied by black pieces:

```julia-repl
julia> pieces(b, BLACK)
SquareSet:
 #  -  #  #  #  #  -  #
 #  #  #  #  -  #  #  #
 -  -  #  -  -  #  -  -
 -  -  -  -  #  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
```

A few other functions returning square sets are `knights`, `bishops`, `rooks`,
`queens`, `kings`, `emptysquares` and `occupiedsquares`.

The function `sidetomove` returns the current side to move, in the form of a
`PieceColor` value that can be either `WHITE` or `BLACK`:

```julia-repl
julia> sidetomove(b)
BLACK
```

A few other functions that are frequently useful when inspecting boards are
`ischeck` (is the side to move in check?), `ischeckmate` (is the side to move
checkmated?) and `isdraw` (is the position an immediate draw?).

### Generating Legal Moves

The legal moves for a board can be obtained with the `moves` function:

```julia-repl
julia> b = fromfen("8/5P2/3k4/8/8/6N1/3B4/4KR2 w - -")
Board (8/5P2/3k4/8/8/6N1/3B4/4KR2 w - -):
 -  -  -  -  -  -  -  -
 -  -  -  -  -  P  -  -
 -  -  -  k  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  N  -
 -  -  -  B  -  -  -  -
 -  -  -  -  K  R  -  -

julia> moves(b)
27-element MoveList:
 Move(f7f8q)
 Move(f7f8r)
 Move(f7f8b)
 Move(f7f8n)
 Move(g3e4)
 Move(g3e2)
 Move(g3f5)
 Move(g3h5)
 ⋮
 Move(f1f4)
 Move(f1f3)
 Move(f1f2)
 Move(f1g1)
 Move(f1h1)
 Move(e1d1)
 Move(e1e2)
 Move(e1f2)
```

The return value is a `MoveList`, a subtype of `AbstractArray`. It contains all
the legal moves for the position.

Here is an example of a simple way to find all moves that give check for the
above board:

```julia-repl
julia> filter(m -> ischeck(domove(b, m)), moves(b))
7-element Array{Move,1}:
 Move(f7f8q)
 Move(f7f8b)
 Move(g3e4)
 Move(g3f5)
 Move(d2b4)
 Move(d2f4)
 Move(f1f6)
```

## Games

There are two types for representing chess games: `SimpleGame` is a basic type
that contains little more than PGN headers (player names, game result, etc.) and
a sequence of moves. `Game` is a more full-featured type that supports
annotated, tree-like games with comments and variations. If you don't need these
features, `SimpleGame` is usually a better choice, because it performs much
better.

For the rest of this section, we will only discuss the more complex `Game` type.
With a few exceptions (that will be pointed out), methods with identical names
and behavior exist for the `SimpleGame` type.

To create a game from the standard chess position, use the parameterless `Game`
constructor:

```julia-repl
julia> g = Game()
Game:
  *
```

The printed representation of the game consists of the moves in short algebraic
notation (in this case, because we just constructed a game, there are no moves)
and an asterisk (`*`) showing our current position in the game.

There is also a version of this constructor that takes a string representing a
board in [Forsyth-Edwards
Notation](https://en.wikipedia.org/wiki/Forsyth–Edwards_Notation), and uses that
instead of the standard chess starting position as the root position of the
game.

You can obtain the current position board position of the game with the `board`
function, which returns a value of type `Board`:

```julia-repl
julia> board(g)
Board (rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -):
 r  n  b  q  k  b  n  r
 p  p  p  p  p  p  p  p
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 P  P  P  P  P  P  P  P
 R  N  B  Q  K  B  N  R
```

To update the game with a new move, use the `domove!` function:

```julia-repl
julia> domove!(g, "Nf3")
Game:
 Nf3 *

julia> domove!(g, "d5")
Game:
 Nf3 d5 *

julia> domove!(g, "d4")
Game:
 Nf3 d5 d4 *
```

A move can be taken back by the `back!` function:

```julia-repl
julia> back!(g)
Game:
 Nf3 d5 * d4
```

Note that the last move, d4, is not removed from the game. It's still there, the
only result of calling `back!` is that our *current location in the game*
(indicated by the asterisk) moved one step back. The current board position is
the one before the move `d4` was made:

```julia-repl
julia> board(g)
Board (rnbqkbnr/ppp1pppp/8/3p4/8/5N2/PPPPPPPP/RNBQKB1R w KQkq -):
 r  n  b  q  k  b  n  r
 p  p  p  -  p  p  p  p
 -  -  -  -  -  -  -  -
 -  -  -  p  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  N  -  -
 P  P  P  P  P  P  P  P
 R  N  B  Q  K  B  -  R
```

It's possible to step forward again by executing `forward!(g)`:

```julia-repl
julia> forward!(g)
Game:
 Nf3 d5 d4 *

julia> board(g)
Board (rnbqkbnr/ppp1pppp/8/3p4/3P4/5N2/PPP1PPPP/RNBQKB1R b KQkq -):
 r  n  b  q  k  b  n  r
 p  p  p  -  p  p  p  p
 -  -  -  -  -  -  -  -
 -  -  -  p  -  -  -  -
 -  -  -  P  -  -  -  -
 -  -  -  -  -  N  -  -
 P  P  P  -  P  P  P  P
 R  N  B  Q  K  B  -  R
```

There are also functions `tobeginning!` and `toend!` that jump all the way to the beginning or
the end of the game (notice the position of the asterisk indicating the current
location in the game in both cases):

```julia-repl
julia> tobeginning!(g)
Game:
 * Nf3 d5 d4

julia> toend!(g)
Game:
 Nf3 d5 d4 *
```

If you call `domove!` at any point other than the end of the game, the previous
game continuation will be deleted:

```julia-repl
julia> toend!(g)
Game:
 Nf3 d5 d4 *

julia> back!(g)
Game:
 Nf3 d5 * d4

julia> domove!(g, "c4")
Game:
 Nf3 d5 c4 *
```

This is not always desirable. Sometimes what we want to do is not to overwrite
the existing continuation, but to insert a new variation. When this is what we
want, the solution is to use `addmove!` instead of `domove!`. The two functions
behave identically when at the end of the game, but at any earlier point of the
game, `addmove!` inserts the new move as an alternative variation, keeping the
existing move (and any previously added variations).

Let's add 1... Nf6 as an alternative to 1... d5 in our existing game. We first
have to navigate to the place in the game where we want to insert the move, and
then call `addmove!`:

```julia-repl
julia> tobeginning!(g)
Game:
 * Nf3 d5 c4

julia> forward!(g)
Game:
 Nf3 * d5 c4

julia> addmove!(g, "Nf6")
Game:
 Nf3 d5 (Nf6 *) c4
```

Alternative variations are printed in parens. Of course, variations can be nested.

## PGN Import and Export

This section describes import and export of chess games in the popular
[PGN format](https://www.chessclub.com/help/PGN-spec). PGN is a rather awkward
and complicated format, and a lot of the "PGN files" out there on the Internet
don't quite follow the standard, and are broken in various ways. The functions
described in this section does a fairly good job of handling correct PGNs
(although bugs are possible), but will often fail on the various not-quite-PGNs
found on the Internet.

### Creating a game from a PGN string

Given a PGN string, the `gamefrompgn` function creates a game object from the
string (throwing a `PGNException` on failure). By default, the return value is
a `SimpleGame` containing only the moves of the game, without any comments,
variations or numeric annotatin glyphs. If the optional named parameter
`annotations` is `true`, the return value is a `Game` with all annotations
included:

```julia-repl
julia> pgnstring = """
       [Event "F/S Return Match"]
       [Site "Belgrade, Serbia JUG"]
       [Date "1992.11.04"]
       [Round "29"]
       [White "Fischer, Robert J."]
       [Black "Spassky, Boris V."]
       [Result "1/2-1/2"]

       1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3
       O-O 9. h3 Nb8 10. d4 Nbd7 11. c4 c6 12. cxb5 axb5 13. Nc3 Bb7 14. Bg5 b4 15.
       Nb1 h6 16. Bh4 c5 17. dxe5 Nxe4 18. Bxe7 Qxe7 19. exd6 Qf6 20. Nbd2 Nxd6 21.
       Nc4 Nxc4 22. Bxc4 Nb6 23. Ne5 Rae8 24. Bxf7+ Rxf7 25. Nxf7 Rxe1+ 26. Qxe1 Kxf7
       27. Qe3 Qg5 28. Qxg5 hxg5 29. b3 Ke6 30. a3 Kd6 31. axb4 cxb4 32. Ra5 Nd5 33.
       f3 Bc8 34. Kf2 Bf5 35. Ra7 g6 36. Ra6+ Kc5 37. Ke1 Nf4 38. g3 Nxh3 39. Kd2 Kb5
       40. Rd6 Kc5 41. Ra6 Nf2 42. g4 Bd3 43. Re6 1/2-1/2
       """;

julia> sg = gamefromstring(pgnstring)
SimpleGame:
 * e4 e5 Nf3 Nc6 Bb5 a6 Ba4 Nf6 O-O Be7 Re1 b5 Bb3 d6 c3 O-O h3 Nb8 d4 Nbd7 c4 c6 cxb5 axb5 Nc3 Bb7 Bg5 b4 Nb1 h6 Bh4 c5 dxe5 Nxe4 Bxe7 Qxe7 exd6 Qf6 Nbd2 Nxd6 Nc4 Nxc4 Bxc4 Nb6 Ne5 Rae8 Bxf7+ Rxf7 Nxf7 Rxe1+ Qxe1 Kxf7 Qe3 Qg5 Qxg5 hxg5 b3 Ke6 a3 Kd6 axb4 cxb4 Ra5 Nd5 f3 Bc8 Kf2 Bf5 Ra7 g6 Ra6+ Kc5 Ke1 Nf4 g3 Nxh3 Kd2 Kb5 Rd6 Kc5 Ra6 Nf2 g4 Bd3 Re6

julia> g = gamefromstring(pgnstring, annotations=true)
Game:
 * e4 e5 Nf3 Nc6 Bb5 a6 Ba4 Nf6 O-O Be7 Re1 b5 Bb3 d6 c3 O-O h3 Nb8 d4 Nbd7 c4 c6 cxb5 axb5 Nc3 Bb7 Bg5 b4 Nb1 h6 Bh4 c5 dxe5 Nxe4 Bxe7 Qxe7 exd6 Qf6 Nbd2 Nxd6 Nc4 Nxc4 Bxc4 Nb6 Ne5 Rae8 Bxf7+ Rxf7 Nxf7 Rxe1+ Qxe1 Kxf7 Qe3 Qg5 Qxg5 hxg5 b3 Ke6 a3 Kd6 axb4 cxb4 Ra5 Nd5 f3 Bc8 Kf2 Bf5 Ra7 g6 Ra6+ Kc5 Ke1 Nf4 g3 Nxh3 Kd2 Kb5 Rd6 Kc5 Ra6 Nf2 g4 Bd3 Re6
```

Unless you really need the annotations, importing to a `SimpleGame` is the
preferred choice. A `SimpleGame` is much faster to create and consumes less
memory.

Converting a game to a PGN string is done by the `gametopgn` function. This
works for both `SimpleGame` and `Game` objects:

```julia-repl
julia> gametopgn(sg)
"[Event \"F/S Return Match\"]\n[Site \"Belgrade, Serbia JUG\"]\n[Date \"1992.11.04\"]\n[Round \"29\"]\n[White \"Fischer, Robert J.\"]\n[Black \"Spassky, Boris V.\"]\n[Result \"1/2-1/2\"]\n\n1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Nb8 10. d4 Nbd7 11. c4 c6 12. cxb5 axb5 13. Nc3 Bb7 14. Bg5 b4 15. Nb1 h6 16. Bh4 c5 17. dxe5 Nxe4 18. Bxe7 Qxe7 19. exd6 Qf6 20. Nbd2 Nxd6 21. Nc4 Nxc4 22. Bxc4 Nb6 23. Ne5 Rae8 24. Bxf7+ Rxf7 25. Nxf7 Rxe1+ 26. Qxe1 Kxf7 27. Qe3 Qg5 28. Qxg5 hxg5 29. b3 Ke6 30. a3 Kd6 31. axb4 cxb4 32. Ra5 Nd5 33. f3 Bc8 34. Kf2 Bf5 35. Ra7 g6 36. Ra6+ Kc5 37. Ke1 Nf4 38. g3 Nxh3 39. Kd2 Kb5 40. Rd6 Kc5 41. Ra6 Nf2 42. g4 Bd3 43. Re6 1/2-1/2\n"

julia> gametopgn(g)
"[Event \"F/S Return Match\"]\n[Site \"Belgrade, Serbia JUG\"]\n[Date \"1992.11.04\"]\n[Round \"29\"]\n[White \"Fischer, Robert J.\"]\n[Black \"Spassky, Boris V.\"]\n[Result \"1/2-1/2\"]\n\n1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Nb8 10. d4 Nbd7 11. c4 c6 12. cxb5 axb5 13. Nc3 Bb7 14. Bg5 b4 15. Nb1 h6 16. Bh4 c5 17. dxe5 Nxe4 18. Bxe7 Qxe7 19. exd6 Qf6 20. Nbd2 Nxd6 21. Nc4 Nxc4 22. Bxc4 Nb6 23. Ne5 Rae8 24. Bxf7+ Rxf7 25. Nxf7 Rxe1+ 26. Qxe1 Kxf7 27. Qe3 Qg5 28. Qxg5 hxg5 29. b3 Ke6 30. a3 Kd6 31. axb4 cxb4 32. Ra5 Nd5 33. f3 Bc8 34. Kf2 Bf5 35. Ra7 g6 36. Ra6+ Kc5 37. Ke1 Nf4 38. g3 Nxh3 39. Kd2 Kb5 40. Rd6 Kc5 41. Ra6 Nf2 42. g4 Bd3 43. Re6 1/2-1/2\n"
```

### Working with PGN files

Given a file with one or more PGN games, the function `gamesinfile` returns a
`Channel` of game objects, one for each game in the file. Like `gamefromstring`,
`gamesinfile` takes an optional named parameter `annotations`. If `annotations`
is `false` (the default), you get a channel of `SimpleGame`s. If it's `true`,
you get a channel of `Game`s with the annotations (comments, variations and
numeric annotation glyphs) included in the PGN games.

As an example, here's a function that scans a PGN file and returns a vector
of all games that end in checkmate:

```julia
function checkmategames(pgnfilename::String)
    result = SimpleGame[]
    for g in gamesinfile(pgnfilename)
        toend!(g)
        if ischeckmate(g)
            push!(result, g)
        end
    end
    result
end
```

## Opening Books

The `Chess.Book` module contains utilities for processing PGN game files and
building opening trees with move statistics, and for looking up board positions
in an opening tree.

### Creating Book Files

To create an opening book, use the `createbook` function, and supply it with
one or more PGN files:

```julia-repl
julia> using Chess, Chess.Book

julia> bk = createbook("/path/to/SomeGameDatabase.pgn");
```

`createbook` also accepts a number of optional named parameters that configure
the scoring of the book moves and what moves are included and excluded. See the
function documentation for details.

Please note that while Chess.jl's PGN parser works pretty well for processing
correct PGN, it's not very robust when it comes to parsing "PGN files" that fail
to follow the standard. Annoyingly, even popular software like ChessBase
sometimes generate broken PGN files (failing to escape quotes in strings is a
particularly frequent problem). If you feed `createbook` with a non-standard PGN
file, it will often fail.

For large databases with millions of games, creating a book consumes a lot of
memory, since all the data is stored in RAM.

The first thing you want to do after creating an opening book is probably to
write it to disk. Assuming that we stored the result of `createbook` in a
variable `bk`, like above, we save the book like this:

```julia-repl
julia> writebooktofile(bk, "/path/to/mybook.obk")
```

Opening book files can be very large, because they contain every move that has
been played even once in the input PGN databases. The function `purgebook` can
create a smaller book from a large book by only including moves which have been
played several times and/or have high scores (the *score* of a move is computed
based on how well it has been formed and by how popular it is, with more weight
being given to recent games and games played by strong players). `purgebook` has
two required parameters, an input file name and an output file name. The
optional named parameters `minscore` (default 0) and `mingamecount` (default 5)
control what moves are included in the output file.

Example usage:

```julia-repl
julia> purgebook("/path/to/mybook.obk", "/path/to/mybook-small.obk", minscore=0.01, mingamecount=10)
```

### Looking Up Positions in a Book File

Given a `Board` value and an opening book file, the function `findbookentries`
find all the opening book entries for that board position. For instance, this
gives us all book moves for the standard opening position:

```julia-repl
julia> b = startboard();

julia> entries = findbookentries(b, "/path/to/mybook.obk");
```
The return value is a vector of `BookEntry` structs. This struct contains the
following slots:

- `move`: The move played. For space reasons, the move is stored as an `Int32`
  value. To get the actual `Move`, do `Move(entry.move)`.
- `wins`: The number of times the player who played this move won the game.
- `draws`: The number of times the game was drawn when this move was played.
- `losses`: The number of times the player who played this move lost the game.
- `elo`: The Elo rating of the highest rated player who played this move.
- `oppelo`: The Elo rating of the highest rated opponent against whom this move
  was played.
- `firstyear`: The first year this move was played.
- `lastyear`: The last year this move was played.
- `score`: The score of the move, used to decide the probability that this move
  is played when picking a book move to play. The score is computed based on the
  move's win/loss/draw statistics and its popularity, especially in recent games
  and games with strong players.

To print out the stats for all moves for a position, use `printbookentries`:

```julia-repl
julia> printbookentries(startboard(), "/path/to/mybook.obk")
e4 0.479 53.5% (+359254, =342397, -290198) 2881 2881 1990 2018
d4 0.343 55.1% (+283148, =280733, -204292) 2881 2881 1990 2018
Nf3 0.092 55.9% (+79513, =82970, -54128) 2881 2881 1990 2018
c4 0.064 55.6% (+53691, =52039, -37534) 2881 2881 1990 2018
g3 0.007 56.0% (+6639, =5986, -4584) 2868 2851 1990 2018
b3 0.006 51.9% (+3532, =3060, -3154) 2857 2881 1990 2018
f4 0.004 45.0% (+2093, =1974, -2775) 2837 2843 1990 2018
Nc3 0.002 49.1% (+1247, =991, -1309) 2834 2851 1990 2018
b4 0.001 44.9% (+535, =431, -704) 2834 2795 1990 2018
e3 0.001 43.6% (+269, =219, -381) 2857 2843 1990 2018
d3 0.000 47.3% (+242, =216, -282) 2843 2819 1990 2018
a3 0.000 48.2% (+223, =182, -246) 2834 2771 1991 2018
c3 0.000 44.0% (+98, =100, -138) 2773 2767 1991 2018
g4 0.000 38.6% (+55, =43, -100) 2795 2795 1991 2018
h3 0.000 48.4% (+47, =30, -51) 2834 2782 1990 2018
h4 0.000 32.6% (+10, =8, -25) 2545 2722 1994 2018
Nh3 0.000 47.5% (+13, =12, -15) 2834 2653 1993 2018
Na3 0.000 68.8% (+9, =4, -3) 2834 2528 1992 2018
a4 0.000 59.4% (+7, =5, -4) 2843 2788 1996 2018
f3 0.000 36.7% (+4, =3, -8) 2834 2843 1999 2018
```

On each output line, we see the move, the probability that this move will be
picked (by `pickbookmove`, described below), the percentage score from the point
of view of the side to move, the number of wins, draws and losses, the maximum
rating, the maximum opponent rating, the first year played, and the last year
played.

To pick a book move, use `pickbookmove`:

```julia-repl
julia> b = domoves(startboard(), "e4", "c5");

julia> pickbookmove(b, "/path/to/mybook.obk", minscore=0.01, mingamecount=10)
Move(g1f3)
```

The optional parameters `minscore` and `mingamecount` are used when you want to
prevent moves that have almost never been played or have a very low score from
being picked.

If no book moves is found for the input position, `pickbookmove` returns
`nothing`.

## Interacting with UCI Engines

This section describes how to run and interact with chess engines using the
[Universal Chess Interface](http://wbec-ridderkerk.nl/html/UCIProtocol.html)
protocol. There are hundreds of UCI chess engines out there. A free, strong
and popular choice is [Stockfish](https://stockfishchess.org). Stockfish is
used as an example in this section, but any other engine should work just as
well.

For the remainder of this section, it is assumed that you know the basics of
how the UCI protocol works, and that `stockfish` is found somewhere in your
`PATH` environment variable

An engine is started by calling the `runengine` command, which takes the path
to the engine as a parameter:

```julia-repl
julia> using Chess, Chess.UCI

julia> sf = runengine("stockfish");
```

The first thing you want to do after starting a chess engine is probably to
set some UCI parameter values. This can be done with `setoption`:

```julia-repl
julia> setoption(sf, "Hash", 256)
```

You can send a game to the engine with `setboard`:

```julia-repl
julia> g = SimpleGame();

julia> domoves!(g, "f4", "e5", "fxe5", "d6", "exd6", "Bxd6", "Nc3")

julia> setboard(sf, g)
```

The second parameter to `setboard` can also be a `Board` or a `Game`.

To ask the engine to search the position you just sent to it, use the `search`
function. `search` has two required parameters: The engine and the UCI `go`
command we want to send to it. There is also an optional named parameter
`infoaction`. This parameter is a function that takes each of the engine's
`info` output lines and does something to them. Here's an example where we just
print the engine output with `println` as our `infoaction`:

```julia-repl
julia> search(sf, "go depth 10", infoaction=println)
info depth 1 seldepth 1 multipv 1 score cp 275 nodes 42 nps 21000 tbhits 0 time 2 pv d6c5
info depth 2 seldepth 2 multipv 1 score cp 93 nodes 118 nps 59000 tbhits 0 time 2 pv d6c5 g2g3
info depth 3 seldepth 3 multipv 1 score cp 83 nodes 207 nps 103500 tbhits 0 time 2 pv a7a6 g2g3 d6c5
info depth 4 seldepth 4 multipv 1 score cp 23 nodes 809 nps 404500 tbhits 0 time 2 pv g8h6 d2d4 h6g4 g2g3
info depth 5 seldepth 6 multipv 1 score cp -22 nodes 1669 nps 556333 tbhits 0 time 3 pv g8e7 e2e3 e8g8 g1f3 f8e8 d2d4
info depth 6 seldepth 7 multipv 1 score mate 3 nodes 2293 nps 764333 tbhits 0 time 3 pv d8h4 g2g3 d6g3 h2g3
info depth 7 seldepth 6 multipv 1 score mate 3 nodes 2337 nps 779000 tbhits 0 time 3 pv d8h4 g2g3 d6g3 h2g3 h4g3
info depth 8 seldepth 6 multipv 1 score mate 3 nodes 2387 nps 795666 tbhits 0 time 3 pv d8h4 g2g3 d6g3 h2g3 h4g3
info depth 9 seldepth 6 multipv 1 score mate 3 nodes 2436 nps 812000 tbhits 0 time 3 pv d8h4 g2g3 d6g3 h2g3 h4g3
info depth 10 seldepth 6 multipv 1 score mate 3 nodes 2502 nps 625500 tbhits 0 time 4 pv d8h4 g2g3 d6g3 h2g3 h4g3
BestMoveInfo (best=d8h4, ponder=g2g3)
```

The return value is a `BestMoveInfo`, a struct containing the two slots
`bestmove` (the best move returned by the engine, a `Move`) and `ponder` (the
ponder move returned by the engine, a `Move` or `nothing`).

In most cases, we want something more easily manipulatable than the raw string
values sent by the engine's `info` lines in our `infoaction` function. The
function `parseinfoline` takes care of this. It takes an `info` string as input
and returns a `SearchInfo` value, a struct that contains the various components
of the `info` line as its slots. See the documentation for `SearchInfo` in the
API reference for details.
