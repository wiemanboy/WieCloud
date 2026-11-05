schema S3SecretRef:
    accessKey: SecretRef
    secretKey: SecretRef

schema S3Secret(Secret):
    accessKey: str
    secretKey: str

schema RepoSecret(Secret):
    password: str

schema S3:
    endpoint: str
    secret: S3Secret

schema Repo:
    secret: RepoSecret

schema Schedule:
    backup: str
    prune: str
    $check: str

schema Retention:
    keepLast: int
    keepDaily: int

schema Backup:
    name: str
    s3: S3
    repo: Repo
    schedule: Schedule
    retention: Retention

