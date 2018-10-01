import os
from flask import Flask, redirect, url_for, request, render_template, jsonify
from pymongo import MongoClient

# from flask_cors import CORS

app = Flask(__name__)

# CORS(app, resources={r"/*": {"origins": "*"}})

client = MongoClient("db", 27017)
db = client.tododb


@app.route("/hello")
def hello():
    return "Hello World from Flask in a uWSGI Nginx Docker container with \
     Python 3.6 (default)"


@app.route("/")
def todo():
    _items = db.tododb.find()
    items = [item for item in _items]

    return render_template("todo.html", items=items)


@app.route("/new", methods=["POST"])
def new():
    item_doc = {
        "name": request.form["name"],
        "description": request.form["description"],
    }
    db.tododb.insert_one(item_doc)

    return redirect(url_for("todo"))


# Error handler API response
@app.errorhandler(404)
def page_not_found(error):
    return jsonify({"error": "Not found"}), 404


# Api status
@app.route("/status")
def apiStatus():
    """api status"""
    return jsonify({"status": "OK"})


if __name__ == "__main__":
    app.run(host="0.0.0.0", debug=True)
