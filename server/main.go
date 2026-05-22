package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
)

func main() {
	jwtSecret = []byte(os.Getenv("JWT_SECRET"))
	if len(jwtSecret) == 0 {
		jwtSecret = []byte("memory-words-secret-change-me")
	}

	initDB()
	defer db.Close()

	mux := http.NewServeMux()

	// 认证
	mux.HandleFunc("POST /api/auth/register", handleRegister)
	mux.HandleFunc("POST /api/auth/login", handleLogin)

	// 单词同步（需认证）
	mux.HandleFunc("GET /api/words", authMiddleware(handleGetWords))
	mux.HandleFunc("POST /api/words", authMiddleware(handlePostWords))
	mux.HandleFunc("PUT /api/words/{id}", authMiddleware(handlePutWord))
	mux.HandleFunc("DELETE /api/words/{id}", authMiddleware(handleDeleteWord))

	// 健康检查
	mux.HandleFunc("GET /api/health", func(w http.ResponseWriter, _ *http.Request) {
		writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
	})

	addr := os.Getenv("ADDR")
	if addr == "" {
		addr = ":8080"
	}

	log.Printf("服务启动: http://localhost%s\n", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatalf("启动失败: %v", err)
	}
}

func writeJSON(w http.ResponseWriter, code int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(data)
}
