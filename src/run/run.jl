export run!

function run!(layers::Vector{AbstractLayer}, bounds; diagnostic = false)
    for i = 1:length(layers)
        run!(layer, bounds; diagnostic = diagnostic)
    end
end
