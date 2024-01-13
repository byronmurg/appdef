import { Tab, Row, Col, Nav } from "react-bootstrap"

export default function SideTabs({ components, ...rest }) {
	const defaultKey = Object.keys(components)[0] || ""

	return (
		<Tab.Container defaultActiveKey={defaultKey} {...rest}>
			<Row>
				<Col sm={2} className="print-hide">
					<Nav variant="pills" className="flex-column" style={{ cursor:"pointer" }} >
						{Object.keys(components).map((k) => (
							<Nav.Item key={k}>
								<Nav.Link eventKey={k}>{k}</Nav.Link>
							</Nav.Item>
						))}
					</Nav>
				</Col>
				<Col sm={8}>
					<Tab.Content>
						{Object.entries(components).map(([k, Component]) => (
							<Tab.Pane eventKey={k} key={k}>
								{Component}
							</Tab.Pane>
						))}
					</Tab.Content>
				</Col>
				<Col sm={2} className="print-hide" ></Col>
			</Row>
		</Tab.Container>
	)
}
