import uuid
from gsca import app
from pathlib import Path
from gsca.db import mongo
import subprocess


class AppPaths:
    apppath = Path(app.root_path).parent  # notice apppath parent
    rcommand = "/usr/local/bin/Rscript"
    rscriptpath = apppath / "gsca-r-app"
    resource_pngs = apppath / "gsca-r-plot/pngs"

    if not resource_pngs.exists():
        resource_pngs.mkdir(parents=True)


class CheckPlot(AppPaths):
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
            {"search": "#".join(self.args["validSymbol"]), "coll": "#".join(self.args["validColl"]), "purpose": self.purpose},
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
                    "uuid": uuidname,
                }
            )
            return {"run": True, "filepath": filepath, "uuid": uuidname}

    def plot(self, filepath):
        rargs = "#".join(self.args["validSymbol"]) + "@" + "#".join(self.args["validColl"])
        cmd = [self.rcommand, str(self.rscriptpath / self.rplot), rargs, str(filepath), str(self.apppath)]
        print("\n\n ", "\n\n  ".join(cmd), "\n\n")
        subprocess.check_output(cmd, universal_newlines=True)


class CheckMultiplePlot(AppPaths):
    """
    For multiple uuids and multiple Rplot scripts.
    And the Rscripts did not share mongo data.
    This is the enhanced format for CheckPlot, but slower.

    Returns:
        [type]: [description]
    """

    def __init__(self, args, purposes, rplots):
        self.args = args
        self.purposes = purposes
        self.rplots = rplots

    def check_run(self):
        uuidnames = [str(uuid.uuid4()) for _ in range(len(self.purposes))]

        res = {
            purpose: self._check_mongo(purpose, uuidname, rplot)
            for purpose, uuidname, rplot in zip(self.purposes, uuidnames, self.rplots)
        }
        return res

    def _check_mongo(self, purpose, uuidname, rplot):
        preanalysised = mongo.db.preanalysised.find_one(
            {"search": "#".join(self.args["validSymbol"]), "coll": "#".join(self.args["validColl"]), "purpose": purpose},
            {"_id": 0, "uuid": 1},
        )
        if preanalysised:
            uuidname = preanalysised["uuid"]
            filename = uuidname + ".png"
            filepath = self.resource_pngs / filename
            run = False if filepath.exists() else True
            return {"run": run, "filepath": filepath, "uuid": uuidname, "rplot": rplot}
        else:
            filename = uuidname + ".png"
            filepath = self.resource_pngs / filename
            mongo.db.preanalysised.insert_one(
                {
                    "search": "#".join(self.args["validSymbol"]),
                    "coll": "#".join(self.args["validColl"]),
                    "purpose": purpose,
                    "uuid": uuidname,
                }
            )
            return {"run": True, "filepath": filepath, "uuid": uuidname, "rplot": rplot}

    def plot(self, filepath, rplot):
        rargs = "#".join(self.args["validSymbol"]) + "@" + "#".join(self.args["validColl"])
        cmd = [self.rcommand, str(self.rscriptpath / rplot), rargs, str(filepath), str(self.apppath)]
        print("\n\n ", "\n\n  ".join(cmd), "\n\n")
        subprocess.check_output(cmd, universal_newlines=True)


class CheckParallelPlot(AppPaths):
    """
    For multiple uuids and one Rplot script.
    And the Rscript save multiple uuid plot files.
    This should be used for share mongo query data to avoid repeat access mongo.
    """

    def __init__(self, args, purposes, rplot):
        self.args = args
        self.purposes = purposes
        self.rplot = rplot

    def check_run(self):
        uuidnames = [str(uuid.uuid4()) for _ in range(len(self.purposes))]

        res = {purpose: self._check_mongo(purpose, uuidname) for purpose, uuidname in zip(self.purposes, uuidnames)}
        return res

    def _check_mongo(self, purpose, uuidname):
        preanalysised = mongo.db.preanalysised.find_one(
            {"search": "#".join(self.args["validSymbol"]), "coll": "#".join(self.args["validColl"]), "purpose": purpose},
            {"_id": 0, "uuid": 1},
        )
        if preanalysised:
            uuidname = preanalysised["uuid"]
            filename = uuidname + ".png"
            filepath = self.resource_pngs / filename
            run = False if filepath.exists() else True
            return {"run": run, "filepath": filepath, "uuid": uuidname}
        else:
            filename = uuidname + ".png"
            filepath = self.resource_pngs / filename
            mongo.db.preanalysised.insert_one(
                {
                    "search": "#".join(self.args["validSymbol"]),
                    "coll": "#".join(self.args["validColl"]),
                    "purpose": purpose,
                    "uuid": uuidname,
                }
            )
            return {"run": True, "filepath": filepath, "uuid": uuidname}

    def plot(self, filepaths):
        rargs = "#".join(self.args["validSymbol"]) + "@" + "#".join(self.args["validColl"])
        cmd = [self.rcommand, str(self.rscriptpath / self.rplot), rargs] + filepaths + [str(self.apppath)]
        print("\n\n ", "\n\n  ".join(cmd), "\n\n")
        subprocess.check_output(cmd, universal_newlines=True)
