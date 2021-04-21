from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from gsca.utils.checkplot import CheckPlot, CheckParallelPlot
from gsca.utils.check_survivalPlot import CheckSurvivalPlot

rppa = Blueprint("rppa", __name__)
api = Api(rppa)

model_rppatable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "fdr": fields.Float(attribute="fdr"),
    "cancertype": fields.String(attribute="cancertype"),
    "class": fields.String(attribute="class"),
    "diff": fields.String(attribute="diff"),
    "pathway": fields.String(attribute="pathway"),
}


class RPPATable(Resource):
    @marshal_with(model_rppatable)
    def post(self):
        args = request.get_json()
        condition = {"symbol": {"$in": args["validSymbol"]}}
        output = {"_id": 0}
        res = list()
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_rppa_diff")
                res.append(m)
        return res


api.add_resource(RPPATable, "/rppatable")


class RPPAPlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="rppaPoint", rplot="exp_rppaplot_profile.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        # return send_file(str(res["filepath"]), mimetype="image/png")
        return {"rppaPointuuid": res["uuid"]}


api.add_resource(RPPAPlot, "/rppaplot")


class RPPAPlotSingleGene(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckSurvivalPlot(args=args, purpose="rppasinglegene", rplot="rppaplot_singlegene.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        # return send_file(str(res["filepath"]), mimetype="image/png")
        return {"rppasinglegeneuuid": res["uuid"]}


api.add_resource(RPPAPlotSingleGene, "/single/gene")
