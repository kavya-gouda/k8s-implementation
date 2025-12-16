from flask import Flask, jsonify
import random
import time

app = Flask(__name__)

# Simulated database connection
db_healthy = True

@app.route('/health')
def health():
    # BAD: Only checks if server responds
    return jsonify({"status": "ok"}), 200

@app.route('/api/data')
def get_data():
    global db_healthy
    
    # Randomly simulate DB failure
    if random.random() < 0.3:
        db_healthy = False
    
    if not db_healthy:
        return jsonify({"error": "Database unavailable"}), 500
    
    return jsonify({"data": "success"}), 200

@app.route('/break-db')
def break_db():
    global db_healthy
    db_healthy = False
    return jsonify({"message": "Database connection broken"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)