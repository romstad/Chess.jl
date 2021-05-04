### A Pluto.jl notebook ###
# v0.14.5

using Markdown
using InteractiveUtils

# ╔═╡ eb038b1a-b2af-49a2-b506-9315df701f47
using Chess

# ╔═╡ f30458ad-89ea-4928-a4e0-4ebff355c573
using PlutoUI # For `with_terminal`.

# ╔═╡ e89bfaed-22da-4f99-aec2-989595e2eff3
using Chess.PGN

# ╔═╡ b8476885-214a-4708-b933-4aac278f3b5b
using Chess.Book

# ╔═╡ f0cf3415-571f-4661-8823-2598aef00c2d
using Chess.UCI

# ╔═╡ a6d99974-5c03-4bf6-b6af-4ccf76d1b9e9
md"# Chess.jl Tutorial"

# ╔═╡ b9d53c2d-faa1-4a44-8b8c-bc62c5237797
md"""
## Table of Contents

* [Introduction](#introduction)
* [Boards](#boards)
  + [Creating Boards](#creating_boards)
  + [Making and Unmaking Moves](#making_and_unmaking_moves)
* [Pieces, Piece Colors, and Piece Types](#pieces_piece_colors_and_piece_types)
* [Squares](#squares)
* [Moves](#moves)
* [Square Sets](#square_sets)
  + [Creating Square Sets](#creating_square_sets)
  + [Extracting Square Sets From Boards](#extracting_square_sets_from_boards)
  + [Set Operations](#set_operations)
  + [Iterating Through Square Sets](#iterating_through_square_sets)
  + [Attack Square Sets](#attack_square_sets)
* [Games](#games)
  + [Creating Games and Adding Moves](#creating_games_and_adding_moves)
  + [Example: Generating Random Games](#example_generating_random_games)
  + [Opening Games in Lichess](#opening_games_in_lichess)
  + [Variations](#variations)
  + [Comments](#comments)
  + [Numeric Annotation Glyphs](#numeric_annotation_glyphs)
* [PGN Import and Export](#pgn_import_and_export)
  + [Creating a Game From a PGN String](#creating_a_game_from_a_pgn_string)
  + [Working With PGN Files](#working_with_pgn_files)
* [Opening Books](#opening_books)
  + [Finding Book Moves](#finding_book_moves)
  + [Example: Playing Random Openings](#example_playing_random_openings)
* [Interacting With UCI Chess Engines](#interacting_with_uci_chess_engines)
  + [Starting and Initializing Engines](#starting_and_initializing_engines)
  + [Searching](#searching)
  + [Parsing Search Output](#parsing_search_output)
  + [Example: Engine vs Engine Games](#example_engine_vs_engine_games)
"""

# ╔═╡ 2ef8d62b-c32f-486f-a2e5-c82ed0418170
md"""
## $(html"<a id='introduction'></a>") Introduction

Chess.jl is a library for doing computer chess in Julia. It contains utilities for creating and manipulating chess positions and games, reading and writing chess games in the popular [PGN](https://en.wikipedia.org/wiki/Portable_Game_Notation) format (including support for comments and variations), for creating opening trees, and for interacting with [UCI chess engines](http://wbec-ridderkerk.nl/html/UCIProtocol.html).

The library should be suitable for most chess programming tasks, except perhaps for trying to write the strongest possible chess engine. Writing a strong chess engine using Chess.jl is certainly possible, and reaching super-human strength shouldn't be too hard, but for maximum performance, a lower-level language like C, C++, Rust or Nim would probably be better.

Most of the functions described in this tutorial are located in the `Chess` module:
"""

# ╔═╡ 563c93f0-721d-4d93-8530-3d219f197bb5
md"""
## $(html"<a id='boards'></a>") Boards

### $(html"<a id='creating_boards'></a>") Creating boards

A chess board is represented by the `Board` type. A board is usually obtained in one of five ways:

1. By calling the `startboard()` function, which returns a board initialized to the standard chess opening position.
2. By using the `@startboard` macro, which allows you to provide a sequence of moves from the starting position.
3. By calling the `fromfen()` function, which takes a board string in [Forsyth-Edwards Notation](https://en.wikipedia.org/wiki/Forsyth–Edwards_Notation) and returns the corresponding board.
4. By making a move or a sequence of moves on an existing chess board, using a function like `domove()` or `domoves()`.
5. By calling the `board()` function on a `Game` or a `SimpleGame`, obtaining the current board position in a game. See the section on games later in this tutorial for a discussion of these types)

Let's begin with the most basic way of creating a chess board: The `startboard()` function.
"""

# ╔═╡ fe7e2e16-6e57-4ab0-92cb-be3465c5bcab
startboard()

# ╔═╡ 861c5b57-7f28-4d59-800b-eeb68a1223b0
md"""The "open in lichess" link will open the board in the popular chess site [lichess](https://lichess.org). Lichess is the best place to play or study chess on the Internet, and best of all, it is completely free!

Sometimes you want to set up a board position by making some moves from the starting position. You could do this by first calling `startboard()` and then calling the `domoves()` or `domoves!()` function (more about those later in this tutorial), but that quickly becomes tedious for interactive use. The `@startboard` macro can be used as a convenient shortcut:
"""

# ╔═╡ 9c7d61a6-81b9-4674-bcee-c86023fa3dc0
@startboard e4 e5 Nf3 Nc6 Bb5

# ╔═╡ f49a0b6f-4283-4e9c-9570-a37d71f653f9
md"""
Annoyingly, the minus sign in standard castling notation (`O-O` for kingside castling and `O-O-O` for queenside castling) confuses Julia's parser. For castling moves, just skip the minus sign and write `OO` or `OOO`, as in the following example.
"""

# ╔═╡ aee3fa17-44b8-41c4-ba6e-aaca43081157
@startboard e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3 g6 Be3 Bg7 f3 OO Qd2 Nc6 OOO

# ╔═╡ 293a3b35-3466-4d11-b116-8cc96fade2a9
md"""
Setting up an arbitrary board position without entering a move sequence can be done with the `fromfen()` function:
"""

# ╔═╡ 0c12848b-5892-425f-8ed2-fd00c5e3a4db
fromfen("5rk1/p1pb2pp/2p5/3p3q/2P3n1/1Q4BN/PP1Np1KP/R3R3 b - -")

# ╔═╡ b4cfb722-7f8c-4106-9cc3-5fcefb8d2233
md"""
FEN strings are quite easy to understand. The first component (`5rk1/p1pb2pp/2p5/3p3q/2P3n1/1Q4BN/PP1Np1KP/R3R3` in the above example) is the board setup. The ranks of the board are listed from top to bottom (beginning with rank 8), separated by the `/` character. For each rank, lowercase letters (p, n, b, r, q or k) denote black pieces, while uppercase letters (P, N, B, R, Q or K) denote white pieces. Digits represents empty squares. In the above example, the 8th rank is `5rk1`, meaning five empty squares followed by a black rook and a black king, and finally one empty square.

The second component (`b` in the above example) is the side to move. It is always one of the two characters `w` or `b`, depending on the side to move. In this case, it's black.

The third component (`-` in the example) is the current castle rights. The dash means that neither side has the right to castle. If one or both sides still have the right to castle, the letters `K`, `Q`, `k` and `q` are used. The uppercase letters mean that white can castle kingside or queenside, while the lowercase letters mean that black can castle. For instance, in a position when both sides can still castle in either direction, the third component would be `KQkq`. In a position where white can only castle queenside and black only kingside, it would be `Qk`.

The fourth coponent (`-` in the example) is the square on which an en passant capture is possible. The dash means that no en passant capture is possible in our case. If an en passant capture had been possible on e3, the fourth component would have been `e3`.

For additional examples and explanations, visit the [Wikipedia article on FEN strings](https://en.wikipedia.org/wiki/Forsyth–Edwards_Notation).
"""

# ╔═╡ 967d3055-45d9-4c77-b0c2-7d514a407278
md"""
### $(html"<a id='making_and_unmaking_moves'></a>")Making and Unmaking Moves

Given a chess board, you will often want to modify the board by making some moves. The most straightforward way to do this is with the `domove` function, which takes two parameters: A chess board and a move. The move can be either a value of the `Move` type or a string representing a move in UCI or SAN notation.

Here's an example of using `domove` to make a move given by a string in short algebraic notation (SAN):
"""

# ╔═╡ 7dd7fa6e-717b-4ba1-a110-987a4cb53a5b
begin
	local b = startboard()
	domove(b, "d4")
end

# ╔═╡ be9065b3-3040-4704-a6cd-6deb7060a0c1
md"""
There is also a function `domoves` that takes a sequence of several moves and executes all of them:
"""

# ╔═╡ b5f6826e-3855-4d41-8ce0-27587dfa598b
begin
	local b = startboard()
	domoves(b, "Nf3", "d5", "c4")
end

# ╔═╡ 633a0f4c-6e5f-40fb-8373-6dd25d8fda6a
md"""
Note that both of these functions return new boards: The original board is left unchanged, as illustrated by this example:
"""

# ╔═╡ 43eb49ed-afba-4850-9b3d-2e36fc800eff
begin
	local b = startboard()
	domove(b, "c4")
	b
end

# ╔═╡ 240dde91-ca7b-4078-a9da-5af8ca72b210
md"""
This is convenient when writing code in a functional style, or when using a reactive notebook environment like Pluto. Unfortunately, it also results in a lot of copying of data, and heap allocations that may have signifcant performance impacts for certain types of applications. When this is a problem, there are alternative functions `domove!` and `domoves!` that destructively modify the input board.

Here is the result of the previous example when modified to use `domove!`:
"""

# ╔═╡ d56d75c2-879f-466f-a634-8f7a19ff389a
begin
	local b = startboard()
	domove!(b, "c4")
	b
end

# ╔═╡ ccd6feec-a51a-4a6e-ad84-95d215604e9a
md"""
`domove!` returns a value of type `UndoInfo`. This can be used to undo the move and go back to the board position before the move was made.
"""

# ╔═╡ ba204c76-7f08-47ec-b64e-9b28e16ce141
begin
	local b = startboard()
	local u = domove!(b, "e4")
	undomove!(b, u)
	b
end

# ╔═╡ 917de419-d7b0-4d61-a897-5bcb012b8e2e
md"""
There is also a function `domoves!()` that can be used to destructively update a board with a sequence of several moves. Unlike `domove!`, this operation is irreversible. No `UndoInfo` is generated, and there is no way to undo the moves and return to the original board.
"""

# ╔═╡ bb906070-43a8-4b5c-a9e5-b248f12b0b89
begin
	local b = startboard()
	domoves!(b, "d4", "Nf6", "c4", "g6", "Nc3", "Bg7", "e4", "d6", "Nf3", "O-O")
	b
end

# ╔═╡ d70b1d38-c897-4b7c-9fa4-7c19ca06e553
md"""
Remember that there is also a macro `@startboard` that allows you to do this more conveniently. The above example could also be written like this:
"""

# ╔═╡ 528d6ca6-7b33-4dcf-8738-90260915c699
@startboard d4 Nf6 c4 g6 Nc3 Bg7 e4 d6 Nf3 OO

# ╔═╡ dd5a8f77-8af5-41ea-936f-49b36ee22f54
md"""
## $(html"<a id='pieces_piece_colors_and_piece_types'></a>")Pieces, Piece Colors, and Piece Types

Chess pieces are represented by the `Piece` type (internally, a simple wrapper around an integer). There are constants `PIECE_WP`, `PIECE_WN`, `PIECE_WB`, `PIECE_WR`, `PIECE_WQ`, `PIECE_WK`, `PIECE_BP`, `PIECE_BN`, `PIECE_BB`, `PIECE_BR`, `PIECE_BQ` and `PIECE_BK` for each of the possible white or black pieces, and a special piece value `EMPTY` for the contents of an empty square on the board.

There are also *piece colors*, represented by the `PieceColor` type (possible values `WHITE`, `BLACK` and `COLOR_NONE`), as well as *piece types*, represented by the `PieceType` type (possible values `PAWN`, `KNIGHT`, `BISHOP`, `ROOK`, `QUEEN`, `KING` and `PIECE_TYPE_NONE`).

Given a piece, you can ask for its color and type by using `pcolor` and `ptype`:
"""

# ╔═╡ 0f257004-8605-4b14-b255-ca0e231ae406
pcolor(PIECE_BN)

# ╔═╡ 4d60d4da-ae36-4784-80ca-bac8aebc1933
ptype(PIECE_BN)

# ╔═╡ a310bac6-080a-4ada-acc1-f423843a9497
md"""
Conversely, if you have a `PieceColor` and a `PieceType`, you can create a `Piece` value by calling the `Piece` constructor:
"""

# ╔═╡ a400d50d-02d5-4a52-ad76-f22d86d5e332
Piece(WHITE, ROOK)

# ╔═╡ 2ca00e38-f7b9-4c0b-be0e-7b92898944ca
md"""
The special `Piece` value `EMPTY` has piece color `COLOR_NONE` and piece type `PIECE_TYPE_NONE`:
"""

# ╔═╡ 93e07389-1624-4530-95fc-b5a51a926fc3
pcolor(EMPTY)

# ╔═╡ caea759c-a63d-43d5-a87f-70441ef77aba
ptype(EMPTY)

# ╔═╡ 4877f578-96d6-44fc-a9c5-cf431f274303
md"""
The current side to move of a board is obtained by calling `sidetomove`:
"""

# ╔═╡ fb2aed2e-aa35-4d7d-92f3-5236075be26a
sidetomove(startboard())

# ╔═╡ 60672e37-4ad8-41dc-9854-344fd40362f6
sidetomove(@startboard Nf3)

# ╔═╡ a7ba9a08-a508-4771-a411-5d564fbcad22
md"""
Use the unary minus operator or the function `coloropp` to invert a color:
"""

# ╔═╡ d06dc3a1-a8ef-4f09-8538-e4ba25efca64
-WHITE

# ╔═╡ aabdade4-3ec7-4832-8bf7-7285d0658361
coloropp(BLACK)

# ╔═╡ 9db8e449-f98d-4735-9c49-2d369aed0b6e
md"""
## $(html"<a id='squares'></a>")Squares

Squares are represented by the `Square` data type. Just as for pieces, piece colors, and piece types, this type is internally just a simple wrapper around an integer. There are constants `SQ_A1`, `SQ_A2`, ..., `SQ_H8` for the 64 squares of the board.

One of the common uses of `Square` values is to ask about the contents of a square on a chess board. This is done with the `pieceon` function:
"""

# ╔═╡ cfdef501-7c9e-4662-80c4-54441bd093c1
pieceon(startboard(), SQ_B1)

# ╔═╡ 29e63f8c-980a-44d3-96d8-4728ba558ac2
pieceon(startboard(), SQ_E8)

# ╔═╡ 20382e3f-6b31-4ba2-b07f-641dcc73fa71
pieceon(startboard(), SQ_A3)

# ╔═╡ 2f8050ef-6faa-4150-8221-5714e94bd2e1
md"""
There are also two types `SquareFile` and `SquareRank` for representing the files and ranks of a board. Given a square, we can get its file or rank by calling `file` or `rank`:
"""

# ╔═╡ 0d8e77f3-dd7b-40c1-b9af-18d5883009a9
file(SQ_E5)

# ╔═╡ 09674208-60c5-4fad-83af-ffb15d8f2f91
rank(SQ_E5)

# ╔═╡ 13cc3c48-9690-4b91-a253-c7a355c1a40e
md"""
Conversely, it is possible to create a `Square` from a `SquareFile` and a `SquareRank`:
"""

# ╔═╡ 47b748d5-c1a4-41ca-99f4-51fb216db311
Square(FILE_C, RANK_4)

# ╔═╡ 6e0451c3-c68a-4783-a1a0-87c69b321bd7
md"""
We can use the functions `tostring` and `squarefromstring` to convert between `Square` values and strings:
"""

# ╔═╡ 51a76d49-d8b9-46b0-8908-08e86b1640f0
tostring(SQ_D4)

# ╔═╡ 7436bddb-53e2-4044-a2df-a63d8cb5ba5d
squarefromstring("g6")

# ╔═╡ eb6edb9c-c4b3-4dc0-b1ac-9bc5817a1149
md"""
## $(html"<a id='moves'></a>") Moves

Moves are represented by the type `Move`. A `Move` value can be obtained by calling one of two possible constructors:
"""

# ╔═╡ 3e1544e5-1a68-419e-8039-99afc55c3836
# Normal move
Move(SQ_E2, SQ_E4)

# ╔═╡ 53ac9f47-f66a-4329-aa16-61dcbe4be365
# Promotion move
Move(SQ_A7, SQ_A8, QUEEN)

# ╔═╡ 67cdc5dd-865d-4bb2-b130-adf7c2e874a5
md"""
We can also convert a move to/from strings in UCI notation:
"""

# ╔═╡ 31cfa4be-8af4-4db5-a183-7f7828f8a15b
tostring(Move(SQ_G8, SQ_F6))

# ╔═╡ a55b94dc-a9d1-4749-b03f-294e2371e169
movefromstring("b2c1r")

# ╔═╡ c03f1d2c-544f-47eb-89d0-fbcb3143524d
md"""
Parsing move strings in short algebraic notation (SAN) requires a board. Without
a board, there is no way to know the source square of a move string like `"Nf3"`. Given a board, we can convert to/from SAN move strings using `movetosan` and `movefromsan`:
"""

# ╔═╡ aba22fd4-c0aa-4d93-863f-fc571396e7c3
movetosan(startboard(), Move(SQ_G1, SQ_F3))

# ╔═╡ e1266ab4-d5ae-4414-bd4b-0113c1875cd6
movefromsan(startboard(), "e4")

# ╔═╡ bd80c9f7-1ddb-47a7-a4f5-01bae805e8cd
md"""
One of the most common ways to obtain a move is to call the `moves` function on a board. This returns a `MoveList`, a list of all legal moves for the board:
"""

# ╔═╡ fb57388a-b5eb-4383-b2ce-38b6e10afb01
begin
	b = @startboard d4 Nf6 c4 e6 Nc3 Bb4
	moves(b)
end

# ╔═╡ 2730adae-23b3-41f0-856a-a46813465208
md"""
## $(html"<a id='square_sets'></a>") Square Sets

The `SquareSet` type represents a set of squares on the chess board. We can do set-theoretic operations like union, intersection and complement on square sets, and test for set membership. Internally, a `SquareSet` is represented by a 64-bit integer, with set operations performed through bitwise operations. This makes square sets very fast to manipulate. 
"""

# ╔═╡ e2c56253-8745-4262-86d4-be83ab7908ca
md"""
### $(html"<a id='creating_square_sets'></a>") Creating Square Sets

There is a `SquareSet` constructor that takes a sequence of squares as input and returns the corresponding square set:
"""

# ╔═╡ 9c8b289b-5cda-4578-8d99-6311322c0e98
SquareSet(SQ_A1, SQ_A2, SQ_A3)

# ╔═╡ 5e193e21-457c-4bb2-bd51-8e8d131891cc
md"""
There are also pre-defined constants `SS_FILE_A`, ..., `SS_FILE_H` for the eight files of the board, and `SS_RANK_1`, ..., `SS_RANK_8` for the eight ranks.
"""

# ╔═╡ ff444a68-e964-47a7-bbf4-2061f85ffb5b
SS_FILE_B

# ╔═╡ 37d27b7a-1e57-4a73-a1d3-04b54add087a
SS_RANK_6

# ╔═╡ 9e14663e-89cb-4445-9eb3-f3ac9dc84d36
md"""
### $(html"<a id='extracting_square_sets_from_boards'></a>") Extracting Square Sets From Boards

Given a `Board` value, there are several functions for obtaining various square sets. The `pieces` function has several methods for extracting sets of squares occupied by various pieces.

The squares occupied by white pieces:
"""

# ╔═╡ 142b4958-449f-4983-afe6-cee5ecb17ae5
pieces(startboard(), WHITE)

# ╔═╡ 4ef7bd67-e834-422a-baa0-2f3870a976d9
md"The set of all squares occupied by pawns of either color (you can also do `pawns(startboard())` with the same effect):"

# ╔═╡ 82a738f6-e3d3-45a3-91ae-90dd3568834b
pieces(startboard(), PAWN)

# ╔═╡ a376190c-69d0-4f47-9b48-fdaa77ffb57b
md"""
The set of squares occupied by black knights (you can also do `knights(startboard(), BLACK)`:
"""

# ╔═╡ d97d771d-6d61-4dbd-b224-0093757b3c5c
pieces(startboard(), PIECE_BN)

# ╔═╡ 42ff96a4-fc48-47f8-b2c2-129a96f6821e
md"The set of all occupied squares on the board:"

# ╔═╡ 245f5586-c8dc-4d61-8d7c-d557d228a9f7
occupiedsquares(startboard())

# ╔═╡ a8df6297-1fdb-4b46-8410-d7e268c6fc1c
md"""
The set of all empty squares on the board:
"""

# ╔═╡ 42db7246-f3a1-4d1d-a6d0-4fec13c3c2c2
emptysquares(startboard())

# ╔═╡ 07f3796a-2fa9-4dc0-b32a-26c834e55716
md"""
### $(html"<a id='set_operations'></a>") Set Operations

It is possible to do various basic set theoretic operations likecomplement, union, increment, and membership tests on square sets, using standard mathematical notation. This sections gives a few examples.

Set membership tests (type `\in <TAB>` and `\notin <TAB>` for the `∈` and `∉` characters):
"""

# ╔═╡ fed01377-5252-40b6-9e0f-a6034b3ef62d
SQ_D1 ∈ SS_FILE_D

# ╔═╡ 7dbd5b17-cc63-4464-9d95-cf87ed172a0b
SQ_D1 ∈ SS_RANK_2

# ╔═╡ 1971c152-3f24-4934-bb94-d0d9567f9024
SQ_E4 ∉ SS_RANK_8

# ╔═╡ 0cc94af0-759a-4399-b21f-5e1d7e278683
md"Set complement:"

# ╔═╡ 4e00a4e7-e615-4a0d-bdd8-64a7aefa6e93
-SS_RANK_4

# ╔═╡ 512ba223-92bf-4ed6-adf1-86744ebb5712
md"""
Set union (type `\cup <TAB>` for the `∪` character):
"""

# ╔═╡ 061ac99b-8391-4a72-af14-d35dcabd063d
SS_RANK_2 ∪ SS_FILE_F

# ╔═╡ 5baa21b3-f0c3-4f63-b474-527d6820059a
md"""
Set intersection (type `\cap <TAB>` for the `∩` character):
"""

# ╔═╡ e8923543-8e52-48e0-a427-cd60494fc258
SS_FILE_D ∩ SquareSet(SQ_D4, SQ_D5, SQ_E4, SQ_E5)

# ╔═╡ 51b64306-e90b-409b-9472-f542948d10ec
md"Set subtraction:"

# ╔═╡ 243faa91-d14e-4224-9c50-054536f1fc7c
SS_FILE_G - (SS_RANK_3 ∪ SS_RANK_4)

# ╔═╡ 3431451d-9440-4918-8018-41c5a2a077d8
md"""
### $(html"<a id='iterating_through_square_sets'></a>") Iterating Through Square Sets

The `squares` function can be used to convert a `SquareSet` to a vector of squares:
"""

# ╔═╡ ef447813-6405-475c-ae2d-427fcc6b38a1
squares(SS_FILE_A)

# ╔═╡ e5cbc125-f314-49d1-8c4e-6db26b77ff6d
md"""
The `squares` function is not necessary for most tasks. It is possible – and much more efficient – to iterate through a `SquareSet` directly:
"""

# ╔═╡ aafe9561-3af4-43ff-a069-02832b18997d
with_terminal() do
	for s ∈ SS_RANK_5
		println(tostring(s))
	end
end

# ╔═╡ 96f1a91e-2ba4-47ed-ba15-2490c93177a6
md"""
### $(html"<a id='attack_square_sets'></a>") Attack Square Sets

Chess.jl contains several functions for generating attacks to/from squares on the chess board.

Attacks by knights, kings or pawns from a given square on the board are the most straightforward.

The squares attacked by a knight on e5:
"""

# ╔═╡ fd30409a-a432-4c17-8210-3782c06daa98
knightattacks(SQ_E5)

# ╔═╡ d66fac3b-431b-48fb-80fb-fc59fd4cf4bf
md"The squares attacked by a king on g2:"

# ╔═╡ ee8dceb5-45b0-43e6-80c5-608f9278fd07
kingattacks(SQ_G2)

# ╔═╡ b3ce5ebc-e40b-491d-8a76-a4dd94db671d
md"The squares attacked by a black pawn on c5 (the color is necessary here, because white and black pawns move in the opposite direction):"

# ╔═╡ f06e6a49-a160-4e83-a921-91da15586c86
pawnattacks(BLACK, SQ_C5)

# ╔═╡ 2e2f2d49-c654-4310-92b9-bed38e9c43c6
md"""
Sliding pieces (bishops, rooks and queens) are a little more complicated, because we need the set of occupied squares on the board in order to identify possible blockers before we can know what squares they attack.

The most common way of providing a set of occupied squares is to use an actual chess board. Let's first create a board position a little more interesting than the starting position.
"""

# ╔═╡ c9493ea0-6e3e-498e-99bb-bcdb8ed5ecee
attackboard = @startboard e4 e5 Nf3 Nc6 d4 exd4 Nxd4 Nf6

# ╔═╡ 74ce06b7-4874-4af7-95e5-191874897fde
md"""
The set of squares attacked by the white queen on d1:
"""

# ╔═╡ 87cbdb1d-b22d-4ebb-8d39-78e22d8288cf
queenattacks(attackboard, SQ_D1)

# ╔═╡ 98fdea63-d717-4deb-a0b3-df98beb14e7d
md"""
The set of squares a bishop on c4 would have attacked (there is no bishop on c4 at the moment, but this does not stop us from asking which squares a hypothetical bishop there would attack):
"""

# ╔═╡ a0e1bd70-57a2-4927-997c-4d34498d06a3
bishopattacks(attackboard, SQ_C4)

# ╔═╡ f70b74fb-d8f7-4442-8844-aca4f949236b
md"""
There is also an `attacksfrom` function, that returns the set of squares attacked by the piece on a given non-empty square, and an `attacksto` function, that returns all squares that contains pieces of either side that attacks a given square:
"""

# ╔═╡ 753f9583-3ccd-4003-9b9b-13b45bf94da4
attacksfrom(attackboard, SQ_H8)

# ╔═╡ 943b6011-c084-4bcd-982b-edc98c131e84
attacksto(attackboard, SQ_D4)

# ╔═╡ 0781fda3-6272-480e-b735-eb5df673d551
md"""
It is possible to identify pieces that can be captured by intersecting attack square sets with sets of pieces of a given color:
"""

# ╔═╡ b38816ba-9081-48e1-b048-5efae8ec9983
attacksfrom(attackboard, SQ_D4) ∩ pieces(attackboard, BLACK)

# ╔═╡ c7448f82-a870-4985-bc68-20de5ca22bc1
md"""
Here is a more complicated example: A function that finds all pieces of a given side that are attacked, but undefended:
"""

# ╔═╡ 46ed3c54-56ca-4055-8026-9d509acc4f8e
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

# ╔═╡ 1cbe2b57-c6d5-4daa-a192-9f4026f04cd7
md"""
Let's create a position for testing the above function:
"""

# ╔═╡ 35ec6c59-a647-4151-9615-d6732a96f68d
testboard = fromfen("r1b5/1kp5/1p3b1p/8/8/4B3/2R3n1/QK6 w - - 0 1")

# ╔═╡ ce18f885-8979-4139-aec4-47d74dad48ab
md"""
A total of five black pieces can be captured: The rook on a8, the pawns on b6 and c7, the bishop on f6, the knight of g2, and the pawn on h6. However, the first three of these are defended by black pieces. Let's try our `attacked_and_undefended` function:
"""

# ╔═╡ e1c6d80d-78b9-496b-9507-fe7ad72665e6
attacked_but_undefended(testboard, BLACK)

# ╔═╡ 0e921fbf-5a1e-4059-9f75-6b04a5c5d44c
md"""
## $(html"<a id='games'></a>") Games

There are two types for representing chess games: `SimpleGame` and `Game`. `SimpleGame` is a basic type that contains little more than the PGN headers (player names, game result, etc.) and a sequence of moves. `Game` is a more complicated type that support annotated, tree-like games with comments and variations. If you don't need these features, `SimpleGame` is always a better choice, as manipulating a `SimpleGame` is much faster.

For the rest of this section, most of our examples use the more complicated `Game` type. With a few exceptions (that will be pointed out), methods with identical names and behavior exist for the `SimpleGame` type. Remember again that `SimpleGame` is really the preferred type in practice, unless you *really* need the extra functionality of the `Game` type.
"""

# ╔═╡ 62cdb11f-b5af-4ed4-b530-42cb5516fcc8
md"""
### $(html"<a id='creating_games_and_adding_moves'></a>") Creating Games and Adding Moves

To create an empty game from the standard chess position, use the parameterless `Game()` constructor:
"""

# ╔═╡ 8ae7347e-0d28-44ff-a69f-c28630223a32
Game()

# ╔═╡ aa8d936a-d770-4c54-b2b3-2056da300e0d
md"""
To the left, we have the current chess board. To the right, we have the move list, which is currently empty, because we haven't added any moves to the game.

Moves can be added to the game with the `domove!()` function:
"""

# ╔═╡ 445c66af-6c1e-4333-a23c-f40a054a840c
begin
	local g = Game()
	domove!(g, "c4")
	domove!(g, "e5")
	domove!(g, "Nc3")
	domove!(g, "Nf6")
	g
end

# ╔═╡ eaec04ab-f617-4668-a1fc-8a6b9e9985d0
md"""
Constructing games this way quickly becomes tedious. For interactive use, there is a macro `@game` (and a similar macro `@simplegame` for the `SimpleGame` type) for constructing a game from the regular starting position with a sequence of moves. The following is equivalent to the above example:
"""

# ╔═╡ e74c0896-32fc-4b62-8358-60d965ac7e1b
@game c4 e5 Nc3 Nf6

# ╔═╡ ea9e5051-f456-4ec2-91da-435b5b66c60e
md"""
Notice that there is now a list of moves in the right hand side of the output.
The "👉" symbol indicates our current position in the game. It is possible to go back to the previous position in the game with the `back!` function, and to go forward again with `forward!`. There are also functions `tobeginning!` and `toend!` for going to the beginning or end of the game.

Examples:
"""

# ╔═╡ 0988d9ab-352c-419e-8294-837f0b42ca2c
begin
	local g = @game e4 c6 d4 d5 Nc3 dxe4 Nxe4 Nf6
	back!(g)
	back!(g)
end

# ╔═╡ cc28612f-89e4-4ceb-90c0-75451839f7b2
md"""
The "👉" is now before the move Nxe4, because we went back two moves.
"""

# ╔═╡ 4868af76-ccd5-40a6-b9bc-5e2d6031368e
begin
	local g = @game d4 Nf6 c4 e6 Nc3 Bb4
	tobeginning!(g)
end

# ╔═╡ 7780d253-78d1-4952-9f3e-ab25f0cb154c
md"""
We see the starting position on the left, and the "👉" at the beginning of the move list on the right, because we called `tobeginning!` to go back to the beginning of the game.
"""

# ╔═╡ 519492dc-e393-4002-aead-5c679fdb4def
md"""
To get the current board in the game, use the `board` function:
"""

# ╔═╡ 3848c2e7-1a11-4f46-b153-c4806dc2d299
begin
	local g = @game d4 Nf6 c4 c5 d5 b5
	board(g)
end

# ╔═╡ 66e5c7ea-85ae-41a9-994f-225e3a7299e3
md"""
### $(html"<a id='example_generating_random_games'></a>") Example: Generating Random Games

By putting together things we've learned earlier in this tutorial, we can now generate random games. This function generates a `SimpleGame` containing random moves:
"""

# ╔═╡ 5edb6907-1012-4e47-b656-daac485deb0a
function randomgame()
	game = SimpleGame()
	while !isterminal(game)
		move = rand(moves(board(game)))
		domove!(game, move)
	end
	game
end

# ╔═╡ 6fd5e41f-7597-499e-bb8b-668e1169a17f
md"""
The only new function in the above function is `isterminal`, which tests for a game over condition (checkmate or some type of immediate draw).

Let's generate a random game:
"""

# ╔═╡ 83cd74d2-d30c-4e35-9670-868d1558165e
randomgame()

# ╔═╡ 05d63c5c-a517-4651-897b-9c1321c9d698
md"""
Approximately how often do completely random games end in checkmate? Let's find out. The following function takes an optional number of games as input (by default, one thousand), generates the deseired number of random games, and returns the fraction of the games that (accidentally) ends in checkmate.
"""

# ╔═╡ 09153cfa-40b5-4bb7-8607-30116e67f65b
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

# ╔═╡ 6143279b-3467-4d16-830e-8797394f1be3
md"""
The above code introduces the new function `ischeckmate`, which tests if a board is a checkmate position.

Let's test it:
"""

# ╔═╡ 618f732c-6dff-445b-a8d6-9062f1f74ade
checkmate_fraction()

# ╔═╡ 76aba57e-0212-4c5d-881b-2c7f20346af1
md"""
It seems that about 15% of all random games end in an accidental checkmate. To me, this is a suprisingly high number.

What will happen if we make random moves, except that we always play the mating move if there is a mate in one? Let's find out. As a first step, let's write a function that checks whether a move is a mate in one.
"""

# ╔═╡ 503bb6dd-1857-494c-a9d5-573e1821d280
move_is_mate_slow(board, move) = ischeckmate(domove(board, move))

# ╔═╡ edbc60ff-1742-42f7-8ac2-5f0469e8929e
md"""
This is simple, elegant and readable. Unfortunately, as the name indicates, it is also kind of slow. The reason is that `domove` copies the board. Using the destructive `domove!` function performs much better, at the price of longer and less readable code.

The function below is functionally equivalent to the one above, but performs much better.
"""

# ╔═╡ f87b6c16-d1db-4c2d-81e0-6a13296f146e
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

# ╔═╡ 3d6e9366-7dd2-43d6-a07c-8d506dd3880c
md"""
Using the function we just wrote, we can make a function that takes a board as input and returns a mate in 1 move if there is one, or a random move otherwise.
"""

# ╔═╡ 8828a3fe-9716-4d8b-ab3a-572c487b74a1
function mate_or_random(board)
	ms = moves(board)
	for move ∈ ms
		if move_is_mate(board, move)
			return move
		end
	end
	rand(ms)
end

# ╔═╡ 69f6e662-8e9f-432a-b698-a6141100b931
md"""
The function below is identical to the `randomgame` function above, except that it uses `mate_or_random` instead of totally random moves:
"""

# ╔═╡ e8e047c4-186c-44bb-966a-b8b1b7c4b57f
function almost_random_game()
	game = SimpleGame()
	while !isterminal(game)
		move = mate_or_random(board(game))
		domove!(game, move)
	end
	game
end

# ╔═╡ 1de7ccfa-7ef9-4519-bdfe-5da16473e977
md"""
What percentage of the games end in checkmate now? Here's a function to find out:
"""

# ╔═╡ c84b0b25-054e-48be-b5c8-33c17c34747f
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

# ╔═╡ d08ab867-3784-4afb-b0ab-3c68a8bed5c6
checkmate_fraction_2()

# ╔═╡ 1e955883-50a5-4558-bbf9-d920615ff9a2
md"""
The result should be somewhere around 0.81. About 81% of all completely random games include at least one opportunity to deliver mate in 1!
"""

# ╔═╡ 7eacb6d9-4c19-4c6c-b047-783e0962c9be
md"""
### $(html"<a id='opening_games_in_lichess'></a>")Opening Games in Lichess

You may have noticed the "Open in lichess" link in some of the above examples. This is used to open and browse through the game in lichess. Unfortunately, this is not completely automatic. The link takes you to the lichess page for importing a game in PGN notation, but does not automatically paste the game PGN. However, it does copy the PGN of the game to the clipboard.

The way to use the "Open in lichess" link is this: First, click the link. Then, in the page that appears in your browser, use Cmd+V or Ctrl+V to paste the game into the "Paste the PGN text here" box, and press the "Import PGN" button. You can now easily browse through the game. 

Here's an "almost random game" for you to try out:
"""

# ╔═╡ 2d8b2671-2ce3-43be-b26c-7f7f30ac4c70
almost_random_game()

# ╔═╡ 111f2a14-561f-4875-8203-3fda5526277f
md"""
### $(html"<a id='variations'></a>") Variations

If we create a game with some moves, go back to an earlier place in the game,
and call `domove!` again with a new move, the previous game continuation is
overwritten:
"""

# ╔═╡ fb1654f1-00cd-4a0f-b96a-4c8efebbd8dd
begin
	local g = @game d4 d5 c4 e6 Nc3 Nf6 Bg5
	back!(g)
	back!(g)
	back!(g)
	domove!(g, "Nf3")
	g
end

# ╔═╡ 50774dbe-6568-4bdb-a744-181da4b8a809
md"""
This is not always desirable. Sometimes we want to add an *alternative* move,
and to view the game as a *tree of variations*.

Games of type `Game` (but not `SimpleGame`!) are able to handle variations.

To add an alternative variation at some point in the game, first make the main line,
then go back to the place where you want to add the alternative move, and then do `addmove!`. The following example is identical to the one above, except that `domove!` has been replaced by `addmove!`:
"""

# ╔═╡ 4277b47f-c106-4bb1-aa6f-713023abce38
begin
	local g = @game d4 d5 c4 e6 Nc3 Nf6 Bg5
	back!(g)
	back!(g)
	back!(g)
	addmove!(g, "Nf3")
	g
end

# ╔═╡ d0afaa99-fabc-42ce-b0b9-4a2101ff3cbb
md"""
The board position is the same, because our current location in the game tree (indicated by the "👉" symbol) is the one after white's move 3. Nf3. However, in the move list on the right, we can see that the original main line with 3. Nc3 Nf6 4. Bg5 is still there. Alternative variations are printed in parens in the Pluto output; the "(1... Nf6 👉)" in the above example.

The function `forward!` takes an optional second argument: Which move to follow when going forward at a branching point in the tree. If this argument is ommited, the main (i.e. first) move is followed.

Here is how you would go to the point after 3. Nc3 in the above example:
"""

# ╔═╡ a1572851-4901-47c7-bda5-4901e6e493d5
begin
	local g = @game d4 d5 c4 e6 Nc3 Nf6 Bg5
	back!(g)
	back!(g)
	back!(g)
	addmove!(g, "Nf3")
	# Our current position in the game tree is here:
	#    1. d4 d5 2. c4 e6 3. Nc3 (3. Nf3 👉) Nf6 4. Bg5
	# Go one move back:
	back!(g)
	# New position in the game tree:
	#   1. d4 d5 2. c4 e6 👉 3. Nc3 (3. Nf3) Nf6 4. Bg5
	# Go forward, following the move Nc3:
	forward!(g, "Nc3")
end

# ╔═╡ 7fe31d85-d100-45ef-ae0e-e3625a1dcd32
md"""
Two other functions that are useful for navigating games with variations are `tobeginningofvariation!` and `toendofvariation!`. See the documentation of these functions for details.

Of course, variations can be nested recursively:
"""

# ╔═╡ 12b8d126-fe7b-48ff-8676-582a3060741b
begin
	local g = @game e4 c5 Nf3 Nc6
	back!(g)
	back!(g)
	addmove!(g, "c3")
	addmove!(g, "Nf6")
	addmove!(g, "e5")
	back!(g)
	back!(g)
	addmove!(g, "d5")
	addmove!(g, "exd5")
end

# ╔═╡ e5f96c44-c248-4bd4-a2b2-603f020894d4
md"""
### $(html"<a id='comments'></a>") Comments

Games of type `Game` (but again, not `SimpleGame`) can also be annotated with
textual comments, by using the `addcomment!` function:

"""

# ╔═╡ bd8f9b95-bd67-4483-b9eb-a80c5070db57
begin
	local g = @game d4 f5
	addcomment!(g, "This opening is known as the Dutch Defense")
	g
end

# ╔═╡ 2807fa4c-3b89-4d5d-bb78-4ffabf77effb
md"""
### $(html"<a id='numeric_annotation_glyphs'></a>") Numeric Annotation Glyphs

It is also possible to add *numeric annotation glyphs* (NAGs) to the game. NAGs
are a standard way of adding symbolic annotations to a chess game. All integers
in the range 0 to 139 have a pre-defined meaning, as described in [this
Wikipedia article](https://en.wikipedia.org/wiki/Numeric_Annotation_Glyphs).

Here is how to add the NAG `$4` ("very poor move or blunder") to the move 2... g4 in the game 1. f4 e5 2. g4 Qh4#:
"""

# ╔═╡ fc4cca60-ce23-4a10-8127-09bb5511deb8
begin
	local g = @game f4 e5 g4 Qh4
	back!(g)
	addnag!(g, 4)
	g
end

# ╔═╡ 56daae05-8c61-4cbe-b5ee-f0182e7e28d5
md"""
## $(html"<a id='pgn_import_and_export'></a>") PGN Import and Export

This section describes import and export of chess games in the popular [PGN
format](https://www.chessclub.com/help/PGN-spec). PGN is a rather awkward and
complicated format, and a lot of the "PGN files" out there on the Internet don't
quite follow the standard, and are broken in various ways. The functions
described in this section do a fairly good job of handling correct PGNs
(although bugs are possible), but will often fail on the various not-quite-PGNs
found on the Internet.

The PGN functions are found in the submodule `Chess.PGN`:
"""

# ╔═╡ 7386b26b-4e5a-46fd-aa1a-1488c35878bb
md"""
### $(html"<a id='creating_a_game_from_a_pgn_string'></a>") Creating a Game From a PGN String

Given a PGN string, the `gamefromstring` function creates a game object from the string (throwing a `PGNException` on failure). By default, the return value is a `SimpleGame` containing only the moves of the game, without any comments, variations or numeric annotatin glyphs. If the optional named parameter `annotations` is `true`, the return value is a `Game` with all annotations included.

Here's a PGN string for us to experiment with:
"""

# ╔═╡ 75853f99-0962-4683-ad10-a3803d4aa6ad
pgnstring = """
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

# ╔═╡ 952577ea-391f-406d-b026-814f48ea96cb
md"""
Trying to import this gives us:
"""

# ╔═╡ f3ef69e2-1ce4-4bef-a2de-043dffb7c2bb
gamefromstring(pgnstring) |> toend!

# ╔═╡ 396c5aa8-ba71-4302-8c24-ec76e74d5184
md"""
The result is a `SimpleGame`, without the annotations. If we want to import the annotations and create a `Game`, we must set the named parameter `annotations` to `true`, like this:
"""

# ╔═╡ 59be4352-7271-4a9b-adef-36d23d8eeb64
gamefromstring(pgnstring, annotations=true) |> toend!

# ╔═╡ b403afab-3ddf-42c5-98da-ac9991091f08
md"""
Unless you really need the annotations, importing to a `SimpleGame` is the
preferred choice. A `SimpleGame` is much faster to create and consumes less
memory.

Exporting a game to a PGN string is done by the `gametopgn` function. This works for both `SimpleGame` and `Game` values:
"""

# ╔═╡ f7a1bd72-2595-42e0-be8a-5f5763517131
gametopgn(gamefromstring(pgnstring)) |> Print

# ╔═╡ 4d067bb7-786a-4946-9380-a27d39f9d784
gametopgn(gamefromstring(pgnstring, annotations=true)) |> Print

# ╔═╡ 91e1cbcf-7ada-44d3-89e2-a2a9a164ec13
md"""
### $(html"<a id='working_with_pgn_files'></a>") Working With PGN Files

Given a file with one or more PGN games, the function `gamesinfile` returns a
`Channel` of game objects, one for each game in the file. Like `gamefromstring`,
`gamesinfile` takes an optional named parameter `annotations`. If `annotations`
is `false` (the default), you get a channel of `SimpleGame`s. If it's `true`,
you get a channel of `Game`s with the annotations (comments, variations and
numeric annotation glyphs) included in the PGN games.

As an example, here's a function that scans a PGN file and returns a vector
of all games that end in checkmate:
"""

# ╔═╡ 7cf93ffd-8b5e-43c6-ac5e-13d1a9183970
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

# ╔═╡ 7119bdf0-070e-40d7-94e9-ab35cf17dcf5
md"""
## $(html"<a id='opening_books'></a>") Opening Books

The opening book function are located not in the main `Chess` module, but in the submodule `Chess.Book`.
"""

# ╔═╡ 35d20127-b307-4de5-850c-46d06cbf3a1f
md"""
The `Chess.Book` module contains functions for processing large PGN files and creating opening book files. There is also a small built-in opening book. The rest of the examples in this section will use the built-in opening book. For information about generating your own books, consult the documentation for the `Chess.Book` module.
"""

# ╔═╡ 768a2a20-4b63-4c5c-ae12-4b18152b412d
md"""
### $(html"<a id='finding_book_moves'></a>") Finding Book Moves

Given a `Board`, the function `findbookentries` finds all opening book moves for that board position:
"""

# ╔═╡ 271648d8-10e8-4512-9cb3-d4907d0e0750
begin
	g = @startboard e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3 Nc6
	findbookentries(g)
end

# ╔═╡ 0114debc-032d-4d99-8d59-8c79dd20528b
md"""
The return value is a vector of `BookEntry` structs. This struct contains the
following slots:

* `move`: The book move for this book entry. For space reasons, the move is stored as an `Int32` value. To get the actual `Move` of a `BookEntry` `e`, do `Move(e.move)`.
* `wins`: The number of times the player who made this move won the game.
* `draws`: The number of times the game was drawn when this move was played.
* `losses`: The number of times the player who played this move lost the game.
* `elo`: The Elo rating of the highest rated player who played this move.
* `oppelo`: The Elo rating of the highest rated opponent against whom this move
  was played.
* `firstyear`: The first year this move was played.
* `lastyear`: The last year this move was played.
* `score`: The score of the move, used to decide the probability that this move is played when picking a book move to play. The score is computed based on the move's win/loss/draw statistics and its popularity, especially in recent games and games with strong players.

As you can see in the output of the example above, book entries are printed in a way that makes it somewhat easier to read them and understand their contents. Nevertheless, it is not easy to scan the above `BookEntry` vector and compare the statistics for the various book moves. A good way to get a summary of this information is the `printbookentries` function:
"""

# ╔═╡ dd75a72c-4218-4778-b0aa-e279794bc3fd
with_terminal() do
	b = @startboard e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3 Nc6
	printbookentries(b)
end

# ╔═╡ e1b274eb-7689-43df-aa3f-8077689267af
md"""
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
"""

# ╔═╡ 33823010-0e63-4f9b-ba29-802e9363c604
pickbookmove(@startboard d4 Nf6 c4 g6 Nc3)

# ╔═╡ cd525aa7-386f-4bc3-9814-265411e8a741
md"""
If no book moves are found for the input position, `pickbookmove` returns `nothing`.
"""

# ╔═╡ ef17fd7b-6436-4e0e-a0a7-3a0d5a019fc5
md"""
### $(html"<a id='example_playing_random_openings'></a>") Example: Playing Random Openings

Here's a function that generates a game (or rather, the beginning of a game) by picking and playing book moves until it reaches a position where no book move is found:
"""

# ╔═╡ fab9da9c-b661-4081-bc72-b5acdb3c019d
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

# ╔═╡ 95a978e2-cbcf-4a0c-90f1-98ba7405f2be
random_opening()

# ╔═╡ 8e8f6cee-f6da-4cd9-bf9d-167b7ac89808
md"""
## $(html"<a id='interacting-with-uci-engines'></a>") Interacting With UCI Engines

This section describes how to run and interact with chess engines using the
[Universal Chess Interface](http://wbec-ridderkerk.nl/html/UCIProtocol.html)
protocol. There are hundreds of UCI chess engines out there. A free, strong
and popular choice is [Stockfish](https://stockfishchess.org). Stockfish is
used as an example in this section, but any other engine should work just as
well.

For running the examples in this section, it is assumed that you have an executable `stockfish` somewhere in your `PATH` environment variable.

The code for interacting with UCI engines is found in the submodule `Chess.UCI`:
"""

# ╔═╡ 57f2184d-676e-4da9-99aa-34b0ec7798f9
md"""
### $(html"<a id='starting_and_initializing_engines'></a>")Starting and Initializing Engines

An engine is started by calling the `runengine` function, which takes the path to the engine as a parameter:
"""

# ╔═╡ 34589d78-9009-412c-8d10-1738729b14b9
sf = runengine("stockfish")

# ╔═╡ 97abbd67-36fa-4451-9e4f-ab96cf82c82b
md"""
The first thing you want to do after starting a chess engine is probably to
set some UCI parameter values. This can be done with `setoption`:
"""

# ╔═╡ 69b5b90b-9c93-4de2-a106-e0f9e6bd10a4
setoption(sf, "Hash", 256)

# ╔═╡ 9d1447b8-2d25-4567-b9f0-4b3ead7cd873
md"""
### $(html"<a id='searching'></a>") Searching

You can send a game to the engine with `setboard`:
"""

# ╔═╡ ae5595c3-0238-4f00-b4ce-d88f366d4e2e
begin
	local g = @simplegame f4 e5 fxe5 d6 exd6 Bxd6 Nc3
	setboard(sf, g)
end

# ╔═╡ 3afc20d0-4f2f-40f5-bd8d-00fb1c838b07
md"""
The second parameter to `setboard` can also be a `Board` or a `Game`.

To ask the engine to search the position you just sent to it, use the `search` function. `search` has two required parameters: The engine and the UCI `go` command we want to send to it.

Here is the most basic example of using `search`:
"""

# ╔═╡ c1b8fcc1-cbbd-43ae-8669-de7b524186b0
search(sf, "go depth 10")

# ╔═╡ abfc5a3d-5024-44a7-af3b-70eefa26dc37
md"""
The return value is a `BestMoveInfo`, a struct containing the two slots `bestmove` (the best move returned by the engine, a `Move`) and `ponder` (the ponder move returned by the engine, a `Move` or `nothing`).

The `search` function also takes an optional named parameter `infoaction`. This parameter is a function that takes each of the engine's `info` output lines and does something to them. Here's an example where we just print the engine output with `println` as our `infoaction`:
"""

# ╔═╡ 9b2e6cb8-67c7-4d15-afde-03a4ae7595da
begin
	local g = @simplegame d4 Nf6 c4 g6 Nc3 d5 cxd5 Nxd5
	setboard(sf, g)
	with_terminal() do
		search(sf, "go depth 10", infoaction = println)
	end
end

# ╔═╡ b941833a-0efa-45e8-a59f-a7007653cfc6
md"""
### $(html"<a id='parsing_search_output'></a>") Parsing Search Output

In most cases, we want something more easily to manipulate than the raw string values sent by the engines `info` lines in our `infoaction` function. The function `parsesearchinfo` takes care of this. It takes an `info` string as input and returns a `SearchInfo` value, a struct that contains the various components of the `info` line as its slots.

Let's see how this works:
"""

# ╔═╡ 29d1ada2-75ce-4a77-a136-f761052c0637
parsesearchinfo("info depth 10 seldepth 17 multipv 1 score cp 50 nodes 16598 nps 691583 tbhits 0 time 24 pv e2e4 d5c3 b2c3 c7c5 f1b5 c8d7 b5c4 f8g7 g1f3 c5d4 c3d4 d8a5 c1d2")

# ╔═╡ e6961baa-90c2-4b5d-9bfa-f71355330509
md"""
The meaning of most of the slots in this struct should be evident if you are familiar with the UCI protocol. If you are not, the two most important slots are the `score` and the `pv`.

The `score` is a value of type `Score`. The definition of the `Score` struct looks
like this:

```julia
struct Score
    value::Int
    ismate::Bool
    bound::BoundType
end
```

There are two types of score: *Centipawn scores* are an evaluation where advantages is measured on a scale where 100 means an advantage corresponding to the value of one pawn. *Mate scores* are scores of the type "mate in X moves". The type of score is indicated by the `ismate` slot, while the numerical value is indicated by the `value` slot.

For instance, when `value` is 50 and `ismate` is `false`, it means that the side to move has an advantage worth about half a pawn. If `value` is 5 and `ismate` is true, it means that the side to move has a forced checkmate in 5 half moves or less.

The final slot, `bound`, indicates whether the score is just an upper bound, a lower bound, or an exact score. The three possible values are `upper`, `lower` and `exact`.

When presenting scores to humans, the `scorestring` function is useful. For centipawn scores, it converts the score to a scale of pawn=1.0, and outputs the score with a single decimal:
"""

# ╔═╡ 08dc0954-02b2-49d2-b3a9-b99d8c41a125
scorestring(Score(-87, false, Chess.UCI.exact))

# ╔═╡ b8806c05-7158-4774-a5f7-80f579f44388
md"""
Mate in N scores are displayed as `#N`:
"""

# ╔═╡ 69f1f5fc-b538-45b3-8e41-3d4822d638ec
scorestring(Score(6, true, Chess.UCI.exact))

# ╔═╡ e72113f2-1608-4e16-adc1-eb359096dbdc
md"""
UCI chess engines always output scores from the point of view of the current side to move. This is not always what we want; often we want scores from white's point of view (i.e. positive scores mean that white is better, while negative scores mean that black is better). `scorestring` takes an optional named parameter `invertsign` that can be used to invert the sign:
"""

# ╔═╡ 07d590d0-3775-468b-a9a3-99d26393d91a
scorestring(Score(-140, false, Chess.UCI.exact), invertsign=true)

# ╔═╡ f0206a54-b71b-42b6-84da-2b87f348eced
md"""
The other interesting slot of `SearchInfo` is the `pv`. This is a vector of moves, what the engine considers the best line of play, assuming optimal play from both sides.
"""

# ╔═╡ 41bdb293-d905-4fda-ac48-fa5926222bc7
md"""
### $(html"<a id='example_engine_vs_engine_games'></a>") Example: Engine vs Engine Games

Using what we have learned, we can easily make a function that generates engine vs engine games. Let's use the `random_opening` function we wrote earlier to initialize the game with some opening position, and let the engine play out the game from there. We'll let the engine think 10 thousand nodes per move.
"""

# ╔═╡ 69feaef9-d4b1-4d12-86f6-0aadf030f8eb
function engine_game(engine)
	g = random_opening()
	while !isterminal(g)
		setboard(engine, g)
		move = search(engine, "go nodes 10000").bestmove
		domove!(g, move)
	end
	g
end

# ╔═╡ 3654e4d9-8e0a-4154-805a-330fc29ae64c
md"""
An example game:
"""

# ╔═╡ 7e1db1d9-0a8b-4056-8a21-9a6c04ad3d9d
engine_game(sf)

# ╔═╡ 727ff4b9-6f52-481d-8155-792bc35803db
md"""
Let's try to build a slightly more sophisticated function for running engine vs engine matches, that also includes the engine evaluation for each move as a comment in the game.

In our improved engine vs engine function, we need to supply an `infoaction` in the call to `search`, in order to obtain the engine evaluation. It can be done like this:
"""

# ╔═╡ f16db75f-9d13-4650-a025-705ca32a9404
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
		addcomment!(g, scorestring(score, invertsign = !whitetomove))
	end
	g
end

# ╔═╡ e753394e-ad69-47b8-8639-d60a22275c72
md"""
A test game:
"""

# ╔═╡ 5c6f4050-b7a8-4f56-aad1-f418b51e2cad
engine_vs_engine_with_evals(sf)

# ╔═╡ Cell order:
# ╟─a6d99974-5c03-4bf6-b6af-4ccf76d1b9e9
# ╟─b9d53c2d-faa1-4a44-8b8c-bc62c5237797
# ╟─2ef8d62b-c32f-486f-a2e5-c82ed0418170
# ╠═eb038b1a-b2af-49a2-b506-9315df701f47
# ╟─563c93f0-721d-4d93-8530-3d219f197bb5
# ╠═fe7e2e16-6e57-4ab0-92cb-be3465c5bcab
# ╟─861c5b57-7f28-4d59-800b-eeb68a1223b0
# ╠═9c7d61a6-81b9-4674-bcee-c86023fa3dc0
# ╟─f49a0b6f-4283-4e9c-9570-a37d71f653f9
# ╠═aee3fa17-44b8-41c4-ba6e-aaca43081157
# ╟─293a3b35-3466-4d11-b116-8cc96fade2a9
# ╠═0c12848b-5892-425f-8ed2-fd00c5e3a4db
# ╟─b4cfb722-7f8c-4106-9cc3-5fcefb8d2233
# ╟─967d3055-45d9-4c77-b0c2-7d514a407278
# ╠═7dd7fa6e-717b-4ba1-a110-987a4cb53a5b
# ╟─be9065b3-3040-4704-a6cd-6deb7060a0c1
# ╠═b5f6826e-3855-4d41-8ce0-27587dfa598b
# ╟─633a0f4c-6e5f-40fb-8373-6dd25d8fda6a
# ╠═43eb49ed-afba-4850-9b3d-2e36fc800eff
# ╟─240dde91-ca7b-4078-a9da-5af8ca72b210
# ╠═d56d75c2-879f-466f-a634-8f7a19ff389a
# ╟─ccd6feec-a51a-4a6e-ad84-95d215604e9a
# ╠═ba204c76-7f08-47ec-b64e-9b28e16ce141
# ╟─917de419-d7b0-4d61-a897-5bcb012b8e2e
# ╠═bb906070-43a8-4b5c-a9e5-b248f12b0b89
# ╟─d70b1d38-c897-4b7c-9fa4-7c19ca06e553
# ╠═528d6ca6-7b33-4dcf-8738-90260915c699
# ╟─dd5a8f77-8af5-41ea-936f-49b36ee22f54
# ╠═0f257004-8605-4b14-b255-ca0e231ae406
# ╠═4d60d4da-ae36-4784-80ca-bac8aebc1933
# ╟─a310bac6-080a-4ada-acc1-f423843a9497
# ╠═a400d50d-02d5-4a52-ad76-f22d86d5e332
# ╟─2ca00e38-f7b9-4c0b-be0e-7b92898944ca
# ╠═93e07389-1624-4530-95fc-b5a51a926fc3
# ╠═caea759c-a63d-43d5-a87f-70441ef77aba
# ╟─4877f578-96d6-44fc-a9c5-cf431f274303
# ╠═fb2aed2e-aa35-4d7d-92f3-5236075be26a
# ╠═60672e37-4ad8-41dc-9854-344fd40362f6
# ╟─a7ba9a08-a508-4771-a411-5d564fbcad22
# ╠═d06dc3a1-a8ef-4f09-8538-e4ba25efca64
# ╠═aabdade4-3ec7-4832-8bf7-7285d0658361
# ╟─9db8e449-f98d-4735-9c49-2d369aed0b6e
# ╠═cfdef501-7c9e-4662-80c4-54441bd093c1
# ╠═29e63f8c-980a-44d3-96d8-4728ba558ac2
# ╠═20382e3f-6b31-4ba2-b07f-641dcc73fa71
# ╟─2f8050ef-6faa-4150-8221-5714e94bd2e1
# ╠═0d8e77f3-dd7b-40c1-b9af-18d5883009a9
# ╠═09674208-60c5-4fad-83af-ffb15d8f2f91
# ╟─13cc3c48-9690-4b91-a253-c7a355c1a40e
# ╠═47b748d5-c1a4-41ca-99f4-51fb216db311
# ╟─6e0451c3-c68a-4783-a1a0-87c69b321bd7
# ╠═51a76d49-d8b9-46b0-8908-08e86b1640f0
# ╠═7436bddb-53e2-4044-a2df-a63d8cb5ba5d
# ╟─eb6edb9c-c4b3-4dc0-b1ac-9bc5817a1149
# ╠═3e1544e5-1a68-419e-8039-99afc55c3836
# ╠═53ac9f47-f66a-4329-aa16-61dcbe4be365
# ╟─67cdc5dd-865d-4bb2-b130-adf7c2e874a5
# ╠═31cfa4be-8af4-4db5-a183-7f7828f8a15b
# ╠═a55b94dc-a9d1-4749-b03f-294e2371e169
# ╟─c03f1d2c-544f-47eb-89d0-fbcb3143524d
# ╠═aba22fd4-c0aa-4d93-863f-fc571396e7c3
# ╠═e1266ab4-d5ae-4414-bd4b-0113c1875cd6
# ╟─bd80c9f7-1ddb-47a7-a4f5-01bae805e8cd
# ╠═fb57388a-b5eb-4383-b2ce-38b6e10afb01
# ╟─2730adae-23b3-41f0-856a-a46813465208
# ╟─e2c56253-8745-4262-86d4-be83ab7908ca
# ╠═9c8b289b-5cda-4578-8d99-6311322c0e98
# ╟─5e193e21-457c-4bb2-bd51-8e8d131891cc
# ╠═ff444a68-e964-47a7-bbf4-2061f85ffb5b
# ╠═37d27b7a-1e57-4a73-a1d3-04b54add087a
# ╟─9e14663e-89cb-4445-9eb3-f3ac9dc84d36
# ╠═142b4958-449f-4983-afe6-cee5ecb17ae5
# ╟─4ef7bd67-e834-422a-baa0-2f3870a976d9
# ╠═82a738f6-e3d3-45a3-91ae-90dd3568834b
# ╟─a376190c-69d0-4f47-9b48-fdaa77ffb57b
# ╠═d97d771d-6d61-4dbd-b224-0093757b3c5c
# ╟─42ff96a4-fc48-47f8-b2c2-129a96f6821e
# ╠═245f5586-c8dc-4d61-8d7c-d557d228a9f7
# ╟─a8df6297-1fdb-4b46-8410-d7e268c6fc1c
# ╠═42db7246-f3a1-4d1d-a6d0-4fec13c3c2c2
# ╟─07f3796a-2fa9-4dc0-b32a-26c834e55716
# ╠═fed01377-5252-40b6-9e0f-a6034b3ef62d
# ╠═7dbd5b17-cc63-4464-9d95-cf87ed172a0b
# ╠═1971c152-3f24-4934-bb94-d0d9567f9024
# ╟─0cc94af0-759a-4399-b21f-5e1d7e278683
# ╠═4e00a4e7-e615-4a0d-bdd8-64a7aefa6e93
# ╟─512ba223-92bf-4ed6-adf1-86744ebb5712
# ╠═061ac99b-8391-4a72-af14-d35dcabd063d
# ╟─5baa21b3-f0c3-4f63-b474-527d6820059a
# ╠═e8923543-8e52-48e0-a427-cd60494fc258
# ╟─51b64306-e90b-409b-9472-f542948d10ec
# ╠═243faa91-d14e-4224-9c50-054536f1fc7c
# ╟─3431451d-9440-4918-8018-41c5a2a077d8
# ╠═ef447813-6405-475c-ae2d-427fcc6b38a1
# ╟─e5cbc125-f314-49d1-8c4e-6db26b77ff6d
# ╠═f30458ad-89ea-4928-a4e0-4ebff355c573
# ╠═aafe9561-3af4-43ff-a069-02832b18997d
# ╟─96f1a91e-2ba4-47ed-ba15-2490c93177a6
# ╠═fd30409a-a432-4c17-8210-3782c06daa98
# ╟─d66fac3b-431b-48fb-80fb-fc59fd4cf4bf
# ╠═ee8dceb5-45b0-43e6-80c5-608f9278fd07
# ╟─b3ce5ebc-e40b-491d-8a76-a4dd94db671d
# ╠═f06e6a49-a160-4e83-a921-91da15586c86
# ╟─2e2f2d49-c654-4310-92b9-bed38e9c43c6
# ╠═c9493ea0-6e3e-498e-99bb-bcdb8ed5ecee
# ╟─74ce06b7-4874-4af7-95e5-191874897fde
# ╠═87cbdb1d-b22d-4ebb-8d39-78e22d8288cf
# ╟─98fdea63-d717-4deb-a0b3-df98beb14e7d
# ╠═a0e1bd70-57a2-4927-997c-4d34498d06a3
# ╟─f70b74fb-d8f7-4442-8844-aca4f949236b
# ╠═753f9583-3ccd-4003-9b9b-13b45bf94da4
# ╠═943b6011-c084-4bcd-982b-edc98c131e84
# ╟─0781fda3-6272-480e-b735-eb5df673d551
# ╠═b38816ba-9081-48e1-b048-5efae8ec9983
# ╟─c7448f82-a870-4985-bc68-20de5ca22bc1
# ╠═46ed3c54-56ca-4055-8026-9d509acc4f8e
# ╟─1cbe2b57-c6d5-4daa-a192-9f4026f04cd7
# ╠═35ec6c59-a647-4151-9615-d6732a96f68d
# ╟─ce18f885-8979-4139-aec4-47d74dad48ab
# ╠═e1c6d80d-78b9-496b-9507-fe7ad72665e6
# ╟─0e921fbf-5a1e-4059-9f75-6b04a5c5d44c
# ╟─62cdb11f-b5af-4ed4-b530-42cb5516fcc8
# ╠═8ae7347e-0d28-44ff-a69f-c28630223a32
# ╟─aa8d936a-d770-4c54-b2b3-2056da300e0d
# ╠═445c66af-6c1e-4333-a23c-f40a054a840c
# ╟─eaec04ab-f617-4668-a1fc-8a6b9e9985d0
# ╠═e74c0896-32fc-4b62-8358-60d965ac7e1b
# ╟─ea9e5051-f456-4ec2-91da-435b5b66c60e
# ╠═0988d9ab-352c-419e-8294-837f0b42ca2c
# ╟─cc28612f-89e4-4ceb-90c0-75451839f7b2
# ╠═4868af76-ccd5-40a6-b9bc-5e2d6031368e
# ╟─7780d253-78d1-4952-9f3e-ab25f0cb154c
# ╟─519492dc-e393-4002-aead-5c679fdb4def
# ╠═3848c2e7-1a11-4f46-b153-c4806dc2d299
# ╟─66e5c7ea-85ae-41a9-994f-225e3a7299e3
# ╠═5edb6907-1012-4e47-b656-daac485deb0a
# ╟─6fd5e41f-7597-499e-bb8b-668e1169a17f
# ╠═83cd74d2-d30c-4e35-9670-868d1558165e
# ╟─05d63c5c-a517-4651-897b-9c1321c9d698
# ╠═09153cfa-40b5-4bb7-8607-30116e67f65b
# ╟─6143279b-3467-4d16-830e-8797394f1be3
# ╠═618f732c-6dff-445b-a8d6-9062f1f74ade
# ╟─76aba57e-0212-4c5d-881b-2c7f20346af1
# ╠═503bb6dd-1857-494c-a9d5-573e1821d280
# ╟─edbc60ff-1742-42f7-8ac2-5f0469e8929e
# ╠═f87b6c16-d1db-4c2d-81e0-6a13296f146e
# ╟─3d6e9366-7dd2-43d6-a07c-8d506dd3880c
# ╠═8828a3fe-9716-4d8b-ab3a-572c487b74a1
# ╟─69f6e662-8e9f-432a-b698-a6141100b931
# ╠═e8e047c4-186c-44bb-966a-b8b1b7c4b57f
# ╟─1de7ccfa-7ef9-4519-bdfe-5da16473e977
# ╠═c84b0b25-054e-48be-b5c8-33c17c34747f
# ╠═d08ab867-3784-4afb-b0ab-3c68a8bed5c6
# ╟─1e955883-50a5-4558-bbf9-d920615ff9a2
# ╟─7eacb6d9-4c19-4c6c-b047-783e0962c9be
# ╠═2d8b2671-2ce3-43be-b26c-7f7f30ac4c70
# ╟─111f2a14-561f-4875-8203-3fda5526277f
# ╠═fb1654f1-00cd-4a0f-b96a-4c8efebbd8dd
# ╟─50774dbe-6568-4bdb-a744-181da4b8a809
# ╠═4277b47f-c106-4bb1-aa6f-713023abce38
# ╟─d0afaa99-fabc-42ce-b0b9-4a2101ff3cbb
# ╠═a1572851-4901-47c7-bda5-4901e6e493d5
# ╟─7fe31d85-d100-45ef-ae0e-e3625a1dcd32
# ╠═12b8d126-fe7b-48ff-8676-582a3060741b
# ╟─e5f96c44-c248-4bd4-a2b2-603f020894d4
# ╠═bd8f9b95-bd67-4483-b9eb-a80c5070db57
# ╟─2807fa4c-3b89-4d5d-bb78-4ffabf77effb
# ╠═fc4cca60-ce23-4a10-8127-09bb5511deb8
# ╟─56daae05-8c61-4cbe-b5ee-f0182e7e28d5
# ╠═e89bfaed-22da-4f99-aec2-989595e2eff3
# ╟─7386b26b-4e5a-46fd-aa1a-1488c35878bb
# ╠═75853f99-0962-4683-ad10-a3803d4aa6ad
# ╟─952577ea-391f-406d-b026-814f48ea96cb
# ╠═f3ef69e2-1ce4-4bef-a2de-043dffb7c2bb
# ╟─396c5aa8-ba71-4302-8c24-ec76e74d5184
# ╠═59be4352-7271-4a9b-adef-36d23d8eeb64
# ╟─b403afab-3ddf-42c5-98da-ac9991091f08
# ╠═f7a1bd72-2595-42e0-be8a-5f5763517131
# ╠═4d067bb7-786a-4946-9380-a27d39f9d784
# ╟─91e1cbcf-7ada-44d3-89e2-a2a9a164ec13
# ╠═7cf93ffd-8b5e-43c6-ac5e-13d1a9183970
# ╟─7119bdf0-070e-40d7-94e9-ab35cf17dcf5
# ╠═b8476885-214a-4708-b933-4aac278f3b5b
# ╠═35d20127-b307-4de5-850c-46d06cbf3a1f
# ╟─768a2a20-4b63-4c5c-ae12-4b18152b412d
# ╠═271648d8-10e8-4512-9cb3-d4907d0e0750
# ╟─0114debc-032d-4d99-8d59-8c79dd20528b
# ╠═dd75a72c-4218-4778-b0aa-e279794bc3fd
# ╟─e1b274eb-7689-43df-aa3f-8077689267af
# ╠═33823010-0e63-4f9b-ba29-802e9363c604
# ╟─cd525aa7-386f-4bc3-9814-265411e8a741
# ╟─ef17fd7b-6436-4e0e-a0a7-3a0d5a019fc5
# ╠═fab9da9c-b661-4081-bc72-b5acdb3c019d
# ╠═95a978e2-cbcf-4a0c-90f1-98ba7405f2be
# ╟─8e8f6cee-f6da-4cd9-bf9d-167b7ac89808
# ╠═f0cf3415-571f-4661-8823-2598aef00c2d
# ╟─57f2184d-676e-4da9-99aa-34b0ec7798f9
# ╠═34589d78-9009-412c-8d10-1738729b14b9
# ╟─97abbd67-36fa-4451-9e4f-ab96cf82c82b
# ╠═69b5b90b-9c93-4de2-a106-e0f9e6bd10a4
# ╟─9d1447b8-2d25-4567-b9f0-4b3ead7cd873
# ╠═ae5595c3-0238-4f00-b4ce-d88f366d4e2e
# ╟─3afc20d0-4f2f-40f5-bd8d-00fb1c838b07
# ╠═c1b8fcc1-cbbd-43ae-8669-de7b524186b0
# ╟─abfc5a3d-5024-44a7-af3b-70eefa26dc37
# ╠═9b2e6cb8-67c7-4d15-afde-03a4ae7595da
# ╟─b941833a-0efa-45e8-a59f-a7007653cfc6
# ╟─29d1ada2-75ce-4a77-a136-f761052c0637
# ╟─e6961baa-90c2-4b5d-9bfa-f71355330509
# ╠═08dc0954-02b2-49d2-b3a9-b99d8c41a125
# ╟─b8806c05-7158-4774-a5f7-80f579f44388
# ╠═69f1f5fc-b538-45b3-8e41-3d4822d638ec
# ╠═e72113f2-1608-4e16-adc1-eb359096dbdc
# ╠═07d590d0-3775-468b-a9a3-99d26393d91a
# ╟─f0206a54-b71b-42b6-84da-2b87f348eced
# ╟─41bdb293-d905-4fda-ac48-fa5926222bc7
# ╠═69feaef9-d4b1-4d12-86f6-0aadf030f8eb
# ╟─3654e4d9-8e0a-4154-805a-330fc29ae64c
# ╠═7e1db1d9-0a8b-4056-8a21-9a6c04ad3d9d
# ╟─727ff4b9-6f52-481d-8155-792bc35803db
# ╠═f16db75f-9d13-4650-a025-705ca32a9404
# ╟─e753394e-ad69-47b8-8639-d60a22275c72
# ╠═5c6f4050-b7a8-4f56-aad1-f418b51e2cad
