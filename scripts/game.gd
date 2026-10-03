extends RefCounted
const C = preload("res://scripts/catalog.gd")
const SAVE_VERSION = 1
var rng = RandomNumberGenerator.new()
var s:Dictionary = {}
var last_error = ""
func new_run(seed_value:int):
 rng.seed = seed_value
 s = {"schema":SAVE_VERSION,"seed":str(seed_value),"revision":0,"phase":"ancient","hp":80,"max_hp":80,"gold":90,"deck":[],"uid":0,"relics":["coal"],"potions":["fire"],"floor":-1,"lane":1,"visited":[],"map":[],"log":[],"battle":{},"reward":[],"shop":{},"event":0,"remove_used":false,"turns":0,"wins":0,"cards_played":0}
 for id in ["cut","cut","cut","cut","cut","brace","brace","brace","brace","flare"]: s.deck.append(make_card(id))
 var rows = [["battle","battle","battle"],["battle","event","battle"],["camp","shop","event"],["elite","battle","elite"],["treasure","treasure","treasure"],["event","shop","camp"],["elite","battle","elite"],["camp","event","shop"],["boss"]]
 for f in range(rows.size()):
  var row:Array=[]
  for l in range(rows[f].size()):
   row.append({"id":"%d_%d"%[f,l],"kind":rows[f][l],"lane":1 if f==8 else l,"event":rng.randi_range(0,3),"encounter":rng.randi_range(0,5)})
  s.map.append(row)
 note("新远征 · 种子 %s" % s.seed)
func make_card(id:String,up:bool=false) -> Dictionary:
 s.uid += 1
 return {"uid":s.uid,"id":id,"up":up,"enchant":"","affliction":""}
func note(t:String):
 s.log.append(t)
 if s.log.size()>180: s.log.pop_front()
func touch(): s.revision += 1
func heal(n:int): s.hp = mini(s.max_hp,s.hp+n)
func relic(id:String) -> bool: return id in s.relics
func add_relic(id:String=""):
 var pool:Array=[]
 for k in C.RELICS:
  if not relic(k): pool.append(k)
 if id=="" and pool.size()>0: id=pool[rng.randi_range(0,pool.size()-1)]
 if id!="" and not relic(id):
  s.relics.append(id); note("获得遗物 · "+C.RELICS[id][0])
 else: s.gold+=40
func ancient(choice:int) -> bool:
 if s.phase!="ancient" or choice<0 or choice>2: return false
 touch()
 if choice==0:
  s.max_hp-=8; s.hp=mini(s.hp,s.max_hp); add_relic("anvil")
 elif choice==1:
  s.gold+=100; s.deck[0].affliction="sting"
 else:
  s.hp-=10; s.deck[0].enchant="glow"; s.deck[5].enchant="glow"
 s.phase="map"; note("与余烬织者订立第%d道契约" % (choice+1)); return true
func legal_nodes() -> Array:
 if s.phase!="map": return []
 var f:int=s.floor+1
 if f>=s.map.size(): return []
 var out:Array=[]
 for n in s.map[f]:
  if s.floor<0 or abs(n.lane-s.lane)<=1: out.append(n)
 return out
func choose_node(id:String) -> bool:
 var selected:Dictionary={}
 for n in legal_nodes():
  if n.id==id: selected=n
 if selected.is_empty(): return false
 touch(); s.floor+=1; s.lane=selected.lane; s.visited.append(id)
 s.phase=selected.kind; s.event=selected.event
 note("第%d层 · %s" % [s.floor+1,selected.kind])
 if s.phase in ["battle","elite","boss"]: start_battle(s.phase,selected.encounter)
 elif s.phase=="shop": build_shop()
 return true
func start_battle(kind:String,encounter:int=0):
 s.phase="battle"
 var enemies:Array=[]
 var names:Array=[]
 if kind=="boss": names=["sovereign"]
 elif kind=="elite": names=["colossus" if encounter%2==0 else "sisters"]
 else:
  names=[["moth","moth"],["hound"],["sentinel"],["leech","moth"],["oracle"],["knight"]][encounter%6]
 for id in names:
  var def=C.ENEMIES[id]
  var hp:int=def[1]+maxi(0,s.floor-1)*2
  enemies.append({"id":id,"name":def[0],"hp":hp,"max_hp":hp,"block":0,"strength":0,"vuln":0,"step":0,"phase":1})
 s.battle={"kind":kind,"turn":0,"energy":0,"block":0,"strength":1 if relic("anvil") else 0,"thorns":2 if relic("seed") else 0,"vuln":0,"weak":0,"echo":0,"next_block":0,"draw":s.deck.duplicate(true),"discard":[],"hand":[],"exhaust":[],"enemies":enemies,"played":0,"initial_count":s.deck.size()}
 shuffle(s.battle.draw); next_turn()
func shuffle(a:Array):
 for i in range(a.size()-1,0,-1):
  var j=rng.randi_range(0,i); var t=a[i]; a[i]=a[j]; a[j]=t
func draw_cards(n:int):
 var b:Dictionary=s.battle
 for _i in range(n):
  if b.hand.size()>=10: break
  if b.draw.is_empty():
   b.draw=b.discard.duplicate(true); b.discard.clear(); shuffle(b.draw)
  if b.draw.is_empty(): break
  b.hand.append(b.draw.pop_back())
func next_turn():
 var b:Dictionary=s.battle
 b.turn+=1; s.turns+=1
 b.block=b.next_block+(2 if relic("cloak") else 0); b.next_block=0
 b.energy=3+(1 if b.turn==1 and relic("chalice") else 0)
 draw_cards(5+(2 if b.turn==1 and relic("lens") else 0))
 note("回合%d · 能量%d" %[b.turn,b.energy])
func intent(e:Dictionary) -> Array:
 var patterns:Array=C.ENEMIES[e.id][2]
 if e.id=="sovereign" and e.phase==2: patterns=[["multi",8,3],["afflict",1],["attack",24],["guard",20]]
 return patterns[int(e.step)%patterns.size()].duplicate()
func intent_text(e:Dictionary) -> String:
 if e.hp<=0: return "已击败"
 var a=intent(e)
 match a[0]:
  "attack": return "攻击 %d" % predicted_enemy_damage(e,a[1])
  "multi": return "连击 %d×%d" %[predicted_enemy_damage(e,a[1]),a[2]]
  "guard": return "护甲 %d" % a[1]
  "buff": return "蓄力 +%d力量" % a[1]
  "vuln": return "施加%d易伤" % a[1]
  "weak": return "施加%d虚弱" % a[1]
  "afflict": return "一张弃牌附着刺痛"
  "heal": return "回复%d生命" % a[1]
 return "?"
func predicted_enemy_damage(e:Dictionary,n:int) -> int:
 return int(floor((n+e.strength)*(1.5 if s.battle.vuln>0 else 1.0)))
func target_needed(card:Dictionary) -> bool:
 var d=C.card(card.id,card.up)
 return d.has("damage") or d.has("shield_hit") or d.has("vuln")
func enemy_damage(index:int,amount:int,modified:bool=true,multiplier:int=1):
 var b:Dictionary=s.battle
 if index<0 or index>=b.enemies.size(): return
 var e:Dictionary=b.enemies[index]
 if e.hp<=0: return
 var n=amount
 if modified:
  n=int(floor((amount+b.strength)*(0.75 if b.weak>0 else 1.0)*(1.5 if e.vuln>0 else 1.0)*multiplier))
 var blocked=mini(e.block,n); e.block-=blocked; e.hp=maxi(0,e.hp-(n-blocked))
 note("%s 受到%d伤害（格挡%d）" %[e.name,n-blocked,blocked])
 if e.id=="sovereign" and e.hp>0 and e.hp<=e.max_hp/2 and e.phase==1:
  e.phase=2; e.step=0; e.block+=12; note("烬冠碎裂 · 君王进入第二阶段，获得12格挡")
func lose_hp(amount:int):
 s.hp=maxi(0,s.hp-amount)
func hit_player(e:Dictionary,amount:int):
 var b:Dictionary=s.battle
 var n=predicted_enemy_damage(e,amount)
 var blocked=mini(b.block,n); b.block-=blocked; lose_hp(n-blocked)
 note("%s 造成%d伤害（格挡%d）" %[e.name,n-blocked,blocked])
 if b.thorns>0:
  enemy_damage(b.enemies.find(e),b.thorns,false); note("荆棘反伤%d" % b.thorns)
func play(uid:int,target:int=-1) -> bool:
 if s.phase!="battle": return false
 var b:Dictionary=s.battle
 var ix=-1
 for i in range(b.hand.size()):
  if b.hand[i].uid==uid: ix=i
 if ix<0: return false
 var c:Dictionary=b.hand[ix]
 var d=C.card(c.id,c.up)
 if d.cost>b.energy: return false
 if target_needed(c) and (target<0 or target>=b.enemies.size() or b.enemies[target].hp<=0): return false
 touch(); b.hand.remove_at(ix); b.energy-=d.cost
 b.played+=1; s.cards_played+=1; note("打出 · "+d.name)
 lose_hp(d.get("self",0)+(1 if c.affliction=="sting" else 0))
 if s.hp<=0:
  (b.exhaust if d.get("exhaust",false) else b.discard).append(c)
  check_outcome(); return true
 var mult=1
 if d.type=="攻击" and b.echo>0: mult=2; b.echo-=1
 b.block+=d.get("block",0)
 if d.has("damage"):
  for _h in range(d.get("hits",1)): enemy_damage(target,d.damage,true,mult)
 if d.has("aoe"):
  for e in range(b.enemies.size()): enemy_damage(e,d.aoe,true,mult)
 if d.has("shield_hit"): enemy_damage(target,b.block+d.shield_hit,true,mult)
 if d.has("vuln") and b.enemies[target].hp>0: b.enemies[target].vuln+=d.vuln
 b.strength+=d.get("strength",0); b.thorns+=d.get("thorns",0); b.energy+=d.get("energy",0)
 b.echo+=d.get("echo",0); b.next_block+=d.get("next_block",0)
 heal(d.get("heal",0)); draw_cards(d.get("draw",0))
 for _i in range(d.get("discard",0)):
  if not b.hand.is_empty(): b.discard.append(b.hand.pop_front())
 if c.enchant=="glow": b.block+=2
 (b.exhaust if d.get("exhaust",false) else b.discard).append(c)
 if relic("bell") and int(b.played)%6==0: b.energy+=1; note("第六声钟 · +1能量")
 check_outcome(); return true
func end_turn() -> bool:
 if s.phase!="battle": return false
 touch(); var b:Dictionary=s.battle
 b.discard.append_array(b.hand); b.hand.clear()
 for e in b.enemies:
  if e.hp<=0: continue
  e.block=0
  var a=intent(e)
  match a[0]:
   "attack": hit_player(e,a[1])
   "multi":
    for _i in range(a[2]):
     if s.hp>0 and e.hp>0: hit_player(e,a[1])
   "guard": e.block+=a[1]
   "buff": e.strength+=a[1]
   "vuln": b.vuln+=a[1]+1
   "weak": b.weak+=a[1]+1
   "heal": e.hp=mini(e.max_hp,e.hp+a[1])
   "afflict":
    # Combat-only affliction is attached to one card in discard before the next draw.
    if not b.discard.is_empty(): b.discard[rng.randi_range(0,b.discard.size()-1)].affliction="sting"
  e.step+=1; e.vuln=maxi(0,e.vuln-1)
  if s.hp<=0: break
 b.vuln=maxi(0,b.vuln-1); b.weak=maxi(0,b.weak-1)
 if check_outcome(): return true
 next_turn(); return true
func check_outcome() -> bool:
 if s.hp<=0: s.phase="defeat"; note("火焰熄灭。远征终止。"); return true
 for e in s.battle.enemies:
  if e.hp>0: return false
 s.wins+=1
 if relic("coal"): heal(4)
 if s.battle.kind=="boss": s.phase="victory"; note("烬冠落地 · 一章切片通关"); return true
 s.gold+=rng.randi_range(18,28)+(18 if s.battle.kind=="elite" else 0)
 if s.battle.kind=="elite": add_relic()
 if s.potions.size()<3 and rng.randf()<0.4: s.potions.append(C.POTIONS.keys()[rng.randi_range(0,2)])
 var ids=C.CARDS.keys(); shuffle(ids); s.reward=ids.slice(0,3)
 s.phase="reward"; note("战斗胜利 · 选择奖励或跳过"); return true
func take_reward(index:int) -> bool:
 if s.phase!="reward" or index< -1 or index>=s.reward.size(): return false
 touch()
 if index>=0: s.deck.append(make_card(s.reward[index])); note("加入牌组 · "+C.CARDS[s.reward[index]][0])
 s.reward=[]; s.phase="map"; return true
func use_potion(index:int,target:int=0) -> bool:
 if s.phase!="battle" or index<0 or index>=s.potions.size(): return false
 var id=s.potions[index]
 if id=="fire" and (target<0 or target>=s.battle.enemies.size() or s.battle.enemies[target].hp<=0): return false
 touch(); s.potions.remove_at(index); note("使用 · "+C.POTIONS[id][0])
 match id:
  "fire": enemy_damage(target,20,false)
  "guard": s.battle.block+=15
  "renew": heal(12)
 check_outcome(); return true
func leave() -> bool:
 if not s.phase in ["camp","shop","event","treasure"]: return false
 touch(); s.phase="map"; return true
func camp_rest() -> bool:
 if s.phase!="camp": return false
 heal(int(s.max_hp*0.3)); note("营火休息 · 回复30%最大生命"); return leave()
func upgrade(uid:int) -> bool:
 if s.phase!="camp": return false
 for c in s.deck:
  if c.uid==uid and not c.up:
   c.up=true; note("升级 · "+C.CARDS[c.id][0]); return leave()
 return false
func treasure() -> bool:
 if s.phase!="treasure": return false
 add_relic(); s.gold+=15; return leave()
func price(base:int) -> int: return int(base*(0.8 if relic("coin") else 1.0))
func build_shop():
 var ids=C.CARDS.keys(); shuffle(ids)
 var offers:Array=[]
 for id in ids.slice(0,3):
  var base=45+rng.randi_range(0,15)
  offers.append({"type":"card","id":id,"base":base,"price":price(base),"sold":false})
 var pool:Array=[]
 for id in C.RELICS:
  if not relic(id): pool.append(id)
 if not pool.is_empty(): offers.append({"type":"relic","id":pool[rng.randi_range(0,pool.size()-1)],"base":100,"price":price(100),"sold":false})
 for id in ["guard","renew"]: offers.append({"type":"potion","id":id,"base":25,"price":price(25),"sold":false})
 s.shop={"offers":offers,"removed":false}
func buy(index:int) -> bool:
 if s.phase!="shop" or index<0 or index>=s.shop.offers.size(): return false
 var offer:Dictionary=s.shop.offers[index]
 if offer.sold or s.gold<offer.price or (offer.type=="potion" and s.potions.size()>=3): return false
 touch(); s.gold-=offer.price; offer.sold=true
 match offer.type:
  "card": s.deck.append(make_card(offer.id))
  "relic":
   add_relic(offer.id)
   if offer.id=="coin":
    for other in s.shop.offers:
     if not other.sold: other.price=price(other.get("base",other.price))
  "potion": s.potions.append(offer.id)
 note("商店购买 · "+offer.id); return true
func remove_card(uid:int) -> bool:
 if s.phase!="shop" or s.shop.removed or s.gold<price(55) or s.deck.size()<=1: return false
 for i in range(s.deck.size()):
  if s.deck[i].uid==uid:
   touch(); s.deck.remove_at(i); s.gold-=price(55); s.shop.removed=true; note("商店移除一张牌"); return true
 return false
func event_choice(index:int,uid:int=-1) -> bool:
 if s.phase!="event": return false
 var ev:int=s.event
 if index<0 or index>=C.EVENTS[ev][2].size(): return false
 var ci=-1
 for i in range(s.deck.size()):
  if s.deck[i].uid==uid: ci=i
 if ev==0 and index==0:
  if s.hp<=6 or ci<0 or s.deck[ci].enchant!="": return false
  s.hp-=6; s.deck[ci].enchant="glow"
 elif ev==1 and index==0:
  if s.gold<35 or ci<0 or s.deck.size()<=1: return false
  s.gold-=35; s.deck.remove_at(ci)
 elif ev==1 and index==1:
  if ci<0 or s.deck[ci].affliction!="": return false
  s.gold+=40; s.deck[ci].affliction="sting"
 elif ev==2:
  if index==0:
   if s.gold<45: return false
   s.gold-=45; add_relic()
  else: heal(8)
 elif ev==3:
  if index==0:
   if s.hp<=8: return false
   s.hp-=8
   var pool:Array=[]
   for c in s.deck:
    if not c.up: pool.append(c)
   shuffle(pool)
   for c in pool.slice(0,2): c.up=true
  else: s.gold+=25
 note("事件选择 · "+C.EVENTS[ev][2][index]); return leave()
func save_to(path:String="user://cinderweave.json") -> bool:
 if s.is_empty(): return false
 var state=s.duplicate(true); state["rng_state"]=str(rng.state); state["rng_seed"]=str(rng.seed)
 var payload=JSON.stringify(state)
 var f=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if f==null: last_error="无法写入临时存档"; return false
 f.store_string(JSON.stringify({"payload":payload,"checksum":payload.sha256_text()})); f.close()
 var err=DirAccess.rename_absolute(path+".tmp",path)
 if err!=OK: last_error="存档替换失败"; return false
 return true
func load_from(path:String="user://cinderweave.json") -> bool:
 if not FileAccess.file_exists(path): last_error="没有可用存档"; return false
 var wrapper=JSON.parse_string(FileAccess.get_file_as_string(path))
 if not wrapper is Dictionary or not wrapper.get("payload",null) is String or not wrapper.get("checksum",null) is String: last_error="存档格式错误"; return false
 if wrapper.payload.sha256_text()!=wrapper.checksum: last_error="存档校验失败"; return false
 var candidate=JSON.parse_string(wrapper.payload)
 if not valid_state(candidate): last_error="存档版本或内容不兼容"; return false
 s=normalize_numbers(candidate); rng.seed=int(s.rng_seed); rng.state=int(s.rng_state); s.erase("rng_seed"); s.erase("rng_state")
 touch(); return true
func valid_state(v) -> bool:
 if not v is Dictionary: return false
 for k in ["schema","seed","revision","phase","hp","max_hp","gold","deck","uid","relics","potions","floor","lane","visited","map","log","battle","reward","shop","event","remove_used","turns","wins","cards_played","rng_state","rng_seed"]:
  if not v.has(k): return false
 if v.schema!=SAVE_VERSION or not v.phase in ["ancient","map","battle","reward","camp","shop","event","treasure","victory","defeat"]: return false
 for key in ["revision","hp","max_hp","gold","uid","floor","lane","event","turns","wins","cards_played"]:
  if not (v[key] is int or v[key] is float) or float(v[key])!=floor(float(v[key])): return false
 if v.max_hp<=0 or v.hp<0 or v.hp>v.max_hp or v.gold<0 or v.floor< -1 or v.floor>8 or v.event<0 or v.event>3: return false
 if not v.battle is Dictionary or not v.shop is Dictionary: return false
 for key in ["visited","log","reward","relics","potions"]:
  if not v[key] is Array: return false
 for id in v.relics:
  if not C.RELICS.has(id): return false
 for id in v.potions:
  if not C.POTIONS.has(id): return false
 for id in v.reward:
  if not C.CARDS.has(id): return false
 if not v.rng_state is String or not v.rng_seed is String or not v.rng_state.is_valid_int() or not v.rng_seed.is_valid_int(): return false
 if not v.deck is Array or v.deck.is_empty() or not v.map is Array or v.map.size()!=9: return false
 var permanent_ids:Array=[]
 for c in v.deck:
  if not valid_card(c) or c.uid in permanent_ids: return false
  permanent_ids.append(c.uid)
 for f in range(v.map.size()):
  if not v.map[f] is Array or v.map[f].size()!=(1 if f==8 else 3): return false
  for n in v.map[f]:
   if not n is Dictionary: return false
   for key in ["id","kind","lane","event","encounter"]:
    if not n.has(key): return false
   if not n.kind in ["battle","elite","camp","shop","event","treasure","boss"]: return false
   for key in ["lane","event","encounter"]:
    if not (n[key] is float or n[key] is int): return false
 if v.phase=="shop":
  if not v.shop.get("offers",null) is Array or not v.shop.get("removed",null) is bool: return false
  for o in v.shop.offers:
   if not o is Dictionary: return false
   for key in ["type","id","price","sold"]:
    if not o.has(key): return false
   if not o.type in ["card","relic","potion"] or not (o.price is int or o.price is float) or o.price<0: return false
   if not {"card":C.CARDS,"relic":C.RELICS,"potion":C.POTIONS}[o.type].has(o.id): return false
 if v.phase=="battle":
  for k in ["kind","turn","energy","block","strength","thorns","vuln","weak","echo","next_block","draw","discard","hand","exhaust","enemies","played","initial_count"]:
   if not v.battle.has(k): return false
  for key in ["turn","energy","block","strength","thorns","vuln","weak","echo","next_block","played","initial_count"]:
   if not (v.battle[key] is int or v.battle[key] is float): return false
  if not v.battle.enemies is Array or v.battle.enemies.is_empty(): return false
  var seen:Array=[]
  for zone in ["draw","discard","hand","exhaust"]:
   if not v.battle[zone] is Array: return false
   for c in v.battle[zone]:
    if not valid_card(c) or c.uid in seen: return false
    seen.append(c.uid)
  if seen.size()!=v.battle.initial_count: return false
  for e in v.battle.enemies:
   if not e is Dictionary or not C.ENEMIES.has(e.get("id","")): return false
   for k in ["name","hp","max_hp","block","strength","vuln","step","phase"]:
    if not e.has(k): return false
   for key in ["hp","max_hp","block","strength","vuln","step","phase"]:
    if not (e[key] is int or e[key] is float): return false
 return true
func valid_card(c) -> bool:
 if not c is Dictionary: return false
 for k in ["uid","id","up","enchant","affliction"]:
  if not c.has(k): return false
 return (c.uid is int or c.uid is float) and c.up is bool and C.CARDS.has(c.id) and c.enchant in ["","glow"] and c.affliction in ["","sting"]
func zones_valid() -> bool:
 if s.battle.is_empty(): return true
 var ids:Array=[]
 for z in ["draw","hand","discard","exhaust"]:
  for c in s.battle[z]:
   if c.uid in ids: return false
   ids.append(c.uid)
 return ids.size()==s.battle.initial_count

func normalize_numbers(v):
 if v is float: return int(v)
 if v is Array:
  var a:Array=[]
  for item in v: a.append(normalize_numbers(item))
  return a
 if v is Dictionary:
  var d:Dictionary={}
  for key in v: d[key]=normalize_numbers(v[key])
  return d
 return v
