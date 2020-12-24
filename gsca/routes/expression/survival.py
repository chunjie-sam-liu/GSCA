from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from gsca.utils.checkplot import CheckPlot
from gsca.utils.check_survivalPlot import CheckSurvivalPlot

survival = Blueprint("survival", __name__)
api = Api(survival)

model_survivaltable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "hr_categorical(H/L)": fields.Float(attribute="hr_categorical(H/L)"),
    "coxp_categorical": fields.Float(attribute="coxp_categorical"),
    "logrankp": fields.Float(attribute="logrankp"),
    "higher_risk_of_death": fields.String(attribute="higher_risk_of_death"),
    "cancertype": fields.String(attribute="cancertype"),
    "sur_type": fields.String(attribute="sur_type"),
}


class SurvivalTable(Resource):
    @marshal_with(model_survivaltable)
    def post(self):
        args = request.get_json()
        condition = {"symbol": {"$in": args["validSymbol"]}}
        output = {"_id": 0}
        res = list()
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_expr_survival")
                res.append(m)
        return res


api.add_resource(SurvivalTable, "/survivaltable")


class SurvivalPlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="survivalplot", rplot="exp_survivalplot_profile.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return {"survivalplotuuid": res["uuid"]}


api.add_resource(SurvivalPlot, "/survivalplot")


class SurvivalSingleGenePlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckSurvivalPlot(args=args, purpose="survivalsinglegene", rplot="survivalplotsinglegene.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return {"survivalsinglegeneuuid": res["uuid"]}


api.add_resource(SurvivalSingleGenePlot, "/single/gene")
