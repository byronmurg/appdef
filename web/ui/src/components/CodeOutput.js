import CopyBox from "./CopyBox"
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import style from './CodeOutputStyle';

export default
function CodeOutput({ children, language, lineNumbers=false }) {

	return (
		<div className="copy-box-parent border-2 border rounded" >
			<CopyBox value={children} />
			<SyntaxHighlighter language={language} showLineNumbers={lineNumbers} style={style} >{children}</SyntaxHighlighter>
		</div>
	)
}
