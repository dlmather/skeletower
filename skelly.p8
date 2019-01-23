pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- skelly tower
-- by dave and elaine

mapx_off=0

p1=
{
	--position
	x=8,
	y=104,
	--velocity
	dx=0,
	dy=0,
	--is the player standing on
	--the ground. used to determine
	--if they can jump.
	isgrounded=false,
	--direction player is facing
	left=false,
	--tuning constants
    walkspeed=2,
	jumpvel=3.4,
    --health
    hp=10,
    cash=0,
}

canons={}

statics={}

projectiles={}

enemies={}

--globals
g=
{
  grav=0.2, -- gravity per frame
}

t=0

-- physics
function checkhoriz(e, start_x, x_off, y_off)
    if x_off==nil then x_off = 7 end
    if y_off==nil then y_off = 7 end
	if e.dx<0 then x_off=7-x_off end
	--look for a wall
    local xmove=(e.x+x_off)/8
	local h=mget(xmove,(e.y+y_off)/8)
    if fget(h,0) then
        e.x=start_x
        return true
    end
    return false
end

function checkvert(e, y_off)
    if y_off == nil then y_off = 0 end
	--check bottom center.
	local v=mget((e.x+4)/8,(e.y+8-y_off)/8)
	
	--assume floating 
	e.isgrounded=false
	
	--only check for floors when
	--moving downward
	if e.dy>=0 and (fget(v,0) or fget(v,1)) then
		--place e on top of tile
		e.y = flr((e.y)/8)*8 + y_off
		--halt velocity
		e.dy = 0
		--allow jumping again
		e.isgrounded=true
	end
	
	--hit ceiling
	--check top center of e
	v=mget((e.x+4)/8,(e.y+y_off)/8)
	
	--only check for ceilings when
	--moving up
	if e.dy<=0 and fget(v,0) then
		--position e right below
		--ceiling
		e.y = flr((e.y+8)/8)*8 - y_off
		--halt upward velocity
		e.dy = 0
	end
end

-- end physics

-- gui

function playerstats()
    print("health:"..tostr(p1.hp), mapx_off, 122, 8)
    print("cash:"..tostr(p1.cash), mapx_off+64, 122, 9)
end

-- end gui

-- player
function playerctrl()
    if (btnp(2)) and p1.isgrounded then
        --launch the player upwards
		p1.dy=-p1.jumpvel
        sfx(1)
	end
    if (btnp(3)) then
        checkpurchase(p1)
    end
	--walk
	p1.dx=0
	if btn(0) then --left
		p1.dx-=p1.walkspeed
		p1.left=true
	end
	if btn(1) then --right
		p1.dx+=p1.walkspeed
		p1.left=false
	end
    if btnp(4) then
        local dx=1
        if p1.left then
            dx=-1
        end
        add(projectiles, arrow(p1.x, p1.y, dx))
        sfx(0)
    end
end

function checkpurchase(e)
    for i=-2,2 do
        local xmove=(e.x+(7*i))/8
        local ymove=(e.y+7)/8
        local s=mget(xmove,ymove)
        if fget(s, 2) then
            mset(xmove, ymove, 6)
            add(canons, canon(flr(xmove)*8+8,flr(ymove)*8))
            p1.cash-=1
            return
        end
    end
end

function arrow(x, y, dx)
    return {
        x=x + 4*dx,
        y=y,
        dx=dx,
        dist=64,
        dmg=1,
        animation={
            static_player(frame(9, 0, 4*dx)),
        },
    }
end

function canon(x, y, fire_rate) 
    return {
        x=x,
        y=y,
        spawn=t,
        firerate=90,
        attack_anim=animation({
            frame(19, 8, 8, -1),
        }),
        animation={
            static_player(frame(17, 0, -8, 0, 2, 1)),
        },
    }
end

function playermove()
    local startx = p1.x
    p1.x+=p1.dx
    checkhoriz(p1, startx, 6)
    for s in all(statics) do
        if p1.x >= s.x and p1.x <= s.x + 7 and
        p1.y >= s.y and p1.y <= s.y + 7 then
            sfx(6)
            p1.cash+=1
            del(statics, s)
        end
    end
	--accumulate gravity
	p1.dy+=g.grav
	--fall
	p1.y+=p1.dy
    checkvert(p1)
    if p1.x > mapx_off + 127 then
        mapx_off += 128
    elseif p1.x < mapx_off then
        mapx_off -= 128
    end
end

function checkgameover()
    if p1.hp <= 0 then
        sfx(3)
        gameover=true
    end
end

-- end player

-- enemy

function spawn(wave)
    local e = wave[t]
    if e != nil then
        add(enemies, e)
    end
end

function enemyattack(e, p)
    p.hp-=e.dmg
    if p.dx != nil then p.dx-=10 end
    if p.dy != nil then p.dy-=1 end
    if e.attack_anim != nil then
        add_anim(e, anim_player(e.attack_anim))
    end
end

function enemyctrl()
    for e in all(enemies) do
        local sizefactor =8*e.size - 1
        if p1.x >= e.x and p1.x <= e.x + sizefactor and
        p1.y >= e.y and p1.y <= e.y + sizefactor then
            enemyattack(e, p1)
        end
        for p in all(projectiles) do
            if p.x >= e.x and p.x <= e.x + sizefactor and
               p.y >= e.y and p.y <= e.y + sizefactor then
                e.hp-=p.dmg
                e.x+=p.dx
                del(projectiles, p)
                if e.hp<=0 then
                    del(enemies, e)
                    sfx(5)
                    if e.drop < rnd(1) then
                        add(statics, {x=e.x,y=e.y + 8*(e.size-1)})
                    end
                else
                    sfx(4)
                end
            end
        end
        local startx=e.x
        e.x+=e.dx
        local collide=checkhoriz(e,startx)
        if collide then
            del(enemies, e)
            sfx(5)
        end
    end
end

function enemybear()
    return {
        x=200,
        y=96,
        hp=16,
        dx=-0.25, 
        size=2,
        dmg=2,
        drop=0.5,
        animation={
            anim_player(animation({
                frame(11, 4, 0, 0, 2, 2),
                frame(13, 2, 0, 0, 2, 2),
            }, true)),
        },
    }
end

function enemyknight()
    local attack=animation({
        frame(39, 3, -2, -2),
        frame(40, 3, -6, -2),
        frame(41, 8, -6),
    })
    local walk=animation({
        frame(42, 2),
        frame(43, 2),
    }, true)
    local k = {
        x=200,
        y=104,
        hp=6,
        dx=-0.5, 
        spr={42,43},
        size=1,
        dmg=1,
        drop=0.5,
        attack_anim=attack,
    }
    add_anim(k, anim_player(walk))
    return k
end

-- end enemy

-- ballistics 

function canonball(c)
    return {
        x=c.x+4,
        y=c.y,
        dx=2,
        dy=-0.5,
        dist=128,
        dmg=5,
        reflect=true,
        animation={
            anim_player(animation({
                frame(20, 4, 0, 0, 1, 1),
                frame(20, 4, 0, 0, 1, 1, true),
                frame(20, 4, 0, 0, 1, 1, true, true),
                frame(20, 4, 0, 0, 1, 1, false, true),
            }, true)),
        },
    }
end

function projectilectrl()
    for c in all(canons) do
        if ((t - c.spawn+ 1) % c.firerate)==0 and #enemies > 0 then
            sfx(7)
            add(projectiles, canonball(c))
            add_anim(c, anim_player(c.attack_anim))
        end
    end
    for p in all(projectiles) do
        local distdecay=1
        if p.dy != nil then
            p.dy+=g.grav
            p.y+=p.dy
            checkvert(p,1)
            if p.isgrounded then
                distdecay=1.2
            end
        end
        local startx=p.x
        p.x+=p.dx
        local collide=checkhoriz(p,startx,6,6)
        if collide then
            if p.reflect != nil then
                p.dist-=20
                p.dx=-p.dx
            else
                del(projectiles,p)
            end
        end
        p.dist-=abs(p.dx)*distdecay
        if p.dist <= 0 then
            del(projectiles,p)
        end
    end
end

-- end ballistics

-- animation

function frame(spr, t, x, y, size_x, size_y, flip_x, flip_y)
    if x==nil then x=0 end
    if y==nil then y=0 end
    if size_x==nil then size_x=1 end
    if size_y==nil then size_y=1 end
    if flip_x==nil then flip_x=false end
    if flip_y==nil then flip_y=false end
    return {
        spr=spr,
        t=t,
        x=x,
        y=y,
        size_x=size_x,
        size_y=size_y,
        flip_x=flip_x,
        flip_y=flip_y,
    }
end

function animation(frames, replay) 
    if replay==nil then replay = false end
    return {
        frames=frames,
        replay=replay,
    }
end

function add_anim(e, anim)
    if e.animation==nil then e.animation={} end
    add(e.animation, anim)
end

function static_player(f) 
    return function(t, rel_x, rel_y)
        spr(f.spr, f.x+rel_x, f.y+rel_y, f.size_x, f.size_y, f.flip_x, f.flip_y)
        return false
    end
end

function anim_player(animation)
    local elapsed = 0
    local idx = 1
    local time = t
    return function(t, rel_x, rel_y) 
        local dt = t - time
        time = t
        local f = animation.frames[idx]
        elapsed += dt 
        if elapsed >= f.t then
            idx += 1
            elapsed -= f.t
        end
        if idx > #animation.frames then
            if animation.replay then
                idx = 1
            else
                return true
            end
        end
        spr(f.spr, f.x+rel_x, f.y+rel_y, f.size_x, f.size_y, f.flip_x, f.flip_y)
        return false
    end
end

-- TODO? Pixel setting as frame option?

-- end animation

-- reserved methods

function _update()
    if gameover then
        return
    end
    t+=1
    wave1={}
    for i=1,10 do
        wave1[60*i]=enemyknight()
        wave1[68*i]=enemybear()
    end
    spawn(wave1)
    playerctrl()
    enemyctrl()
    projectilectrl()
    playermove()
    checkgameover()
end

function draw(e) 
    for anim in all(e.animation) do
        done = anim(t, e.x, e.y)
        if done then del(e.animation, anim) end
    end
end

function _draw()
    cls() --clear the screen
    camera(mapx_off)
    if gameover then
        camera()
        print("game over", 32, 64, 7)
        return
    end
    map(0,0,0,0,128,128) --draw map
    for p in all(projectiles) do
        draw(p)
    end
    for c in all(canons) do
        draw(c)
    end
    for e in all(enemies) do
        draw(e)
    end
    spr(1,p1.x,p1.y,1,1,p1.left) --draw player
    for s in all(statics) do
        spr(15,s.x,s.y)
    end
    playerstats()
end

-- end reserved methods













__gfx__
000000000077770033333333333333334644446444444444ddd0ddd044444444ddd66dd000000000ddd0ddd00000000000000000000000000000000000000000
00000000007575003b333333333b3333644444466444444600000000400000040005500000000000000000000000000040000000000000004000000000000000
0000000000775700333333b3333333b3444444440ddd0ddd0ddd0ddd400001840d5555dd070000700555555d0000044440400000000004444040000000000000
00000000001770003333333333333333444444440000000000000000480a01840555555000777700050000500554448844400000055444884440000000000000
000000000011800033333333b333333344444444ddd0ddd0ddd0ddd048cac1845555555507000070544444450554448844400000055444884440000000000000
0000000000118100444444444444444444444444000000000000000048cac184d9aaaa9000000000445555440444444444400000044444444440000000000000
00000000007770004444444444444444644444460ddd0ddd0ddd0ddd444444440d9aa9dd00000000444444440704444444400000070444444440000000000000
0000000000707000444444444444444446444464000000000000000040000004000aa00000000000566666650007044444400000000704444440000000999900
ddd0ddd00440000000000000000670000000000099999999cccccccc777777770009900000000000ddd0ddd00000044444400000000004444440000000000000
000000003444000050000055077777700055550099999999cccccccc7777777700999900000000000555555d0000044444400000000004444440000000000000
0ddd0ddd3333000550005555076676670565555099999999cccccccc777777770995999000000000566666650044444444400000004444444440000000000000
044004400383330555555555776767770555555099999999cccccccc7777777799555599000000006666666600400fff4440000000400fff4440000000000000
dd4444d00333300555555555777677700555555099999999cccccccc7777777795955959000000006666666600000fff4444000000000fff4444000000000000
044444400037700444555555007667000555555099999999cccccccc77777777095595900000000044555544000004ff44440000000004ff4444000000000000
04bbbb4d0f433b4444400055077770000055550099999999cccccccc777777770099990000000000444444440000044444400000000004444440000000000000
044444400444bb4544444000000000000000000099999999cccccccc777777770009900000000000566666650000440000400000000004000440000000000000
77777777000000000000800088888888000000000000000077cccc77000600000000000000000000000008000000080000000000000000000000000000000000
4444444400555500080088008888888800000000000000007cccccc7000600000600000000000000006560000065600000000000000000000000000000000000
0dd44ddd056555500008a800555555550000000000000000cccccccc000600000060000000000000005560000055600000000000000000000000000000000000
0004400005555550008aa808555555550000000000000000ccc7cccc000600000006005000005000006560000065600000000000000000000000000000000000
ddd44dd00555555008a9a980555555550000000000000000cc7cc7cc050605000000605000000500000a5300000a530000000000000000000000000000000000
0004400005555550089aa980444444440000000000000000cccc7ccc00595000000009006666695900f553000006530000000000000000000000000000000000
0dd55ddd00555500089c99804444444400000000000000007cccccc7000500000005505000000500000660300006f03000000000000000000000000000000000
44400444000000000089980044444444000000000000000077cccc77000900000000000900005000005050000005500000000000000000000000000000000000
__gff__
0000010101020000000004000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0404040404040416161617171716171716161616161616161616161616161602000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0406080606060416161717171717171717171616161616161616161616161602000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0406262626060416161617171717171717171616151616161716161616161602000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0406262626060a16161617171716161616161616161617171717171616161602000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0406060605050416161616161616161616161616161617171717161616161602000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0426262626060416161616161616161616161616161616171716161616161602000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0407060606060416161616161616161616161616161616161616161616161602000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0405050506060416161616161616161616161616161616161616161616161602000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0408060706060a16161616161616161616161616161616161616161616161602000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0406060505050416161616161616161616161616161616161616161616161602000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0406060606060416161616161616161616161616161616161616161616161602000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0405060606060816161616161616161616161616161616161616161616161602000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0410050606060616161616161616161616161616161616161616161616161602000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0420060506060616161616161616161616161616161616161616161616161602000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232302020302030202030302020202020202020202020202020202000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0107010128053270002b00024000270002b0000c0001100024000270002b00024000270002b0000c0001100024000270002b00024000270002b0000c0001100024000270002b00024000270002b0000c00011000
011000000c1520c10218102391023c10239102181022b102181023910218102391023c102301023910239102181023910218102391023c102391021810221102181023910218102391023c102391023910239102
011000001905619056190561a0561d0562005624056280562b0002e0001800013000110001000010000100000c0000c000270000b0000b0000b0000b0000b0000c0000d0000e0000e0000f0000f0000000000000
011000000c0560d0560e0560e0560f0500f050003000c00000100180000c00018000001000c000003000c000051001100005300110000c10018000003000c0000a100160000a30016000111001d000113001d000
011800000017300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103
011000000c170101702710029100291002910024100271002e1002b1002b1002b1002910027100291002b100301002e1002e1002b100301002e10000100001000010000100001000010000100001000010000100
010a00003055030500295002e7002b700277002700027500297002b000295002770024000275001b4001b5001b5001b4001d500295001d4002950024400245002450024400275002750029400295000000000000
0110000000373003030030300303003030030300303003030030300303003030030300303003030030300303113031d303113031d303133031f303133031f3030f3031b3030f3031b30316303223031630322303
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002e775000002e1752e075000002e1752e77500000
__music__
00 02040248
00 00040108
00 00010304
00 00010304
01 00010203
00 00010203
00 00010305
00 00010306
00 00010305
00 00010306
00 00010245
02 00010243

