resource "google_storage_bucket" "pluto_bucket" {
  name     = "${var.project_id}-bucket"
  location = "us-central1"
  versioning {
    enabled = false
  }
}

resource "google_bigquery_dataset" "bq_dataset" {
  dataset_id                  = "activities"
  friendly_name               = "activities"
  description                 = "Moonbank activities dataset"
  location                    = "US"
  default_table_expiration_ms = 3600000
}

resource "google_bigquery_table" "bq_table" {
  dataset_id          = google_bigquery_dataset.bq_dataset.dataset_id
  table_id            = "resources"
  depends_on          = [google_bigquery_dataset.bq_dataset]
  schema              = <<EOF
[
  {
    "name": "messages",
    "type": "STRING"
  }
]
EOF
  deletion_protection = false
}

resource "google_pubsub_topic" "pubsub_topic" {
  name                       = "activities"
  message_retention_duration = "86600s"
}

resource "google_pubsub_subscription" "pubsub_sub" {
  name                 = "activites-catchall"
  topic                = google_pubsub_topic.pubsub_topic.name
  ack_deadline_seconds = 20
  depends_on           = [google_pubsub_topic.pubsub_topic]
}

resource "google_storage_bucket_object" "cloudfunction" {
  name   = "cloudfunction.zip"
  bucket = "mb-devops-user7-terraform"
  source = "./cloudfunction.zip"
}

resource "google_cloudfunctions_function" "function" {
  name        = "pubsub_to_bigquery"
  description = "Capture activities from pubsub and push into BQ"
  runtime     = "python39"

  available_memory_mb   = 128
  source_archive_bucket = "mb-devops-user7-terraform"
  source_archive_object = google_storage_bucket_object.cloudfunction.name
  timeout               = 60
  event_trigger {
    resource   = google_pubsub_topic.pubsub_topic.name
    event_type = "google.pubsub.topic.publish"
  }

  depends_on = [google_pubsub_topic.pubsub_topic]
}

resource "google_cloud_asset_project_feed" "project_feed" {
  project      = var.project_id
  feed_id      = "asset-feed"
  content_type = "RESOURCE"

  feed_output_config {
    pubsub_destination {
      topic = google_pubsub_topic.pubsub_topic.id
    }
  }

  asset_types = [
    "compute.googleapis.com/Autoscaler",
    "compute.googleapis.com/Address",
    "compute.googleapis.com/GlobalAddress",
    "compute.googleapis.com/BackendBucket",
    "compute.googleapis.com/BackendService",
    "compute.googleapis.com/Commitment",
    "compute.googleapis.com/Disk",
    "compute.googleapis.com/ExternalVpnGateway",
    "compute.googleapis.com/Firewall",
    "compute.googleapis.com/FirewallPolicy",
    "compute.googleapis.com/ForwardingRule",
    "compute.googleapis.com/GlobalForwardingRule",
    "compute.googleapis.com/HealthCheck",
    "compute.googleapis.com/HttpHealthCheck",
    "compute.googleapis.com/HttpsHealthCheck",
    "compute.googleapis.com/Image",
    "compute.googleapis.com/Instance",
    "compute.googleapis.com/InstanceGroup",
    "compute.googleapis.com/InstanceGroupManager",
    "compute.googleapis.com/InstanceTemplate",
    "compute.googleapis.com/Interconnect",
    "compute.googleapis.com/InterconnectAttachment",
    "compute.googleapis.com/License",
    "compute.googleapis.com/Network",
    "compute.googleapis.com/NetworkEndpointGroup",
    //"compute.googleapis.com/NodeGrop",
    "compute.googleapis.com/NodeTemplate",
    "compute.googleapis.com/PacketMirroring",
    "compute.googleapis.com/Project",
    "compute.googleapis.com/RegionBackendService",
    "compute.googleapis.com/RegionDisk",
    "compute.googleapis.com/Reservation",
    "compute.googleapis.com/ResourcePolicy",
    "compute.googleapis.com/Route",
    "compute.googleapis.com/Router",
    "compute.googleapis.com/SecurityPolicy",
    "compute.googleapis.com/ServiceAttachment",
    "compute.googleapis.com/Snapshot",
    "compute.googleapis.com/SslCertificate",
    "compute.googleapis.com/SslPolicy",
    "compute.googleapis.com/Subnetwork",
    "compute.googleapis.com/TargetHttpProxy",
    "compute.googleapis.com/TargetHttpsProxy",
    "compute.googleapis.com/TargetInstance",
    "compute.googleapis.com/TargetPool",
    "compute.googleapis.com/TargetTcpProxy",
    "compute.googleapis.com/TargetSslProxy",
    "compute.googleapis.com/TargetVpnGateway",
    "compute.googleapis.com/UrlMap",
    "compute.googleapis.com/VpnGateway",
    "compute.googleapis.com/VpnTunnel"
  ]

  depends_on = [google_pubsub_topic.pubsub_topic]
}
