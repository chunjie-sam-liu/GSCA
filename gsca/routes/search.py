from flask import Blueprint
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse

search = Blueprint("search", __name__)
api = Api(search)


class Symbols(Resource):
    def get(self):
        condition = {}
        output = {"_id": 0, "searchname": 1}
        print(mongo.db.gene_symbol)
        mcur = mongo.db.gene_symbol.find(condition, output).limit(5)
        return list(mcur)


api.add_resource(Symbols, "/symbols")
