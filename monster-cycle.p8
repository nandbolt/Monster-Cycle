pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--monster cycle(v0.9.3)
--by nandbolt

--music--
audio_artist="@jamailmusic"
audio_credits_color=12
music_mainmenu=40
music_ghost=44
music_undead=48
music_human=52
---------

--sfxs--
sfx_kill=3
sfx_hurt=3
sfx_collect=1
sfx_ascend=7
sfx_ghostdash=9
sfx_ghostblast=11
sfx_wraithdash=0
sfx_wraithblast=10
sfx_zombiecharge=14
sfx_zombiebreath=12
sfx_skeletonthrow=13
sfx_humandash=15
sfx_pistolshot=16
sfx_gamestart=1
sfx_highscore=8
---------

--game state
gstate=0
gtime=0 --game time (steps)
ghigh=0 --high score (steps)
vnum="0.9.3"
debug_mode=false

--pools
ghosts={}
wraiths={}
zombies={}
skeletons={}
humans={}
projs={} --projectiles
ps={} --low particle system
ps2={} --high particle system
collectables={}

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
mmomega=1/360

--delay
delay=0

--fade
fade=0

--fog
fogtimer=0
fogfreq=30
cfog={1,5,13}

--target indicator
ctarg={7}

--title
tcols={0,1,2,8}

--help
tips={
	"spirits are invincible\nwhen dashing.",
	"zombie breath goes\nthrough walls.",
	"monsters flee when their\nabilities are on cooldown.",
	"any ability can be used\nso long as there is meter.",
	"slow and steady wins\nthe race!",
	"zombies and skeletons\ncan't hurt each other.",
	"humans can't hurt\nother humans.",
	"humans can either have\na pistol or a knife.",
	"spirits can't see\nhumans or the undead.",
	"humans or the undead\ncan't see spirits.",
	"wraiths have a faster\ndash than ghosts.",
	"wraiths can only shoot\ntwice before recharging.",
	"skeletons can only\nthrow bones.",
	"zombies have a hard\ntime turning.",
	"keep an eye on your\nability and cooldown meters.",
	"water slows down\nhumans and the undead.",
	"choose spawn points\nthat are safe!",
	"every monster is equal.",
	"kiting spirits in a\ncircle is effective.",
	"ghosts have a larger\nability meter than wraiths.",
}

--init
function _init()
	--generate tip
	tip=tips[irnd(1,#tips)]
	
	--not menu state
	if gstate==gst_menu then
		mmx=irnd(0,(mw-ss)/ts)
		mmy=irnd(0,(mh-ss)/ts)
		pmusic(music_mainmenu)
		load_highscore()
	else
		--reset music
		pmusic(music_ghost,0,5)
		
		--clear run
		gtime=0
		
		--clear particles
		
		
		--clear pools
		ghosts={}
		wraiths={}
		zombies={}
		skeletons={}
		humans={}
		projs={}
		ps={}
		ps2={}
		collectables={}
		
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
		make_zombie(468,404,false) --small grave
		make_zombie(940,300,false) --large grave1
		make_zombie(940,204,false) --large grave2
		make_zombie(836,252,false) --large grave3
		make_zombie(268,436,false) --beach
		make_zombie(964,444,false) --forest
		make_zombie(300,332,false) --fountain
		make_zombie(740,252,false) --river
		
		--skeletons
		make_skeleton(468,372,false) --small grave
		make_skeleton(868,252,false) --large grave
		make_skeleton(828,44,false) --rocks
		make_skeleton(420,100,false) --hedges
		
		--humans
		make_human(132,84,false) --hotel
		make_human(924,84,false) --digger
		make_human(508,252,false) --church1
		make_human(588,244,false) --church2
		make_human(84,436,false) --beach
		make_human(740,468,false) --forest
		
		--add player
		update_spawnpoint(false)
		if half_chance() then
			make_ghost(spnr.x,spnr.y,true)
		else
			make_wraith(spnr.x,spnr.y,true)
		end
--		make_human(spnr.x,spnr.y,true)
		player.iframes=900
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
		--main menu
		if mmstart then
			if fade<=0 then
				gstate=gst_help
				mmomega=1/360
			elseif delay<=0 then
				fade-=1
			else
				delay-=1
			end
			mmomega=lerp(mmomega,0,0.1)
		elseif btnp(5) then
			mmstart=true
			fade=mmfade
			delay=mmdelay
			sfx(sfx_gamestart)
			pmusic(-1) --stop music
		end
	elseif gstate==gst_help then
		--help menu
		if btnp(5) then
			gstate=gst_active
			_init()
			sfx(sfx_gamestart)
		end
	else
		--update spawner
		update_spawner()
		
		--update pools
		foreach(ghosts,update_ghost)
		foreach(wraiths,update_wraith)
		foreach(zombies,update_zombie)
		foreach(skeletons,update_skeleton)
		foreach(humans,update_human)
		foreach(projs,update_proj)
		foreach(collectables,update_collectable)
		
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
				sfx(sfx_gamestart)
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
	elseif gstate==gst_help then
		draw_helpmenu()
	else
		--draw tiles
		map(0,0,0,0,mw,mh)
		
		--draw pools
		foreach(ps,draw_p) --low particles
		foreach(collectables,draw_collectable)
		foreach(ghosts,draw_ghost)
		foreach(wraiths,draw_wraith)
		foreach(zombies,draw_zombie)
		foreach(skeletons,draw_skeleton)
		foreach(humans,draw_human)
		foreach(projs,draw_proj) --high particles
		
		--draw high particles
		foreach(ps2,draw_p2)
		
		--active state
		if gstate==gst_active then
			draw_hud()
			draw_targ_line()
		--death menu
		elseif gstate==gst_dead then
			local xx,yy=cam.x+16,cam.y+33
			
			--death prompt
			oprint("more than death.",
				xx,yy,8,1)
			
			--tip
			yy+=24
			oprint("tip:\n"..tip,
				xx,yy,7,1)
			
			--restart prompt
			yy+=40
			oprint("❎/x to retry",
				xx,yy,10,1)
		--victory menu
		elseif gstate==gst_complete then
			local xx,yy=cam.x+33,cam.y+17
			mmtimer+=1
			
			--victory prompt
			tprint("monster ascended.",
				xx,yy)
			
			--time
			yy+=40
			local seconds=flr(gtime/30)
			local c,nh=7,""
			if gtime==ghigh then
				c=10
				nh="(new high!)"
			end
			oprint("time:"..seconds..nh,
				xx,yy,c,1)
			
			--restart prompt
			yy+=40
			oprint("❎/x to play again",
				xx,yy,7,1)
		end
		
		--fade
		if gstate==gst_active then
			if (fade>0) draw_fadein()
		else
			if (mmstart) draw_fadeout()
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
gst_help=1 --help menu state
gst_active=2 --active game state
gst_dead=3 --dead game state
gst_complete=4 --complete game state

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
	local dx,dy=normalize(a.dx,
		a.dy)
	a.dx=dx
	a.dy=dy
end

--normalize vector
function normalize(x,y)
	if (x==0 and y==0) return 0,0
	local ang=atan2(x,y)
	return cos(ang),sin(ang)
end

--50/50 chance
function half_chance()
	return rnd(1)<0.5
end

--sine wave
-- omega:frequency
-- x:input
-- phase:angle offset
-- amp:amplitude
function swave(omega,x,phase,amp)
	return amp*sin(omega*x+phase)
end

--cosine wave
-- omega:frequency
-- x:input
-- phase:angle offset
-- amp:amplitude
function cwave(omega,x,phase,amp)
	return amp*cos(omega*x+phase)
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
	init_dash(ghost,3,1,sfx_ghostdash)
	
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
	return ghost
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
	ghost.sfxxaction=sfx_ghostblast
end

--enter ghost wander state
function ghost_wander(ghost)
	enter_wander_state(ghost)
end

--enter ghost fight state
function ghost_fight(ghost)
	enter_fight_state(ghost)
	
	--choose action
	if half_chance() then
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
	init_run(zombie,4,sfx_zombiecharge)
	
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
	return zombie
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
	zombie.sfxxaction=sfx_z0mbiebreath
end

--enter zombie wander state
function zombie_wander(zombie)
	enter_wander_state(zombie)
end

--enter zombie fight state
function zombie_fight(zombie)
	enter_fight_state(zombie)
	
	--choose action
	if half_chance() then
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
	a.maxhp=3
	a.hp=3
	a.iframes=30 --invincibility frames
	
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
	
	--iframes
	if a.iframes!=nil and
		not dmgable(a) then
		a.iframes-=1
	end
	
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
		for oa in all(pool) do
			--check rect intersection
			if (oa!=a and 
				rect_intersect(bbx1,bby1,
				bbx2,bby2,oa.x-oa.bbhw,
				oa.y-oa.bbhh,oa.x+oa.bbhw,
				oa.y+oa.bbhh)) then
				return oa
			end
		end
	end
	return nil
end

--renders the actor
function draw_actor(a)
	--iframes
	if not dmgable(a) and
		a.iframes%2==0 then
		return
	end
	
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
		if a.trailon or a.xp>=a.maxxp then
			if a.xp>=a.maxxp then
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
function init_dash(a,dspd,dc,dsfx)
	--states
	a.dashing=false
	a.dashspd=dspd
	a.dashctrail=dc --dash trail color
	a.burststr=1.5 --burst strength
	a.burstcost=10 --burst cost
	a.sfxoaction=dsfx --dash sound
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
		a.cooldwn=a.maxcooldwn
		a.meter-=1
	else
		a.dashing=false
		update_meter(a)
	end
	
	--update max speed
	if a.dashing then
		a.maxspd=a.dashspd
		
		--check dash collisions
		local oa=touching(a,a.targs)
		if oa!=nil and
			dmgable(oa) and
			not oa.dashing then
			knockback(oa,oa.x-a.x,
				oa.y-a.y,4)
			dmg_actor(oa,1)
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
		if oa!=nil and dmgable(oa) then
			knockback(oa,oa.x-a.x,
				oa.y-a.y,4)
			dmg_actor(oa,1)
		end
	end
end

--actor kill
function actor_kill(a)
	--kill sound
	if (a.inview) sfx(sfx_kill)
	
	--descend
	local x,y=a.x,a.y
	local nxp=1+a.xp
	local na=descend(a)
	
	--drop xp
	for i=1,nxp do
		spawn_xp(x+rnd(1)*ts-hts,
			y+rnd(1)*ts-hts,na)
	end
	
	--drop hp
	if 0.1<0.2 then
		spawn_hp(x+rnd(1)*ts-hts,
			y+rnd(1)*ts-hts,na)
	end
end

--check ascension
function check_ascend(a)
	--if enough xp
	if a.xp>=a.maxxp then
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
	if (a.inview) sfx(sfx_ascend)
	
	--to tier 2
	if a.tier+1==2 then
		if half_chance() then
			make_zombie(a.x,a.y,is_player)
		else
			make_skeleton(a.x,a.y,is_player)
		end
		
		--undead music
		if is_player then
			pmusic(music_undead)
		end
	--to tier 3
	elseif a.tier+1==3 then
		make_human(a.x,a.y,is_player)
		
		--human music
		if is_player then
			pmusic(music_human)
		end
	--to tier 4
	elseif a.tier+1==4 then
		if is_player then
			--victory
			gstate=gst_complete
			mmstart=false
			if gtime<ghigh or ghigh==0 then
				save_highscore(gtime)
				sfx(sfx_highscore)
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
	local c,na=1,nil
	
	--to tier 2
	if a.tier-1==2 then
		if half_chance() then
			na=make_zombie(a.x,a.y,is_player)
		else
			na=make_skeleton(a.x,a.y,is_player)
		end
		c=8
		
		--undead music
		if is_player then
			pmusic(music_undead)
		end
	--to tier 1
	elseif a.tier-1==1 then
		if half_chance() then
			na=make_ghost(a.x,a.y,is_player)
		else
			na=make_wraith(a.x,a.y,is_player)
		end
		c=5
		
		--ghost music
		if is_player then
			pmusic(music_ghost)
		end
	--to tier 0
	elseif a.tier-1==0 then
		if is_player then
			gstate=gst_dead
			mmstart=false
		end
	end
	
	--blood
	for i=1,8 do
		add_p(a.x+rnd(1)*12-6,
			a.y+rnd(1)*12-6,c)
	end
	
	--destroy actor
	del(a.pool,a)
	
	--return new actor
	return na
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
	if oa!=nil and dmgable(oa) then
		knockback(oa,oa.x-a.x,
			oa.y-a.y,4)
		dmg_actor(oa,1)
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

--damage actor
function dmg_actor(a,dmg)
	a.hp-=dmg
	if a.hp<=0 then
		actor_kill(a)
	else
		a.iframes=30
		if a.inview then
			sfx(sfx_hurt)
		end
	end
end

--knockback
function knockback(a,dx,dy,stren)
	local kdx,kdy=normalize(dx,dy)
	a.vx+=kdx*stren
	a.vy+=kdy*stren
end

--damageable
function dmgable(a)
	return a.iframes<=0
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
	init_dash(wraith,4,8,sfx_wraithdash)
	
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
	return wraith
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
	wraith.sfxxaction=sfx_wraithblast
end

--enter wraith wander state
function wraith_wander(wraith)
	enter_wander_state(wraith)
end

--enter wraith fight state
function wraith_fight(wraith)
	enter_fight_state(wraith)
	
	--choose action
	if half_chance() then
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
	if gstate==gst_active and 
		spnr.cnt%spnr.freq==0 then 
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
	return skeleton
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
	skeleton.sfxoaction=sfx_skeletonthrow
	skeleton.sfxxaction=sfx_skeletonthrow
end

--enter skeleton wander state
function skeleton_wander(skeleton)
	enter_wander_state(skeleton)
end

--enter skeleton fight state
function skeleton_fight(skeleton)
	enter_fight_state(skeleton)
	
	--choose action
	if half_chance() then
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
	if half_chance() then
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
	human.sfxoaction=sfx_humandash
	
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
	return human
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
		human.sfxxaction=sfx_pistolshot
		
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
	if oa!=nil and oa!=p.owner and
		dmgable(oa) and
		not oa.dashing then
		knockback(oa,oa.x-p.x,
			oa.y-p.y,4)
		dmg_actor(oa,1)
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
--gui

--draw main menu
function draw_mainmenu()
	local xx,yy=0,0
	
	--tiles
	map(mmx,mmy,0,0,mw,mh)
	
	--timer
	mmtimer+=1
	
	--draw high particles
	foreach(ps2,draw_p2)
	
	--monster cycle
	circ(hss,hss,33,1)
	circ(hss,hss,31)
	circ(hss,hss,32,7)
	draw_mmsprite(2,0.22)   --ghost
	draw_mmsprite(5,0.28)   --wraith
	draw_mmsprite(34,0.55)  --zombie
	draw_mmsprite(37,0.61)  --skelly
	draw_mmsprite(8,0.88)   --human1
	draw_mmsprite(40,0.94)  --human2
	draw_mmsprite(62,0.415) --heart1
	draw_mmsprite(62,0.745) --heart2
	draw_mmsprite(62,0.075) --heart3
	tprint("monster cycle",39,9)
	
	--play prompt
	oprint("press ❎/x",43,
		63+swave(mmomega*6,mmtimer,
		0,4),10,1)
	
	--credits
	oprint("game by nandbolt(v"..vnum..")",
		15,114,6,1)
	oprint("music by "..audio_artist,
		21,105,audio_credits_color,1)
	
	--fade
	if (mmstart) draw_fadeout()
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

--draw main menu sprite
function draw_mmsprite(spridx,
	phase)
	spr(spridx,60-cwave(mmomega,
		mmtimer,phase,32),60+
		swave(mmomega,mmtimer,phase,32))
end

--title print
function tprint(str,x,y)
	local val=sin(mmomega*mmtimer*6)
	local cidx1,cidx2=flr(
		val*2.4+2.5),flr(val*1.4+1.5)
	cursor(x-1,y)
	print(str,tcols[cidx1])
	cursor(x+1,y)
	print(str,tcols[cidx2])
	cursor(x,y+1)
	print(str,tcols[cidx1])
	cursor(x,y-1)
	print(str,tcols[cidx2])
	cursor(x,y)
	print(str,7)
end

--draw fade out
function draw_fadeout()
	local r=(hss+28)*(1-(fade/30))
	circfill(cam.x+hss,
		cam.y+hss,r,2)
end

--draw fade in
function draw_fadein()
	local r=(hss+28)*(fade/30)
	circfill(cam.x+hss,
		cam.y+hss,r,2)
end

--shadow bar
-- x,y=corner
-- w,h=width,height
-- v=value of bar (0=empty,1=full)
-- c=color
function shdwbar(x,y,w,h,v,c)
	rectfill(x-1,y-1,x+w-1,y+h-1,1)
	if v>0 then
		rectfill(x,y,
			x+flr(clamp(w*v,0,w)),
			y+h,c)
	end
end

--draw hud
function draw_hud()
	local xx,yy=cam.x+2,cam.y+2
	
	--debug
	--cursor(cam.x+2,cam.y+hss)
	--print("collectables:"..#collectables)
	
	--hp
	shdwbar(xx+10,yy+2,32,2,
		player.hp/player.maxhp,8)
	shdwprint("hp",xx,yy,8)
	
	--xp
	yy+=8
	shdwbar(xx+10,yy+2,32,2,
		player.xp/player.maxxp,10)
	shdwprint("xp",xx,yy,10)
	
	--meter
	yy+=8
	shdwbar(xx+10,yy+2,32,2,
		player.meter/player.maxmeter,
		7)
	shdwprint("★",xx,yy,7)
	
	--cooldown
	yy+=8
	shdwbar(xx+10,yy+2,32,2,
		player.cooldwn/player.maxcooldwn,
		13)
	shdwprint("⧗",xx,yy,13)
	
	--goal
	yy+=8
	shdwprint(player.goal,
		xx,yy,7)
	
	--controls
	yy=cam.y+116
	shdwprint(player.oprompt,
		xx,yy,12)
	yy-=8
	shdwprint(player.xprompt,
		xx,yy,14)
	
	--highscore
	local hseconds=flr(ghigh/30)
	if (ghigh==0) hseconds="none"
	xx+=90
	yy=cam.y+2
	shdwprint("high:"..hseconds,
		xx,yy,10)
	
	--timer
	yy+=8
	local seconds=flr(gtime/30)
	shdwprint("time:"..seconds,
		xx,yy,7)
end

--draw help menu
function draw_helpmenu()
	cls(2)
	cursor(8,8)
	print("there is no end in death.\nas a lowly spirit, fight\nfor survival and gain\nenough xp to ascend\nto the next monster tier.\nescape the monster cycle!\n\ncontrols\n⬆️⬇️⬅️➡️:move\n🅾️/z:ability 1\n❎/x:ability 2\np/enter:pause\n\n*tip*\n"..tip.."\n\n❎/x to start",7)
end
-->8
--misc

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

--play music
function pmusic(idx)
	music(idx,0,5)
end
-->8
--collectable

--init collectable
function init_collectable(c,x,y)
	c.owner=nil
	c.targs={ghosts,wraiths,
		zombies,skeletons,humans}
	
	--dimensions
	c.bbhw=1 --bounding box half width
	c.bbhh=1 --bounding box half height
	c.inview=false --in camera view
	
	--movement
	c.x=x --x position
	c.y=y --y position
	c.vx=(rnd(1)-0.5)*4 --x velocity
	c.vy=(rnd(1)-0.5)*4 --y velocity
	c.spd=0 --speed (for queries)
	c.maxspd=0 --current max move speed
	c.accel=0.05 --move acceleration
	c.ethereal=false --ethereal=no wall collisions
	c.bounce=false --bounce on walls
	
	--draw
	c.spr=62
	c.col=9
	
	--input
	c.dx=0 --x direction
	c.dy=0 --y direction
	c.collect=collect
	
	--lifetime
	c.life=150
	
	--trail
	init_trail(c,10)
end

--update collectable
function update_collectable(c)
	--trail
	update_proj_trail(c)
	
	--move and collide
	local collision=move_and_collide(c)
	
	--check collect
	local oa=touching(c,c.targs)
	if oa!=nil and oa!=c.owner then
		c.collect(oa,c)
	else
		--life timer
		c.life-=1
		if c.life<=0 then
			del(collectables,c)
		end
	end
end

--draw collectable
function draw_collectable(c)
	--spr(c.spr,c.x,c.y)
	local col=c.col
	if (c.owner==player) col=5
	circfill(c.x,c.y,1,col)
end

--collect
function collect(a,c)
	--kill sound
	if (c.inview) sfx(sfx_collect)
	del(collectables,c)
end

--spawn xp
function spawn_xp(x,y,owner)
	local xp={}
	init_collectable(xp,x,y)
	xp.collect=collect_xp
	xp.owner=owner
	
	--add to pool
	add(collectables,xp)
end

--collect xp
function collect_xp(a,xp)
	a.xp+=1
	
	--if player and ready to ascend
	if a==player then
		if a.xp>=a.maxxp then
			if a.tier==1 then
				player.goal="◆find tombtone!"
			elseif a.tier==2 then
				player.goal="⌂find bed!"
			elseif a.tier==3 then
				player.goal="∧find water!"
			end
		end
	end
	
	collect(a,xp)
end

--spawn hp
function spawn_hp(x,y,owner)
	local hp={}
	init_collectable(hp,x,y)
	hp.collect=collect_hp
	hp.col=8
	hp.ctrail=14
	hp.owner=owner
	
	--add to pool
	add(collectables,hp)
end

--collect hp
function collect_hp(a,hp)
	a.hp=clamp(a.hp+1,0,a.maxhp)
	collect(a,hp)
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
01510000005555b50b555500005555bb1d77dd7d1d7777d11d717dd1015555451455551011555555f522225fff6446ff75eeee57771dd17700100100d161161d
1545100005bbb85105bbbb5005bbbb5bd7117dd1d717717dd77717d1154441511544445155444455455222544fa48644d55eee5dd7ad81dd01e11e1016166161
5454510005bbbb50b5bbbb5b55bbb855d77777d1d717717dd1777dd7154444514544445545444151f522225fff6486ff75eeee57771d8177018ee81015166151
1d5d451005bbbb50b5bbbb5bb5bbbb5bd77777d17d7777ddd71777dd1544445145444455154444544522255444684644d5eee55ddd18d1dd0188881015166151
0111585105bbb850b58bb85b15b8bb55d7117dd17dd77dd1dd7d7dd11544415145144151154144554522225444684a44d5eeee5ddd18dadd0018810016166161
000015d15b555510515555b50b5555111d77dd10d1dddd711ddddd10545555105155554114555511f155551fff6446ff71555517771dd17700011000d161161d
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
22222222222222222222222222222222222222222222222222222222222222222222222222222222220202522202025222020252220202522202025222020252
22522222222222222252222222522222222222222222222222222222225222222252222222522222222025222220252222202522222025222220252222202522
25222222222202222522222225222222220022222200222222002222252222222522222225222222266226622662266226622662266226622662266226622662
22222222222022222222222222222222252202222522022225220222222222222222222222222222611661166116611661166116611661166116611661166116
22220222222222222222022222220222222222222222222222222222222202222222022222220222622662266226622662266226622662266226622662266226
22202022222252222220202222202022222200522222005222220052222020222220202222202022166116611661166116611661166116611661166116611661
22222222222222222222222222222222222022222220222222202222222222222222222222222222222502222225022222250222222502222225022222250222
22222222222222222222222222222222222222222222222222222222222222222222222222222222250222222502222225022222250222222502222225022222
22222222222222222222222222222222222222200022002002220020002000200022222200202022002062200022222222222222222222222222222222266222
22522222222222222252222222522222225222277700770770207707770777077702222077070700770706277702222222522222225222222252222222611622
25222222222202222522222225222222252222277707270727070022722702270702022722270707222706270222222225222222252222222522222225622622
22222222222022222222222222222222222222272707070707077702702770277020222702277707022701277022222222222222222222222222222202166102
22220222222222222222022222220222222202270707070707000702702700272702222700200707002700270022022222220222222202222222022222266222
22202022222252222220202222202022222020270707722707077222702777070702522277077702770777077700202222202022222020222220202220611652
22222222222222222222222222222222222222222222222222222222222222222222222222222222226222222222222222222222222222222222222222622625
22222222222222222222222222222222222222222222222222222222222222222222222222222222221661222222222222222222222222222222222222166122
22222222222222222222222222222222222222222222222222222222222222222222222222222222222662222222222222222222222222222222222222266222
22522222222222222222222222522222225222222252222222522222225222222252222222522222226116222252222222222222225222222222222222611622
25222222222202222222022225222222252222222522222225222222252222222522222225222222256226222522222222222222252222222222022225622622
22222222222022222220222222222222222222222222222222222222222222222222222222222222021661022222222222222222222222222220222202166102
22220222222222222222222222220222222202222222022222220222222202222222022222220222222662222222022222222222222202222222222222266222
22202022222252222222522222202022222020222220202222202022222020222220202222202022206116522220202222222222222020222222522220611652
22222222222222222222222222222222222222222222222222222222222222222222222222222222226226252222222222222222222222222222222222622625
22222222222222222222222222222222222222222222222222222222222222222222222222222222221661222222222222222222222222222222222222166122
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222266222
22022202225002222250022222500222225002222250022222500222225002222250022222500222225002222250022222500222225002222220205222611622
20250022222220522222205222222052222220522222205222222052222220522222205222222052222220522222205222222052222220522502022225622622
20222224242422222424222224242222242422222424222224242222242422222424222224242222242422222424222224242222242422222222202202166102
25202242224242242242422422424224224242242242422422424224224242242242422422424224224242242242422422424224224242242222052222266222
20022224242224422422244224222442242224422422244224222442242224422422244224222442242224422422244224222442242224424222222220611652
22224244444444444444444444444444444444444444444444444444444411144444444444444444444444444444444444444444444444444422222222622625
2222444444444444444444444444444444444444444444444444444444411a111111114444444444444444444444444444444444444444444444222222166122
252224444444444444444444444444444444444444444444444444411111aaa17777771111444444444444444444444444444444444444442222222222266222
2202424444444444444444444444494444444444444444444444111777711a111111117777111444444449444444494444444444444444442220205222611622
2022244444444444449444d44444944444444444449444d4441177711114111444449411117771144444944444449444449444d4449444d42502022225622622
22242244444444d4494944444d444444444444d44949444411771114494944444d444444491117711d4444444d44444449494444494944442222202202166102
22224244444444444444444444444444444444444444441177114444444444444444444444444117711411115144444444444444444444442222052222266222
250224444944444444444444444949d449444444444441471144444444444444444949d44444444117415555f14949d444444444444444444222222220611652
202022444494444444d44444449d9d444494444444d417714444444444d44444449d9d4444d444444115ffff519d9d4444d4444444d444444422222222622625
222224444444444444444444444444444444444444117414444444444444444444444444444444444455ffff5f44444444444444444444444444222222166122
252224444444444444422222444444444441dddd11471144444444444444444444444444444444444455ffff5f44444422222444444444444444444422222222
22024244444449444424222244444444441d7777d17144444444444444444444444444444444444444151ff15f44444422242444444444444444444422202052
2022244444449444444220524242442442d717717d12442442424424424244244242442442424424421f5555154244242222442444444444449444d425020222
222422444d444444242222022424222224d717717d24222224242222242422222424222224242222241511117124222222242222444444d44949444422222022
2222424444444444224222224222422242dd7777d722422242224222422242224222422242224222422242221712422222266622444444444444444422220522
25022444444949d42222020222022202221dd77dd702220222022202220222022202220222022202220222021271220222666662494444444444444442222222
20202244449d9d4422205052205002522017dddd1d500252205002522050025220500252205002522050025221711115156665604494444444d4444444222222
22222444444444442222222222222222221d11112122222222222222222222222222222222222222222222222215555416665666444444444444444444442222
22222222444444444442222222222222222171222222222222222222222222222222222222222222222662222154444516666666644444442222244444444444
22022202444444444442250222522222225171222222222222222222225222222252222222222222226116222554444546665665644444442224244444444444
20250022449444d444242222252222222517122222002222220022222522222225222222222202222562262225544445466555555242442422224424449444d4
20222224494944444422202222222221111512222522022225220222222222222222222222202222021661022151441546665665242422222224222249494444
25202242444444444442220222220215555b12222222222222222222222202222222022222222222222662222145555152222222422242222222222244444444
2002222444444444442422022220215bbbb510222222005222220052222020222220202222225222206116522151111112205202220222022220520244444444
2222424444d444444442225222222b5bbbb5b2222220222222202222222222222222222222222222226226252222217125020250205002522502025044d44444
22224444444444444442022222222b5bbbb5b2222222222222222222222222222222222222222222221661222222221712222222222222222222222244444444
44444444444444444442222222222b58bb85b2222222222222222222222222222222222222222222222662222222221712222222222222222222244422222444
444444444444444444422502225225b5555152222252222222522222225222222222222222222222226116222252221712522222222222222224244422242444
449444d4444444444424222225222151111012222522222225222222252222222222022222220222256226222522221715222222222202222222442422224424
49494444444444444422202222222221712202222222222222222222222222222220222222202222021661022222222171222222222022222224222222242222
44444444444444444442220222220221712222222222022222220222222202222222222222222222222662222222022171220222222222222222222222222222
44444444444444444424220222202021712200522220202222202022222020222222522222225222206116522220202171202022222252222220520222205202
44d44444444444444442225222222221712022222222222222222222222222222222222222222222226226252222222171222222222222222502025025020250
44444444444444444442022222222221712222222221112111211122112211222222111112222121211661222222222171222222222222222222222222222222
2222244444444444444222222222222171222222221aaa1aaa1aaa11aa11aa122221aaaaa1221a1a1a1662222202025171020252220202522202025222020252
2224244444444444444225022252222171222222221a1a1a1a1a111a111a1122221aa1a1aa11a11a1a1116222220252171202522222025222220252222202522
22224424449444d4442422222522222171002222251aaa1aa11aa11aaa1aaa12221aaa1aaa11a161a16226222662266171622662266226622662266226622662
2224222249494444442220222222222171220222221a111a1a1a11211a111a12221aa1a1aa11a11a1a1661026116611171166116611661166116611661166116
2222222244444444444222022222022171222222221a121a1a1aaa1aa11aa1222221aaaaa11a161a1a1662226226622171266226622662266226622662266226
22205202444444444424220222202021712200522221202121211121122110222222111112216661616616521661166171611661166116611661166116611661
2502025044d4444444422252222222221710222222222222222222222222222222222222226666dddddd66252266621712250222222502222225022222250222
22222222444444444442022222222222171222222222222222222222222222222222222222666dddddddd1222666661715022222250222222502222225022222
25222444444444444442222222222222171222222222222222222222222222222222222222666dddddddd22266655517122222221dddddd1222222221dddddd1
22024244444444444442250222522222171222222252222222522222222222222252222222566dddddddd6226665661712500222d555555d22500222d555555d
20222444449444d444242222252222222171222225222222252222222200222225222222252266dddddd26266666111122222052d111111d22222052d111111d
222422444949444444222022222222222171022222222222222222222522022222222222222222220216616666511a1164242222166556612424222216655661
22224244444444444442220222220222217122222222022222220222222222222222022222220222222662666551aaa152424224166556612242422416655661
250224444444444444242202222020222217105222202022222020222222005222202022222020222061166665511a1154222442d111111d24222442d111111d
2020224444d444444442225222222222221712222222222222222222222022222222222222222222226226266555111554444444d555555d44444444d555555d
222224444444444444420222222222222221111222222222222222222222222222222222222222222216612266517155444444441dddddd1444444441dddddd1
2522244444444444444222222222222222211a112222222222222222222222222222222222222222222662224441714444444444444444444444444444444444
220242444444494444422502222222222251aaa12252222222522222222222222252222222522222226116224417144444444444444449444444444444444444
2022244444449444442422222200222225211a11252222222522222222220222252222222522222225622622417414d44444444444449444449444d444444444
222422444d44444444222022252202222222111212222222222222222220222222222222222222220216610219714444444444444d44444449494444444444d4
22224244444444444442220222222222222202171222022222220222222222222222022222220222222662221714444444444444444444444444444444444444
25022444444949d44424220222220052222020217120202222202022222252222220202222202022206116517144444444444444444949d44444444449444444
20202244449d9d4444422252222022222222222127122222222222222222222222222222222222222262261741d4444444444444449d9d4444d4444444944444
22222444444444444442022222222222222222221271222222222222222222222222222222222222221661721444444444444444444444444444444444444444
25222444444444444442222222222222222222222127112222222222222222222222222222222222222117211dddddd1444444441d1111d1444444441d1111d1
2202424444444444444225022252222222222222221172122222222222222222225222222252222222117112d555555d44444444d165561d44444444d165561d
2022244444444444442422222522222222002222252217712222022222002222252222222522222221771622d111111d42424424161111614242442416111161
22242244444444d44422202222222222252202222222212711202222212212222222221122222221171161021665566124242222116666112424222211666611
2222424444444444444222022222022222222222222202117711222215115122222201cc12220117711662221665566142224222116666114222422211666611
250224444944444444242202222020222222005222202022117711115555551222201cccc111177110611652d111111d22022202161111612202220216111161
20202244449444444442225222222222222022222222222222117771555555122221cccccc17711222622625d555555d20500252d165561d20500252d165561d
22222444444444444442022222222222222222222222222222221111755557111111c1cc1c111222221661221dddddd1222222221d1111d1222222221d1111d1
25222444444444444442222222222222222222222222222222222221775577177771c1cc1c122222222662222202025222020252220202522202025222020252
220242444444444444422502225222222222222222222222222222221d11d11111111cddc1522222226116222220252222202522222025222220252222202522
20222444449444d44424222225222222220022222222022222220222210012222522211115222222256226222662266226622662266226622662266226622662
22242244494944444422202222222222252202222220222222202222252202222222222222222222021661026116611661166116611661166116611661166116
22224244444444444442220222220222222222222222222222222222222222222222022222220222222662226226622662266226622662266226622662266226
25022444444444444424220222202022222200522222522222225222222200522220202222202022206116521661166116611661166116611661166116611661
2020224444d444444442225222222222222022222222222222222222222022222222222222222222226226252225022222250222222502222225022222250222
22222444444444444442022222222222222222222222222222222222222222222222222222222222221661222502222225022222250222222502222225022222
25222444444444444442111212122112111221122222111212122222212211121112111211121112122611121212211211122112222222222222222222222222
22024244444449444441ccc1c1c11cc1ccc11cc12221ccc1c1c122221c11ccc1ccc1ccc1ccc1ccc1c161ccc1c1c11cc1ccc11cc1225222222252222222500222
20222444444494444421ccc1c1c1c1121c11c1122221c1c1c1c12221c1c11c11c1c1ccc1c1c11c11c161ccc1c1c1c1121c11c112252222222522222222222052
222422444d4444444421c1c1c1c1ccc11c11c1222221cc11ccc12221c1c11c11ccc1c1c1ccc11c11c111c1c1c1c1ccc11c11c122222222222222222224242222
22224244444444444441c1c1c1c111c11c11c1122221c1c111c10221c1121c11c1c1c1c1c1c11c11c111c1c1c1c111c11c11c112222202222222022222424224
25022444444949d44421c1c11cc1cc11ccc11cc12221ccc1ccc120221cc1cc11c1c1c1c1c1c1ccc1ccc1c1c11cc1cc11ccc11cc1222020222220202224222442
20202244449d9d444442121221121122111221122222111211122222211011221212121212121112111216152112112211122112222222222222222244444444
22222444444444444442022222222222222222222222222222222222222222222222222222222222221661222222222222222222222222222222222244444444
25222444444444444442222222222222222222222222222222222222222222222222222222222222222662222222222222222222222222222222222244444444
22024244444444441141110111511122222111212152222112511121125112211152112122511122126111211152222111222221115012222250022244444444
202224444444444166166616661666122216661616122216611666166116611666116616151666116116161666122216661022166611615222222052449444d4
22242244444444161116161666161122221616161612221616161616161616161616161612216116121616161612221616120221161416122424222249494444
22224244444444161116661616166122221661166612021616166616161616166116161612216116121616161612021666122221661216142242422444444444
25022444444444161616161616161122221616111610201616161616161616161616161611216116101666161610102116121051161216122422244244444444
20202244444444166616161616166612221666166612221616161616161666166616611666116121616161166611612216116116661161444444444444d44444
22222444444444411141012121211122222111211122222121212121212111211121166111621222121611211122122221221221114414444444444444444444
25222444444444442222222222222222222222222222222222222222222222222226666666662222222222222222222222222222444444444444444444444444
22024244444444442220205222500222225002222250022222500222225002222256666566560222225002222250022222500222444444444444494444444444
20222444449444d42502022222222052222220522222205222222052222220522226665555552052222220522222205222222052449444d444449444449444d4
22242244494944442222202224242222242422222424222224242222242422222424666566542222242422222424222224242222494944444d44444449494444
22224244444444442222052222424224224242242242422422424224224242242242422422424224224242242242422422424224444444444444444444444444
2502244444444444422222222422244224222442242224422422244224222442242224422422244224222442242224422422244244444444444949d444444444
2020224444d44444442222224444444444444444444444444444444444444444444444444444444444444444444444444444444444d44444449d9d4444d44444
22222444444444444444222244444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444

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
0002000003040060600b05004140091400d1300812004120001000f70002700077000270006700037000670009700077000f7000b7000f7001b700147001b7001c7001c7001b7001670000000000000000000000
000400000416009160101600314009140101400312009120101200c1001210010100131001510017100051000710007100091000b1000d1000e1000f10004100041000510006100061000710007100091000a100
01100020037500671000550026100475005710207501b710205501b710207501b710207501b310205502071020750206102075020410205500471007750017100575001610037500571000550037100575002710
00100000198601f860268602694026820268402682000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002c9600c950099400993009820099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000200075000710007500071000750007100015000110000500001000750007100015000110007500071000050000100075000710001500011000050000100075000710001500011000750007100055000510
001000000405004030040500403004050040300005000030000500003000050000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008000015b601cb600fb6012b601cb6017b600e0000900006000040000080026a0026a0026a0026a0026a0029a002da0031a0033a0030a0022a0011a000ca0034a0034a0034a0034a0035a0035a0035a0035a00
0008000023a6023a302dd602dd3023d6023d3030e6030e3023e6023e302d9602d9502d9602d9402d9602d93029a0029a0029a0029a0029a0029a0029a0029a0029a002aa002aa002aa002aa002ba002ba002ba00
0002000003540065600b55004740097400d7300872004720001000f70002700077000270006700037000670009700077000f7000b7000f7001b700147001b7001c7001c7001b7001670000000000000000000000
000800000b6601c8300b6401c8300b62000600006000060000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000b8601c9300b8401c9300b82000600006000060000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00080000269601ee20298601ee2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800002c860319502c8402793022820000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800001ae601fe601ae6005f001de00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000003740067600b75004540095400d5300812004120001000f70002700077000270006700037000670009700077000f7000b7000f7001b700147001b7001c7001c7001b7001670000000000000000000000
0004000037960376202b9602b62021960216200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010002000750007100075000710007500071021a5021a10000500001000750007101fa501fa100075000710000500001000750007101fa501fa10000500001000750007101fa501fa1000750007100055000510
0010002000750007100075000710007500071027e5027e100005000010007500071027a5027a1000750007100005000010007500071021a5021a100005000010007500071021a5021a1000750007100055000510
001000000455003530045500453004550045300055000530005500003000050000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000415004630041500463004150046200023000620002100061000050006100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
910b00001314000100131300010013120001001312000100131100010000100001001814000100181300010018120001001812000100181100010000100001001714000100171300010017120001001712000100
910b00001834000000183300000018320000001832000000183100000000000000001c340000001c330000001c320000001c320000001c3100000000000000001a340000001a330000001a320000001a32000000
910b0000090700907000000000000000000000000000000009070090700000000000000000000000000000000907000000090600000009050000000904000000090700907000000000000c0600c0600e0700e070
910b0000171100000000000000001a140000001a130000001a120000001a120000001a11000000000000000018140000001812000000181200000018110000001714000000171200000017120000001711000000
910b00001a3100000000000000002134000000213300000021320000002132000000213100000000000000001f340000001f330000001f320000001f320000001c340000001c330000001c320000001c32000000
910b000000000000000c0700c07009070090700000000000000000000000000000000906009060000000000009070090700906009060090500905000000000000906009060000000000013070130701507015070
910b00002312000000241200000023120241102412023110231202411024130231102313024110241302311023140241102414023110231402411024140231102315024120241502312023150241202415023120
910b0000213100000023310000002132000000233202131021320233102332021310213202331023320213102132023310233302131021330233102333021310213302332023330213202133023320233401f320
910b0000090600906028010000002602000000280202601009060090602802026010260202801028020260100906009060280302601009050090502803026010260302802028030260200c0700c0700e0700e070
910b00002315024120241502312023150241202414023120231402411024140231102314024110241302311023130241102413023110231302411024130000002312000000241200000023120000002412000000
910b00001f34021320213401f3201f32021320213301f3101f33021310213301f3101f33021310213301f3101f33021310213301f3101f3202131021320000001f3200000021320000001f320000002132000000
910b000026040280200c0700c07009070090702803026010260302801028030260100905009050280302601009060090600906009060090600906028020000002602000000280200000013070130701506015060
000b0000090700907000000000000000000000000000000009070090700000000000000000000000000000000904009040090500905009070090700000000000090700907000000000000c0600c0600e0700e070
000b0000171100000000000000001a140000001a130000001a120000001a120000001a11000000000000000018140000001813000000181200000018120000001714000000171300000017120000001712000000
000b00002312000000241202311023120241102412023110231202411024130231102313024110241302311023140241102414023110231402411024140231202315024120241502312023150241202415023120
000b00002315026120261502312023150261202614023120231402612026140231202314026110261302311023130261102613023110231302611026130231102312023110261200000023120000002612000000
000b00002416024160241602416024150241502414024140241302413024120241202316023160231602316023150231502314023140231302313023120231201f1601f1601f1601f1601f1501f1501f1401f140
000b0000133500000018350133201a340183101c3101a310000001c310133400000018340133101a340183101c3301a3101f3401c310133401f31018340133101a330183101c3401a3101f3301c3101c3501f310
000b00001f1301f1301f1201f1201c1601c1601c1601c1601c1501c1501c1401c1401c1301c1301c1201c1201f1601f1601f1601f1601f1501f1501f1401f1401f1301f1301f1201f12000000000000000000000
000b0000133401c31018340133101a320183101c3401a3101f3201c310133401f31018340133101a340183101c3401a3101f3301c310133401f31018340133101a340183101c3401a3101f3301c3101c3501f310
000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000001a120231102b1401a110211302b12024150211101a120241102b1501a1101f1202b120241501f110
000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a1100000000000
000b0000133401c31018340133101a350183101c3501a3101f3301c310133401f31018340133101a330183101c3401a3101f3401c310133301f31018340133101a320183101c3301a3101f3301c3101c3301f310
000b000009070230101f0301a010210301f010230302101009070230101a020260101f0201a010210201f010090702301009070090700907009070230302101000000230101a020260100c0701a0100e0701f010
000b0000231502412023110231201a11000000241602111023150241202b150231201f1202b120241501f11000000241202b12000000000002b12024150000002317024120000002312000000000000000000000
000b0e0000000000000000000000000000000000000000001a12024110000001a110000001a110014000140001400014000140001400014000140001400014000140001400014000140001400014000140001400
000b0000133301c31018340133101a340183101c3501a3101f3301c310133301f31018340133101a340183101c3401a3101f3401c310133401f31018340133101a350183101c3401a3201f3201c3101c3401f310
000b00003016030160301603016030150301503014030140301303013030120301202f1602f1602f1602f1602f1502f1502f1402f1402f1302f1302f1202f1202b1602b1602b1602b1602b1502b1502b1402b140
000b0000133201c31018340133101a340183101c3401a3101f3301c310133401f31018340133101a330183101c3501a3101f3301c310133401f31018340133101a340183101c3501a3101f3301c3101c3401f310
000b00002b1302b1302b1202b1202816028160281602816028150281502814028140281302813028120281202b1602b1602b1602b1602b1502b1502b1402b1402b1302b1302b1202b12000000000000000000000
000b0000133401c31018350133101a350183101c3501a3201f3601c320133401f32018340133101a340183101c3501a3101f3401c310133401f31018340133101a360183101c3401a3201f3301c3101c3401f310
000b000000000000002d15000000211602d110261502111028150261102d150281102116000000261500000021160261102d13021110211602d110261602111028140261202d14028120211602d1102614021110
000b0000133401c31018340133101a340183101c3501a3101f3401c310133401f31018340133101a350183101c3401a3101f3401c310133401f31018340133101a350183101c3401a3101f3301c3101c3401f310
000b0000211300000026140000002d15000000211502d1102614021110211402611028150211102d15028110211602d110281502111021150281102615021110231602611028160231102d15028110281502d160
480b0000133451c31518345133151a345183151c3551a3151f3351c315133451f31518345133151a345183151c3451a3151f3351c315133351f31518345133151a345183151c3551a3151f3151c3151c3551f315
000b0000241602416024150241502415024150241502415023140231402314023140231402314023140231401c1401c1401c1401c1401c1401c1401c1401c1401f1401f1401f1501f1501f1501f1501f1501f150
000b000018350000001d350183201f3401d310213101f310000002131018340000001d340183101f3401d310213301f310243402131018340243101d340183101f3301d310213401f31024330213102135024310
000b00000e0700e0700e0700e0700e0700e0700e0700e0700e0700e0700e0700e07013060130601506015060150601506015060150600e0700e0700e0700e0700e0700e0700e0700e07018070180701306013060
000b000024150241502415024150241502415024150241501f1601f1601f1601f1601f1601f1601f1501f15021150211502116021160211602116021160211602616026160261602616026160261602616026160
000b00001a340233101f3401a310213201f310233402131026320233101a340263101f3401a310213401f310233402131026330233101a340263101f3401a310213401f310233402131026330233102335026310
000b00001007010070100701007010070100701007010070100701007015060150601a0701a0700e0600e0600e0600e0600e0600e0600e0600e0600e0600e0600e0600e0600e0600e0600e0600e0601306013060
010b000018135231051a1251c1051f1352110524115181051f1351a105231151c1052411518105261351a1051c1151f105211152310518145241051a1151f1051c125211052315524105181251a1051f16521105
000b000018340213101d340183101f3501d310213501f310243302131018340243101d340183101f3301d310213401f310243402131018330243101d340183101f3201d310213301f31024330213102133024310
__music__
03 02424344
03 05064744
03 11134344
03 12144344
00 11424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 3e213761
00 3e1a375a
00 1b1d375d
02 1e203760
01 15211661
00 221a195a
00 231d1c5d
02 24201f60
01 25212661
00 271a285a
00 292a2b2c
02 2d2e2f2c
01 30213161
00 321a335a
00 342c356c
00 342c356c
00 383a397a
00 3b3d3c7d
00 3e1d3f80
00 3e1d3f80
00 383a397a
00 3b3d3c7d
00 3e1d3f80
02 3e1d3f80

