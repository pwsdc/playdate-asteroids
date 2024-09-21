local gfx <const> = playdate.graphics

function playdate.update()
    gfx.drawText("Hello World!", 170, 110)
    gfx.sprite.update()
end
