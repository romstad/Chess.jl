begin
    local b = fromfen("2r2k2/1P6/8/8/p7/2N3N1/8/R3K2R w KQ -")
    @test movefromsan(b, "b8=Q") == Move(SQ_B7, SQ_B8, QUEEN)
    @test movetosan(b, Move(SQ_B7, SQ_B8, QUEEN)) == "b8=Q"
    @test movefromsan(b, "bxc8=R+") == Move(SQ_B7, SQ_C8, ROOK)
    @test movetosan(b, Move(SQ_B7, SQ_C8, ROOK)) == "bxc8=R+"
    @test movefromsan(b, "Nxa4") == Move(SQ_C3, SQ_A4)
    @test movetosan(b, Move(SQ_C3, SQ_A4)) == "Nxa4"
    @test movefromsan(b, "Nge4") == Move(SQ_G3, SQ_E4)
    @test movetosan(b, Move(SQ_G3, SQ_E4)) == "Nge4"
    @test movefromsan(b, "Nce4") == Move(SQ_C3, SQ_E4)
    @test movetosan(b, Move(SQ_C3, SQ_E4)) == "Nce4"
    @test movefromsan(b, "Ne4") == nothing
    @test movefromsan(b, "O-O-O") == Move(SQ_E1, SQ_C1)
    @test movetosan(b, Move(SQ_E1, SQ_C1)) == "O-O-O"
    @test movefromsan(b, "O-O+") == Move(SQ_E1, SQ_G1)
    @test movetosan(b, Move(SQ_E1, SQ_G1)) == "O-O+"

    b = fromfen("2r2k2/1P6/8/8/pb6/2N3N1/8/R3K2R w KQ -")
    @test movefromsan(b, "Ne4") == Move(SQ_G3, SQ_E4)
    @test movetosan(b, Move(SQ_G3, SQ_E4)) == "Ne4"

    b = fromfen("4k3/R7/8/8/8/8/8/R3K3 w -")
    @test movefromsan(b, "Ra6") == nothing
    @test movefromsan(b, "R1a6") == Move(SQ_A1, SQ_A6)
    @test movetosan(b, Move(SQ_A1, SQ_A6)) == "R1a6"
    @test movefromsan(b, "R7a6") == Move(SQ_A7, SQ_A6)
    @test movetosan(b, Move(SQ_A7, SQ_A6)) == "R7a6"

    b = fromfen("4k3/8/8/3q1q2/3q1q2/8/8/4K3 b -")
    @test movefromsan(b, "Qde4#") == nothing
    @test movefromsan(b, "Qfe4#") == nothing
    @test movefromsan(b, "Q4e4#") == nothing
    @test movefromsan(b, "Q5e4#") == nothing
    @test movefromsan(b, "Qd4e4#") == Move(SQ_D4, SQ_E4)
    @test movetosan(b, Move(SQ_D4, SQ_E4)) == "Qd4e4#"
    @test movefromsan(b, "Qd5e4#") == Move(SQ_D5, SQ_E4)
    @test movetosan(b, Move(SQ_D5, SQ_E4)) == "Qd5e4#"
    @test movefromsan(b, "Qf4e4#") == Move(SQ_F4, SQ_E4)
    @test movetosan(b, Move(SQ_F4, SQ_E4)) == "Qf4e4#"
    @test movefromsan(b, "Qf5e4#") == Move(SQ_F5, SQ_E4)
    @test movetosan(b, Move(SQ_F5, SQ_E4)) == "Qf5e4#"
end
