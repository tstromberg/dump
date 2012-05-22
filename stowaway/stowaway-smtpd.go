package main

import (
	"bufio"
	"fmt"
	"log"
	"net"
	"os"
)

func handleConnection(conn net.Conn) {
	log.Printf("Connection request: %s", conn)
	defer conn.Close()
	rconn := bufio.NewReader(conn)
	wconn := bufio.NewWriter(conn)

	hostname, err := os.Hostname()
	fmt.Fprintf(wconn, "220 %s ESMTP stowaway\n", hostname)
	wconn.Flush()

	for {
		response := []byte("")
		response, _, err = rconn.ReadLine()
		if err != nil {
			log.Printf("ReadLine error: %s", err)
		} else {
			log.Printf("Request: %s", response)
			print("%s", response)
			fmt.Fprintf(wconn, "250 Fantastic!\n")
			wconn.Flush()
		}
	}

}

func commandHelo(conn net.Conn) {
}


func listenForConnections() {
	ln, err := net.Listen("tcp", ":2500")
	if err != nil {
		log.Printf("Problem listening: %s", err)
	} else {
		log.Printf("Listening on port 2500")
	}
	for {
		conn, err := ln.Accept()
		if err != nil {
			log.Printf("Problem accepting: %s", err)
		}
		go handleConnection(conn)
	}
}

func main() {
	listenForConnections()
}
