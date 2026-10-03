extends SceneTree
const G=preload("res://scripts/game.gd")
const C=preload("res://scripts/catalog.gd")
var checks=0
var errors:Array=[]
func ck(ok:bool,msg:String):
 checks+=1
 if not ok: errors.append(msg); print("FAIL "+msg)
func fresh(seed_value:int=33):
 var g=G.new(); g.new_run(seed_value); g.ancient(0); g.choose_node("0_1"); return g
func give(g,id:String,up:bool=false):
 var card=g.make_card(id,up); g.s.battle.hand.append(card); g.s.battle.initial_count+=1; return card
func setup_single():
 var g=fresh(); g.s.battle.enemies=[{"id":"sentinel","name":"测试","hp":999,"max_hp":999,"block":0,"strength":0,"vuln":0,"step":0,"phase":1}]; g.s.battle.energy=100; return g
func _init():
 var g=setup_single(); ck(C.CARDS.size()==24,"24 cards"); ck(C.RELICS.size()==8,"8 relics"); ck(C.POTIONS.size()==3,"3 potions"); ck(C.ENEMIES.size()==9,"9 enemies")
 for id in C.CARDS:
  for up in [false,true]:
   g=setup_single(); var c=give(g,id,up); var hp=g.s.battle.enemies[0].hp
   ck(g.play(c.uid,0),"play "+id+str(up)); ck(g.zones_valid(),"zones "+id+str(up))
   ck(not g.play(c.uid,0),"duplicate card rejected "+id+str(up))
 g=setup_single(); g.s.battle.strength=2; g.s.battle.enemies[0].vuln=1; var c=give(g,"cut"); g.play(c.uid,0)
 ck(g.s.battle.enemies[0].hp==987,"strength + vulnerability (6+2)*1.5=12")
 g=setup_single(); g.s.battle.strength=2; g.s.battle.echo=1; c=give(g,"cut"); g.play(c.uid,0)
 ck(g.s.battle.enemies[0].hp==983,"echo includes strength twice")
 g=setup_single(); g.s.battle.enemies[0].block=5; c=give(g,"cut"); g.play(c.uid,0); ck(g.s.battle.enemies[0].hp==997,"enemy block absorbs first")
 g=setup_single(); c=give(g,"cut"); g.s.battle.energy=0; ck(not g.play(c.uid,0),"no energy no mutation"); ck(g.zones_valid(),"insufficient energy zones")
 g=setup_single(); c=give(g,"cut"); ck(not g.play(c.uid,-1),"attack requires target"); ck(not g.play(c.uid,10),"invalid target")
 g=setup_single(); c=give(g,"cut"); c.enchant="glow"; c.affliction="sting"; var hp=g.s.hp; g.play(c.uid,0); ck(g.s.hp==hp-1 and g.s.battle.block==2,"attachment effects")
 g=setup_single(); c=give(g,"temper"); g.play(c.uid,0); ck(g.s.battle.exhaust.has(c),"exhaust zone")
 g=setup_single(); c=give(g,"vault"); g.play(c.uid,0); g.end_turn(); ck(g.s.battle.block==8,"next turn block")
 g=setup_single(); g.s.battle.hand.clear(); g.s.battle.draw.clear(); g.s.battle.discard.clear(); g.s.battle.exhaust.clear(); g.s.battle.initial_count=0; c=give(g,"reclaim"); g.play(c.uid,0); ck(g.s.battle.hand.is_empty(),"resolving card is not shuffled mid-effect"); ck(g.zones_valid(),"limbo accounted after effect")
 g=setup_single(); g.s.battle.hand.clear(); g.s.battle.draw.clear(); g.s.battle.discard.clear(); g.s.battle.exhaust.clear(); g.s.battle.initial_count=0
 for _i in range(12): var card=g.make_card("cut"); g.s.battle.draw.append(card); g.s.battle.initial_count+=1
 g.draw_cards(12); ck(g.s.battle.hand.size()==10,"hand cap 10"); ck(g.zones_valid(),"draw hand cap conservation")
 g=setup_single(); g.s.hp=1; c=give(g,"bloodfuel"); g.play(c.uid,0); ck(g.s.phase=="defeat","self damage defeat first"); ck(g.zones_valid(),"death zone conservation")
 g=setup_single(); g.s.hp=1; g.end_turn(); ck(g.s.phase=="battle","sentinel guard opening"); g.end_turn(); ck(g.s.phase=="defeat","enemy attack defeat")
 g=setup_single(); g.s.battle.kind="boss"; g.s.battle.enemies[0].hp=1; c=give(g,"cut"); g.play(c.uid,0); ck(g.s.phase=="victory","boss victory")
 g=setup_single(); g.s.battle.enemies[0].hp=1; c=give(g,"cut"); g.play(c.uid,0); ck(g.s.phase=="reward" and g.s.reward.size()==3,"normal rewards"); var deck_size=g.s.deck.size(); g.take_reward(-1); ck(g.s.deck.size()==deck_size,"skip reward"); ck(not g.take_reward(0),"duplicate reward")
 g=setup_single(); g.start_battle("boss",0); g.enemy_damage(0,90,false); ck(g.s.battle.enemies[0].phase==2,"boss second phase"); ck(g.intent(g.s.battle.enemies[0])[0]=="multi","phase intent changed")
 g=setup_single(); g.s.phase="shop"; g.s.gold=1000; g.build_shop(); var cost=g.s.shop.offers[0].price; ck(g.buy(0),"shop purchase"); ck(g.s.gold==1000-cost,"exact cost"); ck(not g.buy(0),"sold out duplicate"); ck(g.remove_card(g.s.deck[0].uid),"remove card"); ck(not g.remove_card(g.s.deck[0].uid),"one remove per shop")
 for ev in range(4):
  for ix in range(C.EVENTS[ev][2].size()):
   g=setup_single(); g.s.phase="event"; g.s.event=ev; g.s.gold=1000
   ck(g.event_choice(ix,g.s.deck[0].uid),"event %d choice %d"%[ev,ix]); ck(g.s.phase=="map","event exit")
 g=setup_single(); g.s.phase="event"; g.s.event=0; g.s.hp=6; ck(not g.event_choice(0,g.s.deck[0].uid),"event cost cannot kill")
 g=setup_single(); g.s.phase="camp"; ck(g.upgrade(g.s.deck[0].uid),"camp upgrade"); ck(g.s.deck[0].up,"camp changes master")
 for seed_value in range(100):
  g=G.new(); g.new_run(seed_value); g.ancient(seed_value%3)
  for f in range(9):
   var legal=g.legal_nodes(); ck(not legal.is_empty(),"map no dead end seed%d floor%d"%[seed_value,f]); ck(not g.choose_node("bad"),"invalid route")
   if legal.is_empty(): break
   var n=legal[seed_value%legal.size()]; ck(g.choose_node(n.id),"legal route accepted"); g.s.phase="map"
  ck(g.s.floor==8,"map boss reached")
 # Relic and potion behavior, persistence, and malformed-save defenses.
 for rid in C.RELICS:
  g=G.new(); g.new_run(44); g.s.relics=[rid]; g.ancient(1); g.choose_node("0_1")
  match rid:
   "lens": ck(g.s.battle.hand.size()==7,"lens draw +2")
   "anvil": ck(g.s.battle.strength==1,"anvil strength")
   "cloak": ck(g.s.battle.block==2,"cloak opening block"); g.end_turn(); ck(g.s.battle.block==2,"cloak recurring block")
   "seed": ck(g.s.battle.thorns==2,"seed thorns")
   "chalice": ck(g.s.battle.energy==4,"chalice opening energy"); g.end_turn(); ck(g.s.battle.energy==3,"chalice only first turn")
   "coin": ck(g.price(100)==80,"coin discount")
   "coal":
    g.s.hp=30
    for enemy in g.s.battle.enemies: enemy.hp=0
    g.check_outcome(); ck(g.s.hp==34,"coal heals victory")
   "bell":
    g.s.battle.played=5; g.s.battle.energy=3; c=give(g,"brace"); g.play(c.uid,0); ck(g.s.battle.energy==3,"bell sixth play refund")
 for potion in C.POTIONS:
  g=setup_single(); g.s.potions=[potion]; g.s.hp=30; var energy=g.s.battle.energy
  ck(g.use_potion(0,0),"use potion "+potion); ck(g.s.potions.is_empty(),"potion consumed"); ck(g.s.battle.energy==energy,"potions cost no energy")
  if potion=="fire": ck(g.s.battle.enemies[0].hp==979,"potion fixed damage")
  if potion=="guard": ck(g.s.battle.block==15,"potion block")
  if potion=="renew": ck(g.s.hp==42,"potion heal")
 g=setup_single(); g.s.phase="shop"; g.s.gold=200; g.s.shop={"removed":false,"offers":[{"type":"relic","id":"coin","base":100,"price":100,"sold":false},{"type":"card","id":"cut","base":50,"price":50,"sold":false}]}; g.buy(0); ck(g.s.shop.offers[1].price==40,"mid-shop coin reprices unsold offers")
 g=setup_single(); g.s.max_hp=1000; g.s.hp=1000; g.save_to("user://rng-multiple.json"); var same=G.new(); same.load_from("user://rng-multiple.json")
 for _t in range(7):
  g.end_turn(); same.end_turn(); var left=g.s.duplicate(true); var right=same.s.duplicate(true); left.erase("revision"); right.erase("revision"); ck(left==right,"restored multiple shuffle equality")
 ck(g.rng.randi()==same.rng.randi(),"restored next random output")
 var base=g.s.duplicate(true); base.rng_seed=str(g.rng.seed); base.rng_state=str(g.rng.state)
 for field in ["deck","battle","map","potions","rng_state"]:
  var invalid=base.duplicate(true); invalid[field]=null; ck(not g.valid_state(invalid),"invalid nested save rejected "+field)
 var duplicate=base.duplicate(true); duplicate.deck.append(duplicate.deck[0].duplicate()); ck(not g.valid_state(duplicate),"duplicate UID save rejected")
 # Same seed and same decisions, plus disk save / RNG restoration.
 g=setup_single(); var state_before=g.s.duplicate(true); ck(g.save_to("user://test-valid.json"),"save")
 var restored=G.new(); ck(restored.load_from("user://test-valid.json"),"load")
 ck(g.rng.state==restored.rng.state,"rng state exact 64bit string")
 g.end_turn(); restored.end_turn(); var a=g.s.duplicate(true); var b=restored.s.duplicate(true); a.erase("revision"); b.erase("revision"); ck(a==b,"continued state equality")
 if a!=b:
  for key in a:
   if a[key]!=b[key]: print("DIFF "+str(key)+" A="+str(a[key])+" B="+str(b[key]))
 var f=FileAccess.open("user://test-corrupt.json",FileAccess.WRITE); f.store_string('{"payload":"oops","checksum":"broken"}'); f.close(); ck(not restored.load_from("user://test-corrupt.json"),"corrupt save rejected")
 ck(restored.s.phase=="battle","invalid save leaves current state intact")
 for seed_value in range(10):
  var one=G.new(); var two=G.new(); one.new_run(seed_value); two.new_run(seed_value); one.ancient(1); two.ancient(1); one.choose_node("0_1"); two.choose_node("0_1"); ck(JSON.stringify(one.s)==JSON.stringify(two.s),"same seed equality")
 # Autoplay bounded 30 natural seeds: smoke, zone invariants, legal path, terminal outcome.
 var wins=0; var defeats=0
 for seed_value in range(30):
  g=G.new(); g.new_run(seed_value+20261000); g.ancient(0)
  var actions=0
  while not g.s.phase in ["victory","defeat"] and actions<1500:
   actions+=1
   match g.s.phase:
    "map":
     var legal=g.legal_nodes(); var pick=legal[0]
     for n in legal:
      if n.kind in ["camp","treasure","event"]: pick=n; break
      if n.kind=="battle": pick=n
     g.choose_node(pick.id)
    "battle":
     ck(g.zones_valid(),"autoplay zones")
     var target=0
     for e in range(g.s.battle.enemies.size()):
      if g.s.battle.enemies[e].hp>0: target=e; break
     if g.s.potions.size()>0 and g.s.battle.enemies[target].hp>20: g.use_potion(0,target)
     if g.s.phase!="battle": continue
     var played=false
     for card in g.s.battle.hand.duplicate():
      if g.play(card.uid,target): played=true; break
     if not played: g.end_turn()
    "reward":
     var choice=-1
     for i in range(g.s.reward.size()):
      if g.s.reward[i] in ["quickstep","drain","temper","vow","sunder","redoubt","wardthorns","fracture"]: choice=i; break
     g.take_reward(choice)
    "camp": g.camp_rest()
    "treasure": g.treasure()
    "shop": g.leave()
    "event": g.event_choice(C.EVENTS[g.s.event][2].size()-1,g.s.deck[0].uid)
   if g.s.phase=="battle": ck(g.zones_valid(),"autoplay post zones")
  ck(actions<1500,"bounded terminal run")
  if g.s.phase=="victory": wins+=1
  elif g.s.phase=="defeat": defeats+=1
 print("AUTOPLAY natural seeds: wins=%d defeats=%d"%[wins,defeats])
 print("RULE CHECKS %d; FAILURES %d"%[checks,errors.size()])
 for e in errors: print(e)
 quit(0 if errors.is_empty() else 1)
