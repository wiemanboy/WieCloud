import resources.app

params = option("params")

if params.oxr.kind == "App":
    _items = app.compose(params)

if params.oxr.kind == "Backup":
    _items = app.compose(params)

items = _items
