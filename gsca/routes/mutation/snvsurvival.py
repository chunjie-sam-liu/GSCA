from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from pathlib import Path
import subprocess
import uuid
from gsca.utils.checkplot import CheckPlot

snvsurvival = Blueprint("snvsurvival", __name__)
api = Api(snvsurvival)

model_snvsurvivaltable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "sur_type": fields.String(attribute="sur_type"),
    "hr": fields.Float(attribute="HR"),
    "cox_p": fields.Float(attribute="cox_p"),
    "log_rank_p": fields.Float(attribute="log_rank_p"),
    "higher_risk_of_death": fields.String(attribute="higher_risk_of_death"),
    "cancertype": fields.String(attribute="cancertype"),
}


class SnvSurvivalTable(Resource):
    @marshal_with(model_snvsurvivaltable)
    def post(self):
        args = request.get_json()
        print(args)
        condition = {"symbol": {"$in": args["validSymbol"]}}
        print(condition)
        output = {"_id": 0}
        res = list()
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_snv_survival")
                res.append(m)
        return res


api.add_resource(SnvSurvivalTable, "/snvsurvivaltable")


class SnvSurvivalPlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="snvsurvivalplot", rplot="snv_survivalplot_profile.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")


api.add_resource(SnvSurvivalPlot, "/snvsurvivalplot")


class SnvSurvivalSingleGene(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="snvsurvivalsinglegene", rplot="snvsurvival_singlegene.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")


api.add_resource(SnvSurvivalSingleGene, "/snvsurvivalsinglegeneplot")

model_snvgenesetsurvivaltable = {
    "sur_type": fields.String(attribute="sur_type"),
    "hr": fields.Float(attribute="HR"),
    "cox_p": fields.Float(attribute="cox_p"),
    "log_rank_p": fields.Float(attribute="log_rank_p"),
    "higher_risk_of_death": fields.String(attribute="higher_risk_of_death"),
    "cancertype": fields.String(attribute="cancertype"),
}


class SnvGenesetSurvivalTable(Resource):
    @marshal_with(model_snvgenesetsurvivaltable)
    def post(self):
        args = request.get_json()
        condition = {"cancertype": {"$in": args["cancerTypeSelected"]}}
        output = {"_id": 0}
        res = list()
        mcur = mongo.db["snv_geneset_survival"].find(condition, output)
        return res


api.add_resource(SnvSurvivalTable, "/snvgenesetsurvivaltable")


class SnvSurvivalGenesetPlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="snvsurvivalgenesetplot", rplot="snv_geneset_survival_profile.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")


api.add_resource(SnvSurvivalSingleGene, "/snvsurvivalgenesetplot")
