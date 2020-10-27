from flask import Blueprint
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse

search = Blueprint("search", __name__)
api = Api(search)


class SearchNameList(Resource):
    def get(self):
        condition = {}
        output = {"_id": 0, "searchname": 1, "symbol": 1}
        mcur = mongo.db.gene_symbol.find(condition, output)
        res = {"searchname": [], "symbol": []}
        for item in mcur:
            res["searchname"].append(item["searchname"])
            res["symbol"].append(item["symbol"])
        return res


api.add_resource(SearchNameList, "/searchnamelist")


class SymbolList(Resource):
    def get(self):
        condition = {}
        output = {"_id": 0, "symbol": 1}
        mcur = mongo.db.gene_symbol.find(condition, output)
        res = []
        for item in mcur:
            res.append(item["symbol"])
        return res


api.add_resource(SymbolList, "/symbollist")

