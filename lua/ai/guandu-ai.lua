--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）官渡之战部分
]]--
sgs.ai_role_to_camp["guandu"] = {
	lord = "loyal",
	loyalist = "loyal",
	renegade = "renegade",
	rebel = "rebel"
}
sgs.InitRelationship["guandu"] = function()
	local lord = global_room:getLord()
	local lordname = lord:objectName()
	table.insert(sgs.ai_lords, lordname)
	local allplayers = global_room:getAllPlayers()
	for _,p in sgs.qlist(allplayers) do
		local nameA = p:objectName()
		local campA = sgs.ai_camp[nameA]
		if campA == "loyal" then
			sgs.ai_lord[nameA] = lordname
		end
		for _,p2 in sgs.qlist(allplayers) do
			local nameB = p2:objectName()
			local campB = sgs.ai_camp[nameB]
			if campA == campB then
				sgs.ai_relationship[campA][campB] = "partner"
			else
				sgs.ai_relationship[campA][campB] = "opponent"
			end
		end
	end
end
--[[
	技能：斩颜良诛文丑
	描述：关羽每回合可选择与颜良文丑拼点一次，落败的一方将损失一点体力。
]]--
--[[
	内容：注册“战双雄技能卡”
]]--
sgs.RegistCard("ZhanShuangxiongCard")
--[[
	内容：“斩颜良诛文丑”技能信息
]]--
sgs.ai_skills["zhanshuangxiong"] = {
	name = "zhanshuangxiong",
	dummyCard = function(self)
		return sgs.Card_Parse("@ZhanShuangxiongCard")
	end,
	enabled = function(self, handcards)
		if self.player:hasUsed("ZhanShuangxiongCard") then
			return false
		elseif self.player:isKongcheng() then
			return false
		end
		return true
	end,
}
--[[
	内容：“战双雄技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["ZhanShuangxiongCard"] = function(self, card, use)
	local others = self.room:getOtherPlayers(self.player)
	local target = nil
	for _,YanLiangWenChou in sgs.qlist(others) do
		if YanLiangWenChou:hasSkill("shuangxiong") then
			if not YanLiangWenChou:isKongcheng() then
				if self:isEnemy(YanLiangWenChou) then
					target = YanLiangWenChou
					break
				end
			end
		end
	end
	if target then
		local my_max_card = self:getMaxPointCard()
		local my_max_point = my_max_card:getNumber()
		local max_card = self:getMaxPointCard(target)
		local max_point = max_card:getNumber()
		if my_max_point > max_point then
			use.card = card
			if use.to then
				use.to:append(target)
			end
		end
	end
end
--[[
	套路：仅使用“战双雄技能卡”
]]--
sgs.ai_series["ZhanShuangxiongCardOnly"] = {
	name = "ZhanShuangxiongCardOnly",
	IQ = 2,
	value = 3,
	priority = 4,
	cards = {
		["ZhanShuangxiongCard"] = 1,
		["Others"] = 1,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local duel_skill = sgs.ai_skills["zhanshuangxiong"]
		local dummyCard = duel_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["ZhanShuangxiongCard"], "ZhanShuangxiongCardOnly")
--[[
	技能：小突袭
	描述：张辽只能突袭一个人的一张牌。
]]--
sgs.ai_card_intention["SmallTuxiCard"] = 80
sgs.ai_skill_use["@@smalltuxi"] = function(self, prompt)
	self:sort(self.opponents, "handcard")
	for _,enemy in ipairs(self.opponents) do
		if not enemy:isKongcheng() then
			local flag = true
			if self:hasSkills(sgs.need_kongcheng, enemy) then
				if enemy:getHandcardNum() == 1 then
					flag = false
				end
			end
			if flag then
				local card_str = "@SmallTuxiCard=.->" .. enemy:objectName()
				return card_str
			end
		end
	end
end