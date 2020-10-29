from flask import Flask
from flask_cors import CORS
from gsca.config import Config, ProductionConfig

app = Flask(__name__)
CORS(app)

app.config.from_object(ProductionConfig)

import gsca.db
import gsca.routing

