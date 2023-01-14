export FractalUserMethod, @fum, configure_fum, overlay, mix

struct FractalUserMethod
    name::Symbol
    args::Vector{Any}
    kwargs::Vector{Any}
    body::Union{Expr, Number, Symbol}
end

FractalUserMethod() = FractalUserMethod(:temp, [], [], 0)
Base.length(FractalUserMethod) = 1

# Note: this operator currently works like this:
#       f = @fum function f(x) x+1 end
#       There should be a way to define f in this macro, so we don't need to
#       say `f = @fum function ...`, but instead just `@fum function ...`
macro fum(ex...)

    expr = ex[end]
    kwargs = nothing

    if isa(expr, Symbol)
        error("Cannot convert Symbol to Fractal User Method!")
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
            error("Cannot create Fractal User Method (@fum)! "*
                  "Maybe try Fractal Input (@fi)?")
        end
    elseif expr.head == :function
        def = MacroTools.splitdef(expr)
        name = def[:name]
        args = def[:args]
        kwargs = def[:kwargs]
        return FractalUserMethod(name,args,kwargs,expr.args[2])
    else
        error("Cannot convert expr to Fractal User Method!")
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

function find_fis(fum::FractalUserMethod, fis::Vector{FractalInput})
    fi_indices = zeros(Int, length(fis))
    current_fi = 1
    for i = 1:length(fis)
        for arg in fum.args
            if fis[i].name == string(arg)
                fi_indices[i] = i
                current_fi += 1
            end
        end
        for kwarg in fum.kwargs
            if fis[i].name == string(kwarg.args[1])
                fi_indices[i] = i
                current_fi += 1
            end
        end
    end
    return fi_indices[1:current_fi-1]
end

function configure_fum(fum::FractalUserMethod; name = "0", diagnostic = false,
                       fum_type = :color)
    configure_fum(fum, [FractalInput()]; name = name, diagnostic = diagnostic,
                  fum_type = fum_type)
end

function configure_fum(fum::FractalUserMethod, fis::Vector{FractalInput};
                       name = "0", fum_type = :color, diagnostic = false)

    used_fis = find_fis(fum, fis)
    if fum_type == :color
        fx_string = "function "*string(fum.name)*"_"*
                    name*"(_clr, _p, tid, symbols)\n"
    elseif fum_type == :shader
        fx_string = "function "*string(fum.name)*"_"*name*
                    "(_clr,y,x,tid,symbols)\n"
    elseif fum_type == :hutchinson
        fx_string = "function "*string(fum.name)*"_"*name*"(_p,tid,symbols)\n"
    else
        error("FUM type "*string(fum_type)*" not available!")
    end

    if fum_type == :hutchinson
        fx_string *= "x = _p[tid, 2] \n"
        fx_string *= "y = _p[tid, 1] \n"
    end

    if fum_type == :color || fum_type == :shader
        fx_string *= "red = _clr[tid, 1] \n"
        fx_string *= "green = _clr[tid, 2] \n"
        fx_string *= "blue = _clr[tid, 3] \n"
        fx_string *= "alpha = _clr[tid, 4] \n"
    end

    #println(used_fis, '\n', fis)
    for i = used_fis
        if fis[i].index != 0
            fx_string *= fis[i].name *" = symbols["*string(fis[i].index)*"]\n"
        end
    end

    fx_string *= create_header(fum) * string(fum.body)*"\n"
    if fum_type == :color || fum_type == :shader
        fx_string *= "_clr[tid, 1] = red \n"
        fx_string *= "_clr[tid, 2] = green \n"
        fx_string *= "_clr[tid, 3] = blue \n"
        fx_string *= "_clr[tid, 4] = alpha \n"
    end
    fx_string *= "end"

    F = Meta.parse(replace(fx_string, "'" => '"'))

    if diagnostic
        println(F)
    end

    return eval(F)
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

function overlay(a::FractalUserMethod, b::FractalUserMethod; fum_type = :color)
    new_args = vcat(a.args, b.args)
    new_kwargs = vcat(a.kwargs, b.kwargs)
    new_name = Meta.parse(string(a.name)*"_"*string(b.name))
    new_body = string(b.body)[1:end-3]
    if fum_type == :color || fum_type == :shader
        new_body *= "
            _clr[tid, 1] = red*alpha + (1-alpha)*_clr[tid, 1]\n
            _clr[tid, 2] = green*alpha + (1-alpha)*_clr[tid, 2]\n
            _clr[tid, 3] = blue*alpha + (1-alpha)*_clr[tid, 3]\n
            _clr[tid, 4] = max(alpha, _clr[tid, 4])\n"*
            string(a.body)[1+5:end]
    elseif fum_type == :hutchinson
        new_body *= string(a.body)[1+5:end]
    end

    return FractalUserMethod(new_name, new_args, new_kwargs,
                             Meta.parse(new_body))
end

function mix(a::FractalUserMethod, b::FractalUserMethod; fum_type = :color)
    new_args = vcat(a.args, b.args)
    new_kwargs = vcat(a.kwargs, b.kwargs)
    new_name = Meta.parse(string(a.name)*"_"*string(b.name))
    new_body = string(b.body)[1:end-3]
    if fum_type == :color || fum_type == :shader
        new_body *= "
            _clr[tid, 1] = red*0.5 + _clr[tid, 1]*0.5\n
            _clr[tid, 2] = green*0.5 + _clr[tid, 2]*0.5\n
            _clr[tid, 3] = blue*0.5 + _clr[tid, 3]*0.5\n
            _clr[tid, 4] = max(alpha, _clr[tid, 4])\n"*
            string(a.body)[1+5:end]
    elseif fum_type == :hutchinson
        new_body *= string(a.body)[1+5:end]
    end

    return FractalUserMethod(new_name, new_args, new_kwargs,
                             Meta.parse(new_body))

end

function mix(fums::Vector{FractalUserMethod}; fum_type = :color,
             alphas::Union{Nothing, Vector{N}} = nothing) where N <: Number

    if fum_type == :color || fum_type == :shader
        if length(fums) != length(alphas)
            @warn(string(length(fums))*" FUMs provided with only "*
                  string(length(alphas))*" alpha values!\n" *
                  "Mixing all colors evenly...")
            alphas = [1/length(fums) for i = 1:length(fums)]
        end

        if !isapprox(sum(alphas),1)
            @warn("Mixed FUM alpha values != 1!\n"*
                  "Mixing all colors evenly...")
            alphas = [1/length(fums) for i = 1:length(fums)]
        end
    end

    if length(fums) == 1
        return fums[1]
    end

    new_args = fums[1].args
    new_kwargs = fums[1].kwargs
    new_name = fums[1].name
    new_body = string(fums[1].body)[1:end-3]
    if fum_type == :color || fum_type == :shader
        new_body *="
            _clr[tid, 1] = red*"*string(alphas[1])*"\n
            _clr[tid, 2] = green*"*string(alphas[1])*"\n
            _clr[tid, 3] = blue*"*string(alphas[1])*"\n
            _clr[tid, 4] = "*string(alphas[1])*"\n"
    end

    for i = 2:length(fums)
        new_args = vcat(new_args, fums[i].args)
        new_kwargs = vcat(new_kwargs, fums[i].kwargs)
        new_name = Meta.parse(string(new_name)*"_"*string(fums[i].name))
        if fum_type == :color || fum_type == :shader
            new_body *= string(fums[2].body)[1+5:end-3]*"
                _clr[tid, 1] += red*"*string(alphas[i])*"\n
                _clr[tid, 2] += green*"*string(alphas[i])*"\n
                _clr[tid, 3] += blue*"*string(alphas[i])*"\n
                _clr[tid, 4] += "*string(alphas[i])*"\n"
        elseif fum_type == :hutchinson
            new_body *= string(fums[2].body)[1+5:end]
        end
    end

    if fum_type == :color || fum_type == :shader
        new_body *= "
            red = _clr[tid, 1]
            green = _clr[tid, 2]
            blue = _clr[tid, 3]
            alpha = _clr[tid, 4]
            end\n"
    end

    return FractalUserMethod(new_name, new_args, new_kwargs,
                             Meta.parse(new_body))

end
