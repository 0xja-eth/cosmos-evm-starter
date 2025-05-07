package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"os/exec"
)

type RunRequest struct {
	Args []string `json:"args"`
}

type RunResult struct {
	Stdout     string `json:"stdout"`
	Stderr     string `json:"stderr"`
	ReturnCode int    `json:"returncode"`
	Error      string `json:"error,omitempty"`
}

func runScript(script string, args []string) RunResult {
	cmd := exec.Command(script, args...)
	stdout, err := cmd.Output()
	stderr := ""
	if exitError, ok := err.(*exec.ExitError); ok {
		stderr = string(exitError.Stderr)
	}
	result := RunResult{
		Stdout:     string(stdout),
		Stderr:     stderr,
		ReturnCode: 0,
	}
	if err != nil {
		result.Error = err.Error()
		if exitError, ok := err.(*exec.ExitError); ok {
			result.ReturnCode = exitError.ExitCode()
		} else {
			result.ReturnCode = 1
		}
	}
	return result
}

func handler(script string, withIndex bool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req RunRequest
		if r.Method == http.MethodPost {
			json.NewDecoder(r.Body).Decode(&req)
		}

		indexEnv := os.Getenv("INDEX")
		if withIndex && indexEnv != "" {
			req.Args = append([]string{indexEnv}, req.Args...)
		}

		result := runScript(script, req.Args)

		log.Printf("[SCRIPT] stdout: %s", result.Stdout)
		if result.Stderr != "" {
			log.Printf("[SCRIPT] stderr: %s", result.Stderr)
		}
		if result.Error != "" {
			log.Printf("[SCRIPT] error: %s", result.Error)
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(result)
	}
}

// Handler for GET /run/node
func nodeHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		w.Write([]byte("Method Not Allowed"))
		return
	}
	handler("./scripts/node.sh", false)(w, r)
}

func main() {
	http.HandleFunc("/run/init", handler("./scripts/init.sh", true))
	http.HandleFunc("/run/allocate", handler("./scripts/allocate.sh", false))
	http.HandleFunc("/run/gentx", handler("./scripts/gentx.sh", true))
	http.HandleFunc("/run/collect", handler("./scripts/collect.sh", false))
	http.HandleFunc("/run/node", nodeHandler)
	http.HandleFunc("/run/peers", handler("./scripts/peers.sh", false))
	//http.HandleFunc("/run/start", handler("./scripts/start.sh", false))

	log.Println("Listening on :8080 ...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
