import { Table } from "react-bootstrap"
import "./Doc.css"

function Doc({ title="", children, show=true, ...rest }) {
	return (
		<div className="doc-section" style={{ display:show?"block":"none" }} {...rest}>
			<h3>{title}</h3>
			<div className="doc-section-body" >{children}</div>
		</div>
	)
}

Doc.Details = function({ details }) {
	return (
		<Table striped bordered>
			<tbody>
				{Object.entries(details)
					.filter(([_, value]) => !!value)
					.map(([key, value]) => (
						<tr key={key}>
							<td style={{ width:"50%" }} >{key}</td>
							<td>{value.toString()}</td>
						</tr>
					))}
			</tbody>
		</Table>
	)
}

export default Doc
