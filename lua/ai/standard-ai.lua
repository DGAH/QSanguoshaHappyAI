--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）标准武将包部分
]]--
--[[****************************************************************
	武将：标准·曹操（魏）
]]--****************************************************************
--[[
	技能：奸雄
	描述：每当你受到一次伤害后，你可以获得对你造成伤害的牌。 
]]--
sgs.ai_skill_invoke["jianxiong"] = function(self, data)
	if self.jianxiong then 
		self.jianxiong = nil 
		return true 
	end
	return not self:needKongcheng(self.player, true)
end
--[[
	技能：护驾（主公技）
	描述：每当你需要使用或打出一张【闪】时，你可以令其他魏势力角色选择是否打出一张【闪】（视为由你使用或打出）。 
]]--
table.insert(sgs.ai_global_flags, "hujiasource")
sgs.ai_skill_invoke["hujia"] = function(self, data)
	if sgs.hujiasource then 
		return false 
	end
	local asked = data:toStringList()
	local prompt = asked[2]
	if not self.player:hasFlag("ai_hantong") then
		if self:askForCard("jink", prompt, 1) == "." then 
			return false 
		end
	end
	local cards = self.player:getHandcards()
	for _, friend in ipairs(self.partners_noself) do
		if friend:getKingdom() == "wei" then
			if self:hasEightDiagramEffect(friend) then 
				return true 
			end
		end
	end
	local current = self.room:getCurrent()
	if self:isPartner(current) then
		if current:getKingdom() == "wei" then
			if self:getOverflow(current) > 2 then
				return true
			end
		end
	end
	for _, card in sgs.qlist(cards) do
		if sgs.isCard("Jink", card, self.player) then
			return false
		end
	end
	local lieges = self.room:getLieges("wei", self.player)
	if lieges:isEmpty() then 
		return false
	end
	for _, p in sgs.qlist(lieges) do
		if self:isPartner(p) then
			return true
		elseif self:isNeutral(p, self.player) then
			return true
		end
	end
	return false
end
sgs.ai_skill_cardask["@hujia-jink"] = function(self)
	if #sgs.ai_lords > 0 then
		local YuanShu = self.room:findPlayerBySkillName("weidi")
		if not sgs.hujiasource then
			if not YuanShu then
				sgs.hujiasource = self.room:getLord()
			end
		end
		if sgs.hujiasource then 
			if self:isPartner(sgs.hujiasource) then
				if self:needBear() then
					return "."
				end
				local ZhangFei = self.room:findPlayerBySkillName("dahe")
				if ZhangFei then
					if ZhangFei:isAlive() then
						if sgs.hujiasource:hasFlag("dahe") then
							local jinks = self:getCards("Jink")
							for _,jink in ipairs(jinks) do
								if jink:getSuit() == sgs.Card_Heart then
									return jink:getId()
								end
							end
						end
					end
				end
				return self:getCardId("Jink") or "."
			end
		end
	end
	return "."
end
sgs.ai_choicemade_filter.skillInvoke["hujia"] = function(player, promptlist)
	if promptlist[#promptlist] == "yes" then
		sgs.hujiasource = player
	end
end
sgs.ai_choicemade_filter.cardResponded["@hujia-jink"] = function(player, promptlist)
	if promptlist[#promptlist] ~= "_nil_" then
		sgs.updateIntention(player, sgs.hujiasource, -80)
		sgs.hujiasource = nil
	elseif sgs.hujiasource then
		local lieges = player:getRoom():getLieges("wei", sgs.hujiasource)
		if lieges and not lieges:isEmpty() then
			if player:objectName() == lieges:last():objectName() then
				sgs.hujiasource = nil
			end
		end
	end
end
sgs.slash_prohibit_system["hujia"] = {
	name = "hujia",
	reason = "hujia",
	judge_func = function(self, target, source, slash)
		--友方
		if self:isPartner(target) then 
			return false 
		end
		--天妒
		local guojia = self.room:findPlayerBySkillName("tiandu")
		if guojia then
			if guojia:getKingdom() == "wei" then
				if self:isPartner(target, guojia) then 
					local item = sgs.slash_prohibit_system["tiandu"]
					if item then
						local callback = item["judge_func"]
						if callback and callback(self, guojia, source, slash) then
							return true
						end
					end
				end
			end
		end
		return false
	end
}
--[[****************************************************************
	武将：标准·司马懿（魏）
]]--****************************************************************
sgs.ai_chaofeng.simayi = -2
--[[
	技能：反馈
	描述：每当你受到一次伤害后，你可以获得伤害来源的一张牌。 
]]--
sgs.ai_skill_invoke["fankui"] = function(self, data)
	local target = data:toPlayer()
	if sgs.ai_damage_requirement["fankui"](self, target, self.player) then 
		return true 
	end
	if self:isPartner(target) then
		if self:getOverflow(target) > 2 then 
			return true 
		end
		if self:doNotDiscard(target) then 
			return true 
		end
		if self:hasSkills(sgs.lose_equip_skill, target) then
			local equips = target:getEquips()
			if not equips:isEmpty() then
				return true
			end
		end
		if self:needToThrowArmor(target) then
			if target:getArmor() then
				return true
			end
		end
		return false
	elseif self:isOpponent(target) then
		if self:doNotDiscard(target) then 
			return false 
		end
		return true
	end
	return true
end
sgs.ai_skill_cardchosen["fankui"] = function(self, who, flags)
	local suit_str = sgs.ai_damage_requirement["fankui"](self, who, self.player)
	if suit_str then
		local equips = who:getEquips()
		local cards = sgs.QList2Table(equips)
		local handcards = who:getHandcards()
		handcards = sgs.QList2Table(handcards)
		if #handcards==1 then
			if handcards[1]:hasFlag("visible") then 
				table.insert(cards, handcards[1]) 
			end
		end
		for i=1, #cards, 1 do
			local suit = cards[i]:getSuitString()
			if suit_str == "spade" then
				if suit == suit_str then
					local point = cards[i]:getNumber()
					if point >= 2 then
						if point <= 9 then
							return cards[i]
						end
					end
				end
			elseif suit == suit_str then
				return cards[i]
			end
		end
	end
	return nil
end
sgs.ai_damage_requirement["fankui"] = function(self, source, target)
	if target:hasSkill("fankui") then
		if target:hasSkill("guicai") then
			local function need_retrial(player)
				local aliveCount = self.room:alivePlayerCount()
				local mySeat = player:getSeat()
				local current = self.room:getCurrent()
				local currentSeat = current:getSeat()
				if aliveCount + mySeat % aliveCount > currentSeat then
					if mySeat < aliveCount + mySeat % aliveCount then
						return true
					end
				end
				return false
			end
			local retrial_card = {
				spade = nil,
				heart = nil,
				club = nil,
			}
			local source_card = {
				spade = nil,
				heart = nil,
				club = nil,
			}
			local handcards = target:getHandcards()
			handcards = sgs.QList2Table(handcards)
			for i=1, #handcards, 1 do
				local card = handcards[i]
				local suit = card:getSuit()
				local point = card:getNumber()
				if suit == sgs.Card_Spade then
					if point >= 2 then
						if point <= 9 then
							retrial_card["spade"] = true
						end
					end
				elseif suit == sgs.Card_Heart then
					retrial_card["heart"] = true
				elseif suit == sgs.Card_Club then
					retrial_card["club"] = true
				end
			end
			local cards = source:getEquips()
			cards = sgs.QList2Table(cards)
			if source:getHandcardNum() == 1 then
				handcards = source:getHandcards()
				local card = handcards:first()
				if card:hasFlag("visible") then
					table.insert(cards, card)
				end
			end
			for i=1, #cards, 1 do
				local card = cards[i]
				local suit = card:getSuit()
				local point = card:getNumber()
				if suit == sgs.Card_Spade then
					if point >= 2 then
						if point <= 9 then
							source_card["spade"] = true
						end
					end
				elseif suit == sgs.Card_Heart then
					source_card["heart"] = true
				elseif suit == sgs.Card_Club then
					source_card["club"] = sgs.Card_Club
				end
			end
			local others = self.room:getOtherPlayers(target)
			for _,p in sgs.qlist(others) do
				if need_retrial(p) then
					if self:getFinalRetrial(p) == 1 then
						if p:containsTrick("lightning") then
							if source_card["spade"] then
								if not retrial_card["spade"] then
									return "spade"
								end
							end
						end
						if self:isPartner(p, target) then
							if not p:containsTrick("YanxiaoCard") then
								if not p:hasSkill("qiaobian") then
									if p:containsTrick("indulgence") then
										if p:getHandcardNum() >= p:getHp() then
											if source_card["heart"] then
												if not retrial_card["heart"] then
													return "heart"
												end
											end
										end
									end
									if p:containsTrick("supply_shortage") then
										if self:hasSkills("yongsi", p) then
											if source_card["club"] then
												if not retrial_card["club"] then
													return "club"
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
	end
	return false
end
--[[
	技能：鬼才
	描述：每当一名角色的判定牌生效前，你可以打出一张手牌代替之。 
]]--
sgs.ai_skill_cardask["@guicai-card"] = function(self, data)
	if not self.player:isKongcheng() then
		local judge = data:toJudge()
		if self:needRetrial(judge) then
			local handcards = self.player:getHandcards() 
			local cards = sgs.QList2Table(handcards)
			local card_id = self:getRetrialCardId(cards, judge)
			if card_id ~= -1 then
				return "$" .. card_id
			end
		end
	end
	return "."
end
sgs.ai_wizard_system["guicai"] = {
	name = "guicai",
	skill = "guicai",
	retrial_enabled = function(self, source, target)
		if source:hasSkill("guicai") then
			if not source:isKongcheng() then
				return true
			end
		end
		return false
	end,
}
sgs.guicai_suit_value = {
	heart = 3.9,
	club = 3.9,
	spade = 3.5,
}
--[[
	内容：“鬼才”卡牌需求
]]--
sgs.card_need_system["guicai"] = function(self, card, player)
	if self:getFinalRetrial(player) == 1 then
		local suit = card:getSuit()
		local alives = self.room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			if suit == sgs.Card_Spade then
				if p:containsTrick("lightning") then
					if not p:containsTrick("YanxiaoCard") then
						if card:getNumber() >= 2 then
							if card:getNumber() <= 9 then
								return not self:hasSkills("hongyan|wuyan")
							end
						end
					end
				end
			elseif suit == sgs.Card_Heart then
				if self:isPartner(p) then
					return self:willSkipPlayPhase(p)
				end
			elseif suit == sgs.Card_Club then
				if self:isPartner(p) then
					return self:willSkipDrawPhase(p)
				end
			end
		end
	end
	return false
end
--[[****************************************************************
	武将：标准·夏侯惇（魏）
]]--****************************************************************
sgs.ai_chaofeng.xiahoudun = -3
--[[
	技能：刚烈
	描述：每当你受到一次伤害后，你可以进行一次判定，若判定结果不为♥，则伤害来源选择一项：弃置两张手牌，或受到你造成的1点伤害。 
]]--
--[[
	功能：获取刚烈弃牌
	参数：discard_num（number类型，表示弃牌数目） 
		min_num（number类型，表示最少弃牌数目）
		optional（boolean类型，表示是否可以不弃）
		include_equip（boolean类型，表示是否可以弃装备牌）
		skill_name（string类型，表示弃牌原因）
	结果：table类型，表示所有弃牌的编号
]]--
function SmartAI:getGanglieDiscard(discard_num, min_num, optional, include_equip, skill_name)
	local XiaHouDun = self.room:findPlayerBySkillName(skill_name)
	if XiaHouDun then
		if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, XiaHouDun) then
			return {}
		elseif self:invokeDamagedEffect(self.player, XiaHouDun) then
			return {}
		elseif self:needToLoseHp(self.player, XiaHouDun) then
			return {}
		end
	end
	local to_discard = {}
	local handcards = self.player:getHandcards()
	local cards = sgs.QList2Table(handcards)
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
	self:sortByKeepValue(cards, true)
	for i=#cards, 1, -1 do
		local card = cards[i]
		if not sgs.isCard("Peach", card, self.player) then
			if not self.player:isJilei(card) then
				table.insert(to_discard, card:getEffectiveId())
				table.remove(cards, i)
				index = index + 1
				if index == 2 then 
					break 
				end
			end
		end
	end
	if #to_discard < 2 then 
		return {}
	end
	return to_discard
end
sgs.ai_skill_invoke["ganglie"] = function(self, data)
	local damage = data:toDamage()
	return true
end
sgs.ai_skill_discard["ganglie"] = function(self, discard_num, min_num, optional, include_equip)
	return self:getGanglieDiscard(discard_num, min_num, optional, include_equip, "ganglie")
end
sgs.slash_prohibit_system["ganglie"] = {
	name = "ganglie",
	reason = "ganglie",
	judge_func = function(self, target, source, slash)
		--友方
		if self:isPartner(source, target) then
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
		--刚烈
		local num = source:getHandcardNum()
		local hp = source:getHp()
		return num + hp < 4
	end
}
sgs.ai_damage_requirement["ganglie"] = function(self, source, target)
	if not source:hasSkill("ganglie") then
		if self:invokeDamagedEffect(source, target) then 
			return self:isPartner(source, target) 
		end
	end
	if self:isOpponent(source) then
		local num = source:getHandcardNum()
		if source:getHp() + num <= 3 then
			local enemies = self:getOpponents(source)
			if sgs.isGoodTarget(self, source, enemies) then
				local skills = sgs.need_kongcheng .. "|buqu"
				if not self:hasSkills(skills, source) then
					return true
				elseif num <= 1 then
					return true
				end
			end
		end
	end
	return false
end
--[[****************************************************************
	武将：标准·张辽（魏）
]]--****************************************************************
sgs.ai_chaofeng.zhangliao = 4
--[[
	技能：突袭
	描述：摸牌阶段开始时，你可以放弃摸牌并选择一至两名有手牌的其他角色，改为获得他们的各一张手牌。 
]]--
--[[
	内容：“突袭技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["TuxiCard"] = function(self, card, source, targets)
	local lord = self:getMyLord()
	local tuxi_lord = false
	if source:getState() == "online" then
		for _, to in ipairs(targets) do
			local intention = 80
			if self:hasSkills("kongcheng|lianying|jizhi", to) then
				intention = 0
			elseif self:hasAllSkills("tuntian+zaoxian", to) then
				intention = 0
			end
			sgs.updateIntention(source, to, intention)
		end
	else
		for _, to in ipairs(targets) do
			if lord then
				if to:objectName() == lord:objectName() then 
					tuxi_lord = true 
				end
			end
			local intention = 80
			if source:hasFlag("tuxi_isfriend_"..to:objectName()) then
				intention = -5
			end
			sgs.updateIntention(source, to, intention)
		end
		if sgs.turncount == 1 then
			if not tuxi_lord and lord then
				if not lord:isKongcheng() then
					if self.room:alivePlayerCount() > 2 then 
						sgs.updateIntention(source, lord, -80) 
					end
				end
			end
		end
	end
end
sgs.ai_skill_use["@@tuxi"] = function(self, prompt)
	self:sort(self.opponents, "handcard")
	local targets = {}
	local ZhuGeLiang = self.room:findPlayerBySkillName("kongcheng")
	local LuXun = self.room:findPlayerBySkillName("lianying")
	local DengAi = self.room:findPlayerBySkillName("tuntian")
	local JiangWei = self.room:findPlayerBySkillName("zhiji")
	local wisJiangWei = self.room:findPlayerBySkillName("beifa")
	local myname = self.player:objectName()
	local function addTarget(player, isFriend)
		if player:getHandcardNum() == 0 then
			return #targets
		elseif player:objectName() == myname then 
			return #targets 
		end
		if #targets == 0 then 
			table.insert(targets, player:objectName())
		elseif #targets == 1 then
			if player:objectName() ~= targets[1] then 
				table.insert(targets, player:objectName()) 
			end
		end
		if isfriend and isfriend == 1 then
			self.player:setFlags("tuxi_isfriend_" .. player:objectName())
		end
		return #targets
	end
	local lord = self.room:getLord()
	if lord then
		if self:isOpponent(lord) then
			if sgs.turncount <= 1 then
				if not lord:isKongcheng() then
					addTarget(lord)
				end
			end
		end
	end
	if JiangWei then
		if self:isPartner(JiangWei) then
			if JiangWei:getMark("zhiji") == 0 then
				if JiangWei:getHandcardNum() == 1 then
					local hp = JiangWei:getHp()
					local deltSeat = 0
					if hp >= 3 then
						deltSeat = 1
					end
					if self:getOpponentNumBySeat(self.player, JiangWei) <= deltSeat then
						if addTarget(JiangWei, 1) == 2 then 
							return ("@TuxiCard=.->%s+%s"):format(targets[1], targets[2]) 
						end
					end
				end
			end
		end
	end
	if DengAi then
		if self:isPartner(DengAi) then
			if DengAi:hasSkill("zaoxian") then
				if DengAi:getMark("zaoxian") == 0 then
					if DengAi:getPile("field"):length() == 2 then
						local flag = false
						if not self:isWeak(DengAi) then
							flag = true
						elseif self:getOpponentNumBySeat(self.player, DengAi) == 0 then
							flag = true
						end
						if flag then
							if addTarget(DengAi, 1) == 2 then 
								return ("@TuxiCard=.->%s+%s"):format(targets[1], targets[2]) 
							end
						end
					end
				end
			end
		end
	end
	if ZhuGeLiang then
		if self:isPartner(ZhuGeLiang) then
			if ZhuGeLiang:getHandcardNum() == 1 then
				if self:getOpponentNumBySeat(self.player, ZhuGeLiang) > 0 then
					if ZhuGeLiang:getHp() <= 2 then
						if addTarget(ZhuGeLiang, 1) == 2 then 
							return ("@TuxiCard=.->%s+%s"):format(targets[1], targets[2]) 
						end
					else
						local flag = string.format("visible_%s_%s", myname, ZhuGeLiang:objectName())
						local handcards = ZhuGeLiang:getHandcards()
						local cards = sgs.QList2Table(handcards)
						if #cards == 1 then
							local card = cards[1]
							if card:hasFlag("visible") or card:hasFlag(flag) then
								if sgs.isKindOf("TrickCard|Slash|EquipCard", card) then
									if addTarget(ZhuGeLiang, 1) == 2 then 
										return ("@TuxiCard=.->%s+%s"):format(targets[1], targets[2]) 
									end
								end
							end
						end
					end
				end
			end
		end
	end
	if LuXun then
		if self:isPartner(LuXun) then
			if LuXun:getHandcardNum() == 1 then
				if self:getOpponentNumBySeat(self.player, LuXun) > 0 then	
					local flag = string.format("visible_%s_%s", myname, LuXun:objectName())
					local handcards = LuXun:getHandcards()
					local cards = sgs.QList2Table(handcards)
					if #cards == 1 then
						local card = cards[1]
						if card:hasFlag("visible") or card:hasFlag(flag) then
							if sgs.isKindOf("TrickCard|Slash|EquipCard", card) then
								if addTarget(LuXun, 1) == 2 then 
									return ("@TuxiCard=.->%s+%s"):format(targets[1], targets[2]) 
								end
							end
						end
					end	
				end
			end
		end
	end
	if wisJiangWei then
		if self:isPartner(wisJiangWei) then
			if wisJiangWei:getHandcardNum()== 1 then
				local hp = wisJiangWei:getHp()
				local deltSeat = 0
				if hp >= 3 then
					deltSeat = 1
				end
				if self:getOpponentNumBySeat(self.player, wisJiangWei) <= deltSeat then
					local isGood = false
					for _, enemy in ipairs(self.opponents) do
						if wisJiangWei:canSlash(enemy, sgs.slash) then
							if not self:slashIsProhibited(sgs.slash, enemy, wisJiangWei) then
								local isEffective = false
								if self:slashIsEffective(sgs.slash, enemy, wisJiangWei) then
									if sgs.isGoodTarget(self, enemy, self.opponents) then
										isEffective = true
									end
								end
								if isEffective then
									local defense = sgs.getDefenseSlash(enemy)
									if defense < 4 then
										isGood = true
									end
								end
							end
						end
					end
					if isGood then
						if addTarget(wisJiangWei, 1) == 2 then 
							return ("@TuxiCard=.->%s+%s"):format(targets[1], targets[2]) 
						end
					end
				end
			end
		end
	end
	for i=1, #self.opponents, 1 do
		local p = self.opponents[i]
		local handcards = p:getHandcards()
		local cards = sgs.QList2Table(handcards)
		local flag = string.format("visible_%s_%s", myname, p:objectName())
		for _,card in ipairs(cards) do
			if card:hasFlag("visible") or card:hasFlag(flag) then
				if sgs.isKindOf("Peach|Nullification|Analeptic", card) then
					if addTarget(p) == 2 then 
						return ("@TuxiCard=.->%s+%s"):format(targets[1], targets[2]) 
					end
				end
			end
		end
	end
	for i=1, #self.opponents, 1 do
		local p = self.opponents[i]
		local skills = "jilve|jijiu|qingnang|xinzhan|leiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian"
		if self:hasSkills(skills, p) then
			if addTarget(p) == 2 then 
				return ("@TuxiCard=.->%s+%s"):format(targets[1], targets[2]) 
			end
		end
	end
	for i=1, #self.opponents, 1 do
		local p = self.opponents[i]
		local num = p:getHandcardNum()
		local good_target = true
		if num == 1 then
			if self:needKongcheng(p) then 
				good_target = false 
			end
		elseif num >= 2 then
			if p:hasSkill("tuntian") then
				if p:hasSkill("zaoxian") then 
					good_target = false 
				end
			end
		end
		if good_target then
			if addTarget(p) == 2 then 
				return ("@TuxiCard=.->%s+%s"):format(targets[1], targets[2]) 
			end
		end
	end
	if LuXun then
		local isFriend
		if self:isPartner(LuXun) then
			isFriend = 1
		end
		if addTarget(LuXun, isFriend) == 2 then 
			return ("@TuxiCard=.->%s+%s"):format(targets[1], targets[2]) 
		end
	end
	if DengAi then
		if self:isPartner(DengAi) then
			if DengAi:hasSkill("zaoxian") then
				local flag = false
				if not self:isWeak(DengAi) then
					flag = true
				elseif self:getOpponentNumBySeat(self.player, DengAi) == 0 then
					flag = true
				end
				if flag then
					if addTarget(DengAi, 1) == 2 then 
						return ("@TuxiCard=.->%s+%s"):format(targets[1], targets[2]) 
					end
				end
			end
		end
	end
	local others = self.room:getOtherPlayers(self.player)
	for _,other in sgs.qlist(others) do
		if self:isOpponent(other) then
			local flag = true
			if other:hasSkill("tuntian") then
				if other:hasSkill("zaoxian") then
					flag = false
				end
			end
			if flag then
				if addTarget(other) == 2 then
					return ("@TuxiCard=.->%s+%s"):format(targets[1], targets[2])
				end
			end
		end
	end
	for _,other in sgs.qlist(others) do
		if self:isOpponent(other) then
			local flag = true
			if other:hasSkill("tuntian") then
				if other:hasSkill("zaoxian") then
					flag = false
				end
			end
			if flag then
				if addTarget(other) == 1 then
					if math.random(0, 5) <= 1 then
						if not self:hasSkills("qiaobian") then
							return ("@TuxiCard=.->%s"):format(targets[1])
						end
					end
				end
			end
		end
	end
	return "."
end
sgs.draw_cards_system["tuxi"] = {
	name = "tuxi",
	return_func = function(self, player)
		local others = self.room:getOtherPlayers(player)
		return math.min(2, others:length())
	end,
}
--[[****************************************************************
	武将：标准·许褚（魏）
]]--****************************************************************
sgs.ai_chaofeng.xuchu = 3
--[[
	技能：裸衣
	描述：摸牌阶段，你可以少摸一张牌，若如此做，每当你于此回合内使用【杀】或【决斗】对目标角色造成伤害时，此伤害+1。 
]]--
sgs.ai_skill_invoke["luoyi"] = function(self, data)
	if self.player:isSkipped(sgs.Player_Play) then 
		return false 
	end
	if self:needBear() then 
		return false 
	end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local slashTarget = 0
	local duelTarget = 0
	self:sort(self.opponents, "hp")
	for _,card in ipairs(cards) do
		if card:isKindOf("Slash") then
			for _,enemy in ipairs(self.opponents) do
				if self.player:canSlash(enemy, card, true) then
					if self:slashIsEffective(card, enemy) then
						if self:friendshipLevel(enemy) < -4 then
							if sgs.isGoodTarget(self, enemy, self.opponents) then
								if sgs.getCardsNum("Jink", enemy) < 1 then
									slashTarget = slashTarget + 1
								elseif self:isEquip("Axe") then
									if self.player:getCards("he"):length() > 4 then
										slashTarget = slashTarget + 1
									end
								end
							end
						end
					end
				end
			end
		elseif card:isKindOf("Duel") then
			for _, enemy in ipairs(self.opponents) do
				if self:getCardsNum("Slash") >= sgs.getCardsNum("Slash", enemy) then
					if sgs.isGoodTarget(self, enemy, self.opponents) then
						if self:friendshipLevel(enemy) < -4 then
							if not self:cannotBeHurt(enemy, 2) then
								if self:damageIsEffective(enemy) then
									if enemy:getMark("@late") < 1 then
										duelTarget = duelTarget + 1 
									end
								end
							end
						end
					end
				end
			end
		end
	end	
	if (slashTarget + duelTarget) > 0 then
		self:speak("luoyi")
		return true
	end
	return false
end
sgs.heavy_slash_system["luoyi"] = {
	name = "luoyi",
	reason = "luoyi",
	extra_func = function(source, slash, target, isFireSlash, isThunderSlash)
		if source:hasFlag("luoyi") then
			return 1
		end
		return 0
	end,
}
sgs.draw_cards_system["luoyi"] = {
	name = "luoyi",
	correct_func = function(self, player)
		return -1
	end,
}
sgs.luoyi_keep_value = {
	Peach 			= 6,
	Analeptic 		= 5.8,
	Jink 			= 5.2,
	Duel			= 5.5,
	FireSlash 		= 5.6,
	Slash 			= 5.4,
	ThunderSlash 	= 5.5,	
	Axe				= 5,
	Blade 			= 4.9,
	Spear 			= 4.9,
	Fan				= 4.8,
	KylinBow		= 4.7,
	Halberd			= 4.6,
	MoonSpear		= 4.5,
	SPMoonSpear 	= 4.5,
	DefensiveHorse 	= 4
}
--[[
	内容：“裸衣”卡牌需求
]]--
sgs.card_need_system["luoyi"] = function(self, card, player)
	local slash_num = 0
	local target
	local cards = player:getHandcards()
	local need_slash = true
	local current = self.room:getCurrent()
	local flag = string.format("visible_%s_%s", current:objectName(), player:objectName())
	for _, c in sgs.qlist(cards) do
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if sgs.isCard("Slash", c, player) then
				need_slash = false
				break
			end	  
		end
	end
	self:sort(self.opponents, "defenseSlash")
	for _, enemy in ipairs(self.opponents) do
		if player:canSlash(enemy) then
			if self:willUseSlash(enemy, player, sgs.slash) then
				if self:slashIsEffective(sgs.slash, enemy) then
					if sgs.getDefenseSlash(enemy) <= 2 then
						target = enemy
						break
					end
				end
			end
		end
	end
	if need_slash and target then
		if sgs.isCard("Slash", card, player) then 
			return true 
		end
	end
	return sgs.isCard("Duel", card, player)  
end
--[[****************************************************************
	武将：标准·郭嘉（魏）
]]--****************************************************************
sgs.ai_chaofeng.guojia = -4
--[[
	技能：天妒
	描述：每当你的判定牌生效后，你可以获得之。 
]]--
sgs.ai_skill_invoke["tiandu"] = sgs.ai_skill_invoke["jianxiong"]
sgs.slash_prohibit_system["tiandu"] = {
	name = "tiandu",
	reason = "tiandu",
	judge_func = function(self, target, source, slash)
		--烈弓
		if self:canLiegong(target, source) then
			return false
		end
		--八卦阵
		if self:isOpponent(target, source) then
			local enemies = self:getOpponents(source)
			if #enemies > 1 then
				if self:hasEightDiagramEffect(target) then
					if not sgs.IgnoreArmor(source, target) then
						return true
					end
				end
			end
		end
		return false
	end
}
--[[
	技能：遗计
	描述：每当你受到1点伤害后，你可以观看牌堆顶的两张牌，然后将一张牌交给一名角色，将另一张牌交给一名角色。 
]]--
sgs.ai_skill_invoke["yiji"] = function(self, data)
	if self.player:getHandcardNum() < 2 then 
		return true 
	end
	local Shenfen_user
	local alives = self.room:getAlivePlayers()
	for _, player in sgs.qlist(alives) do
		if player:hasFlag("ShenfenUsing") then
			Shenfen_user = player
			break
		end
	end
	for _,friend in ipairs(self.partners) do
		local flag = true
		if friend:hasSkill("manjuan") then
			if friend:getPhase() == sgs.Player_NotActive then
				flag = false
			end
		end
		if flag then
			if not self:needKongcheng(friend, true) then
				if not self:isLihunTarget(friend) then
					if not Shenfen_user then
						return true
					elseif Shenfen_user:objectName() == friend:objectName() then
						return true
					elseif friend:getHandcardNum() >= 4 then
						return true
					end
				end
			end
		end
	end
	return false
end
sgs.ai_skill_askforyiji["yiji"] = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(card_id)
		table.insert(cards, card)
	end
	local Shenfen_user
	local alives = self.room:getAlivePlayers()
	for _,player in sgs.qlist(alives) do
		if player:hasFlag("ShenfenUsing") then
			Shenfen_user = player
			break
		end
	end
	if Shenfen_user then
		if self:isPartner(Shenfen_user) then
			if Shenfen_user:objectName() ~= self.player:objectName() then
				for _, id in ipairs(card_ids) do
					return Shenfen_user, id
				end
			else
				return nil, -1
			end
		else
			if self.player:getHandcardNum() < self:getOverflow(false, true) then
				return nil, -1
			end
			local card, friend = self:getCardNeedPlayer(cards)
			if card and friend then
				if friend:getHandcardNum() >= 4 then
					return friend, card:getId()
				end
			end
		end
	else
		if self.player:getHandcardNum() <= 2 then
			return nil, -1
		end
	end
	local friends = {}
	local canKeep = false
	for _,friend in ipairs(self.partners) do
		if not self:needKongcheng(friend, true) then
			if not self:isLihunTarget(friend) then
				local flag = true
				if friend:hasSkill("manjuan") then
					if friend:objectName() == sgs.Player_NotActive then
						flag = false
					end
				end
				if flag then
					flag = false
					if not Shenfen_user then
						flag = true
					elseif friend:objectName() == Shenfen_user:objectName() then
						flag = true
					elseif friend:getHandcardNum() >= 4 then
						flag = true
					end
					if flag then
						if friend:objectName() == self.player:objectName() then 
							canKeep = true
						else 
							table.insert(friends, friend)
						end
					end
				end
			end
		end
	end
	if #friends > 0 then
		local card, target = self:getCardNeedPlayer(cards)
		if card and target then
			for _, friend in ipairs(friends) do
				if target:objectName() == friend:objectName() then
					return friend, card:getEffectiveId()
				end
			end
		end
		if Shenfen_user then
			if self:isPartner(Shenfen_user) then
				return Shenfen_user, cards[1]:getEffectiveId()
			end
		end
		self:sort(friends, "defense")
		self:sortByKeepValue(cards, true)
		return friends[1], cards[1]:getEffectiveId()
	elseif canKeep then
		return nil, -1
	else
		local other = {}
		local others = self.room:getOtherPlayers(self.player)
		for _, player in sgs.qlist(others) do
			local flag = true
			if self:isLihunTarget(player) then
				if self:isPartner(player) then
					flag = false
				end
			end
			if flag then
				if self:isPartner(player) then
					table.insert(other, player)
				elseif not player:hasSkill("lihun") then
					table.insert(other, player)
				end
			end
		end
		return other[math.random(1, #other)], card_ids[math.random(1, #card_ids)]
	end
end
sgs.ai_damage_requirement["yiji"] = function(self, source, target)
	if target:hasSkill("yiji") then
		local need_card = false
		local current = self.room:getCurrent()
		if self:isEquip("Crossbow", current) then
			need_card = true
		elseif current:hasSkill("paoxiao") then
			need_card = true
		elseif current:hasFlag("shuangxiong") then
			need_card = true
		elseif self:hasSkills("jieyin|jijiu", current) then
			if self:getOverflow(current) <= 0 then
				need_card = true
			end
		end
		if need_card then
			if self:isPartner(current, target) then
				return true
			end
		end
		local friends = {}
		local alives = self.room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			if self:isPartner(p, target) then
				table.insert(friends, p)
			end
		end
		self:sort(friends, "hp")
		local count = #friends
		if count > 0 then
			if friends[1]:objectName() == target:objectName() then
				if self:isWeak(target) then
					if self:getCardsNum("Peach", target) == 0 then
						return false
					end
				end
			end
			if count > 1 then
				if self:isWeak(friends[2]) then
					return true
				end
				if target:getHp() > 2 then
					if sgs.turncount > 2 then
						return true
					end
				end
			end
		end
	end
	return false
end
--[[****************************************************************
	武将：标准·甄姬（魏）
]]--****************************************************************
--[[
	技能：倾国
	描述：你可以将一张黑色手牌当【闪】使用或打出。 
]]--
sgs.ai_view_as["qingguo"] = function(card, player, place, class_name)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isBlack() and place == sgs.Player_PlaceHand then
		return ("jink:qingguo[%s:%s]=%d"):format(suit, number, card_id)
	end
end
sgs.qingguo_suit_value = {
	spade = 4.1,
	club = 4.2
}
--[[
	内容：“倾国”卡牌需求
]]--
sgs.card_need_system["qingguo"] = function(self, card, player)
	if card:isBlack() then
		local cards = player:getCards("h")
		return cards:length() < 2
	end
	return false
end
--[[
	内容：“倾国”统计信息
]]--
sgs.card_count_system["qingguo"] = {
	name = "qingguo",
	pattern = "Jink",
	ratio = 0.85,
	statistics_func = function(class_name, player, data)
		local count = data["count"]
		count = count + data["Black"] 
		local equips = player:getCards("e")
		for _,equip in sgs.qlist(equips) do
			if equip:isBlack() then
				count = count - 1
			end
		end
		count = count + data["unknown"] * 0.85
		return count
	end
}
--[[
	技能：洛神
	描述：准备阶段开始时，你可以进行一次判定，若判定结果为黑色，你获得生效后的判定牌且你可以重复此流程。 
]]--
sgs.ai_skill_invoke["luoshen"] = function(self, data)
	if self:willSkipPlayPhase() then
		local ErZhang = self.room:findPlayerBySkillName("guzheng")
		if ErZhang then
			if self:isOpponent(ErZhang) then 
				return false 
			end
		end
	end
	return true
end
--[[****************************************************************
	武将：标准·刘备（蜀）
]]--****************************************************************
sgs.ai_chaofeng.liubei = -2
--[[
	技能：仁德
	描述：出牌阶段限一次，你可以将任意数量的手牌以任意分配方式交给任意数量的其他角色，然后当你于以此法交给其他角色的手牌首次达到两张或更多时，你回复1点体力。 
]]--
--[[
	功能：判断是否应当发动仁德而不是直接使用卡牌
	参数：无
	结果：boolean类型，表示是否应发动
]]--
function SmartAI:shouldUseRende()
	local slashCount = self:getCardsNum("Slash")
	if slashCount > 0 then
		local hasCrossbow = false
		if self:hasCrossbowEffect() then
			hasCrossbow = true
		elseif self:getCardsNum("Crossbow") > 0 then
			hasCrossbow = true
		end
		if hasCrossbow then
			self:sort(self.opponents, "defense")
			for _,enemy in ipairs(self.opponents) do
				local distance = self.player:distanceTo(enemy)
				local inMyAttackRange = false
				if distance == 1 then
					inMyAttackRange = true
				elseif distance == 2 then
					if not self.player:getOffensiveHorse() then
						if self:getCardsNum("OffensiveHorse") > 0 then
							inMyAttackRange = true
						end
					end
				end
				if inMyAttackRange then
					local can_use = false
					if enemy:getHp() == 1 then
						if sgs.getCardsNum("Peach", enemy) < 1 then
							can_use = true
						end
					end
					if not can_use then
						local skills = "fenyong|zhichi|fankui|neoganglie|ganglie|enyuan|nosenyuan|langgu|guixin"
						if not self:hasSkills(skills, enemy) then
							can_use = true
						end
					end
					if can_use then
						local slashes = self:getCards("Slash")
						local slash_count = 0
						for _,slash in ipairs(slashes) do
							if not self:slashIsProhibited(enemy, self.player, slash) then
								slash_count = slash_count + 1
							end
						end
						if slash_count >= enemy:getHp() then 
							return false 
						end
					end
				end
			end
		end
	end
	for _,enemy in ipairs(self.opponents) do
		if enemy:canSlash(self.player) then
			if not self:slashIsProhibited(self.player, enemy, sgs.slash) then
				if self:isEquip("GudingBlade", enemy) then
					if self.player:getHandcardNum() == 1 then
						if sgs.getCardsNum("Slash", enemy) >= 1 then
							return false
						end
					end
				elseif self:isEquip("Crossbow", enemy) then
					if self:getOverflow() <= 0 then
						return false
					end
				end
			end
		end
	end
	for _,friend in ipairs(self.partners_noself) do
		if friend:hasSkill("jijiu") then
			return true
		elseif friend:hasSkill("haoshi") then
			if friend:containsTrick("supply_shortage") then
				if friend:containsTrick("YanxiaoCard") then
					return true
				end
			else
				return true
			end
		end
	end
	if self.player:usedTimes("RendeCard") < 2 then
		return true
	elseif self:getOverflow() > 0 then
		return true
	elseif self.player:getLostHp() < 2 then
		return true
	end
	return false
end
--[[
	内容：“仁德技能卡”的卡牌成分
]]--
sgs.card_constituent["RendeCard"] = {
	benefit = 1,
	use_value = 8.5,
	use_priority = 8.8,
}
--[[
	内容：“仁德技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["RendeCard"] = function(self, card, source, targets)
	local target = targets[1]
	local intention = -70
	if target:hasSkill("manjuan") then
		if target:getPhase() == sgs.Player_NotActive then
			intention = 0
		end
	end
	if target:hasSkill("kongcheng") then
		if target:isKongcheng() then
			intention = 30
		end
	end
	sgs.updateIntention(source, target, intention)
end
--[[
	内容：注册“仁德技能卡”
]]--
sgs.RegistCard("RendeCard")
--[[
	内容：“仁德”技能信息
]]--
sgs.ai_skills["rende"] = {
	name = "rende",
	dummyCard = function(self)
		local card_str = "@RendeCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if not self.player:hasUsed("RendeCard") then
			if not self.player:isKongcheng() then
				if sgs.current_mode == "04_1v3" then
					if self.player:getMark("Rende") > 1 then
						return false
					end
				end
				return true
			end
		end
		return false
	end
}
sgs.ai_skill_use_func["RendeCard"] = function(self, card, use)
	if self:shouldUseRende() then
		local handcards = self.player:getHandcards()
		local cards = sgs.QList2Table(handcards)
		self:sortByUseValue(cards, true)
		local name = self.player:objectName()
		local usecard, friend = self:getCardNeedPlayer(cards)
		if usecard and friend then
			if friend:objectName() == self.player:objectName() then
				return 
			elseif not handcards:contains(usecard) then 
				return 
			end
			if friend:hasSkill("enyuan") and #cards >= 2 then
				self:sortByUseValue(cards, true)
				for i = 1, #cards, 1 do
					if cards[i]:getId() ~= usecard:getId() then
						local card_str = "@RendeCard=" .. usecard:getId() .. "+" .. cards[i]:getId()
						use.card = sgs.Card_Parse(card_str)
						break
					end
				end
			else
				local card_str = "@RendeCard=" .. usecard:getId()
				use.card = sgs.Card_Parse(card_str)
			end
			if use.to then 
				use.to:append(friend) 
			end
		else
			local PangTong = self.room:findPlayerBySkillName("manjuan")
			if PangTong then
				if self.player:isWounded() then
					if self.player:getHandcardNum() >= 3 then
						local times = self.player:usedTimes("RendeCard")
						if times < 2 then
							self:sortByUseValue(cards, true)
							local to_give = {}
							for _,c in ipairs(cards) do
								if not sgs.isKindOf("Peach|ExNihilo", c) then 
									table.insert(to_give, c:getId()) 
								end
								if #to_give == 2 - times then 
									break 
								end
							end
							if #to_give > 0 then
								local card_str = "@RendeCard=" .. table.concat(to_give, "+")
								use.card = sgs.Card_Parse(card_str)
								if use.to then 
									use.to:append(PangTong) 
								end
							end
						end
					end
				end
			end
		end
	end
end
sgs.ai_skill_use["@@rende"] = function(self, prompt)
	local cards = {}
	local property = self.player:property("rende")
	local rende_list = property:toString():split("+")
	for _, id in ipairs(rende_list) do
		local card_id = tonumber(id)
		local card = sgs.Sanguosha:getCard(card_id)
		if card then 
			table.insert(cards, card) 
		end
	end
	if #cards > 0 then
		self:sortByUseValue(cards, true)
		local name = self.player:objectName()
		local card, friend = self:getCardNeedPlayer(cards)
		local usecard
		if card and friend then
			if friend:objectName() == self.player:objectName() then
				return 
			elseif not self.player:getHandcards():contains(card) then 
				return 
			end
			usecard = "@RendeCard=" .. card:getId()
			if friend:hasSkill("enyuan") then
				if #cards >= 2 then
					if sgs.current_mode == "04_1v3" then
						if self.player:getMark("rende") == 1 then
							return usecard.."->"..friend:objectName()
						end
					end
					self:sortByUseValue(cards, true)
					for i=1, #cards, 1 do
						if cards[i]:getId() ~= card:getId() then
							usecard = "@RendeCard=" .. card:getId() .. "+" .. cards[i]:getId()
							break
						end
					end
				end
			end
			if usecard then 
				return usecard .. "->" .. friend:objectName() 
			end
		end
	end
	return "."
end
--[[
	套路：仅使用“仁德技能卡”
]]--
sgs.ai_series["RendeCardOnly"] = {
	name = "RendeCardOnly",
	IQ = 2,
	value = 3,
	priority = 5,
	cards = {
		["RendeCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local rende_skill = sgs.ai_skills["rende"]
		local dummyCard = rende_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["RendeCard"], "RendeCardOnly")
--[[
	技能：激将（主公技）
	描述：当你需要使用或打出一张【杀】时，你可令其他蜀势力角色打出一张【杀】（视为由你使用或打出）。 
]]--
table.insert(sgs.ai_global_flags, "jijiangsource")
--[[
	内容：“激将技能卡”的卡牌成分
]]--
sgs.card_constituent["JijiangCard"] = {
	use_value = 8.5,
	use_priority = 2.45,
}
--[[
	内容：“激将技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["JijiangCard"] = function(self, card, source, targets)
	local name = source:objectName()
	if sgs.ai_lord[name] ~= name then
		local current = self.room:getCurrent()
		if current:objectName() == name then
			return sgs.ai_card_intention.Slash(self, card, source, targets)
		end
	end
end
--[[
	内容：注册“激将技能卡”
]]--
sgs.RegistCard("JijiangCard")
--[[
	内容：“激将”技能信息
]]--
sgs.ai_skills["jijiang"] = {
	name = "jijiang",
	lordskill = true,
	dummyCard = function(self)
		local card_str = "@JijiangCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		local lieges = self.room:getLieges("shu", self.player)
		if lieges:isEmpty() then 
			return false 
		end
		if self.player:hasUsed("JijiangCard") then
			return false
		end
		if self.player:hasFlag("Global_JijiangFailed") then
			return false
		end
		if not sgs.slash:isAvailable(self.player) then 
			return false
		end
		return true
	end
}
sgs.ai_skill_use_func["JijiangCard"] = function(self, card, use)
	self:sort(self.opponents, "defenseSlash")
	if not sgs.jijiangtarget then 
		table.insert(sgs.ai_global_flags, "jijiangtarget") 
	end
	sgs.jijiangtarget = {}
	local dummy_use = { 
		isDummy = true, 
		to = sgs.SPlayerList(),
	}
	local others = self.room:getOtherPlayers(self.player)
	if self.player:hasFlag("slashTargetFix") then
		for _, p in sgs.qlist(others) do
			if p:hasFlag("SlashAssignee") then
				dummy_use.to:append(p)
			end
		end
	end
	self:useCardSlash(sgs.slash, dummy_use)
	if dummy_use.card then
		if dummy_use.to:length() > 0 then
			use.card = card
			for _, p in sgs.qlist(dummy_use.to) do
				table.insert(sgs.jijiangtarget, p)
				if use.to then 
					use.to:append(p) 
				end
			end
		end
	end
end
sgs.ai_skill_cardask["@jijiang-slash"] = function(self, data)
	if not sgs.jijiangsource then
		return "."
	elseif not self:isFriend(sgs.jijiangsource) then 
		return "." 
	end
	if self:needBear() then 
		return "." 
	end
	local jijiangtargets = {}
	local alives = self.room:getAllPlayers()
	for _,target in sgs.qlist(alives) do
		if target:hasFlag("JijiangTarget") then
			if self:isPartner(target) then
				if self:needToLoseHp(target, sgs.jijiangsource, true) then
					return "."
				elseif self:invokeDamagedEffect(target, sgs.jijiangsource, sgs.slash) then 
					return "." 
				end
				table.insert(jijiangtargets, target)
			end
		end
	end
	if #jijiangtargets == 0 then
		return self:getCardId("Slash") or "."
	end
	self:sort(jijiangtargets, "defenseSlash")
	local slashes = self:getCards("Slash")
	for _,slash in ipairs(slashes) do
		for _, target in ipairs(jijiangtargets) do
			if not self:slashIsProhibited(slash, target, sgs.jijiangsource) then
				if self:slashIsEffective(slash, target, sgs.jijiangsource) then
					return slash:toString()
				end
			end
		end
	end
	return "."
end
sgs.ai_skill_invoke["jijiang"] = function(self, data)
	if not self:amLord() then
		return false
	end
	if sgs.jijiangsource then 
		return false 
	end
	local asked = data:toStringList()
	local prompt = asked[2]
	if not self.player:hasFlag("ai_hantong") then
		if self:askForCard("slash", prompt, 1) == "." then 
			return false 
		end
	end
	local current = self.room:getCurrent()
	if self:isPartner(current) then
		if current:getKingdom() == "shu" then
			if self:getOverflow(current) > 2 then
				if not self:isEquip("Crossbow", current) then
					return true
				end
			end
		end
	end
	local cards = self.player:getHandcards()
	for _, card in sgs.qlist(cards) do
		if sgs.isCard("Slash", card, self.player) then
			return false
		end
	end
	local lieges = self.room:getLieges("shu", self.player)
	if lieges:isEmpty() then 
		return false 
	end
	for _, p in sgs.qlist(lieges) do
		if self:isPartner(p) then
			return true
		end
	end
	return false
end
sgs.ai_cardsview_valuable["jijiang"] = function(self, class_name, player, need_lord)
	if class_name == "Slash" then
		local reason = sgs.Sanguosha:getCurrentCardUseReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			if not player:hasFlag("Global_JijiangFailed") then
				if need_lord ~= false or player:hasLordSkill("jijiang") then
					local current = self.room:getCurrent()
					if current:getKingdom() == "shu" then
						if not self:hasCrossbowEffect(current) then
							if self:getOverflow(current) > 2 then	
								self.player:setFlags("stack_overflow_jijiang")
								local isfriend = self:isPartner(current, player)
								self.player:setFlags("-stack_overflow_jijiang")
								if isfriend then 
									return "@JijiangCard=." 
								end
							end
						end
					end
					local cards = player:getHandcards()
					for _, card in sgs.qlist(cards) do
						if sgs.isCard("Slash", card, player) then 
							return 
						end
					end
					local lieges = self.room:getLieges("shu", player)
					if not lieges:isEmpty() then 
						for _, p in sgs.qlist(lieges) do
							self.player:setFlags("stack_overflow_jijiang")
							has_friend = self:isPartner(p, player)
							self.player:setFlags("-stack_overflow_jijiang")
							if has_friend then 
								return "@JijiangCard=." 
							end
						end
					end
				end
			end
		end
	end
end
sgs.ai_choicemade_filter.skillInvoke["jijiang"] = function(player, promptlist)
	if promptlist[#promptlist] == "yes" then
		sgs.jijiangsource = player
	end
end
sgs.ai_choicemade_filter.cardResponded["@jijiang-slash"] = function(player, promptlist, self)
	if promptlist[#promptlist] ~= "_nil_" then
		sgs.updateIntention(player, sgs.jijiangsource, -40)
		sgs.jijiangsource = nil
		sgs.jijiangtarget = nil
	elseif sgs.jijiangsource then
		if player:objectName() == player:getRoom():getLieges("shu", sgs.jijiangsource):last():objectName() then
			sgs.jijiangsource = nil
			sgs.jijiangtarget = nil
		end
	end
end
--[[
	套路：仅使用“激将技能卡”
]]--
sgs.ai_series["JijiangCardOnly"] = {
	name = "JijiangCardOnly",
	IQ = 2,
	value = 3,
	priority = 5,
	cards = {
		["JijiangCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return sgs.slash:isAvailable(self.player)
	end,
	action = function(self, handcards, skillcards)
		local jijiang_skill = sgs.ai_skills["jijiang"]
		local dummyCard = jijiang_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end
}
table.insert(sgs.ai_card_actions["JijiangCard"], "JijiangCardOnly")
--[[****************************************************************
	武将：标准·关羽（蜀）
]]--****************************************************************
--[[
	技能：武圣
	描述：你可以将一张红色牌当【杀】使用或打出。 
]]--
--[[
	内容：注册“武圣杀”
]]--
sgs.RegistCard("wusheng>>Slash")
--[[
	内容：“武圣”技能信息
]]--
sgs.ai_skills["wusheng"] = {
	name = "wusheng",
	dummyCard = function(self)
		local suit = sgs.slash:getSuitString()
		local point = sgs.slash:getNumberString()
		local card_str = string.format("slash:wusheng[%s:%s]=%d", suit, point, 0)
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if not self.player:isNude() then
			if sgs.slash:isAvailable(self.player) then 
				return true
			end
		end
		return false
	end
}
--[[
	内容：“武圣杀”的具体产生方式
]]--
sgs.ai_view_as_func["wusheng>>Slash"] = function(self, card)
	local cards = self.player:getCards("he")
	local reds = {}
	for _,red in sgs.qlist(cards) do
		if red:isRed() then
			if not red:isKindOf("Slash") then
				if not sgs.isCard("ExNihilo", red, self.player) then
					table.insert(reds, red)
				end
			end
		end
	end
	if #reds > 0 then
		self:sortByUseValue(reds, true)
		local redcard = nil
		local slashValue = sgs.getCardValue("Slash", "use_value")
		local residue = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, sgs.slash)
		for _,red in ipairs(reds) do
			local name = sgs.getCardName(red, "className")
			local value = sgs.getCardValue("use_value")
			if value < slashValue then
				redcard = red
				break
			elseif residue > 0 then
				redcard = red
				break
			end
		end
		if redcard then
			local suit = redcard:getSuitString()
			local number = redcard:getNumberString()
			local card_id = redcard:getEffectiveId()
			local card_str = string.format("slash:wusheng[%s:%s]=%d", suit, number, card_id)
			local slash = sgs.Card_Parse(card_str)
			return slash
		end
	end
end
--[[
	内容：“武圣”响应方式
	需求：杀
]]--
sgs.ai_view_as["wusheng"] = function(card, player, place, class_name)
	if place ~= sgs.Player_PlaceSpecial then
		if card:isRed() then
			if not card:isKindOf("Peach") then
				if not card:hasFlag("using") then
					local suit = card:getSuitString()
					local number = card:getNumberString()
					local card_id = card:getEffectiveId()
					return ("slash:wusheng[%s:%s]=%d"):format(suit, number, card_id)
				end
			end
		end
	end
end
--[[
	内容：“武圣”卡牌需求
]]--
sgs.card_need_system["wusheng"] = function(self, card, player)
	if card:isRed() then
		return player:getHandcardNum() < 3
	end
	return false
end
--[[
	内容：“武圣”统计信息
]]--
sgs.card_count_system["wusheng"] = {
	name = "wusheng",
	pattern = "Slash",
	ratio = 0.69,
	statistics_func = function(class_name, player, data)
		if player:hasSkill("wusheng") then
			local count = data["count"]
			count = count + data["Red"] 
			count = count + data["unknown"] * 0.69
			return count
		end
	end
}
--[[
	套路：仅使用“武圣杀”
]]--
sgs.ai_series["wusheng>>SlashOnly"] = {
	name = "wusheng>>SlashOnly", 
	IQ = 2,
	value = 2, 
	priority = 1, 
	skills = "wusheng",
	cards = { 
		["wusheng>>Slash"] = 1, 
		["Others"] = 0, 
	},
	enabled = function(self) 
		if sgs.slash:isAvailable(self.player) then
			local cards = self.player:getCards("he")
			for _,card in sgs.qlist(cards) do
				if card:isRed() then
					return true
				end
			end
		end
		return false
	end,
	action = function(self, handcards, skillcards) 
		local wusheng_skill = sgs.ai_skills["wusheng"]
		local dummyCard = wusheng_skill["dummyCard"]()
		dummyCard:setFlags("isDummy")
		return {dummyCard}
	end,
	break_condition = function(self) 
		return false
	end,
}
table.insert(sgs.ai_card_actions["wusheng>>Slash"], "wusheng>>SlashOnly")
--[[****************************************************************
	武将：标准·张飞（蜀）
]]--****************************************************************
sgs.ai_chaofeng.zhangfei = 3
--[[
	技能：咆哮（锁定技）
	描述：你于出牌阶段内使用【杀】无数量限制。 
]]--
sgs.paoxiao_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.7,
	FireSlash = 5.6,
	Slash = 5.4,
	ThunderSlash = 5.5,
	ExNihilo = 4.7
}
--[[
	内容：“咆哮”卡牌需求
]]--
sgs.card_need_system["paoxiao"] = function(self, card, player)
	local cards = player:getHandcards()
	local weapon = player:getWeapon()
	local hasWeapon = false
	if weapon then
		if not weapon:isKindOf("Crowwbow") then
			hasWeapon = true
		end
	end
	local slash_num = 0
	local current = self.room:getCurrent()
	local flag = string.format("visible_%s_%s", current:objectName(), player:objectName())
	for _, c in sgs.qlist(cards) do
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:isKindOf("Weapon") then
				if not c:isKindOf("Crossbow") then
					hasWeapon=true
				end
			end
			if c:isKindOf("Slash") then 
				slash_num = slash_num +1 
			end
		end
	end
	if hasWeapon then
		if self:isEquip("Spear", player) then
			return true
		elseif card:isKindOf("Slash") then
			return true
		elseif slash_num > 1 then
			return card:isKindOf("Analeptic")
		end
	else
		if card:isKindOf("Weapon") then
			return not card:isKindOf("Crossbow")
		end
	end
	return false
end
--[[****************************************************************
	武将：标准·诸葛亮（蜀）
]]--****************************************************************
--[[
	技能：观星
	描述：准备阶段开始时，你可以观看牌堆顶的X张牌，然后将任意数量的牌以任意顺序置于牌堆顶，将其余的牌以任意顺序置于牌堆底。（X为存活角色数且至多为5） 
]]--
--[[
	技能：空城（锁定技）
	描述：若你没有手牌，你不能被选择为【杀】或【决斗】的目标。 
]]--
--[[****************************************************************
	武将：标准·赵云（蜀）
]]--****************************************************************
--[[
	技能：龙胆
	描述：你可以将一张【杀】当【闪】使用或打出，或将一张【闪】当【杀】使用或打出。 
]]--
--[[
	内容：注册“龙胆杀”
]]--
sgs.RegistCard("longdan>>Slash")
--[[
	内容：“龙胆”技能信息
]]--
sgs.ai_skills["longdan"] = {
	name = "longdan",
	dummyCard = function(self)
		local suit = sgs.slash:getSuitString()
		local point = sgs.slash:getNumberString()
		local card_str = string.format("slash:longdan[%s:%s]=%d", suit, point, 0)
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if not self.player:isNude() then
			if sgs.slash:isAvailable(self.player) then 
				return true
			end
		end
		return false
	end
}
--[[
	内容：“龙胆杀”的具体产生方式
]]--
sgs.ai_view_as_func["longdan>>Slash"] = function(self, card)
	local cards = self.player:getHandcards()
	local jinks = {}
	for _,jink in sgs.qlist(cards) do
		if jink:isKindOf("Jink") then
			table.insert(jinks, jink)
		end
	end
	if #jinks > 0 then
		self:sortByKeepValue(jinks)
		local jink = jinks[1]
		local suit = jink:getSuitString()
		local number = jink:getNumberString()
		local card_id = jink:getEffectiveId()
		local card_str = ("slash:longdan[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)
		return slash
	end
end
--[[
	内容：“龙胆”响应方式
	需求：闪、杀
]]--
sgs.ai_view_as["longdan"] = function(card, player, place, class_name)
	if card_place == sgs.Player_PlaceHand then
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		if card:isKindOf("Jink") then
			return ("slash:longdan[%s:%s]=%d"):format(suit, number, card_id)
		elseif card:isKindOf("Slash") then
			return ("jink:longdan[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end
--[[
	内容：“龙胆”统计信息
]]--
sgs.card_count_system["longdan_slash"] = {
	name = "longdan_slash",
	pattern = "Slash",
	ratio = 0.72,
	statistics_func = function(class_name, player, data)
		if player:hasSkill("longdan") then
			local count = data["SlashOrJink"] 
			count = count + data["unknown"] * 0.72
			return count
		end
	end
}
sgs.card_count_system["longdan_jink"] = {
	name = "longdan_jink",
	pattern = "Jink",
	ratio = 0.72,
	statistics_func = function(class_name, player, data)
		if player:hasSkill("longdan") then
			local count = data["SlashOrJink"] 
			count = count + data["unknown"] * 0.72
			return count
		end
	end
}
sgs.longdan_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.7,
	FireSlash = 5.7,
	Slash = 5.6,
	ThunderSlash = 5.5,
	ExNihilo = 4.7
}
--[[
	套路：仅使用龙胆杀
]]--
sgs.ai_series["longdan>>SlashOnly"] = {
	name = "longdan>>SlashOnly", 
	IQ = 2,
	value = 2, 
	priority = 1, 
	skills = "longdan",
	cards = { 
		["longdan>>Slash"] = 1, 
		["Others"] = 1, 
	},
	enabled = function(self) 
		if sgs.slash:isAvailable(self.player) then
			local cards = self.player:getCards("h")
			for _,card in sgs.qlist(cards) do
				if card:isKindOf("Jink") then
					return true
				end
			end
		end
		return false
	end,
	action = function(self, handcards, skillcards) 
		local longdan_skill = sgs.ai_skills["longdan"]
		local dummyCard = longdan_skill["dummyCard"](self)
		dummyCard:setFlags("isDummy")
		return {dummyCard}
	end,
	break_condition = function(self) 
		return false
	end,
}
table.insert(sgs.ai_card_actions["longdan>>Slash"], "longdan>>SlashOnly")
--[[****************************************************************
	武将：标准·马超（蜀）
]]--****************************************************************
sgs.ai_chaofeng.machao = 1
--[[
	技能：铁骑
	描述：每当你指定【杀】的目标后，你可以进行一次判定，若判定结果为红色，该角色不能使用【闪】对此【杀】进行响应。 
]]--
sgs.ai_skill_invoke["tieji"] = function(self, data)
	local target = data:toPlayer()
	if self:isPartner(target) then
		return false
	end
	local ZhangJiao = self.room:findPlayerBySkillName("guidao")
	if ZhangJiao then
		if self:isOpponent(ZhangJiao) then
			if self:canRetrial(ZhangJiao) then 
				return false 
			end
		end
	end
	if target:hasArmorEffect("EightDiagram") then
		if not sgs.IgnoreArmor(self.player, target) then 
			return true 
		end
	end
	if target:hasLordSkill("hujia") then
		for _, p in ipairs(self.opponents) do
			if p:getKingdom() == "wei" then
				if p:hasArmorEffect("EightDiagram") then
					return true
				elseif p:getHandcardNum() > 0 then 
					return true 
				end
			end
		end
	end
	if target:hasSkill("longhun") then
		if target:getHp() == 1 then
			if self:hasSuit("club", true, target) then 
				return true 
			end
		end
	end
	if target:isKongcheng() then
		return false
	elseif self:getKnownNum(target) == target:getHandcardNum() then
		if sgs.getKnownCard(target, "Jink", true) == 0 then 
			return false 
		end
	end
	return true
end
--[[
	技能：马术（锁定技）
	描述：你与其他角色的距离-1。 
]]--
--[[****************************************************************
	武将：标准·黄月英（蜀）
]]--****************************************************************
sgs.ai_chaofeng.huangyueying = 4
--[[
	技能：集智
	描述：每当你使用锦囊牌选择目标后，你可以展示牌堆顶的一张牌。若此牌为基本牌，你选择一项：1.将之置入弃牌堆；2.用一张手牌替换之。若此牌不为基本牌，你获得之。 
]]--
sgs.ai_skill_cardask["@jizhi-exchange"] = function(self, data)
	local card = data:toCard()
	local handcards = self.player:getHandcards()
	handcards = sgs.QList2Table(handcards)
	if self.player:getPhase() == sgs.Player_Play then
		if card:isKindOf("Slash") then
			if not sgs.slash:isAvailable(self.player) then 
				return "." 
			end
		end
		self:sortByUseValue(handcards)
		local value = sgs.getUseValue(card, self.player)
		for _, card_ex in ipairs(handcards) do
			if sgs.getUseValue(card_ex, self.player) < value then
				if not self:isValuableCard(card_ex) then
					return "$" .. card_ex:getEffectiveId()
				end
			end
		end
	else
		if self.player:hasSkill("manjuan") then
			if self.player:getPhase() == sgs.Player_NotActive then 
				return "." 
			end
		end
		self:sortByKeepValue(handcards)
		local value = sgs.getKeepValue(card, self.player)
		for _, card_ex in ipairs(handcards) do
			if sgs.getKeepValue(card_ex, self.player) < value then
				if not self:isValuableCard(card_ex) then
					return "$" .. card_ex:getEffectiveId()
				end
			end
		end
	end
	return "."
end
sgs.jizhi_keep_value = {
	Peach 		= 6,
	Analeptic 	= 5.9,
	Jink 		= 5.8,
	ExNihilo	= 5.7,
	Snatch 		= 5.7,
	Dismantlement = 5.6,
	IronChain 	= 5.5,
	SavageAssault=5.4,
	Duel 		= 5.3,
	ArcheryAttack = 5.2,
	AmazingGrace = 5.1,
	Collateral 	= 5,
	FireAttack	= 4.9
}
--[[
	内容：“集智”卡牌需求
]]--
sgs.card_need_system["jizhi"] = function(self, card, player)
	return card:isNDTrick()
end
--[[
	技能：奇才（锁定技）
	描述：你使用锦囊牌无距离限制。你装备区里除坐骑牌外的牌不能被其他角色弃置。 
]]--
--[[****************************************************************
	武将：标准·孙权（吴）
]]--****************************************************************
sgs.ai_chaofeng.sunquan = 2
--[[
	技能：制衡
	描述：出牌阶段限一次，你可以弃置任意数量的牌，然后摸等量的牌。 
]]--
--[[
	内容：“制衡技能卡”的卡牌成分
]]--
sgs.card_constituent["ZhihengCard"] = {
	benefit = 2,
	use_value = 9,
	use_priority = 2.61,
}
--[[
	内容：注册制衡技能卡
]]--
sgs.RegistCard("ZhihengCard") 
--[[
	内容：“制衡”技能信息
]]--
sgs.ai_skills["zhiheng"] = {
	name = "zhiheng",
	dummyCard = function(self)
		local card_str = "@ZhihengCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if not self.player:hasUsed("ZhihengCard") then
			if not self.player:isNude() then
				return true
			end
		end
		return false
	end
}
--[[
	内容：“制衡技能卡”的一般使用方式
]]--
sgs.ai_skill_use_func["ZhihengCard"] = function(self, card, use)
	local unprefered_cards = {}
	local hp = self.player:getHp()
	if hp < 3 then
		local zcards = self.player:getCards("he")
		local use_slash = false
		local keep_jink = false
		local keep_anal = false
		local keep_weapon = false
		local keep_slash = self.player:getTag("JilveWansha"):toBool()
		for _, zcard in sgs.qlist(zcards) do
			if not sgs.isCard("Peach", zcard, self.player) then
				if not sgs.isCard("ExNihilo", zcard, self.player) then
					local shouldUse = true
					if not use_slash then
						if sgs.isCard("Slash", zcard, self.player) then
							local dummy_use = { 
								isDummy = true , 
								to = sgs.SPlayerList(),
							}
							self:useBasicCard(zcard, dummy_use)
							if dummy_use.card then
								if keep_slash then 
									shouldUse = false 
								end
								if dummy_use.to then
									for _, p in sgs.qlist(dummy_use.to) do
										if p:getHp() <= 1 then
											shouldUse = false
											if self.player:distanceTo(p) > 1 then 
												keep_weapon = self.player:getWeapon() 
											end
											break
										end
									end
									if dummy_use.to:length() > 1 then 
										shouldUse = false 
									end
								end
								if not self:isWeak() then 
									shouldUse = false 
								end
								if not shouldUse then 
									use_slash = true 
								end
							end
						end
					end
					if zcard:getTypeId() == sgs.Card_TypeTrick then
						local dummy_use = { 
							isDummy = true, 
						}
						self:useTrickCard(zcard, dummy_use)
						if dummy_use.card then 
							shouldUse = false 
						end
					end
					if zcard:getTypeId() == sgs.Card_TypeEquip then
						if not self.player:hasEquip(zcard) then
							local dummy_use = { 
								isDummy = true, 
							}
							self:useEquipCard(zcard, dummy_use)
							if dummy_use.card then 
								shouldUse = false 
							end
							if keep_weapon then
								if zcard:getEffectiveId() == keep_weapon:getEffectiveId() then 
									shouldUse = false 
								end
							end
						end
					end
					if self.player:hasEquip(zcard) then
						if not self:needToThrowArmor() then
							if zcard:isKindOf("Armor") then
								shouldUse = false 
							elseif zcard:isKindOf("DefensiveHorse") then
								shouldUse = false
							end
						end
					end
					if not keep_jink then
						if sgs.isCard("Jink", zcard, self.player) then
							keep_jink = true
							shouldUse = false
						end
					end
					if hp == 1 then
						if not keep_anal then
							if sgs.isCard("Analeptic", zcard, self.player) then
								keep_anal = true
								shouldUse = false
							end
						end
					end
					if shouldUse then 
						table.insert(unprefered_cards, zcard:getId()) 
					end
				end
			end
		end
	end
	if #unprefered_cards == 0 then
		local use_slash_num = 0
		local handcards = self.player:getHandcards()
		local cards = sgs.QList2Table(handcards)
		self:sortByKeepValue(cards)
		for _,slash in ipairs(cards) do
			if slash:isKindOf("Slash") then
				local will_use = false
				local extra = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, slash)
				if use_slash_num <= extra then
					local dummy_use = { 
						isDummy = true,	
					}
					self:useBasicCard(slash, dummy_use)
					if dummy_use.card then
						will_use = true
						use_slash_num = use_slash_num + 1
					end
				end
				if not will_use then 
					table.insert(unprefered_cards, slash:getId()) 
				end
			end
		end
		local JinkNum = self:getCardsNum("Jink") - 1
		if self.player:getArmor() then 
			JinkNum = JinkNum + 1 
		end
		if JinkNum > 0 then
			for _,jink in ipairs(cards) do
				if jink:isKindOf("Jink") and JinkNum > 0 then
					table.insert(unprefered_cards, jink:getId())
					JinkNum = JinkNum - 1
				end
			end
		end
		for _,c in ipairs(cards) do
			if sgs.isKindOf("OffensiveHorse|AmazingGrace", c) then
				table.insert(unprefered_cards, c:getId())
			elseif self:getSameTypeEquip(c, self.player) then
				table.insert(unprefered_cards, c:getId())
			elseif c:isKindOf("Weapon") and self.player:getHandcardNum() < 3 then
				table.insert(unprefered_cards, c:getId())
			elseif c:getTypeId() == sgs.Card_TypeTrick then
				local dummy_use = { 
					isDummy = true, 
				}
				self:useTrickCard(c, dummy_use)
				if not dummy_use.card then 
					table.insert(unprefered_cards, c:getId()) 
				end
			end
		end
		local weapon = self.player:getWeapon()
		if weapon then
			if self.player:getHandcardNum() < 3 then
				table.insert(unprefered_cards, weapon:getId())
			end
			local horse = self.player:getOffensiveHorse()
			if horse then
				table.insert(unprefered_cards, horse:getId())
			end
		end
		if self:needToThrowArmor() then
			local armor = self.player:getArmor()
			table.insert(unprefered_cards, armor:getId())
		end
	end
	local to_discard = {}
	for index = #unprefered_cards, 1, -1 do
		local card_id = unprefered_cards[index]
		local c = sgs.Sanguosha:getCard(card_id)
		if not self.player:isJilei(c) then 
			table.insert(to_discard, card_id) 
		end
	end
	if #to_discard > 0 then
		local card_str = "@ZhihengCard="..table.concat(to_discard, "+")
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
	end
end
--[[
	内容：“制衡”卡牌需求
]]--
sgs.card_need_system["zhiheng"] = function(self, card, player)
	return not card:isKindOf("Jink")
end
--[[
	套路：仅使用“制衡技能卡”
]]--
sgs.ai_series["ZhihengCardOnly"] = {
	name = "ZhihengCardOnly", 
	IQ = 2,
	value = 5, 
	priority = 1, 
	cards = { 
		["ZhihengCard"] = 1, 
		["Others"] = 0, 
	},
	enabled = function(self) 
		return not self.player:isNude()
	end,
	action = function(self, handcards, skillcards) 
		local zhiheng_skill = sgs.ai_skills["zhiheng"]
		local dummyCard = zhiheng_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self) --何时被中断以重新选择套路
		return false
	end,
}
table.insert(sgs.ai_card_actions["ZhihengCard"], "ZhihengCardOnly")
--[[
	技能：救援（主公技，锁定技）
	描述：其他吴势力角色对处于濒死状态的你使用的【桃】回复的体力+1。 
]]--
--[[****************************************************************
	武将：标准·甘宁（吴）
]]--****************************************************************
sgs.ai_chaofeng.ganning = 2
--[[
	技能：奇袭
	描述：你可以将一张黑色牌当【过河拆桥】使用。 
]]--
--[[
	内容：注册“奇袭过河拆桥”
]]--
sgs.RegistCard("qixi>>Dismantlement")
--[[
	内容：“奇袭”技能信息
]]--
sgs.ai_skills["qixi"] = {
	name = "qixi",
	dummyCard = function(self)
		local suit = sgs.dismantlement:getSuitString()
		local number = sgs.dismantlement:getNumberString()
		local card_id = sgs.dismantlement:getEffectiveId()
		local card_str = ("dismantlement:qixi[%s:%s]=%d"):format(suit, number, card_id)
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		local cards = self.player:getCards("he")
		for _,card in sgs.qlist(cards) do
			if card:isBlack() then
				return true
			end
		end
		return false
	end
}
--[[
	内容：“奇袭过河拆桥”的具体产生方式
]]--
sgs.ai_view_as_func["qixi>>Dismantlement"] = function(self, card)
	local cards = self.player:getCards("he")
	local blacks = {}
	local hasWeapon = false
	for _,black in sgs.qlist(cards) do
		if black:isBlack() then
			table.insert(blacks, black)
			if black:isKindOf("Weapon") then
				hasWeapon = true
			end
		end
	end
	if #blacks > 0 then
		self:sortByUseValue(blacks, true)
		local disValue = sgs.getCardValue("Dismantlement", "use_value")
		for _,black in ipairs(blacks) do
			local name = sgs.getCardName(black, "className")
			local value = sgs.getCardValue(name, "use_value")
			local flag = false
			if value < disValue then
				flag = true
			elseif self:getOverflow() > 0 then
				flag = true
			end
			if flag then
				local should_use = true
				if black:isKindOf("Armor") then
					if not self.player:getArmor() then
						should_use = false
					end
				elseif black:isKindOf("Weapon") then
					if not self.player:getWeapon() then
						should_use = false
					end
				elseif black:isKindOf("Slash") then
					if self:getCardsNum("Slash") == 1 then
						local dummy_use = {
							isDummy = true
						}
						self:useBasicCard(black, dummy_use)
						if dummy_use.card then
							should_use = false
						end
					end
				end
				if should_use then
					local suit = black:getSuitString()
					local number = black:getNumberString()
					local card_id = black:getEffectiveId()
					local card_str = ("dismantlement:qixi[%s:%s]=%d"):format(suit, number, card_id)
					local dismantlement = sgs.Card_Parse(card_str)
					return dismantlement
				end
			end
		end
	end
end
sgs.qixi_suit_value = {
	spade = 3.9,
	club = 3.9
}
--[[
	内容：“奇袭”卡牌需求
]]--
sgs.card_need_system["qixi"] = function(self, card, player)
	return card:isBlack()
end
--[[
	套路：仅使用“奇袭过河拆桥”
]]--
sgs.ai_series["qixi>>DismantlementOnly"] = {
	name = "qixi>>DismantlementOnly", 
	IQ = 2,
	value = 5, 
	priority = 1, 
	skills = "qixi",
	cards = { 
		["qixi>>Dismantlement"] = 1, 
		["Others"] = 0, 
	},
	enabled = function(self) 
		return not self.player:isNude()
	end,
	action = function(self, handcards, skillcards) 
		local qixi_skill = sgs.ai_skills["qixi"]
		local dummyCard = qixi_skill["dummyCard"](self)
		dummyCard:setFlags("isDummy")
		return {dummyCard}
	end,
	break_condition = function(self) 
		return false
	end,
}
table.insert(sgs.ai_card_actions["qixi>>Dismantlement"], "qixi>>DismantlementOnly")
--[[****************************************************************
	武将：标准·吕蒙（吴）
]]--****************************************************************
--[[
	技能：克己
	描述：若你未于出牌阶段内使用或打出【杀】，你可以跳过你的弃牌阶段。 
]]--
--[[****************************************************************
	武将：标准·黄盖（吴）
]]--****************************************************************
sgs.ai_chaofeng.huanggai = 3
--[[
	技能：苦肉
	描述：出牌阶段，你可以失去1点体力，然后摸两张牌。 
]]--
--[[
	内容：“苦肉技能卡”的卡牌成分
]]--
sgs.card_constituent["KurouCard"] = {
	use_priority = 6.8,
}
--[[
	内容：注册“苦肉技能卡”
]]--
sgs.RegistCard("KurouCard")
--[[
	内容：“苦肉”技能信息
]]--
sgs.ai_skills["kurou"] = {
	name = "kurou",
	dummyCard = function(self)
		local card_str = "@KurouCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		return true
	end
}
--[[
	内容：“苦肉技能卡”的一般使用方式
]]--
sgs.ai_skill_use_func["KurouCard"] = function(self, card, use)
	if not use.isDummy then 
		self:speak("kurou") 
	end
	local canlost = 1
	local isLord = self:amLord()
	if isLord then
		canlost = 0
	end
	local hp = self.player:getHp()
	local lost = self.player:getLostHp()
	local num = self.player:getHandcardNum()
	local flag = false
	if hp > 3 then
		if lost <= canlost then
			if num > hp then
				flag = true
			end
		end
	end
	if hp - num >= 2 then
		flag = true
	end
	if flag then
		if not isLord or sgs.turncount > 1 then
			use.card = card
			return 
		end
	end
	local weapon = self.player:getWeapon()
	local hasCrossbow = false
	if weapon and weapon:isKindOf("Crossbow") then
		hasCrossbow = true
	elseif self.player:hasSkill("paoxiao") then
		hasCrossbow = true
	end
	if hasCrossbow then
		if hp > 1 then
			for _,enemy in ipairs(self.opponents) do
				if self.player:canSlash(enemy, nil, true) then
					if self:slashIsEffective(slash, enemy, self.player) then
						if not (enemy:hasSkill("kongcheng") and enemy:isKongcheng()) then
							if not (self:hasSkills("fankui|guixin", enemy) and not self:hasSkills("paoxiao")) then
								if not self:hasSkills("fenyong|jilei|zhichi", enemy) then
									if sgs.isGoodTarget(self, enemy, self.opponents) then
										if not self:slashIsProhibited(enemy, self.player, sgs.slash) then
											use.card = card
											return
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
	if hp == 1 then
		if self:getCardsNum("Analeptic") >= 1 then
			use.card = card
			return
		end
		--使用苦肉技能卡自杀
		local next_player = self.player:getNextAlive()
		if not isLord then
			if not self:amRenegade() then
				local to_death = false
				local others = self.room:getOtherPlayers(self.player)
				if self:isFriend(next_player) then
					for _,p in sgs.qlist(others) do
						if self:hasSkills("gzxiaoguo|xiaoguo", p) then
							if not self:isFriend(p) then
								if not p:isKongcheng() then
									if self:amRebel() then
										local equips = self.player:getEquips()
										if equips:isEmpty() then
											to_death = true
											break
										end
									end
								end
							end
						end
					end
					if not to_death then
						if not self:willSkipPlayPhase(next_player) then
							if next_player:hasSkill("jieyin") then
								if self.player:isMale() then 
									return 
								end
							end
							if next_player:hasSkill("qingnang") then 
								return 
							end
						end
					end
				else
					if self:amRebel() then
						if not self:willSkipPlayPhase(next_player) then
							to_death = true
						elseif next_player:hasSkill("shensu") then
							to_death = true
						end
					end
				end
				local myname = self.player:objectName()
				local lordname = sgs.ai_lord[myname]
				if lordname then
					local lord = findPlayerByObjectName(self.room, lordname)
					if self:amLoyalist() then
						if lord:isNude() then
							return 
						end
						if self:isOpponent(next_player) then
							if not self:willSkipPlayPhase(next_player) then
								if self:hasSkills("noslijian|lijian", next_player) then
									if self.player:isMale() then
										if lord:isMale() then
											to_death = true
										end
									end
								elseif next_player:hasSkill("quhu") then
									if lord:getHp() > next_player:getHp() then
										if not lord:isKongcheng() then
											if lord:inMyAttackRange(self.player) then
												to_death = true
											end
										end
									end
								end
							end
						end
					end
				end
				if to_death then
					local CaoPi = self.room:findPlayerBySkillName("xingshang")
					if CaoPi then
						if self:isEnemy(CaoPi) then
							if self:amRebel() then
								if num >= 3 then
									to_death = false
								end
							elseif self:amLoyalist() then
								if lord:getCardCount(true) + 2 <= num then
									to_death = false
								end
							end
						end
					end
					if self.player:aliveCount() == 2 then
						if #self.friends == 1 then
							if #self.enemies == 1 then
								to_death = false
							end
						end
					end
				end
				if to_death then
					self.player:setFlags("Kurou_toDie")
					use.card = card
					return 
				end
				self.player:setFlags("-Kurou_toDie")
			end
		end
	end
end
--[[
	套路：仅使用“苦肉技能卡”
]]--
sgs.ai_series["KurouCardOnly"] = {
	name = "KurouCardOnly", 
	IQ = 2,
	value = 5, 
	priority = 1, 
	skills = "kurou",
	cards = { 
		["KurouCard"] = 1, 
		["Others"] = 0, 
	},
	enabled = function(self) 
		return true
	end,
	action = function(self, handcards, skillcards) 
		local kurou_skill = sgs.ai_skills["kurou"]
		local dummyCard = kurou_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self) --何时被中断以重新选择套路
		return false
	end,
}
table.insert(sgs.ai_card_actions["KurouCard"], "KurouCardOnly")
--[[****************************************************************
	武将：标准·周瑜（吴）
]]--****************************************************************
sgs.ai_chaofeng.zhouyu = 3
--[[
	技能：英姿
	描述：摸牌阶段，你可以额外摸一张牌。 
]]--
sgs.ai_skill_invoke.yingzi = function(self, data)
	return true
end
sgs.draw_cards_system["yingzi"] = {
	name = "yingzi",
	correct_func = function(self, player)
		return 1
	end,
}
--[[
	技能：反间
	描述：出牌阶段限一次，若你有手牌，你可以令一名其他角色选择一种花色，然后该角色获得你的一张手牌再展示之，若此牌的花色与其所选的不同，你对其造成1点伤害。 
]]--
--[[
	内容：“反间技能卡”的卡牌成分
]]--
sgs.card_constituent["FanjianCard"] = {
	damage = 2,
}
sgs.ai_card_intention["FanjianCard"] = 70
--[[
	内容：注册“反间技能卡”
]]--
sgs.RegistCard("FanjianCard")
--[[
	内容：“反间”技能信息
]]--
sgs.ai_skills["fanjian"] = {
	name = "fanjian",
	dummyCard = function(self)
		local card_str = "@FanjianCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if self.player:isKongcheng() then
			return false
		elseif self.player:hasUsed("FanjianCard") then
			return false
		end
		return true
	end
}
--[[
	内容：“反间技能卡”的一般使用方式
]]--
sgs.ai_skill_use_func["FanjianCard"] = function(self, card, use)
	local handcards = self.player:getCards("h")
	handcards = sgs.QList2Table(handcards)
	local WuGuoTai = self.room:findPlayerBySkillName("buyi")
	if WuGuoTai then
		if self:isPartner(WuGuoTai) then
			WuGuoTai = nil
		end
	end
	self:sortByUseValue(handcards, true)
	self:sort(self.opponents, "hp")
	for _,c in ipairs(handcards) do
		local flag = true
		if c:getSuit() == sgs.Card_Diamond then
			if self.player:getHandcardNum() == 1 then
				flag = false
			end
		end
		if #handcards <= 4 then
			if c:isKindOf("Peach") then
				flag = false
			elseif c:isKindOf("Analeptic") then
				flag = false
			end
		end
		if flag then
			for _,enemy in ipairs(self.opponents) do
				if not self:hasSkills("qingnang|jijiu|tianxiang", enemy) then
					local flag = true
					if WuGuoTai then
						if c:getTypeId() ~= sgs.Card_Basic then
							if enemy:isKongcheng() then
								flag = false
							elseif enemy:objectName() == WuGuoTai:objectName() then
								flag = false
							end
						end
					end
					if flag then
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
sgs.ai_skill_suit["fanjian"] = function(self)
	local map = {0, 0, 1, 2, 2, 3, 3, 3}
	local suit = map[math.random(1, 8)]
	if self.player:hasSkill("hongyan") then
		if suit == sgs.Card_Spade then 
			return sgs.Card_Heart 
		else 
			return suit 
		end
	end
end
--[[
	套路：仅使用“反间技能卡”
]]--
sgs.ai_series["FanjianCardOnly"] = {
	name = "FanjianCardOnly", 
	IQ = 2,
	value = 5, 
	priority = 1, 
	skills = "fanjian",
	cards = { 
		["FanjianCard"] = 1, 
		["Others"] = 1, 
	},
	enabled = function(self) 
		return true
	end,
	action = function(self, handcards, skillcards) 
		local fanjian_skill = sgs.ai_skills["fanjian"]
		local dummyCard = fanjian_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self) 
		return false
	end,
}
table.insert(sgs.ai_card_actions["FanjianCard"], "FanjianCardOnly")
--[[****************************************************************
	武将：标准·大乔（吴）
]]--****************************************************************
sgs.ai_chaofeng.daqiao = 2
--[[
	技能：国色
	描述：你可以将一张♦牌当【乐不思蜀】使用。 
]]--
--[[
	内容：注册“国色乐不思蜀”
]]--
sgs.RegistCard("guose>>Indulgence")
--[[
	内容：“国色”技能信息
]]--
sgs.ai_skills["guose"] = {
	name = "guose",
	dummyCard = function(self)
		local suit = sgs.indulgence:getSuitString()
		local number = sgs.indulgence:getNumberString()
		local card_id = sgs.indulgence:getEffectiveId()
		local card_str = ("indulgence:guose[%s:%s]=%d"):format(suit, number, card_id)
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		local cards = self.player:getCards("he")
		for _,card in sgs.qlist(cards) do
			if card:getSuit() == sgs.Card_Diamond then
				return true
			end
		end
		return false
	end
}
--[[
	内容：“国色乐不思蜀”的具体产生方式
]]--
sgs.ai_view_as_func["guose>>Indulgence"] = function(self, card)
	local cards = self.player:getCards("he")
	local diamonds = {}
	local hasWeapon = false
	local hasArmor = false
	for _,c in sgs.qlist(cards) do
		if c:getSuit() == sgs.Card_Diamond then
			if not c:isKindOf("Indulgence") then
				table.insert(diamonds, c)
			end
		else
			if c:isKindOf("Weapon") then
				hasWeapon = true
			elseif c:isKindOf("Armor") then
				hasArmor = true
			end
		end
	end
	if #diamonds > 0 then
		self:sortByUseValue(diamonds, true)
		local indValue = sgs.getCardValue("Indulgence", "use_value")
		for _,diamond in ipairs(diamonds) do
			local name = sgs.getCardName(diamond)
			local value = sgs.getCardValue(name, "use_value")
			if value < indValue then
				local should_use = true
				if diamond:isKindOf("Weapon") then
					if self.player:getWeapon() then
						if not hasWeapon then
							if self.player:hasEquip(diamond) then
								should_use = false
							end
						end
					else
						should_use = false
					end
				elseif diamond:isKindOf("Armor") then
					if self.player:getArmor() then
						if not hasArmor then
							if self.player:hasEquip(diamond) then
								if self:evaluateArmor() > 0 then
									should_use = false
								end
							end
						end
					else
						should_use = false
					end
				end
				if should_use then
					local number = diamond:getNumberString()
					local card_id = diamond:getEffectiveId()
					local card_str = ("indulgence:guose[diamond:%s]=%d"):format(number, card_id)	
					local indulgence = sgs.Card_Parse(card_str)
					return indulgence
				end
			end
		end
	end
end
sgs.guose_suit_value = {
	diamond = 3.9
}
--[[
	内容：“国色”卡牌需求
]]--
sgs.card_need_system["guose"] = function(self, card, player)
	return card:getSuit() == sgs.Card_Diamond
end
--[[
	套路：仅使用“国色乐不思蜀”
]]--
sgs.ai_series["guose>>IndulgenceOnly"] = {
	name = "guose>>IndulgenceOnly", 
	IQ = 2,
	value = 5, 
	priority = 3, 
	skills = "guose",
	cards = { 
		["guose>>Indulgence"] = 1, 
		["Others"] = 0, 
	},
	enabled = function(self) 
		return true
	end,
	action = function(self, handcards, skillcards) 
		local guose_skill = sgs.ai_skills["guose"]
		local dummyCard = guose_skill["dummyCard"](self)
		dummyCard:setFlags("isDummy")
		return {dummyCard}
	end,
	break_condition = function(self) 
		return false
	end,
}
table.insert(sgs.ai_card_actions["guose>>Indulgence"], "guose>>IndulgenceOnly")
--[[
	技能：流离
	描述：每当你成为【杀】的目标时，你可以弃置一张牌并选择你攻击范围内的一名其他角色（除此【杀】使用者），将此【杀】转移给该角色。 
]]--
--[[
	内容：“流离技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["LiuliCard"] = function(self, card, source, targets)
	sgs.ai_liuli_effect = true
end
sgs.ai_skill_use["@@liuli"] = function(self, prompt)
	local tag = self.player:getTag("liuli-card")
	local slash = tag:toCard()
	local others = self.room:getOtherPlayers(self.player)
	others = sgs.QList2Table(others)
	local source = nil
	for _,player in ipairs(others) do
		if player:hasFlag("LiuliSlashSource") then
			source = player
			break
		end
	end
	self:sort(self.opponents, "defense")
	
	local function doLiuli(who)
		if not self:isPartner(who) then
			if who:hasSkill("leiji") then
				if self:hasSuit("spade", true, who) or who:getHandcardNum() >= 3 then
					if sgs.getKnownCard(who, "Jink", true) >= 1 then
						return "."
					elseif not self:isEquip("QinggangSword", source) then
						if self:hasEightDiagramEffect(who) then
							return "."
						end
					end
				end
			end
		end
		local cards = self.player:getCards("h")
		cards = sgs.QList2Table(cards)
		local distance = self.player:distanceTo(who)
		local range = self.player:getAttackRange()
		self:sortByKeepValue(cards)
		for _,card in ipairs(cards) do
			if distance <= range then
				if not who:hasSkill("kongcheng") or not who:isKongcheng() then
					local card_str = "@LiuliCard="..card:getEffectiveId().."->"..who:objectName()
					return card_str
				end
			end
		end
		cards = self.player:getCards("e")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		local weapon = self.player:getWeapon()
		for _,equip in ipairs(cards) do
			local flag = true
			if weapon and equip:getId() == weapon:getId() then
				if distance > 1 then
					flag = false
				end
			end
			if flag then
				if equip:isKindOf("OffensiveHorse") then
					if range == distance then
						if self.player:distanceTo(who, 1) > 1 then
							flag = false
						end
					end
				end
			end
			if flag then
				if self.player:inMyAttackRange(who) then
					if not who:hasSkill("kongcheng") or not who:isKongcheng() then
						local card_str = "@LiuliCard="..equip:getEffectiveId().."->"..who:objectName()
						return card_str
					end
				end
			end
		end
		return "."
	end
	
	for _,enemy in ipairs(self.opponents) do
		if not source or source:objectName() ~= enemy:objectName() then
			local ret = doLiuli(enemy)
			if ret ~= "." then 
				return ret 
			end
		end
	end
	for _,p in ipairs(others) do
		if self:isNeutral(p) then
			if not source or source:objectName() ~= p:objectName() then
				local ret = doLiuli(p)
				if ret ~= "." then 
					return ret 
				end
			end
		end
	end
	self:sort(self.partners_noself, "defense")
	self.partners_noself = sgs.reverse(self.partners_noself)
	for _,friend in ipairs(self.friends_noself) do
		if not source or source:objectName() ~= friend:objectName() then
			local flag = false
			if not self:slashIsEffective(slash, friend) then
				flag = true
			elseif self:needLeiji(friend, source) then
				flag = true
			end
			if flag then
				local ret = doLiuli(friend)
				if ret ~= "." then 
					return ret 
				end
			end
		end
	end
	for _,friend in ipairs(self.friends_noself) do
		if not source or source:objectName() ~= friend:objectName() then
			local flag = false
			if self:needToLoseHp(friend, source, true) then
				flag = true
			elseif self:invokeDamagedEffects(friend, source, slash) then
				flag = true
			end
			if flag then
				local ret = doLiuli(friend)
				if ret ~= "." then 
					return ret 
				end
			end
		end
	end
	if self:isWeak() or self:hasHeavySlashDamage(source, slash) then
		if source:hasWeapon("Axe") then
			if source:getCards("he"):length() > 2 then
				if not self:getCardId("Peach") then
					if not self:getCardId("Analeptic") then
						for _, friend in ipairs(self.friends_noself) do
							if not source or source:objectName() ~= friend:objectName() then
								if not self:isWeak(friend) then
									local ret = doLiuli(friend)
									if ret ~= "." then 
										return ret 
									end
								end
							end
						end
					end
				end
			end
		end
		if not self:getCardId("Jink") then
			for _,friend in ipairs(self.friends_noself) do
				if not source or source:objectName() ~= friend:objectName() then
					local flag = false
					if not self:isWeak(friend) then
						flag = true
					elseif self:hasEightDiagramEffect(friend) then
						if sgs.getCardsNum("Jink", friend) >= 1 then
							flag = true
						end
					end
					if flag then
						local ret = doLiuli(friend)
						if ret ~= "." then 
							return ret 
						end
					end
				end
			end
		end
	end
	return "."
end
--[[
	内容：“流离”卡牌需求
]]--
sgs.card_need_system["liuli"] = function(self, card, player)
	if not card:isKindOf("Jink") then
		local cards = player:getCards("he")
		return cards:length() <= 2
	end
	return false
end
sgs.slash_prohibit_system["liuli"] = {
	name = "liuli",
	reason = "liuli",
	judge_func = function(self, target, source, slash)
		--友方
		if self:isPartner(target, source) then
			return false
		end
		--原版解烦
		if source:hasFlag("NosJiefanUsed") then
			return false
		end
		--无牌
		if target:isNude() then
			return false
		end
		--流离
		local friends = self:getPartners(source, nil, true)
		for _,friend in ipairs(friends) do
			if source:canSlash(friend) then
				if self:slashIsEffective(slash, friend, source) then
					return true
				end
			end
		end
		return false
	end
}
--[[
	功能：判断一名角色是否可以将杀流离给其他角色
	参数：target（ServerPlayer类型，表示杀的目标角色）
		other（ServerPlayer类型或table类型，表示其他角色）
	结果：boolean类型，表示是否可以流离
]]--
function SmartAI:canLiuli(target, other)
	if target:hasSkill("liuli") then
		if type(other) == "table" then
			for _,p in ipairs(other) do
				if p:getHp() < 3 then
					if self:canLiuli(target, p) then
						return true
					end
				end
			end
			return false
		else
			local source = self.player
			if not self:needToLoseHp(other, source, true) then
				return false
			elseif not self:invokeDamagedEffect(other, source, sgs.slash) then
				return false
			end
			local num = target:getHandcardNum()
			local dist = target:distanceTo(other)
			local range = target:getAttackRange()
			if num > 0 then
				if dist <= range then
					return true
				end
			end
			local weapon = target:getWeapon()
			local horse = target:getOffensiveHorse()
			if weapon and horse then
				if dist <= range then
					return true
				end
			end
			if weapon or horse then
				if dist <= 1 then
					return true
				end
			end
		end
	end
	return false
end
--[[****************************************************************
	武将：标准·陆逊（吴）
]]--****************************************************************
sgs.ai_chaofeng.luxun = -1
--[[
	技能：谦逊（锁定技）
	描述：你不能被选择为【顺手牵羊】与【乐不思蜀】的目标。 
]]--
--[[
	技能：连营
	描述：每当你失去最后的手牌后，你可以摸一张牌。 
]]--
sgs.ai_skill_invoke["lianying"] = function(self, data)
	if self:needKongcheng(self.player, true) then
		return self.player:getPhase() == sgs.Player_Play
	end
	return true
end
--[[****************************************************************
	武将：标准·孙尚香（吴）
]]--****************************************************************
sgs.ai_chaofeng.sunshangxiang = 6
--[[
	技能：结姻
	描述：出牌阶段限一次，你可以弃置两张手牌并选择一名已受伤的男性角色，你和该角色各回复1点体力。 
]]--
--[[
	内容：“结姻技能卡”的卡牌成分
]]--
sgs.card_constituent["JieyinCard"] = {
	benefit = 2,
	use_priority = 2.8,
}
--[[
	内容：“结姻技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["JieyinCard"] = function(self, card, source, targets)
	local target = targets[1]
	local flag = "jieyin_isenemy_"..target:objectName()
	if not source:hasFlag(flag) then 
		sgs.updateIntention(source, target, -80)
	end
end
--[[
	内容：注册“结姻技能卡”
]]--
sgs.RegistCard("JieyinCard")
--[[
	内容：“结姻”技能信息
]]--
sgs.ai_skills["jieyin"] = {
	name = "jieyin",
	dummyCard = function(self) 
		local card_str = "@JieyinCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if #handcards >= 2 then
			if self.player:usedTimes("JieyinCard") == 0 then
				local alives = self.room:getAlivePlayers()
				for _,p in sgs.qlist(alives) do
					if p:isWounded() then
						if p:isMale() then
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
	内容：“结姻技能卡”的一般使用方式
]]--
sgs.ai_skill_use_func["JieyinCard"] = function(self, card, use)
	if self:needBear() then
		if not self.player:isWounded() then
			if not self:isWeak() then
				return 
			end
		end
	end
	--确定结姻技能卡的卡牌构成
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local first = nil
	local second = nil
	self:sortByUseValue(cards, true)
	for _,c in ipairs(cards) do
		if c:isKindOf("TrickCard") then
			local dummy_use = {
				isDummy = true,
			}
			self:useTrickCard(c, dummy_use)
			if not dummy_use.card then
				if first then
					if not second then
						second = c:getEffectiveId()
					end
				else
					first = c:getEffectiveId()
				end
			end
			if first and second then 
				break 
			end
		end
	end
	for _,c in ipairs(cards) do
		if c:getTypeId() ~= sgs.Card_Equip then
			if first then
				if not second then
					if first ~= c:getEffectiveId() then
						second = c:getEffectiveId()
					end
				end
			else
				first = c:getEffectiveId()
			end
		end
		if first and second then 
			break 
		end
	end
	local card_str = nil
	if first and second then
		card_str = ("@JieyinCard=%d+%d"):format(first, second)
	end
	--确定结姻技能卡的使用对象
	local expects, ignores = self:getWoundedFriend(true)
	local target = nil
	local overflow = self:getOverflow()
	local isWeak = self:isWeak()
	local need_use = isWeak or ( overflow > 0 )
	for _,friend in ipairs(expects) do
		if need_use then
			target = friend
			break
		elseif self:isWeak(friend) then
			target = friend
			break
		end
	end
	if isWeak then
		for _,friend in ipairs(ignores) do
			target = friend
			break
		end
	end
	if not target then
		if isWeak and ( overflow > 1 ) then
			need_use = false
			if self:amLord() then
				need_use = true
			elseif self:amRenegade() then 
				need_use = true
			end
			if need_use then
				local others = self.room:getOtherPlayers(self.player)
				for _,other in sgs.qlist(others) do
					if other:isMale() then
						if other:isWounded() then
							local chaofeng = sgs.ai_chaofeng[other:getGeneralName()] or 0
							if chaofeng <= 2 then
								if not self:hasSkills(sgs.masochism_skill, other) then
									target = other
									self.player:setFlags("jieyin_isenemy_"..other:objectName())
									break
								end
							end
						end
					end
				end
			end
		end
	end
	--使用结姻技能卡
	if target then
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then 
			use.to:append(target) 
		end
		return
	end
end
--[[
	套路：仅使用“结姻技能卡”
]]--
sgs.ai_series["JieyinCardOnly"] = {
	name = "JieyinCardOnly", 
	IQ = 2,
	value = 4, 
	priority = 1, 
	cards = { 
		["JieyinCard"] = 1, 
		["Others"] = 2, 
	},
	enabled = function(self) 
		return true
	end,
	action = function(self, cards) 
		local jieyin_skill = sgs.ai_skills["jieyin"]
		local dummyCard = jieyin_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self) 
		return false
	end,
}
table.insert(sgs.ai_card_actions["JieyinCard"], "JieyinCardOnly")
--[[
	技能：枭姬
	描述：每当你失去一张装备区的装备牌后，你可以摸两张牌。 
]]--
sgs.xiaoji_keep_value = {
	Peach = 6,
	Jink = 5.1,
	Weapon = 4.9,	
	Armor = 5,
	OffensiveHorse = 4.8,
	DefensiveHorse = 5
}
--[[****************************************************************
	武将：标准·华佗（群）
]]--****************************************************************
sgs.ai_chaofeng.huatuo = 6
--[[
	技能：青囊
	描述：出牌阶段限一次，你可以弃置一张手牌并选择一名已受伤的角色，令该角色回复1点体力。
]]--
--[[
	内容：“青囊技能卡”的卡牌成分
]]--
sgs.card_constituent["QingnangCard"] = {
	benefit = 2,
	use_priority = 4.2,
}
sgs.ai_card_intention["QingnangCard"] = -100
--[[
	内容：注册青囊技能卡
]]--
sgs.RegistCard("QingnangCard") 
--[[
	内容：“青囊”技能信息
]]--
sgs.ai_skills["qingnang"] = {
	name = "qingnang",
	dummyCard = function(self) 
		local card_str = "@QingnangCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if #handcards > 0 then
			if self.player:usedTimes("QingnangCard") == 0 then
				local alives = self.room:getAlivePlayers()
				for _,p in sgs.qlist(alives) do
					if p:isWounded() then
						return true
					end
				end
			end
		end
		return false
	end
}
--[[
	内容：“青囊技能卡”的一般使用方式
]]--
sgs.ai_skill_use_func["QingnangCard"] = function(self, card, use)
	if not self.player:isKongcheng() then
		local handcards = self.player:getHandcards()
		handcards = sgs.QList2Table(handcards)
		self:sortByKeepValue(handcards)
		local reds = {}
		local blacks = {}
		local peaches = {}
		local use_card = nil
		for _,c in ipairs(handcards) do
			if c:isBlack() then
				table.insert(blacks, c)
			elseif c:isKindOf("Peach") then
				table.insert(peaches, c)
			else
				table.insert(reds, c)
			end
		end
		if #blacks > 0 then
			use_card = blacks[1]
		elseif #reds > 0 then
			use_card = reds[1]
		elseif #peaches > 0 then
			use_card = peaches[1]
		end
		if use_card then
			local targets = {}
			for _,friend in ipairs(self.partners) do
				if friend:isWounded() then
					table.insert(targets, friend)
				end
			end
			if #targets > 0 then
				self:sort(targets, "defense")
				local target = targets[1]
				local card_str = "@QingnangCard="..use_card:getId()--.."->"..target:objectName()
				local acard = sgs.Card_Parse(card_str)
				use.card = acard
				if use.to then
					use.to:append(target)
				end
			end
		end
	end
end
--[[
	套路：仅使用青囊技能卡
]]--
sgs.ai_series["QingnangCardOnly"] = {
	name = "QingnangCardOnly", 
	value = 4, 
	priority = 1, 
	cards = { 
		["QingnangCard"] = 1, 
		["Others"] = 1, 
	},
	enabled = function(self) 
		return true
	end,
	action = function(self, cards) 
		local qingnang_skill = sgs.ai_skills["qingnang"]
		local dummyCard = qingnang_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self) 
		return false
	end,
}
table.insert(sgs.ai_card_actions["QingnangCard"], "QingnangCardOnly")
--[[
	技能：急救
	描述：你的回合外，你可以将一张红色牌当【桃】使用。 
]]--
sgs.ai_view_as["jijiu"] = function(card, player, place, class_name)
	if place ~= sgs.Player_PlaceSpecial then
		if card:isRed() then
			if player:getPhase() == sgs.Player_NotActive then
				if not player:hasFlag("Global_PreventPeach") then
					local suit = card:getSuitString()
					local number = card:getNumberString()
					local card_id = card:getEffectiveId()
					return ("peach:jijiu[%s:%s]=%d"):format(suit, number, card_id)
				end
			end
		end
	end
end
--[[
	内容：“急救”卡牌需求
]]--
sgs.card_need_system["jijiu"] = sgs.card_need_system["wusheng"]
--[[
	内容：“急救”统计信息
]]--
sgs.card_count_system["jijiu"] = {
	name = "jijiu",
	pattern = "Peach",
	ratio = 0.6,
	statistics_func = function(class_name, player, data)
		if player:hasSkill("jijiu") then
			local count = data["count"]
			count = count + data["Red"] 
			count = count + data["unknown"] * 0.6
			return count
		end
	end
}
sgs.jijiu_suit_value = {
	heart = 6,
	diamond = 6,
}
--[[****************************************************************
	武将：标准·吕布（群）
]]--****************************************************************
sgs.ai_chaofeng.lvbu = 1
--[[
	技能：无双（锁定技）
	描述：每当你使用【杀】指定一名目标角色后，其需依次使用两张【闪】才能抵消。每当你使用【决斗】指定一名目标角色后，或成为一名角色使用【决斗】的目标后，其每次进行响应需依次打出两张【杀】。 
]]--
sgs.ai_skill_cardask["@wushuang-slash-1"] = function(self, data, pattern, target)
	if sgs.ai_skill_cardask["nullfilter"](self, data, pattern, target) then 
		return "." 
	end
	if self:canUseJieyuanDecrease(target) then 
		return "." 
	end
	if not target:hasSkill("jueqing") then
		if self.player:hasSkill("wuyan") then
			return "."
		elseif target:hasSkill("wuyan") then 
			return "." 
		end
	end
	if self:getCardsNum("Slash") < 2 then
		if self.player:getHandcardNum() ~= 1 then
			return "."
		elseif not self:hasSkills(sgs.need_kongcheng) then 
			return "." 
		end
	end
end
sgs.ai_skill_cardask["@multi-jink-start"] = function(self, data, pattern, target, target2, arg)
	local rest_num = tonumber(arg)
	if rest_num == 1 then 
		return sgs.ai_skill_cardask["slash-jink"](self, data, pattern, target) 
	end
	if sgs.ai_skill_cardask["nullfilter"](self, data, pattern, target) then 
		return "." 
	end
	if self:canUseJieyuanDecrease(target) then 
		return "." 
	end
	if sgs.ai_skill_cardask["slash-jink"](self, data, pattern, target) == "." then 
		return "." 
	end
	if self.player:hasSkill("kongcheng") then
		if self.player:getHandcardNum() == 1 then
			if self:getCardsNum("Jink") == 1 then
				if target:hasWeapon("guding_blade") then 
					return "." 
				end
			end
		end
	else
		if self:getCardsNum("Jink") < rest_num then
			if self:hasLoseHandcardEffective() then 
				return "." 
			end
		end
	end
end
sgs.ai_skill_cardask["@multi-jink"] = sgs.ai_skill_cardask["@multi-jink-start"]
--[[****************************************************************
	武将：标准·貂蝉（群）
]]--****************************************************************
sgs.ai_chaofeng.diaochan = 4
--[[
	技能：离间
	描述：出牌阶段限一次，你可以弃置一张牌并选择两名男性角色，令其中一名男性角色视为对另一名男性角色使用一张【决斗】。
]]--
--[[
	功能：确定用于发动离间的卡牌编号
	参数：无
	结果：number类型，表示所用卡牌的编号
]]--
function SmartAI:getLijianCard()
	local card_id
	local handcards = self.player:getHandcards()
	local cards = sgs.QList2Table(handcards)
	self:sortByKeepValue(cards)
	local lightning = self:getCard("Lightning")
	local use_lightning = lightning and self:willUseLightning(lightning)
	local weapon = self.player:getWeapon()
	local armor = self.player:getArmor()
	local def_horse = self.player:getDefensiveHorse()
	local off_horse = self.player:getOffensiveHorse()
	if self:needToThrowArmor() then
		card_id = armor:getId()
	elseif self.player:getHandcardNum() > self.player:getHp() then			
		if lightning and not use_lightning then
			card_id = lightning:getEffectiveId()
		else	
			for _, acard in ipairs(cards) do
				if not acard:isKindOf("Peach") then
					if sgs.isKindOf("BasicCard|EquipCard|AmazingGrace", acard) then
						card_id = acard:getEffectiveId()
						break
					end
				end
			end
		end
	elseif not self.player:getEquips():isEmpty() then
		if weapon then 
			card_id = weapon:getId()
		elseif off_horse then 
			card_id = off_horse:getId()
		elseif def_horse then 
			card_id = def_horse:getId()
		elseif armor and player:getHandcardNum() <= 1 then 
			card_id = armor:getId()
		end
	end
	if not card_id then
		if lightning and not use_lightning then
			card_id = lightning:getEffectiveId()
		else
			for _, acard in ipairs(cards) do
				if not acard:isKindOf("Peach") then
					if sgs.isKindOf("BasicCard|EquipCard|AmazingGrace", acard) then
						card_id = acard:getEffectiveId()
						break
					end
				end
			end
		end
	end
	return card_id
end
--[[
	功能：确定离间的目标
	参数：class_name（string类型，表示离间技能卡的具体类型）
		isDummy（boolean类型，表示是否为模拟离间）
	结果：ServerPlayer类型（first，表示被决斗的角色）和ServerPlayer类型（second，表示发起决斗的角色）
]]--
function SmartAI:findLijianTarget(card_name, isDummy)
	local function findFriend_maxSlash(self, first)
		local maxSlash = 0
		local friend_maxSlash
		local nos_fazheng, fazheng
		for _, friend in ipairs(self.partners_noself) do
			if friend:isMale() then
				if self:trickIsEffective(sgs.duel, first, friend) then
					if friend:getHp() > 1 then
						if friend:hasSkill("nosenyuan") then
							nos_fazheng = friend
						end
						if friend:hasSkill("enyuan") then
							fazheng = friend 
						end
					end
					local slashNum = sgs.getCardsNum("Slash", friend)
					if slashNum > maxSlash then
						maxSlash = slasNum
						friend_maxSlash = friend
					end
				end
			end
		end
		if friend_maxSlash then
			local safe = false
			if self:hasSkills("neoganglie|vsganglie|fankui|enyuan|ganglie|nosenyuan", first) then
				if not self:hasSkills("wuyan|noswuyan", first) then
					if first:getHp() <= 1 then
						if first:getHandcardNum() == 0 then 
							safe = true 
						end
					end
				end
			end
			if not safe then
				if sgs.getCardsNum("Slash", friend_maxSlash) >= sgs.getCardsNum("Slash", first) then 
					safe = true 
				end
			end
			if safe then 
				return friend_maxSlash 
			end
		end
		if nos_fazheng or fazheng then 
			return nos_fazheng or fazheng 
		end	
		return nil
	end
	local flag = false
	if self:amRebel() then
		flag = true
	elseif self:amRenegade() then
		--if sgs.current_mode_players["loyalist"] + 1 > sgs.current_mode_players["rebel"] then
			flag = true
		--end
	end
	local lord = self.room:getLord()
	if flag then
		-- 优先离间1血忠和主
		if lord and lord:isMale() then
			if not lord:isNude() then
				if lord:objectName() ~= self.player:objectName() then
					self:sort(self.opponents, "handcard")
					local e_peaches = 0
					local loyalist
					for _, enemy in ipairs(self.opponents) do
						e_peaches = e_peaches + sgs.getCardsNum("Peach", enemy)
						if not loyalist then
							if enemy:isMale() then
								if enemy:getHp() == 1 then
									if enemy:objectName() ~= lord:objectName() then
										if self:trickIsEffective(sgs.duel, enemy, lord) then
											loyalist = enemy
											break
										end
									end
								end
							end
						end
					end
					if loyalist then
						if e_peaches < 1 then 
							return loyalist, lord
						end
					end
				end
			end
		end
		--收友方反
		if #self.friends_noself >= 2 then
			if self:getAllPeachNum() < 1 then 
				local nextplayerIsEnemy = false
				local nextp = self.player:getNextAlive()
				for i = 1, self.room:alivePlayerCount(), 1 do
					if self:willSkipPlayPhase(nextp) then
						nextp = nextp:getNextAlive()
					else
						if not self:isFriend(nextp) then 
							nextplayerIsEnemy = true 
						end
						break
					end
				end	
				if nextplayerIsEnemy then
					local round = 50
					local to_die, nextfriend
					self:sort(self.enemies, "hp")
					for _, a_friend in ipairs(self.friends_noself) do	-- 目标1：寻找1血友方
						if a_friend:getHp() == 1 then
							if a_friend:isKongcheng() then
								if not self:hasSkills("kongcheng|yuwen", a_friend) then
									if a_friend:isMale() then
										--目标2：寻找位于我之后，离我最近的友方
										for _, b_friend in ipairs(self.friends_noself) do		
											if b_friend:objectName() ~= a_friend:objectName() then
												if b_friend:isMale() then
													local b_round = self:playerGetRound(b_friend)
													if b_round < round then
														if self:trickIsEffective(sgs.duel, a_friend, b_friend) then
															round = b_round
															to_die = a_friend
															nextfriend = b_friend
														end
													end
												end
											end
										end
										if to_die and nextfriend then 
											return to_die, nextfriend 
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
	--帮助孙策主公觉醒
	local others = self.room:getOtherPlayers(self.player)
	if lord and self:isPartner(lord) then
		if lord:hasSkill("hunzi") and lord:getMark("hunzi") == 0 then
			if lord:getHp() == 2 then
				if lord:objectName() ~= self.player:objectName() then
					local enemycount = self:getEnemyNumBySeat(self.player, lord)
					local peaches = self:getAllPeachNum()
					if peaches >= enemycount then
						local f_target, e_target
						for _, ap in sgs.qlist(others) do
							if ap:objectName() ~= lord:objectName() then
								if ap:isMale() and self:trickIsEffective(sgs.duel, lord, ap) then
									if self:hasSkills("jiang|nosjizhi|jizhi", ap) then
										if self:isPartner(ap) then
											if not ap:isLocked(sgs.duel) then
												if not use.isDummy then 
													lord:setFlags("AIGlobal_NeedToWake") 
												end
												return lord, ap
											end
										end
									end
									if self:isPartner(ap) then
										f_target = ap
									else
										e_target = ap
									end
								end
							end
						end
						if f_target or e_target then
							local target
							if f_target and not f_target:isLocked(duel) then
								target = f_target
							elseif e_target and not e_target:isLocked(duel) then
								target = e_target
							end
							if target then
								if not use.isDummy then 
									lord:setFlags("AIGlobal_NeedToWake") 
								end
								return lord, target
							end
						end
					end
				end
			end
		end
	end
	--神关羽武魂带走
	local GuanYu = self.room:findPlayerBySkillName("wuhun")
	if GuanYu and GuanYu:isMale() then
		if GuanYu:objectName() ~= self.player:objectName() then
			if self:amRebel() then
				if lord and lord:isMale() then
					if lord:objectName() ~= self.player:objectName() then
						if not lord:hasSkill("jueqing") then
							if self:trickIsEffective(sgs.duel, GuanYu, lord) then
								return GuanYu, lord
							end
						end
					end
				end
			end
			if self:isEnemy(GuanYu) then
				if #self.enemies >= 2 then
					for _, enemy in ipairs(self.enemies) do
						if enemy:objectName() ~= GuanYu:objectName() then
							if enemy:isMale() then
								if not enemy:isLocked(sgs.duel) then
									if self:trickIsEffective(sgs.duel, GuanYu, enemy) then
										return GuanYu, enemy
									end
								end
							end
						end
					end
				end
			end
		end
	end
	if not self.player:hasUsed(card_name) then
		self:sort(self.opponents, "defense")
		local males, others = {}, {}
		local first, second
		local ZhuGeLiang, XunYu
		for _, enemy in ipairs(self.opponents) do
			if enemy:isMale() then
				if not self:hasSkills("wuyan|noswuyan", enemy) then
					if enemy:hasSkill("kongcheng") then
						if enemy:isKongcheng() then 
							ZhuGeLiang = enemy
						end
					elseif enemy:hasSkill("jieming") then 
						XunYu = enemy
					else
						for _, anotherenemy in ipairs(self.opponents) do
							if anotherenemy:isMale() then
								if anotherenemy:objectName() ~= enemy:objectName() then
									if #males == 0 then
										if self:trickIsEffective(sgs.duel, enemy, anotherenemy) then
											local isHunzi = false
											if enemy:hasSkill("hunzi") then
												if enemy:getMark("hunzi") < 1 then
													if enemy:getHp() == 2 then
														isHunzi = true
													end
												end
											end
											if isHunzi then
												table.insert(others, enemy)
											else
												table.insert(males, enemy)
											end
										end
									end
									if #males == 1 then
										if self:trickIsEffective(sgs.duel, males[1], anotherenemy) then
											if anotherenemy:hasSkills("nosjizhi|jizhi|jiang") then
												table.insert(others, anotherenemy)
											else
												table.insert(males, anotherenemy)
											end
											if #males >= 2 then 
												break 
											end
										end
									end
								end
							end
						end
					end
					if #males >= 2 then 
						break
					end
				end
			end
		end
		if #males >= 1 then
			local male = males[1]
			if self:mayRebel(male) then
				if male:getHp() == 1 then
					local mylord = self:getMyLord()
					if mylord and mylord:isMale() then
						if mylord:objectName() ~= male:objectName() then
							if self:trickIsEffective(sgs.duel, male, mylord) then
								if not mylord:isLocked(sgs.duel) then
									if mylord:objectName() ~= self.player:objectName() then
										local slash_count = sgs.getCardsNum("Slash", male)
										if slash_count < 1 then
											return male, mylord
										elseif slash_count < sgs.getCardsNum("Slash", mylord) then
											return male, mylord
										elseif self:getKnownNum(male) == male:getHandcardNum() then
											if sgs.getKnownCard(male, "Slash", true, "he") == 0 then
												return male, mylord
											end
										end
									end
								end
							end
						end
					end
					local afriend = findFriend_maxSlash(self, male)
					if afriend then
						if afriend:objectName() ~= male:objectName() then
							return male, afriend
						end
					end
				end
			end
		end
		if #males == 1 then
			local male = males[1]
			if self:mayLord(male) then
				if sgs.turncount <= 1 then
					if self:amRebel() then
						if self.player:aliveCount() >= 3 then
							local p_slash = 0
							local max_p, max_pp
							for _, p in sgs.qlist(others) do
								if p:isMale() and not self:isPartner(p) then
									if p:objectName() ~= male:objectName() then
										if self:trickIsEffective(sgs.duel, male, p) then
											if not p:isLocked(sgs.duel) then
												if p_slash < sgs.getCardsNum("Slash", p) then
													if p:getKingdom() == male:getKingdom() then
														max_p = p
														break
													elseif not max_pp then
														max_pp = p
													end
												end
											end
										end
									end
								end
							end
							if max_p then 
								table.insert(males, max_p) 
							end
							if max_pp and #males == 1 then 
								table.insert(males, max_pp)
							end
						end
					end
				end
			end
		end
		if #males == 1 then
			if #others >= 1 and not others[1]:isLocked(sgs.duel) then
				table.insert(males, others[1])
			elseif XunYu and not XunYu:isLocked(sgs.duel) then
				if sgs.getCardsNum("Slash", males[1]) < 1 then
					table.insert(males, XunYu)
				else
					local drawcards = 0
					for _, enemy in ipairs(self.opponents) do
						local x = 0
						local maxhp = enemy:getMaxHp()
						local num = enemy:getHandcardNum()
						if maxhp > num then
							x = math.min(5, maxhp-num)
						end
						if x > drawcards then 
							drawcards = x 
						end
					end
					if drawcards <= 2 then
						table.insert(males, XunYu)
					end
				end
			end
		end
		if #males == 1 and #self.partners_noself > 0 then
			first = males[1]
			if ZhuGeLiang and self:trickIsEffective(sgs.duel, first, ZhuGeLiang) then
				table.insert(males, ZhuGeLiang)
			else
				local friend_maxSlash = findFriend_maxSlash(self, first)
				if friend_maxSlash then 
					table.insert(males, friend_maxSlash) 
				end
			end
		end
		if #males >= 2 then
			first = males[1]
			second = males[2]
			if lord then
				if first:getHp() <= 1 then
					local case = false
					if sgs.role_predictable then
						case = true
					elseif self:mayLord(self.player) then
						case = true
					end
					if case then
						local friend_maxSlash = findFriend_maxSlash(self, first)
						if friend_maxSlash then 
							second = friend_maxSlash 
						end
					elseif lord:isMale() then
						if not self:hasSkills("wuyan|noswuyan", lord) then
							case = true
							if self:amRebel() then
								if first:objectName() ~= lord:objectName() then
									if self:trickIsEffective(sgs.duel, first, lord) then
										second = lord
										case = false
									end
								end
							end
							if case then
								if self:amLoyalist() or self:amRenegade() then
									if not self:hasSkills("ganglie|enyuan|neoganglie|nosenyuan", first) then
										if sgs.getCardsNum("Slash", first) <= sgs.getCardsNum("Slash", second) then
											second = lord
										end
									end
								end
							end
						end
					end
				end
			end
			if first and second then
				if first:objectName() ~= second:objectName() then
					if not second:isLocked(sgs.duel) then
						return first, second
					end
				end
			end
		end
	end
	return nil, nil
end
--[[
	内容：“离间技能卡”的卡牌信息
]]--
sgs.card_constituent["LijianCard"] = {
	damage = 2,
	use_value = 8.5,
	use_priority = 4,
}
--[[
	内容：“离间技能卡”的卡牌仇恨值
]]--
sgs.ai_card_intention["LijianCard"] = function(self, card, source, targets)
	if self:isPartner(targets[1], targets[2]) then
		if self:mayRebel(source) then
			if self:mayRebel(targets[1]) then
				if targets[1]:getHp() == 1 then
					sgs.updateIntentions(source, targets, 40)
				end
			end
		end
	elseif not targets[1]:hasSkill("wuhun") then
		sgs.updateIntention(source, targets[1], 80)
	end
end
--[[
	内容：注册“离间技能卡”
]]--
sgs.RegistCard("LijianCard")
--[[
	内容：“离间”技能信息
]]--
sgs.ai_skills["lijian"] = {
	name = "lijian",
	dummyCard = function(self)
		local card_str = "@LijianCard=."
		return sgs.Card_Parse(card_str)
	end,
	enabled = function(self, handcards)
		if self.player:hasUsed("LijianCard") then
			return false
		elseif self.player:isNude() then
			return false
		end
		return true
	end,
}
--[[
	内容：“离间技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["LijianCard"] = function(self, card, use)
	local card_id = self:getLijianCard()
	if card_id then
		local first, second = self:findLijianTarget("LijianCard", use.isDummy)
		if first and second then
			local card_str = "@LijianCard=" .. card_id
			local acard = sgs.Card_Parse(card_str)
			use.card = acard
			if use.to then
				use.to:append(first)
				use.to:append(second)
			end
		end
	end
end
--[[
	套路：仅使用“离间技能卡”
]]--
sgs.ai_series["LijianCardOnly"] = {
	name = "LijianCardOnly",
	IQ = 2,
	value = 3,
	priority = 3,
	skills = "lijian",
	cards = {
		["LijianCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local lijian_skill = sgs.ai_skills["lijian"]
		local dummyCard = lijian_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["LijianCard"], "LijianCardOnly")
--[[
	技能：闭月
	描述：结束阶段开始时，你可以摸一张牌。 
]]--
sgs.ai_skill_invoke["biyue"] = function(self, data)
	return not self:needKongcheng(self.player, true)
end
--[[****************************************************************
	武将：标准·袁术（群）
]]--****************************************************************
--[[
	技能：妄尊
	描述：主公的准备阶段开始时，你可以摸一张牌，然后主公本回合手牌上限-1。 
]]--
sgs.ai_skill_invoke["wangzun"] = function(self, data)
	local lord = self.room:getCurrent()
	if self.player:getPhase() == sgs.Player_NotActive then
		if self:needKongcheng(self.player, true) then
			if self.player:hasSkill("manjuan") then
				return self:isOpponents(lord)
			end
		end
	end
	if self:isOpponent(lord) then 
		return true
	else
		if not self:isWeak(lord) then
			local overflow = self:getOverflow(lord)
			if overflow < -2 then
				return true
			elseif self:willSkipDrawPhase(lord) then
				if overflow < 0 then
					return true
				end
			end
		end
	end
	return false
end
--[[
	技能：同疾（锁定技）
	描述：若你的手牌数大于你的体力值，且你在一名其他角色的攻击范围内，则其他角色不能被选择为该角色的【杀】的目标。 
]]--
--[[****************************************************************
	武将：标准·华雄（群）
]]--****************************************************************
--[[
	技能：耀武（锁定技）
	描述：每当你受到红色【杀】的伤害时，伤害来源选择一项：回复1点体力，或摸一张牌。 
]]--
sgs.ai_skill_choice["yaowu"] = function(self, choices)
	local hp = self.player:getHp()
	if hp >= sgs.getBestHp(self.player) then
		return "draw"
	end
	if self:needKongcheng(self.player, true) then
		if self.player:getPhase() == sgs.Player_NotActive then
			return "draw"
		end
	end	
	return "recover"
end