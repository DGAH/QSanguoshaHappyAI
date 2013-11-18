--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）翼扩展包部分
]]--
--[[****************************************************************
	武将：翼·夏侯惇（魏）
]]--****************************************************************
--[[
	技能：刚烈
	描述：每当你受到伤害后，你可以进行一次判定，若判定结果不为♥，则你选择一项：令伤害来源弃置两张手牌，或对伤害来源造成1点伤害。 
]]--
sgs.ai_skill_invoke["neoganglie"] = function(self, data)
	local damage = data:toDamage()
	local source = damage.from
	if not source then
		local ZhangJiao = self.room:findPlayerBySkillName("guidao")
		return ZhangJiao and self:isPartner(ZhangJiao)
	end
	if self:isPartner(source) then
		if self:invokeDamagedEffect(source, self.player) then
			source:setFlags("ganglie_target")
			return true
		elseif self:needToLoseHp(source, self.player, nil, true) then
			source:setFlags("ganglie_target")
			return true
		end
	end
	if self:invokeDamagedEffect(source, self.player) then
		if self:isOpponent(source) then
			if source:getHandcardNum() < 2 then 
				return false
			end
		end
	end
	return not self:isPartner(source)
end
sgs.ai_skill_choice["neoganglie"] = function(self, choices)
	local target = nil
	local others = self.room:getOtherPlayers(self.player)
	for _, player in sgs.qlist(others) do
		if player:hasFlag("ganglie_target") then
			target = player
			target:setFlags("-ganglie_target")
			break
		end
	end
	if target then
		if self:isPartner(target) then
			if self:invokeDamagedEffect(target, self.player) then
				return "damage"
			elseif self:needToLoseHp() then
				return "damage"
			end
		elseif target:getHandcardNum() > 1 then
			if self:invokeDamagedEffect(target, self.player) then
				return "throw"
			elseif self:needToLoseHp(target, self.player) then
				return "throw"
			end
		end
	end
	return "damage"
end
sgs.ai_skill_discard["neoganglie"] = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local handcards = self.player:getHandcards()
	local cards = sgs.QList2Table(handcards)
	local index = 0
	self:sortByKeepValue(cards)
	cards = sgs.reverse(cards)
	for i = #cards, 1, -1 do
		local card = cards[i]
		if not self.player:isJilei(card) then
			table.insert(to_discard, card:getEffectiveId())
			table.remove(cards, i)
			index = index + 1
			if index == 2 then 
				break 
			end
		end
	end	
	return to_discard
end
sgs.ai_damage_requirement["neoganglie"] = function(self, source, target)
	if target:hasSkill("neoganglie") then
		if source:getHp() <= 2 then
			if not source:hasSkill("buqu") then
				if self:isOpponent(source, target) then
					if sgs.isGoodTarget(self, source, self.opponents) then
						if not self:invokeDamagedEffect(source, target) then
							if not self:needToLoseHp(source, target) then
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
--[[****************************************************************
	武将：翼·许褚（魏）
]]--****************************************************************
--[[
	技能：裸衣
	描述：出牌阶段限一次，你可以弃置一张装备牌，若如此做，本回合你使用【杀】或【决斗】对目标角色造成伤害时，此伤害+1。
]]--
--[[
	内容：“裸衣技能卡”的卡牌成分
]]--
sgs.card_constituent["LuoyiCard"] = {
	use_priority = 9.2,
}
--[[
	内容：注册“裸衣技能卡”
]]--
sgs.RegistCard("LuoyiCard")
--[[
	内容：“裸衣”技能信息
]]--
sgs.ai_skills["neoluoyi"] = {
	name = "neoluoyi",
	dummyCard = function(self)
		return sgs.Card_Parse("@LuoyiCard=.")
	end,
	enabled = function(self, handcards)
		if self.player:hasUsed("LuoyiCard") then 
			return false
		end
		local cards = self.player:getCards("he")
		for _,equip in sgs.qlist(cards) do
			if equip:isKindOf("EquipCard") then
				return true
			end
		end
		return false
	end,
}
--[[
	内容：“裸衣技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["LuoyiCard"] = function(self, card, use)
	if self:needBear() then 
		return 
	end
	local acard = nil
	if self:needToThrowArmor() then
		local armor = self.player:getArmor()
		local card_str = "@LuoyiCard=" .. armor:getEffectiveId()
		acard = sgs.Card_Parse(card_str)
		use.card = acard
		return 
	end
	if sgs.slash:isAvailable(self.player) then
		local handcards = self.player:getHandcards()
		local cards = self.player:getCards("he")
		local equipNum = 0
		for _,equip in sgs.qlist(cards) do
			if equip:isKindOf("EquipCard") then
				local flag = true
				if equip:isKindOf("Weapon") then
					if self.player:hasEquip(equip) then
						flag = false
					end
				end
				if flag then
					equipNum = equipNum + 1
				end
			end
		end
		if equipNum > 0 then
			local slashTargetNum = 0
			local noHorseTargetNum = 0
			local duelTargetNum = 0
			local off_horse = self.player:getOffensiveHorse()
			local range = self.player:getAttackRange()
			for _,c in sgs.qlist(handcards) do
				if c:isKindOf("Slash") then
					for _,enemy in ipairs(self.opponents) do
						if self.player:canSlash(enemy, card) then
							if self:slashIsEffective(card, enemy) then
								if self:friendshipLevel(enemy) < -4 then
									if sgs.isGoodTarget(self, enemy, self.opponents) then
										local flag = false
										if sgs.getCardsNum("Jink", enemy) < 1 then
											flag = true
										elseif self:isEquip("Axe") then
											if cards:length() > 4 then
												flag = true
											end
										end
										if flag then
											slashTargetNum = slashTargetNum + 1
											if off_horse then
												if self.player:distanceTo(enemy, 1) <= range then
													noHorseTargetNum = noHorseTargetNum + 1
												end
											end
										end
									end
								end
							end
						end
					end
				elseif c:isKindOf("Duel") then
					for _, enemy in ipairs(self.opponents) do
						if self:getCardsNum("Slash") >= sgs.getCardsNum("Slash", enemy) then
							if sgs.isGoodTarget(self, enemy, self.opponents) then
								if self:friendshipLevel(enemy) < -4 then
									if not self:cannotBeHurt(enemy, 2) then
										if self:damageIsEffective(enemy) then
											if enemy:getMark("@late") == 0 then
												duelTargetNum = duelTargetNum + 1 
											end
										end
									end
								end
							end
						end
					end
				end
			end
			if slashTargetNum + duelTargetNum > 0 then
				local usecard = nil
				if self:needToThrowArmor() then
					usecard = self.player:getArmor()
				else
					for _, c in sgs.qlist(cards) do
						if c:isKindOf("EquipCard") then
							if not self.player:hasEquip(c) then 
								usecard = c
								break
							end
						end
					end
				end
				if not usecard then
					if off_horse then
						if noHorseTargetNum == 0 then
							for _, c in sgs.qlist(cards) do
								if c:isKindOf("EquipCard") then 
									if not c:isKindOf("OffensiveHorse") then 
										usecard = c
										break
									end
								end
							end
							if not usecard then
								if duelTargetNum == 0 then 
									return 
								end
							end
						end
					end
				end
				if not usecard then
					for _, c in sgs.qlist(cards) do
						if c:isKindOf("EquipCard") then
							local can_use = true
							if c:isKindOf("Weapon") then
								if self.player:hasEquip(c) then
									can_use = false
								end
							end
							if can_use then
								usecard = c
								break
							end
						end
					end
				end
				if usecard then
					local card_str = "@LuoyiCard=" .. usecard:getEffectiveId()
					acard = sgs.Card_Parse(card_str)
				end
			end
		end
	end
	if acard then
		self:speak("luoyi")
		use.card = acard
	end
end
sgs.heavy_slash_system["neoluoyi"] = {
	name = "neoluoyi",
	reason = "neoluoyi",
	extra_func = function(source, slash, target, isFireSlash, isThunderSlash)
		if source:hasFlag("neoluoyi") then
			return 1
		end
		return 0
	end,
}
--[[
	套路：仅使用“裸衣技能卡”
]]--
sgs.ai_series["LuoyiCardOnly"] = {
	name = "LuoyiCardOnly",
	IQ = 2,
	value = 2,
	priority = 4,
	skills = "neoluoyi",
	cards = {
		["LuoyiCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local luoyi_skill = sgs.ai_skills["neoluoyi"]
		local dummyCard = luoyi_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["LuoyiCard"], "LuoyiCardOnly")
--[[****************************************************************
	武将：翼·曹仁（魏）
]]--****************************************************************
--[[
	技能：据守
	描述：结束阶段开始时，你可以摸X+2张牌，然后将你的武将牌翻面。（X为你已损失的体力值） 
]]--
sgs.ai_skill_invoke["neojushou"] = function(self, data)
	if self.player:faceUp() then
		for _,friend in ipairs(self.partners_noself) do
			if self:hasSkills("fangzhu|jilve", friend) then
				return true
			end
		end
		if self:hasSkills("jiushi|toudu|jushou|kuiwei") then
			return true
		end
	else
		return true
	end
	return self:isWeak()
end
--[[****************************************************************
	武将：翼·关羽（蜀）
]]--****************************************************************
--[[
	技能：武圣
	描述：你可以将一张红色牌当【杀】使用或打出。 
]]--
--[[
	技能：义释
	描述：每当你使用♥【杀】对目标角色造成伤害时，你可以防止此伤害，然后获得其区域里的一张牌。 
]]--
sgs.ai_skill_invoke["yishi"] = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isPartner(target) then
		if damage.damage == 1 then
			if self:invokeDamagedEffect(target, self.player) then
				if target:getJudgingArea():isEmpty() then
					return false
				elseif target:containsTrick("YanxiaoCard") then
					return false
				end
			end
		end
		return true
	else
		if self:hasHeavySlashDamage(self.player, damage.card, target) then 
			return false 
		end
		if self:isWeak(target) then 
			return false 
		end
		if self:doNotDiscard(target, "e", true) then
			return false
		end
		if self:invokeDamagedEffect(target, self.player, true) then
			return true
		else
			local armor = target:getArmor() 
			if armor then
				if not armor:isKindOf("SilverLion") then 
					return true 
				end
			end
		end
		if self:getDangerousCard(target) then 
			return true 
		end
		if target:getDefensiveHorse() then 
			return true 
		end
		return false
	end
end
--[[****************************************************************
	武将：翼·张飞（蜀）
]]--****************************************************************
--[[
	技能：咆哮（锁定技）
	描述：你于出牌阶段内使用【杀】无数量限制。 
]]--
--[[
	技能：探囊（锁定技）
	描述：你与其他角色的距离-X。（X为你已损失的体力值） 
]]--
--[[****************************************************************
	武将：翼·赵云（翼）
]]--****************************************************************
--[[
	技能：龙胆
	描述：你可以将一张【杀】当【闪】使用或打出，或将一张【闪】当【杀】使用或打出。 
]]--
--[[
	技能：义从（锁定技）
	描述：若你的体力值大于2，你与其他角色的距离-1；若你的体力值小于或等于2，其他角色与你的距离+1。 
]]--
--[[****************************************************************
	武将：翼·周瑜（吴）
]]--****************************************************************
--[[
	技能：英姿
	描述：摸牌阶段，你可以额外摸一张牌。 
]]--
--[[
	技能：反间
	描述：出牌阶段限一次，你可以选择一张手牌并令一名其他角色选择一种花色，然后该角色获得该牌并展示之。若此牌花色与该角色所选花色不同，你对其造成1点伤害。 
]]--
--[[
	内容：“反间技能卡”的卡牌成分
]]--
sgs.card_constituent["NeoFanjianCard"] = {
	damage = 2,
}
--[[
	内容：“反间技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["NeoFanjianCard"] = sgs.ai_card_intention["FanjianCard"]
--[[
	内容：注册“反间技能卡”
]]--
sgs.RegistCard("NeoFanjianCard")
--[[
	内容：“反间”技能信息
]]--
sgs.ai_skills["neofanjian"] = {
	name = "neofanjian",
	dummyCard = function(self)
		return sgs.Card_Parse("@NeoFanjianCard=.")
	end,
	enabled = function(self, handcards)
		if self.player:hasUsed("NeoFanjianCard") then
			return false
		elseif self.player:isKongcheng() then
			return false
		end
		return true
	end,
}
--[[
	内容：“反间技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["NeoFanjianCard"] = function(self, card, use)
	self:sort(self.opponents, "defense")
	local targets = {}
	for _,enemy in ipairs(self.opponents) do
		if self:canAttack(enemy) then
			if not self:hasSkills("qingnang|tianxiang", enemy) then
				table.insert(targets, enemy)
			end
		end
	end
	if #targets > 0 then
		local WuGuoTai = self.room:findPlayerBySkillName("buyi")
		local handcards = self.player:getCards("h")
		handcards = sgs.QList2Table(handcards)
		self:sortByKeepValue(handcards)
		for _,target in ipairs(targets) do
			local care = false
			if WuGuoTai then
				if target:getHp() <= 1 then
					if self:isPartner(WuGuoTai, target) then
						care = true
					end
				end
			end
			local usecard = nil
			for _,c in ipairs(handcards) do
				local flag = not sgs.isKindOf("Peach|Analeptic", c)
				local suit = c:getSuit()
				if flag and care then
					flag = ( c:isKindOf("BasicCard") )
				end
				if flag and self:hasSkills("longhun|noslonghun", target) then
					flag = ( suit ~= sgs.Card_Heart )
				end
				if flag and self:hasSkills("jiuchi", target) then
					flag = ( suit ~= sgs.Card_Spade )
				end
				if flag and self:hasSkills("jijiu", target) then
					flag = ( c:isBlack() )
				end
				if flag then
					usecard = c
					break
				end
			end
			if usecard then
				local keepValue = sgs.getKeepValue(usecard, self.player)
				if usecard:getSuit() == sgs.Card_Diamond then
					keepValue = keepValue + 0.5
				end
				if keepValue < 6 then
					local card_str = "@NeoFanjianCard=" .. usecard:getEffectiveId()
					local acard = sgs.Card_Parse(card_str)
					use.card = acard
					if use.to then
						use.to:append(target)
					end
					return 
				end
			end
		end
	end
end
sgs.ai_skill_suit["neofanjian"] = function(self)
	local map = {0, 0, 1, 2, 2, 3, 3, 3}
	local suit = map[math.random(1, 8)]
	if self.player:hasSkill("hongyan") then
		if suit == sgs.Card_Spade then 
			return sgs.Card_Heart 
		end
	end
	return suit
end
--[[
	套路：仅使用“反间技能卡”
]]--
sgs.ai_series["NeoFanjianCardOnly"] = {
	name = "NeoFanjianCardOnly",
	IQ = 2,
	value = 4,
	priority = 1,
	skills = "neofanjian",
	cards = {
		["NeoFanjianCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local fanjian_skill = sgs.ai_skills["neofanjian"]
		local dummyCard = fanjian_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["NeoFanjianCard"], "NeoFanjianCardOnly")
--[[****************************************************************
	武将：翼·公孙瓒（群）
]]--****************************************************************
--[[
	技能：筑楼
	描述：结束阶段开始时，你可以摸两张牌，然后选择一项：失去1点体力，或弃置一张武器牌。 
]]--
sgs.ai_skill_invoke["zhulou"] = function(self, data)
	local weaponnum = 0
	local handcards = self.player:getCards("h")
	for _, card in sgs.qlist(handcards) do
		if card:isKindOf("Weapon") then
			weaponnum = weaponnum + 1
		end
	end
	if weaponnum > 0 then 
		return true 
	end
	local hp = self.player:getHp()
	if hp > 2 then
		if self.player:getHandcardNum() < 3 then
			return true
		end
	elseif hp < 3 then
		if self.player:getWeapon() then
			return true
		end
	end
	return false
end
sgs.ai_skill_cardask["@zhulou-discard"] =  function(self, data)
	local weapon = self.player:getWeapon()
	if weapon then
		return "$" .. weapon:getEffectiveId()
	end
	local cards = self.player:getCards("he")
	for _,card in sgs.qlist(cards) do
		if card:isKindOf("Weapon") then
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end
sgs.zhulou_keep_value = sgs.qiangxi_keep_value
--[[
	内容：“筑楼”卡牌需求
]]--
sgs.card_need_system["zhulou"] = sgs.card_need_system["weapon"]
--[[
	技能：义从（锁定技）
	描述：若你的体力值大于2，你与其他角色的距离-1；若你的体力值小于或等于2，其他角色与你的距离+1。 
]]--