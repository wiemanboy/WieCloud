import resources.app

params = option("params")

if params.oxr.kind == "App":
    items = app.compose(params)

