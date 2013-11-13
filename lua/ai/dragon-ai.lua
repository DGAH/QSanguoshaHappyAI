--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）龙版扩展包部分
	注：此扩展包在端午序曲版（20130610）中不存在，仅为兼容新版而作
]]--
--[[****************************************************************
	武将：龙版·许褚（魏）
]]--****************************************************************
--[[
	技能：裸衣（锁定技）
	描述：若你的装备区没有武器牌，你使用且你为伤害来源的【杀】对目标角色造成伤害时，此伤害+1。
]]--
--[[****************************************************************
	武将：龙版·马超（蜀）
]]--****************************************************************
--[[
	技能：马术（锁定技）
	描述：你与其他角色的距离-1。其他角色与你的距离+1。你的装备区只能有一张坐骑牌。
]]--
--[[****************************************************************
	武将：龙版·孙权（吴）
]]--****************************************************************
--[[
	技能：制衡
	描述：结束阶段开始时，你可以弃置任意数量的手牌，然后将手牌数补至等于体力值的张数。
]]--
sgs.ai_skill_use["@@drzhiheng"] = function(self, prompt)
end
--[[****************************************************************
	武将：龙版·周瑜（吴）
]]--****************************************************************
--[[
	技能：借刀（阶段技）
	描述：你可以将一名其他角色的武器牌移动至你的装备区：若如此做，回合结束时将此武器牌移动回该角色装备区。
]]--
--[[
	内容：注册“借刀技能卡”
]]--
sgs.RegistCard("DrJiedaoCard")
--[[
	内容：“借刀”技能信息
]]--
sgs.ai_skills["drjiedao"] = {
	name = "drjiedao",
	dummyCard = function(self)
		return sgs.Card_Parse("@DrJiedaoCard=.")
	end,
	enabled = function(self, handcards)
		if self.player:hasUsed("DrJiedaoCard") then
			return false
		else
			local others = self.room:getOtherPlayers(self.player)
			for _,p in sgs.qlist(others) do
				if p:getWeapon() then
					return true
				end
			end
		end
		return false
	end,
}
--[[
	内容：“借刀技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["DrJiedaoCard"] = function(self, card, use)
	--Waiting For More Details
end
--[[
	套路：仅使用“借刀技能卡”
]]--
sgs.ai_series["DrJiedaoCardOnly"] = {
	name = "DrJiedaoCardOnly",
	IQ = 2,
	value = 2,
	priority = 4,
	skills = "drjiedao",
	cards = {
		["DrJiedaoCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local jiedao_skill = sgs.ai_skills["jiedao"]
		local dummyCard = jiedao_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["DrJiedaoCard"], "DrJiedaoCardOnly")
--[[****************************************************************
	武将：龙版·吕布（群）
]]--****************************************************************
--[[
	技能：无双（锁定技）
	描述：每当你指定【杀】的目标后，目标角色须连续使用两张【闪】抵消此【杀】。一名角色响应你使用的【南蛮入侵】或【万箭齐发】时，须先弃置一张牌。
]]--
sgs.ai_skill_discard["drwushuang"] = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummyreason", discard_num, min_num, false, true)
end
--[[****************************************************************
	武将：龙版·华佗（群）
]]--****************************************************************
--[[
	技能：青囊
	描述：出牌阶段，若你已受伤，你可以弃置一张牌：若如此做，你回复1点体力。
]]--
--[[
	内容：注册“青囊技能卡”
]]--
sgs.RegistCard("DrQingnangCard")
--[[
	内容：“青囊”技能信息
]]--
sgs.ai_skills["drqingnang"] = {
	name = "drqingnang",
	dummyCard = function(self)
		return sgs.Card_Parse("@DrQingnangCard=.")
	end,
	enabled = function(self, handcards)
		if self.player:isNude() then
			return false
		elseif self.player:isWounded() then
			return true
		end
		return false
	end,
}
--[[
	内容：“青囊技能卡”的具体使用方式
]]--
sgs.ai_skill_use_func["DrQingnangCard"] = function(self, card, use)
	--Waiting For More Details
end
--[[
	套路：仅使用“青囊技能卡”
]]--
sgs.ai_series["DrQingnangCardOnly"] = {
	name = "DrQingnangCardOnly",
	IQ = 2,
	value = 3,
	priority = 2,
	skills = "drqingnang",
	cards = {
		["DrQingnangCard"] = 1,
		["Others"] = 0,
	},
	enabled = function(self)
		return true
	end,
	action = function(self, handcards, skillcards)
		local qingnang_skill = sgs.ai_skills["drqingnang"]
		local dummyCard = qingnang_skill["dummyCard"](self)
		return {dummyCard}
	end,
	break_condition = function(self)
		return false
	end,
}
table.insert(sgs.ai_card_actions["DrQingnangCard"], "DrQingnangCardOnly")
--[[
	技能：急救
	描述：每当一名角色受到伤害时，你可以弃置一张红色牌：若如此做，此伤害-1。
]]--
sgs.ai_skill_cardask["@JijiuDecrease"] = function(self, data)
	--Waiting For More Details
	return "."
end