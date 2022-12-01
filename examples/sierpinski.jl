using Fae

function main(num_particles, num_iterations, num_frames; ArrayType = Array)
    FloatType = Float32

    bounds = [-1.125 1.125; -2 2]
    res = (1080, 1920)

    layer = FractalLayer(res; ArrayType = ArrayType, logscale = false,
                         FloatType = FloatType, num_iterations = num_iterations,
                         num_particles = num_particles)

    theta = 0
    r = 1
    A_1 = [r*cos(theta), r*sin(theta)]
    B_1 = [r*cos(theta + 2*pi/3), r*sin(theta + 2*pi/3)]
    C_1 = [r*cos(theta + 4*pi/3), r*sin(theta + 4*pi/3)]

    A_2 = [r*cos(-theta), r*sin(-theta)]
    B_2 = [r*cos(-theta + 2*pi/3), r*sin(-theta + 2*pi/3)]
    C_2 = [r*cos(-theta + 4*pi/3), r*sin(-theta + 4*pi/3)]

    H = Fae.define_triangle(; A = A_1, B = B_1, C = C_1,
                            color = [[1.0, 0.0, 0.0, 1.0],
                                     [0.0, 1.0, 0.0, 1.0],
                                     [0.0, 0.0, 1.0, 1.0]],
                            name = "s1", chosen_fx = :sierpinski)
    H_2 = Fae.define_triangle(A = A_2, B = B_2, C = C_2,
                              color = [[0.0, 1.0, 1.0, 1.0],
                                       [1.0, 0.0, 1.0, 1.0],
                                       [1.0, 1.0, 0.0, 1.0]],
                              name = "s2", chosen_fx = :sierpinski)

    final_H = fee(Hutchinson, [H, H_2])

    for i = 1:num_frames

        theta = 2*pi*(i-1)/num_frames
        A_1 = [r*cos(theta), r*sin(theta)]
        B_1 = [r*cos(theta + 2*pi/3), r*sin(theta + 2*pi/3)]
        C_1 = [r*cos(theta + 4*pi/3), r*sin(theta + 4*pi/3)]

        A_2 = [r*cos(-theta), r*sin(-theta)]
        B_2 = [r*cos(-theta + 2*pi/3), r*sin(-theta + 2*pi/3)]
        C_2 = [r*cos(-theta + 4*pi/3), r*sin(-theta + 4*pi/3)]

        Fae.update_triangle!(H, A_1, B_1, C_1)
        Fae.update_triangle!(H_2, A_2, B_2, C_2)

        update!(final_H, [H, H_2])

        layer.H1 = final_H

        Fae.run!(layer, bounds)

        filename = "check"*lpad(i-1,5,"0")*".png"

        Fae.write_image([layer], filename = filename)

        zero!(layer)
    end
end
