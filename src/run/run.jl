export run!

function run!(layer::AbstractLayer, time::TimeInterface)
    run!(layer; frame = current_frame(time))
end

function run!(layers::Vector{AbstractLayer}, time::TimeInterface)
    run!(layers; frame = current_frame(time))
end

function run!(layers::Vector{AbstractLayer}; frame = 0)
    for i = 1:length(layers)
        run!(layers[i]; frame = frame)
    end
end

# dummy function that should be defined for each layer
function run!(layer::AbstractLayer; frame = 0)
    @error("run!("*string(typeof(layer))*") not defined!")
end
