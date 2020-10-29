from flask import Blueprint, request
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse


expression = Blueprint("expression", __name__)
api = Api(expression)

mdoel_degs = {}


class DEG(Resource):
    def get(self):
        parser = reqparse.RequestParser()
        parser.add_argument("symbol", type=str, required=True)
        parser.add_argument("cancertypes", type=str)

        args = parser.parse_args()

        condition = {}
        if args.filter != "":
            condition["symbol"] = {"$regex": args.filter, "$options": "i"}
        mcur = mongo.db["BLCA_deg"].find(condition)
        n_record = mcur.count()
        return {""}


api.add_resource(DEG, "/degs")


class DEGTable(Resource):
    def post(self):
        args = request.get_json()
        deg_coll_names = [f"{i}_deg" for i in args["cancertypes"]]
        print(deg_coll_names)
        coll_names = list(set(deg_coll_names) & set(mongo.db.list_collection_names()))
        print(coll_names)
        return {"cj": "cj"}


api.add_resource(DEGTable, "/degtable")

