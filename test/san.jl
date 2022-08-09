begin
    for T in [String, SubString]
        local movelist = MoveList(200)
        local b = fromfen(T("2r2k2/1P6/8/8/p7/2N3N1/8/R3K2R w KQ -"))
        @test movefromsan(b, T("b8=Q"), movelist) == Move(SQ_B7, SQ_B8, QUEEN)
        @test movefromsan(b, T("b8=Q")) == Move(SQ_B7, SQ_B8, QUEEN)
        @test movetosan(b, Move(SQ_B7, SQ_B8, QUEEN)) == "b8=Q"
        @test movefromsan(b, T("bxc8=R+"), movelist) == Move(SQ_B7, SQ_C8, ROOK)
        @test movefromsan(b, T("bxc8=R+")) == Move(SQ_B7, SQ_C8, ROOK)
        @test movetosan(b, Move(SQ_B7, SQ_C8, ROOK)) == "bxc8=R+"
        @test movefromsan(b, T("Nxa4"), movelist) == Move(SQ_C3, SQ_A4)
        @test movefromsan(b, T("Nxa4")) == Move(SQ_C3, SQ_A4)
        @test movetosan(b, Move(SQ_C3, SQ_A4)) == "Nxa4"
        @test movefromsan(b, T("Nge4"), movelist) == Move(SQ_G3, SQ_E4)
        @test movefromsan(b, T("Nge4")) == Move(SQ_G3, SQ_E4)
        @test movetosan(b, Move(SQ_G3, SQ_E4)) == "Nge4"
        @test movefromsan(b, T("Nce4"), movelist) == Move(SQ_C3, SQ_E4)
        @test movefromsan(b, T("Nce4")) == Move(SQ_C3, SQ_E4)
        @test movetosan(b, Move(SQ_C3, SQ_E4)) == "Nce4"
        @test isnothing(movefromsan(b, T("Ne4")))
        @test movefromsan(b, T("O-O-O"), movelist) == Move(SQ_E1, SQ_C1)
        @test movefromsan(b, T("O-O-O")) == Move(SQ_E1, SQ_C1)
        @test movetosan(b, Move(SQ_E1, SQ_C1)) == "O-O-O"
        @test movefromsan(b, T("O-O+"), movelist) == Move(SQ_E1, SQ_G1)
        @test movefromsan(b, T("O-O+")) == Move(SQ_E1, SQ_G1)
        @test movetosan(b, Move(SQ_E1, SQ_G1)) == "O-O+"

        b = fromfen(T("2r2k2/1P6/8/8/pb6/2N3N1/8/R3K2R w KQ -"))
        @test movefromsan(b, T("Ne4"), movelist) == Move(SQ_G3, SQ_E4)
        @test movefromsan(b, T("Ne4")) == Move(SQ_G3, SQ_E4)
        @test movetosan(b, Move(SQ_G3, SQ_E4)) == "Ne4"

        b = fromfen(T("4k3/R7/8/8/8/8/8/R3K3 w -"))
        @test isnothing(movefromsan(b, T("Ra6"), movelist))
        @test isnothing(movefromsan(b, T("Ra6")))
        @test movefromsan(b, T("R1a6"), movelist) == Move(SQ_A1, SQ_A6)
        @test movefromsan(b, T("R1a6")) == Move(SQ_A1, SQ_A6)
        @test movetosan(b, Move(SQ_A1, SQ_A6)) == "R1a6"
        @test movefromsan(b, T("R7a6"), movelist) == Move(SQ_A7, SQ_A6)
        @test movefromsan(b, T("R7a6")) == Move(SQ_A7, SQ_A6)
        @test movetosan(b, Move(SQ_A7, SQ_A6)) == "R7a6"

        b = fromfen(T("4k3/8/8/3q1q2/3q1q2/8/8/4K3 b -"))
        @test isnothing(movefromsan(b, T("Qde4#"), movelist))
        @test isnothing(movefromsan(b, T("Qfe4#"), movelist))
        @test isnothing(movefromsan(b, T("Q4e4#"), movelist))
        @test isnothing(movefromsan(b, T("Q5e4#"), movelist))
        @test isnothing(movefromsan(b, T("Qde4#")))
        @test isnothing(movefromsan(b, T("Qfe4#")))
        @test isnothing(movefromsan(b, T("Q4e4#")))
        @test isnothing(movefromsan(b, T("Q5e4#")))
        @test movefromsan(b, T("Qd4e4#"), movelist) == Move(SQ_D4, SQ_E4)
        @test movefromsan(b, T("Qd4e4#")) == Move(SQ_D4, SQ_E4)
        @test movetosan(b, Move(SQ_D4, SQ_E4)) == "Qd4e4#"
        @test movefromsan(b, T("Qd5e4#"), movelist) == Move(SQ_D5, SQ_E4)
        @test movefromsan(b, T("Qd5e4#")) == Move(SQ_D5, SQ_E4)
        @test movetosan(b, Move(SQ_D5, SQ_E4)) == "Qd5e4#"
        @test movefromsan(b, T("Qf4e4#"), movelist) == Move(SQ_F4, SQ_E4)
        @test movefromsan(b, T("Qf4e4#")) == Move(SQ_F4, SQ_E4)
        @test movetosan(b, Move(SQ_F4, SQ_E4)) == "Qf4e4#"
        @test movefromsan(b, T("Qf5e4#"), movelist) == Move(SQ_F5, SQ_E4)
        @test movefromsan(b, T("Qf5e4#")) == Move(SQ_F5, SQ_E4)
        @test movetosan(b, Move(SQ_F5, SQ_E4)) == "Qf5e4#"
    end
end
