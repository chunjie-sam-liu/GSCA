from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from gsca.utils.checkplot import CheckParallelPlot, CheckPlot, CheckMultiplePlot, CheckTablePlot
from gsca.utils.checktable import CheckTableGSVA

geneset = Blueprint("geneset", __name__)
api = Api(geneset)


class GSVAAnalysis(Resource):
    def post(self):
        args = request.get_json()

        checktable = CheckTableGSVA(args=args)
        res = checktable.check_run()
        if res["run"]:
            checktable.analysis()

        table_uuidname = res["uuid"]
        uuidnames = {"tableuuid": table_uuidname}
        return uuidnames


api.add_resource(GSVAAnalysis, "/analysis")


class ExprGSVAPlot(Resource):
    def post(self):
        args = request.get_json()

        return args


api.add_resource(ExprGSVAPlot, "/gsvaplot")

