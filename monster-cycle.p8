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

--projectiles
projs={}

--particle system
ps={}

--camera
cam={}
cam.x=0 --camera x
cam.y=0 --camera y
cam.accel=1 --camera acceleration

--collisions
walls={}
for i=1,128-112 do
	walls[i]=i+111
end
tombs={10,11,12,47,63}
beds={26,27,28,29,42,44,58,60}

--main init
function _init()
	--not menu state
	if gstate!=gst_menu then
		--clear run
		gtime=0
		
		--clear particles
		ps={}
		
		--clear pools
		ghosts={}
		wraiths={}
		zombies={}
		skeletons={}
		humans={}
		
		--clear projectiles
		projs={}
		
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
			--make_ghost(spnr.x,spnr.y,true)
			make_zombie(spnr.x,spnr.y,true)
		else
			--make_wraith(spnr.x,spnr.y,true)
			make_zombie(spnr.x,spnr.y,true)
		end
	end
end

--main update
function _update()
	--menu game state
	if gstate==gst_menu then
		if btnp(5) then
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
		
		--update projectiles
		foreach(projs,update_proj)
		
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
			if btnp(5) then
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
		print("created by nandbolt(v0.5)",1)
		cursor(xx+1,yy+1)
		print("created by nandbolt(v0.5)",7)
		
		--test
		yy+=16
		cursor(xx,yy)
		--print("dist:"..get_dist(10,
		--		10,15,15),1)
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
		
		--draw projectiles
		foreach(projs,draw_proj)
		
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
			
			--controls
			yy+=32
			cursor(xx,yy)
			print(player.oprompt,1)
			cursor(xx+1,yy+1)
			print(player.oprompt,12)
			yy+=8
			cursor(xx,yy)
			print(player.xprompt,1)
			cursor(xx+1,yy+1)
			print(player.xprompt,14)
			
			--debug
			yy+=8
			cursor(xx,yy)
			--print("fps:"..stat(7),1)
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

--check rectangle intersection
function rect_intersect(ax1,ay1,ax2,ay2,bx1,by1,bx2,by2)
	--zero area
	if (ax1==ax2 or ay1==ay2 or
		bx1==bx2 or by1==by2) then
		return false
	end
	
	--horizontal check
	if (ax1>bx2 or ax2<bx1) then
		return false
	end
	
	--vertical check
	if (ay1>by2 or ay2<by1) then
		return false
	end
	
	return true
end

--normalize direction vector
function normalize_dir(a)
	--zero vector
	if (a.dx==0 and a.dy==0) return
	
	--get angle
	local ang=atan2(a.dx,a.dy)
	
	--normalize
	a.dx=cos(ang)
	a.dy=sin(ang)
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
	ghost.ascenders=tombs
	ghost.targs={ghosts,wraiths}
	
	--trail
	init_trail(ghost,12)
	
	--dash
	init_dash(ghost,3,1)
	
	--blaster
	init_ghost_blaster(ghost)
	
	--player or npc
	if is_player then
		ghost.update_input=update_player_input
		ghost.goal="✽fight ghosts."
		ghost.oprompt="🅾️ dash"
		ghost.xprompt="❎ shoot"
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
	update_blaster(ghost)
	update_trail(ghost)
	
	--move and collide
	move_and_collide(ghost)
	
	--check ascendance
	check_ascend(ghost)
end


--renders the ghost
function draw_ghost(ghost)
	if player.tier==1 then
		draw_actor(ghost)
	end
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
	ghost.dx=ghost.tx-ghost.x
	ghost.dy=ghost.ty-ghost.y
	normalize_dir(ghost)
end

--init ghost blaster
function init_ghost_blaster(ghost)
	init_blaster(ghost)
	ghost.pc1=12
	ghost.pc2=1
	ghost.paccel=0.05
	ghost.pburst=1
	ghost.psize=1
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
	zombie.ascenders=beds
	zombie.targs={humans}
	
	--trail
	--init_trail(zombie,11)
	
	--sprite
	zombie.rsprs={33,49}
	zombie.dsprs={34,50}
	zombie.dgsprs={35,51}
	zombie.sprs=zombie.rsprs
	
	--dash
	init_run(zombie,3)
	
	--player or npc
	if is_player then
		zombie.update_input=update_player_input
		zombie.goal="웃eat humans."
		zombie.oprompt="🅾️ lunge"
		zombie.xprompt="❎ spit"
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
	update_run(zombie)
	
	--move and collide
	move_and_collide(zombie)
	
	--check ascendance
	check_ascend(zombie)
end

--renders the zombie
function draw_zombie(zombie)
	if player.tier!=1 then
		draw_actor(zombie)
	else
		pset(zombie.x,zombie.y,7)
	end
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
	zombie.dx=zombie.tx-zombie.x
	zombie.dy=zombie.ty-zombie.y
	normalize_dir(zombie)
end
-->8
--actor

--init actor
function init_actor(a,x,y,is_player)
	--dimensions
	a.bbhw=3 --bounding box half width
	a.bbhh=3 --bounding box half height
	
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
	a.oactionp=false --🅾️ action pressed
	a.xactionp=false --❎ action pressed
end

--inits vars for npc actor
function init_actor_npc(a,uinput)
	a.update_input=uinput
	a.targ=nil --target
	a.tx=a.x --target x position
	a.ty=a.y --target y position
	a.mstate=st_wander --mental state
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
	normalize_dir(player)
	
	--action inputs
	player.oaction=btn(4)
	player.xaction=btn(5)
	player.oactionp=btnp(4)
	player.xactionp=btnp(5)
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
	local bb=a.x-a.bbhw
	if(a.vx>0)bb=a.x+a.bbhw
	local tx=(bb+a.vx)/ts
	local ty=a.y/ts
	if not a.ethereal and
		in_table(walls,mget(tx,ty)) then
		a.vx=0
	end
	a.x=clamp(a.x+a.vx,0,mw-ts)
	bb=clamp(bb+a.vx,0,mw-ts*2)
	
	--handle y collision
	bb=a.y-a.bbhh
	if(a.vy>0)bb=a.y+a.bbhh
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
	--get bbox dimensions
	local bbx1=a.x-a.bbhw
	local bbx2=a.x+a.bbhw
	local bby1=a.y-a.bbhh
	local bby2=a.y+a.bbhh
	
	--loop through target pool
	for pool in all(pools) do
		for i=#pool,1,-1 do
			--get other bbox dimensions
			local oa=pool[i]
			local obbx1=oa.x-oa.bbhw
			local obbx2=oa.x+oa.bbhw
			local obby1=oa.y-oa.bbhh
			local obby2=oa.y+oa.bbhh
			
			--check rect intersection
			local colliding=rect_intersect(
				bbx1,bby1,bbx2,bby2,
				obbx1,obby1,obbx2,obby2)
			if oa!=a and not
			 oa.invulnerable and
			 colliding then
				return oa
			end
		end
	end
	return nil
end

--draw rectangular hitbox
function draw_hitbox(a)
	local bbx1,bbx2=a.x-a.bbhw,a.x+a.bbhw
	local bby1,bby2=a.y-a.bbhh,a.y+a.bbhh
	for y=bby1,bby2 do
		for x=bbx1,bbx2 do
			if (x==bbx1 or x==bbx2 or
				y==bby1 or y==bby2) then
				pset(x,y,7)
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
			a.sprs=a.dgsprs
			
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
			a.sprs=a.dsprs
			
			--update y facing direction
			if a.vy<0 then
				a.flipy=true
			elseif a.vy>0 then
				a.flipy=false
			end
		--right sprite
		else
			a.sprs=a.rsprs
			
			--update x facing direction
			if a.vx<0 then
				a.flipx=true
			elseif a.vx>0 then
				a.flipx=false
			end
		end
	end
	
	--final sprite
	local sprite=a.sprs[a.spridx]
	if (a.tier==1 and a.dashing) sprite+=16
	spr(sprite,a.x-hts,a.y-hts,
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
	add_p(a.x+irnd(-a.bbhw,a.bbhw),
		a.y+irnd(-a.bbhh,a.bbhh),a.ctrail)
end

--init dash
function init_dash(a,dspd,dc)
	--states
	a.dashing=false
	a.dashspd=dspd
	a.dashctrail=dc --dash trail color
	a.burststr=1.5 --burst strength
	a.burstcost=10 --burst cost
end

--init run
function init_run(a,rspd)
	--states
	a.running=false
	a.runspd=rspd
	a.contactdmg=true
end

--update dash
function update_dash(a)
	if a.oaction and a.meter>0 then
		if not a.dashing then
			--burst
			a.vx+=a.dx*a.burststr
			a.vy+=a.dy*a.burststr
			a.meter-=a.burstcost
			
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
end

--update run
function update_run(a)
	if a.oaction and a.meter>0 then
		if not a.running then
			--if player
			if a==player then
				sfx(0)
			end
		end
		a.running=true
		a.cooldwn=a.maxcooldwn
		a.meter-=1
	else
		a.running=false
		if a.cooldwn<=0 then
			a.meter=a.maxmeter
			a.cooldwn=a.maxcooldwn
		elseif a.meter<a.maxmeter then
			a.cooldwn-=1
		end
	end
	
	--update max speed
	if a.running then
		a.maxspd=a.runspd
	else
		a.maxspd=a.normspd
	end
	
	--contact damage
	if a.contactdmg then
		local oa=touching(a,a.targs)
		if oa!=nil then
			actor_kill(a,oa)
		end
	end
end

--actor kill
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
	
	--descend other actor
	descend(oa)
end

--check ascension
function check_ascend(a)
	--if enough xp
	if a.xp==a.maxxp then
		--if on ascend tile
		local tile=mget(a.x/ts,a.y/ts)
		if in_table(a.ascenders,tile) then
			ascend(a)
			return
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
	return nil
end

--npc think
function npc_think(a)
	if (a.mstate==st_wander) then
		--check near target
		a.targ=get_near_targ(a)
		if a.targ!=nil then
			a.mstate=st_fight
			if rnd(1)<0.5 then
				a.oaction=true
			else
				a.xactionp=true
			end
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

--descend
function descend(a)
	local is_player=a==player
	
	--to tier 2
	if a.tier-1==2 then
		if rnd(1)>0.5 then
			make_zombie(a.x,a.y,is_player)
		else
			make_skeleton(a.x,a.y,is_player)
		end
	--to tier 1
	elseif a.tier-1==1 then
		if rnd(1)>0.5 then
			make_ghost(a.x,a.y,is_player)
		else
			make_wraith(a.x,a.y,is_player)
		end
	--to tier 0
	elseif a.tier-1==0 then
		if is_player then
			gstate=gst_dead
			sfx(4)
		end
	end
	
	--destroy actor
	del(a.pool,a)
end

--init blaster
function init_blaster(a)
	--target
	a.ptargs=a.targs
	
	--movement
	a.pspd=4
	a.paccel=0.1
	a.pethereal=false
	a.pcost=20
	a.precoil=3
	a.pfollow=false
	
	--draw
	a.pc1=7
	a.pc2=6
	
	--lifetime
	a.plife=30
end

--update blaster
function update_blaster(a)
	--check blast input + meter cost
	if a.xactionp and a.meter>0 then
		--blast
		spawn_proj(a,a.x,a.y,a.dx,a.dy,a.pburst)
		a.meter-=a.pcost
		a.vx+=-a.dx*a.precoil
		a.vy+=-a.dy*a.precoil
		
		--cooldown
		a.cooldwn=a.maxcooldwn
		a.xactionp=false
		
		--if player
		if a==player then
			sfx(0)
		end
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
	wraith.ascenders=tombs
	wraith.targs={ghosts,wraiths}
	
	--trail
	init_trail(wraith,5)
	
	--dash
	init_dash(wraith,4,8)
	
	--blaster
	init_wraith_blaster(wraith)
	
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
		wraith.oprompt="🅾️ dash"
		wraith.xprompt="❎ shoot"
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
	update_dash(wraith)
	update_blaster(wraith)
	update_trail(wraith)
	
	--move and collide
	move_and_collide(wraith)
	
	--check ascendance
	check_ascend(wraith)
end

--renders the wraith
function draw_wraith(wraith)
	if player.tier==1 then
		draw_actor(wraith)
	end
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
	wraith.dx=wraith.tx-wraith.x
	wraith.dy=wraith.ty-wraith.y
	normalize_dir(wraith)
end

--init wraith blaster
function init_wraith_blaster(wraith)
	init_blaster(wraith)
	wraith.pc1=9
	wraith.pc2=8
	wraith.paccel=0.05
	wraith.pburst=4
	wraith.psize=2
	wraith.pspd=2
	wraith.plife=90
	wraith.pfollow=true
	wraith.pcost=30
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
	skeleton.ascenders=beds
	skeleton.targs={humans}
	
	--trail
	--init_trail(skeleton,7)
	
	--sprite
	skeleton.rsprs={36,52}
	skeleton.dsprs={37,53}
	skeleton.dgsprs={38,54}
	skeleton.sprs=skeleton.rsprs
	
	--run
	init_run(skeleton,3)
	
	--player or npc
	if is_player then
		skeleton.update_input=update_player_input
		skeleton.goal="웃fight humans."
		skeleton.oprompt="🅾️ run"
		skeleton.xprompt="❎ throw"
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
	update_run(skeleton)
	
	--move and collide
	move_and_collide(skeleton)
	
	--check ascendance
	check_ascend(skeleton)
end

--renders the skeleton
function draw_skeleton(skeleton)
	if player.tier!=1 then
		draw_actor(skeleton)
	else
		pset(skeleton.x,skeleton.y,7)
	end
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
	skeleton.dx=skeleton.tx-skeleton.x
	skeleton.dy=skeleton.ty-skeleton.y
	normalize_dir(skeleton)
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
	--init_trail(human,4)
	
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
	
	--run
	init_run(human,3)
	human.contactdmg=false
	
	--player or npc
	if is_player then
		human.update_input=update_player_input
		human.goal="✽kill monsters"
		human.oprompt="🅾️ run"
		human.xprompt="❎ use item"
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
	update_run(human)
	
	--move and collide
	move_and_collide(human)
	
	--check ascendance
	check_ascend(human)
end

--renders the human
function draw_human(human)
	if player.tier!=1 then
		draw_actor(human)
	else
		pset(human.x,human.y,7)
	end
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
	human.dx=human.tx-human.x
	human.dy=human.ty-human.y
	normalize_dir(human)
end
-->8
--projectile

--init projectile
function spawn_proj(a,x,y,dx,dy,burst)
	local proj={}
	proj.owner=a
	proj.targs=a.targs
	
	--dimensions
	proj.bbhw=a.psize --bounding box half width
	proj.bbhh=a.psize --bounding box half height
	
	--movement
	proj.x=x --x position
	proj.y=y --y position
	proj.vx=dx*burst --x velocity
	proj.vy=dy*burst --y velocity
	proj.spd=0 --speed (for queries)
	proj.maxspd=a.pspd --current max move speed
	proj.normspd=a.pspd --normal max move speed
	proj.accel=a.paccel --acceleration
	proj.ethereal=a.pethereal --ethereal=no wall collisions
	proj.follow=a.pfollow --follow owner
	
	--draw
	proj.c=a.pc1
	proj.draw=draw_ghost_proj
	
	--lifetime
	proj.life=a.plife
	
	--input
	proj.dx=dx
	proj.dy=dy
	
	--trail
	init_trail(proj,a.pc2)
	
	--add to projectile pool
	add(projs,proj)
end

--update projectile trail
function update_proj_trail(p)
	add_p(p.x+irnd(-p.bbhw,p.bbhw),
		p.y+irnd(-p.bbhh,p.bbhh),p.ctrail)
end

--update projectile
function update_proj(p)
	--trail
	update_proj_trail(p)
	
	--follow
	if p.follow then
		--set direction
		p.dx=p.owner.x-p.x
		p.dy=p.owner.y-p.y
		normalize_dir(p)
	end
	
	--move and collide
	move_and_collide(p)
	
	--check collisions
	local oa=touching(p,p.targs)
	if oa!=nil and oa!=p.owner then
		actor_kill(p.owner,oa)
	end
	
	--life timer
	p.life-=1
	if (p.life<=0) del(projs,p)
end

--draw projectile
function draw_proj(p)
	if ((player.tier>1 and 
		p.owner.tier>1) or
		(player.tier==1 and 
		p.owner.tier==1)) then
		p.draw(p)
	end
	--draw hitbox
	--draw_hitbox(p)
end

--draw ghost projectile
function draw_ghost_proj(p)
	circfill(p.x,p.y,p.bbhw+1,p.ctrail)
	circfill(p.x,p.y,p.bbhw,p.c)
end
__gfx__
00000000000000000000000000000000000000000000000000050000000fff5000000050005f00001dddddd11dd11dd11d1111d1000000000000500005050000
00000000000ccc00000cc00000cc00000055770000500500005550005f555500005555f0005555ffd555555dd556655dd165561d005000000005450054545000
0070070000cc11c000cccc000ccccc00055557d0055555500555550005fff15005ffff5005ffff5fd111111dd516615d16111161054555500054445005450000
000770000cccccd00cccccc00cccc1c000555500055555505555577005ffff5055ffff5f05fff155166556611665566111666611544666750005650054565000
000770000cccccd00c1cc1c000cccc10005555000755557005555d7005ffff5055ffff5f05ffff50166556611665566111666611054555500005650005056500
0070070000cc11c00c1cc1c000c1ccd0055557d0077557700057dd0005fff150051ff15f05f1ff50d111111dd516615d16111161005000000005650000005750
00000000000ccc0000cddc00000c1d000055770000d00d0000077000005555f50f55550505555500d555555dd556655dd165561d000000000005750000000500
0000000000000000000000000000000000000000000000000000000000055000050000000550f5001dddddd11dd11dd11d1111d1000000000000500000000000
00000000000000000000000000000000000000000000000000050000000550000500000000000000d444444444444444addddddddddddddd0000000000000000
00000000000111000001100000110000005588000050050000555000005555f50f55550000555555155555555555555fc555555555555557000d0d000d000d00
055555500011cc10001111000111110005555890055555500555550005fff15005ffff5055ffff551677615111115115c6776c5ccccc5cc500d7d7d0d7ddd7d0
54444815011111200111111001111c1000555500055555505555588005ffff50f5ffff55f5fff1501767611111111115c7676cccccccccc5000d7d000d777d00
545d55500111112001c11c10001111c000555500085555800555598005ffff50f5ffff5505ffff5f1767611111111115c7676cccccccccc5000d7d00d7ddd7d0
54d000000011cc1001c11c10001c112005555890088558800058990005fff150f51ff15005f1ff551677611115111115c6776cccc5ccccc5000d7d000d000d00
0500000000011100001221000001c2000055880000900900000880005f555500505555f00f555500155555555555555fc55555555555555700d7d7d000000000
00000000000000000000000000000000000000000000000000000000000fff50000000500ff50000d44444f4444444f4addddd7ddddddd7d000d0d0000000000
00000000000bbb50000000500005b00000dd77d000dddd0000dddd00000444500000005000540000d222222d44444f44aeeeeeeaddddd7dd000000001dd11dd1
005550005b555500005555b0005555bb0d77dd000d7777d00d717dd7545555000055554000555544f567765fffffffff756776577777777700d70000d516615d
0544450005bbb85005bbbb5005bbbb5bd7117dd0d717717dd77717d70544415005444450054444544576675446a66664d576675dd1a1111d0d7d0000d516615d
00d5450005bbbb50b5bbbb5b05bbb855d77777d0d717717dd1777ddd054444505544445405444155f577775f64448846757777571ddd88d107d7d000d515515d
000d450005bbbb50b5bbbb5b05bbbb50d77777d0dd7777d7d71777d00544445055444454054444504566665464884446d566665d1d88ddd1000d7d70d515515d
0005850005bbb850b58bb85b05b8bb50d7117dd00dd77dd7dd7d7dd00544415005144154054144504522225446666a64d5eeee5dd1111a1d0000d7d0d516615d
00051500005555b55b5555050b5555000d77dd7d07dddd0d0ddddd00005555450455550505555500f522225fffffffff75eeee577777777700007d00d516615d
00005000000bbb50050000000bb5b50000ddd0000d0000000007d00000055000050000000550450045222254444444f4d5eeee5ddddddd7d000000001dd11dd1
00000000000bbb50050000000000000000ddd00000dddd0000dddd000005500005000000000000004522255444466f44d5eee55dddd117dd000000001d1111d1
00500000005555b50b555500005555bb0d77dd7d0d7777d00d717dd0005555450455550000555555f522225fff6446ff75eeee57771dd17700000000d161161d
0545000005bbb85005bbbb5005bbbb5bd7117dd0d717717dd77717d0054441500544445055444455455222544fa48644d55eee5dd7ad81dd0000000016166161
5454500005bbbb50b5bbbb5b55bbb855d77777d0d717717dd1777dd7054444504544445545444150f522225fff6486ff75eeee57771d81770000000015166151
0d5d450005bbbb50b5bbbb5bb5bbbb5bd77777d07d7777ddd71777dd0544445045444455054444544522255444684644d5eee55ddd18d1dd0000000015166151
0000585005bbb850b58bb85b05b8bb55d7117dd07dd77dd0dd7d7dd00544415045144150054144554522225444684a44d5eeee5ddd18dadd0000000016166161
000005d05b555500505555b50b5555000d77dd00d0dddd700ddddd00545555005055554004555500ff5555ffff6446ff77555577771dd17700000000d161161d
00000000000bbb50000000500bb5000000dd77d0000000d0077d0000000444500000005004450000444444f4444664f4dddddd7dddd11d7d000000001d1111d1
22222222222222222222222244444444444444444444444433333333333333333333333322222222222222222222222222222222cccccccccccccccccccccccc
2202220222500222222020524494449444d99444444949d43343334333d443333334346322522222222222222222222222222222cccc1ccccccccccccccccccc
202500222222205225020222494d9944444449d44d949444343644333f3f34d33643433325222222220022222222022222222222ccc1c11cccccc11ccccccccc
202222242424222222222022494444434343444444444944343333f3f1f1f33f3333343322222222252202222220222222222222c7cccccccccccccccccccccc
2520224222424224222205224d4944344434344344449d4436343f1f3f1f1ff1f333463322220222222222222222222222222222cccccccccccccccccccccccc
2002222424222442422222224994444343444334344444443443f3f1f1fff11f1f33333322202022222200522222522222222222ccc1cc7ccccccccccccccccc
222242444444444444222222444434333333333333444444333f1f1c1c111cc1c1ff333322222222222022222222222222222222c11c1cccc7cccccccccccccc
222244444444444444442222444433333333333333334444333f11cccccccccccc11f33322222222222222222222222222222222cccccccccccccccccccccccc
2522244444444444444222224d44433333333333333444443633f1cccccccccccc1f333344444f44444444444444444444444444dddddddd9999999988888888
220242444444444444422502449434333333343333344d94334f1f1ccccccccccc1f3643ffffffff444449444444444444444444d777777d9aaaaaa98eeeeee8
20222444449444d444242222494443333333434333434444343ff1cccc7cccccc1f1f3334f444444444494444444444444444444d7dddddd9a9999998e888888
22242244494944444422202244434433363333333344494433f1ff1cccccc7ccc1ff3433ffffffff4d444444444444d444444444d777777d9aaaaaa98eeeeee8
222242444444444444422202444434333333333333344494333f1f1ccccccccccc1f3343444f4444444444444444444444444444ddd7dddd999a9999888e8888
2502244444444444442422024d94433333333633334344943643f1cccc1cccccc1f1f34344f44444444949d44944444444444444dd7ddddd99a9999988e88888
2020224444d44444444222524949443333333333333444d434343f1cc1c1cccccc1f3363ffffffff449d9d444494444444444444d777777d9aaaaaa98eeeeee8
2222244444444444444202224444433333333333333434443333f1cccccccccccc1f3333444444f4444444444444444444444444dddddddd9999999988888888
222224444444444444422222444443333333333333344444333ff1cccccccccccc1f3333ddddd7dd333333333333333333333333000000000000000000000000
22242444444444444424222244434333333333333343444433f1f11cc1c1cc1cc1f1f33377777777336343333333333333333333000000000000000000000000
2222442442424424444220524444334334343343333449d4333f11f11f1f11f11c1f3463d7dddddd344433333633333333333333000000000000000000000000
22242222242422222422220244434444434344444344449433f1ff3ff1f1ff3ff1f3334377777777333333333333334333333333000000000000000000000000
222222224222422222422222444444443444344444344444333f33331f3f1f333f1f3333ddd7dddd333333333333343333333333000000000000000000000000
2220520222022202222202024449d494449444944444949433346343f343f34333f34343dd7ddddd333343333333333333333333000000000000000000000000
2502025020500252222050524d9494d949d994d44449d9d436434364346443633334646377777777333634433333333333333333000000000000000000000000
222222222222222222222222444444444444444444444444333333333333333333333333dddddd7d333333333333333333333333000000000000000000000000
000000000000000000000000000000000000000000000000222555222255552225555552dd11111dd555555d2226622222020252225555225555555555555555
00000000000000000000000000000000000000000000000025556522255665525566665571212217569769652262262222202522254444525656656556766665
000000000000000000000000000000000000000000000000556665522577665556667665d121221d5a6556a52562262226622662544ff4455656656555555555
0000000000000000000000000000000000000000000000005566765525655665567765657121221757566565022662026226622654f44f455756756556656765
000000000000000000000000000000000000000000000000156775655566666556655665d121221d56566575222662226226622654f44f455657656556656665
000000000000000000000000000000000000000000000000156655655566665555666665d121221d5a6556a52062265226622662544ff4455656657555555555
00000000000000000000000000000000000000000000000015566655155555511556665571212217569679652262262522250222254444525656656556766675
000000000000000000000000000000000000000000000000215555512111551221555552dd11111dd555555d2226622225022222225555225555555555555555
949494949494949494949494949494949494949494949494949494153545d5d5d5d5e5e5757575e5e5d5d5d5d54555159494949494a796969696969697969796
97969796e5e5a79696a7a7d2a79494949494949494949494159494949494949494b7a094c094c0941594949415949494949494949415949494949494e79595e7
9494949494949494949494949494949494949494949494949494941535454545a7d5d5e5e575e5e5d5d5a745454555159494949494a7a7969696969697969796
9796979696e5a79696a79696a79494949494949494949494159494949494949494b7c7c7c7c7c7941594b7941594b7c7c7c7c7c7941594c7c7c7c7c7e7f7f7e7
949494949494949494949494949494949494949494949494949494153646463645d5d5d5e5e5e5d5d5d5455646465615949494949494a7a79696969697969796
979697969696d39696a79696a79494949494949494949494159494949494949494b79494949494151594b7f215f2b7a094c094a0941594c094c094a0b7949494
949494949494949494949494949494949494949494949494949494151515153545d5d5d5d5d5d5d5d5d545551515151594949494949494a7a796969696969696
969696969696a79696a7c1d1a79494949494949494949494159494949494949494b79494949415151594b7941594b715151515151515151515151515b7949494
9494949494949494949494949494949494949494949494949494949494941535454545a7d5d5d5a745454555159494949494949494949494a7a7d2a7a7a7a7a7
a7a7a7a7a7a7a7a7a7a7a7a7a79494949494949494949494159494949494949494949494151515941594b7b015f2b7b094c094b0941594a094b094a0b7949494
949494949494949494949494949494949494949494949494949494949494153646463645d5d5d545564646561594949494949494949494949494159494949494
9494949494949494949494949494949494949494949494941515151515151515151515151594b7941594b7941594b7c7c7c7c7c7941594c7c7c7c7c7b7949494
949494949494949494949494949494949494949494949494949494949494151515153545d5d5d545551515151594949494949494949494949494159494949494
9494949494949494949494949494949494949494949494949494949494949494949494949494b7f215b0b7f315f2b7b094a094c0941594a094a094b0b7949494
94949494949494949494949494949494949494949494949494949494949494949415354545454545551594949494949494949494949494949494159494949494
949494949494949494949494949494949494949494949494949494949494949494b794949494b7941594b7941594b715151515151515151515151515b7949494
94949494949494949494949494949494949494949494949494949494949494949415364646464646561594949494949494949494949494949494159494949494
949494949494949494949494949494949494949494949494949494949494949494b794949494b7f315f2b7f315b0b7a094a094b0949494c094a094a0b7949494
94949494949494949494949494949494949494949494949494949494949494949415151515151515151515151515151515151515151515151515159494949494
949494949494949494949494949494949494949494949494949494949494949494c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
949494949494949494d7d7d794949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
9494949494949494d7a1b195d7949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
9494949494949494d7959595d7949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
9494949494949494d7959595d7949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
141414141414141414d7b2d714141414141414141414141414249494949494949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
44444444444444444444444444444444444444444444444454241414141424949494949494949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
74747474747474747474747474747474747474747474748454444444445424141414141424949494949494949494949494949494949494949494949494949494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
757575757575757575757575757575757575757575757584747474748454444444444454241414a014141414b014141414141414141414141414141414249494
94949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
75757575757575757575757575757575757575757575757575757575847474747474845444444444444444444444444444444444444444444444444454241414
1414a014141414141414c01414141424949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
75757575757575757575757575757575757575757575757575757575757575757575847474747474747474747474747474747474747474747474748454444444
44444444444444444444444444445425949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
75757575757575757575757575757575757575757575757575757575757575757575757575757575757575757575757575757575757575757575758474747474
74747474747474747474747474845525949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
75757575757575757575757575757575757575757575757575757575757575757575757575757575757575757575757575757575757575757575757575757575
75757575757575757575757575855525949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494
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
4949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949497878494949787878787878787878787849494949494949494949494949494949494949
4949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494978784949784949494949494949787849494949494949494949494949494949494949
4949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949497849787849784949494949494949497849494949494949494949494949494949494949
4949494949494949494949497f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f2d7f49494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949787849494949784949784949494949497849494949494949494949494949494949494949
4949494949494949494949497f1c1d69692c7f1a1b59595959597f2a592a595959597f697f49494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949784949494949784949787849497849497849494949494949494949494949494949494949
4949494949494949494949497f696969693c7f595959595959597f3a593a595959597f697f494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949497849497878494978494978494949497d7d7d7d7d7d7d7d7d7d4949494949
4949494949494949494949497f69696969697f1a1b59595959597f595959595959597f697f494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949784949497878497878494978494978494949497d5959597d595959597d492f494949
4949494949494949494949497f2d7f7f7f7f7f7f7f7f7f7f7f2b7f7f7f7f7f7f7f2b7f697f494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494978784949494949497849784978784978494949497d5959593b595959597d4949494949
4949494949494949494949497f697a695f5f3d69696969696969696969696969696969697f494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949497878787849784978784949784978784978494949497d5959597d595959597d492f494949
4949494949494949494949497f69697a5f5f7f7f7f7f7f7f7f2b7f7f7f7f7f7f7f2b7f697f494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949497878494949787849787849494949494978494949497d5959597d595959597d4141414142
4949494949494949494949497f79697a5f5f7f2a592a595959597f1a1b59595959597f697f494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949497849497849497849497878784978494949497d1a1b597d595959593b5151515152
4949494949494949494949497f79697a5f5f7f3a593a595959597f595959595959597f697f494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949497849497849784949497849787878494949497d7d7d7d7d7d7d7d7d7d6161605152
4949494949494949494949497f69697a5f5f7f595959595959597f1a1b59595959597f697f49494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949497849784949787849494949787849494949494949494949494949494949505152
4949494949494949494949497f697a695f5f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f2d7f49494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949497849784949787849497878787849494949494949494949494949494949505152
4949494949494949494949497f6969695f5f696969697f494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949784949787849497878784978494949494949494949494949494949505152
4949494949494949494949497f6969695f5f696969697f494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494978784949497849497878494949494949494949494949494949494949505152
4949494949494949494949497f7969695f5f6979695e7f494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494978784949497849497878497849494949494949494949494949494949505152
4949494949494949494949497f7969695f5f6979695e7f494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949784949497849494949497849494949494949494949494949494949505152
4949494949494949494949497f7969695f5f6979695e7f494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949787849497878787878787849784949494949494949494949494949505152
4949494949494949494949497f6969695f5f696969697f494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949497849497878787878787878784949494949494949494949494949505152
494949494949494949494949497f7f7f2d2d7f7f7f7f49494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494949494978784949494949494949494949494949494949494949505152
494949494949494949494949494949495151494949494949494949494949494949515151515151515151515151515151515151515151515151515149494949494949494949494949494949494949494949494949494949494949494949494949497c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c505152
494949494949494949494949494949495151494949494949494949494949494949514344444444444551494949494949494949494949494949495149494949494949494949494949494949494949494949494949494949494949494949494949497b494949497b0b512f7b3f512f7b0a490b490a4949490a490c490b7b505152
494949494949494949494949494949495151494949494949494949494949494949515354545454545551494949494949494949494949494949495149494949494949494949494949494949494949494949494949494949494949494949494949497b494949497b4951497b4951497b515151515151515151515151517b505152
4949494949494949494949494949494951514949494949494949494949495151515153545d5d5d5455515151514949494949494949494949494951494949494949494949494949494949494949494949494949494949494949494949494949494949494949497b2f513f7b2f510b7b0a490a490c495a490b490a490a7b505152
4949494949494949494949494949494951514949494949494949494949495143444443545d5d5d5445444445514949494949494949494949494951494949494949494949494949494949494949494949494949494949494951515151515151515151515151497b4951497b4951497b7c7c7c7c7c495a497c7c7c7c7c7b505152
49494949494949494949494949494949515149494949494949494949494951535454547a5d5d5d7a545454555149494949494949494949497a7a2d7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a49494949494949494949495149494949494949494949495151514951497b2f513f7b0b490a490a495a490a490c490a7b505152
4949494949494949494949494949494951514949494949494949495151515153545d5d5d5d5d5d5d5d5d545551515151494949494949497a7a696969696969696969696969697a69696969697a49494949494949494949495149494949494949497b49494949515151497b4951497b5151515151515a5151515151517b505152
4949494949494949494949494949494951514949494949494949495143444443545d5d5d5e5e5e5d5d5d5445444445514949494949497a7a696969697969796979697969695e7a69696969693d51515151515151515151515149494949494949497b49494949495151497b0b512f7b0a490c490a495a490b490a490a7b505152
49494949494949494949494949494949515149494949494949494951535454547a5d5d5e5e575e5e5d5d7a545454555149494949497a7a696969696979697969796979695e5e7a69696969697a49494949494949494949495149494949494949497b7c7c7c7c7c4951497b4951497b7c7c7c7c7c495a497c7c7c7c7c7e7f2b7e
4949494949494949494949494949494951514949494949494949495153545d5d5d5d5e5e5757575e5e5d5d5d5d54555149494949497a69696969696979697969796979695e5e7a69696969697a49494949494949494949495149494949494949497b0b490a490a49514949495149494949494949495a4949494949497e59597e
5151515151515151515151515151515151515151515151515151515153545d5d5d5d5e57570b57575e5d5d5d5d54555149494949497a69696969696969696969696969695e5e7a69696969697a49494949494949494949495149494949494949497b51515151515151515151515151515151515151515151515151513b59597e
__sfx__
000100000000014550145501455015550155501655016550155500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000061000600036000260002600116000060002600026000160009600016000160000600006000060000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000061000510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000190501f050260502705000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000191500c150091500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
