--[[
	新版太阳神三国杀MOD之欢乐AI系统（独孤安河实验版）聊天部分
]]--
function speak(to, type)
	if sgs.ai_chat_enabled then
		if to:getState() == "robot" then
			local items = sgs.ai_chat[type]
			local index = math.random(1, #items)
			to:speak(items[index])
		end
	end
end

function SmartAI:speak(type, isFemale)
	if sgs.ai_chat_enabled then
		if self.player:getState() == "robot" then 
			if isFemale then
				type = type .. "_female"
			end
			local items = sgs.ai_chat[type]
			if items then
				local index = math.random(1, #items)
				self.player:speak(items[index])
			else
				self.player:speak(type)
			end
		end
	end
end

function speakTrigger(card, from, to, event)
	if event == "death" then
		if from:hasSkill("ganglie") or from:hasSkill("neoganglie") then
			speak(from, "ganglie_death")
		end
	end
	if card then
		if card:isKindOf("Indulgence") then --乐不思蜀
			if to:getHandcardNum() > to:getHp() then
				speak(to, "indulgence")
			end
		elseif card:isKindOf("LeijiCard") then --雷击
			speak(from, "leiji_jink")
		elseif card:isKindOf("QuhuCard") then --驱虎
			speak(from, "quhu")
		elseif card:isKindOf("Slash") then --杀
			if from:hasSkill("wusheng") and to:hasSkill("yizhong") then
				speak(from, "wusheng_yizhong")
			elseif to:hasSkill("yiji") and to:getHp() <= 1 then
				speak(to, "guojia_weak")
			end
		elseif card:isKindOf("SavageAssault") then --南蛮入侵
			if to:hasSkill("kongcheng") or to:hasSkill("huoji") then
				speak(to, "daxiang")
			end
		elseif card:isKindOf("FireAttack") then --火攻
			if to:hasSkill("luanji") then
				speak(to, "yuanshao_fire")
			end
		end
	end
end

sgs.ai_chat = {
	yiji = {
		"再用力一点",
		"要死了啊!"
	},
	hostile = {
		"yoooo少年，不来一发么",
		"果然还是看你不爽",
		"我看你霸气外露，不可不防啊"
	},
	hostile_female = {
		"啧啧啧，来帮你解决点手牌吧",
		"叫你欺负人!" ,
		"手牌什么的最讨厌了"
	},
	friendly = {
		"。。。" 
	},
	respond_friendly = { 
		"谢了。。。" 
	},
	respond_hostile = {
		"擦，小心菊花不保",
		"内牛满面了", 
		"哎哟我去"
	},
	duel = {
		"来吧！像男人一样决斗吧！"
	},
	duel_female = {
		"哼哼哼，怕了吧"
	},
	lucky = {
		"哎哟运气好",
		"哈哈哈哈哈"
	},
	collateral = {
		"你妹啊，我的刀！"
	},
	collateral_female = {
		"别以为这样就算赢了！"
	},
	jijiang = {
		"主公，我来啦"
	},
	jijiang_female = {
		"别指望下次我会帮你哦"
	},
	kurou = {
		"有桃么!有桃么？",
		"教练，我想要摸桃",
		"桃桃桃我的桃呢",
		"求桃求连弩各种求"
	},
	leiji_jink = {
		"我有闪我会到处乱说么？",
		"你觉得我有木有闪啊",
		"哈我有闪"
	},
	quhu = {
		"出大的！",
		"来来来拼点了",
		"哟，拼点吧"
	},
	luoyi = {
		"不脱光衣服干不过你"
	},
	wusheng_yizhong = {
		"诶你技能是啥来着？",
		"在杀的颜色这个问题上咱是色盲",
		"咦你的技能呢？"
	},
	indulgence = {
		"乐，乐你妹啊乐",
		"擦，乐我",
		"诶诶诶被乐了！"
	},
	daxiang = {
		"好多大象啊！",
		"擦，孟获你的宠物又调皮了",
		"内牛满面啊敢不敢少来点AOE"
	},
	yuanshao_fire = {
		"谁去打119啊",
		"别别别烧了别烧了。。。",
		"又烧啊，饶了我吧。。。"
	},
	guojia_weak = {
		"擦，再卖血会卖死的",
		"不敢再卖了诶诶诶诶"
	},
	ganglie_death = {
		"菊花残，满地伤。。。"
	}
}

sgs.ai_chat_func[sgs.SlashEffected].blindness = function(self, player, data)
	local effect = data:toSlashEffect()
	if effect.from then
		if not effect.to:isLord() or sgs.hegemony_mode then
			local chat = {
				"队长，是我，别开枪，自己人.",
				"尼玛你杀我，你真是夏侯惇啊",
				"盲狙一时爽啊, 我泪奔啊",
				"我次奥，哥们，盲狙能不能轻点？",
				"再杀我一下，老子和你拼命了"
			}
			if self:isEquip("Crossbow", effect.from) then
				table.insert(chat, "快闪，药家鑫来了。")
				table.insert(chat, "果然是连弩降智商呀。")
				table.insert(chat, "杀死我也没牌拿，真2")
			end
			if effect.from:getMark("drank") > 0 then
				table.insert(chat, "喝醉了吧，乱砍人？")		
			end
			if effect.from:isLord() and not sgs.hegemony_mode then
				table.insert(chat, "尼玛眼瞎了，老子是忠啊")
				table.insert(chat, "主公别打我，我是忠")
				table.insert(chat, "主公，再杀我，你会裸")
			end
			local index = 1 + (os.time() % #chat)
			if os.time() % 10 <= 3 then
				effect.to:speak(chat[index])
			end
		end
	end
end

sgs.ai_chat_func[sgs.Death].stupid_lord = function(self, player, data)
	local damage = data:toDeath().damage
	local chat = {
		"2B了吧，老子这么忠还杀我",
		"主要臣死，臣不得不死",
		"房主下盘T了这个主，拉黑不解释",
		"还有更2的吗",
		"对这个主，真的很无语",
	}
	if damage and damage.from then
		if damage.to:objectName() == player:objectName() then
			if damage.from:objectName() ~= player:objectName() then
				if sgs.ai_lord[player:objectName()] == damage.from:objectName() then
					local index = 1 + (os.time() % #chat)
					damage.to:speak(chat[index])
				end
			end
		end
	end
end

sgs.ai_chat_func[sgs.EventPhaseStart].comeon = function(self, player, data)
	local chat = {
		"有货，可以来搞一下",
		"我有X张【闪】",
		"没闪, 忠内不要乱来",
		"不爽，来啊！砍我啊",
		"求杀求砍求蹂躏",
	}
	if player:getPhase() == sgs.Player_Finish then
		if not player:isKongcheng() and player:hasSkill("leiji") then
			if os.time() % 10 < 4 then
				local index = 1 + (os.time() % #chat)
				player:speak(chat[index])
			end
		end
	end	
end

sgs.ai_chat_func[sgs.EventPhaseStart].beset = function(self, player, data)	
	local chat = {
		"大家一起围观一下“主公”！",
		"不要一下弄死了，慢慢来",
		"速度，一人一下，弄死",
		"哥们，你投降吧，免受皮肉之苦啊，投降给全尸",
	}
	if player:getPhase() == sgs.Player_Start then
		if #sgs.ai_camps == 2 then
			local members1 = sgs.getCampMembers(sgs.ai_camps[1])
			local members2 = sgs.getCampMembers(sgs.ai_camps[2])
			local alives = self.room:getAlivePlayers()
			local a = #members1
			local b = #members2
			if a + b == alives:length() then
				if (a == 1 and b > 1) or (a > 1 and b == 1) then	
					if os.time() % 10 < 4 then
						local index = 1 + (os.time() % #chat)
						player:speak(chat[index])
					end
				end
			end
		end
	end
end