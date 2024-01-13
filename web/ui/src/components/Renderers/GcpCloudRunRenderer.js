import {useState} from "react"
import { TextField } from "../FormUtils"
import RenderBox from "../RenderBox"
import { Alert } from "react-bootstrap"
import SideTabs from "../SideTabs"

function GihubWorkflowRenderer({ spec }) {
	const [SecretPrefix, setSecretPrefix] = useState("DEV_")
	const [BucketName, setBucketName] = useState("")
	return (
		<>
			<TextField label="bucket name" value={BucketName} onChange={setBucketName} />
			<TextField
				label="secret prefix"
				value={SecretPrefix}
				onChange={setSecretPrefix}
			/>
			<RenderBox type="github-gcp-cloud-run" spec={spec} language="yaml" templateVars={{BucketName,SecretPrefix}} />,
		</>
	)
}

export default function GcpCloudRunRenderer({ spec }) {
	return (
		<>
			<Alert variant="warning" >
				GCP cloud-run support is focused on very low-budget clients. It does not support
				any dbs or cron jobs. It is also not considered high-security. If you require any
				of these features a kubernetes cluster is cheaper and more versatile.
			</Alert>
			<SideTabs components={{
					"Terraform": <RenderBox type="gcp-cloud-run" spec={spec} language="hcl" />,
					"Github workflow": <GihubWorkflowRenderer spec={spec} />,
				}} />
		</>
	)

}
