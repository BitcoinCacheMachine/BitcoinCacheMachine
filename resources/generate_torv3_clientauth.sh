#https://tor.stackexchange.com/questions/19221/how-to-setup-client-authorization-for-v3-onion-services

openssl genpkey -algorithm x25519 -out private-key.pem

openssl pkey -in private-key.pem -pubout -outform PEM -out public-key.pem

cat private-key.pem | grep -v " PRIVATE KEY" | basez --base64pem --decode | tail --bytes 32 | basez --base32 | tr -d '=' > client.auth_private

ONION=".onion"
echo -n "$ONION:descriptor:x25519:" | cat - client.auth_private

# Prepare the initial `.auth` file.
cat public-key.pem | grep -v " PUBLIC KEY" | basez --base64pem --decode | tail --bytes 32 | basez --base32 | tr -d '=' > client.auth

# Prepend the Tor descriptor fields to the base32-encoded bytes in the `.auth` file.
echo -n "descriptor:x25519:" | cat - client.auth