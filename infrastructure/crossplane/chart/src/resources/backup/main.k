import lib.crossplane
import lib.kubernetes
import lib.utils

compose: (any) -> [{str:any}] = lambda params: any {
    ctx = params.ctx
    backups: any = ctx["apiextensions.crossplane.io/environment"]["backups"]

    observed_xr: any = params.oxr

    # Repo secrets
    _desired_repo_secrets = [kubernetes.external_secret(backup.repo.secret.name, observed_xr.metadata.name, {
        kind = backup.repo.secret.storeRef.kind
        name = backup.repo.secret.storeRef.name
    }, [backup.repo.secret.password]) for backup in backups]

    # S3 credentials secrets
    _desired_s3_credentials_secrets = [kubernetes.external_secret(backup.s3.secret.name, observed_xr.metadata.name, {
        kind: backup.s3.secret.storeRef.kind
        name: backup.s3.secret.storeRef.name
    }, [
        backup.s3.secret.accessKey
        backup.s3.secret.secretKey
    ]) for backup in backups]

    # Schedules
    _desired_schedules = [kubernetes.schedule(observed_xr.metadata.name, observed_xr.spec.target.bucket, {
        name: utils.dash_name(backup.repo.secret.name)
        key: backup.repo.secret.password
    }, {
        accessKey: {
            name: utils.dash_name(backup.s3.secret.name)
            key: backup.s3.secret.accessKey
        }
        secretKey: {
            name: utils.dash_name(backup.s3.secret.name)
            key: backup.s3.secret.secretKey
        }
    }, observed_xr.spec.backup?.podSpec?.securityContext or {}, backup) for backup in backups]

    # Restores
    restores = observed_xr.spec.restores
    _desired_restores = [kubernetes.restore(restore.name, observed_xr.metadata.name, restore.claim.name, restore.snapshot, crossplane.get_resource_by_name_and_kind(restore.fromBackup, "Schedule", _desired_schedules).spec.backend or {}) for restore in restores if restore.enabled == True]

    if observed_xr.spec.enabled == False:
        _desired_schedules = []

    # Check readiness
    observed_resources = [value.Resource for _, value in params.ocds]
    _desired_external_secrets = crossplane.check_readiness([*_desired_repo_secrets, *_desired_s3_credentials_secrets], observed_resources, crossplane.readiness.external_secret)
    _desired_schedules = crossplane.check_readiness(_desired_schedules, observed_resources, crossplane.readiness.schedule)
    _desired_restores = crossplane.check_readiness(_desired_restores, observed_resources, crossplane.readiness.restore)

    # Update status
    _desired_xr: {str:any} = {
        **params.dxr
        status.targets = [{
            name = backup.name
            endpoint = backup.s3.endpoint
            schedule = backup.schedule
            retention = backup.retention
        } for backup in backups]
    }

    items = [_desired_xr, *_desired_external_secrets, *_desired_schedules, *_desired_restores]
}
