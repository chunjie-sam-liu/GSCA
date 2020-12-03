from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from pathlib import Path
import subprocess
import uuid
from gsca.utils.checkplot import CheckPlot

immunemethy = Blueprint("immunemethy", __name__)
api = Api(immunemethy)

model_immmethycortable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "cancertype": fields.String(attribute="cancertype"),
    "cell_type": fields.String(attribute="cell_type"),
    "cor": fields.Float(attribute="cor"),
    "fdr": fields.Float(attribute="fdr"),
    "p_value": fields.Float(attribute="p_value"),
}


class ImmMethyCorTable(Resource):
    @marshal_with(model_immmethycortable)
    def post(self):
        args = request.get_json()
        condition = {"symbol": {"$in": args["validSymbol"]}}
        output = {"_id": 0}
        res = list()
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_immune_cor_methy")
                res.append(m)
        return res


api.add_resource(ImmMethyCorTable, "/immmethycortable")


class ImmMethyCorPlot(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="immmethycorplot", rplot="immmethy_cor_profile.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")


api.add_resource(ImmMethyCorPlot, "/immmethycorplot")


class ImmMethyCorSingleGene(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckPlot(args=args, purpose="immmethycorsinglegene", rplot="immmethy_cor_singlegene.R")
        res = checkplot.check_run()

        if res["run"]:
            checkplot.plot(filepath=res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")


api.add_resource(ImmMethyCorSingleGene, "/immmethycorsinglegene")
