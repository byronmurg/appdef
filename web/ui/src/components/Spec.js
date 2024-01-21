
export default
class Spec {
	constructor(baseSpec = {}) {
		this.spec_version = baseSpec.spec_version
		this.name = baseSpec.name
		this.apps = baseSpec.apps
		this.cron = baseSpec.cron
		this.startup = baseSpec.startup
		this.s3 = baseSpec.s3
		this.mongo = baseSpec.mongo
		this.postgresql = baseSpec.postgresql
		this.external = baseSpec.external
		this.secret_source = baseSpec.secret_source
	}


	static Entrify(containerMap, type) {
		return Object.entries(containerMap).map(([name, container]) => ({
			name,
			type,
			container,
			fullname: `${type}-${name}`,
		}))
	}

	/*
	 * Entry functions to generalise the different
	 * container types
	 */

	get AppEntries() {
		return Spec.Entrify(this.apps || {}, "app")
	}

	get CronEntries() {
		return Spec.Entrify(this.cron || {}, "cron")
	}

	get StartupEntries() {
		return Spec.Entrify(this.startup || {}, "startup")
	}

	get AllEntries() {
		return [].concat(
			this.AppEntries,
			this.CronEntries,
			this.StartupEntries,
		)
	}

	get ProxyEntries() {
		return Spec.Entrify(this.external ||{}, "proxy")
	}

	/*
	 * These getters simply default the db property to that 
	 * calling functions don't have to repeat the logic
	 */
	get Postgresql() {
		return this.postgresql || { enabled:false, dbs:[] }
	}

	get Mongo() {
		return this.mongo || { enabled:false, dbs:[] }
	}

	get S3() {
		return this.s3 || { enabled:false, dbs:[] }
	}

	/*
	 * A method to determine if any dbs at all are in use
	 */

	UsesAnyDbs() {
		return this.Postgresql.enabled || this.Mongo.enabled || this.S3.enabled
	}

	get Subdomains() {
		return this.AppEntries.filter((entry) => !!entry.container.path)
			.map((entry) => entry.subdomain || "")
			.filter((value, index, self) => self.indexOf(value) === index)
	}
}
