package main

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
)

func handleGetWords(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value(userIDKey).(string)
	since := r.URL.Query().Get("since")

	rows, err := db.Query(
		"SELECT id, user_id, word, translation, pronunciation, part_of_speech, example_sent, tags, mastery_level, created_at, updated_at, deleted FROM words WHERE user_id = ? AND updated_at > ? ORDER BY updated_at",
		userID, since,
	)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "查询失败"})
		return
	}
	defer rows.Close()

	words := []Word{}
	for rows.Next() {
		var w Word
		rows.Scan(&w.ID, &w.UserID, &w.Word, &w.Translation, &w.Pronunciation,
			&w.PartOfSpeech, &w.ExampleSent, &w.Tags, &w.MasteryLevel,
			&w.CreatedAt, &w.UpdatedAt, &w.Deleted)
		words = append(words, w)
	}

	writeJSON(w, http.StatusOK, SyncResp{Words: words, ServerTime: time.Now().UnixMilli()})
}

func handlePostWords(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value(userIDKey).(string)
	serverTime := time.Now().UnixMilli()

	var words []Word
	if err := json.NewDecoder(r.Body).Decode(&words); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "请求格式错误"})
		return
	}

	for _, w := range words {
		w.UserID = userID
		if w.ID == "" {
			w.ID = uuid.New().String()
		}

		// 服务端统一盖时间戳
		w.UpdatedAt = serverTime
		if w.CreatedAt == 0 {
			w.CreatedAt = serverTime
		}

		db.Exec(`INSERT OR REPLACE INTO words
			(id, user_id, word, translation, pronunciation, part_of_speech, example_sent, tags, mastery_level, created_at, updated_at, deleted)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
			w.ID, w.UserID, w.Word, w.Translation, w.Pronunciation,
			w.PartOfSpeech, w.ExampleSent, w.Tags, w.MasteryLevel,
			w.CreatedAt, w.UpdatedAt, w.Deleted,
		)
	}

	writeJSON(w, http.StatusOK, SyncResp{ServerTime: serverTime})
}

func handlePutWord(rw http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value(userIDKey).(string)
	wordID := strings.TrimPrefix(r.URL.Path, "/api/words/")

	// 检查是否存在
	var exist int
	db.QueryRow("SELECT COUNT(*) FROM words WHERE id=? AND user_id=?", wordID, userID).Scan(&exist)
	if exist == 0 {
		writeJSON(rw, http.StatusNotFound, map[string]string{"error": "单词不存在"})
		return
	}

	var w Word
	if err := json.NewDecoder(r.Body).Decode(&w); err != nil {
		writeJSON(rw, http.StatusBadRequest, map[string]string{"error": "请求格式错误"})
		return
	}
	w.ID = wordID
	w.UserID = userID

	_, err := db.Exec(`UPDATE words SET word=?, translation=?, pronunciation=?, part_of_speech=?, example_sent=?, tags=?, mastery_level=?, updated_at=?, deleted=? WHERE id=? AND user_id=?`,
		w.Word, w.Translation, w.Pronunciation, w.PartOfSpeech,
		w.ExampleSent, w.Tags, w.MasteryLevel, w.UpdatedAt, w.Deleted,
		w.ID, userID,
	)
	if err != nil {
		writeJSON(rw, http.StatusInternalServerError, map[string]string{"error": "更新失败"})
		return
	}

	writeJSON(rw, http.StatusOK, map[string]string{"ok": "true"})
}

func handleDeleteWord(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value(userIDKey).(string)
	wordID := strings.TrimPrefix(r.URL.Path, "/api/words/")

	var exist int
	db.QueryRow("SELECT COUNT(*) FROM words WHERE id=? AND user_id=?", wordID, userID).Scan(&exist)
	if exist == 0 {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "单词不存在"})
		return
	}

	_, err := db.Exec("UPDATE words SET deleted=1 WHERE id=? AND user_id=?", wordID, userID)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "删除失败"})
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"ok": "true"})
}
