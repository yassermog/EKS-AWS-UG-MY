id=testrotati
region="ap-southeast-1"

aws secretsmanager list-secret-version-ids \
    --secret-id $id \
    --region $region \
    --include-deprecated


#aws secretsmanager get-secret-value \
#    --secret-id $id \
#    --region $region

 ##    --version-stage AWSPENDING \
   