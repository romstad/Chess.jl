export chess960fen


function insertatempty!(array, item, index)
    for i ∈ 1:length(array)
        if array[i] ≠ '?' && i ≤ index
            index += 1
        end
    end
    array[index] = item
end


KNIGHT_TABLE_960 = [
    [1, 1],
    [1, 2],
    [1, 3],
    [1, 4],
    [2, 2],
    [2, 3],
    [2, 4],
    [3, 3],
    [3, 4],
    [4, 4]
]


function backrank(n::Int)
    result = fill('?', 8)
    (n2, b1) = fldmod(n, 4)
    result[2b1 + 2] = 'b'
    (n3, b2) = fldmod(n2, 4)
    result[2b2 + 1] = 'b'
    (n4, q) = fldmod(n3, 6)
    insertatempty!(result, 'q', q + 1)
    knights = KNIGHT_TABLE_960[n4 + 1]
    insertatempty!(result, 'n', knights[1])
    insertatempty!(result, 'n', knights[2])
    insertatempty!(result, 'r', 1)
    insertatempty!(result, 'k', 1)
    insertatempty!(result, 'r', 1)
    reduce(*, result)
end


function castlestring960(setup, buffer)
    ch1 = '?'
    ch2 = '?'
    for i ∈ 8:-1:1
        if setup[i] == 'r'
            ch1 = Char(i - 1 + Int('a'))
            break
        end
    end
    for i ∈ 1:8
        if setup[i] == 'r'
            ch2 = Char(i - 1 + Int('a'))
            break
        end
    end
    print(buffer, uppercase(ch1))
    print(buffer, uppercase(ch2))
    print(buffer, lowercase(ch1))
    print(buffer, lowercase(ch2))
end


"""
    chess950fen(i)

Returns the FEN string of the Chess960 position with index `i`.

The parameter `i` must be an integer in the range 0-959.
"""
function chess960fen(i)
    setup = backrank(i)
    result = IOBuffer()
    print(result, setup)
    print(result, "/pppppppp/8/8/8/8/PPPPPPPP/")
    print(result, uppercase(setup))
    print(result, " w ")
    castlestring960(setup, result)
    print(result, " -")
    String(take!(result))
end
