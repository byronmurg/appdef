import { useState } from "react"
import { Row, Button, Col } from "react-bootstrap"
import YamlBox from "./YamlBox"
import SchemaForm from "./SchemaForm"
import RenderPage from "./RenderPage"

export default function SpecBox() {
	const [spec, setSpec] = useState({ spec_version: 1, name: "myapp" })
	const [inRender, setInRender] = useState(false)

	const onFormSubmit = (e) => {
		e.preventDefault()
		setInRender(true)
	}

	if (inRender) {
		return (
			<>
				<div className="print-hide" >
					<Row>
						<Col>
					<h3>Rendering {spec.name}</h3>
						</Col>
						<Col >
					<Button variant="primary" style={{float:"right"}} onClick={() => setInRender(false)}>
						edit
					</Button>
						</Col>
					</Row>
				</div>
				<RenderPage spec={spec} />
			</>
		)
	}

	return (
		<Row>
			<Col sm={8}>
				<SchemaForm value={spec} onChange={setSpec} onSubmit={onFormSubmit} />
			</Col>
			<Col sm={4}>
				<div className="sticky-top">
					<YamlBox value={spec} onChange={setSpec} defaultValue="spec_version: 1" />
				</div>
			</Col>
		</Row>
	)
}
