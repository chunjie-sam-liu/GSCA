from gsca import app
from gsca.routes.expression.deg import deg
from gsca.routes.expression.survival import survival
from gsca.routes.expression.subtype import subtype
from gsca.routes.expression.stage import stage
from gsca.routes.expression.gsva import gsva
from gsca.routes.expression.gsea import gsea
from gsca.routes.expression.rppa import rppa
from gsca.routes.expression.paen import paen


app.register_blueprint(deg, url_prefix="/api/expression/deg")
app.register_blueprint(survival, url_prefix="/api/expression/survival")
app.register_blueprint(subtype, url_prefix="/api/expression/subtype")
app.register_blueprint(stage, url_prefix="/api/expression/stage")
app.register_blueprint(gsva, url_prefix="/api/expression/gsva")
app.register_blueprint(gsea, url_prefix="/api/expression/gsea")
app.register_blueprint(rppa, url_prefix="/api/expression/rppa")
app.register_blueprint(paen, url_prefix="/api/expression/paen")
