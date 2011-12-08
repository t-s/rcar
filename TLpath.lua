-- TLpath v1.01, an A* pathfinding implementation designed to be used in Love2D
-- by Taehl (SelfMadeSpirit@gmail.com)

local thread = love._curthread

if thread:getName() == "main" then		-- we're in the main thread, so set up the handler
	require("TSerial")
	
	TLpath = {status="Initializing TLpath thread...",list={}}	-- namespace
	thread = love.thread.newThread("TLpath","TLpath.lua") thread:start()	-- start the pathing thread
	thread:send("require", love.filesystem.read("TSerial.lua"))	-- pass it TSerial, since threads can't read files?!?
	TLpath.status = "TLpath.calcNodes needs to be run before paths can be found."


	-- Calculate the node graph (do this whenever the nodes change)
	function TLpath.calcNodes(nodes, dynamic)
		TLpath.cancelPathfinding()	-- Trying to find paths while changing nodes is bad.
		if dynamic then thread:send("calcDynamicNodes", TSerial.pack(nodes)) else thread:send("calcStaticNodes", TSerial.pack(nodes)) end
		TLpath.status = "Updating "..(dynamic and "dynamic" or "static").." nodes."
		if love.timer then TLpath.calcNodesStart = love.timer.getTime() end
	end


	-- This function determines if one node can see another, and what the g-score ("cost") of their path is
	function TLpath.setGfunction(f) return thread:send("runCode", "function gScore(a,b) "..f.." end") end
	-- This function calculates the h-score (heuristic factor) of a node. The default should be fine for most cases, change only if you know what you're doing!
	function TLpath.setHfunction(f) return thread:send("runCode", "function hScore(a,goal) "..f.." end") end


	-- Find a path for an entity
	function TLpath.findPath(ent, goal)
		if not (ent.path and ent.path[1]) then error("Can't find a path without a starting node! (ent.path[1] must be a node index)") end
		table.insert(TLpath.list, {ent,goal,(love.timer and love.timer.getTime())})
	end
	
	
	-- Clears all waiting pathfinding requests.
	function TLpath.cancelPathfinding()
		thread:send("cancelPath", true)
		TLpath.busy,TLpath.list = nil,{}
		TLpath.status = "Cancelled pathfinding requests - it's safe to calcNodes now."
	end


	-- Handles TLpath realtime events (call this in love.update)
	function TLpath.update()
		local r=thread:receive("error") assert(not r, r)	-- show an error message if the thread had a problem
		local r=thread:receive("status") if r then
			if r=="calcNodes finished" then TLpath.status = "Finished updating nodes"..(love.timer and " in "..math.floor((love.timer.getTime()-TLpath.calcNodesStart)*1000+.5)*.001 .." seconds." or ".")
			else TLpath.status = r
			end
		end
		
		-- spool pathfinding requests
		if #TLpath.list > 0 and not TLpath.busy then
			TLpath.busy = TLpath.list[1][1]
			thread:send("findPath", TSerial.pack{TLpath.busy, TLpath.list[1][2]})
			if love.timer then TLpath.list[1][3],TLpath.list[1][4] = love.timer.getTime()-TLpath.list[1][3], love.timer.getTime() end
		end
		
		-- set paths once they're found
		local r=thread:receive("setPath") if r then
			r = TSerial.unpack(r)
			TLpath.busy.path,TLpath.busy = r, false
			TLpath.status = "Finished calculating a"..(r.unreachable and "n unreachable path" or " path "..#r.." nodes long")..(love.timer and (" in "..math.floor((love.timer.getTime()-TLpath.list[1][4])*1000+.5)*.001 .." seconds, after waiting "..math.floor((TLpath.list[1][3])*1000+.5)*.001 .." seconds in que. ") or ". ")..#TLpath.list-1 .." more to go."
			table.remove(TLpath.list, 1)
		end
	end




else		-- otherwise, we're in the path thread, so set up that stuff
	loadstring(thread:demand("require"))()		-- this is dumb!


	-- default g-score function (very likely to need to be changed to suit each game)
	function gScore(a,b) local d = ((b.x-a.x)^2+(b.y-a.y)^2)^0.5 return d<=100 and d or nil end
	-- default h-score function (the default is good for most cases)
	function hScore(a,goal) return ((goal.x-a.x)^2+(goal.y-a.y)^2)^0.5 end


	-- find a path with the A* algorithm
	function findPath(ent, goal, nodes)
		if ent.path[1] == goal then return {goal} end	-- if we're not already there
		local closedSet,openSet,foundPath = {},{{index=ent.path[1], f=0,h=0, parent="start"}}, false
		while #openSet>0 do
			local ai,a = 1, openSet[1]
			local r=thread:receive("cancelPath") if r then return false end		-- quit here to prevent errors if nodes are getting calced
			for index,g in pairs(nodes[a.index].dests or nodes) do
				if not closedSet[index] then	-- if it hasn't already been investigated
					local g = type(g)=="number" and g or gScore(nodes[a.index], nodes[index])
					if g then	-- if g is reachable
						local f,h = a.f + g, hScore(nodes[index], nodes[goal])
						local fh = f + h
						-- place this into the openSet according to its f score (this way, we never need to sort openSet, giving a huge performance boost)
						for j=1,#openSet do                                  -- (often literally a thousand times faster, in my tests                    )
							if fh < (openSet[j].f+openSet[j].h) then
								table.insert(openSet, j, {index=index,f=f,h=h,parent=a.index})
								if j<=ai then ai=ai+1 end		-- a's index gets bumped up
								-- remove any further entries which have this node, since this path to it is more efficient
								for j=j+1,#openSet do
									if index == openSet[j].index then
										table.remove(openSet,j)
										if j<ai then ai=ai-1 end		-- a's index goes back down
										break
									end
								end
								break
							elseif openSet[j].index == index then break	-- there's already a better path to this node
							elseif j==#openSet then table.insert(openSet, {index=index,f=f,h=h,parent=a.index})	-- put it on the end of the table
							end
						end
					end--				<<==== my code looks like a boob. x_x
				end
			end
			-- move it from the open set to the closed set
			closedSet[a.index]=a.parent
			table.remove(openSet,ai)
			-- if it's the goal, backtrace the path and report it
			if a.index==goal then
				foundPath = true
				local t,p = {},a.index
				local n=0
				repeat table.insert(t,1,p) p=closedSet[p] until p==ent.path[1]	-- or until p=="start", if you don't want to skip the starting node
				return t
			end
		end
		-- if no path has been found by now, the goal is unreachable
		ent.path.unreachable = true
		return ent.path
	end


	-- watch for commands
	repeat
		local r=thread:receive("runCode") if r then loadstring(r)() end
		
		local r=thread:receive("calcStaticNodes") if r then
			nodes=TSerial.unpack(r)
			for k,n in ipairs(nodes) do
				if not n.dests then		-- if nodes already have dests specified by the game, leave them alone
					n.dests = {}
					for k2,n2 in ipairs(nodes) do if n~=n2 then n.dests[k2] = gScore(n,n2) end end
				end
			end
			thread:send("status", "calcNodes finished")
		end
		
		local r=thread:receive("calcDynamicNodes") if r then nodes=TSerial.unpack(r) thread:send("status", "calcNodes finished") end
		
		local r=thread:receive("findPath") if r then
			local r2=thread:receive("cancelPath")	-- clear cancel request if needed
			r=TSerial.unpack(r)
			local p = findPath(r[1],r[2],nodes)
			if p then thread:send("setPath", TSerial.pack(p)) end
		end
	until thread:receive("quit")
end