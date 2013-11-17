--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）中心计算文件
]]--
--[[****************************************************************
	卡牌控制
]]--****************************************************************
--[[
	功能：获取统一卡牌用名
	参数：card（Card类型，表示目标卡牌）
		nametype（string类型，表示用名要求）
	结果：string类型（name），表示卡牌用名
]]--
function sgs.getCardName(card, nametype)
	if card then
		--获取对象名
		if nametype == "objectName" then
			return card:objectName()
		--获取类型名
		elseif nametype == "className" then
			return card:getClassName()
		--获取技能名
		elseif nametype == "skillName" then
			return card:getSkillName()
		--获取卡牌字符串
		elseif nametype == "cardString" then
			return card:toString()
		--获取统一用名
		else
			local name = card:getClassName()
			if name == "SkillCard" or name == "LuaSkillCard" then
				name = card:objectName()
			elseif not card:isKindOf("SkillCard") then
				local skillname = card:getSkillName()
				if skillname and skillname ~= "" then
					name = skillname..">>"..name
				end
			end
			return name
		end
	end
end
--[[
	功能：获取卡牌成分
	参数：card_name（string类型，表示卡牌统一用名）
		type（string类型，表示待查的成分类型。其中：
			damage表示伤害成分；
			control表示控制成分；
			lucky表示幸运成分；
			benefit表示收益成分；
			use_value表示卡牌的使用价值；
			keep_value表示卡牌的保留价值；
			use_priority表示卡牌的使用优先级
		）
		player（ServerPlayer类型，表示只针对角色）
	结果：number类型，表示卡牌成分对应的数值
]]--
function sgs.getCardValue(card_name, type, player)
	if player then
		if type == "use_value" then
			return sgs.getUseValue(card_name, player)
		elseif type == "keep_value" then
			return sgs.getKeepValue(card_name, player)
		elseif type == "use_priority" then
			return sgs.getUsePriority(card_name, player)
		end
	end
	local constituent = sgs.card_constituent[card_name]
	if constituent then
		return constituent[type] or 0
	end
	return 0
end
--[[
	功能：获取一名角色对于当前角色而言所有已知的卡牌数量（全局视角）
	参数：player（ServerPlayer类型，表示目标角色）
	结果：number类型（known），表示已知的卡牌数量
]]--
function sgs.getKnownNum(player)
	if player then
		local cards = player:getHandcards()
		local known = 0
		local current = global_room:getCurrent()
		local myname = current:objectName()
		local name = player:objectName()
		local flag = string.format("visible_%s_%s", myname, name)
		for _, card in sgs.qlist(cards) do
			if card:hasFlag("visible") or card:hasFlag(flag) then
				known = known + 1
			end
		end
		return known
	else
		global_room:writeToConsole(debug.traceback())
	end
end
--[[
	功能：获取一名角色对于当前角色而言所有已知的某类卡牌的数量
	参数：player（Player类型，表示目标角色）
		class_name（string类型，表示卡牌类型）
		viewas（boolean类型）
		flag（string类型，表示卡牌位置）
	结果：number类型
]]--
function sgs.getKnownCard(player, class_name, viewas, flag)
	if player then
		flag = flag or "h"
		player = findPlayerByObjectName(global_room, player:objectName())
		local cards = player:getCards(flag)
		local count = 0
		local suits = {
			["club"] = 1, 
			["spade"] = 1, 
			["diamond"] = 1, 
			["heart"] = 1
		}
		local current = global_room:getCurrent()
		local myname = current:objectName()
		local name = player:objectName()
		local visible_flag = string.format("visible_%s_%s", myname, name)
		for _,card in sgs.qlist(cards) do
			local id = card:getEffectiveId()
			local place = global_room:getCardPlace(id)
			local isVisible = false
			if card:hasFlag("visible") then
				isVisible = true
			elseif card:hasFlag(visible_flag) then
				isVisible = true
			elseif place == sgs.Player_PlaceEquip then
				isVisible = true
			elseif name == myname then
				isVisible = true
			end
			if isVisible then
				local will_count = false
				if viewas then
					if sgs.isCard(class_name, card, player) then
						will_count = true
					end
				end
				if card:isKindOf(class_name) then
					will_count = true
				end
				if not will_count and suits[class_name] then
					if card:getSuitString() == class_name then
						will_count = true
					end
				end
				if class_name == "red" then
					if card:isRed() then
						will_count = true
					end
				elseif class_name == "black" then
					if card:isBlack() then
						will_count = true
					end
				end
				if will_count then
					count = count + 1 
				end
			end
		end
		return count
	else
		global_room:writeToConsole(debug.traceback())
	end
	return 0
end
--[[
	功能：获取一名角色对于当前角色而言的所有已知卡牌的数量（玩家视角）
	参数：player（ServerPlayer类型，表示目标角色）
	结果：number类型（known），表示已知卡牌的数量
]]--
function SmartAI:getKnownNum(player)
	player = player or self.player
	if player then
		local cards = player:getHandcards()
		local current = self.room:getCurrent()
		local flag = string.format("visible_%s_%s", current:objectName(), player:objectName())
		local known = 0
		for _,card in sgs.qlist(cards) do
			if card:hasFlag("visible") or card:hasFlag(flag) then
				known = known + 1
			end
		end
		return known
	else
		return self.player:getHandcardNum()
	end
end
--[[
	功能：获取一名角色拥有的指定花色的卡牌数目
	参数：suits（string类型，表示指定的花色）
		include_equip（boolean类型，表示是否包括装备）
		player（ServerPlayer类型，表示目标角色）
	结果：number类型（count），表示卡牌数目
]]--
function SmartAI:getSuitNum(suits, include_equip, player)
	player = player or self.player
	local flag = include_equip and "he" or "h"
	local count = 0
	local cards = nil
	if player:objectName() == self.player:objectName() then
		cards = player:getCards(flag)
		cards = sgs.QList2Table(cards)
	else
		if include_equip then
			cards = player:getEquips()
			cards = sgs.QList2Table(cards)
		else
			cards = {}
		end
		local handcards = player:getHandcards()
		local visible_flag = string.format("visible_%s_%s", self.player:objectName(), player:objectName())
		for _,c in sgs.qlist(handcards) do
			if c:hasFlag("visible") or c:hasFlag(visible_flag) then
				table.insert(cards, c)
			end
		end
	end
	suits = suits:split("|")
	for _,c in ipairs(cards) do
		for _,suit in ipairs(suits) do
			if c:getSuitString() == suit then
				count = count + 1
			end
		end
	end
	return count
end
--[[
	功能：判断一名角色是否拥有的指定花色的卡牌
	参数：suits（string类型，表示指定的花色）
		include_equip（boolean类型，表示是否包括装备）
		player（ServerPlayer类型，表示目标角色）
	结果：boolean类型，表示是否拥有
]]--
function SmartAI:hasSuit(suits, include_equip, player)
	return self:getSuitNum(suits, include_equip, player) > 0
end
--[[
	功能：获取一名角色手牌中最多可能拥有的某类卡牌的数目
	参数：class_name（string类型，表示卡牌类型）
		target（ServerPlayer类型，表示目标角色）
	结果：number类型（count），表示估计的卡牌数目
]]--
function SmartAI:getRestCardsNum(class_name, target)
	target = target or self.player
	local total = sgs.Sanguosha:getCardCount() --卡牌总数
	local total_num = 0 --目标类型卡牌总数
	for i=1, total, 1 do
		local card = sgs.Sanguosha:getEngineCard(i-1)
		if card:isKindOf(class_name) then 
			total_num = total_num + 1 
		end
	end
	sgs.discard_pile = self.room:getDiscardPile() --弃牌堆
	local discard_num = 0 --弃牌堆中的目标类型卡牌总数
	for _,id in sgs.qlist(sgs.discard_pile) do
		local card = sgs.Sanguosha:getEngineCard(id)
		if card:isKindOf(class_name) then 
			discard_num = discard_num + 1 
		end
	end
	local known_num = 0 --已知的其他角色拥有的目标类型卡牌总数
	local others = self.room:getOtherPlayers(target)
	for _,p in sgs.qlist(others) do
		local known = sgs.getKnownCard(p, class_name)
		known_num = known_num + known
	end
	local count = total_num - discard_num - known_num
	return count
end
--[[
	功能：判断是否应避免对目标角色使用杀
	参数：target（ServerPlayer类型，表示杀的目标角色）
		source（ServerPlayer类型，表示使用杀的角色）
		slash（Card类型，表示待使用的杀）
	结果：boolean类型，表示是否应避免
]]--
function SmartAI:slashIsProhibited(target, source, slash)
	source = source or self.player
	slash = slash or sgs.slash
	--禁止技
	if self.room:isProhibited(source, target, slash) then
		return true
	end
	--杀禁止判定
	for _,item in pairs(sgs.slash_prohibit_system) do
		local skills = item["reason"] or ""
		if self:hasAllSkills(skills, target) then
			local callback = item["judge_func"]
			if callback and callback(self, target, source, slash) then
				return true
			end
		end
	end
	return false
end
--[[
	功能：
	参数：class_name（string类型，表示目标卡牌类型）
		player（ServerPlayer类型，表示作为卡牌来源的角色）
		card（Card类型，表示唯一需要考虑的卡牌）
	结果：string类型，表示卡牌产生字符串
]]--
function SmartAI:getCardId(class_name, player, card)
	player = player or self.player
	local cards = nil
	if card then 
		cards = { card }
	else
		cards = player:getCards("he")
		local piles = player:getPileNames() --type(piles) == "StringList" -> table
		for _, key in ipairs(piles) do
			local pile = player:getPile(key)
			for _, id in sgs.qlist(pile) do
				local c = sgs.Sanguosha:getCard(id)
				cards:append(c)
			end
		end
		cards = sgs.QList2Table(cards)
	end
	self:sortByUsePriority(cards, false, player)
	local card_str = sgs.getValuableViewAsString(self, class_name, player)
	if card_str then
		return card_str
	end
	--蛊惑
	local guhuo_str = self:getGuhuoCard(class_name, false)
	if guhuo_str then
		return guhuo_str
	end
	local vs_card_strs = {}
	local st_card_ids = {}
	for _,c in ipairs(cards) do
		local id = c:getEffectiveId()
		local place = self.room:getCardPlace(id)
		--视为技
		local vs_str = sgs.getViewAsCard(c, class_name, player, place, true)
		if vs_str then
			table.insert(vs_card_strs, vs_str)
		end
		--直接使用
		if c:isKindOf(class_name) then
			if not sgs.prohibitUseDirectly(c, player) then
				if place ~= sgs.Player_PlaceSpecial then
					table.insert(st_card_ids, id)
				end
			end
		end
	end
	local vs_str = nil
	local vs_card = nil
	local st_id = nil
	if #vs_card_strs > 0 then
		vs_str = vs_card_strs[1]
		vs_card = sgs.Card_Parse(vs_str)
	end
	if #st_card_ids > 0 then
		st_id = st_card_ids[1]
	end
	if vs_str or st_id then
		local reverse = false
		if player:hasSkill("chongzhen") then
			if vs_card then
				if vs_card:getSkillName() == "longdan" then
					reverse = true
				end
			end
		end
		if reverse then
			return vs_str or st_id
		else
			return st_id or vs_str
		end
	end
	return sgs.getViewAsString(self, class_name, player, true)
end
--[[
	功能：
	参数：class_name（string类型，表示目标卡牌类型）
		player（ServerPlayer类型，表示作为卡牌来源的角色）
	结果：Card类型
]]--
function SmartAI:getCard(class_name, player)
	player = player or self.player
	local card_id = self:getCardId(class_name, player)
	if card_id then 
		return sgs.Card_Parse(card_id) 
	end
end
--[[
	功能：判断一名角色是否装备有指定装备
	参数：equip_name（string类型，表示指定装备名）
		player（ServerPlayer类型，表示待判断的角色）
	结果：boolean类型，表示装备情况（true表示装备了此装备，false表示未装备）
]]--
function SmartAI:isEquip(equip_name, player)
	player = player or self.player
	local equips = player:getCards("e")
	for _, equip in sgs.qlist(equips) do
		if equip:isKindOf(equip_name) then 
			return true 
		end
	end
	if equip_name == "EightDiagram" then
		if player:hasSkill("bazhen") then
			if not player:getArmor() then 
				return true 
			end
		end
	elseif equip_name == "Crossbow" then
		if player:hasSkill("paoxiao") then 
			return true 
		end
	end
	return false
end
--[[
	功能：判断一名角色是否无视目标角色的防具
	参数：from（ServerPlayer类型，表示待判断的角色）
		to（ServerPlayer类型，表示目标角色）
	结果：boolean类型，表示是否无视
]]--
function sgs.IgnoreArmor(from, to)
	if from and to then
		if from:hasWeapon("QinggangSword") then
			return true
		elseif to:getMark("Armor_Nullified") > 0 then
			return true
		end
		return false
	else
		global_room:writeToConsole(debug.traceback())
	end
end
--[[
	功能：评价防具价值
	参数：armor（Card类型，表示待评价的防具卡牌）
		player（ServerPlayer类型，表示装备该防具的角色）
	结果：number类型（value），表示装备的价值
]]--
function SmartAI:evaluateArmor(armor, player)
	player = player or self.player
	local value = 0
	local armor = armor or player:getArmor()
	if armor then
		if player:hasSkill("jijiu") then
			if armor:isRed() then
				value = value + 0.5
			end
		end
		if self:hasSkills("qixi|guidao", player) then
			if armor:isBlack() then
				value = value + 0.5
			end
		end
		local skills = player:getVisibleSkillList()
		for _,skill in sgs.qlist(skills) do
			local callback = sgs.ai_armor_value[skill:objectName()]
			if type(callback) == "function" then
				local v = callback(self, armor, player) or 0
				value = value + v
			end
		end
		local callback = sgs.ai_armor_value[armor:objectName()]
		if type(callback) == "function" then
			local v = callback(self, armor, player) or 0
			value = value + v
		else
			value = value + 0.5
		end
		return value
	end
	return 0
end
--[[
	功能：判断目标角色是否需要弃置防具
	参数：player（ServerPlayer类型，表示目标角色）
	结果：boolean类型，表示是否需要
]]--
function SmartAI:needToThrowArmor(player)
	player = player or self.player
	local armor = player:getArmor()
	if armor then
		if player:hasArmorEffect(armor:objectName()) then
			if self:hasSkills("bazhen|yizhong") then
				if not armor:isKindOf("EightDiagram") then 
					return true 
				end
			end
			if self:evaluateArmor(armor, player) <= -2 then 
				return true 
			end
			if player:hasArmorEffect("SilverLion") then
				if player:isWounded() then
					if self:isPartner(player) then
						if player:objectName() == self.player:objectName() then
							return true
						elseif self:isWeak(player) then
							return not player:hasSkills(sgs.use_lion_skill)
						end
					else
						return true
					end
				end
			end
			if not self.player:hasSkill("moukui") then
				if player:hasArmorEffect("Vine") then
					if player:objectName() ~= self.player:objectName() then
						if self:isEnemy(player) then
							if self.player:getPhase() == sgs.Player_Play then
								if sgs.slash:isAvailable(self.player) then
									if not self:slashIsProhibited(player, self.player, sgs.fire_slash) then
										if not sgs.IgnoreArmor(self.player, player) then
											local haveFireSlash = false
											if self:getCard("FireSlash") then
												haveFireSlash = true
											elseif self:getCard("Slash") then
												if self:isEquip("Fan") then
													haveFireSlash = true
												elseif self:hasSkills("lihuo|zonghuo", self.player) then
													haveFireSlash = true
												elseif self:getCardsNum("Fan") > 0 then
													haveFireSlash = true
												end
											end
											if haveFireSlash then
												if player:isKongcheng() then
													return true
												elseif sgs.card_lack[player:objectName()]["Jink"] == 1 then
													return true
												elseif sgs.getCardsNum("Jink", player) < 1 then
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
	end
	return false
end
--[[****************************************************************
	AI免疫体系
]]--****************************************************************
sgs.damage_invalid_system = {} --伤害无效系统
sgs.trick_invalid_system = {} --锦囊无效系统
sgs.aoe_invalid_system = {} --AOE伤害无效系统
sgs.slash_invalid_system = {} --杀无效系统
sgs.amazing_grace_invalid_system = {} --五谷丰登无效系统
sgs.slash_prohibit_system = {} --杀禁止系统
sgs.best_hp_system = {} --最优体力系统
sgs.damage_avoid_system = {} --伤害避免系统
sgs.heavy_slash_system = {} --杀伤加成系统
sgs.ai_damage_requirement = {} --伤害需求表
sgs.draw_cards_system = {} --摸牌统计系统
--[[
	功能：判断一次伤害是否有效
	参数：target（ServerPlayer类型，表示伤害对象）
		nature（sgs.DamageStruct_Nature类型，表示伤害属性）
		source（ServerPlayer类型，表示伤害来源）
	结果：boolean类型，表示伤害是否有效
]]--
function SmartAI:damageIsEffective(target, nature, source)
	target = target or self.player
	source = source or self.room:getCurrent()
	nature = nature or sgs.DamageStruct_Normal
	--伤害来源有技能“绝情”
	if source:hasSkill("jueqing") then 
		return true
	end
	--考虑场上“五灵·火”的影响
	local JinXuanDi = self.room:findPlayerBySkillName("wuling")
	if JinXuanDi and JinXuanDi:getMark("@fire") > 0 then
		nature = sgs.DamageStruct_Fire
	end
	--伤害无效判定
	local notThunder = ( nature ~= sgs.DamageStruct_Thunder )
	for _,item in pairs(sgs.damage_invalid_system) do
		local callback = item["judge_func"]
		if callback and callback(target, nature, source, notThunder) then
			return false
		end
	end
	return true
end
--[[
	功能：判断锦囊牌对一名角色是否有效
	参数：card（Card类型，表示待使用的锦囊牌）
		target（ServerPlayer类型，表示待判断的目标角色）
		source（ServerPlayer类型，表示锦囊牌的使用者）
	结果：boolean类型，表示是否有效
]]--
function SmartAI:trickIsEffective(card, target, source)
	target = target or self.player
	source = source or self.room:getCurrent()
	--禁止技
	if self.room:isProhibited(source, target, card) then 
		return false 
	end
	--锦囊无效判定
	for _,item in pairs(sgs.trick_invalid_system) do
		local callback = item["judge_func"]
		if type(callback) == "function" then
			if callback(card, target, source) then
				return false
			end
		end
	end
	--锦囊伤害无效判定
	local nature = sgs.DamageStruct_Normal
	if card:isKindOf("FireAttack") then
		nature = sgs.DamageStruct_Fire
	end
	local JinXuanDi = self.room:findPlayerBySkillName("wuling")
	if JinXuanDi and JinXuanDi:getMark("@fire") > 0 then 
		nature = sgs.DamageStruct_Fire 
	end
	if sgs.isKindOf("Duel|FireAttack|ArcheryAttack|SavageAssault", card) then
		--self.equipsToDec = sgs.getCardNumAtCertainPlace(card, from, sgs.Player_PlaceEquip)
		local effective = self:damageIsEffective(target, nature, source)
		self.equipsToDec = 0
		if not effective then
			return false
		end
	end
	return true
end
--[[
	功能：判断AOE对一名角色是否有效
	参数：card（Card类型，表示待使用的AOE卡牌）
		target（ServerPlayer类型，表示待判断的目标角色）
		source（ServerPlayer类型，表示AOE卡牌使用者）
	结果：boolean类型，表示是否有效
]]--
function SmartAI:aoeIsEffective(card, target, source)
	source = source or self.room:getCurrent()
	local alive_count = self.room:alivePlayerCount()
	--禁止技
	if self.room:isProhibited(source, target, card) then
		return false
	end
	--卡牌锁定
	if target:isLocked(card) then
		return false
	end
	--AOE无效判定
	for _,item in pairs(sgs.aoe_invalid_system) do
		local callback = item["judge_func"]
		if callback and callback(card, target, source) then
			return false
		end
	end
	--伤害无效判定
	return self:damageIsEffective(target, sgs.DamageStruct_Normal, source)
end
--[[
	功能：判断五谷丰登对一名角色是否有效
	参数：card（Card类型，表示五谷丰登卡牌）
		target（ServerPlayer类型，表示五谷丰登的目标角色）
		source（ServerPlayer类型，表示五谷丰登的使用者）
	结果：boolean类型，表示是否有效
]]--
function SmartAI:AG_IsEffective(card, target, source)
	for _,item in pairs(sgs.amazing_grace_invalid_system) do
		local callback = item["judge_func"]
		if type(callback) == "function" then
			if callback(self, card, target, source) then
				return false
			end
		end
	end
	return true
end
--[[
	功能：判断是否适合对一名角色使用铁索连环
	参数：target（ServerPlayer类型，表示将被使用铁索连环的目标角色）
		source（ServerPlayer类型，表示使用铁索连环的角色）
		nature（sgs.DamageStruct_Nature类型，表示伤害属性）
		damage（number类型，表示伤害点数）
		slash（Card类型，表示将对目标角色使用的杀）
	结果：boolean类型，表示是否适合使用
]]--
function SmartAI:isGoodChainTarget(target, source, nature, damage, slash)
	if target:isChained() then
		source = source or self.player
		nature = nature or sgs.DamageStruct_Fire
		damage = damage or 1
		if source:hasSkill("jueqing") then 
			return true 
		end
		if slash then
			if slash:isKindOf("FireSlash") then
				nature = sgs.DamageStruct_Fire
			elseif slash:isKindOf("ThunderSlash") then
				nature = sgs.DamageStruct_Thunder
			else
				nature = sgs.DamageStruct_Normal
			end
		elseif nature == sgs.DamageStruct_Fire then
			if target:hasArmorEffect("Vine") then 
				damage = damage + 1 
			end
			if target:getMark("@gale") > 0 then
				if self.room:findPlayerBySkillName("kuangfeng") then 
					damage = damage + 1 
				end
			end
		end
		local JinXuanDi = self.room:findPlayerBySkillName("wuling")
		if JinXuanDi then
			if JinXuanDi:getMark("@fire") then 
				nature = sgs.DamageStruct_Fire
			elseif not slash then
				if JinXuanDi:getMark("@thunder") > 0 then
					if nature == sgs.DamageStruct_Thunder then
						damage = damage + 1
					end
				elseif JinXuanDi:getMark("@wind") > 0 then
					if nature == sgs.DamageStruct_Fire then
						damage = damage + 1
					end
				end
			end
		end
		if self:damageIsEffective(target, nature, source) then
			if target:hasArmorEffect("SilverLion") then 
				damage = 1 
			end
			local kills = 0, kill_lord, the_enemy 
			local good, bad, F_count, E_count = 0, 0, 0, 0
			local peach_num = 0
			if self.player:objectName() == source:objectName() then
				peach_num = self:getCardsNum("Peach") 
			else
				peach_num = sgs.getCardsNum("Peach", source)
			end
			
			local function getChainedPlayerValue(player, point)
				local value = 0
				if self:isGoodChainPartner(player) then 
					value = value + 1 
				end
				if self:isWeak(player) then 
					value = value - 1 
				end
				if nature == sgs.DamageStruct_Fire then
					if point then
						if player:hasArmorEffect("Vine") then
							point = point + 1
						end
						if player:getMark("@gale") > 0 then
							if self.room:findPlayerBySkillName("kuangfeng") then
								point = point + 1
							end
						end
					end
				end
				if self:cannotBeHurt(player, damage, source) then 
					value = value - 100 
				end
				if damage + (point or 0) >= player:getHp() then
					value = value - 2
					if self:mayLord(player) then
						if not self:isPartner(player, source) then 
							kill_lord = true 
						end
					end
					if self:isOpponent(player, source) then 
						kills = kills + 1 
					end
				else
					if self:isOpponent(player, source) then
						if source:getHandcardNum() < 2 then
							if player:hasSkills("ganglie|neoganglie") then
								if source:getHp() == 1 then
									if self:damageIsEffective(source, nil, player) then
										if peach_num < 1 then 
											value = value - 100 
										end
									end
								end
							end
						end
					end
					if player:hasSkill("vsganglie") then
						local can
						local friends = self:getPartners(source)
						for _, t in ipairs(friends) do
							if t:getHp() == 1 then
								if t:getHandcardNum() < 2 then
									if self:damageIsEffective(t, nil, player) then
										if peach_num < 1 then
											if self:mayLord(t) then
												value = value - 100
												if not self:isOpponent(t, source) then 
													killlord = true 
												end
											end
											can = true
										end
									end
								end
							end
						end
						if can then 
							value = value - 2 
						end
					end
				end
				if player:hasArmorEffect("SilverLion") then 
					return value - 1 
				end
				value = value - damage - (point or 0)
				return value
			end
			
			local value = getChainedPlayerValue(target)
			if self:isPartner(target) then
				good = value
				F_count = F_count + 1
			elseif self:isOpponent(target) then
				bad = value
				E_count = E_count + 1
			end
			if nature == sgs.DamageStruct_Normal then 
				return good >= bad 
			end
			local alives = self.room:getAllPlayers()
			for _, player in sgs.qlist(alives) do
				if player:objectName() ~= target:objectName() then
					if player:isChained() then
						if self:damageIsEffective(player, nature, source) then
							local v = getChainedPlayerValue(player, 0)
							if not kill_lord then
								local enemies = self:getOpponents(source)
								if kills == #enemies then
									if slash then
										self.room:setCardFlag(slash, "AIGlobal_killoff")
									end
									return true
								end
							end
							if self:isPartner(player) then
								good = good + v
								F_count = F_count + 1
							elseif self:isOpponent(player) then
								bad = bad + v
								E_count = E_count + 1
								the_enemy = player
							end
						end
					end
				end
			end
			if kill_lord then
				if self:mayRebel(source) then 
					return true 
				end
			end
			if slash then
				if F_count == 1 and E_count == 1 then
					if the_enemy then
						if the_enemy:isKongcheng() then
							if the_enemy:getHp() == 1 then
								local slashes = self:getCards("Slash")
								for _, c in ipairs(slashes) do
									if not c:isKindOf("NatureSlash") then
										if not self:willUseSlash(the_enemy, source, slash) then 
											return 
										end
									end
								end
							end
						end
					end
				end
			end
			if F_count > 0 and E_count <= 0 then 
				return false
			end
			return good >= bad
		end
	end
	return false
end
--[[
	功能：判断是否应对一名角色使用杀
	参数：target（ServerPlayer类型，表示杀的目标角色）
		source（ServerPlayer类型，表示杀的使用者）
		card（Card类型，表示待使用的杀）
	结果：boolean类型，表示是否应使用
]]--
function SmartAI:willUseSlash(target, source, card)
	if sgs.current_mode:find("_mini_36") then
		return not self.player:hasSkill("keji")
	end
	card = card or sgs.slash
	source = source or self.player
	if self:slashIsProhibited(target, source, card) then
		return false
	end
	local nature = sgs.DamageStruct_Normal
	if card:isKindOf("FireSlash") then
		nature = sgs.DamageStruct_Fire
	elseif card:isKindOf("ThunderSlash") then
		nature = sgs.DamageStruct_Thunder
	end
	local isEffective = self:slashIsEffective(card, target, nil, source)
	if self:isPartner(target, source) then
		local isFireSlash = false
		if card:isKindOf("FireSlash") then
			isFireSlash = true
		elseif source:hasWeapon("Fan") then
			isFireSlash = true
		elseif source:hasSkill("zonghuo") then
			isFireSlash = true
		end
		if isFireSlash then
			if target:hasArmorEffect("Vine") then
				if not target:isChained() then
					return false
				elseif not self:isGoodChainTarget(target, source, sgs.DamageStruct_Fire, nil, card) then 
					return false 
				end
			end
			if isEffective then
				if target:isChained() then
					if not source:hasSkill("jueqing") then
						if card:isKindOf("NatureSlash") or source:hasSkill("zonghuo") then
							if not self:isGoodChainTarget(target, self.player, nature, nil, card) then
								return false 
							end
						end
					end
				end
			end
			if isEffective then
				if target:getHp() < 2 then
					if sgs.getCardsNum("Jink", target) == 0 then
						return false 
					end
				end
			end
			if isEffective then
				if self:mayLord(target) then
					if self:isWeak(target) then 
						return false 
					end
				end
			end
			if target:isKongcheng() then
				if self:isEquip("GudingBlade", source) then
					return false 
				end
			end
		end
	else
		if isEffective then
			if card:isKindOf("NatureSlash") or source:hasSkill("zonghuo") then
				if target:isChained() then
					if not source:hasSkill("jueqing") then
						if not self:isGoodChainTarget(target, source, nature, nil, card) then
							return false
						end
					end
				end
			end
		end
	end
	return isEffective 
end
--[[
	内容：判断一名角色是否处于危险之中
	参数：player（ServerPlayer类型，表示待判断的目标角色）
	结果：boolean类型，表示是否危险
]]--
function sgs.isInDanger(player)
	if player then
		local hp = player:getHp()
		if hp < 3 then --hp = 2、1、0、-1 ……
			local defense = sgs.getDefense(player)
			return defense < 5
		end
	end
	return false
end
--[[
	内容：判断一名角色是否健康
	参数：player（ServerPlayer类型，表示待判断的目标角色）
	结果：boolean类型，表示是否健康
]]--
function sgs.isHealthy(player)
	if player then
		local hp = player:getHp()
		if hp > 3 then
			return true
		elseif hp > 2 then
			local defense = sgs.getDefense(player)
			return defense > 4
		end
		return false
	end
	return true
end
--[[
	功能：判断伤害目标是否可以发动竭缘减少伤害点数
	参数：source（ServerPlayer类型，表示伤害来源）
		target（ServerPlayer类型，表示伤害目标）
	结果：boolean类型，表示是否可以发动
]]--
function SmartAI:canUseJieyuanDecrease(source, target)
	local target = target or self.player
	if source then
		if target:hasSkill("jieyuan") then
			if source:getHp() >= target:getHp() then
				local handcards = target:getHandcards()
				for _, card in sgs.qlist(handcards) do
					if card:isRed() then
						if not sgs.isCard("Peach", card, target) then
							if not sgs.isCard("ExNihilo", card, target) then 
								return true 
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
	功能：获取一名角色的最优体力值
	参数：player（ServerPlayer类型，表示目标角色）
	结果：number类型，表示最优体力值
]]--
function sgs.getBestHp(player)
	local skills = player:getVisibleSkillList()
	local maxhp = player:getMaxHp()
	local isLord = false
	for _,lord in ipairs(sgs.ai_lords) do
		if lord == player:objectName() then
			isLord = true
		end
	end
	for _,skillname in sgs.qlist(skills) do
		local item = sgs.best_hp_system[skillname]
		if item then
			local callback = item["best_hp"]
			if type(callback) == "function" then
				local hp = callback(player, maxhp, isLord) 
				if hp then
					return hp
				end
			end
		end
	end
	return maxhp
end
--[[
	功能：判断使用拥有符合条件的合作方角色
	参数：prompt（string类型，表示考察的条件）
		player（ServerPlayer类型，表示作为标准的角色）
	结果：boolean类型，表示是否拥有
]]--
function SmartAI:hasPartners(prompt, player)
	player = player or self.player
	local partners = self:getPartners(player, nil, true)
	if #partners > 0 then
		if prompt == "draw" then
			local function needKongcheng(target)
				if target:isKongcheng() then
					if target:hasSkill("kongcheng") then
						return true
					elseif target:hasSkill("zhiji") then
						if target:getMark("zhiji") == 0 then
							return true
						end
					end
				end
				return false
			end
			for _,friend in ipairs(partners) do
				if not friend:hasSkill("manjuan") then
					if not needKongcheng(friend) then
						return true
					end
				end
			end
		elseif prompt == "male" then
			for _,friend in ipairs(partners) do
				if friend:isMale() then
					return true
				end
			end
		elseif prompt == "female" then
			for _,friend in ipairs(partners) do
				if friend:isFemale() then
					return true
				end
			end
		elseif prompt == "wounded_male" then
			for _,friend in ipairs(partners) do
				if friend:isMale() then
					if friend:isWounded() then
						return true
					end
				end
			end
		elseif prompt == "friend" then
			return true
		else
			global_room:writeToConsole(debug.traceback()) 
		end
	end
	return false
end
--[[****************************************************************
	特征分析系统
]]--****************************************************************
--[[
	功能：获取一名角色溢出手牌的数目
	参数：player（ServerPlayer类型，表示目标角色）
		justMaxCards（boolean类型，表示只获取该角色的手牌上限）
	结果：number类型（count），表示溢出数目或手牌上限
]]--
function SmartAI:getOverflow(player, justMaxCards)
	player = player or self.player
	local kingdomCount = 0
	local phase = player:getPhase()
	if player:hasSkill("yongsi") then
		if phase ~= sgs.Player_NotActive then
			if phase ~= sgs.Player_Finish then
				local skip = false
				if player:hasSkill("keji") then
					if not player:hasFlag("keji_use_slash") then
						skip = true
					end
				end
				if player:hasSkill("conghui") then
					skip = true
				end
				if not skip then
					local kingdoms = {}
					local alives = self.room:getAlivePlayers()
					for _,p in sgs.qlist(alives) do
						local kingdom = p:getKingdom()
						if not kingdoms[kingdom] then
							kingdoms[kingdom] = true
							kingdomCount = kingdomCount + 1
						end
					end
				end
			end
		end
	end
	local cardCount = player:getCardCount(true)
	local maxCards = player:getMaxCards()
	if justMaxCards then
		if kingdomCount > 0 then
			if cardCount <= kingdomCount then 
				return 0
			else 
				return math.min(maxCards, cardCount-kingdomCount)
			end
		end
		return maxCards
	end
	local num = player:getHandcardNum() 
	if kingdomCount > 0 then
		if cardCount <= kingdomCount then 
			return num
		end
		local MaxHandCards = math.min(maxCards, cardCount-kingdomCount)
		return num - MaxHandCards
	end
	return num - maxCards
end
--[[
	功能：获取一名角色最少拥有的手牌数目
	参数：player（ServerPlayer类型，表示目标角色）
	结果：number类型（least），表示最少的手牌数目
]]--
function SmartAI:getLeastHandcardNum(player)
	player = player or self.player
	local least = 0
	--连营
	if player:hasSkill("lianying") then
		if least < 1 then 
			least = 1 
		end
	end
	local lost = player:getLostHp()
	--伤逝
	if player:hasSkill("shangshi") then
		local limit = math.min(2, lost)
		if least < limit then 
			least = limit
		end
	end
	--原版伤逝
	if player:hasSkill("nosshangshi") then
		if least < lost then 
			least = lost
		end
	end
	--初版绝境
	if player:hasSkill("nosjuejing") then
		least = 4
	end
	return least
end
--[[
	功能：判断对一名角色而言失去手牌是否有效
	参数：player（ServerPlayer类型，表示目标角色）
	结果：boolean类型，表示是否有效
]]--
function SmartAI:hasLoseHandcardEffective(player)
	player = player or self.player
	local num = player:getHandcardNum()
	local least = self:getLeastHandcardNum(player)
	return num > least
end
--[[
	功能：
	参数：player（ServerPlayer类型）
		source（ServerPlayer类型）
	结果：number类型
]]--
function SmartAI:playerGetRound(player, source)
	if player then
		source = source or self.room:getCurrent()
		if player:objectName() == source:objectName() then
			return 0
		else
			local aliveCount = self.room:alivePlayerCount()
			local seat = player:getSeat()
			local myseat = source:getSeat()
			local round = (seat - myseat) % aliveCount
			return round
		end
	else
		return self.room:writeToConsole(debug.traceback())
	end
end
--[[
	功能：统计两名角色之间的友方角色数目
	参数：from（ServerPlayer类型，表示位于起始位置的角色）
		to（ServerPlayer类型，表示位于截止位置的角色）
	结果：number类型（count），表示统计结果
]]--
function SmartAI:getFriendNumBySeat(from, to)
	local alives = self.room:getAlivePlayers()
	local aliveCount = alives:length()
	local fromSeat = from:getSeat()
	local toSeat = to:getSeat()
	toSeat = (toSeat - fromSeat) % aliveCount
	local count = 0
	for _, p in sgs.qlist(alives) do
		if self:isFriend(p, from) then
			local seat = p:getSeat()
			seat = (seat - fromSeat) % aliveCount
			if seat < toSeat then
				count = count + 1
			end
		end
	end
	return count
end
--[[
	功能：统计两名角色之间的敌方角色数目
	参数：from（ServerPlayer类型，表示位于起始位置的角色）
		to（ServerPlayer类型，表示位于截止位置的角色）
		target（ServerPlayer类型，表示作为评价标准的角色）
		include_neutral（boolean类型，表示是否包括态度未知或中立的角色）
	结果：number类型（count），表示统计结果
]]--
function SmartAI:getEnemyNumBySeat(from, to, target, include_neutral)
	target = target or from
	local alives = self.room:getAllPlayers()
	local aliveCount = alives:length()
	local fromSeat = from:getSeat()
	local toSeat = to:getSeat()
	toSeat = (toSeat - fromSeat) % aliveCount
	local count = 0
	for _, p in sgs.qlist(alives) do
		local isEnemy = false
		if self:isEnemy(p, target) then
			isEnemy = true
		elseif include_neutral then
			isEnemy = not self:isFriend(p, target) 
		end
		if isEnemy then
			local seat = p:getSeat()
			seat = (seat - fromSeat) % aliveCount
			if seat < toSeat then
				count = count + 1
			end
		end
	end
	return count
end
--[[
	功能：统计两名角色之间的合作方角色数目
	参数：from（ServerPlayer类型，表示位于起始位置的角色）
		to（ServerPlayer类型，表示位于截止位置的角色）
	结果：number类型（count），表示统计结果
]]--
function SmartAI:getPartnerNumBySeat(from, to)
	local alives = self.room:getAlivePlayers()
	local aliveCount = alives:length()
	local fromSeat = from:getSeat()
	local toSeat = to:getSeat()
	toSeat = (toSeat - fromSeat) % aliveCount
	local count = 0
	for _, p in sgs.qlist(alives) do
		if self:isPartner(p, from) then
			local seat = p:getSeat()
			seat = (seat - fromSeat) % aliveCount
			if seat < toSeat then
				count = count + 1
			end
		end
	end
	return count
end
--[[
	功能：统计两名角色之间的对立方角色数目
	参数：from（ServerPlayer类型，表示位于起始位置的角色）
		to（ServerPlayer类型，表示位于截止位置的角色）
		target（ServerPlayer类型，表示作为评价标准的角色）
		include_neutral（boolean类型，表示是否包括态度未知或中立的角色）
	结果：number类型（count），表示统计结果
]]--
function SmartAI:getOpponentNumBySeat(from, to, target, include_neutral)
	target = target or from
	local alives = self.room:getAllPlayers()
	local aliveCount = alives:length()
	local fromSeat = from:getSeat()
	local toSeat = to:getSeat()
	toSeat = (toSeat - fromSeat) % aliveCount
	local count = 0
	for _, p in sgs.qlist(alives) do
		local isOpponent = false
		if self:isOpponent(p, target) then
			isOpponent = true
		elseif include_neutral then
			isOpponent = not self:isPartner(p, target) 
		end
		if iOpponent then
			local seat = p:getSeat()
			seat = (seat - fromSeat) % aliveCount
			if seat < toSeat then
				count = count + 1
			end
		end
	end
	return count
end
--[[
	功能：判断一名角色是否希望被翻面
	参数：player（ServerPlayer类型，表示待判断的目标角色）
		n（number类型，表示翻面时摸牌的数目）
		isFangzhu（boolean类型，表示是否因放逐而翻面）
	结果：boolean类型，表示是否希望被翻面
]]--
function SmartAI:toTurnOver(player, n, isFangzhu)
	if player then
		n = n or 0
		if self:isOpponent(player) then
			local manchong = self.room:findPlayerBySkillName("junxing")
			if manchong then
				if self:isPartner(player, manchong) then
					if self:playerGetRound(manchong) < self:playerGetRound(player) then
						if manchong:faceUp() then
							if not self:willSkipPlayPhase(manchong) then
								if not manchong:isKongcheng() then
									return false
								elseif not self:willSkipDrawPhase(manchong) then
									return false
								end
							end
						end
					end
				end
			end
		end
		if isFangzhu then
			if player:getHp() == 1 then
				if sgs.ai_AOE_data then
					if player:isKongcheng() then
						local use = sgs.ai_AOE_data:toCardUse()
						if use.to:contains(player) then
							if self:aoeIsEffective(use.card, player) then
								if self:playerGetRound(player) > self:playerGetRound(self.player) then
									return false 
								end
							end
						end
					end
				end
			end
		end
		if player:hasUsed("ShenfenCard") then
			if player:faceUp() then
				if player:getPhase() == sgs.Player_Play then
					if not player:hasUsed("ShenfenCard") then
						if player:getMark("@wrath") >= 6 then
							return false
						end
					elseif player:hasFlag("ShenfenUsing") then
						return false
					end
				end
			end
		end
		if n > 1 then
			if player:hasSkill("jijiu") then
				if player:hasSkill("manjuan") then
					if player:getPhase() == sgs.Player_NotActive then
						return true
					end
				end
				return false
			end
		end
		if not player:faceUp() then
			if not player:hasFlag("ShenfenUsing") then
				if not player:hasFlag("GuixinUsing") then
					return false
				end
			end
		end
		if self:hasSkills("jushou|neojushou|kuiwei", player) then
			if player:getPhase() <= sgs.Player_Finish then
				return false
			end
		end
		if player:hasSkill("lihun") then
			if not player:hasUsed("LihunCard") then
				if player:faceUp() then
					if player:getPhase() == sgs.Player_Play then
						return false
					end
				end
			end
		end
		return true
	else
		global_room:writeToConsole(debug.traceback())
	end
end
--[[
	功能：判断杀是否产生高点数伤害
	参数：source（ServerPlayer类型，表示使用杀的角色）
		slash（Card类型，表示使用的杀）
		target（ServerPlayer类型，表示杀的目标角色）
		getValue（boolean类型，表示是否获取伤害点数）
	结果：boolean类型（表示是否产生）或number类型（表示伤害点数）
]]--
function SmartAI:hasHeavySlashDamage(source, slash, target, getValue)
	source = source or self.room:getCurrent()
	target = target or self.player
	local damage = 1
	if not source:hasSkill("jueqing") then
		if target:hasArmorEffect("SilverLion") then
			if not sgs.IgnoreArmor(source, target) then
				if getValue then 
					return 1
				else 
					return false 
				end
			end
		end
	end
	local isFireSlash = false
	if slash then
		if slash:isKindOf("FireSlash") then
			isFireSlash = true
		elseif slash:objectName() == "slash" then
			if source:hasWeapon("Fan") then
				isFireSlash = true
			elseif source:hasSkill("lihuo") then
				if not self:isWeak(source) then
					isFireSlash = true
				end
			end
		end
	end
	local isThunderSlash = false
	if slash then
		if slash:isKindOf("ThunderSlash") then
			isThunderSlash = true
		end
	end
	local JinXuanDi = self.room:findPlayerBySkillName("wuling")
	if JinXuanDi then
		if JinXuanDi:getMark("@fire") > 0 then
			isFireSlash = true
			isThunderSlash = false
		elseif JinXuanDi:getMark("@wind") > 0 then
			if isFireSlash then
				damage = damage + 1
			end
		elseif JinXuanDi:getMark("@thunder") > 0 then
			if isThunderSlash then
				damage = damage + 1
			end
		end
	end
	if slash and slash:hasFlag("drank") then
		damage = damage + 1
	else
		local dranks = source:getMark("drank")
		if dranks > 0 then
			damage = damage + dranks
		end
	end
	--杀伤加成系统
	for _,item in pairs(sgs.heavy_slash_system) do
		local callback = item["extra_func"]
		if type(callback) == "function" then
			local extra = callback(source, slash, target, isFireSlash, isThunderSlash) or 0
			damage = damage + extra
		end
	end
	if JinXuanDi then
		if isFireSlash or isThunderSlash then
			if JinXuanDi:getMark("@earth") > 0 then
				if damage > 1 then
					damage = 1
				end
			end
		end
	end
	if getValue then
		return damage
	end
	return damage > 1
end
--[[
	功能：判断一名角色是否需要扣减体力
	参数：target（ServerPlayer类型，表示待判断的目标角色）
		source（ServerPlayer类型，表示发起攻击的角色）
		isSlash（boolean类型，表示是否用杀作为攻击手段）
		passive（boolean类型，表示是否被动扣减体力）
		recover（boolean类型）
	结果：boolean类型，表示是否需要
]]--
function SmartAI:needToLoseHp(target, source, isSlash, passive, recover)
	source = source or self.room:getCurrent()
	target = target or self.player
	if self:hasHeavySlashDamage(source) then 
		return false 
	end
	if source:hasSkill("jueqing") then
		if self:hasSkills(sgs.masochism_skill, target) then
			return false
		end
	else
		if isSlash then
			if not self:isPartner(source, target) then
				if source:hasSkill("nosqianxi") then
					if source:distanceTo(target) == 1 then
						return false
					end
				end
				if source:hasWeapon("IceSword") then
					local cards = target:getCards("he")
					if cards:length() > 1 then
						return false
					end
				end
			end
		end
	end
end
--[[
	功能：判断伤害目标是否应考虑主动承担伤害以发动卖血效果
	参数：target（ServerPlayer类型，表示伤害目标）
		source（ServerPlayer类型，表示伤害来源）
		card（Card类型，表示伤害卡牌）
	结果：boolean类型，表示是否承担伤害
]]--
function SmartAI:invokeDamagedEffect(target, source, card)
	target = target or self.player
	source = source or self.room:getCurrent()
	if card == true then
		card = sgs.slash
	end
	if source:hasSkill("jueqing") then 
		return false 
	end
	if card then
		if card:isKindOf("Slash") then
			if source:hasSkill("nosqianxi") then
				if source:distanceTo(target) == 1 then
					return false
				end
			end
			if source:hasWeapon("IceSword") then
				local cards = target:getCards("he")
				if cards:length() > 1 then
					if not self:isPartner(source, target) then
						return false
					end
				end
			end
		end
	end
	if target:hasLordSkill("shichou") then
		local callback = sgs.ai_damage_requirement["shichou"]
		local level = callback(self, source, target)
		return level == 1
	end
	if self:hasHeavySlashDamage(source) then 
		return false 
	end
	if sgs.isGoodHp(target) then
		local skills = target:getVisibleSkillList()
		for _, skill in sgs.qlist(skills) do
			local callback = sgs.ai_damage_requirement[skill:objectName()]
			if type(callback) == "function" then
				if callback(self, source, target) then 
					return true 
				end
			end
		end
	end
	return false
end
--[[
	功能：判断一名角色是否需要主动死亡
	参数：player（ServerPlayer类型，表示待判断的角色）
	结果：boolean类型，表示是否需要
]]--
function SmartAI:needDeath(player)
	player = player or self.player
	if player:hasSkill("wuhun") then
		local maxfriendmark = 0
		local maxenemymark = 0
		local friends = self:getFriends(player, nil, true)
		if #friends > 0 then
			local alives = self.room:getAlivePlayers()
			for _,p in sgs.qlist(alives) do
				local mark = p:getMark("@nightmare")
				if self:isFriend(player, p) then
					if player:objectName() ~= p:objectName() then
						if mark > maxfriendmark then 
							maxfriendmark = mark 
						end
					end
				elseif self:isEnemy(player, p) then
					if mark > maxenemymark then 
						maxenemymark = mark 
					end
				end
				if maxfriendmark > maxenemymark then 
					return false
				elseif maxenemymark == 0 then 
					return false
				else 
					return true 
				end
			end
		end
	end
	return false
end
--[[
	功能：判断一名角色是否可以攻击另一名角色
	参数：target（ServerPlayer类型，表示攻击目标）
		source（ServerPlayer类型，表示攻击来源）
		nature（sgs.DamageStruct_Nature类型，表示伤害属性）
	结果：boolean类型，表示是否可以攻击
]]--
function SmartAI:canAttack(target, source, nature)
	source = source or self.player
	nature = nature or sgs.DamageStruct_Normal
	local damage = 1
	if nature == sgs.DamageStruct_Fire then
		if not target:hasArmorEffect("SilverLion") then
			if target:hasArmorEffect("Vine") then 
				damage = damage + 1 
			end
		end
		if target:getMark("@gale") > 0 then 
			damage = damage + 1 
		end
	end
	if #self.enemies == 1 then
		return true
	elseif self:hasSkills("jueqing") then 
		return true 
	end
	if self:invokeDamagedEffect(target, source) then
		return false
	elseif self:needToLoseHp(target, source, false, true) then
		if #self.enemies > 1 then
			return false
		end
	end 
	if not sgs.isGoodTarget(self, target, self.opponents) then 
		return false 
	end
	if self:cannotBeHurt(target, damage, self.player) then
		return false
	elseif not self:damageIsEffective(target, nature, source) then 
		return false 
	end
	if nature ~= sgs.DamageStruct_Normal then
		if target:isChained() then
			if not self:isGoodChainTarget(target, self.player, nature) then 
				return false 
			end
		end
	end
	return true
end
--[[
	功能：获取多目标攻击性锦囊牌对某一目标角色的使用价值
	参数：card（Card类型，表示待使用的AOE卡牌）
		target（ServerPlayer类型，表示当前考察的目标角色）
		source（ServerPlayer类型，表示卡牌的使用者）
	结果：number类型（value），表示使用价值
]]--
function SmartAI:getAoeValueTo(card, target, source)
	local value = 0
	local sj_num = 0
	if card:isKindOf("ArcheryAttack") then 
		sj_num = sgs.getCardsNum("Jink", target) 
	elseif card:isKindOf("SavageAssault") then 
		sj_num = sgs.getCardsNum("Slash", target) 
	end
	if self:aoeIsEffective(card, target, source) then
		local name = target:objectName()
		local hp = target:getHp()
		if sj_num < 1 then
			value = -70
		elseif card:isKindOf("SavageAssault") then
			if sgs.card_lack[name]["Slash"] == 1 then
				value = -70
			else
				value = -50
			end
		elseif card:isKindOf("ArcheryAttack") then
			if sgs.card_lack[name]["Jink"] == 1 then
				value = -70
			else
				value = -50
			end
		else
			value = -50
		end
		value = value + math.min(20, hp * 5)
		if self:invokeDamagedEffect(target, source) then 
			value = value + 40 
		end
		if self:needToLoseHp(to, from, nil, true) then 
			value = value + 10 
		end
		if card:isKindOf("ArcheryAttack") then
			local hasEightDiagram = self:hasEightDiagramEffect(target)
			local flag = true
			if target:hasSkill("leiji") then
				if self:canLeiji(target, source) then
					if hasEightDiagram or sj_num >= 1 then
						value = value + 100
						if self:hasSuit("spade", true, target) then 
							value = value + 150
						else 
							value = value + target:getHandcardNum() * 35
						end
						flag = false
					end
				end
			end
			if flag and hasEightDiagram then
				value = value + 20
				local final = self:getFinalRetrial(target)
				if final == 2 then
					value = value - 15
				elseif final == 1 then
					value = value + 10
				end
			end
		end
		if card:isKindOf("ArcheryAttack") and sj_num >= 1 then
			if self:hasSkills("mingzhe|gushou", target) then 
				value = value + 8 
			end
			if target:hasSkill("xiaoguo") then 
				value = value - 4 
			end
		elseif card:isKindOf("SavageAssault") and sj_num >= 1 then
			if target:hasSkill("gushou") then 
				value = value + 8 
			end
			if target:hasSkill("xiaoguo") then 
				value = value - 4 
			end
		end
		if target:hasSkills("longdan+chongzhen") then
			if self:isOpponent(target) then
				if card:isKindOf("ArcheryAttack") then
					if sgs.getCardsNum("Slash", target) >= 1 then
						value = value + 15
					end
				elseif card:isKindOf("SavageAssault") then
					if sgs.getCardsNum("Jink", target) >= 1 then
						value = value + 15
					end
				end
			end
		end
		local current = self.room:getCurrent()
		if current:hasSkill("wansha") then
			if target:getHp() <= 1 then
				local noPeach = false
				if sgs.card_lack[name]["Peach"] == 1 then
					noPeach = true
				elseif sgs.getCardsNum("Peach", target) == 0 then
					noPeach = true
				end
				if noPeach then
					value = value - 30
					if self:isPartner(target) then
						if self:getCardsNum("Peach") >= 1 then
							value = value + 10
						end
					end
				end
			end
		end
		if not source:hasSkill("jueqing") then
			if sgs.current_mode ~= "06_3v3" then
				if hp <= 1 then
					if self:mayLord(source) then
						if self:mayLoyalist(target) then
							if self:getCardsNum("Peach") == 0 then
								value = value - source:getCardCount(true) * 20
							end
						end
					end
				end
			end
			if hp > 1 then
				if target:hasSkill("quanji") then 
					value = value + 10 
				end
				if target:hasSkill("langgu") then
					if self:isOpponent(target, source) then 
						value = value - 15 
					end
				end
				if target:hasSkill("jianxiong") then
					if card:isVirtualCard() then
						value = value + card:subcardsLength() * 10
					else
						value = value + 10
					end
				end
				if target:hasSkill("fenyong") then
					if target:hasSkill("xuehen") then
						if target:getMark("@fenyong") == 0 then
							value = value + 30
						end
					end
				end
				if target:hasSkill("shenfen") then
					if target:hasSkill("kuangbao") then
						local mark = target:getMark("@wrath")
						value = value + math.min(25, mark * 5)
					end
				end
				if target:hasSkill("beifa") then
					if target:getHandcardNum() == 1 then
						if self:needKongcheng(target) then
							if sj_num == 1 or sgs.getCardsNum("Nullification", target) == 1 then
								value = value + 20
							elseif self:getKnownNum(target) < 1 then
								value = value + 5
							end
						end
					end
				end
				if target:hasSkill("tanlan") then
					if self:isOpponent(target) then
						if not source:isKongcheng() then 
							value = value + 10 
						end
					end
				end
			end
		end
	else
		value = value + 10
		if target:hasSkill("juxiang") then
			if not card:isVirtualCard() then 
				value = value + 20 
			end
		end
		if target:hasSkill("danlao") then
			if self.player:aliveCount() > 2 then 
				value = value + 20 
			end
		end
	end
	return value
end
--[[
	功能：获取多目标攻击性锦囊牌的使用价值
	参数：card（Card类型，表示待使用的AOE卡牌）
		source（ServerPlayer类型，表示卡牌的使用者）
	结果：number类型，表示使用价值
]]--
function SmartAI:getAoeValue(card, source)
	local attacker = source or self.player
	if card:isKindOf("SavageAssault") then
		local MengHuo = self.room:findPlayerBySkillName("huoshou")
		attacker = MengHuo or attacker
	end	
	local good = 0
	local bad = 0
	local lord = nil
	if self:amRenegade() then
		lord = self.room:getLord()
	else
		lord = self:getMyLord()
	end
	local function canHelpLord()
		if lord then
			if attacker:hasSkill("qice") then
				if card:isVirtualCard() then
					return true
				end
			end
			local peach_num, null_num, slash_num, jink_num = 0, 0, 0, 0
			if card:isVirtualCard() then
				if card:subcardsLength() > 0 then	
					local subcards = card:getSubcards()
					for _, id in sgs.qlist(subcards) do
						local subcard = sgs.Sanguosha:getCard(id)
						if sgs.isCard("Peach", subcard, self.player) then 
							peach_num = peach_num - 1 
						elseif sgs.isCard("Slash", subcard, self.player) then 
							slash_num = slash_num - 1 
						elseif sgs.isCard("Jink", subcard, self.player) then 
							jink_num = jink_num - 1 
						elseif sgs.isCard("Nullification", subcard, self.player) then 
							null_num = null_num - 1 
						end
					end
				end
			end
			if self:getCardsNum("Peach") > peach_num then 
				return true 
			end
			if card:isKindOf("SavageAssault") then
				if lord:hasLordSkill("jijiang") then
					if self.player:getKingdom() == "shu" then
						if self:getCardsNum("Slash") > slash_num then 
							return true 
						end
					end
				end
			elseif card:isKindOf("ArcheryAttack") then
				if lord:hasLordSkill("hujia") then
					if self.player:getKingdom() == "wei" then
						if self:getCardsNum("Jink") > jink_num then 
							return true 
						end
					end
				end
			end
			local goodnull, badnull = 0, 0
			local alives = self.room:getAlivePlayers()
			for _, p in sgs.qlist(alives) do
				if self:isPartner(lord, p) then 
					goodnull = goodnull + sgs.getCardsNum("Nullification", p) 
				else
					badnull = badnull + sgs.getCardsNum("Nullification", p) 
				end
			end
			return goodnull - null_num - badnull >= 2
		end
		return false
	end
	local isFriendEffective, isEnemyEffective = 0, 0
	for _, friend in ipairs(self.partners_noself) do
		good = good + self:getAoeValueTo(card, friend, attacker)
		if self:aoeIsEffective(card, friend, attacker) then 
			isFriendEffective = isEnemyEffective + 1 
		end
	end
	for _, enemy in ipairs(self.opponents) do
		bad = bad + self:getAoeValueTo(card, enemy, attacker)
		if self:aoeIsEffective(card, enemy, attacker) then 
			isEnemyEffective = isEnemyEffective + 1 
		end
	end
	if isEnemyEffective == 0 then
		if isFriendEffective == 0 then
			if self:hasSkills("jizhi|nosjizhi") then
				return 10
			else
				return -100
			end
		else
			return -100
		end
	end
	if not sgs.hegemony_mode then
		if lord then
			if not self:amLord() then
				if sgs.isInDanger(lord) then
					if self:aoeIsEffective(card, lord, attacker) then
						if not canHelpLord() then
							local can_buqu = false
							if lord:hasSkill("buqu") then
								local buqus = lord:getPile("buqu")
								if buqus:length() <= 4 then
									can_buqu = true
								end
							end
							if not can_buqu then
								local lord_hp = lord:getHp()
								if self:isOpponent(lord) then
									if lord_hp <= 1 then
										good = good + 200
									else
										good = good + 150
									end
									if lord_hp <= 2 then
										if #self.enemies == 1 then 
											good = good + 150 - hp * 50 
										end
										if lord:isKongcheng() then 
											good = good + 150 - hp * 50 
										end
									end
								else
									if lord_hp <= 1 then
										bad = bad + 2013
									else
										bad = bad + 250
									end
								end
							end
						end
					end
				end
			end
		end
	end
	if isEnemyEffective + isFriendEffective > 1 then
		local alives = self.room:getAlivePlayers()
		for _, player in sgs.qlist(alives) do
			if player:hasSkill("huangen") then
				local hp = player:getHp()
				if self:isPartner(player) then
					if hp >= #self.partners_noself then
						good = good + 300
					else
						good = good + hp * 50
					end
				elseif self:isOpponent(player) then
					if hp >= #self.opponents then
						bad = bad + 300
					else
						bad = bad + hp * 50
					end
				end
			end
		end
	end
	local enemy_number = 0
	local others = self.room:getOtherPlayers(self.player)
	for _, player in sgs.qlist(others) do
		if self:cannotBeHurt(player) then
			if self:aoeIsEffective(card, player, attacker) then
				local flag = true
				if player:hasSkill("wuhun") then
					if not self:isWeak(player) then
						if attacker:getMark("@nightmare") == 0 then
							if attacker:objectName() == self.player:objectName() then
								if not self:amRenegade() then
									if not self:amLord() then
										flag = false
									end
								end
							else
								flag = false
								if lord then
									if self:isPartner(attacker) then
										if attacker:objectName() == lord:objectName() then
											flag = true
										end
									end
								end
							end
						end
					end
				end
				if flag then
					bad = bad + 250
				end
			end
		end
		if player:hasSkill("dushi") then
			if not attacker:hasSkill("benghuai") then
				if self:isPartner(attacker) then
					if self:isWeak(player) then 
						bad = bad + 40 
					end
				end
			end
		end
		if self:aoeIsEffective(card, player, attacker) then
			if not self:isPartner(player, attacker) then 
				enemy_number = enemy_number + 1 
			end
		end
	end
	local forbid_start = true
	if self:hasSkills("nosjizhi|jizhi") then
		forbid_start = false
		good = good + 51
	end
	if self.player:hasSkill("shenfen") then
		if self.player:hasSkill("kuangbao") then
			forbid_start = false
			good = good + 3 * enemy_number
			if not self.player:hasSkill("wumou") then
				good = good + 3 * enemy_number
			elseif self.player:getMark("@wrath") > 0 then
				good = good + 1.5 * enemy_number
			end
		end
	end
	if not sgs.hegemony_mode then
		if forbid_start then
			if sgs.turncount < 2 then
				if self.player:getSeat() <= 3 then
					if card:isKindOf("SavageAssault") then
						if enemy_number > 0 then
							if self:amRebel() then
								if isFriendEffective > 0 then
									bad = bad + 50
								end
							else
								if isEnemyEffective > 0 then
									good = good + 50
								end
							end
						end
					end
				end
			end
		end
		if lord then
			if not self:amLord() then
				if self:isWeak(lord) then
					if #self.friends > 0 then
						if self:countRebel() == 0 then
							bad = bad + 300
						end
					end
				end
			end
		end
	end
	if self:hasSkills("jianxiong|luanji|qice|manjuan") then 
		good = good + 2 * enemy_number 
	end
	return good - bad
end
--[[
	功能：判断一张卡牌对某角色而言是否特别有价值
	参数：card（Card类型，表示待判断的卡牌）
		player（ServerPlayer类型，表示作为标准的角色）
	结果：boolean类型，表示是否有价值
]]--
function SmartAI:isValuableCard(card, player)
	player = player or self.player
	if sgs.isCard("peach", card, player) then
		if sgs.getCardsNum("Peach", player) <= 2 then
			return true
		end
	end
	if sgs.isCard("Analeptic", card, player) then
		if self:isWeak(player) then
			return true
		end
	end
	if player:getPhase() == sgs.Player_Play then
		if sgs.isCard("ExNihilo", card, player) then
			if not player:isLocked(card) then
				return true
			end
		end
	else
		if sgs.isCard("Jink", card, player) then
			if sgs.getCardsNum("Jink", player) < 2 then
				return true
			end
		end
		if sgs.isCard("Nullification", card, player) then
			if sgs.getCardsNum("Nullification", player) < 2 then
				if self:hasSkills("jizhi|nosjizhi|jilve", player) then
					return true
				end
			end
		end
	end
	return false
end
--[[
	功能：获取所有受伤的友方角色
	参数：maleOnly（boolean类型，表示是否只包括男性角色）
	结果：table类型（result，表示所有需要回复体力的友方角色）和table类型（ignore，表示所有无需回复体力的友方角色）
]]--
function SmartAI:getWoundedFriend(maleOnly)
	self:sort(self.partners, "hp")
	local result = {}
	local ignore = {}
	local function addToList(player, index)
		if player:isWounded() then
			if maleOnly then
				if player:isMale() then
					if index == 1 then
						table.insert(result, player)
					else
						table.insert(ignore, player)
					end
				end
			else
				if index == 1 then
					table.insert(result, player)
				else
					table.insert(ignore, player)
				end
			end
		end
	end
	local function getHpValue(player)
		local value = player:getHp()
		if self:hasSkills("nosrende|rende|kuanggu|zaiqi", player) then
			if value >= 2 then 
				value = value + 5 
			end
		end
		if self:isWeak(player) then
			local name = player:objectName()
			if sgs.ai_lord[name] == name then
				value = value - 10
			end
			if self.player:objectName() == name then
				if player:hasSkill("qingnang") then
					value = value - 5
				end
			end
		end
		if player:hasSkill("buqu") then
			local buqus = player:getPile("buqu")
			if buqus:length() <= 2 then
				value = value + 5
			end
		end
		return value
	end
	local function compare_func(a, b)
		local valueA = getHpValue(a)
		local valueB = getHpValue(b)
		if valueA == valueB then
			return sgs.getDefenseSlash(a) < sgs.getDefenseSlash(b)
		else
			return valueA < valueB
		end
	end
	local my_lord = self:getMyLord()
	for _,friend in ipairs(self.friends) do
		if my_lord and my_lord:objectName() == friend:objectName() then
			if friend:hasSkill("hunzi") then
				if friend:getMark("hunzi") == 0 then
					local hp = friend:getHp()
					if self:getOpponentNumBySeat(self.player, friend) <= (hp>= 2 and 1 or 0) then
						addToList(friend, 2)
					end
				end
			elseif self:needToLoseHp(friend, nil, nil, true, true) then
				addToList(friend, 2)
			elseif not sgs.isHealthy(my_lord) then
				addToList(friend, 1)
			end
		else
			if self:needToLoseHp(friend, nil, nil, nil, true) then
				addToList(friend, 2)
			elseif self:hasSkills("rende|kuanggu|zaiqi", friend) then
				local hp = friend:getHp()
				if hp >= 2 then
					addToList(friend, 2)
				end
			else
				addToList(friend, 1)
			end
		end
	end
	table.sort(result, compare_func)
	table.sort(ignore, compare_func)
	return result, ignore
end
--[[
	功能：判断是否满足“烈弓”的发动条件
	参数：target（ServerPlayer类型，表示杀指定的目标）
		source（ServerPlayer类型，表示杀的使用者）
	结果：boolean类型，表示是否满足
]]--
function SmartAI:canLiegong(target, source)
	source = source or self.room:getCurrent()
	target = target or self.player
	if source then
		if source:getPhase() == sgs.Player_Play then
			local num = target:getHandcardNum()
			local hp = source:getHp()
			if source:hasSkill("liegong") then
				local range = source:getAttackRange()
				if num <= range then
					return true
				elseif num >= hp then
					return true
				end
			elseif source:hasSkill("kofliegong") then
				return num >= hp
			end
		end
	end
	return false
end
--[[****************************************************************
	环境信息系统
]]--****************************************************************
--[[
	功能：获取目标角色手牌中点数最大的卡牌
	参数：player（ServerPlayer类型，表示目标角色）
		flag（boolean类型，表示是否只考虑卡牌点数、不关心其它信息）
	结果：Card类型（max_card），表示符合条件的卡牌
]]--
function SmartAI:getMaxPointCard(player, flag)
	player = player or self.player
	if player:isKongcheng() then
		return nil
	end
	local cards = player:getCards("h")
	local current = self.room:getCurrent()
	local myname = current:objectName()
	local name = player:objectName()
	local visible_flag = string.format("visible_%s_%s", myname, name)
	local isMyself = ( myname == name )
	local max_card = nil
	local max_point = 0
	if flag then
		for _,card in sgs.qlist(cards) do
			local isVisible = isMyself
			isVisible = isVisible or card:hasFlag("visible")
			isVisible = isVisible or card:hasFlag(visible_flag)
			if isVisible then
				local point = card:getNumber()
				if point > max_point then
					max_point = point
					max_card = card
				end
			end
		end
		return max_card
	else
		for _,card in sgs.qlist(cards) do
			local isVisible = isMyself and not self:isValuableCard(card)
			isVisible = isVisible or card:hasFlag("visible")
			isVisible = isVisible or card:hasFlag(visible_flag)
			if isVisible then
				local point = card:getNumber()
				if point > max_point then
					max_point = point
					max_card = card
				end
			end
		end
		if isMyself then
			if not max_card then
				max_point = 0
				for _,card in sgs.qlist(cards) do
					local point = card:getNumber()
					if point > max_point then
						max_point = point
						max_card = card
					end
				end
			end
		else
			return max_card
		end
		if max_point > 0 then
			if self:hasSkills("tianyi|dahe|xianzhen", player) then
				for _,card in sgs.qlist(cards) do
					local point = card:getNumber()
					if point == max_point then
						if not sgs.isCard("Slash", card, player) then
							return card
						end
					end
				end
			end
			if player:hasSkill("qiaoshui") then
				for _, card in sgs.qlist(cards) do
					local point = card:getNumber()
					if point == max_point then
						if not card:isNDTrick() then
							return card
						end
					end
				end
			end
		end
	end
	return max_card
end
--[[
	功能：获取目标角色手牌中点数最小的卡牌
	参数：player（ServerPlayer类型，表示目标角色）
	结果：Card类型（max_card），表示符合条件的卡牌
]]--
function SmartAI:getMinPointCard(player)
	player = player or self.player
	if player:isKongcheng() then
		return nil
	end
	local cards = player:getHandcards()
	local min_card = nil
	local min_point = 14
	local current = self.room:getCurrent()
	local myname = current:objectName()
	local name = player:objectName()
	local visible_flag = string.format("visible_%s_%s", myname, name)
	local isMyself = ( myname == name )
	for _, card in sgs.qlist(cards) do
		local isVisible = isMyself
		isVisible = isVisible or card:hasFlag("visible")
		isVisible = isVisible or card:hasFlag(visible_flag)
		if isVisible then
			local point = card:getNumber()
			if point < min_point then
				min_point = point
				min_card = card
			end
		end
	end
	return min_card
end
--[[
	功能：判断一名角色是否会跳过其摸牌阶段
	参数：player（ServerPlayer类型，表示待判断的目标角色）
		NotContains_Null（boolean类型，表示是否不包括被无懈可击的情形）
	结果：boolean类型，表示是否跳过
]]--
function SmartAI:willSkipDrawPhase(player, NotContains_Null)
	player = player or self.player
	if player:isSkipped(sgs.Player_Draw) then
		return true
	end
	local null_count = 0
	if not NotContains_Null then
		local alives = self.room:getAllPlayers()
		for _, p in sgs.qlist(alives) do
			if self:isFriend(p, player) then 
				null_count = null_count + sgs.getCardsNum("Nullification", p) 
			elseif self:isEnemy(p, player) then 
				null_count = null_count - sgs.getCardsNum("Nullification", p) 
			end
		end
	end
	local count = 0
	local current = self.room:getCurrent()
	if self.player:objectName() == current:objectName() then
		if self.player:objectName() ~= player:objectName() then
			if self:isPartner(player) then
				local cards = current:getCards("he")
				for _, card in sgs.qlist(cards) do
					local flag = false
					if current:distanceTo(player) == 1 then
						if sgs.isCard("Snatch", card, current) then
							flag = true
						end
					end
					flag = flag or sgs.isCard("Dismantlement", card, current)
					if flag then
						local trick = sgs.cloneCard(card:objectName(), card:getSuit(), card:getNumber())
						if self:trickIsEffective(trick, player) then 
							count = count + 1 
						end
					end
				end
			end
		end
	end
	if player:containsTrick("supply_shortage") then
		if player:containsTrick("YanxiaoCard") then
			return false
		elseif self:hasSkills("shensu|jisu", player) then
			return false
		elseif player:hasSkill("qiaobian") then
			if not player:isKongcheng() then 
				return false 
			end
		end
		if null_count + count > 1 then 
			return false 
		end
		return true
	end
	return false
end
--[[
	功能：判断一名角色是否会跳过其出牌阶段
	参数：player（ServerPlayer类型，表示待判断的目标角色）
		NotContains_Null（boolean类型，表示是否不包括被无懈可击的情形）
	结果：boolean类型，表示是否跳过
]]--
function SmartAI:willSkipPlayPhase(player, NotContains_Null)
	player = player or self.player
	if player:isSkipped(sgs.Player_Play) then
		return true
	end
	--惴恐
	local FuHuangHou = self.room:findPlayerBySkillName("zhuikong")
	if FuHuangHou then
		if FuHuangHou:objectName() ~= player:objectName() then
			if self:isOpponent(player, FuHuangHou) then
				if FuHuangHou:isWounded() then
					if FuHuangHou:getHandcardNum() > 1 then
						if not player:isKongcheng() then
							if not self:isWeak(FuHuangHou) then
								local max_card = self:getMaxPointCard(FuHuangHou)
								if max_card then
									local max_point = max_card:getNumber()
									local my_max_card = self:getMaxPointCard(player)
									if my_max_card then
										if max_point > my_max_card:getNumber() then
											return true
										end
									end
									if max_point >= 12 then 
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
	--顺手牵羊、过河拆桥
	local current = self.room:getCurrent()
	local count = 0 --友方顺手牵羊、过河拆桥的数量
	if self.player:objectName() == current:objectName() then
		if self.player:objectName() ~= player:objectName() then
			if self:isPartner(player) then
				local cards = current:getCards("he")
				for _,card in sgs.qlist(cards) do
					local flag = false
					if current:distanceTo(player) == 1 then
						if sgs.isCard("Snatch", card, current) then
							flag = true
						end
					end
					flag = flag or sgs.isCard("Dismantlement", card, current)
					local trick = sgs.cloneCard(card:objectName(), card:getSuit(), card:getNumber())
					if self:trickIsEffective(trick, player) then
						count = count + 1
					end
				end
			end
		end
	end
	local null_count = 0 --友方无懈可击的数量
	if not NotContains_Null then
		local alives = self.room:getAlivePlayers()
		for _, p in sgs.qlist(alives) do
			if self:isPartner(p, player) then 
				null_count = null_count + sgs.getCardsNum("Nullification", p) 
			elseif self:isOpponent(p, player) then 
				null_count = null_count - sgs.getCardsNum("Nullification", p) 
			end
		end
	end
	--乐不思蜀
	if player:containsTrick("indulgence") then
		if player:containsTrick("YanxiaoCard") then
			return false
		elseif self:hasSkills("keji|conghui",player) then
			return false
		elseif player:hasSkill("qiaobian") then
			if not player:isKongcheng() then 
				return false 
			end
		end
		if null_count + count > 1 then 
			return false 
		end
		return true
	end
	return false
end
--[[
	功能：计算一名角色摸牌阶段的摸牌数目
	参数：player（ServerPlayer类型，表示目标角色）
		skills（sgs.QList<Skill*>类型，表示所涉及的技能范围）
		overall（boolean类型，表示是否考虑所有范围内的技能、不论目标角色是否拥有）
	结果：number类型（count），表示摸牌数目
]]--
function SmartAI:ImitateResult_DrawNCards(player, skills, overall)
	if player then
		if player:isSkipped(sgs.Player_Draw) then
			return 0
		end
		local count = 2
		if skills then
			local drawSkills = {}
			if overall then
				for _,skill in sgs.qlist(skills) do
					table.insert(drawSkills, skill:objectName())
				end
			else
				for _,skill in sgs.qlist(skills) do
					if player:hasSkill(skill:objectName()) then
						table.insert(drawSkills, skill:objectName())
					end
				end
			end
			if #drawSkills > 0 then
				for _,skillname in ipairs(drawSkills) do
					local item = sgs.draw_cards_system[skillname]
					if item then
						local return_func = item["return_func"]
						if type(return_func) == "function" then
							return return_func(self, player) or count
						end
						local correct_func = item["correct_func"]
						if type(correct_func) == "function" then
							count = count + (correct_func(self, player) or 0)
						end
					end
				end
			end
		end
		return count
	end
	return 0
end
--[[
	功能：判断一名角色是否会成为离魂的目标
	参数：player（ServerPlayer类型，表示待判断的目标角色）
		drawCardNum（number类型，表示将摸牌的数目）
	结果：boolean类型，表示是否成为目标
]]--
function SmartAI:isLihunTarget(player, drawCardNum)
	player = player or self.player
	drawCardNum = drawCardNum or 1
	if type(player) == "table" then
		if #player > 0 then 
			for _, p in ipairs(player) do
				if self:isLihunTarget(p, drawCardNum) then 
					return true
				end
			end
		end
		return false
	end
	if player:isMale() then
		local DiaoChan = self.room:findPlayerBySkillName("lihun")
		if DiaoChan then
			if self:isPartner(player, DiaoChan) then
				return false
			elseif DiaoChan:hasUsed("LihunCard") then
				return false
			end
			local num = player:getHandcardNum() + drawCardNum
			if DiaoChan:getPhase() == sgs.Player_Play then
				if DiaoChan:faceUp() then
					if num - player:getHp() >= 2 then
						return true
					end
				else
					if num > 0 then
						if num - player:getHp() >= -1 then
							return true
						end
					end
				end
			else
				if DiaoChan:faceUp() then
					if not self:willSkipPlayPhase(DiaoChan) then
						if self:playerGetRound(player) > self:playerGetRound(DiaoChan) then
							if num >= player:getHp() + 2 then
								return true
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
	内容：获取一名角色所有可获取的桃的数量
	参数：player（ServerPlayer类型，表示目标角色）
	结果：number类型（count），表示桃的数量
]]--
function SmartAI:getAllPeachNum(player)
	player = player or self.player
	local count = 0
	local friends = self:getFriends(player)
	for _,friend in ipairs(friends) do
		local num = 0
		if self.player:objectName() == friend:objectName() then
			num = self:getCardsNum("Peach") 
		else
			num = sgs.getCardsNum("Peach", friend)
		end
		count = count + num
	end
	return count
end
--[[
	内容：判断是否应当对一名角色使用桃
	参数：target（ServerPlayer类型，表示求桃的目标角色）
	结果：string类型，表示桃的具体使用方式（"."表示不对其使用桃）
]]--
function SmartAI:willUsePeachTo(target)
	if self.player:isLocked(sgs.peach) then
		return "."
	elseif target:isLocked(sgs.peach) then 
		return "." 
	end
	local card_str = nil
	if self.player:objectName() == target:objectName() then
		if not self:needDeath(target) then
			card_str = "."
			if self.player:isLocked(sgs.analeptic) then
				card_str = self:getCardId("Peach")
			else
				card_str = self:getCardId("Analeptic")
			end
			return card_str
		end
	end
	local current = self.room:getCurrent()
	if self:amRenegade() then
		local ignore = true
		if self:mayLord(target) then
			ignore = false
		elseif self.player:objectName() == target:objectName() then
			ignore = false
		end
		if ignore then
			if self.player:objectName() == current:objectName() then
				return "."
			elseif not self:isPartner(target) then
				return "."
			end
		end
	end
	if self:amLord() then
		if self.player:objectName() ~= target:objectName() then
			if self:getCardsNum("Peach") == 1 then
				if self:isWeak() then
					if self.player:getHp() <= 1 then
						if self:getOpponentNumBySeat(current, self.player, self.player) > 0 then
							return "."
						end
					end
				end
			end
		end
	end
	if self:mayRenegade(target) then
		if self.player:objectName() ~= target:objectName() then
			if self:amLoyalist() or self:amLord() or self:amRenegade() then
				if not self:isPartner(target) then
					return "."
				end
			end
			if self:amRebel() or self:amRenegade() then
				if not self:isPartner(target) then
					return "."
				end
			end
		end
	end
	if self:isPartner(target) then
		if self:needDeath(target) then 
			return "." 
		end
		local lord = self:getMyLord()
		if self.player:objectName() ~= target:objectName() then
			if lord then
				if target:objectName() ~= lord:objectName() then
					if self:amLoyalist() or self:amRenegade() then
						if self.room:alivePlayerCount() > 2 then
							if sgs.isInDanger(lord) then
								return "."
							end
						end
					end
				end
			end
		end
		if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") < 1 - target:getHp() then
			if not self:mayLord(target) then
				return "."
			end
		end
		if not self:mayLord(target) then
			if target:objectName() ~= self.player:objectName() then
				local possible_friend = 0
				for _,friend in ipairs(self.partners_noself) do
					local possible = true
					if sgs.card_lack[friend:objectName()]["Peach"] == 1 then
						possible = false
					-- elseif not self:ableToSave(friend, target) then
						-- possible = false
					elseif self:playerGetRound(friend) < self:playerGetRound(self.player) then
						possible = false
					elseif self:getKnownNum(friend) == friend:getHandcardNum() then
						if sgs.getCardsNum("Peach", friend) == 0 then
							possible = false
						end
					end
					if possible then
						if friend:getHandcardNum() > 0 or sgs.getCardsNum("Peach", friend) > 0 then
							possible_friend = possible_friend + 1
						end
					end
				end
				if possible_friend == 0 then
					if self:getCardsNum("Peach") < 1 - target:getHp() then
						return "."
					end
				end
			end
		end
		if lord then
			if target:objectName() ~= lord:objectName() then
				if self.player:objectName() ~= target:objectName() then
					local count = self:getOpponentNumBySeat(current, lord, self.player)
					if lord:getHp() <= 1 then
						if self:isEnemy(current) then
							if current:canSlash(lord, nil, true) then
								if sgs.getCardsNum("Peach", lord) == 0 then
									if sgs.getCardsNum("Analeptic", lord) == 0 then
										if #self.friends_noself <= 2 then
											if sgs.slash:isAvailable(current) then
												if self:damageIsEffective(current, nil, lord) then
													local peachCount = self:getCardsNum("Peach")
													if peachCount <= count + 1 then
														return "."
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
		local buqus = target:getPile("buqu")
		if not buqus:isEmpty() then
			local same = false
			for i, card_id in sgs.qlist(buqus) do
				for j, card_id2 in sgs.qlist(buqus) do
					if i ~= j then
						local cardA = sgs.Sanguosha:getCard(card_id)
						local cardB = sgs.Sanguosha:getCard(card_id2)
						if cardA:getNumber() == cardB:getNumber() then
							same = true
							break
						end
					end
				end
			end
			if not same then 
				return "." 
			end
		end
		if target:hasFlag("Kurou_toDie") then
			local weapon = target:getWeapon()
			if not weapon then
				return "."
			elseif weapon:objectName() ~= "Crossbow" then 
				return "." 
			end
		end
		if self.player:objectName() ~= target:objectName() then
			if target:hasSkill("jiushi") then
				if target:faceUp() then
					if target:getHp()== 0 then
						return "."
					end
				end
			end
		end
		if self.player:objectName() == target:objectName() then
			card_str = self:getCardId("Analeptic")
			card_str = card_str or self:getCardId("Peach")
		elseif self:mayLord(target) then
			card_str = self:getCardId("Peach")
		-- elseif self:doNotSave(target) then
			-- return "."
		else
			local weak_lord = 0
			for _,friend in ipairs(self.friends_noself) do
				if self:mayLord(friend) then
					if friend:getHp() <= 1 then
						if not friend:hasSkill("buqu") then
							weak_lord = weak_lord + 1
						end
					end
				end
			end
			if self:amRenegade() then
				for _,enemy in ipairs(self.enemies) do
					if self:mayLord(enemy) then
						if enemy:getHp() <= 1 then
							if not enemy:hasSkill("buqu") then
								weak_lord = weak_lord + 1
							end
						end
					end
				end
			end
			if weak_lord < 1 then
				card_str = self:getCardId("Peach") 
			elseif self:getAllPeachNum() > 1 then
				card_str = self:getCardId("Peach") 
			end
		end
	end
	return card_str or "."
end
--[[
	功能：判断是否应当使用“桃园结义”
	参数：card（Card类型，表示待使用的桃园结义）
	结果：boolean类型，表示是否应使用
]]--
function SmartAI:willUseGodSalvation(card)
	if card then 
		local good, bad = 0, 0
		local wounded_friend = 0
		local wounded_enemy = 0
		local LiuXie = self.room:findPlayerBySkillName("huangen")
		if LiuXie then
			local LiuXieHp = LiuXie:getHp()
			if self:isPartner(LiuXie) then
				if self.player:hasSkill("noswuyan") then
					if LiuXieHp > 0 then 
						return true 
					end
				end
				good = good + 7 * LiuXieHp
			else
				if self.player:hasSkill("noswuyan") then
					if self:isOpponent(LiuXie) then
						if LiuXieHp > 1 then
							if #self.opponents > 1 then 
								return false 
							end
						end
					end
				end
				bad = bad + 7 * LiuXieHp
			end
		end
		if self.player:hasSkill("noswuyan") then
			if self.player:isWounded() then
				return true
			elseif self.player:hasSkills("nosjizhi|jizhi") then 
				return true 
			end
			return false
		end
		if self.player:hasSkills("nosjizhi|jizhi") then 
			good = good + 6 
		end
		if self:hasLoseHandcardEffective() then
			good = good + 5
		elseif self.player:hasSkill("kongcheng") then
			if self.player:getHandcardNum() == 1 then
				good = good + 5
			end
		end
		for _,friend in ipairs(self.partners) do
			good = good + 10 * sgs.getCardsNum("Nullification", friend)
			if friend:getMark("@late") == 0 then
				if not friend:hasSkill("noswuyan") then
					if friend:isWounded() then
						wounded_friend = wounded_friend + 1
						good = good + 10
						local isLord = self:mayLord(friend)
						local hp = friend:getHp()
						if isLord then 
							good = good + 11 / (hp + 0.1) 
						end
						if self:hasSkills(sgs.masochism_skill, friend) then
							good = good + 5
						end
						if hp <= 1 and self:isWeak(friend) then
							good = good + 5
							if isLord then 
								good = good + 10 
							end
						else
							if isLord then 
								good = good + 5 
							end
						end
						if self:needToLoseHp(friend, nil, nil, true, true) then 
							good = good - 3 
						end
					elseif friend:hasSkill("danlao") then 
						good = good + 5
					end
				end
			end
		end
		for _, enemy in ipairs(self.opponents) do
			bad = bad + 10 * sgs.getCardsNum("Nullification", enemy)
			if enemy:getMark("@late") == 0 then
				if not enemy:hasSkill("noswuyan") then
					if enemy:isWounded() then
						wounded_enemy = wounded_enemy + 1
						bad = bad + 10
						local isLord = self:mayLord(enemy)
						local hp = enemy:getHp()
						if isLord then
							bad = bad + 11 / (hp + 0.1)
						end
						if self:hasSkills(sgs.masochism_skill, enemy) then
							bad = bad + 5
						end
						if hp <= 1 and self:isWeak(enemy) then
							bad = bad + 5
							if isLord then 
								bad = bad + 10 
							end
						else
							if isLord then 
								bad = bad + 5 
							end
						end
						if self:needToLoseHp(enemy, nil, nil, true, true) then 
							bad = bad - 3 
						end
					elseif enemy:hasSkill("danlao") then 
						bad = bad + 5
					end
				end
			end
		end
		if good - bad > 5 then
			if wounded_friend > 0 then
				return true
			end
		end
		if wounded_friend == 0 then
			if wounded_enemy == 0 then
				if self.player:hasSkills("nosjizhi|jizhi") then
					return true
				end
			end
		end
	else
		self.room:writeToConsole(debug.traceback()) 
	end
	return false 
end
--[[
	功能：判断是否应当使用酒
	参数：target（ServerPlayer类型，表示杀的目标角色）
		slash（Card类型，表示将使用的杀）
		analeptic（Card类型，表示将使用的酒）
	结果：boolean类型，表示是否应使用
]]--
function SmartAI:willUseAnaleptic(target, slash, analeptic)
	if sgs.turncount <= 1 then
		if self:amRenegade() then
			local lord = self.room:getLord()
			if sgs.isHealthy(lord) then
				if self:getOverflow() < 2 then 
					return false 
				end
			end
		end
	end
	--白银狮子
	if target:hasArmorEffect("SilverLion") then
		if not sgs.IgnoreArmor(self.player, target) then
			if not self.player:hasSkill("jueqing") then 
				return false 
			end
		end
	end
	--贞烈
	if target:hasSkill("zhenlie") then 
		return false 
	end
	--安娴
	if target:hasSkill("anxian") then
		if target:getHandcardNum() > 0 then 
			return false 
		end
	end
	--潜袭
	if self.player:hasSkill("nosqianxi") then
		if self.player:distanceTo(target) == 1 then
			local skills = sgs.masochism_skill.."|longhun|buqu|"..sgs.recover_skill.."|".. sgs.exclusive_skill
			if self:hasSkills(skills, target) then
				return false
			end
		end
	end
	local no_cost = false
	if analeptic:isVirtualCard() then
		if analeptic:subcardsLength() == 0 then 
			no_cost = true 
		end
	end
	if not no_cost then
		--丈八蛇矛
		if self.player:hasWeapon("Spear") then
			if slash:getSkillName() == "Spear" then
				if self.player:getHandcardNum() <= 2 then 
					return false 
				end
			end
		end
		--享乐
		if target:hasSkill("xiangle") then
			local basicNum = 0
			local handcards = self.player:getHandcards()
			for _,basic in sgs.qlist(handcards) do
				if basic:getTypeId() == sgs.Card_Basic then
					if not sgs.isCard("Peach", basic) then
						basicNum = basicNum + 1
					end
				end
			end
			if basicNum < 3 then
				return false
			end
		end
	end
	--酒池
	if analeptic:getSkillName() == "jiushi" then
		--放逐
		if target:hasSkill("fangzhu") then
			return true
		end
		--极略
		if target:hasSkill("jilve") then
			if target:getMark("@bear") > 0 then 
				return true 
			end
		end
	end
	--烈弓
	if self:canLiegong(target, self.player) then 
		return true 
	end
	--贯石斧
	if self.player:hasWeapon("Axe") then
		if self.player:getCards("he"):length() > 4 then 
			return true 
		end
	end
	--铁骑
	if self.player:hasSkill("tieji") then 
		return true 
	end
	--大喝、潜袭
	--Waiting For More Details
	--肉林、无双
	local caseDoubleJinks = false
	if self.player:hasSkill("roulin") then
		if target:isFemale() then
			caseDoubleJinks = true
		end
	end
	if not caseDoubleJinks then
		if self.player:isFemale() then
			if target:hasSkill("roulin") then
				caseDoubleJinks = true
			end
		end
	end
	if not caseDoubleJinks then
		caseDoubleJinks = ( self.player:hasSkill("wushuang") )
	end
	local knownJinkNum = nil
	if caseDoubleJinks then
		knownJinkNum = sgs.getKnownCard(target, "Jink", true, "he")
		if knownJinkNum >= 2 then 
			return false 
		end
		return sgs.getCardsNum("Jink", target) < 2
	end
	knownJinkNum = knownJinkNum or sgs.getKnownCard(target, "Jink", true, "he")
	if knownJinkNum >= 1 then
		if self:getOverflow() <= 0 then
			return false
		elseif self:getCardsNum("Analeptic") <= 1 then 
			return false 
		end
	end
	if self:getCardsNum("Analeptic") > 1 then
		return true
	elseif sgs.getCardsNum("Jink", target) < 1 then
		return true
	elseif sgs.card_lack[target:objectName()]["Jink"] == 1 then
		return true
	end
	return false
end
--[[
	功能：获取自身对指定卡牌的需求情况
	参数：card（Card类型，表示指定的卡牌）
	结果：number类型（value），表示需求程度
]]--
function SmartAI:getCardNeedValue(card)
	if card:isKindOf("Peach") then
		self:sort(self.partners, "hp")
		if self.partners[1]:getHp() < 2 then 
			return 10 
		end
		if self.player:getHp() < 3 then
			return 10
		elseif self.player:getLostHp() > 1 and not self:hasSkills("longhun|buqu") then
			return 10
		elseif self:hasSkills("kurou|benghuai") then 
			return 14 
		end
		return sgs.getUseValue(card, self.player)
	end
	local WuGuoTai = self.room:findPlayerBySkillName("buyi")
	if WuGuoTai then
		if self:isPartner(WuGuoTai) then
			if not card:isKindOf("BasicCard") then
				if self.player:getHp() < 3 then
					return 13
				elseif self.player:getLostHp() > 1 and not self:hasSkills("longhun|buqu") then
					return 13
				elseif self:hasSkills("kurou|benghuai") then 
					return 13 
				end
			end
		end
	end
	if self:isWeak() then
		if card:isKindOf("Jink") then
			if self:getCardsNum("Jink") < 1 then 
				return 12 
			end
		end
	end
	local value = 0
	local skills = self.player:getVisibleSkillList()
	local count = 0
	local class_name = card:getClassName()
	for _, skill in sgs.qlist(skills) do
		local key = skill:objectName() .. "_keep_value"
		if sgs[key] then
			local v = sgs[key][class_name]
			if v then
				count = count + 1
				value = value + v 
			end
		end
	end
	if count > 0 then
		return value / count + 4
	end
	count = 0
	local suit = card:getSuitString()
	for _, skill in sgs.qlist(skills) do
		local key = skill:objectName() .. "_suit_value"
		if sgs[key] then
			local v = sgs[key][suit]
			if v then
				count = count + 1
				value = value + v 
			end
		end
	end
	if count > 0 then 
		return value / count + 4 
	end
	if card:isKindOf("Slash") then	
		if self:getCardsNum("Slash") == 0 then 
			return 5.9 
		else
			return 4
		end
	elseif card:isKindOf("Analeptic") then
		if self.player:getHp() < 2 then 
			return 10 
		end
	elseif card:isKindOf("Crossbow") then
		if self:hasSkills("luoshen|yongsi|kurou|keji|wusheng|wushen") then 
			return 20
		end
	elseif card:isKindOf("Axe") then
		if self:hasSkills("luoyi|jiushi|jiuchi|pojun") then 
			return 15 
		end
	elseif card:isKindOf("Weapon") then
		if not self.player:getWeapon() then
			if self:getCardsNum("Slash") > 1 then 
				return 6
			end
		end
	elseif card:isKindOf("Nullification") then
		if self:getCardsNum("Nullification") == 0 then
			if self:willSkipPlayPhase() then
				return 10
			elseif self:willSkipDrawPhase() then 
				return 10 
			end
			for _,friend in ipairs(self.partners_noself) do
				if self:willSkipPlayPhase(friend) then
					return 9
				elseif self:willSkipDrawPhase(friend) then 
					return 9 
				end
			end
			return 6
		end
	end
	return sgs.getUseValue(card, self.player)
end
--[[
	功能：按自身对卡牌的需求程度对一组卡牌进行排序
	参数：cards（table类型，表示待排序的卡牌）
		inverse（boolean类型，表示是否逆序）
	结果：无（表cards被改变）
]]--
function SmartAI:sortByCardNeed(cards, inverse)
	local values = {}
	for _,card in ipairs(cards) do
		values[card] = self:getCardNeedValue(card)
	end
	local function compare_func(a, b)
		local value1 = values[a]
		local value2 = values[b]
		if value1 == value2 then
			if inverse then 
				return a:getNumber() < b:getNumber() 
			end
			return a:getNumber() > b:getNumber()
		else
			if inverse then 
				return value1 > value2 
			end
			return value1 < value2
		end
	end
	table.sort(cards, compare_func)
end
--[[
	功能：获取有卡牌需求的角色
	参数：cards（table类型，表示待分配的卡牌）
	结果：Card类型和ServerPlayer类型
]]--
function SmartAI:getCardNeedPlayer(cards)
	if not cards then
		local handcards = self.player:getHandcards()
		cards = sgs.QList2Table(handcards)
	end
	local friends = {}
	for _,player in ipairs(self.partners_noself) do
		if not player:hasSkill("manjuan") then
			local exclude = false
			if self:needKongcheng(player, true) then
				exclude = true
			elseif player:containsTrick("indulgence") then
				if not player:containsTrick("YanxiaoCard") then
					exclude = true
				end
			end
			if self:hasSkills("keji|qiaobian|conghui|shensu|jisu", player) then
				exclude = false
			elseif player:getHp() - player:getHandcardNum() >= 3 then
				exclude = false
			elseif self:mayLord(player) then
				if self:isWeak(player) then
					if self:getOpponentNumBySeat(self.player, player) >= 1 then
						exclude = false
					end
				end
			end
			if not exclude then
				table.insert(friends, player)
			end
		end
	end
	--刘备、荀彧、华佗
	local num = self.player:getHandcardNum()
	if self.player:hasSkill("nosrende") then
		if self.player:getPhase() == sgs.Player_Play then
			local CardsToSpecial = {}
			local SpecialNum = 0
			local XunYu = nil
			local HuaTuo = nil
			for _,player in ipairs(friends) do
				if player:hasSkill("jieming") then
					XunYu = player
					SpecialNum = SpecialNum + 1
				end
				if player:hasSkill("huatuo") then
					HuaTuo = player
					SpecialNum = SpecialNum + 1
				end
			end
			if SpecialNum > 1 then
				local NoDistance = self.slash_distance_limit
				local KeptSlash = 0
				local RedCardNum = 0
				--说实话，这段没看明白……
				for _,c in ipairs(cards) do
					if sgs.isCard("Slash", c, self.player) then
						if self.player:canSlash(XunYu, nil, not NoDistance) then
							if self:slashIsEffective(c, XunYu) then
								KeptSlash = KeptSlash + 1
							end
						end
						if KeptSlash > 0 then
							table.insert(CardsToSpecial, c)
						end
					elseif sgs.isCard("Duel", c, self.player) then
						table.insert(CardsToSpecial, c)
					end
				end
				for _,c in ipairs(CardsToSpecial) do
					if c:isRed() then
						RedCardNum = RedCardNum + 1
						break --这句是自己后加的；感觉只判断RedCardNum是否大于零，那只需加到一即可。
					end
				end
				if RedCardNum > 0 then
					if num > #CardsToSpecial then
						for _,c in ipairs(CardsToSpecial) do
							if c:isRed() then
								return c, HuaTuo
							else
								return c, XunYu
							end
						end
					end
				end
			end
		end
	end
	--考虑虚弱的队友
	self:sort(friends, "defense")
	for _, friend in ipairs(friends) do
		if friend:getHandcardNum() < 3 then
			if self:isWeak(friend) then
				for _,c in ipairs(cards) do
					if sgs.isCard("Peach", c, friend) then --给桃
						return c, friend
					elseif sgs.isCard("Analeptic", c, friend) then --给酒
						return c, friend
					elseif sgs.isCard("Jink", c, friend) then --给闪
						if self:getOpponentNumBySeat(self.player, friend) > 0 then
							return c, friend
						end
					end
				end
			end
		end
	end
	--牌太少不够仁德回复就都留着
	if self.player:hasSkill("nosrende") then
		if self.player:isWounded() then
			if num < 2 then
				if self.player:getMark("nosrende") == 0 then 
					return 
				end
			end
		end
	end
	--小心古锭刀和原版潜袭
	if self.player:hasSkill("rende") then
		if not self.player:hasUsed("RendeCard") then
			if self.player:isWounded() then
				if self.player:getMark("rende") < 2 then
					if num < 2 then
						if self.player:getMark("rende") == 0 then 
							return 
						end
					end
					if num + self.player:getMark("rende") == 2 then
						if self:getOverflow() <= 0 then
							for _, enemy in ipairs(self.opponents) do
								--古锭刀
								if self:isEquip("GudingBlade", enemy) then
									if enemy:canSlash(self.player) then
										return 
									elseif self:hasSkills("shensu|wushen|jiangchi", enemy) then 
										return 
									end
								end
								--原版潜袭
								if enemy:canSlash(self.player, nil, true) then
									if enemy:hasSkill("nosqianxi") then
										if enemy:distanceTo(self.player) == 1 then 
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
	--分配防具和防御马
	for _, friend in ipairs(friends) do
		if friend:getHp() <= 2 then
			if friend:faceUp() then
				for _, c in ipairs(cards) do
					if c:isKindOf("Armor") then
						if not friend:getArmor() then
							if not self:hasSkills("yizhong|bazhen", friend) then
								return c, friend
							end
						end
					elseif c:isKindOf("DefensiveHorse") then
						if not friend:getDefensiveHorse() then
							return c, friend
						end
					end
				end
			end
		end
	end
	--考虑急救和结姻
	self:sortByUseValue(cards, true)
	for _, friend in ipairs(friends) do
		if self:hasSkills("jijiu|jieyin", friend) then
			if friend:getHandcardNum() < 4 then
				for _, c in ipairs(cards) do
					if friend:hasSkill("jieyin") then
						return c, friend
					elseif friend:hasSkill("jijiu") then
						if c:isRed() then
							return c, friend
						end
					end
				end
			end
		end
	end	
	--分配诸葛连弩
	for _, friend in ipairs(friends) do
		if self:hasSkills("longdan|wusheng|keji", friend) then
			if not self:hasSkills("paoxiao", friend) then
				if friend:getHandcardNum() >=2 then
					for _, c in ipairs(cards) do
						if c:isKindOf("Crossbow") then
							return c, friend
						end
					end
				end
			end
		end
	end	
	--按诸葛连弩分配杀
	for _, friend in ipairs(friends) do
		if sgs.getKnownCard(friend, "Crossbow") then
			local others = self.room:getOtherPlayers(friend)
			for _, p in sgs.qlist(others) do
				if self:isOpponent(p) then
					if sgs.isGoodTarget(self, p, self.opponent) then
						if friend:distanceTo(p) <= 1 then
							for _, c in ipairs(cards) do
								if sgs.isCard("Slash", c, friend) then
									return c, friend
								end
							end
						end
					end
				end
			end
		end
	end
	--保留一张闪
	local CardsToGive = {}
	local KeptJink = 0
	for _,c in ipairs(cards) do
		if KeptJink < 1 and sgs.isCard("Jink", c, self.player) then --留闪
			KeptJink = KeptJink + 1
		else
			table.insert(CardsToGive, c)
		end
	end
	--分配武器和进攻马
	local function compareByAction(a, b)
		local front = self.room:getFront(a, b)
		return front:objectName() == a:objectName()
	end
	table.sort(friends, compareByAction)
	for _,friend in ipairs(friends) do
		if friend:faceUp() then
			local can_slash = false
			local others = self.room:getOtherPlayers(friend)
			for _,p in sgs.qlist(others) do
				if self:isOpponent(p) then
					if sgs.isGoodTarget(self, p, self.opponents) then
						if friend:distanceTo(p) <= friend:getAttackRange() then
							can_slash = true
							break
						end
					end
				end
			end
			local flag = string.format("weapon_done_%s_%s", self.player:objectName(), friend:objectName())
			if not can_slash then
				for _,p in sgs.qlist(others) do
					if self:isOpponent(p) then
						if sgs.isGoodTarget(self, p, self.opponents) then
							if friend:distanceTo(p) > friend:getAttackRange() then
								for _,c in ipairs(CardsToGive) do
									if c:isKindOf("Weapon") then
										if not friend:getWeapon() then
											if not friend:hasFlag(flag) then
												local range = sgs.weapon_range[c:getClassName()] or 0
												range = range + friend:getAttackRange()
												if friend:distanceTo(p) <= range then
													self.room:setPlayerFlag(friend, flag)
													return c, friend 
												end
											end
										end
									elseif c:isKindOf("OffensiveHorse") then
										if not friend:getOffensiveHorse() then
											if not friend:hasFlag(flag) then
												if friend:distanceTo(p) <= friend:getAttackRange() + 1 then
													self.room:setPlayerFlag(friend, flag)
													return c, friend
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
	--按卡牌需求分配
	local function compareByPoint(a, b)
		return a:getNumber() > b:getNumber()
	end
	table.sort(CardsToGive, compareByPoint)
	for _, friend in ipairs(friends) do
		if friend:faceUp() then
			if not self:needKongcheng(friend, true) then
				for _, c in ipairs(CardsToGive) do
					local skills = friend:getVisibleSkillList()
					for _, skill in sgs.qlist(skills) do
						local callback = sgs.card_need_system[skill:objectName()]
						if type(callback) == "function" then
							if callback(self, c, friend) then
								return c, friend
							end
						end
					end
				end
			end
		end
	end
	--激将
	if self.player:hasLordSkill("jijiang") then
		for _, friend in ipairs(friends) do
			if friend:getKingdom() == "shu" then
				if friend:getHandcardNum() < 3  then
					for _,c in ipairs(CardsToGive) do
						if sgs.isCard("Slash", c, friend) then
							return c, friend
						end
					end
				end
			end
		end
	end
	--破空城
	if #self.opponents > 0 then
		self:sort(self.opponents, "defense")
		local victim = self.opponents[1]
		if victim:isKongcheng() then
			if self:needKongcheng(victim, true) then
				if not victim:hasSkill("manjuan") then
					for _,c in ipairs(CardsToGive) do
						if sgs.isKindOf("Lightning|Collateral|OffensiveHorse|Weapon|AmazingGrace", c) then
							return c, victim
						elseif sgs.isKindOf("Slash", c) then
							if self.player:getPhase() == sgs.Player_Play then
								return c, victim
							end
						end
					end
				end
			end
		end
	end
	--嘲讽度和收益技能
	self:sort(friends, "defense")
	for _, c in ipairs(CardsToGive) do
		for _, friend in ipairs(self.partners_noself) do
			if not self:needKongcheng(friend, true) then
				if not friend:hasSkill("manjuan") then
					if friend:getHandcardNum() <= 3 then
						if not self:willSkipPlayPhase(friend) then
							local flag = false
							if (sgs.ai_chaofeng[self.player:getGeneralName()] or 0) > 2 then
								flag = true
							elseif self:hasSkills(sgs.priority_skill, friend) then
								flag = true
							end
							if flag then
								flag = false
								if num > 3 then
									flag = true
								elseif self:getOverflow() > 0 then
									flag = true
								end
							end
							if flag then
								return c, friend
							end
						end
					end
				end
			end
		end
	end
	--分配溢出的手牌
	self:sort(friends, "handcard")
	for _, c in ipairs(CardsToGive) do
		for _, friend in ipairs(self.partners_noself) do
			if not friend:hasSkill("manjuan") then
				if not self:needKongcheng(friend, true) then
					if friend:getHandcardNum() <= 3 then
						if num > 3 then
							return c, friend 
						elseif self:getOverflow() > 0 then
							return c, friend
						elseif self.player:isWounded() then
							if self.player:hasSkill("rende") then
								if self.player:usedTimes("RendeCard") < 2 then
									return c, friend
								end
							end
							if self.player:hasSkill("nosrende") then
								if self.player:usedTimes("NosRendeCard") < 2 then
									return c, friend
								end
							end
						end
					end
				end
			end
		end
	end
	--仁德回复
	for _, c in ipairs(CardsToGive) do
		for _, friend in ipairs(self.partners_noself) do
			if not friend:hasSkill("manjuan") then
				if not self:needKongcheng(friend, true) then
					if num > 3 then
						return c, friend
					elseif self:getOverflow() > 0 then
						return c, friend
					elseif self.player:isWounded() then
						if self.player:hasSkill("rende") then
							if self.player:usedTimes("RendeCard") < 2 then
								return c, friend
							end
						end
						if self.player:hasSkill("nosrende") then
							if self.player:usedTimes("NosRendeCard") < 2 then
								return c, friend
							end
						end
					end
				end
			end
		end
	end
	--最后的挣扎
	if #cards > 0 then
		local need_rende = false
		if self.player:hasSkill("rende") then
			if not self.player:hasUsed("RendeCard") then
				if self.player:getMark("rende") < 2 then
					need_rende = true
				end
			end
		end
		if not need_rende then
			if self.player:hasSkill("nosrende") then
				if self.player:getMark("nosrende") < 2 then
					need_rende = true
				end
			end
		end
		if need_rende then
			need_rende = false
			if self.player:isWounded() then
				if #self.friends_noself > 0 then
					need_rende = true
				end
			end
			if not need_rende then
				if self:isWeak() then
					if #self.friends_noself == 0 then
						if #self.partners_noself > 0 then
							need_rende = true
						end
					end
				end
			end
		end
		if need_rende then
			local others = self.room:getOtherPlayers(self.player)
			others = sgs.QList2Table(others)
			self:sort(others, "defense")
			self:sortByUseValue(cards, true)
			return cards[1], others[1]
		end
	end
end