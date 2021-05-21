from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from pathlib import Path
import subprocess
import uuid
from gsca.utils.checkplot import CheckPlot, CheckUUIDPlot, CheckGSVASurvivalSingleCancerType
from gsca.utils.check_survivalPlot import CheckSurvivalPlot

immunesnv = Blueprint("immunesnv", __name__)
api = Api(immunesnv)

model_immsnvcortable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "cancertype": fields.String(attribute="cancertype"),
    "cell_type": fields.String(attribute="cell_type"),
    "logfc": fields.Float(attribute="logfc"),
    "fdr": fields.Float(attribute="fdr"),
    "p_value": fields.Float(attribute="p_value"),
}


class ImmSnvCorTable(Resource):
    @marshal_with(model_immsnvcortable)
    def post(self):
        args = request.get_json()
        condition = {"symbol": {"$in": args["validSymbol"]}}
        output = {"_id": 0}
        res = list()
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_immune_cor_snv")
                res.append(m)
        return res


api.add_resource(ImmSnvCorTable, "/immsnvcortable")


class ImmSnvCorPlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="immsnvcorplot", rplot="immsnv_cor_profile.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return {"immsnvcorplotuuid": res["uuid"]}


api.add_resource(ImmSnvCorPlot, "/immsnvcorplot")


class ImmSnvCorSingleGene(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckSurvivalPlot(args=args, purpose="immsnvcorsinglegene", rplot="immsnv_cor_singlegene.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return {"immsnvcorsinglegeneuuid": res["uuid"]}


api.add_resource(ImmSnvCorSingleGene, "/immsnvcorsinglegene")


class SnvImmGenesetCorPlot(Resource):
    def get(self, uuidname):
        checkplot = CheckUUIDPlot(
            gsxa_uuid=uuidname,
            name_uuid="gsva_uuid",
            purpose="snvimmunegenesetcorplot",
            rplot="snv_geneset_immune_profile.R",
            precol="preanalysised",
            gsxacol="preanalysised_snvgeneset",
        )
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot()

        return {"snvimmunegenesetcorplotuuid": res["uuid"], "snvimmunegenesetcortableuuid": uuidname}


api.add_resource(SnvImmGenesetCorPlot, "/immsnvgenesetcorplot/<string:uuidname>")


class ImmSnvGenesetCorSingleGene(Resource):
    def get(self, uuidname, cancertype, surType):
        checkplot = CheckGSVASurvivalSingleCancerType(
            gsxa_uuid=uuidname,
            cancertype=cancertype,
            surType=surType,
            name_uuid="snvgenesetsurvivalsinglecancer_uuid",
            purpose="snvgenesetimmunesinglecancer",
            rplot="snv_geneset_immune_singlecancer.R",
            precol="preanalysised",
            gsxacol="preanalysised_snvgeneset",
        )
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot()

        return {"immgenesetsnvcorsinglegeneuuid": res["uuid"]}


api.add_resource(
    ImmSnvGenesetCorSingleGene, "/immsnvgenesetcorsinglegeneplot/<string:uuidname>/<string:cancertype>/<string:surType>"
)

