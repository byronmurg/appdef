import Doc from "../Doc"

export default function PlatformK8sToolsDocumentation() {
	return (
		<Doc title="Platform K8s Tools">
			<p>
				Platform K8s tools are a set of recommended Kubernetes cluster level
				tools. Each one can be disabled in terraform. They are designed to be
				platform agnostic and can be used in almost any type of kubernetes
				cluster.
			</p>

			<Doc title="Nginx Ingress Controller">
				<p>
					An ingress controller is a standardised way of routing HTTP traffic
					into a kubernetes cluster.
				</p>
				<p>
					We use a standard nginx controller, deployed via Helm chart.
				</p>
			</Doc>

			<Doc title="Grafana and Loki">
				<p>
					A Grafana/Loki/Prometheus stack is installed as standard to collect
					and aggregate cluster metrics and logs. This can be accessed at
					grafana.BASE_DOMAIN and, by default, required both oauth and password
					authentication. The oauth is the primary security barrier and the
					password can be retained by developers.
				</p>
				<p>
					We can install some Rad default dashboards but we encourage developers
					and clients to alter these to suit their needs.
				</p>
				<p>
					The stack is installed via grafana's official Loki-stack helm chart and
					should be updated in accordance.
				</p>
				<p>
					We recommend installing metrics intgration which can take different forms
					depending on the platform-setup. The baseline is to use the metrics-server
					helm chart.
				</p>
				<p>
					As the ServiceMontor api may not be available in all circumstances we
					use the promethues scrape annotations e.g. <code> prometheus.io/port: '80' </code>
				</p>
				<p>
					If the oauth-proxy is not enabled no ingress will be created for grafana.
				</p>
			</Doc>

			<Doc title="Letsencrypt and CertManager">
				<p>
					For the provisioning of SSL certificates we deploy Certmanager with letsencrypt
					configuration. This is useful primarily for development systems but can also be
					used securely for production systems.
				</p>
				<p>
					As the CertificatRequest api may not always be available we prefer usage of the
					ingress annotation <code> cert-manager.io/cluster-issuer </code> for certificate
					assignment.
				</p>
			</Doc>

			<Doc title="External-DNS">
				<p>
					For the creation of DNS records for new deployments we use external-dns. 
				</p>
				<p>
					At configuration time the service needs to be granted usage over a cloud
					service account that can alter DNS. See the github page for how this is
					configured for different DNS providers: <a href="https://github.com/kubernetes-sigs/external-dns" >here</a>
				</p>
				<p>
					This is deployed via the Bitnami Helm chart.
				</p>
			</Doc>

			<Doc title="Oauth-Proxy">
				<p>
					Oauth proxy allows us to apply an oauth check barrier in-front of services within
					the cluster. By having a cetralised service development environments ban be created
					on-the-fly without having to create new oauth credentials.
				</p>
				<p>
					In order to apply the security barrier ingresses can use nginx's auth_request
					functionality, which makes a seperate HEAD request to the proxy with the initial
					request's headers before continuing to resolve the request. This can be used
					by ingress objects by setting the annotations: <code> "nginx.ingress.kubernetes.io/auth-signin":"https://URL/oauth2/start?rd=https://$host$escaped_request_uri", "nginx.ingress.kubernetes.io/auth-url":"https://URL/oauth2/auth" </code>.
				</p>
			</Doc>
		</Doc>
	)
}
