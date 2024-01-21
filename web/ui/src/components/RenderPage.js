import { Tabs, Tab } from "react-bootstrap"
import KubernetesRenderer from "./Renderers/KubernetesRenderer"
import GcpCloudRunRenderer from "./Renderers/GcpCloudRunRenderer"
import Spec from "./Spec"

export default function RenderPage({ spec }) {

	spec = new Spec(spec)

	return (
		<Tabs defaultActiveKey="k8s" className="m-3" mountOnEnter >
			<Tab eventKey="k8s" title="Kubernetes">
				<KubernetesRenderer spec={spec} />
			</Tab>
			<Tab eventKey="gcp-cloud-run" title="Cloud run">
				<GcpCloudRunRenderer spec={spec} />
			</Tab>
		</Tabs>
	)
}
