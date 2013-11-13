--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）林扩展包部分
]]--
--[[****************************************************************
	武将：林·徐晃（魏）
]]--****************************************************************
--[[
	技能：断粮
	描述：你可以将一张黑色的基本牌或黑色的装备牌当【兵粮寸断】使用。锁定技，你可以对距离2以内的其他角色使用【兵粮寸断】。 
]]--
--[[
	内容：注册“断粮兵粮寸断”
]]--
sgs.RegistCard("duanliang>>SupplyShortage")
--[[
	内容：“断粮”技能信息
]]--
sgs.ai_skills["duanliang"] = {
	name = "duanliang",
	dummyCard = function(self)
		local suit = sgs.supply_shortage:getSuitString()
		local number = sgs.supply_shortage:getNumberString()
		local card_id = sgs.supply_shortage:getEffectiveId()
		local card_str = ("supply_shortage:duanliang[%s:%s]=%d"):format(suit, number, card_id)
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if not self.player:isNude() then
			local cards = self.player:getCards("he")
			for _,card in sgs.qlist(cards) do
				if card:isBlack() then
					if card:isKindOf("BasicCard") then
						return true
					elseif card:isKindOf("EquipCard") then
						return true
					end
				end
			end
		end
		return false
	end
}
--[[
	内容：“断粮兵粮寸断”的具体产生方式
]]--
sgs.ai_view_as_func["duanliang>>SupplyShortage"] = function(self, card)
	local cards = self.player:getCards("he")
	local blacks = {}
	for _,black in sgs.qlist(cards) do
		if black:isBlack() then
			if black:isKindOf("BasicCard") then
				table.insert(blacks, black)
			elseif black:isKindOf("EquipCard") then
				table.insert(blacks, black)
			end
		end
	end
	if #blacks > 0 then
		self:sortByUseValue(blacks, true)
		local ss_value = sgs.getCardValue("SupplyShortage", "use_value")
		for _,black in ipairs(blacks) do
			local name = sgs.getCardName(black)
			if sgs.getCardValue(name, "use_value") < ss_value then
				local suit = black:getSuitString()
				local number = black:getNumberString()
				local card_id = black:getEffectiveId()
				local card_str = ("supply_shortage:duanliang[%s:%s]=%d"):format(suit, number, card_id)
				local supply_shortage = sgs.Card_Parse(card_str)
				return supply_shortage
			end
		end
	end
end
--[[
	内容：“断粮”卡牌需求
]]--
sgs.card_need_system["duanliang"] = function(self, card, player)
	if card:isBlack() then
		if card:getTypeId() ~= sgs.Card_TypeTrick then
			return sgs.getKnownCard(player, "black", false) < 2
		end
	end
	return false
end
--[[
	套路：仅使用“断粮兵粮寸断”
]]--
sgs.ai_series["duanliang>>SupplyShortageOnly"] = {
	name = "duanliang>>SupplyShortageOnly",
	IQ = 2,
	value = 1,
	priority = 1,
	skills = "duanliang",
	cards = {
		["duanliang>>SupplyShortage"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local duanliang_skill = sgs.ai_skills["duanliang"]
		local dummyCard = duanliang_skill["dummyCard"](self)
		dummyCard:setFlags("isDummy")
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["duanliang>>SupplyShortage"], "duanliang>>SupplyShortageOnly")
--[[****************************************************************
	武将：林·曹丕（魏）
]]--****************************************************************
sgs.ai_chaofeng.caopi = -3
--[[
	技能：行殇
	描述：其他角色死亡时，你可以获得该角色的牌。 
]]--
sgs.ai_skill_invoke["xingshang"] = true
--[[
	技能：放逐
	描述：每当你受到一次伤害后，你可以令一名其他角色摸X张牌，然后该角色将其武将牌翻面。（X为你已损失的体力值） 
]]--
sgs.ai_playerchosen_intention["fangzhu"] = function(self, source, target)
	if target:hasSkill("manjuan") then
		if target:getPhase() == sgs.Player_NotActive then 
			sgs.updateIntention(source, target, 80) 
		end
	end
	local lost = source:getLostHp()
	local intention = 80 / math.max(lost, 1)
	if not self:toTurnOver(target, lost) then 
		intention = -intention 
	end
	if lost < 3 then
		sgs.updateIntention(source, target, intention)
	else
		intention = math.min(intention, -30)
		sgs.updateIntention(source, target, intention)
	end
end
sgs.ai_skill_playerchosen["fangzhu"] = function(self, targets)
	self:sort(self.partners_noself, "handcard")
	local target = nil
	local n = self.player:getLostHp()
	for _,friend in ipairs(self.partners_noself) do
		if not self:toTurnOver(friend, n) then
			target = friend
			break
		end
	end
	if not target then
		if n >= 3 then
			target = self:findPlayerToDraw(false, n)
			if not target then
				for _,enemy in ipairs(self.enemies) do
					if self:toTurnOver(enemy, n, true) then
						if enemy:hasSkill("manjuan") then
							if enemy:getPhase() == sgs.Player_NotActive then
								target = enemy
								break
							end
						end
					end
				end
			end	
		else
			self:sort(self.opponents, "chaofeng")
			for _,enemy in ipairs(self.opponents) do
				if self:toTurnOver(enemy, n, true) then
					if enemy:hasSkill("manjuan") then
						if enemy:getPhase() == sgs.Player_NotActive then
							target = enemy
							break
						end
					end
				end
			end
			if not target then
				for _,enemy in ipairs(self.opponents) do
					if self:toTurnOver(enemy, n, true) then
						if self:hasSkills(sgs.priority_skill, enemy) then
							target = enemy
							break
						end
					end
				end
			end
			if not target then
				for _,enemy in ipairs(self.opponents) do
					if self:toTurnOver(enemy, n, true) then
						target = enemy
						break
					end
				end
			end
		end
	end
	return target
end
sgs.ai_damage_requirement["fangzhu"] = function(self, source, target)
	if target:hasSkill("fangzhu") then
		local enemies = self:getOpponents(target)
		local lost = target:getLostHp()
		if lost < 1 then
			if #enemies >= 1 then
				self:sort(enemies, "defense")
				for _,enemy in ipairs(enemies) do
					if self:toTurnOver(enemy, lost+1) then
						return true
					end
				end
			end
		end
		local friends = self:getPartners(target, nil, true)
		self:sort(friends, "defense")
		for _,friend in ipairs(friends) do
			if not self:toTurnOver(friend, lost+1) then
				return true
			end
		end
	end
	return false
end
--[[
	技能：颂威（主公技）
	描述：其他魏势力角色的黑色判定牌生效后，该角色可以令你摸一张牌。 
]]--
sgs.ai_playerchosen_intention["songwei"] = -50
sgs.ai_skill_playerchosen["songwei"] = function(self, targets)
	for _, target in sgs.qlist(targets) do
		if self:isPartner(target) then
			if target:isAlive() then
				return target
			end
		end
	end
	return nil
end
--[[****************************************************************
	武将：林·孟获（蜀）
]]--****************************************************************
--[[
	技能：祸首（锁定技）
	描述：【南蛮入侵】对你无效。每当其他角色使用【南蛮入侵】指定目标后，你成为【南蛮入侵】的伤害来源。 
]]--
--[[
	技能：再起
	描述：摸牌阶段开始时，若你已受伤，你可以放弃摸牌，改为从牌堆顶亮出X张牌（X为你已损失的体力值），你回复等同于其中♥牌数量的体力，然后将这些♥牌置入弃牌堆，最后获得其余的牌。 
]]--
sgs.ai_skill_invoke["zaiqi"] = function(self, data)
	local lost = self.player:getLostHp()
	return lost >= 2
end
sgs.draw_cards_system["zaiqi"] = {
	name = "zaiqi",
	return_func = function(self, player)
		local lost = player:getLostHp()
		return math.floor(lost * 3 / 4) 
	end,
}
--[[****************************************************************
	武将：林·祝融（蜀）
]]--****************************************************************
--[[
	技能：巨象（锁定技）
	描述：【南蛮入侵】对你无效。其他角色使用的【南蛮入侵】在结算完毕后置入弃牌堆时，你获得之。 
]]--
--[[
	技能：烈刃
	描述：每当你使用【杀】对目标角色造成一次伤害后，你可以与该角色拼点：若你赢，你获得其一张牌。 
]]--
sgs.ai_skill_invoke["lieren"] = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isOpponent(target) then
		local num = self.player:getHandcardNum()
		if num == 1 then
			if not self:isWeak() then
				if self:needKongcheng() then
					return true
				elseif not self:hasLoseHandcardEffective() then
					return true
				end
			end
			local handcards = self.player:getHandcards()
			local card = handcards:first()
			if card:isKindOf("Peach") or card:isKindOf("Jink") then
				return false
			end
		end
		local can_invoke = false
		if num > self.player:getHp() then
			can_invoke = true
		elseif not self:hasLoseHandcardEffective() then
			can_invoke = true
		elseif self:needKongcheng() then
			if num == 1 then
				can_invoke = true
			end
		else
			local max_card = self:getMaxPointCard()
			local max_point = max_card:getNumber()
			if max_point > 10 then
				can_invoke = true
			end
		end
		if can_invoke then
			if not self:doNotDiscard(target, "h", true) then
				if num ~= 1 then
					return true
				elseif not self:doNotDiscard(target, "e", true) then
					return true
				end
			end
		end
		if self:doNotDiscard(target, "he", true, 2) then
			return false
		end
	end
	return false
end
sgs.ai_skill_pindian["lieren"] = function(self, requestor, maxcard, mincard) 
	local handcards = self.player:getHandcards()
	local cards = sgs.QList2Table(handcards)
	self:sortByKeepValue(cards)
	if requestor:objectName() == self.player:objectName() then
		return cards[1]:getId()
	end
	local max_card = self:getMaxPointCard(self.player)
	if max_card then
		return max_card:getId()
	end
	return maxcard
end
--[[
	内容：“烈刃”卡牌需求
]]--
sgs.card_need_system["lieren"] = function(self, card, player)
	if sgs.isCard("Slash", card, player) then
		return sgs.getKnownCard(player, "Slash", true) == 0
	end
	return false
end
--[[****************************************************************
	武将：林·孙坚（吴）
]]--****************************************************************
--[[
	技能：英魂
	描述：准备阶段开始时，若你已受伤，你可以选择一名其他角色并选择一项：1.令其摸一张牌，然后弃置X张牌；2.令其摸X张牌，然后弃置一张牌。（X为你已损失的体力值） 
]]--
sgs.ai_playerchosen_intention["yinghun"] = function(self, source, target)
	if source:getLostHp() > 1 then 
		return 
	end
	local intention = -80
	if target:hasSkill("manjuan") then 
		intention = -intention 
	end
	sgs.updateIntention(source, target, intention)
end
sgs.ai_skill_choice["yinghun"] = function(self, choices)
	return self.yinghunchoice
end
sgs.ai_skill_playerchosen["yinghun"] = function(self, targets)
	local lost = self.player:getLostHp()
	local n = lost - 1
	if lost == 1 then
		if #self.partners == 1 then
			for _,enemy in ipairs(self.opponents) do
				if enemy:hasSkill("manjuan") then
					return enemy
				end
			end
			return nil
		end
	end
	self.yinghun = nil
	if lost == 1 then
		self:sort(self.partners_noself, "handcard")
		self.partners_noself = sgs.reverse(self.partners_noself)
		for _, friend in ipairs(self.partners_noself) do
			if self:hasSkills(sgs.lose_equip_skill, friend) then
				if friend:getCards("e"):length() > 0 then
					if not friend:hasSkill("manjuan") then
						self.yinghun = friend
						break
					end
				end
			end
		end
		if not self.yinghun then
			for _, friend in ipairs(self.partners_noself) do
				if friend:hasSkill("tuntian") then
					if friend:hasSkill("zaoxian") then
						if not friend:hasSkill("manjuan") then
							self.yinghun = friend
							break
						end
					end
				end
			end
		end
		if not self.yinghun then
			for _, friend in ipairs(self.partners_noself) do
				if self:needToThrowArmor(friend) then	
					if not friend:hasSkill("manjuan") then
						self.yinghun = friend
						break
					end
				end
			end
		end
		if not self.yinghun then
			for _, enemy in ipairs(self.opponents) do
				if enemy:hasSkill("manjuan") then
					return enemy
				end
			end
		end
		if not self.yinghun then
			for _, friend in ipairs(self.partners_noself) do
				if friend:getCards("he"):length() > 0 then
					if not friend:hasSkill("manjuan") then
						self.yinghun = friend
						break
					end
				end
			end
		end
		if not self.yinghun then
			for _, friend in ipairs(self.partners_noself) do
				if not friend:hasSkill("manjuan") then
					self.yinghun = friend
					break
				end
			end
		end
	elseif #self.partners > 1 then
		self:sort(self.partners_noself, "chaofeng")
		for _, friend in ipairs(self.partners_noself) do
			if self:hasSkills(sgs.lose_equip_skill, friend) then
				if friend:getCards("e"):length() > 0 then
					if not friend:hasSkill("manjuan") then
						self.yinghun = friend
						break
					end
				end
			end
		end
		if not self.yinghun then
			for _, friend in ipairs(self.partners_noself) do
				if friend:hasSkill("tuntian") then
					if friend:hasSkill("zaoxian") then
						if not friend:hasSkill("manjuan") then
							self.yinghun = friend
							break
						end
					end
				end
			end
		end
		if not self.yinghun then
			for _, friend in ipairs(self.partners_noself) do
				if self:needToThrowArmor(friend) then
					if not friend:hasSkill("manjuan") then
						self.yinghun = friend
						break
					end
				end
			end
		end
		if not self.yinghun then
			if #self.opponents > 0 then
				local weak_friend = nil
				if self:amLord() then
					if self:isWeak() then
						if self.player:getHp() < 2 then
							if self:getCardsNum("Peach") < 1 then
								weak_friend = true
							end
						end
					end
				end
				if not weak_friend then
					for _, friend in ipairs(self.partners_noself) do
						if self:isWeak(friend) then
							weak_friend = true 
							break 
						end
					end
				end
				if not weak_friend then
					self:sort(self.opponents, "chaofeng")
					for _, enemy in ipairs(self.opponents) do
						if enemy:getCards("he"):length() == n then
							if not self:doNotDiscard(enemy, "he", true, n, true) then
								self.yinghunchoice = "d1tx"
								return enemy
							end
						end
					end
					for _, enemy in ipairs(self.opponents) do
						if enemy:getCards("he"):length() >= n then
							if not self:doNotDiscard(enemy, "he", true, n, true) then
								if self:hasSkills(sgs.cardneed_skill, enemy) then
									self.yinghunchoice = "d1tx"
									return enemy
								end
							end
						end
					end
				end
				if not self.yinghun then
					self.yinghun = self:findPlayerToDraw(false, n)
				end
				if not self.yinghun then
					for _, friend in ipairs(self.partners_noself) do
						if not friend:hasSkill("manjuan") then
							self.yinghun = friend
							break
						end
					end
				end
				if self.yinghun then 
					self.yinghunchoice = "dxt1" 
				end
			end
		end
	end
	if not self.yinghun then
		if lost > 1 then
			if #self.opponents > 0 then
				self:sort(self.opponents, "handcard")
				for _, enemy in ipairs(self.opponents) do
					if enemy:getCards("he"):length() >= n then
						if not self:doNotDiscard(enemy, "he", true, n, true) then
							self.yinghunchoice = "d1tx"
							return enemy
						end
					end
				end
				self.opponents = sgs.reverse(self.opponents)
				for _, enemy in ipairs(self.opponents) do
					if not enemy:isNude() then
						local flag = true
						if self:hasSkills(sgs.lose_equip_skill, enemy) then
							if enemy:getCards("e"):length() > 0 then
								flag = false
							end
						end
						if flag then
							if enemy:hasArmorEffect("SilverLion") then
								if enemy:isWounded() then
									if self:isWeak(enemy) then
										flag = false
									end
								end
							end
						end
						if flag then
							if enemy:hasSkill("tuntian") then
								if enemy:hasSkill("zaoxian") then
									flag = false
								end
							end
						end
						if flag then
							self.yinghunchoice = "d1tx"
							return enemy
						end
					end
				end
				for _, enemy in ipairs(self.opponents) do
					if not enemy:isNude() then
						local flag = true
						if self:hasSkills(sgs.lose_equip_skill, enemy) then
							if enemy:getCards("e"):length() > 0 then
								flag = false
							end
						end
						if flag then
							if enemy:hasArmorEffect("SilverLion") then
								if enemy:isWounded() then
									if self:isWeak(enemy) then
										flag = false
									end
								end
							end
						end
						if flag then
							if enemy:hasSkill("tuntian") then
								if enemy:hasSkill("zaoxian") then
									if lost < 3 then
										if enemy:getCards("he"):length() < 2 then
											flag = false
										end
									end
								end
							end
						end
						if flag then
							self.yinghunchoice = "d1tx"
							return enemy
						end
					end
				end
			end
		end
	end
	return self.yinghun
end
sgs.ai_choicemade_filter.skillChoice["yinghun"] = function(player, promptlist, self)
	local to
	local others = self.room:getOtherPlayers(player)
	for _, p in sgs.qlist(others) do
		if p:hasFlag("YinghunTarget") then
			to = p
			break
		end
	end
	local choice = promptlist[#promptlist]
	if choice == "dxt1" then
		sgs.updateIntention(player, to, -80)
	else
		sgs.updateIntention(player, to, 80)
	end
end
--[[
	内容：“英魂”最优体力
]]--
sgs.best_hp_system["yinghun"] = {
	name = "yinghun",
	reason = "yinghun",
	best_hp = function(player, maxhp, isLord)
		if isLord then
			return math.max(3, maxhp-2)
		else
			return math.max(2, maxhp-2)
		end
	end,
}
--[[****************************************************************
	武将：林·鲁肃（吴）
]]--****************************************************************
sgs.ai_chaofeng.lusu = 4
--[[
	技能：好施
	描述：摸牌阶段，你可以额外摸两张牌，然后若你的手牌多于五张，你将一半（向下取整）的手牌交给手牌数最少的一名其他角色。 
]]--
--[[
	功能：获取所有其他角色的手牌下限
	参数：无
	结果：number类型（least），表示手牌最少的角色的手牌数
]]--
function SmartAI:getLowerBoundOfHandcard()
	local least = math.huge
	local others = self.room:getOtherPlayers(self.player)
	for _,p in sgs.qlist(others) do
		local num = p:getHandcardNum()
		least = math.min(least, num)
	end
	return least
end
--[[
	功能：查找一名达到手牌下限的角色
	参数：无
	结果：ServerPlayer类型，表示最先符合条件的角色
]]--
function SmartAI:getBeggar()
	local least = self:getLowerBoundOfHandcard()
	self:sort(self.partners_noself, "defense")
	for _, friend in ipairs(self.partners_noself) do
		if friend:getHandcardNum() == least then
			return friend
		end
	end
	local others = self.room:getOtherPlayers(self.player)
	for _, player in sgs.qlist(others) do
		if player:getHandcardNum() == least then
			return player
		end
	end
end
--[[
	内容：“好施技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["HaoshiCard"] = -80
sgs.ai_skill_invoke["haoshi"] = function(self, data)
	local count = self.player:getHandcardNum()
	local skills = {
		yongsi = sgs.getKingdomsCount(),
		yingzi = 1,
		zishou = self.player:getLostHp(),
		shenwei = 2,
		juejing = self.player:getLostHp(),
		ayshuijian = 1 + self.player:getEquips():length(),
	}
	for skill, extra in pairs(skills) do
		if self.player:hasSkill(skill) then
			count = count + extra
		end
	end
	if count <= 1 then
		return true
	end
	local target = self:getBeggar()
	if self:isPartner(target) then
		if not target:hasSkill("manjuan") then
			sgs.haoshi_target = target
			return true
		end
	end
	return false
end
sgs.ai_skill_use["@@haoshi!"] = function(self, prompt)
	local target = sgs.haoshi_target or self:getBeggar()
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local ids = {}
	local count = math.floor(#cards / 2)
	for i=1, count, 1 do
		local card = cards[i]
		local id = card:getEffectiveId()
		table.insert(ids, id)
	end
	local card_str = "@HaoshiCard=" .. table.concat(ids, "+") .. "->" .. target:objectName()
	return card_str
end
--[[
	内容：“好施”卡牌需求
]]--
sgs.card_need_system["haoshi"] = function(self, card, player)
	return not self:willSkipDrawPhase(player)
end
sgs.draw_cards_system["haoshi"] = {
	name = "haoshi",
	correct_func = function(self, player)
		return 2
	end,
}
--[[
	技能：缔盟
	描述：出牌阶段限一次，你可以选择两名其他角色并弃置X张牌（X为两名目标角色手牌数的差），令这些角色交换手牌。 
]]--
--[[
	功能：明确发动缔盟时应弃置的牌
	参数：delt（number类型，表示缔盟双方的手牌差）
		mycards（table类型，表示所有可用于发动缔盟的牌）
	结果：table类型（to_discard），表示找到的所有弃牌
]]--
function SmartAI:getDimengDiscard(delt, mycards)
	local to_discard = {}
	local function aux_func(card)
		local id = card:getEffectiveId()
		local place = self.room:getCardPlace(id)
		if place == sgs.Player_PlaceEquip then
			if card:isKindOf("SilverLion") and self.player:isWounded() then 
				return -2
			elseif card:isKindOf("OffensiveHorse") then 
				return 1
			elseif card:isKindOf("Weapon") then 
				return 2
			elseif card:isKindOf("DefensiveHorse") then 
				return 3
			elseif card:isKindOf("Armor") then 
				return 4
			end
		elseif sgs.getUseValue(card, self.player) >= 6 then 
			return 3 --使用价值高的牌，如顺手牵羊(9),下调至桃
		elseif self:hasSkills(sgs.lose_equip_skill) then 
			return 5
		end
		return 0
	end
	local function compare_func(a, b)
		local valueA = aux_func(a)
		local valueB = aux_func(b)
		if valueA ~= valueB then
			return valueA < valueB
		end
		return sgs.getKeepValue(a, self.player) < sgs.getKeepValue(b, self.player)
	end
	table.sort(mycards, compare_func)
	for _, card in ipairs(cards) do
		if not self.player:isJilei(card) then 
			table.insert(to_discard, card:getId()) 
		end
		if #to_discard >= delt then 
			break 
		end
	end
	if #to_discard ~= delt then 
		return {} 
	end
	return to_discard
end
--[[
	功能：判断是否值得发动缔盟
	参数：friend（ServerPlayer类型，表示缔盟目标中偏向友方的角色）
		enemy（ServerPlayer类型，表示缔盟目标中偏向敌方的角色）
		mycards（table类型，表示所有可用于发动缔盟的卡牌）
		myequips（table类型，表示所有可用于发动缔盟的装备区的牌）
	结果：boolean类型，表示是否值得
]]--
function SmartAI:dimengIsWorth(friend, enemy, mycards, myequips)
	local num1 = enemy:getHandcardNum()
	local num2 = friend:getHandcardNum()
	if num1 < num2 then
		return false
	elseif num1 == num2 then
		if num1 > 0 then
			if self:hasAllSkills("tuntian+zaoxian", friend) then
				return true
			end
			return false
		end
	end
	local card_num = #mycards
	local delt = num1 - num2
	if delt < card_num then
		return false
	end
	local equip_num = #myequips
	if equip_num > 0 then
		if self:hasSkills(sgs.lose_equip_skill) then
			return true
		end
	end
	local should_keep = 0
	local should_use = 0
	local standard = math.ceil(delt / 2)
	for i=1, delt, 1 do
		local card = mycards[i]
		local keepValue = sgs.getKeepValue(card, self.player)
		if keepValue > 4 then
			should_keep = should_keep + 1
		end
		local useValue = sgs.getUseValue(card, self.player)
		if useValue >= 6 then
			should_use = should_use + 1
		end
	end
	if should_use > standard then
		return false
	end
	if should_keep > standard then
		return false
	end
	return true
end
--[[
	内容：“缔盟技能卡”的卡牌信息
]]--
sgs.card_constituent["DimengCard"] = {
	control = 3,
	use_value = 3.5,
	use_priority = 2.8,
}
--[[
	内容：注册“缔盟技能卡”
]]--
sgs.RegistCard("DimengCard")
--[[
	内容：“缔盟”技能信息
]]--
sgs.ai_skills["dimeng"] = {
	name = "dimeng",
	dummyCard = function(self)
		local card_str = "@DimengCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if self.room:alivePlayerCount() > 2 then
			if not self.player:hasUsed("DimengCard") then
				return true
			end
		end
		return false
	end,
}
--[[
	内容：“缔盟技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["DimengCard"] = function(self, card, use)
	if self:needBear() then 
		return 
	end
	local card_num = 0
	local mycards = {}
	local myequips = {}
	local keep_slash = nil
	local handcards = self.player:getHandcards()
	for _,c in sgs.qlist(handcards) do
		if not self.player:isJilei(c) then
			local should_use = false
			if not keep_slash then
				if sgs.isCard("Slash", c, self.player) then
					local dummy_use = { 
						isDummy = true, 
						to = sgs.SPlayerList(), 
					}
					self:useBasicCard(c, dummy_use)
					if dummy_use.card then
						if dummy_use.to then
							if dummy_use.to:length() > 1 then
								should_use = true
							else
								local target = dummy_use.to:first()
								local hp = target:getHp()
								if hp <= 1 then
									should_use = true
								end
							end
						end
					end
				end
			end
			if not should_use then
				card_num = card_num + 1
				table.insert(mycards, c)
			end
		end
	end
	local equips = self.player:getEquips()
	for _,equip in sgs.qlist(equips) do
		if not self.player:isJilei(equip) then
			card_num = card_num + 1
			table.insert(mycards, equip)
			table.insert(myequips, equip)
		end
	end
	self:sortByKeepValue(mycards)
	self:sort(self.opponents, "handcard")
	local friends = {}
	for _,friend in ipairs(self.partners_noself) do
		if not friend:hasSkill("manjuan") then
			table.insert(friends, friend)
		end
	end
	if #friends == 0 then 
		return 
	end
	self:sort(friends, "handcard")
	local least_friend = friends[1]
	local num2 = least_friend:getHandcardNum()
	self:sort(self.opponents, "defense")
	for _,enemy in ipairs(self.opponents) do
		local num1 = enemy:getHandcardNum()
		if enemy:hasSkill("manjuan") then
			if num1 >= num2 then
				if num1 - num2 <= card_num then
					if num1 > 0 or num2 > 0 then
						if num1 == num2 then
							use.card = card
						else
							local delt = num1 - num2
							local to_discard = self:getDimengDiscard(delt, mycards)
							if #to_discard > 0 then
								local card_str = "@DimengCard="..table.concat(to_discard, "+")
								local acard = sgs.Card_Parse(card_str)
								use.card = acard
							end
						end
						if use.card then
							if use.to then
								use.to:append(enemy)
								use.to:append(least_friend)
							end
							return 
						end
					end
				end
			end
		end
	end
	for _,enemy in ipairs(self.opponents) do
		local num1 = enemy:getHandcardNum()
		if num1 > 0 or num2 > 0 then
			if self:dimengIsWorth(least_friend, enemy, mycards, myequips) then
				if num1 == num2 then
					use.card = card
				else
					local delt = math.abs(num1 - num2)
					local to_discard = self:getDimengDiscard(delt, mycards)
					if #to_discard > 0 then
						local card_str = "@DimengCard=" .. table.concat(to_discard, "+")
						local acard = sgs.Card_Parse(card_str)
						use.card = acard
					end
				end
				if use.card then
					if use.to then
						use.to:append(enemy)
						use.to:append(least_friend)
					end
					return 
				end
			end
		end
	end
end
--[[
	套路：仅使用“缔盟技能卡”
]]--
sgs.ai_series["DimengCardOnly"] = {
	name = "DimengCardOnly",
	IQ = 2,
	value = 5,
	priority = 2,
	skills = "dimeng",
	cards = {
		["DimengCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local dimeng_skill = sgs.ai_skills["dimeng"]
		local dummyCard = dimeng_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["DimengCard"], "DimengCardOnly")
--[[****************************************************************
	武将：林·董卓（群）
]]--****************************************************************
--[[
	技能：酒池
	描述：你可以将一张♠手牌当【酒】使用。 
]]--
--[[
	内容：注册“酒池酒”
]]--
sgs.RegistCard("jiuchi>>Analeptic")
--[[
	内容：“酒池”技能信息
]]--
sgs.ai_skills["jiuchi"] = {
	name = "jiuchi",
	dummyCard = function(self)
		local id = sgs.analeptic:getEffectiveId()
		local point = sgs.analeptic:getNumberString()
		local card_str = string.format("analeptic:jiuchi[spade:%s]=%d", point, id)
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if not self.player:isKongcheng() then
			if sgs.analeptic:isAvailable(self.player) then 
				return true
			end
		end
		return false
	end
}
--[[
	内容：“酒池酒”的具体产生方式
]]--
sgs.ai_view_as_func["jiuchi>>Analeptic"] = function(self, card)
	local handcards = self.player:getCards("h")
	local spades = {}
	for _,spade in sgs.qlist(handcards) do
		if spade:getSuit() == sgs.Card_Spade then
			table.insert(spades, spade)
		end
	end
	if #spades > 0 then
		self:sortByUseValue(spades, true)
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		local card_str = ("analeptic:jiuchi[spade:%s]=%d"):format(number, card_id)
		local analeptic = sgs.Card_Parse(card_str)
		return analeptic
	end
end
--[[
	内容：“酒池”响应方式
	需求：酒
]]--
sgs.ai_view_as["jiuchi"] = function(card, player, place, class_name)
	if place == sgs.Player_PlaceHand then
		if card:getSuit() == sgs.Card_Spade then
			local suit = card:getSuitString()
			local number = card:getNumberString()
			local card_id = card:getEffectiveId()
			return ("analeptic:jiuchi[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end
--[[
	内容：“酒池”卡牌需求
]]--
sgs.card_need_system["jiuchi"] = function(self, card, player)
	if card:getSuit() == sgs.Card_Spade then
		local clubNum = sgs.getKnownCard(player, "club", false)
		local spadeNum = sgs.getKnownCard(player, "spade", false)
		return clubNum + spadeNum == 0
	end
	return false
end
--[[
	内容：“酒池”统计信息
]]--
sgs.card_count_system["jiuchi"] = {
	name = "jiuchi",
	pattern = "Analeptic",
	ratio = 0.3,
	statistics_func = function(class_name, player, data)
		if player:hasSkill("jiuchi") then
			local count = data["count"]
			count = count + data["spade"] 
			local equips = player:getCards("e")
			for _,equip in sgs.qlist(equips) do
				if equip:getSuit() == sgs.Card_Spade then
					count = count - 1
				end
			end
			count = count + data["unknown"] * 0.3
			return count
		end
	end
}
--[[
	技能：肉林（锁定技）
	描述：每当你使用【杀】指定一名女性目标角色后，其需依次使用两张【闪】才能抵消；每当你成为女性角色使用【杀】的目标后，你需依次使用两张【闪】才能抵消。 
]]--
sgs.ai_skill_cardask["@roulin1-jink-1"] = sgs.ai_skill_cardask["@wushuang-jink-1"]
sgs.ai_skill_cardask["@roulin2-jink-1"] = sgs.ai_skill_cardask["@wushuang-jink-1"]
--[[
	内容：“肉林”卡牌需求
]]--
sgs.card_need_system["roulin"] = function(self, card, player)
	if card:isKindOf("Slash") then
		for _,enemy in ipairs(self.opponents) do
			if enemy:isFemale() then
				if player:canSlash(enemy, nil, true) then
					if self:slashIsEffective(card, enemy) then
						if sgs.isGoodTarget(self, enemy, self.opponents) then
							if self:willUseSlash(enemy, player, card) then
								if not (enemy:hasSkill("kongcheng") and enemy:isKongcheng()) then
									return sgs.getKnownCard(player, "Slash", true) == 0
								end
							end
						end
					end
				end
			end
		end
	end
	return false
end
--[[
	技能：崩坏（锁定技）
	描述：结束阶段开始时，若你不是当前的体力值最小的角色（或之一），你选择一项：1.失去1点体力；2.减1点体力上限。 
]]--
sgs.ai_skill_choice["benghuai"] = function(self, choices, data)
	local hp = self.player:getHp()
	local peachCount = self:getCardsNum("Peach")
	local analCount = self:getCardsNum("Analeptic")
	for _,friend in ipairs(self.partners_noself) do
		if friend:hasSkill("tianxiang") then 
			if hp >= 3 then
				return "hp"
			elseif hp > 1 then
				if peachCount + analCount > 0 then
					return "hp"
				end
			end
		end
	end
	local maxhp = self.player:getMaxHp()
	if maxhp >= hp + 2 then
		if maxhp > 5 then
			local choose_hp = false
			if self:hasSkills("nosmiji|yinghun|zaiqi|juejing|nosshangshi") then
				choose_hp = true
			elseif self.player:hasSkill("miji") then
				if self:findPlayerToDraw(false) then
					choose_hp = true
				end
			end
			if choose_hp then
				local enemy_num = 0
				for _, p in ipairs(self.opponents) do
					if p:inMyAttackRange(self.player) then
						if not self:willSkipPlayPhase(p) then 
							enemy_num = enemy_num + 1 
						end
					end
				end
				local LiuShan = sgs.fangquan_effect and self.room:findPlayerBySkillName("fangquan")
				if LiuShan then
					sgs.fangquan_effect = false
					enemy_num = self:getEnemyNumBySeat(LiuShan, self.player, self.player)
				end
				local least = 1
				if self:amLord() then
					least = math.max(2, enemy_num-1)
				end
				if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") + hp > least then
					return "hp" 
				end
			end
		end
		return "maxhp"
	end
	return "hp"
end
--[[
	技能：暴虐（主公技）
	描述：其他群雄角色造成伤害一次后，该角色可以进行一次判定：若判定结果为♠，你回复1点体力。 
]]--
sgs.ai_playerchosen_intention["baonue"] = -40
sgs.ai_skill_playerchosen["baonue"] = function(self, targets)
	local zhangjiao = self.room:findPlayerBySkillName("guidao")
	local isFriend = false
	if zhangjiao then
		if self:isPartner(zhangjiao) then
			isFriend = true
		end
	end
	for _,target in sgs.qlist(targets) do
		if self:isPartner(target) and target:isAlive() then
			if target:isWounded() then
				return target
			end
			if isFriend then
				return target
			end
		end
	end
	return nil
end
--[[****************************************************************
	武将：林·贾诩（群）
]]--****************************************************************
--[[
	技能：完杀（锁定技）
	描述：你的回合内，除濒死角色外的其他角色不能使用【桃】。 
]]--
--[[
	技能：乱武（限定技）
	描述：出牌阶段，你可以令所有其他角色对距离最近的另一名角色使用一张【杀】，否则该角色失去1点体力。 
]]--
--[[
	内容：“乱武技能卡”的卡牌信息
]]--
sgs.card_constituent["LuanwuCard"] = {
	damage = 2,
}
--[[
	内容：注册“乱武技能卡”
]]--
sgs.RegistCard("LuanwuCard")
--[[
	内容：“乱武”技能信息
]]--
sgs.ai_skills["luanwu"] = {
	name = "luanwu",
	dummyCard = function(self)
		local card_str = "@LuanwuCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if self.player:getMark("@chaos") > 0 then
			return true
		end
		return false
	end,
}
--[[
	内容：“乱武技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["LuanwuCard"] = function(self, card, use)
	if sgs.current_mode == "_mini_13" then
		use.card = card
	end
	local lord = self.room:getLord()
	if lord then
		if not self:amRebel() then
			if self:isWeak(lord) then
				return 
			end
		end
	end
	local bad = 0
	local good = 0
	local others = self.room:getOtherPlayers(self.player)
	for _,p in sgs.qlist(others) do
		if self:isWeak(p) then
			if self:isPartner(p) then
				bad = bad + 1
			else
				good = good + 1
			end
		end
	end
	if good == 0 then
		return 
	end
	for _,player in sgs.qlist(others) do
		local hp = player:getHp() 
		hp = math.max(hp, 1)
		if sgs.getCardsNum("Analeptic", player) > 0 then
			if self:isPartner(player) then 
				good = good + 1.0 / hp
			else 
				bad = bad + 1.0 / hp
			end
		end
		local hasSlash = ( sgs.getCardsNum("Slash", player) > 0 )
		local canSlash = false
		local range = player:getAttackRange()
		local targets = self.room:getOtherPlayers(player)
		for _, p in sgs.qlist(targets) do
			if player:distanceTo(p) <= range then 
				canSlash = true 
				break 
			end
		end
		if not hasSlash or not canSlash then
			local peachCount = sgs.getCardsNum("Peach", player)
			if self:isPartner(player) then 
				good = good + math.max(peachCount, 1)
			else 
				bad = bad + math.max(peachCount, 1)
			end
		end
		if sgs.getCardsNum("Jink", player) == 0 then
			local lost_value = 0
			if self:hasSkills(sgs.masochism_skill, player) then 
				lost_value = player:getHp() / 2 
			end
			if self:isPartner(player) then 
				bad = bad + (lost_value + 1) / hp
			else 
				good = good + (lost_value + 1) / hp
			end
		end
	end
	if good > bad then 
		use.card = sgs.Card_Parse("@LuanwuCard=.") 
	end
end
sgs.ai_skill_playerchosen["luanwu"] = sgs.ai_skill_playerchosen["zero_card_as_slash"]
--[[
	套路：仅使用“乱武技能卡”
]]--
sgs.ai_series["LuanwuCardOnly"] = {
	name = "LuanwuCardOnly",
	IQ = 2,
	value = 4,
	priority = 3,
	skills = "luanwu",
	cards = {
		["LuanwuCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local luanwu_skill = sgs.ai_skills["luanwu"]
		local dummyCard = luanwu_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["LuanwuCard"], "LuanwuCardOnly")
--[[
	技能：帷幕（锁定技）
	描述：你不能被选择为黑色锦囊牌的目标。 
]]--
sgs.amazing_grace_invalid_system["weimu"] = {
	name = "weimu",
	reason = "weimu",
	judge_func = function(self, card, target, source)
		if target:hasSkill("weimu") then
			return card:isBlack()
		end
		return false
	end
}