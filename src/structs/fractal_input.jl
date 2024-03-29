export FractalInput, fi, @fi, set!, combine, to_args, find_fi_index, value

struct FractalInput
    s::Union{Symbol, String}
    x::Ref{Union{Number, Tuple, Vector}}
end

fi(args...) = FractalInput(args...)

function set!(fi::FractalInput, val)
    fi.x.x = val
end

function combine(nt::Tuple, fis::Tuple)
    return Tuple(combine(nt[i], fis[i]) for i = 1:length(fis))
end

combine(fis::Vector{FractalInput}, nt::NamedTuple) = combine(nt, fis)

function combine(nt::NamedTuple, fis::Vector{FractalInput})
    if length(fis) == 0
        return nt
    end

    fi_vals = (remove_vectors(fis[i].x.x) for i = 1:length(fis))
    fi_keys = (Symbol(fis[i].s) for i = 1:length(fis))

    return NamedTuple{(keys(nt)..., fi_keys...)}((values(nt)..., fi_vals...))
end

function to_args(nt::Tuple, fis::Tuple)
    return Tuple(combine(fis[i], nt[i]) for i = 1:length(fis))
end

function to_args(nt::NamedTuple, fis::Vector{FractalInput})
    if length(fis) == 0
        return values(nt)
    end
    fi_vals = (remove_vectors(fis[i].x.x) for i = 1:length(fis))
    return (values(nt)..., fi_vals...)
end

function find_fi_index(s, fis::FT) where FT <: Union{Vector{FractalInput},
                                                     Tuple}
    for i = 1:length(fis)
        if Symbol(fis[i].s) == Symbol(s)
            return i
        end
    end
end

value(fi::FractalInput) = fi.x.x
value(a) = a
