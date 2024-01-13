import specToFlow from "./specToFlow"
import Diagram from "./Diagram"

export default
function SpecDiagram({ spec }) {
	const { nodes, edges } = specToFlow(spec)
	return <Diagram nodes={nodes} edges={edges} />
}
