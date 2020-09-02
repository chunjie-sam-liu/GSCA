from flask import render_template
from gsca import app

from gsca.routes.home import home  # ok


# routing
app.register_blueprint(home, url_prefix="/api/home")


@app.route("/", methods=["GET"])
def index():
    return render_template("index.html")
