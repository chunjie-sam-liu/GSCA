from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from gsca.utils.checkplot import CheckParallelPlot, CheckPlot, CheckMultiplePlot
from gsca.utils.checktable import CheckTable

deg = Blueprint("deg", __name__)
api = Api(deg)

model_degtable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "normal": fields.Float(attribute="normal"),
    "tumor": fields.Float(attribute="tumor"),
    "fc": fields.Float(attribute="fc"),
    "fdr": fields.Float(attribute="fdr"),
    "n_normal": fields.Float(attribute="n_normal"),
    "n_tumor": fields.Float(attribute="n_tumor"),
    "cancertype": fields.String(attribute="cancertype"),
}


class DEGTable(Resource):
    @marshal_with(model_degtable)
    def post(self):
        args = request.get_json()
        condition = {"symbol": {"$in": args["validSymbol"]}}
        output = {"_id": 0}
        res = list()
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_deg")
                res.append(m)
        return res


api.add_resource(DEGTable, "/degtable")


class DEGPlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="degplot", rplot="degplot.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return {"degplotuuid": res["uuid"]}


api.add_resource(DEGPlot, "/degplot")


class DEGPlotSingleGene(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="degplotsinglegene", rplot="degplotsinglegene.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        # return send_file(str(res["filepath"]), mimetype="image/png")
        return {"degplotsinglegeneuuid": res["uuid"]}


api.add_resource(DEGPlotSingleGene, "/degplot/single/gene")


class DEGPlotSingleCancerType(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="degplotsinglecancertype", rplot="degplotsinglecancertype.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        # return send_file(str(res["filepath"]), mimetype="image/png")
        return {"degplotsinglecancertypeuuid": res["uuid"]}


api.add_resource(DEGPlotSingleCancerType, "/degplot/single/cancertype")


class DegGsvaTable(Resource):
    def post(self):
        args = request.get_json()
        checktable = CheckTable(args=args, purpose="deggsva", rtable="deg_gsva.R")
        res = checktable.check_run()
        if res["run"]:
            checktable.table(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="table/tsv")


api.add_resource(DegGsvaTable, "/deggsva")


class testMultiplePlot(Resource):
    def post(self):
        args = request.get_json()
        purposes = ("testa", "testb")
        rplots = ("testa.R", "testb.R")
        checkplot = CheckMultiplePlot(args=args, purposes=purposes, rplots=rplots)
        check_run = checkplot.check_run()
        for purpose, res in check_run.items():
            if res["run"]:
                checkplot.plot(filepath=res["filepath"], rplot=res["rplot"])

        uuidnames = {purpose + "uuid": check_run[purpose]["uuid"] for purpose in purposes}
        return uuidnames


api.add_resource(testMultiplePlot, "/testMultiplePlot")


class testParallelPlot(Resource):
    def post(self):
        args = request.get_json()
        purposes = ("testaparallelplot", "testbparallelplot")
        rplot = "testc.R"
        checkplot = CheckParallelPlot(args=args, purposes=purposes, rplot=rplot)
        check_run = checkplot.check_run()
        if any([res["run"] for res in check_run.values()]):
            filepaths = [str(check_run[purpose]["filepath"]) for purpose in purposes]
            checkplot.plot(filepaths=filepaths)
        uuidnames = {purpose + "uuid": check_run[purpose]["uuid"] for purpose in purposes}
        # return uuidnames
        return uuidnames


api.add_resource(testParallelPlot, "/testParallelPlot")
