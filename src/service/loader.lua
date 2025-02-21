local image = require "soluna.image"
local spritepack = require "soluna.spritepack"

local missing = {}

local function fetchfile(filecache, filename)
	local f = io.open(filename, "rb")
	if not f then
		if not missing[filename] then
			missing[filename] = true
			print("Missing file : " .. filename)
		end
		return
	end
	local content = f:read "a"
	f:close()
	local data, w, h = image.load(content)
	if data == nil then
		if not missing[filename] then
			missing[filename] = true
			print("Invalid image : " .. filename .. "(" .. w .. ")")
		end
		return
	end
	local r = { data = data, w = w, h = h }
	filecache[filename] = r
	return r
end

-- todo: make weak table
--local filecache = setmetatable({} , { __mode = "kv", __index = fetchfile })
local filecache = setmetatable({} , { __index = fetchfile })

local S = {}

local sprite = {}

function S.load(filename, offx, offy, x, y, w, h)
	local c = filecache[filename]
	if c == nil then
		return
	end
	local index = image.makeindex(x, y, w, h)
	if offx < 0 then
		offx = - c.w * offx // 1 | 0
	end
	if offy < 0 then
		offy = - c.h * offy // 1 | 0
	end
	local obj = c[index]
	if obj then
		assert(obj.x == offx and obj.y == offy)
		return obj.id
	end
	local cx, cy, cw, ch = image.crop(c.data, c.w, c.h, x, y, w, h)
	offx = offx - cx
	offy = offy - cy
	local id = #sprite+1
	sprite[id] = {
		filename = filename,
		index = index,
		id = id,
		x = offx,
		y = offy,
		cx = cx + (x or 0),
		cy = cy + (y or 0),
		cw = cw,
		ch = ch,
	}
	return id
end

-- todo: packing should be out of loader 
function S.pack(width)
	local n = #sprite
	local pack = spritepack.pack(n)
	for i=1,n do
		local s = sprite[i]
		pack:add(i, s.cw, s.ch)
	end
	local r = pack:run(width)
	for id,v in pairs(r) do
		local x = v >> 32
		local y = v & 0xffffffff
		local obj = sprite[id]
		local c = filecache[obj.filename]
		local data = image.canvas(c.data, c.w, c.h, obj.cx, obj.cy, obj.cw, obj.ch)
		local w, h, ptr = image.canvas_size(data)
		r[id] = { id = id, data = ptr, x = x, y = y, w = w, h = h, stride = c.w * 4, dx = obj.x, dy = obj.y }
	end
	return r
end

function S.write(id, filename)
	local obj = sprite[id]
	assert(obj.cx)
	local c = filecache[obj.filename]
	local data = image.canvas(c.data, c.w, c.h, obj.cx, obj.cy, obj.cw, obj.ch)
	local img = image.new(obj.cw, obj.ch)
	image.blit(img:canvas(), data)
	img:write(filename)
end

return S