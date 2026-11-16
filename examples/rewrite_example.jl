using Fable

function swirl_square(pix, cam, pt, clr)
    y = pt.y
    x = pt.x
    r = sqrt(y*y + x*x)

    v1 = x*cos(r*r) + y*sin(r*r)
    v2 = x*sin(r*r) - y*cos(r*r)

    y = v1
    x = v2
    pt = Point2D(x, y)
    simple_output(pix, cam, pt, clr)
end

function output_and_scale(pix, cam, pt, clr, x_scale; y_scale = 3)
    pt_2 = Point2D(pt.x*x_scale*x_scale, pt.y*y_scale)

    simple_output(pix, cam, pt_2, clr)
end

@kernel inbounds = true function generate_square(pix, cam, g)
    A = Point2D(-0.5, 0.5)
    B = Point2D(0.5, 0.5)
    C = Point2D(0.5, -0.5)
    D = Point2D(-0.5, -0.5)

    pt = Point2D(0.0,0.0)
    clr = RGBA{Float32}(1,0,1,1)
    square_clr = RGBA{Float32}(1,0,1,1)
    @square 100 A square_clr B square_clr C square_clr D square_clr begin
        output_and_scale(pix, cam, _pt, _clr, 0.5; y_scale = 0.5)
        #swirl_square(pix, cam, _pt, _clr)
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

    world_size = Point2D(world_size_x, world_size_y)
    world_position = Point2D(-world_size.x * 0.5, -world_size.y*0.5)

    cam = SimpleCamera(ppu, world_size, world_position)

    backend = get_backend(pixels)
    kernel! = generate_square(backend, 256)
    #AMDGPU.@device_code_gcn begin
    AMDGPU.@time begin
    kernel!(pixels, cam, output_and_scale; ndrange = width*10)
    synchronize(backend)
    end
    @time save("check.png", Array(pixels))
end
