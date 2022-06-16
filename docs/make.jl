using Documenter, Fae

makedocs(
    sitename="Fae.jl",
    authors="James Schloss (Leios) and contributors",
    pages = [
        "Home" => "index.md",
        "General Information" => "general_info.md",
        "Examples" => Any[
            "Logo" => "examples/logo.md",
        ],
    ],
)

deploydocs(;
    repo="github.com/leios/Fae.jl",
)
