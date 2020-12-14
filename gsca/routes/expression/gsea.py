from flask import Blueprint, request
from flask_restful import Api, Resource

gsea = Blueprint("gsea", __name__)
api = Api(gsea)


class GSEAAnalysis(Resource):
    def post(self):
        args = request.get_json()
        print(args)

        return args


api.add_resource(GSEAAnalysis, "/gseaanalysis")
