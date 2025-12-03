#!/bin/bash

# Private GPT Docker Launcher Script
# This script helps you start the dockerized Private GPT application

set -e

echo "🐳 Private GPT Docker Launcher"
echo "=============================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    echo "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

# Function to check if containers are running
check_status() {
    echo ""
    echo "📊 Container Status:"
    docker-compose ps
}

# Parse command line arguments
case "${1:-up}" in
    up|start)
        echo "🚀 Starting Private GPT with Docker..."
        echo ""
        docker-compose up -d
        echo ""
        echo "✅ Services started!"
        echo ""
        echo "⏳ Waiting for services to be ready..."
        sleep 5
        
        # Pull the model if Ollama is healthy
        echo ""
        echo "📥 Pulling deepseek-r1:8b model (this may take a while on first run)..."
        docker exec private-gpt-ollama ollama pull deepseek-r1:8b || true
        
        echo ""
        echo "🎉 Private GPT is now running!"
        echo ""
        echo "📱 Access the application:"
        echo "   - Web UI: http://localhost:8501"
        echo "   - Ollama API: http://localhost:11434"
        echo ""
        echo "📝 Useful commands:"
        echo "   - View logs:    ./docker-start.sh logs"
        echo "   - Stop services: ./docker-start.sh stop"
        echo "   - Restart:      ./docker-start.sh restart"
        echo "   - Status:       ./docker-start.sh status"
        echo ""
        ;;
    
    down|stop)
        echo "🛑 Stopping Private GPT..."
        docker-compose down
        echo "✅ Services stopped!"
        ;;
    
    restart)
        echo "🔄 Restarting Private GPT..."
        docker-compose restart
        echo "✅ Services restarted!"
        check_status
        ;;
    
    logs)
        echo "📜 Showing logs (Ctrl+C to exit)..."
        echo ""
        docker-compose logs -f
        ;;
    
    status)
        check_status
        ;;
    
    build)
        echo "🔨 Building Docker images..."
        docker-compose build --no-cache
        echo "✅ Build complete!"
        ;;
    
    clean)
        echo "🧹 Cleaning up Docker resources..."
        read -p "This will remove containers, images, and volumes. Continue? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker-compose down -v --rmi all
            echo "✅ Cleanup complete!"
        else
            echo "❌ Cleanup cancelled."
        fi
        ;;
    
    exec)
        if [ -z "$2" ]; then
            echo "📦 Opening shell in app container..."
            docker exec -it private-gpt-app /bin/bash
        else
            docker exec -it "private-gpt-${2}" /bin/bash
        fi
        ;;
    
    help|--help|-h)
        echo "Usage: ./docker-start.sh [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  up, start    Start all services (default)"
        echo "  down, stop   Stop all services"
        echo "  restart      Restart all services"
        echo "  logs         Show and follow logs"
        echo "  status       Show container status"
        echo "  build        Rebuild Docker images"
        echo "  clean        Remove all containers, images, and volumes"
        echo "  exec [name]  Open shell in container (app or ollama)"
        echo "  help         Show this help message"
        echo ""
        ;;
    
    *)
        echo "❌ Unknown command: $1"
        echo "Run './docker-start.sh help' for usage information."
        exit 1
        ;;
esac

