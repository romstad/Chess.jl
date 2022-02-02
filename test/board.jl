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
    @test rookattacks(b, SQ_C4) == SquareSet(
        SQ_A4,
        SQ_B4,
        SQ_D4,
        SQ_E4,
        SQ_F4,
        SQ_G4,
        SQ_C1,
        SQ_C2,
        SQ_C3,
        SQ_C5,
        SQ_C6,
        SQ_C7,
        SQ_C8,
    )
    local b = fromfen("2r2k2/8/8/8/2Q3P1/8/4P3/3K4 w - -")
    @test queenattacks(b, SQ_C4) == SquareSet(
        SQ_C1,
        SQ_C2,
        SQ_C3,
        SQ_C5,
        SQ_C6,
        SQ_C7,
        SQ_C8,
        SQ_A4,
        SQ_B4,
        SQ_D4,
        SQ_E4,
        SQ_F4,
        SQ_G4,
        SQ_A2,
        SQ_B3,
        SQ_D5,
        SQ_E6,
        SQ_F7,
        SQ_G8,
        SQ_E2,
        SQ_D3,
        SQ_B5,
        SQ_A6,
    )
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
    local b = fromfen("2r4b/1kp5/8/2P1Q3/1P6/2K1P2r/8/8 w - -")
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

    b = fromfen("bqnb1rkr/pp3ppp/3ppn2/2p5/5P2/P2P4/NPP1P1PP/BQ1BNRKR w HFhf -")
    @test perft(b, 0) == 1
    @test perft(b, 1) == 21
    @test perft(b, 2) == 528
    @test perft(b, 3) == 12189
    @test perft(b, 4) == 326672
    @test perft(b, 5) == 8146062

    b = fromfen("b1qr1krb/pp1ppppp/n2n4/8/2p5/2P3P1/PP1PPP1P/BNQRNKRB w GDgd -")
    @test perft(b, 0) == 1
    @test perft(b, 1) == 28
    @test perft(b, 2) == 707
    @test perft(b, 3) == 19721
    @test perft(b, 4) == 549506
    @test perft(b, 5) == 15583376

    b = fromfen("nrnbqkbr/2pp2pp/4pp2/pp6/8/1P3P2/P1PPPBPP/NRNBQ1KR w hb -")
    @test perft(b, 0) == 1
    @test perft(b, 1) == 25
    @test perft(b, 2) == 656
    @test perft(b, 3) == 16951
    @test perft(b, 4) == 466493
    @test perft(b, 5) == 12525939

    b = fromfen("qnbbrknr/1p1ppppp/8/p1p5/5P2/PP1P4/2P1P1PP/QNBBRKNR w HEhe -")
    @test perft(b, 0) == 1
    @test perft(b, 1) == 27
    @test perft(b, 2) == 573
    @test perft(b, 3) == 16331
    @test perft(b, 4) == 391656
    @test perft(b, 5) == 11562434

    b = fromfen("nrq1kbnr/p1pbpppp/3p4/1p6/6P1/1N3N2/PPPPPP1P/1RBQKB1R w HBhb -")
    @test perft(b, 0) == 1
    @test perft(b, 1) == 24
    @test perft(b, 2) == 648
    @test perft(b, 3) == 16640
    @test perft(b, 4) == 471192
    @test perft(b, 5) == 12871967

    b = fromfen("1qrkrnbb/1p1p1ppp/pnp1p3/8/3PP3/P6P/1PP2PP1/NQRKRNBB w ECec -")
    @test perft(b, 0) == 1
    @test perft(b, 1) == 24
    @test perft(b, 2) == 688
    @test perft(b, 3) == 17342
    @test perft(b, 4) == 511444
    @test perft(b, 5) == 13322502

    b = fromfen("1brnqknr/2p1pppp/p2p4/1P6/6P1/4Nb2/PP1PPP1P/BBR1QKNR w HChc -")
    @test perft(b, 0) == 1
    @test perft(b, 1) == 34
    @test perft(b, 2) == 1019
    @test perft(b, 3) == 32982
    @test perft(b, 4) == 1003103
    @test perft(b, 5) == 33322477

    b = fromfen("brn1kbrn/pp2p1pp/3p4/q1p2p2/2P4P/6P1/PP1PPP2/BRNQKBRN w GBgb -")
    @test perft(b, 0) == 1
    @test perft(b, 1) == 18
    @test perft(b, 2) == 477
    @test perft(b, 3) == 10205
    @test perft(b, 4) == 273925
    @test perft(b, 5) == 6720181

    b = fromfen("b1rknnrq/bpppp1p1/p6p/5p1P/6P1/4N3/PPPPPP2/BBRKN1RQ w GCgc -")
    @test perft(b, 0) == 1
    @test perft(b, 1) == 33
    @test perft(b, 2) == 851
    @test perft(b, 3) == 28888
    @test perft(b, 4) == 763967
    @test perft(b, 5) == 26686205

    b = fromfen("brkqnrnb/1p1pp1p1/p4p2/2p4p/8/P2PP3/1PP1QPPP/BRK1NRNB w FBfb -")
    @test perft(b, 0) == 1
    @test perft(b, 1) == 24
    @test perft(b, 2) == 479
    @test perft(b, 3) == 12584
    @test perft(b, 4) == 280081
    @test perft(b, 5) == 7830230

    b = fromfen("brkrqb1n/1pppp1pp/p7/3n1p2/P5P1/3PP3/1PP2P1P/BRKRQBNN w DBdb -")
    @test perft(b, 0) == 1
    @test perft(b, 1) == 27
    @test perft(b, 2) == 669
    @test perft(b, 3) == 18682
    @test perft(b, 4) == 484259
    @test perft(b, 5) == 13956472
end

begin
    fens = [
        "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -",
        "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w Kq -",
        "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w Qk -",
        "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w - -",
        "rnbqkbnr/pppp1ppp/4p3/4P3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6",
    ]
    for f in fens
        @test fen(fromfen(f)) == f
    end

    for i = 0:959
        f = chess960fen(i)
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


begin
    b = fromfen("8/4k3/3p4/4p3/8/2BK4/8/8 w - - 0 1")
    @test see(b, Move(SQ_C3, SQ_E5)) == -2
    b = fromfen("8/4k3/3p4/4p3/8/2BK4/8/Q7 w - - 0 1")
    @test see(b, Move(SQ_C3, SQ_E5)) == -1
    b = fromfen("8/4k3/8/4p3/8/2BK4/8/q7 w - - 0 1")
    @test see(b, Move(SQ_C3, SQ_E5)) == -2
    b = fromfen("8/4k3/8/4p3/8/2BK4/8/8 w - - 0 1")
    @test see(b, Move(SQ_C3, SQ_E5)) == 1
    b = fromfen("7q/4k1b1/3p4/4n3/8/2BK1N2/4R3/4R3 w - - 0 1")
    @test see(b, Move(SQ_F3, SQ_E5)) == 1
    b = fromfen("7q/4k1b1/3p4/4n3/8/2BK1N2/4R3/4R3 w - - 0 1")
    @test see(b, Move(SQ_E2, SQ_E5)) == -1
    b = fromfen("7q/4k1b1/3p4/4n3/8/2BK1N2/4R3/8 w - - 0 1")
    @test see(b, Move(SQ_E2, SQ_E5)) == -2
    b = fromfen("7q/4k1b1/3p4/4n3/8/2BK1N2/4R3/8 w - - 0 1")
    @test see(b, Move(SQ_C3, SQ_E5)) == 0
    b = fromfen("8/2b5/3k4/4p3/3K1P2/8/8/8 w - -")
    @test see(b, Move(SQ_F4, SQ_E5)) == 1
    b = fromfen("8/8/3k1p2/4p3/3K1P2/2B5/8/8 w - -")
    @test see(b, Move(SQ_F4, SQ_E5)) == 0
end

begin
    b = fromfen("r1bqk2r/p4pb1/2pp1np1/6P1/2PPp3/2N5/PP3PB1/R1BQK2R b KQkq -")
    domove!(b, "Rxh1+")
    @test fen(b) == "r1bqk3/p4pb1/2pp1np1/6P1/2PPp3/2N5/PP3PB1/R1BQK2r w Qq -"
end

begin
    b = startboard()
    @test fen(decompress(compress(b))) == fen(b)
    b = fromfen("4k3/8/8/pP6/8/8/8/4K3 w - a6")
    @test fen(decompress(compress(b))) == fen(b)
    b = fromfen("r3k2r/8/8/8/Pp6/8/8/4K3 b kq a3")
    @test fen(decompress(compress(b))) == fen(b)
end

begin
    movelist = MoveList(200)
    b = startboard()
    new_board = domoves(b, "d4", "Nf6", "c4", "e6", "Nc3", "Bb4")
    new_board_pre = domoves(b, "d4", "Nf6", "c4", "e6", "Nc3", "Bb4", movelist=movelist)
    @test fen(new_board) == fen(new_board_pre)
end

# test for issue #26
begin
    b = fromfen("6Q1/8/5Q2/2p1B3/1bPpP3/1P3P2/PkPN2B1/R3K3 b Q - 0 48")
    @test !cancastlekingside(b, WHITE)
    @test cancastlequeenside(b, WHITE)

    domove!(b, "Kxa1")
    @test !cancastlekingside(b, WHITE)
    @test !cancastlequeenside(b, WHITE)
end
