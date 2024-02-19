pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--monster cycle
--by nandbolt

--game state
gstate=0
gtime=0 --game time (steps)

--actor pools
ghosts={}
wraiths={}
zombies={}
skeletons={}
humans={}

--particle system
ps={}

--camera
cam={}
cam.x=0 --camera x
cam.y=0 --camera y
cam.accel=1 --camera acceleration

--collisions
walls={64}
tombs={80,96}
beds={97}

--main init
function _init()
	--not menu state
	if gstate!=gst_menu then
		--clear run
		gtime=0
		
		--clear pools
		ghosts={}
		wraiths={}
		zombies={}
		skeletons={}
		humans={}
		
		--preprocess enemies
		for i=1,4 do
			spnr.x=irnd(0,mw)
			spnr.y=irnd(0,mw)
			make_ghost(spnr.x,spnr.y,false)
		end
		for i=1,4 do
			spnr.x=irnd(0,mw)
			spnr.y=irnd(0,mw)
			make_wraith(spnr.x,spnr.y,false)
		end
		for i=1,2 do
			spnr.x=irnd(0,mw)
			spnr.y=irnd(0,mw)
			make_zombie(spnr.x,spnr.y,false)
		end
		for i=1,2 do
			spnr.x=irnd(0,mw)
			spnr.y=irnd(0,mw)
			make_skeleton(spnr.x,spnr.y,false)
		end
		for i=1,4 do
			spnr.x=irnd(0,mw)
			spnr.y=irnd(0,mw)
			make_human(spnr.x,spnr.y,false)
		end
		
		--add player
		spnr.x=hmw+irnd(0,128)-64
		spnr.y=hmh+irnd(0,128)-64
		if rnd(1)<0.5 then
			make_ghost(spnr.x,spnr.y,true)
		else
			make_wraith(spnr.x,spnr.y,true)
		end
	end
end

--main update
function _update()
	--menu game state
	if gstate==gst_menu then
		if btn(4) then
			gstate=gst_active
			_init()
		end
	else
		--ambience
		sfx(2)
		
		--update spawner
		update_spawner()
		
		--update particles
		foreach(ps,update_p)
		
		--update actors
		foreach(ghosts,update_ghost)
		foreach(wraiths,update_wraith)
		foreach(zombies,update_zombie)
		foreach(skeletons,update_skeleton)
		foreach(humans,update_human)
		
		--update camera
		cam.x=lerp(cam.x,player.x-hss,
			cam.accel)
		cam.x=clamp(cam.x,0,mw-ss)
		cam.y=lerp(cam.y,player.y-hss,
			cam.accel)
		cam.y=clamp(cam.y,0,mh-ss)
		camera(cam.x,cam.y)
		
		--dead state
		if gstate==gst_dead or
			gstate==gst_complete then
			if btn(5) then
				gstate=gst_active
				_init()
			end
		else
			gtime+=1
		end
	end
end

--main draw
function _draw()
	--clear
	cls()
	
	--menu state
	if gstate==gst_menu then
		local xx,yy=16,24
		cls(2)
		
		--title
		cursor(xx,yy)
		print("monster cycle",1)
		cursor(xx+1,yy+1)
		print("monster cycle",7)
		
		--game mode prompts
		yy+=32
		cursor(xx,yy)
		print("press 🅾️ to play",1)
		cursor(xx+1,yy+1)
		print("press 🅾️ to play",7)
		
		--credits
		yy+=32
		cursor(xx,yy)
		print("created by nandbolt(v0.2)",1)
		cursor(xx+1,yy+1)
		print("created by nandbolt(v0.2)",7)
	else
		--draw tiles
		map(0,0,0,0,mw,mh)
		
		--draw particles
		foreach(ps,draw_p)
		
		--draw actors
		foreach(ghosts,draw_ghost)
		foreach(wraiths,draw_wraith)
		foreach(zombies,draw_zombie)
		foreach(skeletons,draw_skeleton)
		foreach(humans,draw_human)
		
		--active state
		if gstate==gst_active then
			local xx,yy=cam.x+1,cam.y+1
			local val=0
			
			--goal
			cursor(xx,yy)
			print(player.goal,1)
			cursor(xx+1,yy+1)
			print(player.goal,7)
			
			--timer
			yy+=8
			local seconds=flr(gtime/30)
			cursor(xx,yy)
			print("time:"..seconds,1)
			cursor(xx+1,yy+1)
			print("time:"..seconds,7)
			
			--xp
			yy+=8
			val=player.xp/player.maxxp
			rectfill(xx,yy,xx+32,yy+2,1)
			rectfill(xx+1,yy+1,xx+1+ceil(32*val),yy+3,10)
			
			--meter
			yy+=6
			val=player.meter/player.maxmeter
			rectfill(xx,yy,xx+32,yy+2,1)
			rectfill(xx+1,yy+1,xx+1+flr(32*val),yy+3,7)
			
			--cooldown
			yy+=6
			val=player.cooldwn/player.maxcooldwn
			rectfill(xx,yy,xx+32,yy+2,1)
			rectfill(xx+1,yy+1,xx+1+flr(32*val),yy+3,13)
			
			--actors
			yy+=8
			val=#ghosts
			cursor(xx,yy)
			print("🐱 "..val,1)
			cursor(xx+1,yy+1)
			print("🐱 "..val,12)
			yy+=8
			val=#wraiths
			cursor(xx,yy)
			print("🐱 "..val,1)
			cursor(xx+1,yy+1)
			print("🐱 "..val,5)
			yy+=8
			val=#zombies
			cursor(xx,yy)
			print("😐 "..val,1)
			cursor(xx+1,yy+1)
			print("😐 "..val,3)
			yy+=8
			val=#skeletons
			cursor(xx,yy)
			print("😐 "..val,1)
			cursor(xx+1,yy+1)
			print("😐 "..val,7)
			yy+=8
			val=#humans
			cursor(xx,yy)
			print("웃 "..val,1)
			cursor(xx+1,yy+1)
			print("웃 "..val,15)
		--death menu
		elseif gstate==gst_dead then
			--death prompt
			cursor(cam.x+32,cam.y+32)
			print("death.",1)
			cursor(cam.x+33,cam.y+33)
			print("death.",7)
			
			--restart prompt
			cursor(cam.x+32,cam.y+64)
			print("❎ to retry",1)
			cursor(cam.x+33,cam.y+65)
			print("❎ to retry",7)
		--victory menu
		elseif gstate==gst_complete then
			--victory prompt
			cursor(cam.x+32,cam.y+16)
			print("monster ascended.",1)
			cursor(cam.x+33,cam.y+17)
			print("monster ascended.",7)
			
			--time
			cursor(cam.x+32,cam.y+26)
			print("time:"..gtime,1)
			cursor(cam.x+33,cam.y+27)
			print("time:"..gtime,7)
			
			--restart prompt
			cursor(cam.x+32,cam.y+36)
			print("❎ to play again",1)
			cursor(cam.x+33,cam.y+37)
			print("❎ to play again",7)
		end
	end
end
-->8
--math

--constants
mw=128*8 --map width
hmw=128*4 --half map width
mh=128*4 --map height
hmh=128*2 --half map height
ss=128 --screen size
hss=64 --half screen size
ts=8 --tile size
hts=4 --half tile size
st_wander=0 --wander state
st_fight=1 --fight state
st_flee=2 --flee state
gst_menu=0 --menu game state
gst_active=1 --active game state
gst_dead=2 --dead game state
gst_complete=3 --complete game state

--returns vector2 length
function get_vec_len(x,y)
	return sqrt(x*x+y*y)
end

--returns distance between two points
function get_dist(x1,y1,x2,y2)
	return get_vec_len(x2-x1,y2-y1)
end

--lerp
function lerp(a,b,t)
	return a+t*(b-a)
end

--random integer
function irnd(low,high)
	return flr(rnd(high-low+1)+low)
end

--clamp
function clamp(value,low,high)
	if (value<low) return low
	if (value>high) return high
	return value
end

--point collision check
function point_in_box(x,y,x1,y1,x2,y2)
	if (x>=x1 and x<=x2 and
		y>=y1 and y<=y2) then
		return true
	end
	return false
end

--returns if item is in table
function in_table(tbl,item)
	for i=1,#tbl do
		if (tbl[i]==item) return true
	end
	return false
end

--point_in_view
function point_in_view(x,y)
	if x>cam.x and x<cam.x+ss and
		y>cam.y and y<cam.y+ss then
		return true
	end
	return false
end
-->8
--ghost

--creates a ghost and adds it
--to the list of ghosts
function make_ghost(x,y,is_player)
	local ghost={}
	
	--actor
	init_actor(ghost,x,y,is_player)
	
	--states
	ghost.ethereal=true
	ghost.tier=1
	ghost.ascenders={80,96}
	ghost.targs={ghosts,wraiths}
	
	--trail
	init_trail(ghost,12)
	
	--dash
	init_dash(ghost,3,1,{{17},{18},{19}})
	
	--player or npc
	if is_player then
		ghost.update_input=update_player_input
		ghost.goal="✽fight ghosts."
		player=ghost
	else
		init_actor_npc(ghost,ghost_npc_input)
	end
	
	--add to list
	ghost.pool=ghosts
	add(ghost.pool,ghost)
end

--updates ghost logic
function update_ghost(ghost)
	--update input/abilities
	ghost.update_input(ghost)
	update_dash(ghost)
	
	--move and collide
	move_and_collide(ghost)
	
	--check ascendance
	check_ascend(ghost)
end


--renders the ghost
function draw_ghost(ghost)
	draw_actor(ghost)
end

--ghost npc input
function ghost_npc_input(ghost)
	--update state
	ghost.mcnt+=1
	if (ghost.mcnt%2)==0 then
		npc_think(ghost)
	end
	
	--states
	if ghost.mstate==st_fight then
		update_target(ghost)
	else
		update_rand_target(ghost)
	end
	
	--update input direction
	ghost.dx=clamp(ghost.tx-ghost.x,-1,1)
	ghost.dy=clamp(ghost.ty-ghost.y,-1,1)
end
-->8
--particles

--add particle
function add_p(x,y,c)
	local p={}
	p.x,p.y=x,y
	p.vx,p.vy=0,0
	p.life=10
	p.c=c
	add(ps,p)
end

--update particle
function update_p(p)
	if (p.life<=0) then
		--destroy particle
		del(ps,p)
	else
		--update position
		p.x+=p.vx
		p.y+=p.vy
		
		--update life
		p.life-=1
	end
end

--draw particle
function draw_p(p)
	pset(p.x,p.y,p.c)
	if p.life>5 then
		pset(p.x-1,p.y,p.c)
		pset(p.x+1,p.y,p.c)
		pset(p.x,p.y-1,p.c)
		pset(p.x,p.y+1,p.c)
	end
end
-->8
--zombie

--creates a zombie and adds it
--to the list of ghosts
function make_zombie(x,y,is_player)
	local zombie={}
	
	--actor
	init_actor(zombie,x,y,is_player)
	
	--state
	zombie.tier=2
	zombie.ascenders={80,96}
	zombie.targs={humans}
	
	--trail
	init_trail(zombie,3)
	
	--sprite
	zombie.rsprs={33,49}
	zombie.dsprs={34,50}
	zombie.dgsprs={35,51}
	zombie.sprs=zombie.rsprs
	
	--dash
	init_dash(zombie,2,3,
		{zombie.rsprs,zombie.dsprs,
		zombie.dgsprs})
	
	--player or npc
	if is_player then
		zombie.update_input=update_player_input
		zombie.goal="웃eat humans."
		player=zombie
	else
		init_actor_npc(zombie,zombie_npc_input)
	end
	
	--add to list
	zombie.pool=zombies
	add(zombie.pool,zombie)
end

--updates zombie logic
function update_zombie(zombie)
	--get input
	zombie.update_input(zombie)
	update_dash(zombie)
	
	--move and collide
	move_and_collide(zombie)
	
	--check ascendance
	check_ascend(zombie)
end

--renders the zombie
function draw_zombie(zombie)
	draw_actor(zombie)
end

-- npc input
function zombie_npc_input(zombie)
	--update state
	zombie.mcnt+=1
	if (zombie.mcnt%2)==0 then
		npc_think(zombie)
	end
	
	--states
	if zombie.mstate==st_fight then
		update_target(zombie)
	else
		update_rand_target(zombie)
	end
	
	--update input direction
	zombie.dx=clamp(zombie.tx-zombie.x,-1,1)
	zombie.dy=clamp(zombie.ty-zombie.y,-1,1)
end

--zombie npc think
function zombie_npc_think(zombie)
end
-->8
--actor

--init actor
function init_actor(a,x,y,is_player)
	--movement
	a.x=x --x position
	a.y=y --y position
	a.vx=0 --x velocity
	a.vy=0 --y velocity
	a.spd=0 --speed (for queries)
	a.maxspd=2 --current max move speed
	a.normspd=2 --normal max move speed
	a.accel=0.1 --move acceleration
	a.ethereal=false --ethereal=no wall collisions
	
	--sprite
	a.rsprs={1} --right sprites
	a.dsprs={2} --down sprites
	a.dgsprs={3} --diagonal sprites
	a.sprs=a.rsprs --current sprites
	a.spridx=1 --current sprite index
	a.animspd=1 --animation speed (frames per second)
	a.animcnt=0 --animation counter
	a.flipx=false --sprite flip x
	a.flipy=false --sprite flip y
	
	--tier
	a.tier=1
	a.targs={}
	
	--health
	a.invulnerable=false
	
	--xp
	a.maxxp=3
	a.xp=0
	
	--meter
	a.maxmeter=90
	a.meter=90
	
	--cooldown
	a.maxcooldwn=90
	a.cooldwn=90
	
	--input
	a.dx=0 --x direction
	a.dy=0 --y direction
	a.oaction=false --🅾️ action
	a.xaction=false --❎ action
end

--inits vars for npc actor
function init_actor_npc(a,uinput)
	a.update_input=uinput
	a.targ=nil	--target
	a.tx=a.x	--target x position
	a.ty=a.y --target y position
	a.mstate=st_wander	--mental state
	a.mcnt=irnd(0,16) --mental counter
	a.tradius=32 --target detection radius
end

--updates player actor input
function update_player_input()
	--move input
	player.dx=tonum(btn(1))-
		tonum(btn(0))
	player.dy=tonum(btn(3))-
		tonum(btn(2))
	
	--action inputs
	player.oaction=btn(4)
	player.xaction=btn(5)
end

--moves the actor and handles
--collisions
function move_and_collide(a)
	--update velocity
	a.vx=lerp(a.vx,
		a.dx*a.maxspd,
		a.accel)
	a.vy=lerp(a.vy,
		a.dy*a.maxspd,
		a.accel)
	
	--handle x collision
	local bb=a.x
	if(a.vx>0)bb=a.x+ts
	local tx=(bb+a.vx)/ts
	local ty=a.y/ts
	if not a.ethereal and
		in_table(walls,mget(tx,ty)) then
		a.vx=0
	end
	a.x=clamp(a.x+a.vx,0,mw-ts)
	bb=clamp(bb+a.vx,0,mw-ts*2)
	
	--handle y collision
	bb=a.y
	if(a.vy>0)bb=a.y+ts
	tx=a.x/ts
	ty=(bb+a.vy)/ts
	if not a.ethereal and 
		in_table(walls,mget(tx,ty)) then
		a.vy=0
	end
	a.y=clamp(a.y+a.vy,0,mh-ts)
	
	--update speed
	a.spd=get_vec_len(a.vx,a.vy)
end

--checks actor collisions
-- return: actor or nil
function touching(a,pools)
	for pool in all(pools) do
		for y=a.y,a.y+ts,ts do
			for x=a.x,a.x+ts,ts do
				for i=#pool,1,-1 do
					local oa=pool[i]
					local x1=oa.x
					local x2=oa.x+ts
					local y1=oa.y
					local y2=oa.y+ts
					local colliding=point_in_box(x,y,x1,y1,x2,y2)
					if oa!=a and not
					 oa.invulnerable and
					 colliding then
						return oa
					end
				end
			end
		end
	end
	return nil
end

--draw rectangular hitbox
function draw_hitbox(a)
	for y=a.y,a.y+ts do
		for x=a.x,a.x+ts do
			if (x==a.x or x==a.x+ts or
				y==a.y or y==a.y+ts) then
				pset(x,y,1)
			end
		end
	end
end

--renders the actor
function draw_actor(a)
	--update sprites
	a.animcnt+=a.spd*3
	if a.animcnt>=30 then
		a.animcnt=a.animcnt%30
		a.spridx+=1
		if a.spridx>#a.sprs then
			a.spridx=1
		end
	end
	
	--if moving
	if (get_dist(0,0,a.vx,
		a.vy)>a.maxspd/2) then
		--diagonal sprite
		if abs(abs(a.vx)-
			abs(a.vy))<1 then
			if a.dashing then
				a.sprs=a.dashdgsprs
			else
				a.sprs=a.dgsprs
			end
			
			--update facing direction
			if a.vx>0 then
				a.flipx=false
			else
				a.flipx=true
			end
			if a.vy>0 then
				a.flipy=false
			else
				a.flipy=true
			end
		--down sprite
		elseif abs(a.vx)<abs(a.vy) then
			if a.dashing then
				a.sprs=a.dashdsprs
			else
				a.sprs=a.dsprs
			end
			
			--update y facing direction
			if a.vy<0 then
				a.flipy=true
			elseif a.vy>0 then
				a.flipy=false
			end
		--right sprite
		else
			if a.dashing then
				a.sprs=a.dashrsprs
			else
				a.sprs=a.rsprs
			end
			
			--update x facing direction
			if a.vx<0 then
				a.flipx=true
			elseif a.vx>0 then
				a.flipx=false
			end
		end
	end
	
	--ghost sprite
	spr(a.sprs[a.spridx],a.x,a.y,
		1,1,a.flipx,a.flipy)
		
	--draw hitbox
	--draw_hitbox(a)
end

--init trail
function init_trail(a,c)
	a.normctrail=c --normal trail color
	a.ctrail=a.normctrail --trail color
end

--update trail
function update_trail(a)
	a.ctrail=a.normctrail
	if (a.xp==a.maxxp) then
		a.ctrail=10
	elseif (a.dashing) then
		a.ctrail=a.dashctrail
	end
	add_p(a.x+irnd(1,6),
		a.y+irnd(1,6),a.ctrail)
end

--init dash
function init_dash(a,dspd,dc,sprs)
	--states
	a.dashing=false
	a.dashspd=dspd
	a.dashctrail=dc --dash trail color
	a.dashdmg=1
	
	--sprites
	a.dashrsprs=sprs[1]
	a.dashdsprs=sprs[2]
	a.dashdgsprs=sprs[3]
end

--update dash
function update_dash(a)
	if a.oaction and a.meter>0 then
		if not a.dashing then
			--burst
			a.vx+=a.dx*2
			a.vy+=a.dy*2
			a.meter-=10
			
			--if player
			if a==player then
				sfx(0)
			end
		end
		a.dashing=true
		a.invulnerable=true
		a.cooldwn=a.maxcooldwn
		a.meter-=1
	else
		a.dashing=false
		a.invulnerable=false
		if a.cooldwn<=0 then
			a.meter=a.maxmeter
			a.cooldwn=a.maxcooldwn
		elseif a.meter<a.maxmeter then
			a.cooldwn-=1
		end
	end
	
	--update max speed
	if a.dashing then
		a.maxspd=a.dashspd
		
		--check dash collisions
		local oa=touching(a,a.targs)
		if oa!=nil then
			actor_kill(a,oa)
		end
	else
		a.maxspd=a.normspd
	end
	
	--update trail
	update_trail(a)
end

--ghost kill
function actor_kill(a,oa)
	--add xp
	a.xp=clamp(a.xp+1,0,a.maxxp)
	
	--if player and ready to ascend
	if a==player then
		sfx(3)
		if a.xp==a.maxxp then
			if a.tier==1 then
				player.goal="◆find tombtone!"
			elseif a.tier==2 then
				player.goal="⌂find bed!"
			elseif a.tier==3 then
				player.goal="★find portal!"
			end
		end
	end
	
	--if other is player
	if oa==player then
		gstate=gst_dead
		sfx(4)
	end
	
	--destroy other ghost
	del(oa.pool,oa)
end

--check ascension
function check_ascend(a)
	if a.xp==a.maxxp then
		for y=a.y,a.y+ts,ts do
			for x=a.x,a.x+ts,ts do
				local tile=mget(x/ts,y/ts)
				if in_table(a.ascenders,tile) then
					ascend(a)
					return
				end
			end
		end
	end
end

--ascend
function ascend(a)
	local is_player=a==player
	
	--to tier 2
	if a.tier+1==2 then
		if rnd(1)>0.5 then
			make_zombie(a.x,a.y,is_player)
		else
			make_skeleton(a.x,a.y,is_player)
		end
	--to tier 3
	elseif a.tier+1==3 then
		make_human(a.x,a.y,is_player)
	--to tier 4
	elseif a.tier+1==4 then
		gstate=gst_complete
	end
	
	--destroy actor
	del(a.pool,a)
end

--get nearby target
function get_near_targ(a)
	for pool in all(a.targs) do
		for oa in all(pool) do
			if (a!=oa and get_dist(a.x,
				a.y,oa.x,oa.y)<=
				a.tradius) then
				return oa
			end
		end
	end
end

--npc think
function npc_think(a)
	if (a.mstate==st_wander) then
		--check near target
		a.targ=get_near_targ(a)
		if a.targ!=nil then
			a.mstate=st_fight
			a.oaction=true
		end
	else
		local dist = get_dist(a.x,a.y,a.targ.x,a.targ.y)
		if a.targ==nil or dist>a.tradius then
			a.mstate=st_wander
		end
	end
end

--update target
function update_target(a)
	if a.targ!=nil then
		a.tx=a.targ.x+irnd(0,64)-32
		a.ty=a.targ.y+irnd(0,64)-32
	else
		a.mstate=st_wander
	end
end

--update random target
function update_rand_target(a)
	if (a.mcnt%30)==0 then
		a.tx=a.x+irnd(0,64)-32
		a.ty=a.y+irnd(0,64)-32
	end
end
-->8
--wraith

--creates wraith, adds to pool
function make_wraith(x,y,is_player)
	local wraith={}
	
	--actor
	init_actor(wraith,x,y,is_player)
	
	--states
	wraith.ethereal=true
	wraith.tier=1
	wraith.ascenders={80,96}
	wraith.targs={ghosts,wraiths}
	
	--trail
	init_trail(wraith,5)
	
	--dash
	init_dash(wraith,4,8,{{20},{21},{22}})
	
	--meter
	wraith.maxmeter=60
	wraith.meter=60
	
	--sprite
	wraith.rsprs={4}
	wraith.dsprs={5}
	wraith.dgsprs={6}
	wraith.sprs={4}
	
	--player or npc
	if is_player then
		wraith.update_input=update_player_input
		wraith.goal="✽fight ghosts."
		player=wraith
	else
		init_actor_npc(wraith,wraith_npc_input)
	end
	
	--add to list
	wraith.pool=wraiths
	add(wraith.pool,wraith)
end

--updates wraith logic
function update_wraith(wraith)
	--get input
	wraith.update_input(wraith)
	
	--update dash
	update_dash(wraith)
	
	--move and collide
	move_and_collide(wraith)
	
	--check ascendance
	check_ascend(wraith)
end

--renders the wraith
function draw_wraith(wraith)
	draw_actor(wraith)
end

--wraith npc input
function wraith_npc_input(wraith)
	--update state
	wraith.mcnt+=1
	if (wraith.mcnt%2)==0 then
		npc_think(wraith)
	end
	
	--states
	if wraith.mstate==st_fight then
		update_target(wraith)
	else
		update_rand_target(wraith)
	end
	
	--update input direction
	wraith.dx=clamp(wraith.tx-wraith.x,-1,1)
	wraith.dy=clamp(wraith.ty-wraith.y,-1,1)
end
-->8
--spawner
spnr={}
spnr.x=0 --spawner x
spnr.y=0 --spawner y
spnr.cnt=0 --spawn counter
spnr.freq=30 --spawn frequency
spnr.maxghosts=4 --max ghost spawns
spnr.maxwraiths=4 --max wraith spawns
spnr.maxzombies=4 --max zombie spawns
spnr.maxskeletons=4 --max skeleton spawns
spnr.maxhumans=4 --max human spawns

--update spawn point
function update_spawnpoint(ethereal)
	spnr.x=cam.x+irnd(0,1)*(ss+ts)-ts
	spnr.y=cam.y+irnd(0,1)*(ss+ts)-ts
	if spnr.x>mw then
		spnr.x-=ss
	elseif spnr.x<0 then
		spnr.x+=ss
	end
	if spnr.y>mh then
		spnr.x-=ss
	elseif spnr.y<0 then
		spnr.x+=ss
	end
end

--update spawner
function update_spawner()
	spnr.cnt+=1
	if spnr.cnt%spnr.freq==0 then 
		local n=irnd(0,4)
		if n==0 and #ghosts<spnr.maxghosts then
			update_spawnpoint(true)
			make_ghost(spnr.x,spnr.y,false)
		elseif #wraiths<spnr.maxwraiths then
			update_spawnpoint(true)
			make_wraith(spnr.x,spnr.y,false)
		elseif #zombies<spnr.maxzombies then
			update_spawnpoint(false)
			make_zombie(spnr.x,spnr.y,false)
		elseif #skeletons<spnr.maxskeletons then
			update_spawnpoint(false)
			make_skeleton(spnr.x,spnr.y,false)
		elseif #humans<spnr.maxhumans then
			update_spawnpoint(false)
			make_human(spnr.x,spnr.y,false)
		end
	end
end
-->8
--skeleton

--creates a zombie and adds it
--to the list of skeletons
function make_skeleton(x,y,is_player)
	local skeleton={}
	
	--actor
	init_actor(skeleton,x,y,is_player)
	
	--state
	skeleton.tier=2
	skeleton.ascenders={80,96}
	skeleton.targs={humans}
	
	--trail
	init_trail(skeleton,7)
	
	--sprite
	skeleton.rsprs={36,52}
	skeleton.dsprs={37,53}
	skeleton.dgsprs={38,54}
	skeleton.sprs=skeleton.rsprs
	
	--dash
	init_dash(skeleton,2,7,
		{skeleton.rsprs,skeleton.dsprs,
		skeleton.dgsprs})
	
	--player or npc
	if is_player then
		skeleton.update_input=update_player_input
		skeleton.goal="웃fight humans."
		player=skeleton
	else
		init_actor_npc(skeleton,skeleton_npc_input)
	end
	
	--add to list
	skeleton.pool=skeletons
	add(skeleton.pool,skeleton)
end

--updates zombie logic
function update_skeleton(skeleton)
	--get input
	skeleton.update_input(skeleton)
	update_dash(skeleton)
	
	--move and collide
	move_and_collide(skeleton)
	
	--check ascendance
	check_ascend(skeleton)
end

--renders the skeleton
function draw_skeleton(skeleton)
	draw_actor(skeleton)
end

-- npc input
function skeleton_npc_input(skeleton)
	--update state
	skeleton.mcnt+=1
	if (skeleton.mcnt%2)==0 then
		npc_think(skeleton)
	end
	
	--states
	if skeleton.mstate==st_fight then
		update_target(skeleton)
	else
		update_rand_target(skeleton)
	end
	
	--update input direction
	skeleton.dx=clamp(skeleton.tx-skeleton.x,-1,1)
	skeleton.dy=clamp(skeleton.ty-skeleton.y,-1,1)
end
-->8
--human

--creates a human and adds it
--to the list of humans
function make_human(x,y,is_player)
	local human={}
	
	--actor
	init_actor(human,x,y,is_player)
	
	--state
	human.tier=3
	human.ascenders={80,96}
	human.targs={zombies,skeletons}
	
	--trail
	init_trail(human,4)
	
	--sprite
	if rnd(1)<0.5 then
		human.rsprs={7,23}
		human.dsprs={8,24}
		human.dgsprs={9,25}
	else
		human.rsprs={39,55}
		human.dsprs={40,56}
		human.dgsprs={41,57}
	end
	human.sprs=human.rsprs
	
	--dash
	init_dash(human,3,4,
		{human.rsprs,human.dsprs,
		human.dgsprs})
	
	--player or npc
	if is_player then
		human.update_input=update_player_input
		human.goal="✽kill monsters"
		player=human
	else
		init_actor_npc(human,human_npc_input)
	end
	
	--add to list
	human.pool=humans
	add(human.pool,human)
end

--updates human logic
function update_human(human)
	--get input
	human.update_input(human)
	update_dash(human)
	
	--move and collide
	move_and_collide(human)
	
	--check ascendance
	check_ascend(human)
end

--renders the human
function draw_human(human)
	draw_actor(human)
end

-- npc input
function human_npc_input(human)
	--update state
	human.mcnt+=1
	if (human.mcnt%2)==0 then
		npc_think(human)
	end
	
	--states
	if human.mstate==st_fight then
		update_target(human)
	else
		update_rand_target(human)
	end
	
	--update input direction
	human.dx=clamp(human.tx-human.x,-1,1)
	human.dy=clamp(human.ty-human.y,-1,1)
end
__gfx__
00000000000000000000000000000000000000000000000000050000000fff4000000040004f0000222222222226622200000000000000000000000000000000
00000000000ccc00000cc00000cc00000055770000500500005550004f444400004444f0004444ff222222222262262200000000000000000000000000000000
0070070000cc11c000cccc000ccccc0005555750055555500555550004fff14004ffff4004ffff4f662226622262262200000000000000000000000000000000
000770000cccccc00cccccc00cccc1c000555500055555505555577004ffff4044ffff4f04fff144226262262226622200000000000000000000000000000000
000770000cccccc00c1cc1c000cccc1000555500075555700555557004ffff4044ffff4f04ffff40226662262222622200000000000000000000000000000000
0070070000cc11c00c1cc1c000c1ccc005555750077557700057550004fff140041ff14f04f1ff40662226622226622200000000000000000000000000000000
00000000000ccc0000cccc00000c1c00005577000050050000077000004444f40f44440404444400222222222262262200000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000044000040000000440f400222222222262262200000000000000000000000000000000
33333333000000000000000000000000000000000000000000050000000440000400000000000000000000000000000000000000000000000000000000000000
33333333000111000001100000110000005588000050050000555000004444f40f44440000444444000000000000000000000000000000000000000000000000
334333330011cc10001111000111110005555850055555500555550004fff14004ffff4044ffff44000000000000000000000000000000000000000000000000
34343333011111100111111001111c1000555500055555505555588004ffff40f4ffff44f4fff140000000000000000000000000000000000000000000000000
333333330111111001c11c10001111c000555500085555800555558004ffff40f4ffff4404ffff4f000000000000000000000000000000000000000000000000
333333330011cc1001c11c10001c111005555850088558800058550004fff140f41ff14004f1ff44000000000000000000000000000000000000000000000000
3333333300011100001111000001c1000055880000500500000880004f444400404444f00f444400000000000000000000000000000000000000000000000000
33333333000000000000000000000000000000000000000000000000000fff40000000400ff40000000000000000000000000000000000000000000000000000
2222222200033350000000500005300000dd77d000dddd0000dddd00000444500000005000540000000000000000000000000000000000000000000000000000
222222225355550000555530005555330d77dd000d7777d00d707dd7545555000055554000555544000000000000000000000000000000000000000000000000
22222222053338500533335005333353d7007dd0d707707dd77707d7054441500544445005444454000000000000000000000000000000000000000000000000
22222222053333503533335305333855d77777d0d707707dd0777ddd054444505544445405444155000000000000000000000000000000000000000000000000
22222222053333503533335305333350d77777d0dd7777d7d70777d0054444505544445405444450000000000000000000000000000000000000000000000000
22022222053338503583385305383350d7007dd00dd77dd7dd7d7dd0054441500514415405414450000000000000000000000000000000000000000000000000
202022220055553553555505035555000d77dd7d07dddd0d0ddddd00005555450455550505555500000000000000000000000000000000000000000000000000
2222222200033350050000000335350000ddd0000d0000000007d000000550000500000005504500000000000000000000000000000000000000000000000000
4444444400033350050000000000000000ddd00000dddd0000dddd00000550000500000000000000000000000000000000000000000000000000000000000000
444444440055553503555500005555330d77dd7d0d7777d00d707dd0005555450455550000555555000000000000000000000000000000000000000000000000
44444444053338500533335005333353d7007dd0d707707dd77707d0054441500544445055444455000000000000000000000000000000000000000000000000
44444244053333503533335355333855d77777d0d707707dd0777dd7054444504544445545444150000000000000000000000000000000000000000000000000
44442424053333503533335335333353d77777d07d7777ddd70777dd054444504544445505444454000000000000000000000000000000000000000000000000
44444444053338503583385305383355d7007dd07dd77dd0dd7d7dd0054441504514415005414455000000000000000000000000000000000000000000000000
444444445355550050555535035555000d77dd00d0dddd700ddddd00545555005055554004555500000000000000000000000000000000000000000000000000
4444444400033350000000500335000000dd77d0000000d0077d0000000444500000005004450000000000000000000000000000000000000000000000000000
55555555222222222226622200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56666665222222222262262200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555662226622262262200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56656665226262262226622200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56656665226662262222622200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555662226622226622200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56666665222222222262262200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555222222222262262200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1dddddd144444f443333333322222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d555555dffffffff3333333322222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d511115d4f4444443343333322222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d166661dffffffff3434333322222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d165561d444f44443333333322222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d511115d44f444443333333322022222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d555555dffffffff3333333320202222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1dddddd1444444f43333333322222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1dddddd1444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d555555d444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d511115d444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d166661d555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d165561d549444450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d511115d555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d555555d444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1dddddd1444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03030303030303030303030303030303030303030305030303030303030303030303030302b0b00502030205b00502030205b0b002020202020202020202b002
030302b0020202020602020203020202020202020202020202020202020202020202020303030301010303030303030303030303030303010103030303030101
03030303030303030303030303030303030303030303030303030301030303030303030302b0b00502030205b00502030205b0b002020201010202020202b006
030306b0020202020202020203030202020202020202020202020202020202020202020303030301010103030303030303030303030303030103030303030101
03030303030303030303030303030303030303030303030303030101030303030303030302b0b00202030202b00202030202b0b002020201010202020202b006
030306b0020202020202020202030202020602020202a0a0a0a0a0a0a00202020202020303030303010101030303030303030303030303030103030303030101
03030303030303030303030303030303030303030303030303010101030303030303030302b0b00502030205b00502030205b0b002020101010202020202b006
030306b0020202020202020202030303030303030303030303030303030302020202020303030303010101030303030305030303030303030303030303030101
03030303030303030303030303030303030303030303030303010103030303030303030302b0b00502030205b00502030205b0b002020101010102020202b002
030302b002020202020202020202020202020202b003020203b003020203b0020202020303030303010101030303030303030303030303030303030303030101
03030303030303030303030303030303030303030303030301010103030303030303030302b0b00502030205b00502030205b0b0020201010101020202020404
0416040402020202020202020202020202020202b003060603b003060603b0020202020303030303030103030303030303030303030303030303030303030101
03030303030303030303030303030303030303030303030301010103030303030303030302b0b00202030202b00202030202b0b0020201010102020202040415
1515150404020202020202020202020202020202b003030303b003020203b0020202020303030303030303030303030303030303030303030303030303030101
03030303030303030303030303030303030303030303030301010303030303030303030302b0b00502030205b00502030205b0b0020202010102020202041515
1515151504020202020202020202010102020202b003060603b003060603b0020202020303030303030303030303030303030303030303030303030303030101
03030303030303030303030303030303030303030303030301010303030303030303030302b0b00502030205b00502030205b0b0020202020202020202041515
1515151504020202020206020202010102020202b003020203b003020203b0020202020303030303030303030303030303030303030303030303030303030101
03030303030303030303030303030303030303030303030101010303030303030303030302020202020302020202020302020202020202020202020202040415
15151504040202020202020202020101020202020203030303030303030302020202020303030303030303030303030303030303030303030303030303030101
03030303030303030303030303030303050303030303030101010303030303030303030302020202020303030202020302020202020202020202020202020404
16040404020202020202020202020101020202020202a0a0a0a0a0a0a00202020202020303030303030303030101010101010101010101010101010501010101
03030303030303030303030303030303030303030303030301030303030303030303030302020202020202030303030303030202020202020202020202020202
03020202020202020202020202010101020202020202020202020202020202020202030303030303030303030101010101010101010101010101010101010101
03030503030303030303030303030303030303030303030303030303030303030303030302020202020202020202020202030303030303030303030303030303
03020202020202020202020202010101020202020202020202020202020202020203030303030303030303030101010101010101010101010101010101010101
03030303030303030303030303030303030303030303030303030303030303030303030303020202020202020202020202020202020202020202020202020202
02020202020202020202020202020202020202020202020202020202020202020303030303030303030303030101010101010101010101010101010101010101
03030303030303030303030303030303030303030303030303030303030303030303030303030302020202020202020202020202020202020202020202020202
02020202020202020202020202020202020202020202020202020202020202020303030303030303030303030101010101010101010101010101010101010101
03030303030303030303030303030303030303030303030303030303030303030303030303030302020202020202020202020202020202020205020202020202
02020202020202020202020202020202020202020202020202020202020202030303030303030303030303030101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010303030303030303030303030303030303030303030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030303030303030303030101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010103030303030303030303030303030303030303030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030303030301010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101030303030303030303030303030303030303030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030303030101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010303030303030303030303030303030303030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030303010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010103030303030303030303030303030303030303030303030303030301
01010101030303030303030303030303030303030303030303030303030303030303030301010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010103030303030303030303030303030303030301010101010101010103
01010101010103030303030303030303030303030303030303030303030303030303030301010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010601010101010101010101010103030303030303030303030303030303010101010101010101010101
01010103030303030303030503030303030303030303030303030303030303030303030301010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010103030303030303030303030303030303010101010101010101030303
03030303030303030303030303030303030303030301030303030303030303030303030301010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010103030303030303030303060303030303030303030303030303030303
03030303030303030303030303030303030303030101030303030303030303030303030301010101010101010101010101010105010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010103030303030303030303030303030303030303030303030303030303
03030303030303030303030303030303030301010103030303030503030303030303030301010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010103030303030303030303030303030303030303030303030303030303
03030303030303030303030303030303030301010103030303030303030303030303030301010101010101010101010101010101010101010101010101010101
01010101010101010601010101010101010101010101010101010101010101010101010103030303030303030303030303030303030303030303030303030303
03030303030303030303030303030303030101030303030303030303030303030303030301010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010103030303030303030303030303030303030303030303030303030303
03050303030303030303030303030303030101030303030303030303030303030303030301010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010103030303030303030303030303030303030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030301010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010103030303030303030303030303030303030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030301010101010101010101010101010101010101010101010101010101
01010101010101010101010101010101010101010101010101010101010101010101010103030303030303030303030303030303030303030303030303030303
03030303030303030303030303030303030303030303030303030303030303030303030301010101010101010101010101010101010101010101010101010101
__label__
22222220222222202222222022222220222222202222222022222220222222202222244444444444444444444444444444444444444444444444444444444444
02722202777277720772727277722202077272720772277277722772022222020222244444444444444444444444444444444444444444444444444444444444
22777722722227227222727227222222722272727272722227227222222222222222244444444444444444444444444444444444444444444444444444444444
22777222772227227222777227222222722277727272777227227772662222222222244444444444444442222222222266222222222222222222222222222222
27777222722227227272727227222222727272727272227227222276226222222222244444444444444442222222222622622222222222222222222222222222
22227222722277727772727227222222777272727722772227227726276222222222244444444444444442222222222622622222222222222222222222222222
22222222222222222222222222222222222222222222222222222222662222222222244444244444442442222222222266222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222262222222222244442424444424242222222222226222222222222222222222222222222
22222220222222202222222022222220222222202222222022222222662222202222244444444444444442202222222266222220222222202222222022222220
72727772022277020272770202222202022222020222220202222226226222020222244444444444444442020222222622622202022222020221220202222202
72727272272227222722272222222222222222222222222222222226226222222222244444444444444442222222222622622222222222122111122222222222
77737773333337222722272222222222222222222222222222222222662221dddddd144444444444444441dddddd12226622222222222111111cc12222222222
7373733337333722272227222222222222222222222222222222222622622d555555d4444444444444444d555555d22622622222222222121111112222222222
7373733433337772722277722222222222222222222222222222222622622d511115d4444444444444444d511115d22622622222222222221111112222222222
4333334343333222222222222222222222222222222222222222222266222d166661d4444424444444244d166661d2226622222222222211111cc12222222222
3333333333333222222222222222222222222222222222222222222226222d165561d4444242444442424d165561d22226222222222221111111122222222222
3333333333333220222222202222222022222220222222202222222266222d511115d4444444444444444d511115d22266222220222212112222222022222220
7373777333337772027277720222220202222202022222020222222622622d555555d4444444444444444d555555d22622622202022222020222220202222202
73737373373372722722227222222222222222222222222222222226226221dddddd144444444444444441dddddd122622622222222212212222222222222222
37337773333372722722277222222222222222222222222222222222662221dddddd144444444444444441dddddd122266222222222222222222222222222222
7373733337337272272222722222222222222222222222222222222622622d555555d4444444444444444d555555d22622622222222121222222222222222222
7373733433337772722277722222222222222222222222222222222622622d511115d4444444444444444d511115d22622622222111112222222222222222222
4333334343333222222222222222222222222222222222222222222266222d166661d4444424444444244d166661d22266222221cc1112222222222222222222
3333333333333222222222222222222222222222222222222222222226222d165561d4444242444442424d165561d22226222221111112222222222222222222
3333333333333220222222202222222022222220222222202222222266222d511115d4444444444444444d511115d22266222221111112212222222022222220
7773777377737772777222027772777202727772777222020222222622622d555555d4444444444444444d555555d22622622201cc1111020222220202222202
77737333373372227272272272727272272272727272222222222226226221dddddd144444444444444441dddddd122622622222111122222222222222222222
73737733373377227722222277727272272277727272222222222222662221dddddd144444444444444441dddddd122266222222222222222222222222222222
7373733337337222727227222272727227222272727222222222222622622d555555d4444444444444444d555555d22622622222222222222222222222222222
7373777437337772727222222272777272222272777222222222222622622d511115d4444444444444444d511115d22622622222222222222222222222222222
4333334343333222222222222222222222222222222222222222222266222d166661d4444424444444244d166661d22266222222222222222222222222222222
3333333333333222222222222222222222222222222222222222222226222d165561d4444242444442424d165561d22226222222222222222222222222222222
3333333333333220222222202222222022222220222222202222222266222d511115d4444444444444444d511115d22266222220222222202222222022222220
7773777377737772022272020222777277727772727222020222222622622d555555d4444444444444444d555555d22622622202022222020222220202222202
37333733777372222722722222227222727272727272222222222226226221dddddd144444444444444441dddddd122622622222222222222222222222222222
37333733737377333333777222227772777277727772222222222222662222222222244444444444444442222222222266222222222222222222222222222222
37333733737373333733727222222272227272722272222222222226226222222222244444444444444442222222222622622222222222222222222222222222
37337774737377743333777227227772227277722272222222222226226222222222244444444444444442222222222622622222222222222222222222222222
43333343433333434333322222222222222222222222222222222222662222222222244444244444442442222222222266222222222222222222222222222222
33333333333333333333322222222222222222222222222222222222262222222222244442424444424242222222222226222222222222222222222222222222
33333333333333333333322022222220222222202222222022222222662222202222244444444444444442202222222266222220222222202222222022222220
33333333333333333333320202222202022222020222220202222226226222020222244444444444444442020222222622622202022222020222220202222202
33333333333333333333322222222222222222222222222222222226226222222222244444444444444442222222222622622222222222222222222222222222
33333333333333333333322222222222222222222222222222222555555555555555555555555555555555555555555555555222222222222222222222222222
33333333333333333333322222222222222222222222222222222566666655666666556666665566666655666666556666665222222222222222222222222222
33333334333333343333322222222222222222222222222222222555555555555555555555555555555555555555555555555222222222222222222222222222
43333343433333434333322222222222222222222222222222222566566655665666556656665566566655665666556656665222222222222222222222222222
33333333333333333333322222222222222222222222222222222566566655665666556656665566566655665666556656665222222222222222222222222222
33333333333333333333322022222220222222202222222022222555555555555555555555555555555555555555555555555220222222202222222022222220
33333333333333333333320202222202022222020222220202222566666655666666556666665566666655666666556666665202022222020222220202c22202
33333333333333333333322222222222222222222222222222222555555555555555555555555555555555555555555555555222222222222222222ccccc2c22
333333333333322222222222222222222222222222222555555555555555544444f4444444f4444444f4444444f445555555555555555222222222c11cccccc2
3333333333333222222222222222222222222222222225666666556666665ffffffffffffffffffffffffffffffff5666666556666665222222222cccccccc22
33333334333332222222222222222222222222222222255555555555555554f4444444f4444444f4444444f4444445555555555555555222222222cccccccc22
4333334343333222222222222222222222222222222225665666556656665ffffffffffffffffffffffffffffffff566566655665666522222222cc11cccc222
3333333333333222222222222222222222222222222225665666556656665444f4444444f4444444f4444444f44445665666556656665222222222ccccccc2c2
333333333333322022222220222222202222222022222555555555555555544f4444444f4444444f4444444f44444555555555555555522022222220222cc220
3333333333333202022222020222220202222202022225666666556666665ffffffffffffffffffffffffffffffff56666665566666652020222220202222202
3333333333333222222222222222222222222222222225555555555555555444444f4444444f4444444f4444444f455555555555555552222222222222222c22
3333333333333222222222222222222222222222222225555555544444f4444444f4444444f4444444f4444444f4444444f44555555552222222222222222222
33333333333332222222222222222222222222222222256666665ffffffffffffffffffffffffffffffffffffffffffffffff566666652222222222222222222
333333343333322222222222222222222222222222222555555554f4444444f4444444f4444444f4444444f4444444f444444555555552222222222222222222
43333343433332222222222222222222222222222222256656665ffffffffffffffffffffffffffffffffffffffffffffffff566566652222222222222222222
33333333333332222222222222222222222222222222256656665444f4444444f4444444f4444444f4444444f4444444f4444566566652222222222222222222
3333333333333220222222202222222022222220222225555555544f4444444f4444444f4444444f4444444f4444444f44444555555552202222222022222220
33333333333332020222220202222202022222020222256666665fffffffffffffccccfffffffffffffffffffffffffffffff566666652020222220202222202
33333333333332222222222222222222222222222222255555555444444f44444c11ccc4444f4444444f4444444f4444444f4555555552222222222222222222
2222222222222222222222222222222222222222222225555555544444f444444cccccc444f4444444f4444444f4444444f44555555552222222222222222222
22222222222222222222222222222222222222222222256666665fffffffffffcccccccffffffffffffffffffffffffffffff5666666522222222222c2222222
222222222222222222222222222222222222222222222555555554f4444444f44c11ccc4444444f4444444f4444444f444444555555552222222222222222222
22222222222222222222222222222222222222222222256656665fffffffffffccccccccfffffffffffffffffffffffffffff566566652222222c2c2c2222222
22222222222222222222222222222222222222222222256656665444f4444444fc4444c4f4444444f4444444f4444444f444456656665222222ccc2222222222
2222222022222220222222202222222022222220222225555555544f4444444f4444444f4444444f4444444f4444444f4444455555555220ccccc22022222220
02222202022222020222220202222202022222020222256666665ffffffffffffffffffffffffffffffffffffffffffffffff5666666520c11ccc20c02222202
22222222222222222222222222222222222222222222255555555444444f4444444f4444444f4444444f4444444f4444444f45555555522cccccc22222222222
222222222222222222222222222222222222222222222555555555555555544444f4444444f4444444f4444444f44555555555555555522cccccc22222222222
2222222222222222222222222222222222222222222225666666556666665ffffffffffffffffffffffffffffffff566666655666666522c11ccc22222222222
22222222222222222222222222222222222222222222255555555555555554f4444444f4444444f4444444f4444445555555555555555222cccccc2222222222
2222222222222222222222222222222222222222222225665666556656665ffffffffffffffffffffffffffffffff56656665566566652222222c22222222222
2222222222222222222222222222222222222222222225665666556656665444f4444444f4444444f4444444f444456656665566566652222222222222222222
222222202222222022222220222222202222222022222555555555555555544f4444444f4444444f4444444f4444455555555555555552202222222022222220
0222220202222202022222020222220202222202022225666666556666665ffffffffffffffffffffffffffffffff56666665566666652020222220202222202
2222222222222222222222222222222222222222222225555555555555555444444f4444444f4444444f4444444f455555555555555552222222222222222222
22222222222222222222222222222222222222222222222222222555555555555555544444444555555555555555555555555222222222222222222222222222
22222222222222222222222222222222222222222222222222222566666655666666544444444566666655666666556666665222222222222222222222222222
22222222222222222222222222222222222222222222222222222555555555555555544444444555555555555555555555555222222222222222222222222222
22222222222222222222222222222222222222222222222222222566566655665666555555555566566655665666556656665222222222222222222222222222
22222222222222222222222222222222222222222222222222222566566655665666554944445566566655665666556656665222222222222222222222222222
22222220222222202222222022222220222222202222222022222555555555555555555555555555555555555555555555555220222222202222222022222220
02222202022222020222220202222202022222020222220202222566666655666666544444444566666655666666556666665202022222020222220202222202
22222222222222222222222222222222222222222222222222222555555555555555544444444555555555555555555555555222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220
02222202022222020222220202222202022222020222220202222202022222020222220202222202022222020222220202222202022222020222220202222202
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220
02222202022222020222220202222202022222020222220202222202022222020222220202222202022222020222220202222202022222020222220202222202
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220
02222202022222020222220202222202022222020222220202222202022222020222220202222202022222020222220202222202022222020222220202222202
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220222222202222222022222220
02222202022222020222220202222202022222020222220202222202022222020222220202222202022222020222220202222202022222020222220202222202
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222221dddddd122222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
2222222222222d555555d22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
2222222222222d511115d22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
2222222222222d166661d22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
2222222222222d165561d22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222

__map__
1010101010101010101010101010101010101010101010101010101010101010101010103030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303010101010101010101010101010101010101010101010101010101010
1010101010101010101010101010101010101010101010101010101010101010101010103030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303010101010101010101010101010101010101010101010101010101010
1010101010101010101010101010101010101010101010101010101010101010101010103030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303010101010101010101010101010101010101010101010101010101010
1010101010101010101010101010101010101010101010101010101010101010101010103030303030303030303030303030303030303030303030303030303030303030303030305030303030303030303030303030303030303030303030303030303010101010101010101010101010101010101010101010101010101010
1010101010101010101010101010101010101010101010101010101010101010101010103030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303010101010101010105010101010101010101010101010101010101010
1010101010101010101010101010101010101010101010101010101010501010101010103030303030303030305030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303010101010101010101010101010101010101010101010101010101010
1010101010101010101010101010101010101010101010101010101010101010101010103030303030303030303030303010103030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303010101010101010101010101010101010101010101010101010101010
1010101010101010101010101010101010101010101010101010101010101010101010103030303030303030303030101010303030303030303030303030303030303030303030303030303030303030303030303030303030303050303030303030303010101010101010101010101010101010101010101050101010101010
1010101010101010101010101010101010101010101010101010101010101010101010103030303030303030303010103030101030303030303030303030303030303030301010101010303030303030303030303030303030303030303030303030303010101010101010101010101010101010101010101010101010101010
1010101010101010101050101010101010101010101010101010101010101010101010103030303030303030301010101010103030303030303030303030303030303030301010101010101010303030303030303030303030303030303030303030303010101010101010101010101010101010101010101010101010101010
1010101010101010101010101010101010101010101010101010101010101010101010103030303030303030301010103030303030303030303030303030303030303030303030101010101010303030303030303030303030303030303030303030303010101010101010101010101010101010101010101010101010101010
1010101010101010101010101010101010101010101010101010101010101010101010103030303030303030101030303030303030303030303030305030303030303030303030303030303030303030303030303030303030303030303030303030303010101010101010101010101010101010101010101010101010101010
1010101010101010101010101010101010101010101010101010101010101010101010303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303010101010101010101010101010101010101010101010101010101010
1010101010101010101010101010101010101010101010101010101010101010101030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030301010101010101010101010101010101010101010101010101010
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303010101010101010101010101010101010101010101010101010
3030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030
3030303030303030303030303030303030303030303030303030303030303030303030303020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020502020202020202030303030303030303030303030303030303030303030303030303030303030303030
3030303030303030303030303030303030303030103030303030303030303030303030302020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020303030303030303030303030303030303030303030303030303030303030303030
3030303030303030303030303030303030303010103030303030303030303030303030305020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202030303030303030303030303030303030303030303030303030303030303030
3030303030303030303030303030303030301010103030303030303030303030303030302020202020204040404040402020204040406140402020202020202020202020202020202020202020202020202020201020202020202020202020202020203030303030303030303030303030303030303030303030303030303030
3030303030305030303030303030303030301010103030303030303030303030303030302020202020204051515151404040404051515151402020202020202020202020202020202020202020202020202010101020202020202020202020202020203030303030303030303030303030303030303030303030303030303030
3030303030303030303030303030303030301010103030303030303030303030303030302020202020204051515151515151515151515151402020202020202020202020202020202020202020202020201010101010202020202020202020202020203030303030303030303030303030303030303030503030303030303030
3030303030303030303030303030303030101010303030303030303030303030303030302020202020204051515151515151515151515151402020202020202020202020202020202050202020202020101010101020202020202020202020202020203030303030303030303030303030303030303030303030303030303030
3030303030303030303030303030303030101010303030303030303030303030303030302020202020204051515151404040404051515151402020202020202020205020202020202020202020202020101010202020202020202020202020202020203030303030303030303030303030303030303030303030303030303030
3030303030303030303030303030303010101030303030303030303030303030303030302020202020204040614040402020204040404040402020202020202020202020202020202020202020202020202020202020202020202020202020202020203030303030303030303030303030303030303030303030303030303030
3030303030303030303030303030303010103030303030303030303030303030303030302020202020202020302020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020203030303030303030303030303030303030303030303030303030303030
3030303030303030303030303030301010103030303030303030303030303030303030302020202020202020302020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020203030303030305030303030303030303030303030303030303030301010
3030303030303030303030303030301010303030303030303030303030303030303030302020202020203030303030303030202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020203030303030303030303030303030303030303030303030303030301010
3030303030303030303030303030301010303030303030303030303030303030303030302020202020303020202020302030303030303030303030303030302020202020202020202020202020202020202020202050202020202020202060202020203030303030303030303030303030303030301010303030303030301010
3030303030303030303030303030301030303030303030303030303030303030303030302020202020302020202020302020202020202020202020202020303030202020202020202020202020202020202020202020202020202020202020202020203030303030303030303030303030303030301010303030303030301010
3030303030303030303030303030301030303030303030303030303030303030303030302020202020302020202020302020202020202020202020202020202030202020202020202020202020202020202020202020202020202020202020202020203030303030303030303030303030303030303010103030303030301010
3030303030303030303030303030101030303030303030303030303030303030303030302020202020302020202020302020202020202020202020202020202030303030303030303030303030202020202020202020202020202020202020202020203030303010303030303030303030303030303010101030303030301010
__sfx__
000100000000014550145501455015550155501655016550155500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000061000600036000260002600116000060002600026000160009600016000160000600006000060000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000061000510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000190501f050260502705000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000191500c150091500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
