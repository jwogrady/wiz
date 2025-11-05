#!/usr/bin/env bash
# Test GitHub connectivity and SSH key setup
#
# Usage:
#   ./scripts/test_github.sh

set -euo pipefail

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  GitHub Repository Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check SSH keys exist
echo "1. Checking SSH keys..."
if [[ -f ~/.ssh/id_ed25519 ]]; then
    echo "   ✓ SSH key found: ~/.ssh/id_ed25519"
    echo "   Public key:"
    cat ~/.ssh/id_ed25519.pub | sed 's/^/      /'
    echo ""
else
    echo "   ✖ No SSH key found in ~/.ssh/"
    exit 1
fi

# Check SSH agent
echo "2. Checking SSH agent..."
if ssh-add -l >/dev/null 2>&1; then
    echo "   ✓ SSH agent is running"
    echo "   Loaded keys:"
    ssh-add -l | sed 's/^/      /'
    echo ""
else
    echo "   ⚠ SSH agent not running or no keys loaded"
    echo "   Attempting to start agent and load keys..."

    eval "$(ssh-agent -s)" >/dev/null 2>&1 || true
    ssh-add ~/.ssh/id_ed25519 2>/dev/null || true

    if ssh-add -l >/dev/null 2>&1; then
        echo "   ✓ SSH agent started and key loaded"
        ssh-add -l | sed 's/^/      /'
        echo ""
    else
        echo "   ✖ Failed to start SSH agent"
        echo ""
    fi
fi

# Test HTTPS access
echo "3. Testing HTTPS access to GitHub..."
if git ls-remote https://github.com/jwogrady/wiz.git >/dev/null 2>&1; then
    echo "   ✓ HTTPS access works"
    echo "   Repository: https://github.com/jwogrady/wiz.git"
    echo ""
else
    echo "   ✖ HTTPS access failed"
    echo ""
fi

# Test SSH access
echo "4. Testing SSH access to GitHub..."
ssh_test_output=$(timeout 5 ssh -T git@github.com 2>&1 || \
    echo "timeout_or_error")
if echo "${ssh_test_output}" | grep -q "successfully authenticated"; then
    echo "   ✓ SSH authentication successful!"
    echo ""
elif echo "${ssh_test_output}" | grep -q "Permission denied"; then
    echo "   ✖ SSH authentication failed (Permission denied)"
    echo ""
    echo "   ⚠ Your SSH public key is not added to your GitHub account"
    echo ""
    echo "   To fix this, add your SSH key to GitHub:"
    echo "   1. Copy your public key (shown in step 1 above)"
    echo "   2. Go to: https://github.com/settings/keys"
    echo "   3. Click 'New SSH key'"
    echo "   4. Paste your public key and save"
    echo ""
    echo "   Your public key:"
    cat ~/.ssh/id_ed25519.pub | sed 's/^/      /'
    echo ""
elif echo "${ssh_test_output}" | grep -q "Hi jwogrady"; then
    echo "   ✓ SSH authentication successful!"
    echo "   GitHub response:"
    echo "${ssh_test_output}" | sed 's/^/      /'
    echo ""
else
    echo "   ⚠ SSH test returned unexpected result"
    echo "${ssh_test_output}" | sed 's/^/      /'
    echo ""
fi

# Test repository access
echo "5. Testing repository access..."
echo "   Attempting to fetch repository info..."

if git ls-remote git@github.com:jwogrady/wiz.git >/dev/null 2>&1; then
    echo "   ✓ SSH repository access works!"
    echo "   Repository: git@github.com:jwogrady/wiz.git"
    echo ""

    # Show current remote
    if [[ -d ~/wiz ]]; then
        echo "   Current remote configuration:"
        (cd ~/wiz && git remote -v | sed 's/^/      /')
    fi
else
    echo "   ✖ SSH repository access failed"
    echo "   Repository is accessible via HTTPS instead"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

