extends SceneTree
const Main=preload("res://scripts/main.gd")
const G=preload("res://scripts/game.gd")
const C=preload("res://scripts/catalog.gd")
# Headless UI verification excludes playback; native audio is separately blocked by the host.
class SilentMain:
 extends Main
 func tone(_hz:float=520.0): pass
var checks=0
var failures=0
var transcript:Array=[]
var g=G.new()
func ck(ok:bool,msg:String):
 checks+=1
 if not ok: failures+=1; print("FAIL "+msg)
func step(method:String,args:Array=[]):
 ck(g.callv(method,args),"natural replay "+method+str(args))
 transcript.append({"action":method,"args":args})
func play(id:String):
 for c in g.s.battle.hand:
  if c.id==id: step("play",[c.uid,0]); return
 ck(false,"natural hand missing "+id)
func card_uid(id:String) -> int:
 for c in g.s.deck:
  if c.id==id: return c.uid
 return -1
func collect(n:Node,kind:String) -> Array:
 var out:Array=[]
 if n.is_class(kind): out.append(n)
 for child in n.get_children(): out.append_array(collect(child,kind))
 return out
func _initialize(): call_deferred("run")
func run():
 # Exact strategy manually completed in native GUI on baseline 33bc8a3.
 # Every fixture is produced only by legal actions; no HP/deck/phase edits.
 g.new_run(20261003); step("ancient",[0]); step("choose_node",["0_0"])
 play("flare"); play("cut"); step("end_turn")
 play("cut"); play("cut"); play("cut"); step("take_reward",[0])
 step("choose_node",["1_1"]); step("event_choice",[0,g.s.deck[0].uid])
 step("choose_node",["2_0"]); ck(g.save_to("res://tests/fixtures/independent_camp.json"),"save natural camp fixture")
 step("upgrade",[card_uid("flare")]); step("choose_node",["3_0"])
 play("fracture"); play("cut"); play("cut"); play("brace"); step("end_turn")
 play("flare"); play("cut"); play("cut"); step("use_potion",[0,0]); step("take_reward",[0])
 step("choose_node",["4_0"]); step("treasure"); step("choose_node",["5_1"])
 ck(g.save_to("res://tests/fixtures/independent_shop.json"),"save natural shop fixture")
 step("buy",[1]); step("buy",[3]); step("leave"); step("choose_node",["6_1"])
 play("flare"); play("immolate"); play("drain"); step("take_reward",[-1]); step("choose_node",["7_0"])
 step("upgrade",[card_uid("immolate")]); step("choose_node",["8_0"])
 play("fracture"); play("immolate"); play("flare"); play("cut"); play("brace"); step("end_turn")
 play("cut"); play("drain"); play("brace"); step("end_turn")
 play("fracture"); play("cut"); play("cut"); play("cut"); step("end_turn"); play("drain")
 ck(g.s.phase=="victory" and g.s.hp==53 and g.s.turns==9 and g.s.cards_played==28,"manual GUI route reproduces exact victory")
 var trace=FileAccess.open("res://tests/fixtures/independent_natural_trace.json",FileAccess.WRITE)
 trace.store_string(JSON.stringify({"seed":20261003,"actions":transcript,"outcome":"victory","note":"Replays the strategy manually completed from new run to victory through native GUI on baseline 33bc8a3. No state injection."},"  ")); trace.close()
 var main=SilentMain.new(); root.add_child(main); await process_frame
 main.menu=false
 for id in C.CARDS:
  var c={"id":id,"uid":123,"up":false,"enchant":"glow","affliction":"sting"}
  var frozen=JSON.stringify(c)
  var before=C.description(c).split("\n"); var upgraded=c.duplicate(true); upgraded.up=true
  var after=C.description(upgraded).split("\n")
  ck(before.size()==after.size(),"comparison lines aligned "+id)
  var summary=main.upgrade_description(c)
  ck(summary.begins_with("能量 %d → %d" % [C.card(id).cost,C.card(id,true).cost]),"comparison includes cost "+id)
  for i in range(before.size()):
   ck(summary.contains(before[i]) and summary.contains(after[i]),"comparison includes effects "+id+str(i))
  ck(JSON.stringify(c)==frozen,"comparison never mutates card "+id)
  main.layer=Control.new(); main.add_child(main.layer)
  main.card_ui(c,Rect2(0,0,244,305),func(): pass,false,false,"",true)
  await process_frame
  for txt in collect(main.layer,"Label"):
   if txt.text==summary: ck(txt.get_minimum_size().y<=211,"comparison text fits "+id)
  main.remove_child(main.layer); main.layer.queue_free(); main.layer=null
 ck(main.g.load_from("res://tests/fixtures/independent_camp.json"),"load old-schema camp fixture")
 main.pending="upgrade"; main.modal="choose"; var original=JSON.stringify(main.g.s); main.render(); await process_frame
 ck(JSON.stringify(main.g.s)==original,"preview rendering does not upgrade or consume camp")
 var flare=main.g.s.deck.filter(func(c): return c.id=="flare")[0]
 ck(main.upgrade_description(flare).contains("能量 2 → 1") and main.upgrade_description(flare).contains("造成8伤害 → 造成11伤害"),"flare explicit before-after")
 main.choose_deck_card(flare.uid); var revision=main.g.s.revision; main.choose_deck_card(flare.uid)
 ck(main.g.s.phase=="map" and flare.up and main.g.s.revision==revision,"upgrade exactly once on repeated click")
 ck(main.g.save_to("user://independent_upgrade.json"),"save upgraded state")
 var restored=G.new(); ck(restored.load_from("user://independent_upgrade.json"),"load upgraded state")
 ck(restored.s.phase=="map" and restored.s.deck.filter(func(c): return c.id=="flare")[0].up,"upgrade persists")
 ck(main.g.load_from("res://tests/fixtures/independent_shop.json"),"load old-schema shop fixture")
 main.modal=""; main.pending=""; original=JSON.stringify(main.g.s); main.render(); await process_frame
 var labels=collect(main.layer,"Label").map(func(n): return n.text)
 var tab=InputEventKey.new(); tab.keycode=KEY_TAB; tab.pressed=true
 collect(main.layer,"Button")[0].grab_focus(); Input.parse_input_event(tab); await process_frame
 ck(main.modal=="deck","real Tab dispatch opens deck even with button focus")
 main.modal=""; main.render(); tab.echo=true; Input.parse_input_event(tab); await process_frame
 ck(main.modal=="","Tab repeat is ignored")
 for o in main.g.s.shop.offers:
  if o.type=="card": ck(labels.has(C.CARDS[o.id][0]+" · %d能量" % C.card(o.id).cost),"shop energy visible "+o.id)
 ck(JSON.stringify(main.g.s)==original,"shop price display does not mutate state")
 var purchase=main.guarded("buy",[1]); purchase.call(); var gold=main.g.s.gold; var count=main.g.s.deck.size(); purchase.call()
 ck(main.g.s.gold==gold and main.g.s.deck.size()==count,"shop stale repeated purchase guarded")
 ck(main.g.save_to("user://independent_shop.json") and restored.load_from("user://independent_shop.json"),"shop save/load")
 ck(restored.s.shop.offers[1].sold and restored.s.gold==gold,"shop purchase persists")
 main.queue_free(); await process_frame
 print("INDEPENDENT CHECKS %d; FAILURES %d" % [checks,failures]); quit(failures)
