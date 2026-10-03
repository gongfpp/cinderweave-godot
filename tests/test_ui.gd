extends SceneTree
const Main=preload("res://scripts/main.gd")
const C=preload("res://scripts/catalog.gd")
var checks=0
var failures=0
func ck(ok:bool,msg:String):
 checks+=1
 if not ok: failures+=1; print("FAIL "+msg)
func _initialize(): call_deferred("run")
func run():
 var main=Main.new(); root.add_child(main); await process_frame
 main.g.new_run(33); main.menu=false; main.render(); await process_frame
 ck(main.g.s.phase=="ancient","ancient UI")
 main.act("ancient",[0]); main.act("choose_node",["0_1"]); await process_frame
 var stale=main.guarded("end_turn"); stale.call(); var turn=main.g.s.battle.turn; stale.call(); ck(main.g.s.battle.turn==turn,"stale double-click rejected by revision")
 var key=InputEventKey.new(); key.keycode=KEY_ESCAPE; key.pressed=true; main._unhandled_key_input(key); ck(main.modal=="pause","Escape pause")
 var space=InputEventKey.new(); space.keycode=KEY_SPACE; space.pressed=true; main._unhandled_key_input(space); ck(main.g.s.battle.turn==turn,"paused Space cannot play")
 main._unhandled_key_input(key); ck(main.modal=="","Escape closes pause")
 for modal in ["deck","draw","discard","exhaust","log","relics","pause","help"]:
  main.modal=modal; main.render(); await process_frame; ck(is_instance_valid(main.layer),"render modal "+modal)
 main.modal=""
 for phase in ["ancient","map","reward","camp","shop","event","treasure","victory","defeat"]:
  main.g.s.phase=phase
  if phase=="reward": main.g.s.reward=["quickstep","drain","echo"]
  if phase=="shop": main.g.build_shop()
  main.render(); await process_frame; ck(is_instance_valid(main.layer),"render phase "+phase)
 main.g.s.phase="shop"; main.g.build_shop(); main.pending="remove"; main.modal="choose"; main.render(); await process_frame; ck(main.layer.get_child_count()>2,"deck chooser")
 main.modal=""; main.g.start_battle("boss",0); main.g.s.battle.hand.clear(); main.g.s.battle.draw.clear(); main.g.s.battle.discard.clear(); main.g.s.battle.initial_count=10
 for i in range(10): main.g.s.battle.hand.append(main.g.make_card(C.CARDS.keys()[i+10]))
 main.render(); await process_frame; ck(main.g.s.battle.hand.size()==10,"10-card layout rendered")
 main.queue_free(); await process_frame
 print("UI CHECKS %d; FAILURES %d"%[checks,failures]); quit(failures)
