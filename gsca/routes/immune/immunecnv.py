from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from pathlib import Path
import subprocess
import uuid
from gsca.utils.checkplot import CheckPlot, CheckUUIDPlot, CheckGSVASurvivalSingleCancerType
from gsca.utils.check_survivalPlot import CheckSurvivalPlot

immunecnv = Blueprint("immunecnv", __name__)
api = Api(immunecnv)

model_immcnvcortable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "cancertype": fields.String(attribute="cancertype"),
    "cell_type": fields.String(attribute="cell_type"),
    "cor": fields.Float(attribute="cor"),
    "fdr": fields.Float(attribute="fdr"),
    "p_value": fields.Float(attribute="p_value"),
}


class ImmCnvCorTable(Resource):
    @marshal_with(model_immcnvcortable)
    def post(self):
        args = request.get_json()
        condition = {"symbol": {"$in": args["validSymbol"]}}
        output = {"_id": 0}
        res = list()
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_immune_cor_cnv")
                res.append(m)
        return res


api.add_resource(ImmCnvCorTable, "/immcnvcortable")


class ImmCnvCorPlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="immcnvcorplot", rplot="immcnv_cor_profile.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return {"immcnvcorplotuuid": res["uuid"]}


api.add_resource(ImmCnvCorPlot, "/immcnvcorplot")


class ImmCnvCorSingleGene(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckSurvivalPlot(args=args, purpose="immcnvcorsinglegene", rplot="immcnv_cor_singlegene.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return {"immcnvcorsinglegeneuuid": res["uuid"]}


api.add_resource(ImmCnvCorSingleGene, "/immcnvcorsinglegene")


class CnvImmGenesetCorPlot(Resource):
    def get(self, uuidname):
        checkplot = CheckUUIDPlot(
            gsxa_uuid=uuidname,
            name_uuid="gsva_uuid",
            purpose="cnvimmunegenesetcorplot",
            rplot="cnv_geneset_immune_profile.R",
            precol="preanalysised",
            gsxacol="preanalysised_cnvgeneset",
        )
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot()

        return {"cnvimmunegenesetcorplotuuid": res["uuid"], "cnvimmunegenesetcortableuuid": uuidname}


api.add_resource(CnvImmGenesetCorPlot, "/immcnvgenesetcorplot/<string:uuidname>")


class ImmCnvGenesetCorSingleGene(Resource):
    def get(self, uuidname, cancertype, surType):
        checkplot = CheckGSVASurvivalSingleCancerType(
            gsxa_uuid=uuidname,
            cancertype=cancertype,
            surType=surType,
            name_uuid="cnvgenesetsurvivalsinglecancer_uuid",
            purpose="cnvgenesetimmunesinglecancer",
            rplot="cnv_geneset_immune_singlecancer.R",
            precol="preanalysised",
            gsxacol="preanalysised_cnvgeneset",
        )
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot()

        return {"immgenesetcnvcorsinglegeneuuid": res["uuid"]}


api.add_resource(
    ImmCnvGenesetCorSingleGene, "/immcnvgenesetcorsinglegeneplot/<string:uuidname>/<string:cancertype>/<string:surType>"
)

