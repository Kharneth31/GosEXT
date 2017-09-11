if myHero.charName ~= "Katarina" then return end

require("DamageLib")

class "Katarina"
local Spin = false
local daggerPos = {}

--Int

function OnLoad()
    Katarina()
end

local Spells = {
		Q = {range = 625},
		W = {},
		E = {range = 725},
		R = {range = 550},
		P = {range = 340}
	}

function Katarina:__init()
	self:Menu()
	Callback.Add("Tick", function() self:Tick() end)
	PrintChat("Katarina : Loaded")
end

function Katarina:Menu()
	Menu = MenuElement({type = MENU, id = "Kharneth's Katarina", name = "Katarina"})

	Menu:MenuElement({type = MENU, id = "Combo", name = "[Combo Manager]"})
	Menu.Combo:MenuElement({id = "Q", name = "Use Q", value = true})
	Menu.Combo:MenuElement({id = "W", name = "Use W", value = true})
	Menu.Combo:MenuElement({id = "E", name = "Use E", value = true})
	Menu.Combo:MenuElement({id = "R", name = "Use R", value = true})
	Menu.Combo:MenuElement({id = "Hex", name = "Use Hextech", value = true})

	Menu:MenuElement({type = MENU, id = "Harass", name = "[Harass Manager]"})
	Menu.Harass:MenuElement({id = "Q", name = "Use Q", value = true})
	Menu.Harass:MenuElement({id = "W", name = "Use W", value = true})
	Menu.Harass:MenuElement({id = "E", name = "Use E", value = false})
	Menu.Harass:MenuElement({id = "Disabled", name = "Disable All", value = false})

	Menu:MenuElement({type = MENU, id = "Ks", name = "[KS Manager]"})
	Menu.Ks:MenuElement({id = "Q", name = "Use Q", value = true})
	Menu.Ks:MenuElement({id = "W", name = "Use W", value = true})
	Menu.Ks:MenuElement({id = "E", name = "Use E", value = true})
	Menu.Ks:MenuElement({id = "R", name = "Use R", value = false})
	if myHero:GetSpellData(4).name == "SummonerDot" or myHero:GetSpellData(5).name == "SummonerDot" then
		Menu.Ks:MenuElement({id = "UseIgn", name = "Use Ignite", value = false})
	end
	Menu.Ks:MenuElement({id = "Recall", name = "Disable During Recall", value = true})
	Menu.Ks:MenuElement({id = "Disabled", name = "Disable All", value = false})


	Menu:MenuElement({type = MENU, id = "Misc", name = "[Misc Settings]"})
	Menu.Misc:MenuElement({id = "R", name = "R Max range", value = 450, min = 0, max = 550})
end
local function GetClosestAllyHero(pos,range)
	local closest
	for i=1,Game.HeroCount() do
		local hero=Game.Hero(i)
		if hero.isAlly and not hero.dead and not hero.isImmortal and not hero.isMe then
			if pos:DistanceTo(Vector(hero.pos))<=range then
				if closest then
					if pos:DistanceTo(Vector(hero.pos))<pos:DistanceTo(Vector(closest.pos)) then
						closest=hero
					end
				else closest=hero end
			end
		end
	end
	return closest
end
local function GetClosestAllyMinion(pos,range)
	local closest
	for i=1,Game.MinionCount() do
		local minion=Game.Minion(i)
		if minion.isAlly and not minion.dead and not minion.isImmortal then
			if pos:DistanceTo(Vector(minion.pos))<=range then
				if closest then
					if pos:DistanceTo(Vector(minion.pos))<pos:DistanceTo(Vector(closest.pos)) then
						closest=minion
					end
				else closest=minion end
			end
		end
	end
	return closest
end
function Katarina:Tick()
	if myHero.dead or self:CheckR() or spin == true then return end
	self:DaggerAdd()
	self:DaggerRemove()
	self:CheckR()
	self:KillSteal()
	local target=_G.SDK.TargetSelector:GetTarget(800)
	if target and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then   
            self:Combo(target)
	elseif target and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then 
		self:Harass()
	elseif target and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then 
		self:Flee()
	end
end

function Katarina:DaggerAdd()
	for u = 1, Game.ParticleCount() do
		local particle = Game.Particle(u)
		if particle and particle.name == "Katarina_Base_W_Indicator_Ally.troy" then
			local found = false
			for i=1,#daggerPos do
				if daggerPos[i] == particle.pos then
					found = true
				end
			end
			if found == false then
				table.insert(daggerPos, particle.pos)
			end
		end
	end
end

function Katarina:DaggerRemove()
	for i=1,#daggerPos do
		local found = false
		for u = 1, Game.ParticleCount() do
			local particle = Game.Particle(u)
			if particle and particle.name == "Katarina_Base_W_Indicator_Ally.troy" then
				if daggerPos[i] == particle.pos then
					found = true
				end
			end
		end
		if found == false then
			table.remove(daggerPos, i)
		end
	end
end

function Katarina:CheckR()
	local found = false
		if Spin == true then
			for K, Enemy in pairs(self:GetEnemyHeroes()) do
				if self:IsValidTarget(Enemy, Spells.R.range, false, myHero.pos) then
					found = true
				end
			end
		end
	if found == false and Spin then
		self:EnableEOW()
		Spin = false
	end
end
function Katarina:Flee()

end
function Katarina:KillSteal()
	if  Menu.Ks.Disabled:Value() or (self:IsRecalling() and Menu.Ks.Recall:Value()) or Spin then return end
	for K, Enemy in pairs(self:GetEnemyHeroes()) do
		if Menu.Ks.Q:Value() and self:IsReady(_Q) and self:IsValidTarget(Enemy, Spells.Q.range, false, myHero.pos) then
			if getdmg("Q", Enemy, myHero) > Enemy.health then
				self:CastQ(Enemy)
			end
		end
		if Menu.Ks.Q:Value() and Menu.Ks.E:Value() and self:IsReady(_Q) and self:IsReady(_E) and self:IsValidTarget(Enemy, Spells.Q.range + Spells.E.range, false, myHero.pos) then
			if getdmg("Q", Enemy, myHero) > Enemy.health then
				self:EKS(Enemy)
			end
		end
		if Menu.Ks.E:Value() and self:IsReady(_E) and self:IsValidTarget(Enemy, Spells.E.range, false, myHero.pos) then
			if getdmg("E", Enemy, myHero) > Enemy.health then
				self:CastE(Enemy)
			end
		end

		if myHero:GetSpellData(5).name == "SummonerDot" and Menu.Ks.UseIgn:Value() and self:IsReady(SUMMONER_2) then
			if self:IsValidTarget(Enemy, 600, false, myHero.pos) and Enemy.health + Enemy.hpRegen*2.5 + Enemy.shieldAD < 50 + 20*myHero.levelData.lvl then
				Control.CastSpell(HK_SUMMONER_2, Enemy)
			end
		end
		if myHero:GetSpellData(4).name == "SummonerDot" and Menu.Ks.UseIgn:Value() and self:IsReady(SUMMONER_1) then
			if self:IsValidTarget(Enemy, 600, false, myHero.pos) and Enemy.health + Enemy.hpRegen*2.5 + Enemy.shieldAD < 50 + 20*myHero.levelData.lvl then
				Control.CastSpell(HK_SUMMONER_1, Enemy)
			end
		end
	end
end

function Katarina:EKS(target)
	for K, Enemy in pairs(self:GetEnemyHeroes()) do
		if self:IsValidTarget(Enemy, Spells.E.range, false, myHero.pos) and Enemy.pos:DistanceTo(target.pos) < Spells.Q.range then
			self:CastE(Enemy) return
		end
	end
	for K, Ally in pairs(self:GetAllyHeroes()) do
		if self:IsValidTarget(Ally, Spells.E.range, false, myHero.pos) and Ally.pos:DistanceTo(target.pos) < Spells.Q.range then
			self:CastE(Ally) return
		end
	end
	for K, Minion in pairs(self:GetMinions(Spells.E.range)) do
		if self:IsValidTarget(Minion, Spells.E.range, false, myHero.pos) and Minion.pos:DistanceTo(target.pos) < Spells.Q.range then
			self:CastE(Minion) return
		end
	end
end

function  Katarina:DisableEOW()
	_G.SDK.Orbwalker:SetAttack(false)

	_G.SDK.Orbwalker:SetMovement(false)
end

function  Katarina:EnableEOW()
	_G.SDK.Orbwalker:SetMovement(true)
	_G.SDK.Orbwalker:SetAttack(true)
end

function Katarina:CastQ(target)
	Control.CastSpell(HK_Q, target)
end

function Katarina:CastW()
	Control.CastSpell(HK_W)
end

function Katarina:CastE(target)
	Control.CastSpell(HK_E, target)
eend

function Katarina:CastR()
	Spin = true
	self:DisableEOW()
	Control.CastSpell(HK_R)
	DelayAction(function() Spin = false self:EnableEOW() end, 2.5)
end

function bulkKata:NormalCombo(target)

end
	
		if Menu.Combo.Qlocal target = self:GetTarget(Spells.Q.range)
		if target ~= nil and self:IsValidTarget(target, Spells.Q.range, false, myHero.pos) then
			self:CastQ(target)
                end

        elseif Menu.Combo.E:Value() and self:IsReady(_E) then
		for i=1,#daggerPos do
			for i, Enemy in pairs(self:GetEnemyHeroes()) do
				if self:IsValidTarget(Enemy, Spells.E.range + Spells.P.range, false, myHero.pos) and self:IsValidTarget(Enemy, Spells.P.range, false, daggerPos[i]) then
					self:CastE(daggerPos[i])
				end
			end
		end
	elseif Menu.Combo.E:Value() and self:IsReady(_E) then
		local target = self:GetTarget(Spells.E.range)
		if self:IsValidTarget(target, Spells.E.range, false, myHero.pos)then
			Control.CastSpell(HK_E,target)

	elseif Menu.Combo.W:Value() and self:IsReady(_W) then
		local target = self:GetTarget(Spells.P.range)
		if target ~= nil and self:IsValidTarget(target, Spells.P.range, false, myHero.pos) then
			self:CastW()
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
end
function Katarina:Harass()
	if Menu.Harass.Disabled:Value() then return end
	if Menu.Harass.E:Value() and self:IsReady(_E) and not Spin then
		for i=1,#daggerPos do
			for i, Enemy in pairs(self:GetEnemyHeroes()) do
				if self:IsValidTarget(Enemy, Spells.E.range + Spells.P.range, false, myHero.pos) and self:IsValidTarget(Enemy, Spells.P.range, false, daggerPos[i]) then
					self:CastE(daggerPos[i])
				end
			end
		end
	end
	if Menu.Harass.E:Value() and self:IsReady(_E) then
		local target = self:GetTarget(Spells.E.range)
		if target ~= nil and self:IsValidTarget(target, Spells.E.range, false, myHero.pos)then
			self:CastE(target)
		end
	end
	if Menu.Harass.W:Value() and self:IsReady(_W) then
		local target = self:GetTarget(Spells.P.range)
		if target ~= nil and self:IsValidTarget(target, Spells.P.range, false, myHero.pos) then
			self:CastW()
		end
	end
	if Menu.Harass.Q:Value() and self:IsReady(_Q) then
		local target = self:GetTarget(Spells.Q.range)
		if target ~= nil and self:IsValidTarget(target, Spells.Q.range, false, myHero.pos) then
			self:CastQ(target)
		end
	end
end

function Katarina:GetTarget(range)
  local target = nil
  local lessCast = 0
  local GetEnemyHeroes = self:GetEnemyHeroes()
  for i = 1, #GetEnemyHeroes do
  	local Enemy = GetEnemyHeroes[i]
    if self:IsValidTarget(Enemy, range, false, myHero.pos) then
      local Armor = (100 + Enemy.magicResist) / 100
      local Killable = Armor * Enemy.health
      if Killable <= lessCast or lessCast == 0 then
        target = Enemy
        lessCast = Killable
      end
    end
  end
  return target
end

function Katarina:IsRecalling()
	for K, Buff in pairs(self:GetBuffs(myHero)) do
		if Buff.name == "recall" and Buff.duration > 0 then
			return true
		end
	end
	return false
end

function Katarina:IsBuffed(target, BuffName)
	for K, Buff in pairs(GetBuffs(target)) do
		if Buff.name == BuffName then
			return true
		end
	end
	return false
end

function Katarina:GetAllyHeroes()
	AllyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isAlly then
			table.insert(AllyHeroes, Hero)
		end
	end
	return AllyHeroes
end

function Katarina:GetEnemyHeroes()
	EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(EnemyHeroes, Hero)
		end
	end
	return EnemyHeroes
end

function Katarina:GetMinions(range)
	EnemyMinions = {}
	for i = 1, Game.MinionCount() do
		local Minion = Game.Minion(i)
		if self:IsValidTarget(Minion, range, false, myHero) then
			table.insert(EnemyMinions, Minion)
		end
	end
end

function Katarina:GetPercentMP(unit)
	return 100 * unit.mana / unit.maxMana
end

function Katarina:GetPercentHP(unit)
	return 100 * unit.health / unit.maxHealth
end

function Katarina:GetBuffs(unit)
	T = {}
	for i = 0, unit.buffCount do
		local Buff = unit:GetBuff(i)
		if Buff.count > 0 then
			table.insert(T, Buff)
		end
	end
	return T
end

function Katarina:IsImmune(unit)
	for K, Buff in pairs(self:GetBuffs(unit)) do
		if (Buff.name == "kindredrnodeathbuff" or Buff.name == "undyingrage") and GetPercentHP(unit) <= 10 then
			return true
		end
		if Buff.name == "vladimirsanguinepool" or Buff.name == "judicatorintervention" or Buff.name == "zhonyasringshield" then 
            return true
        end
	end
	return false
end

function Katarina:IsValidTarget(unit, range, checkTeam, from)
    local range = range == nil and math.huge or range
    if unit == nil or not unit.valid or not unit.visible or unit.dead or not unit.isTargetable or self:IsImmune(unit) or (checkTeam and unit.isAlly) then 
        return false 
    end 
    return unit.pos:DistanceTo(from) < range 
end

function Katarina:IsReady(slot)
	if  myHero:GetSpellData(slot).currentCd == 0 and myHero:GetSpellData(slot).level > 0 then
		return true
	end
	return false
end
