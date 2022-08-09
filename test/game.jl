begin
    for T in [String, SubString]
        pgn = T("1. d4 e5 2. c4 f5 3. Nc3 (3. Nf3 Nf6 4. g3) 3... Na6 4. e4")
        g = Chess.PGN.gamefromstring(pgn; annotations=true)
        s = Chess.PGN.gamefromstring(pgn)
        s_g = SimpleGame(g)

        toend!(g)
        toend!(s)
        toend!(s_g)

        @assert fen(board(g)) == fen(board(s))
        @assert fen(board(s)) == fen(board(s_g))
    end
end

begin
    for T in [String, SubString]
        pgn = T("1. e4 c6 2. Nf3 d5 3. exd5 cxd5 4. d4 Nc6 5. Nc3 e6 6. Be2 Bd6 7. O-O Nf6")
        g = Chess.PGN.gamefromstring(pgn; annotations=true)
        s = Chess.PGN.gamefromstring(pgn)
        s_g = SimpleGame(g)
        g_s = Game(s)

        toend!(g)
        toend!(s)
        toend!(s_g)
        toend!(g_s)

        @assert fen(board(g)) == fen(board(s))
        @assert fen(board(s)) == fen(board(s_g)) 
        @assert fen(board(s_g)) == fen(board(g_s))
    end
end