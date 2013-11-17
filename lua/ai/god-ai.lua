--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）神武将包部分
]]--
--[[****************************************************************
	武将：神·关羽（神）
]]--****************************************************************
sgs.ai_chaofeng.shenguanyu = -6
--[[
	技能：武神（锁定技）
	描述：你的♥手牌视为普通【杀】。你使用♥【杀】无距离限制。
]]--
--[[
	内容：注册“武神杀”
]]--
sgs.RegistCard("wushen>>Slash")
--[[
	内容：“武神”技能信息
]]--
sgs.ai_skills["wushen"] = {
	name = "wushen",
	dummyCard = function(self)
		local suit = sgs.slash:getSuitString()
		local number = sgs.slash:getNumberString()
		local card_id = sgs.slash:getEffectiveId()
		local card_str = ("slash:wushen[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)
		return slash
	end,
	enabled = function(self, handcards)
		if sgs.slash:isAvailable(self.player) then
			local cards = self.player:getCards("he")
			for _,heart in sgs.qlist(cards) do
				if heart:getSuit() == sgs.Card_Heart then
					return true
				end
			end
		end
		return false
	end,
}
--[[
	内容：“武神杀”的具体产生方式
]]--
sgs.ai_view_as_func["wushen>>Slash"] = function(self, card)
	local cards = self.player:getCards("he")
	local hearts = {}
	for _,heart in sgs.qlist(cards) do
		if heart:getSuit() == sgs.Card_Heart then
			table.insert(hearts, heart)
			break
		end
	end
	if #hearts > 0 then
		local heart = hearts[1]
		local suit = heart:getSuitString()
		local number = heart:getNumberString()
		local card_id = heart:getEffectiveId()
		local card_str = ("slash:wushen[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)
		return slash
	end
end
sgs.ai_filterskill_filter["wushen"] = function(card, player, place)
	if card:getSuit() == sgs.Card_Heart then 
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		return ("slash:wushen[%s:%s]=%d"):format(suit, number, card_id) 
	end
end
--[[
	内容：“武神”响应方式
	需求：杀
]]--
sgs.ai_view_as["wushen"] = function(card, player, place, class_name)
	if place ~= sgs.Player_PlaceSpecial then
		if card:getSuit() == sgs.Card_Heart then
			if not card:hasFlag("using") then
				local suit = card:getSuitString()
				local number = card:getNumberString()
				local card_id = card:getEffectiveId()
				return ("slash:wushen[%s:%s]=%d"):format(suit, number, card_id)
			end
		end
	end
end
--[[
	内容：“武神”统计信息
]]--
sgs.card_count_system["wushen"] = {
	name = "wushen",
	pattern = "Slash",
	ratio = 0.5,
	statistics_func = function(class_name, player, data)
		if player:hasSkill("wushen") then
			local count = data["count"]
			count = count + data["heart"] 
			count = count + data["unknown"] * 0.5
			return count
		end
	end
}
--[[
	套路：仅使用“武神杀”
]]--
sgs.ai_series["wushen>>SlashOnly"] = {
	name = "wushen>>SlashOnly",
	IQ = 2,
	value = 2,
	priority = 1,
	skills = "wushen",
	cards = {
		["wushen>>Slash"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local wushen_skill = sgs.ai_skills["wushen"]
		local slash = wushen_skill["dummyCard"](self)
		slash:setFlags("isDummy")
		return {slash}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["wushen>>Slash"], "wushen>>SlashOnly")
--[[
	技能：武魂（锁定技）
	描述：每当你受到伤害扣减体力前，伤害来源获得等于伤害点数的“梦魇”标记。你死亡时，你选择拥有“梦魇”标记数最多的一名存活角色，该角色进行一次判定：若判定结果不为【桃】或【桃园结义】，该角色死亡。 
]]--
sgs.ai_skill_playerchosen["wuhun"] = function(self, targets)
	local enemies = {}
	local lords = {}
	for _, player in sgs.qlist(targets) do
		if self:mayLord(player) then 
			table.insert(lords, player)
		end
		if self:isEnemy(player) then
			table.insert(enemies, player)
		end
	end
	if #lords > 0 then
		if self:amRebel() then
			for _,lord in ipairs(lords) do
				if self:isEnemy(lord) then
					return lord
				end
			end
		end
	end
	if #enemies > 0 then
		self:sort(enemies, "threat")
		return enemies[1]
	end
	local targetlist = sgs.QList2Table(targets) 
	self:sort(targetlist, "hp")
	local target = targetlist[1]
	if self:amLoyalist() then
		if self:mayLord(target) then
			target = targetlist[2]
		end
	end
	return target
end
sgs.slash_prohibit_system["wuhun"] = {
	name = "wuhun",
	reason = "wuhun",
	judge_func = function(self, target, source, slash)
		--绝情
		if source:hasSkill("jueqing") then 
			return false 
		end
		--原版解烦
		if source:hasFlag("NosJiefanUsed") then 
			return false 
		end
		--武魂
		local damageNum = self:hasHeavySlashDamage(source, slash, target, true) or 1
		local friends = self:getPartners(source)
		local enemies = self:getOpponents(source)
		local maxfriendmark = 0
		local maxenemymark = 0
		for _, friend in ipairs(friends) do
			local friendmark = friend:getMark("@nightmare")
			if friendmark > maxfriendmark then 
				maxfriendmark = friendmark 
			end
		end
		for _, enemy in ipairs(enemies) do
			local enemymark = enemy:getMark("@nightmare")
			if enemymark > maxenemymark then	
				if enemy:objectName() ~= target:objectName() then 
					maxenemymark = enemymark 
				end
			end
		end
		if self:isEnemy(target, source) then
			if not self:mayLord(target) or not self:mayRebel(source) then
				if maxfriendmark + damageNum >= maxenemymark then
					local aliveCount = self.room:alivePlayerCount()
					if #enemies ~= 1 or #friends + #enemies < aliveCount then
						if source:getMark("@nightmare") ~= maxfriendmark or not self:mayLoyalist(source) then
							return true
						end
					end
				end
			end
		end
	end
}
sgs.damage_avoid_system["wuhun"] = {
	reason = "wuhun",
	judge_func = function(self, target, damage, source)
		local name = target:objectName()
		for _,lord in ipairs(sgs.ai_lords) do
			if lord == name then
				return false
			end
		end
		local maxFriendMark = 0
		local maxEnemyMark = 0
		local myname = source:objectName()
		local target_friends = self:getFriends(target, nil, true)
		if #target_friends > 0 then
			local my_friends = self:getFriends(source)
			local my_enemies = self:getEnemies(source)
			for _,friend in ipairs(my_friends) do
				local mark = friend:getMark("@nightmare")
				if mark > maxFriendMark then
					maxFriendMark = mark
				end
			end
			for _,enemy in ipairs(my_enemies) do
				if enemy:objectName() ~= name then
					local mark = enemy:getMark("@nightmare")
					if mark > maxEnemyMark then
						maxEnemyMark = mark
					end
				end
			end
			if self:isEnemy(target, source) then
				if maxFriendMark + damage > maxEnemyMark then
					local aliveCount = self.room:alivePlayerCount()
					if #my_enemies == 1 then
						if #my_friends + #my_enemies == aliveCount then
							return false
						end
					end
					if source:getMark("@nightmare") == maxFriendMark then
						if self:mayLoyalist(source) then 
							return false
						end
					end
					return true
				end
			elseif maxFriendMark + damage > maxEnemyMark then
				return true
			end
		end
	end
}
--[[
	功能：获取所有可能的武魂复仇目标
	参数：无
	结果：table类型（targets），表示所有可能的目标
]]--
function sgs.getWuhunRevengeTargets()
	local targets = {}
	local maxcount = 0
	local alives = global_room:getAlivePlayers()
	for _, p in sgs.qlist(alives) do
		local count = p:getMark("@nightmare")
		if count > maxcount then
			targets = { p }
			maxcount = count
		elseif count == maxcount then
			table.insert(targets, p)
		end
	end
	return targets
end
--[[****************************************************************
	武将：神·吕蒙（神）
]]--****************************************************************
--[[
	技能：涉猎
	描述：摸牌阶段开始时，你可以放弃摸牌，改为从牌堆顶亮出五张牌，你获得不同花色的牌各一张，将其余的牌置入弃牌堆。 
]]--
sgs.ai_skill_invoke["shelie"] = true
sgs.draw_cards_system["shelie"] = {
	name = "shelie",
	return_func = function(self, player)
		return 3
	end,
}
--[[
	技能：攻心
	描述：出牌阶段限一次，你可以观看一名其他角色的手牌，然后选择其中一张♥牌并选择一项：弃置之，或将之置于牌堆顶。
]]--
--[[
	内容：“攻心技能卡”的卡牌成分
]]--
sgs.card_constituent["GongxinCard"] = {
	use_value = 8.5,
	use_priority = 9.5,
}
--[[
	内容：“攻心技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["GongxinCard"] = 80
--[[
	内容：注册“攻心技能卡”
]]--
sgs.RegistCard("GongxinCard")
--[[
	内容：“攻心”技能信息
]]--
sgs.ai_skills["gongxin"] = {
	name = "gongxin",
	dummyCard = function(self)
		local card_str = ("@GongxinCard=.")
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if self.player:hasUsed("GongxinCard") then 
			return false
		end
		return true
	end
}
--[[
	内容：“攻心技能卡”的一般使用方式
]]--
sgs.ai_skill_use_func["GongxinCard"] = function(self, card, use)
	if #self.opponents > 0 then
		self:sort(self.opponents, "handcard")
		for index = #self.opponents, 1, -1 do
			local enemy = self.opponents[index]
			if not enemy:isKongcheng() then
				use.card = card
				if use.to then
					use.to:append(enemy)
				end
				return 
			end
		end
	end
end
sgs.ai_skill_askforag.gongxin = function(self, card_ids)
	local tag = self.player:getTag("GongxinTarget")
	local target = tag:toPlayer()
	if target then
		if self:isPartner(target) then
			return -1
		end
		local nextAlive = self.player
		repeat
			nextAlive = nextAlive:getNextAlive()
		until nextAlive:faceUp()
		local peach, ex_nihilo, jink, nullification, slash
		local valuable = nil
		for _,id in ipairs(card_ids) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("Peach") then 
				peach = id 
			elseif card:isKindOf("ExNihilo") then 
				ex_nihilo = id 
			elseif card:isKindOf("Jink") then 
				jink = id 
			elseif card:isKindOf("Nullification") then 
				nullification = id 
			elseif card:isKindOf("Slash") then 
				slash = id 
			end
		end
		valuable = peach or ex_nihilo or jink or nullification or slash or card_ids[1]
		local willUseExNihilo, willRecast
		if self:getCardsNum("ExNihilo") > 0 then
			local ex_nihilo2 = self:getCard("ExNihilo")
			if ex_nihilo2 then
				local dummy_use = { 
					isDummy = true, 
				}
				self:useTrickCard(ex_nihilo2, dummy_use)
				if dummy_use.card then 
					willUseExNihilo = true 
				end
			end
		elseif self:getCardsNum("IronChain") > 0 then
			local iron_chain = self:getCard("IronChain")
			if iron_chain then
				local dummy_use = { 
					to = sgs.SPlayerList(), 
					isDummy = true, 
				}
				self:useTrickCard(iron_chain, dummy_use)
				if dummy_use.card then
					if dummy_use.to:isEmpty() then 
						willRecast = true 
					end
				end
			end
		end
		if willUseExNihilo or willRecast then
			local card = sgs.Sanguosha:getCard(valuable)
			if card:isKindOf("Peach") then
				self.gongxinchoice = "put"
				return valuable
			elseif card:isKindOf("Nullification") then
				if self:getCardsNum("Nullification") == 0 then
					self.gongxinchoice = "put"
					return valuable
				end
			elseif sgs.isKindOf("TrickCard|Indulgence|SupplyShortage", card) then
				local dummy_use = { 
					isDummy = true 
				}
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then
					self.gongxinchoice = "put"
					return valuable
				end
			elseif card:isKindOf("Jink") then
				if self:getCardsNum("Jink") == 0 then
					self.gongxinchoice = "put"
					return valuable
				end
			elseif card:isKindOf("Slash") then
				if sgs.slash:isAvailable(self.player) then
					local dummy_use = { 
						isDummy = true, 
					}
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then
						self.gongxinchoice = "put"
						return valuable
					end
				end
			end
			self.gongxinchoice = "discard"
			return valuable
		end
		if self:isOpponent(nextAlive) then
			if nextAlive:hasSkill("luoshen") then
				if valuable then
					self.gongxinchoice = "put"
					return valuable
				end
			end
		end
		if nextAlive:hasSkill("yinghun") then
			if nextAlive:isWounded() then
				if self:isPartner(nextAlive) then
					self.gongxinchoice = "put" 
				else
					self.gongxinchoice = "discard"
				end
				return valuable
			end
		end
		local hasLightning, hasIndulgence, hasSupplyShortage
		local tricks = nextAlive:getJudgingArea()
		if not tricks:isEmpty() then
			if not nextAlive:containsTrick("YanxiaoCard") then
				local trick = tricks:at(tricks:length() - 1)
				if self:trickIsEffective(trick, nextAlive) then
					if trick:isKindOf("Lightning") then 
						hasLightning = true
					elseif trick:isKindOf("Indulgence") then 
						hasIndulgence = true
					elseif trick:isKindOf("SupplyShortage") then 
						hasSupplyShortage = true
					end
				end
			end
		end
		if target:hasSkill("hongyan") then
			if hasLightning then
				if self:isOpponent(nextAlive) then
					if not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum() > 0) then
						for _, id in ipairs(card_ids) do
							local card = sgs.Sanguosha:getEngineCard(id)
							if card:getSuit() == sgs.Card_Spade then
								if card:getNumber() >= 2 then
									if card:getNumber() <= 9 then
										self.gongxinchoice = "put"
										return id
									end
								end
							end
						end
					end
				end
			end
		end
		if hasIndulgence then
			if self:isPartner(nextAlive) then
				self.gongxinchoice = "put"
				return valuable
			end
		end
		if hasSupplyShortage then
			if self:isOpponent(nextAlive) then
				if not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum() > 0) then
					local enemy_null = 0
					local others = self.room:getOtherPlayers(self.player)
					for _, p in sgs.qlist(others) do
						if self:isPartner(p) then 
							enemy_null = enemy_null - sgs.getCardsNum("Nullification", p) 
						elseif self:isOpponent(p) then 
							enemy_null = enemy_null + sgs.getCardsNum("Nullification", p) 
						end
					end
					enemy_null = enemy_null - self:getCardsNum("Nullification")
					if enemy_null < 0.8 then
						self.gongxinchoice = "put"
						return valuable
					end
				end
			end
		end
		if self:isPartner(nextAlive) then
			if not self:willSkipDrawPhase() then
				if not self:willSkipPlayPhase() then
					if not nextAlive:hasSkill("luoshen") then
						if not nextAlive:hasSkill("tuxi") then
							if not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum() > 0) then
								if peach and valuable == peach then
									self.gongxinchoice = "put"
									return valuable
								elseif ex_nihilo and valuable == ex_nihilo then
									self.gongxinchoice = "put"
									return valuable
								elseif jink and valuable == jink then
									if sgs.getCardsNum("Jink", nextAlive) < 1 then
										self.gongxinchoice = "put"
										return valuable
									end
								elseif nullification and valuable == nullification then
									if sgs.getCardsNum("Nullification", nextAlive) < 1 then
										self.gongxinchoice = "put"
										return valuable
									end
								elseif slash and valuable == slash then
									if self:hasCrossbowEffect(nextAlive) then
										self.gongxinchoice = "put"
										return valuable
									end
								end
							end
						end
					end
				end
			end
		end
		local card = sgs.Sanguosha:getCard(valuable)
		local keep = false
		if sgs.isKindOf("Slash|Jink|EquipCard|Disaster|GlobalEffect|Nullification", card) then
			keep = true
		elseif target:isLocked(card) then
			keep = true
		end
		self.gongxinchoice = "discard"
		if keep then
			if target:objectName() == nextAlive:objectName() then
				self.gongxinchoice = "put"
			end
		end
		return valuable
	end
end
sgs.ai_skill_choice.gongxin = function(self, choices)
	return self.gongxinchoice or "discard"
end
--[[
	套路：仅使用“攻心技能卡”
]]--
sgs.ai_series["GongxinCardOnly"] = {
	name = "GongxinCardOnly", 
	IQ = 2,
	value = 10, 
	priority = 5, 
	skills = "gongxin",
	cards = { 
		["GongxinCard"] = 1, 
		["Others"] = 0, 
	},
	enabled = function(self) 
		if self.player:hasUsed("GongxinCard") then
			return false
		end
		return true
	end,
	action = function(self, handcards, skillcards) 
		local gongxin_skill = sgs.ai_skills["gongxin"]
		local dummyCard = gongxin_skill["dummyCard"]()
		return {dummyCard}
	end,
	break_condition = function(self) 
		return false
	end,
}
table.insert(sgs.ai_card_actions["GongxinCard"], "GongxinCardOnly")
--[[****************************************************************
	武将：神·周瑜（神）
]]--****************************************************************
--[[
	技能：琴音
	描述：每当你于弃牌阶段内因你的弃置而失去第X张手牌时（X至少为2），你可以选择一项：1.令所有角色各回复1点体力；2.令所有角色各失去1点体力。每阶段限一次。 
]]--
sgs.ai_skill_invoke["qinyin"] = function(self, data)
	self:sort(self.partners, "hp")
	self:sort(self.opponents, "hp")
	local up = 0
	local down = 0
	for _,friend in ipairs(self.partners) do
		local isWounded = friend:isWounded()
		down = down - 10
		up = up + (isWounded and 10 or 0)
		if self:hasSkills(sgs.masochism_skill, friend) then
			down = down - 5
			if isWounded then 
				up = up + 5 
			end
		end
		if self:needToLoseHp(friend, nil, nil, true) then 
			down = down + 5 
		end
		if self:needToLoseHp(friend, nil, nil, true, true) then
			if isWounded then 
				up = up - 5 
			end
		end
		if self:isWeak(friend) then
			local isLord = self:mayLord(friend)
			if isWounded then 
				up = up + 10 + (isLord and 20 or 0) 
			end
			down = down - 10 - (isLord and 40 or 0)
			if friend:getPile("buqu"):length() > 4 then
				down = down - 20 - (isLord and 40 or 0)
			elseif friend:getHp() <= 1 then
				if not friend:hasSkill("buqu") then
					down = down - 20 - (isLord and 40 or 0)
				end
			end
		end
	end
	for _,enemy in ipairs(self.partners) do
		local isWounded = enemy:isWounded()
		down = down + 10
		up = up - (isWounded and 10 or 0)
		if self:hasSkills(sgs.masochism_skill, enemy) then 
			down = down + 10
			if isWounded then 
				up = up - 10 
			end
		end
		if self:needToLoseHp(enemy, nil, nil, true) then 
			down = down - 5 
		end
		if self:needToLoseHp(enemy, nil, nil, true, true) then
			if isWounded then 
				up = up - 5 
			end
		end
		if self:isWeak(enemy) then
			if isWounded then 
				up = up - 10 
			end
			down = down + 10
			if enemy:getHp() <= 1 then
				if not enemy:hasSkill("buqu") then
					down = down + 10
					if self:mayLord(enemy) then
						if #self.opponents > 1 then
							down = down + 20
						end
					end
				end
			end
		end
	end
	if down > 0 then 
		sgs.ai_skill_choice["qinyin"] = "down"
		return true
	elseif up > 0 then
		sgs.ai_skill_choice["qinyin"] = "up"
		return true
	end
	return false
end
--[[
	技能：业炎（限定技）
	描述：出牌阶段，你可以对一至三名角色造成至多共3点火焰伤害（你选择目标时任意分配每名目标角色受到的伤害点数）。若你将对一名角色分配2点或更多的火焰伤害，你须执行弃置四张不同花色的手牌并失去3点体力的消耗。 
]]--
--[[
	功能：判断是否有条件使用“大/中业炎技能卡”
]]--
function SmartAI:judgeGreatYeyan()
	if self.player:getHandcardNum() >= 4 then
		local spade, club, heart, diamond
		local cards = self.player:getHandcards()
		for _,card in sgs.qlist(cards) do
			local suit = card:getSuit()
			if suit == sgs.Card_Spade then
				spade = true
			elseif suit == sgs.Card_Heart then
				heart = true
			elseif suit == sgs.Card_Club then
				club = true
			elseif suit == sgs.Card_Diamond then
				diamond = true
			end
		end
		if spade and heart and club and diamond then
			return true
		end
	end
	return false
end
--[[
	内容：“大/中业炎技能卡”、“小业炎技能卡”的卡牌成分
]]--
sgs.card_constituent["GreatYeyanCard"] = {
	use_value = 8,
	use_priority = 9,
}
sgs.card_constituent["SmallYeyanCard"] = {
	use_priority = 2.3,
}
--[[
	内容：“大/中业炎技能卡”、“小业炎技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["GreatYeyanCard"] = 200
sgs.ai_card_intention["SmallYeyanCard"] = 80
--[[
	内容：注册“大/中业炎技能卡”、“小业炎技能卡”
]]--
sgs.RegistCard("GreatYeyanCard")
sgs.RegistCard("SmallYeyanCard")
--[[
	内容：“业炎”技能信息
]]--
sgs.ai_skills["yeyan"] = {
	name = "yeyan",
	dummyCard = function(self)
		local card_str = ""
		if sgs.Ask_GreatYeyanCard then
			card_str = "@GreatYeyanCard=."
		elseif sgs.Ask_SmallYeyanCard then
			card_str = "@SmallYeyanCard=."
		else
			if self:judgeGreatYeyan() then
				card_str = "@GreatYeyanCard=."
			else
				card_str = "@SmallYeyanCard=."
			end
		end
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		return self.player:getMark("@flame") > 0
	end,
}
sgs.ai_skill_use_func["GreatYeyanCard"] = function(self, card, use)
	if #self.opponents > 0 then
		local changeToSmall = true
		self:sort(self.opponents, "hp")
		for _,enemy in ipairs(self.opponents) do
			if enemy:isChained() then
				if self:isGoodChainTarget(enemy, nil, nil, 3) then
					changeToSmall = false
					break
				end
			else
				if enemy:getHp() <= 3 then
					changeToSmall = false
					break
				elseif enemy:hasArmorEffect("Vine") then
					changeToSmall = false
					break 
				end
			end
		end
		if changeToSmall then
			local callback = sgs.ai_skill_use_func["SmallYeyanCard"]
			return callback(self, card, use)
		else
			if self:amLord() then
				if sgs.turncount <= 1 then
					return 
				elseif self:getAllPeachNum() < 4 - self.player:getHp() then
					return 
				elseif self:countRebel() > #self:getChainedOpponents() then
					return 
				end
			elseif self:amRenegade() then
				if self.room:alivePlayerCount() > 2 then
					if self:getCardsNum("Peach") < 3 - self.player:getHp() then
						return 
					end
				end
			end
			local handcards = self.player:getHandcards()
			local cards = sgs.QList2Table(handcards)
			self:sortByUseValue(cards, true)
			local to_use = {}
			local spade, heart, club, diamond
			for _,c in ipairs(cards) do
				local suit = c:getSuit()
				if suit == sgs.Card_Spade then
					if not spade then
						spade = c
						table.insert(to_use, c:getId())
					end
				elseif suit == sgs.Card_Heart then
					if not heart then
						heart = c
						table.insert(to_use, c:getId())
					end
				elseif suit == sgs.Card_Club then
					if not club then
						club = c
						table.insert(to_use, c:getId())
					end
				elseif suit == sgs.Card_Diamond then
					if not diamond then
						diamond = c
						table.insert(to_use, c:getId())
					end
				end
			end
			if #to_use == 4 then
				local card_str = "@GreatYeyanCard="..table.concat(to_use, "+")
				local acard = sgs.Card_Parse(card_str)
				local targets = {}
				for _,enemy in ipairs(self.opponents) do
					if not enemy:hasArmorEffect("SilverLion") then
						if self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
							if self:friendshipLevel(enemy) < -4 then
								local flag = true
								if enemy:hasSkill("tianxiang") then
									if not enemy:isKongcheng() then
										flag = false
									end
								end
								if flag then
									table.insert(targets, enemy)
								end
							end
						end
					end
				end
				if #targets > 0 then
					local target = nil
					for _,enemy in ipairs(targets) do
						if enemy:isChained() then
							if self:isGoodChainTarget(enemy, nil, nil, 3) then
								if enemy:hasArmorEffect("Vine") or enemy:getMark("@gale") > 0 then
									use.card = acard
									if use.to then
										use.to:append(enemy)
										use.to:append(enemy)
										use.to:append(enemy)
									end
									return 
								elseif not target then
									target = enemy
								end
							end
						end
					end
					if target then
						use.card = acard
						if use.to then
							use.to:append(enemy)
							use.to:append(enemy)
							use.to:append(enemy)
						end
						return 
					end
					for _,enemy in ipairs(targets) do
						if enemy:hasArmorEffect("Vine") or enemy:getMark("@gale") > 0 then
							use.card = acard
							if use.to then
								use.to:append(enemy)
								use.to:append(enemy)
								use.to:append(enemy)
							end
							return 
						elseif not target then
							target = enemy
						end
					end
					if target then
						use.card = acard
						if use.to then
							use.to:append(enemy)
							use.to:append(enemy)
							use.to:append(enemy)
						end
					end
				end
			end
		end
	end
end
sgs.ai_skill_use_func["SmallYeyanCard"] = function(self, card, use)
	self.yeyanchained = false
	local acard = nil
	if self.player:getHp() + self:getCardsNum("Peach") + self:getCardsNum("Analeptic") <= 2 then
		acard = sgs.Card_Parse("@SmallYeyanCard=.")
	end
	if not acard then
		local target_num = 0
		local chained = 0
		for _, enemy in ipairs(self.opponents) do
			local flag = false
			if enemy:getHp() <= 1 then
				flag = true
			elseif enemy:hasArmorEffect("Vine") then
				flag = true
			elseif enemy:getMark("@gale") > 0 then
				flag = true
			end
			if flag then
				if self:amRenegade() then
					if self:mayLord(enemy) then
						flag = false
					end
				end
			end
			if flag then
				target_num = target_num + 1
			end
		end
		for _, enemy in ipairs(self.opponents) do
			if enemy:isChained() then
				if self:isGoodChainTarget(enemy) then 
					if chained == 0 then 
						target_num = target_num +1 
					end
					chained = chained + 1
				end
			end
		end
		self.yeyanchained = ( chained > 1 )
		if target_num > 2 then
			acard = sgs.Card_Parse("@SmallYeyanCard=.")
		elseif target_num > 1 and self.yeyanchained then
			acard = sgs.Card_Parse("@SmallYeyanCard=.")
		else
			local aliveCount = self.room:alivePlayerCount()
			if #self.opponents + 1 == aliveCount then
				local mode = self.room:getMode()
				local count = sgs.Sanguosha:getPlayerCount(mode)
				if aliveCount < count then
					acard = sgs.Card_Parse("@SmallYeyanCard=.")
				end
			end
		end
	end
	if acard then
		local targets = sgs.SPlayerList()
		local enemies = {}
		for _,enemy in ipairs(self.opponents) do
			if self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
				if enemy:isKongcheng() then
					table.insert(enemies, enemy)
				elseif not enemy:hasSkill("tianxiang") then
					table.insert(enemies, enemy)
				end
			end
		end
		for _,enemy in ipairs(enemies) do
			if enemy:isChained() then
				if enemy:hasArmorEffect("Vine") then
					if self:isGoodChainTarget(enemy) then
						if not targets:contains(enemy) then
							targets:append(enemy)
							if targets:length() >= 3 then 
								break 
							end
						end
					end
				end
			end
		end
		if targets:length() < 3 then
			for _,enemy in ipairs(enemies) do
				if enemy:isChained() then
					if self:isGoodChainTarget(enemy) then
						if not targets:contains(enemy) then
							targets:append(enemy) 
							if targets:length() >= 3 then 
								break 
							end
						end
					end
				end
			end
		end
		if targets:length() < 3 then
			for _,enemy in ipairs(enemies) do
				if not enemy:isChained() then
					if enemy:hasArmorEffect("Vine") then
						if not targets:contains(enemy) then
							targets:append(enemy)
							if targets:length() >= 3 then 
								break 
							end
						end
					end
				end
			end
		end
		if targets:length() < 3 then
			for _,enemy in ipairs(enemies) do
				if not enemy:isChained() then
					if not targets:contains(enemy) then
						targets:append(enemy)
						if targets:length() >= 3 then 
							break 
						end
					end
				end
			end
		end
		if not targets:isEmpty() then
			use.card = acard
			if use.to then
				use.to = targets
			end
		end
	end
end
--[[****************************************************************
	武将：神·诸葛亮（神）
]]--****************************************************************
--[[
	技能：七星
	描述：分发起始手牌时，共发你十一张牌，你选四张作为手牌，其余的背面朝上移出游戏，称为“星”；摸牌阶段结束时，你可以用任意数量的手牌等量替换这些“星”。 
]]--
sgs.ai_skill_askforag["qixing"] = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(card_id)
		table.insert(cards, card)
	end
	self:sortByCardNeed(cards)
	local phase = player:getPhase()
	if phase == sgs.Player_Draw then
		return cards[#cards]:getEffectiveId()
	elseif phase == sgs.Player_Finish then
		return cards[1]:getEffectiveId()
	end
	return -1
end
--[[
	技能：狂风
	描述：结束阶段开始时，你可以将一张“星”置入弃牌堆并选择一名角色，若如此做，你的下回合开始前，每当其受到的火焰伤害结算开始时，此伤害+1。 
]]--
--[[
	内容：“狂风技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["KuangfengCard"] = 80
sgs.ai_skill_use["@@kuangfeng"] = function(self, prompt)
	local friendly_fire
	for _,friend in ipairs(self.partners_noself) do
		if friend:getMark("@gale") == 0 then
			if self:damageIsEffective(friend, sgs.DamageStruct_Fire) then
				if friend:faceUp() then
					if not self:willSkipPlayPhase(friend) then
						if friend:hasSkill("huoji") then
							friendly_fire = true
							break
						elseif friend:hasWeapon("fan") then
							friendly_fire = true
							break
						elseif friend:hasSkill("yeyan") then
							if friend:getMark("@flame") > 0 then
								friendly_fire = true
								break
							end
						end
					end
				end
			end
		end
	end
	local is_chained = 0
	local targets = {}
	for _,enemy in ipairs(self.opponents) do
		if enemy:getMark("@gale") == 0 then
			if self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
				if enemy:isChained() then
					is_chained = is_chained + 1
					table.insert(targets, enemy)
				elseif enemy:hasArmorEffect("Vine") then
					table.insert(targets, 1, enemy)
					break
				end
			end
		end
	end
	local usecard = false
	if friendly_fire then
		if is_chained > 1 then 
			usecard = true 
		end
	end
	self:sort(self.partners, "hp")
	if target[1] then
		if not self:isWeak(self.partners[1]) then
			if target[1]:hasArmorEffect("Vine") then
				if friendly_fire then 
					usecard = true 
				end
			end
		end
	end
	if usecard then
		if not target[1] then 
			table.insert(target, self.opponents[1]) 
		end
		if target[1] then 
			return "@KuangfengCard=.->" .. target[1]:objectName() 
		end
	end
	return "."
end
sgs.heavy_slash_system["kuangfeng"] = {
	name = "kuangfeng",
	reason = "kuangfeng",
	extra_func = function(source, slash, target, isFireSlash, isThunderSlash)
		if isFireSlash then
			if not source:hasSkill("jueqing") then
				if target:getMark("@gale") > 0 then
					return 1
				end
			end
		end
		return 0
	end,
}
--[[
	技能：大雾
	描述：结束阶段开始时，你可以将X张“星”置入弃牌堆并选择X名角色，若如此做，你的下回合开始前，每当这些角色受到的非雷电伤害结算开始时，防止此伤害。 
]]--
--[[
	内容：“大雾技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["DawuCard"] = -70
sgs.ai_skill_use["@@dawu"] = function(self, prompt)
	self:sort(self.partners_noself, "hp")
	local targets = {}
	local lord = self:getMyLord()
	self:sort(self.partners_noself, "defense")
	local flag = false
	if lord then
		if lord:getMark("@fog") == 0 then
			if not sgs.isHealthy(lord) then
				if not self:amLord() then
					if not lord:hasSkill("buqu") then
						flag = true
					end
				end
			end
		end
	end
	if flag then
		if lord:hasSkill("hunzi") then
			if lord:getMark("hunzi") == 0 then
				if lord:getHp() > 1 then
					flag = false
				end
			end
		end
	end
	if flag then 
		table.insert(targets, lord:objectName())
	else
		for _, friend in ipairs(self.friends_noself) do
			local can_use = false
			if friend:getMark("@fog") == 0 then
				if self:isWeak(friend) then
					if not friend:hasSkill("buqu") then
						can_use = true
					end
				end
			end
			if can_use then
				if friend:hasSkill("hunzi") then
					if friend:getMark("hunzi") == 0 then
						if friend:getHp() > 1 then
							can_use = false
						end
					end
				end
			end
			if can_use then
				table.insert(targets, friend:objectName())
				break 
			end
		end	
	end
	if self.player:getPile("stars"):length() > #targets then
		if self:isWeak() then 
			table.insert(targets, self.player:objectName()) 
		end
	end
	if #targets > 0 then 
		return "@DawuCard=.->" .. table.concat(targets, "+") 
	end
	return "."
end
local dawu_damage_invalid = {
	reason = "dawu",
	judge_func = function(target, nature, source, notThunder)
		if notThunder then
			return target:getMark("@fog") > 0
		end
		return false
	end
}
table.insert(sgs.damage_invalid_system, dawu_damage_invalid) --添加到伤害无效判定表
--[[****************************************************************
	武将：神·曹操（神）
]]--****************************************************************
sgs.ai_chaofeng.shencaocao = -6
--[[
	技能：归心
	描述：每当你受到1点伤害后，若至少一名其他角色的区域里有牌，你可以选择所有其他角色，获得这些角色区域里的一张牌，然后将你的武将牌翻面。 
]]--
sgs.ai_skill_invoke["guixin"] = function(self, data)
	if self.player:hasSkill("manjuan") then
		if self.player:getPhase() == sgs.Player_NotActive then 
			return false 
		end
	end
	local DiaoChan = self.room:findPlayerBySkillName("lihun")
	if DiaoChan then
		if self:isOpponent(DiaoChan) then
			if not DiaoChan:hasUsed("LihunCard") then
				if self.player:isMale() then
					if self.room:alivePlayerCount() > 5 then
						local current = self.room:getCurrent()
						if DiaoChan:objectName() == current:objectName() then
							return false
						elseif self:playerGetRound(DiaoChan) < self:playerGetRound(self.player) then
							return false
						end
					end
				end
			end
		end
	end
	if self.room:alivePlayerCount() > 2 then
		return true
	elseif not self.player:faceUp() then
		return true
	end
	return false
end
sgs.ai_damage_requirement["guixin"] = function(self, source, target)
	if target:hasSkill("guixin") then
		if self.room:alivePlayerCount() > 3 then
			local count = 0
			local others = self.room:getOtherPlayers(target)
			for _,p in sgs.qlist(others) do
				local cards = p:getCards("hej")
				if cards:length() > 0 then
					count = count + 1
				end
			end
			if self:isLihunTarget(target, count) then
				return false
			end
			return true
		end
	end
	return false
end
--[[
	技能：飞影（锁定技）
	描述：其他角色与你的距离+1 
]]--
--[[****************************************************************
	武将：神·吕布（神）
]]--****************************************************************
--[[
	技能：狂暴（锁定技）
	描述：游戏开始时，你获得两枚“暴怒”标记。每当你造成或受到1点伤害后，你获得一枚“暴怒”标记。 
]]--
--[[
	技能：无谋（锁定技）
	描述：每当你使用一张非延时类锦囊牌选择目标后，你选择一项：失去1点体力，或弃一枚“暴怒”标记。 
]]--
sgs.ai_skill_choice["wumou"] = function(self, choices)
	if self.player:getMark("@wrath") > 6 then 
		return "discard" 
	end
	if self.player:getHp() + self:getCardsNum("Peach") > 3 then 
		return "losehp"
	else 
		return "discard"
	end
end
--[[
	技能：无前
	描述：出牌阶段，你可以弃两枚“暴怒”标记并选择一名其他角色，该角色的防具无效且你获得技能“无双”，直到回合结束。 
]]--
--[[
	内容：“无前技能卡”的卡牌成分
]]--
sgs.card_constituent["WuqianCard"] = {
	use_value = 5,
	use_priority = 2.5,
}
--[[
	内容：“无前技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["WuqianCard"] = 80
--[[
	内容：注册“无前技能卡”
]]--
sgs.RegistCard("WuqianCard")
--[[
	内容：“无前”技能信息
]]--
sgs.ai_skills["wuqian"] = {
	name = "wuqian",
	dummyCard = function(self)
		local card_str = "@WuqianCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if self.player:getMark("@wrath") >= 2 then
			return true
		end
		return false
	end
}
--[[
	内容：“无前技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["WuqianCard"] = function(self, card, use)
	if self.player:hasUsed("WuqianCard") then
		return 
	end
	self:sort(self.opponents, "hp")
	local has_enemy = nil
	for _, enemy in ipairs(self.opponents) do
		if enemy:getHp() <= 2 then
			if sgs.getCardsNum("Jink", enemy) < 2 then
				if enemy:getHandcardNum() > 0 then
					if self.player:distanceTo(enemy) <= self.player:getAttackRange() then 
						has_enemy = enemy 
						break 
					end
				end
			end
		end
	end
	if has_enemy then
		local card_str = "@WuqianCard=."
		local acard = nil
		if self:getCardsNum("Slash") > 0 then
			local handcards = self.player:getHandcards()
			for _,c in sgs.qlist(handcards) do
				if c:isKindOf("Slash") then
					if self:slashIsEffective(c, has_enemy) then
						if self.player:canSlash(has_enemy, c) then
							if c:isAvailable(self.player) then
								if self:getCardsNum("Analeptic") > 0 then
									acard = sgs.Card_Parse(card_str)
								elseif has_enemy:getHp() <= 1 then
									acard = sgs.Card_Parse(card_str)
								end
							end
						end
					end
				elseif c:isKindOf("Duel") then
					acard = sgs.Card_Parse(card_str)
				end
			end
		end
		if acard then
			self:sort(self.opponents, "hp")
			for _,enemy in ipairs(self.opponents) do
				if enemy:getHp() <= 2 then
					if sgs.getCardsNum("Jink", enemy) < 2 then
						if self.player:inMyAttackRange(enemy) then
							local can_use = false
							if enemy:hasArmorEffect("SilverLion") then
								can_use = true
							elseif sgs.getCardsNum("Jink", enemy) > 0 then
								can_use = true
							end
							if can_use then
								use.card = acard
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
end
--[[
	套路：仅使用“无前技能卡”
]]--
sgs.ai_series["WuqianCardOnly"] = {
	name = "WuqianCardOnly",
	IQ = 2,
	value = 2,
	priority = 4,
	skills = "wuqian",
	cards = {
		["WuqianCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local wuqian_skill = sgs.ai_skills["wuqian"]
		local dummyCard = wuqian_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["WuqianCard"], "WuqianCardOnly")
--[[
	技能：神愤
	描述：出牌阶段限一次，你可以弃六枚“暴怒”标记并选择所有其他角色，对这些角色各造成1点伤害，然后这些角色先各弃置其装备区里的所有牌，再各弃置四张手牌，最后你将你的武将牌翻面。 
]]--
--[[
	内容：“神愤技能卡”的卡牌成分
]]--
sgs.card_constituent["ShenfenCard"] = {
	damage = 4,
	control = 3,
	use_value = 8,
	use_priority = 9.3,
}
--[[
	内容：“神愤技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["ShenfenCard"] = function(self, card, source, targets)
	 sgs.shenfensource = nil
end
--[[
	内容：注册“神愤技能卡”
]]--
sgs.RegistCard("ShenfenCard")
--[[
	内容：“神愤”技能信息
]]--
sgs.ai_skills["shenfen"] = {
	name = "shenfen",
	dummyCard = function(self)
		local card_str = "@ShenfenCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if self.player:getMark("@wrath") >= 6 then
			if not self.player:hasUsed("ShenfenCard") then
				return true
			end
		end
		return false
	end
}
--[[
	内容：“神愤技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["ShenfenCard"] = function(self, card, use)
	local good = ( #self.opponents - #self.partners_noself ) * 1.5
	local nextAlive = self.player:getNextAlive()
	if self:isOpponent(nextAlive) then
		if self.player:getHp() > 2 then 
			good = good - 0.5 
		end
	end
	if self:amRebel() then 
		good = good + 1 
	elseif self:amRenegade() then 
		good = good + 0.5 
	end
	if not self.player:faceUp() then 
		good = good + 1 
	end	
	if self:hasSkills("jushou|neojushou|lihun|kuiwei|jiushi") then 
		good = good + 1 
	end
	local weapon = self.player:getWeapon()
	if weapon and weapon:isKindOf("Crossbow") then
		if self:getCardsNum("Slash", self.player) > 1 then 
			good = good + 1 
		end
	end
	local others = self.room:getOtherPlayers(self.player)
	for _, p in sgs.qlist(others) do
		--good = good + self:dangerousshenguanyu(p)
		if p:hasSkill("dushi") then
			if p:getHp() < 2 then 
				good = good - 1 
			end
		end
	end
	for _,friend in ipairs(self.partners_noself) do
		if self:hasSkills("fangzhu|jilve", friend) then
			if friend:getHp() > 1 then
				good = good + friend:getLostHp() * 0.25 + 0.5
				break
			end
		end
	end
	for _, friend in ipairs(self.partners_noself) do
		if friend:hasSkill("jujian") then
			good = good + 0.5
			break
		end
	end
	if self:amRenegade() then
		local lord = self.room:getLord()
		if lord then
			if not self:isPartner(lord) then
				if lord:getHp() == 1 then
					if self:damageIsEffective(lord) then
						if self:getCardsNum("Peach") == 0 then
							return 
						end
					end
				end
			end
		end
	end
	local friends_ZDL, enemies_ZDL = 0, 0
	for _,friend in ipairs(self.partners_noself) do
		friends_ZDL = friends_ZDL + friend:getCardCount(true) + friend:getHp()
		if friend:getHandcardNum() > 4 then 
			good = good + friend:getHandcardNum() * 0.25 
		end
		--good = good + self:cansaveplayer(friend)
		if friend:hasArmorEffect("SilverLion") then
			if friend:getHp() > 1 then 
				good = good + 0.5 
			end
		end
		if self:damageIsEffective(friend) then
			if friend:getHp() == 1 and self:getAllPeachNum() < 1 then
				if self:mayLord(friend) then
					good = good - 100 
				elseif sgs.current_mode ~= "06_3v3" then
					if self:amLord() and self:mayLoyalist(friend) then
						good = good - 0.6 + (self.player:getCardCount(true) * 0.3)
					end
				end
			else
				good = good - 1
			end
			if self:mayLord(friend) then
				good = good - 0.5
			end
		elseif not self:damageIsEffective(friend) then
			good = good + 1
		end
		if friend:hasSkill("guixin") then
			if friend:getHp() > 1 then 
				good = good + 1 
			end
		end
	end	
	for _,enemy in ipairs(self.opponents) do
		enemies_ZDL = enemies_ZDL + enemy:getCardCount(true) + enemy:getHp()
		if enemy:getHandcardNum() > 4 then 
			good = good - enemy:getHandcardNum() * 0.25 
		end
		--good = good - self:cansaveplayer(enemy)
		if self:damageIsEffective(enemy) then
			if self:mayLord(enemy) and self:amRebel() then
				good = good + 1
			end
			if enemy:getHp() == 1 then
				if self:mayLord(enemy) and self:amRebel() then
					good = good + 3
				elseif not self:amLord() then
					good = good + 1 
				end
			end
			if enemy:getHp() > 1 then
				if enemy:hasSkill("guixin") then 
					good = good - self.player:aliveCount() * 0.2 
				end
				if enemy:hasSkill("ganglie") then 
					good = good - 1 
				end
				if enemy:hasSkill("xuehen") then 
					good = good - 1 
				end
				if enemy:hasArmorEffect("SilverLion") then 
					good = good - 0.5 
				end
			end
		else    
			good = good - 1
		end
	end
	if #self.partners_noself > 0 then
		friends_ZDL = friends_ZDL / #self.friends_noself
	else
		friends_ZDL = 0
	end
	if #self.opponents > 0 then
		enemies_ZDL = enemies_ZDL / #self.opponents
	else
		enemies_ZDL = 0
	end
	local Combat_Effectiveness = (friends_ZDL - enemies_ZDL) / 2
	good = good - Combat_Effectiveness
	if good > 0 then 
		sgs.shenfensource = self.player
		use.card = card		
	end	
end
local shenfen_filter = function(player, carduse)
	if carduse.card:isKindOf("ShenfenCard") then
		sgs.shenfensource = player
	end
end
table.insert(sgs.ai_choicemade_filter.cardUsed, shenfen_filter)
--[[
	套路：仅使用“神愤技能卡”
]]--
sgs.ai_series["ShenfenCardOnly"] = {
	name = "ShenfenCardOnly",
	IQ = 2,
	value = 5,
	priority = 2,
	skills = "shenfen",
	cards = {
		["ShenfenCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local shenfen_skill = sgs.ai_skills["shenfen"]
		local dummyCard = shenfen_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["ShenfenCard"], "ShenfenCardOnly")
--[[****************************************************************
	武将：神·赵云（神）
]]--****************************************************************
--[[
	技能：绝境（锁定技）
	描述：摸牌阶段，你额外摸X张牌。你的手牌上限+2。（X为你已损失的体力值） 
]]--
sgs.draw_cards_system["juejing"] = {
	name = "juejing",
	correct_func = function(self, player)
		local lost = player:getLostHp()
		return lost
	end,
}
--[[
	技能：龙魂
	描述：你可以将X张同花色的牌按以下规则使用或打出：♥当【桃】；♦当火【杀】；♠当【无懈可击】；♣当【闪】。（X为你的当前体力值且至少为1） 
]]--
--[[
	内容：注册“龙魂桃”、“龙魂火杀”
]]--
sgs.RegistCard("longhun>>Peach")
sgs.RegistCard("longhun>>FireSlash")
--[[
	内容：“龙魂”技能信息
]]--
sgs.ai_skills["longhun"] = {
	name = "longhun",
	dummyCard = function(self)
		if sgs.Ask_Peach then
			local point = sgs.peach:getNumberString()
			local id = sgs.peach:getId()
			local card_str = ("peach:longhun[heart:%s]=%d"):format(point, id)
			return sgs.Card_Parse(card_str)
		else
			local point = sgs.fire_slash:getNumberString()
			local id = sgs.fire_slash:getId()
			local card_str = ("fire_slash:longhun[diamond:%s]=%d"):format(point, id)
			return sgs.Card_Parse(card_str)
		end
	end,
	enabled = function(self, handcards)
		return not self.player:isNude()
	end
}
--[[
	内容：“龙魂火杀”、“龙魂桃”的具体产生方式
]]--
sgs.ai_view_as_func["longhun>>FireSlash"] = function(self, card)
	if sgs.slash:isAvailable(self.player) then
		local cards = self.player:getCards("he")
		local flag = self.player:canSlashWithoutCrossbow()
		local weapon = self.player:getWeapon()
		local diamonds = {}
		for _,diamond in sgs.qlist(cards) do
			if diamond:getSuit() == sgs.Card_Diamond then
				local id = diamond:getEffectiveId()
				local can_use = true
				if weapon then
					if weapon:isKindOf("Crossbow") then
						if id == weapon:getId() then
							can_use = flag
						end
					end
				end
				if can_use then
					table.insert(diamonds, diamond)
				end
			end
		end
		local hp = self.player:getHp() 
		hp = math.max(hp, 1)
		if #diamonds >= hp then
			self:sortByUseValue(diamonds, true)
			local to_use = {}
			for index, diamond in ipairs(diamonds) do
				if index <= hp then
					table.insert(to_use, diamond:getEffectiveId())
				else
					break
				end
			end
			local card_str = nil
			if #to_use > 0 then
				local point = to_use[1]:getNumber()
				local ids = table.concat(to_use, "+")
				card_str = string.format("fire_slash:longhun[diamond:%s]=%s", point, ids)
				return sgs.Card_Parse(card_str)
			end
		end
	end
end
sgs.ai_view_as_func["longhun>>Peach"] = function(self, card)
	if self.player:getHp() <= 1 then
		if self:amLord() or self:amRenegade() then
			local hearts = {}
			local cards = self.player:getCards("he")
			for _,heart in sgs.qlist(cards) do
				if heart:getSuit() == sgs.Card_Heart then
					table.insert(hearts, heart)
				end
			end
			if #hearts > 0 then
				self:sortByUseValue(hearts, true)
				local heart = hearts[1]
				local point = heart:getNumber()
				local id = heart:getEffectiveId()
				local card_str = string.format("peach:longhun[heart:%s]=%d", point, id)
				return sgs.Card_Parse(card_str)
			end
		end
	end
end
--[[
	内容：“龙魂”响应方式
	需求：杀、闪、桃、无懈可击
]]--
sgs.ai_view_as["longhun"] = function(card, player, place)
	if player:getHp() <= 1 then
		if place ~= sgs.Player_PlaceSpecial then 
			local suit_str = card:getSuitString()
			local number = card:getNumberString()
			local card_id = card:getEffectiveId()
			local suit = card:getSuit()
			if suit == sgs.Card_Diamond then
				return ("fire_slash:longhun[%s:%s]=%d"):format(suit_str, number, card_id)
			elseif suit == sgs.Card_Club then
				return ("jink:longhun[%s:%s]=%d"):format(suit_str, number, card_id)
			elseif suit == sgs.Card_Heart then
				if not player:hasFlag("Global_PreventPeach") then
					return ("peach:longhun[%s:%s]=%d"):format(suit_str, number, card_id)
				end
			elseif suit == sgs.Card_Spade then
				return ("nullification:longhun[%s:%s]=%d"):format(suit_str, number, card_id)
			end
		end
	end
end
--[[
	内容：“龙魂”卡牌需求
]]--
sgs.card_need_system["longhun"] = function(self, card, player)
	local cards = player:getCards("he")
	if cards:length() <= 2 then
		return true
	else
		local suit = card:getSuit()
		if suit == sgs.Card_Heart then
			return true
		elseif suit == sgs.Card_Diamond then
			return true
		end
	end
	return false
end
--[[
	内容：“龙魂”统计信息
]]--
sgs.card_count_system["longhun_slash"] = {
	name = "longhun_slash",
	pattern = "Slash",
	ratio = 0.5,
	statistics_func = function(class_name, player, data)
		if player:hasSkill("longhun") then
			local count = data["count"]
			count = count + data["diamond"] 
			count = count + data["unknown"] * 0.5
			return count
		end
	end
}
sgs.card_count_system["longhun_jink"] = {
	name = "longhun_jink",
	pattern = "Jink",
	ratio = 0.65,
	statistics_func = function(class_name, player, data)
		if player:hasSkill("longhun") then
			local count = data["count"]
			count = count + data["club"] 
			count = count + data["unknown"] * 0.65
			return count
		end
	end
}
sgs.card_count_system["longhun_peach"] = {
	name = "longhun_peach",
	pattern = "Jink",
	ratio = 0.65,
	statistics_func = function(class_name, player, data)
		if player:hasSkill("longhun") then
			local count = data["count"]
			count = count + data["heart"] 
			count = count + data["unknown"] * 0.65
			return count
		end
	end
}
sgs.card_count_system["longhun_nullification"] = {
	name = "longhun_nullification",
	pattern = "Nullification",
	ratio = 0.5,
	statistics_func = function(class_name, player, data)
		if player:hasSkill("longhun") then
			local count = data["count"]
			count = count + data["spade"] 
			count = count + data["unknown"] * 0.5
			return count
		end
	end
}
--[[
	内容：“龙魂”最优体力
]]--
sgs.best_hp_system["longhun"] = {
	name = "longhun",
	reason = "longhun",
	best_hp = function(player, maxhp)
		local cards = player:getCards("he")
		if cards:length() > 2 then
			return 1
		end
	end,
}
--[[****************************************************************
	武将：神·司马懿（神）
]]--****************************************************************
--[[
	技能：忍戒（锁定技）
	描述：每当你受到一次伤害后，你获得等同于你受到的伤害数量的“忍”标记；每当你于弃牌阶段内因你的弃置而失去手牌时，你获得等同于你失去的手牌数量的“忍”标记。 
]]--
--[[
	技能：拜印（觉醒技）
	描述：准备阶段开始时，若你拥有4枚或更多的“忍”标记，你减1点体力上限，然后获得技能“极略”（每当一名角色的判定牌生效前，若你有手牌，你可以弃1枚“忍”标记发动“鬼才”；每当你受到一次伤害后，你可以弃1枚“忍”标记，发动“放逐”；每当你使用锦囊牌选择目标后，你可以弃1枚“忍”标记，发动“集智”；出牌阶段限一次，若你有牌，你可以弃1枚“忍”标记，发动“制衡”；出牌阶段，你可以弃1枚“忍”标记，执行“完杀”的效果，直到回合结束。） 
]]--
--[[
	内容：“拜印”最优体力
]]--
sgs.best_hp_system["baiyin"] = {
	name = "baiyin",
	reason = "renjie+baiyin",
	best_hp = function(player, maxhp, isLord)
		if player:hasSkill("renjie") then
			if player:getMark("baiyin") == 0 then
				return maxhp - 1
			end
		end
	end,
}
--[[
	技能：连破
	描述：一名角色的回合结束后，若你于此回合内杀死了至少一名角色，你可以获得一个额外的回合。 
]]--
sgs.ai_skill_invoke["lianpo"] = true
--[[
	技能：极略
	描述：每当一名角色的判定牌生效前，若你有手牌，你可以弃1枚“忍”标记发动“鬼才”；每当你受到一次伤害后，你可以弃1枚“忍”标记，发动“放逐”；每当你使用锦囊牌选择目标后，你可以弃1枚“忍”标记，发动“集智”；出牌阶段限一次，若你有牌，你可以弃1枚“忍”标记，发动“制衡”；出牌阶段，你可以弃1枚“忍”标记，执行“完杀”的效果，直到回合结束。
]]--
--[[
	内容：“极略技能卡”的卡牌成分
]]--
sgs.card_constituent["JilveCard"] = {
	use_priority = 0,
}
--[[
	内容：注册“极略技能卡”
]]--
sgs.RegistCard("JilveCard")
--[[
	内容：“极略”技能信息
]]--
sgs.ai_skills["jilve"] = {
	name = "jilve",
	dummyCard = function(self)
		return sgs.Card_Parse("@JilveCard=.")
	end,
	enabled = function(self, handcards)
		if self.player:getMark("@bear") > 0 then
			if self.player:hasFlag("JilveWansha") then
				if self.player:hasFlag("JilveZhiheng") then
					return false
				end
			end
			return true
		end
		return false
	end,
}
--[[
	内容：“极略技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["JilveCard"] = function(self, card, use)
	local hasWansha = false
	if self.player:hasSkill("wansha") then
		hasWansha = true
	elseif self.player:hasFlag("JilveWansha") then
		hasWansha = true
	end
	if not hasWansha then
		if self.player:getMark("bear") >= 5 then
			sgs.ai_skill_choice["jilve"] = "wansha"
			-- local wansha_card = sgs.Card_Parse("@JilveCard=.")
			-- dummy_use = {
				-- isDummy = true, 
			-- }
			-- self:useSkillCard(wansha_card, dummy_use)
			use.card = card
			return 
		end
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		local slashes = self:getCards("Slash")
		self:sort(self.opponents, "hp")
		if #self.opponents > 1 then
			for _, enemy in ipairs(self.opponents) do
				if self:isWeak(enemy) then
					--if self:damageMinusHp(self, enemy, 1) > 0 then
						local isKongcheng = false
						if enemy:hasSkill("kongcheng") then
							if enemy:isKongcheng() then
								isKongcheng = true
							end
						end
						if not isKongcheng then
							sgs.ai_skill_choice["jilve"] = "wansha"
							-- local wansha_card = sgs.Card_Parse("@JilveCard=.")
							-- dummy_use = {
								-- isDummy = true,
							-- }
							-- self:useSkillCard(wansha_card, dummy_use)
							use.card = card
							return 
						end
					--end
				end
			end
		end
	end
	local hasZhiheng = false
	if self.player:hasSkill("zhiheng") then
		hasZhiheng = true
	elseif self.player:hasFlag("JilveZhiheng") then
		hasZhiheng = true
	end
	if not hasZhiheng then
		sgs.ai_skill_choice["jilve"] = "zhiheng"
		local zhiheng_card = sgs.Card_Parse("@ZhihengCard=.")
		local dummy_use = {
			isDummy = true,
		}
		self:useSkillCard(zhiheng_card, dummy_use)
		if dummy_use.card then 
			use.card = card
			return 
		end
	elseif not hasWansha then
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		local slashes = self:getCards("Slash")
		self:sort(self.opponents, "hp")
		if #self.opponents > 1 then
			for _, enemy in ipairs(self.opponents) do
				if self:isWeak(enemy) then
					--if self:damageMinusHp(self, enemy, 1) > 0 then
						local isKongcheng = false
						if enemy:hasSkill("kongcheng") then
							if enemy:isKongcheng() then
								isKongcheng = true
							end
						end
						if not isKongcheng then
							sgs.ai_skill_choice["jilve"] = "wansha"
							local wansha_card = sgs.Card_Parse("@JilveCard=.")
							dummy_use = {
								isDummy = true,
							}
							--self:useSkillCard(wansha_card, dummy_use)
							use.card = card
							return 
						end
					--end
				end
			end
		end
	end
end
sgs.ai_skill_invoke["jilve_jizhi"] = function(self, data)
	local n = self.player:getMark("@bear")
	local use = ( n > 2 or self:getOverflow() > 0 )
	local card = data:toCardResponse().m_card
	card = card or data:toCardUse().card
	return use or card:isKindOf("ExNihilo")
end
sgs.ai_skill_invoke["jilve_guicai"] = function(self, data)
	local n = self.player:getMark("@bear")
	local use = ( n>2 or self:getOverflow()>0 )
	local judge = data:toJudge()
	if self:needRetrial(judge) then 
		use = use or ( judge.who:objectName() == self.player:objectName() )
		use = use or ( judge.reason == "lightning" )
		if use then
			local handcards = self.player:getHandcards()
			local cards = sgs.QList2Table(handcards)
			local id = self:getRetrialCardId(cards, judge)
			return id ~= -1
		end
	end
	return false
end
sgs.ai_skill_invoke["jilve_fangzhu"] = function(self, data)
	local others = self.room:getOtherPlayers(self.player)
	local callback = sgs.ai_skill_playerchosen["fangzhu"]
	if type(callback) == "function" then
		if callback(self, others) then
			return true
		end
	end
	return false
end
sgs.ai_skill_use["@zhiheng"] = function(self, prompt)
	local card = sgs.Card_Parse("@ZhihengCard=.")
	local dummy_use = {
		isDummy = true,
	}
	self:useSkillCard(card, dummy_use)
	if dummy_use.card then 
		return (dummy_use.card):toString() .. "->." 
	end
	return "."
end
sgs.ai_wizard_system["jilve"] = {
	name = "jilve",
	skill = "jilve",
	retrial_enabled = function(self, source, target)
		if source:hasSkill("jilve") then
			if not source:isKongcheng() then
				if source:getMark("@bear") > 0 then
					return true
				end
			end
		end
		return false
	end,
}
--[[
	套路：仅使用“极略技能卡”
]]--
sgs.ai_series["JilveCardOnly"] = {
	name = "JilveCardOnly",
	IQ = 2,
	value = 3,
	priority = 3,
	skills = "jilve",
	cards = {
		["JilveCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local jilve_skill = sgs.ai_skills["jilve"]
		local dummyCard = jilve_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["JilveCard"], "JilveCardOnly")