extends Node2D

func _ready() -> void:
	randomize()
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
	get_node("BGSprite2D").texture = bgTexture

	get_node("Score").size.x = remainWidth
	get_node("Score").position.x = boardWidth
	get_node("Score").position.y = tet_board.board2screenH *4

	tet_mino_next = Tetromino.new(tet_board)
	tet_mino_next.make_tmino(tet_board.BoardW+1,2,Tetromino.rand_type(),0)
	tet_mino_move = Tetromino.new(tet_board)

	reset_game()
	proceed_next()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if tet_board.start_remove_fulllines() :
		if tet_board.scroll_down_column(): # end del full line
			force_down_frame -= 1
			if force_down_frame < 1:
				force_down_frame = 1
	else:
#		removelinetest()
		handle_input()
		force_down()

	var scoreStr = "Score:%d\nLine:%d\n" % [tet_board.score, tet_board.line_score]
	for i in tmino_type_stat.size():
		scoreStr += "%s:%d\n" % [Tetromino.TetName[i],tmino_type_stat[i]]
	get_node("Score").text = scoreStr

var tet_board :Board
var tet_mino_move :Tetromino
var tet_mino_next :Tetromino
var force_down_frame :int
var since_last_force_down_frame :int
var tmino_type_stat = []

func proceed_next():
	tet_mino_move.copy_tmino_from_next(tet_board.BoardW/2-1,0,tet_mino_next)
	tmino_type_stat[tet_mino_move.t] +=1
	tet_mino_next.change_type(Tetromino.rand_type())

func reset_game():
	force_down_frame = 60
	since_last_force_down_frame = 0
	tmino_type_stat = []
	tmino_type_stat.resize(tet_mino_move.TypeSize)
	for i in tet_mino_move.TypeSize:
		tmino_type_stat[i] = 0

func game_over():
	get_node("GameOver").visible = true
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
		get_node("GameOver").visible = false
		var act_success = tet_mino_move.move_down()
		if !act_success:
			tet_board.set_to_board(tet_mino_move.tulist)
			proceed_next()
			if !tet_board.can_set_to_board(tet_mino_move.tulist):
				game_over()

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

