---@alias Cell "FOREST" | "LAND" | "WATER"
---@alias int integer
---@alias bool boolean
---@alias PartialCell Cell | Cell[]
---@alias Grid PartialCell[][]
---@class (exact) Pos
---@field x int
---@field y int

local socket = require("socket")
local WIDTH, HEIGHT = 10, 10

---@type table<Cell, table<Cell, boolean>>
local connections = {
	FOREST = { LAND = true, FOREST = true },
	LAND = { WATER = true, FOREST = true, LAND = true },
	WATER = { LAND = true, WATER = true },
}

---@type Grid
local world = {}
for _ = 1, HEIGHT do
	local cur = {}
	for _ = 1, WIDTH do
		table.insert(cur, { "FOREST", "LAND", "WATER" })
	end
	table.insert(world, cur)
end

---@param grid Grid
---@param fn fun(x: int, y: int, row: PartialCell[], val: PartialCell)
local function ApplyToGrid(grid, fn)
	for y, row in ipairs(grid) do
		for x, val in ipairs(row) do
			fn(x, y, row, val)
		end
	end
end

---@param grid Grid
---@return string rendered
local function RenderGrid(grid)
	local building = ""
	local oy = 1
	ApplyToGrid(grid, function(x, y, row, val)
		if oy ~= y then
			building = building .. "\n"
			oy = y
		end
		if type(val) ~= "string" then
			building = building .. " "
			return
		end
		building = building .. val:sub(1, 1)
	end)
	return building
end

---@param cell PartialCell
---@param value Cell
local function PropogateToCell(cell, value)
	if type(cell) ~= "table" then
		return
	end
	local i = 1
	while i <= #cell do
		if not connections[cell[i]][value] then
			table.remove(cell, i)
		else
			i = i + 1
		end
	end
end

---@param grid Grid
---@return bool collapsed
local function CollapseCell(grid)
	local best_c = 999
	---@type Pos[]
	local best = {}
	ApplyToGrid(grid, function(x, y, row, val)
		if type(val) ~= "table" then
			return
		end
		if #val < best_c then
			best = { { x = x, y = y } }
			best_c = #val
		elseif #val == best_c then
			table.insert(best, { x = x, y = y })
		end
	end)
	if #best == 0 then
		print("no cells found!", best_c)
		return false
	end
	print(best_c)
	local pos = best[math.random(1, #best)]
	local cell = grid[pos.y][pos.x]
	if #cell == 0 then
		print("error! @ x: " .. pos.x .. " y: " .. pos.y)
	end
	local collapse_to = cell[math.random(1, #cell)]
	print("collapsing to:", collapse_to)
	if pos.x > 1 then
		PropogateToCell(grid[pos.y][pos.x - 1], collapse_to)
	end
	if pos.x < WIDTH then
		PropogateToCell(grid[pos.y][pos.x + 1], collapse_to)
	end
	if pos.y > 1 then
		PropogateToCell(grid[pos.y - 1][pos.x], collapse_to)
	end
	if pos.y < HEIGHT then
		PropogateToCell(grid[pos.y + 1][pos.x], collapse_to)
	end
	grid[pos.y][pos.x] = collapse_to
	return true
end

while true do
	CollapseCell(world)
	print("new world: ")
	print(RenderGrid(world))
	socket.sleep(0.1)
end