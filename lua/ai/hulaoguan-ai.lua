--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）虎牢关模式部分
]]--
--[[
	技能：重整
	描述：神·吕布行动后轮到先锋角色行动，则所有重整阶段的武将减少一回合。若先锋正在重整，则由最靠近先锋的角色进行回合。重整阶段共6回合，每减少1回合时，重整角色回复一点体力，若体力回满则摸一张牌。 
]]--
sgs.ai_skill_choice["Hulaopass"] = "recover"
--[[
	技能：特殊摸牌
	描述：有联盟军撤退（死亡）时，其他联盟军可选择是否从牌堆摸一张牌。按照当前行动顺序依次询问。
]]--
sgs.ai_skill_invoke["draw_1v3"] = function(self, data)
	return not self:needKongcheng(self.player, true)
end
--[[
	技能：武器重铸
	描述：虎牢关模式中，所有武器牌除了可直接装备使用外，还可直接进行重铸（效果同铁索连环重铸）。 
]]--
sgs.ai_skill_invoke["weapon_recast"] = function(self, data)
	if self:hasSkills(sgs.lose_equip_skill, self.player) then 
		return false 
	end
	if self:amLord() then 
		local use = data:toCardUse()
		local weapon = use.card
		if weapon:objectName() ~= "Crossbow" then 
			return true 
		else 
			return false 
		end 
	else
		if self.player:getWeapon() then 
			return true 
		else 
			return false 
		end
	end
end