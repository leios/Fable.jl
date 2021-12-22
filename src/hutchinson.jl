function choose_fid(H)
    rnd = rand()

    offset = 0

    for i = 1:length(H.prob_set)
        if rnd > offset && rnd <= offset + H.prob_set[i]
            return i
        end
        offset += H.prob_set[i]
    end 

    println("Could not find appropriate function, ",
            "falling back to random selection...")

    return rand(1:length(H.f_set))
end

# This is a simple function to create a set of hutchinson operators
# Note that we are trying to convert all exprs into functions
# This allows us to write some more flexible macro syntax
#     (Impero @pde_equation, for example)
# Partially incomplete...
function create_hutchinson(f_set, prob_set, clr_set)
    for i = 1:length(f_set)
        if typeof(f_set[i]) == Expr
            f_set[i] = eval(f_set[i])
        end
    end

    return Hutchinson(f_set, prob_set, clr_set)
end
