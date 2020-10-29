from flask import Blueprint, request
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse

expression = Blueprint("expression", __name__)
api = Api(expression)

mdoel_degtable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "normal": fields.Float(attribute="normal"),
    "tumor": fields.Float(attribute="tumor"),
    "fc": fields.Float(attribute="fc"),
    "fdr": fields.Float(attribute="fdr"),
    "n_normal": fields.Float(attribute="n_normal"),
    "n_tumor": fields.Float(attribute="n_tumor"),
    "cancertype": fields.String(attribute="cancertype"),
}


class DEGTable(Resource):
    @marshal_with(mdoel_degtable)
    def post(self):
        args = request.get_json()
        condition = {"symbol": {"$in": args["validSymbol"]}}
        output = {"_id": 0}
        res = list()
        print(args)
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_deg")
                res.append(m)

        return res


api.add_resource(DEGTable, "/degtable")

