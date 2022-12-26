export AbstractLayer, default_params, params, update_params!, find_overlap,
       find_bounds

abstract type AbstractLayer end;

struct Overlap
    range::Tuple
    start_index_1::Tuple
    start_index_2::Tuple
end

# TODO: higher dimensions...
function find_bounds(position, world_size)
    return (ymin = position[1] - 0.5 * world_size[1],
            ymax = position[1] + 0.5 * world_size[1],
            xmin = position[2] - 0.5 * world_size[2],
            xmax = position[2] + 0.5 * world_size[2])
end

function find_bounds(layer)
    return find_bounds(layer.position, layer.world_size)
end

# Note: currently returns ndrange for layer_1, but this might not be right...
function find_overlap(layer_1::AL1, layer_2::AL2)  where {AL1 <: AbstractLayer,
                                                          AL2 <: AbstractLayer}

    # Returning early if size and position is the same
    if layer_1.world_size == layer_2.world_size &&
       layer_1.position == layer_2.position
        return Overlap(size(layer_1.canvas), (1,1), (1,1))
    end

    # finding boundaries of each canvas
    bounds_1 = find_bounds(layer_1)
    bounds_2 = find_bounds(layer_2)

    # finding overlap region and starting indices
    ymin = max(bounds_1.ymin, bounds_2.ymin)
    xmin = max(bounds_1.xmin, bounds_2.xmin)

    ymax = min(bounds_1.ymax, bounds_2.ymax)
    xmax = min(bounds_1.xmax, bounds_2.xmax)

    if xmax < xmin || ymax < ymin
        @warn("No overlap between layers...")
        return nothing
    end

    start_index_1 = [1, 1]
    start_index_2 = [1, 1]

    if ymin > bounds_1.ymin
        start_index_1[1] = floor(Int, layer_1.ppu * (ymin - bounds_1.ymin)) + 1
    end
    if xmin > bounds_1.xmin
        start_index_1[2] = floor(Int, layer_1.ppu * (xmin - bounds_1.xmin)) + 1
    end

    if ymin > bounds_2.ymin
        start_index_2[1] = floor(Int, layer_2.ppu * (ymin - bounds_2.ymin)) + 1
    end
    if xmin > bounds_2.xmin
        start_index_2[2] = floor(Int, layer_2.ppu * (xmin - bounds_2.xmin)) + 1
    end

    return Overlap((floor(Int, (ymax - ymin)*layer_1.ppu), 
                    floor(Int, (xmax - xmin)*layer_1.ppu)), 
                   Tuple(start_index_1),
                   Tuple(start_index_2))

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
