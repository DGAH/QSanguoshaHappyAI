--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）铜雀台扩展包部分
]]--
--[[****************************************************************
	武将：铜雀台·伏皇后（群）
]]--****************************************************************
--[[
	技能：密信
	描述：出牌阶段限一次，你可以将一张手牌交给一名其他角色，该角色须对你选择的另一名角色使用一张【杀】（无距离限制），否则你选择的角色观看其手牌并获得其中任意一张。 
]]--
--[[
	内容：“密信技能卡”的卡牌成分
]]--
sgs.card_constituent["MixinCard"] = {
	use_priority = 0,
}
--[[
	内容：“密信技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["MixinCard"] = -20
--[[
	内容：注册“密信技能卡”
]]--
sgs.RegistCard("MixinCard")
--[[
	内容：“密信”技能信息
]]--
sgs.ai_skills["mixin"] = {
	name = "mixin",
	dummyCard = function(self)
		return sgs.Card_Parse("@MixinCard=.")
	end,
	enabled = function(self, handcards)
		if self.player:hasUsed("MixinCard") then
			return false
		elseif self.player:isKongcheng() then 
			return false
		end
		return true
	end,
}
--[[
	内容：“密信技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["MixinCard"] = function(self, card, use)
	if self:needBear() then 
		return 
	elseif #self.partners_noself == 0 then 
		return 
	elseif #self.opponents == 0 then 
		return 
	end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local slash	= nil
	self:sortByKeepValue(cards)
	for _,c in ipairs(cards) do
		if c:isKindOf("Slash") then
			slash = c
			break
		end
	end
	if slash then
		local card_str = "@MixinCard="..slash:getEffectiveId()
		for _, friend in ipairs(self.partners_noself) do
			if friend:hasSkills("tuntian+zaoxian") then
				if not friend:hasSkill("manjuan") then
					use.card = sgs.Card_Parse(card_str)
					if use.to then 
						use.to:append(friend) 
					end
					return
				end
			end
		end
		for _, friend in ipairs(self.friends_noself) do
			if not friend:hasSkill("manjuan") then
				use.card = sgs.Card_Parse(card_str)
				if use.to then 
					use.to:append(friend) 
				end
				return
			end
		end
	else
		local function compare_func(a, b)
			return self:getCardsNum("Slash", a) > self:getCardsNum("Slash", b)
		end
		table.sort(self.partners_noself, compare_func)
		local card_str = "@MixinCard="..cards[1]:getEffectiveId()
		for _,friend in ipairs(self.partners_noself) do
			if not friend:hasSkill("manjuan") then
				if self:getCardsNum("Slash", friend) >= 1 then
					use.card = sgs.Card_Parse(card_str)
					if use.to then 
						use.to:append(friend) 
					end
					return
				end
			end
		end
		for _,friend in ipairs(self.partners_noself) do
			if friend:hasSkills("tuntian+zaoxian") then
				if not friend:hasSkill("manjuan") then
					use.card = sgs.Card_Parse(card_str)
					if use.to then 
						use.to:append(friend) 
					end
					return
				end
			end
		end
	end
end
sgs.ai_skill_playerchosen["mixin"] = sgs.ai_skill_playerchosen["zero_card_as_slash"]
sgs.ai_skill_cardask["#mixin"] = function(self, data, pattern, target)
	if target then
		local slashes = self:getCards("Slash")
		for _,slash in ipairs(slashes) do
			if self:slashIsEffective(slash, target) then
				if self:isPartner(target) then
					if self:canLeiji(target, self.player) then 
						return slash:toString() 
					elseif self:invokeDamagedEffect(target, self.player) then 
						return slash:toString() 
					elseif self:needToLoseHp(target, self.player, nil, true) then 
						return slash:toString() 
					end
				else
					if not self:invokeDamagedEffect(target, self.player, slash) then
						if not self:canLeiji(target, self.player) then
							return slash:toString()
						end
					end
				end
			end
		end
		for _,slash in ipairs(slashes) do
			if not self:isPartner(target) then
				if not self:canLeiji(target, self.player) then 
					return slash:toString() 
				elseif not self:slashIsEffective(slash, target) then 
					return slash:toString() 
				end			
			end
		end
	end
	return "."
end
--[[
	套路：仅使用“密信技能卡”
]]--
sgs.ai_series["MixinCardOnly"] = {
	name = "MixinCardOnly",
	IQ = 2,
	value = 2,
	priority = 1,
	skills = "mixin",
	cards = {
		["MixinCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local mixin_skill = sgs.ai_skills["mixin"]
		local dummyCard = mixin_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["MixinCard"], "MixinCardOnly")
--[[
	技能：藏匿
	描述：弃牌阶段开始时，你可以回复1点体力或摸两张牌，然后将你的武将牌翻面；其他角色的回合内，当你获得（每回合限一次）/失去一次牌时，若你的武将牌背面朝上，你可以令该角色摸/弃置一张牌。 
]]--
sgs.ai_skill_invoke["cangni"] = function(self, data)
	local target = self.room:getCurrent()
	if self.player:hasFlag("cangnilose") then 
		return self:isOpponent(target) 
	end
	if self.player:hasFlag("cangniget") then 
		return self:isPartner(target) 
	end
	local num = self.player:getHandcardNum()
	local hp = self.player:getHp()
	if num + 2 <= hp then
		return true
	elseif self.player:isWounded() then
		return true
	end
	return false
end
sgs.ai_skill_choice["cangni"] = function(self, choices)
	local num = self.player:getHandcardNum()
	local hp = self.player:getHp()
	if num + 2 <= hp then
		return "draw"
	else
		return "recover"
	end
end
--[[****************************************************************
	武将：铜雀台·吉本（群）
]]--****************************************************************
--[[
	技能：毒医
	描述：出牌阶段限一次，你可以亮出牌堆顶的一张牌并交给一名角色，若此牌为黑色，该角色不能使用或打出其手牌，直到回合结束。 
]]--
--[[
	内容：注册“毒医技能卡”
]]--
sgs.RegistCard("DuyiCard")
--[[
	内容：“毒医”技能信息
]]--
sgs.ai_skills["duyi"] = {
	name = "duyi",
	dummyCard = function(self)
		return sgs.Card_Parse("@DuyiCard=.")
	end,
	enabled = function(self, handcards)
		return not self.player:hasUsed("DuyiCard")
	end,
}
--[[
	内容：“毒医技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["DuyiCard"] = function(self, card, use)
	use.card = card
end
sgs.ai_skill_playerchosen["duyi"] = function(self, targets)
	if self:needBear() then 
		return self.player 
	end
	local to
	if self:getOverflow() < 0 then
		to = self:findPlayerToDraw(true)
	else
		to = self:findPlayerToDraw(false)
	end
	if to then 
		return to
	end
	return self.player
end
--[[
	套路：仅使用“毒医技能卡”
]]--
sgs.ai_series["DuyiCardOnly"] = {
	name = "DuyiCardOnly",
	IQ = 2,
	value = 2,
	priority = 1,
	skills = "duyi",
	cards = {
		["DuyiCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local duyi_skill = sgs.ai_skills["duyi"]
		local dummyCard = duyi_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["DuyiCard"], "DuyiCardOnly")
--[[
	技能：断指
	描述：当你成为其他角色使用的牌的目标后，你可以弃置其至多两张牌（也可以不弃置），然后失去1点体力。 
]]--
sgs.ai_skill_invoke["duanzhi"] = function(self, data)
	local use = data:toCardUse()
	local source = use.from
	if source then
		if self:isOpponent(source) then
			if use.card:getSubtype() == "attack_card" then
				if self.player:getHp() == 1 then
					if not self:getCard("Peach") then
						if not self:getCard("Analeptic") then
							if not self:amLord() then
								if self:getAllPeachNum() == 0 then
									self.player:setFlags("AI_doNotSave")
									return true
								end
							end
						end
					end
				end
			end
			if self.player:getHp() > 2 then
				if not self:doNotDiscard(source, "he", true, 2) then
					return true
				end
			end
		end
	end
	return false
end
sgs.ai_skill_choice["duanzhi"] = function(self, choices)
	return "discard"
end
--[[****************************************************************
	武将：铜雀台·伏完（群）
]]--****************************************************************
--[[
	技能：奉印
	描述：其他角色的回合开始时，若其当前的体力值不比你少，你可以交给其一张【杀】，令其跳过其出牌阶段和弃牌阶段。 
]]--
sgs.ai_skill_use["@@fengyin"] = function(self, data)
	if self:needBear() then 
		return "." 
	end
	local cards = self.player:getHandcards()
	local card
	for _,c in sgs.qlist(cards)  do
		if c:isKindOf("Slash") then
			card = c
			break
		end
	end
	if card then
		local card_id = card:getEffectiveId()
		local target = self.room:getCurrent()
		if self:isPartner(target) then
			if self:willSkipPlayPhase(target) then
				if target:getHandcardNum() + 2 > target:getHp() then
					if target:getHp() >= self.player:getHp() then
						return "@FengyinCard="..card_id
					end
				end
			end
		elseif self:isOpponent(target) then
			if not self:willSkipPlayPhase(target) then
				if target:getHandcardNum() >= target:getHp() then
					if target:getHp() >= self.player:getHp() then
						return "@FengyinCard="..card_id
					end
				end
			end
		end
	end
	return "."
end
--[[
	技能：持重（锁定技）
	描述：你的手牌上限等于你的体力上限；其他角色死亡时，你加1点体力上限。 
]]--
--[[****************************************************************
	武将：铜雀台·穆顺（群）
]]--****************************************************************
--[[
	技能：谋溃
	描述：每当你指定【杀】的目标后，你可以选择一项：摸一张牌，或弃置目标角色一张牌：若如此做，此【杀】被目标角色的【闪】抵消后，该角色弃置你的一张牌。 
]]--
sgs.ai_skill_invoke["moukui"] = function(self, data)
	local target = data:toPlayer()
	sgs.moukui_target = target
	if self:isPartner(target) then 
		return self:needToThrowArmor(target) 
	else 
		return true 
	end 
end
sgs.ai_skill_choice["moukui"] = function(self, choices, data)
	local target = sgs.moukui_target
	if self:isOpponent(target) then
		if self:doNotDiscard(target) then
			return "draw"
		end
	end	
	return "discard"
end
--[[****************************************************************
	武将：铜雀台·刘协（群）
]]--****************************************************************
--[[
	技能：天命
	描述：每当你被指定为【杀】的目标时，你可以弃置两张牌，然后摸两张牌。若全场唯一的体力值最多的角色不是你，该角色也可以弃置两张牌，然后摸两张牌。 
]]--
sgs.ai_skill_invoke["tianming"] = function(self, data)
	self.tianming_discard = nil
	if self.player:isNude() then 
		return true 
	end
	if self.player:hasSkill("manjuan") then
		if self.player:getPhase() == sgs.Player_NotActive then 
			return false 
		end
	end
	local cards = self.player:getCards("he")
	-- if self:canHit() then
		-- return true
	-- else
		if cards:length() < 3 then
			return false
		end
	--end
	local unprefered_cards = {}
	for _, c in sgs.qlist(cards) do
		if not sgs.isCard("Peach", c, self.player) then
			table.insert(unprefered_cards, c:getId())
		end
	end
	if #unprefered_cards == 0 then
		local handcards = self.player:getHandcards()
		handcards = sgs.QList2Table(handcards)
		if self:getCardsNum("Slash") > 1 then
			self:sortByKeepValue(handcards)
			for _, card in ipairs(handcards) do
				if card:isKindOf("Slash") then 
					table.insert(unprefered_cards, card:getId()) 
				end
			end
			table.remove(unprefered_cards, 1)
		end
		local armor = self.player:getArmor()
		if self:needToThrowArmor() then
			table.insert(unprefered_cards, armor:getId())
		end
		local num = self:getCardsNum("Jink") - 1
		if armor then 
			num = num + 1 
		end
		if num > 0 then
			for _, card in ipairs(handcards) do
				if card:isKindOf("Jink") and num > 0 then
					table.insert(unprefered_cards, card:getId())
					num = num - 1
				end
			end
		end
		num = self.player:getHandcardNum()
		for _, card in ipairs(handcards) do
			local canInsert = false
			if card:isKindOf("Weapon") then
				if num < 3 then
					canInsert = true
				end
			elseif sgs.isKindOf("OffensiveHorse|AmazingGrace|Lightning", card) then
				canInsert = true
			elseif self:getSameTypeEquip(card, self.player) then
				canInsert = true
			end
			if canInsert then
				table.insert(unprefered_cards, card:getId())
			end
		end
		local weapon = self.player:getWeapon()
		if weapon and num < 3 then
			table.insert(unprefered_cards, weapon:getId())
		end
		local horse = self.player:getOffensiveHorse()
		if horse and weapon then
			table.insert(unprefered_cards, horse:getId())
		end
	end
	local to_discard = {}
	for index = #unprefered_cards, 1, -1 do
		local id = unprefered_cards[index]
		local card = sgs.Sanguosha:getCard(id)
		if not self.player:isJilei(card) then 
			table.insert(to_discard, id) 
		end
	end
	if #to_discard >= 2 or #to_discard == #handcards then
		self.tianming_discard = to_discard
		return true
	end
end
sgs.ai_skill_discard["tianming"] = function(self, discard_num, min_num, optional, include_equip)
	local discard = self.tianming_discard
	if discard and #discard >= 2 then
		return { discard[1], discard[2] }
	else
		return self:askForDiscard("dummyreason", 2, 2, false, true)
	end
end
--[[
	技能：密诏
	描述：出牌阶段限一次，你可以将所有手牌（至少一张）交给一名其他角色：若如此做，你令该角色与另一名由你指定的有手牌的角色拼点：若一名角色赢，视为该角色对没赢的角色使用一张【杀】。 
]]--
--[[
	内容：“密诏技能卡”的卡牌成分
]]--
sgs.card_constituent["MizhaoCard"] = {
	use_priority = 1.5,
}
--[[
	内容：“密诏技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["MizhaoCard"] = 0
sgs.ai_playerchosen_intention["mizhao"] = 10
--[[
	内容：注册“密诏技能卡”
]]--
sgs.RegistCard("MizhaoCard")
--[[
	内容：“密诏”技能信息
]]--
sgs.ai_skills["mizhao"] = {
	name = "mizhao",
	dummyCard = function(self)
		return sgs.Card_Parse("@MizhaoCard=.")
	end,
	enabled = function(self, handcards)
		if self.player:hasUsed("MizhaoCard") then
			return false
		elseif self.player:isKongcheng() then
			return false
		end
		return true
	end,
}
--[[
	内容：“密诏技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["MizhaoCard"] = function(self, card, use)
	if self:needBear() then 
		return 
	end
	local handcards = self.player:getHandcards()
	for _, peach in sgs.qlist(handcards) do
		if peach:isKindOf("Peach") then
			if self.player:isWounded() then
				if not self:needToLoseHp(self.player, nil, nil, true, true) then
					use.card = peach
					return
				end
			end
		end
	end
	local num = self.player:getHandcardNum()
	local count = 0
	for _, enemy in ipairs(self.opponents) do
		if not enemy:isKongcheng() then 
			count = count + 1 
		end
	end
	local target = nil
	if num == 1 and count >= 1 then
		if #self.opponents > 1 then
			local trash = self:getCard("Disaster") 
			trash = trash or self:getCard("GodSalvation") 
			trash = trash or self:getCard("AmazingGrace") 
			trash = trash or self:getCard("Slash") 
			trash = trash or self:getCard("FireAttack")
			if trash then
				self:sort(self.opponents, "handcard")
				for _, enemy in ipairs(self.opponents) do
					if not enemy:hasSkills("tuntian+zaoxian") then
						if not (enemy:hasSkill("manjuan") and enemy:isKongcheng()) then
							target = enemy
							break
						end
					end
				end
			end
		end
	end
	if not target then
		if count >= 1 then 
			self:sort(self.partners_noself, "defense")
			self.partners_noself = sgs.reverse(self.partners_noself)
			for _, friend in ipairs(self.partners_noself) do
				if friend:hasSkills("tuntian+zaoxian") then
					if not friend:hasSkill("manjuan") then
						if not self:isWeak(friend) then
							target = friend
							break
						end
					end
				end
			end
			if not target then
				for _, friend in ipairs(self.partners_noself) do
					if not friend:hasSkill("manjuan") then
						target = friend
						break
					end
				end
			end
		end
	end
	if target then
		local ids = {}
		for _,c in sgs.qlist(handcards) do
			local id = c:getId()
			table.insert(ids, id) 
		end
		local card_str = "@MizhaoCard=" .. table.concat(ids, "+")
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		target:setFlags("AI_MizhaoTarget")
		if use.to then 
			use.to:append(target) 
		end
	end
end
sgs.ai_skill_playerchosen["mizhao"] = function(self, targets)
	self:sort(self.opponents, "defense")
	local others = self.room:getOtherPlayers(self.player)
	local from = nil
	for _,p in sgs.qlist(others) do
		if p:hasFlag("AI_MizhaoTarget") then
			from = p
			from:setFlags("-AI_MizhaoTarget")
			break
		end
	end
	for _, to in ipairs(self.opponents) do
		if targets:contains(to) then
			if self:slashIsEffective(sgs.slash, to, nil, from) then
				if not self:invokeDamagedEffect(to, from, sgs.slash) then
					if not self:needToLoseHp(to, from, true, true) then
						if not self:canLeiji(to, from) then
							return to
						end
					end
				end
			end
		end
	end
	for _, to in ipairs(self.opponents) do
		if targets:contains(to) then
			return to
		end
	end
	return targets:first()
end
sgs.ai_skill_pindian["mizhao"] = function(self, requestor, maxcard, mincard)
	local target = requestor
	if self.player:objectName() == requestor:objectName() then
		local others = self.room:getOtherPlayers(self.player)
		for _,p in sgs.qlist(others) do
			if p:hasFlag("MizhaoPindianTarget") then
				target = p
				break
			end
		end
	end
	local handcards = self.player:getHandcards()
	local cards = sgs.QList2Table(handcards)
	local function compare_funcA(a, b)
		return a:getNumber() > b:getNumber()
	end
	local function compare_funcB(a, b)
		return a:getNumber() < b:getNumber()
	end
	if self:isPartner(target) and self.player:getHp() > target:getHp() then
		table.sort(cards, compare_funcA)
	else
		table.sort(cards, compare_funcB)
	end
	for _, card in ipairs(cards) do
		if sgs.getKeepValue(card, self.player) < 8 then
			return card
		elseif card:isKindOf("EquipCard") then 
			return card
		end
	end
	return cards[1]
end
--[[
	套路：仅使用“密诏技能卡”
]]--
sgs.ai_series["MizhaoCardOnly"] = {
	name = "MizhaoCardOnly",
	IQ = 2,
	value = 4,
	priority = 2,
	skills = "mizhao",
	cards = {
		["MizhaoCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		for _,mizhao_card ipairs(skillcards) do
			if mizhao_card:objectName() == "MizhaoCard" then
				return {mizhao_card}
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["MizhaoCard"], "MizhaoCardOnly")
--[[****************************************************************
	武将：铜雀台·灵雎（群）
]]--****************************************************************
--[[
	技能：竭缘
	描述：每当你对一名其他角色造成伤害时，若其体力值大于或等于你的体力值，你可以弃置一张黑色手牌：若如此做，此伤害+1。每当你受到一名其他角色造成的伤害时，若其体力值大于或等于你的体力值，你可以弃置一张红色手牌：若如此做，此伤害-1。 
]]--
sgs.ai_skill_cardask["@jieyuan-increase"] = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isPartner(target) then 
		return "." 
	end
	if target:hasArmorEffect("SilverLion") then 
		return "." 
	end
	local handcards = self.player:getHandcards()
	local cards = {}
	for _,black in sgs.qlist(handcards) do
		if black:isBlack() then
			table.insert(cards, black)
		end
	end
	if #cards > 0 then
		self:sortByKeepValue(cards)
		return "$"..cards[1]:getEffectiveId()
	end
	return "."
end
sgs.ai_skill_cardask["@jieyuan-decrease"] = function(self, data)
	local damage = data:toDamage()
	local handcards = self.player:getHandcards()
	local cards = {}
	for _,red in sgs.qlist(handcards) do
		if red:isRed() then
			table.insert(cards, red)
		end
	end
	if #cards > 0 then
		self:sortByKeepValue(cards)
		if damage.card then
			if damage.card:isKindOf("Slash") then		 
				if self:hasHeavySlashDamage(damage.from, damage.card, self.player) then
					return "$" .. cards[1]:getEffectiveId()
				end
			end
		end
		if damage.damage <= 1 then
			if self:invokeDamagedEffect(self.player, damage.from) then 
				return "." 
			elseif self:needToLoseHp(self.player, damage.from) then 
				return "." 
			end
		end
		return "$" .. cards[1]:getEffectiveId()
	end
	return "."
end
--[[
	内容：“竭缘”卡牌需求
]]--
sgs.card_need_system["jieyuan"] = sgs.card_need_system["beige"]
sgs.heavy_slash_system["jieyuan_increase"] = {
	name = "jieyuan_increase",
	reason = "jieyuan",
	extra_func = function(source, slash, target, isFireSlash, isThunderSlash)
		local from_hp = source:getHp()
		local to_hp = target:getHp()
		if source:hasSkill("jieyuan") then
			if not source:hasSkill("jueqing") then
				if to_hp >= from_hp then
					if source:getHandcardNum() >= 3 then
						return 1
					end
				end
			end
		end
		return 0
	end,
}
sgs.heavy_slash_system["jieyuan_decrease"] = {
	name = "jieyuan_decrease",
	reason = "jieyuan",
	extra_func = function(source, slash, target, isFireSlash, isThunderSlash)
		local from_hp = source:getHp()
		local to_hp = target:getHp()
		if target:hasSkill("jieyuan") then
			if not source:hasSkill("jueqing") then
				if to_hp <= from_hp then
					if target:getHandcardNum() > 3 then
						return -1
					else
						local count = sgs.getKnownCard(target, "heart")
						count = count + sgs.getKnownCard(target, "diamond")
						if count > 0 then
							return -1
						end
					end
				end
			end
		end
		return 0
	end,
}
--[[
	技能：焚心（限定技）
	描述：若你不是主公，你杀死一名非主公其他角色检验胜利条件之前，你可以与该角色交换身份牌。 
]]--
sgs.ai_skill_invoke["fenxin"] = function(self, data)
	local target = data:toPlayer()
	if self:mayRenegade(target) then
		return false
	end
	local target_camp = sgs.ai_camp[target:objectName()]
	if target_camp ~= self.camp then
		local reportA = sgs.CreateCampReport(target_camp)
		local reportB = sgs.CreateCampReport(self.camp)
		if reportA["defense"] > reportB["defense"] then
			return true
		end
	end
	return false
end