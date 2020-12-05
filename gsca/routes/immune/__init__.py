from gsca import app
from gsca.routes.immune.immunecnv import immunecnv
from gsca.routes.immune.immunesnv import immunesnv
from gsca.routes.immune.immunemethy import immunemethy
from gsca.routes.immune.immuneexpr import immuneexpr

app.register_blueprint(immunecnv, url_prefix="/api/immune/immunecnv")
app.register_blueprint(immunesnv, url_prefix="/api/immune/immunesnv")
app.register_blueprint(immunemethy, url_prefix="/api/immune/immunemethy")
app.register_blueprint(immuneexpr, url_prefix="/api/immune/immuneexpr")
