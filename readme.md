# Install ArgoCD

ArgoCD can be installed using either kubectl or Helm. Choose one of the following methods:

## Using kubectl

```shell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## Verify argo status

```console
kubectl get all -n argocd
```

The output will be similar to

```console
NAME                                                    READY   STATUS    RESTARTS   AGE
pod/argocd-application-controller-0                     1/1     Running   0          2m18s
pod/argocd-applicationset-controller-7b9c4dfb77-j6j7z   1/1     Running   0          2m18s
pod/argocd-dex-server-9b5c6dccd-r9ndm                   1/1     Running   0          2m18s
pod/argocd-notifications-controller-756764ddd5-7vt26    1/1     Running   0          2m18s
pod/argocd-redis-69f8795dbd-7nqpm                       1/1     Running   0          2m18s
pod/argocd-repo-server-565fb47c89-49txx                 1/1     Running   0          2m18s
pod/argocd-server-86f64667bc-z29lc                      1/1     Running   0          2m18s

NAME                                              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
service/argocd-applicationset-controller          ClusterIP   10.111.117.180   <none>        7000/TCP,8080/TCP            2m18s
service/argocd-dex-server                         ClusterIP   10.108.32.9      <none>        5556/TCP,5557/TCP,5558/TCP   2m18s
service/argocd-metrics                            ClusterIP   10.102.142.243   <none>        8082/TCP                     2m18s
service/argocd-notifications-controller-metrics   ClusterIP   10.97.251.128    <none>        9001/TCP                     2m18s
service/argocd-redis                              ClusterIP   10.98.98.139     <none>        6379/TCP                     2m18s
service/argocd-repo-server                        ClusterIP   10.104.222.35    <none>        8081/TCP,8084/TCP            2m18s
service/argocd-server                             ClusterIP   10.109.35.157    <none>        80/TCP,443/TCP               2m18s
service/argocd-server-metrics                     ClusterIP   10.102.228.115   <none>        8083/TCP                     2m18s

NAME                                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/argocd-applicationset-controller   1/1     1            1           2m18s
deployment.apps/argocd-dex-server                  1/1     1            1           2m18s
deployment.apps/argocd-notifications-controller    1/1     1            1           2m18s
deployment.apps/argocd-redis                       1/1     1            1           2m18s
deployment.apps/argocd-repo-server                 1/1     1            1           2m18s
deployment.apps/argocd-server                      1/1     1            1           2m18s

NAME                                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/argocd-applicationset-controller-7b9c4dfb77   1         1         1       2m18s
replicaset.apps/argocd-dex-server-9b5c6dccd                   1         1         1       2m18s
replicaset.apps/argocd-notifications-controller-756764ddd5    1         1         1       2m18s
replicaset.apps/argocd-redis-69f8795dbd                       1         1         1       2m18s
replicaset.apps/argocd-repo-server-565fb47c89                 1         1         1       2m18s
replicaset.apps/argocd-server-86f64667bc                      1         1         1       2m18s

NAME                                             READY   AGE
statefulset.apps/argocd-application-controller   1/1     2m18s
```

## Get password

```console
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

## Access ArgoCD UI

After installing ArgoCD, access the ArgoCD web UI using port-forwarding:

```console
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

hen, open your web browser and navigate to http://localhost:8080. The user is admin and the password is the output of the step [above](get_password).

![ArgoCD UI](./images/argocd-ui.png)

Further detail in the  following [link](https://apexlemons.com/devops/argocd-on-minikube-on-macos/)



## Deploy Confluet for kubernetes

Login in argo UI and add a new application. Copy and paste the following yaml.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: operator
  annotations:
    argocd.argoproj.io/sync-wave: "1"
spec:
  destination:
    name: ''
    namespace: confluent-dev
    server: 'https://kubernetes.default.svc'
  source:
    path: ''
    repoURL: 'https://packages.confluent.io/helm'
    targetRevision: 0.1193.1
    chart: confluent-for-kubernetes
    helm:
      parameters:
        - name: "namespaced"
          value: "false"
  sources: []
  project: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - ServerSideApply=true
```

Or you can use the argocd cli

```shell
argocd login localhost:8080
argocd app create -f cfk_across_namespace.yaml
```

At the end you will see the following in argocd UI
![ArgoCD UI](./images/operator.png)


## Deploy a Confluet Cloud Cluster

### Create a new Standard cluster

1. Select Cloud provider
2. Fill in "Cluster name"

### Create a new Service Account
1. Navigate to Accounts & access
2. Add a new Service Account
3. Fill in Name and description
4. Assign role "CloudClusterAdmin" to the cluster created in previous step.
5. Finally create Service Account

### Create an API KEY

1. Add a new API Key
2. Select Service Account created in previous step.
3. Create ACL that allow create topic with prefix "demo"


## Deploy a new ArgoCD App for CC

Login in argo UI and add a new application. Copy and paste the following yaml.


```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: confluent-cloud
spec:
  destination:
    namespace: confluent-cloud
    server: 'https://kubernetes.default.svc'
  source:
    path: /data/cloud
    repoURL: https://github.com/sotojuan2/cfk-control-plane-argocd
    targetRevision: HEAD
  sources: []
  project: default
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
    automated:
      prune: false
      selfHeal: false
```

Or you can use the argocd cli

```shell
argocd login localhost:8080
argocd app create -f cfk_confluent_cloud.yaml
```


## Deploy a new ArgoCD App for CP

Login in argo UI and add a new application. Copy and paste the following yaml.


```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: confluent-cp
spec:
  destination:
    namespace: confluent-cp
    server: https://kubernetes.default.svc
  source:
    path: data/CP
    repoURL: https://github.com/sotojuan2/cfk-control-plane-argocd
    targetRevision: HEAD
  sources: []
  project: default
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
    automated:
      prune: false
      selfHeal: false
```

Or you can use the argocd cli

```shell
argocd login localhost:8080
argocd app create -f cfk_confluent_cp.yaml
```