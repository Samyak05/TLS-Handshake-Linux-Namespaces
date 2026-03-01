# 🔐 TLS Handshake Analysis over Layer-3 Routing using Linux Network Namespaces

![Linux](https://img.shields.io/badge/Platform-Linux-blue)
![Networking](https://img.shields.io/badge/Domain-Computer%20Networks-green)
![TLS](https://img.shields.io/badge/Protocol-TLS-red)

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

Create namespaces and routing:

```bash
sudo ./setup.sh
```

Verify connectivity:

```bash
sudo ip netns exec red ping 10.0.2.2
```

Expected observation:

- Successful ping replies
- TTL decreases from 64 → 63 (proof of router traversal)

Cleanup environment:

```bash
sudo ./cleanup.sh
```

---

## 🔐 TLS Handshake Execution (TLS 1.2)

TLS 1.2 was explicitly enforced to observe the full handshake including `ClientKeyExchange` and `ChangeCipherSpec`.

### Start TLS Server (blue namespace)

```bash
sudo ip netns exec blue openssl s_server \
  -key blue_namespace/key.pem \
  -cert blue_namespace/cert.pem \
  -accept 4433 \
  -tls1_2
```

### Start TLS Client (red namespace)

```bash
sudo ip netns exec red openssl s_client \
  -connect 10.0.2.2:4433 \
  -tls1_2
```

---

## 📡 Packet Capture & Analysis

Capture traffic from router interface:

```bash
sudo ip netns exec router tcpdump -i veth-r1 -w tls_capture.pcap
```

Open the `.pcap` file in Wireshark.

### Recommended Filters

```
tcp.port == 4433
tls
```

---

## 🔎 Detailed Observations

### ✅ TCP 3-Way Handshake

1. SYN  
2. SYN-ACK  
3. ACK  

Connection successfully established before TLS begins.

---

### ✅ TLS 1.2 Handshake Flow

1. ClientHello  
2. ServerHello  
3. Certificate (plaintext transmission)  
4. ServerHelloDone  
5. ClientKeyExchange  
6. ChangeCipherSpec  
7. Finished  

---

### 🔐 Encryption Boundary

After `ChangeCipherSpec`, Wireshark displays:

```
TLS Application Data
```

This confirms symmetric session key activation and encrypted communication.

---

### 🌐 Layer-3 Routing Proof

Initial TTL observed from sender: `64`  
TTL at receiver: `63`

The decrement confirms:

- Packet passed through one router
- True Layer-3 forwarding occurred
- No direct Layer-2 bridging between namespaces

---

## 🔬 Packet-Level Verification

The following were validated in Wireshark:

- TCP sequence number progression
- TLS record encapsulation inside TCP segments
- Proper segmentation and acknowledgements
- No broadcast leakage between subnets
- Clear transition from asymmetric to symmetric encryption

---

## 🔄 Cryptographic Flow Summary (TLS 1.2)

1. ClientHello — proposes cipher suites
2. ServerHello — selects cipher suite
3. Certificate — server proves identity
4. ClientKeyExchange — pre-master secret encrypted using RSA
5. Both sides derive symmetric session keys
6. ChangeCipherSpec
7. Finished

After this point, encrypted application data begins

---

## 📁 Project Structure

```
TLS-Handshake-Linux-Namespaces/
│
├── blue_namespace/
│   ├── cert.pem
│   └── key.pem   (ignored via .gitignore)
│
├── diagrams/
│   └── topology.png
│
├── screenshots/
│   ├── 01_wireshark_pcap_opening.png
│   ├── 02_initial_syn.png
│   ├── 03_syn_ack.png
│   ├── 04_final_ack.png
│   ├── 05_client_hello.png
│   ├── 06_server_hello.png
│   ├── 07_sending_encrypted_data.png
│   └── 08_connection_termination.png
│
├── report/
│   └── report.pdf
│
├── setup.sh
├── cleanup.sh
├── README.md
├── .gitignore
└── tls_capture.pcap
```

---

## ⚠ Security Disclaimer

Self-signed certificates were used strictly for academic experimentation.

In production environments:

- Certificates must be issued by trusted Certificate Authorities (CA)
- TLS 1.3 is strongly recommended
- Private keys must never be committed to version control

---

## 🎓 Learning Outcomes

- Clear distinction between Layer-2 and Layer-3 communication
- TCP connection lifecycle understanding
- TLS 1.2 handshake internals
- Asymmetric → symmetric cryptographic transition
- Practical Wireshark packet inspection
- Realistic network simulation using Linux namespaces

---

## 🔗 Lecture Source: Network Namespaces - Session 1
https://nitkeduin-my.sharepoint.com/:v:/g/personal/tahiliani_nitk_edu_in/EZsxo6VafiBIn3ybNUNOYPYBJ9Oe7nvBMFc81vTTC-FhtQ?e=b16yGn&nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJTdHJlYW1XZWJBcHAiLCJyZWZlcnJhbFZpZXciOiJTaGFyZURpYWxvZy1MaW5rIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXcifX0%3D

---

## 👨‍💻 Author

Samyak Gedam  
National Institute of Technology Surathkal, Karnataka.  
Built as part of first task in mini-project course during my 2nd Semester.