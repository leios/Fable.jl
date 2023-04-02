export FractalInput, fi, @fi, set!, combine

struct FractalInput
    s::Union{Symbol, String}
    x::Ref{Union{Number, Tuple, Vector}}
end

fi(args...) = FractalInput(args...)

function set!(fi::FractalInput, val)
    fi.x.x = val
end

function combine(fis::Tuple, nt::Tuple)
    return Tuple(combine(fis[i], nt[i]) for i = 1:length(fis))
end

combine(fis::Vector{FractalInput}, nt::NamedTuple) = combine(nt, fis)

function remove_vectors(a)
    return a
end
function remove_vectors(a::Vector)
    return Tuple(a)
end

function combine(nt::NamedTuple, fis::Vector{FractalInput})
    if length(fis) == 0
        return nt
    end

    fi_vals = (remove_vectors(fis[i].x.x) for i = 1:length(fis))
    fi_keys = (Symbol(fis[i].s) for i = 1:length(fis))

    return NamedTuple{(keys(nt)..., fi_keys...)}((values(nt)..., fi_vals...))
end
