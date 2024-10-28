-- Playdate Asteroids

--------------------------- global variables/constructs ---------------------------

local pd <const> = playdate
local gfx <const> = pd.graphics

-- create ship
local shipImage <const> = gfx.image.new("img/ship")
local shipSprite <const> = gfx.sprite.new(shipImage)
local shipRotation <const> = 7
local shipSpeed <const> = 5

-- projectiles
local projectileImage <const> = gfx.image.new(5, 5, gfx.kColorBlack)
local projectileSpeed <const> = shipSpeed * 1.5
local maxProjectiles <const> = 1
local projectiles = {}

-- initialize projectile sprites
for i=1, maxProjectiles, 1 do
    projectiles[i] = {
        sprite = gfx.sprite.new(projectileImage),
        active = false
    }
end

-- scorekeeping
local score = 0
local highestScores = {}
local highestScoresLength = 0
local maxHighScores <const> = 5
local name = "AAA"
local nameLetters = { "A", "A", "A" }
local nameIndex = 1

-- game states
local gameState = "title"
-- combined state and input handler table - to prevent issues in the future of states and input handlers getting out of sync
local states = {
    ["playing"] = {
        gameFunction = function () gameplay() end,
        inputHandler = {
            -- fire projectile when leftButton is pressed down if the crank IS NOT docked
            leftButtonDown = function()
                if not pd.isCrankDocked() then
                    fireProjectile()
                end
            end,
            -- callback to fire projectile when aButton is pressed down if the crank IS docked
            AButtonDown = function()
                if pd.isCrankDocked() then
                    fireProjectile()
                end
            end
        }
    },
    ["paused"] = {
        gameFunction = function () pauseMenu() end,
        inputHandler = {}
    },
    ["lost"] = {
        gameFunction = function () loseScreen() end,
        inputHandler = {}
    },
    ["title"] = {
        gameFunction = function () titleScreen() end,
        inputHandler = {}
    },
    ["start"] = {
        gameFunction = function () start() end,
        inputHandler = {}
    },
}


--------------------------- misc. playdate things ---------------------------

-- Loads saved data
local gameData = pd.datastore.read()
if gameData ~= nil then
    highestScores = gameData.currentHighestScores
else
    highestScores = {}
end

-- saves game data
function saveGameData()
    -- save high score leaderboard
    local gameData = {
        currentHighestScores = highestScores,
    }

    -- Serialize game data table into the datastore
    pd.datastore.write(gameData)
end

-- Automatically save game data when the player chooses
-- to exit the game via the System Menu or Menu button
function pd.gameWillTerminate()
    saveGameData()
end

-- Automatically save game data when the device goes
-- to low-power sleep mode because of a low battery
function pd.gameWillSleep()
    saveGameData()
end

function setGameState(state)
    gameState = state

    -- initial pop when setting initial state does not appear to cause issues
    pd.inputHandlers.pop()
    pd.inputHandlers.push(states[state].inputHandler)
end



--------------------------- update ---------------------------

function pd.update()
    -- run the corresponding function of the current state
    states[gameState].gameFunction()
end



--------------------------- start ---------------------------

function start()
    -- put the sprites on the screen
    spriteSetup()

    -- set the game state
    setGameState("playing")
end

function spriteSetup()
    -- add ship to center of screen
    shipSprite:moveTo(200, 120)
    shipSprite:add()
end



--------------------------- gameplay ---------------------------

function gameplay()
    -- refresh the screen
    gfx.sprite.update()

    -- player movement
    rotateShip(shipRotation)
    moveShip(shipSpeed)
    updateProjectiles()
end

-- ship angle = crank angle when undocked,
-- otherwise use d-pad left/right to rotate
function rotateShip(speed)
    if not pd.isCrankDocked() then
        shipSprite:setRotation(pd.getCrankPosition())
    else
        if pd.buttonIsPressed(pd.kButtonLeft) then
            -- rotate ship left
            shipSprite:setRotation(shipSprite:getRotation() - speed)
        elseif pd.buttonIsPressed(pd.kButtonRight) then
            -- rotate ship right
            shipSprite:setRotation(shipSprite:getRotation() + speed)
        end
    end
end

-- moves the ship in the direction it's pointing whenever the up key is pressed
function moveShip(speed)
    -- (directions are swapped because 0 degrees is straight up)
    local x_travel = math.sin(math.rad(shipSprite:getRotation())) * speed
    local y_travel = -math.cos(math.rad(shipSprite:getRotation())) * speed

    -- if the up button is pressed, move the ship in the direction it's pointing
    -- (down goes in the opposite direction)
    if pd.buttonIsPressed(pd.kButtonUp) then
        shipSprite:moveBy(x_travel, y_travel)
    elseif pd.buttonIsPressed(pd.kButtonDown) then
        shipSprite:moveBy(-x_travel, -y_travel)
    end

    -- wraps the ship around (left/right and top/bottom)
    local x, y = shipSprite:getPosition()
    local pad = 20 -- allow the ship to be fully off screen before wrapping
    if x < -pad then shipSprite:moveTo(400+pad-1, y) end
    if x > 400+pad then shipSprite:moveTo(0-pad+1, y) end
    if y < -pad then shipSprite:moveTo(x, 240+pad-1) end
    if y > 240+pad then shipSprite:moveTo(x, 0-pad+1) end
end

-- only "activates" the projectile, see updateProjectiles() for movement and checkCollisions() for collisions
function fireProjectile()
    for i,projectile in ipairs(projectiles) do
        if not projectile.active then
            activateProjectile(projectile)
            break
        end
    end
end

function activateProjectile(projectile)
    local shipX <const>, shipY <const> = shipSprite:getPosition()
    local shipRotation <const> = shipSprite:getRotation()

    projectile.active = true
    projectile.sprite:setRotation(shipRotation)
    projectile.sprite:moveTo(shipX, shipY)
    projectile.sprite:add()
end

function deactivateProjectile(projectile)
    projectile.active = false
    projectile.sprite:remove()
end

function updateProjectiles()
    for i,projectile in ipairs(projectiles) do
        if projectile.active then
            local projectileDirection <const> = projectile.sprite:getRotation()
            local x_travel <const> = math.sin(math.rad(projectileDirection)) * projectileSpeed
            local y_travel <const> = -math.cos(math.rad(projectileDirection)) * projectileSpeed
            projectile.sprite:moveBy(x_travel, y_travel);
            checkCollisions(projectile)
        end
    end
end

function checkCollisions(projectile)
    -- check collisions with sides
    local screenWidth <const>, screenHeight <const> = playdate.display.getSize()
    local x <const>, y <const> = projectile.sprite:getPosition()
    if x <= 0 or x >= screenWidth then
        deactivateProjectile(projectile)
    end
    if y <= 0 or y >= screenHeight then
        deactivateProjectile(projectile)
    end
    
    -- TODO (separate issue): check collisions with asteroids
end



--------------------------- pause menu ---------------------------

function pauseMenu()
end



--------------------------- lose screen ---------------------------

function loseScreen()
end



--------------------------- title screen ---------------------------

function titleScreen()
    drawTitle()

    updateName()

    -- start the game once up is pressed
    if pd.buttonJustPressed(pd.kButtonA) then
        setGameState("start")
    end

    -- reset scores by pressing Up and B at same time
    if pd.buttonJustPressed(pd.kButtonUp) and pd.buttonJustPressed(pd.kButtonB) then
        highestScores = {}
        highestScoresLength = 0
    end
end

function drawTitle()
    local yStart = 50

    -- title
    gfx.drawText("Playdate Asteroids", 135, 10)
    gfx.drawText("High Scores: ", 155, 30)

    -- high scores, first name than score
    for i in pairs(highestScores) do
        gfx.drawText(highestScores[i][1], 170, yStart)
        gfx.drawText(highestScores[i][2], 220, yStart)
        yStart += 20
    end

    -- enter name msg
    gfx.drawText("Enter name: ", 140, 200)
    gfx.drawText(nameLetters[1], 240, 200)
    gfx.drawText(nameLetters[2], 252, 200)
    gfx.drawText(nameLetters[3], 264, 200)

    -- start msg
    gfx.drawText("Press A to Start", 144, 220)
end

-- changes a specific letter in the player's 3-character name
function changeLetter(num, forwards)
    -- whether to increment or decrement the character
    local changeBy = -1
    if forwards then
        changeBy = 1
    end

    -- change the character
    nameLetters[num] = string.char(nameLetters[num]:byte() + changeBy)

    -- character wrapping ('A' <-> 'Z')
    if nameLetters[num]:byte() > 90 then
        nameLetters[num] = string.char(65)
    elseif nameLetters[num]:byte() < 65 then
        nameLetters[num] = string.char(90)
    end
end

-- allows the player to move between and change each name character
function updateName()
    -- switch between char positions in name
    if pd.buttonJustPressed(pd.kButtonLeft) and nameIndex > 1 then
        nameIndex -= 1
    end
    if pd.buttonJustPressed(pd.kButtonRight) and nameIndex < 3 then
        nameIndex += 1
    end

    -- update the actual character
    if pd.buttonJustPressed(pd.kButtonUp) then
        changeLetter(nameIndex, true)
    elseif pd.buttonJustPressed(pd.kButtonDown) then
        changeLetter(nameIndex, false)
    end

    -- form name from character
    name = nameLetters[1] .. nameLetters[2] .. nameLetters[3]
end

function drawBase()
    -- add ship to center of screen
    shipSprite:moveTo(200, 120)
    shipSprite:add()
end

-- moves the ship in the direction it's pointing whenever the up key is pressed
function moveShip(speed)
    -- (directions are swapped because 0 degrees is straight up)
    local x_travel = math.sin(math.rad(shipSprite:getRotation())) * speed
    local y_travel = -math.cos(math.rad(shipSprite:getRotation())) * speed

    -- if the up button is pressed, move the ship in the direction it's pointing
    -- (down goes in the opposite direction)
    if playdate.buttonIsPressed(playdate.kButtonUp) then
        shipSprite:moveBy(x_travel, y_travel)
    elseif playdate.buttonIsPressed(playdate.kButtonDown) then
        shipSprite:moveBy(-x_travel, -y_travel)
    end

    -- wraps the ship around (left/right and top/bottom)
    local x, y = shipSprite:getPosition()
    local pad = 20
    if x < -pad then shipSprite:moveTo(400+pad-1, y) end
    if x > 400+pad then shipSprite:moveTo(0-pad+1, y) end
    if y < -pad then shipSprite:moveTo(x, 240+pad-1) end
    if y > 240+pad then shipSprite:moveTo(x, 0-pad+1) end
end

-- Loads saved data
local gameData = playdate.datastore.read()
if gameData ~= nil then
    highestScores = gameData.currentHighestScores
else
    highestScores = {}
end
