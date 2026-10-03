extends SceneTree
const G=preload("res://scripts/game.gd")
const C=preload("res://scripts/catalog.gd")
func _init():
 var saved_win=false; var saved_loss=false
 for seed_value in range(30):
  var g=G.new(); g.new_run(seed_value+20261000); g.ancient(0)
  var actions=0; var transcript:Array=[]
  while not g.s.phase in ["victory","defeat"] and actions<1500:
   actions+=1
   var method=""; var args:Array=[]
   match g.s.phase:
    "map":
     var legal=g.legal_nodes(); var pick=legal[0]
     for n in legal:
      if n.kind in ["camp","treasure","event"]: pick=n; break
      if n.kind=="battle": pick=n
     method="choose_node"; args=[pick.id]
    "battle":
     var target=0
     for e in range(g.s.battle.enemies.size()):
      if g.s.battle.enemies[e].hp>0: target=e; break
     if g.s.potions.size()>0 and g.s.battle.enemies[target].hp>20:
      method="use_potion"; args=[0,target]
     else:
      for card in g.s.battle.hand:
       if C.card(card.id,card.up).cost<=g.s.battle.energy: method="play"; args=[card.uid,target]; break
      if method=="": method="end_turn"
    "reward":
     var choice=-1
     for i in range(g.s.reward.size()):
      if g.s.reward[i] in ["quickstep","drain","temper","vow","sunder","redoubt","wardthorns","fracture"]: choice=i; break
     method="take_reward"; args=[choice]
    "camp": method="camp_rest"
    "treasure": method="treasure"
    "shop": method="leave"
    "event": method="event_choice"; args=[C.EVENTS[g.s.event][2].size()-1,g.s.deck[0].uid]
   var prior=G.new(); prior.s=g.s.duplicate(true); prior.rng.seed=g.rng.seed; prior.rng.state=g.rng.state
   g.callv(method,args); transcript.append({"action":method,"args":args})
   if (g.s.phase=="victory" and not saved_win) or (g.s.phase=="defeat" and not saved_loss):
    var outcome=g.s.phase
    prior.save_to("res://tests/fixtures/"+outcome+"_last.json")
    var f=FileAccess.open("res://tests/fixtures/"+outcome+"_trace.json",FileAccess.WRITE)
    f.store_string(JSON.stringify({"seed":prior.s.seed,"ancient":0,"actions":transcript,"final_action":{"method":method,"args":args},"outcome":outcome,"note":"Generated solely by legal rules; no HP, deck, rewards, or outcomes were edited."},"  ")); f.close()
    print(outcome+" fixture seed "+prior.s.seed+" last "+method+str(args))
    if outcome=="victory": saved_win=true
    else: saved_loss=true
  if saved_win and saved_loss: break
 quit()
