import os
import json as jsonlib
from flask import Flask, redirect, url_for, request, render_template, jsonify

# from pymongo import MongoClient

import flask_monitoringdashboard as dashboard
import flask_profiler
from flask_debugtoolbar import DebugToolbarExtension

from flask_pymongo import PyMongo
from flask_sqlalchemy import SQLAlchemy
from werkzeug.wrappers import Response

# from flask_cors import CORS

app = Flask(__name__)

app.config["MONGO_URI"] = "mongodb://db:27017/tododb"
app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:////tmp/test.db"
mongo = PyMongo(app)

sqlite_db = SQLAlchemy(app)

if "APP_PROFILER" in os.environ:
    app.config["DEBUG"] = True
    # You need to declare necessary configuration to initialize
    # flask-profiler as follows:
    app.config["flask_profiler"] = {
        "enabled": app.config["DEBUG"],
        "storage": {"engine": "sqlite"},
        "basicAuth": {"enabled": True, "username": "admin", "password": "admin"},
        "ignore": ["^/static/.*"],
    }

dashboard.bind(app)

# CORS(app, resources={r"/*": {"origins": "*"}})

# client = MongoClient("db", 27017)
# db = client.tododb

PORT = os.environ.get("LISTEN_PORT")

# SOURCE: http://www.brool.com/post/debugging-uwsgi/
if "APP_DEBUG" in os.environ:
    app.debug = True
    from werkzeug.debug import DebuggedApplication

    app.wsgi_app = DebuggedApplication(app.wsgi_app, True)


@app.route("/hello")
def hello():
    return "Hello World from Flask in a uWSGI Nginx Docker container with \
     Python 3.6 (default)"


@app.route("/")
def todo():
    _items = mongo.db.tododb.find()
    items = [item for item in _items]

    return render_template("todo.html", items=items)


@app.route("/new", methods=["POST"])
def new():
    item_doc = {
        "name": request.form["name"],
        "description": request.form["description"],
    }
    mongo.db.tododb.insert_one(item_doc)

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


@app.route("/json")
def json():
    return Response(
        response=jsonlib.dumps({"Hello": "World"}), content_type="application/json"
    )


@app.route("/post-entry", methods=["POST"])
def post_entry():
    params = request.get_json()
    return Response(
        response=jsonlib.dumps(
            {"name": params.get("name"), "gender": params.get("gender")}
        ),
        content_type="application/json",
    )


# -------------------- site map ------------------------
# SOURCE: https://stackoverflow.com/questions/13317536/get-a-list-of-all-routes-defined-in-the-app
def has_no_empty_params(rule):
    defaults = rule.defaults if rule.defaults is not None else ()
    arguments = rule.arguments if rule.arguments is not None else ()
    return len(defaults) >= len(arguments)


@app.route("/site-map")
def site_map():
    links = []
    for rule in app.url_map.iter_rules():
        # Filter out rules we can't navigate to in a browser
        # and rules that require parameters
        if "GET" in rule.methods and has_no_empty_params(rule):
            url = url_for(rule.endpoint, **(rule.defaults or {}))
            links.append((url, rule.endpoint))
    # links is now a list of url, endpoint tuples


# ---------------------


# -------------------- sqlite tests ------------------------
class ExampleModel(sqlite_db.Model):
    __tablename__ = "examples"
    value = sqlite_db.Column(sqlite_db.String(100), primary_key=True)


@app.route("/example")
def sqlite_example():
    app.logger.info("Hello there")
    ExampleModel.query.get(1)
    return render_template("example.html")


@app.route("/redirect")
def redirect_example():

    response = redirect(url_for("example"))
    response.set_cookie("test_cookie", "1")
    return response


# -------------------- sqlite tests ------------------------


# PROFILER
if "APP_PROFILER" in os.environ:
    # In order to active flask-profiler, you have to pass flask
    # app as an argument to flask-profiler.
    # All the endpoints declared so far will be tracked by flask-profiler.
    flask_profiler.init_app(app)

if "APP_DEBUG_TOOLBAR" in os.environ:
    # set a 'SECRET_KEY' to enable the Flask session cookies
    app.config["SECRET_KEY"] = os.environ.get("APP_DEBUG_TOOLBAR_SECRET_KEY")

    # SOURCE: https://github.com/mgood/flask-debugtoolbar/blob/master/example/example.py
    app.config["DEBUG_TB_INTERCEPT_REDIRECTS"] = True
    # app.config['DEBUG_TB_PANELS'] = (
    #    'flask_debugtoolbar.panels.headers.HeaderDebugPanel',
    #    'flask_debugtoolbar.panels.logger.LoggingPanel',
    #    'flask_debugtoolbar.panels.timer.TimerDebugPanel',
    # )

    toolbar = DebugToolbarExtension(app)

if __name__ == "__main__":
    sqlite_db.create_all()

    app.run(host="0.0.0.0", debug=True, port=5000)
