from flask import Blueprint, render_template
from gsca.db import mongo
from flask_restful import Api, Resource


home = Blueprint("home", __name__)

api = Api(home)


class TestGSCA(Resource):
    def get(self):
        print("cj")
        return {"new": "gsca"}


api.add_resource(TestGSCA, "/gsca")

