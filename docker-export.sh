#!/bin/bash

# Docker Export Script for Private GPT
# This script helps you export Docker images and configuration as tar files

set -e

EXPORT_DIR="docker-export"
APP_IMAGE="private_gpt-app"
OLLAMA_IMAGE="ollama/ollama:latest"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "📦 Docker Export Utility for Private GPT"
echo "========================================"
echo ""

# Create export directory
mkdir -p "$EXPORT_DIR"

# Function to get image size
get_image_size() {
    docker images "$1" --format "{{.Size}}" | head -1
}

# Parse command line arguments
case "${1:-all}" in
    app)
        echo "📦 Exporting App image only..."
        echo ""
        
        # Build the app image first
        echo "🔨 Building app image..."
        docker-compose build app
        
        # Get the actual image name
        IMAGE_NAME=$(docker-compose images -q app | xargs docker inspect --format='{{index .RepoTags 0}}')
        
        if [ -z "$IMAGE_NAME" ]; then
            echo "❌ App image not found. Please build it first with: docker-compose build app"
            exit 1
        fi
        
        echo "📦 Exporting: $IMAGE_NAME"
        echo "   Size: $(get_image_size $IMAGE_NAME)"
        
        OUTPUT_FILE="$EXPORT_DIR/private-gpt-app_${TIMESTAMP}.tar"
        docker save -o "$OUTPUT_FILE" "$IMAGE_NAME"
        
        # Compress
        echo "🗜️  Compressing..."
        gzip "$OUTPUT_FILE"
        
        echo "✅ Exported to: ${OUTPUT_FILE}.gz"
        echo "   Final size: $(du -h ${OUTPUT_FILE}.gz | cut -f1)"
        echo ""
        ;;
    
    ollama)
        echo "📦 Exporting Ollama image..."
        echo ""
        
        # Pull latest if not exists
        if ! docker images "$OLLAMA_IMAGE" | grep -q ollama; then
            echo "📥 Pulling Ollama image..."
            docker pull "$OLLAMA_IMAGE"
        fi
        
        echo "📦 Exporting: $OLLAMA_IMAGE"
        echo "   Size: $(get_image_size $OLLAMA_IMAGE)"
        
        OUTPUT_FILE="$EXPORT_DIR/ollama_${TIMESTAMP}.tar"
        docker save -o "$OUTPUT_FILE" "$OLLAMA_IMAGE"
        
        # Compress
        echo "🗜️  Compressing..."
        gzip "$OUTPUT_FILE"
        
        echo "✅ Exported to: ${OUTPUT_FILE}.gz"
        echo "   Final size: $(du -h ${OUTPUT_FILE}.gz | cut -f1)"
        echo ""
        ;;
    
    models)
        echo "📦 Exporting Ollama models from volume..."
        echo ""
        
        # Check if volume exists
        if ! docker volume ls | grep -q private-gpt-ollama-data; then
            echo "❌ Ollama volume not found. Please run the app first."
            exit 1
        fi
        
        OUTPUT_FILE="$EXPORT_DIR/ollama-models_${TIMESTAMP}.tar.gz"
        
        echo "📦 Backing up volume: private-gpt-ollama-data"
        docker run --rm \
            -v private-gpt-ollama-data:/data \
            -v "$(pwd)/$EXPORT_DIR:/backup" \
            ubuntu:22.04 \
            tar czf "/backup/ollama-models_${TIMESTAMP}.tar.gz" -C /data .
        
        echo "✅ Exported to: $OUTPUT_FILE"
        echo "   Size: $(du -h $OUTPUT_FILE | cut -f1)"
        echo ""
        ;;
    
    all)
        echo "📦 Exporting complete Docker setup..."
        echo ""
        
        # Build images
        echo "🔨 Building images..."
        docker-compose build
        
        # Export app image
        echo ""
        echo "📦 [1/3] Exporting App image..."
        APP_IMAGE_NAME=$(docker-compose images -q app | xargs docker inspect --format='{{index .RepoTags 0}}')
        if [ ! -z "$APP_IMAGE_NAME" ]; then
            docker save "$APP_IMAGE_NAME" | gzip > "$EXPORT_DIR/private-gpt-app_${TIMESTAMP}.tar.gz"
            echo "✅ App image: $(du -h $EXPORT_DIR/private-gpt-app_${TIMESTAMP}.tar.gz | cut -f1)"
        fi
        
        # Export ollama image
        echo ""
        echo "📦 [2/3] Exporting Ollama image..."
        if ! docker images "$OLLAMA_IMAGE" | grep -q ollama; then
            docker pull "$OLLAMA_IMAGE"
        fi
        docker save "$OLLAMA_IMAGE" | gzip > "$EXPORT_DIR/ollama_${TIMESTAMP}.tar.gz"
        echo "✅ Ollama image: $(du -h $EXPORT_DIR/ollama_${TIMESTAMP}.tar.gz | cut -f1)"
        
        # Export models if volume exists
        echo ""
        echo "📦 [3/3] Exporting models (if available)..."
        if docker volume ls | grep -q private-gpt-ollama-data; then
            docker run --rm \
                -v private-gpt-ollama-data:/data \
                -v "$(pwd)/$EXPORT_DIR:/backup" \
                ubuntu:22.04 \
                tar czf "/backup/ollama-models_${TIMESTAMP}.tar.gz" -C /data .
            echo "✅ Models: $(du -h $EXPORT_DIR/ollama-models_${TIMESTAMP}.tar.gz | cut -f1)"
        else
            echo "⚠️  No models found (volume doesn't exist yet)"
        fi
        
        # Copy configuration files
        echo ""
        echo "📦 Copying configuration files..."
        cp docker-compose.yml "$EXPORT_DIR/"
        cp Dockerfile "$EXPORT_DIR/"
        cp requirements.txt "$EXPORT_DIR/"
        cp .dockerignore "$EXPORT_DIR/" 2>/dev/null || true
        
        # Create deployment instructions
        cat > "$EXPORT_DIR/IMPORT_INSTRUCTIONS.txt" << 'EOF'
Private GPT - Import Instructions
==================================

To deploy this Docker package on another machine:

1. Prerequisites:
   - Docker installed
   - Docker Compose installed

2. Load the images:
   
   # Load App image
   docker load -i private-gpt-app_*.tar.gz
   
   # Load Ollama image
   docker load -i ollama_*.tar.gz

3. (Optional) Restore models:
   
   # Create volume
   docker volume create private-gpt-ollama-data
   
   # Restore models
   docker run --rm \
     -v private-gpt-ollama-data:/data \
     -v $(pwd):/backup \
     ubuntu:22.04 \
     tar xzf /backup/ollama-models_*.tar.gz -C /data

4. Start services:
   
   docker-compose up -d

5. Access the application:
   
   Web UI: http://localhost:8501
   Ollama API: http://localhost:11434

For more help, see DOCKER.md
EOF
        
        # Create a complete package
        echo ""
        echo "📦 Creating complete package..."
        PACKAGE_NAME="private-gpt-docker-package_${TIMESTAMP}.tar.gz"
        tar czf "$PACKAGE_NAME" -C "$EXPORT_DIR" .
        
        echo ""
        echo "✅ Complete! All files exported to: $EXPORT_DIR/"
        echo ""
        echo "📦 Package contents:"
        ls -lh "$EXPORT_DIR/"
        echo ""
        echo "📦 Complete package: $PACKAGE_NAME"
        echo "   Size: $(du -h $PACKAGE_NAME | cut -f1)"
        echo ""
        echo "📄 To import on another machine, extract the package and follow:"
        echo "   $EXPORT_DIR/IMPORT_INSTRUCTIONS.txt"
        echo ""
        ;;
    
    package)
        echo "📦 Creating deployment package (config only, no images)..."
        echo ""
        
        PACKAGE_DIR="private-gpt-package"
        mkdir -p "$PACKAGE_DIR"
        
        # Copy all necessary files
        cp -r app/ "$PACKAGE_DIR/"
        cp -r backend/ "$PACKAGE_DIR/"
        cp Dockerfile "$PACKAGE_DIR/"
        cp docker-compose.yml "$PACKAGE_DIR/"
        cp requirements.txt "$PACKAGE_DIR/"
        cp .dockerignore "$PACKAGE_DIR/" 2>/dev/null || true
        cp .gitignore "$PACKAGE_DIR/" 2>/dev/null || true
        cp README.md "$PACKAGE_DIR/" 2>/dev/null || true
        cp DOCKER.md "$PACKAGE_DIR/" 2>/dev/null || true
        cp docker-start.sh "$PACKAGE_DIR/" 2>/dev/null || true
        cp run.sh "$PACKAGE_DIR/" 2>/dev/null || true
        cp main.py "$PACKAGE_DIR/" 2>/dev/null || true
        
        # Make scripts executable
        chmod +x "$PACKAGE_DIR"/*.sh 2>/dev/null || true
        
        # Create deployment guide
        cat > "$PACKAGE_DIR/DEPLOY.txt" << 'EOF'
Private GPT - Deployment Guide
===============================

This package contains all source code and configuration.

Docker Deployment:
------------------
1. Build and start:
   ./docker-start.sh start

2. Access at: http://localhost:8501

Local Deployment:
-----------------
1. Install dependencies:
   pip install -r requirements.txt

2. Run:
   ./run.sh
   or
   python main.py

For detailed instructions, see README.md and DOCKER.md
EOF
        
        # Create archive
        PACKAGE_FILE="private-gpt-source_${TIMESTAMP}.tar.gz"
        tar czf "$PACKAGE_FILE" "$PACKAGE_DIR"
        
        echo "✅ Source package created: $PACKAGE_FILE"
        echo "   Size: $(du -h $PACKAGE_FILE | cut -f1)"
        echo ""
        echo "📦 Contents:"
        echo "   - Source code (app/ and backend/)"
        echo "   - Docker configuration"
        echo "   - Documentation"
        echo "   - Launch scripts"
        echo ""
        echo "To deploy: Extract and run './docker-start.sh start'"
        echo ""
        
        # Cleanup
        rm -rf "$PACKAGE_DIR"
        ;;
    
    clean)
        echo "🧹 Cleaning up export directory..."
        rm -rf "$EXPORT_DIR"
        rm -f private-gpt-*.tar.gz
        echo "✅ Cleaned up!"
        ;;
    
    help|--help|-h)
        echo "Usage: ./docker-export.sh [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  app       Export only the App Docker image"
        echo "  ollama    Export only the Ollama Docker image"
        echo "  models    Export Ollama models from volume"
        echo "  all       Export everything (images + models + config) [default]"
        echo "  package   Create source code package (no images)"
        echo "  clean     Clean up export directory"
        echo "  help      Show this help message"
        echo ""
        echo "Examples:"
        echo "  ./docker-export.sh all       # Export complete setup"
        echo "  ./docker-export.sh app       # Export only app image"
        echo "  ./docker-export.sh models    # Export only models"
        echo "  ./docker-export.sh package   # Export source code only"
        echo ""
        echo "Import on another machine:"
        echo "  docker load -i private-gpt-app_*.tar.gz"
        echo "  docker load -i ollama_*.tar.gz"
        echo "  docker-compose up -d"
        echo ""
        ;;
    
    *)
        echo "❌ Unknown command: $1"
        echo "Run './docker-export.sh help' for usage information."
        exit 1
        ;;
esac

echo "💡 Tip: To import on another machine:"
echo "   docker load -i <image-file>.tar.gz"
echo ""

