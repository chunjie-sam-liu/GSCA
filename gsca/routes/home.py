from flask import Blueprint, render_template
from gsca.db import mongo
from flask_restful import Api, Resource


home = Blueprint("home", __name__)

api = Api(home)


class TestGSCA(Resource):
    def get(self, gene_name):
        print("cj")
        expr = mongo.db.expr.find({"gene": gene_name})
        return expr


api.add_resource(TestGSCA, "/gsca")
