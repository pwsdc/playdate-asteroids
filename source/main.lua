-- Playdate Asteroids

local pd <const> = playdate
local gfx <const> = pd.graphics

-- create ship
local shipImage <const> = gfx.image.new("img/ship")
local shipSprite <const> = gfx.sprite.new(shipImage)

-- create projectile that ship shoots
local projectileImage <const> = gfx.image.new(5, 5, gfx.kColorBlack)
local projectileSprite <const> = gfx.sprite.new(projectileImage)
local isProjectileFired = false

-- scorekeeping
local score = 0
local highestScores = {}
local highestScoresLength = 0
local maxHighScores <const> = 5
local name = "AAA"
local nameLetters = { "A", "A", "A" }
local nameIndex = 1

local gameState = "title"
local states = {
    ["playing"] = gameplay,
    ["paused"] = pause_menu,
    ["lost"] = lose_screen,
    ["title"] = title_screen,
    ["start"] = start
}


--------------------------- misc. playdate things ---------------------------

-- Loads saved data
local gameData = pd.datastore.read()
if gameData ~= nil then
    highestScores = gameData.currentHighestScores
else
    highestScores = {}
end

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


--------------------------- written functions ---------------------------

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

function handle_name()
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
    local pad = 20
    if x < -pad then shipSprite:moveTo(400+pad-1, y) end
    if x > 400+pad then shipSprite:moveTo(0-pad+1, y) end
    if y < -pad then shipSprite:moveTo(x, 240+pad-1) end
    if y > 240+pad then shipSprite:moveTo(x, 0-pad+1) end
end


--------------------------- update ---------------------------

function pd.update()
    -- run the corresponding function of the current state
    local func = states[gameState]
    func()
end


--------------------------- state functions ---------------------------

function gameplay()
    -- refresh the screen
    gfx.sprite.update()

    -- player movement
    rotateShip(7)
    moveShip(5)
end



function pause_menu()
end



function lose_screen()
end



function title_screen()
    drawTitle()

    handle_name()

    if pd.buttonJustPressed(pd.kButtonA) then
        gameState = "start"
    end

    -- reset scores by pressing Up and B at same time
    if pd.buttonJustPressed(pd.kButtonUp) and pd.buttonJustPressed(pd.kButtonB) then
        highestScores = {}
        highestScoresLength = 0
    end
end



function start()
    -- draw the basic elements to the screen
    drawBase()

    -- set the game state
    gameState = "playing"
end