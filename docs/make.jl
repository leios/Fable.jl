using Documenter

makedocs(
    sitename="Fae.jl",
    authors="James Schloss (Leios) and contributors",
    pages = [
        "General Information" => "index.md",
        "Layering" => "layering.md",
        "Time Interface" => "time_interface.md",
        "Post Processing" => "postprocessing.md",
        "Research Directions" => "research_directions.md",
        "Examples" => Any[
            "Rotating Square" => "examples/swirled_square.md",
            "Simple Smears" => "examples/smear.md",
        ],
    ],
)

deploydocs(;
    repo="github.com/leios/Fae.jl",
)
