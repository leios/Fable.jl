#TODO: implement symmetry function that does the following:
#      1. allows for rotational symmetries
#      2. allows for inverting along axes
function apply_symmetry(;rotational_number = 0, flip_axis = 0)
end

function affine_rand()
    return [rand() rand() 0; rand() rand() 0; 0 0 1]
end

function affine(A, p::Point)
    loc = A*[p.x, p.y, 1]
    return Point(loc[1], loc[2], p.c)
end
