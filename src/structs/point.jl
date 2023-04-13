export point, generate_points, generate_points, absum, dims

# Might need the following interface for GPU compatability:
# Can otherwise use NamedTuples:
# point(x) = (x=x,)
# point(x, y) = (x=x, y=y)
# point(x, y, z) = (x=x, y=y, z=z)
# point(x, y, z, w) = (x=x, y=y, z=z, w=w)

abstract type AbstractPoint end

struct Point1D{N} <: AbstractPoint
    y::N
end

struct Point2D{N} <: AbstractPoint
    y::N
    x::N
end

struct Point3D{N} <: AbstractPoint
    y::N
    x::N
    z::N
end

struct Point4D{N} <: AbstractPoint
    y::N
    x::N
    z::N
    w::N
end

point(x) = Point1D(x)
point(x, y) = Point2D(x, y)
point(x, y, z) = Point3D(x, y, z)
point(x, y, z, w) = Point4D(x, y, z, w)

absum(pt::Point1D) = abs(pt.y)
absum(pt::Point2D) = abs(pt.y) + abs(pt.x)
absum(pt::Point3D) = abs(pt.y) + abs(pt.x) + abs(pt.z)
absum(pt::Point4D) = abs(pt.y) + abs(pt.x) + abs(pt.z) + abs(pt.w)

dims(pt::Point1D) = 1
dims(pt::Point2D) = 2
dims(pt::Point3D) = 3
dims(pt::Point4D) = 4

function generate_point(; dims=2, bounds = find_bounds((0,0), (2,2)))
    return point([rand() * (bounds[i*2] - bounds[i*2-1]) +
                  bounds[i*2-1] for i=1:dims]...)
end

function generate_points(N::Int; ArrayType=Array, dims=2,
                         bounds=find_bounds((0,0), (2,2)))
    return ArrayType([generate_point(dims = dims, bounds = bounds) for i = 1:N])
end
