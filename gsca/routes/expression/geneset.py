from flask import Blueprint, request, send_file
from gsca.db import mongo
from flask_restful import Api, Resource, fields, marshal_with, reqparse
from gsca.utils.checkplot import CheckParallelPlot, CheckPlot, CheckMultiplePlot
from gsca.utils.checktable import CheckTable

geneset = Blueprint("geneset", __name__)
api = Api(geneset)


class GeneSetTable(Resource):
    def post(self):
        args = request.get_json()
        print(args)

        return args


api.add_resource(GeneSetTable, "/genesettable")
