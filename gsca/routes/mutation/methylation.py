from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from pathlib import Path
import subprocess
import uuid
from gsca.utils.checkplot import CheckPlot

methylation = Blueprint("methylation", __name__)
api = Api(methylation)

model_methydetable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "cancertype": fields.String(attribute="cancertype"),
    "fc": fields.Float(attribute="fc"),
    "gene_tag": fields.String(attribute="gene_tag"),
    "trend": fields.String(attribute="trend"),
    "pval": fields.Float(attribute="pval"),
    "logfdr": fields.Float(attribute="logfdr"),
}


class MethyDeTable(Resource):
    @marshal_with(model_methydetable)
    def post(self):
        args = request.get_json()
        condition = {"symbol": {"$in": args["validSymbol"]}}
        output = {"_id": 0}
        res = list()
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_methy_diff")
                m["logfdr"] = 10 ** -m["logfdr"]
                res.append(m)
        return res


api.add_resource(MethyDeTable, "/methylationdetable")


class MethyDePlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="singleGeneMethyDiff", rplot="methy_diff_plot.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")


api.add_resource(MethyDePlot, "/methylationdeplot")


class SingleGeneMethyDE(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="singleGeneMethyDiff", rplot="methy_diff_single_gene.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")


api.add_resource(SingleGeneMethyDE, "/singlegenemethyde")


class SingleCancerMethyDE(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="singleCancerMethyDiff", rplot="methy_diff_single_cancer.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")


api.add_resource(SingleCancerMethyDE, "/singlecancermethyde")
