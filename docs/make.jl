using Documenter, Chess

makedocs(;
    modules=[Chess],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/romstad/Chess.jl/blob/{commit}{path}#L{line}",
    sitename="Chess.jl",
    authors="Tord Romstad",
    assets=String[],
)
