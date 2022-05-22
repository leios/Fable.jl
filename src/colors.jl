export Colors

module Colors

import Fae.@fum

previous = @fum function previous(clr)
end

red = @fum function red(clr, tid)
    red = 1
    green = 0
    blue = 0
    alpha = 1
end

green = @fum function green(clr, tid)
    red = 0
    green = 1
    blue = 0
    alpha = 1
end

blue = @fum function blue(clr, tid)
    red = 0
    green = 0
    blue = 1
    alpha = 1
end

magenta = @fum function magenta(clr, tid)
    red = 1
    green = 0
    blue = 1
    alpha = 1
end
end
