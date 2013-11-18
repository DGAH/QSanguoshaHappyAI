--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）总控制文件
]]--
require "middleClass"
math.randomseed(os.time())
SmartAI = class "SmartAI"
version = "QSanguosha AI 20130610 (V1.10 Alpha)"
dofile "lua/ai/tools-ai.lua" --工具函数库
dofile "lua/ai/iq-ai.lua" --智商水平部分

function CloneAI(player)
	return SmartAI(player).lua_ai
end
--[[****************************************************************
	AI系统用表
]]--****************************************************************
sgs.current_mode = nil --当前游戏模式
sgs.hegemony_mode = false --是否启用国战模式
sgs.role_predictable = false --是否开启身份预知
sgs.ai_chat_enabled = false --是否开启AI聊天
sgs.ai_init_count = 0 --已初始化的AI数目
sgs.close_partners = false --是否取消关系策略调整
sgs.system_record = {} --AI真实阵营（仅供系统处理方便使用。请勿在AI思考时引用此表，否则视为作弊！）

sgs.ai_camps = {} --AI阵营总表
sgs.ai_destoryed_camps = {} --所有被消灭的AI阵营
sgs.ai_members_count = {} --AI阵营当前剩余人数表（0表示不存在此阵营，-1表示剩余人数未知）
sgs.ai_camp = {} --AI阵营推定表（unknown表示未知的阵营；格式：sgs.ai_camp[objectName] = "campName"）
sgs.ai_lords = {} --所有阵营的领袖
sgs.ai_lord = {} --AI所在阵营的领袖（仅供系统处理方便使用。请勿在AI思考时引用此表，否则视为作弊！）
sgs.ai_relationship = {} --AI间相互关系（partner表示合作、neutral表示不关心、opponent表示对抗）
sgs.ai_friendly_level = {} --AI对各阵营表示友好的水平
sgs.ai_hostile_level = {} --AI对各阵营表示敌对的水平
sgs.ai_camp_history = {} --AI立场记录
sgs.InitRelationship = {} --各游戏模式下的角色间关系初始化模块

sgs.ai_chaofeng = {} --武将嘲讽度
sgs.ai_global_flags = {} --全局标志表
sgs.ai_compare_funcs = {} --比较函数表，用于排序
sgs.ai_type_name = {} --卡牌类型名
sgs.card_constituent = {} --卡牌成分
sgs.ai_card_intention = {} --卡牌使用仇恨值
sgs.ai_playerchosen_intention = {} --卡牌目标指定仇恨值
sgs.card_lack = {} --卡牌紧缺记录
sgs.card_need_system = {} --卡牌需求系统
sgs.card_count_system = {} --卡牌统计系统
sgs.objectName = {} --卡牌对象名记录表
sgs.className = {} --卡牌类型名记录表
sgs.ai_suit_priority = {} --卡牌花色使用优先级

sgs.ai_skill_suit = {} --askForSuit()
sgs.ai_skill_kingdom = {} --askForKingdom()
sgs.ai_skill_invoke = {} --askForSkillInvoke()
sgs.ai_skill_choice = {} --askForChoice()
sgs.ai_skill_discard = {} --askForDiscard() --askForExchange()
sgs.ai_skill_null = {} --askForNullification()
sgs.ai_skill_cardchosen = {} --askForCardChosen()
sgs.ai_skill_cardask = {} --askForCard()
sgs.ai_skill_use = {} --askForUseCard()
sgs.ai_skill_askforag = {} --askForAG()
sgs.ai_skill_cardshow = {} --askForCardShow()
sgs.ai_skill_askforyiji = {} --askForYiji()
sgs.ai_skill_pindian = {} --askForPindian()
sgs.ai_skill_playerchosen = {} --askForPlayerChosen()
sgs.ai_skill_general = {} --askForGeneral()
sgs.ai_skill_peach = {} --askForSinglePeach()

sgs.ai_skills = {} --可以主动发动的AI技能表单
sgs.ai_view_as_func = {} --
sgs.ai_skill_use_func = {} --SkillCards
sgs.ai_filterskill_filter = {} --锁定视为技影响检验表
sgs.ai_view_as = {} --使用视为技进行响应的方法
sgs.ai_cardsview_valuable = {}
sgs.ai_cardsview = {}

sgs.ai_series_suit = {} --askForSuit()
sgs.ai_series_kingdom = {} --askForKingdom()
sgs.ai_series_invoke = {} --askForSkillInvoke()
sgs.ai_series_choice = {} --askForChoice()
sgs.ai_series_discard = {} --askForDiscard() --askForExchange()
sgs.ai_series_null = {} --askForNullification()
sgs.ai_series_cardchosen = {} --askForCardChosen()
sgs.ai_series_cardask = {} --askForCard()
sgs.ai_series_use = {} --askForUseCard()
sgs.ai_series_askforag = {} --askForAG()
sgs.ai_series_cardshow = {} --askForCardShow()
sgs.ai_series_askforyiji = {} --askForYiji()
sgs.ai_series_pindian = {} --askForPindian()
sgs.ai_series_playerchosen = {} --askForPlayerChosen()
sgs.ai_series_general = {} --askForGeneral()
sgs.ai_series_peach = {} --askForSinglePeach()
sgs.ai_series_guanxing = {} --askForGuanxing()
sgs.ai_series_use_func = {} --SkillCards

sgs.ai_choicemade_filter = {
	cardUsed = {},
	cardResponded = {},
	skillInvoke = {},
	skillChoice = {},
	Nullification =	{},
	playerChosen = {},
	cardChosen = {},
	Yiji = {},
	viewCards = {},
	pindian = {},
}

sgs.ai_compare_funcs = {}
sgs.ai_debug_func = {}
sgs.ai_chat_func = {}
sgs.ai_event_callback = {}
for i=sgs.NonTrigger, sgs.NumOfEvents, 1 do
	sgs.ai_debug_func[i] = {}
	sgs.ai_chat_func[i] = {}
	sgs.ai_event_callback[i] = {}
end
--[[****************************************************************
	AI系统初始化
]]--****************************************************************
sgs.ai_role_to_camp = {
	--国战模式
	["hegemony"] = {
		lord = "wei",
		loyalist = "shu",
		rebel = "wu",
		renegade = "qun",
	},
	--KOF模式
	["02_1v1"] = {
		lord = "warm",
		renegade = "cold",
	},
	--虎牢关1v3模式
	["04_1v3"] = {
		lord = "lvbu",
		rebel = "ally",
	},
	--3v3模式
	["06_3v3"] = {
		lord = "warm",
		loyalist = "warm",
		rebel = "cold",
		renegade = "cold",
	},
	--血战到底模式
	["06_xmode"] = {
		lord = "warm",
		loyalist = "warm",
		rebel = "cold",
		renegade = "cold",
	},
	--2人身份局
	["02p"] = {
		lord = "lord",
		rebel = "rebel",
	},
	--3人身份局
	["03p"] = {
		lord = "loyal",
		rebel = "rebel",
		renegade = "renegade",
	},
	--4人身份局
	["04p"] = {
		lord = "loyal",
		rebel = "rebel",
		renegade = "renegade",
	},
	--5人身份局
	["05p"] = {
		lord = "loyal",
		loyalist = "loyal",
		rebel = "rebel",
		renegade = "renegade",
	},
	--6人身份局
	["06p"] = {
		lord = "loyal",
		loyalist = "loyal",
		rebel = "rebel",
		renegade = "renegade",
	},
	--6人身份局（双内奸）
	["06pd"] = {
		lord = "loyal",
		loyalist = "loyal",
		rebel = "rebel",
		renegade = "renegade",
		single = 1, --两个内奸各自为战
	},
	--7人身份局
	["07p"] = {
		lord = "loyal",
		loyalist = "loyal",
		rebel = "rebel",
		renegade = "renegade",
	},
	--8人身份局
	["08p"] = {
		lord = "loyal",
		loyalist = "loyal",
		rebel = "rebel",
		renegade = "renegade",
	},
	--8人身份局（双内奸）
	["08pd"] = {
		lord = "loyal",
		loyalist = "loyal",
		rebel = "rebel",
		renegade = "renegade",
		single = 1, --两个内奸各自为战
	},
	--8人身份局（无内奸）
	["08pz"] = {
		lord = "loyal",
		loyalist = "loyal",
		rebel = "rebel",
	},
	--9人身份局
	["09p"] = {
		lord = "loyal",
		loyalist = "loyal",
		rebel = "rebel",
		renegade = "renegade",
	},
	--10人身份局
	["10p"] = {
		lord = "loyal",
		loyalist = "loyal",
		rebel = "rebel",
		renegade = "renegade",
	},
	--10人身份局（双内奸）
	["10pd"] = {
		lord = "loyal",
		loyalist = "loyal",
		rebel = "rebel",
		renegade = "renegade",
		single = 1, --两个内奸各自为战
	},
	--10人身份局（无内奸）
	["10pz"] = {
		lord = "loyal",
		loyalist = "loyal",
		rebel = "rebel",
	},
	--通用情形（一般身份局）
	["gamerule"] = {
		lord = "loyal",
		loyalist = "loyal",
		renegade = "renegade",
		rebel = "rebel",
		single = 1,
	},
}
--[[
	功能：公共表初始化
	参数：无
	结果：无
]]--
function setInitialTables()
	--游戏模式
	sgs.current_mode = string.lower(global_room:getMode()) 
	--身份预知
	sgs.role_predictable = false 
	if sgs.GetConfig("RolePredictable", true) then --是否开启身份预知
		sgs.role_predictable = true
	end
	--国战模式
	sgs.hegemony_mode = false 
	if sgs.GetConfig("EnableHegemony", true) then --是否启用国战模式
		sgs.hegemony_mode = true
		sgs.maxShown = sgs.GetConfig("HegemonyMaxShown", 1) --最大亮将数目
	end
	--AI聊天
	sgs.ai_chat_enabled = false 
	if sgs.GetConfig("AIChat", true) then --是否启用AI聊天
		sgs.ai_chat_enabled = true
	end
	--卡牌类型
	sgs.ai_type_name = {
		"SkillCard",
		"BasicCard",
		"TrickCard",
		"EquipCard",
	}
	--归类技能表
	sgs.lose_equip_skill = "kofxiaoji|xiaoji|xuanfeng|nosxuanfeng"
	sgs.need_kongcheng = "lianying|kongcheng|sijian"
	sgs.masochism_skill = "guixin|yiji|fankui|jieming|xuehen|neoganglie|ganglie|vsganglie|enyuan|fangzhu|" ..
	"nosenyuan|langgu|quanji|zhiyu|renjie|tanlan|tongxin|huashen"
	sgs.wizard_skill = "guicai|guidao|jilve|tiandu|luoying|noszhenlie|huanshi"
	sgs.wizard_harm_skill = "guicai|guidao|jilve"
	sgs.priority_skill = 		"dimeng|haoshi|qingnang|nosjizhi|jizhi|guzheng|qixi|jieyin|guose|duanliang|jujian|fanjian|neofanjian|lijian|" ..
	"noslijian|manjuan|tuxi|qiaobian|yongsi|zhiheng|luoshen|rende|mingce|wansha|gongxin|jilve|anxu|" ..
	"qice|yinling|qingcheng|houyuan|zhaoxin|shuangren"
	sgs.save_skill = "jijiu|buyi|nosjiefan|chunlao|longhun"
	sgs.exclusive_skill = "huilei|duanchang|wuhun|buqu|dushi"
	sgs.cardneed_skill =		"paoxiao|tianyi|xianzhen|shuangxiong|nosjizhi|jizhi|guose|duanliang|qixi|qingnang|yinling|luoyi|guhuo|kanpo|" ..
	"jieyin|renjie|zhiheng|rende|nosjujian|guicai|guidao|longhun|luanji|qiaobian|beige|jieyuan|" ..
	"mingce|nosfuhun|lirang|longluo|xuanfeng|xinzhan|dangxian|xiaoguo|neoluoyi|fuhun"
	sgs.drawpeach_skill = "tuxi|qiaobian"
	sgs.recover_skill =	"nosrende|rende|kuanggu|zaiqi|jieyin|qingnang|yinghun|hunzi|shenzhi|longhun|" ..
	"nosmiji|zishou|ganlu|xueji|shangshi|nosshangshi|ytchengxiang|buqu|miji"
	sgs.use_lion_skill = "longhun|duanliang|qixi|guidao|noslijian|lijian|jujian|nosjujian|zhiheng|mingce|" ..
	"yongsi|fenxun|gongqi|yinling|jilve|qingcheng|neoluoyi|diyyicong"
	sgs.need_equip_skill = "shensu|mingce|jujian|beige|yuanhu|gongqi|nosgongqi|yanzheng|qingcheng|neoluoyi|"..
	"longhun|shuijian"
	sgs.judge_reason = "bazhen|EightDiagram|wuhun|supply_shortage|tuntian|nosqianxi|nosmiji|indulgence|"..
	"lightning|baonue$|leiji|caizhaoji_hujia|tieji|luoshen|ganglie|neoganglie|vsganglie"
end
--[[
	功能：通用AI间关系初始化
	参数：无
	结果：无
]]--
sgs.InitRelationship["gamerule"] = function()
	local players = global_room:getAllPlayers()
	local convert = sgs.ai_role_to_camp["gamerule"]
	local lord = global_room:getLord()
	if lord then
		sgs.ai_camp[lord:objectName()] = convert["lord"]
		sgs.ai_lord[lord:objectName()] = lord:objectName()
		table.insert(sgs.ai_lords, lord:objectName())
	end
	if sgs.role_predictable then --身份预知
		for _,pA in sgs.qlist(players) do
			local nameA = pA:objectName()
			local roleA = pA:getRole()
			sgs.ai_camp[nameA] = convert[roleA]
			if sgs.ai_camp[nameA] == "loyal" then
				sgs.ai_lord[nameA] = lord:objectName()
			end
			for _,pB in sgs.qlist(players) do
				local nameB = pB:objectName()
				local roleB = pB:getRole()
				sgs.ai_camp[nameB] = convert[roleB]
				if sgs.ai_camp[nameB] == sgs.ai_camp[nameA] then
					sgs.ai_relationship[nameA][nameB] = "opponent"
				else
					sgs.ai_relationship[nameA][nameB] = "partner"
				end
			end
		end
	else --未开启身份预知
		for _,p in sgs.qlist(players) do
			local name = p:objectName()
			sgs.ai_relationship[name][name] = "partner"
			local role = p:getRole()
			if role == "loyalist" then
				sgs.ai_lord[name] = lord:objectName()
			end
		end
	end
end
--[[
	功能：国战模式AI间关系初始化
	参数：无
	结果：无
]]--
sgs.InitRelationship["hegemony"] = function()
	local allplayers = global_room:getAllPlayers()
	if sgs.role_predictable then --身份预知
		for _,p in sgs.qlist(allplayers) do
			local kingdom = getHegemonyKingdom(p)
			sgs.ai_camp[p:objectName()] = kingdom
		end
		for _,p in sgs.qlist(allplayers) do
			local myname = p:objectName()
			sgs.ai_relationship[myname][myname] = "partner"
			local others = global_room:getOtherPlayers(p)
			for _,other in sgs.qlist(others) do
				local name = other:objectName()
				if sgs.ai_camp[myname] == sgs.ai_camp[name] then
					sgs.ai_relationship[myname][name] = "partner"
				else
					sgs.ai_relationship[myname][name] = "opponent"
				end
			end
		end
	else --非身份预知
		for _,p in sgs.qlist(allplayers) do
			local myname = p:objectName()
			sgs.ai_relationship[myname][myname] = "partner"
			local others = global_room:getOtherPlayers(p)
			for _,other in sgs.qlist(others) do
				local name = other:objectName()
				sgs.ai_relationship[myname][name] = "neutral"
			end
		end
	end
end
--[[
	功能：KOF模式AI间关系初始化
	参数：无
	结果：无
]]--
sgs.InitRelationship["02_1v1"] = function()
	sgs.role_predictable = true --身份预知
	sgs.close_partners = true --不调整关系策略
	local first = global_room:getLord()
	local others = global_room:getOtherPlayers(first)
	local second = others:first()
	local name1 = first:objectName()
	local name2 = second:objectName()
	sgs.ai_camp[name1] = "warm"
	sgs.ai_camp[name2] = "cold"
	sgs.ai_relationship[name1][name2] = "opponent"
	sgs.ai_relationship[name2][name1] = "opponent"
	sgs.ai_relationship[name1][name1] = "partner"
	sgs.ai_relationship[name2][name2] = "partner"
	sgs.ai_lord[name1] = name1
	table.insert(sgs.ai_lords, name1)
end
--[[
	功能：2人身份局模式AI间关系初始化
	参数：无
	结果：无
]]--
sgs.InitRelationship["02p"] = function()
	sgs.role_predictable = true --身份预知
	sgs.close_partners = true --不调整关系策略
	local first = global_room:getLord()
	local others = global_room:getOtherPlayers(first)
	local second = others:first()
	local name1 = first:objectName()
	local name2 = second:objectName()
	sgs.ai_camp[name1] = "lord"
	sgs.ai_camp[name2] = "renegade"
	sgs.ai_relationship[name1][name2] = "opponent"
	sgs.ai_relationship[name2][name1] = "opponent"
	sgs.ai_relationship[name1][name1] = "partner"
	sgs.ai_relationship[name2][name2] = "partner"
	sgs.ai_lord[name1] = name1
	table.insert(sgs.ai_lords, name1)
end
--[[
	功能：虎牢关1v3模式AI间关系初始化
	参数：无
	结果：无
]]--
sgs.InitRelationship["04_1v3"] = function()
	sgs.role_predictable = true --身份预知
	sgs.close_partners = true --不调整关系策略
	local lvbu = global_room:getLord()
	local others = global_room:getOtherPlayers(lvbu)
	local name = lvbu:objectName()
	sgs.ai_camp[name] = "lvbu"
	for _,p in sgs.qlist(others) do
		sgs.ai_camp[p:objectName()] = "ally"
	end
	local allplayers = global_room:getAllPlayers()
	for _,p in sgs.qlist(allplayers) do
		local name1 = p:objectName()
		sgs.ai_relationship[name1][name1] = "partner"
		others = allplayers
		others:removeOne(p)
		for _,other in sgs.qlist(others) do
			local name2 = other:objectName()
			if sgs.ai_camp[name1] == sgs.ai_camp[name2] then
				sgs.ai_relationship[name1][name2] = "partner"
			else
				sgs.ai_relationship[name1][name2] = "opponent"
			end
		end
	end
	sgs.ai_lord[name] = name
	table.insert(sgs.ai_lords, name)
end
--[[
	功能：3v3对战模式AI间关系初始化
	参数：无
	结果：无
]]--
sgs.InitRelationship["06_3v3"] = function()
	sgs.role_predictable = true --身份预知
	sgs.close_partners = true --不调整关系策略
	local lord1, lord2 = nil, nil
	local allplayers = global_room:getAllPlayers()
	for _,p in sgs.qlist(allplayers) do
		local name = p:objectName()
		local role = p:getRole()
		if role == "lord" then
			sgs.ai_camp[name] = "warm"
			lord1 = name
			table.insert(sgs.ai_lords, lord1)
		elseif role == "loyalist" then
			sgs.ai_camp[name] = "warm"
		elseif role == "renegade" then
			sgs.ai_camp[name] = "cold"
			lord2 = name
			table.insert(sgs.ai_lords, lord2)
		elseif role == "rebel" then
			sgs.ai_camp[name] = "cold"
		end
	end
	for _,p in sgs.qlist(allplayers) do
		local name1 = p:objectName()
		sgs.ai_relationship[name1][name1] = "partner"
		if sgs.ai_camp[name1] == "warm" then
			sgs.ai_lord[name1] = lord1
		elseif sgs.ai_camp[name1] == "cold" then
			sgs.ai_lord[name1] = lord2
		end
		local others = global_room:getOtherPlayers(p)
		for _,other in sgs.qlist(others) do
			local name2 = other:objectName()
			if sgs.ai_camp[name1] == sgs.ai_camp[name2] then
				sgs.ai_relationship[name1][name2] = "partner"
			else
				sgs.ai_relationship[name1][name2] = "opponent"
			end
		end
	end
end
--[[
	功能：血战到底模式AI间关系初始化
	参数：无
	结果：无
]]--
sgs.InitRelationship["06_xmode"] = function()
	sgs.role_predictable = true --身份预知
	sgs.close_partners = true --不调整关系策略
	local allplayers = global_room:getAllPlayers()
	for _,p in sgs.qlist(allplayers) do
		local name = p:objectName()
		local role = p:getRole()
		if ("lord|loyalist"):match(role) then
			sgs.ai_camp[name] = "warm"
		elseif ("renegade|rebel"):match(role) then
			sgs.ai_camp[name] = "cold"
		end
	end
	for _,p in sgs.qlist(allplayers) do
		local name1 = p:objectName()
		local others = global_room:getOtherPlayers(p)
		for _,other in sgs.qlist(others) do
			local name2 = other:objectName()
			if sgs.ai_camp[name1] == sgs.ai_camp[name2] then
				sgs.ai_relationship[name1][name2] = "partner"	
			else
				sgs.ai_relationship[name1][name2] = "opponent"
			end
		end
	end
end
--[[
	功能：AI间关系初始化
	参数：无
	结果：无
]]--
function InitialRelationship()
	sgs.close_partners = false
	--KOF模式
	if sgs.current_mode:find("02_1v1") then
		sgs.InitRelationship["02_1v1"]()
	--2人局
	elseif sgs.current_mode:find("02p") then
		if sgs.hegemony_mode then --国战模式
			sgs.InitRelationship["hegemony"]()
		else
			sgs.InitRelationship["02p"]()
		end
	--虎牢关1v3模式
	elseif sgs.current_mode:find("04_1v3") then
		sgs.InitRelationship["04_1v3"]()
	--3v3对战模式
	elseif sgs.current_mode:find("06_3v3") then
		sgs.InitRelationship["06_3v3"]()
	--血战到底模式
	elseif sgs.current_mode:find("06_xmode") then
		sgs.InitRelationship["06_xmode"]()
	--小型场景模式
	elseif sgs.current_mode:find("mini") then
		sgs.role_predictable = true --身份预知
		sgs.close_partners = true --不调整关系策略
		local callback = sgs.InitRelationship[sgs.current_mode]
		if not callback then
			callback = sgs.InitRelationship["gamerule"]
		end
		callback()
	--自定义场景模式
	elseif sgs.current_mode:find("custom_scenario") then
		sgs.role_predictable = true --身份预知
		local callback = sgs.InitRelationship[sgs.current_mode]
		if not callback then
			callback = sgs.InitRelationship["gamerule"]
		end
		callback()
	--场景模式
	elseif not sgs.current_mode:find("0") then 
		sgs.role_predictable = true --身份预知
		local callback = sgs.InitRelationship[sgs.current_mode]
		if not callback then
			callback = sgs.InitRelationship["gamerule"]
		end
		callback()
	--身份局模式
	else
		if sgs.hegemony_mode then --国战模式
			sgs.InitRelationship["hegemony"]()
		else --普通身份局
			sgs.InitRelationship["gamerule"]()
		end
	end
end
--[[
	功能：初始化并获取身份对应的阵营
	参数：role（string类型，表示角色身份）
		player（ServerPlayer类型，表示目标角色）
	结果：string类型（camp），表示阵营
]]--
function sgs.RegistCamp(role, player)
	local convert = nil
	if sgs.hegemony_mode then --国战模式
		convert = sgs.ai_role_to_camp["hegemony"]
	else --非国战模式
		convert = sgs.ai_role_to_camp[sgs.current_mode]
	end
	convert = convert or sgs.ai_role_to_camp["gamerule"]
	assert(convert)
	if convert["skip"] then
		local callback = convert["convert_func"]
		if type(callback) == "function" then
			return callback(role, player)
		end
	end
	local camp = convert[role] --自身阵营
	assert(camp)
	if role == "renegade" then --身份为内奸
		if convert["single"] then --内奸各自为战
			local renegade_count = sgs.renegade_count or 0
			sgs.renegade_count = renegade_count + 1
			camp = string.format("%s%d", camp, sgs.renegade_count)
		end
	end
	return camp
end
--[[
	功能：AI系统初始化
	参数：无
	结果：无
	备注：换将或复活时，系统也会自动进入此函数将角色重新初始化
]]--
function SmartAI:initialize(player)
	self.player = player --自身角色
	self.room = player:getRoom() --当前房间
	self.role = player:getRole() --自身身份（主公、忠臣、内奸、反贼，不同游戏模式下有不同含义）
	self.lua_ai = sgs.LuaAI(player)
	
	self.lua_ai.callback = function(full_method_name, ...)
		local method_name_start = 1
		while true do			
			local found = string.find(full_method_name, "::", method_name_start)
			if found ~= nil then				
				method_name_start = found + 2
			else				
				break
			end				 
		end
		local method_name = string.sub(full_method_name, method_name_start)
		local method = self[method_name]
		if method then
			local success, result1, result2
			success, result1, result2 = pcall(method, self, ...)
--self.room:writeToConsole(string.format("method=%s", method_name))
			if not success then
				self.room:writeToConsole(result1)
				self.room:writeToConsole(method_name)
				self.room:writeToConsole(debug.traceback())
				self.room:outputEventStack()
			else
				return result1, result2
			end
		end
	end
	
	if not sgs.initialized then
		sgs.initialized = true
		sgs.turncount = 0
		sgs.debugmode = false
		sgs.ai_init_count = 0
		global_room = self.room
		global_room:writeToConsole(version .. ", Powered by " .. _VERSION)
		setInitialTables() --公共表初始化
	end
	
--msg(string.format("Initialize:%s(%s)", player:getGeneralName(), player:objectName()))	
	local myname = self.player:objectName()
	if sgs.game_start then
		sgs.RevivePlayer(player)
		self.camp = sgs.system_record[myname]
	else
		self.camp = sgs.RegistCamp(self.role, self.player) --自身阵营
		sgs.system_record[myname] = self.camp --AI真实阵营（系统专用）
		local count = sgs.ai_members_count[self.camp] 
		if count then
			sgs.ai_members_count[self.camp] = count + 1
		else
			sgs.ai_members_count[self.camp] = 1
			table.insert(sgs.ai_camps, self.camp)
		end
	end
	self.friends = {self.player}
	self.friends_noself = {}
	self.enemies = {}
	self.unknowns = {}
	self.partners = {self.player}
	self.partners_noself = {}
	self.opponents = {}
	self.neutrals = {}
	if sgs.game_start then
		self.room:setPlayerMark(self.player, "AI_UpdateIntention", 1)
		self:updatePlayers()
		self:choosePartner()
	else
		sgs.ai_relationship[myname] = {}
		sgs.ai_friendly_level[myname] = {}
		sgs.ai_hostile_level[myname] = {}
		sgs.ai_camp_history[myname] = {}
	end
	sgs.card_lack[myname] = {
		["Slash"] = 0,
		["Jink"] = 0,
		["Peach"] = 0,
	}
	sgs.ai_init_count = sgs.ai_init_count + 1
	if not sgs.game_start then
		local count = self.room:alivePlayerCount()
		if sgs.ai_init_count == count then
			InitialRelationship() --角色关系初始化
			sgs.game_start = true
		end
	end
end
--[[****************************************************************
	角色关系判断
]]--****************************************************************
--[[
	功能：获取一名角色的推断阵营
	参数：player（ServerPlayer类型，表示目标角色）
	结果：string类型（camp），表示当前对该角色的阵营推断结果
]]--
function sgs.getCamp(player)
	local name = player:objectName()
	local camp = sgs.ai_camp[name] or "unknown"
	return camp
end
--[[
	功能：判断一名角色是否与另一名角色是战友关系
	参数：target（ServerPlayer类型，表示待判断的目标角色）
		player（ServerPlayer类型，表示用作判断标准的角色）
	结果：boolean类型（true表示是战友关系，false表示非战友关系）
	备注：战友关系是指，两名角色的胜利条件相同且允许与对方共同胜利，比如主公和忠臣间的关系。
		请注意，两名战友关系的角色，在某段时间内也可能同时处于制约关系。
		仅仅是胜利条件相同的两名角色不一定是战友关系，比如双内局的两名内奸。
		当结果为true时，SmartAI:isEnemy(target, player)的结果一定是false。
]]--
function SmartAI:isFriend(target, player)
	if target then
		player = player or self.player
		local targetCamp = sgs.getCamp(target)
		if targetCamp == "unknown" then
			return false
		end
		local playerCamp = sgs.getCamp(player)
		if player:objectName() == self.player:objectName() then
			playerCamp = self.camp
		end
		return targetCamp == playerCamp
	end
	return false
end
--[[
	功能：判断一名角色是否与另一名角色是敌对关系
	参数：target（ServerPlayer类型，表示待判断的目标角色）
		player（ServerPlayer类型，表示用作判断标准的角色）
	结果：boolean类型（true表示是敌对关系，false表示非敌对关系）
	备注：敌对关系是指，两名角色的胜利条件相矛盾，不能与对方共同胜利，比如主公和反贼间的关系。
		请注意，两名敌对关系的角色，也可能在某段时间内处于合作关系，比如主公和内奸。
		当结果为true时，SmartAI:isFriend(target, player)的结果一定是false。
]]--
function SmartAI:isEnemy(target, player)
	if target then
		player = player or self.player
		local targetCamp = sgs.getCamp(target)
		if targetCamp == "unknown" then
			return false
		end
		local playerCamp = sgs.getCamp(player)
		if player:objectName() == self.player:objectName() then
			playerCamp = self.camp
		end
		return targetCamp ~= playerCamp
	end
	return false
end
--[[
	功能：判断一名角色是否是另一名角色的己方成员
	参数：target（ServerPlayer类型，表示待判断的目标角色）
		player（ServerPlayer类型，表示用作判断标准的角色）
	结果：boolean类型（true表示是己方成员，false表示非己方成员）
]]--
function SmartAI:isPartner(target, player)
	if target then
		player = player or self.player
		return sgs.ai_relationship[player:objectName()][target:objectName()] == "partner"
	end
	return false
end
--[[
	功能：判断一名角色是否是另一名角色的敌方成员
	参数：target（ServerPlayer类型，表示待判断的目标角色）
		player（ServerPlayer类型，表示用作判断标准的角色）
	结果：boolean类型（true表示是敌方成员，false表示非敌方成员）
]]--
function SmartAI:isOpponent(target, player)
	if target then
		player = player or self.player
		return sgs.ai_relationship[player:objectName()][target:objectName()] == "opponent"
	end
	return false
end
--[[
	功能：判定一名角色是否对另一名角色持中立态度
	参数：target（ServerPlayer类型，表示待判断的目标角色）
		player（ServerPlayer类型，表示用作判断标准的角色）
	结果：boolean类型（true表示是中立角色，false表示持有立场的角色）
]]--
function SmartAI:isNeutral(target, player)
	if target then
		player = player or self.player
		return sgs.ai_relationship[player:objectName()][target:objectName()] == "neutral"
	end
	return false
end
--[[
	功能：判断一名角色是否与另一名角色是合作关系
	参数：target（ServerPlayer类型，表示待判断的目标角色）
		player（ServerPlayer类型，表示用作判断标准的角色）
	结果：boolean类型（true表示是合作关系，false表示非合作关系）
	备注：合作关系是指，两名原本是非战友关系的角色，出于共同对抗更强大敌方的需求，所形成的暂时的类似战友的关系。
		这意味着，当结果为true时，SmartAI:isFriend(target, player)的结果一定为false。
]]--
function SmartAI:isTempFriend(target, player)
	if self:isPartner(target, player) then
		return not self:isFriend(target, player)
	end
	return false
end
--[[
	功能：判断一名角色是否与另一名角色是制约关系
	参数：target（ServerPlayer类型，表示待判断的目标角色）
		player（ServerPlayer类型，表示用作判断标准的角色）
	结果：boolean类型（true表示是制约关系，false表示非制约关系）
	备注：制约关系是指，两名原本是非敌对关系的角色，由于某种原因，形成的暂时的类似敌对的关系。
		比如在国战模式下，同势力角色本为战友关系；
		但受亮将数目的限制，在本势力足够强大时，同势力暗将与明将间就会形成这种制约关系。
		因此这意味着，当结果为true时，SmartAI:isFriend(target, player)的结果一定为true。
		绝大多数情况下，结果应当是false。
]]--
function SmartAI:isTempEnemy(target, player)
	if self:isOpponent(target, player) then
		return not self:isEnemy(target, player)
	end
	return false
end
--[[
	功能：获取一名角色的己方成员
	参数：player（ServerPlayer类型，表示目标角色）
		targets（sgs.QList<ServerPlayer*>类型，表示所有待选角色列表）
		noself（boolean类型，表示结果中是否包含目标角色）
	结果：table类型（friends），表示所有己方成员
]]--
function SmartAI:getFriends(player, targets, noself)
	player = player or self.player
	targets = targets or self.room:getAlivePlayers()
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p, player) then
			if not noself or p:objectName() ~= player:objectName() then
				table.insert(friends, p)
			end
		end
	end
	return friends
end
--[[
	功能：获取一名角色的对方成员
	参数：player（ServerPlayer类型，表示目标角色）
		targets（sgs.QList<ServerPlayer*>类型，表示所有待选角色列表）
	结果：table类型（enemies），表示所有对方成员
]]--
function SmartAI:getEnemies(player, targets)
	player = player or self.player
	targets = targets or self.room:getAlivePlayers()
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p, player) then
			table.insert(enemies, p)
		end
	end
	return enemies
end
--[[
	功能：获取一名角色的友方成员
	参数：player（ServerPlayer类型，表示目标角色）
		targets（sgs.QList<ServerPlayer*>类型，表示所有待选角色列表）
		noself（boolean类型，表示结果中是否包含目标角色）
	结果：table类型（partners），表示所有友方成员
]]--
function SmartAI:getPartners(player, targets, noself)
	player = player or self.player
	targets = targets or self.room:getAlivePlayers()
	local partners = {}
	local name = player:objectName()
	for _,p in sgs.qlist(targets) do
		local p_name = p:objectName()
		if sgs.ai_relationship[name][p_name] == "partner" then
			if not noself or name ~= p_name then
				table.insert(partners, p)
			end
		end
	end
	return partners
end
--[[
	功能：获取一名角色的敌方成员
	参数：player（ServerPlayer类型，表示目标角色）
		targets（sgs.QList<ServerPlayer*>类型，表示所有待选角色列表）
	结果：table类型（opponents），表示所有敌方成员
]]--
function SmartAI:getOpponents(player, targets)
	player = player or self.player
	targets = targets or self.room:getAlivePlayers()
	local opponents = {}
	local name = player:objectName()
	for _,p in sgs.qlist(targets) do
		if sgs.ai_relationship[name][p:objectName()] == "opponent" then
			table.insert(opponents, p)
		end
	end
	return opponents
end
--[[
	功能：获取一名角色的无关成员
	参数：player（ServerPlayer类型，表示目标角色）
		targets（sgs.QList<ServerPlayer*>类型，表示所有待选角色列表）
	结果：table类型（neutrals），表示所有无关成员
]]--
function SmartAI:getNeutrals(player, targets)
	player = player or self.player
	targets = targets or self.room:getAlivePlayers()
	local neutrals = {}
	local name = player:objectName()
	for _,p in sgs.qlist(targets) do
		local relation = sgs.ai_relationship[name][p:objectName()]
		if not relation or (relation == "neutral") then
			table.insert(neutrals, p)
		end
	end
	return neutrals
end
--[[
	功能：对两名角色间的关系评级
	参数：target（ServerPlayer类型，表示待评级的目标角色）
		player（ServerPlayer类型，表示作为评级标准的角色）
	结果：number类型（level），表示关系等级
]]--
function SmartAI:friendshipLevel(target, player)
	player = player or self.player
	local level = 0
	if self:isPartner(target, player) then
		if self:isFriend(target, player) then
			level = 10
		elseif self:isEnemy(target, player) then
			level = 4
		else
			level = 6
		end
	elseif self:isOpponent(target, player) then
		if self:isEnemy(target, player) then
			level = -10
		elseif self:isFriend(target, player) then
			level = -4
		else
			level = -6
		end
	else
		if self:isFriend(target, player) then
			level = 1
		elseif self:isEnemy(target, player) then
			level = -1
		else
			level = 0
		end
	end
	if self:isPartner(player, target) then
		level = level + 2
	elseif self:isOpponent(player, target) then
		level = level - 2
	end
	return level
end
--[[
	内容：获取最友好的角色
	参数：targets（table类型或sgs.QList<ServerPlayer*>类型，表示考察范围）
		minLevel（number类型，表示关系评级的最低级别）
		maxLevel（number类型，表示关系评级的最高级别）
	结果：table类型（friends），表示所有最友好的角色
]]--
function SmartAI:getPriorFriend(targets, minLevel, maxLevel)
	targets = targets or self.room:getAlivePlayers()
	minLevel = minLevel or -99
	maxLevel = maxLevel or 99
	if type(targets) == "userdata" then
		targets = sgs.QList2Table(targets)
	end
	local levels = {}
	for _,p in ipairs(targets) do
		levels[p] = self:friendshipLevel(p)
	end
	local function compare_func(a, b)
		return levels[a] > levels[b]
	end
	table.sort(targets, compare_func)
	local friends = {}
	local mark = nil
	for _,p in ipairs(targets) do
		local level = levels[p]
		if level < minLevel then
			return friends
		elseif level <= maxLevel then
			if mark then
				if level == mark then
					table.insert(friends, p)
				else
					return friends
				end
			else
				mark = level
				table.insert(friends, p)
			end
		end
	end
	return friends
end
--[[
	内容：获取最敌视的角色
	参数：targets（table类型或sgs.QList<ServerPlayer*>类型，表示考察范围）
		maxLevel（number类型，表示关系评级的最高级别）
		minLevel（number类型，表示关系评级的最低级别）
	结果：table类型（enemies），表示所有最友好的角色
]]--
function SmartAI:getPriorEnemy(targets, maxLevel, minLevel)
	targets = targets or self.room:getAlivePlayers()
	minLevel = minLevel or -99
	maxLevel = maxLevel or 99
	if type(targets) == "userdata" then
		targets = sgs.QList2Table(targets)
	end
	local levels = {}
	for _,p in ipairs(targets) do
		levels[p] = self:friendshipLevel(p)
	end
	local function compare_func(a, b)
		return levels[a] < levels[b]
	end
	table.sort(targets, compare_func)
	local enemies = {}
	local mark = nil
	for _,p in ipairs(targets) do
		local level = levels[p]
		if level > maxLevel then
			return enemies
		elseif level >= minLevel then
			if mark then
				if level == mark then
					table.insert(enemies, p)
				else
					return enemies
				end
			else
				mark = level
				table.insert(enemies, p)
			end
		end
	end
	return enemies
end
--[[****************************************************************
	卡牌转化场景
]]--****************************************************************
--[[
	功能：判断卡牌是否禁止直接使用
	参数：card（Card类型，表示待判断的卡牌）
		player（ServerPlayer类型，表示卡牌的使用者）
	结果：boolean类型，表示是否禁止使用
]]--
function sgs.prohibitUseDirectly(card, player)
	local method = card:getHandlingMethod()
	if player:isCardLimited(card, method) then 
		return true 
	end
	if card:isKindOf("Peach") then
		if player:hasFlag("Global_PreventPeach") then 
			return true 
		end
	end
	return false
end
--[[
	功能：判断卡牌是否受锁定视为技影响
	参数：card（Card类型，表示待判断的卡牌）
		player（ServerPlayer类型，表示拥有锁定视为技的角色）
		place（sgs.Card_Place类型，表示卡牌所在的区域）
	结果：Card类型（vs_card），表示被锁定视为技影响后的卡牌
]]--
function sgs.getFilterViewAsCard(card, player, place)
	local skills = player:getVisibleSkillList(true)
	for _,skill in sgs.qlist(skills) do
		local skillname = skill:objectName()
		local callback = sgs.ai_filterskill_filter[skillname]
		if callback and type(callback) == "function" then
			local filter_str = callback(card, player, place)
			if filter_str then
				local vs_card = sgs.Card_Parse(filter_str)
				if vs_card then
					local method = vs_card:getHandlingMethod()
					if player:isCardLimited(vs_card, method) then
						return vs_card
					end
				end
			end
		end
	end
end
--[[
	功能：获取由视为技产生的用于响应的卡牌
	参数：card（Card类型）
		class_name（string类型，表示需求卡牌的具体类型）
		player（ServerPlayer类型，表示等待响应的角色）
		place（sgs.Card_Place类型）
		toString（boolean类型，表示是否将卡牌字符串作为结果）
	结果：Card类型（vs_card，表示由视为技产生的用于响应的卡牌）或string类型（card_str，表示卡牌字符串）
]]--
function sgs.getViewAsCard(card, class_name, player, place, toString)
	local skills = player:getVisibleSkillList(true)
	for _, skill in sgs.qlist(skills) do
		local skillname = skill:objectName()
		local callback = sgs.ai_view_as[skillname]
		if callback and type(callback) == "function" then
			local card_str = callback(card, player, place, class_name)
			if card_str then
				local vs_card = sgs.Card_Parse(card_str)
				if vs_card and vs_card:isKindOf(class_name) then
					local method = vs_card:getHandlingMethod()
					if not player:isCardLimited(vs_card, method) then
						if toString then
							return card_str
						else
							return vs_card 
						end
					end
				end
			end
		end
	end
end
--[[
	功能：
	参数：self（即表SmartAI）
		class_name（string类型，表示卡牌类型）
		player（ServerPlayer类型，表示目标角色）
	结果：string类型（card_str），表示卡牌使用方式
]]--
function sgs.getValuableViewAsString(self, class_name, player)
	local skills = player:getVisibleSkillList(true)
	for _, skill in sgs.qlist(skills) do
		local skillname = skill:objectName()
		if player:hasSkill(skillname) then
			local callback = sgs.ai_cardsview_valuable[skillname]
			if type(callback) == "function" then
				local card_str = callback(self, class_name, player)
				if card_str then 
					return card_str 
				end
			end
		end
	end
end
--[[
	功能：
	参数：self（即表SmartAI）
		class_name（string类型，表示卡牌类型）
		player（ServerPlayer类型，表示目标角色）
		valuable（boolean类型，表示是否同时考虑sgs.getValuableViewAsString）
	结果：string类型（card_str），表示卡牌使用方式
]]--
function sgs.getViewAsString(self, class_name, player, valuable)
	if valuable then
		local card_str = sgs.getValuableViewAsString(self, class_name, player)
		if card_str then
			return card_str
		end
	end
	local skills = player:getVisibleSkillList(true)
	for _, skill in sgs.qlist(skills) do
		local skillname = skill:objectName()
		if player:hasSkill(skillname) then
			local callback = sgs.ai_cardsview[skillname]
			if type(callback) == "function" then
				local card_str = callback(self, class_name, player)
				if card_str then 
					return card_str 
				end
			end
		end
	end
end
--[[
	功能：判断某张卡牌对一名角色而言是否可以视作目标类型的卡牌
	参数：name（string类型，表示卡牌的类型名）
		card（Card类型，表示待判断的卡牌）
		player（ServerPlayer类型，表示该角色）
	结果：boolean类型，表示是否可以
]]--
function sgs.isCard(name, card, player)
	if card then
		player = player or global_room:getCurrent()
		if name:find(">>") then
			name = name:split(">>")
			name = name[#name]
		end
		local id = card:getEffectiveId()
		local yes = card:isKindOf(name)
		if id > 0 then
			local place = global_room:getCardPlace(id)
			local vs_card = sgs.getFilterViewAsCard(card, player, place)
			if vs_card then
				if not vs_card:isKindOf(name) then
					return false
				end
			end
			if yes then
				return true
			end
			vs_card = sgs.getViewAsCard(card, name, player, place)
			if vs_card then
				return true
			end
			return false
		end
		return yes
	else
		global_room:writeToConsole(debug.traceback())
	end
end
--[[
	功能：随机获取一名角色指定位置的一张卡牌
	参数：who（ServerPlayer类型，表示目标角色）
		flags（string类型，表示指定的卡牌位置）
	结果：number类型，表示卡牌的编号
]]--
function SmartAI:getCardRandomly(who, flags)
	local cards = who:getCards(flags)
	if cards:isEmpty() then 
		return 
	end
	local count = cards:length()
	local r = math.random(0, count-1)
	local card = cards:at(r)
	if who:hasArmorEffect("SilverLion") then
		if self:isOpponent(who) then
			if who:isWounded() then
				if card:getId() == who:getArmor():getId() then
					if r ~= (count-1) then
						card = cards:at(r+1)
					elseif r > 0 then
						card = cards:at(r-1)
					end
				end
			end
		end
	end
	return card:getEffectiveId()
end
--[[
	功能：获取自身指定位置处的特定类型的所有卡牌
	参数：class_name（string类型，表示特定的卡牌类型）
		flag（string类型，表示卡牌的位置标志）
	结果：
]]--
function SmartAI:getCards(class_name, flag)
	local player = self.player
	local private_pile = false
	if not flag then 
		private_pile = true 
	end
	flag = flag or "he"
	local all_cards = player:getCards(flag)
	if private_pile then
		local piles = player:getPileNames()
		for _, key in ipairs(piles) do
			local ids = player:getPile(key)
			for _, id in sgs.qlist(key) do
				local c = sgs.Sanguosha:getCard(id)
				all_cards:append(c)
			end
		end
	end
	local cards = {}
	local place, card_str
	card_str = sgs.getValuableViewAsString(self, class_name, player)
	if card_str then
		card_str = sgs.Card_Parse(card_str)
		table.insert(cards, card_str)
	end
	for _, card in sgs.qlist(all_cards) do
		local id = card:getEffectiveId()
		place = self.room:getCardPlace(id)
		local insert = false
		if class_name == "." then
			if place ~= sgs.Player_PlaceSpecial then
				insert = true
				table.insert(cards, card)
			end
		end
		if not insert then
			if card:isKindOf(class_name) then
				if not sgs.prohibitUseDirectly(card, player) then
					if place ~= sgs.Player_PlaceSpecial then
						insert = true
						table.insert(cards, card)
					end
				end
			end
		end
		if not insert then
			card_str = sgs.getViewAsCard(card, class_name, player, place)
			if card_str then
				table.insert(cards, card_str)
			end
		end
	end
	card_str = sgs.getViewAsString(self, class_name, player, true)
	if card_str then
		card_str = sgs.Card_Parse(card_str)
		table.insert(cards, card_str)
	end
	return cards
end
--[[
	功能：获取蛊惑视为卡牌的具体方式
	参数：class_name（string类型，表示卡牌的类型）
	结果：string类型（card_str），表示蛊惑卡的具体使用方式
]]--
function SmartAI:getGuhuoViewAsCard(class_name)
	local cards = {}
	local Mini48 = ( sgs.current_mode == "_mini_48" )
	if Mini48 then
		local handcards = self.player:getCards("h")
		cards = sgs.QList2Table(handcards)
	else
		cards = self:getCards(class_name, "h")
	end
	local flag = false
	local count = #cards
	if count > 1 then
		flag = true
	elseif count == 1 then
		if Mini48 then
			flag = true
		else
			local suit = cards[1]:getSuit()
			if suit == sgs.Card_Heart then
				flag = true
			end
		end
	end
	if flag then
		local index = 1
		if class_name == "Peach" then
			index = count
		elseif class_name == "Analeptic" then
			local ban_packages = sgs.GetConfig("BanPackages", "")
			if not ban_packages:match("maneuvering") then
				index = count
			end
		elseif class_name == "Jink" then
			index = count
		end
msg(string.format("guhuo:%s", class_name))
		local object_name = sgs.objectName[class_name]
		assert(object_name)
		local card = sgs[object_name]
		assert(card)
		if not self.player:isCardLimited(card, sgs.Card_MethodUse, true) then
			local card_str = "@GuhuoCard=" .. cards[index]:getEffectiveId() .. ":" .. object_name
			return card_str
		end
	end
end
--[[
	功能：获取可用的蛊惑卡使用方式
	参数：class_name（string类型，表示卡牌的类型）
		at_play（boolean类型，表示是否用于出牌阶段）
	结果：string类型，表示蛊惑卡的具体使用方式
]]--
function SmartAI:getGuhuoCard(class_name, at_play)
	local player = self.player
	if player then
		if player:hasSkill("guhuo") then
			if at_play then
				if class_name == "Peach" then
					if not player:isWounded() then
						return nil
					end
				elseif class_name == "Analeptic" then
					if player:hasUsed("Analeptic") then
						return nil
					end
				elseif ("Slash|ThunderSlash|FireSlash"):match(class_name) then
					if not sgs.slash:isAvailable(player) then
						return nil
					end
				elseif class_name == "Jink" then
					return nil
				elseif class_name == "Nullification" then
					return nil
				end
			else
				if class_name == "Peach" then
					if self.player:hasFlag("Global_PreventPeach") then
						return nil
					end
				end
			end
			return self:getGuhuoViewAsCard(class_name)
		end
	end
end
--[[****************************************************************
	特征预测场景
]]--****************************************************************
--[[
	功能：判断一名角色是否等效于装备了诸葛连弩
	参数：player（ServerPlayer类型，表示目标角色）
	结果：boolean类型，表示是否等效
]]--
function SmartAI:hasCrossbowEffect(player)
	player = player or self.player
	if player:hasWeapon("Crossbow") then
		return true
	elseif player:hasSkill("paoxiao") then
		return true
	end
	return false
end
--[[
	功能：获取节命技能嘲讽值
	参数：player（ServerPlayer类型，表示拥有节命技能的角色）
	结果：number类型（value），表示嘲讽值
]]--
function SmartAI:getJiemingChaofeng(player)
	local max_delt = 0
	local value = 0
	local friends = self:getPartners(player)
	for _,friend in ipairs(friends) do
		local maxhp = friend:getMaxHp()
		local num = friend:getHandcardNum()
		local delt = maxhp - num
		delt = math.min(5, delt)
		if delt > max_delt then
			max_delt = delt
		end
	end
	if max_delt < 2 then
		value = 5 - max_delt * 2
	else
		value = 0 - max_delt * 2
	end
	return value
end
--[[
	功能：判断一名角色是否应避免被伤害
	参数：target（ServerPlayer类型，表示伤害目标）
		damage（number类型，表示伤害点数）
		source（ServerPlayer类型，表示伤害来源）
	结果：boolean类型，表示是否应避免
]]--
function SmartAI:cannotBeHurt(target, damage, source)
	source = source or self.player
	damage = damage or 1
	if source:hasSkill("jueqing") then
		return false
	end
	for _,item in pairs(sgs.damage_avoid_system) do
		local skill = item["reason"] or ""
		if self:hasSkills(skill, target) then
			local callback = item["judge_func"]
			if type(callback) == "function" then
				if callback(self, target, damage, source) then
					return true
				end
			end
		end
	end
	return false
end
--[[
	功能：获取一名角色拥有的某种类型卡牌的期望数目
	参数：class_name（string类型，表示指定的卡牌类型）
		player（ServerPlayer类型，表示目标角色）
	结果：number类型，表示卡牌数目
]]--
function sgs.getCardsNum(class_name, player)
	if player then
		local handcards = player:getHandcards()
		local equips = player:getCards("e")
		local data = {
			count = 0, --该类型卡牌数目
			shown = 0, --已知卡牌数目
			unknown = 0, --未知卡牌数目
			EquipCard = 0, --手牌中的装备牌数目
			Peach = 0, --手牌中桃的数目
			Slash = 0, --手牌中杀的数目
			Jink = 0, --手牌中闪的数目
			SlashOrJink = 0, --手牌中杀和闪的总数目
			Black = 0, --所有非此类型卡牌中黑色卡牌的数目
			Red = 0, --所有非此类型卡牌中红色卡牌的数目
			spade = 0, --所有非此类型卡牌中黑桃卡牌的数目
			heart = 0, --所有非此类型卡牌中红心卡牌的数目
			club = 0, --所有非此类型卡牌中草花卡牌的数目
			diamond = 0, --所有非此类型卡牌中方块卡牌的数目
		}
		local current = global_room:getCurrent()
		local my_name = current:objectName()
		local name = player:objectName()
		local visible_flag = string.format("visible_%s_%s", my_name, name)
		for _,card in sgs.qlist(handcards) do
			local isVisible = false
			if card:hasFlag("visible") then
				isVisible = true
			elseif card:hasFlag(visible_flag) then
				isVisible = true
			elseif my_name == name then
				isVisible = true
			end
			if isVisible then
				data["shown"] = data["shown"] + 1
				if card:isKindOf(class_name) then
					data["count"] = data["count"] + 1
				else
					if card:isKindOf("EquipCard") then
						data["EquipCard"] = data["EquipCard"] + 1
					elseif card:isKindOf("Slash") then
						data["Slash"] = data["Slash"] + 1
					elseif card:isKindOf("Jink") then
						data["Jink"] = data["Jink"] + 1
					end
					local suit = card:getSuit()
					if suit == sgs.Card_Spade then
						data["spade"] = data["spade"] + 1
					elseif suit == sgs.Card_Heart then
						data["heart"] = data["heart"] + 1
					elseif suit == sgs.Card_Club then
						data["club"] = data["club"] + 1
					elseif suit == sgs.Card_Diamond then
						data["diamond"] = data["diamond"] + 1
					end
				end
			end
		end
		data["SlashOrJink"] = data["Slash"] + data["Jink"]
		data["unknown"] = player:getHandcardNum() - data["shown"]
		for _,equip in sgs.qlist(equips) do
			if not equip:isKindOf(class_name) then
				local suit = equip:getSuit()
				if suit == sgs.Card_Spade then
					data["spade"] = data["spade"] + 1
				elseif suit == sgs.Card_Heart then
					data["heart"] = data["heart"] + 1
				elseif suit == sgs.Card_Club then
					data["club"] = data["club"] + 1
				elseif suit == sgs.Card_Diamond then
					data["diamond"] = data["diamond"] + 1
				end
			end
		end
		data["Red"] = data["heart"] + data["diamond"]
		data["Black"] = data["spade"] + data["club"]
		local flag = false
		local count = nil
		for _,item in pairs(sgs.card_count_system) do
			if flag then
				break
			end
			if item["pattern"] == class_name then
				local callback = item["statistics_func"]
				if type(callback) == "function" then
					count = callback(class_name, player, data) 
					if count ~= nil then
						flag = true
					end
				end
			end
		end
		data["flag"] = flag --已经过技能统计
		data["already"] = count --统计结果
		local item = sgs.card_count_system["gamerule"] --系统最后统计
		local callback = item["statistics_func"]
		return callback(class_name, player, data)
	else
		global_room:writeToConsole(debug.traceback()) 
		return 0
	end
end
--[[
	功能：获取一名角色指定位置处的特定类型卡牌的数目
	参数：class_name（string类型，表示指定的卡牌类型）
		player（ServerPlayer类型，表示目标角色）
		flag（string类型，表示卡牌位置范围）
		myself（boolean类型，表示是否不考虑该角色所有友方角色的影响）
	结果：number类型（count），表示卡牌数目
]]--
function SmartAI:getCardsNum(class_name, player, flag, myself)
	player = player or self.player
	local count = 0
	if type(class_name) == "table" then
		for _, each_class in ipairs(class_name) do
			local n = self:getCardsNum(each_class, player, flag, teamwork)
			count = count + n
		end
		return count
	end
	local cards = self:getCards(class_name, flag)
	count = #cards
	local card_str = sgs.getViewAsString(self, class_name, player, true)
	if card_str then
		local card = sgs.Card_Parse(card_str)
		local skillname = card:getSkillName()
		if skillname == "Spear" or skillname == "fuhun" then
			local num = player:getHandcardNum()
			count = count + math.floor(num / 2) - 1
		elseif skillname == "jiuzhu" then
			local num = player:getCardCount(true)
			local hp = player:getHp()
			num = math.min(num, hp-1)
			num = math.max(num, 0)
			count = math.max(num, count)
		elseif skillname == "chunlao" then
			local wines = player:getPile("wine")
			local num = wines:length()
			count = count + num - 1
		elseif skillname == "renxin" then
			count = count + 1
		end
	end
	if not myself then
		if class_name == "Jink" then
			if player:hasLordSkill("hujia") then
				local lieges = self.room:getLieges("wei", player)
				for _, liege in sgs.qlist(lieges) do
					if self:isPartner(liege, player) then
						local also = liege:hasLordSkill("hujia")
						local num = self:getCardsNum("Jink", liege, nil, also)
						count = count + num
					end
				end
			end
		elseif class_name == "Slash" then
			if player:hasSkill("wushuang") then
				count = count * 2
			end
			if player:hasLordSkill("jijiang") then
				local lieges = self.room:getLieges("shu", player)
				for _, liege in sgs.qlist(lieges) do
					if self:isPartner(liege, player) then
						local also = liege:hasLordSkill("jijiang")
						local num = self:getCardsNum("Slash", liege, nil, also)
						count = count + num
					end
				end
			end
		end
	end
	return count
end
--[[
	功能：获取一名角色使用某类卡牌的距离限制
	参数：card（Card类型，表示将使用的卡牌）
		source（ServerPlayer类型，表示使用卡牌的角色）
	结果：number类型，表示距离限制
]]--
function SmartAI:getDistanceLimit(card, source)
	source = source or self.player
	if card:getSkillName() ~= "qiaoshui" then
		if sgs.isKindOf("Snatch|SupplyShortage", card) then
			local correct = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, source, card)
			return 1 + correct
		end
	end
end
--[[
	功能：获取一组角色名单中不能成为指定卡牌的目标的所有角色
	参数：players（table类型或sgs.QList<ServerPlayer*>类型，表示所有考察的目标角色）
		card（Card类型，表示指定的卡牌）
		source（ServerPlayer类型，表示卡牌的使用者）
	结果：table类型（excluded），表示所有被排除的角色
]]--
function SmartAI:exclude(players, card, source)
	source = source or self.player
	local excluded = {}
	local limit = self:getDistanceLimit(card, source)
	local range_fix = 0
	if type(players) ~= "table" then 
		players = sgs.QList2Table(players) 
	end	
	if card:isVirtualCard() then
		local horse = source:getOffensiveHorse()
		if horse then
			local subcards = card:getSubcards()
			for _,id in sgs.qlist(subcards) do
				if horse:getEffectiveId() == id then 
					range_fix = range_fix + 1 
				end
			end
		end
		if card:getSkillName() == "jixi" then 
			range_fix = range_fix + 1 
		end
	end
	for _,player in ipairs(players) do
		if not self.room:isProhibited(source, player, card) then
			local should_insert = true
			if limit then
				local dist = source:distanceTo(player, range_fix)
				should_insert = ( dist <= limit )
			end
			if should_insert then
				table.insert(excluded, player)
			end
		end
	end
	return excluded
end
--[[
	功能：判断一名角色是否体力上佳
	参数：player（ServerPlayer类型，表示目标角色）
	结果：boolean类型，表示是否上佳
]]--
function sgs.isGoodHp(player)
	local hp = player:getHp()
	local good = false
	if hp > 1 then
		good = true
	elseif sgs.getCardsNum("Peach", player) >= 1 then
		good = true
	elseif sgs.getCardsNum("Analeptic", player) >= 1 then
		good = true
	end
	if not good then
		if player:hasSkill("buqu") then
			local buqus = player:getPile("buqu")
			if buqus:length() <= 4 then
				good = true
			end
		end
	end
	if not good then
		if player:hasSkill("niepan") then
			if player:getMark("@nirvana") > 0 then
				good = true
			end
		end
	end
	if not good then
		if player:hasSkill("fuli") then
			if player:getMark("@laoji") > 0 then
				good = true
			end
		end
	end
	if good then
		return true
	end
	local others = global_room:getOtherPlayers(player)
	local current = global_room:getCurrent()
	local mycamp = sgs.ai_camp[player:objectName()]
	if not current:hasSkill("wansha") then
		for _,p in sgs.qlist(others) do
			if sgs.ai_camp[p:objectName()] == mycamp then
				if sgs.getCardsNum("Peach", p) > 0 then
					return true
				end
			end
		end
	end
	return false
end
--[[
	功能：判断一名角色是否在所有考察范围内的角色中最适合成分攻击目标
	参数：self（即表SmartAI）
		target（ServerPlayer类型，表示目标角色）
		players（table类型，表示所有考察目标）
		isSlash（boolean类型，表示是否用杀进行攻击）
	结果：boolean类型，表示是否合适
]]--
function sgs.isGoodTarget(self, target, players, isSlash)
	if type(players) == "table" then
		if #players == 1 then 
			return true 
		end
		local found = false
		for _,p in ipairs(players) do
			if not self:cannotBeHurt(p) then
				if sgs.isGoodTarget(self, p) then
					found = true
					break
				end
			end
		end
		if not found then
			return true
		end
	end
	local arr = {
		"jieming", 
		"yiji", 
		"guixin", 
		"fangzhu", 
		"neoganglie", 
		"nosmiji", 
		"xuehen", 
		"xueji"
	}
	local m_skill = false
	local attacker = global_room:getCurrent()
	for _,masochism in ipairs(arr) do
		if target:hasSkill(masochism) then
			if masochism == "nosmiji" and target:isWounded() then 
				m_skill = false
			elseif masochism == "xueji" and target:isWounded() then 
				m_skill = false
			elseif attacker and attacker:hasSkill("jueqing") then 
				m_skill = false
			elseif masochism == "jieming" and self and self:getJiemingChaofeng(target) > -4 then 
				m_skill = false
			elseif masochism == "yiji" and self and not self:hasPartners("draw", target) then 
				m_skill = false
			else
				m_skill = true
				break
			end
		end
	end
	local function isLord(p)
		for _,lord in ipairs(sgs.ai_lords) do
			if p:objectName() == lord then
				return true
			end
		end
		return false
	end
	local amLord = isLord(target)
	if not amLord then
		if not attacker:hasSkill("jueqing") then
			if target:hasSkill("huilei") then
				if target:getHp() == 1 then
					if attacker:getHandcardNum() >= 4 then 
						return false 
					end
					local camp = sgs.ai_camp[target:objectName()] or ""
					return string.find(camp, "rebel")
				end
			end
			if target:hasSkill("wuhun") then
				if not attacker:hasSkill("jueqing") then
					if isLord(attacker) then
						return false
					elseif target:getHp() <= 2 then
						return false
					end
				end
			end
		end
	end
	if target:hasLordSkill("shichou") then
		if target:getMark("@hate") == 0 then
			local others = global_room:getOtherPlayers(target)
			for _,p in sgs.qlist(others) do
				local mark = "hate_"..target:objectName()
				if p:getMark(mark) > 0 then
					if p:getMark("@hate_to") > 0 then
						return false
					end
				end
			end
		end
	end
	if isSlash then
		if self then
			if self:getCardsNum("Slash") > target:getHp() then
				if self:hasCrossbowEffect() then
					return true
				elseif self:getCardsNum("Crossbow") > 0 then
					return true
				end
			end
		end
	end
	if target:hasSkill("hunzi") then
		if target:getMark("hunzi") == 0 then
			if amLord then
				if target:getHp() == 2 then
					if self:countLoyalist() > 0 then
						return false
					end
				end
			end
		end
	end
	if m_skill then
		if sgs.isGoodHp(target) then
			return false
		end
	end
	return true
end
--[[
	功能：判断一名角色是否虚弱
	参数：player（ServerPlayer类型，表示待判断的目标角色）
	结果：boolean类型，表示是否虚弱
]]--
function SmartAI:isWeak(player)
	player = player or self.player
	--不屈
	if player:hasSkill("buqu") then
		local buqus = player:getPile("buqu")
		if buqus:length() < 4 then
			return false
		end
	end
	--龙魂
	if player:hasSkill("longhun") then
		local cards = player:getCards("he")
		if cards:length() > 2 then
			return false
		end
	end
	--魂姿
	if player:hasSkill("hunzi") then
		if player:getMark("hunzi") == 0 then
			if player:getHp() > 1 then
				return false
			end
		end
	end
	--一般情形
	local hp = player:getHp()
	local num = player:getHandcardNum() 
	if hp <= 1 then
		return true
	elseif hp <= 2 then
		return num <= 2
	end
	return false
end
--[[****************************************************************
	角色属性计算
]]--****************************************************************
--[[
	功能：计算一名角色的综合存在感
	参数：player（Player类型，表示目标角色）
	结果：number类型（value），表示角色价值
]]--
function sgs.getValue(player)
	if player then
		local hp = player:getHp()
		local num = player:getHandcardNum()
		local value = hp * 2 + num
		return value
	else
		global_room:writeToConsole(debug.traceback())
		return 0
	end
end
--[[
	功能：计算一名角色的防御的能力
	参数：player（Player类型，表示目标角色）
	结果：number类型（defense），表示角色的防御水平数值
]]--
function sgs.getDefense(player)
	if player then
		local hp = player:getHp() 
		local value = sgs.getValue(player)
		local defense = math.min(value, hp * 3)
		local attacker = global_room:getCurrent() --current
		local armor = player:getArmor()
		if armor then
			defense = defense + 2
		elseif player:hasSkill("yizhong") then
			defense = defense + 2
		end
		local hasEightDiagram = false
		if player:hasArmorEffect("EightDiagram") then
			hasEightDiagram = true
		elseif player:hasSkill("bazhen") then
			if not armor then
				hasEightDiagram = true
			end
		end
		if hasEightDiagram then
			defense = defense + 1.3
			if player:hasSkill("tiandu") then 
				defense = defense + 0.6 
			end
			if player:hasSkill("gushou") then 
				defense = defense + 0.4 
			end
			if player:hasSkill("leiji") then 
				defense = defense + 0.4 
			end
			if player:hasSkill("noszhenlie") then 
				defense = defense + 0.2 
			end
			if player:hasSkill("hongyan") then 
				defense = defense + 0.2 
			end
		end
		local num = player:getHandcardNum()
		if player:hasSkills("tuntian+zaoxian") then 
			defense = defense + num * 0.4 
		end
		if player:hasSkill("aocai") then
			if player:getPhase() == sgs.Player_NotActive then 
				defense = defense + 0.3 
			end
		end
		if attacker then
			if not attacker:hasSkill("jueqing") then
				if sgs.isGoodHp(player) then
					local mskills = sgs.masochism_skill:split("|")
					for _, masochism in ipairs(mskills) do
						if player:hasSkill(masochism) then
							defense = defense + 1
						end
					end
				end
				if player:getMark("@tied") > 0 then 
					defense = defense + 1 
				end
				if player:hasSkill("jieming") then 
					defense = defense + 4 
				end
				if player:hasSkill("yiji") then 
					defense = defense + 4 
				end
				if player:hasSkill("guixin") then 
					defense = defense + 4 
				end
				if player:hasSkill("yuce") then 
					defense = defense + 2 
				end
			end
		end
		if not sgs.isGoodTarget(nil, player) then 
			defense = defense + 10 
		end
		if player:hasSkills("rende|nosrende") and hp > 2 then 
			defense = defense + 1 
		end
		if player:hasSkill("kuanggu") and hp > 1 then 
			defense = defense + 0.2 
		end
		if player:hasSkill("zaiqi") and hp > 1 then 
			defense = defense + 0.35 
		end
		if player:hasSkill("tianming") then 
			defense = defense + 0.1 
		end
		if hp > sgs.getBestHp(player) then 
			defense = defense + 0.8 
		end
		if hp <= 2 then 
			defense = defense - 0.4 
		end
		if player:hasSkill("tianxiang") then 
			defense = defense + num * 0.5 
		end
		if num == 0 then
			if hp <= 1 then 
				defense = defense - 2.5 
			elseif hp == 2 then 
				defense = defense - 1.5 
			end
			if not hasEightDiagram then 
				defense = defense - 2 
			end
		end
		local isLord = false
		for _,lordname in ipairs(sgs.ai_lords) do
			if lordname == player:objectName() then
				isLord = true
				break
			end
		end
		if isLord then
			defense = defense - 0.4
			-- if sgs.isInDanger(player) then --stack overflow
				-- defense = defense - 0.7 
			-- end
		end
		local chaofeng = sgs.ai_chaofeng[player:getGeneralName()] or 0
		if chaofeng >= 3 then
			defense = defense - math.max(6, chaofeng) * 0.035
		end
		if not player:faceUp() then 
			defense = defense - 0.35 
		end
		if not player:containsTrick("YanxiaoCard") then
			if player:containsTrick("indullgence") then
				defense = defense - 0.15
			end
			if player:containsTrick("supply_shortage") then
				defense = defense - 0.15
			end
		end
		if not hasEightDiagram then
			if player:hasSkill("jijiu") then 
				defense = defense - 3 
			end
			if player:hasSkill("dimeng") then 
				defense = defense - 2.5 
			end
			if player:hasSkill("guzheng") then
				if sgs.getKnownCard(player, "Jink", true) == 0 then 
					defense = defense - 2.5 
				end
			end
			if player:hasSkill("qiaobian") then 
				defense = defense - 2.4 
			end
			if player:hasSkill("jieyin") then 
				defense = defense - 2.3 
			end
			if player:hasSkills("noslijian|lijian") then 
				defense = defense - 2.2 
			end
			if player:hasSkill("nosmiji") then
				if player:isWounded() then 
					defense = defense - 1.5 
				end
			end
			if player:hasSkill("xiliang") then
				if sgs.getKnownCard(player, "Jink", true) == 0 then 
					defense = defense - 2 
				end
			end
			if player:hasSkill("shouye") then 
				defense = defense - 2 
			end
		end
		return defense
	else
		global_room:writeToConsole(debug.traceback())
	end
end
--[[
	功能：计算一名角色的嘲讽度
	参数：player（Player类型，表示目标角色）
	结果：number类型（chaofeng），表示角色的嘲讽度
]]--
function sgs.getChaofeng(player)
	local name = player:getGeneralName()
	local chaofeng = sgs.ai_chaofeng[name] or 0
	return chaofeng
end
--[[
	功能：计算一名角色的威胁值
	参数：player（Player类型，表示目标角色）
	结果：number类型（threat），表示角色的威胁值
]]--
function sgs.getThreat(player)
	local others = global_room:getOtherPlayers(player)
	local threat = player:getHandcardNum()
	for _,p in sgs.qlist(others) do
		if player:canSlash(p) then
			local defense = sgs.getDefense(p)
			threat = threat + 10 / defense
		end
	end
	local chaofeng = sgs.getChaofeng(player)
	threat = threat + chaofeng / 2
	return threat
end
--[[
	内容：比较函数表
]]--
--按存在感比较
sgs.ai_compare_funcs["value"] = function(a, b)
	local valueA = sgs.getValue(a)
	local valueB = sgs.getValue(b)
	return valueA < valueB
end
--按角色防御能力比较
sgs.ai_compare_funcs["defense"] = function(a, b)
	local defenseA = sgs.getDefense(a)
	local defenseB = sgs.getDefense(b)
	return defenseA < defenseB
end
--按体力值比较
sgs.ai_compare_funcs["hp"] = function(a, b)
	local hpA = a:getHp()
	local hpB = b:getHp()
	if hpA == hpB then
		return sgs.ai_compare_funcs["defense"](a, b)
	else
		return hpA < hpB
	end
end
--按手牌数目比较
sgs.ai_compare_funcs["handcard"] = function(a, b)
	local numA = a:getHandcardNum()
	local numB = b:getHandcardNum()
	if numA == numB then
		return sgs.ai_compare_funcs["defense"](a, b)
	else
		return numA < numB
	end
end
--按武将嘲讽度比较
sgs.ai_compare_funcs["chaofeng"] = function(a, b)
	local chaofengA = sgs.ai_chaofeng[a:getGeneralName()] or 0
	local chaofengB = sgs.ai_chaofeng[b:getGeneralName()] or 0
	if chaofengA == chaofengB then
		return sgs.ai_compare_funcs["value"](a, b)
	else
		return chaofengA > chaofengB
	end
end
--按角色的威胁程度比较
sgs.ai_compare_funcs["threat"] = function(a, b)
	local threatA = sgs.getThreat(a)
	local threatB = sgs.getThreat(b)
	return threatA > threatB
end
--[[
	功能：对指定的一些角色按一定的标准进行排序
	参数：players（table类型，表示待排序的所有角色）
		key（string类型，表示排序的标准）
	结果：无（players被改变）
]]--
function SmartAI:sort(players, key)
	if players then
		if #players > 0 then
			local function _sort(players, key)
				key = key or "defense"
				local func = sgs.ai_compare_funcs[key]
				table.sort(players, func)
			end
			if not pcall(_sort, players, key) then 
				self.room:writeToConsole(debug.traceback()) 
			end
		end
	else
		self.room:writeToConsole(debug.traceback())
	end
end
--[[****************************************************************
	角色身份判断
]]--****************************************************************
--[[
	功能：判断自己是否相当于主公
	参数：无
	结果：boolean类型，表示是否相当
	备注：相当于主公，意味着自己阵亡后游戏立即结束。
]]--
function SmartAI:amLord()
	local myname = self.player:objectName()
	return sgs.ai_lord[myname] == myname
end
--[[
	功能：判断自己是否相当于忠臣
	参数：无
	结果：boolean类型，表示是否相当
	备注：相当于忠臣，意味着自己阵亡后，若凶手为本方主公，其弃置所有手牌和装备。
]]--
function SmartAI:amLoyalist()
	local myname = self.player:objectName()
	local lord = sgs.ai_lord[myname]
	if lord then
		if lord ~= myname then
			return true
		end
	end
	return false
end
--[[
	功能：判断自己是否相当于内奸
	参数：无
	结果：boolean类型，表示是否相当
]]--
function SmartAI:amRenegade()
	return string.find(self.camp, "renegade")
end
--[[
	功能：判断自己是否相当于反贼
	参数：无
	结果：boolean类型，表示是否相当
	备注：相当于反贼，意味着自己阵亡，凶手可以摸三张牌。
]]--
function SmartAI:amRebel()
	return string.find(self.camp, "rebel")
end
--[[
	功能：判断一名角色是否相当于主公
	参数：player（ServerPlayer类型，表示目标角色）
	结果：boolean类型，表示是否相当
]]--
function SmartAI:mayLord(player)
	player = player or self.player
	local name = player:objectName()
	for _,lord in ipairs(sgs.ai_lords) do
		if lord == name then
			return true
		end
	end
	return false
end
--[[
	功能：判断一名角色是否相当于忠臣
	参数：player（ServerPlayer类型，表示目标角色）
	结果：boolean类型，表示是否相当
]]--
function SmartAI:mayLoyalist(player)
	player = player or self.player
	local name = player:objectName()
	if name == self.player:objectName() then
		return self:amLoyalist()
	end
	if self:mayLord(player) then
		return false
	end
	local camp = sgs.ai_camp[name] or ""
	return string.find(camp, "loyal")
end
--[[
	功能：判断一名角色是否相当于内奸
	参数：player（ServerPlayer类型，表示目标角色）
	结果：boolean类型，表示是否相当
]]--
function SmartAI:mayRenegade(player)
	player = player or self.player
	local name = player:objectName()
	if name == self.player:objectName() then
		return self:amRenegade() 
	end
	local camp = sgs.ai_camp[name] or ""
	return string.find(camp, "renegade")
end
--[[
	功能：判断一名角色是否相当于反贼
	参数：player（ServerPlayer类型，表示目标角色）
	结果：boolean类型，表示是否相当
]]--
function SmartAI:mayRebel(player)
	player = player or self.player
	local name = player:objectName()
	if name == self.player:objectName() then
		return self:amRebel()
	end
	local camp = sgs.ai_camp[name] or ""
	return string.find(camp, "rebel")
end
--[[
	功能：获取存活的相当于忠臣的角色数目
	参数：players（sgs.QList<ServerPlayer*>类型，表示所有待考察的目标角色）
	结果：number类型（count），表示角色数目
]]--
function SmartAI:countLoyalist(players)
	players = players or self.room:getAlivePlayers()
	local count = 0
	for _,p in sgs.qlist(players) do
		if self:mayLoyalist(p) then
			count = count + 1
		end
	end
	return count
end
--[[
	功能：获取存活的相当于内奸的角色数目
	参数：players（sgs.QList<ServerPlayer*>类型，表示所有待考察的目标角色）
	结果：number类型（count），表示角色数目
]]--
function SmartAI:countRenegade(players)
	players = players or self.room:getAlivePlayers()
	local count = 0
	for _,p in sgs.qlist(players) do
		if self:mayRenegade(p) then
			count = count + 1
		end
	end
	return count
end
--[[
	功能：获取存活的相当于反贼的角色数目
	参数：players（sgs.QList<ServerPlayer*>类型，表示所有待考察的目标角色）
	结果：number类型（count），表示角色数目
]]--
function SmartAI:countRebel(players)
	players = players or self.room:getAlivePlayers()
	local count = 0
	for _,p in sgs.qlist(players) do
		if self:mayRebel(p) then
			count = count + 1
		end
	end
	return count
end
--[[
	功能：获取本方领袖角色
	参数：player（ServerPlayer类型，表示目标角色）
	结果：ServerPlayer类型（lord），表示领袖角色
]]--
function SmartAI:getMyLord(player)
	player = player or self.player
	local name = player:objectName()
	local lordname = sgs.ai_lord[name]
	if lordname then
		local lord = findPlayerByObjectName(self.room, lordname)
		return lord
	end
	return nil
end
--[[
	功能：获取所有领袖角色
	参数：无
	结果：table类型，表示所有领袖角色
]]--
function SmartAI:getLords()
	local lords = {}
	for _,lordname in ipairs(sgs.ai_lords) do
		local lord = findPlayerByObjectName(self.room, lordname)
		table.insert(lords, lord)
	end
	return lords
end
--[[
	功能：获取一个阵营中的所有已知角色
	参数：camp（string类型，表示阵营名）
	结果：table类型（members），表示该阵营中的所有角色
]]--
function sgs.getCampMembers(camp)
	local alives = global_room:getAlivePlayers()
	local members = {}
	for _,p in sgs.qlist(alives) do
		local name = p:objectName()
		if sgs.ai_camp[name] == camp then
			table.insert(members, p)
		end
	end
	return members
end
--[[
	功能：获取一个阵营中所有已知角色的数目
	参数：camp（string类型，表示阵营名）
	结果：number类型（count），表示该阵营中的所有角色数目
]]--
function sgs.getCampMemberCount(camp)
	local alives = global_room:getAlivePlayers()
	local count = 0
	for _,p in sgs.qlist(alives) do
		if sgs.ai_camp[p:objectName()] == camp then
			count = count + 1
		end
	end
	return count
end
--[[
	功能：获取防御水平最强的阵营
	参数：无
	结果：string类型（maxcamp），表示最强阵营名
]]--
function sgs.getMaxDefenseCamp()
	local defense_table = {}
	local mem_count = {}
	for _,camp in ipairs(sgs.ai_camps) do
		defense_table[camp] = 0
		mem_count[camp] = 0
	end
	local alives = global_room:getAlivePlayers()
	for _,p in sgs.qlist(alives) do
		local camp = sgs.getCamp(p)
		if camp ~= "unknown" then
			local defense = sgs.getDefense(p)
			if sgs.ai_lord[p:objectName()] == p:objectName() then
				defense = defense * 0.8
			end
			defense_table[camp] = defense_table[camp] + defense
			mem_count[camp] = mem_count[camp] + 1
		end
	end
	for _,camp in ipairs(sgs.ai_camps) do
		if mem_count[camp] == 0 then
			mem_count[camp] = 1
		end
		local average = defense_table[camp] / mem_count[camp]
		local count = sgs.ai_members_count[camp]
		if count < 0 then
			count = mem_count[camp]
		end
		defense_table[camp] = average * count
	end
	local maxcamp = "unknown"
	local maxdefense = 0
	for camp, defense in pairs(defense_table) do
		if defense > maxdefense then
			maxdefense = defense
			maxcamp = camp
		end
	end	
	return maxcamp
end
--[[
	功能：获取对指定阵营的评估报告
	参数：camp（string类型，表示阵营名）
	结果：table类型（report），表示评估报告表
]]--
function sgs.CreateCampReport(camp)
	local report = {}
	report["name"] = camp --阵营名
	report["members"] = sgs.getCampMembers(camp) --本阵营所有成员
	report["count"] = sgs.ai_members_count[camp] --本阵营当前应有成员数目
	report["known_count"] = #report["members"] --已出现的本阵营成员数目
	if report["known_count"] > 0 then
		local player = report["members"][1]
		report["lord"] = sgs.ai_lord[player:objectName()] --阵营领袖
		local defense = 0
		for _,member in ipairs(report["members"]) do
			local m_defense = sgs.getDefense(member)
			defense = defense + m_defense
		end
		report["defense"] = defense --整体防御力
	else
		report["lord"] = nil
		report["defense"] = 0
	end
	return report
end
--[[
	功能：清理阵营信息
	参数：无
	结果：无
]]--
function sgs.CampStandardization()
	for index, camp in ipairs(sgs.ai_camps) do
		local count = sgs.ai_members_count[camp]
		if not count or (count == 0) then
			table.insert(sgs.ai_destoryed_camps, camp)
			table.remove(sgs.ai_camps, index)
		end
	end
	for index, camp in ipairs(sgs.ai_destoryed_camps) do
		local count = sgs.ai_members_count[camp]
		if count and (count ~= 0) then
			table.insert(sgs.ai_camps, camp)
			table.remove(sgs.ai_destoryed_camps, index)
		end
	end
end
--[[
	功能：复活角色
	参数：player（ServerPlayer类型，表示新加入的角色）
	结果：无
]]--
function sgs.RevivePlayer(player)
	local name = player:objectName() --角色对象名
	local role = player:getRole() --角色身份
	local camp = sgs.system_record[name] --利用真实阵营复活
	if not camp then --如果属于新加入的角色
		camp = sgs.RegistCamp(role, player) --注册阵营
		sgs.system_record[name] = camp --记录真实阵营
		if sgs.role_predictable then --如果开启了身份预知
			sgs.ai_camp[name] = camp --写入AI推定阵营
		end
	else --如果只是复活
		sgs.ai_camp[name] = camp --AI推定阵营（因为复活时身份是确定的，所以不再推定，直接写入真实阵营）
	end
	--更新该阵营成员数
	local count = sgs.ai_members_count[camp] 
	if count then
		sgs.ai_members_count[camp] = count + 1 
	else
		sgs.ai_members_count[camp] = 1
		if not sgs.ai_camps[camp] then
			table.insert(sgs.ai_camps, camp)
		end
	end
end
--[[
	功能：去除角色
	参数：player（ServerPlayer类型，表示被去除的角色）
	结果：无
	备注：考虑到之后可能出现的复活、换将等问题，
		这里保留了sgs.system_record中的内容，
		只是清除了作为外界推断结果的sgs.ai_camp。
]]--
function sgs.RemovePlayer(player)
	local name = player:objectName()
	sgs.ai_camp[name] = nil --清除对该角色的阵营评定
	local camp = sgs.system_record[name] --提取其真实阵营
	local count = sgs.ai_members_count[camp] --更新该阵营角色数目
	assert(count)
	sgs.ai_members_count[camp] = count - 1
	sgs.ai_relationship[name] = {} --清空该角色的关系策略
	sgs.CampStandardization() --清理阵营信息
end
--[[
	功能：交换两名角色的身份（焚心专用）
	参数：playerA（ServerPlayer类型，表示被改换身份的角色）
		playerB（ServerPlayer类型，表示另一名被改换身份的角色）
	结果：无
]]--
function sgs.ExchangePlayerRole(playerA, playerB)
	--交换阵营评定
	local nameA = playerA:objectName()
	local nameB = playerB:objectName()
	local campA = sgs.getCamp(playerA)
	local campB = sgs.getCamp(playerB)
	sgs.ai_camp[nameA] = campB
	sgs.ai_camp[nameB] = campA
	local temp = sgs.system_record[nameA]
	sgs.system_record[nameA] = sgs.system_record[nameB]
	sgs.system_record[nameB] = temp
	--交换角色关系策略
	local alives = global_room:getAlivePlayers()
	for _,p in sgs.qlist(alives) do
		local name = p:objectName()
		local temp = sgs.ai_relationship[p][nameA]
		sgs.ai_relationship[p][nameA] = sgs.ai_relationship[p][nameB]
		sgs.ai_relationship[p][nameB] = temp
	end
	--交换身份
	local roleA = playerA:getRole()
	local roleB = playerB:getRole()
	local flagA = "AI_ModifyRoleTo:"..roleB
	local flagB = "AI_ModifyRoleTo:"..roleA
	global_room:setPlayerFlag(playerA, flagA)
	global_room:setPlayerFlag(playerB, flagB)
	global_room:setPlayerMark(playerA, "AI_ModifyRole", 1)
	global_room:setPlayerMark(playerB, "AI_ModifyRole", 1)
end
--[[
	功能：重置角色阵营信息
	参数：无
	结果：无
]]--
function SmartAI:ResetPlayerCamp()
	if self.player:getMark("AI_ResetPlayerCamp") > 0 then
		self.room:setPlayerMark(self.player, "AI_ResetPlayerCamp", 0)
		self.role = self.player:getRole() --自身身份
		self.camp = sgs.system_record[self.player:objectName()] --自身阵营
		self.room:setPlayerMark(self.player, "AI_UpdateIntention", 1)
		self:updatePlayers() --更新角色身份关系
		self:choosePartner() --更新角色关系策略
	end
end
--[[
	功能：更新局势信息
	参数：无
	结果：无
	备注：这里只是从宏观上把所有阵营sgs.ai_camps重置了，
		并根据实际情况更新了每名角色的真实阵营sgs.system_record，
		以及各阵营角色数sgs.ai_members_count。
		但是记录每名角色推定阵营的sgs.ai_camp并没有改变（这个表决定了isFriend等关系），
		角色间关系sgs.ai_relationship也没有改变（这个表决定了isPartner等关系）。
]]--
function sgs.updateAlivePlayers()
--msg("updateAlivePlayers")
	local alives = global_room:getAlivePlayers()
	sgs.ai_camps = {} 
	sgs.ai_members_count = {}
	sgs.renegade_count = 0 --重置内奸数目，否则会影响下面用到的sgs.RegistCamp
	for _,p in sgs.qlist(alives) do
		local role = p:getRole() --角色身份
		local camp = sgs.RegistCamp(role, p) --重新注册阵营
		sgs.system_record[p:objectName()] = camp --重置角色真实阵营
		local count = sgs.ai_members_count[camp]  --更新阵营角色数目
		if count then
			sgs.ai_members_count[camp] = count + 1
		else
			sgs.ai_members_count[camp] = 1
			table.insert(sgs.ai_camps, camp) --添加新阵营
		end
	end
	for _,p in sgs.qlist(alives) do
		global_room:setPlayerMark(p, "AI_ResetPlayerCamp", 1)
	end
end
--[[
	功能：阵营排序函数
]]--
sgs.SortCampsBy = {
	defense = function(inverse)
		sgs.defense_table = {}
		for _,camp in ipairs(sgs.ai_camps) do
			local report = sgs.CreateCampReport(camp)
			sgs.defense_table[camp] = report["defense"] or 0
		end
		local compare_func = function(campA, campB)
			local defenseA = sgs.defense_table[campA]
			local defenseB = sgs.defense_table[campB]
			if inverse then
				return defenseA > defenseB
			else
				return defenseA < defenseB
			end
		end
		table.sort(sgs.ai_camps, compare_func)
	end,
	members_count = function(inverse)
		sgs.m_count_table = {}
		for _,camp in ipairs(sgs.ai_camps) do
			local members = sgs.getCampMembers(camp)
			sgs.m_count_table[camp] = #members
		end
		local compare_func = function(campA, campB)
			local countA = sgs.m_count_table[campA]
			local countB = sgs.m_count_table[campB]
			if inverse then
				return countA > countB
			else
				return countA < countB
			end
		end
		table.sort(sgs.ai_camps, compare_func)
	end,
}
--[[
	功能：初始化关系策略
	参数：无
	结果：无
]]--
function SmartAI:initPartners(pos)
--msg(string.format("initPartners>> pos=%d, player=%s", pos or -1, self.player:getGeneralName()))
	self.partners = {} --合作者们
	self.partners_noself = {} --合作者们（不含自身）
	self.opponents = {} --对抗者们
	self.neutrals = {} --中立者们
	for _,friend in ipairs(self.friends) do
		table.insert(self.partners, friend)
	end
	for _,friend in ipairs(self.friends_noself) do
		table.insert(self.partners_noself, friend)
	end
	for _,enemy in ipairs(self.enemies) do
		table.insert(self.opponents, enemy)
	end
	for _,other in ipairs(self.unknowns) do
		table.insert(self.neutrals, other)
	end
--self:Debug_ShowMyAttitude()
--sgs.Debug_ShowRelationship()
end
--[[
	功能：调整相互关系策略
	参数：无
	结果：无（改变了表self.partners、self.partners_noself、self.opponents、self.neutrals）
]]--
function SmartAI:choosePartner(pos)
--msg(string.format("choosePartner>> pos=%d, player=%s", pos or -1, self.player:getGeneralName()))
	--关闭关系策略调整
	if sgs.close_partners then 
		self:initPartners()
		return 
	end
	--开启关系策略调整
	local others = self.room:getOtherPlayers(self.player) --待分配的角色
	self.partners = {self.player} --合作者们
	self.partners_noself = {} --合作者们（不含自身）
	self.opponents = {} --对抗者们
	self.neutrals = {} --中立者们
	--按阵营数目调整相互关系策略
	local campCount = #sgs.ai_camps --阵营数目
	--自身为内奸时，将处于危险的主公加入合作者中
	local myname = self.player:objectName()
	if campCount > 2 then
		if self:amRenegade() then
			local lord = self.room:getLord()
			if lord then
				if lord:objectName() ~= myname then --isEnemy -> isPartner
					if self:isWeak(lord) or sgs.isInDanger(lord) then
						table.insert(self.partners, lord)
						table.insert(self.partners_noself, lord)
						others:removeOne(lord)
					end
				end
			end
		end
	end
	--国战模式
	if sgs.hegemony_mode then
		--准备国战模式数据
		local hegemony_flag = false
		local isAnjiang = false
		local haveShown = {}
		if self.player:getGeneralName() == "anjiang" then
			isAnjiang = true
			for _,p in sgs.qlist(others) do
				if p:getKingdom() == self.camp then
					table.insert(haveShown, p)
				end
			end
		end
		if #haveShown >= sgs.maxShown then
			hegemony_flag = true
		end
		--调整国战模式关系策略
		if hegemony_flag then
			if campCount <= 2 then -- isFriend -> isOpponent
				for _,friend in ipairs(haveShown) do
					table.insert(self.opponents, friend)
					others:removeOne(friend)
				end
			else --isFriend -> isNeutral
				for _,friend in ipairs(haveShown) do
					table.insert(self.neutrals, friend)
					others:removeOne(friend)
				end
			end
		end
	--身份局模式等
	else
		if campCount == 3 then 
			local maxcamp = sgs.getMaxDefenseCamp() --防御能力最强的阵营
--msg(string.format("maxcamp=%s", maxcamp))
			if self.camp ~= maxcamp then
				for _,enemy in ipairs(self.enemies) do
					local camp = sgs.getCamp(enemy)
					if camp ~= "unknown" then
						if camp ~= maxcamp then --isEnemy -> isPartner
							table.insert(self.partners, enemy)
							table.insert(self.partners_noself, enemy)
							others:removeOne(enemy)
						end
					end
				end
			end
		elseif campCount > 3 then
			local maxcamp = sgs.getMaxDefenseCamp() --防御能力最强的阵营
--msg(string.format("maxcamp=%s", maxcamp))
			if self.camp ~= maxcamp then
				for _,enemy in ipairs(self.enemies) do
					local camp = sgs.getCamp(enemy)
					if camp ~= "unknown" then
						if camp ~= maxcamp then --isEnemy -> isNeutral
							table.insert(self.neutrals, enemy)
							others:removeOne(enemy)
						end
					end
				end
			end
		end
	end
	for _,p in sgs.qlist(others) do
		if self:isFriend(p) then --isFriend -> isPartner
			table.insert(self.partners, p)
			table.insert(self.partners_noself, p)
		elseif self:isEnemy(p) then --isEnemy -> isOpponent
			table.insert(self.opponents, p)
		else --isUnknown -> isNeutral
			table.insert(self.neutrals, p)
		end
	end
	if #self.opponents == 0 and #self.neutrals > 0 then --保证至少有一名可对抗角色，使得游戏可以进行下去
		self:sort(self.neutrals, "threat")
		local XiaHouJie = self.neutrals[1] --无故躺枪的悲催角色
		table.insert(self.opponents, XiaHouJie) 
		sgs.ai_relationship[myname][XiaHouJie:objectName()] = "opponent"
		table.remove(self.neutrals, 1)
	end
--self:Debug_ShowMyAttitude()
--sgs.Debug_ShowRelationship()
end
--[[
	功能：清空全局标志
	参数：无
	结果：无（表sgs.ai_global_flags被清空）
]]--
function SmartAI:clearGlobalFlags()
	for _,flag in ipairs(sgs.ai_global_flags) do
		sgs[flag] = nil
	end
end
--[[
	功能：初始化角色信息
	参数：无
	结果：无
]]--
function SmartAI:initPlayers()
	self.friends = {self.player}
	self.friends_noself = {}
	self.enemies = {}
	self.unknowns = {}
	local others = self.room:getOtherPlayers(self.player)
	for _,lord in ipairs(sgs.ai_lords) do
		if lord ~= self.player:objectName() then
			local mylord = findPlayerByObjectName(self.room, lord)
			if sgs.ai_camp[lord] == self.camp then
				table.insert(self.friends, mylord)
			else
				table.insert(self.enemies, mylord)
			end
			others:removeOne(mylord)
		end
	end
	for _,p in sgs.qlist(others) do
		local camp = sgs.getCamp(p)
		if self.camp == camp then
			table.insert(self.friends, p)
			table.insert(self.friends_noself, p)
		elseif camp == "unknown" then
			table.insert(self.unknowns, p)
		else
			table.insert(self.enemies, p)
		end
	end
end
--[[
	功能：更新角色信息
	参数：clear_flags（boolean类型，表示是否清除所有标志）
	结果：无（改变了表self.friends、self.friends_noself、self.enemies、self.unknowns）
]]--
function SmartAI:updatePlayers(pos)
--msg(string.format("updatePlayers>> pos=%d, player=%s", pos or -1, self.player:getGeneralName()))
	--改换阵营
	if self.player:getMark("AI_ModifyRole") > 0 then
		local roles = {
			"lord",
			"loyalist",
			"renegade",
			"rebel",
		}
		for _,role in ipairs(roles) do
			local flag = "AI_ModifyRoleTo:"..role
			if self.player:hasFlag(flag) then
				self.role = role
				flag = "-"..flag
				self.room:setPlayerFlag(self.player, flag)
				break 
			end
		end
		local myname = self.player:objectName()
		self.camp = sgs.ai_system_record[myname]
		self.room:setPlayerMark(self.player, "AI_ModifyRole", 0)
	end
	--重置阵营信息
	if self.player:getMark("AI_ResetPlayerCamp") > 0 then
		self:ResetPlayerCamp()
		self.room:setPlayerMark(self.player, "AI_ResetPlayerCamp", 0)
	end
	-- 判断是否有必要更新角色信息
	if self.player:getMark("AI_UpdateIntention") > 0 then
		self.room:setPlayerMark(self.player, "AI_UpdateIntention", 0)
	else
		return 
	end
	--数据准备
	local unknowns = {}
	for _,p in ipairs(self.unknowns) do
		table.insert(unknowns, p)
	end
	--更新关系
	self.friends = {self.player} --战友们
	self.friends_noself = {} --战友们（不含自身）
	self.enemies = {} --敌人们
	self.unknowns = {} --状况不明者们
	local others = self.room:getOtherPlayers(self.player)
	for _,p in sgs.qlist(others) do
		if p:isAlive() then
			local p_camp = sgs.getCamp(p)
			if p_camp == "unknown" then --isUnknown
				table.insert(self.unknowns, p)
			else
				if self.camp == p_camp then --isFriend
					table.insert(self.friends, p)
					table.insert(self.friends_noself, p)
				else --isEnemy
					table.insert(self.enemies, p)
				end
			end
		end
	end
	if #self.enemies == 0 and #self.unknowns > 0 then
		self:sort(self.unknowns, "threat")
		table.insert(self.enemies, self.unknowns[1])
		table.remove(self.unknowns, 1)
	end
	--初步更新关系策略
	for _,p in ipairs(unknowns) do
		if self:isFriend(p) then
			table.insert(self.partners, p)
			table.insert(self.partners_noself, p)
		elseif self:isEnemy(p) then
			table.insert(self.opponents, p)
		end
	end
end
--[[
	功能：根据一名角色的针对程度对指定的一组阵营排序
	参数：camps（table类型，表示阵营名单）
		player（ServerPlayer类型，表示作为标准的角色）
	结果：无（camps被改变）
]]--
function sgs.SortCampsByHostile(camps, player)
	local name = player:objectName()
	local function compare_hostile_func(a, b)
		local hostileA = sgs.ai_hostile_level[name][a] or 0
		local hostileB = sgs.ai_hostile_level[name][b] or 0
		if hostileA == hostileB then
			local friendlyA = sgs.ai_friendly_level[name][a] or 0
			local friendlyB = sgs.ai_friendly_level[name][b] or 0
			if friendlyA == friendlyB then
				local memA = sgs.ai_members_count[a] or 0
				local memB = sgs.ai_members_count[b] or 0
				return memA > memB
			else
				return friendlyA > friendlyB
			end
		else
			return hostileA < hostileB
		end
	end
	table.sort(camps, compare_hostile_func)
end
--[[
	功能：根据对指定阵营的针对程度对一组角色进行排序
	参数：players（table类型，表示待排序的一组角色）
		camp（string类型，表示作为标准的阵营）
	结果：无（players被改变）
]]--
function sgs.SortPlayersByCamp(players, camp)
	local function compare_func(a, b)
		local nameA = a:objectName()
		local nameB = b:objectName()
		local hostileA = sgs.ai_hostile_level[nameA][camp] or 0
		local hostileB = sgs.ai_hostile_level[nameB][camp] or 0
		if sgs.ai_lord[nameA] == nameA then
			hostileA = -999
		end
		if sgs.ai_lord[nameB] == nameB then
			hostileB = -999
		end
		if hostileA == hostileB then
			local friendlyA = sgs.ai_friendly_level[nameA][camp] or 0
			local friendlyB = sgs.ai_friendly_level[nameB][camp] or 0
			if friendlyA == friendlyB then
				local memA = sgs.ai_members_count[a] or 0
				local memB = sgs.ai_members_count[b] or 0
				return memA > memB
			else
				return friendlyA > friendlyB
			end
		else
			return hostileA < hostileB
		end
	end
	table.sort(players, compare_func)
end
--[[
	功能：推测角色所属阵营
	参数：player（ServerPlayer类型，表示目标角色）
	结果：string类型（sgs.ai_camp[name]），表示最可能的阵营
]]--
function sgs.evaluatePlayerCamp(player)
	local name = player:objectName() --该角色对象名
	if sgs.role_predictable then --身份预知
		sgs.ai_camp[name] = sgs.system_record[name]
	else --未开启身份预知
		if sgs.ai_lord[name] == name then --主公
			sgs.ai_camp[name] = sgs.system_record[name]
		else --一般角色
			sgs.SortCampsByHostile(sgs.ai_camps, player)
			local campCount = #sgs.ai_camps
			if campCount == 1 then --仅剩余一个阵营（单势力国战模式<有无法亮将的同势力暗将>等）
				sgs.ai_camp[name] = sgs.ai_camps[1]
				return sgs.ai_camp[name]
			elseif campCount == 2 then --仅剩余两个阵营（主内、主反、双势力国战模式等）
				--对主公阵营的态度
				for _,lord in ipairs(sgs.ai_lords) do
					local lordcamp = sgs.ai_camp[lord]
					local r = sgs.ai_relationship[name][lord]
					if r == "partner" then
						sgs.ai_camp[name] = lordcamp
						return lordcamp
					elseif r == "opponent" then
						for _,camp in ipairs(sgs.ai_camps) do
							if camp ~= lordcamp then
								sgs.ai_camp[name] = camp
								return camp
							end
						end
					end
				end
				--一般判断（包括无主公的情形）
				local campA = sgs.ai_camps[1]
				local friendlyA = sgs.ai_friendly_level[name][campA] or 0
				local hostileA = sgs.ai_hostile_level[name][campA] or 0
				local campB = sgs.ai_camps[2]
				local friendlyB = sgs.ai_friendly_level[name][campB] or 0
				local hostileB = sgs.ai_hostile_level[name][campB] or 0
				local deltA = friendlyA - hostileA
				local deltB = friendlyB - hostileB
				if deltA > deltB then
					sgs.ai_camp[name] = campA
				elseif deltA < deltB then
					sgs.ai_camp[name] = campB
				else
					sgs.ai_camp[name] = "unknown"
				end
				return sgs.ai_camp[name]
			elseif campCount == 3 then --仅剩余三个阵营（主内反、主忠内反、三势力国战模式等）
				for index, camp in ipairs(sgs.ai_camps) do
					if camp ~= "unknown" and index < #sgs.ai_camps then
						if (sgs.ai_friendly_level[name][camp] or 0) > 0 then
							sgs.ai_camp[name] = camp
							break
						elseif (sgs.ai_hostile_level[name][camp] or 0) == 0 then
							sgs.ai_camp[name] = camp
							break
						end
					end
				end
			else --多个阵营（四势力国战模式等）
				for index, camp in ipairs(sgs.ai_camps) do
					if camp ~= "unknown" and index < #sgs.ai_camps then
						if (sgs.ai_friendly_level[name][camp] or 0) > 0 then
							sgs.ai_camp[name] = camp
							break
						elseif (sgs.ai_hostile_level[name][camp] or 0) == 0 then
							sgs.ai_camp[name] = camp
							break
						end
					end
				end
			end
		end
	end
	return sgs.ai_camp[name]
end
--[[
	功能：推定其余角色阵营
	参数：无
	结果：无
]]--
function sgs.evaluateRestCamps()
	local alives = global_room:getAlivePlayers()
	local count = {}
	for _,camp in ipairs(sgs.ai_camps) do
		local mem_count = sgs.ai_members_count[camp]
		if mem_count < 0 then
			mem_count = alives:length()
		end
		count[camp] = mem_count
	end
	local unknowns = {}
	for _, p in sgs.qlist(alives) do
		local camp = sgs.getCamp(p)
		if camp == "unknown" then
			table.insert(unknowns, p)
		else
			count[camp] = count[camp] - 1
		end
	end
	local rests = {}
	local mistakes = {}
	for _,camp in ipairs(sgs.ai_camps) do
		if count[camp] > 0 then
			table.insert(rests, camp)
		elseif count[camp] < 0 then
			table.insert(mistakes, camp)
		end
	end
	if #rests == 1 then
		local camp = rests[1]
		for _,p in ipairs(unknowns) do
			sgs.ai_camp[p:objectName()] = camp
		end
	end
	if #mistakes > 0 then
		for _,camp in ipairs(mistakes) do
			local members = sgs.getCampMembers(camp)
			sgs.SortPlayersByCamp(members, camp)
			for index, p in ipairs(members) do
				if index > sgs.ai_members_count[camp] then
					sgs.ai_camp[p:objectName()] = "unknown"
				end
			end
		end
	end
end
--[[
	功能：根据卡牌仇恨值更新情况判定并更新角色阵营
	参数：source（ServerPlayer类型，表示仇恨来源）
		target（ServerPlayer类型，表示仇恨目标）
		intention（number类型，表示新增加的仇恨值）
	结果：无
]]--
sgs.ai_card_intention["general"] = function(source, target, intention)
	if intention == 0 then
		return 
	end
	assert(source)
	if not sgs.role_predictable then
		if target then
			local fromName = source:objectName()
			for _,lordName in ipairs(sgs.ai_lords) do
				if lordName == fromName then 
					return --不更新领袖角色引起的仇恨值
				end
			end
			local alives = global_room:getAlivePlayers()
			for _,p in sgs.qlist(alives) do
				global_room:setPlayerMark(p, "AI_UpdateIntention", 1)
			end
--msg(string.format("(%s->%s):%d", source:getGeneralName(), target:getGeneralName(), intention))
			local toName = target:objectName()
			--获取原先的关系表和阵营推定
			local original_relationship = sgs.ai_relationship[fromName][toName]
			local original_camp = sgs.getCamp(source) --原先对自身的推定阵营
			local target_camp = sgs.getCamp(target) --对方角色的推定阵营
			local isToUnknown = ( target_camp == "unknown" )
--msg(string.format("original=%s, target=%s", original_camp, target_camp))
			--尝试更新关系表
			if intention < 0 then
				table.insert(sgs.ai_camp_history[fromName], "+"..target_camp)
				if isToUnknown then
					return 
				else
--msg(string.format("intention<0, to:%s", target_camp))
					sgs.ai_relationship[fromName][toName] = "partner"
					local friendly_level = sgs.ai_friendly_level[fromName][target_camp] or 0
					sgs.ai_friendly_level[fromName][target_camp] = friendly_level + 1
				end
			elseif intention > 0 then
				table.insert(sgs.ai_camp_history[fromName], "-"..target_camp)
				if isToUnknown then
					return 
				else
--msg(string.format("intention>0, to:%s", target_camp))
					sgs.ai_relationship[fromName][toName] = "opponent"
					local hostile_level = sgs.ai_hostile_level[fromName][target_camp] or 0
					sgs.ai_hostile_level[fromName][target_camp] = hostile_level + 1
				end
			end
			--根据新的关系表推定阵营
			local new_camp = sgs.evaluatePlayerCamp(source)
--msg(string.format("evaluatePlayerCamp:new_camp=%s", new_camp))
			if original_camp == "unknown" then --原先并无阵营推定
--msg(string.format("original is unknown, change to new camp."))
				sgs.ai_camp[fromName] = new_camp
			else --原先已有阵营推定
				if original_camp == new_camp then --阵营推定不变
--msg(string.format("original is new camp, do nothing."))
					--Nothing
				else --阵营推定变化
--sgs.Debug_ShowCampHistory(source)
					local history = sgs.ai_camp_history[fromName]
					local values = {}
					for _,camp in ipairs(sgs.ai_camps) do
						values[camp] = 0
					end
					local current_camp = "unknown"
					local current_count = 0
					local ratio = 1
					for index, item in pairs(history) do
						local attitude = string.sub(item, 1, 1)
						local camp = string.sub(item, 2)
--msg(string.format("attitude=%s,camp=%s", attitude, camp))
						local value = 1
						if attitude == "+" then --友好的行为
							if camp == "unknown" then --对未知势力友好
								--Nothing
							else --对已知势力友好
								if camp == current_camp then
									current_count = current_count + 1
								else
									current_camp = camp
									current_count = 1
								end
								value = current_count * ratio
								values[camp] = values[camp] + value
							end
						elseif attitude == "-" then --不友好的行为
							if camp == "unknown" then --对未知势力不友好
								if current_camp == "unknown" then
									for _,known in ipairs(sgs.ai_camps) do
										if #sgs.getCampMembers(known) > 0 then
											values[known] = values[known] + ratio / 4
										end
									end
								else
									for _,known in ipairs(sgs.ai_camps) do
										if current_camp == known then
											flag = false
											value = current_count * ratio / 2
											values[known] = values[known] + value
											break
										end
									end
								end
							else --对已知势力不友好
								if camp == current_camp then
									current_count = 0
								end
								value = ratio
								values[camp] = values[camp] - value
								if current_camp ~= "unknown" then
									values[current_camp] = values[current_camp] + 1
								end
							end
						end
						ratio = ratio * 2
					end
					local function compare_func(a, b)
						return values[a] > values[b]
					end
					table.sort(sgs.ai_camps, compare_func)
					sgs.ai_camp[fromName] = sgs.ai_camps[1]
				end
			end
			if sgs.ai_camp[fromName] ~= original_camp then
				--Do Something to Choose Partners.
			end
			sgs.evaluateRestCamps() --推定其余角色阵营
sgs.Debug_ShowCamps() --在服务器端显示阵营推定结果
--sgs.Debug_ShowCampHistory(source) --在服务器端显示立场转换历史
		else
			global_room:writeToConsole(debug.traceback())
		end
	end
end
--[[
	功能：获取对target使用的锦囊TrickClass的一般仇恨值
]]--
function sgs.getTrickIntention(TrickClass, target)
	local Intention = sgs.ai_card_intention[TrickClass]
	if type(Intention) == "number" then
		return Intention 
	elseif type(Intention == "function") then
		if TrickClass == "IronChain" then 
			if target then
				if target:isChained() then
					return -80
				else
					return 80
				end
			end
		end
	end
	if TrickClass == "Collateral" then 
		return 0 
	elseif TrickClass == "AmazingGrace" then 
		return -10 
	elseif sgs.getCardValue(TrickClass, "damage") > 0 then 
		return 70
	elseif sgs.getCardValue(TrickClass, "benefit") > 0 then 
		return -40
	end
	if target then
		if TrickClass == "Snatch" or TrickClass == "Dismantlement" then
			local judgelist = target:getCards("j")
			if judgelist:isEmpty() then
				local armor = target:getArmor()
				if armor and armor:isKindOf("SilverLion") and target:isWounded() then 
					return 0
				else
					return 80
				end
			end
		end
	end
	return 0
end
--[[
	内容：根据无懈可击的使用情况更新仇恨值
]]--
sgs.ai_choicemade_filter.Nullification["general"] = function(player, promptlist)
	local TrickClass = promptlist[2]
	local targetname = promptlist[3]
	if TrickClass == "Nullification" then
		if sgs.Nullification_Source then
			if type(sgs.Nullification_Intention) == "number" then
				sgs.Nullification_Level = sgs.Nullification_Level + 1
				if sgs.Nullification_Level % 2 == 0 then
					sgs.updateIntention(player, sgs.Nullification_Source, sgs.Nullification_Intention)
				elseif sgs.Nullification_Level % 2 == 1 then
					sgs.updateIntention(player, sgs.Nullification_Source, -sgs.Nullification_Intention)
				end
				return 
			end
		end
		self.room:writeToConsole(debug.traceback())
	else
		sgs.Nullification_Source = findPlayerByObjectName(global_room, targetname)
		sgs.Nullification_Level = 1
		sgs.Nullification_Intention = sgs.getTrickIntention(TrickClass, sgs.Nullification_Source)
		local isNeutral = false
		if sgs.Nullification_Source then
			local camp = sgs.getCamp(sgs.Nullification_Source)
			isNeutral = ( camp == "unknown" )
		end
		if isNeutral then
			if sgs.TrickUsefrom then
				local camp = sgs.getCamp(sgs.TrickUsefrom)
				if camp ~= "unknown" then
					if sgs.Nullification_Intention ~= 0 then
						if ("Snatch|Dismantlement|FireAttack|Duel"):match(TrickClass) then
							sgs.Nullification_Source = sgs.TrickUsefrom
							sgs.Nullification_Intention = -sgs.Nullification_Intention
						end
					end
				end
			end
		end
		if player:objectName() ~= targetname then
			sgs.updateIntention(player, sgs.Nullification_Source, -sgs.Nullification_Intention)
		end
	end
end
--[[
	内容：根据卡牌选择目标的情况更新仇恨值
]]--
sgs.ai_choicemade_filter.playerChosen["general"] = function(from, promptlist, self)
	if from:objectName() == promptlist[3] then 
		return 
	end
	local reason = string.gsub(promptlist[2], "%-", "_")
	local target = nil
	local alives = global_room:getAlivePlayers()
	for _, p in sgs.qlist(alives) do
		if p:objectName() == promptlist[3] then 
			target = p 
			break 
		end
	end
	local callback = sgs.ai_playerchosen_intention[reason]
	if callback then
		local source = from
		if type(callback) == "number" then
			sgs.updateIntention(source, target, callback)
		elseif type(callback) == "function" then
			callback(self, source, target)
		end
	end
end
--[[
	内容：更新可见的卡牌
]]--
sgs.ai_choicemade_filter.viewCards["general"] = function(from, promptlist, self)
	local name = promptlist[#promptlist]
	local target = findPlayerByObjectName(self.room, name)
	if target then
		if not target:isKongcheng() then
			local flag = string.format("visible_%s_%s", from:objectName(), target:objectName())
			local handcards = target:getHandcards()
			for _, card in sgs.qlist(handcards) do
				if not card:hasFlag("visible") then 
					card:setFlags(flag) 
				end
			end
		end
	end
end
--[[
	功能：更新仇恨值
	参数：source（ServerPlayer类型，表示仇恨来源）
		target（ServerPlayer类型，表示仇恨目标）
		intention（number类型，表示新增加的仇恨值）
	结果：无
]]--
function sgs.updateIntention(source, target, intention)
	if target and source then
		if target:objectName() ~= source:objectName() then
			sgs.ai_card_intention["general"](source, target, intention)
		end
	else
		global_room:writeToConsole(debug.traceback())
	end
end
--[[
	功能：批量更新仇恨值
	参数：source（ServerPlayer类型，表示仇恨来源）
		targets（table类型，表示所有仇恨目标）
		intention（number类型，表示新增加的仇恨值）
	结果：无
]]--
function sgs.updateIntentions(source, targets, intention)
	for _,target in ipairs(targets) do
		sgs.updateIntention(source, target, intention)
	end
end
--[[
	功能：事件处理
	参数：event（sgs.TriggerEvent类型，表示当前事件）
		player（ServerPlayer类型，表示当前处理的角色）
		data（sgs.QVariant类型，表示当前环境数据）
	结果：无
]]--
function SmartAI:filterEvent(event, player, data)
	if not sgs.recorder then
		sgs.recorder = self
	end
	local name = player:objectName()
	local isMe = ( name == self.player:objectName() )
	local isRecorder = ( self == sgs.recorder )
	if isMe then
		if sgs.debugmode then
			if type(sgs.ai_debug_func[event]) == "table" then
				for _,callback in pairs(sgs.ai_debug_func[event]) do
					if type(callback) == "function" then 
						callback(self, player, data) 
					end
				end
			end
		end
		if type(sgs.ai_chat_func[event]) == "table" then
			if sgs.GetConfig("AIChat", true) then
				if player:getState() == "robot" then
					for _,callback in pairs(sgs.ai_chat_func[event]) do
						if type(callback) == "function" then 
							callback(self, player, data) 
						end
					end
				end
			end
		end
		if type(sgs.ai_event_callback[event]) == "table" then
			for _,callback in pairs(sgs.ai_event_callback[event]) do
				if type(callback) == "function" then 
					callback(self, player, data) 
				end
			end
		end
	end
	sgs.LastEvent = event
	sgs.LastEventData = data
	if isRecorder then
		if event == sgs.ChoiceMade then --记录者
			local use = data:toCardUse()
			if use and use.card then
				self:clearGlobalFlags()
				for _, callback in ipairs(sgs.ai_choicemade_filter["cardUsed"]) do
					if type(callback) == "function" then
						callback(player, use)
					end
				end
			end
			local data_string = data:toString()
			if data_string then
				local promptlist = data_string:split(":")
				local event_name = promptlist[1]
				local pattern = promptlist[2]
				local prompt = promptlist[3]
				local callbacks = sgs.ai_choicemade_filter[event_name]
				if callbacks and type(callbacks) == "table" then
					local index = 2
					if event_name == "cardResponded" then
						index = 3
					end
					local callback = callbacks[promptlist[index]]
					callback = callback or callbacks[general]
					if callback and type(callback) == "function" then
						callback(player, promptlist, self)
					end
				end
				if data_string == "skillInvoke:fenxin:yes" then
					local allplayers = self.room:getAllPlayers()
					for _,target in sgs.qlist(allplayers) do
						if target:hasFlag("FenxinTarget") then
							sgs.ExchangePlayerRole(player, target) --交换身份
							self:clearGlobalFlags()
							self:updatePlayers()
						end
					end
				end
			end
		end
	end
	if event == sgs.CardUsed then --所有角色：卡牌选择目标后
		self:clearGlobalFlags()
		self:updatePlayers()
	elseif event == sgs.CardEffect then --所有角色：卡牌生效前
		self:clearGlobalFlags()
		self:updatePlayers()
	elseif event == sgs.GameStart then --所有角色：游戏开始时
		self:clearGlobalFlags()
		self:initPlayers()
		self:initPartners()
	elseif event == sgs.EventPhaseStart then --所有角色：阶段开始时
		self:clearGlobalFlags()
		self:updatePlayers()
	elseif event == sgs.Death then --所有角色：阵亡时（全局时机）
		self:updatePlayers()
		if isRecorder then
			sgs.updateAlivePlayers()
		end
	elseif event == sgs.HpChanged then --所有角色：体力变化后
		self:updatePlayers()
	elseif event == sgs.MaxHpChanged then --所有角色：体力上限变化后
		self:updatePlayers()
	elseif event == sgs.BuryVictim then --所有角色：处理阵亡角色时
		if isRecorder then
			local death = data:toDeath()
			local victim = death.who
			sgs.RemovePlayer(victim)
			sgs.updateAlivePlayers() 
		end
		self:updatePlayers()
	end
	if isMe then 
		if event == sgs.AskForPeaches then --当前角色：濒死状态求桃时
			local dying = data:toDying()
			local target = dying.who
			if self:isPartner(target) then
				if target:getHp() < 1 then
					sgs.card_lack[name]["Peach"] = 1
				end
			end
		elseif event == sgs.EventPhaseStart then --阶段开始时（新的设定）
			local phase = player:getPhase()
			if phase == sgs.Player_RoundStart then
				self:choosePartner()
			elseif phase == sgs.Player_NotActive then
				self:choosePartner()
			end
		end
	end
	if isRecorder then
		if event == sgs.TargetConfirmed then --记录者：指定/成为目标后（全局时机）
			local use = data:toCardUse()
			local source = use.from
			local card = use.card
			local targets = use.to
			targets = sgs.QList2Table(targets)
			if source and source:objectName() == name then
				--更新卡牌仇恨值
				local className = card:getClassName()
				local callback = sgs.ai_card_intention[className]
				if callback then
					if type(callback) == "function" then
						callback(self, card, source, targets)
					elseif type(callback) == "number" then
						sgs.updateIntentions(source, targets, callback)
					end
				elseif className == "LuaSkillCard" then
					if card:isKindOf("LuaSkillCard") then
						callback = sgs.ai_card_intention[card:objectName()]
						if callback then
							if type(callback) == "function" then
								callback(self, card, source, targets)
							elseif type(callback) == "number" then
								sgs.updateIntentions(source, targets, callback)
							end
						end
					end
				end
			end
			local lord = self:getMyLord(player)
			if lord and card:isKindOf("AOE") then
				if lord:getHp() == 1 then
					if use.to:contains(lord) then
						if self:aoeIsEffective(card, lord, source) then
							if card:isKindOf("SavageAssault") then
								sgs.ai_lord_in_danger_SA = true
							elseif card:isKindOf("ArcheryAttack") then
								sgs.ai_lord_in_danger_AA = true
							end
						end
					end
				end
			end
			if sgs.turncount <= 1 and #sgs.ai_lords > 0 then
				if sgs.getCamp(source) == "unknown" then
					if source and source:objectName() == name then
						local firstTarget = targets[1]
						if firstTarget then
							local can_update = false
							if sgs.isKindOf("YinlingCard|FireAttack", card) then
								can_update = true
							elseif sgs.isKindOf("Snatch|Dismantlement", card) then
								if not self:needToThrowArmor(firstTarget) then
									if not firstTarget:hasSkills("tuntian+zaoxian") then
										can_update = true
										if firstTarget:getCards("j"):length() > 0 then
											if not firstTarget:containsTrick("YanxiaoCard") then
												can_update = false
											end
										end
										if can_update then
											if firstTarget:getCards("e"):length() > 0 then
												if self:hasSkills(sgs.lose_equip_skill, firstTarget) then
													can_update = false
												end
											end
										end
										if can_update then
											if firstTarget:getHandcardNum() == 1 then
												if self:needKongcheng(firstTarget) then
													can_update = false
												end
											end
										end
									end
								end
							elseif sgs.isKindOf("Slash", card) then
								if not self:invokeDamagedEffect(firstTarget, player, card) then
									if not self:needToLoseHp(firstTarget, player, true, true) then
										can_update = true
										if sgs.getCardsNum("Jink", firstTarget) > 0 then
											if firstTarget:hasSkill("leiji") then
												can_update = false
											elseif firstTarget:hasSkills("tuntian+zaoxian") then
												can_update = false
											end
										end
									end
								end
							elseif sgs.isKindOf("Duel", card) then
								local skillname = card:getSkillName()
								if not ("lijian|noslijian"):match(skillname) then
									if not self:invokeDamagedEffect(firstTarget, player) then
										if not self:needToLoseHp(firstTarget, player, nil, true, true) then
											can_update = true
										end
									end
								end
							end
							if can_update then
								if sgs.getCamp(firstTarget) == "unknown" then
									local toUnknown = true
									for _,target in ipairs(targets) do
										if sgs.getCamp(target) ~= "unknown" then
											toUnknown = false
											break
										end
									end
									if toUnknown then
										for _,lordname in ipairs(sgs.ai_lords) do
											lord = findPlayerByObjectName(self.room, lordname)
											local result = self:exclude({lord}, card, source)
											local exclude_lord = ( #result > 0 )
											if exclude_lord then
												sgs.updateIntention(source, lord, -10)
												can_update = false
											end
										end
									end
								end
								if can_update then
									sgs.updateIntention(source, firstTarget, 10)
								end
							end
						end
					end
				end
			end
		elseif event == sgs.CardEffect then --记录者：卡牌生效前
			local effect = data:toCardEffect()
			local source = effect.from
			local target = effect.to
			local card = effect.card
			--AOE
			if card:isKindOf("AOE") then
				if target and self:mayLord(target) then
					if sgs.ai_lord_in_danger_SA or sgs.ai_lord_in_danger_AA then
						sgs.ai_lord_in_danger_SA = nil
						sgs.ai_lord_in_danger_AA = nil
					end
				end
			end
			--借刀杀人
			if card:isKindOf("Collateral") then 
				sgs.ai_collateral = true 
			end
			--雷击
			if card:isKindOf("Slash") then
				if target:hasSkill("leiji") then
					if target:hasArmorEffect("EightDiagram") or sgs.getCardsNum("Jink", target) > 0 then
						sgs.ai_leiji_effect = true
					end
				end
			end
			--冲阵
			if source and target then
				if target:hasSkills("longdan+chongzhen") then
					if sgs.isKindOf("AOE|Slash", card) then
						sgs.chongzhen_target = source
					end
				end
			end
		elseif event == sgs.PreDamageDone then --记录者：扣减体力前
		elseif event == sgs.Damaged then --记录者：造成伤害后
			local damage = data:toDamage()
			local card = damage.card
			if not card then
				local source = damage.from
				local target = damage.to
				local intention = 100
				if sgs.ai_quhu_effect then
					sgs.ai_quhu_effect = nil
					local XunYu = self.room:findPlayerBySkillName("quhu")
					intention = 80
					source = XunYu
				elseif source then
					if source:hasFlag("ShenfenUsing") then
						intention = 0
					elseif source:hasFlag("FenchengUsing") then
						intention = 0
					end
				end
				if damage.transfer or damage.chain then 
					intention = 0 
				end
				if source then
					if intention ~= 0 then
						sgs.updateIntention(source, target, intention)
					end
				end
			end
		elseif event == sgs.CardUsed then --记录者：卡牌选择目标后
			local use = data:toCardUse()
			local card = use.card
			if card:isKindOf("Duel") then
				for _,lordname in ipairs(sgs.ai_lords) do
					local lord = findPlayerByObjectName(self.room, lordname)
					if lord and lord:hasFlag("AIGlobal_NeedToWake") then
						lord:setFlags("-AIGlobal_NeedToWake")
					end
				end
			elseif sgs.isKindOf("Snatch|Dismantlement", card) then
				for _,target in sgs.qlist(use.to) do
					local cards = target:getCards("hej")
					for _,c in sgs.qlist(cards) do
						local flag = "-AIGlobal_SDCardChosen_"..card:objectName()
						self.room:setCardFlag(c, flag)
					end
				end
			elseif card:isKindOf("AOE") then
				if sgs.ai_AOE_data then
					sgs.ai_AOE_data = nil
				end
			elseif card:isKindOf("Slash") then
				local current = self.room:getCurrent()
				local source = use.from
				if current:objectName() == source:objectName() then
					local reason = use.m_reason
					if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
						if use.m_addHistory then
							source:setFlags("hasUsedSlash")
						end
					end
				end
			end
			--冲阵
			if sgs.chongzhen_target then 
				sgs.chongzhen_target = nil 
			end
			--奇策
			if card:getSkillName() == "qice" then
				if sgs.ai_qice_data then
					sgs.ai_qice_data = nil
				end
			end
		elseif event == sgs.CardsMoveOneTime then --记录者：卡牌移动时（全局时机）
			local move = data:toMoveOneTime()
			local source = move.from
			local target = move.to
			source = source and findPlayerByObjectName(self.room, source:objectName())
			target = target and findPlayerByObjectName(self.room, target:objectName())
			local reason = move.reason
			for index=0, move.card_ids:length()-1, 1 do
				local place = move.from_places:at(index)
				local card_id = move.card_ids:at(index)
				local card = sgs.Sanguosha:getCard(card_id)
				--摸牌堆、纵玄
				if place == sgs.Player_DrawPile then
					self.top_draw_pile_id = nil
				elseif move.to_place == sgs.Player_DrawPile then
					local flag = true
					if source then
						local property = source:property("zongxuan_move")
						local zongxuan_id = tonumber(property:toString())
						if zongxuan_id == card_id then
							flag = false
						end
					end
					if flag then
						self.top_draw_pile_id = nil
					end
				end
				--可见的卡牌
				if move.to_place == sgs.Player_PlaceHand then
					if target then
						local targetName = target:objectName()
						if name == targetName then
							if card:hasFlag("visible") then
								if sgs.isCard("Slash", card, player) then 
									sgs.card_lack[name]["Slash"] = 0 
								elseif sgs.isCard("Jink", card, player) then 
									sgs.card_lack[name]["Jink"] = 0
								elseif sgs.isCard("Peach", card, player) then 
									sgs.card_lack[name]["Peach"] = 0 
								end
							else
								sgs.card_lack[name]["Slash"] = 0
								sgs.card_lack[name]["Jink"] = 0
								sgs.card_lack[name]["Peach"] = 0
							end
						end
						if place ~= sgs.Player_DrawPile then
							if source then
								local sourceName = source:objectName()
								if name == sourceName then
									if sourceName ~= targetName then
										if place == sgs.Player_PlaceHand then
											if not card:hasFlag("visible") then
												local flag = string.format("visible_%s_%s", sourceName, targetName)
												global_room:setCardFlag(card_id, flag, source)
											end
										end
									end
								end
							end
						end
					end
				end
				--巧变
				if reason.m_skillName == "qiaobian" then
					if source and target then
						if self.room:getCurrent():objectName() == name then	
							local from = sgs.QList2Table(move.from_places)
							if table.contains(from, sgs.Player_PlaceDelayedTrick) then
								if card:isKindOf("YanxiaoCard") then
									sgs.updateIntention(player, source, 80)
									sgs.updateIntention(player, target, -80)
								elseif sgs.isKindOf("SupplyShortage|Indulgence", card) then
									sgs.updateIntention(player, source, -80)
									sgs.updateIntention(player, target, 80)
								end
							end
							if table.contains(from, sgs.Player_PlaceEquip) then
								sgs.updateIntention(player, target, -80)
							end
						end
					end
				end
				--遗计
				if reason.m_skillName == "yiji" then
					if reason.m_reason == sgs.CardMoveReason_S_REASON_PREVIEW then
						if target and target:objectName() == name then			
							global_room:setCardFlag(card_id, "yijicard")
						end
					end
				end
				--遗计、秘计
				if move.to_place == sgs.Player_PlaceHand then
					if place == sgs.Player_PlaceHand then
						if target and source then
							if source:objectName() == player:objectName() then
								local flag = false
								if source:hasSkill("yiji") then
									if card:hasFlag("yijicard") then
										flag = true
									end
								end
								if source:hasSkill("miji") then
									if source:getPhase() == sgs.Player_Finish then
										flag = true
									end
								end
								if flag then
									flag = false
									if reason.m_reason == sgs.CardMoveReason_S_REASON_GIVE then
										flag = true
									elseif reason.m_reason == sgs.CardMoveReason_S_REASON_PREVIEWGIVE then
										flag = true
									end
									if flag then
										if target:hasSkill("kongcheng") then
											flag = false
										elseif target:hasSkill("manjuan") then
											if target:getPhase() == sgs.Player_NotActive then
												flag = false
											end
										end
										if flag then
											sgs.updateIntention(source, target, -70)
										end	
									end
								end
							end
						end
					end
				end
				--雷击（弃牌时居然弃闪？说明闪很富裕）
				local flag = false
				if player:hasFlag("AI_Playing") then
					if player:getPhase() == sgs.Player_Discard then
						if reason.m_reason == sgs.CardMoveReason_S_REASON_RULEDISCARD then 
							if player:hasSkill("leiji") then
								if sgs.isCard("Jink", card, player) then
									if player:getHandcardNum() >= 2 then
										sgs.card_lack[name]["Jink"] = 2 
									end
								end
							end
							if sgs.turncount <= 3 then
								if not player:hasSkills("renjie+baiyin") or player:hasSkill("jilve") then
									if not player:hasFlag("ShuangrenSkipPlay") then
										flag = true
									end
								end
							end
						end
					end
				end
				--该杀却不杀属于示好行为
				if flag then
					local isNeutral = ( sgs.getCamp(player) == "unknown" )
					--isNeutral = isNeutral and CanUpdateIntention(player)
					if isNeutral then
						if sgs.isCard("Slash", card, player) then
							if not player:hasFlag("hasUsedSlash") or player:hasFlag("JiangchiInvoke") then
								local others = self.room:getOtherPlayers(player)
								for _,p in sgs.qlist(others) do
									local has_slash_prohibit_skill = false
									local skills = p:getVisibleSkillList()
									for _, skill in sgs.qlist(skills) do
										local s_name = skill:objectName()
										local filter = sgs.slash_prohibit_system[s_name]
										if type(filter) == "function" then
											if not ("tiandu|hujia|huilei|weidi"):match(s_name) then
												if s_name == "xiangle" then
													local basic_num = 0
													for _, id in sgs.qlist(move.card_ids) do
														local c = sgs.Sanguosha:getCard(id)
														if c:isKindOf("BasicCard") then
															basic_num = basic_num + 1
														end
													end
													if basic_num < 2 then 
														has_slash_prohibit_skill = true 
														break 
													end
												else
													has_slash_prohibit_skill = true
													break
												end
											end
										end
									end
									if p:hasSkill("fangzhu") then
										if p:getLostHp() < 2 then
											has_slash_prohibit_skill = true
										end
									end
									if not has_slash_prohibit_skill then
										if player:canSlash(p, card, true) then
											if self:slashIsEffective(card, p) then
												if sgs.isGoodTarget(self, p, self.opponents) then
													sgs.updateIntention(player, p, -35) 
													self:updatePlayers()
												end
											end
										end
									end
								end
							end
						end
						--巧变
						local ZhangHe = self.room:findPlayerBySkillName("qiaobian")
						local lord = self:getMyLord(ZhangHe)
						flag = true
						if ZhangHe and lord then
							if self:playerGetRound(ZhangHe) <= self:playerGetRound(lord) then
								flag = false
							end
						end
						if flag then
							if lord and not lord:hasSkill("qiaobian") then
								local others = self.room:getOtherPlayers(player)
								if sgs.isCard("Indulgence", card, player) then
									for _, p in sgs.qlist(others) do
										if not p:containsTrick("indulgence") then
											if not p:containsTrick("YanxiaoCard") then
												if not self:hasSkills("qiaobian", p) then
													local result = self:exclude( {p}, card, player)
													if #result == 1 then
														sgs.updateIntention(player, p, -35)
														self:clearGlobalFlags()
														self:updatePlayers()
													end
												end
											end
										end
									end
								elseif sgs.isCard("SupplyShortage", card, player) then
									for _, p in sgs.qlist(others) do
										local limit = 1
										if player:hasSkill("duanliang") then
											limit = 2
										end
										if player:distanceTo(p) <= limit then
											if not p:containsTrick("supply_shortage") then
												if not p:containsTrick("YanxiaoCard") then
													if not self:hasSkills("qiaobian", p) then
														local result = self:exclude( {p}, card, player)
														if #result == 1 then
															sgs.updateIntention(player, p, -35)
															self:clearGlobalFlags()
															self:updatePlayers()
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
		elseif event == sgs.StartJudge then --记录者：开始判定时
			local judge = data:toJudge()
			local reason = judge.reason
			if reason == "beige" then
				local CaiWenJi = self.room:findPlayerBySkillName("beige")
				local intention = -60
				if player:objectName() == CaiWenJi:objectName() then 
					intention = 0 
				end
				sgs.updateIntention(CaiWenJi, player, intention)
			end
			sgs.JudgeResult = judge:isGood()
		elseif event == sgs.AskForRetrial then --记录者：询问改判时（全局时机）
			local judge = data:toJudge()
			local target = judge.who
			local source = sgs.RetrialPlayer
			if target and source then
				if sgs.JudgeResult ~= judge:isGood() then
					if sgs.judge_reason:match(judge.reason) then
						if judge:isGood() then
							sgs.updateIntention(source, target, -10)
						else
							sgs.updateIntention(source, target, 10)
						end
					end
					sgs.RetrialPlayer = nil
					sgs.JudgeResult = judge:isGood()
				end
			end
		elseif event == sgs.EventPhaseEnd then --记录者：阶段结束时
			if player:getPhase() == sgs.Player_Play then
				player:setFlags("AI_Playing")
				--移除出牌序列名
				sgs.SeriesName = nil 
				--清空出牌记录
				sgs.ai_card_history = {} 
				sgs.OpenDebugMode = nil 
				--掀桌
				if sgs.CanXianzhuo(player) then 
					sgs.DoXianzhuo(player) 
				end
			end
		elseif event == sgs.EventPhaseStart then --记录者：阶段开始时
			if player:getPhase() == sgs.Player_NotActive then
				if player:isLord() then 
					sgs.turncount = sgs.turncount + 1 
				end
				if sgs.debugmode then 
					sgs.debugmode:close() 
				end
				local humanCount = 0
				local allplayers = self.room:getAllPlayers()
				for _, p in sgs.qlist(allplayers) do
					if p:getState() ~= "robot" then 
						humanCount = humanCount +1 
					end
				end
				self.room:setTag("humanCount", sgs.QVariant(humanCount))
			end
		elseif event == sgs.GameStart then --记录者：游戏开始时
			--启用AI智商系统
			sgs.InitIQ() 
		end
	end
end
--[[****************************************************************
	卡牌价值场景
]]--****************************************************************
--[[
	功能：调整卡牌使用优先级
	参数：player（ServerPlayer类型，表示使用卡牌的角色）
		card（Card类型，表示待使用的卡牌）
		priority（number类型，表示当前的使用优先级）
	结果：number类型（priority），表示调整后的使用优先级
]]--
function sgs.adjustUsePriority(player, card, priority)
	if card:getTypeId() == sgs.Card_Skill then 
		return priority 
	end
	local suits = {
		"club", 
		"spade", 
		"diamond", 
		"heart",
	}
	local skills = player:getVisibleSkillList()
	for _,skill in sgs.qlist(skills) do
		local callback = sgs.ai_suit_priority[skill:objectName()]
		if type(callback) == "function" then
			suits = callback(self, card):split("|")
			break
		elseif type(callback) == "string" then
			suits = callback:split("|")
			break
		end
	end
	table.insert(suits, "no_suit")
	if card:isKindOf("Slash") then 
		if card:getSkillName() == "Spear" then 
			priority = priority - 0.01 
		end
		if card:isRed() then 
			priority = priority - 0.05 
		end
		if card:isKindOf("NatureSlash") then 
			priority = priority - 0.1 
		end
		if card:getSkillName() == "longdan" then
			if self:hasSkills("chongzhen") then 
				priority = priority + 0.21 
			end
		end
		if card:getSkillName() == "fuhun" then 
			if player:getPhase() == sgs.Player_Play then
				priority = priority + 0.21 
			else
				priority = priority - 0.1
			end
		end
		if player:hasSkill("jiang") then
			if card:isRed() then 
				priority = priority + 0.21 
			end
		end
		if player:hasSkill("wushen") then
			if card:getSuit() == sgs.Card_Heart then 
				priority = priority + 0.11 
			end
		end
		if player:hasSkill("jinjiu") then
			if card:getEffectiveId() >= 0 then
				local id = card:getEffectiveId()
				local ecard = sgs.Sanguosha:getEngineCard(id)
				if ecard:isKindOf("Analeptic") then 
					priority = priority + 0.11 
				end
			end
		end
	end
	if player:hasSkill("mingzhe") then
		if card:isRed() then 
			if player:getPhase() == sgs.Player_NotActive then
				priority = priority - 0.05 
			else
				priority = priority + 0.05
			end
		end
	end
	local suits_value = {}
	for index, suit in ipairs(suits) do
		suits_value[suit] = 10 - index * 2 
	end
	priority = priority + (suits_value[card:getSuitString()] or 0) / 100
	priority = priority + (13 - card:getNumber()) / 1000
	return priority
end
--[[
	功能：获取针对某角色的卡牌使用价值
	参数：card（Card类型，表示指定的卡牌；或string类型，表示卡牌类型）
		player（ServerPlayer类型，表示作为标准的角色）
	结果：number类型（value），表示使用价值
]]--
function sgs.getUseValue(card, player)
	if type(card) == "string" then
		local name = sgs.objectName[card]
		if name and sgs[name] then
			card = sgs[name]
		else
			local constituent = sgs.card_constituent[card]
			if constituent then
				return constituent["use_value"] or 0
			end
			return 0
		end
	end
	assert( type(card) == "userdata" )
	local value = 0
	if card:isKindOf("GuhuoCard") then
		local card_str = card:toString()
		local userstring = card_str:split(":")
		local objectName = userstring[3]
		local guhuocard = sgs.Sanguosha:cloneCard(objectName, card:getSuit(), card:getNumber())
		local count = 0
		local alives = global_room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			if sgs.ai_relationship[player:objectName()][p:objectName()] == "opponent" then
				count = count + 1
			end
		end
		value = sgs.getUseValue(guhuocard, player) + count * 0.3
		local subcards = card:getSubcards()
		local id = subcards:first()
		if sgs.Sanguosha:getCard(id):objectName() == objectName then
			if card:getSuit() == sgs.Card_Heart then 
				value = value + 3 
			end
		end
		return value
	end
	local name = sgs.getCardName(card)
	value = sgs.getCardValue(name, "use_value")
	local typeID = card:getTypeId()
	if typeID == sgs.Card_TypeEquip then
	elseif typeID == sgs.Card_TypeBasic then
	elseif typeID == sgs.Card_TypeTrick then
	end
	if player:getHandcardNum() == 1 then
		for _,skill in ipairs(sgs.need_kongcheng) do
			if player:hasSkill(skill) then
				value = 10
				break
			end
		end
	end
	if player:hasWeapon("Halberd") then
		if card:isKindOf("Slash") then
			if player:isLastHandCard(card) then 
				value = 10 
			end
		end
	end
	if player:getPhase() == sgs.Player_Play then 
		value = sgs.adjustUsePriority(player, card, value) 
	end
	return value
end
--[[
	功能：获取针对某角色的卡牌保留价值
	参数：card（Card类型，表示指定的卡牌；或string类型，表示卡牌类型）
		player（ServerPlayer类型，表示作为标准的角色）
		kept（table类型，表示已确定保留的卡牌）
	结果：number类型（value），表示保留价值
]]--
function sgs.getKeepValue(card, player, kept)
	if type(card) == "string" then
		local name = sgs.objectName[card]
		if name and sgs[name] then
			card = sgs[name]
		else
			local constituent = sgs.card_constituent[card]
			if constituent then
				return constituent["keep_value"] or 0
			end
			return 0
		end
	end
	local value = 0
	local class_name = card:getClassName()
	local suit = card:getSuitString()
	local skills = player:getVisibleSkillList()
	local count = 0
	for _,skill in sgs.qlist(skills) do
		local key = skill:objectName() .. "_keep_value"
		if sgs[key] then
			local v = sgs[key][class_name]
			if v then
				count = count + 1
				value = value + v
			end
		end
		key = skill:objectName() .. "_suit_value"
		if sgs[key] then
			local v = sgs[key][suit]
			if v then
				count = count + 1
				value = value + v
			end
		end
	end
	if count > 0 then
		value = value / count
	end
	local keepValue = 0
	if sgs.card_constituent[class_name] then
		keepValue = sgs.card_constituent[class_name]["keep_value"] or 0
	end
	kept = kept or {}
	local MaDai = global_room:findPlayerBySkillName("qianxi")
	for _,c in ipairs(kept) do
		if c:getClassName() == class_name then
			keepValue = keepValue - 1.2
		elseif c:isKindOf("Slash") and card:isKindOf("Slash") then
			keepValue = keepValue - 1
		end
		if MaDai then
			if c:isKindOf("Jink") and class_name == "Jink" then
				if MaDai:distanceTo(player) == 1 then
					if sgs.ai_camp[MaDai:objectName()] ~= sgs.ai_camp[player:objectName()] then
						keepValue = keepValue + 2
					end
				end
			end
		end
	end
	if keepValue > value then
		value = keepValue
	end
	return value
end
--[[
	功能：获取针对某角色的卡牌使用优先级
	参数：card（Card类型，表示指定的卡牌；或string类型，表示卡牌类型）
		player（ServerPlayer类型，表示作为标准的角色）
	结果：number类型（priority），表示使用优先级
]]--
function sgs.getUsePriority(card, player)
	if type(card) == "string" then
		local name = sgs.objectName[card]
		if name and sgs[name] then
			card = sgs[name]
		else
			local constituent = sgs.card_constituent[card]
			if constituent then
				return constituent["use_priority"] or 0
			end
			return 0
		end
	end
	assert( type(card) == "userdata" )
	local priority = 0
	local class_name = card:getClassName()
	if card:isKindOf("EquipCard") then
		local skills = sgs.lose_equip_skill:split("|")
		for _,skill in ipairs(skills) do
			if player:hasSkill(skill) then
				return 15
			end
		end
		if card:isKindOf("Armor") and not player:getArmor() then 
			priority = sgs.getCardValue(class_name, "use_priority") + 5.2
		elseif card:isKindOf("Weapon") and not player:getWeapon() then 
			priority = sgs.getCardValue(class_name, "use_priority") + 3
		elseif card:isKindOf("DefensiveHorse") and not player:getDefensiveHorse() then 
			priority = 5.8
		elseif card:isKindOf("OffensiveHorse") and not player:getOffensiveHorse() then 
			priority = 5.5
		end
		return priority
	end
	local name = sgs.getCardName(card)
	priority = sgs.getCardValue(name, "use_priority")
	priority = sgs.adjustUsePriority(player, card, priority)
	return priority
end
--[[
	功能：按指定成分对一组卡牌进行排序
	参数：cards（table类型，表示待排序的所有卡牌）
		key（string类型，表示作为排序标准的卡牌成分）
		inverse（boolean类型，表示排序方向，true表示由小到大排序，false表示由大到小排序）
	结果：无（cards被改变）
]]--
function SmartAI:sortCards(cards, key, inverse)
	if cards then
		if type(cards) == "userdata" then
			cards = sgs.QList2Table(cards)
		end
		local function compare_func(a, b)
			local classA = a:getClassName()
			local classB = b:getClassName()
			local constituentA = sgs.card_constituent[classA]
			local constituentB = sgs.card_constituent[classA]
			local valueA = 0
			if constituentA then
				valueA = constituentA[key] or 0
			end
			local valueB = 0
			if constituentB then
				valueB = constituentB[key] or 0
			end
			if inverse then
				return valueA < valueB
			else
				return valueA > valueB
			end
		end
		table.sort(cards, compare_func)
	else
		self.room:writeToConsole(debug.traceback())
	end
end
--[[
	功能：按卡牌使用价值排序
	参数：cards（table类型，表示待排序的所有卡牌）
		inverse（boolean类型，表示排序方向，true表示由小到大排序，false表示由大到小排序）
		player（ServerPlayer类型，表示特定的卡牌使用角色）
	结果：无（cards被改变）
]]--
function SmartAI:sortByUseValue(cards, inverse, player)
	if player then
		local values = {}
		for _,card in ipairs(cards) do
			values[card] = sgs.getUseValue(card, player)
		end
		local function compare_func(a, b)
			local valueA = values[a]
			local valueB = values[b]
			if valueA == valueB then
				if inverse then
					return a:getNumber() < b:getNumber()
				else
					return a:getNumber() > b:getNumber()
				end
			else
				if inverse then
					return valueA < valueB
				else
					return valueA > valueB
				end
			end
		end
	else
		self:sortCards(cards, "use_value", inverse)
	end
end
--[[
	功能：按卡牌保留优先级排序
	参数：cards（table类型，表示待排序的所有卡牌）
		inverse（boolean类型，表示排序方向，true表示由大到小排序，false表示由小到大排序）
		player（ServerPlayer类型，表示特定的卡牌保留角色）
		kept（table类型，表示所有已经确定保留的卡牌）
	结果：无（cards被改变）
]]--
function SmartAI:sortByKeepValue(cards, inverse, player, kept)
	if player then
		local values = {}
		for _,card in ipairs(cards) do
			local value = sgs.getKeepValue(card, player, kept)
			value = sgs.adjustUsePriority(player, card, value)
			if card:isKindOf("NatureSlash") then
				value = value - 0.1
			end
			values[card] = value
		end
		local function compare_func(a, b)
			if inverse then
				return values[a] > values[b]
			else
				return values[a] < values[b]
			end
		end
	else
		self:sortCards(cards, "keep_value", not inverse)
	end
end
--[[
	功能：按卡牌使用优先级排序
	参数：cards（table类型，表示待排序的所有卡牌）
		inverse（boolean类型，表示排序方向，true表示由小到大排序，false表示由大到小排序）
		player（ServerPlayer类型，表示特定的卡牌使用角色）
	结果：无（cards被改变）
]]--
function SmartAI:sortByUsePriority(cards, inverse, player)
	if player then
		local priorities = {}
		for _,card in ipairs(cards) do
			priorities[card] = sgs.getUsePriority(card, player)
		end
		local function compare_func(a, b)
			local priorityA = priorities[a]
			local priorityB = priorities[b]
			if priorityA == priorityB then
				if inverse then
					return a:getNumber() < b:getNumber()
				else
					return a:getNumber() > b:getNumber()
				end
			else
				if inverse then
					return priorityA < priorityB
				else
					return priorityA > priorityB
				end
			end
		end
	else
		self:sortCards(cards, "use_priority", inverse)
	end
end
--[[****************************************************************
	判定场景控制
]]--****************************************************************
sgs.ai_wizard_system = {} --判定系统
--[[
	功能：判断一组角色是否拥有判定系列技能
	参数：players（sgs.QList<ServerPlayer*>类型，表示所有待判断的角色）
		harmOnly（boolean类型，表示是否只考虑可以用于制造伤害的判定系列技能）
	结果：boolean类型，表示是否拥有
]]--
function SmartAI:hasWizard(players, harmOnly)
	local skills = nil
	if harmOnly then 
		skills = sgs.wizard_harm_skill 
	else 
		skills = sgs.wizard_skill 
	end
	for _, player in ipairs(players) do
		if self:hasSkills(skills, player) then
			return true
		end
	end
	return false
end
--[[
	功能：判断一名角色是否有能力更改目标角色的判定结果
	参数：player（ServerPlayer类型，表示待判断的角色）
		retrial_target（ServerPlayer类型，表示进行判定的目标角色）
	结果：boolean类型，表示是否有能力
]]--
function SmartAI:canRetrial(player, retrial_target)
	player = player or self.player
	retrial_target = retrial_target or self.player
	for _,item in pairs(sgs.ai_wizard_system) do
		local callback = item["retrial_enabled"]
		if type(callback) == "function" then
			if callback(self, player, retrial_target) then
				return true
			end
		end
	end
	return false
end
--[[
	功能：获取最后进行改判的情况
	参数：player（ServerPlayer类型，表示位于当前视角的角色）
	结果：number类型，表示情况代号（0表示无人改判；1表示友方角色改判；-1表示非友方角色改判）
]]--
function SmartAI:getFinalRetrial(player) 
	local maxfriendseat = -1
	local maxenemyseat = -1
	local tmpfriend
	local tmpenemy
	player = player or self.room:getCurrent()
	local mySeat = player:getSeat()
	local aliveCount = global_room:alivePlayerCount()
	for _,p in ipairs(self.partners) do
		if self:hasSkills(sgs.wizard_harm_skill, p) then
			if self:canRetrial(p, player) then
				tmpfriend = (p:getSeat() - mySeat) % aliveCount
				if tmpfriend > maxfriendseat then 
					maxfriendseat = tmpfriend 
				end
			end
		end
	end
	for _,p in ipairs(self.opponents) do
		if self:hasSkills(sgs.wizard_harm_skill, p) then
			if self:canRetrial(p, player) then
				tmpenemy = (p:getSeat() - mySeat) % aliveCount
				if tmpenemy > maxenemyseat then 
					maxenemyseat = tmpenemy 
				end
			end
		end
	end
	if maxfriendseat == -1 and maxenemyseat == -1 then 
		return 0
	elseif maxfriendseat > maxenemyseat then 
		return 1
	else 
		return -1
	end
end
dofile "lua/ai/imagine-ai.lua" --中心计算文件
--[[
	功能：判断是否有必要改判
	参数：judge（sgs.JudgeStruct类型，表示判定信息）
	结果：boolean类型，表示是否有必要
]]--
function SmartAI:needRetrial(judge)
	local reason = judge.reason --判定原因
	local target = judge.who --判定角色
	--闪电
	if reason == "lightning" then
		if self:hasSkills("wuyan|hongyan", target) then 
			return false 
		end
		for _,lordname in ipairs(sgs.ai_lords) do
			local lord = findPlayerByObjectName(self.room, lordname)
			if self:friendshipLevel(lord) > -3 then
				local need = false
				if self:mayLord(target) then
					need = true
				elseif target:isChained() then
					if lord:isChained() then
						need = true
					end
				end
				if need then
					if lord:hasArmorEffect("SilverLion") then
						if lord:getHp() >= 2 then
							if self:isGoodChainTarget(lord, self.player, sgs.DamageStruct_Thunder) then
								return false
							end
						end
					end
					if not judge:isGood() then
						return self:damageIsEffective(lord, sgs.DamageStruct_Thunder)
					end
				end
			end
		end
		if target:hasArmorEffect("SilverLion") then
			if target:getHp() > 1 then 
				return false 
			end
		end
		if target:isChained() then
			if self:isPartner(target) then
				if self:isGoodChainTarget(target, self.player, sgs.DamageStruct_Thunder, 3) then 
					return false 
				end
			else
				if not self:isGoodChainTarget(target, self.player, sgs.DamageStruct_Thunder, 3) then 
					return judge:isGood() 
				end
			end
		end	
	--乐不思蜀
	elseif reason == "indulgence" then
		if target:isSkipped(sgs.Player_Draw) then
			if target:isKongcheng() then
				local case = false
				if target:hasSkill("shenfen") then
					if target:getMark("@wrath") >= 6 then
						case = true
					end
				end
				if not case then
					if target:hasSkill("kurou") then
						if target:getHp() >= 3 then
							case = true
						end
					end
				end
				if not case then
					if target:hasSkill("jixi") then
						local fields = target:getPile("field")
						if fields:length() > 2 then
							case = true
						end
					end
				end
				if not case then
					if target:hasSkill("lihun") then
						local enemies = self:getOpponents(target)
						if self:isLihunTarget(enemies, 0) then
							case = true
						end
					end
				end
				if not case then
					if target:hasSkill("xiongyi") then
						if target:getMark("@arise") > 0 then
							case = true
						end
					end
				end
				if case then
					if self:isPartner(target) then
						return not judge:isGood()
					else
						return judge:isGood()
					end
				end
			end
		end
		if self:isPartner(target) then
			local skills = target:getVisibleSkillList()
			local count = self:ImitateResult_DrawNCards(target, skills)
			if target:getHp() - target:getHandcardNum() >= count then
				if self:getOverflow() < 0 then 
					return false 
				end
			end
			if target:hasSkill("tuxi") then
				if target:getHp() > 2 then
					if self:getOverflow() < 0 then 
						return false 
					end
				end
			end
			return not judge:isGood()
		else
			return judge:isGood()
		end
	--兵粮寸断
	elseif reason == "supply_shortage" then
		if self:isPartner(target) then
			if self:hasSkills("guidao|tiandu", target) then 
				return false 
			end
			return not judge:isGood()
		else
			return judge:isGood()
		end
	--洛神
	elseif reason == "luoshen" then
		if self:isPartner(target) then
			if target:getHandcardNum() > 30 then 
				return false 
			end  
			if self:isEquip("Crossbow", target) then
				return not judge:isGood()
			elseif sgs.getKnownCard(target, "Crossbow", false) > 0 then 
				return not judge:isGood() 
			end
			if self:getOverflow(target) > 1 then
				if self.player:getHandcardNum() < 3 then 
					return false 
				end
			end
			return not judge:isGood()
		else
			return judge:isGood()
		end
	--屯田
	elseif reason == "tuntian" then
		if not target:hasSkill("zaoxian") then
			if target:getMark("zaoxian") == 0 then 
				return false 
			end
		end
	--悲歌
	elseif reason == "beige" then
		return true
	end
	--一般情形
	if self:isPartner(target) then
		return not judge:isGood()
	elseif self:isOpponent(target) then
		return judge:isGood()
	end
	return false
end
--[[
	功能：获取用于改判的卡牌编号
	参数：cards（table类型，表示卡牌的选取范围）
		judge（sgs.JudgeStruct类型，表示判定信息）
	结果：number类型，表示卡牌编号
]]--
function SmartAI:getRetrialCardId(cards, judge)
	local use_cards = {}
	local reason = judge.reason
	local target = judge.who
	local final = self:getFinalRetrial()
	for _,c in ipairs(cards) do
		local id = c:getId()
		local card = sgs.Sanguosha:getEngineCard(id)
		if target:hasSkill("hongyan") then
			if card:getSuit() == sgs.Card_Spade then
				local name = card:objectName()
				local point = card:getNumber()
				card = sgs.cloneCard(name, sgs.Card_Heart, point)
			end
		end
		local isPeach = sgs.isCard("Peach", card, self.player)
		if reason == "beige" then
			if not isPeach then
				local tag = self.room:getTag("CurrentDamageStruct")
				local damage = tag:toDamage()
				local source = damage.from
				if source then
					local judge_suit = judge.card:getSuit()
					local suit = card:getSuit()
					if self:isPartner(source) then
						local hasSpade = false
						local otherSuits = {}
						if judge_suit ~= sgs.Card_Spade then
							if suit == sgs.Card_Spade then
								if not self:toTurnOver(source) then
									table.insert(use_cards, c)
									flag = false
									hasSpade = true
								end
							end
						end
						if not hasSpade then
							if self:getOverflow() > 0 then
								if suit ~= judge_suit then
									local flag = true
									if judge_suit == sgs.Card_Heart then
										if target:isWounded() then
											if self:isPartner(target) then
												flag = false
											end
										end
									elseif judge_suit == sgs.Card_Club then
										if self:needToThrowArmor(source) then
											flag = false
										end
									elseif judge_suit == sgs.Card_Diamond then
										if target:hasSkill("manjuan") then
											if self:isOpponent(target) then
												if target:getPhase() == sgs.Player_NotActive then
													flag = false
												end
											end
										end
									end
									if flag then
										if suit == sgs.Card_Spade then
											if self:toTurnOver(source, 0) then
												table.insert(otherSuits, c)
											end
										elseif suit == sgs.Card_Heart then
											if target:isWounded() then
												if self:isPartner(target) then
													table.insert(otherSuits, c)
												end
											end
										elseif suit == sgs.Card_Club then
											if self:needToThrowArmor(source) then
												table.insert(otherSuits, c)
											elseif source:isNude() then
												table.insert(otherSuits, c)
											end
										elseif suit == sgs.Card_Diamond then
											local hasManjuan = target:hasSkill("manjuan")
											local notActive = ( target:getPhase() == sgs.Player_NotActive )
											if hasManjuan and notActive then
												if self:isOpponent(target) then
													table.insert(otherSuits, c)
												end
											else
												if self:isPartner(target) then
													table.insert(otherSuits, c)
												end
											end
										end
									end
								end
							end
						end
						if not hasSpade then
							for _,cd in ipairs(otherSuits) do
								table.insert(use_cards, c)
							end
						end
					else
						if judge_suit == sgs.Card_Spade then
							if suit ~= sgs.Card_Spade then
								if not self:toTurnOver(source) then
									table.insert(use_cards, c)
								end
							end
						end
					end
				end
			end
		else
			local isGood = judge:isGood(card)
			local flag = not isPeach
			if not self:getFinalRetrial() == 2 then
				--if not self:DontRespondPeach(judge) then
					flag = true
				--end
			end
			if flag then
				if isGood then
					if self:isPartner(target) then
						table.insert(use_cards, c)
					end
				else
					if self:isOpponent(target) then
						table.insert(use_cards, c)
					end
				end
			end
		end
		if next(use_cards) then
			if self:needToThrowArmor() then
				local armor = self.player:getArmor()
				local armor_id = armor:getEffectiveId()
				for _, c in ipairs(use_cards) do
					local cid = c:getEffectiveId()
					if cid == armor_id then 
						return cid
					end
				end
			end
			self:sortByKeepValue(use_cards)
			return use_cards[1]:getEffectiveId()
		end
	end
	return -1
end
--[[****************************************************************
	触发响应
]]--****************************************************************
--[[
	功能：响应askForCardChosen询问
	参数：who（ServerPlayer类型，表示被选择卡牌的目标角色）
		flags（string类型，表示卡牌的选择范围，"h"：手牌区；"e"：装备区；"j"：判定区）
		reason（string类型，表示询问的原因）
		method（sgs.Card_HandlingMethod类型，表示卡牌移动的方式）
	结果：number类型，表示被选中的卡牌的编号（-1表示不选择任何卡牌）
]]--
function SmartAI:askForCardChosen(who, flags, reason, method) --06
	local isDiscard = ( method == sgs.Card_MethodDiscard )
	reason = string.gsub(reason, "%-", "_")
	--按套路要求响应
	if sgs.SeriesName then
		local response = sgs.ai_series_cardchosen[sgs.SeriesName]
		if response then
			local callback = response[reason]
			if type(callback) == "function" then
				local card = callback(self, who, flags, method)
				if card then
					return card:getEffectiveId()
				end
			end
		end
	end
	--按技能要求响应
	local callback = sgs.ai_skill_cardchosen[reason]
	if callback then
		if type(callback) == "function" then
			local card = callback(self, who, flags, method)
			if card then 
				return card:getEffectiveId() 
			end
		elseif type(callback) == "number" then
			sgs.ai_skill_cardchosen[reason] = nil
			local cards = who:getCards(flags)
			for _,card in sgs.qlist(cards) do
				if card:getEffectiveId() == callback then 
					return callback 
				end
			end
		end
	end
	--一般情形
	if ("snatch|dismantlement|yinling"):match(reason) then
		local flag = "AIGlobal_SDCardChosen_" .. reason
		local to_choose
		local cards = who:getCards("flags")
		for _, card in sgs.qlist(cards) do
			if card:hasFlag(flag) then
				card:setFlags("-" .. flag)
				to_choose = card:getId()
				break
			end
		end
		if to_choose then
			local is_handcard
			if not who:isKongcheng() then
				if who:handCards():contains(to_choose) then 
					is_handcard = true 
				end
			end
			if is_handcard then
				if reason == "dismantlement" then
					if sgs.current_mode == "02_1v1" then
						if sgs.GetConfig("1v1/Rule", "Classical") == "2013" then
							local handcards = who:getHandcards()
							cards = sgs.QList2Table(handcards)
							local peach = nil
							local jink = nil
							for _,card in ipairs(cards) do
								if not peach then
									if sgs.isCard("Peach", card, who) then 
										peach = card:getId() 
									end
								end
								if not jink then
									if sgs.isCard("Jink", card, who) then 
										jink = card:getId() 
									end
								end
								if peach and jink then 
									break 
								end
							end
							if peach or jink then 
								return peach or jink 
							end
							self:sortByKeepValue(cards, true)
							return cards[1]:getEffectiveId()
						end
					end
				end
			end
			return to_choose
		end
	end
	if self:isPartner(who) then
		if flags:match("j") then
			if not who:containsTrick("YanxiaoCard") then
				if not (who:hasSkill("qiaobian") and who:getHandcardNum() > 0) then
					local tricks = who:getCards("j")
					local lightning, indulgence, supply_shortage
					for _, trick in sgs.qlist(tricks) do
						local canDiscard = false
						if not isDiscard then
							canDiscard = true
						elseif self.player:canDiscard(who, trick:getId()) then
							canDiscard = true
						end
						if canDiscard then
							if trick:isKindOf("Lightning") then
								lightning = trick:getId()
							elseif trick:isKindOf("Indulgence") then
								indulgence = trick:getId()
							elseif trick:isKindOf("SupplyShortage") then
								supply_shortage = trick:getId()
							end
						end
					end
					if lightning then
						if self:hasWizard(self.enemies) then
							return lightning
						end
					end
					if indulgence and supply_shortage then
						if who:getHp() < who:getHandcardNum() then
							return indulgence
						else
							return supply_shortage
						end
					end
					if indulgence or supply_shortage then
						return indulgence or supply_shortage
					end
				end
			end
		end
		if flags:match("e") then
			local armor = who:getArmor()
			if armor then
				local armor_id = armor:getEffectiveId()
				if not isDiscard or self.player:canDiscard(who, armor_id) then
					if self:needToThrowArmor(who, reason == "moukui") then
						return armor_id
					end
					if self:evaluateArmor(armor, who) < -5 then
						return armor_id
					end
				end
			end
			if self:hasSkills(sgs.lose_equip_skill, who) then
				if self:isWeak(who) then
					local weapon = who:getWeapon()
					if weapon then
						local weapon_id = weapon:getEffectiveId()
						if not isDiscard or self.player:canDiscard(who, weapon_id) then 
							return weapon_id
						end
					end
					local horse = who:getOffensiveHorse()
					if horse then
						local horse_id = horse:getEffectiveId()
						if not isDiscard or self.player:canDiscard(who, horse_id) then 
							return horse_id
						end
					end
				end
			end
		end
	else
		if flags:match("e") then
			local dangerous = self:getDangerousCard(who)
			if dangerous then
				if not isDiscard or self.player:canDiscard(who, dangerous) then 
					return dangerous 
				end
			end
			if who:hasArmorEffect("EightDiagram") then
				if not self:needToThrowArmor(who, reason == "moukui") then
					local armor = who:getArmor()
					if not isDiscard or self.player:canDiscard(who, armor:getId()) then 
						return armor:getId() 
					end
				end
			end
			if self:hasSkills("jijiu|beige|mingce|weimu|qingcheng", who) then
				if not self:doNotDiscard(who, "e", false, 1, reason) then
					local horse = who:getDefensiveHorse()
					if horse then
						if not isDiscard or self.player:canDiscard(who, horse:getEffectiveId()) then 
							return horse:getEffectiveId() 
						end
					end
					local armor = who:getArmor()
					if armor then
						if not self:needToThrowArmor(who, reason == "moukui") then
							if not isDiscard or self.player:canDiscard(who, armor:getEffectiveId()) then 
								return armor:getEffectiveId() 
							end
						end
					end
					horse = who:getOffensiveHorse()
					if horse then
						if not who:hasSkill("jijiu") or horse:isRed() then
							if not isDiscard or self.player:canDiscard(who, horse:getEffectiveId()) then
								return horse:getEffectiveId()
							end
						end
					end
					local weapon = who:getWeapon()
					if weapon then
						if not who:hasSkill("jijiu") or weapon:isRed() then
							if not isDiscard or self.player:canDiscard(who, weapon:getEffectiveId()) then
								return weapon:getEffectiveId()
							end
						end
					end
				end
			end
			local valuable = self:getValuableCard(who)
			if valuable then
				if not isDiscard or self.player:canDiscard(who, valuable) then
					return valuable
				end
			end
		end
		if flags:match("h") then
			if not isDiscard or self.player:canDiscard(who, "h") then
				if self:hasSkills("jijiu|qingnang|qiaobian|jieyin|beige|buyi|manjuan", who) then
					if not who:isKongcheng() then
						if who:getHandcardNum() <= 2 then
							if not self:doNotDiscard(who, "h", false, 1, reason) then
								return self:getCardRandomly(who, "h")
							end
						end
					end
				end
				local handcards = who:getHandcards()
				local cards = sgs.QList2Table(handcards)
				local flag = string.format("visible_%s_%s", self.player:objectName(), who:objectName())
				if #cards <= 2 then
					if not self:doNotDiscard(who, "h", false, 1, reason) then
						for _, c in ipairs(cards) do
							if c:hasFlag("visible") or c:hasFlag(flag) then
								if sgs.isKindOf("Peach|Analeptic", c) then
									return self:getCardRandomly(who, "h")
								end
							end
						end
					end
				end
			end
		end
		if flags:match("j") then
			local tricks = who:getCards("j")
			local lightning, yanxiao
			for _, trick in sgs.qlist(tricks) do
				if trick:isKindOf("Lightning") then
					if not isDiscard or self.player:canDiscard(who, trick:getId()) then
						lightning = trick:getId()
					end
				elseif trick:isKindOf("YanxiaoCard") then
					if not isDiscard or self.player:canDiscard(who, trick:getId()) then
						yanxiao = trick:getId()
					end
				end
			end
			if lightning then
				if self:hasWizard(self.opponents, true) then
					return lightning
				end
			end
			if yanxiao then
				return yanxiao
			end
		end
		if flags:match("h") then
			if not self:doNotDiscard(who, "h") then
				if self:hasSkills(sgs.cardneed_skill, who) then 
					return self:getCardRandomly(who, "h")
				elseif who:getHandcardNum() == 1 then
					if who:getHp() <= 2 then
						if sgs.getDefenseSlash(who) < 3 then
							return self:getCardRandomly(who, "h")
						end
					end
				end
			end
		end
		if flags:match("e") then
			if not self:doNotDiscard(who, "e") then
				local horse = who:getDefensiveHorse()
				if horse then
					if not isDiscard or self.player:canDiscard(who, horse:getEffectiveId()) then 
						return horse:getEffectiveId() 
					end
				end
				local armor = who:getArmor()
				if armor then
					if not self:needToThrowArmor(who, reason == "moukui") then
						if not isDiscard or self.player:canDiscard(who, armor:getEffectiveId()) then 
							return armor:getEffectiveId() 
						end
					end
				end
				horse = who:getOffensiveHorse()
				if horse then
					if not isDiscard or self.player:canDiscard(who, horse:getEffectiveId()) then 
						return horse:getEffectiveId() 
					end
				end
				local weapon = who:getWeapon()
				if weapon then
					if not isDiscard or self.player:canDiscard(who, weapon:getEffectiveId()) then 
						return weapon:getEffectiveId() 
					end
				end
			end
		end
		if flags:match("h") then
			if not who:isKongcheng() then
				if who:getHandcardNum() <= 2 then
					if not self:doNotDiscard(who, "h", false, 1, reason) then
						return self:getCardRandomly(who, "h")
					end
				end
			end
		end
	end
	return -1
end
--[[
	功能：判断杀对一名角色是否有效
	参数：slash（Card类型，表示使用的杀）
		target（ServerPlayer类型，表示杀的目标角色）
		source（ServerPlayer类型，表示杀的使用角色）
		ignore_armor（boolean类型，表示是否忽略目标角色的防具）
	结果：boolean类型，表示是否有效
]]--
function SmartAI:slashIsEffective(slash, target, source, ignore_armor)
	if slash and target then
		source = source or self.player
		--谋溃
		if not ignore_armor then
			local armor = target:getArmor()
			if armor then
				if source:hasSkill("moukui") then
					if source:objectName() == self.player:objectName() then
						local flag = not self:isPartner(target)
						flag = flag or self:needToThrowArmor(target)
						if flag then
							local id = self:askForCardChosen(target, "he", "moukui")
							if id == armor:getEffectiveId() then 
								ignore_armor = true 
							end
						end
					end
				end
			end
		end
		--杀无效判定
		for _,item in pairs(sgs.slash_invalid_system) do
			local callback = item["judge_func"]
			if type(callback) == "function" then
				if callback(slash, target, source, ignore_armor) then
					return false
				end
			end
		end
		return true
	end
	return false
end
--[[
	功能：判断一名角色是否期待空城
	参数：player（ServerPlayer类型，表示待判断的角色）
		keep（boolean类型，表示该角色是否期待保持空城状态）
	结果：boolean类型，表示是否期待空城
]]--
function SmartAI:needKongcheng(player, keep)
	player = player or self.player
	if keep then
		if player:isKongcheng() then
			if player:hasSkill("kongcheng") then
				return true
			elseif player:hasSkill("zhiji") then
				if player:getMark("zhiji") == 0 then
					return true
				end
			end
		end
		return false
	end
	if not player:hasFlag("stack_overflow_xiangle") then
		if player:hasSkill("beifa") then
			if not player:isKongcheng() then
				local enemies = self:getOpponents(player)
				for _,enemy in ipairs(enemies) do
					if player:canSlash(enemy, sgs.slash) then
						if not self:slashIsProhibited(enemy, player, sgs.slash) then
							if self:slashIsEffective(sgs.slash, enemy, player) then
								if not self:invokeDamagedEffect(enemy, player, sgs.slash) then
									if not self:needToLoseHp(enemy, player, true, true) then
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
	if not player:isKongcheng() then
		if not self:hasLoseHandcardEffective(player) then
			return true
		end
	end
	if player:hasSkill("zhiji") then
		if player:getMark("zhiji") == 0 then 
			return true 
		end
	end
	if player:hasSkill("shude") then
		if player:getPhase() == sgs.Player_Play then 
			return true 
		end
	end
	if self:hasSkills(sgs.need_kongcheng, player) then
		return true
	end
	return false
end
--[[
	功能：判断是否不应要求目标角色弃置卡牌
	参数：target（ServerPlayer类型，表示目标角色）
		flags（string类型，表示待弃置卡牌的位置）
		conservative（boolean类型，表示是否采取保守策略）
		num（number类型，表示将弃牌的数目）
		cannot_choose（boolean类型，表示是否不能选择弃置的牌）
	结果：boolean类型，表示是否有影响
]]--
function SmartAI:doNotDiscard(target, flags, conservative, num, cannot_choose)
	if target:isNude() then 
		return true 
	end
	num = num or 1
	flags = flags or "he"
	if not conservative then
		if sgs.turncount <= 2 then
			if self.room:alivePlayerCount() > 2 then
				conservative = true
			end
		end
	end
	local enemies = self:getOpponents(target)
	if #enemies == 1 then
		if self:hasSkills("noswuyan|qianxun|weimu", enemies[1]) then
			if self.room:alivePlayerCount() == 2 then 
				conservative = false 
			end
		end
	end
	if target:hasSkill("tuntian") then
		if target:hasSkill("zaoxian") then
			if target:getPhase() == sgs.Player_NotActive then
				if conservative then
					return true
				elseif #self.enemies > 1 then 
					return true 
				end
			end
		end
	end
	local handcard_num = target:getHandcardNum()
	if cannot_choose then
		if target:hasSkill("lirang") then
			if self:hasPartners("draw", target) then 
				return true 
			end
		end
		local delt = handcard_num - num
		if self:needKongcheng(target) then
			if delt <= 0 then 
				return true 
			end
		end
		local lost = target:getLostHp()
		if target:hasSkill("shangshi") then
			if delt < math.min(2, lost) then 
				return true 
			end
		end
		if target:hasSkill("nosshangshi") then
			if delt < lost then 
				return true 
			end
		end
		if self:hasSkills(sgs.lose_equip_skill, target) then
			if target:hasEquip() then 
				return true 
			end
		end
		if self:needToThrowArmor(target) then 
			return true 
		end
	else
		if flags:match("e") then
			if target:hasSkill("jieyin") then
				if target:getDefensiveHorse() then
					return false
				end
				local armor = target:getArmor()
				if armor then
					if armor:isKindOf("SilverLion") then
						return false
					end
				end
			end
		end
		local justPlaceHand = false
		if flags == "h" then
			justPlaceHand = true
		elseif flags == "he" then
			if not target:hasEquip() then
				justPlaceHand = true
			end
		end
		if justPlaceHand then
			if target:isKongcheng() then 
				return true 
			end
			if not self:hasLoseHandcardEffective(target) then 
				return true 
			end
			if handcard_num == 1 then
				if self:needKongcheng(target) then 
					return true 
				end
			end
			if #self.partners > 1 then
				if handcard_num == 1 then
					if target:hasSkill("sijian") then 
						return false 
					end
				end
			end
		end
		local justPlaceEquip = false
		if flags == "e" then
			justPlaceEquip = true
		elseif flags == "he" then
			if target:isKongcheng() then
				justPlaceEquip = true
			end
		end
		local cards_num = target:getCardCount(true)
		if justPlaceEquip then
			if not target:hasEquip() then 
				return true 
			end
			if self:hasSkills(sgs.lose_equip_skill, target) then 
				return true 
			end
			if cards_num == 1 then
				if self:needToThrowArmor(target) then 
					return true 
				end
			end
		end
		if flags == "he" then
			if num == 2 then
				if cards_num < 2 then 
					return true 
				end
				if not target:hasEquip() then
					if not self:hasLoseHandcardEffective(target) then
						return true 
					end
					if handcard_num <= 2 then
						if self:needKongcheng(target) then 
							return true 
						end
					end
				end
				if self:hasSkills(sgs.lose_equip_skill, target) then
					if handcard_num < 2 then 
						return true 
					end
				end
				if cards_num <= 2 then
					if self:needToThrowArmor(target) then 
						return true 
					end
				end
			elseif num > 2 then
				if cards_num < num then 
					return true 
				end 
			end
		end
	end
	return false
end
--[[
	功能：获取一名角色装备的有威胁的卡牌的编号
	参数：who（ServerPlayer类型，表示目标角色）
	结果：number类型，表示卡牌编号
]]--
function SmartAI:getDangerousCard(who)
	local weapon = who:getWeapon()
	if weapon then
		if weapon:isKindOf("Crossbow") then
			if sgs.getCardsNum("Slash", who) > 0 then
				for _,friend in ipairs(self.partners) do
					if who:distanceTo(friend) <= 1 then
						return weapon:getEffectiveId()
					end
				end
			end
		elseif weapon:isKindOf("GudingBlade") then
			if sgs.getCardsNum("Slash", who) > 0 then
				for _,friend in ipairs(self.partners) do
					if who:inMyAttackRange(friend) then
						if friend:isKongcheng() then
							if not friend:hasSkills("kongcheng|tianming") then
								return weapon:getEffectiveId()
							end
						end
					end
				end
			end
		elseif weapon:isKindOf("Spear") then
			if who:hasSkill("paoxiao") then
				if who:getHandcardNum() >= 1 then
					return weapon:getEffectiveId()
				end
			end
		elseif weapon:isKindOf("Axe") then
			if self:hasSkills("luoyi|neoluoyi|pojun|jiushi|jiuchi|jie|wenjiu|shenli|jieyuan", who) then
				return weapon:getEffectiveId()
			end
		elseif weapon:isKindOf("SPMoonSpear") then
			if self:hasSkills("guidao|longdan|longhun|guicai|jilve|huanshi|qingguo|kanpo", who) then
				return weapon:getEffectiveId()
			end
		end
		if who:hasSkill("liegong") then
			return weapon:getEffectiveId()
		end
	end
	local armor = who:getArmor()
	if armor then
		if armor:isKindOf("EightDiagram") then
			if who:hasSkill("leiji") then 
				return armor:getEffectiveId() 
			end
			if who:getKingdom() == "wei" then
				for _,lordname in ipairs(sgs.ai_lords) do
					local lord = findPlayerByObjectName(self.room, lordname)
					if self:isOpponent(lord) then
						if self:isFriend(lord, who) then
							return armor:getEffectiveId()
						end
					end
				end
			end
		end
	end
end
--[[
	功能：获取一名角色装备的有价值的卡牌的编号
	参数：who（ServerPlayer类型，表示目标角色）
	结果：number类型，表示卡牌编号
]]--
function SmartAI:getValuableCard(who)
	local weapon = who:getWeapon()
	local armor = who:getArmor()
	local offhorse = who:getOffensiveHorse()
	local defhorse = who:getDefensiveHorse()
	self:sort(self.partners, "hp")
	local friend = nil
	if #self.partners > 0 then 
		friend = self.partners[1] 
	end
	local range = who:getAttackRange()
	if friend then
		if self:isWeak(friend) then
			local distance = who:distanceTo(friend)
			if distance > 1 then
				if distance <= range then
					if not self:doNotDiscard(who, "e", true) then
						if weapon then
							return weapon:getEffectiveId()
						end
						if offhorse then
							return offhorse:getEffectiveId()
						end
					end
				end
			end
		end
	end
	if weapon then
		if weapon:isKindOf("MoonSpear") then
			if self:hasSkills("keji|conghui", who) then
				if who:getHandcardNum() > 5 then
					return weapon:getEffectiveId()
				end
			end
		end
		if self:hasSkills("qiangxi|zhulou|taichen", who) then
			return weapon:getEffectiveId()
		end 
	end
	local canDiscard = not self:doNotDiscard(who, "e")
	if defhorse then
		if canDiscard then
			return defhorse:getEffectiveId()
		end
	end
	if armor then
		if canDiscard then
			if self:evaluateArmor(armor, who) > 3 then
				if not self:needToThrowArmor(who) then
					return armor:getEffectiveId()
				end
			end
		end
	end
	if offhorse then
		if self:hasSkills("nosqianxi|kuanggu|duanbing|qianxi", who) then
			return offhorse:getEffectiveId()
		end
	end
	local equips = who:getEquips()
	for _,equip in sgs.qlist(equips) do
		if who:hasSkill("longhun") then
			if not equip:getSuit() == sgs.Card_Diamond then 
				return equip:getEffectiveId() 
			end
		end
		if self:hasSkills("guose|yanxiao", who) then
			if equip:getSuit() == sgs.Card_Diamond then 
				return equip:getEffectiveId() 
			end
		end
		if who:hasSkill("baobian") then
			if who:getHp() <= 2 then 
				return equip:getEffectiveId() 
			end
		end
		if self:hasSkills("qixi|duanliang|yinling|guidao", who) then
			if equip:isBlack() then 
				return equip:getEffectiveId() 
			end
		end
		if self:hasSkills("wusheng|jijiu|xueji|nosfuhun", who) then
			if equip:isRed() then 
				return equip:getEffectiveId() 
			end
		end
		if self:hasSkills(sgs.need_equip_skill, who) then
			if not self:hasSkills(sgs.lose_equip_skill, who) then 
				return equip:getEffectiveId() 
			end
		end
	end
	if armor then
		if canDiscard then
			if not self:needToThrowArmor(who) then
				return armor:getEffectiveId()
			end
		end
	end
	if offhorse then
		if who:getHandcardNum() > 1 then
			if not self:doNotDiscard(who, "e", true) then
				for _,friend in ipairs(self.partners) do
					if who:distanceTo(friend) == range then
						if range > 1 then
							return offhorse:getEffectiveId()
						end
					end
				end
			end
		end
	end
	if weapon then
		if who:getHandcardNum() > 1 then
			if not self:doNotDiscard(who, "e", true) then
				for _,friend in ipairs(self.partners) do
					local dist = who:distanceTo(friend)
					if dist <= range then
						if dist > 1 then
							return weapon:getEffectiveId()
						end
					end
				end
			end
		end
	end
end
--[[
	功能：找个角色摸牌
	参数：include_self（boolean类型，表示是否考虑自己）
		count（number类型，表示摸牌的数目）
	结果：ServerPlayer类型（friend），表示推荐摸牌的角色
]]--
function SmartAI:findPlayerToDraw(include_self, count)
	count = count or 1
	local players = nil
	if include_self then
		players = self.room:getAlivePlayers()
	else
		players = self.room:getOtherPlayers(self.player)
	end
	local friends = {}
	for _, player in sgs.qlist(players) do
		if self:isPartner(player) then
			local flag = true
			if player:hasSkill("manjuan") then
				if player:getPhase() == sgs.Player_NotActive then
					flag = false
				end
			end
			if flag then
				if player:hasSkill("kongcheng") then
					if player:isKongcheng() then
						if count <= 2 then
							flag = false
						end
					end
				end
			end
			if flag then
				if not self:willSkipPlayPhase(friend) then
					table.insert(friends, player)
				end
			end
		end
	end
	if #friends > 0 then
		self:sort(friends, "defense")
		for _, friend in ipairs(friends) do
			if friend:getHandcardNum() < 2 then
				if not self:needKongcheng(friend) then
					return friend
				end
			end
		end
		for _, friend in ipairs(friends) do
			if self:hasSkills(sgs.cardneed_skill, friend) then
				return friend
			end
		end
		self:sort(friends, "handcard")
		for _, friend in ipairs(friends) do
			if not self:needKongcheng(friend) then
				return friend
			end
		end
	end
	return nil
end
--[[
	功能：找个角色弃牌
	参数：flags（string类型，表示弃牌的选择范围）
		include_self（boolean类型，表示是否考虑自身）
		isDiscard（boolean类型，表示是否以弃置的方式弃牌）
		players（sgs.QList<ServerPlayer*>类型，表示所有待考察的目标角色）
	结果：ServerPlayer类型，表示被选出的目标角色
]]--
function SmartAI:findPlayerToDiscard(flags, include_self, isDiscard, players)
	if isDiscard == nil then 
		isDiscard = true 
	end
	flags = flags or "he"
	local friends = nil
	local enemies = nil
	if players then
		friends = {}
		enemies = {}
		for _,p in sgs.qlist(players) do
			if self:isPartner(p) then
				if include_self then
					table.insert(friends, p)
				elseif self.player:objectName() ~= p:objectName() then
					table.insert(friends, p)
				end
			else
				table.insert(enemies, p)
			end
		end
	else
		if include_self then
			friends = self.partners
		else
			friends = self.partners_noself
		end
		enemies = self.opponents
	end
	self:sort(enemies, "defense")
	if flags:match("e") then
		for _, enemy in ipairs(enemies) do
			if self.player:canDiscard(enemy, "e") then
				local dangerous = self:getDangerousCard(enemy)
				if dangerous then
					if not isDiscard then
						return enemy
					elseif self.player:canDiscard(enemy, dangerous) then
						return enemy
					end
				end
			end
		end
		for _, enemy in ipairs(enemies) do
			if enemy:hasArmorEffect("EightDiagram") then
				if not self:needToThrowArmor(enemy) then
					local armor = enemy:getArmor()
					if self.player:canDiscard(enemy, armor:getEffectiveId()) then
						return enemy
					end
				end
			end
		end
	end
	if flags:match("j") then
		for _, friend in ipairs(friends) do
			local flag = false
			if friend:containsTrick("supply_shortage") then
				flag = true
			elseif friend:containsTrick("indulgence") then
				if not friend:hasSkill("keji") then
					flag = true
				end
			end
			if flag then
				if not friend:containsTrick("YanxiaoCard") then
					if not friend:hasSkill("qiaobian") or friend:isKongcheng() then
						if not isDiscard or self.player:canDiscard(friend, "j") then
							return friend
						end
					end
				end
			end
		end
		if self:hasWizard(enemies, true) then
			for _, friend in ipairs(friends) do
				if friend:containsTrick("lightning") then
					if not isDiscard or self.player:canDiscard(friend, "j") then 
						return friend 
					end
				end
			end
			for _, enemy in ipairs(enemies) do
				if enemy:containsTrick("lightning") then
					if not isDiscard or self.player:canDiscard(enemy, "j") then 
						return enemy 
					end
				end
			end
		end
	end
	if flags:match("e") then
		for _, friend in ipairs(friends) do
			if self:needToThrowArmor(friend) then
				local armor = friend:getArmor()
				if not isDiscard or self.player:canDiscard(friend, armor:getEffectiveId()) then
					return friend
				end
			end
		end
		for _, enemy in ipairs(enemies) do
			if self.player:canDiscard(enemy, "e") then
				local valuable = self:getValuableCard(enemy)
				if valuable then
					if not isDiscard or self.player:canDiscard(enemy, valuable) then
						return enemy
					end
				end
			end
		end
		for _, enemy in ipairs(enemies) do
			if self:hasSkills("jijiu|beige|mingce|weimu|qingcheng", enemy) then
				if not self:doNotDiscard(enemy, "e") then
					local horse = enemy:getDefensiveHorse()
					if horse then
						if not isDiscard or self.player:canDiscard(enemy, horse:getEffectiveId()) then 
							return enemy 
						end
					end
					local armor = enemy:getArmor()
					if armor then
						if not self:needToThrowArmor(enemy) then
							if not isDiscard or self.player:canDiscard(enemy, armor:getEffectiveId()) then 
								return enemy 
							end
						end
					end
					horse = enemy:getOffensiveHorse()
					if horse then
						if not enemy:hasSkill("jijiu") or horse:isRed() then
							if not isDiscard or self.player:canDiscard(enemy, horse:getEffectiveId()) then
								return enemy
							end
						end
					end
					local weapon = who:getWeapon()
					if weapon then
						if not enemy:hasSkill("jijiu") or weapon:isRed() then
							if not isDiscard or self.player:canDiscard(enemy, weapon:getEffectiveId()) then
								return enemy
							end
						end
					end
				end
			end
		end
	end
	if flags:match("h") then
		for _, enemy in ipairs(enemies) do
			local handcards = enemy:getHandcards()
			local cards = sgs.QList2Table(handcards)
			local flag = string.format("visible_%s_%s", self.player:objectName(), enemy:objectName())
			if #cards <= 2 then
				if not enemy:isKongcheng() then
					if not enemy:hasSkills("tuntian+zaoxian") or enemy:getPhase() ~= sgs.Player_NotActive then
						for _, c in ipairs(cards) do
							if c:hasFlag("visible") or c:hasFlag(flag) then
								if sgs.isKindOf("Peach|Analeptic", c) then
									if not isDiscard or self.player:canDiscard(enemy, c:getId()) then
										return enemy
									end
								end
							end
						end
					end
				end
			end
		end
	end
	if flags:match("e") then
		for _, enemy in ipairs(enemies) do
			if enemy:hasEquip() then
				if not self:doNotDiscard(enemy, "e") then
					if not isDiscard or self.player:canDiscard(enemy, "e") then
						return enemy
					end
				end
			end
		end
	end
	if flags:match("j") then
		for _, enemy in ipairs(enemies) do
			if enemy:containsTrick("YanxiaoCard") then
				if not isDiscard or self.player:canDiscard(enemy, "j") then 
					return enemy 
				end
			end
		end
	end
	if flags:match("h") then
		self:sort(enemies, "handcard")
		for _, enemy in ipairs(enemies) do
			if not isDiscard or self.player:canDiscard(enemy, "h") then
				if not self:doNotDiscard(enemy, "h") then
					return enemy
				end
			end
		end
	end
	if flags:match("h") then
		local ZhuGeLiang = self.room:findPlayerBySkillName("kongcheng")
		if ZhuGeLiang then
			if self:isPartner(ZhuGeLiang) then
				if ZhuGeLiang:getHandcardNum() == 1 then
					if self:getOpponentNumBySeat(self.player, ZhuGeLiang) > 0 then
						if ZhuGeLiang:getHp() <= 2 then
							if not isDiscard or self.player:canDiscard(ZhuGeLiang, "h") then
								return ZhuGeLiang
							end
						end
					end
				end
			end
		end
	end
end
--[[
	功能：响应askForSuit询问
	参数：reason（string类型，表示询问的原因）
	结果：number类型，表示花色代号（0：黑桃；1：红心；2：草花；3：方块）
]]--
function SmartAI:askForSuit(reason) --01
	reason = reason or "fanjian"
	--按套路要求响应
	if sgs.SeriesName then
		local response = sgs.ai_series_suit[sgs.SeriesName]
		if response then
			local callback = response[reason]
			if callback then
				return callback(self)
			end
		end
	end
	--按技能要求响应
	local callback = sgs.ai_skill_suit[reason]
	if callback and type(callback) == "function" then
		if callback(self) then 
			return callback(self) 
		end
	end
	--默认处理
	return math.random(0, 3)
end
--[[
	功能：响应askForSkillInvoke询问
	参数：skill_name（string类型，表示待发动的技能）
		data（sgs.QVariant类型，表示环境数据）
	结果：boolean类型，表示是否发动技能（true：发动；false：不发动）
]]--
function SmartAI:askForSkillInvoke(skill_name, data) --02
	skill_name = string.gsub(skill_name, "%-", "_")
	--按套路要求响应
	if sgs.SeriesName then
		local response = sgs.ai_series_invoke[sgs.SeriesName]
		if response then
			local callback = response[skill_name]
			if type(callback) == "boolean" then
				return callback
			elseif type(callback) == "function" then
				return callback(self, data)
			end
		end
	end
	--按技能要求响应
	local invoke = sgs.ai_skill_invoke[skill_name]
	if invoke then
		if type(invoke) == "boolean" then
			return invoke
		elseif type(invoke) == "function" then
			return invoke(self, data)
		end
	end
	--默认处理
	local skill = sgs.Sanguosha:getSkill(skill_name)
	if skill then
		return skill:getFrequency() == sgs.Skill_Frequent
	end
	return false
end
--[[
	功能：响应askForChoice询问
	参数：skill_name（string类型，表示发起询问的技能）
		choices（string类型，表示以“+”分隔的各备选项）
		data（sgs.QVariant类型，表示环境数据）
	结果：string类型，表示选择的项目
]]--
function SmartAI:askForChoice(skill_name, choices, data) --03
	--按套路要求响应
	if sgs.SeriesName then
		local response = sgs.ai_series_choice[sgs.SeriesName]
		if response then
			local callback = response[skill_name]
			if type(callback) == "string" then
				return callback
			elseif type(callback) == "function" then
				return callback(self, choices, data)
			end
		end
	end
	--按技能要求响应
	local choice = sgs.ai_skill_choice[skill_name]
	if choice then
		if type(choice) == "string" then
			return choice
		elseif type(choice) == "function" then
			return choice(self, choices, data)
		end
	end
	--默认处理
	local skill = sgs.Sanguosha:getSkill(skill_name)
	if skill then
		local default = skill:getDefaultChoice(self.player)
		if choices:match(default) then
			return default
		end
	end
	local choice_table = choices:split("+")
	for index, ch in ipairs(choice_table) do
		if ch == "benghuai" then 
			table.remove(choice_table, index) 
			break 
		end
	end
	local r = math.random(1, #choice_table)
	return choice_table[r]
end
--[[
	功能：响应askForDiscard询问
	参数：reason（string类型，表示询问弃牌的原因）
		discard_num（number类型，表示需要弃牌的数目）
		min_num（number类型，表示最少需要弃牌的数目）
		optional（boolean类型，表示弃牌是否可选，true：可以不弃牌；false：强制弃牌）
		include_equip（boolean类型，表示是否可以弃装备区的牌，true：可以弃装备牌；false：只弃手牌）
	结果：table类型，表示所有要弃掉的卡牌编号的集合
]]--
function SmartAI:askForDiscard(reason, discard_num, min_num, optional, include_equip) --04
	min_num = min_num or discard_num
	local exchange = self.player:hasFlag("Global_AIDiscardExchanging")
	--按套路要求响应
	if sgs.SeriesName then
		local response = sgs.ai_series_discard[sgs.SeriesName]
		if response then
			local callback = response[reason]
			if callback then
				local ids = callback(self, discard_num, min_num, optional, include_equip)
				if type(ids) == "number" then
					local card = sgs.Sanguosha:getCard(ids)
					if not self.player:isJilei(card) then
						return {ids}
					end
				elseif type(ids) == "table" then
					if not exchange then
						for _,id in ipairs(ids) do
							local card = sgs.Sanguosha:getCard(id)
							if self.player:isJilei(card) then
								return {}
							end
						end
					end
					return ids
				end
			end
		end
	end
	--按技能要求响应
	local callback = sgs.ai_skill_discard[reason]
	if callback and type(callback) == "function" then
		local ids = callback(self, discard_num, min_num, optional, include_equip)
		if ids then
			if type(ids) == "number" then
				local card = sgs.Sanguosha:getCard(ids)
				if not self.player:isJilei(card) then
					return {ids}
				end
			end
			if type(ids) == "table" then
				for _,id in ipairs(ids) do
					if not exchange then
						local card = sgs.Sanguosha:getCard(id)
						if self.player:isJilei(card) then
							return {}
						end
					end
				end
				return ids
			end
			return {}
		end
	--默认处理
	elseif optional then
		return {}
	end
	local to_discard = {}
	local flag = "h"
	if include_equip then
		local equips = self.player:getEquips()
		if equips:isEmpty() then
			flag = flag .. "e"
		elseif not self.player:isJilei(equips:first()) then 
			flag = flag .. "e"
		end
	end
	local cards = self.player:getCards(flag)
	cards = sgs.QList2Table(cards)
	local function aux_func(card)
		local id = card:getEffectiveId()
		local place = self.room:getCardPlace(id)
		if place == sgs.Player_PlaceEquip then
			if card:isKindOf("SilverLion") then
				if self.player:isWounded() then 
					return -2
				end
			end
			if card:isKindOf("Weapon") then
				if self.player:getHandcardNum() < discard_num + 2 then
					if not self:needKongcheng() then 
						return 0
					end
				end
			end
			if card:isKindOf("OffensiveHorse") then
				if self.player:getHandcardNum() < discard_num + 2 then
					if not self:needKongcheng() then 
						return 0
					end
				end
			end
			if card:isKindOf("OffensiveHorse") then 
				return 1
			elseif card:isKindOf("Weapon") then 
				return 2
			elseif card:isKindOf("DefensiveHorse") then 
				return 3
			elseif self:hasSkills("bazhen|yizhong") then
				if card:isKindOf("Armor") then 
					return 0
				end
			end
			if card:isKindOf("Armor") then 
				return 4
			end
		elseif self:hasSkills(sgs.lose_equip_skill) then 
			return 5
		else 
			return 0
		end
	end
	local compare_func = function(a, b)
		local auxA = aux_func(a)
		local auxB = aux_func(b)
		if auxA ~= auxB then 
			return auxA < auxB 
		end
		return sgs.getCardValue(a, "keep_value") < sgs.getCardValue(b, "keep_value")
	end
	table.sort(cards, compare_func)
	local least = min_num
	if discard_num - min_num > 1 then
		least = discard_num - 1
	end
	for _,card in ipairs(cards) do
		if self.player:hasSkill("qinyin") then
			if #to_discard >= least then
				break
			end
		end
		if #to_discard >= discard_num then 
			break 
		end
		local id = card:getId()
		if exchange or not self.player:isJilei(card) then 
			table.insert(to_discard, id) 
		end
	end
	return to_discard
end
--[[
	功能：响应askForNullification询问
	参数：trick（Card类型，表示）
		from（ServerPlayer类型，表示）
		to（ServerPlayer类型，表示）
		positive（boolean类型，表示）
	结果：Card类型（null_card），表示使用的无懈可击
]]--
function SmartAI:askForNullification(trick, from, to, positive) --05
	--按套路要求响应
	if sgs.SeriesName then
		local response = sgs.ai_series_null[sgs.SeriesName]
		if response then
			return response(self, trick, from, to, positive)
		end
	end
	--按技能要求响应
	--一般处理
	if self.player:isDead() then 
		return nil 
	end
	local null_card = self:getCardId("Nullification") --无懈可击
	if null_card then 
		null_card = sgs.Card_Parse(null_card) 
	else --没有无懈可击 
		return nil 
	end
	if self.player:isLocked(null_card) then 
		return nil 
	end
	if from and from:isDead() then --已死
		return nil
	elseif to and to:isDead() then 
		return nil 
	end 
	if self.player:hasSkill("wumou") then
		if self.player:getMark("@wrath") == 0 then
			if self:isWeak() then 
				return nil 
			elseif self:amLord() then
				return nil
			end
		end
	end
	if trick:isKindOf("FireAttack") then
		if to:isKongcheng() then
			return nil
		elseif from:isKongcheng() then 
			return nil 
		end
		if self.player:objectName() == from:objectName() then
			if self.player:getHandcardNum() == 1 then
				if self.player:handCards():first() == null_card:getId() then 
					return nil 
				end
			end
		end
	end
	if ("snatch|dismantlement"):match(trick:objectName()) then
		if to:isAllNude() then 
			return nil 
		end
	end
	if self:isPartner(to) then
		if to:hasFlag("AIGlobal_NeedToWake") then 
			return nil
		end
	end
	if from and not from:hasSkill("jueqing") then
		if sgs.isKindOf("Duel|FiraAttack|AOE", trick) then --“绝情”“无言”、决斗、火攻、AOE 
			if to:hasSkill("wuyan") then
				return nil
			elseif self:invokeDamagedEffect(to, from) then
				if self:isPartner(to) then
					return nil
				end
			end
		end 
		if sgs.isKindOf("Duel|AOE", trick) then--决斗、AOE 
			if not self:damageIsEffective(to, sgs.DamageStruct_Normal) then 
				return nil 
			end 
		end
		if trick:isKindOf("FireAttack") then --火攻
			if not self:damageIsEffective(to, sgs.DamageStruct_Fire) then 
				return nil 
			end 
		end
	end
	if sgs.isKindOf("Duel|FireAttack|AOE", trick) then
		if self:needToLoseHp(to, from) then --扣减体力有利
			if self:isPartner(to) then
				return nil 
			end
		end
	end
	local null_num = self:getCardsNum("Nullification")
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	--准备使用无懈可击--
	if positive then
		if from then
			if sgs.isKindOf("FireAttack|Duel|AOE", trick) then
				if self:isPartner(from) then 
					if self:needDeath(to) then
						return null_card
					elseif self:cannotBeHurt(to, 1, from) then	
						return null_card 
					end
					return
				end
			end
		end
		if ("snatch|dismantlement"):match(trick:objectName()) then
			if not to:containsTrick("YanxiaoCard") then
				if to:containsTrick("indulgence") or to:containsTrick("supply_shortage") then
					if self:isOpponent(from) then 
						return null_card 
					end
					if self:isPartner(to) then
						if to:isNude() then 
							return nil 
						end
					end
				end
			end
		end
		if trick:getSkillName() == "lijian" then
			if trick:isKindOf("Duel") then
				if self:isPartner(to) then
					if self:isWeak(to) then
						return null_card 
					elseif null_num > 1 then
						return null_card 
					elseif self:getOverflow() then
						return null_card 
					elseif not self:isWeak() then 
						return null_card 
					end
					return
				end
			end
		end
		if from then
			if self:isOpponent(from) then
				if self.player:hasSkill("kongcheng") then
					if self.player:getHandcardNum() == 1 then
						if self.player:isLastHandCard(null_card) then
							if trick:isKindOf("SingleTargetTrick") then
								return null_card
							end
						end
					end
				end
				if trick:isKindOf("ExNihilo") then
					if self:isWeak(from) then
						return null_card 
					elseif self:hasSkills(sgs.cardneed_skill, from) then
						return null_card 
					elseif from:hasSkill("manjuan") then 
						return null_card 
					end
				end
				if trick:isKindOf("IronChain") then
					if not to:hasArmorEffect("Vine") then 
						return nil 
					end
				end
				if self:isFriend(to) then
					if trick:isKindOf("Dismantlement") then
						if self:getDangerousCard(to) then
							return null_card 
						elseif self:getValuableCard(to) then 
							return null_card 
						end
						if to:getHandcardNum() == 1 then
							if not self:needKongcheng(to) then
								if sgs.getKnownCard(to, "TrickCard", false) == 1 then
									return nil
								elseif sgs.getKnownCard(to, "EquipCard", false) == 1 then
									return nil
								elseif sgs.getKnownCard(to, "Slash", false) == 1 then
									return nil
								end
								return null_card
							end
						end
					else
						if trick:isKindOf("Snatch") then 
							return null_card 
						end
						if trick:isKindOf("Duel") then
							if not from:hasSkill("wuyan") then
								if self:isWeak(to) then 
									return null_card 
								end
							end
						end
						if trick:isKindOf("FireAttack") then
							if from:objectName() ~= to:objectName() then
								if not from:hasSkill("wuyan") then
									if from:getHandcardNum() > 2 then
										return null_card 
									elseif self:isWeak(to) then
										return null_card 
									elseif to:hasArmorEffect("Vine") then
										return null_card 
									elseif to:getMark("@gale") > 0 then
										return null_card 
									elseif to:isChained() then
										if not self:isGoodChainTarget(to) then
											return null_card 
										end
									end
								end
							end
						end
					end
				elseif self:isEnemy(to) then
					if sgs.isKindOf("Snatch|Dismantlement", trick) then
						if to:getCards("j"):length() > 0 then
							return null_card
						end
					end
				end
			end
		end
		if self:isPartner(to) then
			if not to:hasSkill("guanxing") or global_room:alivePlayerCount() <= 4 then 
				if trick:isKindOf("Indulgence") then
					if to:getHp() - to:getHandcardNum() >= 2 then 
						return nil 
					end
					if to:hasSkill("tuxi") then
						if to:getHp() > 2 then 
							return nil 
						end
					end
					if to:hasSkill("qiaobian") then
						if not to:isKongcheng() then 
							return nil 
						end
					end
					return null_card
				elseif trick:isKindOf("SupplyShortage") then
					if self:hasSkills("guidao|tiandu", to) then 
						return nil 
					end
					if to:getMark("@kuiwei") == 0 then --溃围？
						return nil 
					end
					if to:hasSkill("qiaobian") then
						if not to:isKongcheng() then 
							return nil 
						end
					end
					return null_card
				end
			end
			if trick:isKindOf("AOE") then
				local MengHuo = self.room:findPlayerBySkillName("huoshou") --祸首
				local flag = false
				if not from:hasSkill("wuyan") then
					flag = true
				elseif MengHuo then
					if trick:isKindOf("SavageAssault") then
						flag = true
					end
				end
				if flag then
					local lord = sgs.ai_lord[self.player:objectName()]
					if lord then
						lord = findPlayerByObjectName(self.room, lord)
					end
					local current = self.room:getCurrent()
					local current_seat = current:getSeat()
					local aliveCount = self.room:alivePlayerCount()
					local to_dist = (to:getSeat() - current_seat) % aliveCount
					if lord then
						if self:isWeak(lord) then
							if self:aoeIsEffective(trick, lord) then 
								local lord_dist = (lord:getSeat() - current_seat) % aliveCount
								if lord_dist > to_dist then
									if self.player:objectName() ~= to:objectName() then
										return nil
									elseif self.player:getHp() ~= 1 then
										return nil
									elseif self:canAvoidAOE(trick) then
										return nil
									end
								end
							end
						end
					end
					if self.player:objectName() == to:objectName() then
						if self:hasSkills("jieming|yiji|guixin", self.player) then
							if self.player:getHp() > 1 then
								return nil
							elseif self:getCardsNum("Peach") > 0 then
								return nil
							elseif self:getCardsNum("Analeptic") > 0 then
								return nil
							end
						end
						if not self:canAvoidAOE(trick) then
							return null_card
						end
					end
					if self:isWeak(to) then
						if self:aoeIsEffective(trick, to) then
							local my_dist = (self.player:getSeat() - current_seat) % aliveCount
							if to_dist > my_dist then
								return null_card
							elseif null_num > 1 then
								return null_card
							elseif self:canAvoidAOE(trick) then
								return null_card
							elseif self.player:getHp() > 1 then
								return null_card
							elseif self:mayLord(to) then
								if self:amLoyalist() then
									return null_card
								end
							end
						end
					end
				end
				if trick:isKindOf("Duel") then
					if not from:hasSkill("wuyan") then
						if self.player:objectName() == to:objectName() then
							if self:hasSkills(sgs.masochism_skill, self.player) then 
								if self.player:getHp() > 1 then
									return nil
								elseif self:getCardsNum("Peach") > 0 then
									return nil
								elseif self:getCardsNum("Analeptic") > 0 then
									return nil
								end
							end
							if self:getCardsNum("Slash") == 0 then
								return null_card
							end
						end
					end
				end
			end
			if from then
				if self:isOpponent(to) then
					if trick:isKindOf("GodSalvation") then
						if self:isWeak(to) then
							return null_card
						end
					end
				end
			end
		end
		--waiting for more details
	else
		if from then
			if sgs.isKindOf("FireAttack|Duel|AOE", trick) then
				if self:needDeath(to) or self:cannotBeHurt(to, 1, from) then
					if self:isEnemy(from) then 
						return null_card 
					end
					return
				end
			end
			if trick:getSkillName() == "lijian" then
				if trick:isKindOf("Duel") then
					if self:isEnemy(to) then
						if self:isWeak(to) then
							return null_card
						elseif null_num > 1 then
							return null_card
						elseif self:getOverflow() then
							return null_card
						elseif not self:isWeak() then 
							return null_card 
						end
						return
					end
				end
			end
			if from:objectName() == to:objectName() then
				if self:isFriend(from) then 
					return null_card 
				else 
					return 
				end
			end
			if not trick:isKindOf("GlobalEffect") then
				if not trick:isKindOf("AOE") then
					if self:isFriend(from) then
						local flag = true
						if ("snatch|dismantlement"):match(trick:objectName()) then
							if to:isNude() then
								flag = false
							end
						end
						if flag then
							if trick:isKindOf("FireAttack") then
								if to:isKongcheng() then
									flag = false
								end
							end
						end
						if flag then	
							return null_card 
						end
					end
				end
			end
		else
			if self:isEnemy(to) then
				return null_card 
			end
		end
	end
end
--[[
	功能：响应askForCard询问
	参数：pattern（string类型，表示所需卡牌的样式）
		prompt（string类型，表示以“:”分割的提示信息）
		data（sgs.QVariant类型，表示环境数据）
	结果：string类型，表示卡牌的具体使用方法
]]--
function SmartAI:askForCard(pattern, prompt, data) --07
--self.room:writeToConsole("AskForCard:pattern="..pattern..",prompt="..prompt)
	local promptlist = prompt:split(":")
	local reason = promptlist[1]
	local nameA = promptlist[2]
	local nameB = promptlist[3]
	local argA = promptlist[4]
	local argB = promptlist[5]
	local targetA = nil
	local targetB = nil
	if nameA then
		local players = self.room:getPlayers()
		for _,p in sgs.qlist(players) do
			if p:getGeneralName() == nameA then
				targetA = p
				break
			elseif p:objectName() == nameA then
				targetA = p
				break
			end
		end
		if nameB then
			for _,p in sgs.qlist(players) do
				if p:getGeneralName() == nameB then
					targetB = p
					break
				elseif p:objectName() == nameB then
					targetB = p
					break
				end
			end
		end
	end
	--按套路要求响应
	if sgs.SeriesName then
		local response = sgs.ai_series_cardask[sgs.SeriesName]
		if response then
			local callback = response[reason]
			if type(callback) == "function" then
				local result = callback(self, data, pattern, targetA, targetB, argA, argB)
				if result then
					return result
				end
			end
		end
	end
	--按技能要求响应
	local callback = sgs.ai_skill_cardask[reason]
	if callback and type(callback) == "function" then
		local ret = callback(self, data, pattern, targetA, targetB, argA, argB)
		if ret then 
			return ret 
		end
	end
	--默认处理
	if data then
		if type(data) == "number" then
			return nil
		end
	end
	local ignore_func = sgs.ai_skill_cardask["nullfilter"]
	if pattern == "slash" then
		if not ignore_func(self, data, pattern, target) then
			local slash = self:getCardId("Slash") or "."
			if slash == "." then
				sgs.card_lack[self.player:objectName()]["Slash"] = 1
			end
			return slash
		end
	elseif pattern == "jink" then
		if not ignore_func(self, data, pattern, target) then
			local jink = self:getCardId("Jink") or "."
			if jink == "." then
				sgs.card_lack[self.player:objectName()]["Jink"] = 1
			end
			return jink
		end
	end
end
--[[
	功能：响应askForUseCard询问
	参数：pattern（string类型，表示所需卡牌的样式）
		prompt（string类型，表示以“:”分割的提示信息）
		method（类型，表示卡牌移动方式）
	结果：string类型，表示卡牌的具体使用方法（"."表示不使用）
	备注：包含了询问askForUseSlashTo的情形
]]--
function SmartAI:askForUseCard(pattern, prompt, method) --08
	--按套路要求响应
	if sgs.SeriesName then
		local response = sgs.ai_series_use[sgs.SeriesName]
		if response then
			local callback = response[pattern]
			if callback then
				return callback(self, prompt, method) or "."
			end
		end
	end
	--按技能要求响应
	local use_func = sgs.ai_skill_use[pattern]
	if use_func then
		return use_func(self, prompt, method) or "."
	end
	--默认处理
	return "."
end
--[[
	功能：响应askForAG询问
	参数：card_ids（table类型，表示五谷窗口中各卡牌的编号）
		refusable（boolean类型，表示选牌是否可以拒绝，true：可以不选；false：至少选择一张）
		reason（string类型，表示询问选牌的原因）
	结果：number类型（id），表示选出的卡牌编号
]]--
function SmartAI:askForAG(card_ids, refusable, reason) --09
	local ag_reason = string.gsub(reason, "%-", "_")
	--按套路要求响应
	if sgs.SeriesName then
		local response = sgs.ai_series_askforag[sgs.SeriesName]
		if response then
			local callback = response[ag_reason]
			if type(callback) == "function" then
				local id = callback(self, card_ids)
				if id then
					return id
				end
			end
		end
	end
	--按技能要求响应
	local callback = sgs.ai_skill_askforag[ag_reason]
	if callback and type(callback) == "function" then
		local id = callback(self, card_ids)
		if id then 
			return id 
		end
	end
	--默认处理
	if refusable then
		if reason == "xinzhan" then
			local next_player = self.player:getNextAlive()
			if self:isPartner(next_player) then
				if next_player:containsTrick("indulgence") then
					if not next_player:containsTrick("YanxiaoCard") then
						if #card_ids == 1 then 
							return -1 
						end
					end
				end
			end
			for _,card_id in ipairs(card_ids) do
				return card_id
			end
			return -1
		end
	end
	local cards = {}
	for _,id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		table.insert(cards, card)
	end
	for _,card in ipairs(cards) do
		if card:isKindOf("Peach") then 
			return card:getEffectiveId() 
		end
	end
	if not self:isWeak() or self:getCardsNum("Jink") ~= 0 then 
		for _,card in ipairs(cards) do
			if card:isKindOf("Indulgence") then
				return card:getEffectiveId() 
			elseif card:isKindOf("AOE") then
				return card:getEffectiveId() 
			end
		end
	end
	self:sortByCardNeed(cards)
	local index = #cards
	return cards[index]:getEffectiveId()
end
--[[
	功能：响应askForCardShow询问
	参数：requestor（ServerPlayer类型，表示发起请求的角色）
		reason（string类型，表示询问的原因）
	结果：
]]--
function SmartAI:askForCardShow(requestor, reason) --10
	--按套路要求响应
	if sgs.SeriesName then
		local response = sgs.ai_series_cardshow[sgs.SeriesName]
		if response then
			local callback = response[reason]
			if callback then
				return callback(self, requestor)
			end
		end
	end
	--按技能要求响应
	local func = sgs.ai_skill_cardshow[reason]
	if func then
		return func(self, requestor)
	--默认处理
	else
		return self.player:getRandomHandCard()
	end
end
--[[
	功能：响应askForYiji询问
	参数：card_ids（类型，表示所有观看的卡牌的编号）
		reason（string类型，表示询问分牌的原因）
	结果：第一项为ServerPlayer类型，表示目标角色
		第二项为number类型，表示分给该目标角色的卡牌的编号
]]--
function SmartAI:askForYiji(card_ids, reason) --11
	if reason then
		reason = string.gsub(reason,"%-","_")
		--按套路要求响应
		if sgs.SeriesName then
			local response = sgs.ai_series_askforyiji[sgs.SeriesName]
			if response then
				local callback = response[reason]
				if type(callback) == "function" then
					local target, id = callback(self, card_ids)
					if target and id then
						return target, id
					end
				end
			end
		end
		--按技能要求响应
		local callback = sgs.ai_skill_askforyiji[reason]
		if callback and type(callback) == "function" then
			local target, id = callback(self, card_ids)
			if target and id then 
				return target, id 
			end
		end
	end
	return nil, -1
end
--[[
	功能：响应askForPindian询问
	参数：requestor（ServerPlayer类型，表示发起拼点请求的角色）
		reason（string类型，表示拼点的原因）
	结果：
]]--
function SmartAI:askForPindian(requestor, reason) --12
	local handcards = self.player:getHandcards()
	handcards = sgs.QList2Table(handcards)
	
	local compare_func = function(a, b)
		return a:getNumber() < b:getNumber()
	end
	table.sort(handcards, compare_func)
	
	local mincard = handcards[1]
	local maxcard = handcards[#handcards]
	--按套路要求响应
	if sgs.SeriesName then
		local response = sgs.ai_series_pindian[sgs.SeriesName]
		if response then
			local callback = response[reason]
			if type(callback) == "function" then
				local result = callback(self, requestor, maxcard, mincard)
				if result then
					return result
				end
			end
		end
	end
	--按技能要求响应
	local callback = sgs.ai_skill_pindian[reason]
	if callback and type(callback) == "function" then
		local ret = callback(self, requestor, maxcard, mincard)
		if ret then 
			return ret 
		end
	end
	--默认处理
	if self:isPartner(requestor) then 
		return mincard 
	else 
		return maxcard 
	end
end
--[[
	功能：响应askForPlayerChosen询问
	参数：targets（sgs.QList<ServerPlayer*>类型，表示待选择的所有角色）
		reason（string类型，表示选择的原因）
	结果：ServerPlayer类型（target），表示被选出的角色
]]--
function SmartAI:askForPlayerChosen(targets, reason) --13
	reason = string.gsub(reason, "%-", "_")
	--按套路要求响应
	if sgs.SeriesName then
		local response = sgs.ai_series_playerchosen[sgs.SeriesName]
		if response then
			local callback = response[reason]
			if type(callback) then
				return callback(self, targets)
			end
		end
	end
	--按技能要求响应
	local callback = sgs.ai_skill_playerchosen[reason]
	local target = nil
	if type(callback) == "function" then
		target = callback(self, targets)
	end
	return target
end
--[[
	功能：响应askForSinglePeach询问
	参数：dying（ServerPlayer类型，表示当前濒死的角色）
	结果：string类型，表示卡牌的具体使用方式（"."表示不救）
]]--
function SmartAI:askForSinglePeach(dying) --14
	--按套路要求响应
	if sgs.SeriesName then
		local response = sgs.ai_series_peach[sgs.SeriesName]
		if type(response) == "function" then
			return response(self, dying)
		end
	end
	--按技能要求响应
	--默认处理
	local card_str = self:willUsePeachTo(dying)
	if card_str then
		return card_str
	end
	return "."
end
--[[
	内容：按游戏规则统计卡牌数目
]]--
sgs.card_count_system["gamerule"] = {
	name = "gamerule",
	pattern = "",
	ratio = 1,
	statistics_func = function(class_name, player, data)
		local count = 0
		if class_name == "Slash" then
			if data["flag"] then
				count = data["already"]
			else
				count = data["count"]
				count = count + data["unknown"] * 0.35
			end
			if player:hasSkill("wushuang") then
				count = count * 2
			end
		elseif class_name == "Jink" then
			if data["flag"] then
				count = data["already"]
			else
				count = data["count"]
				count = count + data["unknown"] * 0.6
			end
		else
			if data["flag"] then
				count = data["already"]
			else
				count = data["count"]
			end
		end
		return count
	end
}
--[[
	功能：判断是否需要采取忍戒策略
	参数：player（ServerPlayer类型，表示待判断的角色）
	结果：boolean类型，表示是否需要
]]--
function SmartAI:needBear(player)
	player = player or self.player
	if player:hasSkills("renjie+baiyin") then
		if not player:hasSkill("jilve") then
			if player:getMark("@bear") < 4 then
				return true
			end
		end
	end
	return false
end
--[[
	内容：按游戏规则弃牌（弃牌阶段弃牌）
]]--
sgs.ai_skill_discard["gamerule"] = function(self, discard_num, min_num)
	local handcards = self.player:getHandcards()
	local cards = sgs.QList2Table(handcards)
	local to_discard = {}
	
	local peaches = {}
	local jinks = {} 
	local analeptics = {}
	local nullifications = {}
	local slashes = {}
	local keepdata = {
		"peach1", 
		"peach2", 
		"jink1", 
		"peach3", 
		"analeptic", 
		"jink2", 
		"nullification", 
		"slash",
	}
	if not self:isWeak() then
		local flag = false
		if self.player:getHp() > sgs.getBestHp(self.player) then
			flag = true
		elseif self:invokeDamagedEffect(self.player) then
			flag = true
		elseif not sgs.isGoodTarget(self, self.player) then
			flag = true
		end
		if flag then
			keepdata = {
				"peach1", 
				"peach2", 
				"analeptic", 
				"peach3", 
				"nullification", 
				"slash",
			}
		end
	end
	local keeparr = {}
	for _, name in ipairs(keepdata) do 
		keeparr[name] = nil 
	end
	local function compare_func(a, b)
		local v1 = sgs.adjustUsePriority(self.player, a, 1)
		local v2 = sgs.adjustUsePriority(self.player, b, 1)
		if a:isKindOf("NatureSlash") then 
			v1 = v1 - 0.1 
		end
		if b:isKindOf("NatureSlash") then 
			v2 = v2 - 0.1 
		end
		return v1 < v2 
	end
	local function resetCards(allcards, keepcards)
		local result = {}
		for _, acard in ipairs(allcards) do
			local found = false
			for _, keepcard in pairs(keepcards) do
				if keepcard then
					if keepcard:getEffectiveId() == acard:getEffectiveId() then
						found = true
						break
					end
				end
			end
			if not found then 
				table.insert(result, acard) 
			end
		end
		return result
	end
	for _, card in ipairs(cards) do
		if sgs.isCard("Peach", card, self.player) then 
			table.insert(peaches, card) 
		end
	end	
	table.sort(peaches, compare_func)
	if #peaches >= 1 and table.contains(keepdata, "peach1") then 
		keeparr.peach1 = peaches[1] 
	end
	if #peaches >= 2 and table.contains(keepdata, "peach2") then 
		keeparr.peach2 = peaches[2] 
	end
	if #peaches >= 3 and table.contains(keepdata, "peach3") then 
		keeparr.peach3 = peaches[3] 
	end
	cards = resetCards(cards, keeparr)	
	for _, card in ipairs(cards) do
		if sgs.isCard("Jink", card, self.player) then 
			table.insert(jinks, card)
		end
	end
	table.sort(jinks, compare_func)
	if #jinks >= 1 and table.contains(keepdata, "jink1") then 
		keeparr.jink1 = jinks[1] 
	end
	if #jinks >= 2 and table.contains(keepdata, "jink2") then 
		keeparr.jink2 = jinks[2] 
	end
	cards = resetCards(cards, keeparr)	
	for _, card in ipairs(cards) do
		if sgs.isCard("Analeptic", card, self.player) then 
			table.insert(analeptics, card) 
		end
	end
	table.sort(analeptics, compare_func)
	if #analeptics >= 1 and table.contains(keepdata, "analeptic") then 
		keeparr.analeptic = analeptics[1] 
	end
	cards = resetCards(cards, keeparr)	
	for _, card in ipairs(cards) do
		if sgs.isCard("Nullification", card, self.player) then 
			table.insert(nullifications, card) 
		end
	end
	table.sort(nullifications, compare_func)
	if #nullifications >= 1 and table.contains(keepdata, "nullification") then 
		keeparr.nullification = nullifications[1] 
	end
	cards = resetCards(cards, keeparr)	
	for _, card in ipairs(cards) do
		if sgs.isCard("Slash", card, self.player) then 
			table.insert(slashes, card) 
		end
	end
	table.sort(slashes, compare_func)
	if #slashes >= 1 and table.contains(keepdata, "slash") then 
		keeparr.slash = slashes[1] 
	end
	cards = resetCards(cards, keeparr)
	self:sortByUseValue(cards)
	self:sortByKeepValue(cards, true)
	local sortedCards = {}
	for _, name in ipairs(keepdata) do
		if keeparr[name] then 
			table.insert(sortedCards, keeparr[name]) 
		end
	end
	for _, card in ipairs(cards) do
		table.insert(sortedCards, card)
	end
	local least = min_num
	if discard_num - min_num > 1 then
		least = discard_num - 1
	end
	for i=#sortedCards, 1, -1 do
		local card = sortedCards[i]
		if not self.player:isJilei(card) then			
			table.insert(to_discard, card:getId())
		end
		if self.player:hasSkill("qinyin") and #to_discard >= least then
			break
		elseif #to_discard >= discard_num then
			break
		elseif self.player:isKongcheng() then 
			break 
		end
	end
	return to_discard
end
--[[
	内容：选择伤害目标
]]--
sgs.ai_skill_playerchosen["damage"] = function(self, targets)
	local players = sgs.QList2Table(targets)
	self:sort(players, "hp")
	for _, target in ipairs(players) do
		if self:isOpponent(target) then 
			return target 
		end
	end
	for _,target in ipairs(players) do
		if self:isTempFriend(target) then
			return target
		end
	end
	return players[#players]
end
--[[
	内容：不响应卡牌询问
]]--
sgs.ai_skill_cardask["nullfilter"] = function(self, data, pattern, target)
	if self.player:isDead() then 
		return "." 
	end
	local nature = sgs.DamageStruct_Nature
	local effect = nil
	if type(data) == "userdata" then
		effect = data:toSlashEffect()
		if effect and effect.slash then
			nature = effect.nature
			--原版解烦
			if effect.slash:hasFlag("nosjiefan-slash") then
				local tag = self.room:getTag("NosJiefanTarget")
				local dying = tag:toPlayer()
				local HanDang = self.room:findPlayerBySkillName("nosjiefan")
				if self:isPartner(dying) then
					if not self:isOpponent(HanDang) then 
						return "." 
					end
				end
			end
		end
	end
	if effect then
		--高伤害
		if self:hasHeavySlashDamage(target, effect.slash, self.player) then
			return nil
		end
		--原版潜袭
		local source = effect.from
		if source then
			if source:hasSkill("nosqianxi") then
				if source:distanceTo(self.player) == 1 then
					return nil
				end
			end
		end
	end
	--绝情
	if target then
		if target:hasSkill("jueqing") then
			if self:needToLoseHp() then
				return "."
			else
				return nil
			end
		end
	end
	if self:damageIsEffective(nil, nature, target) then
		if target then
			--刮骨
			if target:hasSkill("guagu") then
				if self.player:isLord() then
					return "."
				end
			end
			--寒冰剑
			if effect then
				if target:hasWeapon("IceSword") then
					local cards = self.player:getCards("he")
					if cards:length() > 1 then
						return nil
					end
				end
			end
			--不施救
			if self:mayRebel(target) then
				if self:amRebel() then
					if self.player:hasFlag("AI_doNotSave") then
						return "."
					end
				end
			end
			--需要死亡
			if self:needDeath() then
				return "."
			end
		end
		if self:needToLoseHp() then
			return "."
		end
		--卖血需求
		if self:invokeDamagedEffect(self.player, target) then
			return "."
		end
		local hp = self.player:getHp()
		--忍戒
		if self:needBear() then
			if hp > 2 then
				return "."
			end
		end
		--自立
		if self.player:hasSkill("zili") then
			if not self.player:hasSkill("paiyi") then
				if self.player:getLostHp() < 2 then
					return "."
				end
			end
		end
		--无谋
		if self.player:hasSkill("wumou") then
			if self.player:getMark("@wrath") < 7 then
				if hp > 2 then
					return "."
				end
			end
		end
		--天香
		if self.player:hasSkill("tianxiang") then
			local damageStruct = {
				["damage"] = 1,
				["nature"] = nature or sgs.DamageStruct_Normal
			}
			local callback = sgs.ai_skill_use["@@tianxiang"]
			if callback and callback(self, damageStruct) ~= "." then
				return "."
			end
		end
		--龙魂
		if self.player:hasSkill("longhun") then
			if hp > 1 then
				return "."
			end
		end
	else
		return "."
	end
end
--[[****************************************************************
	出牌活动总控制
]]--****************************************************************
dofile "lua/ai/series-ai.lua" --出牌套路注册文件
--[[
	功能：初始化出牌环境
	参数：无
	结果：无
]]--
function SmartAI:initEnvironment()
	if not sgs.slash then
		sgs.slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	end
	self.slashAvail = sgs.Sanguosha:correctCardTarget(
		sgs.TargetModSkill_Residue, self.player, sgs.slash
		) + 1
	if self:isEquip("Crossbow") then
		sgs.slashAvail = 100
	end
	self.slashTargets = sgs.Sanguosha:correctCardTarget(
		sgs.TargetModSkill_ExtraTarget, self.player, sgs.slash
		) + 1
	self.slashDistLimit = sgs.Sanguosha:correctCardTarget(
		sgs.TargetModSkill_DistanceLimit, self.player, sgs.slash
		) + 1
	self.slashIsDistLimited = ( self.slashDistLimit > 50 )
	self.predictedRange = self.player:getAttackRange()
	if self.player:hasFlag("InfinityAttackRange") then
		self.predictedRange = 10000
	elseif self.player:getMark("InfinityAttackRange") > 0 then
		self.predictedRange = 10000
	end
end
--[[
	功能：获取可用的技能卡
	参数：handcards（table类型，表示所有可用于构成技能卡的手牌）
	结果：table类型（skillcards），表示所有可用的技能卡
]]--
function SmartAI:getUsableSkillCards(handcards)
	local skillcards = {}
	for index, skill in pairs(sgs.ai_skills) do
		local skillname = skill["name"]
		if skillname then
			local isLordSkill = skill["lordskill"]
			local hasSkill = false
			if isLordSkill then
				if self.player:hasLordSkill(skillname) then
					hasSkill = true
				end
			elseif self.player:hasSkill(skillname) then
				hasSkill = true
			end
			if hasSkill then --检验是否有此技能
				local enabled = skill["enabled"]
				if enabled and enabled(self, handcards) then --检验此技能是否可以发动
					local callback = skill["dummyCard"]
					if callback and type(callback) == "function" then --检验发动是否产生技能卡
						local dummyCard = callback(self) --产生技能卡
						if dummyCard then
							dummyCard:setFlags("isDummy") --设置标记
							table.insert(skillcards, dummyCard) --添加到技能卡表
						end
					end
				end
			end
		end
	end
	return skillcards
end
--[[
	功能：对现有卡牌产生可行的出牌序列
	参数：handcards（sgs.QList<Card*>类型，表示可供使用的手牌）
	结果：table类型（series），表示可行的出牌序列
]]--
function SmartAI:getSeries(handcards)
	local series = {} --待产生的出牌序列
	--开始新的出牌序列
	if #series == 0 then
		local cards = sgs.QList2Table(handcards)
		--移除不能使用和重铸的卡牌
		for index, card in ipairs(cards) do
			local method = card:getHandlingMethod()
			if self.player:isCardLimited(card, method) then
				if card:canRecast() then
					if self.player:isCardLimited(card, sgs.Card_MethodRecast) then
						table.remove(cards, index)
					end
				else
					table.remove(cards, index)
				end
			end
		end
		--获取可用的技能卡
		local skillcards = self:getUsableSkillCards(cards)
		--产生序列
		local allcards = sgs.ConcatTable(skillcards, cards)
		if #allcards > 0 then --存在可用的卡牌（包括实际卡牌和技能卡；此时的技能卡为其dummyCard）
			self:sortCards(allcards, "use_priority") --按使用优先级排序
			for _,card in ipairs(allcards) do --选取优先级最高的卡牌作为序列代表卡牌
				local name = sgs.getCardName(card)
				local actions = sgs.ai_card_actions[name] --含有当前技能卡的行动序列名集合，table<string>类型
				if actions then
					actions = sgs.sortSeriesByUsePriority(actions) --按使用优先级排序
					for _,action in pairs(actions) do
						local ai_series = sgs.ai_series[action] --当前考察的行动序列
						if ai_series then
							local series_name = ai_series["name"] --当前考察的序列名
							if self:checkSeries(series_name, cards, skillcards) then --可以使用该序列
								series = ai_series["action"](self, cards, skillcards) or {} --产生具体的出牌序列
								if #series > 0 then --序列产生成功
									sgs.SeriesName = series_name
									return series
								else
									self:windUpSeries("Consider", series_name)
								end
							end
						end
					end
				end
			end
		end
	end
	return series
end
--[[
	功能：按出牌序列产生当前应使用的卡牌
	参数：handcards（sgs.QList<Card*>类型，表示当前可用的手牌）
	结果：Card类型（card），表示当前应使用的卡牌
]]--
function SmartAI:getTurnUseCard(handcards)
	local card = nil
	--继续原有的出牌序列
	if sgs.SeriesName then
		if #sgs.ai_current_series > 0 then --原有出牌序列还有牌可出
			local break_func = sgs.ai_series[sgs.SeriesName]["break_condition"] --获取序列中断检测函数
			if break_func and break_func(self) then --中断原有出牌序列
msg("break:"..sgs.SeriesName)
				self:windUpSeries("Break")
			else --继续按原序列出牌
				card = sgs.ai_current_series[1]
				sgs.ai_current_card = card
				table.remove(sgs.ai_current_series, 1) 
				return card
			end
		end
	end
	--产生新的出牌序列
	sgs.ai_current_series = self:getSeries(handcards)
	if #sgs.ai_current_series > 0 then
		card = sgs.ai_current_series[1]
		sgs.ai_current_card = card
		table.remove(sgs.ai_current_series, 1)
	end
	return card
end
--[[
	功能：主动出牌
	参数：use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:activate(use)
self.room:writeToConsole("\nActivate:"..self.player:getGeneralName().."("..self.player:objectName()..")")
	self:updatePlayers() --更新角色间关系
	self:initEnvironment() --初始化出牌环境
	repeat 
		local handcards = self.player:getCards("h") --获取所有手牌
		local card = self:getTurnUseCard(handcards)
		if card then 
			assert(sgs.SeriesName)
			local type = card:getTypeId()
			local key = "use" .. sgs.ai_type_name[type + 1]
self.room:writeToConsole("key="..key..", series="..sgs.SeriesName)
			self[key](self, card, use) --使用卡牌
			if use:isValid(nil) then --产生了有效的可以使用的卡牌
				local name = sgs.getCardName(use.card)
				table.insert(sgs.ai_card_history, name) --记录卡牌使用历史
				sgs.ai_current_card = nil
				return 
			else --卡牌无效
				self:windUpSeries("InValid") --中止出牌序列
			end
		else
			return 
		end
	until false
end
--[[
	功能：使用特定卡牌
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useCardByClassName(card, use)
	if card then
		local class_name = card:getClassName()
		local key = "useCard" .. class_name
		local use_func = self[key]
		if use_func then
			use_func(self, card, use)
		end
	else
		global_room:writeToConsole(debug.traceback()) 
	end
end
--[[
	功能：使用技能卡
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useSkillCard(card, use)
	local name = sgs.getCardName(card)
	--按照套路特殊要求使用技能卡
	local state = sgs.useCardInSeries(self, card, use, name)
	if state == "NOTHING" then
	elseif state ~= "ERROR" then
		return 
	end
	--按照一般情形使用技能卡
	local use_func = sgs.ai_skill_use_func[name]
	if use_func then --按照技能卡自身要求使用
		use_func(self, card, use)
		if use.to then
			if not use.to:isEmpty() then
				--检查技能卡中是否有有效伤害成分
				local damage = sgs.getCardValue(name, "damage")
				if damage > 0 then
					for _,target in sgs.qlist(use.to) do
						if self:damageIsEffective(target) then
							return 
						end
					end
					use.card = nil
				end
			end
		end
	else --按照一般卡牌使用
		if card:hasFlag("isDummy") then
			card:setFlags("-isDummy")
			local callback = sgs.ai_view_as_func[name]
			if type(callback) == "function" then
				card = callback(self, card)
				if not card then
					return 
				end
			end
		end
		local key = "useCard" .. name
		use_func = self[key]
		if use_func then
			use_func(self, card, use)
		end
	end
end
--[[
	功能：使用基本牌
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useBasicCard(card, use)
	if card then
		local name = sgs.getCardName(card)
		if card:hasFlag("isDummy") then 
			card:setFlags("-isDummy")
			local callback = sgs.ai_view_as_func[name]
			if type(callback) == "function" then
				card = callback(self, card)
				if not card then
					return 
				end
			end
		end
		--按照套路特殊要求使用技能卡
		local state = sgs.useCardInSeries(self, card, use, name)
		if state == "NOTHING" then
		elseif state ~= "ERROR" then
			return 
		end
		--按照一般情形使用技能卡
--[[		if self.player:hasSkill("ytchengxiang") then
			if card:getNumber() < 7 then
				if self.player:getHandcardNum() < 8 then
					return 
				end
			end
		end]]--
		--if self:shouldUseRende() then
			--return 
		--end
--[[		if self:needBear() then
			if not (card:isKindOf("Peach") and self.player:getLostHp() > 1) then
				return 
			end
		end]]--
		self:useCardByClassName(card, use)
	else
		global_room:writeToConsole(debug.traceback()) 
	end
end
--[[
	功能：使用锦囊牌
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useTrickCard(card, use)
	if card then
		local name = sgs.getCardName(card)
		if card:hasFlag("isDummy") then
			card:setFlags("-isDummy")
			local callback = sgs.ai_view_as_func[name]
			if type(callback) == "function" then
				card = callback(self, card)
				if not card then
					return 
				end
			end
		end
		--按照套路特殊要求使用技能卡
		local state = sgs.useCardInSeries(self, card, use, name)
		if state == "NOTHING" then
		elseif state ~= "ERROR" then
			return 
		end
		--按照一般情形使用技能卡
		if self.player:hasSkill("ytchengxiang") then
			if self.player:getHandcardNum() < 8 then
				if card:getNumber() < 7 then 
					return 
				end
			end
		end
--[[		if self:needBear() then
			if not sgs.isKindOf("AmazingGrace|ExNihilo|Snatch|IronChain|Collateral", card) then 
				return 
			end
		end
		if self.player:hasSkill("wumou") then
			if self.player:getMark("@wrath") < 7 then
				if not sgs.isKindOf("AOE|DelayedTrick|IronChain", card) then
					if not (card:isKindOf("Duel") and self.player:getMark("@wrath") > 0) then 
						return
					end
				end
			end
		end]]--
		-- if self:shouldUseRende() then
			-- if not card:isKindOf("ExNihilo") then 
				-- return 
			-- end
		-- end
--[[		if card:isKindOf("AOE") then
			local others = self.room:getOtherPlayers(self.player)
			local avail_num = others:length()
			local avail_friends = 0
			for _, other in sgs.qlist(others) do
				if self.room:isProhibited(self.player, other, card) then
					avail_num = avail_num - 1
				elseif self:isPartner(other) then
					avail_friends = avail_friends + 1
				end
			end
			if avail_num < 1 then 
				return 
			end
			local MengHuo = nil
			if card:isKindOf("SavageAssault") then 
				MengHuo = self.room:findPlayerBySkillName("huoshou") 
			end
			local flag = false
			if self.player:hasSkill("noswuyan") then
				flag = true
			elseif self.player:hasSkill("wuyan") then
				if not self.player:hasSkill("jueqing") then
					if not MengHuo then
						flag = true
					elseif avail_num <= 1 then
						flag = true
					elseif MengHuo:hasSkill("wuyan") then
						if not MengHuo:hasSkill("jueqing") then
							flag = true
						end
					end
				end
			end
			if flag then
				if self.player:hasSkill("huangen") then
					if self.player:getHp() > 0 then
						if avail_num > 1 then
							if avail_friends > 0 then 
								use.card = card 
							else 
								return 
							end
						end
					end
				end
			end
			if sgs.current_mode:find("p") then
				if sgs.current_mode >= "04p" then
					if sgs.turncount < 2 then
						if card:isKindOf("ArcheryAttack") then
							if self:amLoyalist() then
								return 
							elseif self:amLord() then
								if self:getOverflow() < 1 then
									return 
								end
							end
						elseif card:isKindOf("SavageAssault") then
							if self:amRebel() then
								return 
							end
						end
					end
				end
			end
			if self:getAoeValue(card) > 0 then
				use.card = card
			end
		end]]--
		self:useCardByClassName(card, use)
--[[		if not card:isKindOf("AOE") then
			if use.to and not use.to:isEmpty() then
				local name = sgs.getCardName(card)
				if sgs.getCardValue(name, "damage") > 0 then
					local nature = sgs.DamageStruct_Normal
					if card:isKindOf("FireAttack") then
						nature = sgs.DamageStruct_Fire
					end
					for _,target in sgs.qlist(use.to) do
						if self:damageIsEffective(target, nature) then 
							return 
						end
					end
					use.card = nil
				end
			end
		end]]--
	else
		global_room:writeToConsole(debug.traceback()) 
	end
end
--[[
	功能：使用装备牌
	参数：card（Card类型，表示待使用的卡牌）
		use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构）
	结果：无
]]--
function SmartAI:useEquipCard(card, use)
	if card then
		local name = sgs.getCardName(card)
		if card:hasFlag("isDummy") then
			card:setFlags("-isDummy")
			local callback = sgs.ai_view_as_func[name]
			if type(callback) == "function" then
				card = callback(self, card)
				if not card then
					return 
				end
			end
		end
		--按照套路特殊要求使用技能卡
		local state = sgs.useCardInSeries(self, card, use, name)
		if state == "NOTHING" then
		elseif state ~= "ERROR" then
			return 
		end
		--按照一般情形使用技能卡
--[[		if self.player:hasSkill("ytchengxiang") then
			if self.player:getHandcardNum() < 8 then
				if card:getNumber() < 7 then
					if self:getSameTypeEquip(card) then 
						return 
					end
				end
			end
		end
		if self:hasSkills("kofxiaoji|xiaoji") then
			if self:evaluateArmor(card) > -5 then
				use.card = card
				return
			end
		end
		if self:hasSkills(sgs.lose_equip_skill) then
			if self:evaluateArmor(card) > -5 then
				if #self.opponents > 0 then
					use.card = card
					return
				end
			end
		end
		if self.player:getHandcardNum() <= 2 then
			if self:needKongcheng() then
				if self:evaluateArmor(card) > -5 then
					use.card = card
					return
				end
			end
		end
		local same = self:getSameTypeEquip(card)
		if same then
			if self.player:hasSkill("nosgongqi") then
				if sgs.slash:isAvailable(self.player) then
					return 
				end
			end
			-- if self.player:hasSkills("nosrende") then
				-- if self:shouldUseRende() then
					-- if self:hasPartners("draw") then
						-- return 
					-- end
				-- end
			-- end
			-- if self.player:hasSkill("rende") then
				-- if not self.player:hasUsed("RendeCard") then
					-- if self:shouldUseRende() then
						-- if self:hasFriends("draw") then
							-- return 
						-- end
					-- end
				-- end
			-- end
			if self:hasSkills("yongsi|renjie") then
				if self:getOverflow() < 2 then
					return 
				end
			end
			if self:hasSkills("qixi|duanliang|yinling") then
				if card:isBlack() then
					return 
				elseif same:isBlack() then
					return 
				end
			end
			if self:hasSkills("guose|longhun|noslonghun") then
				if not card:isKindOf("Crossbow") then
					if card:getSuit() == sgs.Card_Diamond then
						return 
					elseif same:getSuit() == sgs.Card_Diamond then
						return 
					end
				end
			end
			if self.player:hasSkill("jijiu") then
				if card:isRed() then
					return 
				elseif same:isRed() then
					return 
				end
			end
			if self.player:hasSkill("guidao") then
				if same:isBlack() then
					if card:isRed() then 
						return 
					end
				end
			end
		end]]--
		self:useCardByClassName(card, use)
--[[		if use.card or use.broken then 
			return 
		end]]--
		--Waiting For More Details
	else
		global_room:writeToConsole(debug.traceback()) 
	end
end
--[[
	功能：寻找自己可能拥有的一张酒
	参数：use（sgs.CardUseStruct类型，表示待填充的卡牌使用结构体）
		slash（Card类型，表示将使用的杀）
	结果：Card类型，表示找到的酒
]]--
function SmartAI:searchForAnaleptic(use, slash)
	if slash then
		if slash:hasFlag("drank") then 
			return nil 
		end
	end
	if use.to then
		local anal = self:getCard("Analeptic")
		if anal then
			local analAvail = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, anal)
			if self.player:usedTimes("Analeptic") < analAvail then
				local slashAvail = 0
				if sgs.ai_current_series then
					for _,card in ipairs(sgs.ai_current_series) do
						if card:isKindOf("Slash") then
							slashAvail = slashAvail + 1
						end
					end
				end
				if sgs.ai_current_card then
					if sgs.ai_current_card:isKindOf("Slash") then
						slashAvail = slashAvail + 1
					end
				end
				if analAvail > 1 then
					if analAvail < slashAvail then 
						return nil 
					end
				end
				local handcards = self.player:getHandcards()
				handcards = sgs.QList2Table(handcards)
				if self.player:getPhase() == sgs.Player_Play then
					if self.player:hasFlag("lexue") then
						local mark = self.player:getMark("lexue")
						local lexuesrc = sgs.Sanguosha:getCard(mark)
						if lexuesrc:isKindOf("Analeptic") then
							local suit = lexuesrc:getSuit()
							local src_name = sgs.getCardName(lexuesrc)
							local src_value = sgs.getCardValue(src_name, "use_value")
							self:sortByUseValue(handcards, true)
							for _,c in ipairs(handcards) do
								if c:getSuit() == suit then
									local analeptic = sgs.cloneCard("analeptic", suit, lexuesrc:getNumber())
									analeptic:addSubcard(c:getId())
									analeptic:setSkillName("lexue")
									local name = sgs.getCardName(c)
									local value = sgs.getCardValue(name, "use_value")
									if src_value > value then
										return analeptic
									end
								end
							end
						end
					end
					if self.player:hasLordSkill("weidai") then
						if not self.player:hasFlag("Global_WeidaiFailed") then
							return sgs.Card_Parse("@WeidaiCard=.")
						end
					end
				end
				local card_str = self:getCardId("Analeptic")
				if card_str then 
					return sgs.Card_Parse(card_str) 
				end
				local skillcards = self:getUsableSkillCards(handcards)
				for _,analeptic in ipairs(skillcards) do
					if analeptic:getClassName() == "Analeptic" then
						if analeptic:getEffectiveId() ~= slash:getEffectiveId() then
							return analeptic
						end
					end
				end
			end
		end
	end
	return nil
end
dofile "lua/ai/debug-ai.lua" --内部测试文件
dofile "lua/ai/chat-ai.lua" --聊天部分
dofile "lua/ai/standard_cards-ai.lua" --标准卡牌包部分
dofile "lua/ai/maneuvering-ai.lua" --军争篇部分
dofile "lua/ai/guanxing-ai.lua" --观星部分
dofile "lua/ai/standard-ai.lua" --标准武将包部分
dofile "lua/ai/sp-ai.lua" --SP扩展包部分
dofile "lua/ai/basara-ai.lua" --暗将模式部分

local files = table.concat(sgs.GetFileNames("lua/ai"), " ")
local loaded = "standard|standard_cards|maneuvering|sp" --已加载的内容
local extensions = sgs.Sanguosha:getExtensions() --Lua扩展包部分
local scenarioes = sgs.Sanguosha:getModScenarioNames() --场景模式部分

for _, aextension in ipairs(extensions) do
	local name = string.lower(aextension)
	if not loaded:match(aextension) and files:match(name) then
		dofile("lua/ai/" .. name .. "-ai.lua")
	end
end

for _, ascenario in ipairs(scenarioes) do
	local name = string.lower(ascenario)
	if not loaded:match(ascenario) and files:match(name) then
		dofile("lua/ai/" .. name .. "-ai.lua")
	end
end

dofile "lua/ai/brains-ai.lua" --套路扩充部分
dofile "lua/ai/pk-ai.lua" --单挑套路扩充部分