#Terraform console output
output "AmazonLinux_availability_zone" {
  value = aws_instance.myFirst_TF-server.availability_zone
}

#Terraform console output
output "Ubuntu_availability_zone" {
  value = aws_instance.mySecond_TF-server.availability_zone
}
