function love.load()
    -- Initialize player
    player = {
        x = 100,
        y = 100,
        width = 32,
        height = 32,
        walkUpImages = {love.graphics.newImage("assets/player_walk_up_1.png"), love.graphics.newImage("assets/player_walk_up_2.png")},
        walkDownImages = {love.graphics.newImage("assets/player_walk_down_1.png"), love.graphics.newImage("assets/player_walk_down_2.png")},
        walkLeftImages = {love.graphics.newImage("assets/player_walk_left_1.png"), love.graphics.newImage("assets/player_walk_left_2.png")},
        walkRightImages = {love.graphics.newImage("assets/player_walk_right_1.png"), love.graphics.newImage("assets/player_walk_right_2.png")},
        currentWalkImages = nil,
        health = 500,
        attack = 10,
        defense = 5,
        direction = "down",
        walkFrame = 1,
        walkTimer = 0,
        speed = 150,
        attackImages = {
            left = love.graphics.newImage("assets/attack-left.png"),
            right = love.graphics.newImage("assets/attack-right.png"),
            down = love.graphics.newImage("assets/attack-down.png"),
            up = love.graphics.newImage("assets/attack-up.png")
        },
        attacking = false,
        attackDuration = 0.2
    }

    -- Initialize enemies
    enemies = {}
    enemySpawnTimer = 0
    enemySpawnInterval = 2
    gameOver = false

    -- Initialize rupees
    rupeeImages = {
        love.graphics.newImage("assets/rupee-1.png"),
        love.graphics.newImage("assets/rupee-2.png")
    }
    rupeeAnimationFrame = 1
    rupeeAnimationTimer = 0
    rupees = {}

    -- Initialize rocks table
    rocks = {}

    -- Camera setup
    camera = {
        x = 0,
        y = 0,
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight()
    }
end

function love.update(dt)
    if not gameOver then
        updatePlayer(dt)
        updateEnemies(dt)
        updateRupees(dt)

        -- Handle enemy spawning at regular intervals
        enemySpawnTimer = enemySpawnTimer + dt
        if enemySpawnTimer >= enemySpawnInterval then
            enemySpawnTimer = 0
            spawnEnemy()
        end

        -- Reset the attacking state until the next mouse click
        if player.attacking then
            player.attackDuration = player.attackDuration - dt
            if player.attackDuration <= 0 then
                player.attacking = false  -- Stop attacking after the duration
            end
        end
    else
        -- Check for restart (just for testing purposes)
        if love.keyboard.isDown("r") then
            gameOver = false
            player.health = 500
            player.x = 100
            player.y = 100
            enemies = {}
            rupees = {}
            rocks = {}
        end
    end

    -- Handle walking animation frame
    player.walkTimer = player.walkTimer + dt
    if player.walkTimer >= 0.15 then
        player.walkFrame = (player.walkFrame % #player.walkUpImages) + 1
        player.walkTimer = 0
    end

    -- Set the walking animation based on direction
    if player.direction == "up" then
        player.currentWalkImages = player.walkUpImages
    elseif player.direction == "down" then
        player.currentWalkImages = player.walkDownImages
    elseif player.direction == "left" then
        player.currentWalkImages = player.walkLeftImages
    elseif player.direction == "right" then
        player.currentWalkImages = player.walkRightImages
    end

    -- Update camera position to center on the player
    camera.x = player.x - camera.width / 2
    camera.y = player.y - camera.height / 2

    -- Prevent camera from going outside the world boundaries
    camera.x = math.max(0, math.min(camera.x, love.graphics.getWidth() - camera.width))
    camera.y = math.max(0, math.min(camera.y, love.graphics.getHeight() - camera.height))

    -- Spawn rocks periodically (every 2 seconds)
    spawnRocks()
end

-- Mouse click triggers attack
function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then  -- Left mouse button
        player.attacking = true
        player.attackDuration = 0.2  -- Set duration for attack animation

        -- Set attack direction based on mouse position
        if x < player.x then
            player.direction = "left"
        elseif x > player.x then
            player.direction = "right"
        elseif y < player.y then
            player.direction = "up"
        elseif y > player.y then
            player.direction = "down"
        end
    end
end

-- Update player movement and prevent movement through rocks
function updatePlayer(dt)
    local newX = player.x
    local newY = player.y
    local canMove = true

    if love.keyboard.isDown('w') then
        newY = player.y - player.speed * dt
        player.direction = "up"
    elseif love.keyboard.isDown('s') then
        newY = player.y + player.speed * dt
        player.direction = "down"
    elseif love.keyboard.isDown('a') then
        newX = player.x - player.speed * dt
        player.direction = "left"
    elseif love.keyboard.isDown('d') then
        newX = player.x + player.speed * dt
        player.direction = "right"
    end

    -- Check for collision with rocks
    for _, rock in ipairs(rocks) do
        if checkCollision(newX, newY, player.width, player.height, rock.x, rock.y, rock.width, rock.height) then
            canMove = false
            break
        end
    end

    -- Only update player position if there's no collision
    if canMove then
        player.x = math.max(0, math.min(newX, love.graphics.getWidth() - player.width))
        player.y = math.max(0, math.min(newY, love.graphics.getHeight() - player.height))
    end

    -- Check for rupee collection
    for i, rupee in ipairs(rupees) do
        if checkCollision(player.x, player.y, player.width, player.height, rupee.x, rupee.y, rupee.width, rupee.height) then
            table.remove(rupees, i)  -- Remove the rupee when collected
        end
    end
end

-- Collision detection function
function checkCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x1 + w1 > x2 and y1 < y2 + h2 and y1 + h1 > y2
end

-- Spawn rocks randomly every 2 seconds
function spawnRocks()
    if math.random() < 0.01 then  -- Adjust this probability to control frequency
        local rock = {
            x = math.random(200, love.graphics.getWidth() - 32),
            y = math.random(200, love.graphics.getHeight() - 32),
            width = 32,
            height = 32,
            image = love.graphics.newImage("assets/rock-tiny.png")
        }
        table.insert(rocks, rock)
    end
end

-- Spawn enemies at regular intervals
function spawnEnemy()
    local newEnemy = {
        x = math.random(200, love.graphics.getWidth() - 32),
        y = math.random(200, love.graphics.getHeight() - 32),
        width = 32,
        height = 32,
        health = 200,
        attack = 10,
        defense = 3,
        speed = 70,
        attackRange = 50,
        attackCooldown = 3,
        image = love.graphics.newImage("assets/enemy.png")
    }

    table.insert(enemies, newEnemy)
end

-- Update enemies logic (moving and attacking)
function updateEnemies(dt)
    for _, enemy in ipairs(enemies) do
        if enemy.health > 0 then
            local dx, dy = player.x - enemy.x, player.y - enemy.y
            local distanceToPlayer = math.sqrt(dx * dx + dy * dy)

            if distanceToPlayer <= enemy.attackRange then
                -- Enemy attacks the player if within attack range
                if enemy.attackCooldown <= 0 then
                    player.health = player.health - enemy.attack
                    enemy.attackCooldown = 1  -- Cooldown for the enemy's next attack
                end
            else
                -- Move towards the player if out of attack range
                local moveX = (dx / distanceToPlayer) * enemy.speed * dt
                local moveY = (dy / distanceToPlayer) * enemy.speed * dt
                enemy.x = enemy.x + moveX
                enemy.y = enemy.y + moveY
            end

            -- Check if the player is attacking
            if player.attacking then
                if math.abs(player.x - enemy.x) < enemy.width and math.abs(player.y - enemy.y) < enemy.height then
                    enemy.health = enemy.health - player.attack
                    if enemy.health <= 0 then
                        -- Drop a rupee when the enemy dies
                        dropRupee(enemy.x, enemy.y)
                    end
                end
            end

            -- Reduce the enemy's attack cooldown
            enemy.attackCooldown = enemy.attackCooldown - dt
        end
    end
end

-- Drop a rupee when an enemy dies
function dropRupee(x, y)
    local newRupee = {
        x = x,
        y = y,
        width = 32,
        height = 32,
        animationFrame = 1,
        timer = 0  -- Timer for the rupee to stay on screen
    }
    table.insert(rupees, newRupee)
end

-- Update rupees' animation (hovering up and down) and timer
function updateRupees(dt)
    -- Update the animation frame for rupees
    rupeeAnimationTimer = rupeeAnimationTimer + dt
    if rupeeAnimationTimer >= 0.5 then
        rupeeAnimationFrame = (rupeeAnimationFrame % 2) + 1  -- Switch between frame 1 and frame 2
        rupeeAnimationTimer = 0  -- Reset timer
    end

    -- Update rupee positions (hover effect) and timers
    for _, rupee in ipairs(rupees) do
        rupee.y = rupee.y + math.sin(love.timer.getTime() * 4) * 0.4  -- Hover effect (up and down)
        rupee.timer = rupee.timer + dt
        if rupee.timer > 5 then  -- Remove rupee after 5 seconds
            table.remove(rupees, _)
        end
    end
end

-- Draw everything (player, rocks, enemies, etc.)
function love.draw()
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)  -- Apply camera translation

    -- Draw player
    love.graphics.draw(player.currentWalkImages[player.walkFrame], player.x, player.y)

    -- Draw attack (depending on direction)
    if player.attacking then
        local attackImage = player.attackImages[player.direction]
        love.graphics.draw(attackImage, player.x, player.y)
    end

    -- Draw rocks
    for _, rock in ipairs(rocks) do
        love.graphics.draw(rock.image, rock.x, rock.y)
    end

    -- Draw enemies and their health bars
    for _, enemy in ipairs(enemies) do
        if enemy.health > 0 then
            love.graphics.draw(enemy.image, enemy.x, enemy.y)
            -- Health bar for the enemy
            love.graphics.setColor(0, 1, 0)  -- Green
            love.graphics.rectangle("fill", enemy.x, enemy.y - 10, enemy.width, 5)
            love.graphics.setColor(1, 0, 0)  -- Red
            love.graphics.rectangle("fill", enemy.x, enemy.y - 10, (enemy.health / 200) * enemy.width, 5)
            love.graphics.setColor(1,1,1)
        end
    end

    -- Draw rupees
    for _, rupee in ipairs(rupees) do
        love.graphics.draw(rupeeImages[rupeeAnimationFrame], rupee.x, rupee.y)
    end

    -- Draw player health bar
    love.graphics.setColor(1, 0, 0)  -- Red
    love.graphics.rectangle("fill", 10, 10, player.health / 2, 20)
    love.graphics.setColor(0,1,0)
    love.graphics.rectangle("fill", 10, 10, player.health / 2, 20)
    love.graphics.setColor(1,1,1)
    -- Game Over condition
    if gameOver then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("GAME OVER! Press 'R' to restart.", love.graphics.getWidth() / 2 - 100, love.graphics.getHeight() / 2)
    end

    love.graphics.pop()
end
