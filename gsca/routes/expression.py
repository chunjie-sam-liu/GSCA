from flask import Blueprint, request
from flask import app
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from pathlib import Path
import subprocess


expression = Blueprint("expression", __name__)
api = Api(expression)

# r plot resource
apppath = Path(api.app.root_path).parent.parent
rcommand = "/usr/bin/Rscript"
rscriptpath = apppath / "gsca/rscripts"
resource_pngs = apppath / "gsca/resource/pngs"

if not resource_pngs.exists():
    resource_pngs.mkdir(parents=True)


mdoel_degtable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "normal": fields.Float(attribute="normal"),
    "tumor": fields.Float(attribute="tumor"),
    "fc": fields.Float(attribute="fc"),
    "fdr": fields.Float(attribute="fdr"),
    "n_normal": fields.Float(attribute="n_normal"),
    "n_tumor": fields.Float(attribute="n_tumor"),
    "cancertype": fields.String(attribute="cancertype"),
}


class DEGTable(Resource):
    @marshal_with(mdoel_degtable)
    def post(self):
        args = request.get_json()
        condition = {"symbol": {"$in": args["validSymbol"]}}
        output = {"_id": 0}
        res = list()
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_deg")
                res.append(m)
        return res


api.add_resource(DEGTable, "/degtable")


class DEGplot(Resource):
    def post(self):
        args = request.get_json()
        rarg = "#".join(args["validSymbol"]) + "@" + "#".join(args["validColl"])

        filename = rarg + ".png"
        filepath = resource_pngs / filename

        cmd = [rcommand, str(rscriptpath / "degplot.R"), rarg, str(filepath), str(apppath)]
        if not filepath.exists():
            subprocess.check_output(cmd, universal_newlines=True)

        print(cmd)

        return {"cj": "cj"}


api.add_resource(DEGplot, "/degplot")
