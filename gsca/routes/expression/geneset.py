from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from gsca.utils.checkplot import CheckParallelPlot, CheckPlot, CheckMultiplePlot, CheckTablePlot, CheckUUIDPlot
from gsca.utils.checktable import CheckTableGSVA

geneset = Blueprint("geneset", __name__)
api = Api(geneset)


class GSVAAnalysis(Resource):
    def post(self):
        args = request.get_json()
        checktable = CheckTableGSVA(args=args)
        res = checktable.check_run()
        print(res)
        if res["run"]:
            checktable.analysis()
        table_uuidname = res["uuid"]
        return {"uuidname": table_uuidname}


api.add_resource(GSVAAnalysis, "/gsvaanalysis")


class ExprGSVAPlot(Resource):
    def get(self, uuidname):
        print(uuidname)
        checkplot = CheckUUIDPlot(gsva_uuid=uuidname, purpose="exprgsvaplot", rplot="expr_gsva_plot.R")
        res = checkplot.check_run()
        print(res)
        if res["run"]:
            checkplot.plot()

        return {"exprgsvaplotuuid": res["uuid"], "exprgsvatableuuid": uuidname}


api.add_resource(ExprGSVAPlot, "/exprgsvaplot/<string:uuidname>")

