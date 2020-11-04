from flask import render_template
from gsca import app

import gsca.routes.expression
import gsca.routes.mutation
from gsca.routes.immune import immune
from gsca.routes.drug import drug
from gsca.routes.search import search

# # routing
app.register_blueprint(immune, url_prefix="/api/immune")
app.register_blueprint(drug, url_prefix="/api/drug")
app.register_blueprint(search, url_prefix="/api/search")


@app.route("/", methods=["GET"])
def index():
    return render_template("index.html")
