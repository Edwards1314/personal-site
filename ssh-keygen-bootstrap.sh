 #!/bin/bash
# 🔑 Bootstrap SSH key generator & GitHub uploader
# Can be run directly after downloading or via curl | bash

echo "🔹 SSH Key Generator & GitHub Uploader"

# Prompt for required info
read -p "Enter your email (for the SSH key comment): " EMAIL
read -p "Enter a title for this key (e.g., 'Work Laptop'): " TITLE
read -s -p "Enter your GitHub Personal Access Token: " TOKEN
echo ""
read -p "Optional: Enter filename for SSH key (default: id_ed25519): " KEY_FILE

# Set default if empty
KEY_FILE=${KEY_FILE:-id_ed25519}
KEY_PATH="$HOME/.ssh/$KEY_FILE"

# Ensure .ssh directory exists
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Handle existing key
if [ -f "$KEY_PATH" ]; then
  echo "⚠️  SSH key already exists at $KEY_PATH"
  read -p "Do you want to overwrite it? (y/N): " OVERWRITE
  if [[ "$OVERWRITE" =~ ^[Yy]$ ]]; then
    echo "🗑️  Removing old key..."
    rm -f "$KEY_PATH" "$KEY_PATH.pub"
  else
    echo "➡️ Using existing key."
  fi
fi

# Generate SSH key if not exists
if [ ! -f "$KEY_PATH" ]; then
  echo "Generating new SSH key..."
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_PATH" -N ""
fi

# Start ssh-agent and add key
eval "$(ssh-agent -s)" >/dev/null
ssh-add "$KEY_PATH"

# Read public key
PUB_KEY=$(cat "${KEY_PATH}.pub")

# Upload to GitHub
echo "⬆️ Uploading key to GitHub..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: token $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/user/keys \
  -d "{\"title\":\"$TITLE\",\"key\":\"$PUB_KEY\"}")

if [ "$RESPONSE" -eq 201 ]; then
  echo "✅ SSH key successfully uploaded to GitHub!"
  echo "   Title: $TITLE"
  echo "   Location: $KEY_PATH"
else
  echo "❌ Failed to upload key. HTTP status: $RESPONSE"
  echo "   Make sure your GitHub token has 'admin:public_key' permission."
fi
