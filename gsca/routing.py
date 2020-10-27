from flask import render_template
from gsca import app

# from gsca.routes.home import home
from gsca.routes.expression import expression
from gsca.routes.search import search


# routing
# app.register_blueprint(home, url_prefix="/api/home")
app.register_blueprint(expression, url_prefix="/api/expression")
app.register_blueprint(search, url_prefix="/api/search")


@app.route("/", methods=["GET"])
def index():
    return render_template("index.html")
