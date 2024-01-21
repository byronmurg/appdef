import {
	KubernetesIngress,
	KubernetesNamespace,
	KubernetesSvc,
	KubernetesHpa,
	KubernetesPod,
} from "./Icons"

export default function specToFlow(spec) {
	const postgresqlDbs = spec.Postgresql.dbs
	const mongoDbs = spec.Mongo.dbs
	const s3Dbs = spec.S3.dbs

	const podScale = new Array(3).fill(true).map((_, i) => i + 1)

	return {
		edges: [
			{
				id: "load_balancer_1-to-ingress",
				from: "load_balancer_1",
				to: "ingress",
				animated: true,
			},
			{
				id: "load_balancer_2-to-ingress",
				from: "load_balancer_2",
				to: "ingress",
				animated: true,
			},
			{
				id: "load_balancer_3-to-ingress",
				from: "load_balancer_3",
				to: "ingress",
				animated: true,
			},
			// Pods to postgresql
			...spec.AllEntries.filter((entry) => entry.container.postgresql?.use).map(
				(entry) => ({
					id: `${entry.fullname}-pg-${entry.container.postgresql.db}`,
					from: entry.fullname,
					to: `postgresql-${entry.container.postgresql.db}`,
					color: "blue",
					parent: "namespace",
				})
			),
			// Pods to mongo
			...spec.AllEntries.filter((entry) => entry.container.mongo?.use).map(
				(entry) => ({
					id: `${entry.fullname}-mongo-${entry.container.mongo.db}`,
					from: entry.fullname,
					to: `mongo-${entry.container.mongo.db}`,
					color: "green",
					parent: "namespace",
				})
			),
			// Pods to s3
			...spec.AllEntries.filter((entry) => entry.container.s3?.use).map(
				(entry) => ({
					id: `${entry.fullname}-s3-${entry.container.s3.db}`,
					from: entry.fullname,
					to: `s3-${entry.container.s3.db}`,
					color: "pink",
					parent: "namespace",
				})
			),
			// Ingress to svc edges
			...spec.AppEntries.filter((entry) => !!entry.container.path).map(
				(entry) => ({
					id: `${entry.fullname}-ingress`,
					from: "ingress-" + (entry.subdomain || ""),
					label: entry.container.path,
					to: entry.fullname + "-svc",
					animated: true,
					parent: "kubernetes",
				})
			),
			// Svc to pod edged
			...spec.AppEntries.flatMap((entry) =>
				podScale.map((n) => ({
					id: entry.fullname + `-svc-pod${n}`,
					from: entry.fullname + "-svc",
					to: entry.fullname + `-pod${n}`,
					color: "cyan",
					parent: entry.fullname,
					animated: true,
				}))
			),
			// Pod to proxy edges
			...spec.AllEntries.flatMap((entry) =>
				(entry.container.external || []).map((ext) => ({
					id: `${entry.fullname}-${ext.name}`,
					from: entry.fullname,
					to: "proxy-" + ext.name,
					animated: true,
					parent: "namespace",
				}))
			),
			// Proxies to gateway
			...spec.ProxyEntries.map((entry) => ({
				id: entry.fullname,
				from: entry.fullname,
				to: "gateway",
				parent: "cloud",
				animated: true,
			})),
			// gateway to internet
			...spec.ProxyEntries.map((entry) => ({
				id: entry.fullname + "-internet",
				from: "gateway",
				to: entry.fullname + "-host",
				parent: "topology",
				animated: true,
			})),
		],
		nodes: [
			{ id: "topology", type: "group", color: "white" },
			{ id: "cloud", text: "cloud", parent: "topology", color: "yellow" },
			{
				id: "internet",
				text: "internet",
				parent: "topology",
				row: 1,
				type: "output",
			},
			{ id: "load_balancer", text: "load balancer", parent: "cloud", row: 0 },
			{ id: "load_balancer_1", text: "zone-1", parent: "load_balancer" },
			{ id: "load_balancer_2", text: "zone-2", parent: "load_balancer" },
			{ id: "load_balancer_3", text: "zone-3", parent: "load_balancer" },
			{
				id: "container_registry",
				text: "container registry",
				parent: "cloud",
				row: 0,
			},
			{
				id: "kubernetes",
				text: "kubernetes",
				parent: "cloud",
				color: "blue",
				row: 1,
			},
			{
				id: "namespace",
				text: "app namespace",
				parent: "kubernetes",
				row: 1,
				icon: KubernetesNamespace,
			},
			{ id: "gateway", text: "gateway", parent: "cloud", row: 2 },
			{
				id: "postgresql",
				text: "postgresql",
				parent: "namespace",
				row: 3,
				hide: !postgresqlDbs.length,
			},
			{
				id: "mongo",
				text: "mongo",
				parent: "namespace",
				row: 3,
				hide: !mongoDbs.length,
			},
			{
				id: "s3",
				text: "s3",
				parent: "namespace",
				row: 3,
				hide: !s3Dbs.length,
			},
			{ id: "proxy", text: "proxy", parent: "namespace", row: 3 },
			{
				id: "ingress",
				parent: "kubernetes",
				text: "ingress",
				icon: KubernetesIngress,
			},
			...spec.Subdomains.map((subdomain) => ({
				id: `ingress-${subdomain}`,
				text: subdomain || "<root>",
				type: "input",
				parent: "ingress",
			})),
			...spec.AppEntries.flatMap((entry) => [
				{
					id: entry.fullname,
					text: entry.name,
					color: "cyan",
					parent: "namespace",
					row: 2,
				},
				{
					id: entry.fullname + "-svc",
					text: "svc",
					color: "cyan",
					parent: entry.fullname,
					icon: KubernetesSvc,
					row: 0,
				},
				{
					id: entry.fullname + "-hpa",
					text: "hpa",
					color: "cyan",
					parent: entry.fullname,
					icon: KubernetesHpa,
					row: 1,
				},
				...podScale.map((n) => ({
					id: entry.fullname + `-pod${n}`,
					text: `pod${n}`,
					color: "cyan",
					parent: entry.fullname + "-hpa",
					icon: KubernetesPod,
					row: 0,
				})),
			]),
			...spec.CronEntries.flatMap((entry) => [
				{
					id: entry.fullname,
					text: entry.name,
					color: "indigo",
					parent: "namespace",
					row: 2,
				},
			]),
			...spec.StartupEntries.flatMap((entry) => [
				{
					id: entry.fullname,
					text: entry.name,
					color: "yellow",
					parent: "namespace",
					row: 2,
				},
			]),
			...spec.ProxyEntries.map((entry) => ({
				id: entry.fullname,
				text: entry.name,
				parent: "proxy",
			})),
			...spec.ProxyEntries.map((entry) => ({
				id: entry.fullname + "-host",
				text: entry.container.hostname,
				parent: "internet",
			})),
			...postgresqlDbs.map((db) => ({
				id: `postgresql-${db.name}`,
				parent: "postgresql",
				color: "blue",
				type: "output",
				text: db.name,
			})),
			...mongoDbs.map((db) => ({
				id: `mongo-${db.name}`,
				parent: "mongo",
				type: "output",
				color: "green",
				text: db.name,
			})),
			...s3Dbs.map((db) => ({
				id: `s3-${db.name}`,
				parent: "s3",
				type: "output",
				color: "pink",
				text: db.name,
			})),
		],
	}
}
