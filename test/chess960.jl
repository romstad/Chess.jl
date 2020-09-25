for i ∈ 0:959
    @test chess960fen(i) == fen(fromfen(chess960fen(i)))
end
