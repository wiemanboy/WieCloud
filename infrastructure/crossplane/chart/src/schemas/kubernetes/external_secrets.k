schema StoreRef:
    kind: str
    name: str

schema Secret:
    name: str
    storeRef: StoreRef

