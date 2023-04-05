export define_triangle, update_triangle!

triangle_fill = @fum function triangle_fill(x,y;
                                            A = (0,0),
                                            B = (0,0),
                                            C = (0,0))
    midpoint = (A .+ B .+ C) ./ 3

    x = midpoint[2] - (x - midpoint[2]) * 0.5
    y = midpoint[1] - (y - midpoint[1]) * 0.5
end

function define_triangle(; A::Union{Vector,Tuple,FractalInput}=(sqrt(3)/4,-0.5),
                           B::Union{Vector,Tuple,FractalInput}=(-sqrt(3)/4,0),
                           C::Union{Vector,Tuple,FractalInput}=(sqrt(3)/4,0.5),
                           color = Shaders.gray,
                           chosen_fx = :fill,
                           additional_fis = FractalInput[])
    fums, fis = define_triangle_operators(A, B, C)

    fnum = 3
    if chosen_fx == :fill
        fnum = 4
    end

    color_set = define_color_operators(color; fnum = fnum)
    fos = [FractalOperator(fums[i], color_set[i], 1/fnum) for i = 1:fnum]

    return Hutchinson(fos, vcat(fis, additional_fis))
end

# This specifically returns the fums for a triangle triangle
function define_triangle_operators(A::Union{Vector, Tuple, FractalInput},
                                   B::Union{Vector, Tuple, FractalInput},
                                   C::Union{Vector, Tuple, FractalInput};
                                   chosen_fx = :fill)

    if chosen_fx != :sierpinski && chosen_fx != :fill
        error("Cannot create triangle with ", string(chosen_fx), " function!")
    end

    if !isa(A, FractalInput)
        A = fi("A", A)
    end
    if !isa(B, FractalInput)
        B = fi("B", B)
    end
    if !isa(C, FractalInput)
        C = fi("C", C)
    end

    s_1 = Flames.halfway(loc = A)
    s_2 = Flames.halfway(loc = B)
    s_3 = Flames.halfway(loc = C)
    if chosen_fx == :fill
        s_4 = triangle_fill(A = A, B = B, C = C)

        return [s_1, s_2, s_3, s_4], [A,B,C]
    elseif chosen_fx == :sierpinski
        return [s_1, s_2, s_3], [A,B,C]
    end
end
