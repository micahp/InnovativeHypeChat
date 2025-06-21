<p align="center">
  <a href="https://chat.innovativehype.com">
    <img src="client/public/assets/logo.svg" height="256">
  </a>
  <h1 align="center">
    <a href="https://chat.innovativehype.com">InnovativeHypeChat</a>
  </h1>
</p>

<p align="center">
  <strong>Based on <a href="https://librechat.ai">LibreChat</a></strong>
</p>

# InnovativeHypeChat

**InnovativeHypeChat** is a *whitelabel-ready* fork of LibreChat. Run your own ChatGPT-style UI with free OSS models or paid keys of your choice.

## 🚀 Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/)
- (Optional) An [OpenRouter](https://openrouter.ai/) API key is not needed to access free models. Add an API key to access OpenRouter's paid models

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/micahp/InnovativeHypeChat.git
   cd InnovativeHypeChat
   ```

2. **Create a .env file**
   ```bash
   cp .env.example .env
   ```
   
3. **(Optional) Update your .env file with your OpenRouter API key**
   ```
   OPENROUTER_API_KEY=your_api_key_here
   ```

4. **Start the application**
   ```bash
    docker compose up -d
    ```

5. **Download Ollama models for RAG**
   ```bash
    ./setup-ollama-models.sh
    ```

6. **Access the application**
   
Open your browser and navigate to [http://localhost:3080](http://localhost:3080)

## How to rebrand

```bash
./rebrand.sh "YourBrand" "#FF6600"
```

## 🌟 Features

InnovativeHypeChat includes all the powerful features of LibreChat plus:

- 🔍 **Free AI Models**: Access to free models through OpenRouter
- 📄 **Document Search**: RAG capabilities through Ollama
- 🧠 **Local Processing**: Uses Ollama for local model inference
- 🚀 **Custom Branding**: Fully customized interface

---

# ✨ LibreChat Features

InnovativeHypeChat is based on LibreChat and inherits all of its amazing features:

- 🖥️ **UI & Experience** inspired by ChatGPT with enhanced design and features

- 🤖 **AI Model Selection**:  
  - Anthropic (Claude), AWS Bedrock, OpenAI, Azure OpenAI, Google, Vertex AI, OpenAI Assistants API (incl. Azure)
  - Custom Endpoints: Use any OpenAI-compatible API, no proxy required
  - Compatible with Local & Remote AI Providers

- 🔧 **Code Interpreter API**: 
  - Secure, Sandboxed Execution in Python, Node.js (JS/TS), Go, C/C++, Java, PHP, Rust, and Fortran
  - Seamless File Handling: Upload, process, and download files directly

- 🔦 **Agents & Tools Integration**:  
  - LibreChat Agents and Custom Assistants
  - Model Context Protocol (MCP) Support for Tools

- 🪄 **Generative UI with Code Artifacts**:  
  - Creation of React, HTML, and Mermaid diagrams directly in chat

- 🎨 **Image Generation & Editing**
  - Text-to-image and image-to-image capabilities

- 💾 **Presets & Context Management**:  
  - Create, Save, & Share Custom Presets  
  - Switch between AI Endpoints and Presets mid-chat

- 💬 **Multimodal & File Interactions**:  
  - Upload and analyze images with various AI models
  - Chat with Files using multiple AI providers

- 🌎 **Multilingual UI**:  
  - Support for multiple languages

- 🔍 **Search & Discovery**:  
  - Search all messages/conversations

- 👥 **Multi-User & Secure Access**:
  - Multi-User, Secure Authentication with OAuth2, LDAP, & Email Login Support

For a complete list of features, visit the [LibreChat documentation](https://docs.librechat.ai/).

## Together AI

Set the following variables in your `.env` to enable Together models and Code Interpreter:

```bash
TOGETHER_API_KEY=your_key
TOGETHER_CHAT_MODEL=meta-llama/Llama-3-70b-chat-hf
TOGETHER_EMBEDDING_MODEL=togethercomputer/m2-bert-80M-8k-retrieval
TOGETHER_CODE_INTERPRETER_IMAGE=python:3.11
VECTOR_PROVIDER=together
```

<p align="center">
  <a href="https://discord.librechat.ai"> 
    <img
      src="https://img.shields.io/discord/1086345563026489514?label=&logo=discord&style=for-the-badge&logoWidth=20&logoColor=white&labelColor=000000&color=blueviolet">
  </a>
  <a href="https://www.youtube.com/@LibreChat"> 
    <img
      src="https://img.shields.io/badge/YOUTUBE-red.svg?style=for-the-badge&logo=youtube&logoColor=white&labelColor=000000&logoWidth=20">
  </a>
  <a href="https://docs.librechat.ai"> 
    <img
      src="https://img.shields.io/badge/DOCS-blue.svg?style=for-the-badge&logo=read-the-docs&logoColor=white&labelColor=000000&logoWidth=20">
  </a>
  <a aria-label="Sponsors" href="https://github.com/sponsors/danny-avila">
    <img
      src="https://img.shields.io/badge/SPONSORS-brightgreen.svg?style=for-the-badge&logo=github-sponsors&logoColor=white&labelColor=000000&logoWidth=20">
  </a>
</p>

<p align="center">
<a href="https://railway.app/template/b5k2mn?referralCode=HI9hWz">
  <img src="https://railway.app/button.svg" alt="Deploy on Railway" height="30">
</a>
<a href="https://zeabur.com/templates/0X2ZY8">
  <img src="https://zeabur.com/button.svg" alt="Deploy on Zeabur" height="30"/>
</a>
<a href="https://template.cloud.sealos.io/deploy?templateName=librechat">
  <img src="https://raw.githubusercontent.com/labring-actions/templates/main/Deploy-on-Sealos.svg" alt="Deploy on Sealos" height="30">
</a>
</p>

<p align="center">
  <a href="https://www.librechat.ai/docs/translation">
    <img 
      src="https://img.shields.io/badge/dynamic/json.svg?style=for-the-badge&color=2096F3&label=locize&query=%24.translatedPercentage&url=https://api.locize.app/badgedata/4cb2598b-ed4d-469c-9b04-2ed531a8cb45&suffix=%+translated" 
      alt="Translation Progress">
  </a>
</p>
