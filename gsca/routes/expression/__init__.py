from gsca import app
from gsca.routes.expression.deg import deg
from gsca.routes.expression.survival import survival
from gsca.routes.expression.subtype import subtype
from gsca.routes.expression.stage import stage

app.register_blueprint(deg, url_prefix="/api/expression/deg")
app.register_blueprint(survival, url_prefix="/api/expression/survival")
app.register_blueprint(subtype, url_prefix="/api/expression/subtype")
app.register_blueprint(stage, url_prefix="/api/expression/stage")
