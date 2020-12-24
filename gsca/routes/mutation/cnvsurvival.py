from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from pathlib import Path, PurePath
import subprocess
import uuid
from gsca.utils.checkplot import CheckPlot, CheckUUIDPlot, CheckGSVASurvivalSingleCancerType
from gsca.utils.check_survivalPlot import CheckSurvivalPlot
from gsca.utils.checktable import CheckTableGSXA

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
        return {"cnvsurvivalplotuuid": res["uuid"]}


api.add_resource(CnvSurvivalPlot, "/cnvsurvivalplot")


class CnvSurvivalSingleGene(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckSurvivalPlot(args=args, purpose="cnvsurvivalsinglegene", rplot="cnvsurvival_singlegene.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return {"cnvsurvivalsinglegeneuuid": res["uuid"]}


api.add_resource(CnvSurvivalSingleGene, "/cnvsurvivalsinglegeneplot")

model_cnvgenesetsurvivaltable = {
    "sur_type": fields.String(attribute="sur_type"),
    "log_rank_p": fields.Float(attribute="log_rank_p"),
    "cancertype": fields.String(attribute="cancertype"),
}


class GeneSetCNVAnalysis(Resource):
    def post(self):
        args = request.get_json()
        checktable = CheckTableGSXA(
            args=args,
            purpose="CNVGeneSetTable",
            ranalysis="cnv_geneset.R",
            precol="preanalysised",
            gsxacol="preanalysised_cnvgeneset",
        )
        res = checktable.check_run()
        if res["run"]:
            checktable.analysis()
        table_uuidname = res["uuid"]
        return {"uuidname": table_uuidname}


api.add_resource(GeneSetCNVAnalysis, "/cnvgeneset")


class CnvGenesetSurvivalPlot(Resource):
    def get(self, uuidname):
        checkplot = CheckUUIDPlot(
            gsxa_uuid=uuidname,
            name_uuid="gsva_uuid",
            purpose="cnvsurvivalgenesetplot",
            rplot="cnv_geneset_survival_profile.R",
            precol="preanalysised",
            gsxacol="preanalysised_cnvgeneset",
        )
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot()

        return {"cnvsurvivalgenesetplotuuid": res["uuid"], "cnvsurvivalgenesettableuuid": uuidname}


api.add_resource(CnvGenesetSurvivalPlot, "/cnvgenesetsurvivalplot/<string:uuidname>")


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
        return res["res"]


api.add_resource(CnvGenesetSurvivalTable, "/cnvgenesetsurvivaltable")


class CnvGenesetSurvivalSingleCancer(Resource):
    def get(self, uuidname, cancertype, surType):
        checkplot = CheckGSVASurvivalSingleCancerType(
            gsxa_uuid=uuidname,
            cancertype=cancertype,
            surType=surType,
            name_uuid="cnvgenesetsurvivalsinglecancer_uuid",
            purpose="cnvgenesetsurvivalsinglecancer",
            rplot="cnv_geneset_survival_singlecancer.R",
            precol="preanalysised",
            gsxacol="preanalysised_cnvgeneset",
        )
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot()

        return {"cnvgenesetsurvivalsinglecanceruuid": res["uuid"]}


api.add_resource(
    CnvGenesetSurvivalSingleCancer, "/cnvgenesetsurvivalsinglecancer/<string:uuidname>/<string:cancertype>/<string:surType>"
)

