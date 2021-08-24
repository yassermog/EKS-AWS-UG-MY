#basurl=$(terraform output -raw base_url)
baseurl="https://58e0c93i61.execute-api.ap-southeast-1.amazonaws.com/serverless_lambda_stage"
curl -s ${baseurl}/hello?Name=DAZN