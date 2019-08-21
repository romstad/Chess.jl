# Manual

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
julia> g = Game();
```

There is also a version of this constructor that takes a string representing a
board in [Forsyth-Edwards
Notation](https://en.wikipedia.org/wiki/Forsyth–Edwards_Notation), and uses that
instead of the standard chess starting position as the root position of the
game.

You can pretty-print the current board position of the game as follows:

```julia-repl
julia> pprint(board(g))
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

In this example, `board` is a function that returns the current board position
of the game, a value of type `Board`, which is described in detail later in this
manual. The `pprint` function pretty-prints a board to the standard output.

To update the game with a new move, use the `domove!` function:

```julia-repl
julia> domove!(g, "e4");

julia> pprint(board(g))
+---|---|---|---|---|---|---|---+
| r | n | b | q | k | b | n | r |
+---|---|---|---|---|---|---|---+
| p | p | p | p | p | p | p | p |
+---|---|---|---|---|---|---|---+
|   |   |   |   |   |   |   |   |
+---|---|---|---|---|---|---|---+
|   |   |   |   |   |   |   |   |
+---|---|---|---|---|---|---|---+
|   |   |   |   | P |   |   |   |
+---|---|---|---|---|---|---|---+
|   |   |   |   |   |   |   |   |
+---|---|---|---|---|---|---|---+
| P | P | P | P |   | P | P | P |
+---|---|---|---|---|---|---|---+
| R | N | B | Q | K | B | N | R |
+---|---|---|---|---|---|---|---+
rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq -
```

A move can be taken back by the `back!` function:

```julia-repl
julia> back!(g);

julia> pprint(board(g))
+---|---|---|---|---|---|---|---+
| r | n | b | q | k | b | n | r
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

The move we made earlier is not removed from the game, only our current position
in the game is modified. It's possible to step forward again by executing
`forward!(g)`. There are also functions `tobeginning!` and `toend!` that goes
all the way to the beginning or the end of the game.

## Boards

## Squares, Moves and Pieces

## PGN Import and Export

## Interacting with UCI Engines
