begin
    local b = startboard()
    local list = MoveList(100)
    local list2 = MoveList(100)
    local positions_tested = 0

    while positions_tested < 100000
        positions_tested += 1
        recycle!(list)
        moves(b, list)
        if list.count == 0 || squarecount(occupiedsquares(b)) < 10
            b = startboard()
            continue
        else
            if !ischeck(b)
                recycle!(list2)
                pseudocaptures(b, list2)
                for m ∈ list
                    if moveiscapture(b, m) || ispromotion(m)
                        @test m ∈ list2
                    else
                        @test m ∉ list2
                    end
                end
            end
            domove!(b, rand(list))
        end
    end
end


begin
    local b = startboard()
    local list = MoveList(100)
    local list2 = MoveList(100)
    local positions_tested = 0

    while positions_tested < 100000
        positions_tested += 1
        recycle!(list)
        moves(b, list)
        if list.count == 0 || squarecount(occupiedsquares(b)) < 10
            b = startboard()
            continue
        else
            if !ischeck(b)
                recycle!(list2)
                pseudoquiets(b, list2)
                for m ∈ list
                    if moveiscapture(b, m) || ispromotion(m)
                        @test m ∉ list2
                    else
                        @test m ∈ list2
                    end
                end
            end
            domove!(b, rand(list))
        end
    end
end


begin
    local b = startboard()
    local list = MoveList(100)
    local list2 = MoveList(100)
    local positions_tested = 0

    while positions_tested < 100000
        positions_tested += 1
        recycle!(list)
        moves(b, list)
        if list.count == 0 || squarecount(occupiedsquares(b)) < 10
            b = startboard()
            continue
        else
            if !ischeck(b)
                recycle!(list2)
                pseudochecks(b, list2)
                for m ∈ list
                    if moveiscapture(b, m) || ispromotion(m) || moveiscastle(b, m)
                        @test m ∉ list2
                    elseif moveischeck(b, m)
                        @test m ∈ list2
                    else
                        @test m ∉ list2
                    end
                end
            end
            domove!(b, rand(list))
        end
    end
end


begin
    local b = startboard()
    local list = MoveList(100)
    local list2 = MoveList(100)
    local positions_tested = 0

    while positions_tested < 100000
        positions_tested += 1
        recycle!(list)
        moves(b, list)
        if list.count == 0 || squarecount(occupiedsquares(b)) < 10
            b = startboard()
            continue
        else
            if !ischeck(b)
                recycle!(list2)
                pseudomoves(b, list2)
                for m ∈ list2
                    @test moveispseudo(b, m)
                    @test pseudoislegal(b, m) || m ∉ list
                end
            end
            domove!(b, rand(list))
        end
    end
end
