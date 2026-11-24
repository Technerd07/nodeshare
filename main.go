package main

import "fmt"

func main() {
	info, err := collectSystemInfo()
	if err != nil {
		fmt.Println("Error collecting system information:", err)
		return
	}
	printall(info)
	if err := writeToJson("node-info.json", info); err != nil {
		fmt.Println("Error saving JSON:", err)
		return
	}
	fmt.Println("System information saved to node-info.json")
}
