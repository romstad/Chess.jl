using Documenter, Chess, Chess.PGN, Chess.UCI

makedocs(;
    modules=[Chess, Chess.PGN, Chess.UCI],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/romstad/Chess.jl/blob/{commit}{path}#L{line}",
    sitename="Chess.jl",
    authors="Tord Romstad",
    assets=String[],
)
