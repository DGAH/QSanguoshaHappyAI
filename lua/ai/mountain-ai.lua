--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）山扩展包部分
]]--
--[[****************************************************************
	武将：山·张郃（魏）
]]--****************************************************************
--[[
	技能：巧变
	描述：你可以弃置一张手牌，跳过你的一个阶段（准备阶段和结束阶段除外）。若以此法跳过摸牌阶段，你获得至多两名其他角色的各一张手牌；若以此法跳过出牌阶段，你可以将场上的一张牌移动到另一名角色区域里的相应位置。 
]]--
--[[
	内容：“巧变技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["QiaobianCard"] = function(self, card, source, targets)
	if source:getMark("qiaobianPhase") == 3 then
		sgs.ai_card_intention["TuxiCard"](self, card, source, targets)
	end
end
--[[
	功能：获取巧变信息
	参数：who（ServerPlayer类型）
		prompt（string类型，表示信息类型："target"为巧变目标、"card"为巧变弃牌）
	结果：ServerPlayer类型（target，表示巧变目标）或Card类型（card，表示巧变弃牌）
]]--
function SmartAI:getQiaobianDetail(who, prompt)
	local card, target
	if self:isPartner(who) then
		local judges = who:getJudgingArea()
		if not judges:isEmpty() then
			if not who:containsTrick("YanxiaoCard") then
				for _,judge in sgs.qlist(judges) do
					local id = judge:getEffectiveId()
					card = sgs.Sanguosha:getCard(id)
					for _,enemy in ipairs(self.opponents) do
						if not enemy:containsTrick(judge:objectName()) then
							if not self.room:isProhibited(self.player, enemy, judge) then
								if not enemy:containsTrick("YanxiaoCard") then
									target = enemy
									break
								end
							end
						end
					end
					if target then 
						break 
					end
				end
			end
		end
		local equips = who:getCards("e")
		local weak = self:isWeak(who)
		if not target then
			if not equips:isEmpty() then
				if self:hasSkills(sgs.lose_equip_skill, who) then
					for _, equip in sgs.qlist(equips) do
						if equip:isKindOf("OffensiveHorse") then 
							card = equip 
							break
						elseif equip:isKindOf("Weapon") then 
							card = equip 
							break
						elseif equip:isKindOf("DefensiveHorse") then
							if not weak then
								card = equip
								break
							end
						elseif equip:isKindOf("Armor") then
							if not weak then
								card = equip
								break
							elseif equip:isKindOf("SilverLion") then
								card = equip
								break
							end
						end
					end
				end
				if card then
					if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then 
						self:sort(self.partners, "defense")
					else
						self:sort(self.partners, "handcard")
						self.partners = sgs.reverse(self.partners)
					end
					local skills = sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill
					for _, friend in ipairs(self.partners) do
						if friend:objectName() ~= who:objectName() then
							if not self:getSameTypeEquip(card, friend) then
								if self:hasSkills(skills, friend) then
									target = friend
									break
								end
							end
						end
					end
					if not target then
						for _, friend in ipairs(self.partners) do
							if friend:objectName() ~= who:objectName() then
								if not self:getSameTypeEquip(card, friend) then
									target = friend
									break
								end
							end
						end
					end
				end
			end
		end
	else
		local judges = who:getJudgingArea()
		if who:containsTrick("YanxiaoCard") then
			for _,judge in sgs.qlist(judges) do
				if judge:isKindOf("YanxiaoCard") then
					local id = judge:getEffectiveId()
					card = sgs.Sanguosha:getCard(id)
					for _,friend in ipairs(self.partners) do
						if not friend:containsTrick(judge:objectName()) then
							if not self.room:isProhibited(self.player, friend, judge) then 
								if not friend:getJudgingArea():isEmpty() then
									target = friend
									break
								end
							end
						end
					end
					if target then 
						break 
					end
					for _, friend in ipairs(self.partners) do
						if not friend:containsTrick(judge:objectName()) then
							if not self.room:isProhibited(self.player, friend, judge) then
								target = friend
								break
							end
						end
					end
					if target then 
						break 
					end
				end
			end
		end
		if card == nil or target == nil then
			if not who:hasEquip() then
				return nil
			elseif self:hasSkills(sgs.lose_equip_skill, who) then 
				return nil 
			end
			local card_id = self:askForCardChosen(who, "e", "snatch")
			if card_id >= 0 then
				local equip = sgs.Sanguosha:getCard(card_id)
				if who:hasEquip(equip) then 
					card = equip
				end
			end
			if card then
				if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then 
					self:sort(self.partners, "defense")
				else
					self:sort(self.partners, "handcard")
					self.partners = sgs.reverse(self.partners)
				end
				for _, friend in ipairs(self.partners) do
					if friend:objectName() ~= who:objectName() then
						if not self:getSameTypeEquip(card, friend) then
							if self:hasSkills(sgs.lose_equip_skill .. "|shensu" , friend) then
								target = friend
								break
							end
						end
					end
				end
				if not target then
					for _, friend in ipairs(self.friends) do
						if friend:objectName() ~= who:objectName() then
							if not self:getSameTypeEquip(card, friend) then
								target = friend
								break
							end
						end
					end
				end
			end			
		end
	end
	if prompt == "card" then
		return card
	elseif prompt == "target" then
		return target
	end
	return card and target
end
sgs.ai_skill_discard["qiaobian"] = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local handcards = self.player:getHandcards()
	local cards = sgs.QList2Table(handcards)
	self:sortByUseValue(cards, true)
	local stealer
	local others = self.room:getOtherPlayers(self.player)
	for _, p in sgs.qlist(others) do
		if p:hasSkill("tuxi") then
			if self:isOpponent(p) then 
				stealer = p
			end
		end
	end
	local card = nil
	for i=1, #cards, 1 do
		local isPeach = cards[i]:isKindOf("Peach")
		if isPeach then
			if stealer then
				if self.player:getHandcardNum() <= 2 then
					if self.player:getHp() > 2 then
						if not stealer:containsTrick("supply_shortage") then
							card = cards[i]
							break
						elseif stealer:containsTrick("YanxiaoCard") then
							card = cards[i]
							break
						end
					end
				end
			end
			local to_discard_peach = true
			for _,p in ipairs(self.partners) do
				if p:getHp() <= 2 then
					if not p:hasSkill("niepan") then
						to_discard_peach = false
					end
				end
			end
			if to_discard_peach then
				card = cards[i]
				break
			end
		else
			card = cards[i]
			break
		end
	end
	if card == nil then 
		return {} 
	end
	table.insert(to_discard, card:getEffectiveId())
	local phase = self.player:getMark("qiaobianPhase")
	if phase == sgs.Player_Judge then
		if not self.player:isSkipped(sgs.Player_Judge) then
			if not self.player:containsTrick("YanxiaoCard") then
				if self.player:containsTrick("lightning") then
					if #self.partners > #self.opponents then
						return to_discard
					elseif not self:hasWizard(self.partners) then
						if self:hasWizard(self.opponents) then
							return to_discard
						end
					end
				end
				if self.player:containsTrick("supply_shortage") then
					if self.player:getHp() > self.player:getHandcardNum() then 
						return to_discard 
					end
					local card_str = sgs.ai_skill_use["@@tuxi"](self, "@tuxi")
					if card_str:match("->") then
						local target_str = card_str:split("->")[2]
						local targets = target_str:split("+")
						if #targets == 2 then
							return to_discard
						end
					end
				end
				if self.player:containsTrick("indulgence") then 
					if self.player:getHandcardNum() > 3 then
						return to_discard
					elseif self.player:getHandcardNum() > self.player:getHp() - 1 then 
						return to_discard 
					end
					for _, friend in ipairs(self.partners_noself) do
						if not friend:containsTrick("YanxiaoCard") then
							if friend:containsTrick("indulgence") then
								return to_discard
							elseif friend:containsTrick("supply_shortage") then
								return to_discard
							end
						end
					end
				end
			end
		end
	elseif phase == sgs.Player_Draw then
		if not self.player:isSkipped(sgs.Player_Draw) then
			if not self.player:hasSkill("tuxi") then
				local card_str = sgs.ai_skill_use["@@tuxi"](self, "@tuxi")
				if card_str:match("->") then
					local target_str = card_str:split("->")[2]
					local targets = target_str:split("+")
					if #targets == 2 then
						return to_discard
					end
				end
			end
		end
	elseif phase == sgs.Player_Play then
		if not self.player:isSkipped(sgs.Player_Play) then
			self:sortByKeepValue(cards)
			table.remove(to_discard)
			table.insert(to_discard, cards[1]:getEffectiveId())
			self:sort(self.opponents, "defense")
			self:sort(self.partners, "defense")
			self:sort(self.partners_noself, "defense")
			for _,friend in ipairs(self.partners) do
				if not friend:getCards("j"):isEmpty() then
					if not friend:containsTrick("YanxiaoCard") then
						if self:getQiaobianDetail(friend, ".") then
							return to_discard
						end
					end
				end
			end
			for _,enemy in ipairs(self.opponents) do
				if not enemy:getCards("j"):isEmpty() then
					if enemy:containsTrick("YanxiaoCard") then
						if self:getQiaobianDetail(enemy, ".") then
							return to_discard
						end
					end
				end
			end
			for _,friend in ipairs(self.partners_noself) do
				if not friend:getCards("e"):isEmpty() then
					if self:hasSkills(sgs.lose_equip_skill, friend) then
						if self:getQiaobianDetail(friend, ".") then
							return to_discard
						end
					end
				end
			end
			local top_value = 0
			for _,c in ipairs(cards) do
				if not c:isKindOf("Jink") then
					local name = sgs.getCardName(c)
					local value = sgs.getCardValue(name, "use_value")
					if value > top_value then	
						top_value = value
					end
				end
			end
			if top_value >= 3.7 then
				if self:getTurnUseCard(handcards) then 
					return {} 
				end
			end
			local targets = {}
			for _, enemy in ipairs(self.opponents) do
				if not self:hasSkills(sgs.lose_equip_skill, enemy) then
					if self:getQiaobianDetail(enemy, ".") then
						table.insert(targets, enemy)
					end
				end
			end
			if #targets > 0 then
				--self:sort(targets, "defense")
				return to_discard
			end
		end
	elseif phase == sgs.Player_Discard then
		if not self.player:isSkipped(sgs.Player_Discard) then
			if self:needBear() then 
				return {}
			end
			self:sortByKeepValue(cards)
			table.remove(to_discard)
			table.insert(to_discard, cards[1]:getEffectiveId())
			if self.player:getHandcardNum() - 1 > self.player:getHp() then
				return to_discard
			end
		end
	end
	return {}
end
sgs.ai_skill_cardchosen["qiaobian"] = function(self, who, flags)
	if flags == "ej" then
		return self:getQiaobianDetail(who, "card")
	end
end
sgs.ai_skill_playerchosen["qiaobian"] = function(self, targets)
	local tag = self.room:getTag("QiaobianTarget")
	local who = tag:toPlayer()
	if who then
		local target = self:getQiaobianDetail(who, "target")
		if target then
			return target
		else
			self.room:writeToConsole("NULL")
		end
	end
end
sgs.ai_skill_use["@qiaobian"] = function(self, prompt)
	self:updatePlayers()
	local handcards = self.player:getHandcards()
	local cards = sgs.QList2Table(handcards)
	self:sortByUseValue(cards, true)
	local card = cards[1]
	if prompt == "@qiaobian-2" then
		local card_str = sgs.ai_skill_use["@@tuxi"](self, "@tuxi")
		if card_str:match("->") then
			local target_str = card_str:split("->")[2]
			return "@QiaobianCard=.->" .. target_str
		else
			return "."
		end
	elseif prompt == "@qiaobian-3" then
		self:sort(self.opponents, "defense")
		for _,friend in ipairs(self.partners) do
			if not friend:getCards("j"):isEmpty() then
				if not friend:containsTrick("YanxiaoCard") then
					if self:getQiaobianDetail(friend, ".") then
						return "@QiaobianCard=.->".. friend:objectName()
					end
				end
			end
		end
		for _,enemy in ipairs(self.opponents) do
			if not enemy:getCards("j"):isEmpty()then
				if enemy:containsTrick("YanxiaoCard") then
					if self:getQiaobianDetail(enemy, ".") then
						return "@QiaobianCard=.->".. enemy:objectName()
					end
				end
			end
		end
		for _,friend in ipairs(self.partners_noself) do
			if not friend:getCards("e"):isEmpty() then
				if self:hasSkills(sgs.lose_equip_skill, friend) then
					if self:getQiaobianDetail(friend, ".") then
						return "@QiaobianCard=.->".. friend:objectName()
					end
				end
			end
		end
		local top_value = 0
		for _,c in ipairs(cards) do
			if not c:isKindOf("Jink") then
				local name = sgs.getCardName(c)
				local value = sgs.getCardValue(name, "use_value")
				if value > top_value then	
					top_value = value
				end
			end
		end
		if top_value >= 3.7 then
			if self:getTurnUseCard(handcards) then 
				return "." 
			end
		end
		local targets = {}
		for _,enemy in ipairs(self.opponents) do
			if self:getQiaobianDetail(enemy, ".") then
				table.insert(targets, enemy)
			end
		end		
		if #targets > 0 then
			self:sort(targets, "defense")
			return "@QiaobianCard=.->".. targets[#targets]:objectName()
		end
	end
	return "."
end
--[[
	内容：“巧变”卡牌需求
]]--
sgs.card_need_system["qiaobian"] = function(self, card, player)
	local cards = player:getCards("h")
	return cards:length() <= 2
end
--[[****************************************************************
	武将：山·邓艾（魏）
]]--****************************************************************
--[[
	技能：屯田
	描述：你的回合外，每当你失去牌后，你可以进行一次判定，当非♥的判定牌生效后，你将此牌置于你的武将牌上，称为“田”；锁定技，你与其他角色的距离-X。（X为“田”的数量） 
]]--
sgs.ai_skill_invoke["tuntian"] = function(self, data)
	if self.player:hasSkill("zaoxian") then
		if #self.opponents == 1 then
			if self.room:alivePlayerCount() == 2 then
				if self.player:getMark("zaoxian") == 0 then
					if self:hasSkills("noswuyan|qianxun", self.opponents[1]) then
						return false
					end
				end
			end
		end
	end
	return true
end
sgs.slash_prohibit_system["tuntian"] = {
	name = "tuntian",
	reason = "tuntian+zaoxian",
	judge_func = function(self, target, source, slash)
		--友方
		if self:isPartner(target) then 
			return false 
		end
		--铁骑
		if source:hasSkill("tieji") then
			return false
		end
		--烈弓
		if self:canLiegong(target, source) then
			return false
		end
		--屯田
		local enemies = self:getOpponents(target)
		if #enemies == 1 then
			if self.room:alivePlayerCount() == 2 then
				if self:hasSkills("noswuyan|qianxun|weimu", source) then 
					return false 
				end
			end
		end
		--缺闪
		if sgs.getCardsNum("Jink", target) < 1 then
			return false
		elseif sgs.card_lack[target:objectName()]["Jink"] == 1 then
			return false
		--虚弱
		elseif self:isWeak(target) then 
			return false 
		end
		--凿险
		if target:getHandcardNum() >= 3 then
			return true
		end
		return false
	end
}
--[[
	技能：凿险（觉醒技）
	描述：准备阶段开始时，若“田”的数量达到3或更多，你减1点体力上限，然后获得技能“急袭”（你可以将一张“田”当【顺手牵羊】使用）。 
]]--
--[[
	技能：急袭
	描述：你可以将一张“田”当【顺手牵羊】使用
]]--
--[[
	内容：注册“急袭顺手牵羊”
]]--
sgs.RegistCard("jixi>>Snatch")
--[[
	内容：“急袭”技能信息
]]--
sgs.ai_skills["jixi"] = {
	name = "jixi",
	dummyCard = function(self)
		local suit = sgs.snatch:getSuitString()
		local number = sgs.snatch:getNumberString()
		local card_id = sgs.snatch:getEffectiveId()
		local card_str = ("snatch:jixi[%s:%s]=%d"):format(suit, number, card_id)
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		local fields = self.player:getPile("field")
		if fields:isEmpty() then
			return false
		end
		return true
	end,
}
--[[
	内容：“急袭顺手牵羊”的具体产生方式
]]--
sgs.ai_view_as_func["jixi>>Snatch"] = function(self, card)
	local num = self.player:getHandcardNum()
	local hp = self.player:getHp()
	local fields = self.player:getPile("field")
	local alives = self.room:getAlivePlayers()
	if num >= hp + 2 then
		if fields:length() <= alives:length() / 2 - 1 then
			return 
		end
	end
	local can_use = false
	local others = self.room:getOtherPlayers(self.player)
	local limit = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, snatch)
	for i=0, fields:length()-1, 1 do
		local field_id = fields:at(i)
		local field = sgs.Sanguosha:getCard(field_id)
		local suit = field:getSuitString()
		local point = field:getNumberString()
		local card_str = ("snatch:jixi[%s:%s]=%d"):format(suit, point, field_id)
		local snatch = sgs.Card_Parse(card_str)
		for _,player in sgs.qlist(others) do
			local distance = self.player:distanceTo(player, 1)
			if distance <= limit then
				if not self.room:isProhibited(self.player, player, snatch) then
					if self:trickIsEffective(snatch, player, self.player) then
						return snatch
					end
				end
			end
		end
	end
end
sgs.ai_view_as["jixi"] = function(card, player, place, class_name)
	if place == sgs.Player_PlaceSpecial then
		if player:getPileName(card_id) == "field" then
			local suit = card:getSuitString()
			local number = card:getNumberString()
			local card_id = card:getEffectiveId()
			return ("snatch:jixi[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end
--[[
	套路：仅使用“急袭顺手牵羊”
]]--
sgs.ai_series["jixi>>SnatchOnly"] = {
	name = "jixi>>SnatchOnly",
	IQ = 2,
	value = 3,
	priority = 2,
	skills = "jixi",
	cards = {
		["jixi>>Snatch"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local jixi_skill = sgs.ai_skills["jixi"]
		local dummyCard = jixi_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["jixi>>Snatch"], "jixi>>SnatchOnly")
--[[****************************************************************
	武将：山·姜维（蜀）
]]--****************************************************************
--[[
	技能：挑衅
	描述：出牌阶段限一次，你可以选择一名攻击范围内含有你的其他角色，该角色需对你使用一张【杀】，否则你弃置其一张牌。 
]]--
--[[
	功能：判断一名角色是否适合作为挑衅的目标
	参数：target（ServerPlayer类型，表示被挑衅的目标）
	结果：boolean类型，表示是否适合
]]--
function SmartAI:isTiaoxinTarget(target)
	if target then	
		if sgs.getCardsNum("Slash", target) < 1 then
			if self.player:getHp() > 1 then
				--if not self:canHit(self.player, target) then
					if target:hasWeapon("DoubleSword") then
						if self.player:getGender() ~= target:getGender() then
							return false
						end
					end
					return true
				--end
			end
		end
		if sgs.card_lack[target:objectName()]["Slash"] == 1 then
			return true
		elseif self:canLeiji(self.player, target) then
			return true
		elseif self:invokeDamagedEffect(self.player, target, sgs.slash) then
			return true
		elseif self:needToLoseHp(self.player, target, true) then
			return true 
		end
	else
		self.room:writeToConsole(debug.traceback())
	end
	return false
end
--[[
	内容：“挑衅技能卡”的卡牌成分
]]--
sgs.card_constituent["TiaoxinCard"] = {
	use_priority = 5.9,
}
--[[
	内容：“挑衅技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["TiaoxinCard"] = 80
--[[
	内容：注册“挑衅技能卡”
]]--
sgs.RegistCard("TiaoxinCard")
--[[
	内容：“挑衅”技能信息
]]--
sgs.ai_skills["tiaoxin"] = {
	name = "tiaoxin",
	dummyCard = function(self)
		return sgs.Card_Parse("@TiaoxinCard=.")
	end,
	enabled = function(self, handcards)
		if self.player:hasUsed("TiaoxinCard") then
			return false
		end
		return true
	end
}
sgs.ai_skill_use_func["TiaoxinCard"] = function(self, card, use)
	local rangefix = use.DefHorse and 1 or 0
	local targets = {}
	for _, enemy in ipairs(self.opponents) do
		local distance = enemy:distanceTo(self.player, rangefix)
		local range = enemy:getAttackRange()
		if distance <= range then
			if not self:doNotDiscard(enemy) then
				if self:isTiaoxinTarget(enemy) then
					table.insert(targets, enemy)
				end
			end
		end
	end
	if #targets > 0 then
		use.card = card
		if use.to then
			self:sort(targets, "defenseSlash")
			use.to:append(targets[1])
		end
	end
end
sgs.ai_skill_cardask["@tiaoxin-slash"] = function(self, data, pattern, target)
	if target then
		local slashes = self:getCards("Slash")
		for _, slash in ipairs(slashes) do
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
					if not self:invokeDamagedEffect(target, self.player, true) then
						if not self:canLeiji(target, self.player) then
							return slash:toString()
						end
					end
				end
			end
		end
		for _, slash in ipairs(slashes) do
			if not self:isPartner(target) then
				if not self:canLeiji(target, self.player) then
					if not self:invokeDamagedEffect(target, self.player, true) then 
						return slash:toString() 
					end
				end
				if not self:slashIsEffective(slash, target) then 
					return slash:toString() 
				end			
			end
		end
	end
	return "."
end
--[[
	套路：仅使用“挑衅技能卡”
]]--
sgs.ai_series["TiaoxinCardOnly"] = {
	name = "TiaoxinCardOnly",
	IQ = 2,
	value = 3,
	priority = 4,
	skills = "tiaoxin",
	cards = {
		["TiaoxinCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local tiaoxin_skill = sgs.ai_skills["tiaoxin"]
		local dummyCard = tiaoxin_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["TiaoxinCard"], "TiaoxinCardOnly")
--[[
	技能：志继（觉醒技）
	描述：准备阶段开始时，若你没有手牌，你选择一项：1.回复1点体力；2.摸两张牌。然后你减1点体力上限，获得技能“观星”。 
]]--
sgs.ai_skill_choice["zhiji"] = function(self, choice)
	local hp = self.player:getHp()
	local maxhp = self.player:getMaxHp()
	if hp < maxhp - 1 then
		return "recover"
	else
		return "draw"
	end
end
--[[****************************************************************
	武将：山·刘禅（蜀）
]]--****************************************************************
--[[
	技能：享乐（锁定技）
	描述：每当你成为一名角色使用【杀】的目标时，该角色需弃置一张基本牌，否则此【杀】对你无效。 
]]--
sgs.ai_skill_cardask["@xiangle-discard"] = function(self, data)
	local target = data:toPlayer()
	if self:isPartner(target) then
		local flag = true
		if target:hasSkill("leiji") then
			if sgs.getCardsNum("Jink", target) > 0 then
				flag = false
			elseif not self:isWeak(target) then
				if self:hasEightDiagramEffect(target) then
					flag = false
				end
			end
		end
		if flag then 
			return "." 
		end
	end
	local has_peach, has_anal, has_slash, has_jink
	local handcards = self.player:getHandcards()
	for _, card in sgs.qlist(handcards) do
		if card:isKindOf("Peach") then 
			has_peach = card
		elseif card:isKindOf("Analeptic") then 
			has_anal = card
		elseif card:isKindOf("Slash") then 
			has_slash = card
		elseif card:isKindOf("Jink") then 
			has_jink = card
		end
	end
	if has_slash then 
		return "$" .. has_slash:getEffectiveId()
	elseif has_jink then 
		return "$" .. has_jink:getEffectiveId()
	elseif has_anal or has_peach then
		if sgs.getCardsNum("Jink", target) == 0 then
			if self.player:getMark("drank") > 0 then
				if self:getAllPeachNum(target) == 0 then
					if has_anal then 
						return "$" .. has_anal:getEffectiveId()
					else 
						return "$" .. has_peach:getEffectiveId()
					end
				end
			end
		end
	end
	return "."
end
sgs.slash_prohibit_system["xiangle"] = {
	name = "xiangle",
	reason = "xiangle",
	judge_func = function(self, target, source, slash)
		--友方
		if self:isPartner(target, source) then
			return false
		end
		--享乐
		local slash_num, anal_num, jink_num
		if source:objectName() == self.player:objectName() then
			slash_num = self:getCardsNum("Slash")
			anal_num = self:getCardsNum("Analeptic")
			jink_num = self:getCardsNum("Jink")
		else
			slash_num = sgs.getCardsNum("Slash", source)
			anal_num = sgs.getCardsNum("Analpetic", source)
			jink_num = sgs.getCardsNum("Jink", source)
		end
		if self.player:getHandcardNum() == 2 then
			if self.player:hasSkill("beifa") then 
				self.player:setFlags("stack_overflow_xiangle") 
			end
			local needkongcheng = self:needKongcheng()
			self.player:setFlags("-stack_overflow_xiangle")
			if needkongcheng then 
				return slash_num + anal_num + jink_num < 2 
			end
		end
		if slash_num + anal_num + math.max(jink_num - 1, 0) < 2 then
			return true
		end
		return false
	end
}
--[[
	技能：放权
	描述：你可以跳过你的出牌阶段，若如此做，此回合结束时，你可以弃置一张手牌并选择一名其他角色，令其获得一个额外的回合。 
]]--
sgs.ai_playerchosen_intention["fangquan"] = function(self, source, target)
	sgs.fangquan_effect = false
	local intention = -10
	if target:hasSkill("benghuai") then
		sgs.fangquan_effect = true
		intention = 0
	end
	sgs.updateIntention(source, target, intention)
end
sgs.ai_skill_invoke["fangquan"] = function(self, data)
	if #self.partners > 1 then
		local handcards = self.player:getHandcards()
		local cards = sgs.QList2Table(handcards)
		local shouldUse, range_fix = 0, 0
		local hasCrossbow, slashTo = false, false
		for _, card in ipairs(cards) do
			if card:isKindOf("TrickCard") then
				if sgs.getUseValue(card, self.player) > 3.69 then
					local dummy_use = { 
						isDummy = true, 
					}
					self:useTrickCard(card, dummy_use)
					if dummy_use.card then 
						if card:isKindOf("ExNihilo") then
							shouldUse = shouldUse + 2
						else
							shouldUse = shouldUse + 1
						end
					end
				end
			elseif card:isKindOf("Weapon") then
				local new_range = sgs.weapon_range[card:getClassName()]
				local current_range = self.player:getAttackRange()
				range_fix = math.min(current_range - new_range, 0)
			elseif card:isKindOf("OffensiveHorse") then
				if not self.player:getOffensiveHorse() then 
					range_fix = range_fix - 1 
				end
			elseif sgs.isKindOf("DefensiveHorse|Armor", card) then
				if not self:getSameTypeEquip(card) then
					if self:isWeak() or self:getCardsNum("Jink") == 0 then 
						shouldUse = shouldUse + 1 
					end
				end
			end
			if card:isKindOf("Crossbow") then
				hasCrossbow = true 
			elseif self:hasCrossbowEffect() then 
				hasCrossbow = true 
			end
		end
		local slashes = self:getCards("Slash")
		for _, enemy in ipairs(self.opponents) do
			for _, slash in ipairs(slashes) do
				if hasCrossbow then
					if self:getCardsNum("Slash") > 1 then
						if self:slashIsEffective(slash, enemy) then
							if self.player:canSlash(enemy, slash, true, range_fix) then
								shouldUse = shouldUse + 2
								hasCrossbow = false
								break
							end
						end
					end
				end
				if not slashTo then
					if sgs.slash:isAvailable(self.player) then
						if self:slashIsEffective(slash, enemy) then
							if self.player:canSlash(enemy, slash, true, range_fix) then
								if sgs.getCardsNum("Jink", enemy) < 1 then
									shouldUse = shouldUse + 1
									slashTo = true
								end
							end
						end
					end
				end
			end
		end
		if shouldUse >= 2 then 
			return false
		end
		local limit = self.player:getMaxCards()
		if self.player:isKongcheng() then 
			return false 
		end
		if self:getCardsNum("Peach") >= limit - 2 then
			if self.player:isWounded() then 
				return false 
			end
		end
		local to_discard = {}
		local index = 0
		local all_peaches = 0
		for _, card in ipairs(cards) do
			if sgs.isCard("Peach", card, self.player) then
				all_peaches = all_peaches + 1
			end
		end
		if all_peaches >= 2 then
			if self:getOverflow() <= 0 then 
				return {} 
			end
		end
		self:sortByKeepValue(cards)
		cards = sgs.reverse(cards)
		for i = #cards, 1, -1 do
			local card = cards[i]
			if not sgs.isCard("Peach", card, self.player) then
				if not self.player:isJilei(card) then
					table.insert(to_discard, card:getEffectiveId())
					table.remove(cards, i)
					break
				end
			end
		end
		return #to_discard > 0
	end
	return false
end
sgs.ai_skill_discard["fangquan"] = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummyreason", 1, 1, false, false)
end
sgs.ai_skill_playerchosen["fangquan"] = function(self, targets)
	self:sort(self.partners_noself, "handcard")
	self.partners_noself = sgs.reverse(self.partners_noself)
	for _, target in ipairs(self.partners_noself) do
		if not target:hasSkill("dawu") then
			if self:hasSkills("yongsi", target) then
				if not self:willSkipPlayPhase(target) then
					if not self:willSkipDrawPhase(target) then
						return target
					end
				end
			end
		end
	end
	for _, target in ipairs(self.partners_noself) do
		if not target:hasSkill("dawu") then
			if self:hasSkills("zhiheng|shensu|"..sgs.priority_skill, target) then
				if not self:willSkipPlayPhase(target) then
					if not self:willSkipDrawPhase(target) then
						return target
					end
				end
			end
		end
	end
	for _, target in ipairs(self.partners_noself) do
		if not target:hasSkill("dawu") then
			return target
		end
	end
	if #self.partners_noself > 0 then 
		return self.partners_noself[1] 
	end
	if not targets:isEmpty() then
		return targets:first()
	end
end
--[[
	技能：若愚（主公技，觉醒技）
	描述：准备阶段开始时，若你是当前的体力值最小的角色（或之一），你加1点体力上限，回复1点体力，然后获得技能“激将”。 
]]--
--[[****************************************************************
	武将：山·孙策（吴）
]]--****************************************************************
--[[
	技能：激昂
	描述：每当你使用一张【决斗】或红色的【杀】指定目标后，或成为一张【决斗】或红色的【杀】的目标后，你可以摸一张牌。 
]]--
--[[
	内容：“激昂”卡牌需求
]]--
sgs.card_need_system["jiang"] = function(self, card, player)
	if sgs.isCard("Duel", card, player) then
		return true
	elseif card:isRed() then
		return sgs.isCard("Slash", card, player)
	end
	return false
end
--[[
	技能：魂姿（觉醒技）
	描述：准备阶段开始时，若你当前的体力值为1，你减1点体力上限，然后获得技能“英姿”和“英魂”。 
]]--
sgs.ai_damage_requirement["hunzi"] = function(self, source, target)
	if target:hasSkill("hunzi") then
		if target:getMark("hunzi") == 0 then
			local hp = target:getHp()
			local current = self.room:getCurrent()
			if self:getEnemyNumBySeat(current, target, target, true) < hp then
				local need = false
				if hp > 2 then
					need = true
				elseif hp == 2 then
					if target:faceUp() then
						need = true
					elseif target:hasSkill("guixin") then
						need = true
					elseif target:hasSkill("toudu") then
						if not target:isKongcheng() then
							need = true
						end
					end
				end
				if need then
					return true
				end
			end
		end
	end
	return false
end
--[[
	内容：“魂姿”最优体力
]]--
sgs.best_hp_system["hunzi"] = {
	name = "hunzi",
	reason = "hunzi",
	best_hp = function(player, maxhp, isLord)
		if player:getMark("hunzi") == 0 then
			return 2
		end
	end,
}
--[[
	技能：制霸（主公技）
	描述：出牌阶段限一次，其他吴势力角色的出牌阶段可以与你拼点（“魂姿”发动后，你可以拒绝此拼点）。若其没赢，你可以获得两张拼点的牌。 
]]--
--[[
	内容：“制霸技能卡”的卡牌成分
]]--
sgs.card_constituent["ZhibaCard"] = {
	use_priority = 0,
}
--[[
	内容：“制霸技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["ZhibaCard"] = 0
--[[
	内容：注册“制霸技能卡”
]]--
sgs.RegistCard("ZhibaCard")
--[[
	内容：“制霸拼点”技能信息
]]--
sgs.ai_skills["zhiba_pindian"] = {
	name = "zhiba_pindian",
	dummyCard = function(self)
		return sgs.Card_Parse("@ZhibaCard=.")
	end,
	enabled = function(self, handcards)
		if #handcards > 0 then
			if self.player:getKingdom() == "wu" then
				if self.player:hasFlag("ForbidZhiba") then
					return false
				end
				return true
			end
		end
		return false
	end,
}
sgs.ai_skill_use_func["ZhibaCard"] = function(self, card, use)
	local lords = {}
	local others = self.room:getOtherPlayers(self.player)
	for _,lord in sgs.qlist(others) do
		if lord:hasLordSkill("zhiba") then
			if not lord:isKongcheng() then
				if not lord:hasFlag("ZhibaInvoked") then
					table.insert(lords, lord)
				end
			end
		end
	end
	local targets = {}
	for _,lord in ipairs(lords) do
		if lord:getMark("hunzi") == 0 then
			table.insert(targets, lord)
		elseif not self:isOpponent(lord) then
			table.insert(targets, lord)
		end
	end
	if #targets > 0 then
		self:sort(targets, "defense")
		local cards = self.player:getHandcards()
		local max_num = 0, max_card
		local min_num = 14, min_card
		for _, c in sgs.qlist(cards) do
			local point = c:getNumber()
			if point > max_num then
				max_num = point
				max_card = c
			end
			if point <= min_num then
				if point == min_num then
					if min_card then
						if sgs.getKeepValue(c, self.player) > sgs.getKeepValue(min_card, self.player) then
							min_num = c:getNumber()
							min_card = c
						end
					end
				else
					min_num = point
					min_card = c
				end
			end
		end
		local current = global_room:getCurrent()
		for _,lord in ipairs(targets) do
			local lord_max_num = 0, lord_max_card
			local lord_min_num = 14, lord_min_card
			local lord_cards = lord:getHandcards()
			local flag = string.format("visible_%s_%s", current:objectName(), lord:objectName())
			for _, c in sgs.qlist(lord_cards) do
				local point = c:getNumber()
				if c:hasFlag("visible") or c:hasFlag(flag) then
					if point > lord_max_num then
						lord_max_card = c
						lord_max_num = point
					end
				end
				if point < lord_min_num then
					lord_min_num = point
					lord_min_card = c
				end
			end
			if self:isOpponent(lord) then
				if max_num > 10 and max_num > lord_max_num then
					if sgs.isCard("Jink", max_card, self.player) then
						if self:getCardsNum("Jink") == 1 then 
							return 
						end
					elseif sgs.isCard("Peach", max_card, self.player) then
						return 
					elseif sgs.isCard("Analeptic", max_card, self.player) then 
						return 
					end
					self.zhiba_pindian_card = max_card:getEffectiveId()
					use.card = card
					if use.to then 
						use.to:append(lord) 
					end
					return
				end
			elseif self:isPartner(lord) then
				if not lord:hasSkill("manjuan") then
					if (lord_max_num > 0 and min_num <= lord_max_num) or min_num < 7 then
						if sgs.isCard("Jink", min_card, self.player) then
							if self:getCardsNum("Jink") == 1 then 
								return 
							end
						end
						self.zhiba_pindian_card = min_card:getEffectiveId()
						use.card = card
						if use.to then 
							use.to:append(lord) 
						end
						return
					end
				end
			end
		end
	end
end
sgs.ai_skill_choice["zhiba_pindian"] = function(self, choices)
	local who = self.room:getCurrent()
	local cards = self.player:getHandcards()
	local has_large_number = false
	local all_small_number = true
	for _, c in sgs.qlist(cards) do
		if c:getNumber() > 11 then
			has_large_number = true
			break
		end
	end
	for _, c in sgs.qlist(cards) do
		if c:getNumber() > 4 then
			all_small_number = false
			break
		end
	end
	if all_small_number then
		return "reject"
	elseif not has_large_number then 
		if self:isOpponent(who) then
			return "reject"
		end
	end 
	return "accept"
end
sgs.ai_skill_pindian["zhiba_pindian"] = function(self, requestor, maxcard, mincard)
	local handcards = self.player:getHandcards()
	local cards = sgs.QList2Table(handcards)
	local function compare_func(a, b)
		return a:getNumber() > b:getNumber()
	end
	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if sgs.getUseValue(card, self.player) < 6 then 
			maxcard = card 
			break 
		end
	end
	return maxcard or cards[1]
end
sgs.ai_choicemade_filter.pindian["zhiba_pindian"] = function(from, promptlist, self)
	local id = tonumber(promptlist[4])
	local card = sgs.Sanguosha:getCard(id)
	local point = card:getNumber()
	local lord = findPlayerByObjectName(self.room, promptlist[5])
	if lord then
		if point < 6 then
			sgs.updateIntention(from, lord, -60)
		elseif point > 8 then
			sgs.updateIntention(from, lord, 60)
		end
	end
end
--[[
	套路：仅使用“制霸技能卡”
]]--
sgs.ai_series["ZhibaCardOnly"] = {
	name = "ZhibaCardOnly",
	IQ = 2,
	value = 2,
	priority = 2,
	cards = {
		["ZhibaCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local zhiba_skill = sgs.ai_skills["zhiba_pindian"]
		local dummyCard = zhiba_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["ZhibaCard"], "ZhibaCardOnly")
--[[****************************************************************
	武将：山·张昭张纮（吴）
]]--****************************************************************
sgs.ai_chaofeng.erzhang = 5
--[[
	技能：直谏
	描述：出牌阶段，你可以将手牌中的一张装备牌置于一名其他角色的装备区里，摸一张牌。 
]]--
--[[
	内容：“直谏技能卡”的卡牌成分
]]--
sgs.card_constituent["ZhijianCard"] = {
	use_priority = 10,
}
--[[
	内容：“直谏技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["ZhijianCard"] = -80
--[[
	内容：注册“直谏技能卡”
]]--
sgs.RegistCard("ZhijianCard")
--[[
	内容：“直谏”技能信息
]]--
sgs.ai_skills["zhijian"] = {
	name = "zhijian",
	dummyCard = function(self)
		return sgs.Card_Parse("@ZhijianCard=.")
	end,
	enabled = function(self, handcards)
		return #handcards > 0
	end,
}
sgs.ai_skill_use_func["ZhijianCard"] = function(self, card, use)
	if #self.partners_noself > 0 then
		local equips = {}
		local handcards = self.player:getHandcards()
		for _,equip in sgs.qlist(handcards) do
			if equip:isKindOf("Weapon") then
				if self:getSameTypeEquip(equip) then
					table.insert(equips, equip)
				elseif equip:isKindOf("GudingBlade") then
					if not self.player:hasSkill("jueqing") then
						if self:getCardsNum("Slash") > 0 then
							local flag = true
							local slash = self:getCard("Slash")
							for _,enemy in ipairs(self.opponents) do
								if enemy:isKongcheng() then
									if self.player:canSlash(enemy, slash, true) then
										if not self:slashIsProhibited(enemy, self.player, slash) then
											if self:slashIsEffective(slash, enemy) then
												flag = false
											end
										end
									end
								end
							end
							if flag then
								table.insert(equips, equip)
							end
						end
					end
				end
			elseif equip:isKindOf("Armor") then
				if self:getSameTypeEquip(equip) then
					table.insert(equips, equip)
				end
			elseif equip:isKindOf("EquipCard") then
				table.insert(equips, equip)
			end
		end
		if #equips > 0 then
			local equip_skills = sgs.need_equip_skill.."|"..sgs.lose_equip_skill
			for _,friend in ipairs(self.partners_noself) do
				if self:hasSkills(equip_skills, friend) then
					for _,equip in ipairs(equips) do
						if not self:getSameTypeEquip(equip, friend) then
							local card_str = "@ZhijianCard=" .. equip:getId()
							local acard = sgs.Card_Parse(card_str)
							use.card = acard
							if use.to then
								use.to:append(friend)
							end
							return
						end
					end
				end
				for _,equip in ipairs(equips) do
					if not self:getSameTypeEquip(equip, friend) then
						local card_str = "@ZhijianCard=" .. equip:getId()
						local acard = sgs.Card_Parse(card_str)
						use.card = acard
						if use.to then
							use.to:append(friend)
						end
						return
					end
				end
			end
		end
	end
end
--[[
	内容：“直谏”卡牌需求
]]--
sgs.card_need_system["zhijian"] = sgs.card_need_system["equip"]
--[[
	套路：仅使用“直谏技能卡”
]]--
sgs.ai_series["ZhijianCardOnly"] = {
	name = "ZhijianCardOnly", 
	value = 5, 
	priority = 4, 
	cards = { 
		["ZhijianCard"] = 1, 
		["Others"] = 1, 
	},
	enabled = function(self) 
		return true
	end,
	action = function(self, handcards, skillcards) 
		local zhijian_skill = sgs.ai_skills["zhijian"]
		local dummyCard = zhijian_skill["dummyCard"]()
		return {dummyCard}
	end,
	break_condition = function(self) 
		return false
	end,
}
table.insert(sgs.ai_card_actions["ZhijianCard"], "ZhijianCardOnly")
--[[
	技能：固政
	描述：其他角色的弃牌阶段结束时，你可以将该角色于此阶段内弃置的一张牌从弃牌堆返回其手牌，若如此做，你可以获得弃牌堆里其余于此阶段内弃置的牌。 
]]--
sgs.ai_skill_invoke["guzheng"] = function(self, data)
	local count = data:toInt()
	if self:isLihunTarget(self.player, count - 1) then 
		return false 
	end
	local player = self.room:getCurrent()
	local isKongcheng = false
	if player:hasSkill("kongcheng") then
		if player:isKongcheng() then
			isKongcheng = true
		end
	end
	if self:isPartner(player) then
		if not isKongcheng then
			return true
		end
	end
	if count >= 3 then
		if not self.player:hasSkill("manjuan") then
			return true
		end
	end
	if count == 2 then
		if not self:hasSkills(sgs.cardneed_skill, player) then
			if not self.player:hasSkill("manjuan") then
				return true
			end
		end
	end
	if self:isOpponent(player) then
		if isKongcheng then
			return true
		end
	end
	return false
end
sgs.ai_skill_askforag["guzheng"] = function(self, card_ids)
	local target = self.room:getCurrent()
	local WuGuoTai = self.room:findPlayerBySkillName("buyi") 
	local needBuyi = false
	if WuGuoTai then
		if target:getHp() <= 1 then
			if self:isPartner(target, WuGuoTai) then
				needBuyi = true
			end
		end
	end
	local cards = {}
	local exceptEquips = {}
	local exceptKeys = {}
	for _,id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		table.insert(cards, card)
		if self.player:hasSkill("zhijian") then
			if not card:isKindOf("EquipCard") then
				table.insert(exceptEquips, card)
			end
		end
		if not sgs.isKindOf("Peach|Jink|Analeptic|Nullification", card) then
			if not card:isKindOf("EquipCard") or not self.player:hasSkill("zhijian") then
				table.insert(exceptKeys, card)
			end
		end	
	end
	if self:isPartner(target) then
		if needBuyi then
			local buyicard1, buyicard2
			self:sortByKeepValue(cards)
			for _, card in ipairs(cards) do
				if card:isKindOf("TrickCard") and not buyicard1 then
					buyicard1 = card:getEffectiveId()
				end
				if not card:isKindOf("BasicCard") and not buyicard2 then
					buyicard2 = card:getEffectiveId()
				end
				if buyicard1 then 
					break 
				end
			end
			if buyicard1 or buyicard2 then 
				return buyicard1 or buyicard2
			end
		end
		local peach_num = 0
		local peach, jink, anal, slash 
		for _, card in ipairs(cards) do
			if card:isKindOf("Peach") then 
				peach = card:getEffectiveId() 
				peach_num = peach_num + 1 
			elseif card:isKindOf("Jink") then 
				jink = card:getEffectiveId() 
			elseif card:isKindOf("Analeptic") then 
				anal = card:getEffectiveId() 
			elseif card:isKindOf("Slash") then 
				slash = card:getEffectiveId() 
			end
		end
		if peach then
			if peach_num > 1 then
				return peach
			elseif self:getCardsNum("Peach") >= self.player:getMaxCards() then
				return peach
			elseif target:getHp() < sgs.getBestHp(target) then
				if target:getHp() < self.player:getHp() then
					return peach 
				end
			end
		end
		if jink or anal then
			if self:isWeak(target) then 
				return jink or anal 
			end
		end
		local skills = target:getVisibleSkillList()
		for _, card in ipairs(cards) do
			if not card:isKindOf("EquipCard") then
				for _, skill in sgs.qlist(skills) do
					local callback = sgs.card_need_system[skill:objectName()]
					if type(callback) == "function" then
						if callback(self, card, target) then
							return card:getEffectiveId()
						end
					end
				end
			end
		end
		if jink or anal or slash then 
			return jink or anal or slash 
		end
		for _, card in ipairs(cards) do
			if not sgs.isKindOf("EquipCard|Peach", card) then
				return card:getEffectiveId()
			end
		end
	else
		if needBuyi then
			for _, card in ipairs(cards) do
				if card:isKindOf("Slash") then
					return card:getEffectiveId() 
				end
			end 
		end
		for _, card in ipairs(cards) do
			if card:isKindOf("EquipCard") then
				if self.player:hasSkill("zhijian") then
					local cannotZhijian = true
					for _, friend in ipairs(self.partners) do
						if not self:getSameTypeEquip(card, friend) then
							cannotZhijian = false
						end
					end
					if cannotZhijian then 
						return card:getEffectiveId() 
					end
				end
			end
		end
		if #exceptKeys > 0 then
			cards = exceptKeys
		elseif #exceptEquips > 0 then
			cards = exceptEquips
		end
		self:sortByKeepValue(cards)
		local valueless, slash
		local skills = target:getVisibleSkillList()
		for _, card in ipairs (cards) do
			if card:isKindOf("Lightning") then
				if not self:hasSkills(sgs.wizard_harm_skill, target) then
					return card:getEffectiveId()
				end
			end
			if card:isKindOf("Slash") then 
				slash = card:getEffectiveId() 
			end
			if not valueless then
				if not card:isKindOf("Peach") then
					for _, skill in sgs.qlist(skills) do
						local callback = sgs.card_need_system[skill:objectName()]
						if type(callback) == "function" then
							if not callback(self, card, target) then
								valueless = card:getEffectiveId()
							end
						else
							valueless = card:getEffectiveId()
							break
						end
					end
				end
			end
		end
		if slash or valueless then
			return slash or valueless 
		end
		return cards[1]:getEffectiveId()
	end
	return card_ids[1] 
end
--[[****************************************************************
	武将：山·左慈（群）
]]--****************************************************************
--[[
	技能：化身
	描述：所有玩家展示武将牌后，你获得两张未加入游戏的武将牌，称为“化身牌”，然后选择其中一张“化身牌”的一项技能（除主公技、限定技与觉醒技），你拥有该技能且性别与势力改为与“化身牌”相同。回合开始时和回合结束后，你可以更换“化身牌”，然后为当前的“化身牌”重新选择一项技能。 
]]--
sgs.ai_skill_invoke["huashen"] = function(self, data)
	local hp = self.player:getHp()
	return hp > 0
end
sgs.ai_skill_choice["huashen"] = function(self, choices)
	local choice_list = choices:split("+")
	local hp = self.player:getHp()
	if hp < 1 then
		if choices:match("buqu") then
			return "buqu"
		end
	end
	local phase = self.player:getPhase()
	local num = self.player:getHandcardNum()
	local skills = ""
	if phase == sgs.Player_RoundStart then
		if choices:matchOne("keji") then 
			if num >= hp and num < 10 then
				if not self:isWeak() then
					return "keji"
				end
			end
			if self.player:isSkipped(sgs.Player_Play) then
				return "keji" 
			end
		end
		if num > 4 then
			skills = ("shuangxiong|nosfuhun|tianyi|xianzhen|paoxiao|luanji|huoji|qixi|duanliang|guose|" ..
			"luoyi|dangxian|neoluoyi|fuhun"):split("|")
			for _, skill in ipairs(skills) do
				if choices:matchOne(skill) then 
					return askill 
				end
			end
			if self:hasFriends("draw") then
				skills = ("rende|lirang|longluo"):split("|")
				for _, skill in ipairs(skills) do
					if choices:matchOne(skill) then 
						return skill 
					end
				end
			end
		end
		if self.player:getLostHp() >= 2 then
			if choices:matchOne("qingnang") then 
				return "qingnang" 
			end
			if choices:matchOne("jieyin") then
				if self:hasFriends("wounded_male") then 
					return "jieyin" 
				end
			end
			if choices:matchOne("rende") then
				if self:hasFriends("draw") then 
					return "rende" 
				end
			end
			skills = ("juejing|nosmiji|nosshangshi|shangshi|caizhaoji_hujia|kuiwei|" ..
			"neojushou|jushou|zaiqi|kuanggu"):split("|")
			for _, skill in ipairs(skills) do
				if choices:matchOne(skill) then 
					return skill 
				end
			end
			if choices:matchOne("miji") then
				if self:hasFriends("draw") then 
					return "miji" 
				end
			end
		end
		if num < 2 then
			if choices:matchOne("haoshi") then 
				return "haoshi" 
			end
		end
		if self.player:isWounded() then
			if choices:matchOne("qingnang") then 
				return "qingnang" 
			end
			if choices:matchOne("jieyin") then
				if self:hasFriends("wounded_male") then 
					return "jieyin" 
				end
			end
			if choices:matchOne("rende") then
				if self:hasFriends("draw") then 
					return "rende" 
				end
			end
			skills = ("juejing|nosmiji"):split("|")
			for _, skill in ipairs(skills) do
				if choices:matchOne(skill) then 
					return skill 
				end
			end
			if hp < 2 and num == 1 then
				if self:getCardsNum("Peach") == 0 then
					if choices:matchOne("shenzhi") then 
						return "shenzhi" 
					end
				end
			end
		end
		local equips = self.player:getCards("e")
		if equips:length() > 1 then
			skills = ("shuijian|xiaoji|xuanfeng|nosxuanfeng|shensu|neoluoyi|gongqi"):split("|")
			for _, skill in ipairs(skills) do
				if choices:matchOne(skill) then 
					return skill 
				end
			end
			if self:hasFriends("friend") then
				if choices:matchOne("yuanhu") then 
					return "yuanhu" 
				end
			end
		end
		if self.player:getWeapon() then
			skills = ("qiangxi|zhulou"):split("|")
			for _, skill in ipairs(skills) do
				if choices:matchOne(skill) then 
					return skill 
				end
			end
		end
		skills = ("manjuan|tuxi|dimeng|haoshi|guanxing|zhiheng|qiaobian|qice|noslijian|lijian|" ..
		"neofanjian|shuijian|shelie|luoshen|yongsi|shude|biyue|yingzi|qingnang|caizhaoji_hujia"):split("|")
		for _, skill in ipairs(skills) do
			if choices:matchOne(skill) then 
				return skill 
			end
		end
		if choices:matchOne("lianli") then
			if self:hasFriends("male") then 
				return "lianli" 
			end
		end
		if self:hasFriends("draw") then
			skills = ("rende|anxu|mingce"):split("|")
			for _, skill in ipairs(skills) do
				if choices:matchOne(skill) then 
					return skill 
				end
			end
		end
		skills = ("fanjian|duyi|mizhao|quhu|gongxin|duanliang|hongyuan|guose|baobian|ganlu|" ..
		"tiaoxin|zhaolie|moukui|liegong|mengjin|qianxi|tieji|wushuang|juejing|nosfuhun|" ..
		"nosqianxi|yanxiao|jueji|tanhu|huoshui|guhuo|xuanhuo|nosxuanhuo|qiangxi|fangquan|" ..
		"lirang|longluo|nosjujian|lieren|pojun|bawang|qixi|yinling|nosjizhi|jizhi|" ..
		"duoshi|zhaoxin|gongqi|neoluoyi|luoyi|wenjiu|jie|jiangchi|wusheng|longdan|" ..
		"jueqing|xueji|yinghun|longhun|jiuchi|qingcheng|shuangren|kuangfu|nosgongqi|wushen|" ..
		"paoxiao|lianhuan|chouliang|houyuan|jujian|shensu|jisu|luanji|chizhong|zhijian|" ..
		"shuangxiong|xinzhan|ytzhenwei|jieyuan|duanbing|fenxun|guidao|guicai|noszhenlie|wansha|"..
		"bifa|lianpo|yicong|nosshangshi|shangshi|lianying|tianyi|xianzhen|zongshi|keji|"..
		"kuiwei|yuanhu|juao|neojushou|jushou|huoji|roulin|fuhun|lihuo|xiaoji|"..
		"mashu|zhengfeng|xuanfeng|nosxuanfeng|jiushi|dangxian|tannang|qicai|taichen|hongyan|"..
		"kurou|lukang_weiyan|yicai|beifa|qinyin|zonghuo|shouye|shaoying|xingshang|suishi|"..
		"yuwen|gongmou|weiwudi_guixin|wuling|shenfen"):split("|")
		for _, skill in ipairs(skills) do
			if choices:matchOne(skill) then 
				return skill 
			end
		end
	else
		if hp == 1 then
			if choices:matchOne("wuhun") then 
				return "wuhun" 
			end
			skills = ("wuhun|duanchang|jijiu|longhun|jiushi|jiuchi|buyi|huilei|dushi|buqu|zhuiyi|jincui"):split("|")
			for _, skill in ipairs(skills) do
				if choices:matchOne(skill) then return skill end
			end
		end
		local isHealthy = false
		if hp > 1 then
			isHealthy = true
		elseif not self:isWeak() then
			isHealthy = true
		elseif self:getAllPeachNum() > 0 then
			isHealthy = true
		end
		if isHealthy then
			if choices:matchOne("guixin") then
				if self.room:alivePlayerCount() > 3 then 
					return "guixin" 
				end
			end
			if choices:matchOne("yiji") then 
				return "yiji" 
			end
			if self.player:getMark("@tied") > 0 then
				if choices:matchOne("tongxin") then 
					return "tongxin" 
				end
			end
			skills = ("fankui|jieming|neoganglie|ganglie|enyuan|fangzhu|nosenyuan|langgu"):split("|")
			for _, skill in ipairs(skills) do
				if choices:matchOne(skill) then 
					return askill 
				end
			end
		end
		if self.player:isKongcheng() then
			if choices:matchOne("kongcheng") then 
				return "kongcheng" 
			end
		end
		if not self.player:getArmor() then
			skills = ("yizhong|bazhen"):split("|")
			for _, skill in ipairs(skills) do
				if choices:matchOne(skill) then 
					return skill 
				end
			end
		end
		if not self.player:faceUp() then
			skills = ("guixin|jiushi|cangni"):split("|")
			for _, skill in ipairs(skills) do
				if choices:matchOne(skill) then 
					return skill 
				end
			end
		end
		if choices:matchOne("shuiyong") then 
			if self.player:hasArmorEffect("Vine") then
				return "shuiyong" 
			elseif self.player:getMark("@gale") > 0 then
				return "shuiyong" 
			end
		end
		local equips = self.player:getCards("e")
		if num > hp then
			if equips:length() > 0 then
				if choices:matchOne("yanzheng") then 
					return "yanzheng" 
				end
			end
		end
		if equips:length() > 1 then
			skills = sgs.lose_equip_skill:split("|")
			for _, skill in ipairs(skills) do
				if choices:matchOne(skill) then 
					return askill 
				end
			end
		end
		skills = ("noswuyan|weimu|wuyan|guzheng|luoying|xiliang|kanpo|liuli|beige|qingguo|"..
		"gushou|mingzhe|xiangle|feiying|longdan"):split("|")
		for _, skill in ipairs(skills) do
			if choices:matchOne(skill) then 
				return skill 
			end
		end
		skills = ("yiji|fankui|jieming|neoganglie|ganglie|enyuan|fangzhu|nosenyuan|langgu"):split("|")
		for _, skill in ipairs(skills) do
			if choices:matchOne(skill) then 
				return skill 
			end
		end
		skills = ("huangen|mingshi|jianxiong|tanlan|qianxun|tianxiang|danlao|juxiang|huoshou|zhichi|" ..
		"yicong|wusheng|wushuang|leiji|guhuo|nosshangshi|shangshi|zhiyu|lirang|tianming|" ..
		"jieyuan|xiaoguo|jijiu|buyi|jiang|guidao|guicai|lianying|mingshi|shushen|"..
		"shuiyong|tiandu|noszhenlie"):split("|")
		for _, skill in ipairs(skills) do
			if choices:matchOne(skill) then 
				return skill 
			end
		end
		if equips:length() > 0 then
			skills = sgs.lose_equip_skill:split("|")
			for _, skill in ipairs(skills) do
				if choices:matchOne(skill) then 
					return skill 
				end
			end
		end
		skills = ("xingshang|weidi|chizhong|jilei|sijian|badao|nosjizhi|jizhi|anxian|wuhun|"..
		"hongyan|buqu|dushi|zhuiyi|huilei"):split("|")
		for _, skill in ipairs(skills) do
			if choices:matchOne(skill) then 
				return skill 
			end
		end
		skills = ("jincui|beifa|yanzheng|xiaoji|xuanfeng|nosxuanfeng|longhun|jiushi|jiuchi|nosjiefan|"..
		"fuhun|zhenlie|kuanggu|lianpo"):split("|")
		for _, skill in ipairs(skills) do
			if choices:matchOne(skill) then 
				return skill 
			end
		end
		skills = ("gongmou|weiwudi_guixin|wuling|kuangbao"):split("|")
		for _, skill in ipairs(skills) do
			if choices:matchOne(skill) then 
				return skill 
			end
		end
	end
	for index = #choice_list, 1, -1 do
		if ("renjie|benghuai|shenjun|dongcha|yishe|shiyong|wumou"):match(choices[index]) then
			table.remove(choices, index)
		end
	end
	if #choice_list > 0 then
		return choice_list[math.random(1, #choice_list)]
	end
end
--[[
	技能：新生
	描述：每当你受到1点伤害后，你可以获得一张“化身牌”。 
]]--
--[[****************************************************************
	武将：山·蔡文姬（群）
]]--****************************************************************
sgs.ai_chaofeng.caiwenji = -5
--[[
	技能：悲歌
	描述：每当一名角色受到一次【杀】的伤害后，你可以弃置一张牌令该角色进行一次判定：若判定结果为♥，该角色回复1点体力；♦，该角色摸两张牌；♠，伤害来源将其武将牌翻面；♣，伤害来源弃置两张牌。 
]]--
sgs.ai_skill_cardask["@beige"] = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	local source = damage.from
	if self:isPartner(source) then
		return "."
	elseif not self:isPartner(target) then
		return "."
	end
	local to_discard = self:askForDiscard("beige", 1, 1, false, true)
	if #to_discard > 0 then
		return "$" .. to_discard[1]
	end
	return "."
end
--[[
	内容：“悲歌”卡牌需求
]]--
sgs.card_need_system["beige"] = function(self, card, player)
	local cards = player:getCards("h")
	return cards:length() <= 2
end
--[[
	技能：断肠（锁定技）
	描述：当你死亡时，杀死你的角色失去其所有武将技能。 
]]--
sgs.slash_prohibit_system["duanchang"] = {
	name = "duanchang",
	reason = "duanchang",
	judge_func = function(self, target, source, slash)
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
		--断肠
		if target:getHp() > 1 then
			local enemies = self:getOpponents(source) 
			if #enemies == 1 then
				return false
			end
		end
		local maxhp = source:getMaxHp()
		if maxhp == 3 then
			if source:getArmor() then
				if source:getDefensiveHorse() then
					return false
				end
			end
		end
		if maxhp <= 3 then
			if self:mayLord(source) then
				if self:isWeak(source) then
					return true
				end
			end
			if #sgs.ai_lords > 0 then
				if self:mayRenegade(source) then
					return true
				end
			end
		end
		return false
	end
}
sgs.damage_avoid_system["duanchang"] = {
	reason = "duanchang",
	judge_func = function(self, target, damage, source)
		local name = target:objectName()
		for _,lord in ipairs(sgs.ai_lords) do
			if lord == name then
				return false
			end
		end
		if target:getHp() <= 1 then
			local target_friends = self:getFriends(target, nil, true)
			if #target_friends > 0 then
				local maxhp = source:getMaxHp()
				if maxhp == 3 then
					if source:getArmor() then
						if source:getDefensiveHorse() then
							return false
						end
					end
				end
				if maxhp <= 3 then
					return true
				end
				if self:mayLord(source) then
					if self:isWeak(source) then
						return true
					end
				end
				if #sgs.ai_lords > 0 then
					if self:mayRenegade(source) then 
						return true
					end
				end
			end
		end
		return false
	end
}