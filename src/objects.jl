export @square, halfway

function halfway(A::Point2D, B::Point2D)
    return Point2D(0.5*(A.x + B.x), 0.5*(A.y + B.y))
end

# This macro walks through the `begin ... end` block as well as other possible
# expr
function walk_through_expr(ex)
    # This is a base expr call like `f(x)`
    if Meta.isexpr(ex, :call)
        return :(Base.@inline $ex)

    # This is something like `x = 5`
    elseif Meta.isexpr(ex, :(=)) && Meta.isexpr(ex.args[2], :call)
        return Expr(:(=), ex.args[1], :(Base.@inline $(ex.args[2])))

    # This is the full block
    elseif Meta.isexpr(ex, :block)
        return Expr(:block, map(walk_through_expr, ex.args)...)
    else
        return ex
    end

end

macro square(num_iterations, A, c_A, B, c_B, C, c_C, D, c_D, ex)
    # expanding expr now and pasting it later
    Meta.isexpr(ex, (:call, :block, :(=))) ||
        error("@square_macro expects a call or a begin/end block of calls")
    body = walk_through_expr(ex)

    return esc(quote
        _pt  = Point2D(0.0, 0.0)
        _clr = RGBA{Float32}(0, 0, 0, 0)
        for _i = 1:$num_iterations
            chosen_fx = rand(1:4)
            if chosen_fx == 1
                _pt = halfway(_pt, $A);
                _clr = $c_A
            elseif chosen_fx == 2
                _pt = halfway(_pt, $B);
                _clr = $c_B
            elseif chosen_fx == 3
                _pt = halfway(_pt, $C);
                _clr = $c_C
            else
                _pt = halfway(_pt, $D);
                _clr = $c_D
            end
            $body
        end
    end)
end

