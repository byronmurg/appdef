import { useState } from "react"
import RenderBox from "../RenderBox"
import { TextField } from "../FormUtils"
import KubernetesDocumentation from "../Documentation/KubernetesDocumentation"
import SideTabs from "../SideTabs"

function KubernetesGithubRenderer({ spec }) {
	const [SecretPrefix, setSecretPrefix] = useState("DEV_")

	return (
		<>
			<TextField
				label="secret prefix"
				value={SecretPrefix}
				onChange={setSecretPrefix}
			/>

			<RenderBox type="github-gke" spec={spec} templateVars={{ SecretPrefix }} language="yaml" />
		</>
	)
}

export default function KubernetesRenderer({ spec }) {

	return <SideTabs components={{
		"Terraform": <RenderBox type="k8s" spec={spec} language="hcl" />,
		"Documentation": <KubernetesDocumentation spec={spec} />,
		"Github workflow": <KubernetesGithubRenderer spec={spec} />,
	}} />
}
