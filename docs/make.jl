using ByOperations
using Documenter

DocMeta.setdocmeta!(ByOperations, :DocTestSetup, :(using ByOperations); recursive=true)

makedocs(;
    modules=[ByOperations],
    authors="Tim Holy <tim.holy@gmail.com> and contributors",
    sitename="ByOperations.jl",
    format=Documenter.HTML(;
        canonical="https://timholy.github.io/ByOperations.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/timholy/ByOperations.jl",
    devbranch="main",
)
