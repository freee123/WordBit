package main

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

func handleRegister(w http.ResponseWriter, r *http.Request) {
	var req RegisterReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "请求格式错误"})
		return
	}

	if req.Username == "" || len(req.Username) < 2 {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "用户名至少2个字符"})
		return
	}
	if len(req.Password) < 4 {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "密码至少4个字符"})
		return
	}

	// 检查是否已存在
	var count int
	db.QueryRow("SELECT COUNT(*) FROM users WHERE username = ?", req.Username).Scan(&count)
	if count > 0 {
		writeJSON(w, http.StatusConflict, map[string]string{"error": "用户名已存在"})
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "密码加密失败"})
		return
	}

	id := uuid.New().String()
	now := time.Now().UTC().Format(time.RFC3339)

	_, err = db.Exec(
		"INSERT INTO users (id, username, password_hash, created_at) VALUES (?, ?, ?, ?)",
		id, req.Username, string(hash), now,
	)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "注册失败"})
		return
	}

	token := genToken(id)
	writeJSON(w, http.StatusCreated, LoginResp{Token: token})
}

func handleLogin(w http.ResponseWriter, r *http.Request) {
	var req LoginReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "请求格式错误"})
		return
	}

	var user User
	err := db.QueryRow(
		"SELECT id, username, password_hash, created_at FROM users WHERE username = ?",
		req.Username,
	).Scan(&user.ID, &user.Username, &user.PasswordHash, &user.CreatedAt)

	if err != nil {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "用户名或密码错误"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "用户名或密码错误"})
		return
	}

	token := genToken(user.ID)
	writeJSON(w, http.StatusOK, LoginResp{Token: token})
}

func genToken(userID string) string {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub": userID,
		"iat": time.Now().Unix(),
		"exp": time.Now().Add(30 * 24 * time.Hour).Unix(), // 30 天过期
	})
	s, _ := token.SignedString(jwtSecret)
	return s
}
