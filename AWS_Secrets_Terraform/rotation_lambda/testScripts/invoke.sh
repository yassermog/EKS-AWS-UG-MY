#function_name=$(terraform output -raw function_name)
function_name="HelloWorld"
region="ap-southeast-1"
aws lambda invoke --region=${region} --function-name=${function_name} response.json