local ltask = require "ltask"
local message = require "soluna.appmessage"
local draw = require "soluna.draw"
local render = require "soluna.render"
local image = require "soluna.image"
local spritepack = require "soluna.spritepack"

local loader = ltask.uniqueservice "loader"

local STATE, RECT

local S = {}

ltask.send(1, "external_forward", ltask.self(), "external")

local command = {}

function command.frame()
	if STATE then
		STATE.pass:begin()
			STATE.pipeline:apply()
			STATE.uniform:apply()
			draw.commit(STATE.bindings, RECT.dx, RECT.dy, RECT.x, RECT.y, RECT.w, RECT.h)
		STATE.pass:finish()
		render.submit()
	end
end

function command.cleanup()
	ltask.send(1, "quit_ltask")
end

local function dispatch(type, ...)
	local f =command[type]
	if f then
		f(...)
	else
--		todo:	
--		print(type, ...)
	end
end

function S.external(p)
	dispatch(message.unpack(p))
end

function S.init(arg)
	assert(STATE == nil)
	
	local img_width = 1024
	local img_height = 1024
	
	local img = render.image {
		width = img_width,
		height = img_height,
	}
	
	local inst_buffer = render.buffer {
		type = "vertex",
		usage = "stream",
		label = "texquad-instance",
		size = 24,	-- 2 * sizeof(float) * 3
	}
	local sr_buffer = render.buffer {
		type = "storage",
		usage = "dynamic",
		label = "texquad-scalerot",
		size = 4096 * 4 * 4,	-- 4096 float * 4
	}
	local sprite_buffer = render.buffer {
		type = "storage",
		usage = "stream",
		label =  "texquad-scalerot",
		size = 128 * 3 * 4, -- 128 int32 * 3
	}

	local S = draw.init(img:id(), inst_buffer:id(), sr_buffer:id(), sprite_buffer:id())
	
	-- todo: don't load texture here
	local id = ltask.call(loader, "load", "asset/avatar.png", -0.5, -1)
	local rect = ltask.call(loader, "pack", img_width)

	local imgmem = image.new(img_width, img_height)
	local canvas = imgmem:canvas()
	local r
	for id, v in pairs(rect) do
		local src = image.canvas(v.data, v.w, v.h, v.stride)
		image.blit(canvas, src, v.x, v.y)
		r = v
	end
	RECT = {
		dx = r.dx,
		dy = r.dy,
		x = r.x,
		y = r.y,
		w = r.w,
		h = r.h,
	}
	img:update(imgmem)
	
	STATE = {
		bindings = S,
		pass = render.pass {
			color0 = 0x4080c0,
		},
		pipeline = render.pipeline "default",
	}
	STATE.uniform = STATE.pipeline:uniform_slot(0):init {
		tex_width = {
			offset = 0,
			type = "float",
		},
		tex_height = {
			offset = 4,
			type = "float",
		},
		framesize = {
			offset = 8,
			type = "float",
			n = 2,
		},
	}
	STATE.uniform.framesize = { 2/arg.width, -2/arg.height }
	STATE.uniform.tex_width = 1/img_width
	STATE.uniform.tex_height = 1/img_height
end

return S
