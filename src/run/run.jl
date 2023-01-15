export run!

function run!(layer::AbstractLayer, time::TimeInterface; diagnostic = false)
    run!(layer; diagnostic = diagnostic, frame = frame(time))
end

function run!(layers::Vector{AbstractLayer}, time::TimeInterface;
              diagnostic = false)
    run!(layers; diagnostic = diagnostic, frame = frame(time))
end

function run!(layers::Vector{AbstractLayer}; diagnostic = false, frame = 0)
    for i = 1:length(layers)
        run!(layers[i]; diagnostic = diagnostic, frame = frame)
    end
end

# dummy function that should be defined for each layer
function run!(layer::AbstractLayer; diagnostic = false, frame = 0)
    @error("run!("*string(typeof(layer))*") not defined!")
end
