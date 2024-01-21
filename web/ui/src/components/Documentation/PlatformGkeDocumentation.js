import Diagram from "../Diagram"
import Doc from "../Doc"

export default function PlatformGkeDocumentation() {

	const nodeCount = new Array(3).fill(true).map((_, i) => i)

	function repeatNodes(template) {
		return nodeCount.map((i) => ({
			...template,
			id: `${template.id}_${i}`,
			text: template.text ? `${template.text} ${i}` : ""
		}))
	}

	const graphNodes = [].concat(
		{
			id: "outer",
			color: "white",
			type: "group",
		},
		{
			id: "cloud",
			text: "gcp",
			color: "yellow",
			parent: "outer",
		},
		{
			id: "loadbalancer",
			parent: "cloud",
		},
		repeatNodes({
			id: `loadbalancer`,
			text: `loadbalancer`,
			parent: "loadbalancer",
		}),
		{
			id: "vpc",
			text: "vpc",
			parent: "cloud",
			row: 1,
		},
		{
			id: "service_subnet",
			text: "service subnet (10.7.0.0/16)",
			parent: "vpc",
		},
		{
			id: "example_sevice",
			text: "example service",
			parent: "service_subnet",
		},
		{
			id: "controller_subnet",
			text: "controller subnet (10.9.0.0/16)",
			parent: "vpc",
		},
		nodeCount.map((i) => ({
			id: `controller_${i}`,
			text: `zone ${i} controller`,
			parent: "controller_subnet",
		})),
		{
			id: "node_subnet",
			row: 1,
			text: "pod subnet (10.8.0.0/16)",
			parent: "vpc",
		},
		nodeCount.map((i) => ({
			id: `node_${i}`,
			parent: "node_subnet",
			text: `node ${i}`,
		})),
		nodeCount.map((i) => ({
			id: `example_pod_${i}`,
			parent: `node_${i}`,
			text: `example pod ${i}`,
		})),
	)

	const graphEdges = [].concat(
		nodeCount.map((i) => ({
			from: `loadbalancer_${i}`,
			to: `example_sevice`,
			animated: true,
		})),

		nodeCount.map((i) => ({
			from: `example_sevice`,
			to: `example_pod_${i}`,
			animated: true,
		})),
	)

	return (
		<Doc title="Platform Gke Documentation" >
			Not finished!!
			<Doc title="Network overview" >
				<Diagram nodes={graphNodes} edges={graphEdges} />

				<Doc title="Subnets" >
					<Doc.Details details={{
						"controllers": "10.9.0.0/16",
						"services": "10.7.0.0/16",
						"pods": "10.8.0.0/16",
						"nodes": "none",
					}} />
				</Doc>
			</Doc>
			<Doc title="Overview" >
				<p>
					Platform GKE is effectively a wrapper around this module from google: <br/>
					<a href="https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/master/modules/private-cluster-update-variant" >https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/master/modules/private-cluster-update-variant</a> <br/>
				</p>
				<p>
					Our module simply sets some sensible defaults and assumes some of the scaling and security measures.
				</p>
			</Doc>
			<Doc title="security features" >
				<Doc title="shielded nodes" >
					<p>
						By default we enabled shielded nodes, which requires GCP to verify each node admission, disallowing any external node from joining the cluster, more can be read on this here: <a href="https://cloud.google.com/kubernetes-engine/docs/how-to/shielded-gke-nodes" >here</a>
					</p>
				</Doc>
				<Doc title="private nodes" >
					Cluster nodes are not assigned an individual IP and cannot be addressed even from within the VPC.
				</Doc>
			</Doc>
		</Doc>
	)
}
