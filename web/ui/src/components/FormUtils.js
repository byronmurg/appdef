import * as Icons from "./Icons"
import { Form, Button, Accordion, Container, Row, Col } from "react-bootstrap"

export
function FieldGroup({ label, children, ...rest }) {
	return (
		<Form.Group className="mb-4" {...rest} >
			{label ? <Form.Label>{label}</Form.Label> : ""}
			{children}
		</Form.Group>
	)
}

export
function HelpText(props) {
	return <Form.Text className="text-muted" {...props} />
}

export
function Field({ label, name, onChange, value, children, ...rest }) {
	return (
		<FieldGroup label={label} >
			<Form.Control
				{...rest}
				value={value||""}
				name={name||label}
				onChange={(e) => onChange(e.target.value)}
				onInput={(e) => e.target.reportValidity()}
			/>
			{children ? <HelpText>{children}</HelpText> : ""}
		</FieldGroup>
	)
}

export
function TextField(props) {
	return <Field type="text" {...props} />
}

export
function TextAreaField(props) {
	return <Field as="textarea" rows={3} {...props} />
}

export
function NumberField({ onChange, ...rest }) {
	return <Field type="text" onChange={(v) => onChange(v === ""? undefined : v*1)} {...rest} />
}

export
function SelectField({ label, value, onChange, options }) {
	return (
		<FieldGroup label={label} >
			<Form.Select value={value} onChange={(e) => onChange(e.target.value || undefined)} >
				{options.map((op, i) => (
					<option key={i}>{op}</option>
				))}
			</Form.Select>
		</FieldGroup>
	)
}

export
function SwitchField({ children, onChange, value, label, ...rest }) {
	return (
		<Form.Group >
			<Form.Check
				type="switch"
				onChange={(e) => onChange(e.target.checked)}
				label={label}
				aria-label={label}
				checked={value||false}
				{...rest}
			/>
			{children ? <Form.Text className="text-muted">{children}</Form.Text> : ""}
		</Form.Group>
	)
}

export
function FieldArray({ name, Component, value = [], onChange, defaultValue, root, deleteText }) {
	const formData = [].concat(value)

	if (!Array.isArray(value)) {
		return <p>invalid value. expected array</p>
	}

	const update = (newData) => {
		onChange(newData)
	}

	const addEntry = () => {
		update([defaultValue, ...formData])
	}

	const deleteEntry = (n) => {
		update(formData.filter((_, i) => i !== n))
	}

	const valueSetter = (i, v) => {
		formData[i] = v
		update(formData)
	}

	return (
		<>
			{formData.map((entry, i) => (
				<Row key={i}>
					<Col sm={10}>
						<Component
							value={entry}
							onChange={(v) => valueSetter(i, v)}
							root={root}
						/>
					</Col>
					<Col sm={2}>
						<Button variant="danger" onClick={() => deleteEntry(i)}>
							{deleteText ? deleteText : <Icons.Trash /> }
						</Button>
					</Col>
				</Row>
			))}
			<Row  className="mt-2"  >
				<Col sm={10}>
					<Button aria-label="add" onClick={addEntry} ><Icons.Plus/></Button>
				</Col>
			</Row>
		</>
	)
}

export
function FieldMap({ name, Component, value = {}, onChange, defaultValue, root, deleteText }) {
	const formData = Object.entries(value)

	if (value.constructor !== Object) {
		return <p>invalid value. expected map</p>
	}

	const update = (newData) => {
		//setFormData(newData)
		onChange(Object.fromEntries(newData))
	}

	const addEntry = () => {
		update([["", defaultValue], ...formData])
	}

	const deleteEntry = (n) => {
		update(formData.filter((_, i) => i !== n))
	}

	const keySetter = (i, v) => {
		formData[i][0] = v
		update(formData)
	}

	const valueSetter = (i, v) => {
		formData[i][1] = v
		update(formData)
	}

	return (
		<>
			<Accordion alwaysOpen className="mb-2" >
				{formData.map((entry, i) => (
					<Accordion.Item eventKey={i} key={i}>
						<Accordion.Header>
							<Form.Control type="text" style={{ width:"16rem" }} value={entry[0]} onChange={(v) => keySetter(i, v.target.value)} onClick={(e) => e.stopPropagation()} />
						</Accordion.Header>
						<Accordion.Body>
							<Container fluid>
								<Row>
									<Col>
										<Component
											value={entry[1]}
											onChange={(v) => valueSetter(i, v)}
											root={root}
										/>
									</Col>
								</Row>
								<Row className="pt-5" >
									<Col>
										<Button variant="danger" onClick={() => deleteEntry(i)}>
											{deleteText ? deleteText : <Icons.Trash /> }
										</Button>
									</Col>
								</Row>
							</Container>
						</Accordion.Body>
					</Accordion.Item>
				))}
			</Accordion>
			<Button aria-label="add" onClick={addEntry} ><Icons.Plus/></Button>
		</>
	)
}

export
function FormSection({ title, children }) {
	return (
		<div className="pt-4" >
			<h5>{title}</h5>
			{children}
			<hr/>
		</div>
	)
}

