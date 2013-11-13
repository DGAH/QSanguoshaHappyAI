--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）智扩展包部分
]]--
--[[****************************************************************
	武将：智·许攸（魏）
]]--****************************************************************
--[[
	技能：倨傲
	描述：出牌阶段限一次，你可以将两张手牌背面向上移出游戏并选择一名角色，该角色的下个回合开始阶段开始时，须获得你移出游戏的两张牌并跳过摸牌阶段。 
]]--
--[[
	内容：注册“倨傲技能卡”
]]--
sgs.RegistCard("JuaoCard")
--[[
	内容：“倨傲”技能信息
]]--
sgs.ai_skills["juao"] = {
	name = "juao",
	dummyCard = function(self)
		return sgs.Card_Parse("@JuaoCard=.")
	end,
	enabled = function(self, handcards)
		if self.player:hasUsed("JuaoCard") then
			return false
		elseif self.player:getHandcardNum() < 2 then
			return false
		end
		return true
	end,
}
--[[
	内容：“倨傲技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["JuaoCard"] = function(self, card, use)
	if self:needBear() then 
		return 
	end
	local givecard = {}
	local cards = self.player:getHandcards()
	for _, friend in ipairs(self.partners_noself) do
		if friend:getHp() == 1 then --队友快死了
			for _, hcard in sgs.qlist(cards) do
				if sgs.isKindOf("Analeptic|Peach", hcard) then
					table.insert(givecard, hcard:getId())
				end
				if #givecard == 1 and givecard[1] ~= hcard:getId() then
					table.insert(givecard, hcard:getId())
				elseif #givecard == 2 then
					local card_str = "@JuaoCard=" .. table.concat(givecard, "+")
					use.card = sgs.Card_Parse(card_str)
					if use.to then 
						use.to:append(friend) 
						self:speak("顶住，你的快递马上就到了。")
					end
					return
				end
			end
		end
		if self:hasSkills("nosjizhi", friend) then --队友有集智
			for _, hcard in sgs.qlist(cards) do
				if hcard:isNDTrick() then
					table.insert(givecard, hcard:getId())
				end
				if #givecard == 1 and givecard[1] ~= hcard:getId() then
					table.insert(givecard, hcard:getId())
				elseif #givecard == 2 then
					local card_str = "@JuaoCard=" .. table.concat(givecard, "+")
					use.card = sgs.Card_Parse(card_str)
					if use.to then 
						use.to:append(friend) 
					end
					return
				end
			end
		end
		if friend:hasSkill("jizhi") then --队友有集智
			for _, hcard in sgs.qlist(cards) do
				if hcard:isKindOf("TrickCard") then
					table.insert(givecard, hcard:getId())
				end
				if #givecard == 1 and givecard[1] ~= hcard:getId() then
					table.insert(givecard, hcard:getId())
				elseif #givecard == 2 then
					local card_str = "@JuaoCard=" .. table.concat(givecard, "+")
					use.card = sgs.Card_Parse(card_str)
					if use.to then 
						use.to:append(friend) 
					end
					return
				end
			end
		end
		if friend:hasSkill("leiji") then --队友有雷击
			for _, hcard in sgs.qlist(cards) do
				if hcard:getSuit() == sgs.Card_Spade or hcard:isKindOf("Jink") then
					table.insert(givecard, hcard:getId())
				end
				if #givecard == 1 and givecard[1] ~= hcard:getId() then
					table.insert(givecard, hcard:getId())
				elseif #givecard == 2 then
					local card_str = "@JuaoCard=" .. table.concat(givecard, "+")
					use.card = sgs.Card_Parse(card_str)
					if use.to then 
						use.to:append(friend) 
						self:speak("我知道你有什么牌，哼哼。")
					end
					return
				end
			end
		end
		if friend:hasSkill("xiaoji") or friend:hasSkill("xuanfeng") then --队友有枭姬（旋风）
			for _, hcard in sgs.qlist(cards) do
				if hcard:isKindOf("EquipCard") then
					table.insert(givecard, hcard:getId())
				end
				if #givecard == 1 and givecard[1] ~= hcard:getId() then
					table.insert(givecard, hcard:getId())
				elseif #givecard == 2 then
					local card_str = "@JuaoCard=" .. table.concat(givecard, "+")
					use.card = sgs.Card_Parse(card_str)
					if use.to then 
						use.to:append(friend) 
					end
					return
				end
			end
		end
	end
	givecard = {}
	for _, enemy in ipairs(self.opponents) do
		if enemy:getHp() == 1 then --敌人快死了
			for _, hcard in sgs.qlist(cards) do
				if hcard:isKindOf("Disaster") then
					table.insert(givecard, hcard:getId())
				end
				if #givecard == 1 and givecard[1] ~= hcard:getId() then
					if not sgs.isKindOf("Peach|TrickCard", hcard) then
						table.insert(givecard, hcard:getId())
						local card_str = "@JuaoCard=" .. table.concat(givecard, "+")
						use.card = sgs.Card_Parse(card_str)
						if use.to then 
							use.to:append(enemy) 
							self:speak("咱最擅长落井下石了。")
						end
						return
					end
				elseif #givecard == 2 then
					local card_str = "@JuaoCard=" .. table.concat(givecard, "+")
					use.card = sgs.Card_Parse(card_str)
					if use.to then 
						use.to:append(enemy) 
						self:speak("咱最擅长落井下石了。")
					end
					return
				end
			end
		end
		if enemy:hasSkill("yongsi") then --敌人有庸肆
			local players = self.room:getAlivePlayers()
			local extra = sgs.getKingdomsCount(players) --额外摸牌的数目
			if enemy:getCardCount(true) <= extra then --如果敌人快裸奔了
				for _,hcard in sgs.qlist(cards) do
					if hcard:isKindOf("Disaster") then
						table.insert(givecard, hcard:getId())
					end
					if #givecard == 1 and givecard[1] ~= hcard:getId() then
						if not sgs.isKindOf("Peach|ExNihilo", hcard) then
							table.insert(givecard, hcard:getId())
							local card_str = "@JuaoCard="..table.concat(givecard, "+")
							use.card = sgs.Card_Parse(card_str)
							if use.to then
								use.to:append(enemy)
							end
							return 
						end
					end
					if #givecard == 2 then
						local card_str = "@JuaoCard="..table.concat(givecard, "+")
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
	if #givecard < 2 then
		for _, hcard in sgs.qlist(cards) do
			if hcard:isKindOf("Disaster") then
				table.insert(givecard, hcard:getId())
			end
			if #givecard == 2 then
				local card_str = "@JuaoCard=" .. table.concat(givecard, "+")
				use.card = sgs.Card_Parse(card_str)
				if use.to then 
					use.to:append(self.opponents[1]) 
				end
				return
			end
		end
	end
end
--[[
	套路：仅使用“倨傲技能卡”
]]--
sgs.ai_series["JuaoCardOnly"] = {
	name = "JuaoCardOnly",
	IQ = 2,
	value = 1,
	priority = 2,
	skills = "juao",
	cards = {
		["JuaoCard"] = 1,
		["Others"] = 2,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local juao_skill = sgs.ai_skills["juao"]
		local dummyCard = juao_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["JuaoCard"], "JuaoCardOnly")
--[[
	技能：贪婪
	描述：每当你受到其他角色造成的一次伤害后，可与伤害来源拼点：若你赢，你获得双方的拼点牌。 
]]--
sgs.ai_skill_invoke["tanlan"] = function(self, data)
	local damage = data:toDamage()
	local source = damage.from
	local my_max_card = self:getMaxPointCard()
	if my_max_card then
		local my_max_point = my_max_card:getNumber()
		local from_num = source:getHandcardNum()
		if my_max_point > 10 then
			if self:isPartner(source) then
				if from_num == 1 then
					if self:needKongcheng(source) then 
						return true 
					end
				end
				if self:getOverflow(source) > 2 then 
					return true 
				end
				if not self:hasLoseHandcardEffective(source) then 
					return true 
				end
				return false
			end
			return true
		end
		local hp = self.player:getHp()
		local num = self.player:getHandcardNum()
		if hp > 2 then
			if num > 2 then
				if my_max_point > 4 then
					return true
				end
			end
		end
		if hp > 1 then
			if num > 1 then
				if my_max_point > 7 then
					return true
				end
			end
		end
		if from_num <= 2 then
			if my_max_point > 2 then
				return true
			end
		end
		if from_num == 1 then
			if self:hasLoseHandcardEffective(source) then
				if not self:needKongcheng(source) then
					return true
				end
			end
		end
		if self:getOverflow() > 2 then
			return true
		end
	end
	return false
end
sgs.ai_skill_pindian["tanlan"] = function(self, requestor, maxcard, mincard)
	local my_max_card = self:getMaxPointCard()	
	if self:isPartner(requestor) then
		return mincard --minusecard
	elseif my_max_card:getNumber() < 6 then
		return mincard --minusecard
	else
		return my_max_card
	end
end
sgs.ai_choicemade_filter.skillInvoke["tanlan"] = function(player, promptlist, self)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from and promptlist[3] == "yes" then
		local target = damage.from
		local intention = 10
		if target:getHandcardNum() == 1 then
			if self:needKongcheng(target) then 
				intention = 0 
			end
		end
		if intention ~= 0 then
			if self:getOverflow(target) > 2 then 
				intention = 0 
			elseif not self:hasLoseHandcardEffective(target) then 
				intention = 0 
			end
		end
		sgs.updateIntention(player, target, intention)
	end
end
--[[
	内容：“贪婪”卡牌需求
]]--
sgs.card_need_system["tanlan"] = sgs.card_need_system["bignumber"]
--[[
	技能：恃才（锁定技）
	描述：若你向其他角色发起拼点且你拼点赢时，或其他角色向你发起拼点且拼点没赢时，你摸一张牌 
]]--
--[[****************************************************************
	武将：智·姜维（蜀）
]]--****************************************************************
--[[
	技能：异才
	描述：每当你使用一张非延时类锦囊时，你可以使用一张【杀】。 
]]--
sgs.ai_skill_invoke["yicai"] = function(self, data)
	if self:needBear() then 
		return false 
	end
	for _,enemy in ipairs(self.opponents) do
		if self.player:canSlash(enemy, nil, true) then
			if self:getCardsNum("Slash") > 0 then 
				return true 
			end
		end
	end
	return false
end
--[[
	技能：北伐（锁定技）
	描述：当你失去最后的手牌时，视为你对一名其他角色使用了一张【杀】，若不能如此做，则视为你对自己使用了一张【杀】。 
]]--
sgs.ai_skill_playerchosen["beifa"] = function(self, targets)
	local targetlist = {}
	for _,p in sgs.qlist(targets) do
		if self:willUseSlash(sgs.slash, p) then
			table.insert(targetlist, p)
		end
	end
	self:sort(targetlist, "defenseSlash")
	for _, target in ipairs(targetlist) do
		if self:isOpponent(target) then
			if self:slashIsEffective(sgs.slash, target) then
				if sgs.isGoodTarget(self, target, targetlist) then
					self:speak("嘿！没想到吧？")
					return target
				end
			end
		end
	end
	for i=#targetlist, 1, -1 do
		if sgs.isGoodTarget(self, targetlist[i], targetlist) then
			return targetlist[i]
		end
	end
	return targetlist[#targetlist]
end
--[[****************************************************************
	武将：智·蒋琬（蜀）
]]--****************************************************************
sgs.ai_chaofeng.wis_jiangwan = 6
--[[
	技能：后援
	描述：出牌阶段限一次，你可以弃置两张手牌并令一名其他角色摸两张牌。 
]]--
--[[
	内容：注册“后援技能卡”
]]--
sgs.RegistCard("HouyuanCard")
--[[
	内容：“后援”技能信息
]]--
sgs.ai_skills["houyuan"] = {
	name = "houyuan",
	dummyCard = function(self)
		return sgs.Card_Parse("@HouyuanCard=.")
	end,
	enabled = function(self, handcards)
		if #handcards > 1 then
			if not self.player:hasUsed("HouyuanCard") then
				return true
			end
		end
		return false
	end,
}
--[[
	内容：“后援技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["HouyuanCard"] = function(self, card, use)
	if self:needBear() then 
		return 
	elseif #self.partners == 1 then 
		return 
	end
	local target = self:findPlayerToDraw(false, 2)
	if target then
		local cards = self.player:getCards("h")
		cards = sgs.QList2Table(cards)
		self:sortByUseValue(cards, true)
		if not cards[1]:isKindOf("ExNihilo") then
			local usecards = {
				cards[1]:getId(), 
				cards[2]:getId(),
			}
			local card_str = "@HouyuanCard=" .. table.concat(usecards, "+")
			use.card = sgs.Card_Parse(card_str)
			if use.to then
				use.to:append(target)
				self:speak("有你这样出远门不带粮食的么？接好了！")
			end
		end
	end
end
--[[
	套路：仅使用“后援技能卡”
]]--
sgs.ai_series["HouyuanCardOnly"] = {
	name = "HouyuanCardOnly",
	IQ = 2,
	value = 3,
	priority = 3,
	skills = "houyuan",
	cards = {
		["HouyuanCard"] = 1,
		["Others"] = 2,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local houyuan_skill = sgs.ai_skills["houyuan"]
		local dummyCard = houyuan_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["HouyuanCard"], "HouyuanCardOnly")
--[[
	技能：筹粮
	描述：回合结束阶段开始时，若你手牌少于三张，你可以从牌堆顶亮出4-X张牌（X为你的手牌数），你获得其中的基本牌，将其余的牌置入弃牌堆。 
]]--
--[[****************************************************************
	武将：智·孙策（吴）
]]--****************************************************************
sgs.ai_chaofeng.wis_sunce = 1
--[[
	技能：霸王
	描述：每当你使用的【杀】被【闪】抵消时，你可以与目标角色拼点：若你赢，可以视为你对至多两名角色各使用了一张【杀】（此杀不计入每阶段的使用限制）。 
]]--
--[[
	内容：“霸王技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["BawangCard"] = sgs.ai_card_intention["ShensuCard"]
sgs.ai_skill_invoke["bawang"] = function(self, data)
	local effect = data:toSlashEffect()
	local target = effect.to
	if self:isOpponent(target) then
		if self:getOverflow() > 0 then 
			return true 
		end
		local my_max_card = self:getMaxPointCard()
		if my_max_card then
			return my_max_card:getNumber() > 10 
		end
	end
	return false
end
sgs.ai_skill_pindian["bawang"] = function(self, requestor, maxcard, mincard)
	local handcards = self.player:getHandcards()
	local cards = sgs.QList2Table(handcards)
	local function compare_func(a, b)
		return a:getNumber() > b:getNumber()
	end
	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if card:getNumber() > 10 then 
			return card 
		end
	end
	self:sortByKeepValue(cards)
	return cards[1]
end
sgs.ai_skill_use["@@bawang"] = function(self, prompt)
	local first_index, second_index
	self:sort(self.opponents, "defenseSlash")
	for i=1, #self.opponents, 1 do
		local target = self.opponents[i]
		if self:willUseSlash(target, nil, sgs.slash) then
			if not target:hasSkill("kongcheng") or not target:isKongcheng() then
				if first_index then
					second_index = i
				else
					first_index = i
				end
			end
		end
		if second_index then 
			break 
		end
	end
	if first_index then
		local first = self.opponents[first_index]:objectName()
		if second_index then
			local second = self.opponents[second_index]:objectName()
			return ("@BawangCard=.->%s+%s"):format(first, second)
		else
			return ("@BawangCard=.->%s"):format(first)
		end
	end
	return "."
end
--[[
	内容：“霸王”卡牌需求
]]--
sgs.card_need_system["bawang"] = sgs.card_need_system["bignumber"]
--[[
	技能：危殆（主公技）
	描述：当你需要使用一张【酒】时，你可以令其他吴势力角色将一张黑桃2~9的手牌置入弃牌堆，视为你将该牌当【酒】使用。 
]]--
--[[
	内容：“危殆技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["WeidaiCard"] = sgs.ai_card_intention["Peach"]
--[[
	内容：注册“危殆技能卡”
]]--
sgs.RegistCard("WeidaiCard")
--[[
	内容：“危殆”技能信息
]]--
sgs.ai_skills["weidai"] = {
	name = "weidai",
	dummyCard = function(self)
		local card_str = "@WeidaiCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if self.player:hasLordSkill("weidai") then
			if sgs.analeptic:isAvailable(self.player) then
				local lieges = self.room:getLieges("wu", self.player)
				if not lieges:isEmpty() then
					return true
				end
			end
		end
		return false
	end,
}
--[[
	内容：“危殆技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["WeidaiCard"] = function(self, card, use)
	if not self.player:hasUsed("WeidaiCard") then
		if sgs.slash:isAvailable(self.player) then
			local slashes = self:getCards("Slash")
			for _,slash in ipairs(slashes) do
				for _,enemy in ipairs(self.opponents) do
					if self:willUseSlash(enemy, self.player, slash) then
						if self:willUseAnaleptic(enemy, slash, sgs.analeptic) then
							use.card = card
							return 
						end
					end
				end
			end
		end
	end
end
sgs.ai_skill_cardask["@weidai-analeptic"] = function(self, data)
	local who = data:toPlayer()
	if self:isOpponent(who) then 
		return "." 
	end
	if self:needBear() then
		if who:getHp() > 0 then 
			return "." 
		end
	end
	local cards = self.player:getHandcards()
	for _, c in sgs.qlist(cards) do
		if c:getSuit() == sgs.Card_Spade then
			local point = c:getNumber()
			if point > 1 then
				if point < 10 then
					return c:getEffectiveId()
				end
			end
		end
	end
	return "."
end
sgs.ai_cardsview["weidai"] = function(self, class_name, player)
	if class_name == "Analeptic" then
		if player:hasLordSkill("weidai") then
			if not player:hasFlag("Global_WeidaiFailed") then
				return "@WeidaiCard=.->."
			end
		end
	end
end
sgs.ai_event_callback[sgs.ChoiceMade].weidai=function(self, player, data)
	local choices = data:toString():split(":")	
	if choices[1] == "cardResponded" then
		if choices[3] == "@weidai-analeptic" then
			local target = findPlayerByObjectName(self.room, choices[4])
			local card = choices[#choices]
			if card ~= "_nil_" then
				sgs.updateIntention(player, target, -80)
			end
		end
	end	
end
--[[
	套路：仅使用“危殆技能卡”
]]--
sgs.ai_series["WeidaiCardOnly"] = {
	name = "WeidaiCardOnly",
	IQ = 2,
	value = 2,
	priority = 3,
	skills = "weidai",
	cards = {
		["WeidaiCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local weidai_skill = sgs.ai_skills["weidai"]
		local dummyCard = weidai_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["WeidaiCard"], "WeidaiCardOnly")
--[[****************************************************************
	武将：智·张昭（吴）
]]--****************************************************************
--[[
	技能：笼络
	描述：回合结束阶段开始时，你可以令一名其他角色摸你于此回合弃牌阶段弃置的牌等量的牌。 
]]--
sgs.ai_playerchosen_intention["longluo"] = -60
sgs.ai_skill_invoke["longluo"] = function(self, data)
	return #self.partners > 1
end
sgs.ai_skill_playerchosen["longluo"] = function(self, targets)
	local n = self.player:getMark("longluo")
	local to = self:findPlayerToDraw(false, n)
	if to then 
		return to 
	end
	return self.partners_noself[1]
end
--[[
	技能：辅佐
	描述：每当其他角色拼点时，你可以弃置一张点数小于8的手牌，让其中一名角色的拼点牌的点数加上这张牌点数的二分之一（向下取整） 
]]--
sgs.ai_skill_use["@@fuzuo"] = function(self, prompt, method)
	if self.player:isKongcheng() then 
		return "." 
	end
	local pindian = self.room:getTag("FuzuoPindianData"):toPindian()
	local from, to = pindian.from, pindian.to
	local from_num, to_num = pindian.from_number, pindian.to_number
	local reason = pindian.reason
	local PDcards = {
		pindian.from_card,
		pindian.to_card,
	}
	local delt = from_num - to_num
	delt = math.abs(delt)
	if delt >= 3 then 
		return "." 
	end
	local cards = {}
	local handcards = self.player:getHandcards()
	for _,c in sgs.qlist(handcards) do
		if c:getNumber() < 8 then
			table.insert(cards, c)
		end
	end
	if #cards == 0 then
		return "."
	end
	self:sortByKeepValue(cards) 
	local card = nil
	for _,c in ipairs(cards) do
		local point = c:getNumber()
		if math.ceil(point / 2) > delt then
			card = c
		end
	end
	if card then
		local isValuable = false
		for _, c in ipairs(PDcards) do
			if sgs.isKindOf("ExNihilo|Peach|Snatch|Dismantlement|Duel", c) then
				isValuable = true
				break
			elseif c:isKindOf("Slash") then
				if self:isEquip("Crossbow", from) then
					if reason ~= "zhiba_pindian" then
						isValuable = true
					end
				end
			end
		end
		local onlyone_Jink_Peach = false
		if sgs.isCard("Peach", card, self.player) then
			if self:getCardsNum("Peach") <= 1 then
				if self.player:isWounded() then
					onlyone_Jink_Peach = true
				end
			end
		elseif sgs.isCard("Jink", card, self.player) then
			if self:getCardsNum("Jink") <= 1 then
				onlyone_Jink_Peach = true
			end
		end
		if reason == "zhiba_pindian" then
			if isValuable or not onlyone_Jink_Peach or self:getOverflow() > 0 and self:willSkipPlayPhase() then
				if self:isPartner(to) and from_num > to_num then			
					return "@FuzuoCard="..card:getEffectiveId().."->"..to:objectName()
				elseif not self:isPartner(to) and to_num > from_num then
					return "@FuzuoCard="..card:getEffectiveId().."->"..from:objectName()
				end
			end		
		elseif reason == "dahe" or reason == "mizhao" or reason == "shuangren" then
			if self:isPartner(from) and from_num < to_num then
				return "@FuzuoCard="..card:getEffectiveId().."->"..from:objectName()
			elseif not self:isPartner(from) and from_num > to_num then
				return "@FuzuoCard="..card:getEffectiveId().."->"..to:objectName()
			end
		elseif reason == "lieren" or reason == "tanlan"  or reason == "jueji" then
			if isValuable or not onlyone_Jink_Peach or self:getOverflow() > 0 and self:willSkipPlayPhase() then
				if self:isPartner(from) and not self:isPartner(to) and from_num < to_num then
					return "@FuzuoCard="..card:getEffectiveId().."->"..from:objectName() 
				elseif self:isPartner(to) and not self:isPartner(from) and to_num < from_num then
					return "@FuzuoCard="..card:getEffectiveId().."->"..to:objectName()
				end		
			end
		elseif reason == "tianyi" or reason == "xianzhen" then		
			if self:isPartner(from) and from_num < to_num and sgs.getCardsNum("Slash", from) >= 1 then			
				return "@FuzuoCard="..card:getEffectiveId().."->"..from:objectName()
			elseif not self:isPartner(from) and self:isPartner(to) and from_num > to_num and sgs.getCardsNum("Slash", from) >= 1 then
				return "@FuzuoCard="..card:getEffectiveId().."->"..to:objectName()
			end
		elseif reason == "quhu"  then
			if not self:isPartner(from) and self:isPartner(to) and from_num > to_num then
				return "@FuzuoCard="..card:getEffectiveId().."->"..to:objectName()
			elseif self:isPartner(from) and from_num >= 10 and from_num < to_num then
				return "@FuzuoCard="..card:getEffectiveId().."->"..from:objectName()
			end
		else
			if self:isPartner(from) and self:isPartner(to) then 
				return "." 
			end
			if not onlyone_Jink_Peach or self:getOverflow() > 0 and self:willSkipPlayPhase() then
				if self:isPartner(from) and from_num < to_num then
					return "@FuzuoCard="..card:getEffectiveId().."->"..from:objectName()
				elseif not self:isPartner(to) and to_num < from_num then
					return "@FuzuoCard="..card:getEffectiveId().."->"..to:objectName()
				end
			end			
		end
	end
	return "."
end
--[[
	技能：尽瘁
	描述：当你死亡时，可选择一名角色，令该角色摸三张牌或者弃置三张牌。 
]]--
sgs.ai_skill_invoke["jincui"] = function(self, data)
	return true
end
sgs.ai_skill_playerchosen["jincui"] = function(self, targets)
	local weak_friend = nil
	for _, friend in ipairs(self.partners_noself) do
		if self:isWeak(friend) then
			weak_friend = true 
			break 
		end
	end
	if not weak_friend then
		self:sort(self.opponents, "handcard")
		for _, enemy in ipairs(self.opponents) do
			if enemy:getCards("he"):length() == 3 then
				if not self:doNotDiscard(enemy, "he", true, 3, true) then
					sgs.jincui_discard = true
					return enemy
				end
			end
		end
		for _, enemy in ipairs(self.opponents) do
			if enemy:getCards("he"):length() >= 3 then
				if not self:doNotDiscard(enemy, "he", true, 3, true) then
					if self:hasSkills(sgs.cardneed_skill, enemy) then
						sgs.jincui_discard = true
						return enemy
					end
				end
			end
		end
	end
	local to = self:findPlayerToDraw(false, 3)
	if to then 
		return to 
	end
	sgs.jincui_discard = true
	return self.opponents[1]
end
sgs.ai_skill_choice["jincui"] = function(self, choices)
	if sgs.jincui_discard then 
		return "throw" 
	else 
		return "draw" 
	end
end
--[[****************************************************************
	武将：智·华雄（群）
]]--****************************************************************
--[[
	技能：霸刀
	描述：当你成为黑色的【杀】的目标后，你可以使用一张【杀】。 
]]--
sgs.ai_skill_cardask["@askforslash"] = function(self, data)
	local slashes = self:getCards("Slash")	
	self:sort(self.opponents, "defenseSlash")
	for _, slash in ipairs(slashes) do
		local no_distance = false
		local limit = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, slash)
		if limit > 50 then
			no_distance = true
		elseif self.player:hasFlag("slashNoDistanceLimit") then
			no_distance = true
		end
		for _, enemy in ipairs(self.opponents) do
			if self.player:canSlash(enemy, slash, not no_distance) then
				if self:willUseSlash(enemy, self.player, slash) then
					if slash:isBlack() and self:hasSkills("wenjiu") then
						if self:slashIsEffective(slash, enemy) then
							if sgs.isGoodTarget(self, enemy, self.opponents) then
								local can_use = true
								if self.player:hasFlag("slashTargetFix") then
									if not enemy:hasFlag("SlashAssignee") then
										can_use = false
									end
								end
								if can_use then
									return ("%s->%s"):format(slash:toString(), enemy:objectName())
								end
							end
						end
					end
				end
			end
		end
	end
	for _, slash in ipairs(slashes) do
		local no_distance = false
		local limit = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, slash)
		if limit > 50 then
			no_distance = true
		elseif self.player:hasFlag("slashNoDistanceLimit") then
			no_distance = true
		end
		for _, enemy in ipairs(self.opponents) do
			if self.player:canSlash(enemy, slash, not no_distance) then
				if self:willUseSlash(enemy, self.player, slash) then
					if not slash:isBlack() then
						if self:slashIsEffective(slash, enemy) then
							if sgs.isGoodTarget(self, enemy, self.opponents) then
								local can_use = true
								if self.player:hasFlag("slashTargetFix") then
									if not enemy:hasFlag("SlashAssignee") then
										can_use = false
									end
								end
								if can_use then
									return ("%s->%s"):format(slash:toString(), enemy:objectName())
								end
							end
						end
					end
				end
			end
		end
	end
	return "."
end
sgs.slash_prohibit_system["badao"] = {
	name = "badao",
	reason = "badao",
	judge_func = function(self, target, source, slash)
		local has_black_slash, has_red_slash
		local slashes = self:getCards("Slash")
		for _, card in ipairs(slashes) do
			if self:slashIsEffective(card, target) then
				if card:isBlack() then
					has_black_slash = true
				elseif card:isRed() then
					has_red_slash = true
				end
			end
		end
		if self:isPartner(target) then
			if slash:isRed() then
				if has_black_slash then 
					return true
				elseif self:isWeak(target) then
					return true
				end
			end
			return false
		else
			if has_red_slash then 
				return slash:isBlack() 
			end
			if sgs.getCardsNum("Slash", target) > 1 then
				local enemies = self:getOpponents(target)
				for _, to in ipairs(enemies) do
					if target:canSlash(to, slash) then
						if self:willUseSlash(to, target, sgs.slash) then
							if self:slashIsEffective(sgs.slash, to) then
								if not self:invokeDamagedEffect(to, target, true) then 
									if not self:needToLoseHp(to, target, true, true) then
										--if self:canHit(to, target) then
											if self:isWeak(to) then
												return slash:isBlack()
											end
										--end
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
}
--[[
	技能：温酒（锁定技）
	描述：你使用黑色的【杀】造成的伤害+1，你无法闪避红色的【杀】 
]]--
--[[
	内容：“温酒”卡牌需求
]]--
sgs.card_need_system["wenjiu"] = function(self, card, player)
	if card:isBlack() then
		return sgs.isCard("Slash", card, player)
	end
	return false
end
sgs.slash_prohibit_system["wenjiu"] = {
	name = "wenjiu",
	reason = "wenjiu",
	judge_func = function(self, target, source, slash)
		local has_black_slash, has_red_slash
		local slashes = self:getCards("Slash")
		for _, card in ipairs(slashes) do
			if self:slashIsEffective(card, target) then
				if card:isBlack() then 
					has_black_slash = true 
				elseif card:isRed() then
					has_red_slash = true 
				end
			end
		end
		if self:isPartner(target) then
			if slash:isRed() then
				if has_black_slash then
					return true
				elseif self:isWeak(target) then
					return true
				end
			end
			return false
		else		
			if has_red_slash then
				if sgs.getCardsNum("Jink", target) > 0 then 
					return not slash:isRed() 
				end
			end
		end
		return false
	end
}
sgs.heavy_slash_system["wenjiu"] = {
	name = "wenjiu",
	reason = "wenjiu",
	extra_func = function(source, slash, target, isFireSlash, isThunderSlash)
		if slash then
			if slash:isBlack() then
				if source:hasSkill("wenjiu") then
					return 1
				end
			end
		end
		return 0
	end,
}
--[[****************************************************************
	武将：智·田丰（群）
]]--****************************************************************
sgs.ai_chaofeng.tianfeng = -1
--[[
	技能：识破
	描述：一名角色的判定阶段开始时，你可以弃置两张牌并获得该角色判定区内的所有牌。 
]]--
sgs.ai_skill_invoke["shipo"] = function(self, data)
	local target = data:toPlayer()
	if self:isPartner(target) then
		if target:containsTrick("supply_shortage") then
			if target:getHp() > target:getHandcardNum() then
				return true
			end
		end
		if target:containsTrick("indulgence") then
			if target:getHandcardNum() > target:getHp() - 1 then
				return true
			end
		end
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke["shipo"] = function(player, promptlist, self)
	if promptlist[3] == "yes" then
		local current = self.room:getCurrent()
		sgs.updateIntention(player, current, -10)
	end
end
--[[
	技能：固守
	描述：回合外，当你使用或打出一张基本牌时，你可以摸一张牌。 
]]--
--[[
	内容：“固守”卡牌需求
]]--
sgs.card_need_system["gushou"] = function(self, card, player)
	if card:getTypeId() == sgs.Card_TypeBasic then
		return player:getHandcardNum() < 3
	end
	return false
end
--[[
	技能：狱刎（锁定技）
	描述：当你死亡时，伤害来源为自己。 
]]--
--[[****************************************************************
	武将：智·司马徽（群）
]]--****************************************************************
sgs.ai_chaofeng.wis_shuijing = 5
--[[
	技能：授业
	描述：出牌阶段，你可以弃置一张红色手牌，令至多两名其他角色各摸一张牌。“解惑”发动后，每阶段限一次。 
]]--
--[[
	内容：“授业技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["ShouyeCard"] = function(self, card, source, targets)
	local intention = -70
	for i=1, #targets, 1 do
		local to = targets[i]
		if to:hasSkill("manjuan") then
			intention = 0
		elseif self:needKongcheng(to, true) then
			intention = 0
		end
		sgs.updateIntention(source, to, intention)
	end
end
--[[
	内容：注册“授业技能卡”
]]--
sgs.RegistCard("ShouyeCard")
--[[
	内容：“授业”技能信息
]]--
sgs.ai_skills["shouye"] = {
	name = "shouye",
	dummyCard = function(self)
		return sgs.Card_Parse("@ShouyeCard=.")
	end,
	enabled = function(self, handcards)
		if #handcards > 0 then
			if self.player:getMark("jiehuo") > 0 then
				if self.player:hasUsed("ShouyeCard") then
					return false
				end
			end
			return true
		end
		return false
	end,
}
--[[
	内容：“授业技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["ShouyeCard"] = function(self, card, use)
	if #self.partners_noself > 0 then
		local acard = nil
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		for _,c in ipairs(cards) do
			if c:isRed() then
				local card_str = "@ShouyeCard=" .. c:getId()
				acard = sgs.Card_Parse(card_str)
				break
			end
		end
		if acard then
			self:sort(self.partners_noself, "defense")
			local first = nil
			local second = nil
			for _, friend in ipairs(self.partners_noself) do
				if not friend:hasSkill("manjuan") then
					if not self:needKongcheng(friend, true) then
						if not first then
							first = friend
						elseif first:objectName() ~= friend:objectName() then
							second = friend
						end
						if second then 
							break 
						end
					end
				end
			end
			if self.player:hasSkill("jiehuo") then
				if self.player:getMark("jiehuo") < 1 then
					if first and not second then
						for _, friend in ipairs(self.partners_noself) do
							if first:objectName() ~= friend:objectName() then
								second = friend
							end
							if second then 
								break 
							end
						end
						if not second then
							for _, enemy in ipairs(self.opponents) do
								if first:objectName() ~= enemy:objectName() then
									if enemy:hasSkill("manjuan") then
										second = enemy
									elseif self:needKongcheng(enemy, true) then
										second = enemy
									end
								end
								if second then 
									break 
								end
							end
						end
					end
				end
			end
			if not second then
				if self:getOverflow() <= 0 then 
					return 
				end
			end
			if first then
				if use.to then
					use.to:append(first)
					self:speak("好好学习，天天向上！")
				end
			end
			if second then
				if use.to then
					use.to:append(second)
				end
			end
			use.card = acard
		end
	end
end
--[[
	内容：“授业”卡牌需求
]]--
sgs.card_need_system["shouye"] = function(self, card, player)
	if card:isRed() then
		if player:hasSkill("jiehuo") then
			if player:getMark("jiehuo") < 1 then
				return player:getHandcardNum() < 3
			end
		end
	end
	return false
end
--[[
	套路：仅使用“授业技能卡”
]]--
sgs.ai_series["ShouyeCardOnly"] = {
	name = "ShouyeCardOnly",
	IQ = 2,
	value = 1,
	priority = 4,
	skills = "shouye",
	cards = {
		["ShouyeCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local shouye_skill = sgs.ai_skills["shouye"]
		local dummyCard = shouye_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["ShouyeCard"], "ShouyeCardOnly")
--[[
	技能：解惑（觉醒技）
	描述：当你发动“授业”不少于7人次时，须减1点体力上限，并获得技能“师恩”（其他角色使用非延时锦囊时，可以让你摸一张牌）。 
]]--
--[[
	技能：师恩
	描述：其他角色使用非延时锦囊时，可以让你摸一张牌
]]--
sgs.ai_skill_invoke["shien"] = function(self, data)
	local target = data:toPlayer()
	if target then
		if target:isAlive() then 
			return self:isPartner(target)
		end
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke["shien"] = function(player, promptlist, self)
	local SiMaHui = self.room:findPlayerBySkillName("shien")
	if SiMaHui and promptlist[3] == "yes" then
		sgs.updateIntention(player, SiMaHui, -10)
	end
end