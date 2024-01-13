import {useState, useEffect} from "react"

const prefix = "/api"

export
function useGet(path) {
	const [data, setData] = useState(null)

	useEffect(() => {
		fetch(prefix+path)
			.then(res => res.json())
			.then((json) => {
				setData(json)
			})
	}, [path])

	return data
}

export
function render({ type, spec, templateVars = {} }) {
	return fetch(prefix+"/render/"+type, {
		method:"POST",
		headers: {
			"Content-Type": "application/json",
		},
		body: JSON.stringify({ spec, templateVars })
	})
		.then(res => res.json())
}
