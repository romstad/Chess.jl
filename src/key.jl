using Random

const ZOB_KEYS = begin
    local rng = MersenneTwister(1685)
    [rand(rng, UInt64) for i ∈ 1:64, j ∈ 1:14]
end

function zobrist(p::Piece, s::Square)::UInt64
    @inbounds ZOB_KEYS[s.val, p.val]
end

function zobep(s::Square)::UInt64
    @inbounds ZOB_KEYS[s.val, 7]
end

function zobcastle(castlerights::UInt8)
    @inbounds ZOB_KEYS[castlerights+1, 8]
end

function zobsidetomove()
    @inbounds ZOB_KEYS[64, 8]
end
