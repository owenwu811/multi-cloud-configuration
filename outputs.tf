#Terraform console output
output "AmazonLinux_availability_zone" {
  value = aws_instance.myFirst_TF-server.availability_zone
  description = "availablility zone of linux ec2 instance"
}

#Terraform console output
output "Ubuntu_availability_zone" {
  value = aws_instance.mySecond_TF-server.availability_zone
  description = "name of the availbility zone that the ec2 instance resides in"
}
#Terraform console output 
output "Load_Balancer_DNS" {
    value = aws_elb.my-elb.dns_name
    description = "name of the elastic load balancer"
}

