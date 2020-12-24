from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from pathlib import Path, PurePath
import subprocess
import uuid
from gsca.utils.checkplot import CheckPlot, CheckUUIDPlot, CheckGSVASurvivalSingleCancerType
from gsca.utils.check_survivalPlot import CheckSurvivalPlot
from gsca.utils.checktable import CheckTableGSXA

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
        condition = {"symbol": {"$in": args["validSymbol"]}}
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
        return {"snvsurvivalplotuuid": res["uuid"]}


api.add_resource(SnvSurvivalPlot, "/snvsurvivalplot")


class SnvSurvivalSingleGene(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckSurvivalPlot(args=args, purpose="snvsurvivalsinglegene", rplot="snvsurvival_singlegene.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return {"snvsurvivalsinglegeneuuid": res["uuid"]}


api.add_resource(SnvSurvivalSingleGene, "/snvsurvivalsinglegeneplot")

model_snvgenesetsurvivaltable = {
    "sur_type": fields.String(attribute="sur_type"),
    "hr": fields.Float(attribute="HR"),
    "cox_p": fields.Float(attribute="cox_p"),
    "log_rank_p": fields.Float(attribute="log_rank_p"),
    "higher_risk_of_death": fields.String(attribute="higher_risk_of_death"),
    "cancertype": fields.String(attribute="cancertype"),
}


class GeneSetSNVAnalysis(Resource):
    def post(self):
        args = request.get_json()
        checktable = CheckTableGSXA(
            args=args,
            purpose="SNVGeneSetTable",
            ranalysis="snv_geneset.R",
            precol="preanalysised",
            gsxacol="preanalysised_snvgeneset",
        )
        res = checktable.check_run()
        if res["run"]:
            checktable.analysis()
        table_uuidname = res["uuid"]
        return {"uuidname": table_uuidname}


api.add_resource(GeneSetSNVAnalysis, "/snvgeneset")


class SnvGenesetSurvivalPlot(Resource):
    def get(self, uuidname):
        checkplot = CheckUUIDPlot(
            gsxa_uuid=uuidname,
            name_uuid="gsva_uuid",
            purpose="snvsurvivalgenesetplot",
            rplot="snv_geneset_survival_profile.R",
            precol="preanalysised",
            gsxacol="preanalysised_snvgeneset",
        )
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot()

        return {"snvsurvivalgenesetplotuuid": res["uuid"], "snvsurvivalgenesettableuuid": uuidname}


api.add_resource(SnvGenesetSurvivalPlot, "/snvgenesetsurvivalplot/<string:uuidname>")


class SnvGenesetSurvivalTable(Resource):
    def post(self):
        args = request.get_json()
        condition = {
            "search": "#".join(args["validSymbol"]),
            "coll": "#".join(args["validColl"]),
            "purpose": "snv_geneset_survival",
        }
        output = {"_id": 0, "res": 1}
        res = mongo.db.snv_geneset_survival.find_one(condition, output)
        return res["res"]


api.add_resource(SnvGenesetSurvivalTable, "/snvgenesetsurvivaltable")


class SnvGenesetSurvivalSingleCancer(Resource):
    def get(self, uuidname, cancertype, surType):
        checkplot = CheckGSVASurvivalSingleCancerType(
            gsxa_uuid=uuidname,
            cancertype=cancertype,
            surType=surType,
            name_uuid="snvgenesetsurvivalsinglecancer_uuid",
            purpose="snvgenesetsurvivalsinglecancer",
            rplot="snv_geneset_survival_singlecancer.R",
            precol="preanalysised",
            gsxacol="preanalysised_snvgeneset",
        )
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot()

        return {"snvgenesetsurvivalsinglecanceruuid": res["uuid"]}


api.add_resource(
    SnvGenesetSurvivalSingleCancer, "/snvgenesetsurvivalsinglecancer/<string:uuidname>/<string:cancertype>/<string:surType>"
)

