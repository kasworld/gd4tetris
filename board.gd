class_name Board extends Node2D

const HiddenTop = 2
const BoardW = 10
const BoardH = 20+HiddenTop
const ShadowColor = Color.DIM_GRAY
const TuBorderSize = 1.0

var board2screenW  :float # screen board ratio
var board2screenH  :float # screen board ratio
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

func _init(width :float,height :float) -> void:
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
				o.queue_free()
	new_board()

func new_tu(x :int,y :int,co :Color)->Polygon2D:
	var tu =  make_tu()
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
			board[del_fullline_column][yl].queue_free()
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
