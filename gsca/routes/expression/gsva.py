from flask import Blueprint, request
from flask_restful import Api, Resource
from gsca.utils.checkplot import CheckUUIDPlot
from gsca.utils.checktable import CheckTableGSXA

gsva = Blueprint("gsva", __name__)
api = Api(gsva)


class GSVAAnalysis(Resource):
    def post(self):
        args = request.get_json()
        checktable = CheckTableGSXA(
            args=args, purpose="GSVATable", ranalysis="expr_gsva.R", precol="preanalysised", gsxacol="preanalysised_gsva"
        )
        res = checktable.check_run()
        print(res)
        if res["run"]:
            checktable.analysis()
        table_uuidname = res["uuid"]
        return {"uuidname": table_uuidname}


api.add_resource(GSVAAnalysis, "/gsvaanalysis")


class ExprGSVAPlot(Resource):
    def get(self, uuidname):
        checkplot = CheckUUIDPlot(
            gsxa_uuid=uuidname,
            name_uuid="gsva_uuid",
            purpose="exprgsvaplot",
            rplot="expr_gsva_plot.R",
            precol="preanalysised",
            gsxacol="preanalysised_gsva",
        )
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot()

        return {"exprgsvaplotuuid": res["uuid"], "exprgsvatableuuid": uuidname}


api.add_resource(ExprGSVAPlot, "/exprgsvaplot/<string:uuidname>")

