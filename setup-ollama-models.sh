#!/bin/bash
# Script to download necessary Ollama models for InnovativeHypeChat

echo "Setting up Ollama models for InnovativeHypeChat..."

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/version > /dev/null; then
  echo "Error: Ollama is not running. Please start Ollama first."
  echo "Run 'docker compose up -d ollama' to start Ollama."
  exit 1
fi

# Download the main chat models
echo "Downloading main chat models..."
ollama pull llama3
ollama pull mistral
ollama pull phi3
ollama pull gemma
ollama pull codellama
ollama pull orca-mini

# Download the embedding model for RAG
echo "Downloading embedding model for RAG..."
ollama pull nomic-embed-text

echo "All models have been downloaded successfully!"
echo "You can now start InnovativeHypeChat with 'docker compose up -d'" 