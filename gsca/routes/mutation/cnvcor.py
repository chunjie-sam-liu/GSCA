from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from pathlib import Path
import subprocess
import uuid
from gsca.utils.checkplot import CheckPlot, CheckParallelPlot

cnvcor = Blueprint("cnvcor", __name__)
api = Api(cnvcor)

model_cnvcortable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "cancertype": fields.String(attribute="cancertype"),
    "spm": fields.Float(attribute="spm"),
    "fdr": fields.Float(attribute="fdr"),
}


class CnvCorTable(Resource):
    @marshal_with(model_cnvcortable)
    def post(self):
        args = request.get_json()
        condition = {"symbol": {"$in": args["validSymbol"]}}
        output = {"_id": 0}
        res = list()
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_cnv_cor_expr")
                res.append(m)
        return res


api.add_resource(CnvCorTable, "/cnvcortable")


class CnvCorPlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="cnvcorplot", rplot="cnv_cor_profile.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return {"cnvcorplotuuid": res["uuid"]}


api.add_resource(CnvCorPlot, "/cnvcorplot")


class CnvCorSingleGene(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="cnvcorsinglegene", rplot="cnv_cor_singlegene.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return {"cnvcorsinglegeneuuid": res["uuid"]}


api.add_resource(CnvCorSingleGene, "/cnvcorsinglegene")
