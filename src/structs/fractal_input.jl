export FractalInput, fi, @fi, set!, to_expr

struct FractalInput
    s::Union{Symbol, String}
    x::Ref{Number}
end

fi(args...) = FractalInput(args...)

function set!(fi::FractalInput, val)
    fi.x.x = val
end

function to_expr(fi)
    val = fi.x.x
    sym = Symbol(fi.s)
    return :($sym = $val)
end
