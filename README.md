# 🛡️ Private GPT

A privacy-focused chatbot application that runs entirely locally using Ollama and open-source LLMs. Features include conversational AI with chat history and RAG (Retrieval-Augmented Generation) for document-based Q&A.

## ✨ Features

- 🤖 **Local LLM Integration** - Uses Ollama for completely private AI inference
- 💬 **Chat Interface** - Clean, modern Streamlit UI with conversation history
- 📚 **RAG Support** - Upload PDF documents and chat with your documents
- ⚙️ **Customizable** - Adjust model, temperature, and system prompts
- 🐳 **Docker Support** - Easy deployment with Docker Compose
- 🔒 **100% Private** - All processing happens locally, no data leaves your machine

## 🏗️ Architecture

```
Private_GPT/
├── app/
│   ├── __init__.py
│   └── ui.py                 # Streamlit user interface
├── backend/
│   ├── __init__.py
│   ├── chat_engine.py        # Ollama chat integration
│   └── rag_engine.py         # RAG with FAISS and embeddings
├── main.py                   # Application entry point
├── requirements.txt          # Python dependencies
├── Dockerfile               # Container definition
├── docker-compose.yml       # Multi-service orchestration
└── README.md               # This file
```

## 🚀 Quick Start

### Prerequisites

1. **Python 3.11+** (for local installation)
2. **Ollama** installed and running
   ```bash
   # Install Ollama (https://ollama.ai)
   curl -fsSL https://ollama.ai/install.sh | sh
   
   # Pull a model (e.g., deepseek-r1)
   ollama pull deepseek-r1
   ```

### Option 1: Local Installation

1. **Clone the repository**
   ```bash
   cd /path/to/Private_GPT
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Run the application**
   ```bash
   python main.py
   ```
   
   Or directly with Streamlit:
   ```bash
   streamlit run app/ui.py
   ```

4. **Open your browser**
   - Navigate to `http://localhost:8501`

### Option 2: Docker Deployment (Recommended for Production)

1. **Start services with the launch script**
   ```bash
   ./docker-start.sh start
   ```
   
   This will:
   - Build and start both Ollama and the app containers
   - Pull the `deepseek-r1:8b` model automatically
   - Set up networking and health checks

2. **Access the application**
   - **Web UI**: http://localhost:8501
   - **Ollama API**: http://localhost:11434

3. **Manage Docker services**
   ```bash
   ./docker-start.sh status   # Check status
   ./docker-start.sh logs     # View logs
   ./docker-start.sh stop     # Stop services
   ./docker-start.sh restart  # Restart services
   ./docker-start.sh help     # Show all commands
   ```

4. **Manual Docker Compose (Alternative)**
   ```bash
   # Start services
   docker-compose up -d
   
   # Pull model manually
   docker exec private-gpt-ollama ollama pull deepseek-r1:8b
   
   # View logs
   docker-compose logs -f
   
   # Stop services
   docker-compose down
   ```

5. **Enable GPU Support (Optional)**
   
   If you have NVIDIA GPU, edit `docker-compose.yml` and uncomment the GPU section:
   ```yaml
   deploy:
     resources:
       reservations:
         devices:
           - driver: nvidia
             count: 1
             capabilities: [gpu]
   ```
   
   Make sure you have [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) installed.

## 📖 Usage Guide

### Basic Chat

1. Open the application in your browser
2. Type your message in the chat input at the bottom
3. The AI will respond using the configured Ollama model
4. Chat history is maintained during your session

### Using RAG (Document Q&A)

1. **Upload Documents**
   - Go to the sidebar (📚 RAG section)
   - Click "Upload PDF documents"
   - Select one or more PDF files
   - Click "Process PDFs" to add them to the knowledge base

2. **Enable RAG**
   - Check the "Enable RAG" checkbox in the sidebar
   - The knowledge base info will show number of chunks

3. **Ask Questions**
   - Type questions about your documents
   - The system will retrieve relevant context and answer based on your documents
   - Click "📚 Retrieved Context" to see which parts of the documents were used

### Customization

**Settings Panel (⚙️ Settings):**
- **Model name**: Change the Ollama model (default: deepseek-r1)
- **Temperature**: Adjust response randomness (0.0 = deterministic, 1.5 = creative)
- **System prompt**: Customize the AI's behavior and personality

Click "Apply settings" to update the configuration.

## 🔧 Configuration

### Environment Variables

You can override the Ollama URL using environment variables:

```bash
# For local development
export OLLAMA_BASE_URL=http://localhost:11434

# For Docker
export OLLAMA_BASE_URL=http://ollama:11434
```

Edit `backend/chat_engine.py` to change the default URL.

### Supported Models

Any Ollama-compatible model works. Popular choices:
- `deepseek-r1` (default) - Strong reasoning capabilities
- `llama3` - Meta's latest model
- `mistral` - Fast and capable
- `phi3` - Efficient smaller model
- `codellama` - Code-focused model

View all available models: https://ollama.ai/library

## 🛠️ Development

### Project Structure

- **app/ui.py**: Streamlit interface with chat and RAG UI
- **backend/chat_engine.py**: Ollama API integration for chat
- **backend/rag_engine.py**: RAG implementation using FAISS and SentenceTransformers
- **main.py**: Application entry point

### Adding Features

1. **New chat engine**: Extend `OllamaChatEngine` in `chat_engine.py`
2. **RAG improvements**: Modify `SimpleLocalRAG` in `rag_engine.py`
3. **UI enhancements**: Update `app/ui.py`

### Running Tests

```bash
# Test Ollama connection
curl http://localhost:11434/api/tags

# Test chat endpoint
curl http://localhost:11434/api/chat -d '{
  "model": "deepseek-r1",
  "messages": [{"role": "user", "content": "Hello!"}]
}'
```

## 🐛 Troubleshooting

### Ollama Connection Issues

**Error**: `Connection refused on port 11434`

**Solutions**:
1. Ensure Ollama is running: `ollama serve`
2. Check if the port is correct: `curl http://localhost:11434/api/tags`
3. For Docker: Use `http://host.docker.internal:11434` on Mac/Windows

### Model Not Found

**Error**: `model 'deepseek-r1' not found`

**Solution**: Pull the model first
```bash
ollama pull deepseek-r1
```

### PDF Processing Errors

**Error**: Issues with PDF uploads

**Solutions**:
1. Ensure the PDF is not encrypted
2. Check file size (very large PDFs may take time)
3. Verify `sentence-transformers` is installed

### Import Errors

**Error**: `ModuleNotFoundError: No module named 'X'`

**Solution**: Reinstall dependencies
```bash
pip install -r requirements.txt
```

## 📦 Dependencies

Core libraries:
- **streamlit**: Web UI framework
- **requests**: HTTP client for Ollama API
- **sentence-transformers**: Text embeddings for RAG
- **faiss-cpu**: Vector similarity search
- **pypdf**: PDF text extraction
- **numpy**: Numerical operations

## 🤝 Contributing

Contributions are welcome! Areas for improvement:
- Support for more document formats (DOCX, TXT, Markdown)
- Streaming responses in the UI
- Chat history persistence
- Multiple knowledge bases
- Advanced RAG techniques (hybrid search, reranking)
- Model quantization support

## 📄 License

This project is open source. Feel free to use, modify, and distribute as needed.

## 🔐 Privacy & Security

- **100% Local**: All processing happens on your machine
- **No Telemetry**: No data collection or phone-home features
- **Open Source**: Fully auditable code
- **Docker Isolated**: Containers provide additional isolation

Your documents and conversations never leave your computer.

## 🎯 Roadmap

- [ ] Streaming responses
- [ ] Chat history export/import
- [ ] Multiple document format support
- [ ] Advanced RAG with reranking
- [ ] Voice input/output
- [ ] Multi-modal support (images)
- [ ] Fine-tuning integration

## 📞 Support

For issues, questions, or suggestions:
1. Check the troubleshooting section above
2. Review Ollama documentation: https://ollama.ai/docs
3. Verify your Python and dependency versions

## 🙏 Acknowledgments

Built with:
- [Ollama](https://ollama.ai) - Local LLM inference
- [Streamlit](https://streamlit.io) - Web framework
- [FAISS](https://github.com/facebookresearch/faiss) - Vector search
- [Sentence Transformers](https://www.sbert.net) - Text embeddings

---

**Made with ❤️ for privacy-conscious AI users**

