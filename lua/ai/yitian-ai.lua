--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）倚天扩展包部分
]]--
--[[****************************************************************
	武将：倚天·魏武帝（神）
]]--****************************************************************
--[[
	技能：归心
	描述：回合结束阶段，你可以做以下二选一：
		1. 永久改变一名其他角色的势力
		2. 永久获得一项未上场或已死亡角色的主公技。(获得后即使你不是主公仍然有效) 
]]--
--[[
	功能：从所有目标角色中选取一名修改其势力
	参数：targets（sgs.QList<ServerPlayer*>类型，表示所有目标角色）
	结果：ServerPlayer类型，表示推荐的目标
]]--
function SmartAI:findPlayerToModifyKingdom(targets)
	if targets and not targets:isEmpty() then
		local lord = self.room:getLord()
		local isGood = lord and self:isPartner(lord)
		for _, target in sgs.qlist(targets) do
			if not self:amLord() then
				if self:amLoyalist() then
					if not self:hasSkills("huashen|liqian", target) then
						local sameKingdom = false
						if lord then
							if target:getKingdom() == lord:getKingdom() then
								sameKingdom = true
							end
						end
						if isGood ~= sameKingdom then
							return target
						end
					end
				end
				if lord then
					if lord:hasLordSkill("xueyi") then
						if not self:mayLord(target) then
							if not self:hasSkills("huashen|liqian", target) then
								local isQun = ( target:getKingdom() == "qun" )
								if isGood ~= isQun then
									return target
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
	功能：为一名角色选择势力
	参数：target（ServerPlayer类型，表示目标角色）
	结果：string类型，表示选择的势力
]]--
function SmartAI:chooseKingdomForPlayer(target)
	local lord = self.room:getLord()
	local isGood = lord and self:isPartner(lord)
	if self:mayLoyalist(target) or self:mayRenegade(target) then
		if isGood then
			return lord and lord:getKingdom()
		else
			if lord then
				local kingdoms = {"qun", "shu", "wu", "wei"}
				for _, kingdom in ipairs(kingdoms) do
					if lord:getKingdom() ~= kingdom then
						return kingdom
					end
				end
			end
		end
	elseif lord and lord:hasLordSkill("xueyi") and not target:isLord() then
		return isGood and "qun" or "wei"
	elseif self.player:hasLordSkill("xueyi") then
		return "qun"
	end
	return "qun"
end
sgs.ai_skill_invoke["weiwudi_guixin"] = true
sgs.ai_skill_choice["weiwudi_guixin"] = function(self, choices)
	--选择势力
	if choices == "wei+shu+wu+qun" then
		local tag = self.room:getTag("Guixin2Modify")
		local target = tag:toPlayer()
		return self:chooseKingdomForPlayer(target)
	--选择技能项
	elseif choices == "modify+obtain" then
		if self:amRenegade() or self:amLord() then
			return "obtain"
		end
		if #sgs.ai_lords == 0 then
			return "obtain"
		end
		local lord = self.room:getLord()
		local skills = lord:getVisibleSkillList()
		local hasLordSkill = false
		for _,skill in sgs.qlist(skills) do
			if skill:isLordSkill() then
				hasLordSkill = true
				break
			end
		end
		if not hasLordSkill then
			return "obtain"
		end
		local others = self.room:getOtherPlayers(self.player)
		others:removeOne(lord)
		if self:findPlayerToModifyKingdom(others) then
			return "modify"
		else
			return "obtain"
		end
	--选择主公技
	else
		if choices:match("xueyi") then
			if not self.room:getLieges("qun", self.player):isEmpty() then 
				return "xueyi" 
			end
		end
		if choices:match("ruoyu") then 
			return "ruoyu" 
		end
		if choices:match("weidai") then
			if self:isWeak() then 
				return "weidai" 
			end
		end
		local choice_table = choices:split("+")
		local index = math.random(1, #choice_table)
		return choice_table[index]
	end
end
sgs.ai_skill_playerchosen["weiwudi_guixin"] = function(self, targets)
	if targets then
		local target = self:findPlayerToModifyKingdom(targets)
		return target or targets:first()
	end
end
--[[
	技能：飞影（锁定技）
	描述：其他角色与你的距离+1 
]]--
--[[****************************************************************
	武将：倚天·曹冲（魏）
]]--****************************************************************
--[[
	技能：称象
	描述：每当你受到一次伤害后，你可以弃置X张点数之和与造成伤害的牌的点数相等的牌，你可以选择至多X名角色，若其已受伤则回复1点体力，否则摸两张牌。 
]]--
--[[
	内容：“称象技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["YTChengxiangCard"] = sgs.ai_card_intention["QingnangCard"]
sgs.ai_skill_use["@@ytchengxiang"] = function(self, prompt)
	local prompts = prompt:split(":")
	local point = tonumber(prompts[4])
	local targets = self.partners
	local function compare_func(a, b)
		if a:isWounded() ~= b:isWounded() then
			return a:isWounded()
		elseif a:isWounded() then
			return a:getHp() < b:getHp()
		else
			return a:getHandcardNum() < b:getHandcardNum()
		end
	end
	table.sort(targets, compare_func)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local opt1 = nil
	local opt2 = nil
	for _,card in ipairs(cards) do
		if card:getNumber() == point then 
			opt1 = "@YTChengxiangCard=" .. card:getId() .. "->" .. targets[1]:objectName() 
			break 
		end
	end
	for _,card1 in ipairs(cards) do
		local idA = card1:getId()
		local pointA = card1:getNumber()
		for __,card2 in ipairs(cards) do
			local idB = card2:getId()
			local pointB = card2:getNumber()
			if idA ~= idB then
				if pointA + pointB == point then
					if #targets >= 2 then
						if targets[2]:isWounded() then
							local nameA = targets[1]:objectName()
							local nameB = targets[2]:objectName()
							opt2 = "@YTChengxiangCard="..idA.."+"..idB.."->"..nameA.."+"..nameB
							break
						end
					end
					local flag = false
					if targets[1]:getHp() == 1 then
						flag = true
					else
						local valueA = sgs.getCardValue(card1, "use_value")
						local valueB = sgs.getCardValue(card2, "use_value")
						if valueA + valueB <= 6 then
							flag = true
						end
					end
					if flag then
						opt2 = "@YTChengxiangCard="..idA.."+"..idB.."->".. targets[1]:objectName()
						break
					end
				end
			end
		end
		if opt2 then 
			break 
		end
	end
	if opt1 and opt2 then
		if self.player:getHandcardNum() > 7 then 
			return opt2 
		else 
			return opt1 
		end
	end
	return opt2 or opt1 or "."
end
--[[
	内容：“称象”卡牌需求
]]--
sgs.card_need_system["ytchengxiang"] = function(self, card, player)
	if card:getNumber() < 8 then
		if player:getHandcardNum() < 12 then
			return sgs.getUseValue(card, self.player) < 6
		end
	end
	return false
end
--[[
	技能：聪慧（锁定技）
	描述：跳过你的弃牌阶段。 
]]--
--[[
	技能：早夭（锁定技）
	描述：回合结束阶段开始时，若你的手牌数大于13，你须弃置所有手牌并失去1点体力。 
]]--
--[[****************************************************************
	武将：倚天·张儁乂（群）
]]--****************************************************************
--[[
	技能：绝汲
	描述：出牌阶段限一次，你可以和一名角色拼点：若你赢，你获得对方的拼点牌。你可以重复此流程，直到你拼点没赢为止。 
]]--
--[[
	内容：“绝汲技能卡”的卡牌成分
]]--
sgs.card_constituent["JuejiCard"] = {
	control = 2,
}
--[[
	内容：“绝汲技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["JuejiCard"] = function(self, card, source, targets)
	local intention = 10
	local target = targets[1]
	if self:needKongcheng(target) then
		if target:getHandcardNum() == 1 then
			intention = 0
		end
	end
	sgs.updateIntention(source, target, intention)
end
--[[
	内容：注册“绝汲技能卡”
]]--
sgs.RegistCard("JuejiCard")
--[[
	内容：“绝汲”技能信息
]]--
sgs.ai_skills["jueji"] = {
	name = "jueji",
	dummyCard = function(self)
		return sgs.Card_Parse("@JuejiCard=.")
	end,
	enabled = function(self, handcards)
		if not self.player:hasUsed("JuejiCard") then
			if #handcards > 0 then
				return true
			end
		end
		return false
	end,
}
--[[
	内容：“绝汲技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["JuejiCard"] = function(self, card, use)
	if self.player:isKongcheng() then 
		return 
	end
	local ZhuGeLiang = self.room:findPlayerBySkillName("kongcheng")
	if ZhuGeLiang then
		if self:isPartner(ZhuGeLiang) then
			if ZhuGeLiang:getHandcardNum() == 1 then
				if zhugeliang:objectName() ~= self.player:objectName() then
					if self:getEnemyNumBySeat(self.player, ZhuGeLiang) > 0 then
						if ZhuGeLiang:getHp() <= 2 then
							local cards = sgs.QList2Table(self.player:getHandcards())
							self:sortByUseValue(cards, true)
							local card_str = "@JuejiCard=" .. cards[1]:getId()
							use.card = sgs.Card_Parse(card_str)
							ZhuGeLiang:setFlags("jueji_target")
							if use.to then 
								use.to:append(ZhuGeLiang) 
							end
							return
						end
					end
				end
			end
		end
	end
	self:sort(self.opponents, "defense")
	local my_max_card = self:getMaxPointCard()
	local my_max_point = my_max_card:getNumber()
	local need_use = false
	if not self:hasLoseHandcardEffective() then
		need_use = true
	elseif self:needKongcheng() then
		if self.player:getHandcardNum() == 1 then
			need_use = true
		end
	end
	if need_use then
		for _,enemy in ipairs(self.opponents) do
			if not self:doNotDiscard(enemy, "h") then
				local card_str = "@JuejiCard=" .. my_max_card:getId()
				use.card = sgs.Card_Parse(card_str)
				enemy:setFlags("jueji_target")
				if use.to then 
					use.to:append(enemy) 
				end
				return
			end
		end
	end
	for _,enemy in ipairs(self.opponents) do
		if not self:doNotDiscard(enemy, "h") then
			local max_card = self:getMaxPointCard(enemy)
			local allknown = 0
			if self:getKnownNum(enemy) == enemy:getHandcardNum() then
				allknown = allknown + 1
			end
			local can_use = false
			if max_card then
				local max_point = max_card:getNumber()
				if my_max_point > max_point then
					if allknown > 0 then
						can_use = true
					end
				end
				if my_max_point > 10 then
					if allknown < 1 then
						can_use = true
					end
				end
			else
				if my_max_point > 10 then
					can_use = true
				end
			end
			if can_use then
				local card_str = "@JuejiCard=" .. my_max_card:getId()
				use.card = sgs.Card_Parse(card_str)
				enemy:setFlags("jueji_target")
				if use.to then 
					use.to:append(enemy) 
				end
				return
			end
		end
	end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if self:getOverflow() > 0 then
		for _,enemy in ipairs(self.opponents) do
			if not self:doNotDiscard(enemy, "h", true) then
				local card_str = "@JuejiCard=" .. cards[1]:getId()
				use.card = sgs.Card_Parse(card_str)
				enemy:setFlags("jueji_target")
				if use.to then 
					use.to:append(enemy) 
				end
				return
			end
		end
	end
end
sgs.ai_skill_invoke["jueji"] = function(self, data)
	local target
	local others = self.room:getOtherPlayers(self.player)
	for _, player in sgs.qlist(others) do
		if player:hasFlag("jueji_target") then
			target = player
		end
	end
	if target then
		return not self:doNotDiscard(target, "h")
	end
	return false 
end
sgs.ai_skill_pindian["jueji"] = function(self, requestor, maxcard, mincard)
	if self:isPartner(requestor) then 
		return 
	end
	local maxpoint = maxcard:getNumber()
	if maxpoint == 13 then 
		return maxcard 
	end
	local num = requestor:getHandcardNum()
	if (maxpoint / 13) ^ num <= 0.6 then 
		return mincard--minusecard 
	end
end
--[[
	内容：“绝汲”卡牌需求
]]--
sgs.card_need_system["jueji"] = sgs.card_need_system["bignumber"]
--[[
	套路：仅使用“绝汲技能卡”
]]--
sgs.ai_series["JuejiCardOnly"] = {
	name = "JuejiCardOnly",
	IQ = 2,
	value = 2,
	priority = 4,
	skills = "jueji",
	cards = {
		["JuejiCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local jueji_skill = sgs.ai_skills["jueji"]
		local dummyCard = jueji_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["JuejiCard"], "JuejiCardOnly")
--[[****************************************************************
	武将：倚天·陆抗（吴）
]]--****************************************************************
--[[
	技能：围堰
	描述：你可以将摸牌阶段视为出牌阶段，将出牌阶段视为摸牌阶段。 
]]--
sgs.ai_skill_invoke["lukang_weiyan"] = function(self, data)
	local handcard = self.player:getHandcardNum()
	local max_card = self.player:getMaxCards()
	local target = 0
	local slashnum = 0
	local slashes = self:getCards("Slash")
	for _,slash in ipairs(slashes) do
		for _,enemy in ipairs(self.opponents) do
			if self.player:canSlash(enemy, slash) then
				if self:slashIsEffective(slash, enemy) then
					if self:slashIsEffective(slash, enemy) then
						if not self:slashIsProhibited(slash, enemy) then
							if sgs.isGoodTarget(self, enemy, self.opponents) then 
								slashnum = slashnum + 1
								target = target + 1
								break
							end
						end
					end
				end
			end 
		end
	end
	local prompt = data:toString()
	if prompt == "draw2play" then
		if self:needBear() then 
			return false 
		end
		if slashnum > 1 then
			if target > 0 then 
				return true 
			end
		end
		if self.player:isSkipped(sgs.Player_Play) then
			local handcards = self.player:getHandcards()
			local series = self:getSeries(handcards)
			if #series > 1 then 
				return true 
			end
		end
	elseif prompt == "play2draw" then
		if self:needBear() then 
			return true 
		end
		if slashnum > 0 then
			if target > 0 then 
				return false 
			end
		end
		local handcards = self.player:getHandcards()
		local series = self:getSeries(handcards)
		if #series < 2 then 
			return true 
		end
	end
	return false
end
--[[
	内容：“围堰”卡牌需求
]]--
sgs.card_need_system["lukang_weiyan"] = function(self, card, player)
	if sgs.isCard("Slash", card, player) then
		return sgs.getKnownCard(player, "Slash", true) < 2
	end
	return false
end
--[[
	技能：克构（觉醒技）
	描述：回合开始阶段开始时，若你是除主公外唯一的吴势力角色，你须减少1点体力上限并获得技能“连营”。 
]]--
--[[****************************************************************
	武将：倚天·晋宣帝（神）
]]--****************************************************************
--[[
	技能：五灵
	描述：回合开始阶段开始时，你可选择一种五灵效果发动，该效果对场上所有角色生效
		该效果直到你的下回合开始为止，你选择的五灵效果不可与上回合重复
		[风]一名角色受到的火焰伤害+1。
		[雷]一名角色受到的雷电伤害+1。
		[水]一名角色使用【桃】时额外回复1点体力。
		[火]一名角色受到的伤害均视为火焰伤害。
		[土]一名角色受到的属性伤害大于1时，防止多余的伤害。 
]]--
sgs.ai_skill_choice["wuling"] = function(self, choices)
	if choices:match("water") then
		local weak_friend, weak_enemy = 0, 0
		local alives = self.room:getAlivePlayers()
		for _, player in sgs.qlist(alives) do
			if self:isWeak(player) then
				if self:isOpponent(player) then 
					weak_enemy = weak_enemy + 1
					if self:mayLord(player) then 
						weak_enemy = weak_enemy + 1 
					end
				elseif self:isPartner(player) then
					weak_friend = weak_friend + 1
					if self:mayLord(player) then 
						weak_friend = weak_friend + 1 
					end
				end
			end
		end
		if weak_friend > 0 then
			if weak_friend >= weak_enemy then 
				return "water" 
			end
		end
	end
	if choices:match("earth") then
		local friends = self:getChainedPartners()
		local enemies = self:getChainedOpponents()
		if #friends > #enemies then
			if #friends + #enemies > 1 then
				return "fire"
			end
		end
		if self:hasWizard(self.opponents, true) then
			if not self:hasWizard(self.partners, true) then
				local alives = self.room:getAlivePlayers()
				for _, player in sgs.qlist(alives) do
					if player:containsTrick("lightning") then 
						return "earth" 
					end
				end
			end
		end
	end
	if choices:match("fire") then
		for _,enemy in ipairs(self.opponents) do
			if enemy:hasArmorEffect("Vine") then 
				return "fire" 
			end
		end
		local friends = self:getChainedPartners()
		local enemies = self:getChainedOpponents()
		if #friends < #enemies then
			if #friends + #enemies > 1 then
				return "fire"
			end
		end
	end
	if choices:match("wind") then
		for _,enemy in ipairs(self.opponents) do
			if enemy:hasArmorEffect("Vine") then 
				return "wind" 
			end
		end
		for _,friend in ipairs(self.partners) do
			if self:hasSkills("huoji|yeyan|zonghuo|lihuo", friend) then 
				return "wind" 
			end
		end
		local friends = self:getChainedPartners()
		local enemies = self:getChainedOpponents()
		if #friends < #enemies then
			if #friends + #enemies > 1 then
				return "wind" 
			end
		end
		for _,friend in ipairs(self.partners) do
			if self:isEquip("Fan", friend) then 
				return "wind" 
			end
		end
		if self:getCardId("FireSlash") then
			return "wind"
		elseif self:getCardId("FireAttack") then 
			return "wind" 
		end
	end
	if choices:match("thunder") then
		if self:hasWizard(self.partners, true) then
			if not self:hasWizard(self.opponents, true) then
				local alives = self.room:getAlivePlayers()
				for _,player in sgs.qlist(alives) do
					if player:containsTrick("lightning") then 
						return "thunder" 
					end
				end
				for _,friend in ipairs(self.partners) do
					if friend:hasSkill("leiji") then 
						return "thunder" 
					end
				end
			end
		end
		if self:getCardId("ThunderSlash") then 
			return "thunder" 
		end
	end
	local choices_table = choices:split("+")
	local index = math.random(1, #choices_table)
	return choices_table[index]
end
--[[****************************************************************
	武将：倚天·夏侯涓（魏）
]]--****************************************************************
--[[
	技能：连理
	描述：回合开始阶段开始时，你可以选择一名男性角色，你和其进入连理状态直到你的下回合开始：该角色可以帮你出闪，你可以帮其出杀 
]]--
--[[
	内容：“连理技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["LianliCard"] = -80
--[[
	内容：注册“连理杀”技能卡
]]--
sgs.RegistCard("LianliSlashCard")
--[[
	内容：“连理（杀）”技能信息
]]--
sgs.ai_skills["lianli-slash"] = {
	name = "lianli-slash",
	dummyCard = function(self)
		return sgs.Card_Parse("@LianliSlashCard=.") 
	end,
	enabled = function(self, handcards)
		if self.player:getMark("@tied") > 0 then
			if sgs.slash:isAvailable(self.player) then
				if not self.player:hasFlag("Global_LianliFailed") then
					return true
				end
			end
		end
		return false
	end,
}
--[[
	内容：“连理杀技能卡”的使用方式
]]--
sgs.ai_skill_use_func["LianliSlashCard"] = function(self, card, use)
	if self.player:hasUsed("LianliSlashCard") then
		if not sgs.lianlislash then 
			return 
		end
	end
	if use.card then 
		use.card = card 
	end
end
table.insert(sgs.ai_global_flags, "lianlisource")
sgs.ai_skill_use["@@lianli"] = function(self, prompt)
	for _,friend in ipairs(self.partners_noself) do --优先考虑与队友连理
		if friend:isMale() then
			if not friend:hasSkill("manjuan") then
				return "@LianliCard=.->" .. friend:objectName()
			end
		end
	end
	for _,friend in ipairs(self.partners_noself) do
		if friend:isMale() then
			return "@LianliCard=.->" .. friend:objectName()
		end
	end
	if self.player:isMale() then --双将时可以和自己连理
		return "@LianliCard=.->"..self.player:objectName()
	end
	if sgs.turncount <= 2 then
		local others = self.room:getOtherPlayers(self.player)
		for _,player in sgs.qlist(others) do
			if player:isMale() then
				if not self:isOpponent(player) then
					if not player:inMyAttackRange(self.player) then
						return "@LianliCard=.->" .. player:objectName()
					end
				end
			end
		end
	end	
	return "."
end
sgs.ai_skill_invoke["lianli_slash"] = function(self, data) --CardAsk
	return self:getCardsNum("Slash") == 0
end
sgs.ai_skill_invoke["lianli_jink"] = function(self, data)
	local tied
	local others = self.room:getOtherPlayers(self.player)
	for _, player in sgs.qlist(others) do
		if player:getMark("@tied") > 0 then 
			tied = player 
			break 
		end
	end
	if self:hasEightDiagramEffect(tied) then 
		return true 
	end
	return self:getCardsNum("Jink") == 0
end
sgs.ai_skill_cardask["@lianli-jink"] = function(self)
	local others = self.room:getOtherPlayers(self.player)
	local target
	for _, p in sgs.qlist(others) do
		if p:getMark("@tied") > 0 then 
			target = p 
			break 
		end
	end
	if not self:isPartner(target) then 
		return "." 
	end
	return self:getCardId("Jink") or "."
end
sgs.ai_skill_cardask["@lianli-slash"] = function(self)
	local others = self.room:getOtherPlayers(self.player)
	local target
	for _, p in sgs.qlist(others) do
		if p:getMark("@tied") > 0 then 
			target = p 
			break 
		end
	end
	if not self:isPartner(target) then
		return "." 
	end
	return self:getCardId("Slash") or "."
end
sgs.ai_choicemade_filter.skillInvoke["lianli-jink"] = function(player, promptlist)
	if promptlist[#promptlist] == "yes" then
		sgs.lianlisource = player
	end
end
sgs.ai_choicemade_filter.cardResponded["@lianli-jink"] = function(player, promptlist)
	if promptlist[#promptlist] ~= "_nil_" then
		local room = player:getRoom()
		local XiaHouJuan = room:findPlayerBySkillName("lianli")
		assert(XiaHouJuan)
		sgs.updateIntention(player, XiaHouJuan, -80)
		sgs.lianlisource = nil
	end
end
local lianli_slash_filter = function(player, carduse)
	if carduse.card:isKindOf("LianliSlashCard") then
		sgs.lianlislash = false
	end
end
table.insert(sgs.ai_choicemade_filter.cardUsed, lianli_slash_filter)
sgs.ai_choicemade_filter.cardResponded["@lianli-slash"] = function(player, promptlist)
	if promptlist[#promptlist] ~= "_nil_" then
		sgs.lianlislash = true
	end
end
sgs.slash_prohibit_system["lianli"] = {
	name = "lianli",
	reason = "lianli",
	judge_func = function(self, target, source, slash)
		--友方
		if self:isPartner(target, source) then
			return false
		end
		--烈弓
		if self:canLiegong(target, source) then 
			return false 
		end
		--连理
		local others = self.room:getOtherPlayers(target)
		for _,p in sgs.qlist(others) do
			if p:getMark("@tied") > 0 then
				if self:isPartner(target, p) then
					local item = nil
					if p:hasSkill("tiandu") then
						item = sgs.slash_prohibit_system["tiandu"]
					elseif p:hasSkill("leiji") then
						item = sgs.slash_prohibit_system["leiji"]
					elseif p:hasSkill("weidi") then
						item = sgs.slash_prohibit_system["weidi"]
					elseif p:hasLordSkill("hujia") then
						item = sgs.slash_prohibit_system["hujia"]
					end
					if item then
						local callback = item["judge_func"] 
						if callback and callback(self, p, source, slash) then
							return true
						end
					end
				end
			end
		end
		return false
	end
}
--[[
	套路：仅使用“连理杀技能卡”
]]--
sgs.ai_series["LianliSlashCardOnly"] = {
	name = "LianliSlashCardOnly",
	IQ = 2,
	value = 1,
	priority = 3,
	cards = {
		["LianliSlashCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local lianli_skill = sgs.ai_skills["lianli-slash"]
		local dummyCard = lianli_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["LianliSlashCard"], "LianliSlashCardOnly")
--[[
	技能：同心
	描述：处于连理状态的两名角色，每受到一点伤害，你可以令你们两人各摸一张牌 
]]--
sgs.ai_skill_invoke["tongxin"] = true
--[[
	技能：离迁（锁定技）
	描述：当你处于连理状态时，势力与连理对象的势力相同；当你处于未连理状态时，势力为魏 
]]--
--[[****************************************************************
	武将：倚天·蔡昭姬（群）
]]--****************************************************************
--[[
	技能：归汉
	描述：出牌阶段限一次，你可以弃置两张相同花色的红色手牌选择一名其他角色，你与该角色交换位置。 
]]--
--[[
	内容：“归汉技能卡”的卡牌成分
]]--
sgs.card_constituent["GuihanCard"] = {	
	use_priority = 8,
}
--[[
	内容：注册“归汉技能卡”
]]--
sgs.RegistCard("GuihanCard")
--[[
	内容：“归汉”技能信息
]]--
sgs.ai_skills["guihan"] = {
	name = "guihan",
	dummyCard = function(self)
		return sgs.Card_Parse("@GuihanCard=.")
	end,
	enabled = function(self, handcards)
		if self.player:hasUsed("GuihanCard") then
			return false
		else
			local count = 0
			for _,card in ipairs(handcards) do
				if card:isRed() then
					count = count + 1
				end
				if count >= 2 then
					return true
				end
			end
		end
		return false
	end,
}
--[[
	内容：“归汉技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["GuihanCard"] = function(self, card, use)
	if self:getOverflow() <= 0 then
		return 
	elseif self.room:alivePlayerCount() == 2 then
		return 
	elseif self:amRenegade() then 
		return 
	elseif #self.partners_noself == 0 then
		return 
	end
	local cards = self.player:getCards("h")
	local reds = {}
	for _,red in sgs.qlist(cards) do
		if red:isRed() then
			table.insert(reds, red)
		end
	end
	local acard = nil
	if #reds > 1 then
		self:sortByUseValue(reds)
		local to_use = {}
		for index = #reds, 1, -1 do
			local red = reds[index]
			if sgs.getUseValue(red, self.player) >= 6 then 
				break 
			end
			if #to_use == 0 then
				table.insert(to_use, red:getId())
				table.remove(reds, index)
			elseif #to_use == 1 then
				local first_id = to_use[1]
				local first = sgs.Sanguosha:getCard(first)
				if red:getSuit() == first:getSuit() then
					table.insert(to_use, red:getId())
					table.remove(reds, index)
				end
			elseif #to_use >=2 then 
				break 
			end
		end
		if #to_use == 2 then 
			local card_str = "@GuihanCard=" .. table.concat(to_use, "+")
			acard = sgs.Card_Parse(card_str) 
		end
	end
	if acard then
		local values = {}
		local range = self.player:getAttackRange()
		local playerA = self.player
		local playerCount = self.player:aliveCount()
		for i=1, playerCount, 1 do
			local diff = 0
			local add = 0
			local isFriend = false
			local playerB = playerA
			for value = #self.partners_noself, 1, -1 do
				playerB = playerB:getNextAlive()
				if playerB:objectName() == self.player:objectName() then
					if self:isPartner(playerA) then
						diff = diff + value
					else
						diff = diff - value
					end
				else
					if self:isPartner(playerB) then
						diff = diff + value
						if isFriend then
							add = add + 1
						else
							isFriend = true
						end
					else
						diff = diff - value
						isFriend = false
					end
				end
			end
			values[playerA:objectName()] = diff + add
			playerA = playerA:getNextAlive()
		end
		local function getValue(a)
			local value = 0
			for _, enemy in ipairs(self.opponents) do
				if a:objectName() ~= enemy:objectName() then
					if a:distanceTo(enemy) <= range then 
						value = value + 1 
					end
				end
			end
			return value
		end
		local function compare_func(a, b)
			local valueA = values[a:objectName()]
			local valueB = values[b:objectName()]
			if valueA == valueB then
				return getValue(a) > getValue(b)
			else
				return valueA > valueB
			end
		end
		local alives = self.room:getAlivePlayers()
		alives = sgs.QList2Table(alives) 
		table.sort(alives, compare_func)
		local target = alives[1]
		if values[target:objectName()] > 0 then
			if target:objectName() ~= self.player:objectName() then
				use.card = acard
				if use.to then 
					use.to:append(target)
				end
			end
		end
	end
end
--[[
	套路：仅使用“归汉技能卡”
]]--
sgs.ai_series["GuihanCardOnly"] = {
	name = "GuihanCardOnly",
	IQ = 2,
	value = 2,
	priority = 4,
	skills = "guihan",
	cards = {
		["GuihanCard"] = 1,
		["Others"] = 2,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local guihan_skill = sgs.ai_skills["guihan"]
		local dummyCard = guihan_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["GuihanCard"], "GuihanCardOnly")
--[[
	技能：胡笳
	描述：回合结束阶段开始时，你可以进行一次判定：若为红色，获得此判定牌。你可以重复此流程，直到出现黑色为止。若你在一个阶段内累计发动3次或更多的“胡笳”，你的武将牌翻面。 
]]--
sgs.ai_skill_invoke["caizhaoji_hujia"] = function(self, data)
	local ZhangJiao = self.room:findPlayerBySkillName("guidao")
	if ZhangJiao then
		if self:isOpponent(ZhangJiao) then
			if sgs.getKnownCard(ZhangJiao, "black", false, "he") > 1 then 
				return false 
			end
		end
	end
	if self.player:faceUp() then
		local invokeNum = self.player:getMark("caizhaoji_hujia")
		if invokeNum < 2 then
			self.room:setPlayerMark(self.player, "caizhaoji_hujia", invokeNum + 1)
			return true
		else
			if self:hasSkills("hongyan|noszhenlie|jiushi|toudu|guicai|huanshi", self.player) then
				self.room:setPlayerMark(self.player, "caizhaoji_hujia", invokeNum + 1) 
				return true
			end
			for _,p in pairs(self.friends_noself) do
				if self:hasSkills("fangzhu|jilve|guicai|huanshi|jujian", p) then
					self.room:setPlayerMark(self.player, "caizhaoji_hujia", invokeNum + 1) 
					return true 
				end
			end
			return false
		end
	end
	return true
end
sgs.ai_event_callback[sgs.EventPhaseEnd].caizhaoji_hujia = function(self, player, data)
	if player:getPhase() == sgs.Player_Finish then
		self.room:setPlayerMark(player, "caizhaoji_hujia", 0) 
	end
end
--[[****************************************************************
	武将：倚天·陆伯言（吴）
]]--****************************************************************
--[[
	技能：神君（锁定技）
	描述：游戏开始时，你选择自己的性别。回合开始阶段开始时，你须改变性别，你受到异性角色造成的非雷电属性伤害时，你防止之。 
]]--
sgs.ai_skill_choice["shenjun"] = function(self, choices)
	local gender = false
	if sgs.role_predictable then
		local male = 0
		for _, enemy in ipairs(self.opponents) do
			if enemy:isMale() then 
				male = male + 1 
			end
		end
		local count = #self.opponents
		gender = ( male < count - male )
	else
		local males = 0
		local alives = self.room:getAlivePlayers()
		for _, player in sgs.qlist(alives) do
			if player:isMale() then 
				males = males + 1 
			end
		end
		local count = self.player:aliveCount()
		gender = ( males <= count - males )
	end
	local seat = self.player:getSeat()
	local aliveCount = self.room:alivePlayerCount()
	if seat < aliveCount / 2 then 
		gender = not gender 
	end
	if gender then 
		return "male" 
	else 
		return "female" 
	end
end
local shenjun_damage_invalid = {
	reason = "shenjun",
	judge_func = function(target, nature, source, notThunder)
		if notThunder then
			if target:hasSkill("shenjun") then
				return source:getGender() ~= target:getGender()
			end
		end
		return false
	end
}
table.insert(sgs.damage_invalid_system, shenjun_damage_invalid) --添加到伤害无效判定表
--[[
	技能：烧营
	描述：当你对一名不处于连环状态的角色造成一次火焰伤害，在扣减体力前，你可选择一名其距离为1的另外一名角色，在该伤害结算完毕后，你进行一次判定：若判定结果为红色，你对选择的角色造成1点火焰伤害。 
]]--
sgs.ai_playerchosen_intention["shaoying"] = function(self, source, target)
	sgs.shaoying_target = target
	sgs.updateIntention(source, target, 10)
end
sgs.ai_skill_invoke["shaoying"] = function(self, data)
	local damage = data:toDamage()
	local enemynum = 0
	local others = self.room:getOtherPlayers(damage.to)
	for _, p in sgs.qlist(others) do
		if damage.to:distanceTo(p) <= 1 then
			if self:isOpponent(p) then
				enemynum = enemynum + 1
			end
		end
	end
	if enemynum < 1 then 
		return false 
	end
	local ZhangJiao = self.room:findPlayerBySkillName("guidao")
	if ZhangJiao then
		if self:isEnemy(ZhangJiao) then
			if sgs.getKnownCard(ZhangJiao, "black", false, "he") > 1 then 
				return false 
			end
		end
	end
	return true
end
sgs.ai_skill_playerchosen["shaoying"] = function(self, targets)
	local tos = {}
	for _, target in sgs.qlist(targets) do
		if self:isOpponent(target) then 
			table.insert(tos, target) 
		end
	end 
	if #tos > 0 then
		-- tos = self:SortByAtomDamageCount(tos, self.player, sgs.DamageStruct_Fire, nil)
		return tos[1]
	end
end
--[[
	技能：纵火（锁定技）
	描述：你使用的【杀】视为火【杀】。 
]]--
--[[****************************************************************
	武将：倚天·钟士季（魏）
]]--****************************************************************
--[[
	技能：共谋
	描述：回合结束阶段开始时，可指定一名其他角色：其在摸牌阶段摸牌后，须给你X张手牌（X为你手牌数与对方手牌数的较小值），然后你须选择X张手牌交给对方 
]]--
sgs.ai_playerchosen_intention["gongmou"] = function(self, source, target)
	local intention = 60
	if target:hasSkill("manjuan") then 
		intention = -intention
	elseif target:hasSkill("enyuan") then 
		intention = 0
	end
	sgs.updateIntention(source, target, intention)
	sgs.gongmou_target = nil
end
sgs.ai_skill_invoke["gongmou"] = function(self, data)
	sgs.gongmou_target = nil
	if self.player:hasSkill("manjuan") then 
		return false 
	end
	self:sort(self.partners_noself, "defense")
	for _,friend in ipairs(self.partners_noself) do
		if friend:hasSkill("enyuan") then
			sgs.gongmou_target = friend
		elseif friend:hasSkill("manjuan") then
			sgs.gongmou_target = friend
			return true
		end
	end
	if sgs.gongmou_target then 
		return true 
	end
	self:sort(self.opponents, "defense")
	for _,enemy in ipairs(self.opponents) do
		if not self:hasSkills("manjuan|qiaobian", enemy) then
			if not self:willSkipDrawPhase(enemy) then
				if not self:needKongcheng(enemy) then
					sgs.gongmou_target = enemy
					return true
				elseif self.player:getHandcardNum() <= enemy:getHandcardNum() then
					sgs.gongmou_target = enemy
					return true
				end
			end
		end
	end
	return false
end
sgs.ai_skill_playerchosen["gongmou"] = function(self, targets)
	if sgs.gongmou_target then 
		return sgs.gongmou_target 
	end
	self:sort(self.opponents, "defense")
	return self.opponents[1]
end
sgs.ai_skill_discard["gongmou"] = function(self, discard_num, optional, include_equip)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local to_discard = {}
	local function compare_func(a, b)
		local valueA = sgs.getCardValue(a, "keep_value")
		local valueB = sgs.getCardValue(b, "keep_value")
		return valueA < valueB
	end
	table.sort(cards, compare_func)
	for _,card in ipairs(cards) do
		if #to_discard >= discard_num then 
			break 
		end
		table.insert(to_discard, card:getId())
	end
	return to_discard
end
--[[****************************************************************
	武将：倚天·姜伯约（蜀）
]]--****************************************************************
--[[
	技能：乐学
	描述：出牌阶段限一次，你可以令一名其他角色展示一张手牌：若该牌为基本牌或非延时类锦囊牌，你可以将与该牌同花色的牌当作该牌使用或打出直到回合结束；否则，你获得该牌。 
]]--
--[[
	内容：“乐学技能卡”的卡牌成分
]]--
sgs.card_constituent["LexueCard"] = {
	use_priority = 10,
}
--[[
	内容：注册“乐学技能卡”
]]--
sgs.RegistCard("LexueCard")
--[[
	内容：“乐学”技能信息
]]--
sgs.ai_skills["lexue"] = {
	name = "lexue",
	dummyCard = function(self)
		return sgs.Card_Parse("@LexueCard=.")
	end,
	enabled = function(self)
		if self.player:hasUsed("LexueCard") then
			if self.player:hasFlag("lexue") then
				return true
			end
			return false
		end
		return true
	end,
}
--[[
	内容：“乐学技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["LexueCard"] = function(self, card, use)
	if self.player:hasFlag("lexue") then
		local mark = self.player:getMark("lexue")
		local src = sgs.Sanguosha:getCard(mark)
		local handcards = self.player:getHandcards()
		local cards = {}
		local suit = src:getSuitString()
		for _,c in sgs.qlist(handcards) do
			if c:getSuitString() == suit then
				table.insert(cards, c)
			end
		end
		if #cards > 0 then
			local name = src:objectName()
			self:sortByUseValue(cards, true)
			for _,c in ipairs(cards) do
				local card_str = string.format("%s:lexue[%s:%d]=%d", name, suit, c:getNumber(), c:getId())
				local acard = sgs.Card_Parse(acard)
				if sgs.getUseValue(acard, self.player) < sgs.getUseValue(c, self.player) then
					if src:isKindOf("BasicCard") then
						self:useBasicCard(src, use)
						if use.card then
							use.card = acard
							return 
						end
					else
						self:useTrickCard(src, use)
						if use.card then
							use.card = acard
							return 
						end
					end
				end
			end
		end
	else
		if #self.opponents > 0 then
			local target = nil
			self:sort(self.opponents, "hp")
			local enemy = self.opponents[1]
			if not enemy:isKongcheng() then
				if self:isWeak(enemy) then
					target = enemy
				end
			end
			if not target then
				self:sort(self.partners_noself, "handcard")
				local index = #self.partners_noself
				target = self.partners_noself[index]
				if target then
					if target:isKongcheng() then 
						target = nil 
					end
				end
			end
			if not target then
				self:sort(self.opponents, "handcard")
				if self.opponents[1] then
					if not self.opponents[1]:isKongcheng() then 
						target = self.opponents[1] 
					else 
						return 
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
	end
end
sgs.ai_skill_cardshow["lexue"] = function(self, requestor)
	local cards = self.player:getHandcards()
	if self:isPartner(requestor) then
		for _, card in sgs.qlist(cards) do
			if card:isKindOf("Peach") and requestor:isWounded() then
				result = card
			elseif card:isNDTrick() then
				result = card
			elseif card:isKindOf("EquipCard") then
				result = card
			elseif card:isKindOf("Slash") then
				result = card
			end
			if result then 
				return result 
			end
		end
	else
		for _, card in sgs.qlist(cards) do
			if card:isKindOf("Jink") then
				result = card
				return result
			elseif card:isKindOf("Nullification") then
				result = card
				return result
			end
		end
	end
	return self.player:getRandomHandCard() 
end
--[[
	套路：仅使用“乐学技能卡”
]]--
sgs.ai_series["LexueCardOnly"] = {
	name = "LexueCardOnly",
	IQ = 2,
	value = 2,
	priority = 5,
	skills = "lexue",
	cards = {
		["LexueCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local lexue_skill = sgs.ai_skills["lexue"]
		local dummyCard = lexue_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["LexueCard"], "LexueCardOnly")
--[[
	技能：殉志
	描述：出牌阶段，你可以摸三张牌并变身为其他未上场或已阵亡的蜀势力角色，回合结束后你死亡。 
]]--
--[[
	内容：注册“殉志技能卡”
]]--
sgs.RegistCard("XunzhiCard")
--[[
	内容：“殉志”技能信息
]]--
sgs.ai_skills["xunzhi"] = {
	name = "xunzhi",
	dummyCard = function(self)
		return sgs.Card_Parse("@XunzhiCard=.")
	end,
	enabled = function(self, handcards)
		return not self.player:hasUsed("XunzhiCard")
	end,
}
--[[
	内容：“殉志技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["XunzhiCard"] = function(self, card, use)
	if self:amLord() then
		return 
	elseif self:amRenegade() then
		return 
	end
	local can_use = false
	if #self.friends > 1 then
		can_use = true
	elseif #self.enemies == 1 then
		if sgs.turncount > 1 then
			can_use = true
		end
	end
	if can_use then
		if self.player:getHp() == 1 then
			if self:getAllPeachNum() == 0 then
				use.card = card
				return 
			end
		end
		if self:amRebel() then
			if self:isWeak() then
				local lord = self.room:getLord()
				if self.player:inMyAttackRange() then
					if self:isEquip("Crossbow") then
						use.card = card
						return 
					end
				end
			end
		end
	end
end
--[[
	套路：仅使用“殉志技能卡”
]]--
sgs.ai_series["XunzhiCardOnly"] = {
	name = "XunzhiCardOnly",
	IQ = 2,
	value = 1,
	priority = 2,
	skills = "xunzhi",
	cards = {
		["XunzhiCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local xunzhi_skill = sgs.ai_skills["xunzhi"]
		local dummyCard = xunzhi_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["XunzhiCard"], "XunzhiCardOnly")
--[[****************************************************************
	武将：倚天·贾文和（群）
]]--****************************************************************
--[[
	技能：洞察
	描述：回合开始阶段开始时，你可以指定一名其他角色：该角色的所有手牌对你处于可见状态，直到你的本回合结束。其他角色都不知道你对谁发动了洞察技能，包括被洞察的角色本身。 
]]--
--[[
	技能：毒士
	描述：杀死你的角色获得技能“崩坏”。 
]]--
sgs.slash_prohibit_system["dushi"] = {
	name = "dushi",
	reason = "dushi",
	judge_func = function(self, target, source, slash)
		--绝情
		if source:hasSkill("jueqing") then
			return false
		end
		--原版解烦
		if source:hasFlag("NosJiefanUsed") then
			return false
		end
		--毒士
		local name = source:objectName()
		if sgs.ai_lord[name] == name then
			local enemies = self:getOpponents(source)
			if #enemies > 1 then
				return true
			end
		end
		return false
	end
}
--[[****************************************************************
	武将：倚天·古之恶来（魏）
]]--****************************************************************
--[[
	技能：死战（锁定技）
	描述：每当你受到一次伤害时，防止此伤害并获得等同于伤害点数的“死战”标记；回合结束阶段开始时，你失去等同于你拥有的“死战”标记数的体力并弃所有的死战标记。 
]]--
--[[
	技能：神力（锁定技）
	描述：出牌阶段，你使用【杀】造成的第一次伤害+X，X为当前死战标记数且最大为3 
]]--
sgs.heavy_slash_system["shenli"] = {
	name = "shenli",
	reason = "shenli",
	extra_func = function(source, slash, target, isFireSlash, isThunderSlash)
		if slash then
			if source:hasFlag("shenli") then
				local mark = source:getMark("@struggle")
				if mark > 0 then
					return math.min(3, mark)
				end
			end
		end
		return 0
	end,
}
--[[****************************************************************
	武将：倚天·邓士载（魏）
]]--****************************************************************
--[[
	技能：争功
	描述：其他角色的回合开始前，若你的武将牌正面朝上，你可以进行一个额外的回合，然后将武将牌翻面。 
]]--
sgs.ai_skill_invoke["zhenggong"] = function(self, data)
	if sgs.turncount <= 1 then
		if #self.enemies == 0 then 
			return false 
		end
	end
	return true
end
--[[
	技能：偷渡
	描述：每当你受到一次伤害后，若你的武将牌背面朝上，你可以弃置一张手牌并将你的武将牌翻面，视为对一名其他角色使用了一张【杀】。 
]]--
sgs.ai_skill_cardask["@toudu"] = function(self, data, pattern, target, target2)
	self.toudu_target = nil
	local targets = sgs.SPlayerList()
	local others = self.room:getOtherPlayers(self.player)
	for _, p in sgs.qlist(others) do
		if self.player:canSlash(p, nil, false) then 
			targets:append(p) 
		end
	end
	if others:isEmpty() then
		return "."
	end
	self.toudu_target = sgs.ai_skill_playerchosen["zero_card_as_slash"](self, targets)
	if self.toudu_target then 
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		for _,card in ipairs(cards) do
			local can_use = true
			if sgs.isCard("Peach", card, self.player) then
				if self:isPartner(self.toudu_target) then
					can_use = false
				end
			end
			if can_use then 
				return card:getEffectiveId() 
			end
		end
	end
	return "."
end
sgs.ai_skill_playerchosen["toudu"] = function(self, targets)
	if self.toudu_target then 
		return self.toudu_target 
	end
	local targetlist = {}
	for _,p in sgs.qlist(targets) do
		if self:willUseSlash(p, self.player, sgs.slash) then
			table.insert(targetlist, p)
		end
	end
	local count = #targetlist
	if count > 0 then
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
		for i=count, 1, -1 do
			if sgs.isGoodTarget(self, targetlist[i], targetlist) then
				return targetlist[i]
			end
		end
		return targetlist[count]
	end
end
sgs.ai_damage_requirement["toudu"] = function(self, attacker, target)
	if target:hasSkill("toudu") then
		if not target:faceUp() then
			local peachCount = sgs.getCardsNum("Peach", target)
			if peachCount > target:getLostHp() then
				if peachCount > 0 then
					return true
				end
			end
			local hp = target:getHp()
			if hp > 1 then
				if self.player:objectName() == target:objectName() then
					for _,enemy in ipairs(self.opponents) do
						if self:isOpponent(enemy) then
							if self:slashIsEffective(sgs.slash, target) then
								if not self:invokeDamagedEffect(enemy, target, sgs.slash) then
									if sgs.getCardsNum("Jink", enemy) < 1 then
										if enemy:getHp() == 1 then
											return true
										elseif enemy:getHp() == 2 then
											if self:hasHeavySlashDamage(target, nil, enemy) then
												return true
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
	return false
end
--[[****************************************************************
	武将：倚天·张公祺（群）
]]--****************************************************************
sgs.ai_chaofeng.zhanggongqi = 4
--[[
	技能：义舍
	描述：出牌阶段，你可将任意数量手牌正面朝上移出游戏称为“米”（至多存在五张）或收回；其他角色在其出牌阶段可选择一张“米”询问你，若你同意，该角色获得这张牌，每阶段限两次 
]]--
--[[
	内容：“义舍要牌技能卡”的卡牌成分
]]--
sgs.card_constituent["YisheAskCard"] = {
	use_priority = 9.1,
}
--[[
	内容：注册“义舍技能卡”、“义舍要牌技能卡”
]]--
sgs.RegistCard("YisheCard")
sgs.RegistCard("YisheAskCard")
--[[
	内容：“义舍”、“义舍要牌”技能信息
]]--
sgs.ai_skills["yishe"] = {
	name = "yishe",
	dummyCard = function(self)
		return sgs.Card_Parse("@YisheCard=.")
	end,
	enabled = function(self, handcards)
		return true
	end,
}
sgs.ai_skills["yisheask"] = {
	name = "yisheask",
	dummyCard = function(self)
		return sgs.Card_Parse("@YisheAskCard=.")
	end,
	enabled = function(self, handcards)
		if self.player:usedTimes("YisheAskCard") < 2 then 
			local others = self.room:getOtherPlayers(self.player)
			for _,ZhangGongQi in sgs.qlist(others) do
				if ZhangGongQi:hasSkill("yishe") then
					local rices = ZhangGongQi:getPile("rice")
					if not rices:isEmpty() then
						return true
					end
				end
			end
		end
		return false
	end,
}
--[[
	内容：“义舍技能卡”、“义舍要牌技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["YisheCard"] = function(self, card, use)
	if self:needBear() then 
		return 
	end
	local rices = self.player:getPile("rice")
	if rices:isEmpty() then
		if self:isKongcheng() then
			return 
		end
		local handcards = self.player:getHandcards()
		local cards = {}
		local overflow = self:getOverflow()
		overflow = math.max(0, overflow)
		local limit = math.min(5, overflow)
		local num = self.player:getHandcardNum()
		if self:needKongcheng() and num < 6 then
			for _, c in sgs.qlist(handcards) do
				table.insert(cards, c:getId())
			end
		else
			local discards = self:askForDiscard("dummyreason", limit, limit)
			for _, c in ipairs(discards) do
				table.insert(cards, c)
			end
		end
		if #cards > 0 then
			local card_str = "@YisheCard="..table.concat(cards, "+")
			local acard = sgs.Card_Parse(card_str)
			use.card = acard
			return 
		end
	else
		if not self.player:hasUsed("YisheCard") then 
			use.card = card 
			return 
		end
	end
end
sgs.ai_skill_use_func["YisheAskCard"] = function(self, card, use)
	local ZhangGongQi = nil
	local rices = nil
	local others = self.room:getOtherPlayers(self.player)
	for _,p in sgs.qlist(others) do
		if p:hasSkill("yishe") then
			rices = p:getPile("rice")
			if not rices:isEmpty() then
				ZhangGongQi = p
				break
			end
		end
	end
	if ZhangGongQi then
		if not self:isOpponent(ZhangGongQi) then
			use.card = card
			return 
		end
	end
end
sgs.ai_skill_choice["yisheask"] = function(self, choices)
	local current = self.room:getCurrent()
	if self:isPartner(current) then 
		return "allow" 
	else 
		return "disallow" 
	end
end
sgs.ai_event_callback[sgs.ChoiceMade].yisheask = function(self, player, data)
	local data_str = data:toString()
	if data_str == "skillChoice:yisheask:allow" then
		local current = self.room:getCurrent()
		sgs.updateIntention(self.player, current, -70)
	end
end
--[[
	套路：仅使用“义舍技能卡”
]]--
sgs.ai_series["YisheCardOnly"] = {
	name = "YisheCardOnly",
	IQ = 2,
	value = 2,
	priority = 5,
	skills = "yishe",
	cards = {
		["YisheCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local yishe_skill = sgs.ai_skills["yishe"]
		local dummyCard = yishe_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["YisheCard"], "YisheCardOnly")
--[[
	套路：仅使用“义舍要牌技能卡”
]]--
sgs.ai_series["YisheAskCardOnly"] = {
	name = "YisheAskCardOnly",
	IQ = 2,
	value = 3,
	priority = 4,
	cards = {
		["YisheAskCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local ask_skill = sgs.ai_skills["yisheask"]
		local dummyCard = ask_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["YisheAskCard"], "YisheAskCardOnly")
--[[
	技能：惜粮
	描述：你可将其他角色弃牌阶段弃置的红牌收为“米”或加入手牌 
]]--
sgs.ai_skill_invoke["xiliang"] = true
sgs.ai_skill_choice["xiliang"] = function(self, choices)	
	if self.player:hasSkill("manjuan") then
		return "put"
	elseif self:needKongcheng(self.player) then 
		return "put" 
	end	
	if not self.player:hasSkill("yishe") then 
		return "obtain" 
	end
	if self:willSkipPlayPhase() then
		if self.player:getHandcardNum() > 2 then 
			return "put" 
		end
	end
	if self.player:getHandcardNum() < 3 then
		return "obtain"
	elseif self:getCardsNum("Jink") < 1 then 
		return "obtain" 
	end
	if self:getOverflow() >= 0 then 
		return "put" 
	end
	return "obtain"
end
--[[****************************************************************
	武将：倚天·倚天剑（魏）
]]--****************************************************************
--[[
	技能：争锋（锁定技）
	描述：当你的装备区没有武器时，你的攻击范围为X，X为你当前体力值。 
]]--
--[[
	技能：镇威
	描述：你的【杀】被手牌中的【闪】抵消时，可立即获得该【闪】。
]]--
sgs.ai_skill_invoke["ytzhenwei"] = function(self, data)
	return not self:needKongcheng(self.player) 
end
--[[
	技能：倚天（联动技）
	描述：当你对曹操造成伤害时，可令该伤害-1 
]]--
sgs.ai_skill_invoke["yitian"] = function(self, data)
	local damage = data:toDamage()
	local CaoCao = damage.to
	return self:isPartner(CaoCao)
end
--[[****************************************************************
	武将：倚天·庞令明（魏）
]]--****************************************************************
--[[
	技能：抬榇
	描述：出牌阶段，你可以失去1点体力或弃置一张武器牌，依次弃置你攻击范围内的一名角色区域内的两张牌。 
]]--
--[[
	内容：“抬榇技能卡”的卡牌成分
]]--
sgs.card_constituent["TaichenCard"] = {
	use_priority = 3.6,
}
--[[
	内容：“抬榇技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["TaichenCard"] = function(self, card, source, targets)
	if #targets > 0 then
		for _,target in ipairs(targets) do
			if target:hasFlag("TaichenOK") then
				target:setFlags("-TaichenOK")
				sgs.updateIntention(source, target, -30)
			else
				sgs.updateIntention(source, target, 30)
			end
		end
	end
end
--[[
	内容：注册“抬榇技能卡”
]]--
sgs.RegistCard("TaichenCard")
--[[
	内容：“抬榇”技能信息
]]--
sgs.ai_skills["taichen"] = {
	name = "taichen",
	dummyCard = function(self)
		return sgs.Card_Parse("@TaichenCard=.")
	end,
	enabled = function(self, handcards)
		return true
	end,
}
--[[
	内容：“抬榇技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["TaichenCard"] = function(self, card, use)
	local weapon = self.player:getWeapon()
	local handcards = self.player:getHandcards()
	local card_str = nil
	local hasWeapon = false
	for _,c in sgs.qlist(handcards) do
		if c:isKindOf("Weapon") then
			hasWeapon = true
			card_str = "@TaichenCard=" .. c:getId()
		end
	end
	local case = false
	if hasWeapon then
		case = true
	elseif self.player:getHp() > 3 then
		case = true
	end
	local targets = {}
	local enemies = {}
	local friends = {}
	local others = self.room:getOtherPlayers(self.player)
	if case then
		if not card_str then
			card_str = "@TaichenCard=."
		end
		for _,p in sgs.qlist(others) do
			if self.player:canSlash(p) then
				table.insert(targets, p)
				if self:isPartner(p) then
					table.insert(friends, p)
				elseif not self:doNotDiscard(p, "he", nil, 2) then
					table.insert(enemies, p)
				end
			end
		end
	else
		if weapon then
			card_str = "@TaichenCard=" .. weapon:getId()
		end
		for _,p in sgs.qlist(others) do
			if self.player:distanceTo(p) <= 1 then
				table.insert(targets, p)
				if self:isPartner(p) then
					table.insert(friends, p)
				elseif not self:doNotDiscard(p, "he", nil, 2) then
					table.insert(enemies, p)
				end
			end
		end
	end
	if #targets > 0 then
		local target = nil
		for _, p in ipairs(targets) do
			if not p:containsTrick("YanxiaoCard") then
				if p:containsTrick("lightning") then
					if self:getFinalRetrial(p) == 2 then 
						target = p
						break
					end
				end
			end
		end
		if not target then
			if #friends > 0 then
				for _, friend in ipairs(friends) do					
					if not friend:containsTrick("YanxiaoCard") then
						if not friend:hasSkill("qiaobian") or friend:isKongcheng() then
							if friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage") then 
								target = friend 
								break 
							end
						end
					end
					if friend:getCards("e"):length() > 1 then
						if self:hasSkills(sgs.lose_equip_skill, friend) then 
							target = friend 
							break
						end
					end
				end
			end
		end	
		if not target then
			if #enemies > 0 then
				self:sort(enemies, "defense")
				for _, enemy in ipairs(enemies) do
					if enemy:containsTrick("YanxiaoCard") then
						if enemy:containsTrick("indulgence") or enemy:containsTrick("supply_shortage") then
							target = enemy 
							break
						end
					end
					if self:getDangerousCard(enemy) then 
						target = enemy 
						break
					end
					if not (enemy:hasSkill("tuntian") and enemy:hasSkill("zaoxian")) then
						target = enemy 
						break
					end
				end
			end
		end
		if target then
			if not card_str then
				if self:isPartner(target) then
					if self.player:getHp() > 2 then 
						card_str = "@TaichenCard=." 
					end
				end
			end
			if card_str then
				use.card = sgs.Card_Parse(card_str)
				if use.to then
					if self:isPartner(target) then
						target:setFlags("TaichenOK")
					end
					use.to:append(target)
				end
			end
		end
	end
end
sgs.taichen_keep_value = sgs.qiangxi_keep_value
--[[
	内容：“抬榇”卡牌需求
]]--
sgs.card_need_system["taichen"] = sgs.card_need_system["weapon"]
--[[
	套路：仅使用“抬榇技能卡”
]]--
sgs.ai_series["TaichenCardOnly"] = {
	name = "TaichenCardOnly",
	IQ = 2,
	value = 3,
	priority = 3,
	skills = "taichen",
	cards = {
		["TaichenCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local taichen_skill = sgs.ai_skills["taichen"]
		local dummyCard = taichen_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["TaichenCard"], "TaichenCardOnly")