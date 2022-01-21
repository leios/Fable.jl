#TODO: implement symmetry function that does the following:
#      1. allows for rotational symmetries
#      2. allows for inverting along axes
function apply_symmetry(;rotational_number = 0, flip_axis = 0)
end

function affine_rand(;dims = 2, scale = 1)
    rand_set = zeros(dims+1, dims+1)
    rand_set[end, end] = 1
    rand_set[1:dims,1:dims] = rand(dims, dims)*scale .- scale*0.5
    return rand_set
end

function affine!(p::Array{Float64}, A)
    p = (A*[p..., 1])[1:end-1]
end
