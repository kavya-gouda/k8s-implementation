from flask import Flask, jsonify
import random
import threading
import time

app = Flask(__name__)

# Application state
db_connected = True
internal_deadlock = False
cache_ready = True
startup_complete = False

def startup_routine():
    """Simulate application startup (cache warming, etc)"""
    global startup_complete
    time.sleep(10)  # Simulate 10s startup
    startup_complete = True

# Start background startup
threading.Thread(target=startup_routine, daemon=True).start()

@app.route('/health/liveness')
def liveness():
    """Only checks internal application state"""
    if internal_deadlock:
        return jsonify({
            "status": "unhealthy",
            "reason": "internal deadlock detected"
        }), 500
    
    return jsonify({"status": "ok"}), 200

@app.route('/health/readiness')
def readiness():
    """Checks if app can handle traffic"""
    issues = []
    
    if not startup_complete:
        issues.append("startup in progress")
    
    if not db_connected:
        issues.append("database unavailable")
    
    if not cache_ready:
        issues.append("cache not ready")
    
    if issues:
        return jsonify({
            "status": "not ready",
            "issues": issues
        }), 503
    
    return jsonify({"status": "ready"}), 200

@app.route('/api/data')
def get_data():
    if not db_connected:
        return jsonify({"error": "Database unavailable"}), 500
    return jsonify({"data": "success"}), 200

@app.route('/simulate/db-down')
def simulate_db_down():
    global db_connected
    db_connected = False
    return jsonify({"message": "DB connection lost"}), 200

@app.route('/simulate/db-up')
def simulate_db_up():
    global db_connected
    db_connected = True
    return jsonify({"message": "DB connection restored"}), 200

@app.route('/simulate/deadlock')
def simulate_deadlock():
    global internal_deadlock
    internal_deadlock = True
    return jsonify({"message": "Deadlock triggered"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)