-- Playdate Asteroids

local gfx <const> = playdate.graphics

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

-- better scheme for tracking gamestate
-- 0 for normal gameplay, 1 for pause, 2 for loss
local playing <const>, paused <const>, lost <const>, title <const>, start <const> = 0, 1, 2, 3, 4
local gameState = title

function saveGameData()
    -- save high score leaderboard
    local gameData = {
        currentHighestScores = highestScores,
    }

    -- Serialize game data table into the datastore
    playdate.datastore.write(gameData)
end

-- Automatically save game data when the player chooses
-- to exit the game via the System Menu or Menu button
function playdate.gameWillTerminate()
    saveGameData()
end

-- Automatically save game data when the device goes
-- to low-power sleep mode because of a low battery
function playdate.gameWillSleep()
    saveGameData()
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

-- displays title screen, lets player change name, lets players tart game
function titleScreenLogic()
    drawTitle()

    -- switch between char positions in name
    if playdate.buttonJustPressed(playdate.kButtonLeft) and nameIndex > 1 then
        nameIndex -= 1
    end
    if playdate.buttonJustPressed(playdate.kButtonRight) and nameIndex < 3 then
        nameIndex += 1
    end

    -- update the actual character
    if playdate.buttonJustPressed(playdate.kButtonUp) then
        changeLetter(nameIndex, true)
    elseif playdate.buttonJustPressed(playdate.kButtonDown) then
        changeLetter(nameIndex, false)
    end

    -- form name from character
    name = nameLetters[1] .. nameLetters[2] .. nameLetters[3]

    if playdate.buttonJustPressed(playdate.kButtonA) then
        gameState = start
    end

    -- reset scores by pressing Up and B at same time
    if playdate.buttonJustPressed(playdate.kButtonUp) and playdate.buttonJustPressed(playdate.kButtonB) then
        highestScores = {}
        highestScoresLength = 0
    end
end

function drawBase()
    -- add ship to center of screen
    shipSprite:moveTo(200, 120)
    shipSprite:add()
end

-- Loads saved data
local gameData = playdate.datastore.read()
if gameData ~= nil then
    highestScores = gameData.currentHighestScores
else
    highestScores = {}
end

function playdate.update()
    -- refresh screen
    if gameState ~= lost then
        gfx.sprite.update()
    end
    
    -- title screen
    if gameState == title then
        titleScreenLogic()
        return
    end

    if gameState == start then
        drawBase()
        gameState = playing

        return -- not necessary, but allows cleaner code below (and doesn't cost much)
    end
end
