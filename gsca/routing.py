from flask import render_template
from gsca import app

import gsca.routes.expression
import gsca.routes.mutation
import gsca.routes.immune
import gsca.routes.drug
from gsca.routes.search import search

# # routing
app.register_blueprint(search, url_prefix="/api/search")


# resource routing
import gsca.routes.resource


@app.route("/", methods=["GET"])
def index():
    return render_template("index.html")
