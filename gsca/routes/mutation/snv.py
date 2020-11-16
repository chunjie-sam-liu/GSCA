from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from pathlib import Path
import subprocess
import uuid
from gsca.utils.checkplot import CheckPlot

snv = Blueprint("snv", __name__)
api = Api(snv)

model_snvtable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "cancertype": fields.String(attribute="cancertype"),
    "mutated_sample_size": fields.Integer(attribute="mutated_sample_size"),
    "percentage": fields.Float(attribute="percentage"),
    "sample_size": fields.Integer(attribute="sample_size"),
}


class SnvTable(Resource):
    @marshal_with(model_snvtable)
    def post(self):
        args = request.get_json()
        condition = {"symbol": {"$in": args["validSymbol"]}}
        output = {"_id": 0}
        res = list()
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_snv_count")
                m["percentage"] = m["percentage"] * 100
                res.append(m)
        return res


api.add_resource(SnvTable, "/snvtable")
