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

begin
    local b = startboard()
    @test pieceon(b, SQ_E1) == PIECE_WK
    @test pieceon(b, FILE_B, RANK_8) == PIECE_BN
    @test pieceon(b, SQ_B5) == EMPTY
end

begin
    local b = startboard()
    local b2 = domove(b, movefromstring("e2e4"))
    @test sidetomove(b) == WHITE
    @test sidetomove(b2) == BLACK
end

begin
    local b = startboard()
    @test epsquare(b) == SQ_NONE
    local b2 = fromfen("rnbqkbnr/pppp1ppp/4p3/4P3/8/8/PPPP1PPP/RNBQKBNR b - -")
    @test epsquare(b2) == SQ_NONE
    local b3 = domove(b2, movefromstring("d7d5"))
    @test epsquare(b3) == SQ_D6
end

begin
    local b = startboard()
    @test pieces(b, WHITE) == SS_RANK_1 ∪ SS_RANK_2
    @test pieces(b, ROOK) == SquareSet(SQ_A1, SQ_H1, SQ_A8, SQ_H8)
    @test pieces(b, BLACK, PAWN) == SS_RANK_7
    @test pieces(b, PIECE_WB) == SquareSet(SQ_C1, SQ_F1)
    @test pawns(b) == SS_RANK_2 ∪ SS_RANK_7
    @test pawns(b, WHITE) == SS_RANK_2
    @test pawns(b, BLACK) == SS_RANK_7
    @test knights(b) == SquareSet(SQ_B1, SQ_G1, SQ_B8, SQ_G8)
    @test knights(b, WHITE) == SquareSet(SQ_B1, SQ_G1)
    @test knights(b, BLACK) == SquareSet(SQ_B8, SQ_G8)
    @test bishops(b) == SquareSet(SQ_C1, SQ_F1, SQ_C8, SQ_F8)
    @test bishops(b, WHITE) == SquareSet(SQ_C1, SQ_F1)
    @test bishops(b, BLACK) == SquareSet(SQ_C8, SQ_F8)
    @test rooks(b) == SquareSet(SQ_A1, SQ_H1, SQ_A8, SQ_H8)
    @test rooks(b, WHITE) == SquareSet(SQ_A1, SQ_H1)
    @test rooks(b, BLACK) == SquareSet(SQ_A8, SQ_H8)
    @test queens(b) == SquareSet(SQ_D1, SQ_D8)
    @test queens(b, WHITE) == SquareSet(SQ_D1)
    @test queens(b, BLACK) == SquareSet(SQ_D8)
    @test kings(b) == SquareSet(SQ_E1, SQ_E8)
    @test kings(b, WHITE) == SquareSet(SQ_E1)
    @test kings(b, BLACK) == SquareSet(SQ_E8)
    @test bishoplike(b) == SquareSet(SQ_C1, SQ_D1, SQ_F1, SQ_C8, SQ_D8, SQ_F8)
    @test bishoplike(b, WHITE) == SquareSet(SQ_C1, SQ_D1, SQ_F1)
    @test bishoplike(b, BLACK) == SquareSet(SQ_C8, SQ_D8, SQ_F8)
    @test rooklike(b) == SquareSet(SQ_A1, SQ_D1, SQ_H1, SQ_A8, SQ_D8, SQ_H8)
    @test rooklike(b, WHITE) == SquareSet(SQ_A1, SQ_D1, SQ_H1)
    @test rooklike(b, BLACK) == SquareSet(SQ_A8, SQ_D8, SQ_H8)
end

begin
    local b = fromfen("5k2/8/4q3/8/2B5/8/4P3/3K4 w - -")
    @test bishopattacks(b, SQ_C4) ==
        SquareSet(SQ_A2, SQ_B3, SQ_E2, SQ_D3, SQ_B5, SQ_A6, SQ_D5, SQ_E6)
    local b = fromfen("2r2k2/8/8/8/2R3P1/8/4P3/3K4 w - -")
    @test rookattacks(b, SQ_C4) ==
        SquareSet(SQ_A4, SQ_B4, SQ_D4, SQ_E4, SQ_F4, SQ_G4,
                  SQ_C1, SQ_C2, SQ_C3, SQ_C5, SQ_C6, SQ_C7, SQ_C8)
    local b = fromfen("2r2k2/8/8/8/2Q3P1/8/4P3/3K4 w - -")
    @test queenattacks(b, SQ_C4) ==
        SquareSet(SQ_C1, SQ_C2, SQ_C3, SQ_C5, SQ_C6, SQ_C7, SQ_C8,
                  SQ_A4, SQ_B4, SQ_D4, SQ_E4, SQ_F4, SQ_G4,
                  SQ_A2, SQ_B3, SQ_D5, SQ_E6, SQ_F7, SQ_G8,
                  SQ_E2, SQ_D3, SQ_B5, SQ_A6)
end

begin
    local b = startboard()
    @test isattacked(b, SQ_F3, WHITE)
    @test !isattacked(b, SQ_F3, BLACK)
end

begin
    local b = fromfen("r1bqkbnr/pppp1ppp/2n5/4p3/3PP3/5N2/PPP2PPP/RNBQKB1R b KQkq - 0 3")
    @test attacksto(b, SQ_D4) == SquareSet(SQ_D1, SQ_F3, SQ_E5, SQ_C6)
end

begin
    local b = fromfen("2r4b/1kp5/8/2P1Q3/1P6/2K1P2r/8/8 w - -");
    @test pinned(b) == SquareSet(SQ_E3, SQ_E5)
end

begin
    local b = startboard()
    @test perft(b, 0) == 1
    @test perft(b, 1) == 20
    @test perft(b, 2) == 400
    @test perft(b, 3) == 8902
    @test perft(b, 4) == 197281
    @test perft(b, 5) == 4865609
    # @test perft(b, 6) == 119060324
    # @test perft(b, 7) == 3195901860

    b = fromfen("r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -")
    @test perft(b, 0) == 1
    @test perft(b, 1) == 48
    @test perft(b, 2) == 2039
    @test perft(b, 3) == 97862
    @test perft(b, 4) == 4085603
    # @test perft(b, 5) == 193690690
    # @test perft(b, 6) == 8031647685

    b = fromfen("8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - -")
    @test perft(b, 0) == 1
    @test perft(b, 1) == 14
    @test perft(b, 2) == 191
    @test perft(b, 3) == 2812
    @test perft(b, 4) == 43238
    @test perft(b, 5) == 674624
    # @test perft(b, 6) == 11030083
    # @test perft(b, 7) == 178633661
end

begin
    fens = ["rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -",
            "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w Kq -",
            "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w Qk -",
            "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w - -",
            "rnbqkbnr/pppp1ppp/4p3/4P3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6"]
    for f in fens
        @test fen(fromfen(f)) == f
    end
end


function computekey(b::Board)::UInt64
    result = UInt64(0)
    for s in occupiedsquares(b)
        p = pieceon(b, s)
        result ⊻= Chess.zobrist(p, s)
    end
    result ⊻= Chess.zobcastle(b.castlerights)
    if epsquare(b) != SQ_NONE
        result ⊻= Chess.zobep(epsquare(b))
    end
    if sidetomove(b) == BLACK
        result ⊻= Chess.zobsidetomove()
    end
    result
end



function keyisright(b::Board)::Bool
    b.key == computekey(b)
end


begin
    b = fromfen("r3k2r/1P6/8/3Pp3/5p2/8/4P3/R3K2R w KQkq e6")
    @test keyisright(b)

    ms = ["bxa8=R+", "b8=N", "dxe6", "e4", "O-O", "Rxh8+"]
    for m in ms
        @test keyisright(domove(b, m))
    end

    for m in ms
        u = domove!(b, m)
        @test keyisright(b)
        undomove!(b, u)
        @test keyisright(b)
    end
end


begin
    @test isstalemate(fromfen("b5bk/3r4/2PNP3/1rNKNr2/2PNP3/3r4/b5b1/8 w - -"))
    @test !isstalemate(fromfen("b5bk/3r4/2PNP3/1rNKNr2/2PNP3/3r4/b7/8 w - -"))
    @test ischeckmate(fromfen("b5bk/3r4/2P1P3/1rNKNr2/2PNP3/3r4/b5b1/8 w - -"))
    @test !ischeckmate(fromfen("6bk/3r4/2P1P3/1rNKNr2/2PNP3/3r4/b5b1/8 w - -"))
    @test ismaterialdraw(fromfen("8/8/3k4/8/3K4/8/8/8 w - -"))
    @test ismaterialdraw(fromfen("8/8/3k4/8/3K4/8/8/7N w - -"))
    @test ismaterialdraw(fromfen("8/8/3k4/8/3K4/8/8/7b w - -"))
    @test !ismaterialdraw(fromfen("8/8/3k4/8/3K4/8/8/7R w - -"))
    @test !ismaterialdraw(fromfen("8/8/3k4/8/3K4/8/8/7q w - -"))
    @test !ismaterialdraw(fromfen("8/8/3k4/8/3K4/8/7b/7N w - -"))
    @test !ismaterialdraw(fromfen("8/8/3k4/8/3K4/8/8/BB6 w - -"))
    @test !ismaterialdraw(fromfen("8/8/3k4/8/3K4/8/3P4/8 w - -"))
end
