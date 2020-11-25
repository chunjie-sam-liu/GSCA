from gsca import app
from gsca.routes.resource.responseplot import responseplot


app.register_blueprint(responseplot, url_prefix="/api/resource/responseplot")
