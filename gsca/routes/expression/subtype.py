from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from pathlib import Path
import subprocess
import uuid

subtype = Blueprint("subtype", __name__)
api = Api(subtype)

# r plot resource
apppath = Path(api.app.root_path).parent.parent.parent  # notice apppath parent
rcommand = "/usr/bin/Rscript"
rscriptpath = apppath / "gsca/rscripts"
resource_pngs = apppath / "gsca/resource/pngs"

if not resource_pngs.exists():
    resource_pngs.mkdir(parents=True)

model_subtypetable = {
    "entrez": fields.Integer(attribute="entrez"),
    "symbol": fields.String(attribute="symbol"),
    "pval": fields.Float(attribute="pval"),
    "fdr": fields.Float(attribute="fdr"),
    "cancertype": fields.String(attribute="cancertype"),
}


class SubtypeTable(Resource):
    @marshal_with(model_subtypetable)
    def post(self):
        args = request.get_json()
        condition = {"symbol": {"$in": args["validSymbol"]}}
        output = {"_id": 0}
        res = list()
        for collname in args["validColl"]:
            mcur = mongo.db[collname].find(condition, output)
            for m in mcur:
                m["cancertype"] = collname.rstrip("_expr_subtype")
                res.append(m)
        return res


api.add_resource(SubtypeTable, "/subtypetable")


class SubtypePlot(Resource):
    def post(self):
        args = request.get_json()
        res = self.__check_run(args=args, purpose="subtypeplot")

        if res["run"]:
            self.__subtypeplot(args, res["filepath"])
        return send_file(str(res["filepath"]), mimetype="image/png")

    def __check_run(self, args, purpose):
        uuidname = str(uuid.uuid4())
        filename = uuidname + ".png"
        filepath = resource_pngs / filename

        preanalysised = mongo.db.preanalysised.find_one(
            {"search": "#".join(args["validSymbol"]), "coll": "#".join(args["validColl"]), "purpose": purpose},
            {"_id": 0, "uuid": 1},
        )
        print(preanalysised)
        if preanalysised:
            uuidname = preanalysised["uuid"]
            filename = uuidname + ".png"
            filepath = resource_pngs / filename
            run = False if filepath.exists() else True
            return {"run": run, "filepath": filepath}
        else:
            mongo.db.preanalysised.insert_one(
                {
                    "search": "#".join(args["validSymbol"]),
                    "coll": "#".join(args["validColl"]),
                    "purpose": purpose,
                    "uuid": uuidname,
                }
            )
            return {"run": True, "filepath": filepath}

    def __subtypeplot(self, args, filepath):
        rargs = "#".join(args["validSymbol"]) + "@" + "#".join(args["validColl"])

        cmd = [rcommand, str(rscriptpath / "exp_subtypeplot_profile.R"), rargs, str(filepath), str(apppath)]
        print(cmd)
        subprocess.check_output(cmd, universal_newlines=True)


api.add_resource(SubtypePlot, "/subtypeplot")
