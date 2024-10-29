# XSIAM-Prisma CDR Lab

## Overview

This repository serves as a comprehensive lab environment for practicing Cloud Detection and Response (CDR) using **XSIAM** and **Prisma Cloud**. The labs are designed to simulate real-world cloud-native threats, leveraging **Kubernetes**, container orchestration platforms, and **Palo Alto Networks** technologies. These labs provide a hands-on approach to explore advanced detection techniques and response scenarios against cloud workloads, enabling users to master the application of cloud security tools and methodologies in a controlled environment.

Key scenarios include detection of containerized cryptominers, identifying vulnerable deployments, analyzing behavioral anomalies using ABIOC (Analytics Behavior Indicator of Compromise) techniques, and integrating **WildFire** threat intelligence for enhanced detection capabilities. By utilizing these labs, practitioners will gain practical experience with critical cloud security components that are essential for a robust security posture.

## Repo Organization

The repository is organized into several key areas, each corresponding to a different type of deployment or detection scenario:

- **Cloud Service Deployment**: Deployment manifests for Kubernetes clusters that simulate real-world cloud environments.
- **Cryptominer Containers**: Labs designed to deploy and detect cryptominers, which include various types:
  - **Static/Set Cryptominer**: A predefined cryptominer that is easy to detect with static analysis.
  - **Ran/Image Cryptominer**: Cryptominer that runs from an image pulled dynamically, providing a more challenging detection scenario.
  - **Replica Set Cryptominer**: Using Kubernetes ReplicaSets to deploy cryptominer containers, simulating a persistent threat in a cloud environment.
  - **Known/Unknown to WildFire**: Labs that demonstrate detection of both known cryptominer signatures (already seen by WildFire) and unknown cryptominer variants.
- **DVWA Deployment**: Deployment of **Damn Vulnerable Web Application (DVWA)**, packaged into a Kubernetes deployment that includes service objects and the ability to assign a public IP. Scenarios include:
  - **SQL Injection**: Exploiting SQL vulnerabilities to demonstrate how attackers can access sensitive information and how Prisma Cloud can detect these attempts.
  - **Reverse Webshell**: Establishing a reverse shell from DVWA, showcasing potential impacts of vulnerable web applications and demonstrating detection and response capabilities.
- **Kubernetes Goat - Easy CDR**: Integration of Kubernetes Goat to provide a beginner-friendly environment for practicing cloud detection and response scenarios.

## Cloud Detection and Response Context

The **Cloud Detection and Response (CDR)** approach in these labs is structured around the dynamic nature of cloud-native environments, where scalability, automation, and containerization introduce new security challenges. The labs leverage **XSIAM**, **Prisma Cloud**, and other key Palo Alto Networks tools to monitor cloud environments in real-time, analyze telemetry data, and respond to threats as they emerge.

The labs cover key elements of cloud security:

1. **Threat Visibility and Detection**: Through Prisma Cloud's ability to provide deep visibility into cloud workloads, including containers, serverless functions, and orchestrated environments. This is complemented by XSIAM's capacity to ingest and analyze large volumes of telemetry data.
2. **Automated Response**: The use of **XSIAM** for orchestrated responses allows automated mitigation of threats detected in cloud environments, minimizing response times and reducing the potential for damage.
3. **Behavioral Analytics**: The implementation of ABIOC in these labs showcases how behavioral analytics can be used to detect threats that might bypass signature-based detection. By understanding the typical behavior within Kubernetes clusters, anomalies can be flagged as potential compromises.
4. **Threat Intelligence Enrichment**: WildFire integration is crucial for adding context to detections. By using global threat intelligence feeds, labs show how to correlate local cloud events with global threat indicators to assess the severity and context of an incident.

## Reference Repositories

These repositories and resources are referenced throughout the lab scenarios to provide additional content or supplementary material for deploying realistic threat simulations:

- **Kubernetes GOAT - Multi-Scenario Deployment File**: [Kubernetes Goat GitHub Repository](https://github.com/madhuakula/kubernetes-goat)
- **WildFire Tests - Powered by Precision AI**: [Advanced WildFire Analysis Documentation](https://docs.paloaltonetworks.com/advanced-wildfire/administration/configure-advanced-wildfire-analysis/verify-wildfire-submissions/test-a-sample-malware-file)
- **LinEnum Script**: A script for privilege escalation enumeration. Use the following command to download and execute LinEnum:
  ```sh
  curl -O https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh
  chmod +x LinEnum.sh
  ./LinEnum.sh
  ```

### Samples to Drop and Execute

- **C2 Agent**: [Unix.Backdoor.DeimosC2](https://github.com/timb-machine/linux-malware/blob/main/malware/binaries/Unix.Backdoor.DeimosC2/05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64)
- **Conti Ransomware**: [Conti Sample](https://github.com/timb-machine/linux-malware/blob/main/malware/binaries/Conti/bb64b27bff106d30a7b74b3589cc081c345a2b485a831d7e8c8837af3f238e1e.elf.x86_64)
- **BPFDoor**: [BPFDoor Sample](https://github.com/timb-machine/linux-malware/blob/main/malware/binaries/BPFDoor/07ecb1f2d9ffbd20a46cd36cd06b022db3cc8e45b1ecab62cd11f9ca7a26ab6d.elf.x86_64)

### Kubernetes Goat Installation Steps

1. **Install MicroK8s**: MicroK8s provides a lightweight Kubernetes distribution that is easy to set up for lab use.
   ```sh
   sudo snap install microk8s --classic
   ```
2. **Install Dependencies**:
   - Install **kubectl**:
     ```sh
     sudo snap install kubectl --classic
     ```
   - Install **Docker** for container runtime support.

3. **Clone Kubernetes Goat Repository**:
   ```sh
   git clone https://github.com/madhuakula/kubernetes-goat.git
   ```

4. **Clone Repository and Setup**:
   ```sh
   git clone https://github.com/hankthebldr/xsiam-prisma-cdr-lab.git
   sudo chmod +x Setup/Access/Teardown
   ```

## Lab Scenarios

1. **Cryptominer Detection**
   - Deploy a containerized cryptominer in the Kubernetes environment. Prisma Cloud monitors the workload and generates alerts for anomalous CPU usage and connections to known mining pools. XSIAM then aggregates and correlates these alerts, providing insights into the attack lifecycle.
2. **Vulnerable Application Deployment**
   - Deploy a deliberately vulnerable web application, such as a container with insecure configurations. Prisma Cloud assesses vulnerabilities, while XSIAM's analytics help prioritize the detected issues based on the potential risk and exposure to other critical assets.
3. **Behavioral Anomaly Analysis**
   - Use ABIOC to establish a behavioral baseline within the Kubernetes environment. Introduce anomalies by simulating data exfiltration or unauthorized container privilege escalation. XSIAM will help analyze deviations from established baselines, creating actionable alerts.

## Usage

- **Learning Objectives**:
  - Gain in-depth knowledge of cloud-native threat detection methodologies within Kubernetes environments.
  - Learn to configure and use Prisma Cloud effectively to achieve high visibility and control over cloud workloads.
  - Understand how to leverage XSIAM to correlate telemetry data, automate responses, and derive meaningful security insights.
  - Develop an understanding of integrating threat intelligence feeds for improved context in incident management.

- **Target Audience**:
  - **Cloud Security Engineers**: Individuals focused on maintaining a secure cloud infrastructure.
  - **Security Operations Teams (SecOps)**: Teams interested in gaining hands-on experience with advanced detection and response workflows using Palo Alto Networks technologies.
  - **DevOps and Cloud Practitioners**: Professionals aiming to integrate security into their CI/CD pipelines and improve their ability to detect and respond to threats in containerized environments.
  - **SOC Analysts**: Analysts looking to enhance their incident detection and response capabilities with cloud-native tools and advanced threat analytics.

## Contributing

Contributions are highly encouraged! Whether it's improving an existing scenario or adding a new one, feel free to open issues or submit pull requests. Expanding the diversity of detection scenarios enhances the value of this lab for everyone involved.

## License

This project is licensed under the MIT License. See the `LICENSE` file for more details.

## Resources

- [Palo Alto Networks XSIAM Documentation](https://docs.paloaltonetworks.com/xsiam)
- [Prisma Cloud Documentation](https://docs.paloaltonetworks.com/prisma)
- [WildFire Threat Intelligence](https://www.paloaltonetworks.com/products/threat-intelligence/wildfire)
- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)

---

Feel free to reach out with questions or suggestions for improvement. Together, we can enhance the state of cloud detection and response, making cloud-native environments more secure and resilient to evolving threats.

