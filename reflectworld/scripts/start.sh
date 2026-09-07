#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Starting ReflectWorld..."

# Backend
if [ ! -d "backend/.venv" ]; then
  echo "Setting up Python environment..."
  if python3 -m venv backend/.venv 2>/dev/null; then
    backend/.venv/bin/pip install -r backend/requirements.txt
    PYTHON=backend/.venv/bin/python
    UVICORN=backend/.venv/bin/uvicorn
  else
    echo "venv not available, using system Python"
    pip3 install -r backend/requirements.txt -q
    PYTHON=python3
    UVICORN=uvicorn
  fi
else
  PYTHON=backend/.venv/bin/python
  UVICORN=backend/.venv/bin/uvicorn
fi

echo "Starting backend on :8000..."
cd backend
$UVICORN main:app --host 0.0.0.0 --port 8000 --reload &
BACKEND_PID=$!
cd ..

# Frontend
if [ ! -d "frontend/node_modules" ]; then
  echo "Installing frontend dependencies..."
  cd frontend && npm install && cd ..
fi

echo "Starting frontend on :3000..."
cd frontend && npm run dev &
FRONTEND_PID=$!
cd ..

echo ""
echo "ReflectWorld is running:"
echo "  Frontend: http://localhost:3000"
echo "  Backend:  http://localhost:8000"
echo "  API docs: http://localhost:8000/docs"
echo ""
echo "Press Ctrl+C to stop."

wait $BACKEND_PID $FRONTEND_PID
