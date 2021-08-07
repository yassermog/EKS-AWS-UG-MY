REGION=ap-southeast-1
CLUSTER=aws-usg-my-eks
aws eks --region ${REGION} update-kubeconfig --name ${CLUSTER}
