function remove_vectors(a)
    return a
end

function remove_vectors(a::Vector)
    return Tuple(a)
end

