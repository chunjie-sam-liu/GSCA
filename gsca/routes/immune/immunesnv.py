from flask import Blueprint
from gsca.db import mongo
from flask_restful import Api, Resource
from pathlib import Path
import subprocess
import uuid

immunesnv = Blueprint("immunesnv", __name__)
api = Api(immunesnv)

