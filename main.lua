-- Player properties
local player = {
    x = 400,  -- Starting X position (center of 800px wide screen)
    y = 300,  -- Starting Y position (center of 600px tall screen)
    speed = 200,  -- Pixels per second
    size = 32  -- Width and height of player square
}

function love.load()
    -- Set up the window
    love.window.setMode(800, 600)
    love.window.setTitle("Movement System")
end

function love.update(dt)
    -- Movement controls
    local dx, dy = 0, 0
    
    -- Check keyboard input
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        dy = -1
    end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        dy = 1
    end
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        dx = -1
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        dx = 1
    end
    
    -- Normalize diagonal movement (prevents moving faster diagonally)
    if dx ~= 0 and dy ~= 0 then
        local length = math.sqrt(dx * dx + dy * dy)
        dx = dx / length
        dy = dy / length
    end
    
    -- Update player position
    player.x = player.x + (dx * player.speed * dt)
    player.y = player.y + (dy * player.speed * dt)
    
    -- Keep player within screen bounds
    player.x = math.max(player.size/2, math.min(800 - player.size/2, player.x))
    player.y = math.max(player.size/2, math.min(600 - player.size/2, player.y))
end

function love.draw()
    -- Draw the player
    love.graphics.setColor(1, 0, 0)  -- Red color
    love.graphics.rectangle("fill", 
        player.x - player.size/2, 
        player.y - player.size/2, 
        player.size, 
        player.size)
    
    -- Draw instructions
    love.graphics.setColor(1, 1, 1)  -- White color
    love.graphics.print("Use WASD or Arrow Keys to move", 10, 10)
end