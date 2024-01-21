import SpecDiagram from "../SpecDiagram"
import Doc from "../Doc"

export default function KubernetesDocumentation({ spec }) {
	return (
		<Doc title={`${spec.name} documentation`}>
			<Doc title="overview">
				<SpecDiagram spec={spec} />
			</Doc>

			<BasicDocumentation spec={spec} />

			<AppsDocumentation spec={spec} />
			<CronDocumentation spec={spec} />
			<StartupDocumentation spec={spec} />

			<DatabasesDocumentation spec={spec} />

			<MaintenenceDocumentation spec={spec} />
		</Doc>
	)
}

function BasicDocumentation({ spec }) {
	return (
		<>
			<Doc title="Concepts">
				<Doc title="High-avalability and Standalone modes">
					<p>
						{spec.name} is designed with a scale switch which will henceforth be
						refered to as <b>HA</b>.
					</p>
					<p>
						HA mode increases the deployment durability and throughput at the
						expense of computing cost.
					</p>
					<p>
						In HA mode each service is set to autoscale on CPU metrics with a
						lower scale of 3. Also for each database it's respective clustering
						method is enabled and a seperate cluster is created for each logical
						database.
					</p>
					<p>
						HA is enabled by default and controlled through the
						<code> HA </code>
						terraform variable.
					</p>
				</Doc>

				<Doc title="Production and Development modes">
					<p>
						{spec.name} can be run in development mode which reduces the
						storage, cpu, and memory requirements for each component. It also
						enables some extended debugging metrics for enabled components.
					</p>
					<p>
						Development mode is disabled by default and can be enabled with the
						<code> DEV_MODE </code> terraform variable.
					</p>
				</Doc>
			</Doc>

			<Doc title="Cluster Requirements">
				<Doc title="Ingress controller">
					<p>
						{spec.name} requires the use of an ingress controller to route
						traffic to internal services.
					</p>
					<p>
						Nginx is the default ingressClass but any ingress controller that
						supports the <code> Prefix </code>
						pathType is supported. To change the ingress class of all ingresses
						set the <code> INGRESS_CLASS_NAME </code>
						terraform variable.
					</p>
				</Doc>

				<Doc title="Network policy">
					<p>
						{spec.name} relies heavily on network-policies for in-cluster
						security and as such it is a required api. In development Calico was
						tested but any NetworkPolicy provider should work fine.
					</p>
				</Doc>
			</Doc>
		</>
	)
}

function AppsDocumentation({ spec }) {
	return (
		<Doc title="services">
			{spec.AppEntries.map((entry) => (
				<EntryDocumentation key={entry.fullname} entry={entry} spec={spec} />
			))}
		</Doc>
	)
}

function CronDocumentation({ spec }) {
	if (!spec.CronEntries.length) {
		return ""
	}

	return (
		<Doc title="services">
			{spec.CronEntries.map((entry) => (
				<EntryDocumentation key={entry.fullname} entry={entry} spec={spec} />
			))}
		</Doc>
	)
}

function StartupDocumentation({ spec }) {
	if (!spec.StartupEntries.length) {
		return ""
	}

	return (
		<Doc ttile="services">
			{spec.StartupEntries.map((entry) => (
				<EntryDocumentation key={entry.fullname} entry={entry} spec={spec} />
			))}
		</Doc>
	)
}

function EntryDocumentation({ entry, spec }) {
	const { container, name } = entry

	return (
		<Doc title={name}>
			<p>{container.description}</p>
			<Doc.Details
				details={{
					schedule: container.schedule,
					"externaly accessible": !!container.path,
					"url path": container.path,
					subdomain: container.subdomain,
					"postgresql database": container.postgresql?.db,
					"mongo database": container.mongo?.db,
					"s3 database": container.s3?.db,
					"external apis": container.external
						?.map((ext) => ext.name)
						.join(", "),
				}}
			/>
		</Doc>
	)
}

function PostgresqlDocumentation({ db, spec, ...rest }) {
	return (
		<Doc title="Postgresql" {...rest}>
			<p>
				Postgresql is used by {spec.name} as it's relational database. In all
				modes this is deployed via a bitnami helm chart for ease of maintenance
				and upgrade.
			</p>

			<Doc title="High-availability">
				<p>
					In high availability mode a new postgresql pool is created for each
					logical database with each client connecting with unique credentials
					and allowed by network policy to only it's preconfigured logical
					database.
				</p>

				<p>
					Each pool consists of 3 postgresql replicas which copy the schema and
					data from other existing instance on startup, and a pgpool instance to
					ensure consistency across replicase. Pgpool works by diverting select
					requests to a single instane but repeating alteration requests to each
					replica.
				</p>
			</Doc>

			<Doc title="Standalone">
				<p>
					With standalone mode a single postgresql instance is created with all
					logic databases residing on the one host. Each client has unique
					credentials to it's preconfigured logical database.
				</p>
			</Doc>
		</Doc>
	)
}

function MongoDocumentation({ db, spec, ...rest }) {
	return (
		<Doc title="Mongo" {...rest}>
			<p>TODO write some mongo docs</p>
		</Doc>
	)
}

function S3Documentation({ db, spec, ...rest }) {
	return (
		<Doc title="S3" {...rest}>
			<p>
				When refering to S3 we may actually be using an S3 alternative, such as
				GCP storage buckets, minio, etc.
			</p>
			<p>TODO write some s3 docs</p>
		</Doc>
	)
}

function MaintenenceDocumentation({ spec }) {
	return (
		<Doc title="Maintenence">
			<Doc title="Disk usage" show={spec.UsesAnyDbs()}>
				<p>
					Initially the size of each db instance volume has been set to 64Gi for
					"prod" mode and 8Gi for "dev" mode. You should ensure that
					volume-expansion is allowed on the host cluster's storageClass to
					allow later expansion without dissruption. If this is not possible
					then expansion (<b>in ha mode</b>) requires an engineer to increase
					the volumeclaim as defined in the deployment terraform then, for each
					instance, delete the underlying pvc, then delete the pod and allow the
					startup replication to complete before continuing to other pods.
				</p>
			</Doc>
			<Doc title="Updates">
				<p>
					Some of the external components used by {spec.name} utilize Helm
					charts for deployment. Even when using an RDS it is wise to keep these
					up-to-date as they can be used for development systems.
				</p>
				<p>
					All of these chat versions are at the start of the{" "}
					<code> deploy.tf </code>
					in the locals section. Just replace the version string with the latest
					chart version and deploy to a test environment.
				</p>
				<p>
					There is also the busybox image which is just used as an
					init-container to check that dependent services are online. This is a
					low-priority update as they only run at startup. To update this you
					can also change the version string at the top of the{" "}
					<code> deploy.tf </code>.
				</p>
			</Doc>
		</Doc>
	)
}

function DatabasesDocumentation({ spec }) {
	return (
		<Doc title="Databases" show={spec.UsesAnyDbs()}>
			<PostgresqlDocumentation
				db={spec.Postgresql}
				spec={spec}
				show={spec.Postgresql.enabled}
			/>
			<MongoDocumentation
				db={spec.Mongo}
				spec={spec}
				show={spec.Mongo.enabled}
			/>
			<S3Documentation db={spec.S3} spec={spec} show={spec.S3.enabled} />
		</Doc>
	)
}
