struct FractalOperator
    name::Symbol
    args::Vector{Any}
    kwargs::Vector{Any}
    body::Union{Expr, Number, Symbol}
end

# Note: this operator currently works like this:
#       f = @fo function f(x) x+1 end
#       There should be a way to define f in this macro, so we don't need to
#       say `f = @fo function ...`, but instead just `@fo function ...`
macro fo(expr)

    if isa(expr, Symbol)
        error("Cannot convert Symbol to Fractal Operator!")
    elseif expr.head == :(=)
        # inline function definitions
        if isa(expr.args[1], Expr)
            def = MacroTools.splitdef(expr)
            name = def[:name]
            args = def[:args]
            kwargs = def[:kwargs]
            return FractalOperator(name,args,kwargs,expr.args[2])
        # inline symbol definitions
        elseif isa(expr.args[1], Symbol)
            error("Cannot create Fractal Operator (@fo)! "*
                  "Maybe try Fractal Input (@fi)?")
        end
    elseif expr.head == :function
        def = MacroTools.splitdef(expr)
        name = def[:name]
        args = def[:args]
        kwargs = def[:kwargs]
        return FractalOperator(name,args,kwargs,expr.args[2])
    else
        error("Cannot convert expr to Fractal Operator!")
    end
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

    # Creating string to Meta.parse
    parse_string = ""

    for i = 1:length(fo.kwargs)
        val = fo.kwargs[i].args[end]
        parse_string *= string(fo.kwargs[i].args[end-1]) *" = "* 
                        string(val) *"\n"
    end

    return parse_string

end

function configure_fo(fo::FractalOperator, fis::Vector{FractalInput})

    fx_string = "function "*string(fo.name)*"_finale(p, tid, symbols)\n"
    fx_string *= "x = p[tid, 2] \n y = p[tid, 1]"

    for i = 1:length(fis)
        fx_string *= fis[i].name *" = symbols["*string(fis[i].index)*"]\n"
    end

    fx_string *= create_header(fo) * string(fo.body)*"\n"
    fx_string *= "p[tid, 2] = x \n p[tid, 1] = y \n"
    fx_string *= "end"

    F = Meta.parse(replace(fx_string, "'" => '"'))

    #println(fx_string)
    println(F)

    return eval(F)
end

function (a::Fae.FractalOperator)(args...; kwargs...)
    new_kwargs = deepcopy(a.kwargs)
    for kwarg in kwargs
        for i = 1:length(a.kwargs)
            if string(kwarg[1]) == string(a.kwargs[i].args[end-1])
                if isa(kwarg[2], FractalInput)
                    new_kwargs[i] = Meta.parse(string(kwarg[1]) *"="*
                                               string(kwarg[2].name))
                elseif isa(kwarg[2], Array)
                    error("Cannot create new kwarg array! "*
                          "Please use Tuple syntax ()!")
                else
                    new_kwargs[i] = Meta.parse(string(kwarg[1]) *"="*
                                               string(kwarg[2]))
                end
            end
        end
    end

    return FractalOperator(a.name, a.args, new_kwargs, a.body)
end

