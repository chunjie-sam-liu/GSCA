from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from gsca.utils.checkplot import CheckPlot

subtype = Blueprint("subtype", __name__)
api = Api(subtype)

model_subtypetable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "pval": fields.Float(attribute="pval"),
    "fdr": fields.Float(attribute="fdr"),
    "cancertype": fields.String(attribute="cancertype"),
}


class SubtypeTable(Resource):
    @marshal_with(model_subtypetable)
    def post(self):
        args = request.get_json()
        condition = {"symbol": {"$in": args["validSymbol"]}}
        output = {"_id": 0}
        res = list()
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_expr_subtype")
                res.append(m)
        return res


api.add_resource(SubtypeTable, "/subtypetable")


class SubtypePlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="subtypeplot", rplot="exp_subtypeplot_profile.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")


api.add_resource(SubtypePlot, "/subtypeplot")


class SubtypePlotSingleGene(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="subtypeplotsinglegene", rplot="subtypeplot_singlegene.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")


api.add_resource(SubtypePlotSingleGene, "/single/gene")
