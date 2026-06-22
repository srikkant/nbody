package game

MSG_TITLE :: "THE N:BODY FORGE"

MSG_NEW_GAME :: "new game"
MSG_EXIT :: "exit"
MSG_RESUME :: "resume"
MSG_RESTART :: "restart"
MSG_MAIN_MENU :: "main menu"

MSG_PAUSED :: "PAUSED"

MSG_TUTORIAL_START :: "DRAG AND RELEASE TO LAUNCH YOUR FIRST ASTEROID"

Messages :: enum {
	Title,
	NewGame,
	Exit,
	Resume,
	Restart,
	MainMenu,
	Paused,
	Tutorial_Start,
}

Messages_Language :: enum {
	En,
}

Messages_EN: [Messages_Language][Messages]string = {
	.En = {
		.Title = MSG_TITLE,
		.NewGame = MSG_NEW_GAME,
		.Exit = MSG_EXIT,
		.Resume = MSG_RESUME,
		.Restart = MSG_RESTART,
		.MainMenu = MSG_MAIN_MENU,
		.Paused = MSG_PAUSED,
		.Tutorial_Start = MSG_TUTORIAL_START,
	},
}


// Simple message system to allow for easy localization in the future.
// For now, it just supports English,
t :: proc(g: ^Game, msg: Messages) -> cstring {
	lang := Messages_Language.En
	return cstring(raw_data(Messages_EN[lang][msg]))
}

