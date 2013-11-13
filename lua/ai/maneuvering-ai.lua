--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）军争篇部分
]]--
--[[****************************************************************
	----------------------------------------------------------------
	卡 牌 控 制
	----------------------------------------------------------------
]]--****************************************************************
sgs.fire_slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0) --火杀
sgs.thunder_slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0) --雷杀
sgs.analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0) --酒
sgs.fire_attack = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_NoSuit, 0) --火攻
sgs.iron_chain = sgs.Sanguosha:cloneCard("iron_chain", sgs.Card_NoSuit, 0) --铁索连环
sgs.supply_shortage = sgs.Sanguosha:cloneCard("supply_shortage", sgs.Card_NoSuit, 0) --兵粮寸断
--伤害属性表
sgs.damage_nature = {
	FireSlash = sgs.DamageStruct_Fire,
	FireAttack = sgs.DamageStruct_Fire,
	ThunderSlash = sgs.DamageStruct_Thunder,
	Lightning = sgs.DamageStruct_Thunder,
	--后续相关的技能卡
	LeijiCard = sgs.DamageStruct_Thunder,
	GreatYeyanCard = sgs.DamageStruct_Fire,
	SmallYeyanCard = sgs.DamageStruct_Fire,
	--后续相关的技能
	["huoji>>FireAttack"] = sgs.DamageStruct_Fire,
	["lihuo>>FireSlash"] = sgs.DamageStruct_Fire,
	["zonghuo>>FireSlash"] = sgs.DamageStruct_Fire,
}
--[[****************************************************************
	----------------------------------------------------------------
	基 本 牌
	----------------------------------------------------------------
]]--****************************************************************
--[[****************************************************************
	火杀
]]--****************************************************************
sgs.objectName["FireSlash"] = "fire_slash"
sgs.className["fire_slash"] = "FireSlash"
--[[
	内容：“火杀”的卡牌成分
]]--
sgs.card_constituent["FireSlash"] = {
	damage = 1,
	use_value = 4.6,
	keep_value = 2.6,
	use_priority = 2.5,
}
--[[
	内容：“火杀”的卡牌仇恨值
]]--
sgs.ai_card_intention["FireSlash"] = sgs.ai_card_intention["Slash"]
--[[
	内容：注册火杀
]]--
sgs.RegistCard("FireSlash")
--[[
	功能：使用火杀
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardFireSlash(card, use)
	if sgs.SeriesName then
		local callback = sgs.ai_series_use_func["FireSlash"][sgs.SeriesName]
		if callback then
			if callback(self, card, use) then
				return 
			end
		end
	end
	self:useCardSlash(card, use)
end
--[[
	套路：仅使用火杀
]]--
sgs.ai_series["FireSlashOnly"] = {
	name = "FireSlashOnly", 
	IQ = 1,
	value = 1, 
	priority = 1.2, 
	cards = { 
		["FireSlash"] = 1, 
		["Others"] = 0, 
	},
	enabled = function(self) 
		return sgs.Slash_IsAvailable(self.player) --self.player:usedTimes("Slash") < (sgs.slashAvail or 0) 
	end,
	action = function(self, handcards, skillcards) 
		if cards then
			for _,slash in ipairs(handcards) do
				if slash:isKindOf("FireSlash") then
					return {slash} 
				end
			end
		end
		return {}
	end,
	break_condition = function(self) 
		return false
	end,
}
table.insert(sgs.ai_card_actions["FireSlash"], "FireSlashOnly")
--[[****************************************************************
	雷杀
]]--****************************************************************
sgs.objectName["ThunderSlash"] = "thunder_slash"
sgs.className["thunder_slash"] = "ThunderSlash"
--[[
	内容：“雷杀”的卡牌成分
]]--
sgs.card_constituent["ThunderSlash"] = {
	damage = 1,
	use_value = 4.55,
	keep_value = 2.5,
	use_priority = 2.5,
}
--[[
	内容：“雷杀”的卡牌仇恨值
]]--
sgs.ai_card_intention["ThunderSlash"] = sgs.ai_card_intention["Slash"]
--[[
	内容：注册雷杀
]]--
sgs.RegistCard("ThunderSlash")
--[[
	功能：使用雷杀
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardThunderSlash(card, use)
	if sgs.SeriesName then
		local callback = sgs.ai_series_use_func["ThunderSlash"][sgs.SeriesName]
		if callback then
			if callback(self, card, use) then
				return 
			end
		end
	end
	self:useCardSlash(card, use)
end
--[[
	套路：仅使用雷杀
]]--
sgs.ai_series["ThunderSlashOnly"] = {
	name = "ThunderSlashOnly", 
	IQ = 1,
	value = 1, 
	priority = 1.1, 
	cards = { 
		["ThunderSlash"] = 1, 
		["Others"] = 0, 
	},
	enabled = function(self) 
		return sgs.Slash_IsAvailable(self.player) --self.player:usedTimes("Slash") < (sgs.slashAvail or 0) 
	end,
	action = function(self, handcards, skillcards) 
		if handcards then
			for _,slash in ipairs(handcards) do
				if slash:isKindOf("ThunderSlash") then
					return {slash} 
				end
			end
		end
		return {}
	end,
	break_condition = function(self) 
		return false
	end,
}
table.insert(sgs.ai_card_actions["ThunderSlash"], "ThunderSlashOnly")
--[[****************************************************************
	酒
]]--****************************************************************
sgs.objectName["Analeptic"] = "analeptic"
sgs.className["analeptic"] = "Analeptic"
--[[
	内容：“酒”的卡牌成分
]]--
sgs.card_constituent["Analeptic"] = {
	benefit = 1,
	use_value = 5.98,
	keep_value = 4.5,
	use_priority = 2.7,
}
--[[
	内容：注册酒
]]--
sgs.RegistCard("Analeptic")
--[[
	功能：使用酒
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardAnaleptic(card, use)
	if sgs.SeriesName then
		local callback = sgs.ai_series_use_func["Analeptic"][sgs.SeriesName]
		if callback then
			if callback(self, card, use) then
				return 
			end
		end
	end
	if not self.player:hasEquip(card) then
		if not self:hasLoseHandcardEffective() then
			if not self:isWeak() then
				if sgs.Analeptic_IsAvailable(self.player, card) then
					use.card = card
				end
			end
		end
	end
end
--[[
	套路：仅使用“酒”
]]--
sgs.ai_series["AnalepticOnly"] = {
	name = "AnalepticOnly",
	IQ = 1,
	value = 3, 
	priority = 1.1, 
	cards = {
		["Analeptic"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		if sgs.Analeptic_IsAvailable(self.player) then
			return true
		end
		return false
	end,
	action = function(self, handcards, skillcards)
		for _,analeptic in ipairs(handcards) do
			if analeptic:isKindOf("Analeptic") then
				return {analeptic}
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["Analeptic"], "AnalepticOnly")
--[[****************************************************************
	----------------------------------------------------------------
	锦 囊 牌
	----------------------------------------------------------------
]]--****************************************************************
--[[****************************************************************
	火攻（非延时性锦囊，单目标锦囊）
]]--****************************************************************
sgs.objectName["FireAttack"] = "fire_attack"
sgs.className["fire_attack"] = "FireAttack"
--[[
	内容：“火攻”的卡牌成分
]]--
sgs.card_constituent["FireAttack"] = {
	damage = 1,
	use_value = 4.8,
	use_priority = sgs.card_constituent["Dismantlement"]["use_priority"] + 0.1
}
sgs.ai_skill_cardshow["fire_attack"] = function(self, requestor)
	local handcards = self.player:getHandcards()
	local cards = sgs.QList2Table(handcards)
	if requestor:objectName() == self.player:objectName() then
		self:sortByUseValue(cards, true)
		return cards[1]
	end
	local result
	local priority = { 
		heart = 4, 
		spade = 3, 
		club = 2, 
		diamond = 1, 
	}
	if requestor:hasSkill("hongyan") then 
		priority = { 
			spade = 10, 
			club = 2, 
			diamond = 1, 
			heart = 0, 
		} 
	end
	local index = -1
	for _, card in ipairs(cards) do
		local suit = card:getSuitString()
		if priority[suit] > index then
			result = card
			index = priority[suit]
		end
	end
	return result 
end
sgs.ai_skill_cardask["@fire-attack"] = function(self, data, pattern, target)
	local convert = {
		[".S"] = "spade",
		[".D"] = "diamond",
		[".H"] = "heart",
		[".C"] = "club",
	}
	local suit = convert[pattern]
	local handcards = self.player:getHandcards()
	local cards = sgs.QList2Table(handcards) 
	self:sortByUseValue(cards, true)
	local lord = self:getMyLord(self.player)
	local card = nil
	for _, acard in ipairs(cards) do
		if acard:getSuitString() == suit then
			if not sgs.isCard("Peach", acard, self.player) then
				card = acard
				break
			else
				local needKeepPeach = true
				if target:getHp() == 1 then
					needKeepPeach = false
				elseif target:getMark("@gale") > 0 then
					needKeepPeach = false
				elseif target:hasArmorEffect("Vine") then
					needKeepPeach = false
				elseif self:isGoodChainTarget(target) then
					needKeepPeach = false
				elseif self:isWeak(target) then
					if not self:isWeak() then
						needKeepPeach = false
					end
				end
				if lord then
					if sgs.isInDanger(lord) then
						if self:getCardsNum("Peach") == 1 then
							if self.player:aliveCount() > 2 then 
								needKeepPeach = true 
							end
						end
					end
				end
				if not needKeepPeach then
					card = acard
					break
				end
			end
		end
	end
	if card then
		return card:getId()
	end
	return "." 
end
--[[
	内容：注册火攻
]]--
sgs.RegistCard("FireAttack")
--[[
	功能：使用火攻
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardFireAttack(fire_attack, use)
	if sgs.SeriesName then
		local callback = sgs.ai_series_use_func["FireAttack"][sgs.SeriesName]
		if callback then
			if callback(self, card, use) then
				return 
			end
		end
	end
	--一般情形
	if self.player:hasSkill("wuyan") then
		if not self.player:hasSkill("jueqing") then 
			return 
		end
	end
	if self.player:hasSkill("noswuyan") then 
		return 
	end
	local lack = {
		spade = true,
		club = true,
		heart = true,
		diamond = true,
	}
	local cards = self.player:getHandcards()
	local canDis = {}
	local id = fire_attack:getEffectiveId()
	for _,c in sgs.qlist(cards) do
		if c:getEffectiveId() ~= id then
			table.insert(canDis, c)
			local suit = c:getSuitString()
			lack[suit] = false
		end
	end
	if self.player:hasSkill("hongyan") then
		lack["spade"] = true
	end
	local suitNum = 0
	for suit, isLack in pairs(lack) do
		if not isLack then 
			suitNum = suitNum + 1 
		end
	end
	self:sort(self.opponents, "defense")
	local function can_attack(enemy)
		local flag = "FireAttackFailed_" .. enemy:objectName()
		if self.player:hasFlag(flag) then
			return false
		elseif enemy:isKongcheng() then
			return false
		elseif self.room:isProhibited(self.player, enemy, fire_attack) then
			return false
		end
		local damage = 1
		if not self.player:hasSkill("jueqing") then
			if not enemy:hasArmorEffect("SilverLion") then
				if enemy:hasArmorEffect("Vine") then 
					damage = damage + 1 
				end
				if enemy:getMark("@gale") > 0 then 
					damage = damage + 1 
				end
			end
			if enemy:hasSkill("mingshi") then
				local myequips = self.player:getEquips()
				local equips = enemy:getEquips()
				if myequips:length() <= equips:length() then
					damage = damage - 1
				end
			end
		end
		if damage > 0 then
			if self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player) then
				if self:friendshipLevel(enemy) < -4 then
					if not self:cannotBeHurt(enemy, damage, self.player) then
						if self:trickIsEffective(fire_attack, enemy) then
							if sgs.isGoodTarget(self, enemy, self.opponents) then
								if self.player:hasSkill("jueqing") then
									return true
								else
									if enemy:hasSkill("jianxiong") then
										if not self:isWeak(enemy) then
											return false
										end
									end
									if self:invokeDamagedEffect(enemy, self.player) then
										return false
									end
									if enemy:isChained() then
										if not self:isGoodChainTarget(enemy) then
											return false
										end
									end
									return true
								end
							end
						end
					end
				end
			end
		end
		return false
	end
	local enemies, targets = {}, {}
	for _,enemy in ipairs(self.opponents) do
		local flag = true
		if use.current_targets then
			if table.contains(use.current_targets, enemy:objectName()) then
				flag = false
			end
		end
		if flag and can_attack(enemy) then
			table.insert(enemies, enemy)
		end
	end
	local can_FireAttack_self
	for _,card in ipairs(canDis) do
		local can_use = true
		if sgs.isCard("Peach", card, self.player) then
			if self:getCardsNum("Peach") < 3 then
				can_use = false
			end
		elseif sgs.isCard("Analeptic", card, self.player) then
			if self:getCardsNum("Analeptic") < 2 then
				can_use = false
			end
		end
		if can_use then
			can_FireAttack_self = true
			break
		end
	end
	if can_FireAttack_self then
		local can_use = true
		if can_use then
			if use.current_targets then
				if table.contains(use.current_targets, self.player:objectName()) then
					can_use = false
				end
			end
		end
		if can_use then
			can_use = false
			if self.player:isChained() then
				if not self:amRenegade() then
					if self:isGoodChainTarget(self.player) then
						if self.player:getHandcardNum() > 1 then
							if not self:hasSkills("jueqing|mingshi") then
								if not self.room:isProhibited(self.player, self.player, fire_attack) then
									if self:damageIsEffective(self.player, sgs.DamageStruct_Fire, self.player) then
										if not self:cannotBeHurt(self.player) then
											if self:trickIsEffective(fire_attack, self.player) then
												can_use = true
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
		if can_use then
			can_use = false
			if self.player:getHp() > 1 then
				can_use = true
			elseif self:getCardsNum("Peach") > 1 then
				can_use = true
			elseif self:getCardsNum("Analeptic") >= 1 then
				can_use = true
			elseif self.player:hasSkill("buqu") then
				can_use = true
			elseif self.player:hasSkill("niepan") then
				if self.player:getMark("@nirvana") > 1 then
					can_use = true
				end
			end
		end
		if can_use then
			table.insert(targets, self.player)
		end
	end
	for _,enemy in ipairs(enemies) do
		if enemy:getHandcardNum() == 1 then
			local can_use = true
			if use.current_targets then
				if table.contains(use.current_targets, enemy:objectName()) then
					can_use = false
				end
			end
			if can_use then
				local handcards = enemy:getHandcards()
				handcards = sgs.QList2Table(handcards)
				local flag = string.format("visible_%s_%s", self.player:objectName(), enemy:objectName())
				if handcards[1]:hasFlag("visible") or handcards[1]:hasFlag(flag) then
					local suit = handcards[1]:getSuitString()
					if not lack[suit] then
						if not table.contains(targets, enemy) then
							table.insert(targets, enemy)
						end
					end
				end
			end
		end
	end
	if #targets == 0 then
		local flag = false
		if suitNum <= 1 then
			flag = true
		elseif suitNum == 2 then
			if lack["diamond"] == false then
				flag = true
			end
		end
		if flag then
			local overflow = self:getOverflow()
			if self.player:hasSkills("jizhi|nosjizhi") then
				if overflow <= -2 then
					return 
				end
			else
				if overflow <= 0 then
					return 
				end
			end
		end
	end
	for _,enemy in ipairs(enemies) do
		local damage = 1
		if not enemy:hasArmorEffect("SilverLion") then
			if enemy:hasArmorEffect("Vine") then 
				damage = damage + 1 
			end
			if enemy:getMark("@gale") > 0 then 
				damage = damage + 1 
			end
		end
		if not self.player:hasSkill("jueqing") then
			if enemy:hasSkill("mingshi") then
				if self.player:getEquips():length() <= enemy:getEquips():length() then
					damage = damage - 1
				end
			end
		end
		if damage > 1 then
			if not self.player:hasSkill("jueqing") then
				if not table.contains(targets, enemy) then
					if self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player) then
						if not use.current_targets then
							table.insert(targets, enemy)
						elseif not table.contains(use.current_targets, enemy:objectName()) then
							table.insert(targets, enemy)
						end
					end
				end
			end
		end
	end
	for _,enemy in ipairs(enemies) do
		if not table.contains(targets, enemy) then
			if not use.current_targets then
				table.insert(targets, enemy) 
			elseif not table.contains(use.current_targets, enemy:objectName()) then 
				table.insert(targets, enemy) 
			end
		end
	end
	if #targets > 0 then
		local godsalvation = self:getCard("GodSalvation")
		if godsalvation then
			if godsalvation:getId() ~= fire_attack:getId() then
				if self:willUseGodSalvation(godsalvation) then
					local use_gs = true
					for _, p in ipairs(targets) do
						if not p:isWounded() then
							break
						elseif not self:trickIsEffective(godsalvation, p, self.player) then 
							break 
						end
						use_gs = false
					end
					if use_gs then
						use.card = godsalvation
						return
					end
				end
			end
		end
		local count = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, fire_attack)
		use.card = fire_attack
		if use.to then
			for i = 1, #targets, 1 do
				use.to:append(targets[i])
				if use.to:length() == count then 
					return 
				end
			end
		end
	end
end
--[[
	套路：仅使用火攻
]]--
sgs.ai_series["FireAttackOnly"] = {
	name = "FireAttackOnly", 
	IQ = 1,
	value = 1, 
	priority = 1, 
	cards = { 
		["FireAttack"] = 1, 
		["Others"] = 1, 
	},
	enabled = function(self) 
		return true
	end,
	action = function(self, handcards, skillcards) 
		if handcards then
			for _,fa in ipairs(handcards) do
				if fa:isKindOf("FireAttack") then
					return {fa} 
				end
			end
		end
		return {}
	end,
	break_condition = function(self) 
		return false
	end,
}
table.insert(sgs.ai_card_actions["FireAttack"], "FireAttackOnly")
--[[****************************************************************
	铁索连环（非延时性锦囊，多目标锦囊）
]]--****************************************************************
sgs.objectName["IronChain"] = "iron_chain"
sgs.className["iron_chain"] = "IronChain"
--[[
	内容：“铁索连环”的卡牌成分
]]--
sgs.card_constituent["IronChain"] = {
	use_value = 5.4,
	use_priority = 9.1,
}
--[[
	内容：“铁索连环”的卡牌仇恨值
]]--
sgs.ai_card_intention["IronChain"] = function(self, card, source, targets)
	local liuxie = self.room:findPlayerBySkillName("huangen")
	local flag = ( #targets > 1 )
	for _, target in ipairs(targets) do
		if target:isChained() then
			sgs.updateIntention(source, target, -60)
		else
			local enemy = true
			if flag then
				if target:hasSkill("danlao") then
					enemy = false
				elseif liuxie then
					local hp = liuxie:getHp()
					if hp >= 1 then
						if self:isPartner(target, liuxie) then
							enemy = false
						end
					end
				end
			end
			if enemy then
				sgs.updateIntention(source, target, 60)
			else
				sgs.updateIntention(source, target, -30)
			end
		end
	end
end
--[[
	内容：注册铁索连环
]]--
sgs.RegistCard("IronChain")
--[[
	功能：使用铁索连环
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardIronChain(card, use)
	if sgs.SeriesName then
		local callback = sgs.ai_series_use_func["IronChain"][sgs.SeriesName]
		if callback then
			if callback(self, card, use) then
				return 
			end
		end
	end
	--一般情形
	local needTarget = false
	local skillname = card:getSkillName()
	if skillname == "guhuo" then
		needTarget = true
	elseif skillname == "qice" then
		needTarget = true
	end
	if not needTarget then
		use.card = card
		if self.player:hasSkill("noswuyan") then 
			return 
		elseif self.player:isLocked(card) then 
			return 
		elseif self:needBear() then 
			return 
		elseif #self.opponents == 1 then
			local partners = self:getChainedPartners()
			if #partners <= 1 then 
				return 
			end
		end
		if self.player:hasSkill("manjuan") then 
			if self:getOverflow() <= 0 then
				return 
			end
		end
		if self.player:hasSkill("wumou") then
			if self.player:getMark("@wrath") < 7 then 
				return 
			end
		end
	elseif not self.player:hasSkill("noswuyan") then 
		use.card = card 
	end
	local enemyTargets = {}
	local friendTargets = {}
	local otherFriends = {}
	local YangXiu = self.room:findPlayerBySkillName("danlao")
	local LiuXie = self.room:findPlayerBySkillName("huangen")
	self:sort(self.partners, "defense")
	for _,friend in ipairs(self.partners) do
		local flag = true
		if use.current_targets then
			if table.contains(use.current_targets, friend:objectName()) then 
				flag = false
			end
		end
		if flag then
			if friend:isChained() then
				if not self:isGoodChainPartner(friend) then
					if self:trickIsEffective(card, friend) then
						if not friend:hasSkill("danlao") then
							table.insert(friendTargets, friend)
							flag = false
						end
					end
				end
			end
			if flag then
				table.insert(otherFriends, friend)
			end
		end
	end
	if not LiuXie or not self:isOpponent(LiuXie) then
		self:sort(self.opponents, "defense")
		for _, enemy in ipairs(self.opponents) do
			local can_use = true
			if use.current_targets then
				if table.contains(use.current_targets, enemy:objectName()) then
					can_use = false
				end
			end
			if can_use then
				if not enemy:isChained() then
					if not self.room:isProhibited(self.player, enemy, card) then
						if not enemy:hasSkill("danlao") then
							if self:trickIsEffective(card, enemy) then
								if self:friendshipLevel(enemy) < -4 then
									if not self:invokeDamagedEffect(enemy) then
										if not self:needToLoseHp(enemy) then
											if sgs.isGoodTarget(self, enemy, self.opponents) then
												table.insert(enemyTargets, enemy)
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	local chainSelf = true
	if use.current_targets then
		if table.contains(use.current_targets, self.player:objectName()) then
			chainSelf = false
		end
	end
	if chainSelf then
		if not self.player:isChained() then
			if not self.player:hasSkill("jueqing") then
				chainSelf = false
				if self:needToLoseHp(self.player) then
					chainSelf = true
				elseif self:invokeDamagedEffect(self.player) then
					chainSelf = true
				end
				if chainSelf then
					chainSelf = false
					if self:getCardId("FireSlash") then
						chainSelf = true
					elseif self:getCardId("ThunderSlash") then
						chainSelf = true
					elseif self:getCardId("Slash") then
						if self.player:hasWeapon("fan") then
							chainSelf = true
						elseif self.player:hasSkill("lihuo") then
							chainSelf = true
						end
					elseif self:getCardId("FireAttack") then
						if self.player:getHandcardNum() > 2 then
							chainSelf = true
						end
					end
				end
			end
		end
	end
	local targets_num = 2 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, card)
	if not self.player:hasSkill("noswuyan") then
		if #friendTargets > 1 then
			if use.to then
				for _,friend in ipairs(friendTargets) do
					use.to:append(friend)
					if use.to:length() == targets_num then 
						return 
					end
				end
			end
		elseif #friendTargets == 1 then
			if #enemyTargets > 0 then
				if use.to then
					use.to:append(friendTargets[1])
					for _,enemy in ipairs(enemyTargets) do
						use.to:append(enemy)
						if use.to:length() == targets_num then 
							return 
						end
					end
				end
			elseif chainSelf then
				if use.to then 
					use.to:append(friendTargets[1]) 
					use.to:append(self.player)
				end
			elseif LiuXie and self:isPartner(LiuXie) and LiuXie:getHp() > 0 and #otherfriends > 0 then
				if use.to then
					use.to:append(friendTargets[1])
					for _, friend in ipairs(otherFriends) do
						use.to:append(friend)
						local hp = LiuXie:getHp()
						local count = math.min(targets_num, hp + 1)
						if use.to:length() == count then 
							return 
						end
					end
				end
			elseif YangXiu and self:isPartner(YangXiu) then
				if use.to then 
					use.to:append(friendTargets[1]) 
					use.to:append(YangXiu)
				end
			elseif use.current_targets then
				if use.to then 
					use.to:append(friendTargets[1]) 
				end
			end
		elseif #enemyTargets > 1 then
			if use.to then
				for _, enemy in ipairs(enemyTargets) do
					use.to:append(enemy)
					if use.to:length() == targets_num then 
						return 
					end
				end
			end
		elseif #enemyTargets == 1 then
			if chainSelf then
				if use.to then 
					use.to:append(enemyTargets[1])
					use.to:append(self.player)					
				end
			elseif LiuXie and self:isPartner(LiuXie) and LiuXie:getHp() > 0 and #otherFriends > 0 then
				if use.to then
					use.to:append(enemyTargets[1])
					for _,friend in ipairs(otherFriends) do
						use.to:append(friend)
						local hp = LiuXie:getHp()
						local count = math.min(targets_num, hp + 1)
						if use.to:length() == count then 
							return 
						end
					end
				end
			elseif YangXiu and self:isPartner(YangXiu) then
				if use.to then 
					use.to:append(enemyTargets[1]) 
					use.to:append(YangXiu)
				end
			elseif use.current_targets then
				if use.to then 
					use.to:append(enemyTargets[1]) 
				end
			end
		elseif #friendTargets == 0 and #enemyTargets == 0 then
			if use.to and LiuXie and self:isPartner(LiuXie) and LiuXie:getHp() > 0
				and (#otherFriends > 1 or (use.current_targets and #otherFriends > 0)) then
				local current_target_length = use.current_targets and #use.current_targets or 0
				local hp = LiuXie:getHp()
				local count = math.min(targets_num, hp)
				for _, friend in ipairs(otherFriends) do
					if use.to:length() + current_target_length == count then 
						return 
					end
					use.to:append(friend)
				end
			elseif use.current_targets then
				if YangXiu then
					if not table.contains(use.current_targets, YangXiu:objectName()) then
						if self:isPartner(YangXiu) then
							if use.to then 
								use.to:append(YangXiu) 
							end
						end
					end
				end
				if LiuXie then
					if not table.contains(use.current_targets, LiuXie:objectName()) then
						if self:isPartner(LiuXie) then
							if LiuXie:getHp() > 0 then
								if use.to then 
									use.to:append(LiuXie) 
								end
							end
						end
					end
				end
			end
		end
	end
end
--[[
	套路：仅使用铁索连环
]]--
sgs.ai_series["IronChainOnly"] = {
	name = "IronChainOnly", 
	IQ = 1,
	value = 1, 
	priority = 1, 
	cards = { 
		["IronChain"] = 1, 
		["Others"] = 0, 
	},
	enabled = function(self) 
		return true
	end,
	action = function(self, handcards, skillcards) 
		if handcards then
			for _,ic in ipairs(handcards) do
				if ic:isKindOf("IronChain") then
					return {ic} 
				end
			end
		end
		return {}
	end,
	break_condition = function(self) 
		return false
	end,
}
table.insert(sgs.ai_card_actions["IronChain"], "IronChainOnly")
--[[
	功能：获取处于横置状态的角色
	参数：players（table类型，表示考察的角色范围）
	结果：table类型（targets），表示考察范围中所有被横置的角色
]]--
function sgs.getChainedPlayers(players)	
	local targets = {}
	if players then
		for _,p in ipairs(players) do
			if p:isChained() then
				table.insert(targets, p)
			end
		end
	end
	return targets
end
--[[
	功能：获取一名角色的处于横置状态的所有友方角色
	参数：player（ServerPlayer类型，表示目标角色）
	结果：table类型，表示该角色的处于横置状态的所有友方角色
]]--
function SmartAI:getChainedPartners(player)
	player = player or self.player
	local friends = self:getPartners(player)
	return sgs.getChainedPlayers(friends)
end
--[[
	功能：获取一名角色的处于横置状态的所有对方角色
	参数：player（ServerPlayer类型，表示目标角色）
	结果：table类型，表示该角色的处于横置状态的所有对方角色
]]--
function SmartAI:getChainedOpponents(player)
	player = player or self.player
	local enemies = self:getOpponents(player)
	return sgs.getChainedPlayers(enemies)
end
--[[
	功能：判断一名角色是否乐意被横置
	参数：target（ServerPlayer类型，表示目标角色）
	结果：boolean类型，表示是否乐意
]]--
function SmartAI:isGoodChainPartner(target)
	target = target or self.player
	if target:hasSkill("buqu") then --不屈
		return true
	elseif target:hasSkill("niepan") then --涅槃
		if target:getMark("@nirvana") > 0 then
			return true
		end
	elseif target:hasSkill("fuli") then --伏枥
		if target:getMark("@laoji") > 0 then
			return true
		end
	elseif self:needToLoseHp(target) then --需要扣减体力
		return true
	elseif self:invokeDamagedEffect(target) then --需要触发伤害效果
		return true
	end
	return false
end
--[[****************************************************************
	兵粮寸断（延时性锦囊）
]]--****************************************************************
sgs.objectName["SupplyShortage"] = "supply_shortage"
sgs.className["supply_shortage"] = "SupplyShortage"
--[[
	内容：“兵粮寸断”的卡牌成分
]]--
sgs.card_constituent["SupplyShortage"] = {
	control = 3,
	use_value = 7,
	use_priority = 0.5,
}
--[[
	内容：“兵粮寸断”的卡牌仇恨值
]]--
sgs.ai_card_intention["SupplyShortage"] = 120
--[[
	内容：注册兵粮寸断
]]--
sgs.RegistCard("SupplyShortage")
--[[
	功能：使用兵粮寸断
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardSupplyShortage(card, use)
	if use.isDummy then
		self.room:writeToConsole("Just Dummy Use : Supply Shortage")
	end
		if sgs.SeriesName then
			local callback = sgs.ai_series_use_func["SupplyShortage"][sgs.SeriesName]
			if callback then
				if callback(self, card, use) then
					return 
				end
			end
		end
		if #self.opponents > 0 then
			local limit = 1
			if self.player:hasSkill("duanliang") then
				limit = 2
			end
			for _,enemy in ipairs(self.opponents) do
				local dist = self.player:distanceTo(enemy) 
				if dist <= limit then
					if not self.player:isProhibited(enemy, card) then
						local area = enemy:getJudgingArea()
						for _,judge in sgs.qlist(area) do
							if judge:isKindOf("SupplyShortage") then
								return 
							end
							if judge:isKindOf("YanxiaoCard") then
								return
							end
						end
						use.card = card
						if use.to then
							use.to:append(enemy)
						end
						return 
					end
				end
			end
		end
end
--[[
	套路：仅使用兵粮寸断
]]--
sgs.ai_series["SupplyShortageOnly"] = {
	name = "SupplyShortageOnly", 
	IQ = 1,
	value = 1, 
	priority = 1, 
	cards = { 
		["SupplyShortage"] = 1, 
		["Others"] = 0, 
	},
	enabled = function(self) 
		return true
	end,
	action = function(self, handcards, skillcards) 
		if handcards then
			for _,ss in ipairs(handcards) do
				if ss:isKindOf("SupplyShortage") then
					return {ss} 
				end
			end
		end
		return {}
	end,
	break_condition = function(self) 
		return false
	end,
}
table.insert(sgs.ai_card_actions["SupplyShortage"], "SupplyShortageOnly")
--[[****************************************************************
	----------------------------------------------------------------
	装 备 牌
	----------------------------------------------------------------
]]--****************************************************************
--[[****************************************************************
	寒冰剑（武器）
]]--****************************************************************
sgs.weapon_range.IceSword = 2
sgs.card_constituent["IceSword"] = {
	use_priority = 2.65,
}
--[[
	内容：注册寒冰剑
]]--
sgs.RegistCard("IceSword")
--[[
	技能：寒冰剑
	描述：每当你使用【杀】对目标角色造成伤害时，若该角色有牌，你可以防止此伤害，然后依次弃置其两张牌。
]]--
sgs.ai_skill_invoke["IceSword"] = function(self, data)
	local damage = data:toDamage()
	if damage.card:hasFlag("drank") then 
		return false 
	end
	return false --Just For Test
end
--[[
	功能：使用寒冰剑
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardIceSword(card, use)
	use.card = card
end
--[[****************************************************************
	古锭刀（武器）
]]--****************************************************************
sgs.weapon_range.GudingBlade = 2
sgs.card_constituent["GudingBlade"] = {
	use_priority = 2.67,
}
--[[
	内容：注册古锭刀
]]--
sgs.RegistCard("GudingBlade")
--[[
	功能：使用古锭刀
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardGudingBlade(card, use)
	use.card = card
end
sgs.heavy_slash_system["guding_blade"] = {
	name = "guding_blade",
	reason = "GudingBlade",
	extra_func = function(source, slash, target, isFireSlash, isThunderSlash)
		if slash then
			if source:hasWeapon("GudingBlade") then
				if target:isKongcheng() then
					if not source:hasSkill("jueqing") then
						return 1
					end
				end
			end
		end
		return 0
	end,
}
sgs.ai_slash_weapon_filter["GudingBlade"] = function(self, target)
	return target:isKongcheng()
end
sgs.ai_weapon_value["GudingBlade"] = function(self, target)
	if target then
		local value = 2
		if target:getHandcardNum() < 1 then
			value = 4
		end
		return value
	end
end
--[[****************************************************************
	朱雀羽扇（武器）
]]--****************************************************************
sgs.weapon_range.Fan = 4
sgs.card_constituent["Fan"] = {
	use_priority = 2.655,
}
--[[
	内容：注册朱雀羽扇、朱雀羽扇火杀
]]--
sgs.RegistCard("Fan")
sgs.RegistCard("Fan>>FireSlash")
--[[
	技能：朱雀羽扇
	描述：你可以将一张普通【杀】当火【杀】使用
]]--
--[[
	内容：“朱雀羽扇”技能信息
]]--
sgs.ai_skills["Fan"] = {
	name = "Fan",
	dummyCard = function(self)
		local suit = sgs.fire_slash:getSuitString()
		local number = sgs.fire_slash:getNumberString()
		local card_id = sgs.fire_slash:getEffectiveId()
		local card_str = ("fire_slash:Fan[%s:%s]=%d"):format(suit, number, card_id)
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if sgs.slash:isAvailable(self.player) then 
			if self.player:hasWeapon("Fan") then
				return #handcards > 0
			end
		end
		return false
	end
}
--[[
	内容：“朱雀羽扇火杀”的具体产生方式
]]--
sgs.ai_view_as_func["Fan>>FireSlash"] = function(self, card)
	local cards = self.player:getCards("h")
	for _,slash in sgs.qlist(cards) do
		if slash:isKindOf("Slash") then
			if not slash:isKindOf("FireSlash") then
				if not slash:isKindOf("ThunderSlash") then
					local suit = slash:getSuitString()
					local number = slash:getNumberString()
					local card_id = slash:getEffectiveId()
					local card_str = ("fire_slash:Fan[%s:%s]=%d"):format(suit, number, card_id)
					local fire_slash = sgs.Card_Parse(card_str)
					return fire_slash
				end
			end
		end
	end
end
sgs.ai_skill_invoke["Fan"] = function(self, data)
	local use = data:toCardUse()
	local targets = use.to
	local JinXuanDi = self.room:findPlayerBySkillName("wuling")
	local isWind = false
	if JinXuanDi then
		if JinXuanDi:getMark("@wind") > 0 then
			isWind = true
		end
	end
	for _,target in sgs.qlist(targets) do
		if self:isPartner(target) then
			if self:damageIsEffective(target, sgs.DamageStruct_Fire) then
				if target:isChained() then
					if self:isGoodChainTarget(target, nil, nil, nil, use.card) then
						return true
					end
				end
			else
				return true
			end
		else
			if self:damageIsEffective(target, sgs.DamageStruct_Fire) then
				if target:isChained() then
					if not self:isGoodChainTarget(target, nil, nil, nil, use.card) then
						return false
					end
				end
				if target:hasArmorEffect("Vine") then
					return true
				elseif target:getMark("@gale") > 0 then
					return true
				elseif isWind then
					return true
				end
			else
				return false
			end
		end
	end
	return false 
end
sgs.ai_view_as["Fan"] = function(card, player, place, class_name)
	if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
		if place ~= sgs.Player_PlaceSpecial then
			if card:objectName() == "slash" then
				local suit = card:getSuitString()
				local number = card:getNumberString()
				local card_id = card:getEffectiveId()
				return ("fire_slash:fan[%s:%s]=%d"):format(suit, number, card_id)
			end
		end
	end
end
--[[
	功能：使用朱雀羽扇
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardFan(card, use)
	use.card = card
end
sgs.ai_slash_weapon_filter["Fan"] = function(self, target)
	return target:hasArmorEffect("Vine")
end
--[[
	套路：仅使用“朱雀羽扇火杀”
]]--
sgs.ai_series["Fan>>FireSlashOnly"] = {
	name = "Fan>>FireSlashOnly", 
	IQ = 1,
	value = 2, 
	priority = 1, 
	cards = { 
		["Fan>>FireSlash"] = 1, 
		["Others"] = 1, 
	},
	enabled = function(self) 
		if self.player:hasWeapon("Fan") then
			if sgs.slash:isAvailable(self.player) then
				local cards = self.player:getCards("h")
				for _,card in sgs.qlist(cards) do
					if card:isKindOf("Slash") then
						return true
					end
				end
			end
		end
		return false
	end,
	action = function(self, handcards, skillcards) 
		local fan_skill = sgs.ai_skills["Fan"]
		local dummyCard = fan_skill["dummyCard"]()
		dummyCard:setFlags("isDummy")
		return {dummyCard}
	end,
	break_condition = function(self) 
		return false
	end,
}
table.insert(sgs.ai_card_actions["Fan>>FireSlash"], "Fan>>FireSlashOnly")
--[[****************************************************************
	白银狮子（防具）
]]--****************************************************************
sgs.card_constituent["SilverLion"] = {
	use_priority = 1.0,
}
--[[
	内容：注册白银狮子
]]--
sgs.RegistCard("SilverLion")
--[[
	功能：使用白银狮子
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardSilverLion(card, use)
	use.card = card
end
--[[****************************************************************
	藤甲（防具）
]]--****************************************************************
sgs.card_constituent["Vine"] = {
	use_priority = 0.95,
}
--[[
	内容：注册藤甲
]]--
sgs.RegistCard("Vine")
--[[
	功能：使用藤甲
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardVine(card, use)
	use.card = card
end
sgs.heavy_slash_system["vine"] = {
	name = "vine",
	reason = "Vine",
	extra_func = function(source, slash, target, isFireSlash, isThunderSlash)
		if isFireSlash then
			if not source:hasSkill("jueqing") then
				if target:hasArmorEffect("Vine") then
					if not sgs.IgnoreArmor(source, target) then
						return 1
					end
				end
			end
		end
		return 0
	end,
}
--[[****************************************************************
	骅骝（防御马）
]]--****************************************************************
sgs.card_constituent["HuaLiu"] = {
	use_priority = 2.75,
}
--[[
	功能：使用骅骝
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardHuaLiu(card, use)
	self:useCardDefensiveHorse(card, use)
end