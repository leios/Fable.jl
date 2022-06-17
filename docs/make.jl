using Documenter

makedocs(
    sitename="Fae.jl",
    authors="James Schloss (Leios) and contributors",
    pages = [
        "Home" => "index.md",
        "Examples" => Any[
            "Logo" => "examples/logo.md",
        ],
        "Research Directions" => "research_directions.md",
    ],
)

#deploydocs(;
#    repo="github.com/leios/Fae.jl",
#)
