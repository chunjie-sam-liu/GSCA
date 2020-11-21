from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from pathlib import Path
import subprocess
import uuid
from gsca.utils.checkplot import CheckPlot

snv = Blueprint("snv", __name__)
api = Api(snv)

model_snvtable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "cancertype": fields.String(attribute="cancertype"),
    "mutated_sample_size": fields.Integer(attribute="mutated_sample_size"),
    "percentage": fields.Float(attribute="percentage"),
    "sample_size": fields.Integer(attribute="sample_size"),
    "deletion": fields.Integer(attribute="deletion"),
    "insertion": fields.Integer(attribute="insertion"),
    "SNV": fields.Integer(attribute="SNV"),
    "substitution": fields.Integer(attribute="substitution"),
}


class SnvTable(Resource):
    @marshal_with(model_snvtable)
    def post(self):
        args = request.get_json()
        condition = {"symbol": {"$in": args["validSymbol"]}}
        output = {"_id": 0}
        res = list()
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_snv_count")
                m["percentage"] = m["percentage"]
                res.append(m)
        return res


api.add_resource(SnvTable, "/snvtable")


class SnvPlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="snvplot", rplot="snvplot_profile.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")


api.add_resource(SnvPlot, "/snvplot")


class SnvLollipop(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="lollipop", rplot="snvplot_lollipop.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")


api.add_resource(SnvLollipop, "/lollipop")


class SnvSummary(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="snvsummary", rplot="snv_summary.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")


api.add_resource(SnvSummary, "/snvsummary")


class SnvOncoplot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="snvoncoplot", rplot="snv_oncoplot.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")


api.add_resource(SnvOncoplot, "/snvoncoplot")


class SnvTitv(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="snvtitv", rplot="snv_titv.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")


api.add_resource(SnvTitv, "/snvtitv")
