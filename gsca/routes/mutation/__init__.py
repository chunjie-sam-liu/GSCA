from gsca import app
from gsca.routes.mutation.snv import snv


app.register_blueprint(snv, url_prefix="/api/mutation/snv")
