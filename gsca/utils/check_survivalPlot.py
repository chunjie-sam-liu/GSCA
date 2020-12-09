import uuid
from gsca import app
from pathlib import Path
from gsca.db import mongo
import subprocess


class AppPaths:
    apppath = Path(app.root_path).parent  # notice apppath parent
    rcommand = "/usr/bin/Rscript"
    rscriptpath = apppath / "gsca-r-app"
    resource_pngs = apppath / "gsca-r-plot/pngs"

    if not resource_pngs.exists():
        resource_pngs.mkdir(parents=True)


class CheckSurvivalPlot(AppPaths):
    """
    [For single uuid and single Rplot scripts]

    Returns:
        [type]: [description]
    """

    def __init__(self, args, purpose, rplot):
        self.args = args
        self.purpose = purpose
        self.rplot = rplot

    def check_run(self):
        uuidname = str(uuid.uuid4())
        filename = uuidname + ".png"
        filepath = self.resource_pngs / filename

        preanalysised = mongo.db.preanalysised.find_one(
            {
                "search": "#".join(self.args["validSymbol"]),
                "coll": "#".join(self.args["validColl"]),
                "surtype": "#".join(self.args["surType"]),
                "purpose": self.purpose,
            },
            {"_id": 0, "uuid": 1},
        )
        if preanalysised:
            uuidname = preanalysised["uuid"]
            filename = uuidname + ".png"
            filepath = self.resource_pngs / filename
            run = False if filepath.exists() else True
            return {"run": run, "filepath": filepath, "uuid": uuidname}
        else:
            mongo.db.preanalysised.insert_one(
                {
                    "search": "#".join(self.args["validSymbol"]),
                    "coll": "#".join(self.args["validColl"]),
                    "purpose": self.purpose,
                    "surtype": "#".join(self.args["surType"]),
                    "uuid": uuidname,
                }
            )
            return {"run": True, "filepath": filepath, "uuid": uuidname}

    def plot(self, filepath):
        rargs = (
            "#".join(self.args["validSymbol"]) + "@" + "#".join(self.args["validColl"]) + "@" + "#".join(self.args["surType"])
        )
        cmd = [self.rcommand, str(self.rscriptpath / self.rplot), rargs, str(filepath), str(self.apppath)]
        print("\n\n ", "\n\n ".join(cmd), "\n\n")
        subprocess.check_output(cmd, universal_newlines=True)
