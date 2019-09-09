using Documenter, Chess, Chess.PGN, Chess.UCI

makedocs(;
    modules=[Chess, Chess.PGN, Chess.UCI],
    format=Documenter.HTML(assets=String[]),
    pages=[
        "Home" => "index.md",
        "User Guide" => "manual.md",
    ],
    repo="https://github.com/romstad/Chess.jl/blob/{commit}{path}#L{line}",
    sitename="Chess.jl",
    authors="Tord Romstad",
)
