from gsca import app
from gsca.routes.mutation.snv import snv
from gsca.routes.mutation.snvsurvival import snvsurvival
from gsca.routes.mutation.methylation import methylation


app.register_blueprint(snv, url_prefix="/api/mutation/snv")
app.register_blueprint(snvsurvival, url_prefix="/api/mutation/snvsurvival")
app.register_blueprint(methylation, url_prefix="/api/mutation/methylation")