import {useState} from "react"
import {default as YAML} from "yaml"
import { Form, Alert } from "react-bootstrap"
import CopyBox from "./CopyBox"

export default
function YamlBox({ value, onChange, defaultValue }) {
	const yamlValue = YAML.stringify(value)
	const [strValue, setStrValue] = useState("")
	const [yamlErr, setYamlErr] = useState(null)

	const onSubmit = (e) => {
		e.preventDefault()

		try {
			const yamlStruct = YAML.parse(strValue)
			setYamlErr(null)
			setStrValue("")
			onChange(yamlStruct)
		} catch (err) {
			setYamlErr(err.message)
		}
	}

	return (
		<Form onSubmit={onSubmit} className="copy-box-parent" >
			<CopyBox value={strValue||yamlValue} />
			<Form.Control as="textarea" style={{ height:"80vh" }}
				onChange={(e) => setStrValue(e.target.value||defaultValue)}
				aria-label="yaml box"
				value={strValue||yamlValue}
			/>
			{ yamlErr ? <Alert variant="warning" >{yamlErr}</Alert> : "" }
			<Form.Control className="mt-2"
				type="submit" onSubmit={onSubmit} value="update"
				disabled={!strValue}
			/>
		</Form>
	)
}
