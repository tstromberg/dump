/* 
	tcpaudit - proof of concept TCP portscanner that retrieves header data.

	Copyright (c) 2012 Thomas Strömberg

	Usage of the works is permitted provided that this instrument is retained 
	with the works, so that any entity that uses the works is notified of this
	instrument.

	DISCLAIMER: THE WORKS ARE WITHOUT WARRANTY.
/*

/*

	Usage:
	------
	tcpaudit -j4 -t64 -p1 -P5535 hostname

	
	Output:
	-------
	127.0.0.1:88 -> 
	127.0.0.1:22 -> SSH-2.0-OpenSSH_5.6|Protocol mismatch.|
	127.0.0.1:80 -> HTTP/1.1 200 OK|Date: Wed, 18 Apr 2012 17:48:32 GMT|Server: Apa
	127.0.0.1:631 -> HTTP/1.0 200 OK|Date: Wed, 18 Apr 2012 17:48:34 GMT|Server: CU
	127.0.0.1:548 -> 
	127.0.0.1:998 -> HTTP/1.0 407 Proxy Authentication Required|Cache-Control: priv

*/
package main

import (
	"bytes"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"net"
	"runtime"
	"strconv"
	"strings"
	"time"
)

var numCores = flag.Int("j", 4, "number of processes to use")
var numThreads = flag.Int("t", 64, "number of threads to use")
var lowerPort = flag.Int("p", 1, "start of port range")
var upperPort = flag.Int("P", 6669, "end of port range")

// var portSpecification = flag.String("p", "1-65535", "ports to scan")

type Task struct {
	job_id   int
	hostname string
	port     int
	open     bool
	data     []byte
}

func interrogate_port(conn net.Conn) (data []byte) {
	//
	// Create two channels: One that is triggered after a 1-second timeout,
	// and one that passes data back from the connection. Whichever returns
	// first wins!
	timeout := make(chan bool, 1)
	go func() {
		time.Sleep(2 * time.Second)
		timeout <- true
	}()

	ch := make(chan []byte, 1)
	go func() {
		fmt.Fprintf(conn, "GET / HTTP/1.0\r\n\r\n")
		snippet, _ := ioutil.ReadAll(io.LimitReader(conn, 96))
		ch <- snippet
	}()
	select {
	case received := <-ch:
		data = received
	case <-timeout:
		// do nothing
	}
	return
}

func scan_worker(input <-chan *Task, output chan<- *Task) {
	for task := range input {
		host_parts := []string{task.hostname, strconv.Itoa(task.port)}
		host_port := strings.Join(host_parts, ":")
		conn, err := net.DialTimeout("tcp", host_port, time.Duration(1*time.Second))
		if err == nil {
			task.open = true
			task.data = interrogate_port(conn)
		}
		output <- task
	}
}

func launch_jobs(hostname string, input chan<- *Task, min_port int, max_port int) {
	launch_count := 0
	for i := min_port; i < max_port; i++ {
		task := Task{launch_count, hostname, i, false, []byte{}}
		input <- &task
		launch_count += 1
	}
}

func display_results(output <-chan *Task, min_port int, max_port int) {
	collected := 0
	for i := min_port; i < max_port; i++ {
		response := <-output
		if response.open {
			piped := bytes.Replace(response.data, []byte("\n"), []byte("|"), -1)
			piped = bytes.Replace(piped, []byte("\r"), []byte(""), -1)
			fmt.Printf("%s:%d -> %s\n", response.hostname, response.port, piped)
		}
		collected += 1
	}
}

func main() {
	flag.Parse()
	hostname := flag.Arg(0)
	runtime.GOMAXPROCS(*numCores)
	input, output := make(chan *Task), make(chan *Task)
	for i := 0; i < *numThreads; i++ {
		go scan_worker(input, output)
	}
	go launch_jobs(hostname, input, *lowerPort, *upperPort)
	// This will block until all results are received.
	display_results(output, *lowerPort, *upperPort)

}
