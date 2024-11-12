# XSIAM-Prisma CDR Lab

## Overview

This repository serves as a comprehensive lab environment for practicing Cloud Detection and Response (CDR) using **XSIAM** and **Prisma Cloud**. The labs are designed to simulate real-world cloud-native threats, leveraging **Kubernetes**, container orchestration platforms, and **Palo Alto Networks** technologies. These labs provide a hands-on approach to explore advanced detection techniques and response scenarios against cloud workloads, enabling users to master the application of cloud security tools and methodologies in a controlled environment.

Key scenarios include detection of containerized cryptominers, identifying vulnerable deployments, analyzing behavioral anomalies using ABIOC (Analytics Behavior Indicator of Compromise) techniques, and integrating **WildFire** threat intelligence for enhanced detection capabilities. By utilizing these labs, practitioners will gain practical experience with critical cloud security components that are essential for a robust security posture.

## Usage
Each Directory is a Specific Detection 
- Directories contain both the kubernetes deployment yaml, these can be added to any cluster
- Diredtories container the scripts, and specific dockerfile specs to build the required images locally should you not want to pull from images refrenced on dockerhub 
- Directores have a Readme file that walks through the step by step process for deploying 


## Lab Scenarios

1. **ATTK-TTP**
   - Malicous Kuberentes deployment executing TTP based processes 
2. **Cryptominer Detection**
   - Cryto-miners embeded within deployment senario
   - xmrig container miner (NGFW)
3. **Vulnerable Application Deployment(AVA)**
   1. Damn Vulnerable Web Application 
4. **Malicous Container** 
   - BIOC/ABICO Detections from a detection container
   - Container > Wildfire Analysis
5. **NFGW stichting Malware analysis**
   - URL/APP - ID 
   - DGA
6. **Behavioral Anomaly Analysis**
   - Local Enumeration on Linux Host 
7. **Kubegoat**
   - Container Escape > Host OS 

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

## Reference Repositories

These repositories and resources are referenced throughout the lab scenarios to provide additional content or supplementary material for deploying realistic threat simulations:

- **Kubernetes GOAT - Multi-Scenario Deployment File**: [Kubernetes Goat GitHub Repository](https://github.com/madhuakula/kubernetes-goat)
- **DVWA***

### Samples to Drop and Execute

- **C2 Agent**: [Unix.Backdoor.DeimosC2](https://github.com/timb-machine/linux-malware/blob/main/malware/binaries/Unix.Backdoor.DeimosC2/05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64)
- **Conti Ransomware**: [Conti Sample](https://github.com/timb-machine/linux-malware/blob/main/malware/binaries/Conti/bb64b27bff106d30a7b74b3589cc081c345a2b485a831d7e8c8837af3f238e1e.elf.x86_64)
- **BPFDoor**: [BPFDoor Sample](https://github.com/timb-machine/linux-malware/blob/main/malware/binaries/BPFDoor/07ecb1f2d9ffbd20a46cd36cd06b022db3cc8e45b1ecab62cd11f9ca7a26ab6d.elf.x86_64)

---

Feel free to reach out with questions or suggestions for improvement. Together, we can enhance the state of cloud detection and response, making cloud-native environments more secure and resilient to evolving threats.

