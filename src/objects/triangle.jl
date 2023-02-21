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
                           name = "triangle",
                           chosen_fx = :fill,
                           diagnostic = false)
    fums, fis = define_triangle_operators(A, B, C; name = name)

    fnum = 3
    if chosen_fx == :fill
        fnum = 4
    end

    if length(color) == 1 || eltype(color) <: Number
        color_set = [create_color(color) for i = 1:fnum]
    elseif length(color) == fnum
        color_set = [create_color(color[i]) for i = 1:fnum]
    else
        error("cannot convert colors for triangle, "*
              "maybe improper number of functions?")
    end
    fos = [FractalOperator(fums[i], color_set[i], 1/fnum) for i = 1:fnum]

    return Hutchinson(fos, fis; name = name, diagnostic = diagnostic)
end

# This specifically returns the fums for a triangle triangle
function define_triangle_operators(A::Union{Vector, Tuple, FractalInput},
                                   B::Union{Vector, Tuple, FractalInput},
                                   C::Union{Vector, Tuple, FractalInput};
                                   chosen_fx = :fill, name="triangle")

    if chosen_fx != :sierpinski && chosen_fx != :fill
        error("Cannot create triangle with ", string(chosen_fx), " function!")
    end

    if !isa(A, FractalInput)
        A = fi("A_"*name, A)
    end
    if !isa(A, FractalInput)
        B = fi("B_"*name, B)
    end
    if !isa(A, FractalInput)
        C = fi("C_"*name, C)
    end

    s_1 = Flames.halfway(loc = A)
    s_2 = Flames.halfway(loc = B)
    s_3 = Flames.halfway(loc = C)
    if chosen_fx == :fill
        s_4 = triangle_fill(A = A, B = B, C = C)

        return [s_1, s_2, s_3, s_4], [f_A,f_B,f_C]
    elseif chosen_fx == :sierpinski
        return [s_1, s_2, s_3], [f_A,f_B,f_C]
    end
end

function update_triangle!(H::Hutchinson;
                          A::Union{Vector,Tuple,FractalInput,Nothing}=nothing,
                          B::Union{Vector,Tuple,FractalInput,Nothing}=nothing,
                          C::Union{Vector,Tuple,FractalInput,Nothing}=nothing,
                          color::Union{Array, Tuple, Nothing}=nothing)

    if A != nothing
        if isa(A, FractalInput)
            H.fi_set[1] = A
        else
            H.fi_set[1] = FractalInput(H.fi_set[3].index,
                                       H.fi_set[3].name,
                                       Tuple(A))
        end
    end

    if B != nothing
        if isa(B, FractalInput)
            H.fi_set[1] = B
        else
            H.fi_set[1] = FractalInput(H.fi_set[3].index,
                                       H.fi_set[3].name,
                                       Tuple(B))
        end
    end

    if C != nothing
        if isa(C, FractalInput)
            H.fi_set[1] = C
        else
            H.fi_set[1] = FractalInput(H.fi_set[3].index,
                                       H.fi_set[3].name,
                                       Tuple(C))
        end
    end

    H.symbols = configure_fis!(H.fi_set)
    if color != nothing
        H.color_set = new_color_array(color)
    end

end
