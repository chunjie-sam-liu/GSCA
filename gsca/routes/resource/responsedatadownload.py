from tabnanny import filename_only
from flask import Blueprint, send_file
from flask_restful import Api, Resource
from gsca import app
from pathlib import Path

responsedatadownload = Blueprint("responsedatadownload", __name__)
api = Api(responsedatadownload)


class ResponseDataDownload(Resource):
    apppath = Path(app.root_path).parent  # notice apppath parent
    resource_data = apppath / "gsca-download"

    def get(self, filename):

        filepath = self.resource_data / filename
        if filepath.exists():
            return send_file(str(filepath), as_attachment=True)
        else:
            return {"Error": "Resource not exists."}


api.add_resource(ResponseDataDownload, "/<string:filename>")
