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
--vector2
function make_v2(x,y)
	local v={}
	v.x=x
	v.y=y
	return v
end

--returns vector2 length
function get_v2_len(v)
	return sqrt(v.x*v.x+v.y*v.y)
end

--normalizes vector2
function normalize_v2(v)
	--return if zero vector
	if v.x==0 and v.y==0 then
		return
	end
	
	--divide vector by length
	local ilen=1/get_v2_len(v)
	v.x*=ilen
	v.y*=ilen
end
-->8
--rigid body
function make_rb(x,y)
	local rb={}
	
	--movement
	rb.pos=make_v2(x,y)
	rb.vel=make_v2(0,0)
	rb.movespd=2
	
	return rb
end
-->8
--actor
--function make_actor(x,y)
-->8
--ghost

--creates a ghost and adds it
--to the list of ghosts
function make_ghost(x,y)
	local ghost={}
	
	--rigid body
	ghost.rb=make_rb(x,y)
	
	--add to list
	add(ghosts,ghost)
end

--updates ghost logic
function update_ghost(ghost)
	--get input
	ghost.rb.vel.x=tonum(btn(1))-tonum(btn(0))
	ghost.rb.vel.y=tonum(btn(3))-tonum(btn(2))
	normalize_v2(ghost.rb.vel)
	
	--update velocity
	ghost.rb.vel.x*=ghost.rb.movespd
	ghost.rb.vel.y*=ghost.rb.movespd
	
	--update position
	ghost.rb.pos.x+=ghost.rb.vel.x
	ghost.rb.pos.y+=ghost.rb.vel.y
end


--renders the ghost
function draw_ghost(ghost)
	spr(1,ghost.rb.pos.x,ghost.rb.pos.y) --face
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
