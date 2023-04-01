export FractalInput, fi, @fi, set!, combine

struct FractalInput
    s::Union{Symbol, String}
    x::Ref{Number}
end

fi(args...) = FractalInput(args...)

function set!(fi::FractalInput, val)
    fi.x.x = val
end

combine(fis::Vector{FractalInput}, nt::NamedTuple) = combine(nt, fis)

function combine(nt::NamedTuple, fis::Vector{FractalInput})
    if length(fis) == 0
        return nt
    end

    fi_vals = (fis[i].x.x for i = 1:length(fis))
    fi_keys = (Symbol(fis[i].s) for i = 1:length(fis))

    return NamedTuple{(keys(nt)..., fi_keys...)}((values(nt)..., fi_vals...))
end
