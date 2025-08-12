# OPA Gatekeeper Rego Policy Examples
# Custom runtime security controls for the GitOps Data Platform

# Policy 1: Block public Cloud Storage buckets
package k8srequiredstorageprivate

violation[{"msg": msg}] {
    input.review.object.kind == "StorageBucket"
    input.review.object.spec.publicAccessPrevention != "enforced"
    msg := "Storage buckets must enforce public access prevention. Set spec.publicAccessPrevention to 'enforced'"
}

violation[{"msg": msg}] {
    input.review.object.kind == "StorageBucket"
    input.review.object.spec.uniformBucketLevelAccess != true
    msg := "Storage buckets must use uniform bucket-level access. Set spec.uniformBucketLevelAccess to true"
}

# Policy 2: Require CMEK encryption for data services
package k8srequiredcmekencryption

violation[{"msg": msg}] {
    input.review.object.kind == "BigQueryDataset"
    not input.review.object.spec.defaultEncryptionConfiguration.kmsKeyName
    msg := "BigQuery datasets must use customer-managed encryption keys (CMEK)"
}

violation[{"msg": msg}] {
    input.review.object.kind == "StorageBucket"
    not input.review.object.spec.encryption.defaultKmsKeyName
    msg := "Storage buckets must use customer-managed encryption keys (CMEK)"
}

violation[{"msg": msg}] {
    input.review.object.kind == "SQLInstance"
    not input.review.object.spec.settings.diskEncryptionConfiguration.kmsKeyName
    msg := "Cloud SQL instances must use customer-managed encryption keys (CMEK)"
}

# Policy 3: Enforce data classification labels
package k8srequireddataclassification

required_labels := {"data-classification", "environment", "team"}

violation[{"msg": msg}] {
    input.review.object.kind in ["BigQueryDataset", "StorageBucket", "SQLInstance", "PubSubTopic"]
    missing := required_labels - set(object.get(input.review.object, ["metadata", "labels"], {}))
    count(missing) > 0
    msg := sprintf("Resource must have required labels: %v", [missing])
}

violation[{"msg": msg}] {
    input.review.object.kind in ["BigQueryDataset", "StorageBucket", "SQLInstance", "PubSubTopic"]
    classification := input.review.object.metadata.labels["data-classification"]
    not classification in ["public", "internal", "sensitive", "confidential"]
    msg := "data-classification label must be one of: public, internal, sensitive, confidential"
}

# Policy 4: Require private networking for SQL instances
package k8srequiredprivatesql

violation[{"msg": msg}] {
    input.review.object.kind == "SQLInstance"
    input.review.object.spec.settings.ipConfiguration.ipv4Enabled == true
    msg := "Cloud SQL instances must not have public IP addresses. Set spec.settings.ipConfiguration.ipv4Enabled to false"
}

violation[{"msg": msg}] {
    input.review.object.kind == "SQLInstance"
    not input.review.object.spec.settings.ipConfiguration.privateNetwork
    msg := "Cloud SQL instances must use private networking. Set spec.settings.ipConfiguration.privateNetwork"
}

# Policy 5: Enforce secure Pub/Sub configurations
package k8srequiredsecurepubsub

violation[{"msg": msg}] {
    input.review.object.kind == "PubSubTopic"
    not input.review.object.spec.kmsKeyName
    msg := "Pub/Sub topics must use customer-managed encryption keys (CMEK)"
}

# Policy 6: Require resource naming conventions
package k8srequirednamingconvention

violation[{"msg": msg}] {
    input.review.object.kind in ["BigQueryDataset", "StorageBucket", "SQLInstance", "PubSubTopic"]
    not regex.match("^(dev|staging|prod)-", input.review.object.metadata.name)
    msg := "Resource names must start with environment prefix (dev-, staging-, prod-)"
}

# Policy 7: Enforce retention policies for compliance
package k8srequiredretentionpolicy

violation[{"msg": msg}] {
    input.review.object.kind == "StorageBucket"
    not input.review.object.spec.retentionPolicy
    msg := "Storage buckets must have retention policies for compliance"
}

violation[{"msg": msg}] {
    input.review.object.kind == "BigQueryDataset"
    not input.review.object.spec.defaultTableExpirationMs
    msg := "BigQuery datasets must have table expiration policies for compliance"
}

# Policy 8: Require audit logging for sensitive resources
package k8srequiredauditlogging

violation[{"msg": msg}] {
    input.review.object.kind == "SQLInstance"
    classification := input.review.object.metadata.labels["data-classification"]
    classification in ["sensitive", "confidential"]
    not contains(input.review.object.spec.settings.databaseFlags, {"name": "log_statement", "value": "all"})
    msg := "Sensitive Cloud SQL instances must enable statement logging"
}

contains(arr, item) {
    arr[_] == item
}
