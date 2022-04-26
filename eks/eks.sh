export AGW_AWS_REGION=us-east-2
export AGW_ACCOUNT_ID=$(aws sts get-caller-identity --profile arley_tests --query 'Account' --output text)
export AGW_EKS_CLUSTER_NAME=poc-cluster

---

eksctl utils associate-iam-oidc-provider \
  --region $AGW_AWS_REGION \
  --cluster $AGW_EKS_CLUSTER_NAME \
  --approve \
  --profile arley_tests

---

curl -S https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.0/docs/install/iam_policy.json -o iam-policy.json

aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy-APIGWDEMO \
  --policy-document file://iam-policy.json 2> /dev/null \
  --profile arley_tests

## Create a service account
eksctl create iamserviceaccount \
  --cluster=$AGW_EKS_CLUSTER_NAME \
  --region $AGW_AWS_REGION \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --override-existing-serviceaccounts \
  --attach-policy-arn=arn:aws:iam::${AGW_ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy-APIGWDEMO \
  --approve \
  --profile arley_tests

---

export AGW_VPC_ID=$(aws eks describe-cluster \
  --name $AGW_EKS_CLUSTER_NAME \
  --region $AGW_AWS_REGION  \
  --profile arley_tests \
  --query "cluster.resourcesVpcConfig.vpcId" \
  --output text)

helm repo add eks https://aws.github.io/eks-charts && helm repo update

kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

helm install aws-load-balancer-controller \
  eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=$AGW_EKS_CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set vpcId=$AGW_VPC_ID\
  --set region=$AGW_AWS_REGION

---

curl -O https://raw.githubusercontent.com/aws-samples/amazon-apigateway-ingress-controller-blog/Mainline/apigw-ingress-controller-blog/ack-iam-policy.json

aws iam create-policy \
  --policy-name ACKIAMPolicy \
  --policy-document file://ack-iam-policy.json \
  --profile arley_tests

helm install ack-apigatewayv2-controller \
  apigatewayv2-chart \
  --namespace kube-system \
  --set serviceAccount.create=false \
  --set aws.region=$AGW_AWS_REGION

---

AGW_VPCLINK_SG=$(aws ec2 create-security-group \
  --description "SG for VPC Link" \
  --group-name SG_VPC_LINK \
  --vpc-id $AGW_VPC_ID \
  --region $AGW_AWS_REGION \
  --profile arley_tests \
  --output text \
  --query 'GroupId')

---

cat > vpclink.yaml<<EOF
apiVersion: apigatewayv2.services.k8s.aws/v1alpha1
kind: VPCLink
metadata:
  name: nlb-internal
spec:
  name: nlb-internal
  securityGroupIDs:
    - $AGW_VPCLINK_SG
  subnetIDs:
    - $(aws ec2 describe-subnets \
          --filter Name=tag:kubernetes.io/role/internal-elb,Values=1 \
          --query 'Subnets[0].SubnetId' \
          --region $AGW_AWS_REGION --output text)
    - $(aws ec2 describe-subnets \
          --filter Name=tag:kubernetes.io/role/internal-elb,Values=1 \
          --query 'Subnets[1].SubnetId' \
          --region $AGW_AWS_REGION --output text)
    - $(aws ec2 describe-subnets \
          --filter Name=tag:kubernetes.io/role/internal-elb,Values=1 \
          --query 'Subnets[2].SubnetId' \
          --region $AGW_AWS_REGION --output text)
EOF

kubectl apply -f vpclink.yaml

---

aws apigatewayv2 get-vpc-links --region $AGW_AWS_REGION --profile arley_tests

---

cat > apigw-api.yaml<<EOF
apiVersion: apigatewayv2.services.k8s.aws/v1alpha1
kind: API
metadata:
  name: apitest-private-nlb
spec:
  body: '{
              "openapi": "3.0.1",
              "info": {
                "title": "ack-apigwv2-import-test-private-nlb",
                "version": "v1"
              },
              "paths": {
              "/\$default": {
                "x-amazon-apigateway-any-method" : {
                "isDefaultRoute" : true,
                "x-amazon-apigateway-integration" : {
                "payloadFormatVersion" : "1.0",
                "connectionId" : "$(kubectl get vpclinks.apigatewayv2.services.k8s.aws \
  nlb-internal \
  -o jsonpath="{.status.vpcLinkID}")",
                "type" : "http_proxy",
                "httpMethod" : "GET",
                "uri" : "$(aws elbv2 describe-listeners \
  --load-balancer-arn --profile arley_tests $(aws elbv2 describe-load-balancers \
  --region $AGW_AWS_REGION --profile arley_tests \
  --query "LoadBalancers[?contains(DNSName, '$(kubectl get service authorservice \
  -o jsonpath="{.status.loadBalancer.ingress[].hostname}")')].LoadBalancerArn" \
  --output text) \
  --region $AGW_AWS_REGION \
  --query "Listeners[0].ListenerArn" \
  --output text)",
               "connectionType" : "VPC_LINK"
                  }
                }
              },
              "/meta": {
                  "get": {
                    "x-amazon-apigateway-integration": {
                       "uri" : "$(aws elbv2 describe-listeners \
  --load-balancer-arn $(aws elbv2 describe-load-balancers \
  --region $AGW_AWS_REGION \
  --profile arley_tests \
  --query "LoadBalancers[?contains(DNSName, '$(kubectl get service echoserver \
  -o jsonpath="{.status.loadBalancer.ingress[].hostname}")')].LoadBalancerArn" \
  --output text) \
  --region $AGW_AWS_REGION \
  --query "Listeners[0].ListenerArn" \
  --output text)",
                      "httpMethod": "GET",
                      "connectionId": "$(kubectl get vpclinks.apigatewayv2.services.k8s.aws \
  nlb-internal \
  -o jsonpath="{.status.vpcLinkID}")",
                      "type": "HTTP_PROXY",
                      "connectionType": "VPC_LINK",
                      "payloadFormatVersion": "1.0"
                    }
                  }
                }
              },
              "components": {}
        }'
EOF

---

echo "
apiVersion: apigatewayv2.services.k8s.aws/v1alpha1
kind: Stage
metadata:
  name: "apiv1"
spec:
  apiID: $(kubectl get apis.apigatewayv2.services.k8s.aws apitest-private-nlb -o=jsonpath='{.status.apiID}')
  stageName: api
  autoDeploy: true
" | kubectl apply -f -