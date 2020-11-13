function affine(A, p::Point)
    loc = A*[p.x, p.y, 1]
    return Point(loc[1], loc[2], p.c)
end
