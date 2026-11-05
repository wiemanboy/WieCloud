import schemas.kubernetes

schedule = lambda xr_name: str, bucket: str, repo_secret_ref: kubernetes.SecretRef, s3_secret_ref: kubernetes.S3SecretRef, backup_pod_security_context: kubernetes.SecurityContext, backup: kubernetes.Backup {
    {
        apiVersion: "k8up.io/v1"
        kind: "Schedule"
        metadata: metadata(backup.name, xr_name, "schedule")
        spec: {
            backend: {
                repoPasswordSecretRef = repo_secret_ref
                s3: {
                    endpoint: backup.s3.endpoint
                    bucket: bucket
                    accessKeyIDSecretRef: s3_secret_ref.accessKey
                    secretAccessKeySecretRef: s3_secret_ref.secretKey
                }
            }
            $check: {
                schedule: backup.schedule.backup
                failedJobsHistoryLimit: 2
                successfulJobsHistoryLimit: 0
            }
            prune: {
                schedule: backup.schedule.prune
                failedJobsHistoryLimit: 2
                successfulJobsHistoryLimit: 0
                retention: backup.retention
            }
            backup: {
                schedule: backup.schedule.backup
                failedJobsHistoryLimit: 2
                successfulJobsHistoryLimit: 1
                podSecurityContext: kubernetes.SecurityContext {
                    runAsUser: backup_pod_security_context.runAsUser or 0
                    fsGroup: backup_pod_security_context.fsGroup or 999
                    fsGroupChangePolicy: backup_pod_security_context.fsGroupChangePolicy or "OnRootMismatch"
                }
            }
        }
    }
}

restore = lambda name: str, xr_name: str, claim_name: str, snapshot: str, backend: {str:any} {
    {
        apiVersion: "k8up.io/v1"
        kind: "Restore"
        metadata: metadata(name, xr_name, "restore")
        spec: {
            restoreMethod.folder.claimName: claim_name
            snapshot: snapshot
            backend: backend
            podSecurityContext: {
                fsGroup: 65532
                fsGroupChangePolicy: "OnRootMismatch"
            }
        }
    }
}
