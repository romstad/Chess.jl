# Tutorial

Chess.jl is designed to work well with [Pluto](https://plutojl.org). For
interactive use, working with Chess.jl under Pluto is much nicer than from the
Julia REPL. A slightly modified version of this tutorial also exists as a Pluto
notebook, available from [this
link](https://romstad.github.io/Chess.jl/tutorial/tutorial.jl). In order to run
it, follow these steps:

1. Make sure you have Julia 1.6 or later installed.
2. Add the packages Chess, Pluto and PlutoUI to your environment.
3. From the Julia REPL, do:

```julia-repl
julia> using PlutoUI

julia> Pluto.run()
```

Pluto will now open in a browser window. In the "Open from file" textbox,
navigate to the location of the downloaded `tutorial.jl` file, and press "Open".

There is also a [static HTML version of the
tutorial notebook](https://romstad.github.io/Chess.jl/tutorial/). Even if you
have no interest in using Chess.jl with Pluto, the notebook may be easier to
read, because of the graphical chess boards.

## Boards

### Creating boards

A chess board is represented by the `Board` type. A board is usually obtained in
one of five ways:

1. By calling the `startboard()` function, which returns a board initialized to
   the standard chess opening position.
2. By using the `@startboard` macro, which allows you to provide a sequence of
   moves from the starting position.
3. By calling the `fromfen()` function, which takes a board string in
   [Forsyth-Edwards
   Notation](https://en.wikipedia.org/wiki/Forsyth–Edwards_Notation) and returns
   the corresponding board.
4. By making a move or a sequence of moves on an existing chess board, using a
   function like `domove()` or `domoves()`.
5. By calling the `board()` function on a `Game` or a `SimpleGame`, obtaining
   the current board position in a game. See the section on games later in this
   tutorial for a discussion of these types)

Let's begin with the most basic way of creating a chess board: The
`startboard()` function.

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

If you are using Chess.jl through a Pluto or Jupyter notebook, you'll see a
graphical board, along with a link for opening the board in
[lichess](http://lichess.org).

Sometimes you want to set up a board position by making some moves from the
starting position. You could do this by first calling `startboard()` and then
calling the `domoves()` or `domoves!()` function (more about those later in this
tutorial), but that quickly becomes tedious for interactive use. The
`@startboard` macro can be used as a convenient shortcut:

```julia-repl
julia> @startboard e4 e5 Nf3 Nc6 Bb5
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

Annoyingly, the minus sign in standard castling notation (`O-O` for kingside
castling and `O-O-O` for queenside castling) confuses Julia's parser. For
castling moves, just skip the minus sign and write `OO` or `OOO`, as in the
following example.

```julia-repl
julia> @startboard e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3 g6 Be3 Bg7 f3 OO Qd2 Nc6 OOO
Board (r1bq1rk1/pp2ppbp/2np1np1/8/3NP3/2N1BP2/PPPQ2PP/2KR1B1R b - -):
 r  -  b  q  -  r  k  -
 p  p  -  -  p  p  b  p
 -  -  n  p  -  n  p  -
 -  -  -  -  -  -  -  -
 -  -  -  N  P  -  -  -
 -  -  N  -  B  P  -  -
 P  P  P  Q  -  -  P  P
 -  -  K  R  -  B  -  R
```

Setting up an arbitrary board position without entering a move sequence can be
done with the `fromfen()` function:

```julia-repl
julia> fromfen("5rk1/p1pb2pp/2p5/3p3q/2P3n1/1Q4BN/PP1Np1KP/R3R3 b - -")
Board (5rk1/p1pb2pp/2p5/3p3q/2P3n1/1Q4BN/PP1Np1KP/R3R3 b - -):
 -  -  -  -  -  r  k  -
 p  -  p  b  -  -  p  p
 -  -  p  -  -  -  -  -
 -  -  -  p  -  -  -  q
 -  -  P  -  -  -  n  -
 -  Q  -  -  -  -  B  N
 P  P  -  N  p  -  K  P
 R  -  -  -  R  -  -  -
```

FEN strings are quite easy to understand. The first component
(`5rk1/p1pb2pp/2p5/3p3q/2P3n1/1Q4BN/PP1Np1KP/R3R3` in the above example) is the
board setup. The ranks of the board are listed from top to bottom (beginning
with rank 8), separated by the `/` character. For each rank, lowercase letters
(p, n, b, r, q or k) denote black pieces, while uppercase letters (P, N, B, R, Q
or K) denote white pieces. Digits represents empty squares. In the above
example, the 8th rank is `5rk1`, meaning five empty squares followed by a black
rook and a black king, and finally one empty square.

The second component (`b` in the above example) is the side to move. It is
always one of the two characters `w` or `b`, depending on the side to move. In
this case, it's black.

The third component (`-` in the example) is the current castle rights. The dash
means that neither side has the right to castle. If one or both sides still have
the right to castle, the letters `K`, `Q`, `k` and `q` are used. The uppercase
letters mean that white can castle kingside or queenside, while the lowercase
letters mean that black can castle. For instance, in a position when both sides
can still castle in either direction, the third component would be `KQkq`. In a
position where white can only castle queenside and black only kingside, it would
be `Qk`.

The fourth coponent (`-` in the example) is the square on which an en passant
capture is possible. The dash means that no en passant capture is possible in
our case. If an en passant capture had been possible on e3, the fourth component
would have been `e3`.

For additional examples and explanations, visit the [Wikipedia article on FEN
strings](https://en.wikipedia.org/wiki/Forsyth–Edwards_Notation).

### Making and Unmaking Moves

Given a chess board, you will often want to modify the board by making some
moves. The most straightforward way to do this is with the `domove` function,
which takes two parameters: A chess board and a move. The move can be either a
value of the `Move` type (you'll learn about this type later in this tutorial)
or a string representing a move in UCI or SAN notation.

Here's an example of using `domove` to make a move given by a string in short algebraic notation (SAN):

```julia-repl
```
Given a chess board, you will usually want to modify the board by making some
moves. The most straightforward way to do this is with the `domove` function,
which takes two parameters: A chess board and a move. The move can be either a
value of the `Move` type or a string representing a move in UCI or SAN notation.

The `Move` type is described in more detail in the API reference. For now, let's
see how to use `domove` to make a move given in short algebraic notation (SAN):

```julia-repl
julia> b = startboard();

julia> domove(b, "d4")
Board (rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq -):
 r  n  b  q  k  b  n  r
 p  p  p  p  p  p  p  p
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  P  -  -  -  -
 -  -  -  -  -  -  -  -
 P  P  P  -  P  P  P  P
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
left unchanged, as illustrated by this example:

```julia-repl
julia> b = startboard();

julia> domove(b, "c4");

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

This is convenient when writing code in a functional style, or when using a
reactive notebook environment like Pluto. Unfortunately, it also results in a
lot of copying of data, and heap allocations that may have signifcant
performance impacts for certain types of applications. When this is a problem,
there are alternative functions `domove!` and `domoves!` that destructively
modify the input board.

Here is the result of the previous example when modified to use `domove!`:

```julia-repl
julia> b = startboard();

julia> domove!(b, "c4");

julia> b
Board (rnbqkbnr/pppppppp/8/8/2P5/8/PP1PPPPP/RNBQKBNR b KQkq -):
 r  n  b  q  k  b  n  r
 p  p  p  p  p  p  p  p
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  P  -  -  -  -  -
 -  -  -  -  -  -  -  -
 P  P  -  P  P  P  P  P
 R  N  B  Q  K  B  N  R
```

`domove!` returns a value of type `UndoInfo`. This can be used to undo the move
and go back to the board position before the move was made:

```julia-repl
julia> b = startboard();

julia> u = domove!(b, "e4");

julia> b
Board (rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq -):
 r  n  b  q  k  b  n  r
 p  p  p  p  p  p  p  p
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  P  -  -  -
 -  -  -  -  -  -  -  -
 P  P  P  P  -  P  P  P
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

There is also a function `domoves!()` that can be used to destructively update a
board with a sequence of several moves. Unlike `domove!`, this operation is
irreversible. No `UndoInfo` is generated, and there is no way to undo the moves
and return to the original board.

Similarly, `domoves!` takes a board and a sequence of moves and executes them
all, destructively modifying the board. Unlike `domove!`, this operation is
irreversible. There is no way to retract the moves and return to the original
board.

```julia-repl
julia> b = startboard();

julia> domoves!(b, "d4", "Nf6", "c4", "g6", "Nc3", "Bg7", "e4", "d6", "Nf3", "O-O")
Board (rnbq1rk1/ppp1ppbp/3p1np1/8/2PPP3/2N2N2/PP3PPP/R1BQKB1R w KQ -):
 r  n  b  q  -  r  k  -
 p  p  p  -  p  p  b  p
 -  -  -  p  -  n  p  -
 -  -  -  -  -  -  -  -
 -  -  P  P  P  -  -  -
 -  -  N  -  -  N  -  -
 P  P  -  -  -  P  P  P
 R  -  B  Q  K  B  -  R
```

Remember that there is also a macro `@startboard` that allows you to do this
more conveniently. The above example could also be written like this:

```julia-repl
julia> @startboard d4 Nf6 c4 g6 Nc3 Bg7 e4 d6 Nf3 OO
Board (rnbq1rk1/ppp1ppbp/3p1np1/8/2PPP3/2N2N2/PP3PPP/R1BQKB1R w KQ -):
 r  n  b  q  -  r  k  -
 p  p  p  -  p  p  b  p
 -  -  -  p  -  n  p  -
 -  -  -  -  -  -  -  -
 -  -  P  P  P  -  -  -
 -  -  N  -  -  N  -  -
 P  P  -  -  -  P  P  P
 R  -  B  Q  K  B  -  R
```

## Pieces, Piece Colors, and Piece Types

Chess pieces are represented by the `Piece` type (internally, a simple wrapper
around an integer). There are constants `PIECE_WP`, `PIECE_WN`, `PIECE_WB`,
`PIECE_WR`, `PIECE_WQ`, `PIECE_WK`, `PIECE_BP`, `PIECE_BN`, `PIECE_BB`,
`PIECE_BR`, `PIECE_BQ` and `PIECE_BK` for each of the possible white or black
pieces, and a special piece value `EMPTY` for the contents of an empty square on
the board.

There are also *piece colors*, represented by the `PieceColor` type (possible
values `WHITE`, `BLACK` and `COLOR_NONE`), as well as *piece types*, represented
by the `PieceType` type (possible values `PAWN`, `KNIGHT`, `BISHOP`, `ROOK`,
`QUEEN`, `KING` and `PIECE_TYPE_NONE`).

Given a piece, you can ask for its color and type by using `pcolor` and `ptype`:

```julia-repl
julia> pcolor(PIECE_BN)
BLACK

julia> ptype(PIECE_BN)
KNIGHT
```

Conversely, if you have a `PieceColor` and a `PieceType`, you can create a
`Piece` value by calling the `Piece` constructor:

```julia-repl
julia> Piece(WHITE, ROOK)
PIECE_WR
```

The special `Piece` value `EMPTY` has piece color `COLOR_NONE` and piece type
`PIECE_TYPE_NONE`:

```julia-repl
julia> pcolor(EMPTY)
COLOR_NONE

julia> ptype(EMPTY)
PIECE_TYPE_NONE
```

The current side to move of a board is obtained by calling `sidetomove`:

```julia-repl
julia> sidetomove(startboard())
WHITE

julia> sidetomove(@startboard Nf3)
BLACK
```

Use the unary minus operator or the function `coloropp` to invert a color:

```julia-repl
julia> -WHITE
BLACK

julia> coloropp(BLACK)
WHITE
```

## Squares

Squares are represented by the `Square` data type. Just as for pieces, piece
colors, and piece types, this type is internally just a simple wrapper around an
integer. There are constants `SQ_A1`, `SQ_A2`, ..., `SQ_H8` for the 64 squares
of the board.

One of the common uses of `Square` values is to ask about the contents of a
square on a chess board. This is done with the `pieceon` function:

```julia-repl
julia> pieceon(startboard(), SQ_B1)
PIECE_WN

julia> pieceon(startboard(), SQ_E8)
PIECE_BK

julia> pieceon(startboard(), SQ_A3)
EMPTY
```

There are also two types `SquareFile` and `SquareRank` for representing the
files and ranks of a board. Given a square, we can get its file or rank by
calling `file` or `rank`:

```julia-repl
julia> file(SQ_E5)
FILE_E

julia> rank(SQ_E5)
RANK_5
```

Conversely, it is possible to create a `Square` from a `SquareFile` and a
`SquareRank`:

```julia-repl
julia> Square(FILE_C, RANK_4)
SQ_C4
```

We can use the functions `tostring` and `squarefromstring` to convert between
`Square` values and strings:

```julia-repl
julia> tostring(SQ_D4)
"d4"

julia> squarefromstring("g6")
SQ_G6
```

## Moves

Moves are represented by the type `Move`. A `Move` value can be obtained by
calling one of two possible constructors:

```julia-repl
julia> Move(SQ_E2, SQ_E4) # Normal move
Move(e2e4)

julia> Move(SQ_A7, SQ_A8, QUEEN) # Promotion move
Move(a7a8q)
```

We can also convert a move to/from strings in UCI notation:

```julia-repl
julia> tostring(Move(SQ_G8, SQ_F6))
"g8f6"

julia> movefromstring("b2c1r")
Move(b2c1r)
```

Parsing move strings in short algebraic notation (SAN) requires a board. Without
a board, there is no way to know the source square of a move string like
`"Nf3"`. Given a board, we can convert to/from SAN move strings using
`movetosan` and `movefromsan`:

```julia-repl
julia> movetosan(startboard(), Move(SQ_G1, SQ_F3))
"Nf3"

julia> movefromsan(startboard(), "e4")
Move(e2e4)
```

One of the most common ways to obtain a move is to call the `moves` function on
a board. This returns a `MoveList`, a list of all legal moves for the board:

```julia-repl
julia> b = @startboard e4 c5 Nf3 d6;

julia> moves(b)
28-element MoveList:
 Move(a2a3)
 Move(b2b3)
 Move(c2c3)
 Move(d2d3)
 Move(e4e5)
 Move(g2g3)
 Move(h2h3)
 Move(a2a4)
 Move(b2b4)
 Move(c2c4)
 ⋮
 Move(f3g1)
 Move(f3h4)
 Move(f1a6)
 Move(f1b5)
 Move(f1c4)
 Move(f1d3)
 Move(f1e2)
 Move(h1g1)
 Move(d1e2)
 Move(e1e2)
```

Most of the usual Julia sequence functions should work with `MoveList` values.
For instance, we can filter out only those moves that give check:

```julia-repl
julia> filter(m -> ischeck(domove(b, m)), moves(b))
1-element Vector{Move}:
 Move(f1b5)
```

## Square Sets

The `SquareSet` type represents a set of squares on the chess board. We can do
set-theoretic operations like union, intersection and complement on square sets,
and test for set membership. Internally, a `SquareSet` is represented by a
64-bit integer, with set operations performed through bitwise operations. This
makes square sets very fast to manipulate.

### Creating Square Sets

There is a `SquareSet` constructor that takes a sequence of squares as input and returns the corresponding square set:

```julia-repl
julia> SquareSet(SQ_A1, SQ_A2, SQ_A3)
SquareSet:
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 #  -  -  -  -  -  -  -
 #  -  -  -  -  -  -  -
 #  -  -  -  -  -  -  -
```

There are also pre-defined constants `SS_FILE_A`, ..., `SS_FILE_H` for the eight
files of the board, and `SS_RANK_1`, ..., `SS_RANK_8` for the eight ranks.

```julia-repl
julia> SS_FILE_B
SquareSet:
 -  #  -  -  -  -  -  -
 -  #  -  -  -  -  -  -
 -  #  -  -  -  -  -  -
 -  #  -  -  -  -  -  -
 -  #  -  -  -  -  -  -
 -  #  -  -  -  -  -  -
 -  #  -  -  -  -  -  -
 -  #  -  -  -  -  -  -

julia> SS_RANK_6
SquareSet:
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 #  #  #  #  #  #  #  #
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
```

### Extracting Square Sets From Boards

Given a `Board` value, there are several functions for obtaining various square sets. The `pieces` function has several methods for extracting sets of squares occupied by various pieces.

The squares occupied by white pieces:

```julia-repl
julia> pieces(startboard(), WHITE)
SquareSet:
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 #  #  #  #  #  #  #  #
 #  #  #  #  #  #  #  #
```

The set of all squares occupied by pawns of either color (you can also do
`pawns(startboard())`, with the same effect):

```julia-repl
julia> pieces(startboard(), PAWN)
SquareSet:
 -  -  -  -  -  -  -  -
 #  #  #  #  #  #  #  #
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 #  #  #  #  #  #  #  #
 -  -  -  -  -  -  -  -
```

The set of squares occupied by black knights (you can also do
`knights(startboard(), BLACK)`:

```julia-repl
julia> pieces(startboard(), PIECE_BN)
SquareSet:
 -  #  -  -  -  -  #  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
```

The set of all occupied squares on the board:

```julia-repl
julia> occupiedsquares(startboard())
SquareSet:
 #  #  #  #  #  #  #  #
 #  #  #  #  #  #  #  #
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 #  #  #  #  #  #  #  #
 #  #  #  #  #  #  #  #
```

The set of all empty squares on the board:

```julia-repl
julia> emptysquares(startboard())
SquareSet:
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 #  #  #  #  #  #  #  #
 #  #  #  #  #  #  #  #
 #  #  #  #  #  #  #  #
 #  #  #  #  #  #  #  #
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
```

### Set Operations

It is possible to do various basic set theoretic operations likecomplement,
union, increment, and membership tests on square sets, using standard
mathematical notation. This sections gives a few examples.

Set membership tests (type `\in <TAB>` and `\notin <TAB>` for the `∈` and `∉`
characters):

```julia-repl
julia> SQ_D1 ∈ SS_FILE_D
true

julia> SQ_D1 ∈ SS_RANK_2
false

julia> SQ_E4 ∉ SS_RANK_8
true
```

Set complement:

```julia-repl
julia> -SS_RANK_4
SquareSet:
 #  #  #  #  #  #  #  #
 #  #  #  #  #  #  #  #
 #  #  #  #  #  #  #  #
 #  #  #  #  #  #  #  #
 -  -  -  -  -  -  -  -
 #  #  #  #  #  #  #  #
 #  #  #  #  #  #  #  #
 #  #  #  #  #  #  #  #
```

Set union (type `\cup <TAB>` for the `∪` character):

```julia-repl
julia> SS_RANK_2 ∪ SS_FILE_F
SquareSet:
 -  -  -  -  -  #  -  -
 -  -  -  -  -  #  -  -
 -  -  -  -  -  #  -  -
 -  -  -  -  -  #  -  -
 -  -  -  -  -  #  -  -
 -  -  -  -  -  #  -  -
 #  #  #  #  #  #  #  #
 -  -  -  -  -  #  -  -
```

Set intersection (type `\cap <TAB>` for the `∩` character):

```julia-repl
julia> SS_FILE_D ∩ SquareSet(SQ_D4, SQ_D5, SQ_E4, SQ_E5)
SquareSet:
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  #  -  -  -  -
 -  -  -  #  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
```

Set subtraction:

```julia-repl
julia> SS_FILE_G - (SS_RANK_3 ∪ SS_RANK_4)
SquareSet:
 -  -  -  -  -  -  #  -
 -  -  -  -  -  -  #  -
 -  -  -  -  -  -  #  -
 -  -  -  -  -  -  #  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  #  -
 -  -  -  -  -  -  #  -
```

### Attack Square Sets

Chess.jl contains several functions for generating attacks to/from squares on
the chess board.

Attacks by knights, kings or pawns from a given square on the board are the most
straightforward.

The squares attacked by a knight on e5:

```julia-repl
julia> knightattacks(SQ_E5)
SquareSet:
 -  -  -  -  -  -  -  -
 -  -  -  #  -  #  -  -
 -  -  #  -  -  -  #  -
 -  -  -  -  -  -  -  -
 -  -  #  -  -  -  #  -
 -  -  -  #  -  #  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
```

The squares attacked by a king on g2:

```julia-repl
julia> kingattacks(SQ_G2)
SquareSet:
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  #  #  #
 -  -  -  -  -  #  -  #
 -  -  -  -  -  #  #  #
```

The squares attacked by a black pawn on c5 (the color is necessary here, because
white and black pawns move in the opposite direction):

```julia-repl
julia> pawnattacks(BLACK, SQ_C5)
SquareSet:
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  #  -  #  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
```

Sliding pieces (bishops, rooks and queens) are a little more complicated,
because we need the set of occupied squares on the board in order to identify
possible blockers before we can know what squares they attack.

The most common way of providing a set of occupied squares is to use an actual
chess board. Let's first create a board position a little more interesting than
the starting position.

```julia-repl
julia> b = @startboard e4 e5 Nf3 Nc6 d4 exd4 Nxd4 Bc5
Board (r1bqk1nr/pppp1ppp/2n5/2b5/3NP3/8/PPP2PPP/RNBQKB1R w KQkq -):
 r  -  b  q  k  -  n  r
 p  p  p  p  -  p  p  p
 -  -  n  -  -  -  -  -
 -  -  b  -  -  -  -  -
 -  -  -  N  P  -  -  -
 -  -  -  -  -  -  -  -
 P  P  P  -  -  P  P  P
 R  N  B  Q  K  B  -  R
```

The set of squares attacked by the white queen on d1:

```julia-repl
julia> queenattacks(b, SQ_D1)
SquareSet:
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  #
 -  -  -  #  -  -  #  -
 -  -  -  #  -  #  -  -
 -  -  #  #  #  -  -  -
 -  -  #  -  #  -  -  -
```

The set of squares a bishop on c4 would have attacked (there is no bishop on c4
at the moment, but this does not stop us from asking which squares a
hypothetical bishop there would attack):

```julia-repl
julia> bishopattacks(b, SQ_C4)
SquareSet:
 -  -  -  -  -  -  -  -
 -  -  -  -  -  #  -  -
 #  -  -  -  #  -  -  -
 -  #  -  #  -  -  -  -
 -  -  -  -  -  -  -  -
 -  #  -  #  -  -  -  -
 #  -  -  -  #  -  -  -
 -  -  -  -  -  #  -  -
```

There is also an `attacksfrom` function, that returns the set of squares
attacked by the piece on a given non-empty square, and an `attacksto` function,
that returns all squares that contains pieces of either side that attacks a
given square:

```julia-repl
julia> attacksfrom(b, SQ_H8)
SquareSet:
 -  -  -  -  -  -  #  -
 -  -  -  -  -  -  -  #
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -

julia> attacksto(b, SQ_D4)
SquareSet:
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  #  -  -  -  -  -
 -  -  #  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  #  -  -  -  -
```

It is possible to identify pieces that can be captured by intersecting attack
square sets with sets of pieces of a given color:`

```julia-repl
julia> attacksfrom(b, SQ_D4) ∩ pieces(b, BLACK)
SquareSet:
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  #  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
 -  -  -  -  -  -  -  -
```

Here is a more complicated example: A function that finds all pieces of a given
side that are attacked, but undefended:

```julia
function attacked_but_undefended(board, color)
    attacker = -color  # The opposite color

    # Find all attacked squares
    attacked = SS_EMPTY  # The empty square set
    for s ∈ pieces(board, attacker)
        attacked = attacked ∪ attacksfrom(board, s)
    end

    # Find all defended squares
    defended = SS_EMPTY
    for s ∈ pieces(b, color)
        defended = defended ∪ attacksfrom(board, s)
    end

    # Return all attacked, but undefended squares containing pieces of
    # the desired color:
    attacked ∩ -defended ∩ pieces(board, color)
end
```

### Iterating Through Square Sets

The `squares` function can be used to convert a `SquareSet` to a vector of
squares:

```julia-repl
julia> squares(SS_FILE_A)
8-element Vector{Square}:
 SQ_A8
 SQ_A7
 SQ_A6
 SQ_A5
 SQ_A4
 SQ_A3
 SQ_A2
 SQ_A1
```

The `squares` function is not necessary for most tasks. It is possible – and
much more efficient – to iterate through a `SquareSet` directly:

```julia-repl
julia> for s ∈ SS_RANK_5
           println(tostring(s))
       end
a5
b5
c5
d5
e5
f5
g5
h5
```

## Games

There are two types for representing chess games: `SimpleGame` and `Game`.
`SimpleGame` is a basic type that contains little more than the PGN headers
(player names, game result, etc.) and a sequence of moves. `Game` is a more
complicated type that support annotated, tree-like games with comments and
variations. If you don't need these features, `SimpleGame` is always a better
choice, as manipulating a `SimpleGame` is much faster.

For the rest of this section, most of our examples use the more complicated
`Game` type. With a few exceptions (that will be pointed out), methods with
identical names and behavior exist for the `SimpleGame` type. Remember again
that `SimpleGame` is really the preferred type in practice, unless you *really*
need the extra functionality of the `Game` type.

### Creating Games and Adding Moves

To create an empty game from the standard chess position, use the parameterless `Game()` constructor:


```julia-repl
julia> g = Game()
Game:
  *
```

The printed representation of the game consists of the moves in short algebraic
notation (in this case, because we just constructed a game, there are no moves)
and an asterisk (`*`) showing our current position in the game.

Moves can be added to the game with the `domove!` function:

```julia-repl
julia> g = Game();

julia> domove!(g, "c4");

julia> domove!(g, "e5");

julia> domove!(g, "Nc3");

julia> domove!(g, "Nf6");

julia> g
Game:
 1. c4 e5 2. Nc3 Nf6 *
```

Constructing games this way quickly becomes tedious. For interactive use, there
is a macro `@game` (and a similar macro `@simplegame` for the `SimpleGame` type)
for constructing a game from the regular starting position with a sequence of
moves. The following is equivalent to the above example:

```julia-repl
julia> g = @game c4 e5 Nc3 Nf6
Game:
 1. c4 e5 2. Nc3 Nf6 *
```

There is now a list of moves in the printed representation of the game. The `*`
symbol still indicates our current position in the game. We can go back one move
by calling `back!`, forward one move by calling `forward!`, or jump to the
beginning or the end of the game by calling `tobeginning!` or `toend!`.

```julia-repl
julia> back!(g)
Game:
 1. c4 e5 2. Nc3 * Nf6

julia> tobeginning!(g)
Game:
 * 1. c4 e5 2. Nc3 Nf6

julia> forward!(g)
Game:
 1. c4 * e5 2. Nc3 Nf6

julia> toend!(g)
Game:
 1. c4 e5 2. Nc3 Nf6 *
```

You can obtain the current position board position of the game with the `board`
function, which returns a value of type `Board`:

```julia-repl
julia> board(g)
Board (rnbqkb1r/pppp1ppp/5n2/4p3/2P5/2N5/PP1PPPPP/R1BQKBNR w KQkq -):
 r  n  b  q  k  b  -  r
 p  p  p  p  -  p  p  p
 -  -  -  -  -  n  -  -
 -  -  -  -  p  -  -  -
 -  -  P  -  -  -  -  -
 -  -  N  -  -  -  -  -
 P  P  -  P  P  P  P  P
 R  -  B  Q  K  B  N  R
```

### Example: Playing Random Games

By putting together things we've learned earlier in this tutorial, we can now
generate random games. This function generates a `SimpleGame` containing random
moves:

```julia
function randomgame()
    game = SimpleGame()
    while !isterminal(game)
        move = rand(moves(board(game)))
        domove!(game, move)
    end
    game
end
```

The only new function in the above code is `isterminal`, which tests for a game
over condition (checkmate or some type of immediate draw).

Approximately how often do completely random games end in checkmate? Let's find
out. The following function takes an optional number of games as input (by
default, one thousand), generates the deseired number of random games, and
returns the fraction of the games that (accidentally) ends in checkmate.

```julia
function checkmate_fraction(game_count = 1000)
    checkmate_count = 0
    for _ in 1:game_count
        g = randomgame()
        if ischeckmate(board(g))
            checkmate_count += 1
        end
    end
    checkmate_count / game_count
end
```

The above code introduces the new function `ischeckmate`, which tests if a board
is a checkmate position.

Let's test it:

```julia-repl
julia> checkmate_fraction(10_000)
0.1546
```

It seems that about 15% of all random games end in an accidental checkmate. To
me, this is a suprisingly high number.

What will happen if we make random moves, except that we always play the mating
move if there is a mate in one? Let's find out. As a first step, let's write a
function that checks whether a move is a mate in one.

```julia
move_is_mate_slow(board, move) = ischeckmate(domove(board, move))
```

This is simple, elegant and readable. Unfortunately, as the name indicates, it
is also kind of slow. The reason is that `domove` copies the board. Using the
destructive `domove!` function performs much better, at the price of longer and
less readable code.

The function below is functionally equivalent to the one above, but performs
much better.

```julia
function move_is_mate(board, move)
    # Do the move
    u = domove!(board, move)

    # Check if the resulting board is checkmate
    result = ischeckmate(board)

    # Undo the move
    undomove!(board, u)

    # Return result
    result
end
```

Using the function we just wrote, we can make a function that takes a board as
input and returns a mate in 1 move if there is one, or a random move otherwise.

```julia
function mate_or_random(board)
    ms = moves(board)
    for move ∈ ms
        if move_is_mate(board, move)
            return move
        end
    end
    rand(ms)
end
```

The function below is identical to the `randomgame` function above, except that
it uses `mate_or_random` instead of totally random moves:

```julia
function almost_random_game()
    game = SimpleGame()
    while !isterminal(game)
        move = mate_or_random(board(game))
        domove!(game, move)
    end
    game
end
```

What percentage of the games end in checkmate now? Here's a function to find
out:

```julia
function checkmate_fraction_2(game_count = 1000)
    checkmate_count = 0
    for _ in 1:game_count
        g = almost_random_game()
        if ischeckmate(board(g))
            checkmate_count += 1
        end
    end
    checkmate_count / game_count
end
```

If you try to run this function, you should get a number around 0.81. About 81%
of all completely random games include at least one opportunity to deliver mate
in 1!

### Variations

If we create a game with some moves, go back to an earlier place in the game,
and call `domove!` again with a new move, the previous game continuation is
overwritten:

```julia-repl
julia> g = @game d4 d5 c4 e6 Nc3 Nf6 Bg5
Game:
 1. d4 d5 2. c4 e6 3. Nc3 Nf6 4. Bg5 *

julia> back!(g); back!(g); back!(g)
Game:
 1. d4 d5 2. c4 e6 * 3. Nc3 Nf6 4. Bg5

julia> domove!(g, "Nf3")
Game:
 1. d4 d5 2. c4 e6 3. Nf3 *
```

This is not always desirable. Sometimes we want to add an *alternative* move,
and to view the game as a *tree of variations*.

Games of type `Game` (but not `SimpleGame`!) are able to handle variations.

To add an alternative variation at some point in the game, first make the main
line, then go back to the place where you want to add the alternative move, and
then do `addmove!`. The following example is identical to the one above, except
that `domove!` has been replaced by `addmove!`:
```julia-repl
julia> g = @game d4 d5 c4 e6 Nc3 Nf6 Bg5;

julia> back!(g); back!(g); back!(g)
Game:
 1. d4 d5 2. c4 e6 * 3. Nc3 Nf6 4. Bg5

julia> addmove!(g, "Nf3")
Game:
 1. d4 d5 2. c4 e6 3. Nc3 (3. Nf3 *) Nf6 4. Bg5
```

Alternative variations are printed in parens in the text representation of a
game; the `(3. Nf3 *)` in the above example. As before, the `*` indicates the
current location in the game tree.

The function `forward!` takes an optional second argument: Which move to follow
when going forward at a branching point in the tree. If this argument is
ommited, the main (i.e. first) move is followed.

Here is how you would go back to the point after 3. Nc3 in the above example:

```julia-repl
julia> back!(g)
Game:
 1. d4 d5 2. c4 e6 * 3. Nc3 (3. Nf3) Nf6 4. Bg5

julia> forward!(g, "Nc3")
Game:
 1. d4 d5 2. c4 e6 3. Nc3 (3. Nf3) * Nf6 4. Bg5
```

Two other functions that are useful for navigating games with variations are
`tobeginningofvariation!` and `toendofvariation!`. See the documentation of
these functions for details.

Of course, variations can be nested:

```julia-repl
julia> g = @game e4 c5 Nf3 Nc6;

julia> back!(g)
Game:
 1. e4 c5 2. Nf3 * Nc6

julia> g = @game e4 c5 Nf3 Nc6;

julia> back!(g); back!(g);

julia> addmove!(g, "c3"); addmove!(g, "Nf6"); addmove!(g, "e5");

julia> back!(g); back!(g);

julia> addmove!(g, "d5"); addmove!(g, "exd5");

julia> g
Game:
 1. e4 c5 2. Nf3 (2. c3 Nf6 (2... d5 3. exd5 *) 3. e5) Nc6
```

### Comments

Games of type `Game` (again, not `SimpleGame`) can also be annotated with
textual comments, by using the `addcomment!` function:

```julia-repl
julia>  g = @game d4 f5;

julia> addcomment!(g, "This opening is known as the Dutch Defense");

julia> g
Game:
 1. d4 f5 {This opening is known as the Dutch Defense} *
```

Comments are printed in curly braces in the textual representation of games, as
can be seen above.

### Numeric Annotation Glyphs

It is also possible to add *numeric annotation glyphs* (NAGs) to the game. NAGs
are a standard way of adding symbolic annotations to a chess game. All integers
in the range 0 to 139 have a pre-defined meaning, as described in [this
Wikipedia article](https://en.wikipedia.org/wiki/Numeric_Annotation_Glyphs).

Here is how to add the NAG `$4` ("very poor move or blunder") to the move 2...
g4 in the game 1. f4 e5 2. g4 Qh4#:

```julia-repl
julia> g = @game f4 e5 g4 Qh4;

julia> back!(g);

julia> addnag!(g, 4);

julia> g
Game:
 1. f4 e5 2. g4 $4 * Qh4#
```

## PGN Import and Export

This section describes import and export of chess games in the popular [PGN
format](https://www.chessclub.com/help/PGN-spec). PGN is a rather awkward and
complicated format, and a lot of the "PGN files" out there on the Internet don't
quite follow the standard, and are broken in various ways. The functions
described in this section do a fairly good job of handling correct PGNs
(although bugs are possible), but will often fail on the various not-quite-PGNs
found on the Internet.

The PGN functions are found in the submodule `Chess.PGN`. Please do

```julia-repl
using Chess, Chess.PGN
```

before trying the examples in this section.

### Creating a Game From a PGN String

Given a PGN string, the `gamefromstring` function creates a game object from the
string (throwing a `PGNException` on failure). Here's a PGN string for us to
experiment with:

```julia-repl
julia> pgnstring = """
       [Event "Important Tournament"]
       [Site "Somewhere"]
       [Date "2021.04.29"]
       [Round "42"]
       [White "Sixpack, Joe"]
       [Black "Public, John Q"]
       [Result "0-1"]

       1. f4 e5 2. fxe5 d6 3. exd6 Bxd6 4. Nc3 \$4 {A terrible blunder. White should
       play} (4. Nf3 {, and Black has insufficient compensation for the pawn.}) Qh4+
       5. g3 Qxg3+ {Black could also have played} (5... Bxg3+ 6. hxg3 Qxg3#) 6. hxg3
       Bxg3# 0-1
       """;
```

Let's try to import it:

```julia-repl
julia> sg = gamefromstring(pgnstring)
SimpleGame (Sixpack, Joe vs Public, John Q, Somewhere 2021):
 * 1. f4 e5 2. fxe5 d6 3. exd6 Bxd6 4. Nc3 Qh4+ 5. g3 Qxg3+ 6. hxg3 Bxg3#
```

The result is a `SimpleGame`. All comments, variations and NAGs in the PGN
string were ignored. If we instead want a `Game` with all annotations included,
we can supply the value `true` to the optional parameter `annotations`:

```julia-repl
julia> g = gamefromstring(pgnstring, annotations=true)
Game (Sixpack, Joe vs Public, John Q, Somewhere 2021):
 * 1. f4 e5 2. fxe5 d6 3. exd6 Bxd6 4. Nc3 $4 {A terrible blunder. White should
play} (4. Nf3 {, and Black has insufficient compensation for the pawn.}) Qh4+ 5. g3 Qxg3+ {Black could also have played} (5... Bxg3+ 6. hxg3 Qxg3#) 6. hxg3 Bxg3#
```

Unless you really need the annotations, importing to a `SimpleGame` is the
preferred choice. A `SimpleGame` is much faster to create and consumes less
memory.

Converting a game to a PGN string is done by the `gametopgn` function. This
works for both `SimpleGame` and `Game` objects:

```julia-repl
julia> println(gametopgn(sg))
[Event "Important Tournament"]
[Site "Somewhere"]
[Date "2021.04.29"]
[Round "42"]
[White "Sixpack, Joe"]
[Black "Public, John Q"]
[Result "0-1"]

1. f4 e5 2. fxe5 d6 3. exd6 Bxd6 4. Nc3 Qh4+ 5. g3 Qxg3+ 6. hxg3 Bxg3# 0-1

julia> println(gametopgn(g))
[Event "Important Tournament"]
[Site "Somewhere"]
[Date "2021.04.29"]
[Round "42"]
[White "Sixpack, Joe"]
[Black "Public, John Q"]
[Result "0-1"]

1. f4 e5 2. fxe5 d6 3. exd6 Bxd6 4. Nc3 $4 {A terrible blunder. White should
play} (4. Nf3 {, and Black has insufficient compensation for the pawn.}) Qh4+ 5. g3 Qxg3+ {Black could also have played} (5... Bxg3+ 6. hxg3 Qxg3#) 6. hxg3 Bxg3# 0-1
```

### Working With PGN Files

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

The opening book function are located not in the main `Chess` module, but in the
submodule `Chess.Book`.

```julia-repl
using Chess.Book
```

The `Chess.Book` module contains functions for processing large PGN files and
creating opening book files. There is also a small built-in opening book. The
rest of the examples in this section will use the built-in opening book. For
information about generating your own books, consult the documentation for the
`Chess.Book` module.

### Finding Book Moves

Given a `Board`, the function `findbookentries` finds all the opening book
moves for that board position. For instance, this gives us all book moves for
the standard opening position:

```julia-repl
julia> b = startboard();

julia> entries = findbookentries(b);
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

To pick a book move, use `pickbookmove`:

```julia-repl
julia> pickbookmove(@startboard e4 c5)
Move(b1c3)
```

`pickbookmove` also takes some optional named parameter for selecting a book
file to use and to eliminate moves that have only been played very rarely. See
the function documentation for details.

If no book moves are found for the input position, `pickbookmove` returns
`nothing`.

### Example: Playing Random Openings

Here's a function that generates a game (or rather, the beginning of a game) by
picking and playing book moves until it reaches a position where no book move is
found:

```julia
function random_opening()
    g = Game()
    while true
        move = pickbookmove(board(g))
        if isnothing(move)
            break
        end
        domove!(g, move)
    end
    g
end
```

Let's try:

```julia-repl
julia> random_opening()
Game:
 Nf3 c5 c4 Nc6 Nc3 Nf6 e3 g6 d4 cxd4 exd4 d5 cxd5 Nxd5 Qb3 Nxc3 bxc3 Bg7 Be2 O-O O-O Qc7 *
```

### Creating Book Files

To create an opening book, use the `createbook` function, and supply it with
one or more PGN files:

```julia-repl
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

## Interacting with UCI Engines

This section describes how to run and interact with chess engines using the
[Universal Chess Interface](http://wbec-ridderkerk.nl/html/UCIProtocol.html)
protocol. There are hundreds of UCI chess engines out there. A free, strong
and popular choice is [Stockfish](https://stockfishchess.org). Stockfish is
used as an example in this section, but any other engine should work just as
well.

For running the examples in this section, it is assumed that you have an
executable `stockfish` somewhere in your `PATH` environment variable.

The code for interacting with UCI engines is found in the submodule `Chess.UCI`:

```julia-repl
julia> using Chess.UCI
```

### Starting and Initializing Engines

An engine is started by calling the runengine function, which takes the path to
the engine as a parameter:

An engine is started by calling the `runengine` command, which takes the path
to the engine as a parameter:

```julia-repl
julia> sf = runengine("stockfish")
Engine: Stockfish 160421
```

The first thing you want to do after starting a chess engine is probably to set
some UCI parameter values. This can be done with `setoption`:

```julia-repl
julia> setoption(sf, "Hash", 256);
```

### Searching

You can send a game to the engine with `setboard`:

```julia-repl
julia> g = @simplegame f4 e5 fxe5 d6 exd6 Bxd6 Nc3;

julia> setboard(sf, g)
```

The second parameter to `setboard` can also be a `Board` or a `Game`.

To ask the engine to search the position you just sent to it, use the `search`
function. `search` has two required parameters: The engine and the UCI `go`
command we want to send to it.

Here is the most basic example of using `search`:

```julia-repl
julia> search(sf, "go depth 10")
BestMoveInfo (best=d8h4, ponder=g2g3)
```

The return value is a `BestMoveInfo`, a struct containing the two slots
`bestmove` (the best move returned by the engine, a `Move`) and `ponder` (the
ponder move returned by the engine, a `Move` or `nothing`).

The `search` function also takes an optional named parameter `infoaction`. This
parameter is a function that takes each of the engine's `info` output lines and
does something to them. Here's an example where we just print the engine output
with `println` as our `infoaction`:

```julia-repl
julia> g = @simplegame d4 Nf6 c4 g6 Nc3 d5 cxd5 Nxd5;

julia> setboard(sf, g)

julia> search(sf, "go depth 10", infoaction = println)
info string NNUE evaluation using nn-62ef826d1a6d.nnue enabled
info depth 1 seldepth 1 multipv 1 score cp 113 nodes 49 nps 24500 tbhits 0 time 2 pv g1f3
info depth 2 seldepth 2 multipv 1 score cp 114 nodes 170 nps 85000 tbhits 0 time 2 pv g1f3 d5c3
info depth 3 seldepth 3 multipv 1 score cp 114 nodes 246 nps 123000 tbhits 0 time 2 pv g1f3 d5c3 b2c3
info depth 4 seldepth 4 multipv 1 score cp 195 nodes 301 nps 150500 tbhits 0 time 2 pv g1f3 d5c3
info depth 5 seldepth 5 multipv 1 score cp 224 nodes 886 nps 295333 tbhits 0 time 3 pv g1f3 d5c3 b2c3
info depth 6 seldepth 6 multipv 1 score cp 113 nodes 1264 nps 316000 tbhits 0 time 4 pv g1f3 d5c3 b2c3 f8g7 e2e4 e8g8
info depth 7 seldepth 7 multipv 1 score cp 87 nodes 2326 nps 465200 tbhits 0 time 5 pv g1f3 d5c3 b2c3 f8g7 e2e4 e8g8 f1d3
info depth 8 seldepth 11 multipv 1 score cp 43 nodes 6660 nps 740000 tbhits 0 time 9 pv e2e4 d5c3 b2c3 c7c5 f1b5 c8d7 d1b3 f8g7 b5d7 b8d7
info depth 9 seldepth 14 multipv 1 score cp 61 nodes 9085 nps 698846 tbhits 0 time 13 pv e2e4 d5c3 b2c3 c7c5 g1f3 c5d4 d1d4
info depth 10 seldepth 14 multipv 1 score cp 30 nodes 24385 nps 762031 tbhits 0 time 32 pv e2e4 d5c3 b2c3 c7c5 f1b5 c8d7 b5d7 b8d7 g1f3 f8g7 e1g1 e8g8 c1e3
BestMoveInfo (best=e2e4, ponder=d5c3)
```

### Parsing Search Output

In most cases, we want something more easily to manipulate than the raw string
values sent by the engines `info` lines in our `infoaction` function. The
function `parsesearchinfo` takes care of this. It takes an `info` string as
input and returns a `SearchInfo` value, a struct that contains the various
components of the `info` line as its slots.

Let's see how this works:

```julia-repl
julia> parsesearchinfo("info depth 10 seldepth 14 multipv 1 score cp 30 nodes 24385 nps 762031 tbhits 0 time 32 pv e2e4 d5c3 b2c3 c7c5 f1b5 c8d7 b5d7 b8d7 g1f3 f8g7 e1g1 e8g8 c1e3")
SearchInfo:
 depth: 10
 seldepth: 14
 time: 32
 nodes: 24385
 nps: 762031
 score: Score(30, false, Chess.UCI.exact)
 tbhits: 0
 multipv: 1
 pv: e2e4 d5c3 b2c3 c7c5 f1b5 c8d7 b5d7 b8d7 g1f3 f8g7 e1g1 e8g8 c1e3
```

The meaning of most of the slots in this struct should be evident if you are
familiar with the UCI protocol. If you are not, the two most important slots are
the `score` and the `pv`.

The `score` is a value of type `Score`. The definition of the `Score` struct
looks like this:

```julia
struct Score
    value::Int
    ismate::Bool
    bound::BoundType
end
```

There are two types of score: *Centipawn scores* are an evaluation where
advantages is measured on a scale where 100 means an advantage corresponding to
the value of one pawn. *Mate scores* are scores of the type "mate in X moves".
The type of score is indicated by the `ismate` slot, while the numerical value
is indicated by the `value` slot.

For instance, when `value` is 50 and `ismate` is `false`, it means that the side
to move has an advantage worth about half a pawn. If `value` is 5 and `ismate`
is true, it means that the side to move has a forced checkmate in 5 half moves
or less.

The final slot, `bound`, indicates whether the score is just an upper bound, a
lower bound, or an exact score. The three possible values are `upper`, `lower`
and `exact`.

The other interesting slot of `SearchInfo` is the `pv`. This is a vector of
moves, what the engine considers the best line of play, assuming optimal play
from both sides.

### Example: Engine vs Engine Games

Using what we have learned, we can easily make a function that generates engine
vs engine games. Let's use the `random_opening` function we wrote earlier (in
the section about opening books) to initialize the game with some opening
position, and let the engine play out the game from there. We'll let the engine
think 10 thousand nodes per move.

```julia
function engine_game(engine)
    g = random_opening()
    while !isterminal(g)
        setboard(engine, g)
        move = search(engine, "go nodes 10000").bestmove
        domove!(g, move)
    end
    g
end
```

Let's try generating a game using Stockfish:

```julia-repl
julia> engine_game(sf)
Game:
 1. d4 d5 2. e3 Bf5 3. Bd3 Bxd3 4. Qxd3 c6 5. Nf3 e6 6. Nbd2 Nf6 7. O-O c5 8. dxc5 Nbd7 9. b4 a5 10. c3 Be7 11. h3 O-O 12. e4 Qc7 13. a4 Rfd8 14. Nd4 Ne5 15. Qe3 Ng6 16. Nb5 Qb8 17. Bb2 dxe4 18. Nxe4 Nd5 19. Qe1 h6 20. Ned6 Bf6 21. Rb1 Be7 22. c4 Ndf4 23. g3 Nxh3+ 24. Kg2 Ng5 25. f4 Nh7 26. bxa5 Bxd6 27. cxd6 Rxd6 28. Nxd6 Qxd6 29. Qe4 Qd2+ 30. Rf2 Qxa5 31. f5 exf5 32. Rxf5 Qd2+ 33. Rf2 Qd7 34. Qd5 Qe8 35. Re1 Qf8 36. c5 Ng5 37. Bc1 Rxa4 38. Bxg5 hxg5 39. Qxb7 Qxc5 40. Qxf7+ Kh7 41. Qf3 Rh4 42. Rfe2 Kh6 43. Re6 Qc2+ 44. R1e2 Qxe2+ 45. Qxe2 Kh7 46. Rxg6 Rb4 47. Rxg5 Rh4 48. Qe7 Rh2+ 49. Kxh2 Kh8 50. Qxg7# *
```

Let's try to make a slightly more sophisticated version of this function, that
also includes the engine evaluation for each move as a comment in the game.

As a first step, here's a function that creates a human readable string from a
`Score` value:

```julia
function scorestring(score, white_to_move)
    value = white_to_move ? score.value : -score.value
    if score.ismate && value > 0
        "+#$(value)"
    elseif score.ismate
        "-#$(abs(value))"
    elseif value > 0
        "+$(value * 0.01)"
    else
        "$(value * 0.01)"
    end
end
```

The function also takes a boolean white_to_move parameter, because we want to
present the scores always from white's point of view, rather than from the side
to move's point of view (which is what we get from the engine).

In our improved engine vs engine function, we need to supply an `infoaction` in
the call to `search`, in order to obtain the engine evaluation. It can be done
like this:

```julia
function engine_vs_engine_with_evals(engine)
    # A variable for keeping track of the score:
    score = Score(0, true, Chess.UCI.exact)

    # An infoaction function that updates the score:
    function infoaction(infoline)
        info = parsesearchinfo(infoline)
        if !isnothing(info.score)
            score = info.score
        end
    end

    g = random_opening()
    while !isterminal(g)
        whitetomove = sidetomove(board(g)) == WHITE
        setboard(engine, g)
        # Use the infoaction defined above when calling search:
        move = search(engine, "go nodes 10000", infoaction=infoaction).bestmove
        # Add the move to the game:
        domove!(g, move)
        # Add the score as a comment:
        addcomment!(g, scorestring(score, whitetomove))
    end
    g
end
```

A test game:

```julia-repl
julia> engine_vs_engine_with_evals()
Game:
 1. Nf3 d5 2. g3 Nf6 3. Bg2 e6 4. O-O Be7 5. d3 O-O 6. Nbd2 c5 7. e4 Nc6 8. e5 Nd7 9. Re1 f6 10. exf6 Nxf6 11. b3 {+1.1} Bd7 {+0.67} 12. Bb2 {+0.68} Ng4 {+0.7000000000000001} 13. h3 {+0.54} Bf6 {+0.65} 14. Bxf6 {+0.62} Nxf6 {+0.85} 15. Ne5 {+0.87} Nxe5 {+1.06} 16. Rxe5 {+0.8} h6 {+0.89} 17. Nf3 {+1.01} a5 {+1.16} 18. a4 {+1.2} Ra6 {+1.32} 19. Re2 {+1.27} Be8 {+1.1500000000000001} 20. Qe1 {+1.07} Bf7 {+1.16} 21. Qd2 {+1.02} Nd7 {+1.3800000000000001} 22. Rae1 {+1.35} Ra8 {+1.3800000000000001} 23. Ne5 {+1.6400000000000001} Nxe5 {+1.9000000000000001} 24. Rxe5 {+1.74} b6 {+1.42} 25. h4 {+1.53} Qd6 {+1.55} 26. Bh3 {+2.02} Rae8 {+1.62} 27. f4 {+1.8900000000000001} Re7 {+1.6400000000000001} 28. f5 {+2.21} Be8 {+1.97} 29. g4 {+2.59} Bd7 {+2.68} 30. g5 {+3.3200000000000003} h5 {+3.3200000000000003} 31. g6 {+4.94} Rf6 {+6.01} 32. Qe2 {+5.98} exf5 {+6.5200000000000005} 33. Rxe7 {+6.72} Rxg6+ {+6.05} 34. Bg2 {+7.32} d4 {+5.89} 35. Kf1 {+7.28} Bc6 {+7.66} 36. Bxc6 {+7.8100000000000005} Qxc6 {+7.9} 37. Re8+ {+7.890000000000001} Kh7 {+8.13} 38. Qxh5+ {+8.15} Rh6 {+8.15} 39. Qxf5+ {+8.32} Rg6 {+8.540000000000001} 40. R1e6 {+8.5} Qg2+ {+8.73} 41. Ke1 {+8.74} Qg1+ {+8.76} 42. Kd2 {+8.88} Qg4 {+8.89} 43. Qf7 {+9.15} Rxe6 {+9.4} 44. Qg8+ {+9.6} Kh6 {+9.57} 45. Rxe6+ {+9.55} Qxe6 {+9.63} 46. Qxe6+ {+9.67} Kh5 {+9.72} 47. Qxb6 {+9.8} Kxh4 {+9.78} 48. Qxa5 {+9.870000000000001} Kh5 {+9.870000000000001} 49. Qxc5+ {+9.870000000000001} g5 {+9.870000000000001} 50. Qxd4 {+10.01} Kg6 {+64.0} 51. Qe4+ {+64.25} Kf6 {+64.26} 52. a5 {+25.27} Kg7 {+75.27} 53. a6 {+#12} Kf7 {+149.45000000000002} 54. a7 {+#5} g4 {+#3} 55. a8=Q {+#3} g3 {+#2} 56. Qf5+ {+#2} Kg7 {+#1} 57. Qaf8# {+#1} *
```
