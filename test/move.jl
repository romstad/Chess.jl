for f in ALL_SQUARES
    for t in ALL_SQUARES
        if t == f
            continue
        end
        m = Move(f, t)
        @test from(m) == f
        @test to(m) == t
        @test !ispromotion(m)
        @test m == movefromstring(tostring(m))
        for prom in [QUEEN, ROOK, BISHOP, KNIGHT]
            m = Move(f, t, prom)
            @test from(m) == f
            @test to(m) == t
            @test ispromotion(m)
            @test promotion(m) == prom
            @test m == movefromstring(tostring(m))
        end
    end
end
