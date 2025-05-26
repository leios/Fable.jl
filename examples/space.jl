#=-----------space.jl----------------------------------------------------------#
 Purpose: to draw a planet, rings, and stars in Fable
#-----------------------------------------------------------------------------=#

using Fable
using Colors
using Random

#------------------------------------------------------------------------------#
# Asteroid
#------------------------------------------------------------------------------#

comet_fire = @fum color function comet_fire(y, x; current_size = 0.3)
    r = sqrt(x*x + y*y)
    red = 1
    green = 0.25 + 0.75*(r / current_size)
    blue = r / current_size
    alpha = 0.5+0.5*(1-(r / current_size))
    return RGBA{Float32}(red, green, blue, alpha)
end

comet_hole = @fum color function comet_hole(y, x; comet_size = 0.04)

    r = sqrt(x*x + y*y)
    if r < 0.2*comet_size
        return RGBA{Float32}(color.r*0.25, color.b*0.25, color.g*0.25,
                             color.alpha)
    else
        return color
    end
    
end

comet_shape = @fum function comet_shape(y, x;
                                        comet_size = 0.04,
                                        tail_size = 0.5)

    x *= comet_size
    y *= comet_size

    if y > 0
        x *= (1-(y/comet_size))
        y *= (tail_size / comet_size)
        x += 0.025*sin((y / (0.4*tail_size))*pi)
    end
    return point(y, x)
end

comet_warp = @fum function comet_warp(y, x; location = (-0.35, 0.35))
    angle = -0.3 #-atan(y, x)
    y_1 = x*sin(angle) + y*cos(angle)
    x = x*cos(angle) - y_1*sin(angle)

    y = y_1

    #y += location[1]
    #x += location[2]
    return point(y, x)
end


#------------------------------------------------------------------------------#
# Rings
#------------------------------------------------------------------------------#

make_disk = @fum function make_disk(y, x;
                                    inner_radius = 0.35, outer_radius = 0.5,
                                    current_radius = 0.3)
    r = sqrt(x*x + y*y)
    theta = atan(y, x)

    thickness = outer_radius - inner_radius
    x = x * (thickness / current_radius) + inner_radius * cos(theta)
    y = y * (thickness / current_radius) + inner_radius * sin(theta)

    return point(y, x)
end

color_disk = @fum color function color_disk(y, x;
                                            num_bands = 4, current_radius = 0.3)
    r = sqrt(x*x + y*y)
    current_band = floor(Int, num_bands *(r / current_radius))
    Random.seed!(current_band)

    green = 0

    red = rand()
    blue = rand()

    a = (num_bands * r / current_radius)%1

    return RGBA(red, green, blue, a)
end

project_disk = @fum function project_disk(y, x; angle = pi*0.4, distance = -2)
    new_angle = (distance / (distance + y*sin(angle)))
    return point(new_angle * y * cos(angle), new_angle * x)

end

color_projected_disk = @fum color function color_projected_disk(y, x;
    planet_radius = 0.3, angle = -0.1*pi)
    angle *= -1
    x = x*cos(angle) - y*sin(angle)
    y = x*sin(angle) + y*cos(angle)

    if y < 0
        r = sqrt(x*x + y*y)
        a = color.alpha
        if r <= planet_radius
            a = 0
        end
        return RGBA{Float32}(color.r, color.g, color.b, a)
    else
        return color
    end
end

#------------------------------------------------------------------------------#
# Planet
#------------------------------------------------------------------------------#

planet_swirl = @fum function planet_swirl(y, x; total_rotations = 7,
                                          planet_radius = 0.3)
    r = sqrt(x*x + y*y)
    theta = (planet_radius-r)*(total_rotations*2*pi)

    v1 = x*cos(theta) + y*sin(theta)
    v2 = x*sin(theta) - y*cos(theta)

    return point(v1, v2)
end

base_planet_color = @fum color function base_planet_color(y, x;
                                                          num_divisions = 10)
    segment = floor(Int, num_divisions * ((atan(y, x) + pi)/(2*pi)))

    Random.seed!(segment^2)

    red = 0.5 + 0.5*rand()
    blue = 0.5 + 0.5*rand()
    
    return RGBA{Float32}(red, 0, blue, 1)
end

planet_glow = @fum color function panet_glow(y, x, color;
                                             glow_offset = (-0.1, -0.1),
                                             gradient_radius = 0.3)


    r = sqrt((x-glow_offset[2])^2 + (y-glow_offset[1])^2)

    ratio = (1 - (r/gradient_radius))
    if ratio < 0
        ratio = 0
    end

    r = color.r * ratio
    g = 0.5*ratio
    b = color.b * ratio


    return RGBA{Float32}(r, g, b, 1)
    
end

#------------------------------------------------------------------------------#
# STARS
#------------------------------------------------------------------------------#

stars = @fum function stars(y, x; num_stars = 100000,
                                  world_size = (3*0.35, 4*0.35),
                                  base_size = 0.0025)
    seed = rand(1:num_stars)
    Random.seed!(seed)

    new_x = world_size[2]*((rand())-0.5)

    seed = simple_rand(seed)
    new_y = world_size[1]*((rand())-0.5)

    seed = simple_rand(seed)
    scale_factor = base_size*(1 + 0.3 * (rand()-0.5))
    x = scale_factor * x + new_x
    y = scale_factor * y + new_y

    return point(y, x)
    
end

#------------------------------------------------------------------------------#
# BG
#------------------------------------------------------------------------------#

background_texture = @fum color function background(y, x)
    r = sqrt(x*x + y*y)
    b = (1-1.5*r)
    if b < 0
        b = 0
    end 
    return RGBA{Float32}(0,0,b,1)
end

translate = @fum function translate(y, x;
                                    translation = (0,0))
    @inbounds x += translation[2]
    @inbounds y += translation[1]
    return point(y, x)
end


rotate = @fum function rotate(y, x; angle = 0)
    return point(x*sin(angle) + y*cos(angle),
                 x*cos(angle) - y*sin(angle))
end

#------------------------------------------------------------------------------#
# MAIN
#------------------------------------------------------------------------------#

function space_example(num_particles, num_iterations;
                       ArrayType = Array, filename = "out.png",
                       background_texture = background_texture,
                       make_disk = make_disk,
                       color_disk = color_disk,
                       project_disk = project_disk,
                       color_projected_disk = color_projected_disk,
                       base_planet_color = base_planet_color,
                       planet_swirl = planet_swirl,
                       planet_glow = planet_glow,
                       comet_fire = comet_fire,
                       comet_hole = comet_hole,
                       comet_shape = comet_shape,
                       comet_warp = comet_warp,
                       translate = translate,
                       stars = stars)
    #world_size = (9*0.125, 16*0.125)
    world_size = (3*0.35, 4*0.35)
    ppu = 1920/world_size[2]

    circle = define_circle(radius = 0.3, color = Shaders.white)
    fo_1 = fo(stars, Shaders.white, (1.0))
    fo_2 = fo((Smears.null, planet_swirl, Smears.null),
              (base_planet_color, Shaders.previous,  planet_glow),
              (0.33, 0.33, 0.34))
    fo_3 = fo((Smears.null, make_disk, project_disk, rotate(angle = -0.1*pi)),
              (color_disk, Shaders.previous, Shaders.previous, color_projected_disk),
              (0.25, 0.25, 0.25, 0.25))
    fo_4 = fo((Smears.null, comet_shape, Smears.null, rotate(angle = -0.4*pi),
               translate(translation = (-0.35, 0.3))),
              (comet_fire, Shaders.previous, comet_hole, Shaders.previous, Shaders.previous),
              (0.2, 0.2, 0.2, 0.2, 0.2))

    transformations = Hutchinson((fo_1, fo_2, fo_4))

    H = Hutchinson((circle, circle, circle))

    flayer = FableLayer(num_particles = num_particles,
                        num_iterations = num_iterations,
                        H = H, H_post = transformations,
                        ppu = ppu,
                        world_size = world_size,
                        ArrayType = ArrayType,
                        overlay = true)

    r_transforms = fo_3
    r_H = circle

    rlayer = FableLayer(num_particles = num_particles,
                        num_iterations = num_iterations,
                        H = r_H, H_post = r_transforms,
                        ppu = ppu,
                        world_size = world_size,
                        ArrayType = ArrayType,
                        overlay = true)

    clayer = ShaderLayer(background_texture;
                         ArrayType = ArrayType,
                         world_size = world_size,
                         ppu = ppu)
    run!(clayer)
    run!(flayer)
    run!(rlayer)
    write_image([clayer, flayer, rlayer]; filename)
end
