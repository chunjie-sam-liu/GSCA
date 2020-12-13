from gsca import app
from gsca.routes.drug.gdsc import gdsc
from gsca.routes.drug.ctrp import ctrp

app.register_blueprint(gdsc, url_prefix="/api/drug/gdsc")
app.register_blueprint(ctrp, url_prefix="/api/drug/ctrp")
