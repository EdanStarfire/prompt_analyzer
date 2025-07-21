curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
\. $NVM_DIR/nvm.sh
nvm install 22
node -v
nvm current
npm -v
npm install -g @anthropic-ai/claude-code
npm i -g opencode-ai@latest