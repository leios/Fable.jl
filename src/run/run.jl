#------------------------------------------------------------------------------#
#
# This is a sketch. To get this to run, we need to make sure each layer has some
# sort of parameters that includes:
#     bounds, num_interactions, num_particles, numthreads, numcores, etc...
#
#------------------------------------------------------------------------------#
export run!

function run!(layers::Vector{AbstractLayer})
    for i = 1:length(layers)
        run!(layer)
    end
end
