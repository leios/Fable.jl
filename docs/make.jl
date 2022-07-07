using Documenter

makedocs(
    sitename="Fae.jl",
    authors="James Schloss (Leios) and contributors",
    pages = [
        "Home" => "index.md",
        "General Information" => "general_info.md",
        "Examples" => Any[
            "Rotating Square" => "examples/swirled_square.md",
            "Simple Smears" => "examples/smear.md",
        ],
        "Research Directions" => "research_directions.md",
    ],
)

deploydocs(;
    repo="github.com/leios/Fae.jl",
)
