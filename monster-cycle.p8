pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--monster cycle
--by nandbolt

--actor pools
ghosts={}
zombies={}
skeletons={}
humans={}

--main init
function _init()
	--add initial actors
	make_ghost(64,64)
end

--main update
function _update()
	--update actors
	for i=1,#ghosts do
		update_ghost(ghosts[i])
	end
end

--main draw
function _draw()
	--clear
	cls()
	
	--draw actors
	for i=1,#ghosts do
		draw_ghost(ghosts[i])
	end
end
-->8
--math

--returns vector2 length
function get_vec_len(x,y)
	return sqrt(x*x+y*y)
end

--lerp
function lerp(a,b,t)
	return a+t*(b-a)
end
-->8
--ghost

--creates a ghost and adds it
--to the list of ghosts
function make_ghost(x,y)
	local ghost={}
	
	--movement
	ghost.x=x
	ghost.y=y
	ghost.vx=0
	ghost.vy=0
	ghost.maxspd=4
	ghost.accel=0.1
	
	--input
	ghost.dx=0
	ghost.dy=0
	
	--add to list
	add(ghosts,ghost)
end

--updates ghost logic
function update_ghost(ghost)
	--get input
	ghost.dx=tonum(btn(1))-
		tonum(btn(0))
	ghost.dy=tonum(btn(3))-
		tonum(btn(2))
	
	--update velocity
	ghost.vx=lerp(ghost.vx,
		ghost.dx*ghost.maxspd,
		ghost.accel)
	ghost.vy=lerp(ghost.vy,
		ghost.dy*ghost.maxspd,
		ghost.accel)
	
	--update position
	ghost.x+=ghost.vx
	ghost.y+=ghost.vy
end


--renders the ghost
function draw_ghost(ghost)
	spr(1,ghost.x,ghost.y) --face
	--trail
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000ccc11c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000cccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000cccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000ccc11c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
