-- Love2D configuration
function love.conf(t)
    t.window.width = 800
    t.window.height = 600
    t.title = "Inventory and Potions System"
end

-- Game state
local player, inventory, hotbar, enemies, camera, healthPotionImage, attackBoostImage, rupeeImage
local enemySpawnTimer, enemySpawnInterval = 0, 2
local gameOver = false

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
        attack = 100,
        defense = 5,
        direction = "down",
        walkFrame = 1,
        walkTimer = 0,
        speed = 150,
        attacking = false,
        attackDuration = 0.2,
        attackRange = 32,
        attackCooldown = 0.5,
        attackImages = {
            left = love.graphics.newImage("assets/attack-left.png"),
            right = love.graphics.newImage("assets/attack-right.png"),
            down = love.graphics.newImage("assets/attack-down.png"),
            up = love.graphics.newImage("assets/attack-up.png")
        },
        heldItem = nil,
        rupees = 0,
        attackTimer = 0
    }

    -- Initialize items
    healthPotionImage = love.graphics.newImage("assets/Health_Potion.png")
    attackBoostImage = love.graphics.newImage("assets/Attack_Boost.png")
    rupeeImage = love.graphics.newImage("assets/rupee-1.png")

    -- Initialize inventory (potions at top)
    inventory = {
        {item = "healthPotion", cost = 5, image = healthPotionImage},
        {item = "attackBoost", cost = 10, image = attackBoostImage}
    }

    -- Initialize hotbar (9 slots at bottom)
    hotbar = {
        slots = {},
        selectedSlot = 1,
        slotSize = 50,
        padding = 5
    }
    for i = 1, 9 do
        hotbar.slots[i] = {
            x = (i - 1) * (hotbar.slotSize + hotbar.padding) + (love.graphics.getWidth() - 9 * (hotbar.slotSize + hotbar.padding) + hotbar.padding) / 2,
            y = love.graphics.getHeight() - hotbar.slotSize - hotbar.padding,
            item = nil
        }
    end

    -- Initialize enemies
    enemies = {}

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

        -- Enemy spawning
        enemySpawnTimer = enemySpawnTimer + dt
        if enemySpawnTimer >= enemySpawnInterval then
            enemySpawnTimer = 0
            spawnEnemy()
        end

        -- Handle attack cooldown
        if player.attacking then
            player.attackTimer = player.attackTimer + dt
            if player.attackTimer >= player.attackDuration then
                player.attacking = false
                player.attackTimer = 0
            end
        end

        -- Handle walking animation
        player.walkTimer = player.walkTimer + dt
        if player.walkTimer >= 0.15 then
            player.walkFrame = (player.walkFrame % #player.walkUpImages) + 1
            player.walkTimer = 0
        end

        -- Update direction-based animation
        if player.direction == "up" then player.currentWalkImages = player.walkUpImages
        elseif player.direction == "down" then player.currentWalkImages = player.walkDownImages
        elseif player.direction == "left" then player.currentWalkImages = player.walkLeftImages
        elseif player.direction == "right" then player.currentWalkImages = player.walkRightImages end

        -- Update camera
        camera.x = math.max(0, math.min(player.x - camera.width / 2, love.graphics.getWidth() - camera.width))
        camera.y = math.max(0, math.min(player.y - camera.height / 2, love.graphics.getHeight() - camera.height))

        -- Hotbar selection
        for i = 1, 9 do
            if love.keyboard.isDown(tostring(i)) then
                hotbar.selectedSlot = i
            end
        end
    else
        if love.keyboard.isDown("r") then
            gameOver = false
            player.health = 500
            player.x = 100
            player.y = 100
            enemies = {}
            player.rupees = 0
            for i = 1, 9 do hotbar.slots[i].item = nil end
        end
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 and not gameOver then
        -- Check potion clicks at top
        for i, potion in ipairs(inventory) do
            local potX = 10 + (i - 1) * 40
            local potY = 70
            if x > potX and x < potX + 32 and y > potY and y < potY + 32 and player.rupees >= potion.cost then
                local selectedSlot = hotbar.slots[hotbar.selectedSlot]
                if not selectedSlot.item then
                    selectedSlot.item = {item = potion.item, cost = potion.cost, image = potion.image}
                    player.rupees = player.rupees - potion.cost
                end
                return
            end
        end

        -- Check hotbar clicks to use items
        for i, slot in ipairs(hotbar.slots) do
            if x > slot.x and x < slot.x + hotbar.slotSize and y > slot.y and y < slot.y + hotbar.slotSize and slot.item then
                if slot.item.item == "healthPotion" then
                    useHealthPotion()
                    slot.item = nil
                elseif slot.item.item == "attackBoost" then
                    useAttackBoost()
                    slot.item = nil
                end
                return
            end
        end

        -- Attack input
        if player.attackCooldown <= 0 and not player.attacking then
            player.attacking = true
            player.attackCooldown = 0.5
            player.attackTimer = 0
            attackEnemiesInRange()
        end
    end
end

function updatePlayer(dt)
    local newX, newY = player.x, player.y
    if love.keyboard.isDown('w') then newY = player.y - player.speed * dt; player.direction = "up"
    elseif love.keyboard.isDown('s') then newY = player.y + player.speed * dt; player.direction = "down"
    elseif love.keyboard.isDown('a') then newX = player.x - player.speed * dt; player.direction = "left"
    elseif love.keyboard.isDown('d') then newX = player.x + player.speed * dt; player.direction = "right" end
    player.x = math.max(0, math.min(newX, love.graphics.getWidth() - player.width))
    player.y = math.max(0, math.min(newY, love.graphics.getHeight() - player.height))
    if player.attackCooldown > 0 then player.attackCooldown = player.attackCooldown - dt end
end

function attackEnemiesInRange()
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        if enemy.health then
            local distance = math.sqrt((enemy.x - player.x)^2 + (enemy.y - player.y)^2)
            if distance <= player.attackRange then
                enemy.health = enemy.health - player.attack
                if enemy.health <= 0 then
                    table.remove(enemies, i)
                    table.insert(enemies, {x = enemy.x, y = enemy.y, timer = 0, bobOffset = 0})
                end
            end
        end
    end
end

function useHealthPotion()
    if player.health < 500 then
        player.health = math.min(player.health + 50, 500)
    end
end

function useAttackBoost()
    player.attack = player.attack + 5
end

function spawnEnemy()
    table.insert(enemies, {
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
    })
end

function updateEnemies(dt)
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        if enemy.health then
            local dx, dy = player.x - enemy.x, player.y - enemy.y
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance <= enemy.attackRange then
                if enemy.attackCooldown <= 0 then
                    player.health = player.health - enemy.attack
                    enemy.attackCooldown = 1
                end
            else
                enemy.x = enemy.x + (dx / distance) * enemy.speed * dt
                enemy.y = enemy.y + (dy / distance) * enemy.speed * dt
            end
            enemy.attackCooldown = enemy.attackCooldown - dt
            if player.health <= 0 then gameOver = true end
        else
            enemy.timer = enemy.timer + dt
            enemy.bobOffset = math.sin(enemy.timer * 3) * 5
            if player.x < enemy.x + 32 and player.x + player.width > enemy.x and player.y < enemy.y + 32 and player.y + player.height > enemy.y then
                player.rupees = player.rupees + 1
                table.remove(enemies, i)
            elseif enemy.timer > 10 then table.remove(enemies, i) end
        end
    end
end

function love.draw()
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    -- Draw player
    if player.attacking then
        love.graphics.draw(player.attackImages[player.direction], player.x, player.y)
    else
        love.graphics.draw(player.currentWalkImages[player.walkFrame], player.x, player.y)
    end

    -- Draw enemies and rupees
    for _, enemy in ipairs(enemies) do
        if enemy.health then
            love.graphics.draw(enemy.image, enemy.x, enemy.y)
            love.graphics.setColor(1, 0, 0)
            love.graphics.rectangle("fill", enemy.x, enemy.y - 10, enemy.width, 5)
            love.graphics.setColor(0, 1, 0)
            love.graphics.rectangle("fill", enemy.x, enemy.y - 10, (enemy.health / 200) * enemy.width, 5)
        else
            love.graphics.draw(rupeeImage, enemy.x, enemy.y + enemy.bobOffset)
        end
    end

    love.graphics.pop()

    -- Draw HUD
    love.graphics.setColor(1, 1, 1)
    -- Player health bar (fixed)
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", 10, 10, 250, 20)
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", 10, 10, player.health / 2, 20)
    love.graphics.setColor(1, 1, 1)

    -- Player stats
    love.graphics.print("Health: " .. player.health, 10, 35)
    love.graphics.print("Attack: " .. player.attack, 10, 50)
    love.graphics.print("Rupees: " .. player.rupees, 10, 65)

    -- Draw inventory (potions at top)
    for i, potion in ipairs(inventory) do
        local x = 10 + (i - 1) * 40
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", x, 70, 32, 32)
        love.graphics.draw(potion.image, x, 70)
        love.graphics.print(potion.cost, x + 10, 102)
    end

    -- Draw hotbar
    for i, slot in ipairs(hotbar.slots) do
        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(i == hotbar.selectedSlot and 3 or 1)
        love.graphics.rectangle("line", slot.x, slot.y, hotbar.slotSize, hotbar.slotSize)
        if slot.item then
            love.graphics.draw(slot.item.image, slot.x + hotbar.padding, slot.y + hotbar.padding)
        end
    end

    if gameOver then
        love.graphics.print("Game Over! Press R to restart", love.graphics.getWidth()/2 - 100, love.graphics.getHeight()/2)
    end
end
