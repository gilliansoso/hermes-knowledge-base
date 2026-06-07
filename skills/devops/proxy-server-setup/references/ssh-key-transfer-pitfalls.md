# SSH Key Transfer Pitfalls

When receiving a PEM private key from a user for SSH access to a remote server,
the transfer method matters. Several approaches fail silently.

## What Works

### Heredoc with single-quoted delimiter (BEST)

The single quotes around `KEYEOF` prevent shell expansion of the key content:

```bash
cat > /path/to/key.pem << 'KEYEOF'
-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----
KEYEOF
chmod 600 /path/to/key.pem
```

### Python3 write (ALTERNATIVE)

```bash
python3 -c "
key_content = open('/dev/stdin').read()
with open('/path/to/key.pem', 'w') as f:
    f.write(key_content)
import os; os.chmod('/path/to/key.pem', 0o600)
" << 'KEYEOF'
-----BEGIN RSA PRIVATE KEY-----
...
KEYEOF
```

## What Fails

| Method | Problem |
|--------|---------|
| `write_file` tool | May redact or mangle PEM content; size often wrong |
| Heredoc without quoted delimiter (`<< KEYEOF`) | Shell expands `$` in key data, corrupting it |
| `echo $KEY | cat > file` | Newlines collapsed, key format destroyed |
| Pasting key as command argument | Shell interprets special characters, truncated |

## Verification

Always verify after writing:

```bash
# Check format
head -1 /path/to/key.pem
# Expected: -----BEGIN RSA PRIVATE KEY-----

# Check size (typical RSA key: 1600-1700 bytes)
wc -c /path/to/key.pem

# Test SSH
ssh -i /path/to/key.pem -o ConnectTimeout=5 user@host "echo OK"
```

## Cleanup

Remove the key file from the Hermes agent server after use — it's a credential
that shouldn't persist on a shared machine:

```bash
rm -f /path/to/key.pem
```
