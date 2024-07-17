export FableInput, fi, @fi, set!, combine, to_args, find_fi_index, value

struct FableInput
    s::Union{Symbol, String}
    x::Ref{Union{Number, Tuple, Vector}}
end

fi(args...) = FableInput(args...)

function set!(fi::FableInput, val)
    fi.x.x = val
end

function combine(nt::Tuple, fis::Tuple)
    return Tuple(combine(nt[i], fis[i]) for i = 1:length(fis))
end

combine(fis::Vector{FableInput}, nt::NamedTuple) = combine(nt, fis)

function combine(nt::NamedTuple, fis::Vector{FableInput})
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

function to_args(nt::NamedTuple, fis::Vector{FableInput})
    if length(fis) == 0
        return values(nt)
    end
    fi_vals = (remove_vectors(fis[i].x.x) for i = 1:length(fis))
    return (values(nt)..., fi_vals...)
end

function find_fi_index(s, fis::FT) where FT <: Union{Vector{FableInput},
                                                     Tuple}
    for i = 1:length(fis)
        if Symbol(fis[i].s) == Symbol(s)
            return i
        end
    end
end

value(fi::FableInput) = fi.x.x
value(a) = a
