class "Evelynn"

function Evelynn:__init()
	self:LoadSpells()
	self:LoadMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Evelynn:LoadSpells()
	Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width }
	W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width }
	E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width }
	R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width }
end
	
function Evelynn:LoadMenu()
	--Main Menu
	self.Menu = MenuElement({type = MENU, id = "Menu", name = "Evelynn"})
	--Main Menu-- Evelynn
	self.Menu:MenuElement({type = MENU, id = "Mode", name = "Revised Evelynn"})
	--Main Menu-- Evelynn -- Combo
	self.Menu.Mode:MenuElement({type = MENU, id = "Combo", name = "Combo"})
	self.Menu.Mode.Combo:MenuElement({id = "Q", name = "Use Q", value = true})
	self.Menu.Mode.Combo:MenuElement({id = "W", name = "Use W if Slowed", value = true})
	self.Menu.Mode.Combo:MenuElement({id = "E", name = "Use E", value = true})
	self.Menu.Mode.Combo:MenuElement({id = "R", name = "Use R", value = true})
	--Main Menu-- Evelynn -- Harass
	self.Menu.Mode:MenuElement({type = MENU, id = "Harass", name = "Harass"})
	self.Menu.Mode.Harass:MenuElement({id = "Q", name = "Use Q", value = true})
	self.Menu.Mode.Harass:MenuElement({id = "W", name = "Use E", value = true})
	self.Menu.Mode.Harass:MenuElement({type = MENU, id = "MM", name = "Mana Manager"})
	self.Menu.Mode.Harass.MM:MenuElement({id = "Mana", name = "Min Mana to Harass(%)", value = 40, min = 0, max = 100, step = 1})
	--Main Menu-- Evelynn -- LaneClear
	self.Menu.Mode:MenuElement({type = MENU, id = "LaneClear", name = "Lane Clear"})
	self.Menu.Mode.LaneClear:MenuElement({id = "Q", name = "Use Q", value = true})
	self.Menu.Mode.LaneClear:MenuElement({id = "E", name = "Use E", value = true})
	self.Menu.Mode.LaneClear:MenuElement({type = MENU, id = "MM", name = "Mana Manager"})
	self.Menu.Mode.LaneClear.MM:MenuElement({id = "Mana", name = "Min Mana to Lane Clear(%)", value = 40, min = 0, max = 100, step = 1})
	--Main Menu-- Evelynn -- JungleClear
	self.Menu.Mode:MenuElement({type = MENU, id = "JungleClear", name = "Jungle Clear"})
	self.Menu.Mode.JungleClear:MenuElement({id = "Q", name = "Use Q", value = true})
	self.Menu.Mode.JungleClear:MenuElement({id = "E", name = "Use E", value = true})
	self.Menu.Mode.JungleClear:MenuElement({type = MENU, id = "MM", name = "Mana Manager"})
	self.Menu.Mode.JungleClear.MM:MenuElement({id = "Mana", name = "Min Mana to Jungle Clear(%)", value = 40, min = 0, max = 100, step = 1})
	--Main Menu-- Evelynn -- Spell Range 
	self.Menu:MenuElement({type = MENU, id = "Drawing", name = "Spell Range"})
	self.Menu.Drawing:MenuElement({id = "R", name = "Draw R Range", value = true})
	self.Menu.Drawing:MenuElement({id = "Width", name = "Width", value = 3, min = 1, max = 5, step = 1})
	self.Menu.Drawing:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 0, 0, 255)})
end

function Evelynn:Tick()
	local Combo = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO]) or (_G.GOS and _G.GOS:GetMode() == "Combo") or (_G.EOWLoaded and EOW:Mode() == "Combo")
	local Clear = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR]) or (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR]) or (_G.GOS and _G.GOS:GetMode() == "Clear") or (_G.EOWLoaded and EOW:Mode() == "LaneClear")
	local Harass = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS]) or (_G.GOS and _G.GOS:GetMode() == "Harass") or (_G.EOWLoaded and EOW:Mode() == "Harass")
	if Combo then
		self:Combo()
	elseif Clear then
		self:Clear()
		self:JClear()
	elseif Harass then
		self:Harass()		
	end
end

function Evelynn:IsSlowed(unit)
    for i = 0, unit.buffCount do
        if unit:GetBuff(i).type == 10 then
            return true
        end
    end
    return false
end

function Evelynn:HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
	local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
		end
	end
	return false
end

function Evelynn:GetValidEnemy(range)
    for i = 1,Game.HeroCount() do
        local enemy = Game.Hero(i)
        if  enemy.team ~= myHero.team and enemy.valid and enemy.pos:DistanceTo(myHero.pos) < Q.range then
            return true
        end
    end
    return false
end

function Evelynn:GetValidMinion(range)
    for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < Q.range then
            return true
        end
    end
    return false
end

function Evelynn:CountEnemyMinions(range)
	local minionsCount = 0
    for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < Q.range then
            minionsCount = minionsCount + 1
        end
    end
    return minionsCount
end

local function Ready(spell) 
  	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end

function Evelynn:isReady (spell)
	return Game.CanUseSpell(spell) == 0 
end

function Evelynn:IsValidTarget(unit,range)
    return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal and unit.pos:DistanceTo(myHero.pos) <= 1500
end

function Evelynn:Combo()

	if self:GetValidEnemy(2500) == false then return end
	
	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
	
	local target =  (_G.SDK and _G.SDK.TargetSelector:GetTarget(1200, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(1200,"AD")) or ( _G.EOWLoaded and EOW:GetTarget())
		
	    if self:IsValidTarget(target,Q.range*1.9) and self.Menu.Mode.Combo.Q:Value() and self:isReady(_Q) then
			Control.CastSpell(HK_Q,target)
	    end 	
	    
	    if self:IsValidTarget(target,R.range) and self:IsSlowed(myHero) and self.Menu.Mode.Combo.W:Value() and self:isReady(_W) then
			Control.CastSpell(HK_W)
	    end

		if self:IsValidTarget(target,E.range*0.9) and self.Menu.Mode.Combo.E:Value() and self:isReady(_E) and myHero.attackData.state == STATE_WINDDOWN  then
			Control.CastSpell(HK_E,target)
	    end

		if self:IsValidTarget(target,R.range) and self.Menu.Mode.Combo.R:Value() and self:isReady(_R) then
					Control.CastSpell(HK_R,target:GetPrediction(R.speed, R.delay))
			end
end


function Evelynn:Harass()

	if self:GetValidEnemy(Q.range) == false then return end
	
	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
	
	local target =  (_G.SDK and _G.SDK.TargetSelector:GetTarget(Q.target, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(Q.target,"AD")) or ( _G.EOWLoaded and EOW:GetTarget())
		
	    if self:IsValidTarget(target,Q.range) and (myHero.mana/myHero.maxMana >= self.Menu.Mode.Harass.MM.Mana:Value() / 100) and self.Menu.Mode.Harass.Q:Value() and self:isReady(_Q) and not myHero.isChanneling  then
			Control.CastSpell(HK_Q,target)
		end
		if self:IsValidTarget(target,E.range) and (myHero.mana/myHero.maxMana >= self.Menu.Mode.Harass.MM.Mana:Value() / 100) and self.Menu.Mode.Harass.W:Value() and self:isReady(_E) and not myHero.isChanneling  then
			Control.CastSpell(HK_E,target)
		end
end

function Evelynn:Clear()

	if self:GetValidMinion(Q.range) == false then return end
	
		for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  minion.team == 200 then
			if self:IsValidTarget(minion,Q.range) and (myHero.mana/myHero.maxMana >= self.Menu.Mode.LaneClear.MM.Mana:Value() / 100) and self.Menu.Mode.LaneClear.Q:Value() and self:isReady(_Q) then
					Control.CastSpell(HK_Q,target)
				break
			end
			if self:IsValidTarget(minion,E.range) and (myHero.mana/myHero.maxMana >= self.Menu.Mode.LaneClear.MM.Mana:Value() / 100) and self.Menu.Mode.LaneClear.E:Value() and self:isReady(_E) then
					Control.CastSpell(HK_E,target)
				break
			end
		end
	end
end

function Evelynn:JClear()

	if self:GetValidMinion(Q.range) == false then return end
	
		for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  minion.team == 300 then
			if self:IsValidTarget(minion,Q.range) and (myHero.mana/myHero.maxMana >= self.Menu.Mode.JungleClear.MM.Mana:Value() / 100) and self.Menu.Mode.JungleClear.Q:Value() and self:isReady(_Q) then
					Control.CastSpell(HK_Q,target)
				break
			end
			if self:IsValidTarget(minion,E.range) and (myHero.mana/myHero.maxMana >= self.Menu.Mode.JungleClear.MM.Mana:Value() / 100) and self.Menu.Mode.JungleClear.E:Value() and self:isReady(_E) then
					Control.CastSpell(HK_E,target)
				break
			end
		end
	end
end

function Evelynn:HpPred(unit, delay)
	if _G.GOS then
		hp =  GOS:HP_Pred(unit,delay)
	else
		hp = unit.health
	end
	return hp
end


function Evelynn:Draw()
	if myHero.dead then return end
		if self.Menu.Drawing.R:Value() then Draw.Circle(myHero.pos, R.range, self.Menu.Drawing.Width:Value(), self.Menu.Drawing.Color:Value())	
		end	
end


function OnLoad()
	if myHero.charName ~= "Evelynn" then return end
	Evelynn()
end

	
