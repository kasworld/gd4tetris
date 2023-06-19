extends Node2D


class Board extends Node2D:
	const HiddenTop = 2
	const BoardW = 10
	const BoardH = 20+HiddenTop
	const ShadowColor = Color.DIM_GRAY
	const TuBorderSize = 4

	var line_del_effect = preload("res://line_del_effect.tscn")
	var lineeffect = []

	var board2screenW  :int # screen board ratio
	var board2screenH  :int # screen board ratio
	func make_tu()->Polygon2D:
		var tu = Polygon2D.new()
		tu.set_polygon( PackedVector2Array([
			Vector2(TuBorderSize,TuBorderSize),
			Vector2(TuBorderSize,board2screenH),
			Vector2(board2screenW,board2screenH),
			Vector2(board2screenW,TuBorderSize),]
		))
		return tu

	var board = []		# array [BoardW][BoardH] of TetUnit
	var free_tulist = []	# reuse tetunit list
	var fulllines = []
	var shadow = []
	var score :int
	func new_shadow()->void:
		for i in 4:
			var o = new_tu(0,0,ShadowColor )
			shadow.append(o)
			add_child(o)
		show_shadow(false)

	func _init(width :int,height :int) -> void:
		board2screenW = width / BoardW
		board2screenH = height / BoardH
		for i in BoardH:
			var lde = line_del_effect.instantiate()
			add_child(lde)
			lde.position.y = i * board2screenH+board2screenH/2
			lineeffect.append(lde)
		new_shadow()
		new_board()

	func new_board()->void:
		score = 0
		board.resize(BoardW)
		for i in range(BoardW):
			board[i] = []
			board[i].resize(BoardH)
		show_shadow(false)

	func clear_board()->void:
		for row in board:
			for o in row:
				if o != null:
					remove_child(o)
					free_tulist.push_back(o)
		new_board()

	func new_tu(x :int,y :int,co :Color)->Polygon2D:
		var tu
		if len(free_tulist) == 0 :
			tu =  make_tu()
		else:
			tu = free_tulist.pop_back()
		tu.position.x = x * board2screenW
		tu.position.y = y * board2screenH
		tu.set_color(co )
		return tu

	# 장애물 미리 설정할때 사용.
	func add_tu_to_board(x :int,y :int,co :Color)->bool:
		if !is_in(x,y) || !empty_at(x,y):
#			print("fail to add_tu_to_board %d %d %s" %[x, y, co])
			return false
		var tu = new_tu(x,y,co)
		add_child(tu)
		board[x][y]=tu
		add_fullline(y)
		return true


	# 이동이 끝난 것을 보드 관리로 이관
	func set_to_board(tulist :Array)->void:
		if !can_set_to_board(tulist):
			print("fail to set_to_board ",tulist)
			return
		for tu in tulist:
			var x = tu.position.x / board2screenW
			var y = tu.position.y / board2screenH
			board[x][y]=tu
			add_fullline(y)
		tulist.resize(0)
		show_shadow(false)
		score += 4
		remove_fulllines()

	func can_set_to_board(tulist :Array)->bool:
		for tu in tulist:
			var x = tu.position.x / board2screenW
			var y = tu.position.y / board2screenH
			if !is_in(x,y) || !empty_at(x,y):
				return false
		return true

	func add_fullline(y :int)->bool:
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

	func remove_fulllines()->void:
		if fulllines.size() == 0 :
			return
		var sc = 0
		for i in fulllines:
			sc += (BoardH- i) *4
		score += sc* fulllines.size()

		fulllines.sort()
		fulllines.reverse()

		for y in fulllines:
			linedel_effect(y)

		for x in BoardW:
			scroll_down_column(x)
		fulllines = []

	func linedel_effect(y :int)->void:
		lineeffect[y].emitting = true
		pass

	func scroll_down_column(x :int)->void:
		var fillarray = []
		fillarray.resize(fulllines.size())
		for yl in fulllines:
			if board[x][yl] != null:
				remove_child(board[x][yl])
				free_tulist.push_back(board[x][yl])
			board[x].remove_at(yl)
		board[x] = fillarray.duplicate() + board[x]
		for yl in range(fulllines.size(),fulllines[0]+1):
			fix_tupos(x,yl)

	func fix_tupos(x :int,y :int)->void:
		if board[x][y] != null:
			board[x][y].position = Vector2(x*board2screenW, y*board2screenH)

	func is_in(x :int,y :int)->bool:
		return x>=0 && x< BoardW && y>=0 && y<BoardH

	func empty_at(x :int,y :int)->bool:
		return board[x][y] == null

	func rand_x()->int:
		return randi_range(0,BoardW)

	func rand_y()->int:
		return randi_range(0,BoardH)

	func draw_shadow_by(tulist :Array)->void:
		for i in tulist.size():
			shadow[i].position = tulist[i].position
		down_to_can(shadow)
		show_shadow(true)

	func show_shadow(b :bool)->void:
		for o in shadow:
			o.visible = b

	func down_to_can(tulist :Array)->void: # also harddrop
		while can_set_to_board(tulist):
			for o in tulist:
				o.position.y += board2screenH
		for o in tulist:
			o.position.y -= board2screenH

class Tetromino extends Node2D:
	enum {TypeI,TypeT,TypeJ,TypeL,TypeS,TypeZ,TypeO,TypeEnd }
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
	var scene : Node2D
	var board : Board # board to check
	var tulist = []
	var x : int # x in board
	var y: int  # y in board
	var t: int  # tet type
	var r: int  # rotate state
	func _init(s :Node2D, b :Board)->void:
		scene = s
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

var tet_board :Board
var tet_mino_move :Tetromino
var tet_mino_next :Tetromino

func copy_tmino_move_from_next()->void:
	tet_mino_move.copy_tmino_from_next(tet_board.BoardW/2-1,0,tet_mino_next)

func _ready() -> void:
	randomize()
	var width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var height =  ProjectSettings.get_setting("display/window/size/viewport_height")
	var shift = Board.HiddenTop*(height / (Board.BoardH-Board.HiddenTop))
	var boardWidth = width/3*2
	tet_board = Board.new(boardWidth,height + shift )
	add_child(tet_board)
	tet_board.position.y = -shift

	var bgImage = Image.create(boardWidth,height,true,Image.FORMAT_RGBA8)
	bgImage.fill(Color.BLACK)
	var bgTexture = ImageTexture.create_from_image(bgImage)
	$BGSprite2D.texture = bgTexture

	$Score.position.x = boardWidth + tet_board.board2screenW *2
	$Score.position.y = tet_board.board2screenH *0

	start_game()

func start_game():
	tet_mino_next = Tetromino.new(self, tet_board)
	tet_mino_next.make_tmino(tet_board.BoardW+1,4,Tetromino.rand_type(),0)
	tet_mino_move = Tetromino.new(self, tet_board)
	copy_tmino_move_from_next()
	tet_mino_next.change_type(Tetromino.rand_type())

func game_over():
	$GameOver.visible = true
	tet_board.clear_board()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
#	removelinetest()
	handle_input()
	$Score.text = "%d" % tet_board.score
	pass

func handle_input()->void:
	if Input.is_action_just_pressed("move_right"):
		tet_mino_move.move_right()
	if Input.is_action_just_pressed("move_left"):
		tet_mino_move.move_left()
	if Input.is_action_pressed("move_down"):
		tet_mino_move.move_down()
	if Input.is_action_just_pressed("rotate"):
		tet_mino_move.tmino_rotate()
	if Input.is_action_just_pressed("hard_drop"):
		tet_board.down_to_can(tet_mino_move.tulist)


func force_down()->void:
	$GameOver.visible = false
	var act_success = tet_mino_move.move_down()
	if !act_success:
		tet_board.set_to_board(tet_mino_move.tulist)
		copy_tmino_move_from_next()
		tet_mino_next.change_type(Tetromino.rand_type())
		if !tet_board.can_set_to_board(tet_mino_move.tulist):
			game_over()

func _on_force_down_timer_timeout() -> void:
	force_down()
	pass

############# test functions

func removelinetest()->void:
	for i in range(tet_board.BoardW):
		tet_board.add_tu_to_board(
			tet_board.rand_x(),tet_board.rand_y(),
			Tetromino.TetColor[ Tetromino.rand_type()]
			)
	tet_board.remove_fulllines()

func act_random()->void:
	var act = randi_range(0,4)
	match act:
		0: # rotate
			tet_mino_move.tmino_rotate()
		1: # left
			tet_mino_move.move_left()
		2: # right
			tet_mino_move.move_right()
		3: # down
			tet_mino_move.move_down()
