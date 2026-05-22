package main

type User struct {
	ID           string `json:"id"`
	Username     string `json:"username"`
	PasswordHash string `json:"-"`
	CreatedAt    string `json:"created_at"`
}

type Word struct {
	ID            string `json:"id"`
	UserID        string `json:"user_id"`
	Word          string `json:"word"`
	Translation   string `json:"translation"`
	Pronunciation string `json:"pronunciation,omitempty"`
	PartOfSpeech  string `json:"part_of_speech,omitempty"`
	ExampleSent   string `json:"example_sent,omitempty"`
	Tags          string `json:"tags,omitempty"`
	MasteryLevel  int    `json:"mastery_level"`
	CreatedAt     int64  `json:"created_at"`
	UpdatedAt     int64  `json:"updated_at"`
	Deleted       int    `json:"deleted"`
}

// ---- 请求/响应 ----

type RegisterReq struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type LoginReq struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type LoginResp struct {
	Token string `json:"token"`
}

type SyncReq struct {
	Words []Word `json:"words"`
}

type SyncResp struct {
	Words      []Word `json:"words"`
	ServerTime int64  `json:"server_time"`
}
