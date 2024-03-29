export AbstractLayer, default_params, params, update_params!, find_overlap,
       find_bounds, AbstractPostProcess

abstract type AbstractLayer end;
abstract type AbstractPostProcess end;

struct Overlap
    range::Tuple
    start_index_1::Tuple
    start_index_2::Tuple
    bounds::NamedTuple
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

# does not return Overlap because it is used inside KA kernels
@inline function find_overlap(index, world_size_1, world_size_2)
    filter_ymin = floor(Int, index[1] - 0.5*world_size_2[1])+1
    filter_ymax = floor(Int, index[1] + 0.5*world_size_2[1])
    filter_xmin = floor(Int, index[2] - 0.5*world_size_2[2])+1
    filter_xmax = floor(Int, index[2] + 0.5*world_size_2[2])

    ymin = max(filter_ymin, 1)
    xmin = max(filter_xmin, 1)

    ymax = min(filter_ymax, world_size_1[1])
    xmax = min(filter_xmax, world_size_1[2])

    if filter_ymin < 1
        # note: the 2 is because it is 1 + (1 - filter_ymin)
        filter_ymin = 2 - filter_ymin
    else
        filter_ymin = 1
    end

    if filter_xmin < 1
        filter_xmin = 2 - filter_xmin
    else
        filter_xmin = 1
    end

    # range, start_index_1, start_index_2
    return ((ymax - ymin + 1, xmax - xmin + 1), (ymin, xmin),
            (filter_ymin, filter_xmin))

end

function find_overlap(layer_1::AL1, layer_2::AL2)  where {AL1 <: AbstractLayer,
                                                          AL2 <: AbstractLayer}

    # Returning early if size and position is the same
    if layer_1.world_size == layer_2.world_size &&
       layer_1.position == layer_2.position
        return Overlap(size(layer_1.canvas), (1,1), (1,1), find_bounds(layer_1))
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
                   Tuple(start_index_2),
                   (ymin = ymin, ymax = ymax, xmin = xmin, xmax = xmax))

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
