global:
  scrape_interval: 60s
  scrape_timeout: 10s
  evaluation_interval: 15s
alerting:
  alertmanagers:
  - static_configs:
    - targets: []
    scheme: http
    timeout: 10s
    api_version: v1
scrape_configs:
- job_name: node
  static_configs:
  - targets: ['node-exporter:9100']
- job_name: keeper
  honor_timestamps: true
  scrape_interval: 15s
  scrape_timeout: 10s
  metrics_path: /metrics
  scheme: http
  static_configs:
  - targets:
    - keeper:9464
- job_name: wallet
  honor_timestamps: true
  scrape_interval: 15s
  scrape_timeout: 10s
  metrics_path: /metrics/${wallet_address}
  scheme: http
  static_configs:
  - targets:
    - wallet-tracker:3000