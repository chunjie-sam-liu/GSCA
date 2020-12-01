from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from pathlib import Path, PurePath
import subprocess
import uuid
from gsca.utils.checkplot import CheckPlot
from gsca.utils.check_survivalPlot import CheckSurvivalPlot

cnvsurvival = Blueprint("cnvsurvival", __name__)
api = Api(cnvsurvival)

model_cnvsurvivaltable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "sur_type": fields.String(attribute="sur_type"),
    "log_rank_p": fields.Float(attribute="log_rank_p"),
    "cancertype": fields.String(attribute="cancertype"),
}


class CnvSurvivalTable(Resource):
    @marshal_with(model_cnvsurvivaltable)
    def post(self):
        args = request.get_json()
        condition = {"symbol": {"$in": args["validSymbol"]}}
        output = {"_id": 0}
        res = list()
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_cnv_survival")
                res.append(m)
        return res


api.add_resource(CnvSurvivalTable, "/cnvsurvivaltable")


class CnvSurvivalPlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="cnvsurvivalplot", rplot="cnv_survivalplot_profile.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")


api.add_resource(CnvSurvivalPlot, "/cnvsurvivalplot")


class CnvSurvivalSingleGene(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckSurvivalPlot(args=args, purpose="cnvsurvivalsinglegene", rplot="cnvsurvival_singlegene.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")


api.add_resource(CnvSurvivalSingleGene, "/cnvsurvivalsinglegeneplot")

model_cnvgenesetsurvivaltable = {
    "sur_type": fields.String(attribute="sur_type"),
    "log_rank_p": fields.Float(attribute="log_rank_p"),
    "cancertype": fields.String(attribute="cancertype"),
}


class CnvGenesetSurvivalPlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="cnvsurvivalgeneset", rplot="cnv_geneset_survival_profile.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")


api.add_resource(CnvGenesetSurvivalPlot, "/cnvgenesetsurvivalplot")


class CnvGenesetSurvivalTable(Resource):
    def post(self):
        args = request.get_json()
        condition = {
            "search": "#".join(args["validSymbol"]),
            "coll": "#".join(args["validColl"]),
            "purpose": "cnv_geneset_survival",
        }
        output = {"_id": 0, "res": 1}
        res = mongo.db.cnv_geneset_survival.find_one(condition, output)
        print(res)
        return res["res"]


api.add_resource(CnvGenesetSurvivalTable, "/cnvgenesetsurvivaltable")


class CnvGenesetSurvivalSingleCancer(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="cnvgenesetsurvivalsinglecancer", rplot="cnv_geneset_survival_singlecancer.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")


api.add_resource(CnvGenesetSurvivalSingleCancer, "/cnvgenesetsurvivalsinglecancer")

