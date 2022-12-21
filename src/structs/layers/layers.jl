export AbstractLayer, default_params, params, update_params!, find_overlap,
       find_bounds

abstract type AbstractLayer end;

struct Overlap
    range::Tuple
    start_index_1::Tuple
    start_index_2::Tuple
end

function find_bounds(layer)
    return (layer.position[1] - 0.5 * layer.size[1],
            layer.position[1] + 0.5 * layer.size[1],
            layer.position[2] - 0.5 * layer.size[2],
            layer.position[2] + 0.5 * layer.size[2])
end

function find_overlap(layer_1::AL1, layer_2::AL2)  where {AL1 <: AbstractLayer,
                                                          AL2 <: AbstractLayer}
    ppu = layer_1.ppu

    # TODO: scale if different PPUs
    if layer_1.ppu != layer_2.ppu
        error("Layer Pixel count Per Unit (PPU) not the same!")
    end

    # Returning early if size and position is the same
    if layer_1.size == layer_2.size && layer_1.position == layer_2.position
        return Overlap(layer_1.size, (1,1), (1,1))
    end

    # finding boundaries of each canvas
    bounds_1 = find_bounds(layer_1)
    bounds_2 = find_bounds(layer_2)

    # finding overlap region and starting indices
    ymin = max(bounds_1[1], bounds_2[1])
    xmin = max(bounds_1[3], bounds_2[3])

    start_index_1 = [0,0]
    start_index_2 = [0,0]

    if bounds_2[2] > bounds_1[2]
        ymax = bounds_2[2]
        start_index_1[1] = 1
        start_index_2[1] = bounds_2[2] - ymin
    else
        ymax = bounds_1[2]
        start_index_1[1] = bounds_1[2] - ymin
        start_index_2[1] = 1
    end

    if bounds_2[4] > bounds_1[4]
        xmax = bounds_2[4]
        start_index_1[2] = 1
        start_index_2[2] = bounds_2[4] - ymin
    else
        ymax = bounds_1[4]
        start_index_1[2] = bounds_1[4] - ymin
        start_index_2[2] = 1
    end

    if xmax < xmin || ymax < ymin
        @warn("No overlap between layers...")
        return nothing
    end

    return Overlap(((ymax - ymin)*ppu, (xmax-xmin)*ppu), 
                   Tuple(start_index_1),
                   Tuple(start_index_1))

end

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
