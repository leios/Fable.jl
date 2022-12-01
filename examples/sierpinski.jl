using Fae

function main(num_particles, num_iterations, num_frames, ArrayType)
    FloatType = Float32

    bounds = [-1.125 1.125; -2 2]
    res = (1080, 1920)

    layer = FractalLayer(res; ArrayType = ArrayType, logscale = false, FloatType = FloatType)

    theta = 0
    r = 1
    A_1 = [r*cos(theta), r*sin(theta)]
    B_1 = [r*cos(theta + 2*pi/3), r*sin(theta + 2*pi/3)]
    C_1 = [r*cos(theta + 4*pi/3), r*sin(theta + 4*pi/3)]

    A_2 = [r*cos(-theta), r*sin(-theta)]
    B_2 = [r*cos(-theta + 2*pi/3), r*sin(-theta + 2*pi/3)]
    C_2 = [r*cos(-theta + 4*pi/3), r*sin(-theta + 4*pi/3)]

    H = Fae.define_triangle(A_1, B_1, C_1,
                            [[1.0, 0.0, 0.0, 1.0],
                            [0.0, 1.0, 0.0, 1.0],
                            [0.0, 0.0, 1.0, 1.0]]; ArrayType = ArrayType,
                            name = "s1", chosen_fx = :sierpinski)
    H_2 = Fae.define_triangle(A_2, B_2, C_2,
                              [[0.0, 1.0, 1.0, 1.0],
                              [1.0, 0.0, 1.0, 1.0],
                              [1.0, 1.0, 0.0, 1.0]]; ArrayType = ArrayType,
                              name = "s2", chosen_fx = :sierpinski)

    final_H = fee([H, H_2]; diagnostic = true)

    for i = 1:num_frames

        theta = 2*pi*(i-1)/num_frames
        A_1 = [r*cos(theta), r*sin(theta)]
        B_1 = [r*cos(theta + 2*pi/3), r*sin(theta + 2*pi/3)]
        C_1 = [r*cos(theta + 4*pi/3), r*sin(theta + 4*pi/3)]

        A_2 = [r*cos(-theta), r*sin(-theta)]
        B_2 = [r*cos(-theta + 2*pi/3), r*sin(-theta + 2*pi/3)]
        C_2 = [r*cos(-theta + 4*pi/3), r*sin(-theta + 4*pi/3)]

        Fae.update_triangle!(H, A_1, B_1, C_1; FloatType = FloatType, ArrayType = ArrayType)
        Fae.update_triangle!(H_2, A_2, B_2, C_2; FloatType = FloatType, ArrayType = ArrayType)

        update!(final_H, [H, H_2])

        Fae.run!(layer, final_H, num_particles, num_iterations,
                 bounds, res; ArrayType = ArrayType, FloatType = FloatType)

        filename = "check"*lpad(i-1,5,"0")*".png"

        @time Fae.write_image([layer], filename)

        zero!(layer)
    end
end
