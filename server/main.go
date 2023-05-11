package main

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/websocket"
	"log"
	"net/http"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

type TreeNode struct {
	Type     string                 `json:"type"`
	UUID     string                 `json:"uuid"`
	Name     string                 `json:"name"`
	Hashsum  string                 `json:"hashsum,omitempty"`
	Children map[string]interface{} `json:"children,omitempty"`
}

func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Error upgrading to WebSocket:", err)
		return
	}
	defer conn.Close()

	for {
		_, msg, err := conn.ReadMessage()
		if err != nil {
			log.Println("Error reading WebSocket message:", err)
			break
		}

		var treeData map[string]TreeNode
		err = json.Unmarshal(msg, &treeData)
		if err != nil {
			log.Println("Error unmarshaling JSON:", err)
			break
		}

		fmt.Println("Received file system tree data:")
		indentedJSON, err := json.MarshalIndent(treeData, "", "  ")
		if err != nil {
			panic(err)
		}
		fmt.Println(string(indentedJSON))
	}
}

func main() {
	http.HandleFunc("/", handleWebSocket)

	log.Println("Starting server on :8080")
	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		log.Fatal("ListenAndServe:", err)
	}
}
