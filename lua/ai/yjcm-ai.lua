--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）一将成名扩展包部分
]]--
--[[****************************************************************
	武将：一将成名·曹植（魏）
]]--****************************************************************
--[[
	技能：落英
	描述：每当其他角色的一张♣牌因弃置或判定而置入弃牌堆时，你可以获得之。 
]]--
sgs.ai_skill_invoke["luoying"] = function(self, data)
	if self.player:hasFlag("DimengTarget") then
		local another
		local others = self.room:getOtherPlayers(self.player)
		for _, player in sgs.qlist(others) do
			if player:hasFlag("DimengTarget") then
				another = player
				break
			end
		end
		if not another then
			return false
		elseif not self:isPartner(another) then 
			return false 
		end
	end
	if self:needKongcheng(self.player, true) then
		return false
	end
	return true
end
sgs.ai_skill_askforag["luoying"] = function(self, card_ids)
	if self:needKongcheng(self.player, true) then 
		return card_ids[1] 
	else 
		return -1 
	end
end
--[[
	技能：酒诗
	描述：每当你需要使用一张【酒】时，若你的武将牌正面朝上，你可以将你的武将牌翻面，视为使用一张【酒】；若你的武将牌背面朝上时你受到伤害，你可以在伤害结算后将你的武将牌翻转至正面朝上。 
]]--
sgs.ai_skill_invoke["jiushi"] = function(self, data)
	return not self.player:faceUp()
end
sgs.ai_cardsview["jiushi"] = function(self, class_name, player)
	if class_name == "Analeptic" then
		if player:hasSkill("jiushi") then
			if player:faceUp() then
				return ("analeptic:jiushi[no_suit:0]=.")
			end
		end
	end
end
--[[
	内容：“酒诗”统计信息
]]--
sgs.card_count_system["jiushi"] = {
	name = "jiushi",
	pattern = "Analeptic",
	ratio = 1,
	statistics_func = function(class_name, player, data)
		if player:hasSkill("jiushi") then
			local count = data["count"]
			count = count + 1
			return count
		end
	end
}
--[[****************************************************************
	武将：一将成名·陈宫（群）
]]--****************************************************************
--[[
	技能：智迟
	描述：你的回合外，每当你受到一次伤害后，【杀】和非延时类锦囊牌对你无效，直到回合结束。 
]]--
sgs.trick_invalid_system["zhichi"] = {
	name = "zhichi",
	reason = "zhichi",
	judge_func = function(card, target, source)
		return target:getMark("@late") > 0
	end,
}
sgs.slash_invalid_system["zhichi"] = {
	name = "zhichi",
	reason = "zhichi",
	judge_func = function(slash, target, source, ignore_armor)
		return target:getMark("@late") > 0
	end,
}
sgs.amazing_grace_invalid_system["zhichi"] = {
	name = "zhichi",
	reason = "zhichi",
	judge_func = function(self, card, target, source)
		if target:hasSkill("zhichi") then
			return target:getMark("@late") > 0
		end
		return false
	end
}
--[[
	技能：明策
	描述：出牌阶段限一次，你可以将一张装备牌或【杀】交给一名其他角色，该角色需视为对其攻击范围内你选择的另一名角色使用一张【杀】，若其未如此做或其攻击范围内没有使用【杀】的目标，其摸一张牌。 
]]--
--[[
	内容：“明策技能卡”的卡牌成分
]]--
sgs.card_constituent["MingceCard"] = {
	use_value = 5.9,
	use_priority = 4,
}
--[[	
	内容：“明策技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["MingceCard"] = -70
--[[
	内容：注册“明策技能卡”
]]--
sgs.RegistCard("MingceCard")
--[[
	内容：“明策”技能信息
]]--
sgs.ai_skills["mingce"] = {
	name = "mingce",
	dummyCard = function(self)
		local card_str = "@MingceCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if not self.player:hasUsed("MingceCard") then
			return not self.player:isNude()
		end
		return false
	end,
}
--[[
	内容：“明策技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["MingceCard"] = function(self, card, use)
	local usecard = nil
	if self:needToThrowArmor() then
		usecard = self.player:getArmor()
	end
	if not usecard then
		local handcards = self.player:getCards("h")
		handcards = sgs.QList2Table(handcards)
		self:sortByUseValue(handcards, true)
		for _,c in ipairs(handcards) do
			if c:isKindOf("Slash") then
				if self:getCardsNum("Slash") > 1 then
					usecard = c
					break
				else
					local dummy_use = {
						isDummy = true,
						to = sgs.SPlayerList(),
					}
					self:useBasicCard(c, dummy_use)
					if dummy_use.to:isEmpty() then
						usecard = c
						break
					elseif dummy_use.to:length() == 1 then
						local victim = dummy_use.to:first()
						if not self:hasHeavySlashDamage(self.player, c, victim) then
							usecard = c
							break
						end
					end
				end
			elseif c:isKindOf("EquipCard") then
				usecard = c
				break
			end
		end
	end
	if not usecard then
		local equips = self.player:getCards("e")
		for _,equip in sgs.qlist(equips) do
			if sgs.isKindOf("Weapon|OffensiveHorse", equip) then
				usecard = equip
				break
			end
		end
	end
	if usecard then
		local card_str = "@MingceCard=" .. usecard:getEffectiveId()
		local function canMingceTo(target)
			if self:needKongcheng(target, true) then
				if self:getOpponentNumBySeat(self.player, target) == 0 then
					return true
				end
			else
				return true
			end
			return false
		end
		self.MingceTarget = nil
		local target = nil
		self:sort(self.opponents, "defense")
		for _, friend in ipairs(self.partners_noself) do
			if canMingceTo(friend) then
				for _, enemy in ipairs(self.opponents) do
					if friend:canSlash(enemy) then
						if self:willUseSlash(enemy, friend, sgs.slash) then
							if sgs.getDefenseSlash(enemy) <= 2 then
								if self:slashIsEffective(slash, enemy) then
									if sgs.isGoodTarget(self, enemy, self.opponents) then
										if enemy:objectName() ~= self.player:objectName() then
											target = friend
											self.MingceTarget = enemy
											break
										end
									end
								end
							end
						end
					end
				end
			end
			if target then 
				break 
			end
		end
		if not target then
			self:sort(self.partners_noself, "defense")
			for _, friend in ipairs(self.partners_noself) do
				if canMingceTo(friend) then
					target = friend
					break
				end
			end
		end
		if target then
			local acard = sgs.Card_Parse(card_str)
			use.card = acard
			if use.to then
				use.to:append(target)
			end
		end
	end
end
sgs.ai_skill_choice["mingce"] = function(self, choices)
	local chengong = self.room:getCurrent()
	if self:isPartner(chengong) then
		local alives = self.room:getAlivePlayers()
		for _, player in sgs.qlist(alives) do
			if player:hasFlag("MingceTarget") then
				if not self:isPartner(player) then
					if self:willUseSlash(player, self.player, sgs.slash) then 
						return "use" 
					end
				end
			end
		end
	end
	return "draw"
end
sgs.ai_skill_playerchosen["mingce"] = function(self, targets)
	if self.MingceTarget then 
		return self.MingceTarget 
	end
	local choose_func = sgs.ai_skill_playerchosen["zero_card_as_slash"]
	return choose_func(self, targets)
end
--[[
	内容：“明策”卡牌需求
]]--
sgs.card_need_system["mingce"] = sgs.card_need_system["equip"]
--[[
	套路：仅使用“明策技能卡”
]]--
sgs.ai_series["MingceCardOnly"] = {
	name = "MingceCardOnly",
	IQ = 2,
	value = 3,
	priority = 3,
	skills = "mingce",
	cards = {
		["MingceCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local mingce_skill = sgs.ai_skills["mingce"]
		local dummyCard = mingce_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["MingceCard"], "MingceCardOnly")
--[[****************************************************************
	武将：一将成名·法正（蜀）
]]--****************************************************************
sgs.ai_chaofeng["fazheng"] = -3
--[[
	技能：恩怨
	描述：每当你获得一名其他角色的两张或更多的牌后，你可以令其摸一张牌。每当你受到1点伤害后，你可以令伤害来源选择一项：交给你一张手牌，或失去1点体力。 
]]--
sgs.ai_skill_invoke["enyuan"] = function(self, data)
	local move = data:toMoveOneTime()
	if move then
		if move.from then
			if move.card_ids then
				if move.card_ids:length() > 0 then
					local from = findPlayerByObjectName(self.room, move.from:objectName())
					if from then 
						if self:isPartner(from) then
							if not self:needKongcheng(from, true) then
								return true
							end
						end
						return false
					end
				end
			end
		end
	end
	local damage = data:toDamage()
	local source = damage.from
	if source then
		if source:isAlive() then
			if self:isPartner(source) then 
				if self:getOverflow(source) > 2 then 
					return true 
				end
				if self:needToLoseHp(source, self.player, nil, true) then
					if not self:hasSkills(sgs.masochism_skill, source) then 
						return true 
					end
				end
				if not self:hasLoseHandcardEffective(damage.from) then
					if not damage.from:isKongcheng() then 
						return true 
					end
				end
				return false
			else
				return true
			end
		end
	end		
	return false
end
sgs.ai_skill_discard["enyuan"] = function(self, discard_num, min_num, optional, include_equip)
	local FaZheng = self.room:findPlayerBySkillName("enyuan")
	if self:needToLoseHp(self.player, FaZheng, nil, true) then
		if not self:hasSkills(sgs.masochism_skill) then 
			return {} 
		end
	end
	local to_discard = {}
	local cards = self.player:getHandcards()
	if self:isPartner(FaZheng) then
		for _,card in sgs.qlist(cards) do
			if sgs.isCard("Peach", card, FaZheng) then
				local count = self:getCardsNum("Peach")
				if count > 1 then
					table.insert(to_discard, card:getEffectiveId())
					return to_discard
				elseif not self:isWeak() then
					if count > 0 then
						table.insert(to_discard, card:getEffectiveId())
						return to_discard
					end
				end
			elseif sgs.isCard("Analeptic", card, FaZheng) then
				if self:getCardsNum("Analeptic") > 1 then
					table.insert(to_discard, card:getEffectiveId())
					return to_discard
				end
			elseif sgs.isCard("Jink", card, FaZheng) then
				if self:getCardsNum("Jink") > 1 then
					table.insert(to_discard, card:getEffectiveId())
					return to_discard
				end
			end
		end
	end
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if not sgs.isCard("Peach", card, self.player) then
			if not sgs.isCard("ExNihilo", card, self.player) then
				table.insert(to_discard, card:getEffectiveId())
				return to_discard
			end
		end
	end
	return {}
end
sgs.ai_choicemade_filter.skillInvoke["enyuan"] = function(player, promptlist, self)
	local invoked = (promptlist[3] == "yes")
	local intention = 0
	local EnyuanDrawTarget = nil
	local others = self.room:getOtherPlayers(player)
	for _, p in sgs.qlist(others) do
		if p:hasFlag("EnyuanDrawTarget") then 
			EnyuanDrawTarget = p 
			break 
		end
	end
	if EnyuanDrawTarget then
		if not invoked and not self:needKongcheng(EnyuanDrawTarget, true) then
			intention = 10
		elseif not self:needKongcheng(from, true) then
			intention = -10
		end
		sgs.updateIntention(player, EnyuanDrawTarget, intention)
	else
		local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
		if damage.from then
			if not invoked then
				intention = -10
			elseif self:needToLoseHp(damage.from, player, nil, true) then
				intention = 0
			elseif not self:hasLoseHandcardEffective(damage.from) and not damage.from:isKongcheng() then
				intention = 0
			elseif self:getOverflow(damage.from) <= 2 then
				intention = 10
			end
			sgs.updateIntention(player, damage.from, intention)
		end
	end
end
--[[
	内容：“恩怨”卡牌需求
]]--
sgs.card_need_system["enyuan"] = function(self, card, player)
	return sgs.getKnownCard(player, "Card", false) < 2
end
sgs.slash_prohibit_system["enyuan"] = {
	name = "enyuan",
	reason = "enyuan",
	judge_func = function(self, target, source, slash)
		--友方
		if self:isFriend(target, source) then 
			return false 
		end
		--绝情
		if source:hasSkill("jueqing") then 
			return false 
		end
		--原版潜袭
		if source:hasSkill("nosqianxi") then
			if source:distanceTo(target) == 1 then 
				return false 
			end
		end
		--原版解烦
		if source:hasFlag("NosJiefanUsed") then 
			return false 
		end
		--卖血触发技
		if not self:hasSkills(sgs.masochism_skill, source) then 
			if self:needToLoseHp(source) then
				return false 
			end
		end
		--恩怨
		local num = source:getHandcardNum()
		if num >= 3 then
			return false
		elseif num == 2 then
			if source:hasSkill("kongcheng") then
				return false
			end
		elseif self:hasSkills("lianying|shangshi|nosshangshi", source) then
			return false
		end
		return true
	end
}
sgs.damage_avoid_system["enyuan"] = {
	reason = "enyuan",
	judge_func = function(self, target, damage, source)
		return false
	end
}
sgs.ai_damage_requirement["enyuan"] = function(self, source, target)
	if target:hasSkill("enyuan") then
		if self:isOpponent(source, target) then
			if self:isWeak(source) then
				local num = source:getHandcardNum()
				if num < 3 then
					if not self:hasSkills("lianying|shangshi|nosshangshi", source) then
						if source:hasSkill("kongcheng") then
							if num > 0 then
								return false
							end
						end
						if self:needToLoseHp(source) then
							if not self:hasSkills(sgs.masochism_skill, source) then
								return false
							end
						end
						return true
					end
				end
			end
		end
	end
	return false
end
--[[
	技能：眩惑
	描述：摸牌阶段开始时，你可以放弃摸牌并选择一名其他角色，改为令其摸两张牌，然后该角色需对其攻击范围内你选择的另一名角色使用一张【杀】，若其未如此做或其攻击范围内没有使用【杀】的目标，你获得其两张牌。 
]]--
sgs.ai_playerchosen_intention["xuanhuo_slash"] = 80
sgs.ai_skill_playerchosen["xuanhuo"] = function(self, targets)
	self:sort(self.opponents, "defense")
	for _,lordname in ipairs(sgs.ai_lords) do
		local lord = findPlayerByObjectName(self.room, lordname)
		if self:isOpponent(lord) then
			for _,enemy in ipairs(self.opponents) do
				if enemy:objectName() ~= lordname then
					if lord:canSlash(enemy) then
						if not (lord:hasSkill("tuntian") and lord:hasSkill("zaoxian")) then
							if enemy:getHp() < 2 and not enemy:hasSkill("buqu") then
								if self:getDangerousCard(lord) or self:getValuableCard(lord) then
									if sgs.getDefense(enemy) < 2 then
										return lord
									end
								end
							end
						end
					end
				end
			end
		end
	end
	for _,enemyA in ipairs(self.opponents) do
		for _,enemyB in ipairs(self.opponents) do
			if enemyA:objectName() ~= enemyB:objectName() then
				if enemyA:canSlash(enemyB) then
					if self:getDangerousCard(enemyA) or self:getValuableCard(enemyA) then
						if not (enemyA:hasSkill("tuntian") and enemyA:hasSkill("zaoxian")) then
							if not self:hasSkills(sgs.lose_equip_skill, enemyA) then
								if not self:needLeiji(enemyB, enemyA) then
									if not self:getDamagedEffects(enemyB, enemyA) then
										if not self:needToLoseHp(enemyB, enemyA, nil, true) then
											return enemyA
										end
									end
								end
								if enemyA:hasSkill("manjuan") then
									if enemyA:getCards("he"):length() > 1 then
										if sgs.getCardsNum("Slash", enemyA) == 0 then
											return enemyA
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
	if #self.partners_noself > 0 then 
		self:sort(self.partners_noself, "defense")
		for _, friend in ipairs(self.partners_noself) do
			if self:hasSkills(sgs.lose_equip_skill, friend) then
				if friend:hasEquip() then
					if not friend:hasSkill("manjuan") then
						return friend
					end
				end
			end
		end
		for _, friend in ipairs(self.partners_noself) do
			if friend:hasSkills("tuntian+zaoxian") then
				if not friend:hasSkill("manjuan") then
					return friend
				end
			end
		end
		for _, friend in ipairs(self.partners_noself) do
			for _, enemy in ipairs(self.opponents) do
				if friend:canSlash(enemy) then
					if not friend:hasSkill("manjuan") then
						if enemy:getHp() < 2 and not enemy:hasSkill("buqu") then
							if sgs.getDefense(enemy) < 2 then
								return friend
							end
						end
					end
				end
			end
		end
		if self.player:hasSkill("enyuan") then
			for _, friend in ipairs(self.partners_noself) do
				if not friend:hasSkill("manjuan") then
					return friend
				end
			end
		end
	end
end
sgs.ai_skill_playerchosen["xuanhuo_slash"] = sgs.ai_skill_playerchosen["zero_card_as_slash"]
sgs.ai_skill_cardask["xuanhuo-slash"] = function(self, data, pattern, t1, t2, prompt)
	local parsedPrompt = prompt:split(":")
	local target, target2
	local alives = self.room:getAlivePlayers()
	for _, p in sgs.qlist(alives) do
		if p:objectName() == parsedPrompt[2] then 
			target = p 
		end 
		if p:objectName() == parsedPrompt[3] then 
			target2 = p 
		end
	end
	if target and target2 then
		local FaZheng = self.room:getCurrent()
		local slashes = self:getCards("Slash")
		for _, slash in ipairs(slashes) do
			if self:isPartner(target2) then
				if self:slashIsEffective(slash, target2) then
					if self:canLeiji(target2, self.player) then 
						return slash:toString() 
					end
					if self:invokeDamagedEffect(target2, self.player) then 
						return slash:toString() 
					end
					if not self:isPartner(FaZheng) then
						if self:needToLoseHp(target2, self.player) then 
							return slash:toString() 
						end
					end
				else
					if not self:isFriend(FaZheng) then
						return slash:toString()
					end
				end
			elseif self:isOpponent(target2) then
				if self:slashIsEffective(slash, target2) then
					if not self:invokeDamagedEffect(target2, self.player, slash) then
						if not self:canLeiji(target2, self.player) then
							return slash:toString()
						end
					end
				end
			end
		end
		if self:hasSkills(sgs.lose_equip_skill) then
			if self.player:hasEquip() then
				if not self.player:hasSkill("manjuan") then 
					return "." 
				end
			end
		end
		if not self:isFriend(FaZheng) then
			for _, slash in ipairs(slashes) do
				if self:isPartner(target2) then
					if not self:mayLord(target2) then
						if target2:getHp() > 3 then
							return slash:toString()
						else
							local heavy = self:hasHeavySlashDamage(self.player, slash, target2)
							--if not self:canHit(target2, self.player, heavy) then
								return slash:toString()
							--end
						end
					end
					if self:needToLoseHp(target2, self.player) then 
						return slash:toString() 
					end
				else
					if not self:canLeiji(target2, self.player) then 
						return slash:toString() 
					end
					if not self:slashIsEffective(slash, target2) then 
						return slash:toString() 
					end		
				end
			end
		end
	end
	return "."
end
sgs.draw_cards_system["xuanhuo"] = {
	name = "xuanhuo",
	return_func = function(self, player)
		return 1
	end,
}
--[[****************************************************************
	武将：一将成名·高顺（群）
]]--****************************************************************
--[[
	技能：陷阵
	描述：出牌阶段限一次，你可以与一名其他角色拼点：若你赢，你获得以下技能：本回合，该角色的防具无效，你无视与该角色的距离，你对该角色使用【杀】无数量限制；若你没赢，你不能使用【杀】，直到回合结束。 
]]--
--[[
	内容：“陷阵技能卡”、“陷阵杀技能卡”的卡牌成分
]]--
sgs.card_constituent["XianzhenCard"] = {
	control = 1,
	use_value = 9.2,
	use_priority = 9.2,
}
sgs.card_constituent["XianzhenSlashCard"] = {
	use_value = 9.2,
	use_priority = 2.45,
}
--[[
	内容：注册“陷阵技能卡”、“陷阵杀技能卡”
]]--
sgs.RegistCard("XianzhenCard")
sgs.RegistCard("XianzhenSlashCard")
--[[
	内容：“陷阵”技能信息
]]--
sgs.ai_skills["xianzhen"] = {
	name = "xianzhen",
	dummyCard = function(self)
		if sgs.Ask_XianzhenCard then
			return sgs.Card_Parse("@XianzhenCard=.")
		elseif sgs.Ask_XianzhenSlashCard then
			return sgs.Card_Parse("@XianzhenSlashCard=.")
		else
			if self.player:hasUsed("XianzhenCard") then
				return sgs.Card_Parse("@XianzhenSlashCard=.")
			else
				return sgs.Card_Parse("@XianzhenCard=.")
			end
		end
	end,
	enabled = function(self, handcards)
		if #handcards > 0 then
			if self.player:hasUsed("XianzhenCard") then
				return true
			elseif self.player:hasFlag("XianzhenSuccess") then
				return true
			end
		end
		return false
	end,
}
--[[
	内容：“陷阵技能卡”、“陷阵杀技能卡”的具体产生方式
]]--
sgs.ai_skill_use_func["XianzhenCard"] = function(self, card, use)
	self:sort(self.opponents, "defense")
	local my_max_card = self:getMaxPointCard()
	local my_max_point = my_max_card:getNumber()
	local slashCount = self:getCardsNum("Slash")
	if my_max_card:isKindOf("Slash") then 
		slashCount = slashCount - 1 
	end
	if slashCount > 0 then
		for _,enemy in ipairs(self.opponents) do
			if enemy:hasFlag("AI_HuangtianPindian") then
				if enemy:getHandcardNum() == 1 then
					self.xianzhen_card = my_max_card:getId()
					use.card = card
					if use.to then
						use.to:append(enemy)
						enemy:setFlags("-AI_HuangtianPindian")
					end
					return
				end
			end
		end
		for _,enemy in ipairs(self.opponents) do
			local can_xianzhen = true
			if enemy:getHandcardNum() == 1 then
				if enemy:hasSkill("kongcheng") then
					can_xianzhen = false
				end
			elseif enemy:isKongcheng() then
				can_xianzhen = false
			elseif not self:canAttack(enemy, self.player) then
				can_xianzhen = false
			elseif self:canLiuli(enemy, self.friends_noself) then
				can_xianzhen = false
			elseif self:canLeiji(enemy, self.player) then 
				can_xianzhen = false
			end
			if can_xianzhen then
				local max_card = self:getMaxPointCard(enemy)
				local max_point = 100
				if max_card then
					max_point = max_card:getNumber()
				end
				if my_max_point > max_point then
					self.xianzhen_card = my_max_card:getId()
					use.card = card
					if use.to then 
						use.to:append(enemy) 
					end
					return
				end
			end
		end
		if my_max_point > 10 then
			for _,enemy in ipairs(self.opponents) do
				local can_xianzhen = true
				if enemy:getHandcardNum() == 1 then
					if enemy:hasSkill("kongcheng") then
						can_xianzhen = false
					end
				elseif enemy:isKongcheng() then
					can_xianzhen = false
				elseif not self:canAttack(enemy, self.player) then
					can_xianzhen = false
				elseif self:canLiuli(enemy, self.friends_noself) then
					can_xianzhen = false
				elseif self:canLeiji(enemy, self.player) then 
					can_xianzhen = false
				end
				if can_xianzhen then
					self.xianzhen_card = my_max_card:getId()
					use.card = card
					if use.to then 
						use.to:append(enemy) 
					end
					return
				end
			end
		end
	end
	local handcards = self.player:getHandcards()
	local cards = sgs.QList2Table(handcards)
	self:sortByUseValue(cards, true)
	local may_card = cards[1]
	local use_value = sgs.getCardValue(may_card, "use_value", self.player)
	local keep_value = sgs.getCardValue(may_card, "keep_value", self.player)
	if use_value < 6 then
		if keep_value < 6 then
			local shouldUse = self:getOverflow() > 0
			if shouldUse then
				for _,enemy in ipairs(self.opponents) do
					local can_xianzhen = true
					if enemy:getHandcardNum() == 1 then
						if enemy:hasSkill("kongcheng") then
							can_xianzhen = false
						end
					elseif enemy:isKongcheng() then
						can_xianzhen = false
					elseif enemy:hasSkills("tuntian+zaoxian") then
						can_xianzhen = false
					end
					if can_xianzhen then
						self.xianzhen_card = may_card:getId()
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
end
sgs.ai_skill_use_func["XianzhenSlashCard"] = function(self, card, use)
	local tag = self.player:getTag("XianzhenTarget")
	local target = tag:toPlayer()
	if self:askForCard("slash", "@xianzhen-slash") == "." then 
		return 
	end
	if self:getCard("Slash") then
		if self.player:canSlash(target, nil, false) then
			if target:isAlive() then
				use.card = card
			end
		end
	end
end
sgs.ai_skill_cardask["@xianzhen-slash"] = function(self)
	local tag = self.player:getTag("XianzhenTarget")
	local target = tag:toPlayer()
	local slashes = self:getCards("Slash")
	for _,slash in ipairs(slashes) do
		if self:slashIsEffective(slash, target) then 
			return slash:toString() 
		end
	end
	return "."
end
--[[
	内容：“陷阵”卡牌需求
]]--
sgs.card_need_system["xianzhen"] = function(self, card, player)
	local handcards = player:getHandcards()
	local hasBig = false
	local current = self.room:getCurrent()
	local flag = string.format("visible_%s_%s", current:objectName(), player:objectName())
	for _,c in sgs.qlist(handcards) do
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:getNumber() > 10 then
				hasBig = true
				break
			end
		end
	end
	if hasBig then
		return sgs.isKindOf("Slash|Analeptic", card)
	else
		return card:getNumber() > 10
	end
end
--[[
	套路：仅使用“陷阵技能卡”
]]--
sgs.ai_series["XianzhenCardOnly"] = {
	name = "XianzhenCardOnly",
	IQ = 2,
	value = 3,
	priority = 4,
	skills = "xianzhen",
	cards = {
		["XianzhenCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local xianzhen_skill = sgs.ai_skills["xianzhen"]
		sgs.Ask_XianzhenCard = true
		local dummyCard = xianzhen_skill["dummyCard"](self)
		sgs.Ask_XianzhenCard = nil
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["XianzhenCard"], "XianzhenCardOnly")
--[[
	套路：仅使用“陷阵杀技能卡”
]]--
sgs.ai_series["XianzhenSlashCardOnly"] = {
	name = "XianzhenSlashCardOnly",
	IQ = 2,
	value = 2,
	priority = 2,
	skills = "xianzhen",
	cards = {
		["XianzhenSlashCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local xianzhen_skill = sgs.ai_skills["xianzhen"]
		sgs.Ask_XianzhenSlashCard = true
		local dummyCard = xianzhen_skill["dummyCard"](self)
		sgs.Ask_XianzhenSlashCard = nil
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["XianzhenSlashCard"], "XianzhenSlashCardOnly")
--[[
	技能：禁酒（锁定技）
	描述：你的【酒】视为【杀】。 
]]--
--[[
	内容：注册“禁酒杀”
]]--
sgs.RegistCard("jinjiu>>Slash")
--[[
	内容：“禁酒”技能信息
]]--
sgs.ai_skills["jinjiu"] = {
	name = "jinjiu",
	dummyCard = function(self)
		local suit = sgs.slash:getSuitString()
		local number = sgs.slash:getNumberString()
		local card_id = sgs.slash:getEffectiveId()
		local card_str = ("slash:jinjiu[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)
		return slash
	end,
	enabled = function(self, handcards)
		if sgs.slash:isAvailable(self.player) then
			return #handcards > 0
		end
	end,
}
--[[
	内容：“禁酒杀”的具体产生方式
]]--
sgs.ai_view_as_func["jinjiu>>Slash"] = function(self, card)
	local cards = self.player:getCards("he")
	local analeptics = {}
	for _,anal in sgs.qlist(cards) do
		if anal:isKindOf("Analeptic") then
			table.insert(analeptics, anal)
			break
		end
	end
	if #analeptics > 0 then
		local heart = analeptics[1]
		local suit = heart:getSuitString()
		local number = heart:getNumberString()
		local card_id = heart:getEffectiveId()
		local card_str = ("slash:jinjiu[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)
		return slash
	end
end
sgs.ai_filterskill_filter["jinjiu"] = function(card, player, place)
	if card:isKindOf("Analeptic") then 
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		return ("slash:jinjiu[%s:%s]=%d"):format(suit, number, card_id) 
	end
end
--[[
	内容：“禁酒”响应方式
	需求：杀
]]--
sgs.ai_view_as["jinjiu"] = function(card, player, place, class_name)
	if place ~= sgs.Player_PlaceSpecial then
		if card:isKindOf("Analeptic") then
			if not card:hasFlag("using") then
				local suit = card:getSuitString()
				local number = card:getNumberString()
				local card_id = card:getEffectiveId()
				return ("slash:jinjiu[%s:%s]=%d"):format(suit, number, card_id)
			end
		end
	end
end
--[[
	套路：仅使用“禁酒杀”
]]--
sgs.ai_series["jinjiu>>SlashOnly"] = {
	name = "jinjiu>>SlashOnly",
	IQ = 2,
	value = 1,
	priority = 1,
	skills = "jinjiu",
	cards = {
		["jinjiu>>Slash"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return sgs.slash:isAvailable(self.player)
	end,
	action = function(self, handcards, skillcards)
		local jinjiu_skill = sgs.ai_skills["jinjiu"]
		local dummyCard = jinjiu_skill["dummyCard"](self)
		dummyCard:setFlags("isDummy")
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["jinjiu>>Slash"], "jinjiu>>SlashOnly")
--[[****************************************************************
	武将：一将成名·凌统（吴）
]]--****************************************************************
--[[
	技能：旋风
	描述：每当你失去一次装备区的装备牌后，或于弃牌阶段内因你的弃置而失去两张或更多的手牌后（弃牌阶段限一次），你可以依次弃置一至两名其他角色的共计两张牌。 
]]--
--[[
	内容：“旋风技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["XuanfengCard"] = function(self, card, source, targets)
	for i=1, #targets, 1 do
		local intention = 80
		local to = targets[i]
		if to:hasSkill("kongcheng") then
			if to:getHandcardNum() == 1 then
				if to:getHp() <= 2 then
					intention = 0
				end
			end
		end
		if self:needToThrowArmor(to) then
			intention = 0
		end
		sgs.updateIntention(source, to, intention)
	end
end
sgs.ai_skill_use["@@xuanfeng"] = function(self, prompt)
	local erzhang = self.room:findPlayerBySkillName("guzheng")
	if erzhang then
		if self:isOpponent(erzhang) then
			local current = self.room:getCurrent()
			if current:getPhase() == sgs.Player_Discard then 
				return "." 
			end
		end
	end
	local first = nil
	local second = nil
	first = self:findPlayerToDiscard("he", false)
	local others = self.room:getOtherPlayers(first)
	second = self:findPlayerToDiscard("he", false, true, others)
	if first then
		if first and not second then
			if self:isPartner(first) then 
				return "." 
			end
			return ("@XuanfengCard=.->%s"):format(first:objectName())
		else
			return ("@XuanfengCard=.->%s+%s"):format(first:objectName(), second:objectName())
		end
	end
	return "."
end
sgs.ai_skill_playerchosen["xuanfeng"] = function(self, targets)	
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	local current = self.room:getCurrent()
	local phase = current:getPhase()
	local isDiscard = ( phase == sgs.Player_Discard )
	for _, enemy in ipairs(self.opponents) do
		if not enemy:isNude() then
			local flag = false
			if not self:doNotDiscard(enemy) then
				flag = true
			elseif self:getDangerousCard(enemy) then
				flag = true
			elseif self:getValuableCard(enemy) then
				flag = true
			end
			if flag then
				if enemy:hasSkill("guzheng") then
					if isDiscard then
						flag = false
					end
				end
				if flag then
					return enemy
				end
			end
		end
	end
end
--[[****************************************************************
	武将：一将成名·马谡（蜀）
]]--****************************************************************
sgs.ai_chaofeng.masu = -4
--[[
	技能：心战
	描述：出牌阶段限一次，若你的手牌数大于你的体力上限，你可以观看牌堆顶的三张牌，展示并获得其中任意数量的♥牌，然后将其余的牌以任意顺序置于牌堆顶。 
]]--
--[[
	内容：“心战技能卡”的卡牌成分
]]--
sgs.card_constituent["XinzhanCard"] = {
	use_value = 4.4,
	use_priority = 9.4,
}
--[[
	内容：注册“心战技能卡”
]]--
sgs.RegistCard("XinzhanCard")
--[[
	内容：“心战”技能信息
]]--
sgs.ai_skills["xinzhan"] = {
	name = "xinzhan",
	dummyCard = function(self)
		return sgs.Card_Parse("@XinzhanCard=.")
	end,
	enabled = function(self, handcards)
		if not self.player:hasUsed("XinzhanCard") then
			local num = self.player:getHandcardNum()
			local maxhp = self.player:getMaxHp()
			if num > maxhp then
				return true
			end
		end
		return false
	end,
}
--[[
	内容：“心战技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["XinzhanCard"] = function(self, card, use)
	use.card = card
end
--[[
	套路：仅使用“心战技能卡”
]]--
sgs.ai_series["XinzhanCardOnly"] = {
	name = "XinzhanCardOnly",
	IQ = 2,
	value = 2,
	priority = 5,
	cards = {
		["XinzhanCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local xinzhan_skill = sgs.ai_skills["xinzhan"]
		local dummyCard = xinzhan_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["XinzhanCard"], "XinzhanCardOnly")
--[[
	技能：挥泪（锁定技）
	描述：你死亡时，杀死你的角色弃置其所有牌。 
]]--
sgs.slash_prohibit_system["huilei"] = {
	name = "huilei",
	reason = "huilei",
	judge_func = function(self, target, source, slash)
		--绝情
		if source:hasSkill("jueqing") then
			return false
		end
		--原版解烦
		if source:hasFlag("NosJiefanUsed") then 
			return false 
		end
		--挥泪
		if self:isWeak(target) then
			if self:isFriend(target, source) then
				return true 
			end
			local enemies = self:getOpponents(source)
			if #enemies > 1 then
				if source:getHandcardNum() > 3 then
					return true
				end
			end
		end
		return false
	end
}
--[[****************************************************************
	武将：一将成名·吴国太（吴）
]]--****************************************************************
--[[
	技能：甘露
	描述：出牌阶段限一次，你可以令装备区的装备牌数量差不超过你已损失体力值的两名角色交换他们装备区的装备牌。 
]]--
--[[
	内容：“甘露技能卡”的卡牌成分
]]--
sgs.card_constituent["GanluCard"] = {
	control = 1,
	use_priority = sgs.card_constituent["Dismantlement"]["use_priority"] + 0.1
}
--[[
	内容：“甘露技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["GanluCard"] = function(self, card, source, targets)
	local compare_func = function(a, b)
		local equipsA = a:getEquips()
		local equipsB = b:getEquips()
		return equipsA:length() < equipsB:length()
	end
	table.sort(targets, compare_func)
	if targets[1]:getEquips():length() < targets[2]:getEquips():length() then
		sgs.updateIntention(source, targets[1], -80)
	end
end
--[[
	内容：注册“甘露技能卡”
]]--
sgs.RegistCard("GanluCard")
--[[
	内容：“甘露”技能信息
]]--
sgs.ai_skills["ganlu"] = {
	name = "ganlu",
	dummyCard = function(self)
		return sgs.Card_Parse("@GanluCard=.")
	end,
	enabled = function(self, handcards)
		if not self.player:hasUsed("GanluCard") then
			return true
		end
		return false
	end,
}
--[[
	内容：“甘露技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["GanluCard"] = function(self, card, use)
	local lost = self.player:getLostHp()
	local function compare_func(a, b)
		local equipsA = a:getEquips()
		local equipsB = b:getEquips()
		return equipsA:length() > equipsB:length()
	end
	table.sort(self.opponents, compare_func)
	table.sort(self.partners, compare_func)
	self.partners = sgs.reverse(self.partners)
	local target = nil
	local min_friend, max_enemy
	for _,friend in ipairs(self.opponents) do
		for _,enemy in ipairs(self.partners) do
			if not self:hasSkills(sgs.lose_equip_skill, enemy) then
				if not enemy:hasSkills("tuntian+zaoxian") then 
					local enemy_equips = enemy:getEquips()
					local friend_equips = friend:getEquips()
					local e = enemy_equips:length()
					local f = friend_equips:length()
					if e > 0 then
						if math.abs( e - f ) <= lost then
							local enemy_armor = enemy:getArmor()
							local friend_armor = friend:getArmor()
							local a = self:evaluateArmor(enemy_armor, friend)
							local b = self:evaluateArmor(friend_armor, enemy)
							local c = self:evaluateArmor(friend_armor, friend)
							local d = self:evaluateArmor(enemy_armor, enemy)
							local value = ( a - b ) - ( c - d )
							if (e > f) or (e == f and value > 0) then
								if self:hasSkills(sgs.lose_equip_skill, friend) then
									use.card = card
									if use.to then
										use.to:append(friend)
										use.to:append(enemy)
									end
									return
								elseif not min_friend and not max_enemy then
									min_friend = friend
									max_enemy = enemy
								end
							end
						end
					end
				end
			end
		end
	end
	if min_friend and max_enemy then
		use.card = card
		if use.to then 
			use.to:append(min_friend)
			use.to:append(max_enemy)
		end
		return
	end
	target = nil
	for _,friend in ipairs(self.partners) do
		if not friend:getEquips():isEmpty() then
			if friend:hasArmorEffect("SilverLion") then
				if friend:isWounded() then
					target = friend
					break
				end
			end
			if self:hasSkills(sgs.lose_equip_skill, friend) then
				target = friend
				break
			end
			if friend:hasSkills("tuntian+zaoxian") then
				if friend:getPhase() == sgs.Player_NotActive then
					target = friend
					break
				end
			end
		end
	end
	if target then
		local equips = target:getEquips()
		for _,friend in ipairs(self.partners) do
			if friend:objectName() ~= target:objectName() then
				local friend_equips = friend:getEquips()
				local delt = friend_equips:length() - equips:length()
				if math.abs(delt) <= lost then
					use.card = card			
					if use.to then
						use.to:append(friend)
						use.to:append(target)
					end
					return
				end
			end
		end
	end
end
--[[
	内容：“甘露”最优体力
]]--
sgs.best_hp_system["ganlu"] = {
	name = "ganlu",
	reason = "ganlu",
	best_hp = function(player, maxhp, isLord)
		if isLord then
			return math.max(3, maxhp-1)
		else
			return math.max(2, maxhp-1)
		end
	end,
}
--[[
	套路：仅使用“甘露技能卡”
]]--
sgs.ai_series["GanluCardOnly"] = {
	name = "GanluCardOnly",
	IQ = 2,
	value = 2,
	priority = 3,
	skills = "ganlu",
	cards = {
		["GanluCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local ganlu_skill = sgs.ai_skills["ganlu"]
		local dummyCard = ganlu_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["GanluCard"], "GanluCardOnly")
--[[
	技能：补益
	描述：每当一名角色进入濒死状态时，你可以展示该角色的一张手牌，若该牌为非基本牌，该角色弃置该牌，然后回复1点体力。 
]]--
sgs.ai_skill_invoke["buyi"] = function(self, data)
	local dying = data:toDying()
	local target = dying.who
	if target:isKongcheng() then
		return false
	end
	local isFriend = not self:isOpponent(target)
	local cards = target:getCards("h")
	local myname = self.player:objectName()
	local name = target:objectName()
	local flag = string.format("visible_%s_%s", myname, name)
	local knownCount = 0
	for _,card in sgs.qlist(cards) do
		local isVisible = false
		if myname == name then
			isVisible = true
		elseif card:hasFlag("visible") then
			isVisible = true
		elseif card:hasFlag(flag) then
			isVisible = true
		end
		if isVisible then
			knownCount = knownCount + 1
		end
	end
	if knownCount < target:getHandcardNum() then
		return isFriend
	end
	return false
end
sgs.ai_skill_cardshow["buyi"] = function(self, requestor)
	assert(self.player:objectName() == requestor:objectName())
	local cards = self.player:getHandcards()
	for _, card in sgs.qlist(cards) do
		if card:getTypeId() ~= sgs.Card_TypeBasic then
			return card
		end
	end
	return self.player:getRandomHandCard()
end
--[[****************************************************************
	武将：一将成名·徐盛（吴）
]]--****************************************************************
--[[
	技能：破军
	描述：每当你使用【杀】对目标角色造成一次伤害后，你可以令其摸X张牌，然后将其武将牌翻面。（X为该角色的体力值且至多为5） 
]]--
sgs.ai_skill_invoke["pojun"] = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if target:faceUp() then
		local hp = target:getHp()
		local isGood = ( hp > 2 )
		if self:isPartner(target) then
			return isGood
		elseif self:isOpponent(target) then
			return not isGood
		end
	else
		if self:isPartner(target) then
			return true
		end
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke["pojun"] = function(player, promptlist, self)
	local intention = 60
	local index = -1
	if promptlist[#promptlist] == "yes" then
		index = 1
	end
	local tag = self.room:getTag("CurrentDamageStruct")
	local damage = tag:toDamage()
	if damage.from and damage.to then
		if not damage.to:faceUp() then
			intention = index * intention
		elseif damage.to:getHp() > 2 then
			intention = -index / 2 * intention
		elseif index == -1 then
			intention = -20
		end
		sgs.updateIntention(damage.from, damage.to, intention)
	end
end
--[[****************************************************************
	武将：一将成名·徐庶（蜀）
]]--****************************************************************
--[[
	技能：无言（锁定技）
	描述：每当你造成或受到伤害时，你防止锦囊牌的伤害。 
]]--
sgs.trick_invalid_system["wuyan"] = {
	name = "wuyan",
	reason = "wuyan",
	judge_func = function(card, target, source)
		if sgs.isKindOf("Duel|FireAttack|AOE", card) then
			if not source:hasSkill("jueqing") then
				if source:hasSkill("wuyan") then
					return true
				elseif target:hasSkill("wuyan") then
					return true
				end
			end
		end
		return false
	end,
}
--[[
	技能：举荐
	描述：结束阶段开始时，你可以弃置一张非基本牌并选择一名其他角色，令该角色选择一项：摸两张牌，或回复1点体力，或重置武将牌并将其翻至正面朝上。 
]]--
--[[
	内容：“举荐技能卡”的卡牌成分
]]--
sgs.card_constituent["JujianCard"] = {
	use_priority = 4.5,
}
--[[
	内容：“举荐技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["JujianCard"] = -100
sgs.ai_skill_use["@@jujian"] = function(self, prompt)
	local nobasic = -1
	if self:needToThrowArmor() then
		local armor = self.player:getArmor()
		nobasic = armor:getId()
	else
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		for _,card in ipairs(cards) do
			if card:getTypeId() ~= sgs.Card_Basic then 
				nobasic = card:getEffectiveId() 
			end
		end
	end
	if nobasic < 0 then
		return "."
	end
	local need = 0
	for _, friend in ipairs(self.partners_noself) do
		if self:isWeak(friend) then
			need = need + 1
		elseif friend:getHandcardNum() < 2 then
			need = need + 1
		elseif not friend:faceUp() then
			need = need + 1
		elseif self:getOverflow() > 0 then
			need = need + 1
		elseif friend:isChained() then
			if not self:isGoodChainPartner(friend) then
				local armor = friend:getArmor()
				if armor and armor:objectName() == "Vine"  then
					need = need + 1
				end
			end
		end
	end
	if need == 0 then
		return "."
	end
	self:sort(self.partners_noself, "defense")
	for _, friend in ipairs(self.partners_noself) do
		if not friend:faceUp() then
			return "@JujianCard="..nobasic.."->"..friend:objectName()
		end
	end
	for _, friend in ipairs(self.partners_noself) do
		if friend:isChained() then
			if not self:isGoodChainPartner(friend) then
				local armor = friend:getArmor()
				if armor and armor:objectName() == "Vine" then
					return "@JujianCard="..nobasic.."->"..friend:objectName()
				end
			end
		end
	end
	for _, friend in ipairs(self.partners_noself) do
		if self:isWeak(friend) then
			return "@JujianCard="..nobasic.."->"..friend:objectName()
		end
	end
	local friend = self.partners_noself[1]
	return "@JujianCard="..nobasic.."->"..friend:objectName()
end
sgs.ai_skill_choice["jujian"] = function(self, choices)
	if self.player:faceUp() then
		local isChained = self.player:isChained()
		local isWounded = self.player:isWounded()
		if self.player:hasArmorEffect("Vine") then
			if isChained then
				if not self:isGoodChainPartner() then
					return "reset"
				end
			end
		end
		if isWounded then
			if self:isWeak() then
				return "recover"
			end
		end
		if self.player:hasSkill("manjuan") then
			if isWounded then
				return "recover"
			end
			if isChained then
				return "reset"
			end
		end
		return "draw"
	else
		return "reset"
	end
end
sgs.jujian_keep_value = {
	Peach = 6,
	Jink = 5,
	EquipCard = 5,
	Duel = 5,
	FireAttack = 5,
	ArcheryAttack = 5,
	SavageAssault = 5,
}
--[[****************************************************************
	武将：一将成名·于禁（魏）
]]--****************************************************************
--[[
	技能：毅重（锁定技）
	描述：若你的装备区没有防具牌，黑色【杀】对你无效。 
]]--
sgs.ai_armor_value["yizhong"] = function(card)
	if not card then 
		return 4 
	end
end
sgs.slash_invalid_system["yizhong"] = {
	name = "yizhong",
	reason = "yizhong",
	judge_func = function(slash, target, source, ignore_armor)
		if target:hasSkill("yizhong") then
			if not target:getArmor() then
				return slash:isBlack()
			end
		end
		return false
	end
}
--[[****************************************************************
	武将：一将成名·张春华（魏）
]]--****************************************************************
--[[
	技能：绝情（锁定技）
	描述：你即将造成的伤害视为失去体力。 
]]--
--[[
	技能：伤逝
	描述：弃牌阶段外，每当你的手牌数小于X时，你可以将手牌补至X张（X为你已损失的体力值且至多为2）。 
]]--
sgs.ai_skill_invoke["shangshi"] = function(self, data)	
	local lost = self.player:getLostHp()
	if lost == 1 then
		local invoke_func = sgs.ai_skill_invoke["lianying"]
		return invoke_func(self, data)
	end
	return true	
end
--[[****************************************************************
	武将：一将成名·钟会（魏）
]]--****************************************************************
--[[
	技能：权计
	描述：每当你受到1点伤害后，你可以摸一张牌，然后将一张手牌置于武将牌上，称为“权”。锁定技，每有一张“权”，你的手牌上限+1。 
]]--
sgs.ai_skill_invoke["quanji"] = function(self, data)
	local current = self.room:getCurrent()
	local juece_effect = false
	if current and current:isAlive() then
		if current:getPhase() ~= sgs.Player_NotActive then
			if self:isOpponent(current) then
				if current:hasSkill("juece") then
					juece_effect = true
				end
			end
		end
	end
	local manjuan_effect = false
	if self.player:hasSkill("manjuan") then
		if self.player:getPhase() == sgs.Player_NotActive then
			manjuan_effect = true
		end
	end
	if self.player:isKongcheng() then
		if manjuan_effect or juece_effect then 
			return false 
		end
	elseif self.player:getHandcardNum() == 1 then
		if manjuan_effect and juece_effect then 
			return false 
		end
	end
	return true
end
sgs.ai_skill_discard["quanji"] = function(self)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local card = cards[1]
	local id = card:getEffectiveId()
	table.insert(to_discard, id)
	return to_discard
end
--[[
	技能：自立（觉醒技）
	描述：准备阶段开始时，若“权”大于或等于三张，你减1点体力上限，摸两张牌或回复1点体力，然后获得技能“排异”（出牌阶段限一次，你可以将一张“权”置入弃牌堆并选择一名角色，该角色摸两张牌。然后若该角色手牌数大于你的手牌数，你对其造成1点伤害）。
]]--
sgs.ai_skill_choice["zili"] = function(self, choice)
	if self.player:getHp() < self.player:getMaxHp() - 1 then 
		return "recover" 
	end
	return "draw"
end
--[[
	内容：“自立”最优体力
]]--
sgs.best_hp_system["zili"] = {
	name = "zili",
	reason = "quanji+zili",
	best_hp = function(player, maxhp, isLord)
		if player:hasSkill("quanji") then
			if player:getMark("zili") == 0 then
				return maxhp - 1
			end
		end
	end,
}
--[[
	技能：排异
	描述：出牌阶段限一次，你可以将一张“权”置入弃牌堆并选择一名角色，该角色摸两张牌。然后若该角色手牌数大于你的手牌数，你对其造成1点伤害
]]--
--[[
	内容：注册“排异技能卡”
]]--
sgs.RegistCard("PaiyiCard")
--[[
	内容：“排异”技能信息
]]--
sgs.ai_skills["paiyi"] = {
	name = "paiyi",
	dummyCard = function(self)
		return sgs.Card_Parse("@PaiyiCard=.")
	end,
	enabled = function(self, handcards)
		if self.player:hasUsed("PaiyiCard") then
			return false
		else
			local powers = self.player:getPile("power")
			if powers:isEmpty() then
				return false
			end
		end
		return true
	end,
}
--[[
	内容：“排异技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["PaiyiCard"] = function(self, card, use)
	local target = nil
	local my_num = self.player:getHandcardNum()
	self:sort(self.partners_noself, "defense")
	for _, friend in ipairs(self.partners_noself) do
		local num = friend:getHandcardNum()
		if num < 2 then
			if num + 1 < my_num then
				if not self:needKongcheng(friend, true) then
					if not friend:hasSkill("manjuan") then
						target = friend
						break
					end
				end
			end
		end
	end
	if not target then
		local my_hp = self.player:getHp()
		local powers = self.player:getPile("power")
		if my_num < my_hp + powers:length() - 1 then
			target = self.player
		end
	end
	if not target then
		self:sort(self.partners_noself, "hp")
		self.partners_noself = sgs.reverse(self.partners_noself)
		for _,friend in ipairs(self.friends_noself) do
			if friend:getHandcardNum() + 2 > my_num then
				if not friend:hasSkill("manjuan") then
					if self:invokeDamagedEffect(friend, self.player) then
						target = friend
						break
					elseif self:needToLoseHp(friend, self.player, nil, true) then
						target = friend
						break
					end
				end
			end
		end
	end
	if not target then
		self:sort(self.opponents, "defense")
		for _,enemy in ipairs(self.opponents) do
			if enemy:hasSkill("manjuan") then
				if enemy:getHandcardNum() > my_num then
					if self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
						local flag = false
						if self.player:hasSkill("jueqing") then
							flag = true
						elseif not self:hasSkills(sgs.masochism_skill, enemy) then
							flag = true
						end
						if flag then
							if not self:invokeDamagedEffect(enemy, self.player) then
								if not self:needToLoseHp(enemy) then
									target = enemy
									break
								end
							end
						end
					end
				end
			end
		end
	end
	if not target then
		for _,enemy in ipairs(self.opponents) do
			if enemy:getHandcardNum() + 2 > my_num then
				if not enemy:hasSkill("manjuan") then
					local flag = false
					if self.player:hasSkill("jueqing") then
						flag = true
					elseif not self:hasSkills(sgs.masochism_skill, enemy) then
						flag = true
					end
					if flag then
						if not self:hasSkills(sgs.cardneed_skill.."|jijiu|tianxiang|buyi", enemy) then
							if self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
								if not self:invokeDamagedEffect(enemy, self.player) then
									if not self:needToLoseHp(enemy) then
										target = enemy
										break
									end
								end
							end
						end
					end
				end
			end
		end
	end
	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end
sgs.ai_skill_askforag["paiyi"] = function(self, card_ids)
	local count = #card_ids
	local index = math.random(1, count)
	return card_ids[index]
end
--[[
	套路：仅使用“排异技能卡”
]]--
sgs.ai_series["PaiyiCardOnly"] = {
	name = "PaiyiCardOnly",
	IQ = 2,
	value = 1,
	priority = 2,
	skills = "paiyi",
	cards = {
		["PaiyiCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local paiyi_skill = sgs.ai_skills["paiyi"]
		local dummyCard = paiyi_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["PaiyiCard"], "PaiyiCardOnly")