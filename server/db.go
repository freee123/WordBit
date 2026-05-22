package main

import (
	"database/sql"
	"log"
	"os"

	_ "modernc.org/sqlite"
)

var db *sql.DB

func initDB() {
	path := os.Getenv("DB_PATH")
	if path == "" {
		path = "memory_words.db"
	}

	var err error
	db, err = sql.Open("sqlite", path)
	if err != nil {
		log.Fatalf("打开数据库失败: %v", err)
	}

	db.SetMaxOpenConns(1) // SQLite 单写

	_, _ = db.Exec(`PRAGMA journal_mode=WAL`)
	_, _ = db.Exec(`PRAGMA foreign_keys=ON`)

	createTables()
}

func createTables() {
	queries := []string{
		`CREATE TABLE IF NOT EXISTS users (
			id            TEXT PRIMARY KEY,
			username      TEXT NOT NULL UNIQUE,
			password_hash TEXT NOT NULL,
			created_at    TEXT NOT NULL
		)`,
		`CREATE TABLE IF NOT EXISTS words (
			id             TEXT PRIMARY KEY,
			user_id        TEXT NOT NULL,
			word           TEXT NOT NULL,
			translation    TEXT NOT NULL,
			pronunciation  TEXT,
			part_of_speech TEXT,
			example_sent   TEXT,
			tags           TEXT,
			mastery_level  INTEGER DEFAULT 0,
			created_at     INTEGER NOT NULL,
			updated_at     INTEGER NOT NULL,
			deleted        INTEGER DEFAULT 0
		)`,
		`CREATE INDEX IF NOT EXISTS idx_words_user ON words(user_id)`,
		`CREATE INDEX IF NOT EXISTS idx_words_updated ON words(user_id, updated_at)`,
	}

	for _, q := range queries {
		if _, err := db.Exec(q); err != nil {
			log.Fatalf("建表失败: %v", err)
		}
	}
}
