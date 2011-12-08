require ("math") -- for sin and cos
hc = require 'hardoncollider' -- collision detection library
require ("TLpath")

text =  {}
nodes = {}
walls = {}

function on_collide(dt, shape1, shape2, mtv_x, mtv_y)
	--text[#text+1] = string.format("Colliding. mtv = (%s,%s)", 
    --                                mtv_x, mtv_y)
	if (((shape1 == mycar) and(shape2 == pc1)) or 
	    ((shape2 == mycar) and(shape1 == pc1))) then
			shape1.x = shape1.x + mtv_x/2;
			shape1.y = shape1.y + mtv_y/2;
			shape2.x = shape2.x - mtv_x/2;
			shape2.y = shape2.y - mtv_y/2;

	if(shape1.acceleration > 0.03) then
		shape1.acceleration = shape1.acceleration - 0.03;
	end
	
	if(shape2.acceleration > 0.03) then
		shape2.acceleration = shape2.acceleration - 0.03;
	end	
		
	elseif(shape1.type == "wall") then
		shape2.x = shape2.x + mtv_x;
		shape2.y = shape2.y + mtv_y;
		if(shape2.acceleration > 0.035) then
			shape2.acceleration = shape2.acceleration - 0.035;
		end
	elseif(shape2.type == "wall") then
		shape1.x = shape1.x + mtv_x;
		shape1.y = shape1.y + mtv_y;
		if(shape1.acceleration > 0.035) then
			shape1.acceleration = shape1.acceleration - 0.035;
		end
	end
	
	
end

function love.load()
	-- init collision detection library
	hardoncollider.init(150, on_collide)

	--load bitmaps
	grass = love.graphics.newImage("grass.bmp"); vert = love.graphics.newImage ("vert.bmp");
	hori = love.graphics.newImage ("hori.bmp" ); cotl = love.graphics.newImage ("cotl.bmp");
	cotr = love.graphics.newImage ("cotr.bmp" ); cobl = love.graphics.newImage ("cobl.bmp");
	cobr = love.graphics.newImage ("cobr.bmp" ); car  = love.graphics.newImage ( "car.bmp");
	car2 = love.graphics.newImage ("car2.bmp" );

	--my car parameters	
	mycar = hc.addRectangle(840,400,car:getWidth(),car:getHeight())
	mycar.acceleration = 0;
	mycar.rotation = 3.14159; -- 180 degrees in radians
	mycar.x = 840;
	mycar.y = 400;
	
	--pc1 car parameters
	pc1 = hc.addRectangle(820,400,car2:getWidth(),car2:getHeight())
	pc1.acceleration = 0;
	pc1.rotation = 3.14159; -- 180 degrees in radians
	pc1.x = 820;
	pc1.y = 400;
	
	--width and height in 96 pixel tiles of world
	WIDTH = 12;
	HEIGHT = 7;
	worldWidth = grass:getWidth() * WIDTH;
	worldHeight = grass:getHeight() * HEIGHT;
	
	--draw screen
	love.graphics.setMode(worldWidth, worldHeight, false, true, 2)
	
    -- 1D array of world map
    array = {  0,0,0,0,0,0,0,0,0,0,0,0,
			   0,6,2,2,2,2,2,2,2,2,4,0,
               0,1,0,0,0,0,0,0,0,0,1,0,
               0,5,2,2,4,0,6,2,4,0,1,0,
               0,0,0,0,1,0,1,0,1,0,1,0,
               0,0,0,0,5,2,3,0,5,2,3,0,
               0,0,0,0,0,0,0,0,0,0,0,0 }
               
    tileHeight = grass:getHeight()
	tileWidth = grass:getWidth() 
      
    yTile = love.graphics.getHeight() /	 grass:getHeight()
	xTile = love.graphics.getWidth()  /	 grass:getWidth()
    local tempWall = 0;
   
     
     for i=0,yTile do
		for j=0,xTile do
			index = ((WIDTH*i)+j)+1
			 local tempNode = {};
			if (array[index] == 1) then
				--wall to left of vertical tile
				tempWall = hc.addRectangle((j*tileWidth)-5,i*tileHeight,5,tileHeight)
				tempWall.type = "wall"
				hc.addToGroup("walls",tempWall)
				walls[#walls+1] = tempWall
				--wall to right of vertical tile
				tempWall = hc.addRectangle((j*tileWidth)+tileWidth,i*tileHeight,5,tileHeight)
				tempWall.type = "wall"
				hc.addToGroup("walls",tempWall)
				walls[#walls+1] = tempWall
				
				tempNode.x = i;
				tempNode.y = j;
				nodes[#nodes+1] = tempNode
			elseif (array[index] == 2) then --horizontal
				--wall at top of horizontal tile
				tempWall = hc.addRectangle(j*tileWidth,(i*tileHeight)-5,tileWidth,5)
				tempWall.type = "wall"
				hc.addToGroup("walls",tempWall)
				walls[#walls+1] = tempWall
				--wall at bottom of horizontal tile
				tempWall = hc.addRectangle((j*tileWidth),(i*tileHeight)+tileHeight,tileWidth,5)
				tempWall.type = "wall"
				hc.addToGroup("walls",tempWall)
				walls[#walls+1] = tempWall
				
				tempNode.x = i;
				tempNode.y = j;
				nodes[#nodes+1] = tempNode
			elseif (array[index]== 3) then --  top left corner, walls at bottom right
				tempWall = hc.addRectangle((j*tileWidth),(i*tileHeight)+tileHeight,tileWidth,5)
				tempWall.type = "wall"
				hc.addToGroup("walls",tempWall)
				walls[#walls+1] = tempWall
				tempWall = hc.addRectangle((j*tileWidth)+tileWidth,i*tileHeight,5,tileHeight)
				tempWall.type = "wall"
				hc.addToGroup("walls",tempWall)
				walls[#walls+1] = tempWall
				
				tempNode.x = i;
				tempNode.y = j;
				nodes[#nodes+1] = tempNode
			elseif (array[index] == 4) then -- bottom left corner, walls at top right
				tempWall = hc.addRectangle(j*tileWidth,(i*tileHeight)-5,tileWidth,5)
				tempWall.type = "wall"
				hc.addToGroup("walls",tempWall)
				walls[#walls+1] = tempWall
				tempWall = hc.addRectangle((j*tileWidth)+tileWidth,i*tileHeight,5,tileHeight)
				tempWall.type = "wall"
				hc.addToGroup("walls",tempWall)
				walls[#walls+1] = tempWall
				
				tempNode.x = i;
				tempNode.y = j;
				nodes[#nodes+1] = tempNode
			elseif (array[index] == 5) then -- top right corner, walls at bottom left
				tempWall = hc.addRectangle((j*tileWidth),(i*tileHeight)+tileHeight,tileWidth,5)
				tempWall.type = "wall"
				hc.addToGroup("walls",tempWall)
				walls[#walls+1] = tempWall
				tempWall = hc.addRectangle((j*tileWidth)-5,i*tileHeight,5,tileHeight)
				tempWall.type = "wall"
				hc.addToGroup("walls",tempWall)
				walls[#walls+1] = tempWall	
				
				tempNode.x = i;
				tempNode.y = j;
				nodes[#nodes+1] = tempNode		
			elseif (array[index] == 6) then -- bottom right corner, walls at top left
				tempWall = hc.addRectangle(j*tileWidth,(i*tileHeight)-5,tileWidth,5)
				tempWall.type = "wall"
				hc.addToGroup("walls",tempWall)
				walls[#walls+1] = tempWall
				tempWall = hc.addRectangle((j*tileWidth)-5,i*tileHeight,5,tileHeight)
				tempWall.type = "wall"
				hc.addToGroup("walls",tempWall)
				walls[#walls+1] = tempWall
				
				tempNode.y = i;
				tempNode.x = j;
				nodes[#nodes+1] = tempNode
				
			end
		end
	end
           
           
           for i=1,3 do
				print (nodes[i].x)
				print (nodes[i].y)
			end
				
end

function love.draw()
	--display collision information
	--for i = 1,#text do
    --    love.graphics.setColor(255,255,255, 125)
	--	love.graphics.print(text[#text - (i-1)], 10, i * 15)
    --end
    
    --for i = 1,#nodes do
	--	love.graphics.setColor(255,255,255, 125)
	--	love.graphics.print(nodes[#nodes - (i-1)].x, 10, i * 15)
	--	love.graphics.print(nodes[#nodes - (i-1)].y, 50, i * 15)
    --end


	yTile = love.graphics.getHeight() /	 grass:getHeight()
	xTile = love.graphics.getWidth()  /	 grass:getWidth()

	tileHeight = grass:getHeight()
	tileWidth = grass:getWidth()

	for i=0,yTile do
		for j=0,xTile do
			index = ((WIDTH*i)+j)+1
			if (array[index] == 1) then
				love.graphics.draw(vert, j*tileWidth, i*tileHeight)
			elseif (array[index] == 2) then
				love.graphics.draw(hori, j*tileWidth, i*tileHeight)
			elseif (array[index]== 3) then
				love.graphics.draw(cotl, j*tileWidth, i*tileHeight)
			elseif (array[index] == 4) then
				love.graphics.draw(cobl, j*tileWidth, i*tileHeight)
			elseif (array[index] == 5) then
				love.graphics.draw(cotr, j*tileWidth, i*tileHeight)
			elseif (array[index] == 6) then
				love.graphics.draw(cobr, j*tileWidth, i*tileHeight)
			else
				love.graphics.draw(grass, j*tileWidth, i*tileHeight)
			end
		end
	end

	--draw actual car graphics
	love.graphics.draw(car, mycar.x, mycar.y, mycar.rotation, 1, 1,car:getWidth()/2, car:getHeight()/2)
	love.graphics.draw(car2, pc1.x, pc1.y, pc1.rotation, 1, 1,car2:getWidth()/2, car2:getHeight()/2)
	mycar:setRotation(mycar.rotation)
	
	--draw bounding boxes
	--mycar:draw()
	--pc1:draw()

	--for z=1,#walls do
	--	walls[z]:draw()
	--end
	

end

function love.update(dt)

		TLpath.update()
		hc.update(dt)

		--while #text > 10 do
		--	table.remove(text, 1)
		--end

		if(mycar.acceleration > 0.015) then
			mycar.acceleration = mycar.acceleration - 0.015;
		end

		mycar.x = mycar.x + math.sin(mycar.rotation) * mycar.acceleration;
		mycar.y = mycar.y - math.cos(mycar.rotation) * mycar.acceleration;
		
		mycar:moveTo(mycar.x,mycar.y)
		pc1:moveTo(pc1.x,pc1.y)
		mycar:rotate(mycar.rotation)
		
		if love.keyboard.isDown("up") then
			if(mycar.acceleration < 3) then
				mycar.acceleration = mycar.acceleration + 0.025;
			end
		end
	
		if love.keyboard.isDown("down") then
			if(mycar.acceleration > -0.25) then
				mycar.acceleration = mycar.acceleration - 0.005;
			end
		end
		
		if love.keyboard.isDown("left") then
			mycar.rotation = mycar.rotation-0.012 * (mycar.acceleration*1.3);
		end
		
		if love.keyboard.isDown("right") then
			mycar.rotation=mycar.rotation+0.012 * (mycar.acceleration*1.3);
		end
		
		if love.keyboard.isDown("q") then
			os.exit()
		end

end


