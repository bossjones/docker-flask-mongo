import os
import json
from flask import Flask, redirect, url_for, request, render_template, jsonify
from pymongo import MongoClient

import flask_monitoringdashboard as dashboard
import flask_profiler
from flask_debugtoolbar import DebugToolbarExtension

# from werkzeug.wrappers import Response

# from flask_cors import CORS

app = Flask(__name__)

if 'APP_PROFILER' in os.environ:
    app.config["DEBUG"] = True
    # You need to declare necessary configuration to initialize
    # flask-profiler as follows:
    app.config["flask_profiler"] = {
        "enabled": app.config["DEBUG"],
        "storage": {
            "engine": "sqlite"
        },
        "basicAuth":{
            "enabled": True,
            "username": "admin",
            "password": "admin"
        },
        "ignore": [
            "^/static/.*"
        ]
    }

dashboard.bind(app)

# CORS(app, resources={r"/*": {"origins": "*"}})

client = MongoClient("db", 27017)
db = client.tododb

PORT = os.environ.get("LISTEN_PORT")

# SOURCE: http://www.brool.com/post/debugging-uwsgi/
if 'APP_DEBUG' in os.environ:
    app.debug = True
    from werkzeug.debug import DebuggedApplication
    app.wsgi_app = DebuggedApplication(app.wsgi_app, True)

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

@app.route('/json')
def json():
    return Response(response=json.dumps({'Hello': 'World'}), content_type='application/json')

@app.route('/', methods=['POST'])
def post_entry():
    params = request.get_json()
    return Response(response=json.dumps({'name': params.get('name'), 'gender': params.get('gender')}),
                    content_type='application/json')

# PROFILER
if 'APP_PROFILER' in os.environ:
    # In order to active flask-profiler, you have to pass flask
    # app as an argument to flask-profiler.
    # All the endpoints declared so far will be tracked by flask-profiler.
    flask_profiler.init_app(app)

if 'APP_DEBUG_TOOLBAR' in os.environ:
    # set a 'SECRET_KEY' to enable the Flask session cookies
    app.config['SECRET_KEY'] = os.environ.get("APP_DEBUG_TOOLBAR_SECRET_KEY")

    toolbar = DebugToolbarExtension(app)

if __name__ == "__main__":
    app.run(host="0.0.0.0", debug=True, port=5000)
