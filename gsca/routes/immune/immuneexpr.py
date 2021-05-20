from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from pathlib import Path
import subprocess
import uuid
from gsca.utils.check_survivalPlot import CheckSurvivalPlot
from gsca.utils.checkplot import (
    CheckPlot,
    CheckUUIDPlot,
    CheckGSVASurvivalSingleCancerType,
    CheckGSEAPlotSingleCancerType,
    CheckParalleUUIDPlot,
)

immuneexpr = Blueprint("immuneexpr", __name__)
api = Api(immuneexpr)

model_immexprcortable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "cancertype": fields.String(attribute="cancertype"),
    "cell_type": fields.String(attribute="cell_type"),
    "cor": fields.Float(attribute="cor"),
    "fdr": fields.Float(attribute="fdr"),
    "p_value": fields.Float(attribute="p_value"),
}


class ImmExprCorTable(Resource):
    @marshal_with(model_immexprcortable)
    def post(self):
        args = request.get_json()
        condition = {"symbol": {"$in": args["validSymbol"]}}
        output = {"_id": 0}
        res = list()
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_immune_cor_expr")
                res.append(m)
        return res


api.add_resource(ImmExprCorTable, "/immexprcortable")


class ImmExprCorPlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="immexprcorplot", rplot="immexpr_cor_profile.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return {"immexprcorplotuuid": res["uuid"]}


api.add_resource(ImmExprCorPlot, "/immexprcorplot")


class ImmExprCorSingleGene(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckSurvivalPlot(args=args, purpose="immexprcorsinglegene", rplot="immexpr_cor_singlegene.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return {"immexprcorsinglegeneuuid": res["uuid"]}


api.add_resource(ImmExprCorSingleGene, "/immexprcorsinglegene")

""" GSVA immune"""


class ImmuGSVAPlot(Resource):
    def get(self, uuidname):
        checkplot = CheckUUIDPlot(
            gsxa_uuid=uuidname,
            name_uuid="immu_uuid",
            purpose="immugsva",
            rplot="immu_gsva.R",
            precol="preanalysised",
            gsxacol="preanalysised_gsva",
        )
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot()

        return {"immugsvaplotuuid": res["uuid"], "immugsvatableuuid": uuidname}


api.add_resource(ImmuGSVAPlot, "/immugsva/<string:uuidname>")


class GSVAImmuSingleCellImage(Resource):
    def get(self, uuidname, cancertype, surType):
        checkplot = CheckGSVASurvivalSingleCancerType(
            gsxa_uuid=uuidname,
            cancertype=cancertype,
            surType=surType,
            name_uuid="gsvaimmusinglecell_uuid",
            purpose="gsvaimmusinglecell",
            rplot="gsva_immu_single_cell.R",
            precol="preanalysised",
            gsxacol="preanalysised_gsva",
        )
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot()

        return {"gsvaimmusinglecelluuid": res["uuid"]}


api.add_resource(GSVAImmuSingleCellImage, "/immugsva/singlecell/<string:uuidname>/<string:cancertype>/<string:surType>")

