import { Clipboard } from "./Icons"
import { Button } from "react-bootstrap"
import "./CopyBox.css"

export default function CopyBox({ value, ...rest }) {
	return (
		<Button className="copy-box" style={{ cursor:"copy" }}
			onClick={() => {
				navigator.clipboard.writeText(value)
			}}
			{...rest}
		>
			<Clipboard />
		</Button>
	)
}
