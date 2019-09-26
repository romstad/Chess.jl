using Documenter, Chess, Chess.Book, Chess.PGN, Chess.UCI

makedocs(;
    modules=[Chess, Chess.Book, Chess.PGN, Chess.UCI],
    format=Documenter.HTML(assets=String[]),
    pages=[
        "Home" => "index.md",
        "User Guide" => "manual.md",
    ],
    repo="https://github.com/romstad/Chess.jl/blob/{commit}{path}#L{line}",
    sitename="Chess.jl",
    authors="Tord Romstad",
)
