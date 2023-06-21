extends Node2D


class Board extends Node2D:
	const HiddenTop = 2
	const BoardW = 10
	const BoardH = 20+HiddenTop
	const ShadowColor = Color.DIM_GRAY
	const TuBorderSize = 4

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
	func make_del_effect()->Polygon2D:
		var de = Polygon2D.new()
		de.set_polygon( PackedVector2Array([
			Vector2(0,0),
			Vector2(0,board2screenH),
			Vector2(BoardW*board2screenW,board2screenH),
			Vector2(BoardW*board2screenW,0),]
		))
		return de

	var board = []		# array [BoardW][BoardH] of TetUnit
	var free_tulist = []	# reuse tetunit list
	var fulllines = []
	var is_del_fulllines :bool
	var del_fullline_column :int
	var del_effect = []
	var shadow = []
	var score :int
	var line_score :int

	func new_shadow()->void:
		for i in 4:
			var o = new_tu(0,0,ShadowColor )
			shadow.append(o)
			add_child(o)
		show_shadow(false)

	func _init(width :int,height :int) -> void:
		board2screenW = width / BoardW
		board2screenH = height / BoardH
		for y in BoardH:
			var de = make_del_effect()
			de.position.y=y*board2screenH
			de.visible = false
			del_effect.append(de)
			add_child(de)
		new_shadow()
		new_board()

	func new_board()->void:
		score = 0
		line_score = 0
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

	func can_set_to_board(tulist :Array)->bool:
		for tu in tulist:
			var x = tu.position.x / board2screenW
			var y = tu.position.y / board2screenH
			if !is_in(x,y) || !empty_at(x,y):
				return false
		return true

	# 이동이 끝난 것을 보드 관리로 이관
	func set_to_board(tulist :Array)->void:
		assert(!is_del_fulllines)
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

	func add_fullline(y :int)->bool:
		assert(!is_del_fulllines)
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

	func start_remove_fulllines()->bool:
		if is_del_fulllines:
			return true
		if fulllines.size() == 0 :
			return false
		var sc = 0
		for y in fulllines:
			sc += (BoardH- y) *4
			del_effect[y].visible = true
		score += sc* fulllines.size()
		line_score += fulllines.size()

		fulllines.sort()
		fulllines.reverse()
		is_del_fulllines = true
		del_fullline_column = 0
		return true

	func end_remove_fullines()->void:
		is_del_fulllines = false
		del_fullline_column = 0
		for y in fulllines:
			del_effect[y].visible = false
		fulllines = []

	# return true when end
	func scroll_down_column()->bool:
		assert(is_del_fulllines)
		var fillarray = []
		fillarray.resize(fulllines.size())
		for yl in fulllines:
			if board[del_fullline_column][yl] != null:
				remove_child(board[del_fullline_column][yl])
				free_tulist.push_back(board[del_fullline_column][yl])
			board[del_fullline_column].remove_at(yl)
		board[del_fullline_column] = fillarray.duplicate() + board[del_fullline_column]
		for yl in range(fulllines.size(),fulllines[0]+1):
			fix_tupos(del_fullline_column,yl)
		del_fullline_column +=1
		if del_fullline_column == BoardW:
			end_remove_fullines()
			return true
		return false

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
		assert(!is_del_fulllines)
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

class Game extends Node2D:
	var tet_board :Board
	var tet_mino_move :Tetromino
	var tet_mino_next :Tetromino
	var force_down_frame :int
	var since_last_force_down_frame :int

	func _init()->void:
		randomize()

	func newgame()->void:
		var width = ProjectSettings.get_setting("display/window/size/viewport_width")
		var height =  ProjectSettings.get_setting("display/window/size/viewport_height")
		var shift = Board.HiddenTop*(height / (Board.BoardH-Board.HiddenTop))
		var boardWidth = width/3*2
		var remainWidth = width - boardWidth
		tet_board = Board.new(boardWidth,height + shift )
		add_child(tet_board)
		tet_board.position.y = -shift

		var bgImage = Image.create(boardWidth,height,true,Image.FORMAT_RGBA8)
		bgImage.fill(Color.BLACK)
		var bgTexture = ImageTexture.create_from_image(bgImage)
		get_parent().get_node("BGSprite2D").texture = bgTexture

		get_parent().get_node("Score").size.x = remainWidth
		get_parent().get_node("Score").position.x = boardWidth  #boardWidth + tet_board.board2screenW *2
		get_parent().get_node("Score").position.y = tet_board.board2screenH *0

		tet_mino_next = Tetromino.new(tet_board)
		tet_mino_next.make_tmino(tet_board.BoardW+1,8,Tetromino.rand_type(),0)
		tet_mino_move = Tetromino.new(tet_board)

		reset_game()
		proceed_next()

	func proceed_next():
		tet_mino_move.copy_tmino_from_next(tet_board.BoardW/2-1,0,tet_mino_next)
		tet_mino_next.change_type(Tetromino.rand_type())

	func reset_game():
		force_down_frame = 60
		since_last_force_down_frame = 0

	func game_over():
		get_parent().get_node("GameOver").visible = true
		tet_board.clear_board()
		reset_game()

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
		since_last_force_down_frame +=1
		if since_last_force_down_frame > force_down_frame:
			since_last_force_down_frame = 0
			get_parent().get_node("GameOver").visible = false
			var act_success = tet_mino_move.move_down()
			if !act_success:
				tet_board.set_to_board(tet_mino_move.tulist)
				proceed_next()
				if !tet_board.can_set_to_board(tet_mino_move.tulist):
					game_over()

	func process(delta: float) -> void:
		if tet_board.start_remove_fulllines() :
			if tet_board.scroll_down_column(): # end del full line
				force_down_frame -= 1
				if force_down_frame < 1:
					force_down_frame = 1
		else:
	#		removelinetest()
			handle_input()
			force_down()

		get_parent().get_node("Score").text = "Score:%d\nLine:%d" % [tet_board.score, tet_board.line_score]

	func removelinetest()->void:
		for i in range(tet_board.BoardW):
			tet_board.add_tu_to_board(
				tet_board.rand_x(),tet_board.rand_y(),
				Tetromino.TetColor[ Tetromino.rand_type()]
				)

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

var game :Game
func _ready() -> void:
	game = Game.new()
	add_child(game)
	game.newgame()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	game.process(delta)
