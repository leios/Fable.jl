export FractalUserMethod, @fum

struct FractalUserMethod
    name::Symbol
    args::Vector{Any}
    kwargs::Vector{Any}
    body::Union{Expr, Number, Symbol}
end

FractalUserMethod() = FractalUserMethod(:temp, [], [], 0)

# Note: this operator currently works like this:
#       f = @fum function f(x) x+1 end
#       There should be a way to define f in this macro, so we don't need to
#       say `f = @fum function ...`, but instead just `@fum function ...`
macro fum(ex...)

    expr = ex[end]
    kwargs = nothing

    if isa(expr, Symbol)
        error("Cannot convert Symbol to Fractal Operator!")
    elseif expr.head == :(=)
        # inline function definitions
        if isa(expr.args[1], Expr)
            def = MacroTools.splitdef(expr)
            name = def[:name]
            args = def[:args]
            kwargs = def[:kwargs]
            return FractalUserMethod(name,args,kwargs,expr.args[2])
        # inline symbol definitions
        elseif isa(expr.args[1], Symbol)
            error("Cannot create Fractal Operator (@fum)! "*
                  "Maybe try Fractal Input (@fi)?")
        end
    elseif expr.head == :function
        def = MacroTools.splitdef(expr)
        name = def[:name]
        args = def[:args]
        kwargs = def[:kwargs]
        return FractalUserMethod(name,args,kwargs,expr.args[2])
    else
        error("Cannot convert expr to Fractal Operator!")
    end
end

macro fractal_user_method(expr)
    :(@fum($(esc(expr))))
end

function find_fum(arg::Symbol, fums::Vector{FractalUserMethod})
    for i = 1:length(fums)
        if arg == fums[i].name
            return fums[i]
        end
    end

    error("Symbol ", arg, " not defined!")
end

# This splats all kwargs into a block above each inlined fum
# note: this only accepts simple expressions for now (p = a), not (p = 10*a)
function create_header(fum::FractalUserMethod)

    # Creating string to Meta.parse
    parse_string = ""

    for i = 1:length(fum.kwargs)
        val = fum.kwargs[i].args[end]
        parse_string *= string(fum.kwargs[i].args[end-1]) *" = "* 
                        string(val) *"\n"
    end

    return parse_string

end

function configure_fum(fum::FractalUserMethod, fis::Vector{FractalInput})

    fx_string = "function "*string(fum.name)*"_finale(p, tid, symbols, fid)\n"
    fx_string *= "x = p[tid, 2] \n y = p[tid, 1]"

    for i = 1:length(fis)
        fx_string *= fis[i].name *" = symbols["*string(fis[i].index)*"]\n"
    end

    fx_string *= create_header(fum) * string(fum.body)*"\n"
    fx_string *= "p[tid, 2] = x \n p[tid, 1] = y \n"
    fx_string *= "end"

    F = Meta.parse(replace(fx_string, "'" => '"'))

    println(F)

    return eval(F)
end

function (a::Fae.FractalUserMethod)(args...; kwargs...)
    new_kwargs = deepcopy(a.kwargs)
    for kwarg in kwargs
        for i = 1:length(a.kwargs)
            # a.kwargs[i].args[end-1] is the rhs of the fum kwarg
            if string(kwarg[1]) == string(a.kwargs[i].args[end-1])
                if isa(kwarg[2], FractalInput)
                    if isa(kwarg[2].val, Number) || kwarg[2].index == 0
                        new_kwargs[i] = Meta.parse(string(kwarg[1]) *"="*
                                                   string(kwarg[2].name))
                    else
                        new_kwargs[i] = Meta.parse(string(kwarg[1]) *"="*
                                                   string(kwarg[2].name) *"["*
                                                   string(kwarg[2].index) *"]")
                    end
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

    return FractalUserMethod(a.name, a.args, new_kwargs, a.body)
end

