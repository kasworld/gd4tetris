extends Node2D

class Board:
	const BoardScale = 1
	const BoardW = 10*BoardScale
	const BoardH = 20*BoardScale
	var Board2ScreenW  # screen board ratio
	var Board2ScreenH  # screen board ratio
	var UnitBorderSize
	func MakeUnit():
		var tu = Polygon2D.new()
		tu.set_polygon( PackedVector2Array([
			Vector2(UnitBorderSize,UnitBorderSize),
			Vector2(UnitBorderSize,Board2ScreenH),
			Vector2(Board2ScreenW,Board2ScreenH),
			Vector2(Board2ScreenW,UnitBorderSize),]
		))
		return tu

	var board 		# array [BoardW][BoardH] of TetUnit
	var free_unit 	# reuse unit
	var scene 		# scene to draw
	var fulllines = []
	var shadow = []
	var shadow_color= Color8( 0, 0, 0, 127 )
	func new_shadow():
		for i in 4:
			var o = new_unit(0,0,shadow_color)
			shadow.append(o)
			scene.add_child(o)
		show_shadow(false)

	func _init(s) -> void:
		var width = ProjectSettings.get_setting("display/window/size/viewport_width")
		var height =  ProjectSettings.get_setting("display/window/size/viewport_height")
		Board2ScreenW = width / BoardW
		Board2ScreenH = height / BoardH
		UnitBorderSize = max(Board2ScreenW / 20,1)
		scene = s
		free_unit = []
		new_shadow()
		new_board()

	func new_board():
		board = []
		board.resize(BoardW)
		for i in range(BoardW):
			board[i] = []
			board[i].resize(BoardH)

	func clear_board():
		for row in board:
			for o in row:
				if o != null:
					scene.remove_child(o)
					free_unit.push_back(o)
		new_board()

	func new_unit(x,y,co):
		var tu
		if len(free_unit) == 0 :
			tu =  MakeUnit()
		else:
			tu = free_unit.pop_back()
		tu.position.x = x * Board2ScreenW
		tu.position.y = y * Board2ScreenH
		tu.set_color(co )
		return tu

	# 장애물 미리 설정할때 사용.
	func add_unit_to_board(x,y,co)->bool:
		if !is_in(x,y) || !empty_at(x,y):
#			print("fail to add_unit_to_board %d %d %s" %[x, y, co])
			return false
		var tu = new_unit(x,y,co)
		scene.add_child(tu)
		board[x][y]=tu
		add_fullline(y)
		return true

	# 이동이 끝난 것을 보드 관리로 이관
	func set_to_board(tulist):
		if !can_set_to_board(tulist):
			print("fail to set_to_board ",tulist)
			return
		for tu in tulist:
			var x = tu.position.x / Board2ScreenW
			var y = tu.position.y / Board2ScreenH
			board[x][y]=tu
			add_fullline(y)
		tulist.resize(0)
		show_shadow(false)

	func can_set_to_board(tulist)->bool:
		for tu in tulist:
			var x = tu.position.x / Board2ScreenW
			var y = tu.position.y / Board2ScreenH
			if !is_in(x,y) || !empty_at(x,y):
				return false
		return true

	func add_fullline(y)->bool:
		if fulllines.find(y) != -1:
			return true
		var is_full=true
		for x in BoardW:
			if empty_at(x,y):
				is_full= false
				break
		if is_full:
			fulllines.append(y)
		return is_full

	func remove_fulllines():
		if fulllines.size() == 0 :
			return
		fulllines.sort()
		fulllines.reverse()
		for x in BoardW:
			scroll_down_column(x)
		fulllines = []

	func scroll_down_column(x):
		var fillarray = []
		fillarray.resize(fulllines.size())
		for yl in fulllines:
			if board[x][yl] != null:
				scene.remove_child(board[x][yl])
				free_unit.push_back(board[x][yl])
			board[x].remove_at(yl)
		board[x] = fillarray.duplicate() + board[x]
		for yl in range(fulllines.size(),fulllines[0]+1):
			fix_unitpos(x,yl)

	func fix_unitpos(x,y):
		if board[x][y] != null:
			board[x][y].position = Vector2(x*Board2ScreenW, y*Board2ScreenH)

	func is_in(x,y)->bool:
		return x>=0 && x< BoardW && y>=0 && y<BoardH

	func empty_at(x,y)->bool:
		return board[x][y] == null

	func rand_x():
		return randi_range(0,BoardW)

	func rand_y():
		return randi_range(0,BoardH)

	func draw_shadow_by(tulist):
		for i in tulist.size():
			shadow[i].position = tulist[i].position
		while can_set_to_board(shadow):
			for o in shadow:
				o.position.y += Board2ScreenH
		for o in shadow:
			o.position.y -= Board2ScreenH
		show_shadow(true)
	func show_shadow(b :bool):
		for o in shadow:
			o.visible = b

class Tetromino:
	enum {TypeI,TypeT,TypeJ,TypeL,TypeS,TypeZ,TypeO,TypeEnd }
	static func rand_type():
		return randi_range(0,TypeO )
	const TetGeo = {
		# type, geo rotation
		TypeO: [[[0,0],[1,0],[1,1],[0,1]], ],
		TypeI: [[[0,2],[1,2],[2,2],[3,2]], [[2,0],[2,1],[2,2],[2,3]], ],
		TypeS: [[[2,1],[1,1],[1,2],[0,2]], [[1,0],[1,1],[2,1],[2,2]], ],
		TypeZ: [[[0,1],[1,1],[1,2],[2,2]], [[2,0],[2,1],[1,1],[1,2]], ],
		TypeT: [[[0,1],[1,1],[2,1],[1,2]], [[1,0],[1,1],[1,2],[0,1]], [[0,1],[1,1],[2,1],[1,0]],  [[1,0],[1,1],[1,2],[2,1]], ],
		TypeJ: [[[0,1],[1,1],[2,1],[2,2]], [[1,0],[1,1],[1,2],[0,2]], [[0,1],[1,1],[2,1],[0,0]],  [[1,0],[1,1],[1,2],[2,0]], ],
		TypeL: [[[0,1],[1,1],[2,1],[0,2]], [[1,0],[1,1],[1,2],[0,0]], [[0,1],[1,1],[2,1],[2,0]],  [[1,0],[1,1],[1,2],[2,2]], ],
	}
	const TetColor = {
		TypeO: Color8( 255,   0, 255, 255 ),
		TypeI: Color8( 255, 255,   0, 255 ),
		TypeS: Color8(   0, 255, 255, 255 ),
		TypeZ: Color8(   0,   0, 255, 255 ),
		TypeT: Color8( 255,   0,   0, 255 ),
		TypeJ: Color8(   0, 255,   0, 255 ),
		TypeL: Color8( 255, 255, 255, 255 ),
	}
	var scene # scene to draw
	var board : Board # board to check
	var tulist = []
	var x : int # x in board
	var y: int  # y in board
	var t: int  # tet type
	var r: int  # rotate state
	func _init(s,b, xa,ya,ta,ra)->void:
		scene = s
		board = b
		x = xa
		y = ya
		t = ta
		r = ra
		var geo = TetGeo[t]
		var co = TetColor[t]
		for p in geo[r%len(geo)]:
			var tu = board.new_unit(x+p[0],y+p[1], co)
			tulist.append(tu)
			scene.add_child(tu)
		board.draw_shadow_by(tulist)
	func geo_by_rotate(ra):
		var geo = TetGeo[t]
		return geo[ra%len(geo)]

	func tulist2poslist():
		var poslist = []
		for tu in tulist:
			poslist.append(tu.position)
		return poslist

	func poslist2tulist(poslist):
		for i in tulist.size():
			tulist[i].position = poslist[i]

	func is_in_poslist(poslist)->bool:
		for pos in poslist:
			var xl = pos.x / board.Board2ScreenW
			var yl = pos.y / board.Board2ScreenH
			if !board.is_in(xl,yl) || !board.empty_at(xl,yl):
				print("not is_in %s" % pos)
				return false
		return true

	func move_left()->bool:
		var poslist = tulist2poslist()
		for i in poslist.size():
			poslist[i].x -= board.Board2ScreenW
		if is_in_poslist(poslist):
			poslist2tulist(poslist)
			board.draw_shadow_by(tulist)
			return true
		return false

	func move_right()->bool:
		var poslist = tulist2poslist()
		for i in poslist.size():
			poslist[i].x += board.Board2ScreenW
		if is_in_poslist(poslist):
			poslist2tulist(poslist)
			board.draw_shadow_by(tulist)
			return true
		return false

	func move_down()->bool:
		var poslist = tulist2poslist()
		for i in poslist.size():
			poslist[i].y += board.Board2ScreenH
		if is_in_poslist(poslist):
			poslist2tulist(poslist)
			board.draw_shadow_by(tulist)
			return true
		return false

	func rotate()->bool:
		var poslist = tulist2poslist()
		var oldgeo = geo_by_rotate(r)
		var newgeo = geo_by_rotate(r+1)
		for i in poslist.size():
			var oldg = oldgeo[i]
			var newg = newgeo[i]
			poslist[i].x += (newg[0]-oldg[0]) *board.Board2ScreenW
			poslist[i].y += (newg[1]-oldg[1]) *board.Board2ScreenH
		if is_in_poslist(poslist):
			poslist2tulist(poslist)
			r+=1
			board.draw_shadow_by(tulist)
			return true
		return false


var TetBoard = Board.new(self)

var TetMino

func _ready() -> void:
	randomize()
	TetMino = Tetromino.new(self,TetBoard,TetBoard.BoardW/2-1,0,Tetromino.rand_type(),0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
#	removelinetest()
	pass

func removelinetest():
	for i in range(TetBoard.BoardW):
		TetBoard.add_unit_to_board(
			TetBoard.rand_x(),TetBoard.rand_y(),
			Tetromino.TetColor[ Tetromino.rand_type()]
			)
#	var fulllines = TetBoard.scan_fulllines()
	TetBoard.remove_fulllines()

func force_down():
	var act_success = TetMino.move_down()
	if !act_success:
		TetBoard.set_to_board(TetMino.tulist)
		TetMino = Tetromino.new(self,TetBoard,TetBoard.BoardW/2-1,0,Tetromino.rand_type(),0)
		if !TetBoard.can_set_to_board(TetMino.tulist):
			print("game end")
			TetBoard.clear_board()


func act_random():
	var act = randi_range(0,4)
	match act:
		0: # rotate
			TetMino.rotate()
		1: # left
			TetMino.move_left()
		2: # right
			TetMino.move_right()
		3: # down
			pass
#			TetMino.move_down()



func _on_force_down_timer_timeout() -> void:
	force_down()

func _on_act_timer_timeout() -> void:
	act_random()
#	pass
