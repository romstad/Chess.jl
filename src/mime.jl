module MIME

using Hiccup
using ..Chess
using ..Chess.PGN

export html

const BOARD_SIZE = 280
const DARK_SQUARE_COLOR = "#a4704b"
const LIGHT_SQUARE_COLOR = "#ffd7a6"
const HIGHLIGHT_COLOR = "#47d18b"

function squarecolor(file, rank)
    if iseven(file + rank)
        LIGHT_SQUARE_COLOR
    else
        DARK_SQUARE_COLOR
    end
end

function imgurl(p::Piece)::String
    c = pcolor(p)
    t = ptype(p)
    "https://raw.githubusercontent.com/romstad/Chess.jl/master/img/" *
    tochar(c) *
    lowercase(tochar(t)) *
    ".svg"
end

function squarehighlight(s)
    f = file(s).val - 1
    r = rank(s).val - 1
    Node(
        :circle,
        Dict(
            :cx => f + 0.5,
            :cy => r + 0.5,
            :r => 0.4,
            :fill => HIGHLIGHT_COLOR,
            :opacity => 0.5,
        ),
    )
end

function squarehighlights(ss::SquareSet)
    Node(:g, map(squarehighlight, Chess.squares(ss)))
end

function square(file::Int, rank::Int, piece)
    Node(
        :g,
        Node(
            :rect,
            Dict(
                :fill => squarecolor(file, rank),
                :x => file,
                :y => rank,
                :width => 1,
                :height => 1,
            ),
        ),
        if piece == EMPTY
            Node(:g)
        else
            Node(
                :image,
                Dict(
                    Symbol("xlink:href") => imgurl(piece),
                    :x => file,
                    :y => rank,
                    :width => 1,
                    :height => 1,
                ),
            )
        end,
    )
end

function square(s::Square, piece)
    f = file(s).val - 1
    r = rank(s).val - 1
    square(f, r, piece)
end

function squares(board)
    Node(:g, map(s -> square(Square(s), pieceon(board, Square(s))), 1:64))
end

function svg(; board = emptyboard(), highlight = SS_EMPTY)
    Node(
        :svg,
        Dict(
            :style => "float: left; margin-right: 20px",
            :viewBox => "0 0 8 8",
            :width => BOARD_SIZE,
            :height => BOARD_SIZE,
        ),
        [squares(board), squarehighlights(highlight)],
    )
end

function lichesslink(board)
    Node(:a, Dict(:href => lichessurl(board), :target => "_blank"), "Open in lichess")
end

function description(board)
    Node(
        :div,
        [
            Node(:p, sidetomove(board) == WHITE ? "White to move" : "Black to move"),
            board.castlerights == 0 ? "" :
            Node(:p, "Castle rights: " * Chess.castlestring(board)),
            epsquare(board) == SQ_NONE ? "" :
            Node(:p, "En passant square: " * tostring(epsquare(board))),
            Node(:p, lichesslink(board)),
        ],
    )
end

function html(board::Board; highlight = SS_EMPTY)
    Node(
        :div,
        Dict(:class => "chessboard"),
        [svg(board = board, highlight = highlight), description(board)],
    )
end

function html(ss::SquareSet)
    Node(:div, Dict(:class => "chessboard"), svg(highlight = ss))
end

function jsify(g)
	  replace("'$(gametopgn(g))'", "\n" => "\\n")
end

function html(g::SimpleGame)
    Node(
        :div,
        Dict(:class => "game"),
        [
            svg(board = board(g)),
            Node(:p, Chess.PGN.formatmoves(g, true)),
            Node(
                :a,
                Dict(
                    :href => "",
                    :onclick => "navigator.clipboard.writeText($(jsify(g))).then(function(){},function(){});window.open('https://lichess.org/paste','_blank');"),
                "Open in lichess"
            )
        ]
    )
end

function html(g::Game)
    Node(
        :div,
        Dict(:class => "game"),
        [
            svg(board = board(g)),
            Node(:p, Chess.PGN.formatmoves(g, true)),
            Node(
                :a,
                Dict(
                    :href => "",
                    :onclick => "navigator.clipboard.writeText($(jsify(g))).then(function(){},function(){});window.open('https://lichess.org/paste','_blank');"),
                "Open in lichess"
            )
        ]
    )
end

end
