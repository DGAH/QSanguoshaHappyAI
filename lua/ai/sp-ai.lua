--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）SP扩展包部分
]]--
--[[****************************************************************
	卡牌部分
]]--****************************************************************
--[[****************************************************************
	SP银月枪（武器）
]]--****************************************************************
sgs.weapon_range.SPMoonSpear = 3
sgs.card_constituent["SPMoonSpear"] = {
	use_priority = 2.62,
}
sgs.ai_playerchosen_intention["SPMoonSpear"] = 80
--[[
	内容：注册SP银月枪
]]--
sgs.RegistCard("SPMoonSpear")
--[[
	功能：使用SP银月枪
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardSPMoonSpear(card, use)
	use.card = card
end
sgs.ai_skill_playerchosen["SPMoonSpear"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _,target in ipairs(targets) do
		if self:isOpponent(target) then
			if self:damageIsEffective(target) then
				if sgs.isGoodTarget(self, target, targets) then
					return target
				end
			end
		end
	end
	return nil
end
--[[
	套路：仅使用“SP银月枪”
]]--
sgs.ai_series["SPMoonSpearOnly"] = {
	name = "SPMoonSpearOnly",
	IQ = 1,
	value = 1.4,
	priority = 1.5,
	cards = {
		["SPMoonSpear"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		for _,spear in ipairs(handcards) do
			if spear:isKindOf("SPMoonSpear") then
				return {spear}
			end
		end
		return {}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["SPMoonSpear"], "SPMoonSpearOnly")
--[[****************************************************************
	武将部分
]]--****************************************************************
--[[****************************************************************
	武将：SP·杨修（魏）
]]--****************************************************************
--[[
	技能：鸡肋
	描述：每当你受到伤害时，你可以选择一种牌的类别，伤害来源不能使用、打出或弃置其该类别的手牌，直到回合结束。 
]]--
sgs.ai_skill_invoke["jilei"] = function(self, data)
	local damage = data:toDamage()
	if damage then
		self.jilei_source = damage.from
		return self:isOpponent(damage.from)
	end
	return false
end
sgs.ai_skill_choice["jilei"] = function(self, choices)
	if self:isEquip("Crossbow", self.jilei_source) then
		if self.jilei_source:inMyAttackRange(self.player) then
			return "BasicCard"
		end
	elseif self.jilei_source:isCardLimited(sgs.ex_nihilo, sgs.Card_MethodUse, true) then
		return "BasicCard"
	end
	return "TrickCard"
end
--[[
	技能：啖酪
	描述：每当一张锦囊牌指定了包括你在内的至少两名目标时，你可以摸一张牌，然后该锦囊牌对你无效。 
]]--
sgs.ai_skill_invoke["danlao"] = function(self, data)
	local effect = data:toCardUse()
	local current = self.room:getCurrent()
	if effect.card:isKindOf("GodSalvation") then
		if self.player:isWounded() then
			return false
		end
	elseif effect.card:isKindOf("AmazingGrace") then
		local myseat = self.player:getSeat()
		local seat = current:getSeat()
		local aliveCount = global_room:alivePlayerCount()
		if (myseat - seat) % aliveCount < aliveCount / 2 then
			return false
		end
	end
	return true
end
--[[****************************************************************
	武将：SP·貂蝉（群）<隐藏武将>
]]--****************************************************************
sgs.ai_chaofeng["sp_diaochan"] = sgs.ai_chaofeng["diaochan"]
--[[
	技能：离间
	描述：出牌阶段限一次，你可以弃置一张牌并选择两名男性角色，令其中一名男性角色视为对另一名男性角色使用一张【决斗】。
]]--
--[[
	技能：闭月
	描述：结束阶段开始时，你可以摸一张牌。 
]]--
--[[****************************************************************
	武将：SP·公孙瓒（群）
]]--****************************************************************
--[[
	技能：义从（锁定技）
	描述：若你的体力值大于2，你与其他角色的距离-1；若你的体力值小于或等于2，其他角色与你的距离+1。 
]]--
--[[****************************************************************
	武将：SP·袁术（群）
]]--****************************************************************
sgs.ai_chaofeng["yuanshu"] = 3
--[[
	技能：庸肆（锁定技）
	描述：摸牌阶段，你额外摸X张牌。弃牌阶段开始时，你弃置X张牌。（X为现存势力数） 
]]--
sgs.draw_cards_system["yongsi"] = {
	name = "yongsi",
	correct_func = function(self, player)
		local count = sgs.getKingdomsCount()
		return count
	end,
}
--[[
	技能：伪帝（锁定技）
	描述：你拥有且可以发动当前主公的主公技。 
]]--
sgs.slash_prohibit_system["weidi"] = {
	name = "weidi",
	reason = "weidi",
	judge_func = function(self, target, source, slash)
		local myname = source:objectName()
		local name = target:objectName()
		for _,lordname in ipairs(sgs.ai_lords) do
			if lordname ~= myname then
				if lordname ~= name then
					local lord = findPlayerByObjectName(self.room, lordname)
					local skills = lord:getVisibleSkillList()
					for _,skill in sgs.qlist(skills) do
						local skillname = skill:objectName()
						if skillname ~= "weidi" then
							if skill:isLordSkill() then
								local item = sgs.slash_prohibit_system[skill]
								if item then
									local reason = item["reason"]
									if type(reason) == "string" then
										reason = reason:split("&")
									end
									for index, key in pairs(reason) do
										if key == skillname then
											table.remove(reason, index)
											break
										end
									end
									local flag = true
									if #reason > 0 then
										if not self:hasAllSkills(reason, target) then
											flag = false
										end
									end
									if flag then
										local callback = item["judge_func"]
										if callback and callback(self, target, source, slash) then
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
		return false
	end
}
sgs.ai_skill_use["@jijiang"] = function(self, prompt)
	if self.player:hasFlag("Global_JijiangFailed") then 
		return "." 
	end
	local card = sgs.Card_Parse("@JijiangCard=.")
	local dummy_use = { 
		isDummy = true, 
	}
	self:useSkillCard(card, dummy_use)
	if dummy_use.card then
		local jijiang = {}
		if sgs.jijiangtarget then
			for _,p in ipairs(sgs.jijiangtarget) do
				table.insert(jijiang, p:objectName())
			end
			return "@JijiangCard=.->" .. table.concat(jijiang, "+")
		end
	end
	return "."
end
--[[****************************************************************
	武将：SP·孙尚香（蜀）<隐藏武将>
]]--****************************************************************
sgs.ai_chaofeng["sp_sunshangxiang"] = sgs.ai_chaofeng["sunshangxiang"]
--[[
	技能：结姻
	描述：出牌阶段限一次，你可以弃置两张手牌并选择一名已受伤的男性角色，你和该角色各回复1点体力。 
]]--
--[[
	技能：枭姬
	描述：每当你失去一张装备区的装备牌后，你可以摸两张牌。 
]]--
--[[****************************************************************
	武将：SP·庞德（魏）<隐藏武将>
]]--****************************************************************
--[[
	技能：马术（锁定技）
	描述：你与其他角色的距离-1。 
]]--
--[[
	技能：猛进
	描述：你使用的【杀】被目标角色的【闪】抵消后，你可以弃置该角色的一张牌。 
]]--
--[[****************************************************************
	武将：SP·关羽（魏）
]]--****************************************************************
--[[
	技能：武圣
	描述：你可以将一张红色牌当【杀】使用或打出。 
]]--
--[[
	技能：单骑（觉醒技）
	描述：准备阶段开始时，若你的手牌数大于体力值，且本局游戏主公为曹操，你减1点体力上限，然后获得技能“马术”。 
]]--
--[[****************************************************************
	武将：SP·最强神话（神）<隐藏武将>
]]--****************************************************************
--[[
	技能：马术（锁定技）
	描述：你与其他角色的距离-1。 
]]--
--[[
	技能：无双（锁定技）
	描述：每当你使用【杀】指定一名目标角色后，其需依次使用两张【闪】才能抵消。每当你使用【决斗】指定一名目标角色后，或成为一名角色使用【决斗】的目标后，其每次进行响应需依次打出两张【杀】。 
]]--
--[[****************************************************************
	武将：SP·暴怒战神（神）<隐藏武将>
]]--****************************************************************
--[[
	技能：马术（锁定技）
	描述：你与其他角色的距离-1。 
]]--
--[[
	技能：无双（锁定技）
	描述：每当你使用【杀】指定一名目标角色后，其需依次使用两张【闪】才能抵消。每当你使用【决斗】指定一名目标角色后，或成为一名角色使用【决斗】的目标后，其每次进行响应需依次打出两张【杀】。 
]]--
--[[
	技能：修罗
	描述：准备阶段开始时，你可以弃置一张与判定区内延时类锦囊牌花色相同的手牌，然后弃置该延时类锦囊牌。 
]]--
sgs.ai_skill_cardask["@xiuluo"] = function(self, data, pattern)
	if self.player:containsTrick("YanxiaoCard") then 
		return "." 
	end
	if not self.player:containsTrick("indulgence") then
		if not self.player:containsTrick("supply_shortage") then
			if not self.player:containsTrick("lightning") or self:hasWizard(self.opponents) then 
				return "." 
			end
		end
	end
	local indul_suit, ss_suit, lightning_suit = nil, nil, nil
	local judges = self.player:getJudgingArea()
	for _, card in sgs.qlist(judges) do
		if card:isKindOf("Indulgence") then 
			indul_suit = card:getSuit() 
		elseif card:isKindOf("SupplyShortage") then 
			ss_suit = card:getSuit() 
		elseif card:isKindOf("Lightning") then 
			ss_suit = card:getSuit() 
		end
	end
	local handcards = self.player:getHandcards()
	if ss_suit then
		for _, card in sgs.qlist(handcards) do
			if card:getSuit() == ss_suit then 
				return "$" .. card:getEffectiveId() 
			end
		end
	elseif indul_suit then
		for _, card in sgs.qlist(handcards) do
			if card:getSuit() == indul_suit then
				if not sgs.isCard("Peach", self.player, card) then 
					return "$" .. card:getEffectiveId() 
				end
			end
		end
	elseif lightning_suit then
		for _, card in sgs.qlist(handcards) do
			if card:getSuit() == lightning_suit then
				if not sgs.isCard("Peach", self.player, card) then 
					return "$" .. card:getEffectiveId() 
				end
			end
		end
	end
	return "."
end
sgs.ai_skill_askforag["xiuluo"] = function(self, card_ids)
	for _, id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("SupplyShortage") then 
			return id 
		end
	end
	for _, id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("Indulgence") then 
			return id 
		end
	end
	if self:hasWizard(self.opponents) then
		if self.player:containsTrick("lightning") then
			for _, id in ipairs(card_ids) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isKindOf("Lightning") then 
					return id 
				end
			end
		end
	end
	return card_ids[1]
end
--[[
	技能：神威（锁定技）
	描述：摸牌阶段，你额外摸两张牌。你的手牌上限+2。 
]]--
sgs.draw_cards_system["shenwei"] = {
	name = "shenwei",
	correct_func = function(self, player)
		return 2
	end,
}
--[[
	技能：神戟（锁定技）
	描述：若你的装备区没有武器牌，你使用【杀】的目标数上限+2。 
]]--
--[[****************************************************************
	武将：SP·蔡文姬（魏）<隐藏武将>
]]--****************************************************************
sgs.ai_chaofeng["sp_caiwenji"] = sgs.ai_chaofeng["caiwenji"]
--[[
	技能：悲歌
	描述：每当一名角色受到一次【杀】的伤害后，你可以弃置一张牌令该角色进行一次判定：若判定结果为♥，该角色回复1点体力；♦，该角色摸两张牌；♠，伤害来源将其武将牌翻面；♣，伤害来源弃置两张牌。 
]]--
--[[
	技能：断肠（锁定技）
	描述：当你死亡时，杀死你的角色失去其所有武将技能。 
]]--
--[[****************************************************************
	武将：SP·马超（群）<隐藏武将>
]]--****************************************************************
sgs.ai_chaofeng["sp_machao"] = sgs.ai_chaofeng["machao"]
--[[
	技能：马术（锁定技）
	描述：你与其他角色的距离-1。 
]]--
--[[
	技能：铁骑
	描述：每当你指定【杀】的目标后，你可以进行一次判定，若判定结果为红色，该角色不能使用【闪】对此【杀】进行响应。 
]]--
--[[****************************************************************
	武将：SP·贾诩（魏）<隐藏武将>
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
	技能：帷幕（锁定技）
	描述：你不能被选择为黑色锦囊牌的目标。 
]]--
--[[****************************************************************
	武将：SP·曹洪（魏）
]]--****************************************************************
--[[
	技能：援护
	描述：结束阶段开始时，你可以将一张装备牌置于一名角色的装备区里，根据此牌的类别执行相应效果：武器牌——你弃置该角色距离为1的一名角色的区域里的一张牌；防具牌——该角色摸一张牌；坐骑牌——该角色回复1点体力。 
]]--
--[[
	功能：获取援护的目标
	参数：equipType（string类型，表示援护的装备牌类型）
		isHandcard（boolean类型，表示是否是来自手牌中的装备牌）
	结果：ServerPlayer类型，表示援护的目标角色
]]--
function SmartAI:getYuanhuTarget(equipType, isHandcard)
	local is_SilverLion = false
	if equipType == "SilverLion" then
		equipType = "Armor"
		is_SilverLion = true
	end
	local targets = nil
	if isHandcard then 
		targets = self.partners 
	else 
		targets = self.partners_noself 
	end
	if equipType == "Weapon" then
		local alives = self.room:getAllPlayers()
		for _,friend in ipairs(targets) do
			local has_equip = false
			local equips = friend:getEquips() 
			for _,equip in sgs.qlist(equips) do
				if equip:isKindOf(equipType) then
					has_equip = true
					break
				end
			end
			if not has_equip then
				for _,victim in sgs.qlist(alives) do
					if friend:distanceTo(victim) == 1 then
						if self:isPartner(victim) then
							if not victim:containsTrick("YanxiaoCard") then
								local flag = false
								if victim:containsTrick("indulgence") then
									flag = true
								elseif victim:containsTrick("supply_shortage") then
									flag = true
								elseif victim:containsTrick("lightning") then
									if self:hasWizard(self.opponents) then
										flag = true
									end
								end
								if flag then
									victim:setFlags("AI_YuanhuToChoose")
									return friend
								end
							end
						end
					end
				end
				self:sort(self.opponents, "defense")
				for _,enemy in ipairs(self.opponents) do
					if friend:distanceTo(enemy) == 1 then
						if not enemy:isNude() then
							enemy:setFlags("AI_YuanhuToChoose")
							return friend
						end
					end
				end
			end
		end
	else
		if equipType == "DefensiveHorse" then
			self:sort(targets, "hp") 
		elseif equipType == "OffensiveHorse" then 
			self:sort(targets, "hp") 
		elseif equipType == "Armor" then 
			self:sort(targets, "handcard") 
		end
		if is_SilverLion then
			local myseat = self.player:getSeat()
			local alive_count = self.room:alivePlayerCount()
			for _,enemy in ipairs(self.opponents) do
				if enemy:hasSkill("kongcheng") then
					if enemy:isKongcheng() then
						local seat_diff = enemy:getSeat() - myseat
						if seat_diff < 0 then 
							seat_diff = seat_diff + alive_count 
						end
						if seat_diff > alive_count / 2.5 + 1 then 
							return enemy 
						end
					end
				end
			end
			for _,enemy in ipairs(self.opponents) do
				if self:hasSkills("bazhen|yizhong", enemy) then
					return enemy
				end
			end
		end
		for _,friend in ipairs(targets) do
			local has_equip = false
			local equips = friend:getEquips()
			for _,equip in sgs.qlist(equips) do
				if equip:isKindOf(equipType) then
					has_equip = true
					break
				end
			end
			if not has_equip then
				if equip_type == "Armor" then
					if not self:needKongcheng(friend, true) then
						if not self:hasSkills("bazhen|yizhong", friend) then 
							return friend 
						end
					end
				else
					if friend:isWounded() then
						if not friend:hasSkill("longhun") then
							return friend
						elseif friend:getCardCount(true) < 3 then 
							return friend 
						end
					end
				end
			end
		end
	end
end
--[[
	内容：“援护技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["YuanhuCard"] = function(self, card, source, targets)
	local target = targets[1]
	local flag = false
	if target:hasSkill("bazhen") then
		flag = true
	elseif target:hasSkill("yizhong") then
		flag = true
	elseif target:hasSkill("kongcheng") then
		if target:isKongcheng() then
			flag = true
		end
	end
	if flag then
		local id = card:getEffectiveId()
		local equip = sgs.Sanguosha:getCard(id)
		if equip:isKindOf("SilverLion") then
			sgs.updateIntention(source, target, 10)
			return 
		end
	end
	sgs.updateIntention(source, target, -50)
end
sgs.ai_skill_use["@@yuanhu"] = function(self, prompt)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	--白银狮子
	if self.player:hasArmorEffect("SilverLion") then
		local target = self:getYuanhuTarget("SilverLion", false)
		if target then
			local card_id = self.player:getArmor():getEffectiveId()
			return "@YuanhuCard=" .. card_id .. "->" .. target:objectName()
		end
	end
	--进攻马
	local horse = self.player:getOffensiveHorse()
	if horse then
		local target = self:getYuanhuTarget("OffensiveHorse", false)
		if target then
			local card_id = horse:getEffectiveId()
			return "@YuanhuCard=" .. card_id .. "->" .. target:objectName()
		end
	end
	--武器
	local weapon = self.player:getWeapon()
	if weapon then
		local target = self:getYuanhuTarget("Weapon", false)
		if target then
			local card_id = weapon:getEffectiveId()
			return "@YuanhuCard=" .. card_id .. "->" .. target:objectName()
		end
	end
	--防具
	local armor = self.player:getArmor()
	if armor then
		if self.player:getLostHp() <= 1 then
			if self.player:getHandcardNum() >= 3 then
				local target = self:getYuanhuTarget("Armor", false)
				if target then
					local card_id = armor:getEffectiveId()
					return "@YuanhuCard=" .. card_id .. "->" .. target:objectName()
				end
			end
		end
	end
	--防御马（手牌）
	for _,card in ipairs(cards) do
		if card:isKindOf("DefensiveHorse") then
			local target = self:getYuanhuTarget("DefensiveHorse", true)
			if target then
				local card_id = card:getEffectiveId()
				return "@YuanhuCard=" .. card_id .. "->" .. target:objectName()
			end
		end
	end
	--进攻马（手牌）
	for _,card in ipairs(cards) do
		if card:isKindOf("OffensiveHorse") then
			local target = self:getYuanhuTarget("OffensiveHorse", true)
			if target then
				local card_id = card:getEffectiveId()
				return "@YuanhuCard=" .. card_id .. "->" .. target:objectName()
			end
		end
	end
	--武器（手牌）
	for _,card in ipairs(cards) do
		if card:isKindOf("Weapon") then
			local target = self:getYuanhuTarget("Weapon", true)
			if target then
				local card_id = card:getEffectiveId()
				return "@YuanhuCard=" .. card_id .. "->" .. target:objectName()
			end
		end
	end
	--防具（手牌）
	for _,card in ipairs(cards) do
		if card:isKindOf("SilverLion") then
			local target = self:getYuanhuTarget("SilverLion", true)
			if target then
				local card_id = card:getEffectiveId()
				return "@YuanhuCard=" .. card_id .. "->" .. target:objectName()
			end
		end
		if card:isKindOf("Armor") then
			local target = self:getYuanhuTarget("Armor", true)
			if target then
				local card_id = card:getEffectiveId()
				return "@YuanhuCard=" .. card_id .. "->" .. target:objectName()
			end
		end
	end
end
sgs.ai_skill_playerchosen["yuanhu"] = function(self, targets)
	for _, p in sgs.qlist(targets) do
		if p:hasFlag("AI_YuanhuToChoose") then
			p:setFlags("-AI_YuanhuToChoose")
			return p
		end
	end
	return targets[1]
end
sgs.yuanhu_keep_value = {
	Peach = 6,
	Jink = 5.1,
	Weapon = 4.7,
	Armor = 4.8,
	Horse = 4.9
}
--[[
	内容：“援护”卡牌需求
]]--
sgs.card_need_system["yuanhu"] = sgs.card_need_system["equip"]
--[[****************************************************************
	武将：SP·关银屏（蜀）
]]--****************************************************************
--[[
	技能：血祭
	描述：出牌阶段限一次，你可以弃置一张红色牌并选择你攻击范围内的至多X名其他角色，对这些角色各造成1点伤害（X为你已损失的体力值），然后这些角色各摸一张牌。 
]]--
--[[
	功能：判断一名角色是否适合作为血祭的目标
	参数：target（ServerPlayer类型，表示当前考察的目标角色）
		card（Card类型，表示将在发动血祭时弃置的红色牌）
	结果：boolean类型，表示是否适合
]]--
function SmartAI:isXuejiTarget(target, card)
	--游戏规则判断
	local distance = self.player:distanceTo(target) 
	local weapon = self.player:getWeapon()
	if weapon then
		if weapon:getEffectiveId() == card:getEffectiveId() then
			if distance > 1 then
				return false
			end
		end
	end
	local range = self.player:getAttackRange()
	local horse = self.player:getOffensiveHorse()
	if horse then
		if horse:getEffectiveId() == card:getEffectiveId() then
			if self.player:distanceTo(target, 1) > range then
				return false
			end
		end
	end
	if distance > range then
		return false
	end
	--游戏策略判断
	if self:isOpponent(target) then
		if not self.player:hasSkill("jueqing") then
			if self:damageIsEffective(target) then
				if not self:cannotBeHurt(target) then
					if not self:invokeDamagedEffect(target) then
						if not self:needToLoseHp(target) then
							if target:hasSkill("guixin") then
								if not target:hasSkill("manjuan") then 
									if self.room:getAliveCount() >= 4 then
										return false
									elseif not target:faceUp() then
										return false 
									end
								end
							end
							if self:hasSkills("ganglie|neoganglie", target) then
								if self.player:getHp() == 1 then
									if self.player:getHandcardNum() <= 2 then 
										return false 
									end
								end
							end
							if target:hasSkill("jieming") then
								for _,enemy in ipairs(self.opponents) do
									if enemy:getHandcardNum() <= enemy:getMaxHp() - 2 then
										if not enemy:hasSkill("manjuan") then 
											return false 
										end
									end
								end
							end
							if target:hasSkill("fangzhu") then
								for _,enemy in ipairs(self.opponents) do
									if not enemy:faceUp() then 
										return false 
									end
								end
							end
							if who:hasSkill("yiji") then
								local HuaTuo = self.room:findPlayerBySkillName("jijiu")
								if HuaTuo then
									if self:isOpponents(HuaTuo) then
										if HuaTuo:getHandcardNum() >= 3 then
											return false
										end
									end
								end
							end
						end
					end
				end
			end
		end
	elseif self:isPartner(target) then
		if target:hasSkill("yiji") then
			if not self.player:hasSkill("jueqing") then
				local HuaTuo = self.room:findPlayerBySkillName("jijiu")
				if HuaTuo then
					if self:isPartner(HuaTuo) then
						if HuaTuo:getHandcardNum() >= 3 then
							if HuaTuo:objectName() ~= self.player:objectName() then
								return true
							end
						end
					end
				end
				if target:getLostHp() == 0 then
					if target:getMaxHp() >= 3 then 
						return true 
					end
				end 
			end
		end
		if target:hasSkill("hunzi") then
			if target:getMark("hunzi") == 0 then
				local next_alive = self.player:getNextAlive()
				if target:objectName() == next_alive:objectName() then
					if target:getHp() == 2 then
						return true 
					end
				end
			end
		end
		if self:cannotBeHurt(target) then
			if not self:damageIsEffective(target) then
				if target:hasSkill("manjuan") then
					if target:getPhase() == sgs.Player_NotActive then
						return false
					end
				end
				if target:hasSkill("kongcheng") then
					if target:isKongcheng() then
						return false
					end
				end
				return true
			end
		end
		return false
	end
	return true
end
--[[
	内容：“血祭技能卡”的卡牌成分
]]--
sgs.card_constituent["XuejiCard"] = {
	use_value = 3,
	use_priority = 2.35,
}
--[[
	内容：“血祭技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["XuejiCard"] = function(self, card, source, targets)
	local HuaTuo = self.room:findPlayerBySkillName("jijiu")
	for _,target in ipairs(targets) do
		local intention = 60
		if target:hasSkill("yiji") then
			if not source:hasSkill("jueqing") then
				if HuaTuo then
					if self:isPartner(HuaTuo, source) then
						if HuaTuo:getHandcardNum() >= 3 then
							if HuaTuo:objectName() ~= source:objectName() then
								intention = -30
							end
						end
					end
				end
				if target:getLostHp() == 0 then
					if target:getMaxHp() >= 3 then
						intention = -10
					end
				end
			end
		end
		if target:hasSkill("hunzi") then
			if target:getMark("hunzi") == 0 then
				if target:getHp() == 2 then
					local next_alive = source:getNextAlive()
					if target:objectName() == next_alive:objectName() then
						intention = -20 
					end
				end
			end
		end
		if self:cannotBeHurt(target) then
			if not self:damageIsEffective(target) then 
				intention = -20 
			end
		end
		sgs.updateIntention(source, target, intention)
	end
end
--[[
	内容：注册“血祭技能卡”
]]--
sgs.RegistCard("XuejiCard")
--[[
	内容：“血祭”技能信息
]]--
sgs.ai_skills["xueji"] = {
	name = "xueji",
	dummyCard = function(self)
		local card_str = "@XuejiCard="
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if not self.player:hasUsed("XuejiCard") then 
			if self.player:isWounded() then 
				local cards = self.player:getCards("he")
				for _,card in sgs.qlist(cards) do
					if card:isRed() then
						return true
					end
				end
			end
		end
		return false
	end,
}
--[[
	内容：“血祭技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["XuejiCard"] = function(self, card, use)
	local cards = self.player:getCards("he")
	local reds = {}
	for _,red in sgs.qlist(cards) do
		if red:isRed() then
			table.insert(reds, red)
		end
	end
	if #reds > 0 then
		self:sortByUseValue(reds, true)
		local redcard = reds[1]
		local card_str = "@XuejiCard="..redcard:getEffectiveId()
		self:sort(self.opponents, "defense")
		local enemy_targets = {}
		local friend_targets = {}
		for _,enemy in ipairs(self.opponents) do
			if self:isXuejiTarget(enemy, redcard) then
				table.insert(enemy_targets, enemy)
			end
		end
		local can_use = false
		if #enemy_targets > 0 then
			can_use = true
		else
			for _,friend in ipairs(self.partners_noself) do
				if self:isXuejiTarget(friend, redcard) then
					table.insert(friend_targets, friend)
				end
			end
			if #friend_targets > 0 then
				can_use = true
			end
		end
		if can_use then
			local lost = self.player:getLostHp()
			local acard = sgs.Card_Parse(card_str)
			use.card = acard
			if use.to then
				for _,enemy in ipairs(enemy_targets) do
					use.to:append(enemy)
					if use.to:length() >= lost then
						return 
					end
				end
				for _,friend in ipairs(friend_targets) do
					use.to:append(friend)
					if use.to:length() >= lost then
						return 
					end
				end
				if use.to:isEmpty() then
					use.card = nil
				end
			end
		end
	end
end
--[[
	内容：“血祭”卡牌需求
]]--
sgs.card_need_system["xueji"] = function(self, card, player)
	if card:isRed() then
		return player:getHandcardNum() < 3
	end
	return false
end
--[[
	内容：“血祭”最优体力
]]--
sgs.best_hp_system["xueji"] = {
	name = "xueji",
	reason = "xueji",
	best_hp = function(player, maxhp, isLord)
		if isLord then
			return math.max(3, maxhp-1)
		else
			return math.max(2, maxhp-1)
		end
	end,
}
--[[
	套路：仅使用“血祭技能卡”
]]--
sgs.ai_series["XuejiCardOnly"] = {
	name = "XuejiCardOnly",
	IQ = 2,
	value = 2,
	priority = 1,
	skills = "xueji",
	cards = {
		["XuejiCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local xueji_skill = sgs.ai_skills["xueji"]
		local dummyCard = xueji_skill["dummyCard"](self)
		return {dummyCard}
	end,
}
table.insert(sgs.ai_card_actions["XuejiCard"], "XuejiCardOnly")
--[[
	技能：虎啸（锁定技）
	描述：每当你于出牌阶段内使用的【杀】被【闪】抵消时，你于此阶段内能额外使用一张【杀】。 
]]--
--[[
	技能：武继（觉醒技）
	描述：结束阶段开始时，若你于此回合内已造成3点或更多伤害，你加1点体力上限，回复1点体力，然后失去技能“虎啸”。 
]]--
--[[****************************************************************
	武将：SP·甄姬（魏）<隐藏武将>
]]--****************************************************************
--[[
	技能：倾国
	描述：你可以将一张黑色手牌当【闪】使用或打出。 
]]--
--[[
	技能：洛神
	描述：准备阶段开始时，你可以进行一次判定，若判定结果为黑色，你获得生效后的判定牌且你可以重复此流程。 
]]--
--[[****************************************************************
	武将：SP·刘协（群）
]]--****************************************************************
--[[
	技能：天命
	描述：每当你被指定为【杀】的目标时，你可以弃置两张牌，然后摸两张牌。若全场唯一的体力值最多的角色不是你，该角色也可以弃置两张牌，然后摸两张牌。 
]]--
--[[
	技能：密诏
	描述：出牌阶段限一次，你可以将所有手牌（至少一张）交给一名其他角色：若如此做，你令该角色与另一名由你指定的有手牌的角色拼点：若一名角色赢，视为该角色对没赢的角色使用一张【杀】。 
]]--
--[[****************************************************************
	武将：SP·灵雎（群）
]]--****************************************************************
--[[
	技能：竭缘
	描述：每当你对一名其他角色造成伤害时，若其体力值大于或等于你的体力值，你可以弃置一张黑色手牌：若如此做，此伤害+1。每当你受到一名其他角色造成的伤害时，若其体力值大于或等于你的体力值，你可以弃置一张红色手牌：若如此做，此伤害-1。 
]]--
--[[
	技能：焚心（限定技）
	描述：若你不是主公，你杀死一名非主公其他角色检验胜利条件之前，你可以与该角色交换身份牌。 
]]--
--[[****************************************************************
	武将：SP·伏完（群）
]]--****************************************************************
--[[
	技能：谋溃
	描述：每当你指定【杀】的目标后，你可以选择一项：摸一张牌，或弃置目标角色一张牌：若如此做，此【杀】被目标角色的【闪】抵消后，该角色弃置你的一张牌。 
]]--
--[[****************************************************************
	武将：SP·夏侯霸（蜀）
]]--****************************************************************
--[[
	技能：豹变（锁定技）
	描述：若你的体力值为3或更低，你视为拥有技能“挑衅”。若你的体力值为2或更低，你视为拥有技能“咆哮”。若你的体力值为1或更低，你视为拥有技能“神速”。 
]]--
--[[
	内容：“豹变”最优体力
]]--
sgs.best_hp_system["baobian"] = {
	name = "baobian",
	reason = "baobian",
	best_hp = function(player, maxhp, isLord)
		local lost = math.max(0, maxhp - 3)
		local best = maxhp - lost
		if isLord then
			return math.max(3, best)
		else
			return math.max(2, best)
		end
	end,
}
--[[****************************************************************
	武将：SP·陈琳（魏）
]]--****************************************************************
--[[
	技能：笔伐
	描述：结束阶段开始时，你可以将一张手牌移出游戏并选择一名其他角色，该角色的回合开始时，观看该牌，然后选择一项：交给你一张与该牌类型相同的牌并获得该牌，或将该牌置入弃牌堆并失去1点体力。 
]]--
--[[
	内容：“笔伐技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["BifaCard"] = 30
sgs.ai_skill_use["@@bifa"] = function(self, prompt)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	self:sort(self.opponents, "hp")
	if #self.opponents > 0 then 
		for _, enemy in ipairs(self.opponents) do
			if not (self:needToLoseHp(enemy) and not self:hasSkills(sgs.masochism_skill, enemy)) then
				for _, c in ipairs(cards) do
					if c:isKindOf("EquipCard") then 
						return "@BifaCard=" .. c:getEffectiveId() .. "->" .. enemy:objectName() 
					end
				end
				for _, c in ipairs(cards) do
					if c:isKindOf("TrickCard") then
						if not (c:isKindOf("Nullification") and self:getCardsNum("Nullification") == 1) then 
							return "@BifaCard=" .. c:getEffectiveId() .. "->" .. enemy:objectName() 
						end
					end
				end
				for _, c in ipairs(cards) do
					if c:isKindOf("Slash") then 
						return "@BifaCard=" .. c:getEffectiveId() .. "->" .. enemy:objectName() 
					end
				end
			end
		end
	end
end
sgs.ai_skill_cardask["@bifa-give"] = function(self, data)
	if self:needToLoseHp() then
		if not self:hasSkills(sgs.masochism_skill) then 
			return "." 
		end
	end
	local card_type = data:toString()
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards)
	for _, c in ipairs(cards) do
		if c:isKindOf(card_type) then
			if not c:isKindOf("Peach") then
				if not c:isKindOf("ExNihilo") then
					return "$" .. c:getEffectiveId()
				end
			end
		end
	end
	return "."
end
--[[
	技能：颂词
	描述：出牌阶段，你可以令一名手牌数大于体力值的角色弃置两张牌，或令一名手牌数小于体力值的角色摸两张牌。对每名角色限一次。 
]]--
--[[
	内容：“颂词技能卡”的卡牌成分
]]--
sgs.card_constituent["SongciCard"] = {
	use_value = 3,
	use_priority = 3,
}
--[[
	内容：“颂词技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention.SongciCard = function(self, card, source, targets)
	local target = targets[1]
	local intention = 0
	if target:getHandcardNum() > target:getHp() then
		intention = 80
	else
		intention = -80
	end
	sgs.updateIntention(source, target, intention)
end
--[[
	内容：注册“颂词”技能卡
]]--
sgs.RegistCard("SongciCard")
--[[
	内容：“颂词”技能信息
]]--
sgs.ai_skills["songci"] = {
	name = "songci",
	dummyCard = function(self)
		return sgs.Card_Parse("@SongciCard=.")
	end,
	enabled = function(self, handcards)
		local alives = self.room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			if p:getMark("@songci") == 0 then
				local num = p:getHandcardNum()
				local hp = p:getHp()
				if num ~= p then
					return true
				end
			end
		end
		return false
	end,
}
--[[
	内容：“颂词技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["SongciCard"] = function(self, card, use)
	self:sort(self.partners, "handcard")
	local current = self.room:getCurrent()
	for _, friend in ipairs(self.partners) do
		if friend:getMark("@songci") == 0 then
			if friend:getHandcardNum() < friend:getHp() then
				if not (friend:hasSkill("manjuan") and current:objectName() ~= friend:objectName()) then
					if not (friend:hasSkill("haoshi") and friend:getHandcardNum() <= 1 and friend:getHp() >= 3) then
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
	self:sort(self.opponents, "handcard")
	self.opponents = sgs.reverse(self.opponents)
	for _,enemy in ipairs(self.opponents) do
		if enemy:getMark("@songci") == 0 then
			if enemy:getHandcardNum() > enemy:getHp() then
				if not enemy:isNude() then
					if not self:doNotDiscard(enemy, "he", nil, 2, true) then
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
--[[
	套路：仅使用“颂词技能卡”
]]--
sgs.ai_series["SongciCardOnly"] = {
	name = "SongciCardOnly",
	IQ = 2,
	value = 5,
	priority = 3,
	skills = "songci",
	cards = {
		["SongciCard"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local songci_skill = sgs.ai_skills["songci"]
		local dummyCard = songci_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["SongciCard"], "SongciCardOnly")
--[[****************************************************************
	武将：SP·大乔小乔（吴）
]]--****************************************************************
--[[
	技能：星舞
	描述：弃牌阶段开始时，你可以将一张与你本回合使用的牌颜色均不同的手牌置于武将牌上。若你有三张“星舞牌”，你将其置入弃牌堆，然后选择一名男性角色，你对其造成2点伤害并弃置其装备区的所有牌。 
]]--
sgs.ai_playerchosen_intention["xingwu"] = 80
sgs.ai_skill_cardask["@xingwu"] = function(self, data)
	local handcards = self.player:getHandcards()
	local cards = sgs.QList2Table(handcards)
	local xingwus = self.player:getPile("xingwu")
	if #cards <= 1 then
		if xingwus:length() == 1 then 
			return "." 
		end
	end
	local good_enemies = {}
	for _,enemy in ipairs(self.opponents) do
		if enemy:isMale() then
			if self:damageIsEffective(enemy) then
				if not self:cannotBeHurt(enemy, 2, self.player) then
					table.insert(good_enemies, enemy)
				end
			else
				local equips = enemy:getEquips()
				if not equips:isEmpty() then
					local flag = true
					if equips:length() == 1 then
						if enemy:getArmor() then
							if self:needToThrowArmor(enemy) then
								flag = false
							end
						end
					end
					if flag then
						table.insert(good_enemies, enemy)
					end
				end
			end
		end
	end
	if #good_enemies == 0 then
		if not xingwus:isEmpty() then
			return "." 
		elseif not self.player:hasSkill("luoyan") then 
			return "." 
		end
	end
	local red_avail = false 
	local black_avail = false
	local n = self.player:getMark("xingwu")
	if bit32.band(n, 2) == 0 then 
		red_avail = true 
	elseif bit32.band(n, 1) == 0 then 
		black_avail = true 
	end
	self:sortByKeepValue(cards)
	local xwcard = nil
	local heart = 0
	local to_save = 0
	local hp = self.player:getHp()
	local aliveCount = self.room:alivePlayerCount()
	local others = self.room:getOtherPlayers(self.player)
	local maxcards = self.player:getMaxCards()
	local isWeak = self:isWeak()
	for _, card in ipairs(cards) do
		if self.player:hasSkill("tianxiang") and card:getSuit() == sgs.Card_Heart and heart < math.min(hp, 2) then
			heart = heart + 1
		elseif sgs.isCard("Jink", card, self.player) then
			if self.player:hasSkill("liuli") and aliveCount > 2 then
				for _, p in sgs.qlist(others) do
					if self:canLiuli(self.player, p) then
						xwcard = card
						break
					end
				end
			end
			if not xwcard then
				if self:getCardsNum("Jink") >= 2 then
					xwcard = card
				end
			end
		elseif to_save > maxcards then
			xwcard = card
		elseif not sgs.isCard("Peach", card, self.player) and not (isWeak and sgs.isCard("Analeptic", card, self.player)) then
			xwcard = card
		else
			to_save = to_save + 1
		end
		if xwcard then
			if red_avail and xwcard:isRed() then
				break
			elseif black_avail and xwcard:isBlack() then
				break
			else
				xwcard = nil
				to_save = to_save + 1
			end
		end
	end
	if xwcard then 
		return "$" .. xwcard:getEffectiveId() 
	else 
		return "." 
	end
end
sgs.ai_skill_playerchosen["xingwu"] = function(self, targets)
	local good_enemies = {}
	for _, enemy in ipairs(self.opponents) do
		if enemy:isMale() then
			table.insert(good_enemies, enemy)
		end
	end
	if #good_enemies == 0 then 
		return targets:first() 
	end
	local getCmpValue = function(enemy)
		local value = 0
		if self:damageIsEffective(enemy) then
			local dmg = enemy:hasArmorEffect("SilverLion") and 1 or 2
			if enemy:getHp() <= dmg then value = 5 else value = value + enemy:getHp() / (enemy:getHp() - dmg) end
			if not sgs.isGoodTarget(self, enemy, self.opponents) then value = value - 2 end
			if self:cannotBeHurt(enemy, dmg, self.player) then value = value - 5 end
			if self:mayLord(enemy) then value = value + 2 end
			if enemy:hasArmorEffect("SilverLion") then value = value - 1.5 end
			if self:hasSkills(sgs.exclusive_skill, enemy) then value = value - 1 end
			if self:hasSkills(sgs.masochism_skill, enemy) then value = value - 0.5 end
		end
		if not enemy:getEquips():isEmpty() then
			local len = enemy:getEquips():length()
			if enemy:hasSkills(sgs.lose_equip_skill) then value = value - 0.6 * len end
			if enemy:getArmor() and self:needToThrowArmor() then value = value - 1.5 end
			if enemy:hasArmorEffect("SilverLion") then value = value - 0.5 end

			if enemy:getWeapon() then value = value + 0.8 end
			if enemy:getArmor() then value = value + 1 end
			if enemy:getDefensiveHorse() then value = value + 0.9 end
			if enemy:getOffensiveHorse() then value = value + 0.7 end
			if self:getDangerousCard(enemy) then value = value + 0.3 end
			if self:getValuableCard(enemy) then value = value + 0.15 end
		end
		return value
	end
	local values = {}
	for _,enemy in ipairs(good_enemies) do
		values[enemy:objectName()] = getCmpValue(enemy)
	end
	local function compare_func(a, b)
		return values[a:objectName()] > values[b:objectName()]
	end
	table.sort(good_enemies, compare_func)
	return good_enemies[1]
end
--[[
	技能：落雁（锁定技）
	描述：若你的武将牌上有“星舞牌”，你视为拥有技能“天香”和“流离”。 
]]--
--[[****************************************************************
	武将：SP·吕布（神）<隐藏武将>
]]--****************************************************************
--[[
	技能：狂暴（锁定技）
	描述：游戏开始时，你获得两枚“暴怒”标记。每当你造成或受到1点伤害后，你获得一枚“暴怒”标记。 
]]--
--[[
	技能：无谋（锁定技）
	描述：每当你使用一张非延时类锦囊牌选择目标后，你选择一项：失去1点体力，或弃一枚“暴怒”标记。 
]]--
--[[
	技能：无前
	描述：出牌阶段，你可以弃两枚“暴怒”标记并选择一名其他角色，该角色的防具无效且你获得技能“无双”，直到回合结束。 
]]--
--[[
	技能：神愤
	描述：出牌阶段限一次，你可以弃六枚“暴怒”标记并选择所有其他角色，对这些角色各造成1点伤害，然后这些角色先各弃置其装备区里的所有牌，再各弃置四张手牌，最后你将你的武将牌翻面。 
]]--
--[[****************************************************************
	武将：SP·诸葛恪（吴）
]]--****************************************************************
--[[
	技能：傲才
	描述：你的回合外，每当你需要使用或打出一张基本牌时，你可以观看牌堆顶的两张牌，然后使用或打出其中一张该类别的基本牌。
]]--
sgs.ai_skill_invoke["aocai"] = function(self, data)
	local asked = data:toStringList()
	local pattern = asked[1]
	local prompt = asked[2]
	local result = self:askForCard(pattern, prompt, 1)
	return result ~= "."
end
sgs.ai_skill_askforag["aocai"] = function(self, card_ids)
	local card_id = card_ids[1]
	local card = sgs.Sanguosha:getCard(card_id)
	if card:isKindOf("Jink") then
		if self.player:hasFlag("dahe") then
			for _,id in ipairs(card_ids) do
				local jink = sgs.Sanguosha:getCard(id)
				if jink:getSuit() == sgs.Card_Heart then 
					return id 
				end
			end
			return -1
		end
	end
	return card_id
end
sgs.ai_cardsview_valuable["aocai"] = function(self, class_name, player)
	if not player:hasFlag("Global_AocaiFailed") then
		if player:getPhase() == sgs.Player_NotActive then
			if class_name == "Slash" then
				local reason = sgs.Sanguosha:getCurrentCardUseReason()
				if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
					return "@AocaiCard=.:slash"
				end
			elseif class_name == "Peach" then
				if not player:hasFlag("Global_PreventPeach") then
					local dying = self.room:getCurrentDyingPlayer()
					if dying and dying:objectName() == player:objectName() then
						return "@AocaiCard=.:peach+analeptic"
					else
						return "@AocaiCard=.:peach"
					end
				end
			elseif class_name == "Analeptic" then
				local dying = self.room:getCurrentDyingPlayer()
				if dying and dying:objectName() == player:objectName() then
					if player:hasFlag("Global_PreventPeach") then
						return "@AocaiCard=.:analeptic"
					else
						return "@AocaiCard=.:peach+analeptic"
					end
				else
					return "@AocaiCard=.:analeptic"
				end
			end
		end
	end
end
--[[
	技能：黩武
	描述：出牌阶段，你可以选择攻击范围内的一名其他角色并弃置X张牌：若如此做，你对该角色造成1点伤害。若你以此法令该角色进入濒死状态，濒死结算后你失去1点体力，且本阶段你不能再次发动“黩武”。（X为该角色当前的体力值） 
]]--
--[[
	功能：获取某角色濒死时可回复体力的数目
	参数：isPartner（boolean类型）
	结果：number类型（num），表示回复数目
]]--
function SmartAI:getSaveNum(isPartner)
	local num = 0
	local alives = self.room:getAlivePlayers()
	for _,player in sgs.qlist(alives) do
		local flag = false
		if isPartner then
			flag = self:isPartner(player)
		else
			flag = self:isOpponent(player)
		end
		if flag then
			if not self.player:hasSkill("wansha") or player:objectName() == self.player:objectName() then
				if player:hasSkill("jijiu") then
					num = num + self:getSuitNum("heart", true, player)
					num = num + self:getSuitNum("diamond", true, player)
					num = num + player:getHandcardNum() * 0.4
				end
				if player:hasSkill("nosjiefan") then
					local slashCount = sgs.getCardsNum("Slash", player)
					if slashCount > 0 then
						if self:isPartner(player) or self:getCardsNum("Jink") == 0 then 
							num = num + slashCount
						end
					end
				end
				num = num + sgs.getCardsNum("Peach", player)
			end
			if player:hasSkill("buyi") then
				if not player:isKongcheng() then 
					num = num + 0.3 
				end
			end
			if player:hasSkill("chunlao") then
				local wines = player:getPile("wine")
				if not wines:isEmpty() then 
					num = num + wines:length()
				end
			end
			if player:hasSkill("jiuzhu") then
				local hp = player:getHp()
				if hp > 1 then
					if not player:isNude() then
						local count = player:getCardCount(true)
						count = math.min(hp-1, count)
						num = num + 0.9 * math.max(0, count)
					end
				end
			end
			if player:hasSkill("renxin") then
				if player:objectName() ~= self.player:objectName() then
					if not player:isKongcheng() then 
						num = num + 1 
					end
				end
			end
		end
	end
	return num
end
--[[
	内容：“黩武技能卡”的卡牌信息
]]--
sgs.card_constituent["DuwuCard"] = {
	damage = 2,
	use_value = 2.45,
	use_priority = 0.6,
}
--[[
	内容：“黩武技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["DuwuCard"] = 80
--[[
	内容：注册“黩武技能卡”
]]--
sgs.RegistCard("DuwuCard")
--[[
	内容：“黩武”技能信息
]]--
sgs.ai_skills["duwu"] = {
	name = "duwu",
	dummyCard = function(self)
		return sgs.Card_Parse("@DuwuCard=.")
	end,
	enabled = function(self, handcards)
		if self.player:hasFlag("DuwuEnterDying") then
			return false
		end
		return true
	end,
}
--[[
	内容：“黩武技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["DuwuCard"] = function(self, card, use)
	local enemies = {}
	for _,enemy in ipairs(self.opponents) do
		if self:canAttack(enemy, self.player) then
			if self.player:inMyAttackRange(enemy) then 
				table.insert(enemies, enemy) 
			end
		end
	end
	if #enemies == 0 then 
		return 
	end
	local function compare_func(a, b)
		local hpA = a:getHp()
		local hpB = b:getHp()
		if hpA < hpB then
			if hpA == 1 and hpB == 2 then 
				return false 
			else 
				return true 
			end
		end
		return false
	end
	table.sort(enemies, compare_func)
	if enemies[1]:getHp() <= 0 then
		use.card = sgs.Card_Parse("@DuwuCard=.")
		if use.to then 
			use.to:append(enemies[1]) 
		end
		return
	end
	local card_ids = {}
	if self:needToThrowArmor() then 
		local armor = self.player:getArmor()
		local id = armor:getEffectiveId()
		table.insert(card_ids, id) 
	end
	local handcards = self.player:getHandcards()
	local use_slash, keep_jink, keep_anal = false, false, false
	local hp = self.player:getHp()
	for _,c in sgs.qlist(handcards) do
		if not sgs.isCard("Peach", c, self.player) then
			if not sgs.isCard("ExNihilo", c, self.player) then
				local shouldUse = true
				local typeId = c:getTypeId()
				if typeId == sgs.Card_TypeTrick then
					local dummy_use = { 
						isDummy = true, 
					}
					self:useTrickCard(c, dummy_use)
					if dummy_use.card then 
						shouldUse = false 
					end
				elseif typeId == sgs.Card_TypeEquip then
					if not self.player:hasEquip(card) then
						local dummy_use = { 
							isDummy = true, 
						}
						self:useEquipCard(c, dummy_use)
						if dummy_use.card then 
							shouldUse = false 
						end
					end
				end
				if not keep_jink then
					if sgs.isCard("Jink", c, self.player) then
						keep_jink = true
						shouldUse = false
					end
				end
				if not keep_anal then
					if hp == 1 then
						if sgs.isCard("Analeptic", c, self.player) then
							keep_anal = true
							shouldUse = false
						end
					end
				end
				if shouldUse then 
					table.insert(card_ids, c:getId()) 
				end
			end
		end
	end
	local hc_num = #card_ids
	local eq_num = 0
	local horse = self.player:getOffensiveHorse()
	if horse then
		table.insert(card_ids, horse:getEffectiveId())
		eq_num = eq_num + 1
	end
	local weapon = self.player:getWeapon()
	if weapon then
		if self:evaluateWeapon(weapon) < 5 then
			table.insert(card_ids, weapon:getEffectiveId())
			eq_num = eq_num + 2
		end
	end
	local function getRangefix(index)
		if index <= hc_num then 
			return 0
		elseif index == hc_num + 1 then
			if eq_num == 2 then
				return sgs.weapon_range[weapon:getClassName()] - 1
			else
				return 1
			end
		elseif index == hc_num + 2 then
			return sgs.weapon_range[weapon:getClassName()]
		end
	end
	local range = self.player:getAttackRange()
	local isWeak = self:isWeak()
	for _,enemy in ipairs(enemies) do
		local enemy_hp = enemy:getHp()
		if enemy_hp < hc_num then
			if enemy_hp <= 0 then
				use.card = sgs.Card_Parse("@DuwuCard=.")
				if use.to then 
					use.to:append(enemy) 
				end
				return
			elseif enemy_hp > 1 then
				local hp_ids = {}
				local rangefix = getRangefix(enemy_hp)
				if self.player:distanceTo(enemy, rangefix) <= range then
					for _, id in ipairs(card_ids) do
						table.insert(hp_ids, id)
						if #hp_ids == enemy_hp then 
							break 
						end
					end
					local card_str = "@DuwuCard=" .. table.concat(hp_ids, "+")
					use.card = sgs.Card_Parse(card_str)
					if use.to then 
						use.to:append(enemy) 
					end
					return
				end
			else
				if not isWeak or self:getSaveNum(true) >= 1 then
					local rangefix = getRangefix(1)
					if self.player:distanceTo(enemy, rangefix) <= range then
						local card_str = "@DuwuCard=" .. card_ids[1]
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
--[[
	套路：仅使用“黩武技能卡”
]]--
sgs.ai_series["DuwuCardOnly"] = {
	name = "DuwuCardOnly",
	IQ = 2,
	value = 3,
	priority = 1,
	skills = "duwu",
	cards = {
		["DuwuCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local duwu_skill = sgs.ai_skills["duwu"]
		local dummyCard = duwu_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["DuwuCard"], "DuwuCardOnly")