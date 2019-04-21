-- LIBRARIES
Particle = dofile("Particle.lua")

-- CONSTANTS
FIELD = nil
PARTS = {}
WIDTH = love.graphics.getWidth()
HEIGHT = love.graphics.getHeight()

-- USER CONSTANTS
SPAN_X = 500*math.pi*(WIDTH/HEIGHT)
SPAN_Y = 500*math.pi
CAM_X = 0 
CAM_Y = 0
MASS_PLANET = 0.1
MASS_STAR = 0.1*10000
MASS_BH = 0.1*1000*1000 


-- VARS
insert_mode = "P"
    -- P -> planet
    -- S -> start
    -- B -> supermassive black hole
dtf = 1
paused = false

World = {
    CosmicField = nil;
    Particles = {};
}

function HSV(h, s, v)
    if s <= 0 then return v,v,v end
    h, s, v = h/256*6, s/255, v/255
    local c = v*s
    local x = (1-math.abs((h%2)-1))*c
    local m,r,g,b = (v-c), 0,0,0
    if h < 1     then r,g,b = c,x,0
    elseif h < 2 then r,g,b = x,c,0
    elseif h < 3 then r,g,b = 0,c,x
    elseif h < 4 then r,g,b = 0,x,c
    elseif h < 5 then r,g,b = x,0,c
    else              r,g,b = c,0,x
    end return (r+m),(g+m),(b+m)
end

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
    
    -- make some stars
    local stars = {}
    for i = 1, math.random(10, 30) do
        local radius = 300--math.random(250, 400)
        local theta = math.random() * 2*math.pi
        local tan_theta = theta + math.pi/2
        local p = make_particle(
            x + radius*math.cos(theta),
            y + radius*math.sin(theta),
            MASS_STAR,
            grav_field
        )
        p.vx = 0.6*math.cos(tan_theta)
        p.vy = 0.6*math.sin(tan_theta)
        table.insert(stars, p)
    end

    -- make some planets
    for i, v in ipairs(stars) do
        for j = 1, math.random(0, 10) do
            local radius = 15--(math.random() + 0.1) * 5
            local theta = math.random() * 2*math.pi
            local tan_theta = theta + math.pi/2
            local p = make_particle(
                v.px + radius*math.cos(theta),
                v.py + radius*math.sin(theta),
                MASS_PLANET,
                grav_field
            )
            p.vx = math.sqrt(v.mass*12/radius)*math.cos(tan_theta)
            p.vy = math.sqrt(v.mass*12/radius)*math.sin(tan_theta)
            print(p.vx, p.vy)
        end
    end
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

end

function love.update(dt)
    
    if paused then
        return
    end
    
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
    
    local xs = -SPAN_X/2
    local xf = SPAN_X/2
    local ys = -SPAN_Y/2
    local yf = SPAN_Y/2
    local xinc = SPAN_X/80
    local yinc = SPAN_X/80
    --[[
    for i = xs, xf, xinc do
        for j = ys, yf, yinc do
            -- first, draw the color field
            local fx, fy = net_force(CAM_X + i, CAM_Y + j)
            local mag_f = math.sqrt(fx*fx + fy*fy)
            
            -- find world coordinate
            local wx, wy = TOW(i, j)

            local h = map(math.sqrt(mag_f), 0, 1000, 0, 359)/10
            if h > 1 then
                h = 1
            end
            local r, g, b = HSV(h*360, 50, 100)
            print(h, r, g, b)
            
            --love.graphics.setColor(r, g, b, 0.1)
            love.graphics.setColor(r, g, b, 0.1)
            love.graphics.circle("fill", wx, wy, 30)
        end
    end
    ]]

    for i = xs - 4*xinc, xf + 4*xinc, xinc do
        for j = ys - 4*yinc, yf + 4*yinc, yinc do

            -- calculate the net force at a given world point
            local fx, fy = net_force(CAM_X + i, CAM_Y + j)
            local mag_f = math.sqrt(fx*fx + fy*fy)
            -- trim to 100 pixels
            if mag_f > 100 then
                fx = fx * (100/mag_f)
                fy = fy * (100/mag_f)
            end
            
            -- find the world coordinate
            local wx, wy = TOW(i, j)
            
            love.graphics.setColor(1, 1, 1, 0.2)
            love.graphics.line(wx - fx/2, wy - fy/2, wx + fx/2, wy + fy/2)
            love.graphics.setColor(map((4*mag_f)^3, 0, 10000, 0, 1), 0, 1, 0.5)
            love.graphics.circle("fill", wx - fx/2, wy - fy/2, 2)

        end
    end
    
    -- draw particles
    for i, v in ipairs(World.Particles) do
        local wx, wy = TOW(-CAM_X + v.px, -CAM_Y + v.py)
        local radius
        if v.mass == MASS_PLANET then
            radius = 6
        elseif v.mass == MASS_STAR then
            radius = 10
        elseif v.mass == MASS_BH then
            radius = 40
        else
            radius = 10
        end
        if wx >= -10 and wx <= WIDTH + 10 and wy >= -10 and wy <= HEIGHT + 10 then
            if v.mass == MASS_PLANET then
                love.graphics.setColor(1, 0, 1, 0.7)
            elseif v.mass == MASS_STAR then
                love.graphics.setColor(1, 0, 0, 0.7)
            else
                love.graphics.setColor(0, 1, 0, 0.7)
            end
            love.graphics.circle("fill", wx, wy, radius)
        end
    end

    love.graphics.setColor(0, 1, 0)
    love.graphics.print(tostring(dtf), WIDTH - 30, HEIGHT - 20)

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
    elseif key == "left" then
        CAM_X = CAM_X - SPAN_X/10
    elseif key == "right" then
        CAM_X = CAM_X + SPAN_X/10
    elseif key == "up" then
        CAM_Y = CAM_Y - SPAN_Y/10
    elseif key == "down" then
        CAM_Y = CAM_Y + SPAN_Y/10
    elseif key == "t" then
        paused = not paused
    end
end

function love.mousepressed(x, y, b)
    
    if b == 1 then
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
    elseif b == 2 then
        local wx = map(x, 0, WIDTH, CAM_X - SPAN_X/2, CAM_X + SPAN_X/2)
        local wy = map(y, 0, HEIGHT, CAM_Y - SPAN_Y/2, CAM_Y + SPAN_Y/2)
        CAM_X = wx
        CAM_Y = wy
    end
    print(b)

end

function love.wheelmoved(x, y)
    if y > 0 then
        SPAN_X = SPAN_X / 1.5
        SPAN_Y = SPAN_Y / 1.5
    elseif y < 0 then
        SPAN_X = SPAN_X * 1.5
        SPAN_Y = SPAN_Y * 1.5
    end
end
