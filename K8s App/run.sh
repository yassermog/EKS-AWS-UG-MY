kubectl get namespaces

kubectl create ns exampe-app

kubectl apply -n exampe-app -f secrets/secret.yaml 
kubectl apply -n exampe-app -f configmaps/configmap.yaml 
kubectl apply -n exampe-app -f deployments/deployment.yaml 
kubectl apply -n exampe-app -f services/service.yaml 

kubectl get svc -n exampe-app