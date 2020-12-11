from flask import Blueprint
from flask_restful import Api, Resource
from gsca.db import mongo


responsetable = Blueprint("responsetable", __name__)
api = Api(responsetable)


class ResponseTable(Resource):
    def get(self, coll, uuidname):
        mcur = mongo.db[coll].find_one({"uuid": uuidname}, {"_id": 0})
        if mcur:
            return mcur
        else:
            return {"Error": "Resource not exists."}


api.add_resource(ResponseTable, "/<string:coll>/<string:uuidname>")
