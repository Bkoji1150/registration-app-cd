
output "nlb_endpoint" {
    value =  "http://${kubernetes_service_v1.alb_service.status.0.load_balancer.0.ingress.0.hostname}"
}