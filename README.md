# X.509 Certificate Chain Generator

This repository provides a Bash script to generate a complete **X.509 certificate chain** for testing, development, and lab environments.

The script generates:
- Root Certificate Authority (self-signed)
- Intermediate Certificate Authority (signed by Root)
- Leaf / End-Entity certificate (signed by Intermediate)

All certificates use **RSA 2048** keys with **SHA-512** signatures and are valid for **3 months (90 days)**.

---

## 🔐 Cryptographic Details

| Component        | Algorithm | Key Size | Signature Algorithm |
|------------------|-----------|----------|---------------------|
| Root CA          | RSA       | 2048     | SHA512withRSA      |
| Intermediate CA  | RSA       | 2048     | SHA512withRSA      |
| Leaf Certificate | RSA       | 2048     | SHA512withRSA      |

---

## 📁 Output Structure

After execution, the script creates the following files inside `cert-chain/`:

cert-chain/
├── root_key.pem
├── root_cert.pem
├── inter_key.pem
├── inter_cert.pem
├── leaf_key.pem
├── leaf_cert.pem
├── chain_leaf_inter_root.pem
├── ca_chain_inter_root.pem
├── root_cert_base64.txt
├── inter_cert_base64.txt
└── leaf_cert_base64.txt



---

## ▶️ Usage

Make the script executable:

```bash
chmod +x generate-cert-chain.sh


Run the script:

./generate-cert-chain.sh





🔍 Verification

Check validity dates:

openssl x509 -in cert-chain/leaf_cert.pem -noout -dates


Check signature algorithm:

openssl x509 -in cert-chain/leaf_cert.pem -noout -text | grep "Signature Algorithm"

⚠️ Security Notice

This project is intended for development and testing only.

Do NOT use these certificates in production

Do NOT commit private keys to public repositories

Use a proper CA or HSM-backed PKI for production systems

📌 Compatibility

OpenSSL ≥ 1.1.1

Linux / macOS

Java-compatible signature algorithm: SHA512withRSA


