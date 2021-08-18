from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from gsca.utils.checkplot import CheckPlot, CheckParallelPlot
from gsca.utils.check_survivalPlot import CheckSurvivalPlot

stage = Blueprint("stage", __name__)
api = Api(stage)

model_stagetable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "pval": fields.Float(attribute="pval"),
    "fdr": fields.Float(attribute="fdr"),
    "cancertype": fields.String(attribute="cancertype"),
    "stagetype": fields.String(attribute="stage_type"),
    "stage1": fields.String(attribute="Stage I (mean/n)"),
    "stage2": fields.String(attribute="Stage II (mean/n)"),
    "stage3": fields.String(attribute="Stage III (mean/n)"),
    "stage4": fields.String(attribute="Stage IV (mean/n)"),
}


class StageTable(Resource):
    @marshal_with(model_stagetable)
    def post(self):
        args = request.get_json()
        condition = {"symbol": {"$in": args["validSymbol"]}}
        output = {"_id": 0}
        res = list()
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_expr_stage")
                res.append(m)
        return res


api.add_resource(StageTable, "/stagetable")


class StagePlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="stagePoint", rplot="exp_stageplot_profile.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        # return send_file(str(res["filepath"]), mimetype="image/png")
        return {"stagePointuuid": res["uuid"]}


api.add_resource(StagePlot, "/stageplot")


class StageHeatTrendPlot(Resource):
    def post(self):
        args = request.get_json()
        purposes = ("stageHeat", "stageTrend")
        checkplot = CheckParallelPlot(args=args, purposes=purposes, rplot="exp_stageHeatTrend_plot.R")
        check_run = checkplot.check_run()

        if any([res["run"] for res in check_run.values()]):
            filepaths = [str(check_run[purpose]["filepath"]) for purpose in purposes]
            checkplot.plot(filepaths=filepaths)
        # return send_file(str(res["filepath"]), mimetype="image/png")
        uuidnames = {purpose + "uuid": check_run[purpose]["uuid"] for purpose in purposes}
        return uuidnames


api.add_resource(StageHeatTrendPlot, "/stageheattrendplot")


class StagePlotSingleGene(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckSurvivalPlot(args=args, purpose="stagesinglegene", rplot="stageplot_singlegene.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        # return send_file(str(res["filepath"]), mimetype="image/png")
        return {"stagesinglegeneuuid": res["uuid"]}


api.add_resource(StagePlotSingleGene, "/single/gene")
