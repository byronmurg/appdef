import Doc from "../Doc"

export default function SecurityPrinciplesDocumentation() {
	return (
		<Doc title="Security Principles">
			<Doc title="Network Isolation">
				<p>
					Connection into the infrastructure needs to be strictly controlled.
					This is typically achieved at the "platform" layer with the spec only
					defininng HTTP ingress access to selected services.
				</p>
				<p>
					Equally importantly we need to control external connection of our own
					applications. If one of our containers were to be compromised we don't
					want an attacker to be able to send data to their own endpoints.
					appspec enforces this by denying all outbound connections and requiring
					that allowed endpoints be explicilty declared in the spec.
				</p>
			</Doc>

			<Doc title="Non-priviledged execution">
				<p>
					It's bad practice for any application to run as a priviledged (root)
					user. By running as a basic user any attacker who manages to perform
					arbitrary execution will be unable to alter the underlying system.
					apppec can enforce this at the host layer by setting the{" "}
					<code> user </code> option for any container.
				</p>
			</Doc>

			<Doc title="Observability">
				<p>
					Application activity must be logged and audited for security and
					compliance purposes. This is achieved primarily at the platform level
					but also with facilities to collect and store application logs and
					metrics.
				</p>
			</Doc>

			<Doc title="Redundancy">
				<p>
					In case of a DOS attack the application must remain online. To achieve
					this all components should be replicated with fallover in case of
					failure.
				</p>
				<p>
					Redundancy should always be spread across cloud provider zones (where
					possible) to account for cloud downtime and network partition.
				</p>
			</Doc>

			<Doc title="Roles not passords">
				<p>
					Passwords can be lost, guessed, forgotten; roles can't. In many cases
					appdef components do use passwords for things such as database
					connections but we consider this a formality for compliance purposes,
					and although they are still company secrets they should never be
					thought of as the principle security measure.
				</p>
			</Doc>

			<Doc title="Cost capacity" >
				<p>
					Each component, both internal and external mush have limits on the 
					infrastructure resources that it can consume. This is to limit potential
					cost on case of hight load.
				</p>
				<p>
					One challenge to this is the trade-off with auto-scaling and may
					require some tweaking dependent on client requirements.
				</p>
			</Doc>
		</Doc>
	)
}
