package main

import (
	"fmt"
	"os"
	"runtime"
	"strconv"
	"strings"
	//"strings"
	//"runtime"
	//"encoding/json"
)

type OSInfo struct {
	Hostname  string
	Arch      string
	OS        string
	CPU_CORES int
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
	fmt.Println("OS-Information")
	fmt.Println("Hostname: ", info.Hostname)
	fmt.Println("Arch: ", info.Arch)
	fmt.Println("OS: ", info.OS)
	fmt.Println("CPU_CORES: ", info.CPU_CORES)
	return info, nil
}

type meminfo struct {
	TotalKB     uint64
	AvailableKB uint64
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
	if _, err := printosinfo(); err != nil {
		return err
	}

	var memory meminfo
	if err := readmemoryfile(&memory); err != nil {
		return err
	}

	fmt.Println("Memory Information")
	fmt.Printf("Total memory: %d kB\n", memory.TotalKB)
	fmt.Printf("Available memory: %d kB\n", memory.AvailableKB)
	return nil
}
