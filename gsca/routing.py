from flask import render_template
from gsca import app

# from gsca.routes.home import home
from gsca.routes.expression import expression


# routing
# app.register_blueprint(home, url_prefix="/api/home")
app.register_blueprint(expression, url_prefix="/api/expression")


@app.route("/", methods=["GET"])
def index():
    return render_template("index.html")
