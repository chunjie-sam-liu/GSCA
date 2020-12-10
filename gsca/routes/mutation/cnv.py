from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from pathlib import Path
import subprocess
import uuid
from gsca.utils.checkplot import CheckPlot, CheckParallelPlot

cnv = Blueprint("cnv", __name__)
api = Api(cnv)

model_cnvtable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "cancertype": fields.String(attribute="cancertype"),
    "a_total": fields.Float(attribute="a_total"),
    "d_total": fields.Float(attribute="d_total"),
    "a_hete": fields.Float(attribute="a_hete"),
    "d_hete": fields.Float(attribute="d_hete"),
    "a_homo": fields.Float(attribute="a_homo"),
    "d_homo": fields.Float(attribute="d_homo"),
}


class CnvTable(Resource):
    @marshal_with(model_cnvtable)
    def post(self):
        args = request.get_json()
        condition = {"symbol": {"$in": args["validSymbol"]}}
        output = {"_id": 0}
        res = list()
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_cnv_percent")
                m["a_total"] = m["a_total"] * 100
                m["d_total"] = m["d_total"] * 100
                m["a_hete"] = m["a_hete"] * 100
                m["d_hete"] = m["d_hete"] * 100
                m["a_homo"] = m["a_homo"] * 100
                m["d_homo"] = m["d_homo"] * 100
                res.append(m)
        return res


api.add_resource(CnvTable, "/cnvtable")


class CnvPiePlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="cnvpieplot", rplot="cnvplot_pie_profile.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return {"cnvpieplotuuid": res["uuid"]}


api.add_resource(CnvPiePlot, "/cnvpieplot")


class CnvHomoPointImage(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="cnvhomopointplot", rplot="cnvhomo_pointplot.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return {"cnvhomopointplotuuid": res["uuid"]}


api.add_resource(CnvHomoPointImage, "/cnvhomopointplot")


class CnvHetePointImage(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="cnvhetepointplot", rplot="cnvhete_pointplot.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return {"cnvhetepointplotuuid": res["uuid"]}


api.add_resource(CnvHetePointImage, "/cnvhetepointplot")

"""
class CnvOncoplot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="cnvoncoplot", rplot="cnv_oncoplot.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return {"cnvoncoplotuuid": res["uuid"]}


api.add_resource(CnvOncoplot, "/cnconcoplot")
"""


class CnvSingleGene(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="cnvsinglegene", rplot="cnv_singlegene_oncoplot.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return {"cnvsinglegeneuuid": res["uuid"]}


api.add_resource(CnvSingleGene, "/cnvsinglegene")

