local Particle = {}

-- PARTICLE constructor
-- Takes x, y, mass, and f
-- f is a callback function that takes
-- two arguments(offset_x, offset_y).  The function
-- should return a pair of coordinates representing
-- a field rooted at the particle.
function Particle:new(x, y, mass, f)
    
    local self = setmetatable({}, {__index = Particle})
    self.px = x
    self.py = y
    self.vx = 0
    self.vy = 0 
    self.ax = 0
    self.ay = 0
    self.mass = mass
    self.f = f

    return self

end

function Particle:calculate_force(x, y)
    
    -- given an x and y coordinate, we want to
    -- find the coordinates relative to this
    -- particle.
    local rx = x - self.px
    local ry = y - self.py

    -- now we can calculate the force
    return self.f(rx, ry, self.mass)

end
    
return Particle
