--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）火扩展包部分
]]--
--[[****************************************************************
	武将：火·典韦（魏）
]]--****************************************************************
sgs.ai_chaofeng.dianwei = 2
--[[
	技能：强袭
	描述：出牌阶段限一次，你可以失去1点体力或弃置一张武器牌，并选择你攻击范围内的一名角色，对其造成1点伤害。 
]]--
--[[
	内容：“强袭技能卡”的卡牌成分
]]--
sgs.card_constituent["QiangxiCard"] = {
	damage = 2,
	use_value = 2.5,
}
--[[
	内容：“强袭技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["QiangxiCard"] = 80
--[[
	内容：注册“强袭技能卡”
]]--
sgs.RegistCard("QiangxiCard")
--[[
	内容：“强袭”技能信息
]]--
sgs.ai_skills["qiangxi"] = {
	name = "qiangxi",
	dummyCard = function(self)
		local card_str = "@QiangxiCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if self.player:hasUsed("QiangxiCard") then
			return false
		end
		return true
	end
}
sgs.ai_skill_use_func["QiangxiCard"] = function(self, card, use)
	local weapon = self.player:getWeapon()
	if weapon then
		self:sort(self.opponents, "defense")
		local hand_weapon = nil
		local cards = self.player:getCards("h")
		for _,c in sgs.qlist(cards) do
			if c:isKindOf("Weapon") then
				hand_weapon = c
				break
			end
		end
		for _,enemy in ipairs(self.opponents) do
			if self:damageIsEffective(enemy) then
				if not self:cannotBeHurt(enemy) then
					local distance = self.player:distanceTo(enemy)
					if hand_weapon then
						if distance <= self.player:getAttackRange() then
							local card_str = "@QiangxiCard=" .. hand_weapon:getId()
							use.card = sgs.Card_Parse(card_str)
							if use.to then
								use.to:append(enemy)
							end
							break
						end
					end
					if distance <= 1 then
						local card_str = "@QiangxiCard="..weapon:getId()
						use.card = sgs.Card_Parse(card_str)
						if use.to then
							use.to:append(enemy)
						end
						break
					end
				end
			end
		end
	else
		self:sort(self.opponents, "hp")
		local hp = self.player:getHp()
		if hp > 1 then
			for _,enemy in ipairs(self.opponents) do
				if self:damageIsEffective(enemy) then
					if not self:cannotBeHurt(enemy) then
						local distance = self.player:distanceTo(enemy)
						if distance <= self.player:getAttackRange() then
							if hp > enemy:getHp() then
								use.card = card
								if use.to then
									use.to:append(enemy)
								end
								break
							end
						end
					end
				end
			end
		end
	end
end
--[[
	内容：“强袭”卡牌需求
]]--
sgs.card_need_system["qiangxi"] = sgs.card_need_system["weapon"]
--[[
	套路：仅使用强袭技能卡
]]--
sgs.ai_series["QiangxiCardOnly"] = {
	name = "QiangxiCardOnly", 
	value = 4, 
	priority = 1, 
	skills = "qiangxi",
	cards = { 
		["QiangxiCard"] = 1, 
		["Others"] = 0, 
	},
	enabled = function(self) 
		return true
	end,
	action = function(self, handcards, skillcards) 
		local qiangxi_skill = sgs.ai_skills["qiangxi"]
		local dummyCard = qiangxi_skill["dummyCard"]()
		return {dummyCard}
	end,
	break_condition = function(self) 
		return false
	end,
}
table.insert(sgs.ai_card_actions["QiangxiCard"], "QiangxiCardOnly")
--[[****************************************************************
	武将：火·荀彧（魏）
]]--****************************************************************
sgs.ai_chaofeng.xunyu = 3
--[[
	技能：驱虎
	描述：出牌阶段限一次，你可以与一名当前的体力值大于你的角色拼点：若你赢，其对其攻击范围内你选择的另一名角色造成1点伤害。若你没赢，其对你造成1点伤害。 
]]--
--[[
	内容：“驱虎技能卡”的卡牌成分
]]--
sgs.card_constituent["QuhuCard"] = {
	control = 1,
}
--[[
	内容：“驱虎技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["QuhuCard"] = 0
sgs.ai_playerchosen_intention["quhu"] = 80
--[[
	内容：注册“驱虎技能卡”
]]--
sgs.RegistCard("QuhuCard")
--[[
	内容：“驱虎”技能信息
]]--
sgs.ai_skills["quhu"] = {
	name = "quhu",
	dummyCard = function(self)
		local card_str = "@QuhuCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if not self.player:hasUsed("QuhuCard") then
			if not self.player:isKongcheng() then
				local others = self.room:getOtherPlayers(self.player)
				for _,p in sgs.qlist(others) do
					if not p:isKongcheng() then
						if p:getHp() > self.player:getHp() then
							return true
						end
					end
				end
			end
		end
		return false
	end
}
sgs.ai_skill_use_func["QuhuCard"] = function(self, card, use)
	if self:needBear() then 
		return 
	end
	local my_max_card = self:getMaxPointCard()
	local my_max_point = my_max_card:getNumber()
	local enemies = {}
	local friends = {}
	local others = self.room:getOtherPlayers(self.player)
	local myHp = self.player:getHp()
	for _,p in sgs.qlist(others) do
		if not p:isKongcheng() then
			local hp = p:getHp()
			if hp > myHp then
				if self:isPartner(p) then
					table.insert(friends, p)
				else
					table.insert(enemies, p)
				end
			end
		end
	end
	if #enemies > 0 then
		self:sort(enemies, "handcard")
		for _,enemy in ipairs(enemies) do
			local max_card = self:getMaxPointCard()
			local num = enemy:getHandcardNum()
			local known_num = sgs.getKnownNum(enemy)
			local isAllKnown = ( num == known_num )
			local can_use = false
			if max_card then
				local max_point = max_card:getNumber()
				if my_max_point > max_point then
					if isAllKnown then
						can_use = true
					elseif my_max_point > 10 then
						can_use = true
					end
				end
			else
				if my_max_point > 10 then
					can_use = true
				end
			end
			if can_use then
				local name = enemy:objectName()
				local range = enemy:getAttackRange()
				for _,victim in ipairs(self.opponents) do
					if victim:objectName() ~= name then
						if enemy:distanceTo(victim) <= range then
							self.quhu_card = my_max_card:getEffectiveId()
							local card_str = "@QuhuCard=."
							use.card = sgs.Card_Parse(card_str)
							if use.to then
								use.to:append(enemy)
							end
							return 
						end
					end
				end
			end
		end
		local can_use = false
		if myHp == 1 then
			if self:getCardsNum("Analeptic") > 0 then
				if self.player:getHandcardNum() >= 2 then
					can_use = true
				end
			end
		elseif not self.player:isWounded() then
			can_use = true
		end
		if can_use then
			if self.player:hasSkill("jieming") then
				can_use = false
				for _,friend in ipairs(self.partners) do
					local maxhp = friend:getMaxHp()
					local num = friend:getHandcardNum()
					local count = math.max(5, maxhp - num)
					if count >= 2 then
						local index = #self.opponents
						if index > 0 then
							self:sort(self.opponents, "handcard")
							local target = self.opponents[index]
							if target:getHandcardNum() > 0 then
								can_use = true
							end
							break
						end
					end
				end
				if can_use then
					for _,enemy in ipairs(enemies) do
						if not enemy:hasSkill("jueqing") then
							local cards = self.player:getHandcards()
							cards = sgs.QList2Table(cards)
							self:sortByUseValue(cards, true)
							self.quhu_card = cards[1]:getEffectiveId()
							local card_str = "@QuhuCard=."
							use.card = sgs.Card_Parse(card_str)
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
end
sgs.ai_skill_playerchosen["quhu"] = sgs.ai_skill_playerchosen["damage"]
--[[
	内容：“驱虎”卡牌需求
]]--
sgs.card_need_system["quhu"] = sgs.card_need_system["bignumber"]
--[[
	套路：仅使用“驱虎技能卡”
]]--
sgs.ai_series["QuhuCardOnly"] = {
	name = "QuhuCardOnly",
	IQ = 2,
	value = 2,
	priority = 2,
	cards = {
		["QuhuCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local quhu_skill = sgs.ai_skills["quhu"]
		local dummyCard = quhu_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["QuhuCard"], "QuhuCardOnly")
--[[
	技能：节命
	描述：每当你受到1点伤害后，你可以令一名角色将手牌补至X张。（X为该角色体力上限且至多为5） 
]]--
sgs.ai_playerchosen_intention["jieming"] = function(self, source, target)
	local num = target:getHandcardNum()
	local maxhp = target:getMaxHp()
	if num < math.min(5, maxhp) then
		sgs.updateIntention(source, target, -80)
	end
end
sgs.ai_skill_playerchosen["jieming"] = function(self, targets)
	local friends = {}
	for _,friend in ipairs(self.partners) do
		if friend:isAlive() then
			if not friend:hasSkill("manjuan") then
				table.insert(friends, friend)
			elseif friend:getPhase() ~= sgs.Player_NotActive then
				table.insert(friends, friend)
			end
		end
	end
	self:sort(friends, "defense")
	local Shenfen_user
	local alives = self.room:getAlivePlayers()
	for _, player in sgs.qlist(alives) do
		if player:hasFlag("ShenfenUsing") then
			Shenfen_user = player
			break
		end
	end
	local max_x = 0
	local target = nil
	if Shenfen_user then
		local y, weak_friend = 3
		for _, friend in ipairs(friends) do
			local maxhp = friend:getMaxHp()
			local x = math.min(maxhp, 5) - friend:getHandcardNum()
			if friend:hasSkill("manjuan") and x > 0 then 
				x = x + 1 
			end
			if maxhp >=5 and x > max_x and friend:isAlive() then
				max_x = x
				target = friend
			end
			if x >= y then
				if self:playerGetRound(friend, Shenfen_user) > self:playerGetRound(self.player, Shenfen_user) then
					if friend:getHp() == 1 then
						if sgs.getCardsNum("Peach", friend) < 1 then
							y = x
							weak_friend = friend
						end
					end
				end
			end
		end
		if weak_friend then
			if sgs.getCardsNum("Peach", Shenfen_user) < 1 then
				return weak_friend
			elseif math.min(Shenfen_user:getMaxHp(), 5) - Shenfen_user:getHandcardNum() <= 1 then
				return weak_friend
			end
		end
		if self:isPartner(Shenfen_user) then
			if math.min(Shenfen_user:getMaxHp(), 5) > Shenfen_user:getHandcardNum() then
				return Shenfen_user
			end
		end
		if target then 
			return target 
		end
	end
	local current = self.room:getCurrent()
	local max_x = 0
	for _, friend in ipairs(friends) do
		local x = math.min(friend:getMaxHp(), 5) - friend:getHandcardNum()
		if friend:hasSkill("manjuan") then 
			x = x + 1 
		end
		if self:hasCrossbowEffect(current) then 
			x = x + 1 
		end
		if x > max_x and friend:isAlive() then
			max_x = x
			target = friend
		end
	end
	return target
end
sgs.ai_damage_requirement["jieming"] = function(self, source, target)
	if self.player:hasSkill("jieming") then
		if self:getJiemingChaofeng(player) <= -6 then
			return true
		end
	end
	return false
end
--[[****************************************************************
	武将：火·庞统（蜀）
]]--****************************************************************
sgs.ai_chaofeng.pangtong = -1
--[[
	技能：连环
	描述：你可以将一张♣手牌当【铁索连环】使用或重铸。 
]]--
--[[
	内容：注册“连环铁索连环”
]]--
sgs.RegistCard("lianhuan>>IronChain")
--[[
	内容：“连环”技能信息
]]--
sgs.ai_skills["lianhuan"] = {
	name = "lianhuan",
	dummyCard = function(self)
		local suit = sgs.iron_chain:getSuitString()
		local number = sgs.iron_chain:getNumberString()
		local card_id = sgs.iron_chain:getEffectiveId()
		local card_str = ("iron_chain:lianhuan[%s:%s]=%d"):format(suit, number, card_id)
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		return not self.player:isKongcheng()
	end,
}
--[[
	内容：“连环铁索连环”的具体产生方式
]]--
sgs.ai_view_as_func["lianhuan>>IronChain"] = function(self, card)
	local cards = self.player:getCards("h")
	local clubs = {}
	for _,club in sgs.qlist(cards) do
		if club:getSuit() == sgs.Card_Club then
			table.insert(clubs, club)
		end
	end
	if #clubs > 0 then
		self:sortByUseValue(clubs, true)
		local slash = self:getCard("FireSlash")
		slash = slash or self:getCard("ThunderSlash")
		slash = slash or self:getCard("Slash")
		if slash then
			local dummy_use = {
				isDummy = true,
			}
			self:useBasicCard(slash, dummy_use)
			if not dummy_use.card then
				slash = nil
			end
		end
		local icValue = sgs.getCardValue("IronChain", "use_value")
		for _,club in ipairs(clubs) do
			local should_use = true
			if slash and slash:objectName() == club:objectName() then
				should_use = false
			end
			local name = sgs.getCardName(club)
			local value = sgs.getCardValue(name, "use_value")
			if value > icValue then
				if club:getTypeId() == sgs.Card_TypeTrick then
					local dummy_use = { 
						isDummy = true, 
					}
					self:useTrickCard(club, dummy_use)
					if dummy_use.card then 
						shouldUse = false 
					end
				end
			end
			if club:getTypeId() == sgs.Card_TypeEquip then
				local dummy_use = { 
					isDummy = true,
				}
				self:useEquipCard(club, dummy_use)
				if dummy_use.card then 
					shouldUse = false 
				end
			end
			if should_use then
				local number = club:getNumberString()
				local card_id = club:getEffectiveId()
				local card_str = ("iron_chain:lianhuan[club:%s]=%d"):format(number, card_id)
				local iron_chain = sgs.Card_Parse(card_str)
				return iron_chain
			end
		end
	end
end
--[[
	内容：“连环”卡牌需求
]]--
sgs.card_need_system["lianhuan"] = function(self, card, player)
	if player:getHandcardNum() <= 2 then
		return card:getSuit() == sgs.Card_Club
	end
	return false
end
--[[
	套路：仅使用“连环铁索连环”
]]--
sgs.ai_series["lianhuan>>IronChainOnly"] = {
	name = "lianhuan>>IronChainOnly", 
	IQ = 2,
	value = 2, 
	priority = 1, 
	skills = "lianhuan",
	cards = { 
		["lianhuan>>IronChain"] = 1, 
		["Others"] = 1, 
	},
	enabled = function(self) 
		local cards = self.player:getCards("h")
		for _,card in sgs.qlist(cards) do
			if card:getSuit() == sgs.Card_Club then
				return true
			end
		end
		return false
	end,
	action = function(self, handcards, skillcards) 
		local lianhuan_skill = sgs.ai_skills["lianhuan"]
		local dummyCard = lianhuan_skill["dummyCard"]()
		dummyCard:setFlags("isDummy")
		return {dummyCard}
	end,
	break_condition = function(self) 
		return false
	end,
}
table.insert(sgs.ai_card_actions["lianhuan>>IronChain"], "lianhuan>>IronChainOnly")
--[[
	技能：涅槃（限定技）
	描述：当你处于濒死状态时，你可以弃置你区域里所有的牌，然后将你的武将牌翻转至正面朝上并重置之，再摸三张牌且将你当前的体力值回复至3点。 
]]--
sgs.ai_skill_invoke["niepan"] = function(self, data)
	local dying = data:toDying()
	local need = 1 - dying.who:getHp()
	local peachCount = self:getCardsNum("Peach")
	local analCount = self:getCardsNum("Analeptic")
	return peachCount + analCount < need
end
--[[****************************************************************
	武将：火·诸葛亮（蜀）
]]--****************************************************************
--[[
	技能：火计
	描述：你可以将一张红色手牌当【火攻】使用。 
]]--
--[[
	内容：注册“火计火攻”
]]--
sgs.RegistCard("huoji>>FireAttack")
--[[
	内容：“火计”技能信息
]]--
sgs.ai_skills["huoji"] = {
	name = "huoji",
	dummyCard = function(self)
		local suit = sgs.fire_attack:getSuitString()
		local number = sgs.fire_attack:getNumberString()
		local card_id = sgs.fire_attack:getEffectiveId()
		local card_str = ("fire_attack:huoji[%s:%s]=%d"):format(suit, number, card_id)
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		return not self.player:isKongcheng()
	end,
}
--[[
	内容：“火计火攻”的具体产生方式
]]--
sgs.ai_view_as_func["huoji>>FireAttack"] = function(self, card)
	local cards = self.player:getCards("h")
	local reds = {}
	for _,red in sgs.qlist(cards) do
		if red:isRed() then
			if not red:isKindOf("Peach") then
				table.insert(reds, red)
			end
		end
	end
	if #reds > 0 then
		local faValue = sgs.getCardValue("FireAttack", "use_value")
		local isOverflow = ( self:getOverflow() > 0 )
		self:sortByUseValue(reds, true)
		for _,red in ipairs(reds) do
			local name = sgs.getCardName(red)
			local flag = false
			if sgs.getCardValue(name, "use_value") < faValue then
				flag = true
			elseif isOverflow then
				flag = true
			end
			if flag then
				local should_keep = false
				if red:isKindOf("Slash") then
					if self:getCardsNum("Slash") == 1 then
						local dummy_use = {
							isDummy = true,
							to = sgs.SPlayerList(),
						}
						self:useBasicCard(red, dummy_use)
						if dummy_use.card then
							local targetCount = dummy_use.to:length()
							if targetCount > 1 then
								should_keep = true
							elseif targetCount > 0 then
								for _,target in sgs.qlist(dummy_use.to) do
									if target:getHp() <= 1 then
										should_keep = true
										break
									end
								end
							end
						end
					end
				end
				if not should_keep then
					local suit = red:getSuitString()
					local number = red:getNumberString()
					local card_id = red:getEffectiveId()
					local card_str = ("fire_attack:huoji[%s:%s]=%d"):format(suit, number, card_id)
					local fire_attack = sgs.Card_Parse(card_str)
					return fire_attack
				end
			end
		end
	end
end
--[[
	内容：“火计”卡牌需求
]]--
sgs.card_need_system["huoji"] = function(self, card, player)
	if player:getHandcardNum() <= 2 then
		return card:isRed()
	end
	return false
end
--[[
	套路：仅使用“火计火攻”
]]--
sgs.ai_series["huoji>>FireAttackOnly"] = {
	name = "huoji>>FireAttackOnly", 
	IQ = 2,
	value = 2, 
	priority = 1, 
	skills = "huoji",
	cards = { 
		["huoji>>FireAttack"] = 1, 
		["Others"] = 1, 
	},
	enabled = function(self) 
		local cards = self.player:getCards("h")
		for _,card in sgs.qlist(cards) do
			if card:isRed() then
				return true
			end
		end
		return false
	end,
	action = function(self, handcards, skillcards) 
		local huoji_skill = sgs.ai_skills["huoji"]
		local dummyCard = huoji_skill["dummyCard"](self)
		dummyCard:setFlags("isDummy")
		return {dummyCard}
	end,
	break_condition = function(self) 
		return false
	end,
}
table.insert(sgs.ai_card_actions["huoji>>FireAttack"], "huoji>>FireAttackOnly")
--[[
	技能：看破
	描述：你可以将一张黑色手牌当【无懈可击】使用。 
]]--
sgs.ai_view_as["kanpo"] = function(card, player, place, class_name)
	if card_place == sgs.Player_PlaceHand then
		if card:isBlack() then
			local suit = card:getSuitString()
			local number = card:getNumberString()
			local card_id = card:getEffectiveId()
			return ("nullification:kanpo[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end
--[[
	内容：“看破”卡牌需求
]]--
sgs.card_need_system["kanpo"] = function(self, card, player)
	return card:isBlack()
end
--[[
	内容：“看破”统计信息
]]--
sgs.card_count_system["kanpo"] = {
	name = "kanpo",
	pattern = "Nullification",
	ratio = 0.5,
	statistics_func = function(class_name, player, data)
		if player:hasSkill("kanpo") then
			local count = data["count"]
			count = count + data["Black"]
			local equips = player:getCards("e")
			for _,equip in sgs.qlist(equips) do
				if equip:isBlack() then
					count = count - 1
				end
			end
			count = count + data["unknown"] * 0.5
			return count
		end
	end
}
--[[
	技能：八阵（锁定技）
	描述：若你的装备区没有防具牌，视为你装备【八卦阵】。 
]]--
sgs.ai_skill_invoke["bazhen"] = sgs.ai_skill_invoke["EightDiagram"]
sgs.ai_armor_value["bazhen"] = function(card)
	if not card then 
		return 4 
	end
end
--[[****************************************************************
	武将：火·太史慈（吴）
]]--****************************************************************
sgs.ai_chaofeng.taishici = 3
--[[
	技能：天义
	描述：出牌阶段限一次，你可以与一名角色拼点。若你赢，你获得以下锁定技，直到回合结束：你使用【杀】无距离限制；你于出牌阶段内能额外使用一张【杀】；你使用【杀】选择目标的个数上限+1。若你没赢，你不能使用【杀】，直到回合结束。 
]]--
--[[
	内容：“天义技能卡”的卡牌成分
]]--
sgs.card_constituent["TianyiCard"] = {
	control = 1,
	use_value = 8.5,
}
--[[
	内容：注册“天义技能卡”
]]--
sgs.RegistCard("TianyiCard")
--[[
	内容：“天义技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["TianyiCard"] = 0
--[[
	内容：“天义”技能信息
]]--
sgs.ai_skills["tianyi"] = {
	name = "tianyi",
	dummyCard = function(self)
		local card_str = "@TianyiCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if not self.player:hasUsed("TianyiCard") then
			if not self.player:isKongcheng() then
				return true
			end
		end
		return false
	end
}
--[[
	内容：“天义技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["TianyiCard"] = function(self, card, use)
	if self:needBear() then
		return 
	end
	self:sort(self.enemies, "handcard")
	local my_max_card = self:getMaxPointCard()
	if my_max_card then
		local my_max_point = my_max_card:getNumber()
		local slashCount = self:getCardsNum("Slash")
		if sgs.isCard("Slash", my_max_card, self.player) then
			slashCount = slashCount - 1
		end
		if self.player:hasSkill("kongcheng") then
			if self.player:getHandcardNum() == 1 then
				for _,enemy in ipairs(self.opponents) do
					if not enemy:isKongcheng() then
						self.tianyi_card = my_max_card:getId()
						use.card = sgs.Card_Parse("@TianyiCard=.")
						if use.to then 
							use.to:append(enemy) 
						end
						return
					end
				end
			end
		end
		for _,enemy in ipairs(self.opponents) do
			if enemy:hasFlag("AI_HuangtianPindian") then
				if enemy:getHandcardNum() == 1 then
					self.tianyi_card = my_max_card:getId()
					use.card = sgs.Card_Parse("@TianyiCard=.")
					if use.to then
						use.to:append(enemy)
						enemy:setFlags("-AI_HuangtianPindian")
					end
					return
				end
			end
		end
		local slash = self:getCard("Slash")	
		local dummy_use = {
			isDummy = true,
		}
		self.player:setFlags("slashNoDistanceLimit")
		if slash then 
			self:useBasicCard(slash, dummy_use) 
		end
		self.player:setFlags("-slashNoDistanceLimit")
		local ZhuGeLiang = self.room:findPlayerBySkillName("kongcheng")
		if slash and slashCount >= 1 then
			if dummy_use.card then
				for _, enemy in ipairs(self.opponents) do
					if not enemy:isKongcheng() then
						if not enemy:hasSkill("kongcheng") or enemy:getHandcardNum() ~= 1 then
							local max_card = self:getMaxPointCard(enemy)
							local max_point = 100
							if max_card then
								max_point = max_card:getNumber()
							end
							if my_max_point > max_point then
								self.tianyi_card = my_max_card:getId()
								use.card = card
								if use.to then 
									use.to:append(enemy) 
								end
								return
							end
						end
					end
				end
				for _, enemy in ipairs(self.opponents) do
					if not enemy:isKongcheng() then
						if not enemy:hasSkill("kongcheng") or enemy:getHandcardNum() ~= 1 then
							if my_max_point >= 10 then
								self.tianyi_card = my_max_card:getId()
								use.card = card
								if use.to then 
									use.to:append(enemy) 
								end
								return
							end
						end
					end
				end
				if #self.opponents < 1 then 
					return 
				end
				self:sort(self.partners_noself, "handcard")
				for index = #self.partners_noself, 1, -1 do
					local friend = self.partners_noself[index]
					if not friend:isKongcheng() then
						local min_card = self:getMinPointCard(friend)
						local min_point = 100
						if min_card then
							min_point = min_card:getNumber()
						end
						if my_max_point > min_point then
							self.tianyi_card = my_max_card:getId()
							use.card = card
							if use.to then 
								use.to:append(friend) 
							end
							return
						end
					end
				end
				if ZhuGeLiang then
					if self:isPartner(ZhuGeLiang) then
						if ZhuGeLiang:getHandcardNum() == 1 then
							if ZhuGeLiang:objectName() ~= self.player:objectName() then
								if my_max_point >= 7 then
									self.tianyi_card = my_max_card:getId()
									use.card = card
									if use.to then 
										use.to:append(ZhuGeLiang) 
									end
									return
								end
							end
						end
					end
				end
				for index = #self.partners_noself, 1, -1 do
					local friend = self.partners_noself[index]
					if not friend:isKongcheng() then
						if my_max_point >= 7 then
							self.tianyi_card = my_max_card:getId()
							use.card = card
							if use.to then 
								use.to:append(friend) 
							end
							return
						end
					end
				end
			end
		end
		local handcards = self.player:getHandcards()
		local cards = sgs.QList2Table(handcards)
		if ZhuGeLiang then
			if self:isPartner(ZhuGeLiang) then
				if ZhuGeLiang:getHandcardNum() == 1 then
					if ZhuGeLiang:objectName()~= self.player:objectName() then
						if self:getEnemyNumBySeat(self.player, ZhuGeLiang) >= 1 then
							self:sortByUseValue(cards,true)
							if sgs.isCard("Jink", cards[1], self.player) then
								if self:getCardsNum("Jink") == 1 then 
									return 
								end
							end
							self.tianyi_card = cards[1]:getId()
							use.card = card
							if use.to then 
								use.to:append(ZhuGeLiang) 
							end
							return
						end
					end
				end
			end
		end
		if self:getOverflow() > 0 then
			self:sortByKeepValue(cards)
			for _, enemy in ipairs(self.opponents) do
				if not enemy:isKongcheng() then
					if not self:doNotDiscard(enemy, "h", true) then
						self.tianyi_card = cards[1]:getId()
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
sgs.ai_skill_pindian["tianyi"] = function(self, requestor, maxcard, mincard)
	local cards = self.player:getHandcards()
	local cards = sgs.QList2Table(cards)
	if requestor:getHandcardNum() == 1 then
		self:sortByKeepValue(cards)
		return cards[1]
	end
	if self:isPartner(requestor) then
		return mincard
	end
	if maxcard and maxcard:getNumber() < 6 then
		self:sortByUseValue(cards, true)
		return cards[1]
	else
		return maxcard
	end
end
--[[
	内容：“天义”卡牌需求
]]--
sgs.card_need_system["tianyi"] = function(self, card, player)
	local cards = player:getHandcards()
	local hasBig = false
	local current = self.room:getCurrent()
	local flag = string.format("visible_%s_%s", current:objectName(), player:objectName())
	for _,c in sgs.qlist(cards) do
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
	套路：仅使用“天义技能卡”
]]--
sgs.ai_series["TianyiCardOnly"] = {
	name = "TianyiCardOnly", 
	IQ = 2,
	value = 2, 
	priority = 1, 
	skills = "tianyi",
	cards = { 
		["TianyiCard"] = 1, 
		["Others"] = 1, 
	},
	enabled = function(self) 
		return true
	end,
	action = function(self, handcards, skillcards) 
		local tianyi_skill = sgs.ai_skills["tianyi"]
		local dummyCard = tianyi_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self) 
		return false
	end,
}
table.insert(sgs.ai_card_actions["TianyiCard"], "TianyiCardOnly")
--[[****************************************************************
	武将：火·袁绍（群）
]]--****************************************************************
sgs.ai_chaofeng.yuanshao = 1
--[[
	技能：乱击
	描述：你可以将两张相同花色的手牌当【万箭齐发】使用。 
]]--
--[[
	内容：注册“乱击万箭齐发”
]]--
sgs.RegistCard("luanji>>ArcheryAttack")
--[[
	内容：“乱击”技能信息
]]--
sgs.ai_skills["luanji"] = {
	name = "luanji",
	dummyCard = function(self)
		local suit = sgs.archery_attack:getSuitString()
		local number = sgs.archery_attack:getNumberString()
		local card_id = sgs.archery_attack:getEffectiveId()
		local card_str = ("archery_attack:luanji[%s:%s]=%d"):format(suit, number, card_id)
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		return #handcards >= 2
	end,
}
--[[
	内容：“乱击万箭齐发”的具体产生方式
]]--
sgs.ai_view_as_func["luanji>>ArcheryAttack"] = function(self, card)
	local handcards = self.player:getHandcards()
	local cards = {}
	for _,c in sgs.qlist(handcards) do
		if not c:isKindOf("Peach") then
			if not c:isKindOf("ExNihilo") then
				if not c:isKindOf("AOE") then
					table.insert(cards, c)
				end
			end
		end
	end
	if #cards > 1 then
		for _,cardA in ipairs(cards) do
			local idA = cardA:getId()
			local suit = cardA:getSuitString()
			for _,cardB in ipairs(cards) do
				local idB = cardB:getId()
				if idA ~= idB then
					if suit == cardB:getSuitString() then
						local aa = sgs.cloneCard("archery_attack")
						aa:addSubcard(cardA)
						aa:addSubcard(cardB)
						local dummy_use = {
							isDummy = true,
						}
						self:useTrickCard(aa, dummy_use)
						if dummy_use.card then
							local card_str = ("archery_attack:luanji[to_be_decided:0]=%d+%d"):format(idA, idB)
							local archery_attack = sgs.Card_Parse(card_str)
							return archery_attack
						end
					end
				end
			end
		end
	end
end
--[[
	套路：仅使用“乱击万箭齐发”
]]--
sgs.ai_series["luanji>>ArcheryAttackOnly"] = {
	name = "luanji>>ArcheryAttackOnly", 
	value = 2, 
	priority = 1, 
	skills = "luanji",
	cards = { 
		["luanji>>ArcheryAttack"] = 1, 
		["Others"] = 2, 
	},
	enabled = function(self) 
		local cards = self.player:getCards("h")
		local suits = {}
		for _,card in sgs.qlist(cards) do
			local suit = card:getSuitString()
			if suits[suit] then
				return true
			else
				suits[suit] = true
			end
		end
		return false
	end,
	action = function(self, handcards, skillcards) 
		local luanji_skill = sgs.ai_skills["luanji"]
		local dummyCard = luanji_skill["dummyCard"]()
		dummyCard:setFlags("isDummy")
		return {dummyCard}
	end,
	break_condition = function(self) 
		return false
	end,
}
table.insert(sgs.ai_card_actions["luanji>>ArcheryAttack"], "luanji>>ArcheryAttackOnly")
--[[
	技能：血裔（主公技，锁定技）
	描述：你的手牌上限+2X。（X为其他群雄角色的数量） 
]]--
--[[****************************************************************
	武将：火·颜良文丑（群）
]]--****************************************************************
sgs.ai_chaofeng.yanliangwenchou = 1
--[[
	技能：双雄
	描述：摸牌阶段开始时，你可以放弃摸牌，改为进行一次判定，当判定牌生效后，你获得此牌，然后你于此回合内可以将一张与此牌颜色不同的手牌当【决斗】使用。 
]]--
--[[
	内容：注册“双雄决斗”
]]--
sgs.RegistCard("shuangxiong>>Duel")
--[[
	内容：“双雄”技能信息
]]--
sgs.ai_skills["shuangxiong"] = {
	name = "shuangxiong",
	dummyCard = function(self)
		local suit = sgs.duel:getSuitString()
		local number = sgs.duel:getNumberString()
		local card_id = sgs.duel:getEffectiveId()
		local card_str = ("duel:shuangxiong[%s:%s]=%d"):format(suit, number, card_id)
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if self.player:getMark("shuangxiong") > 0 then
			return #handcards > 0 
		end
		return false
	end,
}
--[[
	内容：“双雄决斗”的具体产生方式
]]--
sgs.ai_view_as_func["shuangxiong>>Duel"] = function(self, card)
	local mark = self.player:getMark("shuangxiong")
	local cards = self.player:getHandcards()
	local to_use = {}
	if mark == 1 then
		for _,c in sgs.qlist(cards) do
			if c:isBlack() then
				table.insert(to_use, c)
			end
		end
	elseif mark == 2 then
		for _,c in sgs.qlist(cards) do
			if c:isRed() then
				table.insert(to_use, c)
			end
		end
	end
	if #to_use > 0 then
		self:sortByUseValue(to_use, true)
		local acard = to_use[1]
		local suit = acard:getSuitString()
		local number = acard:getNumberString()
		local card_id = acard:getEffectiveId()
		local card_str = ("duel:shuangxiong[%s:%s]=%d"):format(suit, number, card_id)
		local duel = sgs.Card_Parse(card_str)
		return duel
	end
end
sgs.ai_skill_invoke["shuangxiong"] = function(self, data)
	if self:needBear() then 
		return false 
	end
	if self.player:getHandcardNum() >= 3 then
		if self.player:isSkipped(sgs.Player_Play) then
			return false
		end
		if #self.opponents == 0 then
			return false
		end
		if self.player:getHp() < 2 then
			if self:getCardsNum("Slash") <= 1 then
				return false
			elseif self.player:getHandcardNum() < 3 then
				return false
			end
		end
		local dummy_use = {
			isDummy = true
		}
		self:useTrickCard(sgs.duel, dummy_use)
		if dummy_use.card then
			return true
		end
	end
	return false
end
--[[
	内容：“双雄”卡牌需求
]]--
sgs.card_need_system["shuangxiong"] = function(self, card, player)
	return not self:willSkipDrawPhase(player)
end
sgs.draw_cards_system["shuangxiong"] = {
	name = "shuangxiong",
	return_func = function(self, player)
		return 1
	end,
}
--[[
	套路：仅使用“双雄决斗”
]]--
sgs.ai_series["shuangxiong>>DuelOnly"] = {
	name = "shuangxiong>>DuelOnly", 
	value = 2, 
	priority = 1, 
	cards = { 
		["shuangxiong>>Duel"] = 1, 
		["Others"] = 1, 
	},
	enabled = function(self) 
		return true
	end,
	action = function(self, handcards, skillcards) 
		local shuangxiong_skill = sgs.ai_skills["shuangxiong"]
		local dummyCard = shuangxiong_skill["dummyCard"](self)
		dummyCard:setFlags("isDummy")
		return {dummyCard}
	end,
	break_condition = function(self) 
		return false
	end,
}
table.insert(sgs.ai_card_actions["shuangxiong>>Duel"], "shuangxiong>>DuelOnly")
--[[****************************************************************
	武将：火·庞德（群）
]]--****************************************************************
--[[
	技能：马术（锁定技）
	描述：你与其他角色的距离-1。 
]]--
--[[
	技能：猛进
	描述：你使用的【杀】被目标角色的【闪】抵消后，你可以弃置该角色的一张牌。 
]]--
sgs.ai_skill_invoke["mengjin"] = function(self, data)
	local effect = data:toSlashEffect()
	local target = effect.to
	if self:isOpponent(target) then
		if self:doNotDiscard(effect.to) then
			return false
		end
	end
	if self:isPartner(target) then 
		if self:needToThrowArmor(target) then
			return true
		elseif self:doNotDiscard(effect.to) then
			return true
		end
	end
	return not self:isPartner(target)
end