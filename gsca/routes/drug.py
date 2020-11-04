from flask import Blueprint
from gsca.db import mongo
from flask_restful import Api, Resource
from pathlib import Path
import subprocess
import uuid

drug = Blueprint("drug", __name__)
api = Api(drug)

# r plot resource
apppath = Path(api.app.root_path).parent.parent
rcommand = "/usr/bin/Rscript"
rscriptpath = apppath / "gsca/rscripts"
resource_pngs = apppath / "gsca/resource/pngs"

if not resource_pngs.exists():
    resource_pngs.mkdir(parents=True)
