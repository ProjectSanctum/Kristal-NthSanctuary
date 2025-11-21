local Loading = {}

function Loading:init()
    self.prophecy = love.graphics.newImage("mods/nth-sanctuary/libraries/chapter4lib/assets/sprites/backgrounds/IMAGE_DEPTH_EXTEND_MONO_SEAMLESS_BRIGHTER.png")
    self.perlin = love.graphics.newImage("mods/nth-sanctuary/libraries/chapter4lib/assets/sprites/backgrounds/perlin_noise_looping.png")
    self.rune = love.graphics.newImage("mods/nth-sanctuary/assets/sprites/world/events/prophecy/rune.png")
	self.ground_shard_frames = {}
	for i = 1, 4 do
		local frame = love.graphics.newImage("mods/nth-sanctuary/assets/sprites/effects/firework_shine_"..i..".png")
		table.insert(self.ground_shard_frames, frame)
	end
	self.rune_shatter = {}
	self.ground_shards = {}
	self.ground_shards_afterimage = {}
	local rune_pieces = 116
	for i = 1, rune_pieces do
		local piece = love.graphics.newImage("assets/sprites/kristal/rune_shatter/rune_piece_"..i..".png")
		table.insert(self.rune_shatter, {tex = piece, x = SCREEN_WIDTH/2, y = SCREEN_HEIGHT/2, dir = 0, grav = 0, spd = 0})
	end
    self.scroll_speed = 2;
end

---@enum Loading.States
Loading.States = {
    WAITING = 0,
    LOADING = 1,
    DONE = 2,
}

function Loading:enter(from, dir)
    Mod = nil
    MOD_PATH = nil

    self.loading_state = Loading.States.WAITING

    self.animation_done = false

    self.w = self.rune:getWidth()
    self.h = self.rune:getHeight()

    if not Kristal.Config["skipIntro"] then
        self.break1 = love.audio.newSource("assets/sounds/break1.wav", "static")
        self.end_noise = love.audio.newSource("assets/sounds/nthsanctum_intro_end.ogg", "static")
    else
        self:beginLoad()
    end

    self.siner = 0
    self.prophecy_siner = 0
    self.shard_afterimage_timer = 0
    self.factor = 1
    self.factor2 = 0
    self.x = (320 / 2) - (self.w / 2)
    self.y = (240 / 2) - (self.h / 2) - 10
    self.animation_phase = 0
    self.animation_phase_timer = 0
    self.animation_phase_plus = 0
    self.logo_alpha = 1
    self.logo_alpha_2 = 1
    self.skipped = false
    self.skiptimer = 0
    self.key_check = not Kristal.Args["wait"]

    self.fader_alpha = 0

    self.done_loading = false
end

function Loading:beginLoad()
    Kristal.clearAssets(true)

    self.loading_state = Loading.States.LOADING

    Kristal.loadAssets("", "all", "")
    Kristal.loadAssets("", "mods", "", function()
        self.loading_state = Loading.States.DONE

        Assets.saveData()

        Kristal.setDesiredWindowTitleAndIcon()

        -- Create the debug console
        Kristal.Console = Kristal.Stage:addChild(Console())
        -- Create the debug system
        Kristal.DebugSystem = Kristal.Stage:addChild(DebugSystem())

        REGISTRY_LOADED = true
    end)
end

function Loading:update()
    if self.done_loading then
        return
    end

    if (self.loading_state == Loading.States.DONE) and self.key_check and (self.animation_done or Kristal.Config["skipIntro"]) then
        -- We're done loading! This should only happen once.
        self.done_loading = true

        if Kristal.Args["test"] then
            Kristal.setState("Testing")
        elseif AUTO_MOD_START and TARGET_MOD then
            if not Kristal.loadMod(TARGET_MOD) then
                error("Failed to load mod: " .. TARGET_MOD)
            end
        else
            Kristal.setState("MainMenu")
        end
    end
end

function Loading:drawScissor(image, left, top, width, height, x, y, alpha)
    love.graphics.push()

    local scissor_x = ((math.floor(x) >= 0) and math.floor(x) or 0)
    local scissor_y = ((math.floor(y) >= 0) and math.floor(y) or 0)
    love.graphics.setScissor(scissor_x, scissor_y, width, height)

    Draw.setColor(1, 1, 1, alpha)
    Draw.draw(image, math.floor(x) - left, math.floor(y) - top)
    Draw.setColor(1, 1, 1, 1)
    love.graphics.setScissor()
    love.graphics.pop()
end

function Loading:oldHexToRgb(hex, value)
    local color = ColorUtils.hexToRGB(hex)
    return {
        color[1],
        color[2],
        color[3],
        color[4] * (value or 1),
    }
end

function Loading:scr_wave(arg0, arg1, speed_seconds, phase)
    local a4 = (arg1 - arg0) * 0.5;
    return arg0 + a4 + (math.sin((((Kristal.getTime()) + (speed_seconds * phase)) / speed_seconds) * (2 * math.pi)) * a4);
end

function Loading:drawSprite(x, y)
    love.graphics.push()
    local _cx, _cy = 0, 0

    local surf_textured = Draw.pushCanvas(640, 480);
    love.graphics.clear(COLORS.white, 0);
    local pnl_canvas = Draw.pushCanvas(self.perlin:getDimensions())
	love.graphics.setColor(self:oldHexToRgb("#42D0FF", self:scr_wave(0, 0.4, 4, 0)))
    Draw.drawWrapped(self.perlin, true, true, 0, 0, 0, 1, 1)
    Draw.popCanvas(true)
    love.graphics.setColorMask(true, true, true, false);
    local xx, yy = -((_cx * 2) + (self.prophecy_siner * 15)) * 0.5, -((_cy * 2) + (self.prophecy_siner * 15)) * 0.5
	love.graphics.setColor(ColorUtils.hexToRGB("#42D0FF", 1))
    Draw.drawWrapped(self.prophecy, true, true, xx, yy, 0, 2, 2)
	love.graphics.setColor(1,1,1,1)
    local orig_bm, orig_am = love.graphics.getBlendMode()
    love.graphics.setBlendMode("add", "premultiplied");
    Draw.drawWrapped(pnl_canvas, true, true, xx, yy, 0, 2, 2)
	love.graphics.setColor(1,1,1,1)
    love.graphics.setBlendMode(orig_bm, orig_am);
    Draw.popCanvas()
    love.graphics.setColorMask(true, true, true, true);
	
    love.graphics.stencil(function()
        local last_shader = love.graphics.getShader()
        local shader = Kristal.Shaders["Mask"]
        love.graphics.setShader(shader)
        local runeox, runeoy = self.rune:getWidth()/2, self.rune:getHeight()/2
        love.graphics.draw(self.rune, SCREEN_WIDTH/2+x, SCREEN_HEIGHT/2+y, 0, 2, 2, runeox, runeoy)
        love.graphics.setShader(last_shader)
    end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)
	Draw.setColor(1,1,1,0.7)
    Draw.drawCanvas(surf_textured);
	Draw.setColor(1,1,1,1)
    love.graphics.setStencilTest()
    love.graphics.pop()
end

function Loading:drawBrokenSprite()
    love.graphics.push()
	for i, piece in ipairs(self.rune_shatter) do
		local dt_mult = DT * 30
        local runeox, runeoy = self.rune:getWidth()/2, self.rune:getHeight()/2
        local speed_x, speed_y = math.cos(piece.dir) * piece.spd, math.sin(piece.dir) * piece.spd
        local new_speed_x = speed_x + math.cos(math.pi / 2) * (piece.grav * dt_mult)
        local new_speed_y = speed_y + math.sin(math.pi / 2) * (piece.grav * dt_mult)
		piece.dir = math.atan2(new_speed_y, new_speed_x)
        piece.spd = math.sqrt(new_speed_x * new_speed_x + new_speed_y * new_speed_y)
		piece.x = piece.x + speed_x
		piece.y = piece.y + speed_y
		if self.rune_shatter[i] then
			love.graphics.draw(self.rune_shatter[i].tex, piece.x, piece.y, 0, 2, 2, runeox, runeoy)
		end
	end
	for _, shard in ipairs(self.ground_shards_afterimage) do
		local dt_mult = DT * 30
		shard.alpha = shard.alpha - 0.04 * dt_mult
		love.graphics.setColor(1,1,1,shard.alpha)
		love.graphics.draw(self.ground_shard_frames[(math.floor(shard.frame) % 4) + 1], shard.x, shard.y, 0, 1, 1, 2, 2)
		love.graphics.setColor(1,1,1,1)
	end
	for _, shard in ipairs(self.ground_shards) do
		local dt_mult = DT * 30
		shard.y = shard.y + 4 * dt_mult
		local frame = self.siner/6
		if self.shard_afterimage_timer >= 8 then
			table.insert(self.ground_shards_afterimage, {frame = frame + shard.frame_add, x = shard.x, y = shard.y, alpha = 1})
		end
		love.graphics.draw(self.ground_shard_frames[(math.floor(frame + shard.frame_add) % 4) + 1], shard.x, shard.y, 0, 2, 2, 2, 2)
	end
    love.graphics.pop()
end

function Loading:draw()
    if Kristal.Config["skipIntro"] then
        love.graphics.push()
		local dt_mult = DT * 30
        self.prophecy_siner = self.prophecy_siner + ((1/15)*self.scroll_speed) * dt_mult
		local amt = math.sin((self.prophecy_siner / 15) * (2 * math.pi)) * (self.scroll_speed * 6)
		self:drawSprite(-amt, -amt, 0.5)
		self:drawSprite(amt, amt, 0.5)
		love.graphics.setColor(0, 0, 0, 0.6)
		love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
		love.graphics.setColor(1, 1, 1, 1)
        self:drawSprite(0, 0)
        love.graphics.pop()
        return
    end

    local dt_mult = DT * 30

    -- We need to draw the logo on a canvas
    local logo_canvas = Draw.pushCanvas(640, 488)
    love.graphics.clear()

    if (self.animation_phase == 0) then
        self.siner = self.siner + 1 * dt_mult
        if (self.siner >= 30) then
            self.siner = 0
            self.animation_phase = 1
            if self.loading_state == Loading.States.WAITING then
                self:beginLoad()
            end
        end
    end
    if (self.animation_phase == 1) then
        self.siner = self.siner + 1 * dt_mult
        self.prophecy_siner = self.prophecy_siner + ((1/15)*self.scroll_speed) * dt_mult
		local amt = math.sin((self.prophecy_siner / 15) * (2 * math.pi)) * (self.scroll_speed * 6)
		self:drawSprite(-amt, -amt, 0.5)
		self:drawSprite(amt, amt, 0.5)
		love.graphics.setColor(0, 0, 0, 0.6)
		love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
		love.graphics.setColor(1, 1, 1, 1)
        self:drawSprite(0, 0)
        if (self.loading_state == Loading.States.DONE) then
            self.siner = 0
            self.animation_phase = 2
        end
    end
    if (self.animation_phase == 2) then
        self.siner = self.siner + 1 * dt_mult
        self.prophecy_siner = self.prophecy_siner + ((1/15)*self.scroll_speed) * dt_mult
		if self.siner <= 67 then
			self.scroll_speed = MathUtils.lerp(self.scroll_speed, 0, (1/26)*dt_mult)
			local amt = math.sin((self.prophecy_siner / 15) * (2 * math.pi)) * (self.scroll_speed * 6)
			self:drawSprite(-amt, -amt)
			self:drawSprite(amt, amt)
			love.graphics.setColor(0, 0, 0, 0.6)
			love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
			love.graphics.setColor(1, 1, 1, 1)
			self:drawSprite(0, 0)
		else
            self.siner = 0
			self.break1:play()
            self.animation_phase = 3
		end
    end
    if (self.animation_phase == 3) then
        self.siner = self.siner + 1 * dt_mult
		self:drawBrokenSprite()
        if (self.siner >= 20) then
            self.siner = 0
			for _, piece in ipairs(self.rune_shatter) do
				piece.dir = math.rad(MathUtils.random(360))
				piece.grav = 0.4 + MathUtils.random(0.12)
				piece.spd = 4
			end
			for i = 1,15 do
				local width = 120
				table.insert(self.ground_shards, {frame_add = MathUtils.randomInt(0, 3), x = SCREEN_WIDTH/2 - width + (((i-1) * width*2) / 15) + MathUtils.random(-30, 30), y = SCREEN_HEIGHT/2 + MathUtils.random(70)})
				if i == 1 then
					self.ground_shards[i].x = SCREEN_WIDTH/2 - width
				end
				if i == 15 then
					self.ground_shards[i].x = SCREEN_WIDTH/2 + width
				end
			end
			self.end_noise:play()
            self.animation_phase = 4
        end
    end
    if (self.animation_phase == 4) then
        self.siner = self.siner + 1 * dt_mult
		self.shard_afterimage_timer = self.shard_afterimage_timer + 1 * dt_mult
		self:drawBrokenSprite()
		if self.shard_afterimage_timer >= 8 then
			self.shard_afterimage_timer = 0
		end
        if (self.siner >= 120 and self.skipped == false) then
            self.animation_done = true
        end
    end

    -- Reset canvas to draw to
    Draw.popCanvas()

    -- Draw the canvas on the screen scaled by 2x
    Draw.setColor(1, 1, 1, 1)
    Draw.draw(logo_canvas, 0, 0, 0, 1, 1)

    if self.skipped then
        -- Draw the screen fade
        Draw.setColor(0, 0, 0, self.fader_alpha)
        love.graphics.rectangle("fill", 0, 0, 640, 480)

        if self.fader_alpha > 1 then
            self.animation_done = true
            self.break1:stop()
            self.end_noise:stop()
        end

        -- Change the fade opacity for the next frame
        self.fader_alpha = math.max(0, self.fader_alpha + (0.04 * dt_mult))
        self.break1:setVolume(math.max(0, 1 - self.fader_alpha))
        self.end_noise:setVolume(math.max(0, 1 - self.fader_alpha))
    end

    -- Reset the draw color
    Draw.setColor(1, 1, 1, 1)
end

function Loading:onKeyPressed(key)
    self.key_check = true
    self.skipped = true
    if self.loading_state == Loading.States.WAITING then
        self:beginLoad()
    end
end

return Loading
