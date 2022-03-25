from gsca import app
from gsca.routes.resource.responseplot import responseplot
from gsca.routes.resource.responsetable import responsetable
from gsca.routes.resource.responsedatadownload import responsedatadownload


app.register_blueprint(responseplot, url_prefix="/api/resource/responseplot")
app.register_blueprint(responsetable, url_prefix="/api/resource/responsetable")
app.register_blueprint(responsedatadownload, url_prefix="/api/resource/ResponseDataDownload")
