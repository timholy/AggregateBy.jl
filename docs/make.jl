using AggregateBy
using Documenter

DocMeta.setdocmeta!(AggregateBy, :DocTestSetup, :(using AggregateBy); recursive=true)

makedocs(;
    modules=[AggregateBy],
    authors="Tim Holy <tim.holy@gmail.com> and contributors",
    sitename="AggregateBy.jl",
    format=Documenter.HTML(;
        canonical="https://timholy.github.io/AggregateBy.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "How it works" => "explanation.md",
        "Internals" => "advanced.md",
        "Reference" => "reference.md",
    ],
)

deploydocs(;
    repo="github.com/timholy/AggregateBy.jl",
    devbranch="main",
)
