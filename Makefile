pods:
	kubectl --kubeconfig ./admin.conf get pods
svc:
	kubectl --kubeconfig ./admin.conf get svc
nodes:
	kubectl --kubeconfig ./admin.conf get nodes