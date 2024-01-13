import ReactFlow, { Background, Controls } from "react-flow-renderer"
import { Image } from "react-bootstrap"

class Cell {
	paddingX = 10
	paddingY = 20
	marginX = 5
	marginY = 10
	minWidth = 80
	minHeight = 25

	static addReducer(l, r) {
		return l + r
	}

	constructor(node, parent, allNodes) {
		this.id = node.id
		this.text = node.text || ""
		this.row = node.row || 0
		this.type = node.type
		this.icon = node.icon
		this.hide = node.hide || false
		this.parent = parent
		this.parentId = node.parent
		this.color = node.color || "dark"
		this.children = allNodes
			.filter((n) => n.parent === node.id) // Get nodes with this is as parent
			.filter((node) => !node.hide) // Remove any hidden nodes
			.map((child) => new Cell(child, this, allNodes)) // Bless as Cell
	}

	get previousSiblings() {
		if (!this.parent) {
			return []
		}

		const siblings = this.parent.children,
			ret = []

		for (const node of siblings) {
			if (node.id === this.id) {
				break
			}

			ret.push(node)
		}

		return ret
	}

	get previousSameRowSiblings() {
		return this.previousSiblings.filter((sibling) => sibling.row === this.row)
	}

	get siblings() {
		return this.parent
			? this.parent.children.filter((child) => child.id !== this.id)
			: []
	}

	get maxRow() {
		return Math.max(0, ...this.children.map((child) => child.row))
	}

	get childrenByRow() {
		const rows = []

		if (!this.children.length) {
			return rows
		}

		for (let i = 0; i <= this.maxRow; i++) {
			rows[i] = []
		}

		this.children.forEach((child) => {
			rows[child.row].push(child)
		})
		return rows
	}

	get rowWidths() {
		return this.childrenByRow.map((row) =>
			row.map((child) => child.outerWidth).reduce(Cell.addReducer, 0)
		)
	}

	get innerWidth() {
		return Math.max(this.minWidth, ...this.rowWidths) + this.paddingX * 2
	}

	get outerWidth() {
		return this.innerWidth + 2 * this.marginX
	}

	get offsetX() {
		if (! this.parent) {
			return 0
		}

		return (
			this.previousSameRowSiblings
				.map((sibling) => sibling.outerWidth)
				.reduce(Cell.addReducer, 0) +
			this.marginX +
			this.paddingX
		)
	}

	maxComputedHeightForRow(row) {
		return Math.max(0, ...this.childrenByRow[row].map((child) => child.computedHeight))
	}

	get rowHeights() {
		return this.childrenByRow.map((row) =>
			Math.max(0, ...row.map((child) => child.outerHeight))
		)
	}

	get lowerRowHeights() {
		if (!this.parent) {
			return []
		}

		return this.parent.rowHeights.filter((_, i) => i < this.row)
	}

	get offsetY() {
		if (! this.parent) {
			return 0
		}

		return (
			this.lowerRowHeights.reduce(Cell.addReducer, 0) +
			this.paddingY +
			this.marginY
		)
	}

	get computedHeight() {
		const rowHeights = this.rowHeights
		if (rowHeights.length) {
			const combinedRowHeights = rowHeights.reduce(Cell.addReducer, 0)
			return Math.max(this.minHeight, combinedRowHeights) + this.paddingY * 2
		} else {
			return this.minHeight
		}
	}

	get innerHeight() {
		if (this.parent) {
			return Math.max(this.computedHeight, this.parent.maxComputedHeightForRow(this.row))
		} else {
			return this.computedHeight
		}
	}

	get outerHeight() {
		return this.innerHeight + this.marginY * 2
	}

	toFlow() {
		return [this._toFlow(), ...this.children.flatMap((child) => child.toFlow())]
	}

	_toFlow() {
		let label = this.text
		if (this.icon) {
			label = (
				<>
					{this.text}
					<Image height={16} width={16} src={this.icon} />
				</>
			)
		}

		return {
			id: this.id,
			parentNode: this.parentId,
			extent: this.parentId ? "parent" : undefined,
			type: this.type,
			data: {
				label,
			},
			position: {
				x: this.offsetX,
				y: this.offsetY,
			},
			style: {
				width: this.innerWidth,
				height: this.innerHeight,
				background: this.children.length ? "rgba(255, 255, 255, 0)" : "",
				border: `2px solid var(--bs-${this.color})`,
				//fontSize: "1rem",
				padding: "2px",
			},
		}
	}
}

export default
function Diagram({ nodes = [], edges = [] }) {

	// We only need to run createSubNodes for the top-level nodes
	const topLevelNodes = nodes.filter((node) => !node.parent)

	const rootCells = topLevelNodes.map((node) => new Cell(node, null, nodes))

	const initialNodes = rootCells.flatMap((cell) => cell.toFlow())

	const initialEdges = edges.map((edge) => ({
		id: edge.id,
		source: edge.from,
		target: edge.to,
		label: edge.label,
		animated: edge.animated || false,
		// Use the bootstrap color if one is set
		style: edge.color ? { stroke: `var(--bs-${edge.color})` } : undefined,
		type: "smoothstep",
		labelStyle: {
			//fontSize: "1rem",
		}
	}))

	const maxHeight = Math.max(...rootCells.map((cell) => cell.outerHeight))

	return (
		<div style={{ height:maxHeight*0.6, width:"100%" }} >
			<ReactFlow
				defaultNodes={initialNodes}
				defaultEdges={initialEdges}
				fitView={true}
				nodesDraggable={false}
				nodesConnectable={false}
			>
				<Controls className="print-hide" />
				<Background color="#aaa" gap={16} />
			</ReactFlow>
		</div>
	)
}

