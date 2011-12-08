-- This file (and conf.lua) are a demonstration of TLpath and how to use it.
-- They are NOT required to use it (only TLpath.lua and TSerial.lua are)

require("TLpath")


function love.load()
	math.randomseed(os.time())
	mapTime = 0
	
	-- Returns the distance between two points.
	function math.dist(a, b) return ((b.x-a.x)^2+(b.y-a.y)^2)^0.5 end
	-- Normalizes two numbers.
	function math.normalize(x,y) local l=(x*x+y*y)^.5 if l==0 then return 0,0,0 else return x/l,y/l,l end end
	-- Returns the beacon nearest to a given bot
	function findNearest(bot)
		local nearest,dist = nil,math.huge
		for k,b in ipairs(beacons) do local d=math.dist(b,bot) if d<dist then nearest,dist=k,d end end
		return nearest
	end
	
	makeMap(true)
end


function makeMap(new)
	if new then		-- Make a new random map.
		beacons,bots,walls = {},{},{}
		if randommap or math.random(2)~=1 then	-- random or grid
			for i=0,40 do beacons[i] = {x=math.random(20,780),y=math.random(70,580)} end
			for i=0,16 do
				local x,y = math.random(120,680),math.random(10,680)
				walls[i] = { {x=x+math.random(-300,100),y=y+math.random(-300,100)}, {x=x+math.random(-300,300),y=y+math.random(-300,300)} }
			end
		else	-- gridlike map
			for x=105,700,70 do for y=105,500,70 do table.insert(beacons, {x=x,y=y}) end end
			for i=0,48 do
				local x,y,s=math.random(10),math.random(8),math.random(2)==1
				walls[i] = {
					{ x=(x+(s and math.random(-2,2) or 0))*70, y=(y+(s and 0 or math.random(-2,2)))*70, },
					{ x=(x+(s and math.random(-2,2) or 0))*70, y=(y+(s and 0 or math.random(-2,2)))*70, }
				}
			end
		end
		for i=0,40 do local b=beacons[math.random(#beacons)] bots[i] = {x=b.x,y=b.y, speed=100} end
		goal = math.random(#beacons)
	end
	
	-- Use a custom g function in TLpath which prevents bots from finding paths through walls
	-- Note how the code is a string! Using [[ and ]] for a long-format string is your friend here.
	TLpath.setGfunction(
		[[local function checkIntersect(l1p1, l1p2, l2p1, l2p2)		-- checks if two line segments intersect
			local function sign(n) return n>0 and 1 or n<0 and -1 or 0 end
			local function checkDir(pt1, pt2, pt3) return sign(((pt2.x-pt1.x)*(pt3.y-pt1.y)) - ((pt3.x-pt1.x)*(pt2.y-pt1.y))) end
			return (checkDir(l1p1,l1p2,l2p1) ~= checkDir(l1p1,l1p2,l2p2)) and (checkDir(l2p1,l2p2,l1p1) ~= checkDir(l2p1,l2p2,l1p2))
		end
		
		local blocked=false
		for k3,w in ipairs(]]..TSerial.pack(walls)..[[) do	-- TSerial packs tables as Lua code, making it very handy in this situation!
			if checkIntersect(a,b, w[1],w[2]) then blocked=true break end	-- a and b are the two nodes in question; is there a wall between them?
		end
		if blocked then return nil					-- return nil to specify that the nodes aren't connected
		else return ((b.x-a.x)^2+(b.y-a.y)^2)^0.5	-- return the distance between them if they are (distance is the best g-factor in 99% of cases)
		end]]
	)
	-- Tell TLpath that the nodes have changed
	TLpath.calcNodes(beacons)
	
	for k,bot in ipairs(bots) do
		-- To find a path, TLpath requires entities to have a starting node!
		bot.path = {findNearest(bot)}
		-- Have TLpath find paths for each bot, and stream back results as it finds them.
		TLpath.findPath(bot, goal)		-- each bot goes towards the goal
		--TLpath.findPath(bot, bot.goal)	-- each bot finds its own goal
	end
end


function love.keypressed(k)
	if k=="escape" then love.event.push("q")
	elseif k=="e" then makeMap(false)	-- remake the node graph
	elseif k=="r" then mapTime = mapTime==-1 and math.huge or -1
	end
end


function love.mousepressed(x,y,b)
	-- All of this stuff is just for editing the map, and is unimportant to TLpath.
	if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
		if b=="l" then
			table.insert(walls, {{x=x,y=y}, {x=x+math.random(-100,100),y=y+math.random(-100,100)}})
		elseif b=="r" then
			local nearest, ndist = nil,math.huge
			for k,w in ipairs(walls) do
				for i=1,2 do local dist = math.dist({x=x,y=y}, w[i]) if dist<ndist then nearest,ndist = k,dist end end
				local dist = math.dist({x=x,y=y}, {x=(w[2].x+w[1].x)/2, y=(w[2].y+w[1].y)/2}) if dist<ndist then nearest,ndist = k,dist end
			end
			table.remove(walls, nearest)
		end
	elseif love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
		if b=="l" then
			table.insert(bots, {x=x,y=y, speed=100})
			bots[#bots].path = {findNearest(bots[#bots])}
		elseif b=="r" then
			if #bots <= 1 then return end
			local nearest, ndist = nil,math.huge
			for k,bot in ipairs(bots) do local dist = math.dist({x=x,y=y}, bot) if dist<ndist then nearest,ndist = k,dist end end
			table.remove(bots, nearest)
		end
	else
		if b=="l" then	
			table.insert(beacons, {x=x,y=y,claimed=false})
		elseif b=="r" then
			local nearest, ndist = nil,math.huge
			for k,b in ipairs(beacons) do local dist = math.dist({x=x,y=y}, b) if dist<ndist then nearest,ndist = k,dist end end
			table.remove(beacons, nearest)
			-- prevent silly things from happening
			if nearest <= goal then goal = goal-1 end
			for k,bot in ipairs(bots) do bot.path = {findNearest(bot)} end
		elseif b=="m" then
			local nearest, ndist = nil,math.huge
			for k,b in ipairs(beacons) do local dist = math.dist({x=x,y=y}, b) if dist<ndist then nearest,ndist = k,dist end end
			goal = nearest
		end
	end
end


function love.update(dt)
	-- Have TLpath get results, check for errors, etc.
	TLpath.update()
	
	if mapTime > 16 then mapTime=0 makeMap(true) else mapTime = mapTime==-1 and -1 or mapTime+dt end
	
	do -- wall editing
		if (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) and love.mouse.isDown("m") then
			local x,y = love.mouse.getPosition()
			local nearest, ndist = nil,math.huge
			for k,w in ipairs(walls) do for i=1,2 do local dist = math.dist({x=x,y=y}, w[i]) if dist<ndist then nearest,ndist = w[i],dist end end end
			nearest.x,nearest.y = x,y
		end
	end
	
	-- Make each bot follow its path. Pretty simple stuff.
	for k,bot in ipairs(bots) do
		local b = beacons[bot.path[1]]	-- path[1] is the index of the first node in the path
		local xn,yn,d = math.normalize(b.x-bot.x, b.y-bot.y)
		if d > 10 then bot.x,bot.y = bot.x+xn*bot.speed*dt, bot.y+yn*bot.speed*dt
		elseif #bot.path>1 then table.remove(bot.path,1)	-- Path is a list of node indexen. When a bot arrives at one, remove it from the list.
		end
	end
	
end


function love.draw()
	local lg = love.graphics
	lg.setLineWidth(2)
	
	lg.setColor(63,63,255, 255)
	for k,b in ipairs(beacons) do lg.circle("line", b.x, b.y, 10, 3) end
	
	for k,bot in ipairs(bots) do
		-- TLpath will set path.unreachable to true if the goal can't be reached
		if not bot.path.unreachable then lg.setColor(127,255,127, 255) else lg.setColor(31,127,31, 255) end
		lg.circle("line", bot.x, bot.y, 20, 6)
		
		lg.setColor(127,255,127, 47)
		if bot.path then for i=1,#bot.path do
			local d1,d2 = beacons[bot.path[i-1]], beacons[bot.path[i]]
			if not d1 then lg.line(bot.x,bot.y, d2.x,d2.y)
			else lg.line(d1.x,d1.y, d2.x,d2.y)
			end
		end end
	end
	
	lg.setColor(0,255,0, 255)
	local x,y = beacons[goal].x, beacons[goal].y
	lg.circle("line", x,y, 14, 3) lg.circle("line", x,y, 6, 3)
	
	lg.setLineWidth(6)
	lg.setColor(127,31,31, 255)
	for k,w in ipairs(walls) do lg.line(w[1].x,w[1].y, w[2].x,w[2].y) end
	
	lg.setColor(255,255,255, 255)
	lg.print("Left-click to place a beacon, Right-click to remove a beacon, Middle-click to set a beacon as goal.", 8,4)
	lg.print(mapTime==-1 and "Press R to enable map auto-cycle and generate a new map. Press E after editing the map to remake paths." or "Press R to disable map auto-cycle (next map in "..math.floor(16-mapTime).." seconds).", 8,16)
	lg.print("TLpath.status: "..TLpath.status, 8,28)	-- A handy status message that will show timing info if love.timer is enabled.
end