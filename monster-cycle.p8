pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--monster cycle(v0.9.1)
--by nandbolt

--game state
gstate=0
gtime=0 --game time (steps)
ghigh=0 --high score (steps)
vnum="0.9.1"
debug_mode=false

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
ps2={}

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
water={87,77,78,79}

--main menu
mmtimer=0
mmx=0
mmy=0
mmstart=false
mmdelay=30
mmfade=30

--delay
delay=0

--fade
fade=0

--waves
omega=1/360
phase=0
amp=0

--fog
fogtimer=0
fogfreq=30
cfog={1,5,13}

--target indicator
ctarg={7}

--debugging
actors_inview=0

--init
function _init()
	--not menu state
	if gstate==gst_menu then
		mmx=irnd(0,(mw-ss)/ts)
		mmy=irnd(0,(mh-ss)/ts)
		music(0)
		load_highscore()
	else
		--clear music
		music(1)
		
		--clear run
		gtime=0
		
		--clear particles
		ps={}
		ps2={}
		
		--clear pools
		ghosts={}
		wraiths={}
		zombies={}
		skeletons={}
		humans={}
		
		--clear projectiles
		projs={}
		
		--reset fade
		fade=30
		
		--preprocess enemies
		for i=1,4 do
			make_ghost(irnd(0,mw),
				irnd(0,mw),false)
			make_wraith(irnd(0,mw),
				irnd(0,mw),false)
		end
		
		--zombies
		make_zombie(58*ts+hts, --small grave
			50*ts+hts,false)
		make_zombie(117*ts+hts, --large grave1
			37*ts+hts,false)
		make_zombie(117*ts+hts, --large grave2
			25*ts+hts,false)
		make_zombie(104*ts+hts, --large grave3
			31*ts+hts,false)
		make_zombie(33*ts+hts, --beach
			54*ts+hts,false)
		make_zombie(120*ts+hts, --forest
			55*ts+hts,false)
		make_zombie(37*ts+hts, --fountain
			41*ts+hts,false)
		make_zombie(92*ts+hts, --river
			31*ts+hts,false)
		
		--skeletons
		make_skeleton(58*ts+hts, --small grave
			46*ts+hts,false)
		make_skeleton(108*ts+hts, --large grave
			31*ts+hts,false)
		make_skeleton(103*ts+hts, --rocks
			5*ts+hts,false)
		make_skeleton(52*ts+hts, --hedges
			12*ts+hts,false)
		
		--humans
		make_human(16*ts+hts, --hotel
			10*ts+hts,false)
		make_human(115*ts+hts, --digger
			10*ts+hts,false)
		make_human(63*ts+hts, --church1
			31*ts+hts,false)
		make_human(73*ts+hts, --church2
			30*ts+hts,false)
		make_human(10*ts+hts, --beach
			54*ts+hts,false)
		make_human(92*ts+hts, --forest
			58*ts+hts,false)
		
		--add player
		update_spawnpoint(false)
		if debug_mode then
			make_human(spnr.x,spnr.y,true)
		else
			if rnd(1)<0.5 then
				make_ghost(spnr.x,spnr.y,true)
			else
				make_wraith(spnr.x,spnr.y,true)
			end
		end
	end
end

--main update
function _update()
	--fog
	update_fog()
	
	--update particles
	foreach(ps,update_p)
	foreach(ps2,update_p)
	
	--menu game state
	if gstate==gst_menu then
		if mmstart then
			if fade<=0 then
				gstate=gst_active
				_init()
			elseif (delay<=0) then
				fade-=1
			else
				delay-=1
			end
			omega=lerp(omega,0,0.1)
		elseif btnp(5) then
			mmstart=true
			fade=mmfade
			delay=mmdelay
			sfx(1)
			music(-1)
		end
	else
		--update spawner
		update_spawner()
		
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
			if mmstart then
				if fade<=0 then
					gstate=gst_active
					_init()
				else
					fade-=1
				end
			elseif btnp(5) then
				mmstart=true
				fade=mmfade
				sfx(1)
			end
		--active state
		else
			gtime+=1
			if (fade>0) fade-=1
		end
	end
end

--main draw
function _draw()
	--clear
	cls()
	
	--menu state
	if gstate==gst_menu then
		draw_mainmenu()
	else
		--draw tiles
		map(0,0,0,0,mw,mh)
		
		--draw low particles
		foreach(ps,draw_p)
		
		--draw actors
		foreach(ghosts,draw_ghost)
		foreach(wraiths,draw_wraith)
		foreach(zombies,draw_zombie)
		foreach(skeletons,draw_skeleton)
		foreach(humans,draw_human)
		
		--draw projectiles
		foreach(projs,draw_proj)
		
		--draw high particles
		foreach(ps2,draw_p2)
		
		--active state
		if gstate==gst_active then
			local xx,yy=cam.x+2,cam.y+2
			local val,str=0,""
			
			--goal
			str=player.goal
			shdwprint(str,xx,yy,7)
			
			--timer
			yy+=8
			local seconds=flr(gtime/30)
			str="time:"..seconds
			shdwprint(str,xx,yy,7)
			
			--xp
			yy+=8
			val=player.xp/player.maxxp
			rectfill(xx+9,yy+1,xx+41,yy+3,1)
			rectfill(xx+10,yy+2,xx+10+ceil(32*val),yy+4,10)
			str="xp"
			shdwprint(str,xx,yy,10)
			
			--meter
			yy+=8
			val=player.meter/player.maxmeter
			rectfill(xx+9,yy+1,xx+41,yy+3,1)
			rectfill(xx+10,yy+2,xx+10+clamp(flr(32*val),0,32),yy+4,7)
			str="★"
			shdwprint(str,xx,yy,7)
			
			--cooldown
			yy+=8
			val=player.cooldwn/player.maxcooldwn
			rectfill(xx+9,yy+1,xx+41,yy+3,1)
			rectfill(xx+10,yy+2,xx+10+flr(32*val),yy+4,13)
			str="⧗"
			shdwprint(str,xx,yy,13)
			
			--actors
			yy+=8
			val=#ghosts
			str="🐱 "..val
			shdwprint(str,xx,yy,12)
			yy+=8
			val=#wraiths
			str="🐱 "..val
			shdwprint(str,xx,yy,5)
			yy+=8
			val=#zombies
			str="😐 "..val
			shdwprint(str,xx,yy,3)
			yy+=8
			val=#skeletons
			str="😐 "..val
			shdwprint(str,xx,yy,7)
			yy+=8
			val=#humans
			str="웃 "..val
			shdwprint(str,xx,yy,15)
			
			--controls
			yy+=34
			str=player.oprompt
			shdwprint(str,xx,yy,12)
			yy+=8
			str=player.xprompt
			shdwprint(str,xx,yy,14)
			
			--highscore
			local hseconds=flr(ghigh/30)
			if (ghigh==0) hseconds="none"
			xx+=hss+22
			yy=cam.y+2
			str="high:"..hseconds
			shdwprint(str,xx,yy,10)
			
			--target line
			draw_targ_line()
			
			--debug
			if debug_mode then
				yy+=8
				local dval=0
				cursor(xx,yy)
				print("mem:"..stat(0),7)
				yy+=6
				cursor(xx,yy)
				print("cpu:"..stat(1),7)
				yy+=6
				cursor(xx,yy)
				print("fps:"..stat(7),7)
				yy+=6
				dval=#ps+#ps2+
					#projs+#ghosts+
					#wraiths+#zombies+
					#skeletons+#humans
				cursor(xx,yy)
				print("objs:"..dval)
				yy+=6
				cursor(xx,yy)
				print("vis:"..actors_inview)
				actors_inview=0
			end
		--death menu
		elseif gstate==gst_dead then
			local xx,yy=cam.x+33,cam.y+33
			local str=""
			
			--death prompt
			str="more than death."
			oprint(str,xx,yy,7,1)
			
			--restart prompt
			yy+=32
			str="❎ to retry"
			oprint(str,xx,yy,7,1)
		--victory menu
		elseif gstate==gst_complete then
			local xx,yy=cam.x+32,cam.y+16
			mmtimer+=1
			
			--victory prompt
			local omegat=omega*mmtimer
			phase=0.22
			amp=32
			local val=sin(mmtimer/60)
			local cols={0,1,2,8}
			cursor(xx,yy+1)
			print("monster ascended.",cols[flr(val*2.4+2.5)])
			cursor(xx+2,yy+1)
			print("monster ascended.",cols[flr(val*1.4+1.5)])
			cursor(xx+1,yy+2)
			print("monster ascended.",cols[flr(val*2.4+2.5)])
			cursor(xx+1,yy)
			print("monster ascended.",cols[flr(val*1.4+1.5)])
			cursor(xx+1,yy+1)
			print("monster ascended.",7)
			
			--time
			yy+=41
			xx+=1
			local seconds=flr(gtime/30)
			local c,nh=7,""
			if (gtime==ghigh) then
				c=10
				nh="(new high!)"
			end
			str="time:"..seconds..nh
			oprint(str,xx,yy,c,1)
			
			--restart prompt
			yy+=40
			str="❎ to play again"
			oprint(str,xx,yy,7,1)
		end
		
		--fade
		if gstate==gst_active then
			if fade>0 then
				circfill(cam.x+hss,cam.y+hss,(hss+28)*(fade/30),1)
			end
		else
			if mmstart then
				circfill(cam.x+hss,cam.y+hss,(hss+28)*(1-(fade/30)),1)
			end
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
rt2o2=0.7071 --sqrt(2)/2
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

--returns manhattan distance
function get_mdist(x1,y1,x2,y2)
	return abs(x1-x2)+abs(y1-y2)
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

--point in view
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
	ghost.sfxoaction=9
	
	--blaster
	init_ghost_blaster(ghost)
	
	--player or npc
	if is_player then
		ghost.update_input=update_player_input
		ghost.goal="✽fight ghosts."
		ghost.oprompt="🅾️/z dash"
		ghost.xprompt="❎/x shoot"
		player=ghost
	else
		init_actor_npc(ghost)
		ghost.wander=ghost_wander
		ghost.fight=ghost_fight
		ghost.flee=ghost_flee
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

--init ghost blaster
function init_ghost_blaster(ghost)
	init_blaster(ghost)
	ghost.pc1=12
	ghost.pc2=1
	ghost.paccel=0.05
	ghost.pburst=1
	ghost.psize=1
	ghost.pethereal=true
	ghost.sfxxaction=11
end

--enter ghost wander state
function ghost_wander(ghost)
	enter_wander_state(ghost)
end

--enter ghost fight state
function ghost_fight(ghost)
	enter_fight_state(ghost)
	
	--choose action
	if rnd(1)<0.5 then
		ghost.oaction=true
	else
		ghost.xactionp=true
	end
end

--enter ghost flee state
function ghost_flee(ghost)
	enter_flee_state(ghost)
end
-->8
--particles

--add particle (low)
function add_p(x,y,c)
	local p={}
	p.x,p.y=x,y
	p.vx,p.vy=0,0
	p.life=10
	p.c=c
	p.sys=ps
	add(ps,p)
end

--add particle (high)
function add_p2(x,y,c)
	local p={}
	p.x,p.y=x,y
	p.vx,p.vy=(rnd(1)-0.5)*0.5,(rnd(1)-0.5)*0.5
	p.life=90
	p.c=c
	p.sys=ps2
	add(ps2,p)
end

--update particle
function update_p(p)
	if (p.life<=0) then
		--destroy particle
		del(p.sys,p)
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
	if p.life>5 then
		circfill(p.x,p.y,1,p.c)
	else
		pset(p.x,p.y,p.c)
	end
end

--draw particle
function draw_p2(p)
	local r=(0.49*sin((90-p.life)/90+0.25)+0.5)*4
	if p.life>15 then
		circfill(p.x-1,p.y,r,6)
		circfill(p.x,p.y+1,r-1,p.c)
	end
	if p.life>5 and p.life<80 then
		circfill(p.x+1,p.y+3,r,6)
		circfill(p.x+2,p.y+4,r-1,p.c)
	end
	if p.life>10 and p.life<85 then
		circfill(p.x-3,p.y+3,r,6)
		circfill(p.x-1,p.y+4,r-1,p.c)
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
	
	--movement
	zombie.accel=0.05
	
	--trail
	init_trail(zombie,11)
	zombie.trailon=false
	
	--sprite
	zombie.rsprs={33,49}
	zombie.dsprs={34,50}
	zombie.dgsprs={35,51}
	zombie.sprs=zombie.rsprs
	
	--dash
	init_run(zombie,4)
	zombie.sfxoaction=14
	
	--blaster
	init_zombie_blaster(zombie)
	
	--player or npc
	if is_player then
		zombie.update_input=update_player_input
		zombie.goal="웃eat humans."
		zombie.oprompt="🅾️/z charge"
		zombie.xprompt="❎/x breath"
		player=zombie
	else
		init_actor_npc(zombie)
		zombie.wander=zombie_wander
		zombie.fight=zombie_fight
		zombie.flee=zombie_flee
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
	update_blaster(zombie)
	update_trail(zombie)
	
	--move and collide
	move_and_collide(zombie)
	
	--check ascendance
	check_ascend(zombie)
end

--renders the zombie
function draw_zombie(zombie)
	if player.tier!=1 then
		draw_actor(zombie)
	end
end

--init zombie blaster
function init_zombie_blaster(zombie)
	init_blaster(zombie)
	zombie.pc1=3
	zombie.pc2=11
	zombie.paccel=0.05
	zombie.pburst=1
	zombie.precoil=0
	zombie.psize=2
	zombie.pspd=0
	zombie.plife=30
	zombie.pcost=30
	zombie.pethereal=true
	zombie.pdraw=draw_zombie_proj
	zombie.sfxxaction=12
end

--enter zombie wander state
function zombie_wander(zombie)
	enter_wander_state(zombie)
end

--enter zombie fight state
function zombie_fight(zombie)
	enter_fight_state(zombie)
	
	--choose action
	if rnd(1)<0.5 then
		zombie.oaction=true
	else
		zombie.xactionp=true
	end
end

--enter zombie flee state
function zombie_flee(zombie)
	enter_flee_state(zombie)
end
-->8
--actor

--init actor
function init_actor(a,x,y,is_player)
	--dimensions
	a.bbhw=3 --bounding box half width
	a.bbhh=3 --bounding box half height
	a.xfacing=1 --x facing direction
	a.yfacing=0 --y facing direction
	a.inview=false --in camera view
	
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
	a.bounce=false --bounce on walls
	
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
	
	--sfx
	a.sfxoaction=0
	a.sfxxaction=0
	
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
function init_actor_npc(a)
	a.update_input=npc_input
	a.targ=nil --target
	a.tx=a.x --target x position
	a.ty=a.y --target y position
	a.mstate=st_wander --mental state
	a.mfreq=30 --think frequency
	a.mcnt=irnd(0,29) --mental counter
	a.tradius=48 --target detection radius
	
	--states
	a.wander=enter_wander_state
	a.fight=enter_fight_state
	a.flee=enter_flee_state
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
	local collision=false
	local maxspd=a.maxspd
	if not a.ethereal and
		in_table(water,mget(a.x/ts,a.y/ts)) then
		maxspd*=0.25
		if a.dx!=0 or a.dy!=0 then
			add_p(a.x-clamp(a.vx+rnd(4)-2,
				-8,8),a.y-clamp(a.vy+rnd(4)-2,
				-8,8),1)
		end
	end
	
	--update velocity
	a.vx=lerp(a.vx,
		a.dx*maxspd,
		a.accel)
	a.vy=lerp(a.vy,
		a.dy*maxspd,
		a.accel)
	
	--handle x collision
	local bb=a.x-a.bbhw
	if(a.vx>0)bb=a.x+a.bbhw
	local tx=(bb+a.vx)/ts
	local ty=a.y/ts
	if not a.ethereal and
		in_table(walls,mget(tx,ty)) then
		--x collision
		collision=true
		if (a.bounce) then
			a.vx*=-1
			tx=(bb+a.vx)/ts
			if in_table(walls,mget(tx,ty)) then
				a.vx=0
			end
		else
			a.vx=0
		end
	end
	a.x=clamp(a.x+a.vx,0,mw-hts)
	
	--handle y collision
	bb=a.y-a.bbhh
	if(a.vy>0)bb=a.y+a.bbhh
	tx=a.x/ts
	ty=(bb+a.vy)/ts
	if not a.ethereal and 
		in_table(walls,mget(tx,ty)) then
		--y collision
		collision=true
		if (a.bounce) then
			a.vy*=-1
			ty=(bb+a.vx)/ts
			if in_table(walls,mget(tx,ty)) then
				a.vy=0
			end
		else
			a.vy=0
		end
	end
	a.y=clamp(a.y+a.vy,0,mh-hts)
	
	--update speed
	a.spd=get_vec_len(a.vx,a.vy)
	
	--update view
	a.inview=point_in_view(a.x,a.y)
	if (a.inview) actors_inview+=1
	
	return collision
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
	rect(bbx1,bby1,bbx2,bby2,7)
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
				a.xfacing=rt2o2
			else
				a.flipx=true
				a.xfacing=-rt2o2
			end
			if a.vy>0 then
				a.flipy=false
				a.yfacing=rt2o2
			else
				a.flipy=true
				a.yfacing=-rt2o2
			end
		--down sprite
		elseif abs(a.vx)<abs(a.vy) then
			a.sprs=a.dsprs
			a.xfacing=0
			
			--update y facing direction
			if a.vy<0 then
				a.flipy=true
				a.yfacing=-1
			elseif a.vy>0 then
				a.flipy=false
				a.yfacing=1
			end
		--right sprite
		else
			a.sprs=a.rsprs
			a.yfacing=0
			
			--update x facing direction
			if a.vx<0 then
				a.flipx=true
				a.xfacing=-1
			elseif a.vx>0 then
				a.flipx=false
				a.xfacing=1
			end
		end
	end
	
	--final sprite
	local sprite=a.sprs[a.spridx]
	if (a.tier==1 and a.dashing) sprite+=16
	spr(sprite,a.x-hts,a.y-hts,
		1,1,a.flipx,a.flipy)
	
	--debug
	draw_debug(a)
end

--update meter
function update_meter(a)
	if a.cooldwn<=0 then
		a.meter=a.maxmeter
		a.cooldwn=a.maxcooldwn
	elseif a.meter<a.maxmeter then
		a.cooldwn-=1
	end
end

--init trail
function init_trail(a,c)
	a.normctrail=c --normal trail color
	a.ctrail=a.normctrail --trail color
	a.trailon=true --trail on
end

--update trail
function update_trail(a)
	if a.inview then
		if a.trailon or a.xp==a.maxxp then
			if a.xp==a.maxxp then
				a.ctrail=10
			elseif a.dashing then
				a.ctrail=a.dashctrail
			else
				a.ctrail=a.normctrail
			end
			add_p(a.x+irnd(-a.bbhw,a.bbhw),
				a.y+irnd(-a.bbhh,a.bbhh),a.ctrail)
		end
	end
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
	a.burststr=0
	a.burstcost=30
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
			if a.inview then
				sfx(a.sfxoaction)
			end
		end
		a.dashing=true
		a.invulnerable=true
		a.cooldwn=a.maxcooldwn
		a.meter-=1
	else
		a.dashing=false
		a.invulnerable=false
		update_meter(a)
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
			--burst
			if a.burststr!=0 then
				a.vx+=a.dx*a.burststr
				a.vy+=a.dy*a.burststr
				a.meter-=a.burstcost
			end
			
			--if player
			if a.inview then
				sfx(a.sfxoaction)
			end
		end
		a.running=true
		a.cooldwn=a.maxcooldwn
		a.meter-=1
	else
		a.running=false
		update_meter(a)
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
	
	--ascend sound
	if (a.inview) sfx(3)
	
	--if player and ready to ascend
	if a==player then
		if a.xp==a.maxxp then
			if a.tier==1 then
				player.goal="◆find tombtone!"
			elseif a.tier==2 then
				player.goal="⌂find bed!"
			elseif a.tier==3 then
				player.goal="∧find water!"
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
	if (a.inview) sfx(7)
	
	--to tier 2
	if a.tier+1==2 then
		if rnd(1)>0.5 then
			make_zombie(a.x,a.y,is_player)
		else
			make_skeleton(a.x,a.y,is_player)
		end
		
		--undead music
		if is_player then
			music(2)
		end
	--to tier 3
	elseif a.tier+1==3 then
		make_human(a.x,a.y,is_player)
		
		--human music
		if is_player then
			music(3)
		end
	--to tier 4
	elseif a.tier+1==4 then
		if is_player then
			--victory
			gstate=gst_complete
			mmstart=false
			if gtime<ghigh or ghigh==0 then
				save_highscore(gtime)
				sfx(8)
			end
		end
	end
	
	--destroy actor
	del(a.pool,a)
end

--get nearby target
function get_near_targ(a)
	for pool in all(a.targs) do
		for oa in all(pool) do
			if a!=oa then
				local size=a.tradius
				if point_in_box(oa.x,oa.y,
					a.x-size,a.y-size,
					a.x+size,a.y+size) then
					return oa
				end
			end
		end
	end
	return nil
end

--enter wander state
function enter_wander_state(a)
	a.mstate=st_wander
	a.oaction=false
	a.xactionp=false
end

--enter fight state
function enter_fight_state(a)
	a.mstate=st_fight
end

--enter flee state
function enter_flee_state(a)
	a.mstate=st_flee
end

--npc think
function npc_think(a)
	a.targ=get_near_targ(a)
	if a.mstate==st_wander then
		--wander state
		if a.targ!=nil then
			if a.meter>0 then
				--wander->fight
				a.fight(a)
			else
				--wander->flee
				a.flee(a)
			end
		else
			update_rand_targ(a)
		end
	else
		--fight/flee state
		if a.targ==nil then
			--fight/flee->wander
			a.wander(a)
		elseif a.mstate==a.flee then
			--flee state
			if a.meter>0 then
				--flee->fight
				a.fight(a)
			end
		else
			--fight state
			if a.meter<=0 then
				--fight->flee
				a.flee(a)
			else
				--stay in fight
				a.fight(a)
			end
		end
	end
end

--update target
function update_targ(a)
	if a.targ!=nil then
		a.tx=a.targ.x
		a.ty=a.targ.y
	end
end

--update random target
function update_rand_targ(a)
	a.tx=a.x+irnd(0,a.tradius)-a.tradius*0.5
	a.ty=a.y+irnd(0,a.tradius)-a.tradius*0.5
end

--follow target
function follow_targ(a)
	a.dx=a.tx-a.x
	a.dy=a.ty-a.y
	
	--add follow spread
	a.dx+=rnd(1)*32-16
	a.dy+=rnd(1)*32-16
	normalize_dir(a)
end

--flee target
function flee_targ(a)
	a.dx=a.x-a.tx
	a.dy=a.y-a.ty
	normalize_dir(a)
end

--npc input
function npc_input(a)
	--update state
	if time_to_think(a) then
		npc_think(a)
	end
	
	--state logic
	if a.mstate==st_fight then
		update_targ(a)
		follow_targ(a)
	elseif a.mstate==st_flee then
		update_targ(a)
		flee_targ(a)
	else
		follow_targ(a)
	end
end

--descend
function descend(a)
	local is_player=a==player
	if (is_player) sfx(4)
	local c=1
	
	--to tier 2
	if a.tier-1==2 then
		if rnd(1)>0.5 then
			make_zombie(a.x,a.y,is_player)
		else
			make_skeleton(a.x,a.y,is_player)
		end
		c=8
		
		--undead music
		if is_player then
			music(2)
		end
	--to tier 1
	elseif a.tier-1==1 then
		if rnd(1)>0.5 then
			make_ghost(a.x,a.y,is_player)
		else
			make_wraith(a.x,a.y,is_player)
		end
		c=5
		
		--ghost music
		if is_player then
			music(1)
		end
	--to tier 0
	elseif a.tier-1==0 then
		if is_player then
			gstate=gst_dead
			mmstart=false
			--sfx(4)
		end
	end
	
	--blood
	for i=1,8 do
		add_p(a.x+rnd(1)*12-6,
			a.y+rnd(1)*12-6,c)
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
	a.pbounce=false
	a.pfragile=false
	a.pdraw=draw_ghost_proj
	a.psprs={}
	a.pspridx=1
	
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
		--update speed(add to projectile velocity)
		a.spd=get_vec_len(a.vx,a.vy)
		
		--standing shot
		update_standing_shot(a)
		
		--blast
		spawn_proj(a,a.x,a.y,a.dx,a.dy,a.pburst+a.spd)
		a.meter-=a.pcost
		a.vx+=-a.dx*a.precoil
		a.vy+=-a.dy*a.precoil
		
		--cooldown
		a.cooldwn=a.maxcooldwn
		a.xactionp=false
		
		--if player
		if a.inview then
			sfx(a.sfxxaction)
		end
	end
end

--update blaster 2
function update_blaster2(a)
	--check blast input + meter cost
	if a.oactionp and a.meter>0 then
		--update speed(add to projectile velocity)
		a.spd=get_vec_len(a.vx,a.vy)
		
		--standing shot
		update_standing_shot(a)
		
		--blast
		spawn_proj(a,a.x,a.y,a.dx,a.dy,a.pburst+a.spd)
		local ds={}
		if a.dx>0 then
			if a.dy>0 then
				ds={1,0,0,1} --southeast
			elseif a.dy<0 then
				ds={0,-1,1,0} --northeast
			else
				ds={rt2o2,-rt2o2,rt2o2,rt2o2} --east
			end
		elseif a.dx<0 then
			if a.dy>0 then
				ds={-1,0,0,1} --southwest
			elseif a.dy<0 then
				ds={0,-1,-1,0} --northwest
			else
				ds={-rt2o2,-rt2o2,-rt2o2,rt2o2} --west
			end
		else
			if a.dy>0 then
				ds={-rt2o2,rt2o2,rt2o2,rt2o2} --south
			else
				ds={-rt2o2,-rt2o2,rt2o2,-rt2o2} --north
			end
		end
		spawn_proj(a,a.x,a.y,ds[1],ds[2],a.pburst+a.spd)
		spawn_proj(a,a.x,a.y,ds[3],ds[4],a.pburst+a.spd)
		a.meter-=a.pcost*3
		a.vx+=-a.dx*a.precoil
		a.vy+=-a.dy*a.precoil
		
		--cooldown
		a.cooldwn=a.maxcooldwn
		a.oactionp=false
		
		--if player
		if a.inview then
			sfx(a.sfxoaction)
		end
	end
end

--init melee
function init_melee(a)
	a.melee={}
	a.melee.targs=a.targs
	a.melee.x=0
	a.melee.y=0
	a.melee.bboff=8 --hitbox offset
	a.melee.bbhw=3 --hitbox half width
	a.melee.bbhh=3 --hitbox half height
end

--update melee
function update_melee(a)
	--update melee position
	a.melee.x=a.x+a.itmxoff+hts
	a.melee.y=a.y+a.itmyoff+hts
	
	--check active hitbox
	local oa=touching(a.melee,a.targs)
	if oa!=nil then
		actor_kill(a,oa)
	end
end

--update item
function update_item(a)
	--update position
	update_item_pos(a)
	
	--pistol
	if a.itmidx==1 then
		--check blast input + meter cost
		if a.xactionp and a.meter>0 then
			--update speed(add to projectile velocity)
			a.spd=get_vec_len(a.vx,a.vy)
			
			--blast
			local xoff=a.itmxoff+hts
			local yoff=a.itmyoff+hts
			local dx=xoff/a.itmoff
			local dy=yoff/a.itmoff
			spawn_proj(a,a.x+xoff,
				a.y+yoff,dx,dy,
				a.pburst+a.spd)
			a.meter-=a.pcost
			a.vx+=-dx*a.precoil
			a.vy+=-dy*a.precoil
			
			--cooldown
			a.cooldwn=a.maxcooldwn
			a.xactionp=false
			
			--if player
			if a.inview then
				sfx(a.sfxxaction)
			end
		end
	else
		update_melee(a)
	end
end

--update standing shot
function update_standing_shot(a)
	if a.dx==0 and a.dy==0 then
		--facing horizontal
		if a.sprs==a.rsprs then
			if a.flipx then
				a.dx=-1 --left
			else
				a.dx=1 --right
			end
		--facing vertical
		elseif a.sprs==a.dsprs then
			if a.flipy then
				a.dy=-1 --up
			else
				a.dy=1 --down
			end
		--facing diagonal
		else
			if a.flipx then
				a.dx=-rt2o2
			else
				a.dx=rt2o2
			end
			if a.flipy then
				a.dy=-rt2o2
			else
				a.dy=rt2o2
			end
		end
	end
end

--update item position
function update_item_pos(a)
	if ((a==player and a.dx!=0 or 
		a.dy!=0) or (a!=player)) then
		local dx,dy=a.dx,a.dy
		if a!=player then
			dx=a.xfacing
			dy=a.yfacing
		end
		a.itmxoff=dx*a.itmoff-hts
		a.itmyoff=dy*a.itmoff-hts
		if dx!=0 and dy!=0 then
			a.itmspridx=3
		elseif dy!=0 then
			a.itmspridx=2
		else
			a.itmspridx=1
		end
		if dx>0 then
			a.itmflipx=false
		elseif dx<0 then
			a.itmflipx=true
		end
		if dy>0 then
			a.itmflipy=false
		elseif dy<0 then
			a.itmflipy=true
		end
	end
end

--time to think
function time_to_think(a)
	a.mcnt+=1
	return (a.mcnt%a.mfreq)==0
end

--draw debug
function draw_debug(a)
	if debug_mode then
		--bounding box
		draw_hitbox(a)
		
		--facing direction
		line(a.x,a.y,a.x+a.xfacing*8,a.y+a.yfacing*8,7)
		if a!=player then
			local c=7
			if a.mstate==st_fight then 
				c=10
			elseif a.mstate==st_flee then
				c=14
			else
				c=7
			end
			
			--target square
			rect(a.x-a.tradius,a.y-a.tradius,
				a.x+a.tradius,a.y+a.tradius,7)
			
			--target vector
			line(a.x,a.y,a.tx,a.ty,c)
			
			--state circle
			circfill(a.x,a.y,1,c)
		else
			a.tradius=48
			local targ=get_near_targ(a)
			cursor(a.x-22,a.y-12)
			
			--target square
			--rect(a.x-a.tradius,a.y-a.tradius,
			--	a.x+a.tradius,a.y+a.tradius,7)
			
			--target message
			if targ==nil then
				print("nobody near")
			else
				print("target near")
				--target vector
				line(a.x,a.y,targ.x,targ.y,9)
			end
		end
	end
end

--get nearest target
function get_nearest_targ(a)
	local targ=nil
	local ndist=mw
	for pool in all(a.targs) do
		for oa in all(pool) do
			if a!=oa then
				local mdist=get_mdist(a.x,
					a.y,oa.x,oa.y)
				if mdist<ndist then
					targ=oa
					ndist=mdist
				end
			end
		end
	end
	return targ
end

--draw target line
function draw_targ_line()
	if player!=nil and
		player.xp<player.maxxp then
		local targ=get_nearest_targ(player)
		if targ!=nil and
			not targ.inview then
			--get direction
			local x,y=player.x,player.y
			local dx=targ.x-x
			local dy=targ.y-y
			local mdist=flr(get_mdist(x,
				y,targ.x,targ.y))
			
			--get angle
			local ang=atan2(dx,dy)
			
			--normalize
			dx=cos(ang)
			dy=sin(ang)
			
			--draw indicator
			x+=dx*10
			y+=dy*10
			for i=1,flr(mdist/hss) do
				local c=ctarg[i%#ctarg+1]
				circfill(x,y,1,c)
				x+=dx*4
				y+=dy*4
			end
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
		wraith.oprompt="🅾️/z dash"
		wraith.xprompt="❎/x shoot"
		player=wraith
	else
		init_actor_npc(wraith)
		wraith.wander=wraith_wander
		wraith.fight=wraith_fight
		wraith.flee=wraith_flee
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
	wraith.pethereal=true
	wraith.sfxxaction=10
end

--enter wraith wander state
function wraith_wander(wraith)
	enter_wander_state(wraith)
end

--enter wraith fight state
function wraith_fight(wraith)
	enter_fight_state(wraith)
	
	--choose action
	if rnd(1)<0.5 then
		wraith.oaction=true
	else
		wraith.xactionp=true
	end
end

--enter wraith flee state
function wraith_flee(wraith)
	enter_flee_state(wraith)
end
-->8
--spawner
spnr={}
spnr.x=0 --spawner x
spnr.y=0 --spawner y
spnr.cnt=0 --spawn counter
spnr.freq=30 --spawn frequency
spnr.maxghosts=6 --max ghost spawns
spnr.maxwraiths=4 --max wraith spawns
spnr.maxzombies=8 --max zombie spawns
spnr.maxskeletons=6 --max skeleton spawns
spnr.maxhumans=8 --max human spawns

--update spawn point
function update_spawnpoint(ethereal)
	--choose tile
	local tx,ty=irnd(0,mw/ts-1),irnd(0,mh/ts-1)
	local iter=0
	
	--check tiles
	while (iter<100) do
		if (tx>mw/ts-1) then
			--out of bounds
			tx=0
		elseif (point_in_view(tx*ts+hts,
			ty*ts+hts)) then
			--in view
			tx+=1
		elseif (not ethereal and 
			in_table(walls,
			mget(tx,ty))) then
			--in wall
			tx+=1
		else
			--spawn good!
			spnr.x=tx*ts+hts
			spnr.y=ty*ts+hts
			break
		end
		iter+=1
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

--update fog
function update_fog()
	fogtimer+=1
	if fogtimer%fogfreq==0 then
		local num=irnd(1,3)
		for i=1,num do
			spawn_fog()
		end
	end
end

--spawn fog
function spawn_fog()
	local x,y=cam.x+rnd(ss),cam.y+rnd(ss)
	add_p2(x,y,cfog[irnd(1,#cfog)])
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
	
	--movement
	skeleton.bounce=true
	
	--trail
	init_trail(skeleton,7)
	skeleton.trailon=false
	
	--sprite
	skeleton.rsprs={36,52}
	skeleton.dsprs={37,53}
	skeleton.dgsprs={38,54}
	skeleton.sprs=skeleton.rsprs
	
	--run
	init_run(skeleton,3)
	
	--blaster
	init_skeleton_blaster(skeleton)
	
	--player or npc
	if is_player then
		skeleton.update_input=update_player_input
		skeleton.goal="웃fight humans."
		skeleton.oprompt="🅾️/z throw x3"
		skeleton.xprompt="❎/x throw"
		player=skeleton
	else
		init_actor_npc(skeleton)
		skeleton.wander=skeleton_wander
		skeleton.fight=skeleton_fight
		skeleton.flee=skeleton_flee
	end
	
	--add to list
	skeleton.pool=skeletons
	add(skeleton.pool,skeleton)
end

--updates zombie logic
function update_skeleton(skeleton)
	--get input
	skeleton.update_input(skeleton)
	update_blaster(skeleton)
	update_blaster2(skeleton)
	update_trail(skeleton)
	update_meter(skeleton)
	
	--move and collide
	move_and_collide(skeleton)
	
	--check ascendance
	check_ascend(skeleton)
end

--renders the skeleton
function draw_skeleton(skeleton)
	if player.tier!=1 then
		draw_actor(skeleton)
	end
end

--init skeleton blaster
function init_skeleton_blaster(skeleton)
	init_blaster(skeleton)
	skeleton.pc1=7
	skeleton.pc2=13
	skeleton.paccel=0.05
	skeleton.pburst=2
	skeleton.precoil=0
	skeleton.psize=2
	skeleton.pspd=0
	skeleton.plife=60
	skeleton.pcost=30
	skeleton.pbounce=true
	skeleton.pdraw=draw_skeleton_proj
	skeleton.psprs={30,46,31,46}
	skeleton.sfxoaction=13
	skeleton.sfxxaction=13
end

--enter skeleton wander state
function skeleton_wander(skeleton)
	enter_wander_state(skeleton)
end

--enter skeleton fight state
function skeleton_fight(skeleton)
	enter_fight_state(skeleton)
	
	--choose action
	if rnd(1)<0.5 then
		skeleton.oaction=true
	else
		skeleton.xactionp=true
	end
end

--enter skeleton flee state
function skeleton_flee(skeleton)
	enter_flee_state(skeleton)
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
	human.ascenders=water
	human.targs={zombies,skeletons}
	
	--trail
	init_trail(human,4)
	human.trailon=false
	
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
	human.burststr=2
	human.sfxoaction=15
	
	--item
	init_human_item(human)
	
	--xp
	human.maxxp=10
	
	--player or npc
	if is_player then
		human.update_input=update_player_input
		human.goal="✽kill monsters"
		human.oprompt="🅾️/z run"
		human.xprompt="❎/x item"
		player=human
	else
		init_actor_npc(human)
		human.wander=human_wander
		human.fight=human_fight
		human.flee=human_flee
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
	update_item(human)
	update_trail(human)
	
	--move and collide
	move_and_collide(human)
	
	--check ascendance
	check_ascend(human)
end

--renders the human
function draw_human(human)
	if player.tier!=1 then
		draw_actor(human)
		draw_human_item(human)
	end
end

--init human item
function init_human_item(human)
	--choose item
	human.itmidx=irnd(0,1)
	
	--pistol
	if (human.itmidx==1) then
		init_blaster(human)
		human.pc1=10
		human.pc2=5
		human.pburst=6
		human.precoil=1
		human.psize=1
		human.pspd=6
		human.plife=15
		human.pcost=15
		human.pfragile=true
		human.sfxxaction=16
		
		--sprites
		human.itmsprs={16,32,48}
	--knife
	else
		init_melee(human)
		
		--sprites
		human.itmsprs={13,14,15}
	end
	
	--item
	human.itmspridx=1
	human.itmoff=8
	human.itmxoff=8-hts
	human.itmyoff=-hts
	human.itmflipx=false
	human.itmflipy=false
end

--draw human item
function draw_human_item(a)
	spr(a.itmsprs[a.itmspridx],
		a.x+a.itmxoff,a.y+a.itmyoff,
		1,1,a.itmflipx,a.itmflipy)
	
	--melee hitbox
	--if a.itmidx==2 then
		--draw_hitbox(a.melee)
	--end
end

--enter human wander state
function human_wander(human)
	enter_wander_state(human)
end

--enter human fight state
function human_fight(human)
	enter_fight_state(human)
	
	--choose action
	if human.itmidx==1 then
		human.xactionp=true
	else
		human.oaction=true
	end
end

--enter human flee state
function human_flee(human)
	enter_flee_state(human)
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
	proj.inview=false --in camera view
	
	--movement
	proj.x=x --x position
	proj.y=y --y position
	proj.vx=dx*burst --x velocity
	proj.vy=dy*burst --y velocity
	proj.spd=get_vec_len(proj.vx,
		proj.vy) --speed (for queries)
	proj.maxspd=a.pspd --current max move speed
	proj.normspd=a.pspd --normal max move speed
	proj.accel=a.paccel --acceleration
	proj.ethereal=a.pethereal --ethereal=no wall collisions
	proj.follow=a.pfollow --follow owner
	proj.bounce=a.pbounce --bounce on walls
	proj.fragile=a.pfragile --destroy on collision
	
	--draw
	proj.c=a.pc1
	proj.draw=a.pdraw
	proj.sprs=a.psprs
	proj.spridx=1
	
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
	if p.inview then
		add_p(p.x+irnd(-p.bbhw,p.bbhw),
			p.y+irnd(-p.bbhh,p.bbhh),p.ctrail)
	end
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
	local collision=move_and_collide(p)
	
	--check collisions
	local oa=touching(p,p.targs)
	if oa!=nil and oa!=p.owner then
		actor_kill(p.owner,oa)
		collision=true
	end
	
	--life timer
	p.life-=1
	if (p.life<=0 or
		(p.fragile and collision)) then
		del(projs,p)
	end
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

--draw zombie projectile
function draw_zombie_proj(p)
	local rad=p.bbhw*(p.life/30)
	circfill(p.x,p.y+2,rad+1,p.c)
	circfill(p.x,p.y+2,rad,p.ctrail)
	circfill(p.x+2,p.y-2,rad+1,p.c)
	circfill(p.x+2,p.y-2,rad,p.ctrail)
	circfill(p.x-2,p.y-2,rad+1,p.c)
	circfill(p.x-2,p.y-2,rad,p.ctrail)
end

--draw skeleton projectile
function draw_skeleton_proj(p)
	p.spridx+=p.spd
	local spridx=flr(p.spridx-1)%3+1
	spr(p.sprs[spridx],p.x-hts,p.y-hts)
end
-->8
--main menu

--draw main menu
function draw_mainmenu()
	local xx,yy=0,0
	local str=""
	
	--tiles
	map(mmx,mmy,0,0,mw,mh)
	
	--gridlines
	if debug_mode then
		line(hss,0,hss,ss)
		line(hss/2,0,hss/2,ss)
		line(hss*3/2,0,hss*3/2,ss)
		line(0,hss,ss,hss)
		line(0,hss/2,ss,hss/2)
		line(0,hss*3/2,ss,hss*3/2)
	end
	
	--timer
	mmtimer+=1
	
	--draw high particles
	foreach(ps2,draw_p2)
	
	--monster cycle
	local omegat=omega*mmtimer
	phase=0.22
	amp=32
	circ(hss,hss,amp+1,1)
	circ(hss,hss,amp-1,1)
	circ(hss,hss,amp,7)
	xx=hss-amp*cos(omegat+phase)
	yy=hss+amp*sin(omegat+phase)
	spr(2,xx-hts,yy-hts) --ghost
	phase+=0.06
	xx=hss-amp*cos(omegat+phase)
	yy=hss+amp*sin(omegat+phase)
	spr(5,xx-hts,yy-hts) --wraith
	phase=0.55
	xx=hss-amp*cos(omegat+phase)
	yy=hss+amp*sin(omegat+phase)
	spr(34,xx-hts,yy-hts) --zombie
	phase+=0.06
	xx=hss-amp*cos(omegat+phase)
	yy=hss+amp*sin(omegat+phase)
	spr(37,xx-hts,yy-hts) --skelly
	phase=0.88
	xx=hss-amp*cos(omegat+phase)
	yy=hss+amp*sin(omegat+phase)
	spr(8,xx-hts,yy-hts) --human1
	phase+=0.06
	xx=hss-amp*cos(omegat+phase)
	yy=hss+amp*sin(omegat+phase)
	spr(40,xx-hts,yy-hts) --human2
	
	phase=0.415
	xx=hss-amp*cos(omegat+phase)
	yy=hss+amp*sin(omegat+phase)
	circfill(xx,yy,2,1)
	circfill(xx,yy,1,10)
	phase=0.745
	xx=hss-amp*cos(omegat+phase)
	yy=hss+amp*sin(omegat+phase)
	circfill(xx,yy,2,1)
	circfill(xx,yy,1,10)
	phase=0.075
	xx=hss-amp*cos(omegat+phase)
	yy=hss+amp*sin(omegat+phase)
	circfill(xx,yy,2,1)
	circfill(xx,yy,1,10)
	
	--title
	xx=16
	yy=8
	local val=sin(omegat*6)
	local cols={0,1,2,8}
	cursor(xx+22,yy+1)
	print("monster cycle",cols[flr(val*2.4+2.5)])
	cursor(xx+24,yy+1)
	print("monster cycle",cols[flr(val*1.4+1.5)])
	cursor(xx+23,yy+2)
	print("monster cycle",cols[flr(val*2.4+2.5)])
	cursor(xx+23,yy)
	print("monster cycle",cols[flr(val*1.4+1.5)])
	cursor(xx+23,yy+1)
	print("monster cycle",7)
	
	--game mode prompts
	xx=43
	yy=hss-1+val*4
	str="press 🅾️/x"
	oprint(str,xx,yy,10,1)
	
	--credits
	xx=17
	yy=113
	str="created by nandbolt(v"..vnum..")"
	oprint(str,xx,yy,6,1)
	
	--fade
	if mmstart then
		circfill(hss,hss,(hss+28)*(1-(fade/30)),1)
	end
end

--print outlined text
function oprint(str,x,y,c1,c2)
	cursor(x-1,y)
	print(str,c2)
	cursor(x+1,y)
	print(str)
	cursor(x,y-1)
	print(str)
	cursor(x,y+1)
	print(str)
	cursor(x,y)
	print(str,c1)
end

--print shadowed text
function shdwprint(str,x,y,c)
	cursor(x-1,y-1)
	print(str,1)
	cursor(x,y)
	print(str,c)
end
-->8
--save/load

--save highscore
function save_highscore(score)
	dset(0,score)
	ghigh=score
end

--load highscore
function load_highscore()
	cartdata(0)
	ghigh=dget(0)
end
__gfx__
00000000000111000001100000110000001111000010010000151000111fff5100111151015f11111dddddd11dd11dd11d1111d1001000000001510015151000
00000000001ccc10001cc10001cc11000155771001511510015551005f555510015555f1015555ffd555555dd556655dd165561d015111100015451054545100
0070070001cc11c101cccc101ccccc10155557d1155555511555551015fff15115ffff5115ffff5fd111111dd516615d16111161154555510154445115451000
000770001cccccd11cccccc11cccc1c101555510155555515555577115ffff5155ffff5f15fff155166556611665566111666611544666750015651054565100
000770001cccccd11c1cc1c101cccc11015555101755557115555d7115ffff5155ffff5f15ffff51166556611665566111666611154555510015651015156510
0070070001cc11c11c1cc1c101c1ccd1155557d1177557710157dd1015fff151151ff15f15f1ff51d111111dd516615d16111161015111100015651001015751
00000000001ccc1001cddc10001c1d100155771001d11d1000177100015555f51f55551515555510d555555dd556655dd165561d001000000015751000001510
0000000000011100001111000001110000111100001001000001100000155111151111011551f5101dddddd11dd11dd11d1111d1000000000001510000000100
00000000000000000000000000000000001111000010010000151000001551111511110000111111d444444444444444addddddddddddddd0001010001000100
01111110000111000001100000110000015588100151151001555100015555f51f55551011555555155555555555555fc555555555555557001d1d101d111d10
155555510011cc10001111000111110015555891155555511555551015fff15115ffff5155ffff551677615111115115c6776c5ccccc5cc501d7d7d1d7ddd7d1
54444815011111200111111001111c1001555510155555515555588115ffff51f5ffff55f5fff1511767611111111115c7676cccccccccc5001d7d101d777d10
545d55510111112001c11c10001111c001555510185555811555598115ffff51f5ffff5515ffff5f1767611111111115c7676cccccccccc5001d7d10d7ddd7d1
54d111100011cc1001c11c10001c112015555891188558810158991015fff151f51ff15115f1ff551677611115111115c6776cccc5ccccc5001d7d101d111d10
1510000000011100001221000001c2000155881001911910001881005f555510515555f11f5555111555555555555551c55555555555555101d7d7d101000100
01000000000000000000000000000000001111000010010000011000111fff51101111511ff51100d111111111111114a11111111111111d001d1d1000000000
00111000111bbb51001111510015b11101dd77d101dddd1001dddd11111444510011115101541111d222222d44444f44aeeeeeeaddddd7dd001100001dd11dd1
015551005b555510015555b1015555bb1d77dd101d7777d11d717dd754555510015555410155554415677651ffffffff156776517777777701d71000d516615d
1544451015bbb85115bbbb5115bbbb5bd7117dd1d717717dd77717d71544415115444451154444544576675446a66664d576675dd1a1111d1d7d1000d516615d
01d5451015bbbb51b5bbbb5b15bbb855d77777d1d717717dd1777ddd154444515544445415444155f577775f64448846757777571ddd88d117d7d110d515515d
001d451015bbbb51b5bbbb5b15bbbb51d77777d1dd7777d7d71777d11544445155444454154444514566665464884446d566665d1d88ddd1011d7d71d515515d
0015851015bbb851b58bb85b15b8bb51d7117dd11dd77dd7dd7d7dd11544415115144154154144514522225416666a61d5eeee5d11111a110001d7d1d516615d
00151510015555b55b5555151b5555101d77dd7d17dddd1d1ddddd10015555451455551515555510f522225ff111111f75eeee577111111700017d10d516615d
00015100001bbb51151111011bb5b51001ddd1111d1111010117d10000155111151111011551451045222254444444f4d5eeee5ddddddd7d000011001dd11dd1
00100000000bbb50050000000000000001ddd11101dddd1001dddd100015511115111100001111114522255444466f44d5eee55dddd117dd000000001d1111d1
01510000005555b50b555500005555bb1d77dd7d1d7777d11d717dd1015555451455551011555555f522225fff6446ff75eeee57771dd17700000000d161161d
1545100005bbb85105bbbb5005bbbb5bd7117dd1d717717dd77717d1154441511544445155444455455222544fa48644d55eee5dd7ad81dd0000000016166161
5454510005bbbb50b5bbbb5b55bbb855d77777d1d717717dd1777dd7154444514544445545444151f522225fff6486ff75eeee57771d81770000000015166151
1d5d451005bbbb50b5bbbb5bb5bbbb5bd77777d17d7777ddd71777dd1544445145444455154444544522255444684644d5eee55ddd18d1dd0000000015166151
0111585105bbb850b58bb85b15b8bb55d7117dd17dd77dd1dd7d7dd11544415145144151154144554522225444684a44d5eeee5ddd18dadd0000000016166161
000015d15b555510515555b50b5555111d77dd10d1dddd711ddddd10545555105155554114555511f155551fff6446ff71555517771dd17700000000d161161d
00000110111bbb50101111510bb5110001dd77d1101111d1177d1100111444511011115114451100441111f4441661f4dd11117ddd11117d000000001d1111d1
22222222222222222222222244444444444444444444444433333333333333333333333322222222222222222222222222222222cccccccccccccccccccccccc
2202220222500222222020524494449444d99444444949d43343334333d443333334346322522222222222222222222222222222cccc1ccccccccccccccccccc
202500222222205225020222494d9944444449d44d949444343644333f3f34d33643433325222222220022222222022222222222ccc1c11cccccc11ccccccccc
202222242424222222222022494444434343444444444944343333f3f1f1f33f3333343322222222252202222220222222222222c7cccccccccccccccccccccc
2520224222424224222205224d4944344434344344449d4436343f1f3f1f1ff1f333463322220222222222222222222222222222cccccccccccccccccccccccc
2002222424222442422222224994444343444334344444443443f3f1f1fff11f1f33333322202022222200522222522222222222ccc1cc7ccccccccccccccccc
222242444444444444222222444434333333333333444444333f1f1c1c111cc1c1ff333322222222222022222222222222222222c11c1cccc7cccccccccccccc
222244444444444444442222444433333333333333334444333f11cccccccccccc11f33322222222222222222222222222222222cccccccccccccccccccccccc
2522244444444444444222224d44433333333333333444443633f1cccccccccccc1f333349444f44444444444444444444444444ddddd6dd9999999988888888
220242444444444444422502449434333333343333344d94334f1f1ccccccccccc1f3643ffffffff444449444444444444444444d777777d9aaaaaa98eeeeee8
20222444449444d444242222494443333333434333434444343ff1cccc7cccccc1f1f3334f444494444494444444444444444444d7dddddd9af999998e288888
22242244494944444422202244434433363333333344494433f1ff1cccccc7ccc1ff3433ffffffff4d444444444444d444444444d777777d9aaaaaa98eeeeee8
222242444444444444422202444434333333333333344494333f1f1ccccccccccc1f3343444f44444444444444444444444444446dd7dddd99faf999882e2888
2502244444444444442422024d94433333333633334344943643f1cccc1cccccc1f1f34394f44444444949d44944444444444444dd7ddddd9faf999982e28888
2020224444d44444444222524949443333333333333444d434343f1cc1c1cccccc1f3363ffffffff449d9d444494444444444444d777777d9aaaaaa98eeeeee8
2222244444444444444202224444433333333333333434443333f1cccccccccccc1f3333444944f4444444444444444444444444ddddd6dd9999999988888888
222224444444444444422222444443333333333333344444333ff1cccccccccccc1f3333ddd6d7dd333333333333333333333333444944440000000000000000
22242444444444444424222244434333333333333343444433f1f11cc1c1cc1cc1f1f333777777773363433333333333333333334ffffff40000000000000000
2222442442424424444220524444334334343343333449d4333f11f11f1f11f11c1f3463d7dddddd3444333336333333333333334f9444440000000000000000
22242222242422222422220244434444434344444344449433f1ff3ff1f1ff3ff1f33343777777773333333333333343333333334ffffff40000000000000000
222222224222422222422222444444443444344444344444333f33331f3f1f333f1f3333ddd7dddd333333333333343333333333444f94440000000000000000
2220520222022202222202024449d494449444944444949433346343f343f34333f34343dd7dd6dd33334333333333333333333349f944940000000000000000
2502025020500252222050524d9494d949d994d44449d9d4364343643464436333346463777777773336344333333333333333339ffffff40000000000000000
222222222222222222222222444444444444444444444444333333333333333333333333d6dddd7d333333333333333333333333444449440000000000000000
000000000000000022255522225555522552552233555533444555444455554445555554dd11111dd555555d2226622222020252225555225555555555555555
00000000000000002553335225333355553533523544445345556544455665545566665571212217569769652261162222202522254944525656656556766665
00000000000000005333b33553b3b3355333b335594ff495556665544577665556667665d121221d5a6556a52562262226622662544ff4455656656555555555
000000000000000053b33b35533b335153bb333554f44f455566765545655665567765657121221757566565021661026116611654f44f955756756556656765
000000000000000053b33b351533b3355333bb3554f44f45156775655566666556655665d121221d56566575222662226226622659f44f455657656556656665
0000000000000000533b3335533b3b35533b3335544ff445156655655566665555666665d121221d5a6556a52061165216611661544ff9455656657555555555
00000000000000001533355155333351253353551544495115566655155555511556665571212217569679652262262522250222154944515656656556766675
000000000000000021555112155555122255255231555513415555514111551441555554d111111dd555555d2216612225022222215555125555555555555555
161616161616161616160615261616161616161616161616161606153545d5d5d5d5e5e5f47575e5e5d5d5d5d54555b52594b4a494a796969696f59697969796
97969796e5e5a79696a7a7d2a7a4b4940535657585552505b52594a494b4a49494b7a016c016c0061516160615161616161616160615261616161616e79595e7
94949494b4949494c7c705b525c7c7c7c7c7c7c7c7949494949405b53545a645a7d5d5e5e5d4e5e5d5d5a7c6b6a655a52594b4b494a7a7969696f59697969796
9796979696e5a79696a79696a794b4b40535657585552505152594a4b4b4a49494b7c7c7c7c7c7141525b7051525b7c7c7c7c7c705a525c7c7c7c7c7e7f7f7e7
94949494b49494b7d5d5d5d5d5d5d5d5d5d5d5d5d5b79494949405a53646463645d5d5d5e5e5e5d5d5d54556464656152594c4b49494a7a79696f59697969796
979697969696d39696a79696a79494b4053565d485552505a52594b4b494a49494b794b4949414a51525b7f2b5f2b7a014c014a0041524c014c014a0b705a515
94949494b494b7d5b075e4d575d4c075f4d47575b0d5b7949494051515a51535b6d5d5d5d5d5d5d5d5d5b65515c5a5b5259494a4b49494a7a796f59696969696
969696969696a79696a7c1d1a79494b4053565e485552505c52594b49494949494b794a414141515c525b7051525b70515a515a515b5c5a515a51525b705b5a5
94c4a4b49494b7d5f4d4d5d5d5e475e4d5d5d575d4d5b794949406161606a535c6a645a7d5d5d5a7c645a655b5261616269494a4b4949494a7a7d2a7a7a7a7a7
a7a7a7a7a7a7a7a7a7a7a7a7a794a4b4053565758555250515241414141414141414141415a51506a525b7b0a5f2b7b016c016b0061526a016b016a0b705c515
9494a4b49494b7f275d5d5e5d5d5f4d5d5e5d5d5e4d51414141414141404b53646463645d5d5d545564646561525949494949494a4c494944705152537949494
a4a4a49494b4b4b4949494949494a494053565f485552505a515b5a515c5a515a51515a51526b7051525b705c525b7c7c7c7c7c705a525c7c7c7c7c7b70515b5
9494a4b49494b7d5e4d5e5b0e5d5d4d5e5b0e5d5d5d5a5a5b5c515a5b5a515c5b51535b6d5d5d5b655a5b515152594c4b4b4b49494b4b4949405a5259494b4b4
b4b4b4b4b494949494a4949494a49494053565d4855525041526161616161616161616161626b7f2a5b0b7f3a5f2b7b014a014c0041524a014a014b0b705a515
9494a4b49494b7f275d5d5e5d5d5e4d5d5e5d5d575d51616161616161616161606a53545a6c645a65515261616269494a4a4949494949494940515259494b494
a4a4a4a494a4a4a4a4949494a40414140435f7f7f75525a5152594b4b494c49494b79494b494b7051525b7051525b70515b5a5c515a515b5a5151525b70515a5
9494b4a49494b7d5d475d5d5d5d5d5d5d5d5d5f4d4d5b794949494949494949405b536464646464656c524141414141414141414141414141404c52414141414
141414141414141414141414140415a51515d6d6d615a51526269494b4a4a4a494b794a49494b7f316f2b7f316b0b7a016a016b0161616c016a016a0b70515b5
94b4b4a49494b7d5b0e475f4d5d5e5d5d575e475b0d5b794c404142494c4a4940515a515b5c5a51515a515b5a515c5b515a515b515b515b5a5b515b51515a5b5
b515a5b5151515c5a515a51515a515260635f7f7f755261626949494b4b4949494c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c705a5c5
94b49494a49494b7d5d5b075d5e5c0e5d5d4b0d5d5b79494c40587259494a49405a5261616161616161616161616161606152616161616161616161616161616
161606c5261616161616161616161626053565e48555259494a4a4c494b4b4949494b4b4a4a4a4a4949494b4b4b49494a4a4a4949494a4a49494a4a494051515
94949494a4949494c7b7d575d5d5e5d5d5f4d5b7c794041414241626a4a4949405c5259494949494949494949494949405c52594949494b4949494b49494b494
c49405b525949494c494b4b494a49494053565d4855524142494a4a4a494b4b494949494c49494a4a4a49494949494c49494949494949494949494949405b5a5
94041424a4a4c49494b7d5d4e4d5d5d5e475d5b794040487772424a4a404142405a52594c494a4a4a4a4949494c494b7051525c7c7c7c7c7c7c7c7c7c7c7c7c7
c7c705a525b794949494041424b4a094053565758554445424141414141414141414141414141414141414141414141414141414141414141414141414041515
9405672594b4b49494b7d5b0f4e475d475b0d5b79405776767772424c405772505152594a4a494949494a4a4949494b705b52414a014b014a014c014c014a014
b014041525b79494940404672594b494053565f48474845444444444444444444444444444444444444444444444444444444444444444444444444444444444
94061626b4b4c4949494b7d5d5c0d5c0d5d5b79494060677876767259406162605b525949494c49494949494a4a494b7b0b515b5c5b5a515b515a515b5c5a515
a5b515b5f3b79494940587772594b4b4053565d4e4d48484b6a645464645b645a645b645a6454545b64545a6b0454545a6454545b645b6b645b64545a6454545
949494b4b4949494949494c7c7c7c7c7c7c794041424060687772626a494949405b52594949494a494949494949494b7061606152616a016a016b016a016b016
0615261626b7949404047726269494b40535667666757584747474d6d6747474747474844545a6f2a645b645c645b6f245454556463645a6a6a645a64545b6a6
9494b4b40414249494949494949494949494940567259406161626041414249405c52594949494a4c4949494949494b7c7c705a5b0c7c7c7c7c7c7c7c7c7c7c7
f2a525c7c7b794040477872594c494a40535a645666675d4e4d4f4d6d6e475d4f4e475847474844545b6a045a645454545a6b655a235b645a045a645463645a6
9494b4940587259494c494a494949494a4a4940616041414249404048777259405152594c49494a4949404141414141424b705152414c014b014a014c014a014
041525b794949405677726269494a4040435b64545667676767676d6d6767676766675d475e484748445454545c6a64545454555a335c6a6a645455795363645
9494c49406162694a4a4a49494c494a4a49494c404046767250404876787259405a525949494a4a4940404344444445425b705b515a5b5c5a515b5a515b515a5
15b525b794a4940616162694b4b40404343445b6b64545b645a6454444464636456676766675d47584748445a6b0a645564646561535b6a64545569595953636
94c4b4949494a4a4a4949494949494a4041424040477677725a48767672626d7959595d79494a49494053434a645b65525b706c01606152616b016a01606b526
16b026b79494c4c4b4b4b49494a405343445c645b645a64545b64546461515354545a645667666f4d47584844545454555a1b115b5354545455795a1b1959535
949494b4a4a4a49494d7d7d7949494a40577250567878726040477872626d79595959595d794a4a4040535b645c6a65625b7c7c7c705b525c7c7c7c7c705b525
c7c7c7b7949494949494b4b49404043545b645a645a64545a64555343457b25745a645454545667666e475847484c64554444454a535b656469595a1b1955745
94a4a4b4b4949494d7a1b195d79494a406162605777767259467776725949595a295a2959594949405343445a64556262694949494051525a49494949405a524
1414141414141414141414141414343445c645454545c645b645553557a295955745c6a645a64545666675d47584844545454555153545551515959595344545
94a49494b4c49494d7959595d79494c494949406161616269477672626949595a395a395959494940535c645a6562694949494a49405a52594a49494940515a5
c515a5b5b5a5b515a5b5c5a515b53545b645a64557574545b645553557a39595955745454545a6c6a6667666e4758484c6455656b5364656c5345495574545a6
9494949494949494d7959595d79494949494949494949494061616269494959595959595959494940535a645562694949494a4a4c405c52594c4c49494061616
16161616161616161616161606a53545a645455795a2574545c655354557579595955745c6a645454545456666f475854545551515a515b515355444b6a645b6
1414a0141414141414d7b2d7141414141414a01414141414142494949494d79595959595d79494940536464656259494c4a4a49494051525949494a4a4a49494
9494949494949494a4a4949405b536464657579595a357574545551535b6455795959557454545a645c6a6456666d48484c655b534551534443445b64545c6a6
4444444444444444444444444444d6d6444444444444444454241414141424d7959595d79494c4940616161616269494a4a494c49405a52594c494949494a4c4
94a494949494c4c49494a4a40515a5c515b395959557a1b1575756b53646364557959595574545b64545454545657575854555c535551535464645a6a6b0a6b6
7474747474747474747474747474d6d6747474747474748454444444445424141414141424949494949494949494949494949494940515259494949494949494
94a4a4a4a49494949494949405344444445757a1b157959595b31515a5153646465795955746364545b6a645456666d48545551535559595959557b645b64545
7575e4757575e4757575f4757575d6d675f4757575757584747474748454444444444454241414a014141414b014141414141414140415141414141414249494
94949494949494949494949405354545b645455757a295955757444454c5b5a515b39595b315364646464646364565e4854556b535559595a2a29557a645a6b6
d475757575f4757575d47575e475d6d67575e475d4e475757575d4e4847474747474845444444444444444444444444444444444444444444444444454241414
1414a014141414141414c014053545a645a6454557a395574545b645544444444457a1b1575415b5c515a5153555d6d6d635551535455795a3a3959535b64545
75d475d47575d475d4e475f4d475d6d675e4f47575f475e475d4f4757575e4757575847474747474747474747474747474747474747474747474748454444444
44444444444444444444444444354545b645c6b645575745b6c6a645b6b645a64545575745444444444444443555d6d6d635554434a6455795959595354545a6
d4e475e4d47575e475757575d4757575d475d47575d475d475e47575e475d475f4d475e475d475f4757575e475e475e47575d47575e4757575e4758474747474
747474747474747474747474748445c6a64545a6c64545b6454545a6a645454545b6a64545454545a6b645a6454565d48545a645b6a0b645444444443445a645
75f475d475f475d475e475d47575e475757575e47575e4d47575d47575e475d475e47575e47575d475e4757575d47575e4f475e47575d475e475f47575e4d475
e475f475d475e4e4e4757575f48545b645454545a6454545a6a6b6454545a6b64545b64545a6454545a64545b6b665e48545a6454545a64545a6454545b6a645
__label__
ddd6d7ddddd6d7ddddd6d7ddddd6d7ddd555555d444444444444444444444444252224444d444333555555555555555555555555333444444442222222222444
7777777777777777777777777777777756976965444444444444444444444444220242444494343356766665567666655676666533344d944442250222242444
d7ddddddd7ddddddd7ddddddd7dddddd5a6556a54242442442424424424244242022244449444333555555555555555555555555334344444424222222224424
77777777777777777777777777777777575665652424222224242222242422222224224444434433566567655665676556656765334449444422202222242222
ddd7ddddddd7ddddddd7ddddddd7dddd565665754222422242224222422242222222424444443433566566655665666556656665333444944442220222222222
dd7dd6dddd7dd6dddd7dd6dddd7dd6dd5a6556a5220222022202220222022202250224444d944333555555555555555555555555334344944424220222205202
77777777777777777777777777777777569679652050025220500252205002522020224449494433567666755676667556766675333444d44442225225020250
d6dddd7dd6dddd7dd6dddd7dd6dddd7dd555555d2222222222222222222222222222244444444333555555555555555555555555333434444442022222222222
ddd6d7ddddd6d7ddddd6d7ddddd6d7ddd555555000250020022200200020002000222444004040330030f1c000cccccccc1f3333333444444442222225222444
7777777777777777777777777777777756976917770077077050770777077707770242407707070077070f17770ccccccc1f364333344d944442250222024244
d7ddddddd7ddddddd7ddddddd7dddddd5a65561777071707170700217117011707022417111707071117011701ccc11cc1f1f333334344444424222220222444
7777777777777777777777777777777757566517170707070707770170177017702422170417770703170f1770ccccccc1ff3433334449444422202222242244
ddd7ddddddd7ddddddd7ddddddd7dddd5656651707070707070007017017001717024217004007070017001700cccccccc1f3343333444944442220222224244
dd7dd6dddd7dd6dddd7dd6dddd7dd6dd5a655617070771170707712170177707070224417707770177077707770cccccc1f1f343334344944424220225022444
777777777777777777777777777777775696796111311551212112221221112121202244114111331131111111cccccccc1f3363333444d44442225220202244
d6dddd7dd6dddd7dd6dddd7dd6dddd7dd555555d21555112222222222222222222222444444443333333f1cccccccccccc1f3333333434444442022222222444
ddd6d7ddddd6d7ddddd6d7ddddd6d7ddd555555d222222222222222222222222252224444d4443333633f1cccccccccccc1f3333333444444442222225222444
77777777777777777777777777777777569769652252222222522222225222222202424444943433334f1f1ccccc1ccccc1f364333344d944442250222024244
d7ddddddd7ddddddd7ddddddd7dddddd5a6556a52522222225222222252222222022244449444333343ff1ccccc1c11cc1f1f333334344444424222220222444
7777777777777777777777777777777757566565222222222222222222222222222422444443443333f1ff1cc7ccccccc1ff3433334449444422202222242244
ddd7ddddddd7ddddddd7ddddddd7dddd565665752222022222220222222202222222424444443433333f1f1ccccccccccc1f3343333444944442220222224244
dd7dd6dddd7dd6dddd7dd6dddd7dd6dd5a6556a5222020222220202222202022250224444d9443333643f1ccccc1cc7cc1f1f343334344944424220225022444
7777777777777777777777777777777756967965222222222222222222222222202022444949443334343f1cc11c1ccccc1f3363333444d44442225220202244
d6dddd7dd6dddd7dd6dddd7dd6dddd7dd555555d22222222222222222222222222222444444443333333f1cccccccccccc1f3333333434444442022222222444
ddd6d7ddd555555dd555555dddddd7ddd555555d222222222222222222222222252224444d4443333633f1cccccccccccc1f3333333444444442222225222444
77777777569769655697696577777777569769652252222222522222225222222202424444943433334f1f1ccccccccccc1f364333344d944442250222024244
d7dddddd5a6556a55a6556a5d1a1111d5a6556a52522222225222222252222222022244449444333343ff1cccc7cccccc1f1f333334344444424222220222444
7777777757566565575665651ddd88d157566565222222222222222222222222222422444443443333f1ff1cccccc7ccc1ff3433334449444422202222242244
ddd7dddd56566575565665751d88ddd1565665752222022222220222211202222222124144443433333f1f1ccccccccccc1f3343333444944442220222224244
dd7dd6dd5a6556a55a6556a511111a115a6556a522202022222020221cc12022250151151d9443333643f1cccc1cccccc1f1f343334344944424220225022444
77777777569679655696796571111117569679652222222222222221cccc1222201555555149443334343f1cc1c1cccccc1f3363333444d44442225220202244
d6dddd7dd555555dd555555ddddddd7dd555555d222222222222221cccccc11111155555514443333333f1cccccccccccc1f3333333434444442022222222444
ddd6d7ddd555555dddd6d7ddddd6d7ddd555555d222222222222221c1cc1c17777175555714443333633f1cccccccccccc1f3333333444444442222225222444
7777777756976965777777777777777756976965225222222252111c1cc1c1111117755771111433334f1f1ccccccccccc1f364333344d944442250222024244
d7dddddd5a6556a5d7ddddddd7dddddd5a6556a52522222225117771cddc12222021d11d11777113343ff1cccc7cccccc1f1f333334344444424222220222444
7777777757566565777777777777777757566565222222221177111211112222222412414411177113f1ff1cccccc7ccc1ff3433334449444422202222242244
ddd7dddd56566575ddd7ddddddd7dddd565665752222021177110222222222222222424444443117711f1f1ccccccccccc1f3343333444944442220222224244
dd7dd6dd5a6556a5dd7dd6dddd7dd6dd5a6556a5222021271120202222225222250224444d9443311741f1cccc1cccccc1f1f343334344944424220225022444
7777777756967965777777777777777756967965222217712222222222222222202022444949443331771f1cc1c1cccccc1f3363333444d44442225220202244
d6dddd7dd555555dd6dddd7dd6dddd7dd555555d22117212222222222222222222222444444443333313711ccccccccccc1f3333333434444442022222222444
ddd6d7ddd555555dddd6d7ddddd6d7ddd555555d212711222222222222222222252224444d444333363117c1cccccccccc1f3333333444444442222225222444
77777777569769657777777777777777569769651271222222522222222222222202424444943433334f117c1ccc1ccccc1f364333344d944442250222024244
d7dddddd5a6556a5d7ddddddd7dddddd5a6556a12712222225222222222202222022244449444333343ff117c1c1c11cc1f1f333334344444424222220222444
7777777757566565777777777777777757566561712222222222222222202222222422444443443333f1ff1171ccccccc1ff3433334449444422202222242244
ddd7dddd56566575ddd7ddddddd7dddd565665171222022222220222222222222222424444443433333f1f1c171ccccccc1f3343333444944442220222224244
dd7dd6dd5a6556a5dd7dd6dddd7dd6dd5a655175122020222220202222225222250224444d9443333643f1cc1c71cc7cc1f1f343334344944424220225022444
7777777756967965777777777777777756961971222222222222222222222222202022444949443334343f1cc1111ccccc1f3363333444d44442225220202244
d6dddd7dd555555dd6dddd7dd6dddd7dd511171d22222222222222222222222222222444444443333333f1ccc11a11cccc1f3333333434444442022222222444
ddd6d7ddd555555dadddddddddddddddd11a115d222222222222222222222222252224444d4443333633f1ccc1aaa1cccc1f3333333444444442222225222444
7777777756976965c55555555555555751aaa1652252222222522222222222222202424444943433334f1f1cc11a11cccc1f364333344d944442250222024244
d7dddddd5a6556a5c6776c5ccccc5cc5511a11a52522222225222222222202222022244449444333343ff1cccc11171cc1f1f333334344444424222220222444
7777777757566565c7676cccccccccc557111565222222222222222222202222222422444443443333f1ff1ccccc171cc1ff3433334449444422202222242244
ddd7dddd56566575c7676cccccccccc5517165752222022222220222222222222222424444443433333f1f1cccccc171cc1f3343333444944442220222224244
dd7dd6dd5a6556a5c6776cccc5ccccc5517156a5222020222220202222225222250224444d9443333643f1ccccccc171c1f1f343334344944424220225022444
7777777756967965c55555555555555151717965222222222222222222222222202022444949443334343f1cc7ccc171cc1f3363333444d44442225220202244
d6dddd7dd555555da11111111111111d1715555d22222222222222222222222222222444444443333333f1cccccccc171c1f3333333434444442022222222444
d555555dd555555dd555555dd555555d1715555d222222222222222222222222252224444d4443333633f1cccccccc171c1f3333333444444442222225222444
56976965569769655697696556976965171769652252222222222222222222222202424444943433334f1f1ccccccc171c1f364333344d944442250222024244
5a6556a55a6556a55a6556a55a6556a5171556a52522222222002222222202222022244449444333343ff1cccc7ccc1711f1f333334344444424222220222444
5756656557566565575665655756656171566565222222222522022222202222222422444443443333f1ff1cccccc7c171ff3433334449444422202222242244
56566575565665755656657556566571715665752222022222222222222222222222424444443433333f1f1cccccccc1711f3343333444944442220222224244
5a6556a55a6556a55a6556a55a6556a1716556a5222111211121115211221122250211111d9441313143f1cccc1cccc171f1f343334344944424220225022444
5696796556967965569679655696796171967965221aaa1aaa1aaa11aa11aa122021aaaaa1491a1a1a143f1cc1c1ccc1711f3363333444d44442225220202244
d555555dd555555dd555555dd55555517155555d221a1a1a1a1a111a111a1122221aa111aa11a11a1a13f1ccccccccc1711f3333333434444442022222222444
2222222222222222222222222222222171222222221aaa1aa11aa11aaa1aaa12251aa1a1aa11a131a133f1ccccccccc1711f3333333444444442222225222444
2252222222522222225222222252222171522222221a111a1a1a11211a111a12221aa111aa11a11a1a1f1f1cccccccc1711f364333344d944442250222024244
2522222225222222252222222522222171222222251a121a1a1aaa1aa11aa1222021aaaaa11a131a1a1ff1ccccccccc171f1f333334344444424222220222444
2222222222222222222222222222222171222222222122212121112112211222222411111441443131f1ff1cccccccc171ff3433334449444422202222242244
22220222222202222222022222220221712202222222022222222222222202222222424444443433333f1f1cccccccc1711f3343333444944442220222224244
2220202222202022222020222220202171202022222020222222005222202022250224444d9443333643f1ccccccccc171f1f343334344944424220225022444
2222222222222222222222222222222217122222222222222220222222222222202022444949443334343f1ccccc1111511f3363333444d44442225220202244
222222222222222222222222222222221111512222222222222222222222222222222444444443333333f1ccccc15555b11f3333333434444442022222222444
2222222222222222222222222222222155554122222222222222222222222222252224444d4443333633f1cccc15bbbb511f3333333444444442222222222222
22522222222222222252222222522215444451222222222222522222225222222202424444943433334f1f1cccb5bbbb5b1f364333344d944442250222022202
25222222220022222522222225222255444454222200222225222222252222222022244449444333343ff1ccccb5bbbb5bf1f333334344444424222220250022
2222222225220222222222222222225544445422252202222222222222222222222422444443443333f1ff1cc7b58bb85bff3433334449444422202220222224
22220222222222222222022222220215144154222222222222220222222202222222424444443433333f1f1ccc5b5555151f3343333444944442220225202242
2220202222220052222020222220201455551522222200522220202222202022250224444d9443333643f1cccc151111c1f1f343334344944424220220022224
2222222222202222222222222222221511111122222022222222222222222222202022444949443334343f1cc11c171ccc1f3363333444d44442225222224244
222222222222222222222222222222222221712222222222222222222222222222222444444443333333f1ccccc171cccc1f3333333434444442022222224444
2222222222222222222222222222222222217122222222222222222222222222222222224d444333555551dddd11715555555555333444444442222244444444
2222222222522222225222222252222222221711115122022250022222500222220222024494343356761d7777d116655676666533344d944442250244444444
220022222522222225222222252222222200115555f10022222220522222205220250022494443335555d717717d1555555555553343444444242222449444d4
25220222222222222222222222222222252215ffff512224242422222424222220222224444344335665d717717d676556656765334449444422202249494444
22222222222202222222022222220222222255ffff5f2242224242242242422425202242444434335665dd7777d7666556656665333444944442220244444444
22220052222020222220202222202022222255ffff5f22242422244224222442200222244d94433355551dd77dd7555555555555334344944424220244444444
222022222222222222222222222222222220151ff15f424444444444444444442222424449494433567617dddd1d667556766675333444d44442225244d44444
2222222222222222222222222222222222221f55551544444444444444444444222244444444433355551d111151555555555555333434444442022244444444
22222222222222222222222222222222222215111121112244444444444444444444444444444444444117414449444444494444444444444444444444444444
225002222250022222500222225002222250022222117212444444444444444444444444444444444f1f71144ffffff44ffffff4444444444444444444444444
222220522222205222222052222220522222205220251771449444d4449444d4449444d4449444d4417714444f9444444f944444449444d4449444d4449444d4
2424222224242222242422222424222224242222202221271149444449494444494944444949444117f1fff44ffffff44ffffff4494944444949444449494444
22424224224242242242422422424224224242242520221177114444444444444444444444444117711f9444444f9444444f9444444444444444444444444444
2422244224222442242224422422244224222442200222241177111444444441114444444411177119f9449449f9449449f94494444444444444444444444444
4444444444444444444444444444444444444444222242444411777111144411a1144411117771149ffffff49ffffff49ffffff444d4444444d4444444d44444
444444444444444444444444444444444444444422224444444411177771111aaa11117777111444444449444444494444444944444444444444444444444444
4444444444444444444444444444444444444444444444444444444111177711a117771111444333555555555555555555555555333444444442222244444444
4444444444444444444444444444444444444444444444444444444444211111111111444494343356766665567666655676666533344d944424222244444444
449444d4449444d4449444d4449444d4449444d4449444d4449444d4444220522222442449444333555555555555555555555555334344444442205242424424
49494444494944444949444449494444494944444949444449494444242222022224222244434433566567655665676556656765334449442422220224242222
44444444444444444444444444444444444444444444444444444444224222222222222244443433566566655665666556656665333444942242222242224222
4444444444444444444444444444444444444444444444444444444422220202222052024d944333555555555555555555555555334344942222020222022202
44d4444444d4444444d4444444d4444444d4444444d4444444d44444222050522502025049494433567666755676667556766675333444d42220505220500252
44444444444444444444444444444444444444444444444444444444222222222222222244444333555555555555555555555555333434442222222222222222
4444444444444444444444444444444444444444444444444444444444422222252224444d4443333633f1cccccccccccc1f3333333444444442222222222222
44444444444444444444444444444444444444444444444444444444442422222202424444943433334f1f1ccccccccccc1f364333344d944442250222522222
42424424424244244242442442424424424244244242442442424424444220522022244449444333343ff1ccccccc11cc1f1f333334344444424222225222222
2424222224242222242422222424222224242222242422222424222224222202222422444443443333f1ff1cccccccccc1ff3433334449444422202222222222
42224222422242224222422242224222422242224222422242224222224222222222424444443433333f1f1ccccccccccc1f3343333444944442220222220222
2202220222022202220222022202220222022202220222022202220222220202250224444d9443333643f1ccccccccccc1f1f343334344944424220222202022
2050025220500252205002522050025220500252205002522050025222205052202022444949443334343f1cc7cccccccc1f3363333444d44442225222222222
222222222222222222222222222222222222222222222222222222222222222222222444444443333333f1cccccccccccc1f3333333434444442022222222222
222222222222222222112111211121112111211121122222211121212222211221112114411441113611f1ccc111cc1cc1113111333441112212222222222222
222222222252222221661666166616661666166616612222166616161252166116661661166116661166161c1666116116161666133416661161205222500222
222222222522222216111616161116161161161116161222161616161522161616161616161616161616161cc161161c16161616134316161516122222222052
222222222222222216101661166116661161166116161222166116661222161616661616161616611616161cc161161c16161616134416661216102224242222
2222222222220222161116161611161611611611161612221616111612221616161616161616161616161611c161161c16661616131441161216152222424224
22222222222020222166161616661616116116661666105216661666122016161616161616661666166116661161c161c1611666116144161161222224222442
2222222222222222221121212111212122122111211122222111211122222121212121414111411131143111c11c1c1ccc1f3111331444d14412222244444444
222222222222222222222222222222222222222222222222222222222222222222222444444443333333f1cccccccccccc1f3333333434444444222244444444
2222222222222222222222222222222222222222222222221dddddd122222222252224444d4443333633f1cccccccccccc1f3333444444444444444444444444
225222222252222222022202225002222220205222222222d555555d225222222202424444943433334f1f1ccccccccccc1f3643444949d444d99444444949d4
252222222522222220250022222220522502022222220222d111111d252222222022244449444333343ff1cccc7cccccc1f1f3334d949444444449d44d949444
2222222222222222202222242424222222222022222022221665566122222222222422444443443333f1ff1cccccc7ccc1ff3433444449444343444444444944
22220222222202222520224222424224222205222222222216655661222202222222424444443433333f1f1ccccccccccc1f334344449d444434344344449d44
222020222220202220022224242224424222222222225222d111111d22202022250224444d9443333643f1cccc1cccccc1f1f343344444444344433434444444
222222222222222222224244444444444422222222222222d555555d22222222202022444949443334343f1cc1c1cccccc1f3363334444443333333333444444
2222222222222222222244444444444444442222222222221dddddd12222222222222444444443333333f1cccccccccccc1f3333333344443333333333334444

__map__
4949494949494949494949494b4949494b4b4b4b4949494b4b4b4b4b4b4949494949494949494949494a49494949747372747374737249495053564f58554242494949494949494949494949494949494949494949495051515151515178785151517878777877787777787778515151515b5b5b5b5b5b5151515a5a5a5a5151
494949494b4b4b4949494949494b4b4b4b4a4a4a4a4a494a494a4a494a4a4a4949494b4b4b4b4c4b4949494a4974744a4b4a4a494a2a724950536d6d6d4545424249494949494949494949494949494949494949494950515c51515b5151787851517851515151515151517877515c5c515b515151515b5b5b5b5151515c5151
494949494949494b4b494c49494949494b4b4b4b4b4b49494949494b4b4b494b4b4b4b49494949494a4a494c4972734a747274724a3a734a5053564e484845454242494a4a4a4a494a4c494949494c494949494c494950515a5a5b5c517751777851775b51515a5a5a515b517751515a5a5a5a5c5a5a5a5a5a5b5b5b515a5a51
49494c4a494a4a4a4b4b4c497f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f2d7f4949494a494a4a747374494a4a4b7473734949505356574d484845454241424949494949494a4a4949494949494a4949495051515b5b517878515c5151785b517851515b515b5176515a5a5b5b515151515c515151515b51515a5a
49494c4949494949494b49497f1c1d69692c7f1a1b59595959597f2a592a595959597f697f4a4a4949494a74724a4b4a73744a4a7449494a5053666657574848454445424142494a494949494a494a494a4a494949495051515b5a5177515b5a5a51775c5b77785151785b5b7751515b5b515c515a515151515151515c515151
494a494949494949494b49497f696969693c7f595959595959597f3a593a595959597f697f4949494b4974737474744a7273740b734a494950636366664e57484748454445424141424a494a4a494a4a4a4a4c4949496060515c5b51515b5b515a5178515178765c5a78515c78515b5b517e7f7f7f7e7f7f7f7f7e5151515b51
494a4949494949494b4b49497f69696969697f1a1b59595959597f595959595959597f697f494a494c4b4a4a744a4b494a4a72747274494a6060636366664d574f48474845444445424141424c494949494949494949495051515b51515b78515a517678517878515176515176515b51517e5959597e595959597e512f515c51
494a4a494a4a49494b4949497f2d7f7f7f7f7f7f7f7f7f7f7f2b7f7f7f7f7f7f7f2b7f697f4a4a494972744a494a7474734a4a737273494949606063636667664e4e5748474748454444454241424a4a494949494949495051515a5151787651515b51515176517651787851785b5b5a517e5959593b595959597e5151515b51
49494a4949494b4b494949497f697a695f5f3d69696969696969696969696969696969697f494a494b7474737473747473744b737472747449496060636463666766574e4d57484747484544454241424a4a49494949496060515a5176777877517851787851517851787651785b515a517e5959597e595959597e512f515b51
49494a494b4b494a494949497f69697a5f5f7f7f7f7f7f7f7f2b7f7f7f7f7f7f7f2b7f697f49494a4b734a4b4a494a744a74494a7473747474494960616063646366676766574e4d5748474845444542424a49494949494950515a5c787651515177785178775b5151515151765b515a517e5959597e595959597e5151515b51
4949494b4b4949494a4949497f79697a5f5f7f2a592a595959597f1a1b59595959597f697f4a49494b730a734a744a4a4b4a744a4a494a4a74744c49496061616064646366676766574d4f48474845454241424a49494c4950515a5a515151785151775151785b5a78787851785b5b5a5a7e1a1b597e595959593b515b5b5c5a
49494b49494949494a4949497f79697a5f5f7f3a593a595959597f595959595959597f697f4a4a49497474744a724974744a74744b73744a74724949494a4a4a606160636464636667665757574848454445524a4a4949496060515a5a515b76515177517651515c76517878785151515a7e7f7f7f7e7f7f7f7f7e515a515151
49494c49494949494a4c49497f69697a5f5f7f595959595959597f1a1b59595959597f697f494a494c4973744b744a73744a494a4a74747473744a74494949494c49606161616064636667664e57484748554242494a4949494960515a5c5b517851765b517878515a5151767851515a5a51515151515a5151515151515a515b
494949494a4a49494a4949497f697a695f5f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f2d7f494a494b49747349734a74737474744a4a2f744a494a7372744949494949494949606063646366664d575758454542424a494949495051515a5b517851765b5c78785a5b767878785151515a515a514344444444455c515177515b
494949494a4949494a4949497f6969695f5f696969697f4b49494b494949494949494b4b494949494b4b73724a724a4a72747374747374744b7374747474734a4949494b4b4b4b60616063636667664e48484545524c4a494949606051515b5a5151775b5b76785a5b787676517851515a5a515153464747485551515a51515b
494949494a4b4b49494949497f6969695f5f696969697f49494c494b4b4a4a4a4a49494949494a49494b74744974744a494a4a4b4a494a4b4a742f4a4a747473494b49494949494961606063646356574d48485552494a4a49494950515c5b5b5176785b5a51765a5c7778515151515c515a515a53565757585551515a515c5c
49494b4b4b494949494949497f7969695f5f6979695e7f494949494949494949494a4a4a494a4a4c4c4a49744a4b734a7474737274737474747374744b7372734949494a4a4a49494949606160536666574f58554242494a494949606051515a5a7876515a51785a5178785176515151515a7751535657575855515a51515b51
49494b494a49494c494949497f7969695f5f6979695e7f494a4a4949494a4a4a4a494949494a494949494b74734a744b4a4a494a4b4a494a4a4b4a494a74744949494949494b4b4b4a494949506364666657584545524949494c4949606051515a5176515c5176515151515c7751515a517651515366676768555a5a78515b5a
494b494949494949494949497f7969695f5f6979695e7f494949494a4a494c49494b494b4b4a4b494b4949497274727374747274737374747274737474744b49494c4c494b4b494a4a49494c60616053564d4848554242494949494b4b606051515c77785151777876787877785178515151515a6364646464655a5151515b51
494b49494a494949494949497f6969695f5f696969697f4949494a494949494b4949494949494949494949494949494949494b4b4b4b4b494949494b4b4949494949494949494a4a4949494949495053564e575845455249494a49494b4b6060515a515a5151787878787878787878515b5b5c5b5a515b5b5b5b5b5b515b5c5b
494b494c494a4c4949494949497f7f7f2d2d7f7f7f7f4949494c4a49494b4b49404141414141414141414141414141414141414141414141414141414141414141414141414141414141414141414153666657484855524949494a4a494949606161616161616161787878787861616161616161616161616161616161605151
49494b49494a494949494b49494949505151524949494949494a4a494b4b49495051515a515b5a515c5b515a515c515b51515b51515a51515c51515a51515a51515c515a51515a51515c5a51515a516363564d57585552494b49494a4a4a4949497c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c7c50515b
49494949494a4a49494b4b49494949505a5b5249494949494a4a4c4949494949505c4344444444444551626161616161616161616161616161605162616161616161616161616161616161616160515a6366664e585152494b494949494c494b497b494949497b0b412f7b3f412f7b0a410b410a4141410a410c410b7b505b5c
494c494949494a494b49494949494950515a5249494949494a49494949404141405b53546c6b5454555a42414142494c4b4b4b49494949494c5051524949494c494949494949494949494c49495051626053564f585552494b4b494949494949497b494c494b7b5051527b5051527b505c5a515a515b51515a5151527b505b51
494949494949494b4b49494a494949505b515249494c49494a4a49494950515a5151536a5d5d5d6a555b5151515249494949494b4a4a4a4949505a52494949494b4b494c494b4b494c49494949505a525053564d5855524041414141414141414141414141427b2f5c3f7b2f5a0b7b0a610a610c605a620b610a610a7b50515a
49494a49494b4b4949494a4a494949505151524949494c4a4949494949505b43444443545d5d5d54454444455c52494949494b4b4949494972505152734949494949494949494b4949494949495051525053564e585552505b515a5b515c515a515a5a5151427b5051527b5051527b7c7c7c7c7c505a527c7c7c7c7c7b505b5a
4949494a4b4b4949494a4a49494949505a5c524949494a494949404141405153546c547a5d5d5d7a6c6b6a555b42414142494c4a494949497a7a2d7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7451525053564d585552505a62616161616161616161605b5142415a527b2f5b3f7b0b410a410a405a420a410c410a7b50515a
494b4b4c4a4a4a4a4a4949494c49495051515249494a49494c49505b5c5a51536b5d5d5d5d5d5d5d5d5d545551515a51524949494949497a7a695f69696969696969696969697a69696969697a40514240537f7f7f555240515249494a4a49494b7b4b606160515b51527b505c527b50515b5b5c515a515a515b51527b505c51
494b49494949494949494949494949505b5b5249494949494949505143444443545d5d5d5e5e5e5d5d5d6b454444455c52494a4a4a497a7a69695f697969796979697969695e7a69696969693d515a515a516d6d6d515b515c52494a4949494b4b7b49494b6060515a527b0b512f7b0a610c610a605a620b610a610a7b505151
49494949494949494949494949494950515a5249494949494949505a536a6b547a5d5d5e5e4e5e5e5d5d7a546c6a555b52494949497a7a6969695f6979697969796979695e5e7a69696969697a61616150537f7f7f5552605152494a4949494b497b7c7c7c7c7c605c527b505b527b7c7c7c7c7c505a527c7c7c7c7c7e7f2b7e
41414141414141414141414141414140515142414141414141414051536c5d5d5d5d5e5e4d4f575e5e5d5d5d5d54555a524949494a7a696969695f6979697969796979695e5e7a69696969697a7249495053564e585552505152494a49494a49497b0b410a410a40514241405142414141414141405a4241414141417e59597e
5b5a515c515a51515b515a5b515b5c5a515c5b5a515a515b5c5a515b536a5d5d5d5d5e4e570b4d4e5e5d5d5d5d6b555152494c494a7a696969695f5f5f5f5f5f5f5f5f5f5e5e7a69696969697a494b4b5053564d585552505a524a4949494b49497b515c5a515b515a5a515a515b5a515a515a5c51515a5b5c5a5a513b59597e
__sfx__
0002000003030060500b04004130091300d1200811004110001000f70002700077000270006700037000670009700077000f7000b7000f7001b700147001b7001c7001c7001b7001670000000000000000000000
000400000415009150101500313009130101300311009110101100c1001210010100131001510017100051000710007100091000b1000d1000e1000f10004100041000510006100061000710007100091000a100
001000200375006710005500261004750057100375000710035500671007750027100475006310005500671000750036100575007410005500471007750017100575001610037500571000550037100575002710
00100000198501f850268502693026810268302681000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002c9500c940099300992009810099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000200075000710007500071000750007100015000110000500001000750007100015000110007500071000050000100075000710001500011000050000100075000710001500011000750007100055000510
001000000405004030040500403004050040300005000030000500003000050000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008000015b501cb500fb5012b501cb5017b500e0000900006000040000080026a0026a0026a0026a0026a0029a002da0031a0033a0030a0022a0011a000ca0034a0034a0034a0034a0035a0035a0035a0035a00
0008000023a5023a202dd502dd2023d5023d2030e5030e2023e5023e202d9502d9402d9502d9302d9502d92029a0029a0029a0029a0029a0029a0029a0029a0029a002aa002aa002aa002aa002ba002ba002ba00
0002000003530065500b54004730097300d7200871004710001000f70002700077000270006700037000670009700077000f7000b7000f7001b700147001b7001c7001c7001b7001670000000000000000000000
000800000b6501c8200b6301c8200b61000600006000060000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000b8501c9200b8301c9200b81000600006000060000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00080000269501ee10298501ee1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800002c850319402c8302792022810000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800001ae501fe501ae5005f001de00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000003730067500b74004530095300d5200811004110001000f70002700077000270006700037000670009700077000f7000b7000f7001b700147001b7001c7001c7001b7001670000000000000000000000
0004000037950376102b9502b61021950216100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010002000750007100075000710007500071021a5021a10000500001000750007101fa501fa100075000710000500001000750007101fa501fa10000500001000750007101fa501fa1000750007100055000510
0010002000750007100075000710007500071027e5027e100005000010007500071027a5027a1000750007100005000010007500071021a5021a100005000010007500071021a5021a1000750007100055000510
001000000455003530045500453004550045300055000530005500003000050000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000415004630041500463004150046200023000620002100061000050006100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 02424344
03 05064744
03 11134344
03 12144344

