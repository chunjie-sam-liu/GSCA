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
        print("\n\n ", " \\\n ".join(cmd), "\n\n")
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
        print("\n\n ", " \\\n ".join(cmd), "\n\n")
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
        print("\n\n ", " \\\n ".join(cmd), "\n\n")
        subprocess.check_output(cmd, universal_newlines=True)


class CheckTablePlot(AppPaths):
    """
    The resource to generate table and figure simutaneousely.
    """

    def __init__(self, args, purpose, ranalysis):
        self.args = args
        self.purpose = purpose
        self.ranalysis = ranalysis
        self.precol = "preanalysised"
        self.tablecol = "preanalysised_" + purpose

    def check_run(self):
        # test table
        table_uuidname = str(uuid.uuid4())
        table_run = True
        table_preanalysised = mongo.db[self.precol].find_one(
            {
                "search": "#".join(self.args["validSymbol"]),
                "coll": "#".join(self.args["validColl"]),
                "purpose": self.purpose + "table",
            },
            {"_id": 0, "uuid": 1},
        )
        if table_preanalysised:
            table_uuidname = table_preanalysised["uuid"]
            table_col_target = mongo.db[self.tablecol].find_one({"uuid": table_uuidname}, {"_id": 0, "uuid": 1})
            table_run = False if table_col_target else True
        else:
            mongo.db[self.precol].insert_one(
                {
                    "search": "#".join(self.args["validSymbol"]),
                    "coll": "#".join(self.args["validColl"]),
                    "purpose": self.purpose + "table",
                    "uuid": table_uuidname,
                }
            )

        # test plot
        plot_uuidname = str(uuid.uuid4())
        plot_run = True
        plot_filename = plot_uuidname + ".png"
        plot_filepath = self.resource_pngs / plot_filename

        plot_preanalysised = mongo.db[self.precol].find_one(
            {
                "search": "#".join(self.args["validSymbol"]),
                "coll": "#".join(self.args["validColl"]),
                "purpose": self.purpose + "plot",
            },
            {"_id": 0, "uuid": 1},
        )
        if plot_preanalysised:
            plot_uuidname = plot_preanalysised["uuid"]
            plot_filename = plot_uuidname + ".png"
            plot_filepath = self.resource_pngs / plot_filename
            plot_run = False if plot_filepath.exists() else True
        else:
            mongo.db[self.precol].insert_one(
                {
                    "search": "#".join(self.args["validSymbol"]),
                    "coll": "#".join(self.args["validColl"]),
                    "purpose": self.purpose + "plot",
                    "uuid": plot_uuidname,
                }
            )

        return {
            "run": table_run or plot_run,
            "table_run": table_run,
            "table_uuidname": table_uuidname,
            "plot_run": plot_run,
            "plot_uuidname": plot_uuidname,
            "plot_filepath": str(plot_filepath),
        }

    def analysis(self, uuidname, filepath):
        rargs = "#".join(self.args["validSymbol"]) + "@" + "#".join(self.args["validColl"])
        cmd = [
            self.rcommand,
            str(self.rscriptpath / self.ranalysis),
            rargs,
            filepath,
            str(self.apppath),
            uuidname,
            self.tablecol,
        ]
        print("\n\n ", " \\\n ".join(cmd), "\n\n")


class CheckUUIDPlot(AppPaths):
    def __init__(self, gsxa_uuid, name_uuid, purpose, rplot, precol, gsxacol):
        self.gsxa_uuid = gsxa_uuid
        self.name_uuid = name_uuid
        self.purpose = purpose
        self.rplot = rplot

        self.precol = precol
        self.gsxacol = gsxacol

        self.uuid = str(uuid.uuid4())
        self.filename = self.uuid + ".png"
        self.filepath = self.resource_pngs / self.filename

    def check_run(self):
        run = True
        preanalysised = mongo.db[self.precol].find_one(
            {self.name_uuid: self.gsxa_uuid, "purpose": self.purpose}, {"_id": 0, "uuid": 1},
        )

        if preanalysised:
            self.uuid = preanalysised["uuid"]
            self.filename = self.uuid + ".png"
            self.filepath = self.resource_pngs / self.filename
            run = False if self.filepath.exists() else True
        else:
            mongo.db[self.precol].insert_one({self.name_uuid: self.gsxa_uuid, "purpose": self.purpose, "uuid": self.uuid})

        return {"run": run, "uuid": self.uuid}

    def plot(self):

        cmd = [
            self.rcommand,
            str(self.rscriptpath / self.rplot),
            self.gsxa_uuid,
            self.gsxacol,
            str(self.filepath),
            str(self.apppath),
        ]
        print("\n\n ", " \\\n ".join(cmd), "\n\n")
        subprocess.check_output(cmd, universal_newlines=True)


class CheckParalleUUIDPlot(AppPaths):
    """
    For multiple uuids and one Rplot script.
    And the Rscript save multiple uuid plot files.
    This should be used for share mongo query data to avoid repeat access mongo.
    """

    def __init__(self, gsxa_uuid, name_uuid, purposes, rplot, precol, gsxacol):
        self.gsxa_uuid = gsxa_uuid
        self.name_uuid = name_uuid
        self.purposes = purposes
        self.rplot = rplot

        self.precol = precol
        self.gsxacol = gsxacol

        self.uuids = [str(uuid.uuid4()) for _ in range(len(self.purposes))]

    def check_run(self):
        run = True
        res = {purpose: self._check_mongo(purpose, uuid) for purpose, uuid in zip(self.purposes, self.uuids)}
        return res

    def _check_mongo(self, purpose, uuid):
        preanalysised = mongo.db[self.precol].find_one(
            {self.name_uuid: self.gsxa_uuid, "purpose": purpose}, {"_id": 0, "uuid": 1},
        )

        if preanalysised:
            uuid = preanalysised["uuid"]
            filename = uuid + ".png"
            filepath = self.resource_pngs / filename
            run = False if filepath.exists() else True
        else:
            filename = uuid + ".png"
            filepath = self.resource_pngs / filename
            mongo.db[self.precol].insert_one({self.name_uuid: self.gsxa_uuid, "purpose": purpose, "uuid": uuid})
            run = False

        return {"run": run, "filepath": filepath, "uuid": uuid}

    def plot(self, filepaths):
        cmd1 = [self.rcommand, str(self.rscriptpath / self.rplot), self.gsxa_uuid, self.gsxacol]
        cmd = cmd1 + filepaths + [str(self.apppath)]
        print("\n\n ", " \\\n ".join(cmd), "\n\n")
        subprocess.check_output(cmd, universal_newlines=True)


class CheckGSEAPlotSingleCancerType(AppPaths):
    def __init__(self, gsxa_uuid, name_uuid, cancertype, purpose, rplot, precol, gsxacol):
        self.gsxa_uuid = gsxa_uuid
        self.name_uuid = name_uuid
        self.cancertype = cancertype
        self.purpose = purpose
        self.rplot = rplot

        self.precol = precol
        self.gsxacol = gsxacol

        self.uuid = str(uuid.uuid4())
        self.filename = self.uuid + ".png"
        self.filepath = self.resource_pngs / self.filename

    def check_run(self):
        run = True
        preanalysised = mongo.db[self.precol].find_one(
            {self.name_uuid: self.gsxa_uuid, "purpose": self.purpose, "cancertype": self.cancertype}, {"_id": 0, "uuid": 1},
        )
        if preanalysised:
            self.uuid = preanalysised["uuid"]
            self.filename = self.uuid + ".png"
            self.filepath = self.resource_pngs / self.filename
            run = False if self.filepath.exists() else True
        else:
            mongo.db[self.precol].insert_one(
                {self.name_uuid: self.gsxa_uuid, "purpose": self.purpose, "cancertype": self.cancertype, "uuid": self.uuid}
            )

        return {"run": run, "uuid": self.uuid}

    def plot(self):
        cmd = [
            self.rcommand,
            str(self.rscriptpath / self.rplot),
            self.gsxa_uuid,
            self.gsxacol,
            self.cancertype,
            str(self.filepath),
            str(self.apppath),
        ]
        print("\n\n ", " \\\n ".join(cmd), "\n\n")
        subprocess.check_output(cmd, universal_newlines=True)


class CheckGSVASurvivalSingleCancerType(AppPaths):
    def __init__(self, gsxa_uuid, name_uuid, cancertype, surType, purpose, rplot, precol, gsxacol):
        self.gsxa_uuid = gsxa_uuid
        self.name_uuid = name_uuid
        self.cancertype = cancertype
        self.surType = surType
        self.purpose = purpose
        self.rplot = rplot

        self.precol = precol
        self.gsxacol = gsxacol

        self.uuid = str(uuid.uuid4())
        self.filename = self.uuid + ".png"
        self.filepath = self.resource_pngs / self.filename

    def check_run(self):
        run = True
        preanalysised = mongo.db[self.precol].find_one(
            {self.name_uuid: self.gsxa_uuid, "purpose": self.purpose, "cancertype": self.cancertype, "surType": self.surType},
            {"_id": 0, "uuid": 1},
        )
        if preanalysised:
            self.uuid = preanalysised["uuid"]
            self.filename = self.uuid + ".png"
            self.filepath = self.resource_pngs / self.filename
            run = False if self.filepath.exists() else True
        else:
            mongo.db[self.precol].insert_one(
                {
                    self.name_uuid: self.gsxa_uuid,
                    "purpose": self.purpose,
                    "cancertype": self.cancertype,
                    "surType": self.surType,
                    "uuid": self.uuid,
                }
            )

        return {"run": run, "uuid": self.uuid}

    def plot(self):
        cmd = [
            self.rcommand,
            str(self.rscriptpath / self.rplot),
            self.gsxa_uuid,
            self.gsxacol,
            self.cancertype,
            self.surType,
            str(self.filepath),
            str(self.apppath),
        ]
        print("\n\n ", " \\\n ".join(cmd), "\n\n")
        subprocess.check_output(cmd, universal_newlines=True)
