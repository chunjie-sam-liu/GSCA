from gsca.utils.checkplot import CheckGSEAPlotSingleCancerType, CheckUUIDPlot
from gsca.utils.checktable import CheckTableGSXA
from flask import Blueprint, request
from flask_restful import Api, Resource
from gsca.db import mongo

paen = Blueprint("paen", __name__)
api = Api(paen)


class PaenAnalysis(Resource):
    def post(self):
        args = request.get_json()
        checktable = CheckTableGSXA(
            args=args,
            purpose="PaenTable",
            ranalysis="pathwayEnrich.R",
            precol="preanalysised",
            gsxacol="preanalysised_enrichment",
        )
        res = checktable.check_run()
        if res["run"]:
            checktable.analysis()
        table_uuidname = res["uuid"]
        return {"uuidname": table_uuidname}


api.add_resource(PaenAnalysis, "/paenanalysis")


class PaenTable(Resource):
    def get(self, coll, uuidname):
        mcur = mongo.db[coll].find_one({"uuid": uuidname}, {"uuid": 0, "_id": 0})
        if mcur:
            return mcur["enrichment"]
        else:
            return {"Error": "Resource not exists."}


api.add_resource(PaenTable, "/<string:coll>/<string:uuidname>")


class ExprPaenPlot(Resource):
    def get(self, uuidname):
        checkplot = CheckUUIDPlot(
            gsxa_uuid=uuidname,
            name_uuid="gsea_uuid",
            purpose="paenplot",
            rplot="paen_plot.R",
            precol="preanalysised",
            gsxacol="preanalysised_enrichment",
        )
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot()
        return {"paenplotuuid": res["uuid"], "paentableuuid": uuidname}


api.add_resource(ExprPaenPlot, "/paenplot/<string:uuidname>")
