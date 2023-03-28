export FractalUserMethod, @fum

struct FractalUserMethod
    name::Symbol
    args::Tuple
    kwargs::NamedTuple
    fx::Function
end

args(a,n) = a.args[n]

function __to_NamedTuple(kwargs)
    NamedTuple{Tuple(args.(kwargs[:],1))}(Tuple(args.(kwargs[:],2)))
end

function __define_fum_stuff(expr, config)
    def = MacroTools.splitdef(expr)
    def[:name] = name = Symbol(def[:name], :_fum)
    if config == :fractal
        args = [:y, :x, :frame]
    elseif config == :shader
        args = [:y, :x, :red, :green, :blue, :alpha, :frame]
    end
    used_args = def[:args]
    if !issubset(used_args, args)
        error("Function arguments must be one of the following:\n"*
              string(args)*"\n"*
              "Please use key-word arguments for any additional arguments!")
    end
    def[:args] = args
    kwargs = __to_NamedTuple(def[:kwargs])
    fum_fx = combinedef(def)
    return name, args, kwargs, eval(fum_fx)
end

# Note: this operator currently works like this:
#       f = @fum function config f(x) x+1 end
#       There should be a way to define f in this macro, so we don't need to
#       say `f = @fum function ...`, but instead just `@fum function ...`
macro fum(ex...)

    config = :fractal
    if length(ex) == 1
    elseif length(ex) == 2
        if ex[1] == :color || ex[1] == :shader ||
           ex[1] == :(:shader) || ex[1] == :(:color)
            config = :shader
        end
    else
        error("Improperly formatted function definition!\n"*
              "Too many arguments provided!")
    end

    expr = ex[end]
    kwargs = nothing

    if isa(expr, Symbol)
        error("Cannot convert Symbol to Fractal User Method!")
    elseif expr.head == :(=)
        # inline function definitions
        if isa(expr.args[1], Expr)
            name, args, kwargs, fum_fx = __define_fum_stuff(expr, config)
        else
            error("Cannot create FractalUserMethod.\n"*
                  "Input is not a valid function definition!")
        end
    elseif expr.head == :function
        name, args, kwargs, fum_fx = __define_fum_stuff(expr, config)
    else
        error("Cannot convert expr to Fractal User Method!")
    end
    return FractalUserMethod(name,Tuple(args),kwargs,fum_fx)
end

function (a::Fae.FractalUserMethod)(args...; kwargs...)
    new_kwargs = deepcopy(a.kwargs)
    new_name = string(a.name)
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
            elseif string(kwarg[1]) == "name"
                new_name *= kwarg[2]
            end
        end
    end

    return FractalUserMethod(Symbol(new_name), a.args, new_kwargs, a.body)
end

