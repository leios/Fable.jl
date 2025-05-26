@testset "color tests" begin
    color = RGBA(rand(), rand(), rand(), rand())

    sc = StandardColor(color)
    dc = DepthColor(color)

    pc = PriorityColor(color)

    @test (sc+sc).color == color + color
    @test (dc+dc).color == color + color

    # priority colors replace instead of directly adding
    @test (pc+pc).color == color
end
