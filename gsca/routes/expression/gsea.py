from gsca.utils.checkplot import CheckGSEAPlotSingleCancerType, CheckUUIDPlot
from gsca.utils.checktable import CheckTableGSXA
from flask import Blueprint, request
from flask_restful import Api, Resource

gsea = Blueprint("gsea", __name__)
api = Api(gsea)


class GSEAAnalysis(Resource):
    def post(self):
        args = request.get_json()
        checktable = CheckTableGSXA(
            args=args, purpose="GSEATable", ranalysis="expr_gsea.R", precol="preanalysised", gsxacol="preanalysised_gsea"
        )
        res = checktable.check_run()
        if res["run"]:
            checktable.analysis()
        table_uuidname = res["uuid"]
        return {"uuidname": table_uuidname}


api.add_resource(GSEAAnalysis, "/gseaanalysis")


class ExprGSEAPlot(Resource):
    def get(self, uuidname):
        checkplot = CheckUUIDPlot(
            gsxa_uuid=uuidname,
            name_uuid="gsea_uuid",
            purpose="exprgseaplot",
            rplot="expr_gsea_plot.R",
            precol="preanalysised",
            gsxacol="preanalysised_gsea",
        )
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot()
        return {"exprgseaplotuuid": res["uuid"], "exprgseatableuuid": uuidname}


api.add_resource(ExprGSEAPlot, "/exprgseaplot/<string:uuidname>")


class GSEAPlotSingleCancerType(Resource):
    def get(self, uuidname, cancertype):
        checkplot = CheckGSEAPlotSingleCancerType(
            gsxa_uuid=uuidname,
            name_uuid="gseasinglecancertype_uuid",
            cancertype=cancertype,
            purpose="gseasinglecancertype",
            rplot="expr_gsea_plot_single_cancertype.R",
            precol="preanalysised",
            gsxacol="preanalysised_gsea",
        )
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot()
        return {"gseaplotsinglecancertypeuuid": res["uuid"]}


api.add_resource(GSEAPlotSingleCancerType, "/single/cancertype/<string:uuidname>/<string:cancertype>")
