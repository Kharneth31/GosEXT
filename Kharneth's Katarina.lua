if myHero.charName ~= "Katarina" then return end
require "DamageLib"
keybindings = { [ITEM_1] = HK_ITEM_1, [ITEM_2] = HK_ITEM_2, [ITEM_3] = HK_ITEM_3, [ITEM_4] = HK_ITEM_4, [ITEM_5] = HK_ITEM_5, [ITEM_6] = HK_ITEM_6}
local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
local barHeight = 8
local barWidth = 103
local barXOffset = 0
local barYOffset = 0
function SetMovement(bool)
	if _G.EOWLoaded then
		EOW:SetMovements(bool)
		EOW:SetAttacks(bool)
	elseif _G.SDK then
		_G.SDK.Orbwalker:SetMovement(bool)
		_G.SDK.Orbwalker:SetAttack(bool)
	else
		GOS.BlockMovement = not bool
		GOS.BlockAttack = not bool
	end
	if bool then
		castSpell.state = 0
	end
end

class "Katarina"
local Scriptname,Version,Author,LVersion = "Kharneth's Katarina","v1.0","Kharneth31","7.17"

function CurrentTarget(range)
	if _G.SDK then
		return _G.SDK.TargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_PHYSICAL);
	elseif _G.EOW then
		return _G.EOW:GetTarget(range)
	else
		return _G.GOS:GetTarget(range,"AD")
	end
end

function Katarina:__init()
	
	self:LoadSpells()
	self:LoadMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	local orbwalkername = ""
	if _G.SDK then
		orbwalkername = "IC'S orbwalker"		
	elseif _G.EOW then
		orbwalkername = "EOW"	
	elseif _G.GOS then
		orbwalkername = "Noddy orbwalker"
	else
		orbwalkername = "Orbwalker not found"
	end
	PrintChat(Scriptname.." "..Version.." - Loaded...."..orbwalkername)
end

function Katarina:LoadSpells()
	Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width }
	W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width }
	E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width }
	R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width }

end

function Katarina:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "Kharneth's Katarina", name = Scriptname})
	self.Menu:MenuElement({id = "ComboMode", name = "Combo", type = MENU})
	self.Menu.ComboMode:MenuElement({id = "UseQ", name = "Q: Bouncing Blade", value = true})
	self.Menu.ComboMode:MenuElement({id = "UseW", name = "W: Preparation", value = true})
	self.Menu.ComboMode:MenuElement({id = "UseE", name = "E: Shunpo", value = true})
	self.Menu.ComboMode:MenuElement({id = "UseR", name = "R: Death Lotus", value = true})
	self.Menu.ComboMode:MenuElement({id = "comboActive", name = "Combo key", key = string.byte(" ")})
	self.Menu.ComboMode:MenuElement({id = "DrawDamage", name = "Draw damage on HPbar", value = true})
		
	self.Menu:MenuElement({id = "HarassMode", name = "Harass", type = MENU})
	self.Menu.HarassMode:MenuElement({id = "UseQ", name = "Q: Bouncing Blade", value = true})
	self.Menu.HarassMode:MenuElement({id = "UseW", name = "W: Preparation", value = true})
	self.Menu.HarassMode:MenuElement({id = "UseE", name = "E: Shunpo", value = true})
	self.Menu.HarassMode:MenuElement({id = "harassActive", name = "Harass key", key = string.byte("C")})

	self.Menu:MenuElement({id = "ClearMode", name = "Clear", type = MENU})
	self.Menu.ClearMode:MenuElement({id = "UseQ", name = "Q: Boncing Blade", value = true})
	self.Menu.ClearMode:MenuElement({id = "UseW", name = "W: Perparation", value = true})
	self.Menu.ClearMode:MenuElement({id = "UseE", name = "E: Shunpo", value = true})
	self.Menu.ClearMode:MenuElement({id = "clearActive", name = "Clear key", key = string.byte("V")})

	self.Menu:MenuElement({id = "blank", type = SPACE , name = ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "Script Ver: "..Version.. " - LoL Ver: "..LVersion.. ""})
	self.Menu:MenuElement({id = "blank", type = SPACE , name = "by "..Author.. ""})
end

function GetInventorySlotItem(itemID)
		assert(type(itemID) == "number", "GetInventorySlotItem: wrong argument types (<number> expected)")
		for _, j in pairs({ ITEM_1, ITEM_2, ITEM_3, ITEM_4, ITEM_5, ITEM_6}) do
			if myHero:GetItemData(j).itemID == itemID and myHero:GetSpellData(j).currentCd == 0 then return j end
		end
		return nil
	    end


function IsRecalling()
	for K, Buff in pairs(GetBuffs(myHero)) do
		if Buff.name == "recall" and Buff.duration > 0 then
			return true
		end
	end
	return false
end

function ValidTarget(target, range)
	range = range and range or math.huge
	return target ~= nil and target.valid and target.visible and not target.dead and target.distance <= range
end

function Katarina:Tick()
    if myHero.dead or Game.IsChatOpen() == true or IsRecalling() == true then return end
	if self.Menu.HarassMode.harassActive:Value() and self:EnemyInRange(700) then
		self:Harass()
	end
	if self.Menu.ComboMode.comboActive:Value() and self:EnemyInRange(700) then
		self:Combo()
	end
	if self.Menu.ClearMode.clearActive:Value() then
		self:Jungle()
	end
end

function Katarina:HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
		end
	end
	return false
end

function Katarina:IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function Katarina:CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function Katarina:CanCast(spellSlot)
	return self:IsReady(spellSlot)
end 
end

function EnableMovement()
	SetMovement(true)
end

function ReturnCursor(pos)
	Control.SetCursorPos(pos)
	DelayAction(EnableMovement,0.1)
end

function LeftClick(pos)
	Control.mouse_event(MOUSEEVENTF_LEFTDOWN)
	Control.mouse_event(MOUSEEVENTF_LEFTUP)
	DelayAction(ReturnCursor,0.05,{pos})
end
function Katarina:Draw()
    local textPos = myHero.pos:To2D()
        if self:CanCast(_R) then Draw.Circle(myHero.pos, 550, 3,  Draw.Color(255, 000, 222, 255)) end
        if self:CanCast(_E) then Draw.Circle(myHero.pos, 625, 3,  Draw.Color(255, 000, 222, 255)) end
        if self:CanCast(_Q) then Draw.Circle(myHero.pos, 725, 3,  Draw.Color(255, 000, 222, 255)) end
	if self.Menu.ComboMode.DrawDamage:Value() then
		for i, hero in pairs(self:GetEnemyHeroes()) do
			local barPos = hero.hpBar
			if not hero.dead and hero.pos2D.onScreen and barPos.onScreen and hero.visible then
				local QDamage = (self:CanCast(_Q) and getdmg("Q",hero,myHero) or 0)
				local WDamage = (self:CanCast(_W) and getdmg("W",hero,myHero) or 0)
				local EDamage = (self:CanCast(_E) and getdmg("E",hero,myHero) or 0)
				local damage = QDamage + WDamage + EDamage
				if damage > hero.health then
					Draw.Text("killable", 24, hero.pos2D.x, hero.pos2D.y,Draw.Color(0xFF00FF00))
					
				else
					local percentHealthAfterDamage = math.max(0, hero.health - damage) / hero.maxHealth
					local xPosEnd = barPos.x + barXOffset + barWidth * hero.health/hero.maxHealth
					local xPosStart = barPos.x + barXOffset + percentHealthAfterDamage * 100
					Draw.Line(xPosStart, barPos.y + barYOffset, xPosEnd, barPos.y + barYOffset, 10, Draw.Color(0xFF00FF00))
				end
			end
		end	
	end
	

function Jax:CastSpell(spell,pos)
	local customcast = self.Menu.CustomSpellCast:Value()
	if not customcast then
		Control.CastSpell(spell, pos)
		return
	else
		local delay = self.Menu.delay:Value()
		local ticker = GetTickCount()
		if castSpell.state == 0 and ticker > castSpell.casting then
			castSpell.state = 1
			castSpell.mouse = mousePos
			castSpell.tick = ticker
			if ticker - castSpell.tick < Game.Latency() then
				SetMovement(false)
				Control.SetCursorPos(pos)
				Control.KeyDown(spell)
				Control.KeyUp(spell)
				DelayAction(LeftClick,delay/1000,{castSpell.mouse})
				castSpell.casting = ticker + 500
			end
		end
	end
end

function Katarina:Combo()
 


    
if self:CanCast(_Q) and self:EnemyInRange(625) then 
		local QTarget = CurrentTarget(625)
		if self.Menu.ComboMode.UseQ:Value() and QTarget then
            if self:EnemyInRange(625) and myHero.pos:DistanceTo(QTarget.pos) > 250 then
				Control.CastSpell(HK_Q, QTarget)
                       end
	        end
       end
	    if self:CanCast(_E) and self:EnemyInRange(725) then 
		local ETarget = CurrentTarget(725)
		if self.Menu.ComboMode.UseE:Value() and self.Menu.ComboMode.Key:Value() == false and ETarget and not self then
			if self:EnemyInRange(125) and myHero.pos:DistanceTo(ETarget.pos) < 130 then
				Control.CastSpell(HK_E)
			end
		end
           
	        if self:CanCast(_W) and self:EnemyInRange(10) then 
		local WTarget = CurrentTarget(10)
		if self.Menu.ComboMode.UseW:Value(10) and WTarget then
			if self:EnemyInRange(10) and myHero.attackData.state == STATE_WINDDOWN then
				Control.CastSpell(HK_W)
                Control.Attack(WTarget)
			end
		end
	end

LastR = Game.Timer()


Combo:
if self:CanCast(_R) and self:EnemyInRange(R.Range) then 
		local RTarget = CurrentTarget(R.Range)
		if self.Menu.ComboMode.UseR:Value() and RTarget then
			local RDamage = (self:CanCast(_R) and getdmg("R",RTarget,myHero) or 0)
			if Game.Timer() - LastR > 5 and myHero.pos:DistanceTo(RTarget.pos) < 350 and RTarget.health/RTarget.maxHealth < .30 then
				Control.CastSpell(HK_R)
			end
		end
	 end

    
function Katarina:GetEnemyHeroes()
	self.EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isEnemy then
			table.insert(self.EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
end

function Katarina:EnemyInRange(range)
	local count = 0
	for i, target in ipairs(self:GetEnemyHeroes()) do
		if target.pos:DistanceTo(myHero.pos) < range then 
			count = count + 1
		end
	end
	return count
end

function Katarina:Harass()

        
		

	if self:CanCast(_Q) and self:EnemyInRange(625) then 
		local QTarget = CurrentTarget(625)
		if self.Menu.HarassMode.UseQ:Value() and QTarget then
            if self:EnemyInRange(625) and myHero.pos:DistanceTo(QTarget.pos) > 250 then
				Control.CastSpell(HK_Q, QTarget)
                        end
	        end
	end

if self:CanCast(_E) and self:EnemyInRange(725) then 
		local QTarget = CurrentTarget(725)
		if self.Menu.HarassMode.UseQ:Value() and QTarget then
            if self:EnemyInRange(6725) and myHero.pos:DistanceTo(QTarget.pos) > 250 then
				Control.CastSpell(HK_E, QTarget)
                        end
                end
        end
	    if self:CanCast(_W) and self:EnemyInRange(10) then 
		local WTarget = CurrentTarget(10)
		if self.Menu.HarassMode.UseW:Value() and WTarget then
			if self:EnemyInRange(10) and myHero.attackData.state == STATE_WINDDOWN then
				Control.CastSpell(HK_W)
                Control.Attack(WTarget)
			end
		end
	end
	
end

function Katarina:Jungle()
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
    if minion and minion.team == 300 or minion.team ~= myHero.team then
    if self:CanCast(_E) and minion then 
		if self.Menu.ClearMode.UseE:Value() and self.Menu.ComboMode.Key:Value()  == false and not self:HasBuff(myHero, "JaxCounterStrike") then
			if myHero.pos:DistanceTo(minion.pos) < 175 then
				Control.CastSpell(HK_E)
			end
		end
        if self.Menu.ClearMode.UseE:Value() and self.Menu.ComboMode.Key:Value()  == true and not self:HasBuff(myHero, "JaxCounterStrike") then
			if myHero.pos:DistanceTo(minion.pos) < 700 and self:CanCast(_Q) then
				Control.CastSpell(HK_E)
			end
		end
	end
   
        if self:CanCast(_Q) and minion then 
		if self.Menu.ClearMode.UseQ:Value() and ValidTarget(minion, 725) then
            if myHero.pos:DistanceTo(minion.pos) > 250 then
				Control.CastSpell(HK_Q, minion)
                        end
		end
	end

	if self:CanCast(_W) and minion then 
		if self.Menu.ClearMode.UseW:Value() and ValidTarget(minion, 175) then
			if myHero.pos:DistanceTo(minion.pos) < 175 and myHero.attackData.state == STATE_WINDDOWN then
				Control.CastSpell(HK_W)
                Control.Attack(minion)
			end
                end
        end

function OnLoad()
	Katarina()
end