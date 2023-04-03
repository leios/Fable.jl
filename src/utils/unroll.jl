
#=
@generated function stupid_loop!(output_val, fxs, args, kwargs, loop_num)
        ex = :(i-> output_val = $fxs[i]($args...;$kwargs[i]...))
        exs = quote
            exs = Any[Base.Cartesian.inlineanonymous(ex, i) for i = 1:loop_num]
        end
        expr = Expr(:block, exs...)
end
=#
@generated function stupid_loop!(output_val, fxs, args, kwargs)
    exs = Expr[]
    for i = 1:length(fxs.parameters)
        ex = :(output_val = fxs[$i](args...; kwargs[$i]...))
        push!(exs, ex)
    end
    #@async println(exs)
    #ex = :(i-> output_val = $fxs[i]($args...;$kwargs[i]...))
    #exs = Any[Base.Cartesian.inlineanonymous(ex, i) for i = 1:fxs.]
    #return Expr(:tuple, exs)
    return :(Expr(:block, $exs...))

    whatever = Expr(:block, exs...)
    @async dump(whatever)
    return whatever
end

copy_and_substitute_tree(e, varname, newtext, mod) = e

copy_and_substitute_tree(e::Symbol, varname, newtext, mod) =
    e == varname ? newtext : e

function copy_and_substitute_tree(e::Expr, varname, newtext, mod)
    e2 = Expr(e.head)
    for subexp in e.args
        push!(e2.args, copy_and_substitute_tree(subexp, varname, newtext, mod))
    end
    if e.head == :if
        newe = e2
        try
            u = Core.eval(mod, e2.args[1])
            if u == true
                newe = e2.args[2]
            elseif u == false
                if length(e2.args) == 3
                    newe = e2.args[3]
                else
                    newe = :nothing
                end
            end
        catch
        end
        e2 = newe
    end
    e2 
end

macro nexprs(N, ex::Expr)
    val = Core.eval(__module__, N)
    exs = Any[Base.Cartesian.inlineanonymous(ex,i) for i = 1:val]
    Expr(:escape, Expr(:block, exs...))
#=
    quote
        #exs = Any[Base.Cartesian.inlineanonymous($ex,i) for i = 1:$N]
        #Expr(:block, exs...)
    end
=#
end

#macro nexprs(N, ex::Expr)
#    exs = Any[Base.Cartesian.inlineanonymous(ex,i) for i = 1:eval(N)]
#    Expr(:escape, Expr(:block, exs...))
#end

macro fae_unroll(expr)
    if expr.head != :for ||
       length(expr.args) != 2 ||
       expr.args[1].head != :(=) || 
       typeof(expr.args[1].args[1]) != Symbol ||
       expr.args[2].head != :block
        error("Expression following fae_unroll macro must be a for-loop!")
    end
    #esc(println(Core.eval(__module__, expr.args[1].args[2])))
    varname = expr.args[1].args[1]
    ret = Expr(:block)
    for k in Core.eval(__module__, expr.args[1].args[2])
        e2 = copy_and_substitute_tree(expr.args[2], varname, k, __module__)
        #e2 = Base.Cartesian.inlineanonymous(expr.args[2].args[k], k)
        push!(ret.args, e2)
    end
    esc(ret)
end

