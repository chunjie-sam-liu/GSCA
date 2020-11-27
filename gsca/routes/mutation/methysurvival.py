from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from pathlib import Path
import subprocess
import uuid
from gsca.utils.checkplot import CheckPlot, CheckParallelPlot

methysurvival = Blueprint("methysurvival", __name__)
api = Api(methysurvival)
model_methysurvivaltable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "cancertype": fields.String(attribute="cancertype"),
    "log_rank_p": fields.Float(attribute="log_rank_p"),
    "cox_p": fields.Float(attribute="cox_p"),
    "HR": fields.Float(attribute="HR"),
    "higher_risk_of_death": fields.String(attribute="higher_risk_of_death"),
}


class MethySurvivalTable(Resource):
    @marshal_with(model_methysurvivaltable)
    def post(self):
        args = request.get_json()
        condition = {"symbol": {"$in": args["validSymbol"]}}
        output = {"_id": 0}
        res = list()
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_methy_survival")
                res.append(m)
        return res


api.add_resource(MethySurvivalTable, "/methysurvivaltable")


class MethySurvivalPlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="methysurvivalplot", rplot="methy_survival_profile.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")


api.add_resource(MethySurvivalPlot, "/methysurvivalplot")


class MethySurvivalSingleGene(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="methysurvivalsinglegene", rplot="methy_survival_singlegene.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")


api.add_resource(MethySurvivalSingleGene, "/methysurvivalsinglegene")
