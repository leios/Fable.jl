export FractalOperator, @fo

struct FractalOperator
    op::FractalUserMethod
    color::FractalUserMethod
    prob::Number
end

FractalOperator() = FractalOperator(FractalUserMethod(), FractalUserMethod(), 0)

FractalOperator(f::FractalUserMethod) = FractalOperator(f,
                                                        Colors.previous,
                                                        1)
FractalUserMethod(f::FractalOperator) = f.op

# Note: this operator currently works like this:
#       f = @fo function f(x) x+1 end
#       There should be a way to define f in this macro, so we don't need to
#       say `f = @fo function ...`, but instead just `@fo function ...`
macro fo(ex...)

    expr = ex[end]
    kwargs = nothing

    # defining color and probability information
    if length(ex) > 1
        kwargs = ex[1:end-1]
    end

    color = FractalUserMethod()
    prob = 0

    # parsing kwarg symbols
    for i = 1:length(ex)-1
        if isa(kwargs[i], Symbol)
            error("FractalOperator kwarg require = sign! Cannot define: \n"*
                  string(kwargs[i]))
        elseif kwargs[i].head == :(=)
            if(kwargs[i].args[1] == :color)
                # Note: I don't like this eval, but don't know how to remove it
                color = eval(kwargs[i].args[2])
                if isa(color, Vector) || isa(color, Tuple)
                    if length(color) < 3 || length(color) > 4
                        error("Colors must have 3 or 4 elements!")
                    elseif length(color) == 3
                        color = Colors.custom(red = color[1], green = color[2],
                                              blue = color[3], alpha = 1)
                    elseif length(color) == 4
                        color = Colors.custom(red = color[1], green = color[2],
                                              blue = color[3], alpha = color[4])
                    end
                elseif isa(color, RGB)
                    color = Colors.custom(red = color.r, green = color.g,
                                          blue = color.b, alpha = 1)
                elseif isa(color, RGBA)
                    color = Colors.custom(red = color.r, green = color.g,
                                          blue = color.b, alpha = color.alpha)
                end
            elseif(kwargs[i].args[1] == :prob)
                prob = kwargs[i].args[2]
            else
                error("FractalOperators only accept color and prob kwargs! "*
                      "Cannot define:\n"*
                      string(kwargs[i]))
            end
        else
            error("FractalOperator kwargs require = sign! Cannot define: \n"*
                  string(kwargs[i]))
        end
    end

    fum_ex = quote
        @fum $expr
    end

    return FractalOperator(eval(fum_ex), color, prob)
end

macro fractal_operator(expr)
    :(@fo($(esc(expr))))
end

function find_fo(arg::Symbol, fos::Vector{FractalOperator})
    for i = 1:length(fos)
        if arg == fos[i].name
            return fos[i]
        end
    end

    error("Symbol ", arg, " not defined!")
end

# This splats all kwargs into a block above each inlined fo
# note: this only accepts simple expressions for now (p = a), not (p = 10*a)
function create_header(fo::FractalOperator)
    create_header(fo.op)

end

function configure_fo(fo::FractalOperator, fis::Vector{FractalInput})

    fx_string = "function "*string(fo.name)*"_finale(p, tid, symbols, choice)\n"
    fx_string *= "x = p[tid, 2] \n y = p[tid, 1]"

    for i = 1:length(fis)
        fx_string *= fis[i].name *" = symbols["*string(fis[i].index)*"]\n"
    end

    fx_string *= create_header(fo) * string(fo.body)*"\n"
    fx_string *= "p[tid, 2] = x \n p[tid, 1] = y \n"
    fx_string *= "end"

    F = Meta.parse(replace(fx_string, "'" => '"'))

    println(F)

    return eval(F)
end

# We single out the prob and color kwarg
function (a::Fae.FractalOperator)(args...; kwargs...)
    color = a.color
    prob = a.prob

    for kwarg in kwargs
        for i = 1:length(a.op.kwargs)
            if string(kwarg[1]) == "color"
                color = create_color(kwarg[2])
            elseif string(kwarg[1]) == "prob"
                prob = kwarg[2]
            end
        end
    end

    fum = a.op(args...;kwargs...)

    return FractalOperator(fum, color, prob)
end

