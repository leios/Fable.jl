export AbstractLayer, default_params, params, update_params!

abstract type AbstractLayer end;

function default_params(a::Type{AL}) where AL <: AbstractLayer
    return (numthreads = 256, numcores = 4,
            ArrayType = Array, FloatType = Float32)
end

function params(a::Type{AL}; numthreads = 256, numcores = 4, ArrayType = Array,
                FloatType = Float32) where AL <: AbstractLayer
    return (numthreads = numthreads,
            numcores = numcores,
            ArrayType = ArrayType,
            FloatType = FloatType)
end

function update_params!(layer::AL; kwargs...) where AL <: AbstractLayer
    some_keys = [keys(layer.params)...]
    some_values = [values(layer.params)...]

    new_keys = [keys(kwargs)...]
    new_values = [values(kwargs)...]

    for i = 1:length(some_keys)
        for j = 1:length(new_keys)
            if some_keys[i] == new_keys[j]
                some_values[i] = new_values[j]
            end
        end
    end

    layer.params = NamedTuple{Tuple(some_keys)}(some_values)
end
