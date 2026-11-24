package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"runtime"
	"strconv"
	"strings"
)

type OSInfo struct {
	Hostname  string 
	Arch      string 
	OS        string 
	CPU_CORES int    
}

type systemInfo struct {
	OS     OSInfo  
	Memory meminfo 
}

func printosinfo() (OSInfo, error) {
	hostname, error := os.Hostname()

	if error != nil {
		return OSInfo{}, fmt.Errorf("Hostname lookup failed! %w", error)
	}
	info := OSInfo{
		Hostname:  hostname,
		Arch:      runtime.GOARCH,
		OS:        runtime.GOOS,
		CPU_CORES: runtime.NumCPU(),
	}
	return info, nil
}

type meminfo struct {
	TotalKB     uint64 `json:"total_kb"`
	AvailableKB uint64 `json:"available_kb"`
}

func parsememoryInfo(rawinput string) map[string]uint64 {
	stats := make(map[string]uint64)
	rawlines := strings.Split(rawinput, "\n")

	for _, line := range rawlines {
		parts := strings.SplitN(line, ":", 2)
		if len(parts) != 2 {
			continue
		}

		key := strings.TrimSpace(parts[0])
		fields := strings.Fields(parts[1])
		if len(fields) == 0 {
			continue
		}

		value, err := strconv.ParseUint(fields[0], 10, 64)
		if err != nil {
			continue
		}

		stats[key] = value
	}
	return stats
}
func readmemoryfile(target *meminfo) error {
	data, err := os.ReadFile("/proc/meminfo")
	if err != nil {
		return fmt.Errorf("read /proc/meminfo: %w", err)
	}

	stats := parsememoryInfo(string(data))
	if total, ok := stats["MemTotal"]; ok {
		target.TotalKB = total
	}
	if available, ok := stats["MemAvailable"]; ok {
		target.AvailableKB = available
	}
	return nil
}

func printall() error {
	osInfo, err := printosinfo()
	if err != nil {
		return err
	}

	var memory meminfo
	if err := readmemoryfile(&memory); err != nil {
		return err
	}

	fmt.Println("OS Information")
	fmt.Printf("Hostname: %s\nArchitecture: %s\nOS: %s\nCPU cores: %d\n", osInfo.Hostname, osInfo.Arch, osInfo.OS, osInfo.CPU_CORES)
	fmt.Println("Memory Information")
	fmt.Printf("Total memory: %d kB\n", memory.TotalKB)
	fmt.Printf("Available memory: %d kB\n", memory.AvailableKB)
	return nil
}
func saveToJson(filename string) error {
	osInfo, err := printosinfo()
	if err != nil {
		return err
	}
	var memory meminfo
	if err := readmemoryfile(&memory); err != nil {
		return err
	}

	info := systemInfo{OS: osInfo, Memory: memory}
	data, err := json.MarshalIndent(info, "", "  ")
	if err != nil {
		return fmt.Errorf("encode system information as JSON: %w", err)
	}
	if err := os.WriteFile(filename, data, 0644); err != nil {
		return fmt.Errorf("write JSON file %q: %w", filename, err)
	}
	return nil
}
func writeToJson(filename string) error {
	return saveToJson(filename)
}