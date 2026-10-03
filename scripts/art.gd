extends Control
var scene_kind="menu"
var opponents:Array=[]
var seed_value=0
const GOLD=Color("d8ae69")
const TEAL=Color("70b7b1")
func _ready(): mouse_filter=Control.MOUSE_FILTER_IGNORE
func poly(points:Array,c:Color): draw_colored_polygon(PackedVector2Array(points),c)
func _draw():
 draw_rect(Rect2(0,0,1280,800),Color("101b25"))
 for i in range(9):
  var x=60+i*157
  poly([Vector2(x-90,540),Vector2(x-60,250-i%3*80),Vector2(x-12,290-i%3*90),Vector2(x+23,165+i%4*37),Vector2(x+94,540)],Color("182b37"))
 draw_circle(Vector2(890,228),145,Color("273f49"))
 draw_circle(Vector2(911,210),131,Color("182b37"))
 for i in range(24):
  var x=fmod(i*153.7+23,1280); var y=fmod(i*47.3+30,530)
  draw_circle(Vector2(x,y),1.2,Color("bd986244"))
 poly([Vector2(0,590),Vector2(250,470),Vector2(500,590),Vector2(760,460),Vector2(1280,570),Vector2(1280,800),Vector2(0,800)],Color("14212a"))
 for i in range(6): draw_line(Vector2(0,650+i*28),Vector2(1280,650+i*28),Color("29404b"),1)
 if scene_kind in ["menu","ancient","victory","defeat"]:
  crown(Vector2(900,375),2.5,Color("d6a763"))
  for k in range(3): draw_arc(Vector2(900,360),160+k*22,0,TAU,90,Color("53727855"),1)
 elif scene_kind=="battle":
  hero(Vector2(213,362))
  var n=opponents.size()
  for i in range(n):
   var x=660+i*270 if n>1 else 793
   creature(Vector2(x,350),opponents[i],i)
 elif scene_kind=="map":
  draw_arc(Vector2(990,315),190,0,TAU,80,Color("4d727657"),2)
func crown(p:Vector2,k:float,c:Color):
 var pts=[Vector2(-50,12),Vector2(-64,-53),Vector2(-25,-22),Vector2(0,-74),Vector2(25,-22),Vector2(64,-53),Vector2(50,12)]
 for i in range(pts.size()): pts[i]=p+pts[i]*k
 poly(pts,c); draw_line(p+Vector2(-50,22)*k,p+Vector2(50,22)*k,c,4*k)
 for x in [-26,0,26]: draw_circle(p+Vector2(x,-7)*k,5*k,Color("172731"))
func hero(p:Vector2):
 draw_set_transform(p)
 draw_circle(Vector2(0,126),82,Color("060c1280"))
 poly([Vector2(-60,95),Vector2(-39,-48),Vector2(0,-77),Vector2(44,-49),Vector2(79,109),Vector2(20,89),Vector2(-2,127)],Color("a65347"))
 poly([Vector2(-45,84),Vector2(-29,-49),Vector2(3,-72),Vector2(25,-31),Vector2(14,109)],Color("d77f5a"))
 poly([Vector2(-25,-66),Vector2(-16,-106),Vector2(17,-111),Vector2(32,-78),Vector2(21,-50)],Color("dfc99e"))
 poly([Vector2(-18,-100),Vector2(8,-120),Vector2(35,-101),Vector2(21,-84),Vector2(-30,-76)],Color("203844"))
 draw_line(Vector2(52,-40),Vector2(91,94),GOLD,7)
 poly([Vector2(44,-66),Vector2(52,-133),Vector2(67,-74),Vector2(57,-23)],TEAL)
 draw_circle(Vector2(16,-79),3,Color("162a34"))
 draw_line(Vector2(-30,36),Vector2(15,49),Color("efd5a2"),4)
 draw_set_transform(Vector2.ZERO)
func creature(p:Vector2,e:Dictionary,index:int):
 var c=Color("799b9c") if index%2==0 else Color("c08c73")
 if e.hp<=0: c=Color("34434b")
 draw_set_transform(p)
 draw_circle(Vector2(0,121),85,Color("060c1280"))
 match e.id:
  "moth":
   poly([Vector2(-6,-20),Vector2(-100,-92),Vector2(-82,12),Vector2(-109,78),Vector2(-23,58),Vector2(0,105),Vector2(23,58),Vector2(109,78),Vector2(82,12),Vector2(100,-92),Vector2(6,-20)],c)
   for x in [-55,55]: draw_circle(Vector2(x,5),21,Color("d5ad6d")); draw_circle(Vector2(x,5),9,Color("223641"))
   poly([Vector2(-12,-37),Vector2(10,-37),Vector2(17,51),Vector2(0,82),Vector2(-17,51)],Color("243b43"))
  "hound","leech":
   poly([Vector2(-87,75),Vector2(-65,-3),Vector2(-23,-13),Vector2(4,-82),Vector2(34,-59),Vector2(52,-96),Vector2(73,-35),Vector2(106,-7),Vector2(78,20),Vector2(42,14),Vector2(60,92),Vector2(30,92),Vector2(4,43),Vector2(-37,50),Vector2(-58,100)],c)
   draw_line(Vector2(66,-22),Vector2(81,-19),GOLD,5)
   for i in range(3): draw_line(Vector2(-30+i*18,0),Vector2(-45+i*17,38),Color("32444a"),5)
  "sovereign":
   poly([Vector2(-90,112),Vector2(-69,-25),Vector2(-28,-60),Vector2(0,-88),Vector2(30,-56),Vector2(68,-25),Vector2(96,115)],Color("824c4c") if e.phase==1 else Color("b87652"))
   poly([Vector2(-39,80),Vector2(-31,-40),Vector2(0,-66),Vector2(29,-41),Vector2(45,83)],Color("263e46"))
   crown(Vector2(0,-83),0.9,GOLD)
   draw_circle(Vector2(-13,-27),5,TEAL); draw_circle(Vector2(13,-27),5,TEAL)
  _:
   poly([Vector2(-67,95),Vector2(-61,-43),Vector2(-25,-67),Vector2(-17,-101),Vector2(25,-101),Vector2(41,-56),Vector2(66,-34),Vector2(71,94),Vector2(30,112),Vector2(0,76),Vector2(-34,115)],c)
   poly([Vector2(-36,-9),Vector2(0,-36),Vector2(40,-9),Vector2(25,68),Vector2(-19,72)],Color("314854"))
   draw_circle(Vector2(0,8),20,GOLD); draw_circle(Vector2(0,8),10,Color("233b44"))
   draw_line(Vector2(-11,-70),Vector2(19,-70),GOLD,5)
   if e.id=="colossus": draw_rect(Rect2(-85,-60,33,157),Color("c19d69")); draw_rect(Rect2(61,-70,30,166),Color("c19d69"))
 draw_set_transform(Vector2.ZERO)
