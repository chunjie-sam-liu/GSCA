from gsca import app
from gsca.routes.mutation.snv import snv
from gsca.routes.mutation.snvsurvival import snvsurvival


app.register_blueprint(snv, url_prefix="/api/mutation/snv")
app.register_blueprint(snvsurvival, url_prefix="/api/mutation/snvsurvival")
