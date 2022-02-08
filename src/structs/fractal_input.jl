# Fractal inputs are essentially wrappers for the symbols tuple
# I would like to use have these outward-facing so users can update the tuple
struct FractalInput
    index::Union{Int, UnitRange{Int}}
    name::String
    val::Union{Number, Vector, Tuple, NTuple}
end

function fi(args...)
    return FractalInput(args...)
end

function fi(name, val)
    return FractalInput(0, name, val)
end

function configure_fis!(fis::Vector{FractalInput}; max_symbols = length(fis)*2)
    temp_array = zeros(max_symbols)
    idx = 1
    for i = 1:length(fis)
        if isa(fis[i].val, Union{Vector, Tuple, NTuple})
            range = idx:idx+length(fis[i].val)-1
            temp_array[range] .= fis[i].val
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
