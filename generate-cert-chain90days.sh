#!/bin/bash

# Generate a full certificate chain for testing MOSIP keymanager:
#  - Root CA (self-signed)
#  - Intermediate CA (signed by root)
#  - Partner/leaf certificate (signed by intermediate)
#
# All use RSA 2048 with SHA512 (maps to SHA512withRSA in Java).
# Validity: 3 months (90 days)
#
# Output directory: cert-chain/

set -euo pipefail

OUT_DIR="cert-chain"
ROOT_CN="Test Root CA"
INTER_CN="Test Intermediate CA"
LEAF_CN="Test Partner Cert"
DAYS=65

mkdir -p "${OUT_DIR}"
cd "${OUT_DIR}"

echo "=== 1. Generate Root CA (self-signed) ==="

openssl genrsa -out root_key.pem 2048

openssl req -x509 -new -nodes -key root_key.pem \
  -sha512 -days ${DAYS} \
  -subj "/C=US/O=FaydaSec/OU=TestUnit/CN=${ROOT_CN}" \
  -addext "basicConstraints=critical,CA:true,pathlen:1" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" \
  -out root_cert.pem

echo "Root CA:"
openssl x509 -in root_cert.pem -noout -subject -issuer -text | \
  grep -E "Subject:|Issuer:|Signature Algorithm" | head -5
echo

echo "=== 2. Generate Intermediate CA (signed by Root) ==="

openssl genrsa -out inter_key.pem 2048

openssl req -new -key inter_key.pem \
  -subj "/C=US/O=FaydaSec/OU=TestUnit/CN=${INTER_CN}" \
  -out inter.csr

cat > inter_ext.cnf <<EOF
basicConstraints=critical,CA:true,pathlen:0
keyUsage=critical,keyCertSign,cRLSign
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
EOF

openssl x509 -req -in inter.csr \
  -CA root_cert.pem -CAkey root_key.pem \
  -CAcreateserial \
  -out inter_cert.pem \
  -days ${DAYS} -sha512 \
  -extfile inter_ext.cnf

echo "Intermediate CA:"
openssl x509 -in inter_cert.pem -noout -subject -issuer -text | \
  grep -E "Subject:|Issuer:|Signature Algorithm" | head -5
echo

echo "=== 3. Generate Partner/Leaf certificate (signed by Intermediate) ==="

openssl genrsa -out leaf_key.pem 2048

openssl req -new -key leaf_key.pem \
  -subj "/C=US/O=FaydaSec/OU=TestUnit/CN=${LEAF_CN}" \
  -out leaf.csr

cat > leaf_ext.cnf <<EOF
basicConstraints=critical,CA:false
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
EOF

openssl x509 -req -in leaf.csr \
  -CA inter_cert.pem -CAkey inter_key.pem \
  -CAcreateserial \
  -out leaf_cert.pem \
  -days ${DAYS} -sha512 \
  -extfile leaf_ext.cnf

echo "Leaf / Partner certificate:"
openssl x509 -in leaf_cert.pem -noout -subject -issuer -text | \
  grep -E "Subject:|Issuer:|Signature Algorithm" | head -5
echo

echo "=== 4. Create chain files ==="

# Full chain (leaf -> intermediate -> root)
cat leaf_cert.pem inter_cert.pem root_cert.pem > chain_leaf_inter_root.pem

# CA chain (intermediate + root)
cat inter_cert.pem root_cert.pem > ca_chain_inter_root.pem

echo "Created files in $(pwd):"
ls -1
echo

echo "=== 5. Base64 versions for API payloads (single-line) ==="

for f in root_cert.pem inter_cert.pem leaf_cert.pem; do
  out="${f%.pem}_base64.txt"
  base64 -w 0 "$f" > "$out"
  echo "  - $out"
done

echo
echo "Use these for testing:"
echo "  • Upload root CA first      -> root_cert_base64.txt"
echo "  • Then upload intermediate  -> inter_cert_base64.txt"
echo "  • Finally upload partner    -> leaf_cert_base64.txt"
echo
echo "Signature algorithm in Java for all: SHA512withRSA"

