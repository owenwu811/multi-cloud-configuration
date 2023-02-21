I built a Terraform module that can be used to host a full-stack web application across both AWS and Azure clouds for failover and for business critical applications. 

Current known bugs that I discovered during testing:
1. Azure resource groups needed to be manually deleted using the management console. Terraform destroy would delete all infrastructure except Azure resource groups.
Other notes and observations:
2. During testing, I noticed that some resources look much longer than others to destroy, such as the Azure_LB resource, took much longer to delete than other 
resources. It took 3 minutes on average for terraform destroy to delete this resource while the azure virtual network, for example, took only 12 seconds on a run for 
terraform destroy to terminate it. 
The aws_db instance took, on average, the longest to destroy, at 3 min 31s on one run. 

Note:
1. make sure to run Terraform Destroy after you provision infrastructure, or you maybe charged
