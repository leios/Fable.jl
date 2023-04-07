export FractalUserMethod, @fum

struct FractalUserMethod{NT <: NamedTuple,
                         V <: Vector{FractalInput},
                         F <: Function}
    kwargs::NT
    fis::V
    fx::F
end

args(a,n) = a.args[n]

function __set_args(args, config)
    if config == :fractal
        correct_args = [:y, :x, :frame]
    elseif config == :shader
        correct_args = [:y, :x, :color, :frame]
    end
    if !issubset(args, correct_args)
        error("Function arguments must be one of the following:\n"*
              string(correct_args)*"\n"*
              "Please use key-word arguments for any additional arguments!")
    end
    return correct_args
end

# this function can create a NamedTuple from kwargs in a macro, ie:
# kwargs = __to_NamedTuple(def[:kwargs])
# It is not currently used, but took a while to find out, so I'm leaving it
# here for debugging purposes
#function __to_NamedTuple(kwargs)
#    NamedTuple{Tuple(args.(kwargs[:],1))}(Tuple(args.(kwargs[:],2)))
#end

function __define_fum_stuff(expr, config)
    def = MacroTools.splitdef(expr)
    def[:name] = name = Symbol(def[:name], :_fum)
    used_args = def[:args]
    args = __set_args(used_args, config)
    def[:args] = args
    kwargs = NamedTuple()
    fum_fx = combinedef(def)
    return kwargs, eval(fum_fx)
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
            kwargs, fum_fx = __define_fum_stuff(expr, config)
        else
            error("Cannot create FractalUserMethod.\n"*
                  "Input is not a valid function definition!")
        end
    elseif expr.head == :function
        kwargs, fum_fx = __define_fum_stuff(expr, config)
    else
        error("Cannot convert expr to Fractal User Method!")
    end
    return FractalUserMethod(kwargs,FractalInput[], fum_fx)
end


function (a::FractalUserMethod)(args...; kwargs...)

    # we do not reason about standard args right now, although this could
    # be considered in the future if we ensure users always configure their
    # fums beforehand. We could then save the args and such in each fum and
    # assign them to a value that is passed in to the compute kernels.
    if length(args) > 0
        @warn("function arguments cannot be set at"*
              " this time and will be ignored!\n"*
              "Please use appropriate key-word arguments instead!")
    end

    # checking to make sure the symbols are assignable in the first place
    error_flag = false

    # Note: grabs all keywords from the a.fx. If multiple definitions exist,
    # it takes the first one. It might mistakenly grab the wrong function.
    # If this happens, we need to reason about how to pick the right function
    # when two exist with the same name, but different kwargs...
    known_kwargs = Base.kwarg_decl.(methods(a.fx))[1]

    final_kwarg_idxs = Int[]
    final_fi_idxs = Int[]

    ks = keys(kwargs)
    vals = values(NamedTuple(kwargs))
    for i = 1:length(ks)
        if !in(ks[i], known_kwargs)
            @warn(string(key)*" not found in set of fum key-word args!")
            error_flag = true
        end

        if isa(vals[i], FractalInput)
            push!(final_fi_idxs, i)
        else
            push!(final_kwarg_idxs, i)
        end
    end

    if error_flag
        error("one or more keys not found in set of fum key-word args!\n"*
              "Maybe consider creating a new fum function with the right "*
              "key-word arguments?")
    end

    fis = [FractalInput(ks[i], vals[i].x) for i in final_fi_idxs]

    ks = Tuple(ks[final_kwarg_idxs])
    vals = Tuple(remove_vectors.(vals[final_kwarg_idxs]))

    final_kwargs = NamedTuple{ks}(vals)
    return FractalUserMethod(final_kwargs, fis, a.fx)
end

