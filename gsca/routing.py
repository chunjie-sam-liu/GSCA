from flask import render_template
from gsca import app

from gsca.routes.expression import expression
from gsca.routes.search import search
from gsca.routes.mutation import mutation
from gsca.routes.immune import immune
from gsca.routes.drug import drug

# routing
app.register_blueprint(expression, url_prefix="/api/expression")
app.register_blueprint(search, url_prefix="/api/search")
app.register_blueprint(mutation, url_prefix="/api/mutation")
app.register_blueprint(immune, url_prefix="/api/immune")
app.register_blueprint(drug, url_prefix="/api/drug")


@app.route("/", methods=["GET"])
def index():
    return render_template("index.html")
