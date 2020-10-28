from flask import Blueprint
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse


expression = Blueprint("expression", __name__)
api = Api(expression)

mdoel_degs = {}


class DEG(Resource):
    def get(self):
        parser = reqparse.RequestParser()
        parser.add_argument("symbol", type=str, required=True)
        parser.add_argument("cancer_type", type=str)

        args = parser.parse_args()

        condition = {}
        if args.filter != "":
            condition["symbol"] = {"$regex": args.filter, "$options": "i"}
        mcur = mongo.db["BLCA_deg"].find(condition)
        n_record = mcur.count()
        return {""}


api.add_resource(DEG, "/degs")


class DEGTable(Resource):
    def get(self):
        print("cj")

api.add_resource(DEGTable, "/degtable")

