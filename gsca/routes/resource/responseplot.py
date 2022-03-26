from tabnanny import filename_only
from flask import Blueprint, send_file
from flask_restful import Api, Resource
from gsca import app
from pathlib import Path

responseplot = Blueprint("responseplot", __name__)
api = Api(responseplot)


class ResponsePlot(Resource):
    apppath = Path(app.root_path).parent  # notice apppath parent
    resource_pngs = apppath / "gsca-r-plot/pngs"

    def get(self, uuidname):
        filepath = self.resource_pngs / uuidname
        if filepath.exists():
            return send_file(str(filepath), as_attachment=True)
        else:
            return {"Error": "Resource not exists."}


api.add_resource(ResponsePlot, "/<string:uuidname>")

