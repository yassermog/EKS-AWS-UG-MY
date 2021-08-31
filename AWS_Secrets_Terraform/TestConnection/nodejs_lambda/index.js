// Load the AWS SDK
const AWS = require('aws-sdk')
var mysql = require('mysql');

const client = new AWS.SecretsManager({ region: 'ap-southeast-1' })

SecretId = "testsecret"

const getSecrets = async (SecretId) => {
  return await new Promise((resolve, reject) => {
    client.getSecretValue({ SecretId }, (err, result) => {
      if (err) reject(err)
      else {
        resolve(result.SecretString)
      }
    })
  })
}

const main = async (event) => {
  jsoncreds = await getSecrets(SecretId)
  //console.log("result is :" + jsoncreds)
  creds = JSON.parse(jsoncreds);
  console.log(creds);

  var con = mysql.createConnection({
    host: creds.host.replace(':3306', ''),
    user: creds.username,
    password: creds.password,
    port: creds.port,
  });

  con.connect(function (err) {
    if (err) throw err;
    console.log("Connected!");
  });

  return;
}

exports.handler = main