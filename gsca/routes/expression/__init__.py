from gsca import app
from gsca.routes.expression.deg import deg
from gsca.routes.expression.survival import survival

app.register_blueprint(deg, url_prefix="/api/expression/deg")
app.register_blueprint(survival, url_prefix="/api/expression/survival")
