export FableUserMethod, @fum

struct FableUserMethod{NT <: NamedTuple,
                         V <: Vector{FableInput},
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

function __define_fum_stuff(expr, config, mod, force_inbounds)
    def = MacroTools.splitdef(expr)
    def[:name] = name = Symbol(def[:name], :_fum)
    used_args = def[:args]
    args = __set_args(used_args, config)
    def[:args] = args
    if force_inbounds
        body_qt = quote
            @inbounds $(def[:body])
        end
        def[:body] = body_qt
    end
    kwargs = NamedTuple()
    fum_fx = combinedef(def)
    return kwargs, Core.eval(mod, fum_fx)
end

# Note: this operator currently works like this:
#       f = @fum function config f(x) x+1 end
#       There should be a way to define f in this macro, so we don't need to
#       say `f = @fum function ...`, but instead just `@fum function ...`
macro fum(ex...)

    config = :fractal
    force_inbounds = false

    if length(ex) == 1
    else
        for i = 1:length(ex)-1
            if ex[i] == :color || ex[i] == :shader ||
               ex[i] == :(:shader) || ex[i] == :(:color)
                config = :shader
            elseif ex[i] isa Expr && ex[i].head == :(=) &&
                ex[i].args[1] == :inbounds && ex[i].args[2] isa Bool
                force_inbounds = ex[i].args[2]
            else
                error("Incorrect config argument ", ex[i], "!")
            end
        end
    end

    expr = ex[end]
    kwargs = nothing

    if isa(expr, Symbol)
        error("Cannot convert Symbol to Fable User Method!")
    elseif expr.head == :(=)
        # inline function definitions
        if isa(expr.args[1], Expr)
            kwargs, fum_fx = __define_fum_stuff(expr, config, __module__,
                                                force_inbounds)
        else
            error("Cannot create FableUserMethod.\n"*
                  "Input is not a valid function definition!")
        end
    elseif expr.head == :function
        kwargs, fum_fx = __define_fum_stuff(expr, config, __module__,
                                            force_inbounds)
    else
        error("Cannot convert expr to Fable User Method!")
    end

    return FableUserMethod(kwargs, FableInput[], fum_fx)
end


function (a::FableUserMethod)(args...; kwargs...)

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

        if isa(vals[i], FableInput)
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

    fis = [FableInput(ks[i], vals[i].x) for i in final_fi_idxs]

    ks = Tuple(ks[final_kwarg_idxs])
    vals = Tuple(remove_vectors.(vals[final_kwarg_idxs]))

    final_kwargs = NamedTuple{ks}(vals)
    return FableUserMethod(final_kwargs, fis, a.fx)
end
