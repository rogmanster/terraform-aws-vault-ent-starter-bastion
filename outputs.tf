output "bastion_public_ip" {
  value = aws_instance.bastion.*.public_ip
}

output "bastion_public_dns" {
  value = aws_instance.bastion.*.public_dns
}

output "telemetry_public_ip" {
  value = aws_instance.telemetry.*.public_ip
}

output "telemetry_public_dns" {
  value = aws_instance.telemetry.*.public_dns
}

output "key_name" {
  value = aws_key_pair.awskey.key_name
}
