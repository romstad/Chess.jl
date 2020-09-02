#=
Chess.jl: A Julia chess programming library
Copyright (C) 2019 Tord Romstad

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
=#

module MIME

using Hiccup
using ..Chess

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
        tochar(c) * lowercase(tochar(t)) * ".svg"
end

function squarehighlight(s)
    f = file(s).val - 1
    r = rank(s).val - 1
    Node(:circle,
         Dict(:cx => f + 0.5,
              :cy => r + 0.5,
              :r => 0.4,
              :fill => HIGHLIGHT_COLOR,
              :opacity => 0.5))
end

function squarehighlights(ss::SquareSet)
    Node(:g, map(squarehighlight, Chess.squares(ss)))
end

function square(file::Int, rank::Int, piece)
    Node(:g,
         Node(:rect,
              Dict(:fill => squarecolor(file, rank),
                   :x => file,
                   :y => rank,
                   :width => 1,
                   :height => 1)),
         if piece == EMPTY
             Node(:g)
         else
             Node(:image,
                  Dict(Symbol("xlink:href") => imgurl(piece),
                       :x => file,
                       :y => rank,
                       :width => 1,
                       :height => 1))
         end)
end

function square(s::Square, piece)
    f = file(s).val - 1
    r = rank(s).val - 1
    square(f, r, piece)
end

function squares(board)
    Node(:g,
         map(s -> square(Square(s), pieceon(board, Square(s))), 1:64),)
end

function svg(;board = emptyboard(), highlight = SS_EMPTY)
    Node(:svg,
         Dict(:style => "float: left; margin-right: 20px",
              :viewBox => "0 0 8 8",
              :width => BOARD_SIZE,
              :height => BOARD_SIZE),
         [squares(board),
          squarehighlights(highlight)])
end

function lichesslink(board)
    Node(:a,
         Dict(:href => lichessurl(board)),
         "Open in lichess")
end

function description(board)
    Node(:div,
         [Node(:p,
               sidetomove(board) == WHITE ?
               "White to move" : "Black to move"),
          board.castlerights == 0 ?
          "" : Node(:p, "Castle rights: " * Chess.castlestring(board)),
          epsquare(board) == SQ_NONE ?
          "" : Node(:p, "En passant square: " * tostring(epsquare(board))),
          Node(:p, lichesslink(board))])
end

function html(board::Board; highlight=SS_EMPTY)
    Node(:div,
         Dict(:class => "chessboard"),
         [svg(board=board, highlight=highlight),
          description(board)])
end

function html(ss::SquareSet)
    Node(:div,
         Dict(:class => "chessboard"),
         svg(highlight=ss))
end


end
