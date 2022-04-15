module MIME

using Hiccup
using HypertextLiteral
using ..Chess, ..Chess.PGN

export html

const BOARD_SIZE = 280

const DARK_SQUARE_COLOR = "#c3936a"
const LIGHT_SQUARE_COLOR = "#ffd7a6"
const HIGHLIGHT_COLOR = "#47d18b"

const DARK_SQUARE_COLOR_DARK_MODE = "#00796b"
const LIGHT_SQUARE_COLOR_DARK_MODE = "#3ca59b"
const HIGHLIGHT_COLOR_DARK_MODE = "#d23600"

function squarecolor(file, rank)
    if iseven(file + rank)
        "light-square"
    else
        "dark-square"
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
            :class => "highlight",
            :cx => f + 0.5,
            :cy => r + 0.5,
            :r => 0.3,
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
                :class => squarecolor(file, rank),
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
    buf = IOBuffer()
    Chess.castlestring(board, buf)
    Node(
        :div,
        [
            Node(:p, sidetomove(board) == WHITE ? "White to move" : "Black to move"),
            board.castlerights == 0 ? "" : Node(:p, "Castle rights: " * String(take!(buf))),
            epsquare(board) == SQ_NONE ? "" :
            Node(:p, "En passant square: " * tostring(epsquare(board))),
            Node(:p, lichesslink(board)),
        ],
    )
end

function stylenode()
    Node(
        :style,
        Dict(:soped => "true"),
        """
        .dark-square {
            fill: $DARK_SQUARE_COLOR;
            stroke-width: 0;
        }
        .light-square {
            fill: $LIGHT_SQUARE_COLOR;
            stroke-width: 0;
        }
        .highlight {
            fill: $HIGHLIGHT_COLOR;
        }
        @media (prefers-color-scheme: dark) {
            .dark-square {
                fill: $DARK_SQUARE_COLOR_DARK_MODE;
            }
            .light-square {
                fill: $LIGHT_SQUARE_COLOR_DARK_MODE;
            }
            .highlight {
                fill: $HIGHLIGHT_COLOR_DARK_MODE;
            }
        }
        """
    )
end

function html(board::Board; highlight = SS_EMPTY)
    Node(
        :div,
        Dict(:class => "chessboard"),
        [
            stylenode(),
            svg(board = board, highlight = highlight), description(board)
        ],
    )
end

function html(ss::SquareSet)
    Node(
        :div,
        Dict(:class => "chessboard"),
        [
            stylenode(),
            svg(highlight = ss)
        ]
    )
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
            Node(:p, Chess.formatmoves(g, "👉")),
            Node(
                :a,
                Dict(
                    :href => "",
                    :onclick =>
                        "navigator.clipboard.writeText($(jsify(g))).then(function(){},function(){});window.open('https://lichess.org/paste','_blank');",
                ),
                "Open in lichess",
            ),
        ],
    )
end

const GAME_CSS = """
.game {
    text-color: blue;
}
"""

function html(g::Game)
    Node(
        :div,
        Dict(:class => "game", :style => GAME_CSS),
        [
            svg(board = board(g)),
            Node(:p, format_game(g)),
            Node(
                :a,
                Dict(
                    :href => "",
                    :onclick =>
                        "navigator.clipboard.writeText($(jsify(g))).then(function(){},function(){});window.open('https://lichess.org/paste','_blank');",
                ),
                "Open in lichess",
            ),
        ],
    )
end


function format_game(g::Game)

    function movestyle(depth)
        if depth == 0
            "font-weight: bold; color: #000000;"
        elseif depth == 1
            "font-weight: bold; color: #777777;"
        else
            "font-weight: bold; color: #bbbbbb;"
        end
    end

    function moveclass(depth)
        if depth == 0
            "move-depth-0"
        elseif depth == 1
            "move-depth-1"
        else
            "move-depth-2"
        end
    end

    function movestyles()
        Node(
            :style,
            Dict(:scoped => "true"),
            """
                .move-depth-0 {
                    font-weight: bold; color: #000000;
                }
                .move-depth-1 {
                    font-weight: bold; color: #777777;
                }
                .move-depth-2 {
                    font-weight: bold; color: #bbbbbb;
                }
                .comment {
                    color: blue;
                }
                @media (prefers-color-scheme: dark) {
                    .move-depth-0 {
                        font-weight: bold; color: #ffffff;
                    }
                    .move-depth-1 {
                        font-weight: bold; color: #aaaaaa;
                    }
                    .move-depth-2 {
                        font-weight: bold; color: #666666;
                    }
                    .comment {
                        color: #00d9a3;
                    }
                }
            """
        )
    end

    function fmt_move(node, child, movenum, depth, blackmovenum)
        ms = movetosan(node.board, lastmove(child.board))
        space = blackmovenum ? "" : " "
        if sidetomove(node.board) == WHITE
            @htl(
                "<span class=$(moveclass(depth))>$space$(string(movenum ÷ 2 + 1)). $ms</span>"
            )
        elseif blackmovenum || isnothing(node.parent)
            @htl(
                "<span class=$(moveclass(depth))>$space$(string(movenum ÷ 2 + 1))... $ms</span>"
            )
        else
            @htl(
                "<span class=$(moveclass(depth))>$space$ms</span>"
            )
        end
    end

    function fmt_precomment(comment)
        if isnothing(comment)
            @htl("")
        else
            @htl("<span class=\"comment\">$comment</span> ")
        end
    end

    function fmt_comment(comment)
        if isnothing(comment)
            @htl("")
        else
            @htl("<span class=\"comment\"> $comment</span>")
        end
    end

    function fmt_nag(nag)
        if isnothing(nag)
            @htl("")
        else
            @htl(" <span class=\"comment\">\$$nag</span>")
        end
    end

    function fmt_child(child, movenum, blackmovenum, depth)
        move = fmt_move(child.parent, child, movenum, depth, blackmovenum)
        precmt = fmt_precomment(precomment(child))
        cmt = fmt_comment(comment(child))
        nag = fmt_nag(Chess.nag(child))

        @htl("$precmt$move$nag$cmt")
    end

    function fmt_subvars(node, movenum, depth)
        if length(node.children) < 2
            @htl("")
        else
            vars = [
                @htl(
                    " ($(fmt_child(c, movenum, true, depth+1))$(fmt_var(c, movenum+1, depth+1)))"
                ) for c in node.children[2:end]
            ]
            @htl("$vars")
        end
    end

    function fmt_var(node, movenum, depth)
        if !isempty(node.children)
            cni = node == g.node ? " 👉" : ""
            child = first(node.children)
            childhtml = fmt_child(child, movenum, false, depth)
            cont = fmt_var(child, movenum + 1, depth)
            subvars = fmt_subvars(node, movenum, depth)
            @htl("$cni$(fmt_child(child, movenum, false, depth))$subvars$cont")
        elseif node == g.node
            @htl(" 👉")
        else
            @htl("")
        end
    end

    @htl("$(movestyles())$(fmt_var(g.root, 0, 0))")
end

end
