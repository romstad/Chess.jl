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

An even more readable way to print a chess board at the REPL is by using the
`pprint` function:

```julia-repl
julia> pprint(startboard());
+---|---|---|---|---|---|---|---+
| r | n | b | q | k | b | n | r |
+---|---|---|---|---|---|---|---+
| p | p | p | p | p | p | p | p |
+---|---|---|---|---|---|---|---+
|   |   |   |   |   |   |   |   |
+---|---|---|---|---|---|---|---+
|   |   |   |   |   |   |   |   |
+---|---|---|---|---|---|---|---+
|   |   |   |   |   |   |   |   |
+---|---|---|---|---|---|---|---+
|   |   |   |   |   |   |   |   |
+---|---|---|---|---|---|---|---+
| P | P | P | P | P | P | P | P |
+---|---|---|---|---|---|---|---+
| R | N | B | Q | K | B | N | R |
+---|---|---|---|---|---|---|---+
rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -
```

### Making and Unmaking Moves

Given a chess board, you will usually want to modify the board by making some
moves. The most straightforward way to do this is with the `domove` function,
which takes two parameters: A chess board and a move. The move can be either a
value of the `Move` type or a string representing a move in UCI or SAN notation.

The `Move` type is described in more detail later. For now, let's see how to use
`domove` to make a move given by short algebraic notation (SAN):

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
value (discussed in the "Low-level Types" section of this manual) or a string.
The return value is a `Piece`, which can have one of the values `EMPTY` (for an
empty square), `PIECE_WP`, `PIECE_WN`, `PIECE_WB`, `PIECE_WR`, `PIECE_WQ`,
`PIECE_WK`, `PIECE_BP`, `PIECE_BN`, `PIECE_BB`, `PIECE_BR`, `PIECE_BQ` or
`PIECE_BK`:

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

The return value is of type `SquareSet`, which will be discussed in depth later
in this manual.

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

## Squares, Moves and Pieces

## PGN Import and Export

## Interacting with UCI Engines
