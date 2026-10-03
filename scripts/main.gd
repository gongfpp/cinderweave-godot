extends Control
const G=preload("res://scripts/game.gd")
const C=preload("res://scripts/catalog.gd")
const Glyph=preload("res://scripts/glyph.gd")
const Art=preload("res://scripts/art.gd")
const FONT=preload("res://assets/Cinderweave-NotoSansSC.otf")
const GOLD=Color("e5bc77")
const INK=Color("12232e")
const TEXT=Color("e9e4d5")
const MUTE=Color("96adb5")
const TEAL=Color("7bc9c3")
var g=G.new()
var layer:Control
var artwork:Control
var selected_uid=-1
var target=0
var modal=""
var pending=""
var message=""
var seed_input:LineEdit
var menu=true
var feedback:Label
var audio:AudioStreamPlayer
func _ready():
 var theme_new=Theme.new(); theme_new.default_font=FONT; theme_new.default_font_size=18; theme=theme_new
 audio=AudioStreamPlayer.new(); add_child(audio)
 get_tree().auto_accept_quit=false
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--qa-fixture="):
   var path=arg.trim_prefix("--qa-fixture=")
   if path.begins_with("res://tests/fixtures/") and g.load_from(path): menu=false; message="QA场景：由真实规则轨迹生成的恢复点"
 render()
func _notification(what):
 if what==NOTIFICATION_WM_CLOSE_REQUEST:
  if not g.s.is_empty(): g.save_to()
  get_tree().quit()
func _input(event):
 # Tab is normally consumed by Control focus traversal before unhandled input.
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_TAB and not menu and modal=="":
  get_viewport().set_input_as_handled(); modal="deck"; render()
func _unhandled_key_input(event):
 if not event is InputEventKey or not event.pressed or event.echo: return
 if event.keycode==KEY_F12:
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("res://evidence/gui_"+("menu" if menu else g.s.phase)+("_"+modal if modal!="" else "")+".png")
  return
 if event.keycode==KEY_ESCAPE:
  if menu: return
  modal="" if modal!="" else "pause"; render(); return
 if menu or modal!="": return
 if g.s.phase=="battle":
  if event.keycode==KEY_SPACE: act("end_turn"); return
  if event.keycode>=KEY_1 and event.keycode<=KEY_9:
   var ix=event.keycode-KEY_1
   if ix<g.s.battle.hand.size(): select_card(g.s.battle.hand[ix].uid)
func tone(hz:float=520.0):
 var stream=AudioStreamWAV.new(); stream.format=AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate=22050
 var bytes=PackedByteArray(); bytes.resize(4410)
 for i in range(2205):
  var value=int(sin(i*TAU*hz/22050.0)*maxf(0,1-i/2205.0)*1800)
  bytes.encode_s16(i*2,value)
 stream.data=bytes; audio.stream=stream; audio.play()
func box(rect:Rect2,bg:Color=INK,border:Color=Color("365360"),radius:int=12,parent:Control=null) -> Panel:
 var n=Panel.new(); n.position=rect.position; n.size=rect.size
 var st=StyleBoxFlat.new(); st.bg_color=bg; st.border_color=border; st.set_border_width_all(1); st.set_corner_radius_all(radius)
 n.add_theme_stylebox_override("panel",st); (layer if parent==null else parent).add_child(n); return n
func label(text:String,x:float,y:float,w:float=500,h:float=40,size_value:int=20,col:Color=TEXT,parent:Control=null) -> Label:
 var n=Label.new(); n.text=text; n.position=Vector2(x,y); n.size=Vector2(w,h); n.add_theme_font_size_override("font_size",size_value); n.add_theme_color_override("font_color",col); n.mouse_filter=Control.MOUSE_FILTER_IGNORE
 (layer if parent==null else parent).add_child(n); return n
func button(text:String,rect:Rect2,cb:Callable,disabled:bool=false,col:Color=GOLD,parent:Control=null) -> Button:
 var n=Button.new(); n.text=text; n.position=rect.position; n.size=rect.size; n.disabled=disabled; n.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 var normal=StyleBoxFlat.new(); normal.bg_color=Color("19323f"); normal.border_color=col.darkened(0.3); normal.set_border_width_all(1); normal.set_corner_radius_all(8)
 n.add_theme_stylebox_override("normal",normal)
 var hover=normal.duplicate(); hover.bg_color=Color("2c4b58"); hover.border_color=col; n.add_theme_stylebox_override("hover",hover)
 var pressed=hover.duplicate(); pressed.bg_color=Color("3e5b65"); n.add_theme_stylebox_override("pressed",pressed)
 var off=normal.duplicate(); off.bg_color=Color("13232c"); off.border_color=Color("2d3c44"); n.add_theme_stylebox_override("disabled",off)
 n.add_theme_color_override("font_color",col); n.add_theme_color_override("font_disabled_color",Color("879ba3")); n.add_theme_font_size_override("font_size",17)
 n.pressed.connect(cb); (layer if parent==null else parent).add_child(n); return n
func guarded(method:String,args:Array=[]) -> Callable:
 var rev=g.s.get("revision",-1)
 return func():
  if g.s.get("revision",-1)==rev: act(method,args)
func act(method:String,args:Array=[]):
 var ok=g.callv(method,args)
 if ok:
  if g.s.phase=="battle":
   if target<0 or target>=g.s.battle.enemies.size() or g.s.battle.enemies[target].hp<=0:
    for i in range(g.s.battle.enemies.size()):
     if g.s.battle.enemies[i].hp>0: target=i; break
  selected_uid=-1; pending=""; message=str(g.s.log[-1]) if not g.s.log.is_empty() else ""; g.save_to(); tone(660 if g.s.phase=="reward" else 420); render()
 else:
  message="现在不能这样做：检查能量、目标、金币或生命条件"; render()
func render():
 if layer!=null: remove_child(layer); layer.queue_free()
 if artwork!=null: remove_child(artwork); artwork.queue_free()
 artwork=Art.new(); artwork.scene_kind="menu" if menu else g.s.phase
 if not menu and g.s.phase=="battle": artwork.opponents=g.s.battle.enemies
 add_child(artwork); move_child(artwork,0)
 layer=Control.new(); layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(layer)
 if menu: render_menu(); return
 header()
 match g.s.phase:
  "ancient": render_ancient()
  "map": render_map()
  "battle": render_battle()
  "reward": render_reward()
  "camp": render_camp()
  "shop": render_shop()
  "event": render_event()
  "treasure": render_treasure()
  "victory","defeat": render_end()
 if message!="": label(message,36,765,1170,25,16,GOLD)
 if modal!="": render_modal()
func render_menu():
 label("一章规则研究 · 原创内容可玩切片",70,138,700,40,20,TEAL)
 label("烬织",64,186,620,110,86,GOLD)
 label("C I N D E R W E A V E",74,304,700,45,28,TEXT)
 label("让每一道余烬，成为下一次选择。",75,365,650,45,25,MUTE)
 label("单人 · 24张牌 · 分叉远征 · 一位双阶段君王",75,419,730,38,18,MUTE)
 seed_input=LineEdit.new(); seed_input.placeholder_text="输入数字种子（默认 20261003）"; seed_input.position=Vector2(77,486); seed_input.size=Vector2(470,46); seed_input.text="20261003"; layer.add_child(seed_input)
 button("开始远征  →",Rect2(77,551,228,55),func():
  var seed_value=int(seed_input.text) if seed_input.text.is_valid_int() else 20261003
  g.new_run(seed_value); menu=false; modal=""; message=""; target=0; selected_uid=-1; g.save_to(); render())
 button("继续存档",Rect2(320,551,228,55),func():
  if g.load_from(): menu=false; modal=""; message="已恢复存档与随机数状态"; render()
  else: message=g.last_error; label(message,78,622,600,40,18,GOLD),not FileAccess.file_exists("user://cinderweave.json"),TEAL)
 label("M1.0 · Godot 4.6.3 · 完整游戏复刻目标仍在进行中",77,706,980,30,16,MUTE)
 label("本切片的角色、卡牌、图像、文案与数值为原创；不代表原作精确规则或内容。",77,743,1100,27,15,MUTE)
func header():
 box(Rect2(0,0,1280,72),Color("0b1721ed"),Color("35505a"),0)
 label("烬织",28,11,100,47,28,GOLD)
 label("生命 %d / %d"%[g.s.hp,g.s.max_hp],157,13,210,40,20,Color("e7a098"))
 label("金币 %d" % g.s.gold,368,13,150,40,20,GOLD)
 label("第 %d / 9 层" % maxi(0,g.s.floor+1),529,13,170,40,18,MUTE)
 button("牌组 %d" % g.s.deck.size(),Rect2(720,14,126,43),func(): modal="deck"; render(),false,TEAL)
 button("遗物 %d" % g.s.relics.size(),Rect2(857,14,113,43),func(): modal="relics"; render(),false,TEAL)
 button("日志",Rect2(981,14,100,43),func(): modal="log"; render(),false,TEAL)
 button("暂停 Esc",Rect2(1092,14,156,43),func(): modal="pause"; render(),false,MUTE)
func render_ancient():
 label("序幕 / 余烬织者",58,104,780,48,30,GOLD)
 label("「带走一束火，留下等重的昨天。」",59,170,900,50,29,TEXT)
 label("选择一个契约。每份馈赠都带着代价。",60,230,870,36,19,MUTE)
 var names=["锻骨契约","负债契约","余辉契约"]
 var desc=["最大生命 -8\n获得「袖珍铁砧」\n每场战斗开始 +1力量","获得100金币\n一张余烬斩附着「刺痛」\n打出该牌时失去1生命","失去10生命\n余烬斩与守火附魔「余辉」\n每次打出额外获得2格挡"]
 for i in range(3):
  box(Rect2(60+i*378,340,354,300),Color("142935ee"),GOLD.darkened(0.6))
  label("0%d"%(i+1),83+i*378,358,200,35,19,TEAL)
  label(names[i],83+i*378,402,320,50,28,GOLD)
  label(desc[i],83+i*378,465,316,95,18,TEXT)
  button("接受契约",Rect2(83+i*378,575,307,43),guarded("ancient",[i]))
func render_map():
 label("第一章 / 沉烬回廊",38,90,760,48,30,GOLD)
 label("点亮的节点可前往。相邻路径相连；每层只能选择一处。",40,144,1150,30,17,MUTE)
 var legal=[]
 for n in g.legal_nodes(): legal.append(n.id)
 var names={"battle":"战斗", "elite":"精英", "camp":"营火", "shop":"商店", "event":"事件", "treasure":"宝箱", "boss":"烬冠君王"}
 for f in range(9):
  var x=45+f*132
  label("%02d"%(f+1),x+31,210,80,32,16,MUTE)
  for n in g.s.map[f]:
   var y=296+n.lane*122
   if f<8:
    for nxt in g.s.map[f+1]:
     if abs(n.lane-nxt.lane)<=1:
      var line=Line2D.new(); line.add_point(Vector2(x+52,y+31)); line.add_point(Vector2(x+184,327+nxt.lane*122)); line.width=1.2; line.default_color=Color("36515e"); layer.add_child(line)
 for f in range(9):
  var x=45+f*132
  for n in g.s.map[f]:
   var y=296+n.lane*122
   var visited=n.id in g.s.visited
   var active=n.id in legal
   button(("✓ " if visited else "")+names[n.kind],Rect2(x,y,111,62),guarded("choose_node",[n.id]),not active,GOLD if active else TEAL)
 label("远征种子  "+g.s.seed,43,680,550,30,17,MUTE)
 label("升级与移除都改变构筑；营火、商店和精英之间做出取舍。",43,718,1150,30,18,TEXT)
func health_bar(x:float,y:float,w:float,hp:int,max_hp:int,col:Color):
 box(Rect2(x,y,w,8),Color("0a1118"),Color("0a1118"),3)
 if hp>0: box(Rect2(x,y,w*float(hp)/max_hp,8),col,col,3)
func render_battle():
 var b:Dictionary=g.s.battle
 label("战斗 / 第%d回合"%b.turn,38,89,600,40,24,GOLD)
 label("力量 %d   格挡 %d   荆棘 %d" %[b.strength,b.block,b.thorns],38,139,600,35,19,TEAL)
 label("易伤 %d   虚弱 %d   双生印 %d" %[b.vuln,b.weak,b.echo],38,177,600,30,16,MUTE)
 label("织火者",148,454,260,40,22,TEXT)
 health_bar(120,496,200,g.s.hp,g.s.max_hp,Color("d48576"))
 for i in range(b.enemies.size()):
  var e:Dictionary=b.enemies[i]; var x=540+i*270 if b.enemies.size()>1 else 673
  var alive=e.hp>0
  button(g.intent_text(e),Rect2(x,164,244,50),func(): choose_enemy(i),not alive,Color("e5a683") if alive else MUTE)
  var hit=button("",Rect2(x,238,244,210),func(): choose_enemy(i),not alive,TEAL if target==i else MUTE)
  var transparent=StyleBoxFlat.new(); transparent.bg_color=Color("ffffff00"); transparent.border_color=Color("7bc9c340") if target==i else Color("ffffff00"); transparent.set_border_width_all(1); transparent.set_corner_radius_all(40)
  hit.add_theme_stylebox_override("normal",transparent); hit.add_theme_stylebox_override("disabled",transparent); hit.tooltip_text="点击作为目标\n"+e.name
  label(e.name+ (" · II" if e.phase==2 else ""),x,449,246,35,22,GOLD)
  label("%d/%d  格挡%d  易伤%d" %[e.hp,e.max_hp,e.block,e.vuln],x,484,245,29,16,TEXT)
  health_bar(x,522,244,e.hp,e.max_hp,Color("ba7469"))
 box(Rect2(1043,243,208,160),Color("101f29dd"),Color("3b545d"))
 label("药水 / 点击即用",1057,251,198,30,16,MUTE)
 for i in range(g.s.potions.size()):
  var id=g.s.potions[i]
  var btn=button(C.POTIONS[id][0],Rect2(1057,289+i*34,178,29),guarded("use_potion",[i,target]),false,TEAL)
  btn.add_theme_font_size_override("font_size",14); btn.tooltip_text=C.POTIONS[id][1]+"；火焰使用当前选中目标"
 label("%d" % b.energy,45,278,110,85,64,GOLD)
 label("能量 / 3",43,367,155,30,16,MUTE)
 button("抽牌 %d"%b.draw.size(),Rect2(1038,432,102,39),func(): modal="draw"; render(),false,MUTE)
 button("弃牌 %d"%b.discard.size(),Rect2(1150,432,102,39),func(): modal="discard"; render(),false,MUTE)
 button("消耗 %d"%b.exhaust.size(),Rect2(1038,480,102,39),func(): modal="exhaust"; render(),false,MUTE)
 button("结束回合",Rect2(1041,91,211,57),guarded("end_turn"),false,GOLD).tooltip_text="Space · 弃掉手牌，敌人执行已显示意图，然后抽5张、恢复3能量"
 var hand:Array=b.hand
 var w=minf(182,1188.0/maxi(5,hand.size())-7)
 var start=(1280-(w+7)*hand.size())/2
 for i in range(hand.size()):
  var c:Dictionary=hand[i]; var d=C.card(c.id,c.up)
  card_ui(c,Rect2(start+i*(w+7),557,w,199),func(): select_card(c.uid),d.cost>b.energy,c.uid==selected_uid,str(i+1))
 if selected_uid!=-1: label("已选择攻击牌 · 点击敌人打出；再次点击卡牌取消",294,92,740,40,18,TEAL)
 elif message=="": label("点击卡牌出牌 · 攻击牌需点击目标 · 1—9选牌 · Space结束回合",37,767,1170,24,15,MUTE)
func upgrade_description(c:Dictionary) -> String:
 var next=c.duplicate(true); next.up=true
 var before=C.description(c).split("\n"); var after=C.description(next).split("\n")
 var lines:Array[String]=["能量 %d → %d" % [C.card(c.id,c.up).cost,C.card(c.id,true).cost]]
 for i in range(before.size()):
  lines.append(before[i] if before[i]==after[i] else before[i]+" → "+after[i])
 return "\n".join(lines)
func card_ui(c:Dictionary,rect:Rect2,cb:Callable,disabled=false,selected=false,key="",upgrade_preview=false):
 var d=C.card(c.id,c.up)
 var btn=button("",rect,cb,disabled,TEAL if selected else GOLD)
 if selected: btn.position.y-=12
 btn.tooltip_text=d.name+"\n"+(upgrade_description(c) if upgrade_preview else C.description(c))
 var accent=Color("c87560") if d.type=="攻击" else (TEAL if d.type=="技能" else Color("be9eda"))
 var compact=rect.size.y<260 or upgrade_preview
 var st=StyleBoxFlat.new(); st.bg_color=Color("1c3340") if not disabled else Color("16242d"); st.border_color=TEAL if selected else accent.darkened(0.35); st.set_border_width_all(2 if selected else 1); st.set_corner_radius_all(10); btn.add_theme_stylebox_override("normal",st)
 label(str(d.cost),12,6,32,40,28,accent,btn)
 var name_label=label(d.name,47,8,rect.size.x-52,34,16 if rect.size.x>145 else 12,TEXT if not disabled else MUTE,btn); name_label.clip_text=true
 label(d.type+("  ↑" if c.up else ""),12,43,rect.size.x-20,26,13,accent,btn)
 var glyph=Glyph.new(); glyph.code=C.CARDS.keys().find(c.id); glyph.tint=accent
 glyph.position=Vector2(rect.size.x-60,38) if compact else Vector2(rect.size.x/2-47,77); glyph.size=Vector2(45,38) if compact else Vector2(94,94); btn.add_child(glyph)
 var desc=label(upgrade_description(c) if upgrade_preview else C.description(c),12,78 if compact else 183,rect.size.x-23,rect.size.y-94 if compact else rect.size.y-198,14 if rect.size.x>145 else 11,TEXT if not disabled else MUTE,btn); desc.clip_text=true; desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; desc.vertical_alignment=VERTICAL_ALIGNMENT_TOP
 label(key,rect.size.x-23,rect.size.y-25,22,23,12,MUTE,btn)
func select_card(uid:int):
 if menu or modal!="" or g.s.phase!="battle": return
 for c in g.s.battle.hand:
  if c.uid==uid:
   if C.card(c.id,c.up).cost>g.s.battle.energy: message="能量不足"; render(); return
   if g.target_needed(c): selected_uid=-1 if selected_uid==uid else uid; render()
   else: act("play",[uid,target])
   return
func choose_enemy(index:int):
 target=index
 if selected_uid!=-1: act("play",[selected_uid,index])
 else: render()
func render_reward():
 label("战利品 / 一道新的可能",66,112,1050,55,34,GOLD)
 label("金币已收取；从三张牌中选择一张，也可以跳过保持牌组精简。",67,188,1130,40,20,MUTE)
 for i in range(g.s.reward.size()):
  var c={"id":g.s.reward[i],"up":false,"uid":-1,"enchant":"","affliction":""}
  card_ui(c,Rect2(236+i*277,298,237,307),guarded("take_reward",[i]))
 button("跳过奖励 →",Rect2(481,657,320,54),guarded("take_reward",[-1]),false,TEAL)
func render_camp():
 label("营火 / 再走远一点",64,118,1000,55,34,GOLD)
 label("只能选择一项。休息守住生命，锻造让牌更强。",67,190,1100,40,22,MUTE)
 button("休息 · 回复%d生命" % int(g.s.max_hp*0.3),Rect2(91,317,515,110),guarded("camp_rest"))
 button("锻造 · 选择一张牌升级",Rect2(650,317,515,110),func(): pending="upgrade"; modal="choose"; render(),false,TEAL)
 button("离开营火",Rect2(480,543,320,54),guarded("leave"),false,MUTE)
func render_shop():
 label("商店 / 行囊与取舍",47,97,1020,49,30,GOLD)
 label("商品售完不补货；药水最多3瓶；移除服务每家店仅一次。",48,153,1100,35,18,MUTE)
 for i in range(g.s.shop.offers.size()):
  var offer:Dictionary=g.s.shop.offers[i]
  var x=48+(i%3)*402; var y=221+(i/3)*185
  box(Rect2(x,y,376,163),Color("142935ef"),Color("43616a"))
  var title=""; var desc=""
  match offer.type:
   "card": title=C.CARDS[offer.id][0]+" · %d能量" % C.card(offer.id).cost; desc=C.description({"id":offer.id,"up":false})
   "relic": title=C.RELICS[offer.id][0]; desc=C.RELICS[offer.id][1]
   "potion": title=C.POTIONS[offer.id][0]; desc=C.POTIONS[offer.id][1]
  label(title,x+17,y+11,335,35,22,TEAL)
  var txt=label(desc.replace("\n","；"),x+17,y+53,338,51,15,TEXT); txt.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  button("售罄" if offer.sold else "%d金币 · 购买"%offer.price,Rect2(x+17,y+115,338,35),guarded("buy",[i]),offer.sold or g.s.gold<offer.price or (offer.type=="potion" and g.s.potions.size()>=3))
 button("移除一张牌 · %d金币"%g.price(55),Rect2(49,640,560,57),func(): pending="remove"; modal="choose"; render(),g.s.shop.removed or g.s.gold<g.price(55),TEAL)
 button("继续远征 →",Rect2(657,640,572,57),guarded("leave"))
func render_event():
 var event=C.EVENTS[g.s.event]
 label("遭遇 / "+event[0],64,119,1100,56,34,GOLD)
 label(event[1],67,202,1130,95,25,TEXT)
 for i in range(event[2].size()):
  button(event[2][i],Rect2(88,340+i*100,1100,76),func():
   if (g.s.event==0 and i==0) or (g.s.event==1 and i<2): pending="event_%d"%i; modal="choose"; render()
   else: act("event_choice",[i]))
func render_treasure():
 label("密藏 / 裂隙中的赠礼",72,160,1100,62,36,GOLD)
 label("一件未拥有的遗物，以及15枚金币。",73,246,1110,55,26,TEXT)
 button("开启宝箱 →",Rect2(390,426,500,90),guarded("treasure"))
func render_end():
 var won=g.s.phase=="victory"
 label("远征完成" if won else "火焰熄灭",67,176,780,97,63,GOLD if won else Color("d98c7c"))
 label("烬冠已落。一章切片通关。" if won else "换一个选择，再点起下一束火。",72,305,900,58,28,TEXT)
 label("击败敌阵 %d    回合 %d    打出卡牌 %d\n牌组 %d张    遗物 %d件    种子 %s"%[g.s.wins,g.s.turns,g.s.cards_played,g.s.deck.size(),g.s.relics.size(),g.s.seed],73,406,1110,110,23,MUTE)
 button("同种子重开",Rect2(77,590,340,66),func(): g.new_run(int(g.s.seed)); message=""; target=0; selected_uid=-1; g.save_to(); render())
 button("返回标题",Rect2(443,590,340,66),func(): menu=true; render(),false,TEAL)
 label("这是一章原创机制切片，不是《杀戮尖塔2》完整复刻完成版。",76,711,1100,38,18,MUTE)
func render_modal():
 var shade=ColorRect.new(); shade.color=Color("050a10ed"); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); layer.add_child(shade)
 box(Rect2(90,86,1100,646),Color("132630"),Color("64818a"))
 var titles={"pause":"已暂停", "deck":"完整牌组", "relics":"远征遗物", "log":"战斗日志", "choose":"选择一张牌", "draw":"抽牌堆（按名称排列，隐藏抽牌顺序）", "discard":"弃牌堆", "exhaust":"消耗区"}
 label("升级前 → 升级后 · 点击卡牌完成" if modal=="choose" and pending=="upgrade" else titles.get(modal,modal),120,108,920,47,28,GOLD)
 button("关闭 Esc",Rect2(1021,111,137,42),func(): modal=""; pending=""; render(),false,TEAL)
 if modal=="pause":
  label("回合制战斗已冻结。关闭窗口会保存当前远征。",143,203,980,70,24,TEXT)
  button("继续游戏",Rect2(348,330,588,65),func(): modal=""; render())
  button("保存并返回标题",Rect2(348,420,588,65),func():
   if g.save_to(): menu=true; modal=""; render(),false,TEAL)
  button("游戏帮助",Rect2(348,510,588,65),func(): modal="help"; render(),false,MUTE)
  label("种子 %s · 版本 M1.0 · 本地自动存档"%g.s.seed,141,628,970,40,18,MUTE)
 elif modal=="help":
  label("每回合3能量、抽5张。点击攻击牌，再点击敌人。\n格挡在你的下回合开始重置；力量提高攻击伤害。\n易伤使受到的攻击伤害×1.5；虚弱使攻击伤害×0.75。\n消耗牌本场战斗不再洗回；能力只在本场生效。\n药水不消耗能量，点击立即使用；瓶中焰对当前选中敌人。\n余辉附魔每次出牌+2格挡；刺痛附着每次出牌失去1生命。\n1—9选手牌，Space结束回合，Tab牌组，Esc暂停/关闭。\n商店、事件、营火有代价和不可重复选择；每次有效行动自动保存。",140,198,990,470,23,TEXT)
 elif modal=="log":
  var scroll=ScrollContainer.new(); scroll.position=Vector2(123,180); scroll.size=Vector2(1030,510); layer.add_child(scroll)
  var txt=Label.new(); txt.text="\n".join(g.s.log); txt.add_theme_font_size_override("font_size",17); scroll.add_child(txt); scroll.set_deferred("scroll_vertical",99999)
 elif modal=="relics":
  for i in range(g.s.relics.size()):
   var d=C.RELICS[g.s.relics[i]]
   label("◇ "+d[0]+"  /  "+d[1],137,190+i*59,1010,48,21,TEAL)
 else:
  var cards:Array=[]
  if modal in ["deck","choose"]: cards=g.s.deck.duplicate(true)
  elif modal in ["draw","discard","exhaust"]: cards=g.s.battle[modal].duplicate(true)
  if modal=="draw": cards.sort_custom(func(a,b): return a.id<b.id)
  var scroll=ScrollContainer.new(); scroll.position=Vector2(116,181); scroll.size=Vector2(1050,518); layer.add_child(scroll)
  var grid=GridContainer.new(); grid.columns=4; grid.add_theme_constant_override("h_separation",12); grid.add_theme_constant_override("v_separation",12); scroll.add_child(grid)
  for c in cards:
   var upgrade_preview=modal=="choose" and pending=="upgrade" and not c.up
   var card_height=305 if upgrade_preview else 211
   var holder=Control.new(); holder.custom_minimum_size=Vector2(244,card_height+10); grid.add_child(holder)
   var old_layer=layer; layer=holder
   var available=true
   if pending=="upgrade": available=not c.up
   if pending=="event_0" and g.s.event==0: available=c.enchant=="" and g.s.hp>6
   if pending=="event_1" and g.s.event==1: available=c.affliction==""
   card_ui(c,Rect2(0,0,244,card_height),func(): choose_deck_card(c.uid),modal!="choose" or not available,false,"",upgrade_preview)
   layer=old_layer
  if cards.is_empty(): label("这里暂时没有牌",147,249,700,70,23,MUTE)
func choose_deck_card(uid:int):
 if modal!="choose": return
 var action=pending; modal=""
 if action=="upgrade": act("upgrade",[uid])
 elif action=="remove": act("remove_card",[uid])
 elif action.begins_with("event_"): act("event_choice",[int(action.get_slice("_",1)),uid])
