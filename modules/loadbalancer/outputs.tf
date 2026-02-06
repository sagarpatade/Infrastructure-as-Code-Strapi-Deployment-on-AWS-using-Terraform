output "target_group_arn" {
  value = aws_lb_target_group.strapi_tg.arn
}

output "alb_dns_name" {
  value = aws_lb.strapi_alb.dns_name
}