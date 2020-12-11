from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from gsca.utils.checkplot import CheckParallelPlot, CheckPlot, CheckMultiplePlot, CheckTablePlot

geneset = Blueprint("geneset", __name__)
api = Api(geneset)


class GeneSetTable(Resource):
    def post(self):
        args = request.get_json()
        checkplot = CheckTablePlot(args=args, purpose="expr_geneset", ranalysis="expr_geneset.R")
        res = checkplot.check_run()
        if res["run"]:
            checkplot.analysis(uuidname=res["table_uuidname"], filepath=res["plot_filepath"])

        uuidnames = {"tableuuid": res["table_uuidname"], "plotuuid": res["plot_uuidname"]}

        return uuidnames


api.add_resource(GeneSetTable, "/analysis")
