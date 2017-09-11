class "Katarina"

function Katarina:__init()
	self:LoadSpells()
	self:LoadMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Katarina:LoadSpells()
	Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width }
	W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width }
	E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width }
	R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width }
end
	
function Katarina:LoadMenu()
	--Main Menu
	self.Menu = MenuElement({type = MENU, id = "Menu", name = "Katarina"})
	--Main Menu-- Katarina
	self.Menu:MenuElement({type = MENU, id = "Mode", name = "Kharneth's Katarina"})
	--Main Menu-- Katarina -- Combo
	self.Menu.Mode:MenuElement({type = MENU, id = "Combo", name = "Combo"})
	self.Menu.Mode.Combo:MenuElement({id = "Q", name = "Use Q", value = true})
	self.Menu.Mode.Combo:MenuElement({id = "W", name = "Use W", value = true})
	self.Menu.Mode.Combo:MenuElement({id = "E", name = "Use E", value = true})
	self.Menu.Mode.Combo:MenuElement({id = "R", name = "Use R", value = true})
	--Main Menu-- Katarina -- Harass
	self.Menu.Mode:MenuElement({type = MENU, id = "Harass", name = "Harass"})
	self.Menu.Mode.Harass:MenuElement({id = "Q", name = "Use Q", value = true})
	self.Menu.Mode.Harass:MenuElement({id = "W", name = "Use W", value = true})
	self.Menu.Mode.Harass:MenuElement({id = "E", name = "Use E", value = true})	

end

function Katarina:Tick()
	local Combo = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO]) or (_G.GOS and _G.GOS:GetMode() == "Combo") or (_G.EOWLoaded and EOW:Mode() == "Combo")
	local Clear = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR]) or (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR]) or (_G.GOS and _G.GOS:GetMode() == "Clear") or (_G.EOWLoaded and EOW:Mode() == "LaneClear")
	local Harass = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS]) or (_G.GOS and _G.GOS:GetMode() == "Harass") or (_G.EOWLoaded and EOW:Mode() == "Harass")
	if Combo then
		self:Combo()
	elseif Harass then
		self:Harass()		
	end

function Katarina:HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
	local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true		end
	end
	return false
end
 
function Katarina:GetValidEnemy(range)
    for i = 1,Game.HeroCount() do
        local enemy = Game.Hero(i)
        if  enemy.team ~= myHero.team and enemy.valid and enemy.pos:DistanceTo(myHero.pos) < Q.range then
            return true
        end
    end
    return false
end

function Katarina:GetValidMinion(range)
    for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < Q.range then
            return true
        end
    end
    return false
end

function Katarina:CountEnemyMinions(range)
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

function Katarina:isReady (spell)
	return Game.CanUseSpell(spell) == 0 
end

function Katarina:IsValidTarget(unit,range)
    return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal and unit.pos:DistanceTo(myHero.pos) <= 1500
end

function Katarina:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end
    if myHero.activeSpell.isChanneling == true then return end
	if self.Menu.HarassMode.harassActive:Value() and self:EnemyInRange(1200) then
		self:Harass()
	end
	if self.Menu.ComboMode.comboActive:Value() and self:EnemyInRange(1200) then
		self:Combo()
	end
	if self.Menu.ClearMode.clearActive:Value() then
		self:Jungle()
	end

end

efunction Katarina:Combo()
	if self:GetValidEnemy(2500) == false then return end
	
	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
	
	local target =  (_G.SDK and _G.SDK.TargetSelector:GetTarget(1200, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(1200,"AD")) or ( _G.EOWLoaded and EOW:GetTarget())
		
	    if self:IsValidTarget(target,Q.range >625) and self.Menu.Mode.Combo.Q:Value() and self:isReady(_Q) then
			Control.CastSpell(HK_Q,target)
	    end 	

	    if self:IsValidTarget(target,E.range >725) and self.Menu.Mode.Combo.E:Value() and self:isReady(_E) and myHero.attackData.state == STATE_WINDDOWN  then
			Control.CastSpell(HK_E,target)
	    end

            if self:IsValidTarget(target,W.range*.0) and self.Menu.Mode.Combo.E:Value() and self:isReady(_E) and myHero.attackData.state == STATE_WINDDOWN  then
			Control.CastSpell(HK_E,target)
            end

	    if self:CanCast(_R) and self:EnemyInRange(R.Range) then 
		local RTarget = CurrentTarget(R.Range)
		if self.Menu.ComboMode.UseR:Value() and RTarget then
			local RDamage = (self:CanCast(_R) and getdmg("R",RTarget,myHero) or 0)
			if Game.Timer() - LastR > 5 and myHero.pos:DistanceTo(RTarget.pos) < 350 and RTarget.health/RTarget.maxHealth < .40 then
				Control.CastSpell(HK_R)
			end
		end
	end

function Katarina:Harass()
	if self:GetValidEnemy(Q.range) == false then return end
	
	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
	
	local target =  (_G.SDK and _G.SDK.TargetSelector:GetTarget(Q.target, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(Q.target,"AD")) or ( _G.EOWLoaded and EOW:GetTarget())
		
	    if self:IsValidTarget(target,Q.range) and self.Menu.Mode.Harass.Q:Value() and self:isReady(_Q) and not myHero.isChanneling  then
			Control.CastSpell(HK_Q,target)
		end
		if self:IsValidTarget(target,E.range) and self.Menu.Mode.Harass.E:Value() and self:isReady(_E) and not myHero.isChanneling  then
			Control.CastSpell(HK_E,target)
		end
end

function Katarina:HpPred(unit, delay)
	if _G.GOS then
		hp =  GOS:HP_Pred(unit,delay)
	else
		hp = unit.health
	end
	return hp
end

function OnLoad()
	if myHero.charName ~= "Katarina" then return end
	Katarina()
end
end
