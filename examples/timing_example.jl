using Fable

@kernel inbounds = true function generate_sierpinski(pix, cam)
    A = Point2D(-0.5, 0.5)
    B = Point2D(0.5, 0.5)
    C = Point2D(0.5, -0.5)

    pt = Point2D(0.0,0.0)
    @sierpinski 1000000 A B C begin
        simple_output(pix, cam, _pt, _clr)
    end

    return nothing
end

function main(;ArrayType = Array)
    width = 1920
    height = 1080
    pixels = ArrayType(fill(RGBA{Float32}(0,0,0,0),height, width))

    world_size_x::Float32 = 4;
    ppu::Float32 = width / world_size_x;
    world_size_y::Float32 = height/ppu;

    world_size = Point2D(world_size_y, world_size_x)
    world_position = Point2D(-world_size.y*0.5, -world_size.x*0.5)

    cam = SimpleCamera(ppu, world_size, world_position)

    backend = get_backend(pixels)
    kernel! = generate_sierpinski(backend, 256)
    #AMDGPU.@device_code_gcn begin
    AMDGPU.@time begin
    kernel!(pixels, cam; ndrange = width*10)
    synchronize(backend)
    end
    @time save("check.png", Array(pixels))
end
