from flask import Blueprint, request
from flask_restful import Api, Resource

gsea = Blueprint("gsea", __name__)
api = Api(gsea)
