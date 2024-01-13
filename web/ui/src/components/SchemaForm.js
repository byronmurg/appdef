import { Form } from "react-bootstrap"
import CodeExample from "./CodeExample"
import {
	FormSection,
	FieldGroup,
	HelpText,
	TextAreaField,
	TextField,
	NumberField,
	SelectField,
	SwitchField,
	FieldMap,
	FieldArray,
} from "./FormUtils"

function ExternalSelector({ value = {}, root, onChange }) {
	const externalNames = Object.keys(root.external || {})

	return (
		<SelectField
			value={value.name || ""}
			onChange={(e) => onChange({ ...value, name: e.target.value })}
			options={externalNames}
		/>
	)
}

function DbSelector({ name, onChange, value = {}, root = {}, dbPriviledge = false }) {
	const dbNames = root[name]?.dbs?.map((db) => db.name) || [] //@TODO You're better than this Byron

	if (dbNames.length === 0) {
		// Don't render at all if there are no dbs
		return ""
	}

	return (
		<FormSection title={name}>
			<SwitchField
				value={value.use || false}
				label="use"
				onChange={(use) => onChange({ ...value, use })}
			/>
			<SelectField
				value={value.db}
				onChange={(db) => onChange({ ...value, db })}
				options={["", ...dbNames]}
			/>
			{ dbPriviledge ? <SwitchField value={value.priviledged} label="priviledged" onChange={(priviledged) => onChange({ ...value, priviledged })} /> :"" }
		</FormSection>
	)
}

function DbEntry({ value, onChange }) {
	return (
		<TextField
			value={value.name || ""}
			onChange={(name) => onChange({ ...value, name })}
			pattern="[A-Z,a-z]{1,16}"
			title="Can only be 1-16 alphabetical characters"
		>
			Name of the logical database
		</TextField>
	)
}

function DbForm({ value = {}, onChange, root }) {
	return (
		<>
			<SwitchField
				label="enabled"
				value={value.enabled}
				onChange={(enabled) => onChange({ ...value, enabled })}
			/>
			<FieldGroup label="dbs">
				<FieldArray
					value={value.dbs}
					onChange={(dbs) => onChange({ ...value, dbs })}
					Component={DbEntry}
					defaultValue={{ name: "" }}
				/>
			</FieldGroup>
		</>
	)
}

function ExternalPortField(props) {
	return <NumberField placeholder="e.g. 443" min="0" max="65536" {...props} />
}

function ExternalForm({ value = {}, onChange, root }) {
	return (
		<>
			<TextField
				label="hostname"
				value={value.hostname}
				onChange={(hostname) => onChange({ ...value, hostname })}
				placeholder={`e.g. www.bbc.co.uk`}
				pattern="[A-Z,a-z,0-9,-,\\.]{1,255}"
				title="must be a valid fqdn"
			>
				The hostname of the external service. This should just be the fqdn as
				called from your application.
			</TextField>
			<FieldGroup label="ports">
				<FieldArray
					value={value.ports}
					onChange={(ports) => onChange({ ...value, ports })}
					Component={ExternalPortField}
				/>
				<HelpText>
					The remote ports that your app needs to connect to. For HTTP
					connections please only open port 443
				</HelpText>
			</FieldGroup>
		</>
	)
}

function ExternalSelectorField({ value = [], onChange, root }) {
	if (Object.keys(root.external || {}).length === 0) {
		//Don't even render if there are no externals
		return ""
	}

	return (
		<FormSection title="external">
			<FieldArray
				value={value}
				root={root}
				onChange={onChange}
				Component={ExternalSelector}
				defaultValue={{}}
			/>
			<HelpText>
				Which external endpoints, defined at the top-level, this container can
				connect to. Please don't add endpoints unless this conatiner needs it.
			</HelpText>
		</FormSection>
	)
}

function SecretSelector({ value = {}, onChange, root }) {
	return (
		<>
			<TextField
				label="var"
				value={value.var}
				onChange={(v) => onChange({ ...value, var: v })}
				placeholder="e.g. API_KEY"
				pattern="[A-Z,_]{1,32}"
				title="Can only be underscores or captial letters"
				required
			>
				The key in the secret source to use. Also the environment variable which
				this will be mounted in your container.
			</TextField>
			<TextField
				label="description"
				value={value.description}
				onChange={(description) => onChange({ ...value, description })}
				required
			>
				A brief description of this secret.
			</TextField>
		</>
	)
}

function SecretSelectorField({ value = [], onChange, root }) {
	return (
		<FormSection title="secrets">
			<FieldArray
				value={value}
				root={root}
				onChange={onChange}
				Component={SecretSelector}
				defaultValue={{}}
			/>
			<HelpText>
				Define which secrets this component needs. This defines the secret key
				in the secret-source <b>NOT THE ACTUAL SECRET</b>.
			</HelpText>
		</FormSection>
	)
}

function CommonContainerForm({ value = {}, onChange, root, children, dbPriviledge = false }) {
	const makeSetter = (k) => {
		return (v) => onChange({ ...value, [k]: v })
	}

	return (
		<>
			<TextAreaField
				label="description"
				value={value.description || ""}
				onChange={makeSetter("description")}
				placeholder={`e.g. ${root.name} api service ...blah blah`}
				title="Make it at least 3 characters and max 256, the more the better."
				pattern=".{3,256}"
				required
			>
				A description of this component. This may be used in documentation
				generation so remember that a client may see it.
			</TextAreaField>

			<TextField
				label="image"
				value={value.image || ""}
				onChange={makeSetter("image")}
				placeholder={`e.g. ${root.name}-api`}
				title="must be 1-32 alphanimeric, '_' or '-' characters"
				pattern="(\.|\d|_|-|\w|/){1,32}"
				required
			>
				Docker image name. Don't include the tag or repo! You can just make
				something up but it needs to be unique to the client or exist already in
				their docker repo.
			</TextField>

			<TextField
				label="build"
				value={value.build || ""}
				onChange={makeSetter("build")}
				placeholder={`e.g. api/`}
			>
				Directory where the Dockerfile is located relative to the root of the
				repo. You don't need this field if using a static <b>tag</b>.
			</TextField>

			<TextField
				label="tag"
				value={value.tag || ""}
				onChange={makeSetter("tag")}
				placeholder={`e.g. f6573b7b308ad38fb0c42528f06257b16b7e4b74 or some commit ref`}
				title="must be 1-32 alphanimeric, '.' or '-' characters"
				pattern="(\.|\d|-|\w){1,32}"
			>
				Explicitly set the build tag. Only set this field if you need to use a
				specific version of this container. This is useful for versioned apis or
				startup images. Typically CI workflow won't build a new image if this
				field is set.
			</TextField>

			{children}

			<NumberField
				label="user"
				value={value.user}
				onChange={makeSetter("user")}
				placeholder="e.g. 1001"
				type="number"
				min="1000"
				max="65536"
			>
				For extra security we can force the docker container to run as a
				specific user_id. If you already have a <code>USER foo</code> line in
				your Dockerfile this is not required.
			</NumberField>

			<SwitchField
				label="read only"
				value={value.read_only}
				onChange={makeSetter("read_only")}
			>
				For added security we can mount the container's ephemeral file system as
				read_only. This means that a malicious process cannot
				download/upload/compile any unauthorised code on this container. This
				feature is recommended but may break some applications that use local
				caches e.g. NextJs, Nginx
			</SwitchField>

			<SecretSelectorField
				value={value.secrets}
				root={root}
				onChange={makeSetter("secrets")}
			/>

			<ExternalSelectorField
				value={value.external}
				root={root}
				onChange={makeSetter("external")}
			/>

			<DbSelector
				name="mongo"
				value={value.mongo}
				onChange={makeSetter("mongo")}
				root={root}
				dbPriviledge={dbPriviledge}
			/>

			<DbSelector
				name="postgresql"
				value={value.postgresql}
				onChange={makeSetter("postgresql")}
				root={root}
				dbPriviledge={dbPriviledge}
			/>

			<DbSelector
				name="s3"
				value={value.s3}
				onChange={makeSetter("s3")}
				root={root}
			/>
		</>
	)
}

function StartupForm(props) {
	return <CommonContainerForm dbPriviledge={true} {...props} />
}

function CronForm({ value = {}, onChange, root }) {
	const makeSetter = (k) => {
		return (v) => onChange({ ...value, [k]: v })
	}

	return (
		<CommonContainerForm value={value} onChange={onChange} root={root} dbPriviledge={true} >
			<TextField
				label="schedule"
				onChange={makeSetter("schedule")}
				value={value.schedule}
				title="e.g. run every day at 2am (UTC): 00 2 * * *"
			>
				When the job should run in cron format.
				<CodeExample>
					Run every 5 minutes: */5 * * * * <br />
					Run every hour: 00 * * * * <br />
				</CodeExample>
			</TextField>
		</CommonContainerForm>
	)
}

function AppForm({ value = {}, onChange, root }) {
	const makeSetter = (k) => {
		return (v) => onChange({ ...value, [k]: v })
	}

	return (
		<CommonContainerForm value={value} onChange={onChange} root={root}>
			<TextField
				label="path"
				value={value.path}
				onChange={makeSetter("path")}
				placeholder="e.g. /api"
				title="must be 1-6 alphanimeric, '/', '_' or '-' characters"
				pattern="/(/|\w|-|_|\d){0,16}"
			>
				Path to mount this component on it's assigned host. This is presented to
				the component as the MOUNT_PATH env variable. You can then mount your
				service like so:
				<CodeExample>
					expressApp.use(process.env.MOUNT_PATH, apiRoute)
				</CodeExample>
			</TextField>

			<TextField
				label="subdomain"
				value={value.subdomain}
				onChange={makeSetter("subdomain")}
				placeholder="e.g. api"
				title="must be 1-6 alphanimeric or '-' characters"
				pattern="(\w|-){1,16}"
			>
				Subdomain prefix to prepend to the deployed hostname.
			</TextField>

			<NumberField
				label="port"
				value={value.port}
				onChange={makeSetter("port")}
				placeholder="default will use 8080"
				type="number"
				min="1000"
				max="65536"
			>
				Port that the application listens on. This is exposed to the app as env
				variable PORT which you can use like:
				<CodeExample>expressApp.listen(process.env.PORT)</CodeExample>
			</NumberField>

			<TextField
				label="health check"
				value={value.health_check}
				onChange={makeSetter("health_check")}
				placeholder="e.g. /health"
				title="must be 1-6 alphanimeric, '/', '_' or '-' characters"
				pattern="/(/|\w|-|_|\d){0,16}"
			>
				You can add a health check to your apps to indicate whether or not they
				are currently able to handle connections. The route just needs to
				respond with a sucess status code. This health check should be mounted
				at the root of the app and <b>not under MOUNT_PATH</b> Here's a very
				simple example:
				<CodeExample>
					expressApp.get("/health", (_, res) =&gt; res.json([]))
				</CodeExample>
			</TextField>
		</CommonContainerForm>
	)
}

export default function SchemaForm({ onSubmit, onChange, value, ...rest }) {

	const onDataChange = (data) => {
		onChange(data)
	}

	return (
		<Form onSubmit={onSubmit} noValidate >
			<Form.Control type="submit" value="render" />
			<FormSection title="Name">
				<TextField
					value={value.name}
					onChange={(name) => onDataChange({ ...value, name })}
					pattern="^[A-Z,a-z,\-,\d]{2,16}"
					aria-label="name"
					root={value}
				/>
			</FormSection>
			<FormSection title="Apps">
				<HelpText>
					Apps are service applications that run continuously. UIs and APIs are
					examples of "apps".
				</HelpText>
				<FieldMap
					value={value.apps}
					onChange={(apps) => onDataChange({ ...value, apps })}
					Component={AppForm}
					root={value}
					defaultValue={{}}
					deleteText="delete app"
				/>
			</FormSection>

			<FormSection title="Cron">
				<HelpText>
					Cron jobs are containers that are run on a schedule and perform
					maintenance tasks like re-indexing tables and clearing collections.
				</HelpText>
				<FieldMap
					value={value.cron}
					onChange={(cron) => onDataChange({ ...value, cron })}
					Component={CronForm}
					root={value}
					defaultValue={{}}
				/>
			</FormSection>

			<FormSection title="Startup">
				<HelpText>
					Startup jobs run once on deploy and update. They should typically be
					designed to check for any existing state and not assume a fresh
					environment.
				</HelpText>
				<FieldMap
					value={value.startup}
					onChange={(startup) => onDataChange({ ...value, startup })}
					Component={StartupForm}
					root={value}
					defaultValue={{}}
				/>
			</FormSection>

			<FormSection title="Mongo">
				<DbForm
					value={value.mongo}
					onChange={(mongo) => onDataChange({ ...value, mongo })}
				/>
			</FormSection>

			<FormSection title="Postgresql">
				<DbForm
					value={value.postgresql}
					onChange={(postgresql) => onDataChange({ ...value, postgresql })}
				/>
			</FormSection>

			<FormSection title="S3">
				<DbForm
					value={value.s3}
					onChange={(s3) => onDataChange({ ...value, s3 })}
				/>
			</FormSection>

			<FormSection title="External">
				<FieldMap
					value={value.external}
					onChange={(external) => onDataChange({ ...value, external })}
					Component={ExternalForm}
				/>
			</FormSection>

			<FormSection title="Secret Source">
				<SelectField
					value={value.secret_source}
					onChange={(secret_source) => onDataChange({ ...value, secret_source })}
					options={["none", "doppler", "gcp"]}
				>
					This is where the application secrets are stored if any are used.
					You should have been told about this at the start of the project.
				</SelectField>
			</FormSection>
		</Form>
	)
}
