from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from gsca.utils.checkplot import CheckPlot
from gsca.utils.check_survivalPlot import CheckSurvivalPlot

ctrp = Blueprint("ctrp", __name__)
api = Api(ctrp)

model_ctrptable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "fdr": fields.Float(attribute="fdr"),
    "drug": fields.String(attribute="drug"),
    "cor": fields.Float(attribute="cor"),
}


class CTRPTable(Resource):
    @marshal_with(model_ctrptable)
    def post(self):
        args = request.get_json()
        condition = {"symbol": {"$in": args["validSymbol"]}}
        output = {"_id": 0}
        res = list()
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_ctrp_cor_expr")
                res.append(m)
        return res


api.add_resource(CTRPTable, "/ctrptable")


class CTRPPlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="ctrpplot", rplot="ctrpplot_profile.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        # return send_file(str(res["filepath"]), mimetype="image/png")
        return {"ctrpplotuuid": res["uuid"]}


api.add_resource(CTRPPlot, "/ctrpplot")


class CTRPSingleGenePlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckSurvivalPlot(args=args, purpose="ctrpsinglegene", rplot="ctrpplot_singlegene.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        # return send_file(str(res["filepath"]), mimetype="image/png")
        return {"ctrpsinglegeneuuid": res["uuid"]}


api.add_resource(CTRPSingleGenePlot, "/single/gene")
