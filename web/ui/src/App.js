import { BrowserRouter as Router, Routes, Link, Route } from "react-router-dom"
import { Container, Col, Row, Nav, Navbar, NavDropdown } from "react-bootstrap"
import "./themes/appdef.css"
import "./App.css"

import Logo from "./components/Logo"
import SpecBox from "./components/SpecBox"
import PlatformGkeDocumentation from "./components/Documentation/PlatformGkeDocumentation"
import PlatformK8sToolsDocumentation from "./components/Documentation/PlatformK8sToolsDocumentation"
import DockerDocumentation from "./components/Documentation/DockerDocumentation"
import SecurityPrinciplesDocumentation from "./components/Documentation/SecurityPrinciplesDocumentation"


function AppRoutes() {
	return (	
		<Routes>
			<Route path="/docs/gke" element={<PlatformGkeDocumentation />} />
			<Route path="/docs/k8stools" element={<PlatformK8sToolsDocumentation />} />
			<Route path="/docs/docker" element={<DockerDocumentation />} />
			<Route path="/docs/security" element={<SecurityPrinciplesDocumentation />} />
			<Route path="" element={<SpecBox />} />
		</Routes>
	)
}

function App() {
	return (
		<Router>
		<div className="fullscreen">
			<Navbar bg="primary" expand="lg" className="header-bar" >
				<Container fluid>
					<Col sm="auto" >
					<Navbar.Brand>
						<Link to="/" >
							<Logo height="40" width="150" />
						</Link>
					</Navbar.Brand>
					</Col>
					<Col></Col>
					<Col sm="auto" className="print-hide" >
						<Row>
						<Col>
							<NavDropdown title="docs" >
								<NavDropdown.Item as={Link} to="/docs/security" >Security Principles</NavDropdown.Item>
								<NavDropdown.Item as={Link} to="/docs/docker" >Docker</NavDropdown.Item>
								<NavDropdown.Item as={Link} to="/docs/gke" >Platform GKE</NavDropdown.Item>
								<NavDropdown.Item as={Link} to="/docs/k8stools" >Platform K8s Tools</NavDropdown.Item>
							</NavDropdown>
						</Col>
						<Col>
							<Nav.Link href="https://github.com/appdef.io/appdef/tree/main/tool" >cli</Nav.Link>
						</Col>
						<Col >
							<Nav.Link as={Link} to="/" >spec</Nav.Link>
						</Col>
						</Row>
					</Col>
				</Container>
			</Navbar>
			<Container className="main-body pt-4" >
				<AppRoutes />
			</Container>
			<footer className="bg-primary" >
				Copyright © appdef.io 2022
			</footer>
		</div>
		</Router>
	)
}

export default App
