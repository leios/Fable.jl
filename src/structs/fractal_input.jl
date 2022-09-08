export FractalInput, fi, configure_fis!, add, set

# Fractal inputs are essentially wrappers for the symbols tuple
# I would like to use have these outward-facing so users can update the tuple
struct FractalInput
    index::Union{Int, UnitRange{Int}}
    name::String
    val::Union{Number, Vector, Tuple, NTuple, Array}
end

FractalInput() = FractalInput(0,"",0)

function find_fi(fis, str)
    for i = 1:length(fis)
        if fis[i].name == str
            return i
        end
    end

    return nothing
end

function set(fi::FractalInput, val)
    return FractalInput(fi.index, fi.name, val)
end

function add(fis::Vector{FractalInput}, a::Int)
    for i = 1:length(fis)
        fis[i] = add(fis[i],a)
    end

    return fis
end

function add(fi::FractalInput, a::Int)
    index = fi.index
    if isa(index, Number)
        index += a
    else
        index = index[1]+a:index[end]+a
    end

    return FractalInput(index, fi.name, fi.val)
end

function fi(args...)
    return FractalInput(args...)
end

function fi(name, val)
    return FractalInput(0, name, val)
end

function configure_fis!(fis::Vector{FractalInput})
    max_symbols = 0
    for i = 1:length(fis)
        max_symbols += length(fis[i].val)
    end

    temp_array = zeros(max_symbols)
    idx = 1
    for i = 1:length(fis)
        if isa(fis[i].val, Union{Vector, Tuple, NTuple, Array})
            range = idx:idx+length(fis[i].val)-1
            temp_array[range] .= fis[i].val[:]
            fis[i] = FractalInput(range, fis[i].name, fis[i].val)
            idx += length(fis[i].val)
        else
            temp_array[idx] = fis[i].val
            fis[i] = FractalInput(idx, fis[i].name, fis[i].val)
            idx += 1
        end
    end

    return Tuple(temp_array[1:idx-1])
end

function Base.getindex(fi::FractalInput, idx::Union{Int,UnitRange{Int64}})
    return FractalInput(idx, fi.name, fi.val)
end
