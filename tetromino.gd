class_name Tetromino extends Node2D

enum {TypeI,TypeT,TypeJ,TypeL,TypeS,TypeZ,TypeO,TypeSize }
static func rand_type():
	return randi_range(0,TypeO )
const TetGeo = {
	# type, geo rotation
	TypeO: [[[0,0],[1,0],[1,1],[0,1]], ],
	TypeI: [[[-1,2],[0,2],[1,2],[2,2]], [[1,0],[1,1],[1,2],[1,3]], ],
	TypeS: [[[2,1],[1,1],[1,2],[0,2]], [[1,0],[1,1],[2,1],[2,2]], ],
	TypeZ: [[[0,1],[1,1],[1,2],[2,2]], [[2,0],[2,1],[1,1],[1,2]], ],
	TypeT: [[[0,1],[1,1],[2,1],[1,2]], [[1,0],[1,1],[1,2],[0,1]], [[0,1],[1,1],[2,1],[1,0]],  [[1,0],[1,1],[1,2],[2,1]], ],
	TypeJ: [[[0,1],[1,1],[2,1],[2,2]], [[1,0],[1,1],[1,2],[0,2]], [[0,1],[1,1],[2,1],[0,0]],  [[1,0],[1,1],[1,2],[2,0]], ],
	TypeL: [[[0,1],[1,1],[2,1],[0,2]], [[1,0],[1,1],[1,2],[0,0]], [[0,1],[1,1],[2,1],[2,0]],  [[1,0],[1,1],[1,2],[2,2]], ],
}
const TetColor = {
	TypeO: Color.AQUA,
	TypeI: Color.BLUE,
	TypeS: Color.RED,
	TypeZ: Color.YELLOW,
	TypeT: Color.GREEN,
	TypeJ: Color.MAGENTA,
	TypeL: Color.ORANGE,
}
const TetName = {
	TypeO: "O",
	TypeI: "I",
	TypeS: "S",
	TypeZ: "Z",
	TypeT: "T",
	TypeJ: "J",
	TypeL: "L",
}

var board : Board # board to check
var tulist = []
var x : int # x in board
var y: int  # y in board
var t: int  # tet type
var r: int  # rotate state

func _init( b :Board)->void:
	board = b

func make_tmino( xa :int,ya :int,ta :int,ra :int)->void:
	x = xa
	y = ya
	t = ta
	r = ra
	var geo = geo_by_rotate(r)
	var co = TetColor[t]
	for p in geo:
		var tu = board.new_tu(x+p[0],y+p[1], co)
		tulist.append(tu)
		board.add_child(tu)

func copy_tmino_from_next( xa :int,ya :int, tmino)->void:
	x = xa
	y = ya
	t = tmino.t
	r = tmino.r
	var geo = geo_by_rotate(r)
	var co = TetColor[t]
	for p in geo:
		var tu = board.new_tu(x+p[0],y+p[1], co)
		tulist.append(tu)
		board.add_child(tu)
	board.draw_shadow_by(tulist)

func change_type(ta :int):
	t = ta
	var geo = geo_by_rotate(r)
	var co = TetColor[t]
	for i in tulist.size():
		var g = geo[i]
		tulist[i].position.x = (x+g[0]) * board.board2screenW
		tulist[i].position.y = (y+g[1]) * board.board2screenH
		tulist[i].set_color(co)

func geo_by_rotate(ra :int)->Array:
	var geo = TetGeo[t]
	return geo[ra%geo.size()]

func tulist2poslist()->Array:
	var poslist = []
	for tu in tulist:
		poslist.append(tu.position)
	return poslist

func poslist2tulist(poslist :Array)->void:
	for i in tulist.size():
		tulist[i].position = poslist[i]

func is_in_poslist(poslist :Array)->bool:
	for pos in poslist:
		var xl = pos.x / board.board2screenW
		var yl = pos.y / board.board2screenH
		if !board.is_in(xl,yl) || !board.empty_at(xl,yl):
#				print("not is_in %s" % pos)
			return false
	return true

func move_left()->bool:
	var poslist = tulist2poslist()
	for i in poslist.size():
		poslist[i].x -= board.board2screenW
	if is_in_poslist(poslist):
		poslist2tulist(poslist)
		board.draw_shadow_by(tulist)
		return true
	return false

func move_right()->bool:
	var poslist = tulist2poslist()
	for i in poslist.size():
		poslist[i].x += board.board2screenW
	if is_in_poslist(poslist):
		poslist2tulist(poslist)
		board.draw_shadow_by(tulist)
		return true
	return false

func move_down()->bool:
	var poslist = tulist2poslist()
	for i in poslist.size():
		poslist[i].y += board.board2screenH
	if is_in_poslist(poslist):
		poslist2tulist(poslist)
		board.draw_shadow_by(tulist)
		return true
	return false

func tmino_rotate()->bool:
	var poslist = tulist2poslist()
	var oldgeo = geo_by_rotate(r)
	var newgeo = geo_by_rotate(r+1)
	for i in poslist.size():
		var oldg = oldgeo[i]
		var newg = newgeo[i]
		poslist[i].x += (newg[0]-oldg[0]) *board.board2screenW
		poslist[i].y += (newg[1]-oldg[1]) *board.board2screenH
	if is_in_poslist(poslist):
		poslist2tulist(poslist)
		r+=1
		board.draw_shadow_by(tulist)
		return true
	return false
