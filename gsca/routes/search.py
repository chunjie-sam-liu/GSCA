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
        mcur = mongo.db.gene_symbol.find(condition, output).sort("symbol", 1)
        res = []
        for item in mcur:
            res.append(item["symbol"])
        return res


api.add_resource(SymbolList, "/symbollist")

model_symbol = {
    "entrez": fields.Integer,
    "symbol": fields.String,
    "description": fields.String,
    "biotype": fields.String,
    "searchname": fields.String,
}


class SingleSymbol(Resource):
    @marshal_with(model_symbol)
    def get(self, s):
        condition = {"searchname": {"$regex": s, "$options": "i"}}
        print(condition)
        output = {"_id": 0}
        mcur = mongo.db.gene_symbol.find(condition, output).limit(5)
        return list(mcur)


api.add_resource(SingleSymbol, "/symbol/<string:s>")
