extends Control
var code=0
var tint=Color("d1a568")
func _ready(): mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw():
 var p=size/2; var r=minf(size.x,size.y)*0.38
 draw_arc(p,r,0,TAU,36,Color(tint,0.25),1)
 var sides=3+code%5
 var points=PackedVector2Array()
 for i in range(sides): points.append(p+Vector2.from_angle(TAU*i/sides-PI/2)*r)
 points.append(points[0]); draw_polyline(points,Color(tint,0.7),1.6,true)
 for i in range(1+code/5):
  var a=TAU*i/(1+code/5)-PI/2
  draw_line(p,p+Vector2.from_angle(a)*r*0.7,tint,1.5,true)
 draw_circle(p,2+code%3,Color(tint,0.8))
