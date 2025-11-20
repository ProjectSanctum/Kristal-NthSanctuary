---@class MainMenuTitle : StateClass
---
---@field menu MainMenu
---
---@field logo love.Image
---@field has_target_saves boolean
---
---@field options table
---@field selected_option number
---
---@overload fun(menu:MainMenu) : MainMenuTitle
local MainMenuTitle, super = Class(StateClass)

function MainMenuTitle:init(menu)
    self.menu = menu

	self.mod_path = nil
	self.logo_font = Assets.getFont("main")

    self.selected_option = 1
end

function MainMenuTitle:registerEvents()
    self:registerEvent("enter", self.onEnter)
    self:registerEvent("keypressed", self.onKeyPressed)
    self:registerEvent("draw", self.draw)
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function MainMenuTitle:onEnter(old_state)
    self.has_target_saves = TARGET_MOD and Kristal.hasAnySaves(TARGET_MOD) or false

    if TARGET_MOD then
        self.options = {
            {"play",    self.has_target_saves and "Load game" or "Start game"},
            {"options", "Options"},
            {"credits", "Credits"},
            {"quit",    "Quit"},
        }
    else
        self.options = {
            {"play",      "Play a mod"},
            {"modfolder", "Open mods folder"},
            {"options",   "Options"},
            {"credits",   "Credits"},
            {"wiki",      "Open wiki"},
            {"quit",      "Quit"},
        }
    end

    if not TARGET_MOD then
        self.menu.selected_mod = nil
        self.menu.selected_mod_button = nil
    end
	self.mod_path = self.menu.mod_list:getSelectedMod().path
    self.prophecy = love.graphics.newImage(self.mod_path.."/libraries/chapter4lib/assets/sprites/backgrounds/IMAGE_DEPTH_EXTEND_MONO_SEAMLESS_BRIGHTER.png")
    self.prophecy_alt = love.graphics.newImage(self.mod_path.."/libraries/chapter4lib/assets/sprites/backgrounds/IMAGE_DEPTH_EXTEND_SEAMLESS.png")
    self.perlin = love.graphics.newImage(self.mod_path.."/libraries/chapter4lib/assets/sprites/backgrounds/perlin_noise_looping.png")
    self.logo = love.graphics.newImage(self.mod_path.."/assets/sprites/logo.png")
    self.logo_grad = love.graphics.newImage(self.mod_path.."/assets/sprites/logo_gradient.png")
    self.logo_heart = love.graphics.newImage(self.mod_path.."/assets/sprites/logo_heart.png")

    self.menu.heart_target_x = 196
    self.menu.heart_target_y = 238 + 32 * (self.selected_option - 1)
end

function MainMenuTitle:onKeyPressed(key, is_repeat)
    if Input.isConfirm(key) then
        Assets.stopAndPlaySound("ui_select")

        local option = self.options[self.selected_option][1]

        if option == "play" then
            if not TARGET_MOD then
                self.menu:setState("MODSELECT")
				if MainMenu.mod_list:getSelectedMod() and MainMenu.mod_list:getSelectedMod().soulColor then
					MainMenu.heart.color = MainMenu.mod_list:getSelectedMod().soulColor
				end
            elseif self.has_target_saves then
                self.menu:setState("FILESELECT")
            else
                if not Kristal.loadMod(TARGET_MOD, 1) then
                    error("Failed to load mod: " .. TARGET_MOD)
                end
            end

        elseif option == "modfolder" then
            -- FIXME: the game might freeze when using love.system.openURL to open a file directory
            if (love.system.getOS() == "Windows") then
                os.execute('start /B \"\" \"'..love.filesystem.getSaveDirectory()..'/mods\"')
            else
                love.system.openURL("file://"..love.filesystem.getSaveDirectory().."/mods")
            end

        elseif option == "options" then
            self.menu:setState("OPTIONS")

        elseif option == "credits" then
            self.menu:setState("CREDITS")

        elseif option == "wiki" then
            love.system.openURL("https://kristal.cc/wiki")

        elseif option == "quit" then
            love.event.quit()
        end

        return true
    end

    local old = self.selected_option
    if Input.is("up"   , key)                              then self.selected_option = self.selected_option - 1 end
    if Input.is("down" , key)                              then self.selected_option = self.selected_option + 1 end
    if Input.is("left" , key) and not Input.usingGamepad() then self.selected_option = self.selected_option - 1 end
    if Input.is("right", key) and not Input.usingGamepad() then self.selected_option = self.selected_option + 1 end
    if self.selected_option > #self.options then self.selected_option = is_repeat and #self.options or 1 end
    if self.selected_option < 1             then self.selected_option = is_repeat and 1 or #self.options end

    if old ~= self.selected_option then
        Assets.stopAndPlaySound("ui_move")
    end

    self.menu.heart_target_x = 196
    self.menu.heart_target_y = 238 + (self.selected_option - 1) * 32
end

local function draw_sprite_tiled_ext(tex, _, x, y, sx, sy, color, alpha)
    local r,g,b,a = love.graphics.getColor()
    if color then
        Draw.setColor(color, alpha)
    end
    Draw.drawWrapped(tex, true, true, x, y, 0, sx, sy)
    love.graphics.setColor(r,g,b,a)
end

local function draw_set_alpha(a)
    local r,g,b = love.graphics.getColor()
    love.graphics.setColor(r,g,b,a)
end

local function oldHexToRgb(hex, value)
    local color = ColorUtils.hexToRGB(hex)
    return {
        color[1],
        color[2],
        color[3],
        color[4] * (value or 1),
    }
end

local function scr_wave(arg0, arg1, speed_seconds, phase)
    local a4 = (arg1 - arg0) * 0.5;
    return arg0 + a4 + (math.sin((((Kristal.getTime()) + (speed_seconds * phase)) / speed_seconds) * (2 * math.pi)) * a4);
end

function MainMenuTitle:draw()
    local logo_img = self.menu.selected_mod and self.menu.selected_mod.logo or self.logo
	
	if self.mod_path then
		local _cx, _cy = 0, 0

		local last_color = love.graphics.getColor()
		local surf_textured = Draw.pushCanvas(640, 480);
		love.graphics.clear(COLORS.white, 0);
		love.graphics.setColorMask(true, true, true, false);
		local pnl_tex = self.perlin
		local pnl_canvas = Draw.pushCanvas(pnl_tex:getDimensions())
		draw_sprite_tiled_ext(pnl_tex, 0, 0, 0, 1, 1, oldHexToRgb("#42D0FF", 1 or scr_wave(0.4, 0.4, 4, 0)))
		Draw.popCanvas(true)
		local x, y = -((_cx * 2) + ((Kristal.getTime()) * 30)) * 0.5, -((_cy * 2) + ((Kristal.getTime()) * 30)) * 0.5
		draw_sprite_tiled_ext(self.prophecy, 0, x, y, 2, 2, oldHexToRgb("#42D0FF", 1));
		local orig_bm, orig_am = love.graphics.getBlendMode()
		love.graphics.setBlendMode("add");
		draw_sprite_tiled_ext(pnl_canvas, 0, x, y, 2, 2, oldHexToRgb("#42D0FF", 1 or scr_wave(0.4, 0.4, 4, 0)));
		love.graphics.setBlendMode(orig_bm, orig_am);
		local surf_textured_alt = Draw.pushCanvas(640, 480);
		love.graphics.clear(oldHexToRgb("#42D0FF", 1), 0);
		love.graphics.setColorMask(true, true, true, false);
		local pnl_tex = self.perlin
		local pnl_canvas = Draw.pushCanvas(pnl_tex:getDimensions())
		draw_sprite_tiled_ext(pnl_tex, 0, 0, 0, 1, 1, oldHexToRgb("#42D0FF", 1 or scr_wave(0.4, 0.4, 4, 0)))
		Draw.popCanvas(true)
		local x, y = -((_cx * 2) + ((Kristal.getTime()) * 30)) * 0.5, -((_cy * 2) + ((Kristal.getTime()) * 30)) * 0.5
		draw_sprite_tiled_ext(self.prophecy_alt, 0, x, y, 2, 2, oldHexToRgb("#FFFFFF", 0.6));
		local orig_bm, orig_am = love.graphics.getBlendMode()
		love.graphics.setBlendMode("add", "premultiplied");
		draw_sprite_tiled_ext(pnl_canvas, 0, x, y, 2, 2, oldHexToRgb("#42D0FF", 1 or scr_wave(0.4, 0.4, 4, 0)));
		love.graphics.setBlendMode(orig_bm, orig_am);
		Draw.popCanvas()
		Draw.popCanvas()

		local float = math.sin(Kristal.getTime() * 1) * 10
		love.graphics.stencil(function()
			local last_shader = love.graphics.getShader()
			local shader = Kristal.Shaders["Mask"]
			love.graphics.setShader(shader)
			Draw.draw(self.logo, SCREEN_WIDTH/2 - self.logo:getWidth(), 105 - self.logo:getHeight() + float, 0, 2, 2)
			love.graphics.setShader(last_shader)
		end, "replace", 1)
		love.graphics.setStencilTest("greater", 0)
		Draw.setColor(1,1,1,0.7)
		Draw.drawCanvas(surf_textured)
		Draw.setColor(1,1,1,1)
		love.graphics.setStencilTest()
		
		Draw.draw(self.logo_grad, SCREEN_WIDTH/2 - self.logo:getWidth(), 105 - self.logo:getHeight() + float, 0, 2, 2)
		Draw.draw(self.logo_heart, SCREEN_WIDTH/2 - self.logo:getWidth(), 105 - self.logo:getHeight() + float, 0, 2, 2)
		local amt = 3
		love.graphics.stencil(function()
			local last_shader = love.graphics.getShader()
			local shader = Kristal.Shaders["Mask"]
			love.graphics.setShader(shader)
			love.graphics.setFont(self.logo_font)
			love.graphics.print("#th Sanctuary", SCREEN_WIDTH/2 - self.logo_font:getWidth("#th Sanctuary") - amt, 105 - self.logo_font:getHeight("#th Sanctuary") + 64 - amt + float, 0, 2, 2)
			love.graphics.print("#th Sanctuary", SCREEN_WIDTH/2 - self.logo_font:getWidth("#th Sanctuary") + amt, 105 - self.logo_font:getHeight("#th Sanctuary") + 64 + amt + float, 0, 2, 2)
			love.graphics.print("#th Sanctuary", SCREEN_WIDTH/2 - self.logo_font:getWidth("#th Sanctuary") + amt, 105 - self.logo_font:getHeight("#th Sanctuary") + 64 - amt + float, 0, 2, 2)
			love.graphics.print("#th Sanctuary", SCREEN_WIDTH/2 - self.logo_font:getWidth("#th Sanctuary") - amt, 105 - self.logo_font:getHeight("#th Sanctuary") + 64 + amt + float, 0, 2, 2)
			love.graphics.setShader(last_shader)
		end, "replace", 1)
		love.graphics.setStencilTest("greater", 0)
		Draw.setColor(0,0,0.4,0.5)
		love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
		Draw.setColor(0.3,0.3,0.6,0.2)
		Draw.drawCanvas(surf_textured_alt)
		love.graphics.setStencilTest()
		love.graphics.stencil(function()
			local last_shader = love.graphics.getShader()
			local shader = Kristal.Shaders["Mask"]
			love.graphics.setShader(shader)
			love.graphics.setFont(self.logo_font)
			love.graphics.print("#th Sanctuary", SCREEN_WIDTH/2 - self.logo_font:getWidth("#th Sanctuary") - amt, 105 - self.logo_font:getHeight("#th Sanctuary") + 64 + float, 0, 2, 2)
			love.graphics.print("#th Sanctuary", SCREEN_WIDTH/2 - self.logo_font:getWidth("#th Sanctuary") + amt, 105 - self.logo_font:getHeight("#th Sanctuary") + 64 + float, 0, 2, 2)
			love.graphics.print("#th Sanctuary", SCREEN_WIDTH/2 - self.logo_font:getWidth("#th Sanctuary"), 105 - self.logo_font:getHeight("#th Sanctuary") + 64 - amt + float, 0, 2, 2)
			love.graphics.print("#th Sanctuary", SCREEN_WIDTH/2 - self.logo_font:getWidth("#th Sanctuary"), 105 - self.logo_font:getHeight("#th Sanctuary") + 64 + amt + float, 0, 2, 2)
			love.graphics.setShader(last_shader)
		end, "replace", 1)
		love.graphics.setStencilTest("greater", 0)
		Draw.setColor(0,0,0.5,1)
		love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
		Draw.setColor(0.5,0.5,0.7,0.5)
		Draw.drawCanvas(surf_textured_alt)
		love.graphics.setStencilTest()
		love.graphics.stencil(function()
			local last_shader = love.graphics.getShader()
			local shader = Kristal.Shaders["Mask"]
			love.graphics.setShader(shader)
			love.graphics.setFont(self.logo_font)
			love.graphics.print("#th Sanctuary", SCREEN_WIDTH/2 - self.logo_font:getWidth("#th Sanctuary"), 105 - self.logo_font:getHeight("#th Sanctuary") + 64 + float, 0, 2, 2)
			love.graphics.setShader(last_shader)
		end, "replace", 1)
		love.graphics.setStencilTest("greater", 0)
		Draw.setColor(1,1,1,1)
		Draw.drawCanvas(surf_textured_alt)
		love.graphics.setStencilTest()
	end
    --Draw.draw(self.selected_mod and self.selected_mod.logo or self.logo, 160, 70)

    for i, option in ipairs(self.options) do
        Draw.printShadow(option[2], 215, 219 + 32 * (i - 1))
    end
end

-------------------------------------------------------------------------------
-- Class Methods
-------------------------------------------------------------------------------

function MainMenuTitle:selectOption(id)
    for i, options in ipairs(self.options) do
        if options[1] == id then
            self.selected_option = i

            self.menu.heart_target_x = 196
            self.menu.heart_target_y = 238 + (self.selected_option - 1) * 32

            return true
        end
    end

    return false
end

return MainMenuTitle
