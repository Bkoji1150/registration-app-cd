# registration-app-cd
registration-app-cd

### Update kubectl-config
```sh
aws eks --region us-east-1 update-kubeconfig  --name ci-cd-demo-eks-demo
kubectl apply -f kube-manifest/
```