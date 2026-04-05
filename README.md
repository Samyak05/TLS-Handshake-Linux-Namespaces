# 🔐 TLS & Mutual TLS (mTLS) Analysis over Layer-3 Routing using Linux Network Namespaces

![Linux](https://img.shields.io/badge/Platform-Linux-blue)
![Networking](https://img.shields.io/badge/Domain-Computer%20Networks-green)
![TLS](https://img.shields.io/badge/Protocol-TLS%20%7C%20mTLS-red)

---

## 🚀 Motivation

This project was built to deeply understand how TCP and TLS operate over a routed Layer-3 network.

Instead of using physical hardware, Linux network namespaces were used to simulate:

- Isolated network nodes (client, router, server)
- Two different IP subnets
- IP forwarding across a software router
- Real packet-level protocol behavior

The objective was to analyze:

- TCP 3-way handshake
- TLS 1.2 handshake workflow
- Certificate exchange in plaintext
- Encryption boundary after `ChangeCipherSpec`
- TTL decrement across a router (Layer-3 proof)

This project was later extended to include **Mutual TLS (mTLS)** to demonstrate
two-way authentication, where both client and server verify each other's identity
using certificates.

This project provides a hands-on, packet-level understanding of secure communication
mechanisms used in modern distributed systems and zero-trust architectures.

---

## 🗺 Network Topology

![Topology](diagrams/topology.png)

### Addressing Scheme

| Namespace | Interface IP | Subnet |
|------------|--------------|--------|
| red (Client) | 10.0.1.2 | 10.0.1.0/24 |
| router | 10.0.1.1 / 10.0.2.1 | Two connected subnets |
| blue (Server) | 10.0.2.2 | 10.0.2.0/24 |

- Default gateway (red): `10.0.1.1`
- Default gateway (blue): `10.0.2.1`
- IP forwarding enabled in router namespace

---

## 🧰 Requirements

- Ubuntu 22.04 (or compatible Linux system)
- iproute2
- OpenSSL
- tcpdump
- Wireshark (host machine)

---

## ⚙️ Setup Instructions

### 🔐 Generate Certificates

```bash
./generate_certs.sh
```

### 🌐 Create Namespaces and Routing

```bash
sudo ./setup.sh
```

### 🔎 Verify Connectivity

```bash
sudo ip netns exec red ping 10.0.2.2
```

Expected observation:

- Successful ping replies  
- TTL decreases from 64 → 63 (proof of router traversal)

### 🧹 Cleanup

```bash
sudo ./cleanup.sh
```

---

## 🔐 TLS Handshake Execution & Packet Capture (TLS 1.2)

This section demonstrates capturing and analyzing the TLS handshake at packet level in a clean, linear workflow.

### 🛠 Step 1 — Start Packet Capture (Router)

```bash
sudo ip netns exec router tcpdump -i any -w tls_capture.pcap
```

Keep this running.

---

### 🔐 Step 2 — Start TLS Server (blue namespace)

(Open a new terminal)

```bash
sudo ip netns exec blue openssl s_server \
  -accept 4433 \
  -cert /certs/server.crt \
  -key /certs/server.key \
  -tls1_2
```

Expected output:

```
ACCEPT
```

---

### 🔗 Step 3 — Start TLS Client (red namespace)

(Open another terminal)

```bash
sudo ip netns exec red openssl s_client \
  -connect 10.0.2.2:4433 \
  -tls1_2
```

This initiates the TLS handshake.

---

### 🛑 Step 4 — Stop Packet Capture

Press:

```bash
Ctrl + C
```

in the tcpdump terminal.

---

### 👀 Step 5 — Analyze in Wireshark

Open the generated `.pcap` file in Wireshark.

---

### 🔍 Recommended Filters

```
tls
tcp.port == 4433
```

---

### 🔎 Key Observations (TLS)

- TCP 3-way handshake occurs before TLS begins  
- TLS handshake messages visible:
  - ClientHello  
  - ServerHello  
  - Certificate  
  - ServerHelloDone  
  - ClientKeyExchange  
- Encryption starts after `ChangeCipherSpec`  
- Subsequent packets appear as:
  ```
  TLS Application Data
  ```

---

## 🔐 Mutual TLS (mTLS) Execution & Packet Capture

This section demonstrates mutual authentication where both client and server verify each other using certificates.

### 🛠 Step 1 — Start Packet Capture (Router)

```bash
sudo ip netns exec router tcpdump -i any -w mtls_capture.pcap
```

Keep this running.

---

### 🔐 Step 2 — Start mTLS Server (blue namespace)

```bash
sudo ip netns exec blue openssl s_server \
  -accept 4433 \
  -cert /certs/server.crt \
  -key /certs/server.key \
  -CAfile /certs/ca.crt \
  -Verify 1
```

---

### 🔗 Step 3 — Start mTLS Client (SUCCESS CASE)

```bash
sudo ip netns exec red openssl s_client \
  -connect 10.0.2.2:4433 \
  -cert /certs/client.crt \
  -key /certs/client.key \
  -CAfile /certs/ca.crt
```

Expected result:

- Handshake succeeds  
- Client and server authenticate each other  

---

### ❌ Step 4 — Negative Test (Without Client Certificate)

```bash
sudo ip netns exec red openssl s_client \
  -connect 10.0.2.2:4433 \
  -CAfile /certs/ca.crt
```

Expected result:

- Handshake fails  
- Server rejects client  

---

### 🛑 Step 5 — Stop Packet Capture

Press:

```bash
Ctrl + C
```

in the tcpdump terminal.

---

### 👀 Step 6 — Analyze in Wireshark

Open the generated `.pcap` file in Wireshark.

---

### 🔍 Recommended Filters

```
tls
tcp.port == 4433
```

---

### 🔎 Key Observations (mTLS)

- Server sends `Certificate Request`  
- Client responds with its `Certificate`  
- Client proves identity using `Certificate Verify`  
- Mutual authentication is established  
- Without client certificate → handshake failure  

---

## 🔐 Encryption Boundary

After `ChangeCipherSpec`, Wireshark shows:

```
TLS Application Data
```

This applies to both TLS and mTLS, indicating the transition from asymmetric to symmetric encryption.

---

### 🌐 Layer-3 Routing Proof

Initial TTL: 64  
Observed TTL: 63  

---

## 🔄 TLS vs mTLS Comparison

| Feature | TLS | mTLS |
|--------|-----|------|
| Server Authentication | ✅ | ✅ |
| Client Authentication | ❌ | ✅ |
| Certificate Exchange | One-way | Two-way |
| Security Level | High | Very High |
| Use Cases | HTTPS | Zero Trust, Microservices |

---

## 📁 Project Structure

```
network_namespaces/
│
├── blue_namespace/
│   ├── server.crt
│   ├── server.key
│   └── ca.crt
│
├── red_namespace/
│   ├── client.crt
│   ├── client.key
│   └── ca.crt
│
├── ca/
│   ├── ca.crt
│   └── ca.key
│
├── diagrams/
│   └── topology.png
│
├── screenshots/
│
├── report/
│   └── report.pdf
│
├── setup.sh
├── cleanup.sh
├── generate_certs.sh
├── README.md
├── tls_capture.pcap
└── mtls_capture.pcap
```

---

## ⚠ Security Disclaimer

Self-signed certificates are used for educational purposes only.

---

## 🎓 Learning Outcomes

- Layer-3 routing using namespaces  
- TCP handshake understanding  
- TLS 1.2 internals  
- Mutual TLS (mTLS) authentication  
- Certificate Authority (CA) concepts  
- Packet-level analysis with Wireshark  

---

## 🔗 Lecture Source: Network Namespaces - Session 1
https://nitkeduin-my.sharepoint.com/:v:/g/personal/tahiliani_nitk_edu_in/EZsxo6VafiBIn3ybNUNOYPYBJ9Oe7nvBMFc81vTTC-FhtQ?e=b16yGn

---

## 👨‍💻 Author

Samyak Gedam  
National Institute of Technology Surathkal, Karnataka  
Built as part of first task in mini-project course during my 2nd Semester.