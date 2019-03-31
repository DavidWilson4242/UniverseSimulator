-- LIBRARIES
Particle = dofile("Particle.lua")

-- CONSTANTS
FIELD = nil
PARTS = {}
WIDTH = love.graphics.getWidth()
HEIGHT = love.graphics.getHeight()

-- USER CONSTANTS
SPAN_X = 500*math.pi
SPAN_Y = 500*math.pi
CAM_X = 0 
CAM_Y = 0
MASS_PLANET = 0.1
MASS_SUN = 0.1*1000
MASS_BH = 0.1*1000*1000 


-- VARS
insert_mode = "P"
    -- P -> planet
    -- S -> start
    -- B -> supermassive black hole
dtf = 1

World = {
    CosmicField = nil;
    Particles = {};
}

local function grav_field(x, y, mass)
    local r2 = x*x + y*y
    local theta = math.atan2(x, y)
    return -mass*math.sin(theta)/r2, -mass*math.cos(theta)/r2
end

function TOW(x, y)
    return (x * (WIDTH/SPAN_X))+WIDTH/2, (y * (HEIGHT/SPAN_Y))+HEIGHT/2
end

function map(x, a, b, c, d)
    return (x - a)/(b - a)*(d - c) + c
end

function make_particle(x, y, mass, f)
    local p = Particle:new(x, y, mass, f)
    table.insert(World.Particles, p)
    return p
end

function make_galaxy(x, y)
    local bh = make_particle(x, y, MASS_BH, grav_field) 
end

function net_force(x, y, ignore_list)
    local cfx, cfy = World.CosmicField(x, y)

    for i, v in ipairs(World.Particles) do
        local do_check = true
        for j, k in ipairs(ignore_list or {}) do
            if k == v then
                do_check = false
                break
            end
        end
        if do_check then
            local fx, fy = v:calculate_force(x, y)
            cfx = cfx + fx
            cfy = cfy + fy
        end
    end

    return cfx, cfy
end

function love.load()

    World.CosmicField = function(x, y)
        local r2 = (x*x + y*y)^0.1
        local theta = math.atan2(x, y)
        return 0,0---60*math.sin(theta)/r2, -60*math.cos(theta)/r2
    end
    
    --[[
    for i = 1, 9 do
        table.insert(World.Particles, Particle:new(
            map(math.random(), 0, 1, -SPAN_X/2, SPAN_X/2),
            map(math.random(), 0, 1, -SPAN_Y/2, SPAN_Y/2),
            math.random() < 0.5 and math.random(10) or math.random(100, 150),
            function(x, y, m)
                local r2 = x*x + y*y
                local theta = math.atan2(x, y)
                return -m*math.sin(theta)/r2, -m*math.cos(theta)/r2
            end
        ))
    end]]


end

function love.update(dt)
    
    dt = dt*dtf
    
    for i, v in ipairs(World.Particles) do

        -- calculate the gradient force at the
        -- particle's position
        local grad_x, grad_y = net_force(v.px, v.py, {v})

        -- calculate the particles' acceleration
        v.ax = grad_x / v.mass
        v.ay = grad_y / v.mass

        -- we're not going to allow a magnitude force
        -- past a certain threshhold.  this should
        -- prevent object from going over the 
        -- same pixel and throwing each other to
        -- infinity.  
        local acc_mag = math.sqrt(v.ax*v.ax + v.ay*v.ay)
        if acc_mag > 100000 then
            v.ax = v.ax * (100000/acc_mag)
            v.ay = v.ay * (100000/acc_mag)
        end

        -- ... calculate velocity
        v.vx = v.vx + v.ax*dt
        v.vy = v.vy + v.ay*dt

        -- ... calculate position
        v.px = v.px + v.vx*dt
        v.py = v.py + v.vy*dt

    end

end

function love.draw()

    for i = -SPAN_X/2, SPAN_X/2, SPAN_X/60 do
        for j = -SPAN_Y/2, SPAN_Y/2, SPAN_Y/60 do

            -- calculate the net force at a given world point
            local fx, fy = net_force(CAM_X + i, CAM_Y + j)
            
            -- find the world coordinate
            local wx, wy = TOW(i, j)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.line(wx - fx/2, wy - fy/2, wx + fx/2, wy + fy/2)
            
            love.graphics.setColor(0, 0, 1)
            love.graphics.circle("fill", wx + fx/2, wy + fy/2, 2)

        end
    end

    -- draw axes
    --[[
    love.graphics.setColor(0, 1, 0)
    love.graphics.line(0, HEIGHT/2, WIDTH, HEIGHT/2)
    love.graphics.line(WIDTH/2, 0, WIDTH/2, HEIGHT)
    ]]

    for i, v in ipairs(World.Particles) do
        local wx, wy = TOW(-CAM_X + v.px, -CAM_Y + v.py)
        if wx >= -10 and wx <= WIDTH + 10 and wy >= -10 and wy <= HEIGHT + 10 then
            if v.mass < 50 then
                love.graphics.setColor(0, 0, 1, 0.7)
            elseif v.mass < 2000 then
                love.graphics.setColor(1, 0, 0, 0.7)
            else
                love.graphics.setColor(0, 1, 0, 0.7)
            end
            love.graphics.circle("fill", wx, wy, 10)
        end
    end

    love.graphics.setColor(0, 1, 0)
    love.graphics.print(tostring(dtf), WIDTH - 20, HEIGHT - 20)

end

function love.keypressed(key)
    if key == "p" then
        insert_mode = "P"
    elseif key == "s" then
        insert_mode = "S"
    elseif key == "b" then
        insert_mode = "B"
    elseif key == "w" then
        dtf = dtf * 1.5
    elseif key == "q" then
        dtf = dtf * (1/1.5)
    elseif key == "i" then
        SPAN_X = SPAN_X / 1.5
        SPAN_Y = SPAN_Y / 1.5
    elseif key == "o" then
        SPAN_X = SPAN_X * 1.5
        SPAN_Y = SPAN_Y * 1.5
    elseif key == "left" then
        CAM_X = CAM_X - 10
    elseif key == "right" then
        CAM_X = CAM_X + 10
    elseif key == "up" then
        CAM_Y = CAM_Y - 10
    elseif key == "down" then
        CAM_Y = CAM_Y + 10
    end
end

function love.mousepressed(x, y)

    local mass;

    if insert_mode == "P" then
        mass = MASS_PLANET
        local x = map(x, 0, WIDTH, CAM_X - SPAN_X/2, CAM_X + SPAN_X/2)
        local y = map(y, 0, HEIGHT, CAM_Y - SPAN_Y/2, CAM_Y + SPAN_Y/2)
        make_galaxy(x, y)
        return
    elseif insert_mode == "S" then
        mass = MASS_STAR
    elseif insert_mode == "B" then
        mass = MASS_BH
    end

    table.insert(World.Particles, Particle:new(
        map(x, 0, WIDTH, CAM_X - SPAN_X/2, CAM_X + SPAN_X/2),
        map(y, 0, HEIGHT, CAM_Y - SPAN_Y/2, CAM_Y + SPAN_Y/2),
        mass,
        grav_field
    ))

end
