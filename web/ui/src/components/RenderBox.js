import {useState, useEffect} from "react"
import {Alert} from "react-bootstrap"
import {render} from "./Api"
import LoadingBox from "./LoadingBox"
import CodeOutput from "./CodeOutput"

export default
function RenderBox({ type, spec, templateVars, language }) {
	const [res, setRes] = useState(null)

	useEffect(() => {
		render({ type, spec, templateVars }).then(setRes)
	}, [spec, type, templateVars])

	if (res === null) {
		return <LoadingBox/>
	}

	if (res.error) {
		return (
			<Alert variant="danger" >{res.error}</Alert>
		)
	}

	if (res.format_errors) {
		return (
			res.format_errors.map((err, i) => <Alert variant="warning" key={i}>{err}</Alert>)
		)
	}

	return <CodeOutput language={language} lineNumbers >{res.output}</CodeOutput>
}

