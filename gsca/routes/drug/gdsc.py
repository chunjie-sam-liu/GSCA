from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from gsca.utils.checkplot import CheckPlot

gdsc = Blueprint("gdsc", __name__)
api = Api(gdsc)

model_gdsctable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "fdr": fields.Float(attribute="fdr"),
    "drug": fields.String(attribute="drug"),
    "cor": fields.Float(attribute="cor"),
}


class GDSCTable(Resource):
    @marshal_with(model_gdsctable)
    def post(self):
        args = request.get_json()
        condition = {"symbol": {"$in": args["validSymbol"]}}
        output = {"_id": 0}
        res = list()
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_gdsc_cor_expr")
                res.append(m)
        return res


api.add_resource(GDSCTable, "/gdsctable")


class GDSCPlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="gdscplot", rplot="gdscplot_profile.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        # return send_file(str(res["filepath"]), mimetype="image/png")
        return {"gdscplotuuid": res["uuid"]}


api.add_resource(GDSCPlot, "/gdscplot")


class GDSCSingleGenePlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="gdscsinglegene", rplot="gdscplot_singlegene.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        # return send_file(str(res["filepath"]), mimetype="image/png")
        return {"gdscsinglegeneuuid": res["uuid"]}


api.add_resource(GDSCSingleGenePlot, "/single/gene")
