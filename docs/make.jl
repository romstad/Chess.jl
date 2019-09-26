using Documenter, Chess, Chess.Book, Chess.PGN, Chess.UCI

makedocs(;
    modules=[Chess, Chess.Book, Chess.PGN, Chess.UCI],
    format=Documenter.HTML(assets=String[]),
    pages=[
        "Home" => "index.md",
        "User Guide" => "manual.md",
        "API Reference" => "api.md",
        "Index" => "api-index.md"
    ],
    repo="https://github.com/romstad/Chess.jl/blob/{commit}{path}#L{line}",
    sitename="Chess.jl",
    authors="Tord Romstad",
)

deploydocs(
    repo = "github.com/romstad/Chess.jl.git",
)
