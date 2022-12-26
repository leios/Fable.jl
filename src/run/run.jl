export run!

function run!(layers::Vector{AbstractLayer}; diagnostic = false)
    for i = 1:length(layers)
        run!(layers[i]; diagnostic = diagnostic)
    end
end
