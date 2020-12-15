from flask import Blueprint, request
from flask_restful import Api, Resource
from gsca.utils.checkplot import CheckUUIDPlot, CheckGSVASurvivalSingleCancerType
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


class ExprSurvivalGSVAPlot(Resource):
    def get(self, uuidname):
        checkplot = CheckUUIDPlot(
            gsxa_uuid=uuidname,
            name_uuid="gsva_uuid",
            purpose="exprsurvivalgsva",
            rplot="expr_survival_gsva.R",
            precol="preanalysised",
            gsxacol="preanalysised_gsva",
        )
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot()

        return {"exprsurvivalgsvaplotuuid": res["uuid"], "exprsurvivalgsvatableuuid": uuidname}


api.add_resource(ExprSurvivalGSVAPlot, "/exprsurvivalgsva/<string:uuidname>")


class GSVASurvivalSingleCancerImage(Resource):
    def get(self, uuidname, cancertype, sur_Type):
        checkplot = CheckGSVASurvivalSingleCancerType(
            gsxa_uuid=uuidname,
            cancertype=cancertype,
            sur_Type=sur_Type,
            name_uuid="gsvasurvivalsinglecancer_uuid",
            purpose="gsvasurvivalsinglecancer",
            rplot="gsva_survival_single_cancer.R",
            precol="preanalysised",
            gsxacol="preanalysised_gsva",
        )
        res = checkplot.check_run()
        if res["run"]:
            checkplot.plot()

        return {"gsvasurvivalsinglecanceruuid": res["uuid"]}


api.add_resource(
    GSVASurvivalSingleCancerImage, "/survival/singlecancer/<string:uuidname>/<string:cancertype>/<string:sur_Type>"
)
