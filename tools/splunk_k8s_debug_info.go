package main

import (
	"bytes"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
	"sync"
	"time"
)

const (
	defaultFilter = "splunk|collector|otel|certmanager|test|sck|sock"
)

var tempDir string
var outputFile string

func writeOutput(output, fileName, cmd string) {
	if strings.Contains(output, "No resources found") || strings.Contains(output, "error: the server") || output == "" {
		log.Printf("Skipping %s: %s\n", fileName, output)
		return
	}

	// Redact sensitive information
	redactedOutput := redactSensitiveData(output)

	// Write command and output to file
	f, err := os.Create(fileName)
	if err != nil {
		log.Fatalf("Failed to create file: %s\n", err)
	}
	defer f.Close()

	f.WriteString("# Command: " + cmd + "\n")
	f.WriteString(redactedOutput + "\n")
}

func redactSensitiveData(output string) string {
	var buffer bytes.Buffer
	lines := strings.Split(output, "\n")
	for _, line := range lines {
		switch {
		case strings.Contains(line, "BEGIN CERTIFICATE"):
			buffer.WriteString(line + "\n")
			for _, line := range lines {
				if strings.Contains(line, "END CERTIFICATE") {
					buffer.WriteString(line + "\n")
					break
				} else {
					buffer.WriteString("    [CERTIFICATE REDACTED]\n")
				}
			}
		case strings.Contains(line, "ca.crt"), strings.Contains(line, "client.crt"), strings.Contains(line, "client.key"):
			buffer.WriteString("    [SENSITIVE DATA REDACTED]\n")
		case strings.Contains(line, "TOKEN"):
			buffer.WriteString("    [TOKEN REDACTED]\n")
		case strings.Contains(line, "PASSWORD"):
			buffer.WriteString("    [PASSWORD REDACTED]\n")
		default:
			buffer.WriteString(line + "\n")
		}
	}
	return buffer.String()
}

func collectDataNamespace(ns string, k8sObjectNameFilter string, wg *sync.WaitGroup) {
	defer wg.Done()
	log.Printf("Collecting data for namespace: %s with filter: %s\n", ns, k8sObjectNameFilter)
	objectTypes := []string{"deployments", "daemonsets", "configmaps", "secrets", "networkpolicies", "svc", "ingress", "endpoints", "roles", "rolebindings", "otelinst"}

	for _, objType := range objectTypes {
		cmd := exec.Command("kubectl", "get", objType, "-n", ns, "-o", "jsonpath={range .items[*]}{.metadata.name}{\"\\n\"}{end}")
		output, err := cmd.Output()
		if err != nil {
			log.Printf("Failed to get %s: %s\n", objType, err)
			continue
		}
		objects := strings.Split(string(output), "\n")
		for _, object := range objects {
			if object == "" {
				continue
			}
			if strings.Contains(object, k8sObjectNameFilter) {
				cmd := exec.Command("kubectl", "get", objType, object, "-n", ns, "-o", "yaml")
				output, err := cmd.Output()
				if err != nil {
					log.Printf("Failed to get %s: %s\n", objType, err)
					continue
				}
				writeOutput(string(output), fmt.Sprintf("%s/namespace_%s_%s_%s.yaml", tempDir, ns, objType, object), cmd.String())
			}
		}
	}

	// Collect logs from specific pods
	cmd := exec.Command("kubectl", "get", "pods", "-n", ns, "-o", "jsonpath={range .items[*]}{.metadata.name}{\"\\n\"}{end}")
	output, err := cmd.Output()
	if err != nil {
		log.Printf("Failed to get pods: %s\n", err)
		return
	}
	pods := strings.Split(string(output), "\n")

	// Collect logs from a single agent pod
	for _, pod := range pods {
		if strings.Contains(pod, "agent") {
			cmd := exec.Command("kubectl", "logs", pod, "-n", ns)
			output, err := cmd.Output()
			if err != nil {
				log.Printf("Failed to get logs from %s: %s\n", pod, err)
				continue
			}
			writeOutput(string(output), fmt.Sprintf("%s/namespace_%s_logs_pod_%s.log", tempDir, ns, pod), cmd.String())
			break
		}
	}

	// Collect logs from a single cluster-receiver pod
	for _, pod := range pods {
		if strings.Contains(pod, "cluster-receiver") {
			cmd := exec.Command("kubectl", "logs", pod, "-n", ns)
			output, err := cmd.Output()
			if err != nil {
				log.Printf("Failed to get logs from %s: %s\n", pod, err)
				continue
			}
			writeOutput(string(output), fmt.Sprintf("%s/namespace_%s_logs_pod_%s.log", tempDir, ns, pod), cmd.String())
			break
		}
	}

	// Collect logs from all certmanager pods
	for _, pod := range pods {
		if strings.Contains(pod, "certmanager") {
			cmd := exec.Command("kubectl", "logs", pod, "-n", ns)
			output, err := cmd.Output()
			if err != nil {
				log.Printf("Failed to get logs from %s: %s\n", pod, err)
				continue
			}
			writeOutput(string(output), fmt.Sprintf("%s/namespace_%s_logs_pod_%s.log", tempDir, ns, pod), cmd.String())
		}
	}

	// Collect logs from all operator pods
	for _, pod := range pods {
		if strings.Contains(pod, "operator") {
			cmd := exec.Command("kubectl", "logs", pod, "-n", ns)
			output, err := cmd.Output()
			if err != nil {
				log.Printf("Failed to get logs from %s: %s\n", pod, err)
				continue
			}
			writeOutput(string(output), fmt.Sprintf("%s/namespace_%s_logs_pod_%s.log", tempDir, ns, pod), cmd.String())
		}
	}

	// Collect logs from a single Splunk pod
	splunkCmd := exec.Command("kubectl", "get", "pods", "-n", ns, "-l", "app=splunk", "-o", "jsonpath={.items[0].metadata.name}")
	splunkPod, err := splunkCmd.Output()
	if err != nil {
		log.Printf("Failed to get Splunk pod: %s\n", err)
	} else if len(splunkPod) > 0 {
		log.Printf("Getting logs for pod %s in namespace %s\n", splunkPod, ns)
		cmd := exec.Command("kubectl", "logs", strings.TrimSpace(string(splunkPod)), "-n", ns)
		output, err := cmd.Output()
		if err != nil {
			log.Printf("Failed to get logs from Splunk pod: %s\n", err)
		} else {
			writeOutput(string(output), fmt.Sprintf("%s/namespace_%s_logs_pod_%s.log", tempDir, ns, strings.TrimSpace(string(splunkPod))), cmd.String())
		}
	}

	// Collect pod spec and logs for specific annotations
	annotations := []string{
		"instrumentation.opentelemetry.io/inject-java",
		"instrumentation.opentelemetry.io/inject-python",
		"instrumentation.opentelemetry.io/inject-dotnet",
		"instrumentation.opentelemetry.io/inject-go",
		"instrumentation.opentelemetry.io/inject-nodejs",
		"instrumentation.opentelemetry.io/inject-nginx",
		"instrumentation.opentelemetry.io/inject-sdk",
		"instrumentation.opentelemetry.io/inject-apache-httpd",
	}

	for _, annotation := range annotations {
		cmd := exec.Command("kubectl", "get", "pods", "-n", ns, "-o", fmt.Sprintf("jsonpath={range .items[?(@.metadata.annotations['%s'])]}{.metadata.name}{\"\\n\"}{end}", annotation))
		output, err := cmd.Output()
		if err != nil {
			log.Printf("Failed to get pods with annotation %s: %s\n", annotation, err)
			continue
		}
		podWithAnnotation := strings.TrimSpace(string(output))
		if podWithAnnotation != "" {
			cmd := exec.Command("kubectl", "get", "pod", podWithAnnotation, "-n", ns, "-o", "yaml")
			output, err := cmd.Output()
			if err != nil {
				log.Printf("Failed to get pod spec for %s: %s\n", podWithAnnotation, err)
				continue
			}
			writeOutput(string(output), fmt.Sprintf("%s/namespace_%s_pod_spec_%s.yaml", tempDir, ns, podWithAnnotation), cmd.String())
			cmd = exec.Command("kubectl", "logs", podWithAnnotation, "-n", ns)
			output, err = cmd.Output()
			if err != nil {
				log.Printf("Failed to get logs for %s: %s\n", podWithAnnotation, err)
				continue
			}
			writeOutput(string(output), fmt.Sprintf("%s/namespace_%s_logs_pod_%s.log", tempDir, ns, podWithAnnotation), cmd.String())
		}
	}
}

func collectDataCluster(k8sObjectNameFilter string) {
	log.Println("Collecting cluster-wide data...")

	cmds := []struct {
		cmd      []string
		fileName string
	}{
		{[]string{"kubectl", "config", "view", "--minify", "-o", "jsonpath={.clusters[].name}"}, "cluster_name"},
		{[]string{"kubectl", "version"}, "kubernetes_version"},
		{[]string{"kubectl", "get", "namespaces", "-o", "jsonpath={.items[*].metadata.name}"}, "namespaces"},
		{[]string{"kubectl", "get", "nodes"}, "nodes"},
		{[]string{"kubectl", "get", "pods", "--all-namespaces", "--field-selector=status.phase=Running"}, "running_pods"},
	}

	for _, cmd := range cmds {
		output, err := exec.Command(cmd.cmd[0], cmd.cmd[1:]...).Output()
		if err != nil {
			log.Printf("Failed to execute command %v: %s\n", cmd.cmd, err)
			continue
		}
		writeOutput(string(output), fmt.Sprintf("%s/%s.txt", tempDir, cmd.fileName), strings.Join(cmd.cmd, " "))
	}

	crdsCmd := exec.Command("kubectl", "get", "crds", "-o", "yaml")
	crdsOutput, err := crdsCmd.Output()
	if err != nil {
		log.Printf("Failed to get CRDs: %s\n", err)
	} else {
		writeOutput(string(crdsOutput), fmt.Sprintf("%s/cluster_custom_resource_definitions.yaml", tempDir), crdsCmd.String())
	}

	pspCmd := exec.Command("kubectl", "get", "psp", "-o", "yaml")
	pspOutput, err := pspCmd.Output()
	if err != nil {
		log.Printf("Failed to get PSPs: %s\n", err)
	} else {
		writeOutput(string(pspOutput), fmt.Sprintf("%s/cluster_pod_security_policies.yaml", tempDir), pspCmd.String())
	}

	sccCmd := exec.Command("kubectl", "get", "scc", "-o", "yaml")
	sccOutput, err := sccCmd.Output()
	if err != nil {
		log.Printf("Failed to get SCCs: %s\n", err)
	} else {
		writeOutput(string(sccOutput), fmt.Sprintf("%s/cluster_security_context_constraints.yaml", tempDir), sccCmd.String())
	}

	webhookCmd := exec.Command("kubectl", "get", "mutatingwebhookconfiguration.admissionregistration.k8s.io", "-o", "yaml")
	webhookOutput, err := webhookCmd.Output()
	if err != nil {
		log.Printf("Failed to get MutatingWebhookConfiguration: %s\n", err)
	} else {
		writeOutput(string(webhookOutput), fmt.Sprintf("%s/cluster_webhooks.yaml", tempDir), webhookCmd.String())
	}

	certManagerCmd := exec.Command("kubectl", "get", "pods", "--all-namespaces", "-l", "app=cert-manager", "--no-headers")
	certManagerOutput, err := certManagerCmd.Output()
	if err != nil {
		log.Printf("Failed to get cert-manager pods: %s\n", err)
	} else if len(certManagerOutput) > 0 {
		certCmd := exec.Command("kubectl", "get", "Issuers,ClusterIssuers,Certificates,CertificateRequests,Orders,Challenges", "--all-namespaces", "-o", "yaml")
		certOutput, err := certCmd.Output()
		if err != nil {
			log.Printf("Failed to get cert-manager objects: %s\n", err)
		} else {
			writeOutput(string(certOutput), fmt.Sprintf("%s/cluster_cert_manager_objects.yaml", tempDir), certCmd.String())
		}
	}

	helmCmd := exec.Command("helm", "list", "-A")
	helmOutput, err := helmCmd.Output()
	if err != nil {
		log.Printf("Failed to get Helm releases: %s\n", err)
	} else {
		releases := strings.Split(string(helmOutput), "\n")
		for _, release := range releases {
			if release == "" {
				continue
			}
			if strings.Contains(release, k8sObjectNameFilter) {
				parts := strings.Fields(release)
				releaseName := parts[0]
				releaseNamespace := parts[1]
				cmd := exec.Command("helm", "get", "values", releaseName, "-n", releaseNamespace)
				output, err := cmd.Output()
				if err != nil {
					log.Printf("Failed to get Helm values for %s: %s\n", releaseName, err)
					continue
				}
				writeOutput(string(output), fmt.Sprintf("%s/helm_values_%s_%s.yaml", tempDir, releaseName, releaseNamespace), cmd.String())
			}
		}
	}
}

func main() {
	namespaces := ""
	k8sObjectNameFilter := defaultFilter

	for _, arg := range os.Args[1:] {
		switch {
		case strings.HasPrefix(arg, "NAMESPACES="):
			namespaces = strings.TrimPrefix(arg, "NAMESPACES=")
		case strings.HasPrefix(arg, "K8S_OBJECT_NAME_FILTER="):
			k8sObjectNameFilter = strings.TrimPrefix(arg, "K8S_OBJECT_NAME_FILTER=")
		default:
			log.Fatalf("Unknown parameter: %s\n", arg)
		}
	}

	if namespaces == "" {
		cmd := exec.Command("kubectl", "get", "namespaces", "-o", "jsonpath={.items[*].metadata.name}")
		output, err := cmd.Output()
		if err != nil {
			log.Fatalf("Failed to get namespaces: %s\n", err)
		}
		namespaces = string(output)
	}

	log.Printf("Namespaces: %s\n", namespaces)
	log.Printf("Kubernetes object name filter: %s\n", k8sObjectNameFilter)

	var err error
	tempDir, err = os.MkdirTemp("", "splunk_kubernetes_debug_info_")
	if err != nil {
		log.Fatalf("Failed to create temporary directory: %s\n", err)
	}
	defer os.RemoveAll(tempDir)

	outputFile = tempDir + "/cluster.txt"
	f, err := os.Create(outputFile)
	if err != nil {
		log.Fatalf("Failed to create output file: %s\n", err)
	}
	defer f.Close()

	scriptStartTime := time.Now().Format("2006-01-02 15:04:05")
	f.WriteString("Script start time: " + scriptStartTime + "\n")

	collectDataCluster(k8sObjectNameFilter)

	nsList := strings.Split(namespaces, " ")
	var wg sync.WaitGroup
	for _, ns := range nsList {
		if ns == "" {
			continue
		}
		wg.Add(1)
		go collectDataNamespace(ns, k8sObjectNameFilter, &wg)
	}
	wg.Wait()

	scriptEndTime := time.Now().Format("2006-01-02 15:04:05")
	scriptStartTimestamp, _ := time.Parse("2006-01-02 15:04:05", scriptStartTime)
	scriptEndTimestamp, _ := time.Parse("2006-01-02 15:04:05", scriptEndTime)
	scriptDuration := scriptEndTimestamp.Sub(scriptStartTimestamp)
	scriptDurationHuman := fmt.Sprintf("%02d:%02d:%02d", int(scriptDuration.Hours()), int(scriptDuration.Minutes())%60, int(scriptDuration.Seconds())%60)

	f.WriteString("Script end time: " + scriptEndTime + "\n")
	f.WriteString("Script duration: " + scriptDurationHuman + "\n")

	outputZip := fmt.Sprintf("splunk_kubernetes_debug_info_%s.zip", time.Now().Format("20060102_150405"))
	log.Printf("Creating ZIP archive: %s\n", outputZip)

	cmd := exec.Command("zip", "-j", "-r", outputZip, tempDir)
	if err := cmd.Run(); err != nil {
		log.Fatalf("Failed to create ZIP archive: %s\n", err)
	}

	log.Printf("Data collection complete. Output files are available in the ZIP archive: %s\n", outputZip)
}
