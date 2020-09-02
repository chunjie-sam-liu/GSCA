from flask import Blueprint, render_template
from gsca.db import mongo
from flask_restful import Api


home = Blueprint("home", __name__)

api = Api(home)


@home.route("/", methods=["GET"])
def index():
    return render_template("index.html")
