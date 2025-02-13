from flask import Flask, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

@app.route('/objects')
def objects():
    return jsonify([
        {"id": 1, "name": "Asteroid A", "x": 10, "y": 20},
        {"id": 2, "name": "Comet B", "x": -15, "y": 35}
    ])

@app.route('/alerts')
def alerts():
    return jsonify([
        {"id": 1, "threat": True, "name": "Asteroid A"}
    ])

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
