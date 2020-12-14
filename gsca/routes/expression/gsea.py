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
        print(res)
        if res["run"]:
            checktable.analysis()
        table_uuidname = res["uuid"]
        return {"uuidname": table_uuidname}


api.add_resource(GSEAAnalysis, "/gseaanalysis")
