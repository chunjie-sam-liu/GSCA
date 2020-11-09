from flask import Blueprint
from gsca.db import mongo
from flask_restful import Api, Resource
from pathlib import Path
import subprocess
import uuid

snv = Blueprint("snv", __name__)
api = Api(snv)

