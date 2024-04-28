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
  - job_name: 'federate'
    scrape_interval: 60s

    honor_labels: true
    metrics_path: '/federate'
    
    basic_auth:
      username: '${user}'
      password: '${password}'

    params:
      'match[]':
        - '{instance="node-exporter:9100"}'
        - '{__name__=~"up:.*"}'

    static_configs:
      ${targets}
