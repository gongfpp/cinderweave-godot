extends RefCounted
# Original content. Mechanical values are design choices, not claimed STS2 values.
const CARDS = {
"cut": ["余烬斩", "攻击", 1, "对目标造成 %d 伤害", {"damage":6}, {"damage":9}],
"brace": ["守火", "技能", 1, "获得 %d 格挡", {"block":5}, {"block":8}],
"flare": ["裂焰", "攻击", 2, "造成 %d 伤害，施加2易伤", {"damage":8,"vuln":2}, {"damage":11,"vuln":2,"cost":1}],
"needle": ["三棱针", "攻击", 1, "造成 %d 伤害，重复3次", {"damage":3,"hits":3}, {"damage":4,"hits":3}],
"sunder": ["碎冠", "攻击", 2, "造成 %d 伤害", {"damage":16}, {"damage":22}],
"sweep": ["灰环", "攻击", 1, "对所有敌人造成 %d 伤害", {"aoe":6}, {"aoe":9}],
"embercast": ["引星", "攻击", 1, "造成 %d 伤害；抽牌", {"damage":7,"draw":1}, {"damage":9,"draw":2}],
"pulse": ["攻守节拍", "攻击", 1, "获得6格挡；造成 %d 伤害", {"block":6,"damage":4}, {"block":8,"damage":7}],
"redoubt": ["凝灰壁", "技能", 2, "获得 %d 格挡", {"block":14}, {"block":20}],
"quickstep": ["飞灰步", "技能", 0, "获得 %d 格挡；抽1张", {"block":3,"draw":1}, {"block":5,"draw":1}],
"temper": ["锻意", "能力", 1, "本场战斗获得 %d 力量；消耗", {"strength":2,"exhaust":true}, {"strength":3,"exhaust":true}],
"reclaim": ["回响拾取", "技能", 1, "抽 %d 张牌", {"draw":3}, {"draw":4}],
"spark": ["火种", "技能", 0, "获得 %d 能量；消耗", {"energy":1,"exhaust":true}, {"energy":2,"exhaust":true}],
"cinder": ["长夜陨落", "攻击", 2, "对所有敌人造成 %d 伤害；消耗", {"aoe":15,"exhaust":true}, {"aoe":21,"exhaust":true}],
"vow": ["修补誓言", "技能", 1, "回复 %d 生命；消耗", {"heal":5,"exhaust":true}, {"heal":8,"exhaust":true}],
"bloodfuel": ["借命", "技能", 0, "失去3生命；获得 %d 能量", {"self":3,"energy":2}, {"self":3,"energy":3}],
"wardthorns": ["荆焰甲", "能力", 1, "获得 %d 荆棘：被攻击反伤；消耗", {"thorns":3,"exhaust":true}, {"thorns":5,"exhaust":true}],
"vault": ["明日之盾", "技能", 1, "本回合和下回合各获得 %d 格挡", {"block":8,"next_block":8}, {"block":12,"next_block":12}],
"echo": ["双生印", "技能", 1, "下 %d 张攻击牌伤害翻倍；消耗", {"echo":1,"exhaust":true}, {"echo":2,"exhaust":true}],
"fracture": ["灼痕", "攻击", 0, "造成 %d 伤害；施加1易伤", {"damage":3,"vuln":1}, {"damage":5,"vuln":2}],
"drain": ["余温汲取", "攻击", 1, "造成 %d 伤害；回复生命", {"damage":8,"heal":3}, {"damage":11,"heal":5}],
"avalanche": ["盾落", "攻击", 2, "造成等同当前格挡的伤害（+%d）", {"shield_hit":0}, {"shield_hit":7}],
"gather": ["扬灰筛选", "技能", 0, "抽 %d 张，然后弃最左1张手牌", {"draw":3,"discard":1}, {"draw":4,"discard":1}],
"immolate": ["焚身仪式", "攻击", 1, "失去2生命；群伤 %d；获得1力量", {"self":2,"aoe":8,"strength":1}, {"self":2,"aoe":11,"strength":2}]
}
const RELICS = {
"coal": ["不熄煤", "每场战斗胜利后回复4生命"],
"lens": ["曙光透镜", "每场战斗第一回合多抽2张"],
"anvil": ["袖珍铁砧", "每场战斗开始获得1力量"],
"cloak": ["灰羽披风", "每回合开始获得2格挡"],
"bell": ["第六声钟", "每打出6张牌获得1能量"],
"seed": ["赤藤种", "每场战斗开始获得2荆棘"],
"chalice": ["空冠杯", "每场战斗第一回合多1能量"],
"coin": ["商旅护符", "商店价格降低20%"]
}
const POTIONS = {"fire":["瓶中焰","对选中敌人造成20伤害"],"guard":["石肤露","获得15格挡"],"renew":["回春露","回复12生命"]}
const ENEMIES = {
"moth": ["灰翅蛾",25, [["attack",5],["weak",1],["attack",8]]],
"hound": ["炉渣猎犬",32, [["attack",7],["multi",4,2],["buff",2]]],
"sentinel": ["遗炉守卫",38, [["guard",10],["attack",10],["attack",6]]],
"leech": ["炭核蛭",28, [["vuln",2],["attack",9],["heal",5]]],
"oracle": ["裂镜使",30, [["afflict",1],["attack",6],["guard",8]]],
"knight": ["空壳骑士",42, [["buff",2],["attack",10],["multi",4,2]]],
"colossus": ["钉炉巨像",78, [["guard",16],["attack",16],["multi",6,3]]],
"sisters": ["双面审判者",68, [["vuln",2],["multi",6,2],["afflict",1],["attack",17]]],
"sovereign": ["烬冠君王",125, [["attack",13],["guard",14],["multi",6,2],["buff",2]]]
}
const EVENTS = [
["织命井", "井底映出的未来，标价恰好是一道伤口。", ["失去6生命，给一张牌附魔「余辉」", "带着现有的自己离开"]],
["盲眼档案员", "他愿意用一页被遗忘的名字，换走你的旧习惯。", ["支付35金币，移除一张牌", "获得40金币；一张牌附着「刺痛」", "离开"]],
["受困的旅者", "熄灭的营火旁，他把最后一枚遗物交到你手里。", ["支付45金币，获得一件遗物", "分享火焰：回复8生命，然后离开"]],
["沉睡熔炉", "炉膛仍记得锻造的温度。", ["失去8生命，升级两张未升级牌", "拿走25金币"]]
]
static func card(id:String, upgraded:bool=false) -> Dictionary:
 var c = CARDS[id]
 var v:Dictionary = c[5 if upgraded else 4].duplicate(true)
 v["name"] = c[0] + ("+" if upgraded else "")
 v["type"] = c[1]
 v["cost"] = v.get("cost", c[2])
 return v
static func description(inst:Dictionary) -> String:
 var d = card(inst.id, inst.get("up",false))
 var out:Array[String] = []
 if d.has("block"): out.append("获得%d格挡" % d.block)
 if d.has("damage"): out.append("造成%d伤害%s" % [d.damage, "×%d" % d.get("hits",1) if d.get("hits",1)>1 else ""])
 if d.has("aoe"): out.append("对所有敌人造成%d伤害" % d.aoe)
 if d.has("shield_hit"): out.append("造成当前格挡+%d伤害" % d.shield_hit)
 if d.has("vuln"): out.append("施加%d易伤" % d.vuln)
 for k in ["draw","energy","strength","thorns","heal","next_block","echo"]:
  if d.has(k): out.append({"draw":"抽%d张牌","energy":"获得%d能量","strength":"获得%d力量","thorns":"获得%d荆棘","heal":"回复%d生命","next_block":"下回合获得%d格挡","echo":"下%d张攻击伤害翻倍"}[k] % d[k])
 if d.has("discard"): out.append("弃最左1张手牌")
 if d.has("self"): out.append("失去%d生命" % d.self)
 if d.get("exhaust",false): out.append("消耗")
 if inst.get("enchant","")=="glow": out.append("余辉：打出后+2格挡")
 if inst.get("affliction","")=="sting": out.append("刺痛：打出时失去1生命")
 return "\n".join(out)
