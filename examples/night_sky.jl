using Fae, CUDA
using Fae: Colors

function create_sky!(pix, num_particles, num_iterations, reflect_operation;
                     AT = Array, FT = Float32,
                     bounds = [-1.125 1.125; -2 2], res = (1080, 1920))
    sky_color = @fum function sky_color(; bound = 1.125)
        red = 1/exp(10*abs(y/bound))
        green = 1/exp(10*abs(y/bound))
        blue = 1/exp(5*abs(y/bound))
        #red = abs(0.1 + 0.1*(y/bound))%1
        #green = abs(0.1 + 0.1*(y/bound))%1
        #blue = abs(0.5 + 0.5*(y/bound))%1
        alpha = 1
    end

    pos = [bounds[1]*0.5, 0.0]
    rotation = 0.0
    scale_x = (bounds[2,2] - bounds[2,1])
    scale_y = (bounds[1,2] - bounds[1,1])*0.5

    skybox = Fae.define_rectangle(pos, rotation, scale_x, scale_y, sky_color;
                                  AT = AT, name = "sky")
    fractal_flame!(pix, skybox, reflect_operation,
                   num_particles, num_iterations, bounds, res;
                   AT = AT, FT = FT)
end

function create_stars!(pix, num_stars, num_iterations, reflect_operation;
                     AT = Array, FT = Float32,
                     bounds = [-1.125 1.125; -2 2], res = (1080, 1920))

    pos = [bounds[1]*0.5, 0.0]
    rotation = 0.0
    scale_x = (bounds[2,2] - bounds[2,1])
    scale_y = (bounds[1,2] - bounds[1,1])*0.5

    skybox = Fae.define_rectangle(pos, rotation, scale_x, scale_y, (1,1,1,1);
                                  AT = AT, name = "stars")
    fractal_flame!(pix, skybox, reflect_operation,
                   num_stars, num_iterations, bounds, res;
                   AT = AT, FT = FT)

end

function create_moon!(pix, num_particles, num_iterations, reflect_operation;
                     AT = Array, FT = Float32,
                     bounds = [-1.125 1.125; -2 2], res = (1080, 1920))

    moon_color = @fum function sky_color(; bound = 1.125)
        red = abs(-0.75*(y/bound))%1
        green = abs(-0.75*(y/bound))%1
        blue = abs(-(y/bound))%1
        alpha = 1
    end

    pos = [bounds[1]*0.6, bounds[2,1]*0.5]
    radius = 0.4

    moon = define_circle(pos, radius, moon_color; AT = AT, name = "moon")
    fractal_flame!(pix, moon, reflect_operation,
                   num_particles, num_iterations, bounds, res;
                   AT = AT, FT = FT)

end

scale_and_translate = @fo function scale_and_translate(x, y;
                                                       translation = (0,0),
                                                       scale_y = 1,
                                                       scale_x = 1)
    x = scale_x*x + translation[2]
    y = scale_y*y + translation[1]
end

function create_forest!(pix, num_trees, num_particles, num_iterations,
                        reflect_operation; AT = Array, FT = Float32,
                        bounds = [-1.125 1.125; -2 2], res = (1080, 1920))

    tree_black = @fum function tree_black()
        red = 0
        green = 0
        blue = 0
        alpha = 1
    end

    tree = define_barnsley(create_color((0.0, 0.0, 0.0, 0.0));
                           AT = AT, name = "moon", tilt = -0.04)

    max_range = bounds[2,2] - bounds[2,1]
    max_scale = (bounds[1,2] - bounds[1,1])*0.5*0.1

    positions_x = rand(num_trees) .* (max_range) .+ bounds[2,1]
    println(positions_x)
    scales = [0.05 + max_scale * abs(sin(positions_x[i]/(max_range*0.5)))
              for i = 1:num_trees]
    positions_y = [scales[i]+0.05 for i = 1:num_trees]

    fos = [scale_and_translate(prob = 1/num_trees, color = tree_black,
                               translation = (positions_y[i], positions_x[i]),
                               scale_x = scales[i],
                               scale_y = -scales[i]) for i = 1:num_trees]
    tree_2 = fee(fos; name = "tree_2", final = true)


    fractal_flame!(pix, tree, (tree_2, reflect_operation),
                   num_particles, num_iterations,
                   bounds, res; AT = AT, FT = FT)


end

function main(num_particles, num_iterations; AT = Array, FT = Float32)

    fo_1 = scale_and_translate(prob = 0.5, color = Colors.previous,
                               translation = (0, 0), scale_y = -1)
    fo_2 = FractalOperator(Flames.identity, Colors.previous, 0.5)
    reflect_operation = fee([fo_1, fo_2]; name = "reflect", final = true)

    sky_pix = Pixels((1080,1920); AT = AT, FT = FT, logscale = false)
    create_sky!(sky_pix, num_particles, num_iterations, reflect_operation;
                AT = AT)

    star_pix = Pixels((1080,1920); AT = AT, FT = FT, logscale = false)
    create_stars!(star_pix, 10, 100, reflect_operation; AT = AT)

    moon_pix = Pixels((1080,1920); AT = AT, FT = FT, logscale = false)
    create_moon!(moon_pix, num_particles, num_iterations, reflect_operation;
                 AT = AT)

    #forest_pix = Pixels((1080,1920); AT = AT, FT = FT, logscale = false)
    #create_forest!(forest_pix, 2, 2*num_particles, 2*num_iterations,
    #               reflect_operation; AT = AT)

    filename = "check.png"

    @time Fae.write_image([sky_pix, star_pix, moon_pix], filename)
    #@time Fae.write_image([sky_pix, star_pix, moon_pix, forest_pix], filename)
    #@time Fae.write_image([forest_pix], filename)
end
