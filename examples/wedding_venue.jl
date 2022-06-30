using Fae, CUDA
using Fae: Colors
using Images

function create_sky!(pix, num_particles, num_iterations;
                     AT = Array, FT = Float32,
                     bounds = [-1.125 1.125; -2 2], res = (1080, 1920))
    sky_color = @fum function sky_color(; bound = 1.125)
        red = 1/exp(6*abs(y/bound))
        green = 1/exp(4*abs(y/bound))
        blue = 1/exp(abs(y/bound))
        alpha = 1
    end

    pos = [bounds[1]*0.5, 0.0]
    rotation = 0.0
    scale_x = (bounds[2,2] - bounds[2,1])
    scale_y = (bounds[1,2] - bounds[1,1])*0.5

    skybox = Fae.define_rectangle(pos, rotation, scale_x, scale_y, sky_color;
                                  AT = AT, name = "sky")
    fractal_flame!(pix, skybox,
                   num_particles, num_iterations, bounds, res;
                   AT = AT, FT = FT)
end

function create_grass!(pix, num_particles, num_iterations;
                       AT = Array, FT = Float32,
                       bounds = [-1.125 1.125; -2 2], res = (1080, 1920))
    pos = [-bounds[1]*0.5, 0.0]
    rotation = 0.0
    scale_x = (bounds[2,2] - bounds[2,1])
    scale_y = (bounds[1,2] - bounds[1,1])*0.5

    grass_color = (0, 0.5, 0)

    grassbox = Fae.define_rectangle(pos, rotation, scale_x, scale_y,
                                    grass_color; AT = AT, name = "grass")
    fractal_flame!(pix, grassbox,
                   num_particles, num_iterations, bounds, res;
                   AT = AT, FT = FT)

end

function create_clouds!(pix, num_particles, num_iterations;
                        AT = Array, FT = Float32,
                        bounds = [-1.125 1.125; -2 2], res = (1080, 1920))
    H = Fae.define_circle([0.0,0], 1.0, [1,1,1,1]; AT = AT)
    H2 = fee([Flames.cloud],
             [Fae.Colors.previous],
             (1,); name = "clouds_2", final = true)

    H3 = fee([Flames.scale_and_translate(scale = (0.3, 0.3),
                                         translation = (-0.6, 0.8)),
              Flames.scale_and_translate(scale = (0.3, 0.3), 
                                         translation = (-0.4, -0.8))],
              [Fae.Colors.previous, Fae.Colors.previous],
              (0.5, 0.5); name = "clouds_3", final = true)

    H_final = fee([H2, H3]; final = true)

    println(H_final.fnums)

    fractal_flame!(pix, H, H_final,  
                   num_particles, num_iterations, bounds, res;
                   AT = AT, FT = FT)

end

function create_aisle!(pix, num_particles, num_iterations;
                       AT = Array, FT = Float32,
                       bounds = [-1.125 1.125; -2 2], res = (1080, 1920))
    pos = [-bounds[1]*0.6, 0.0]
    rotation = 0.0
    scale_x = 0.1*(bounds[2,2] - bounds[2,1])
    scale_y = (bounds[1,2] - bounds[1,1])*0.4

    aisle_color = (1,1,1)
    bench_color = (0.7-1, 0.35-1, 0.1-1)

    aislebox = Fae.define_rectangle(pos, rotation, scale_x, scale_y,
                                    aisle_color; AT = AT, name = "aisle")
    H2 = fee([Flames.perspective(theta = 0.25*pi, dist = 1),
              Flames.scale_and_translate(scale = (0.3, 5),
                                         translation = (0.4, -1.75)),
              Flames.scale_and_translate(scale = (0.3, 5),
                                         translation = (0.4, 1.75))],
             [Fae.Colors.previous, bench_color, bench_color],
             (1/3, 1/3, 1/3); name = "aisle_perspective", final = true)

    fractal_flame!(pix, aislebox, H2,
                   num_particles, num_iterations, bounds, res;
                   AT = AT, FT = FT)

end

function main(num_particles, num_iterations; AT = Array, FT = Float32)

    res = (1080, 1920)

    #sky_pix = Pixels(res; AT = AT, FT = FT, logscale = false)
    #create_sky!(sky_pix, num_particles, num_iterations; AT = AT)

    #grass_pix = Pixels(res; AT = AT, FT = FT, logscale = false)
    #create_grass!(grass_pix, num_particles, num_iterations; AT = AT)

    #cloud_pix = Pixels(res; AT = AT, FT = FT, logscale = true)
    #create_clouds!(cloud_pix, num_particles, num_iterations; AT = AT)

    aisle_pix = Pixels(res; AT = AT, FT = FT, logscale = false)
    create_aisle!(aisle_pix, num_particles, num_iterations; AT = AT)

    filename = "check.png"

    #bg_img = fill(RGB(0.5, 0.5, 0.5), res)
    bg_img = fill(RGB(0, 0, 0), res)

    println("Time to write to image:")
    @time Fae.write_image([aisle_pix], filename; img = bg_img)
    #@time Fae.write_image([sky_pix, grass_pix, cloud_pix, aisle_pix],
    #                      filename; img = bg_img)
end
