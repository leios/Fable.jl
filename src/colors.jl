export Colors

module Colors

function previous(clr)
end

function red(clr, tid)
    clr[1,tid] = 1
    clr[2,tid] = 0
    clr[3,tid] = 0
    clr[4,tid] = 1
end

function green(clr, tid)
    clr[1,tid] = 0
    clr[2,tid] = 1
    clr[3,tid] = 0
    clr[4,tid] = 1
end

function blue(clr, tid)
    clr[1,tid] = 0
    clr[2,tid] = 0
    clr[3,tid] = 1
    clr[4,tid] = 1
end

function magenta(clr, tid)
    clr[1,tid] = 1
    clr[2,tid] = 0
    clr[3,tid] = 1
    clr[4,tid] = 1
end
end
