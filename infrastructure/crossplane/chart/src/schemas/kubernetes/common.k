schema Resources:
    limits?: Resource
    requests?: Resource

schema Resource:
    cpu?: str
    memory?: str

schema SecurityContext:
    runAsUser?: int
    fsGroup?: int
    fsGroupChangePolicy?: str

schema SecretRef:
    name: str
    key: str

